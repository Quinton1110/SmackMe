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
    /// 6 beats at the current BPM — scales with difficulty so higher BPMs
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

    // MARK: - Beat-Synced Scheduling

    /// Waits for the intro bar (4 beats) using the music player's actual playback
    /// position, so the first action appears exactly when the main melody starts.
    private func scheduleFirstAction() {
        let beatInterval = currentLevelConfig.beatInterval
        let musicTime = AudioManager.shared.musicCurrentTime
        let targetBeat = 4.0 // end of intro bar
        let targetTime = targetBeat * beatInterval
        var delay = targetTime - musicTime
        if delay < 0.05 { delay = targetTime } // music hasn't started yet
        print("[GameEngine] scheduleFirstAction: musicTime=\(String(format: "%.3f", musicTime))s targetTime=\(String(format: "%.3f", targetTime))s delay=\(String(format: "%.3f", delay))s")
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.presentNextAction()
        }
    }

    /// Called by the VC immediately after a correct action.
    /// Snaps the next action to a beat boundary using the music player's actual
    /// position. `minBeatGap` controls how soon the next action can appear:
    ///   - 1.0 for actions with a confirm sound (gives time for it to be heard)
    ///   - 0.0 for freeze (no confirm sound, move to very next beat)
    func continueAfterAction(minBeatGap: Double = 0.5) {
        guard gameState == .playing else { return }
        let beatInterval = currentLevelConfig.beatInterval
        let musicTime = AudioManager.shared.musicCurrentTime
        let currentBeat = musicTime / beatInterval
        // Snap to the next beat boundary that's at least minBeatGap beats away.
        // With minBeatGap=0.5, actual gap ranges from 0.5–1.5 beats (avg ~1 beat),
        // preventing the 2-beat gaps that occurred with minBeatGap=1.0.
        let targetBeat = ceil(currentBeat + minBeatGap)
        let targetTime = targetBeat * beatInterval
        var delay = targetTime - musicTime
        if delay < 0.05 {
            delay += beatInterval
        }
        print("[GameEngine] continueAfterAction: musicPos=\(String(format: "%.3f", musicTime))s beat=\(String(format: "%.1f", currentBeat)) targetBeat=\(String(format: "%.0f", targetBeat)) delay=\(String(format: "%.3f", delay))s gap=\(minBeatGap)")
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.presentNextAction()
        }
    }

    // MARK: - Action Presentation

    private func presentNextAction() {
        guard gameState == .playing else {
            print("[GameEngine] presentNextAction: skipped, gameState=\(gameState)")
            return
        }

        // Check if the level is complete
        if actionsRemainingInLevel <= 0 {
            timer?.invalidate()
            currentAction = nil
            print("[GameEngine] Level \(currentLevel) COMPLETE (all actions done). Total levels: \(mode.levels.count)")
            gameState = .levelComplete
            return
        }

        timer?.invalidate()
        currentAction = mode.actions.randomElement()
        actionStartTime = Date()
        actionsRemainingInLevel -= 1
        print("[GameEngine] presentNextAction: player=\(currentPlayerIndex+1) level=\(currentLevel) remaining=\(actionsRemainingInLevel) action=\(currentAction?.rawValue ?? "nil") deadline=\(actionDeadline)s")

        // Give the player actionDeadline seconds to respond
        timer = Timer.scheduledTimer(withTimeInterval: actionDeadline, repeats: false) { [weak self] _ in
            self?.handleTimeout()
        }
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

        timer?.invalidate()

        if action == expectedAction {
            // Correct — 1 point per correct action
            score += 1
            print("[GameEngine] CORRECT: \(action.rawValue) +1pt (total=\(score)) remaining=\(actionsRemainingInLevel)")
            currentAction = nil
            return true
        } else {
            // Wrong action — game over
            print("[GameEngine] WRONG: got \(action.rawValue), expected \(expectedAction.rawValue) → GAME OVER")
            currentAction = nil
            endGame()
            return false
        }
    }

    // MARK: - Timeout & Game Over

    private func handleTimeout() {
        guard gameState == .playing else { return }

        // Player didn't respond in time — game over
        currentAction = nil
        onActionTimeout?()
        endGame()
    }

    private func endGame() {
        timer?.invalidate()
        timer = nil
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
