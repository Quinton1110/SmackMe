//
//  GameEngine.swift
//  SmackMe
//
//  Core game logic and timing
//

import Foundation
import Combine

class GameEngine: ObservableObject {

    // MARK: - Game State

    enum GameState: Equatable {
        case idle
        case playing
        case levelComplete
        case gameOver        // 1P: game ends; 2P: current player eliminated
        case gameComplete    // 1P: beat all levels; 2P: all players eliminated
    }

    @Published var currentAction: GameAction?
    @Published var score: Int = 0
    @Published var currentLevel: Int = 0
    @Published var gameState: GameState = .idle
    @Published var currentPlayerIndex: Int = 0

    private(set) var mode: GameMode
    let playerCount: Int
    private var timer: Timer?
    private var actionStartTime: Date?
    private var actionsRemainingInLevel: Int = 0

    // MARK: - Grid Cadence

    /// Repeating 20 Hz poll that drives the fixed beat grid and freeze checks.
    private var gridTimer: Timer?
    /// Wall clock time of the next grid boundary (when the current slot is judged
    /// and the next cue is presented).
    private var nextBoundary: Date?
    /// Beats between cues. The whole game runs on this fixed grid so the pulse
    /// stays steady, and a freeze simply fills one slot. This is also the response
    /// window, so it has to be wide enough to hear the cue and react. One bar.
    private let slotBeats: Double = 4.0

    // MARK: - Multiplayer State

    /// Per-player scores (indexed by player number 0..<playerCount)
    var playerScores: [Int] = []
    /// Per-player level progression (each player advances independently)
    var playerLevels: [Int] = []
    /// Which players are still in the game
    var activePlayers: [Bool] = []

    var isMultiplayer: Bool { return playerCount > 1 }

    /// Called when the player misses an action (timeout). VC plays fail sound.
    var onActionTimeout: (() -> Void)?

    var currentLevelConfig: Level {
        return mode.levels[min(currentLevel, mode.levels.count - 1)]
    }

    /// Time the player has to respond to each action.
    /// 6 beats at the current BPM - scales with difficulty so higher BPMs
    /// are genuinely harder (e.g. 3.6s at 100 BPM, 1.0s at 360 BPM).
    var actionDeadline: TimeInterval {
        return currentLevelConfig.beatInterval * 6
    }

    /// Duration of the intro bar before actions begin.
    /// Each music track has a 1-bar (4-beat) intro before the main melody.
    var introBarDuration: TimeInterval {
        return currentLevelConfig.beatInterval * 4
    }

    init(mode: GameMode, playerCount: Int = 1) {
        self.mode = mode
        self.playerCount = max(1, playerCount)
        self.playerScores = Array(repeating: 0, count: self.playerCount)
        self.playerLevels = Array(repeating: 0, count: self.playerCount)
        self.activePlayers = Array(repeating: true, count: self.playerCount)
    }

    // MARK: - Game Flow

    func startGame() {
        // Reset all multiplayer state
        playerScores = Array(repeating: 0, count: playerCount)
        playerLevels = Array(repeating: 0, count: playerCount)
        activePlayers = Array(repeating: true, count: playerCount)
        currentPlayerIndex = 0

        score = 0
        currentLevel = 0
        gameState = .playing
        actionsRemainingInLevel = currentLevelConfig.actionsRequired
        print("[GameEngine] startGame: player=\(currentPlayerIndex+1)/\(playerCount) level=\(currentLevel) actionsRequired=\(actionsRemainingInLevel) bpm=\(currentLevelConfig.bpm) introBar=\(introBarDuration)s")
        scheduleFirstAction()
    }

    func stopGame() {
        gameState = .idle
        timer?.invalidate()
        timer = nil
        stopGridPoll()
        currentAction = nil
    }

    /// Called by the VC after the interlude finishes to start the next level (single player only).
    func advanceToNextLevel() {
        guard currentLevel < mode.levels.count - 1 else {
            print("[GameEngine] advanceToNextLevel: ALL LEVELS DONE (currentLevel=\(currentLevel), totalLevels=\(mode.levels.count))")
            gameState = .gameComplete
            return
        }
        currentLevel += 1
        actionsRemainingInLevel = currentLevelConfig.actionsRequired
        print("[GameEngine] advanceToNextLevel: now level=\(currentLevel) actionsRequired=\(actionsRemainingInLevel) bpm=\(currentLevelConfig.bpm) introBar=\(introBarDuration)s")
        gameState = .playing
        scheduleFirstAction()
    }

    // MARK: - Multiplayer Turn Management

    /// Save the current player's progress and advance their level.
    /// Called by VC when a multiplayer level is completed.
    func advanceCurrentPlayerLevel() {
        playerScores[currentPlayerIndex] = score
        let nextLevel = min(currentLevel + 1, mode.levels.count - 1)
        playerLevels[currentPlayerIndex] = nextLevel
        print("[GameEngine] advanceCurrentPlayerLevel: player=\(currentPlayerIndex+1) score=\(score) nextLevel=\(nextLevel)")
    }

    /// Find the next active player after the current one, or nil if none remain.
    func nextActivePlayer() -> Int? {
        for offset in 1...playerCount {
            let idx = (currentPlayerIndex + offset) % playerCount
            if activePlayers[idx] { return idx }
        }
        return nil
    }

    /// Switch to the given player and start their turn at their current level.
    func startPlayerTurn(_ playerIndex: Int) {
        currentPlayerIndex = playerIndex
        score = playerScores[playerIndex]
        currentLevel = playerLevels[playerIndex]
        actionsRemainingInLevel = currentLevelConfig.actionsRequired
        print("[GameEngine] startPlayerTurn: player=\(playerIndex+1) score=\(score) level=\(currentLevel) bpm=\(currentLevelConfig.bpm)")
        gameState = .playing
        scheduleFirstAction()
    }

    // MARK: - Grid Scheduling

    /// Set by the VC. Returns true if the player has not moved since the given time.
    var isStillSince: ((Date) -> Bool)?

    /// After this time in a freeze slot, any movement loses the game. The short
    /// grace lets motion from the previous action wind down first.
    private var freezeCutoff: Date?

    /// Align the first cue of a level to the end of the intro bar (or the next
    /// grid slot if the music is already past it), then run the fixed grid.
    private func scheduleFirstAction() {
        let beatInterval = currentLevelConfig.beatInterval
        let musicTime = AudioManager.shared.musicCurrentTime
        let introBeat = 4.0 // end of the one bar intro
        var delay = introBeat * beatInterval - musicTime
        if delay < 0.05 {
            // Music already past the intro (continued or looping track). Align to
            // the next slot boundary instead of stalling for another intro.
            let currentBeat = musicTime / beatInterval
            let nextSlot = (floor(currentBeat / slotBeats) + 1) * slotBeats
            delay = nextSlot * beatInterval - musicTime
            if delay < 0.05 { delay += slotBeats * beatInterval }
        }
        nextBoundary = Date().addingTimeInterval(delay)
        print("[GameEngine] scheduleFirstAction: delay=\(String(format: "%.3f", delay))s slotBeats=\(slotBeats)")
        startGridPoll()
    }

    private func startGridPoll() {
        gridTimer?.invalidate()
        gridTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    private func stopGridPoll() {
        gridTimer?.invalidate()
        gridTimer = nil
    }

    /// Runs at 20 Hz. Fails a freeze the instant the player moves, and at each
    /// grid boundary judges the current slot and presents the next cue.
    private func poll() {
        guard gameState == .playing else { stopGridPoll(); return }
        let now = Date()

        // Freeze breaks the instant the player moves, after the settle grace.
        if currentAction == .freeze, let cutoff = freezeCutoff, now >= cutoff,
           let stillCheck = isStillSince, stillCheck(cutoff) == false {
            print("[GameEngine] FREEZE broken (player moved) → GAME OVER")
            currentAction = nil
            endGame()
            return
        }

        // Grid boundary: judge the slot that just ended and open the next one.
        if let boundary = nextBoundary, now >= boundary {
            resolveAndPresent()
            if gameState == .playing {
                advanceBoundary()
            }
        }
    }

    /// Set nextBoundary to the next slot boundary on the music grid, one slot
    /// ahead. Re-deriving from the music each slot keeps cues locked to the beat
    /// and survives the track looping.
    private func advanceBoundary() {
        let beatInterval = currentLevelConfig.beatInterval
        let musicTime = AudioManager.shared.musicCurrentTime
        let currentBeat = musicTime / beatInterval
        let nextSlot = (floor(currentBeat / slotBeats) + 1) * slotBeats
        var delay = nextSlot * beatInterval - musicTime
        // Keep each slot close to a full slotBeats so timing jitter never
        // collapses two cues together.
        if delay < slotBeats * beatInterval * 0.5 {
            delay += slotBeats * beatInterval
        }
        nextBoundary = Date().addingTimeInterval(delay)
    }

    /// Judge the action from the slot that just ended, then present the next one.
    /// A correct response during the slot clears currentAction, so an unanswered
    /// non freeze action here is a miss. A freeze that survived the movement poll
    /// was held still, so it scores.
    private func resolveAndPresent() {
        if let prev = currentAction {
            if prev == .freeze {
                score += 1
                print("[GameEngine] FREEZE held: +1pt (total=\(score))")
                currentAction = nil
            } else {
                print("[GameEngine] MISS: \(prev.rawValue) not answered in time → GAME OVER")
                currentAction = nil
                onActionTimeout?()
                endGame()
                return
            }
        }

        if actionsRemainingInLevel <= 0 {
            stopGridPoll()
            currentAction = nil
            print("[GameEngine] Level \(currentLevel) COMPLETE")
            gameState = .levelComplete
            return
        }

        currentAction = mode.actions.randomElement()
        actionStartTime = Date()
        actionsRemainingInLevel -= 1
        if currentAction == .freeze {
            // Give the player time to hear the "freeze" cue and come to a stop
            // before stillness is enforced, so leftover motion from the previous
            // action (a fast transition off a shake or lift) doesn't lose them
            // before they even know it's a freeze. Up to about 0.6s, capped at
            // half the slot so there's still a real stillness window.
            let settle = min(0.6, slotBeats * currentLevelConfig.beatInterval * 0.5)
            freezeCutoff = Date().addingTimeInterval(settle)
        }
        print("[GameEngine] presentCue: player=\(currentPlayerIndex+1) level=\(currentLevel) remaining=\(actionsRemainingInLevel) action=\(currentAction?.rawValue ?? "nil")")
    }

    // MARK: - Player Input

    /// Process a gesture from the player. Returns true if correct.
    /// Wrong action = immediate game over.
    func processAction(_ action: GameAction) -> Bool {
        guard gameState == .playing,
              let expectedAction = currentAction,
              actionStartTime != nil else {
            print("[GameEngine] processAction: ignored (state=\(gameState), action=\(currentAction?.rawValue ?? "nil"))")
            return false
        }

        if action == expectedAction {
            // Correct. Clear the action; the next cue arrives on the grid, not
            // immediately, so the cadence stays steady no matter how fast you answer.
            score += 1
            print("[GameEngine] CORRECT: \(action.rawValue) +1pt (total=\(score)) remaining=\(actionsRemainingInLevel)")
            currentAction = nil
            return true
        } else {
            // Wrong action - game over
            print("[GameEngine] WRONG: got \(action.rawValue), expected \(expectedAction.rawValue) → GAME OVER")
            currentAction = nil
            endGame()
            return false
        }
    }

    // MARK: - Game Over

    private func endGame() {
        timer?.invalidate()
        timer = nil
        stopGridPoll()
        currentAction = nil

        if isMultiplayer {
            // Save the failing player's score and end the game immediately.
            // Both players' scores are shown on the game over screen.
            playerScores[currentPlayerIndex] = score
            gameState = .gameComplete
            print("[GameEngine] endGame (multi): player=\(currentPlayerIndex+1) failed, score=\(score) → game over for all")
        } else {
            gameState = .gameOver
        }
    }

    // MARK: - High Scores

    func checkHighScore() -> Bool {
        guard score > 0 else { return false }
        let topScores = HighScoreManager.shared.getTopScores(for: mode, limit: 10)
        if topScores.isEmpty { return true }
        return score > (topScores.first?.score ?? 0)
    }

    func saveHighScore(playerName: String) {
        let highScore = HighScore(playerName: playerName, score: score, mode: mode.rawValue, date: Date())
        HighScoreManager.shared.saveScore(highScore)
    }
}
