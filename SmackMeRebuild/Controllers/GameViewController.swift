//
//  GameViewController.swift
//  SmackMe
//
//  Main gameplay view controller
//

import UIKit
import Combine

class GameViewController: UIViewController {
    private var gameEngine: GameEngine!
    private var gestureManager: GestureManager!
    private var mode: GameMode!
    private var playerCount: Int = 1
    private var cancellables = Set<AnyCancellable>()

    private let backgroundImageView = UIImageView()
    private let robotImageView = UIImageView()
    private let scoreLabel = UILabel()
    private let levelLabel = UILabel()
    private let playerLabel = UILabel()
    private var gameplayAccessibilityElement: UIAccessibilityElement?
    private var currentMusicName: String?

    /// Earliest time at which lift/freeze gestures are accepted.
    /// Set to `Date() + cueDuration` when a new action appears, so the player
    /// must hear the full voice cue before their motion counts. Prevents the
    /// previous action's residual motion from triggering the new one
    /// (e.g. two consecutive lifts where the first lift's motion fires the second).
    private var cueEndTime: Date?

    /// Earliest time at which shake is accepted. Uses a short fixed grace
    /// period (0.15s) instead of the full cue duration, since shake is a
    /// deliberate burst that's less likely to be residual from a prior action.
    private var shakeReadyTime: Date?

    /// Overlay view shown between turns in multiplayer ("Pass to Player N").
    private var passScreenOverlay: UIView?

    init(mode: GameMode, playerCount: Int = 1) {
        self.mode = mode
        self.playerCount = playerCount
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleVoiceOverStatusDidChange),
            name: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil
        )

        setupGame()
        setupUI()
        setupGestures()
        setupBindings()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("[AX] GameViewController viewDidAppear voiceOverRunning=\(UIAccessibility.isVoiceOverRunning)")
        enableDirectTouch()
        startGameplayAfterAccessibilityHandoff { [weak self] in
            self?.gameEngine.startGame()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gameplayAccessibilityElement?.accessibilityFrameInContainerSpace = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        gameEngine.stopGame()
        disableDirectTouch()
        AudioManager.shared.stopAll()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        handleGameplayTouchBegan()
    }

    // MARK: - VoiceOver Direct Touch

    /// Enable direct touch so all taps/pinches go straight to the game
    /// without VoiceOver intercepting them.
    private func enableDirectTouch() {
        print("[AX] enableDirectTouch")
        if gameplayAccessibilityElement == nil {
            let element = UIAccessibilityElement(accessibilityContainer: view as Any)
            element.isAccessibilityElement = true
            gameplayAccessibilityElement = element
        }

        gameplayAccessibilityElement?.accessibilityLabel = "SmackMe game"
        gameplayAccessibilityElement?.accessibilityHint = nil
        gameplayAccessibilityElement?.accessibilityTraits = [.allowsDirectInteraction, .startsMediaSession]
        gameplayAccessibilityElement?.accessibilityFrameInContainerSpace = view.bounds

        view.isAccessibilityElement = false
        view.accessibilityViewIsModal = true
        view.accessibilityElements = gameplayAccessibilityElement.map { [$0] }
        presentingViewController?.view.accessibilityElementsHidden = true
        presentingViewController?.navigationController?.view.accessibilityElementsHidden = true
        setDecorativeElementsAccessibilityHidden(true)
        // Small delay lets UIKit finish any layout/transition before
        // VoiceOver tries to focus on the view
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIAccessibility.post(notification: .screenChanged, argument: self.gameplayAccessibilityElement)
        }
    }

    /// Restore normal VoiceOver behavior so alerts and menus are navigable.
    private func disableDirectTouch() {
        view.isAccessibilityElement = false
        view.accessibilityViewIsModal = false
        view.accessibilityElements = nil
        presentingViewController?.view.accessibilityElementsHidden = false
        presentingViewController?.navigationController?.view.accessibilityElementsHidden = false
        setDecorativeElementsAccessibilityHidden(false)
    }

    private func startGameplayAfterAccessibilityHandoff(_ action: @escaping () -> Void) {
        let delay: TimeInterval = UIAccessibility.isVoiceOverRunning ? 0.5 : 0.0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: action)
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundImageView)

        robotImageView.contentMode = .scaleAspectFit
        robotImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(robotImageView)

        scoreLabel.font = UIFont.boldSystemFont(ofSize: 24)
        scoreLabel.textColor = .white
        scoreLabel.textAlignment = .left
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scoreLabel)

        levelLabel.font = UIFont.boldSystemFont(ofSize: 18)
        levelLabel.textColor = .white
        levelLabel.textAlignment = .center
        levelLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(levelLabel)

        playerLabel.font = UIFont.boldSystemFont(ofSize: 18)
        playerLabel.textColor = .yellow
        playerLabel.textAlignment = .right
        playerLabel.translatesAutoresizingMaskIntoConstraints = false
        playerLabel.isHidden = !gameEngine.isMultiplayer
        view.addSubview(playerLabel)

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scoreLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            scoreLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            playerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            playerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            levelLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            levelLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            robotImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            robotImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            robotImageView.widthAnchor.constraint(equalToConstant: 300),
            robotImageView.heightAnchor.constraint(equalToConstant: 300)
        ])

        // Initial background and labels
        let config = mode.levels[0]
        backgroundImageView.image = UIImage(named: config.backgroundImage)
        scoreLabel.text = "Score: 0"
        levelLabel.text = "Level 1"
        if gameEngine.isMultiplayer {
            playerLabel.text = "Player 1"
        }
    }

    private func setupGame() {
        gameEngine = GameEngine(mode: mode, playerCount: playerCount)

        // Engine calls this on timeout - handleGameOver handles the fail sound chain
        gameEngine.onActionTimeout = nil
    }

    private func setupGestures() {
        gestureManager = GestureManager()
        gestureManager.delegate = self
        gestureManager.setup(on: view)
    }

    @objc private func handleVoiceOverStatusDidChange() {
        print("[AX] voiceOverStatusDidChange running=\(UIAccessibility.isVoiceOverRunning)")
        guard viewIfLoaded?.window != nil else { return }
        if gameEngine.gameState == .playing {
            enableDirectTouch()
        }
    }

    private func setDecorativeElementsAccessibilityHidden(_ hidden: Bool) {
        let decorativeViews: [UIView] = [
            backgroundImageView,
            robotImageView,
            scoreLabel,
            levelLabel,
            playerLabel
        ]

        decorativeViews.forEach { view in
            view.isAccessibilityElement = false
            view.accessibilityElementsHidden = hidden
        }
    }

    /// Two-finger scrub (back gesture) exits the game when VoiceOver is on.
    override func accessibilityPerformEscape() -> Bool {
        gameEngine.stopGame()
        AudioManager.shared.stopAll()
        disableDirectTouch()
        dismiss(animated: true)
        return true
    }

    private func handleGameplayTouchBegan() {
        guard gameEngine.gameState == .playing,
              gameEngine.currentAction == .freeze else { return }
        // Cancel freeze detection and treat as wrong action as soon as the
        // player touches the gameplay surface.
        gestureManager.resetFreezeState()
        let _ = gameEngine.processAction(.smack)
    }

    private func setupBindings() {
        // Action display - show animation and play audio cue
        gameEngine.$currentAction
            .sink { [weak self] action in
                self?.updateUI(for: action)
                if action != nil {
                    let now = Date()
                    // Lift waits for the full recorded cue so residual motion
                    // from the previous action cannot trigger the next one early.
                    let cueDuration = AudioManager.shared.actionCueDuration
                    self?.cueEndTime = now.addingTimeInterval(cueDuration)
                    // Shake: short fixed grace period (deliberate burst, less residual risk)
                    self?.shakeReadyTime = now.addingTimeInterval(0.15)
                    // Reset freeze state so detection starts fresh for each new action
                    self?.gestureManager.resetFreezeState()
                }
            }
            .store(in: &cancellables)

        // Score display
        gameEngine.$score
            .sink { [weak self] score in
                self?.scoreLabel.text = "Score: \(score)"
            }
            .store(in: &cancellables)

        // Level changes - update background image and label
        gameEngine.$currentLevel
            .removeDuplicates()
            .sink { [weak self] level in
                guard let self = self else { return }
                self.levelLabel.text = "Level \(level + 1)"
                let config = self.mode.levels[min(level, self.mode.levels.count - 1)]
                if let bgImage = UIImage(named: config.backgroundImage) {
                    self.backgroundImageView.image = bgImage
                }
            }
            .store(in: &cancellables)

        // Player indicator (multiplayer)
        gameEngine.$currentPlayerIndex
            .sink { [weak self] idx in
                guard let self = self, self.gameEngine.isMultiplayer else { return }
                self.playerLabel.text = "Player \(idx + 1)"
            }
            .store(in: &cancellables)

        // Game state changes - controls music and game flow
        gameEngine.$gameState
            .removeDuplicates()
            .sink { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .playing:
                    self.enableDirectTouch()
                    self.startLevelMusic()
                    let levelNum = self.gameEngine.currentLevel + 1
                    let bpm = self.gameEngine.currentLevelConfig.bpm
                    let beatInterval = self.gameEngine.currentLevelConfig.beatInterval
                    // Scale freeze duration with BPM: 1.0s at slow tempos,
                    // shorter at fast tempos (2 beats, min 0.3s).
                    // Combined with the 1-beat gap after freeze, total cycle stays
                    // well within actionDeadline at every BPM.
                    self.gestureManager.freezeDuration = min(1.0, max(beatInterval * 2, 0.3))
                    print("[GameVC] Level \(levelNum) starting: bpm=\(bpm) music=\(self.gameEngine.currentLevelConfig.music) freezeDur=\(self.gestureManager.freezeDuration)s deadline=\(self.gameEngine.actionDeadline)s")
                case .levelComplete:
                    self.handleLevelComplete()
                case .gameOver:
                    self.handleSinglePlayerGameOver()
                case .gameComplete:
                    if self.gameEngine.isMultiplayer {
                        self.handleMultiplayerComplete()
                    } else {
                        self.handleGameComplete()
                    }
                case .idle:
                    break
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Music Management

    private func startLevelMusic() {
        let music = gameEngine.currentLevelConfig.music
        // Only restart if the music track actually changed
        if music != currentMusicName {
            currentMusicName = music
            AudioManager.shared.playMusic(music)
        }
    }

    // MARK: - Action Display

    private func updateUI(for action: GameAction?) {
        if let action = action {
            let bpm = gameEngine.currentLevelConfig.bpm

            // Robot animation
            let images = action.animationImages(for: bpm)
            if let firstImage = images.first, let image = UIImage(named: firstImage) {
                robotImageView.image = image
                let allImages = images.compactMap { UIImage(named: $0) }
                robotImageView.animationImages = allImages
                robotImageView.animationDuration = 0.5
                robotImageView.startAnimating()
            }

            // Play the cue that already matches this BPM at native speed.
            let cueFile = action.soundKey(for: bpm) + ".wav"
            print("[GameVC] ▸ action=\(action.rawValue) bpm=\(bpm) level=\(gameEngine.currentLevel+1) cue=\(cueFile)")
            AudioManager.shared.playActionCue(cueFile)
        } else {
            robotImageView.stopAnimating()
            robotImageView.image = nil
            AudioManager.shared.stopActionCue()
        }
    }

    // MARK: - Level Complete

    private func handleLevelComplete() {
        AudioManager.shared.stopActionCue()

        if gameEngine.isMultiplayer {
            AudioManager.shared.stopMusic()
            currentMusicName = nil
            handleMultiplayerLevelComplete()
        } else {
            handleSinglePlayerLevelComplete()
        }
    }

    private func handleSinglePlayerLevelComplete() {
        // Show congratulations image
        let congratsImages = [
            "smackme_robot_congratulations_trans.png",
            "smackme_robot_congratulations2_trans.png",
            "smackme_robot_congratulations3_trans.png"
        ]
        if let imgName = congratsImages.randomElement(),
           let img = UIImage(named: imgName) {
            robotImageView.stopAnimating()
            robotImageView.image = img
        }

        // Wait a short moment so the last action's confirm sound isn't
        // immediately cut off by the interlude. Then stop music and play interlude.
        let delay = max(0.4, gameEngine.currentLevelConfig.beatInterval * 2)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            AudioManager.shared.stopMusic()
            self?.currentMusicName = nil
            AudioManager.shared.playSound("interlude.wav") { [weak self] in
                DispatchQueue.main.async {
                    self?.robotImageView.image = nil
                    self?.gameEngine.advanceToNextLevel()
                }
            }
        }
    }

    private func handleMultiplayerLevelComplete() {
        // Save this player's progress
        gameEngine.advanceCurrentPlayerLevel()

        let completedPlayer = gameEngine.currentPlayerIndex + 1
        let completedScore = gameEngine.score

        // Show pass-me image
        let passImages = ["smackme_robot_passme01.png", "smackme_robot_passme02.png"]
        if let imgName = passImages.randomElement(),
           let img = UIImage(named: imgName) {
            robotImageView.stopAnimating()
            robotImageView.image = img
        }

        // Find next player
        if let nextPlayer = gameEngine.nextActivePlayer() {
            showPassScreen(
                title: "Level complete!",
                detail: "Player \(completedPlayer) scored \(completedScore)",
                nextPlayer: nextPlayer + 1
            ) { [weak self] in
                self?.robotImageView.image = nil
                self?.enableDirectTouch()
                self?.startGameplayAfterAccessibilityHandoff {
                    self?.gameEngine.startPlayerTurn(nextPlayer)
                }
            }
        } else {
            // Only one player was active, and they completed - shouldn't happen
            // but handle gracefully
            handleMultiplayerComplete()
        }
    }

    // MARK: - Game Over (Single Player)

    private func handleSinglePlayerGameOver() {
        guard presentedViewController == nil else { return }

        disableDirectTouch()

        AudioManager.shared.stopMusic()
        AudioManager.shared.stopActionCue()
        currentMusicName = nil

        let isHighScore = gameEngine.checkHighScore()

        if isHighScore {
            gameEngine.saveHighScore(playerName: "Player")
        }

        if isHighScore {
            AudioManager.shared.playSound("fail.wav") {
                DispatchQueue.main.async {
                    AudioManager.shared.playSound("newhighscore.wav") {
                        DispatchQueue.main.async {
                            AudioManager.shared.playMusic("HighScoreHappy.mp3", loops: true)
                        }
                    }
                }
            }
        } else {
            AudioManager.shared.playSound("fail.wav") {
                DispatchQueue.main.async {
                    AudioManager.shared.playMusic("HighScoreSad.mp3", loops: true)
                }
            }
        }

        let title = isHighScore ? "New High Score!" : "Game Over"
        let alert = UIAlertController(
            title: title,
            message: "Score: \(gameEngine.score)",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            AudioManager.shared.stopAll()
            self?.dismiss(animated: true)
        })

        present(alert, animated: true)
    }

    // MARK: - Multiplayer Complete (game over for all)

    private func handleMultiplayerComplete() {
        guard presentedViewController == nil else { return }

        disableDirectTouch()
        removePassScreen()

        AudioManager.shared.stopMusic()
        AudioManager.shared.stopActionCue()
        currentMusicName = nil

        // Build results message showing both players' scores
        var message = ""
        var bestScore = 0
        var winner = 1
        for i in 0..<gameEngine.playerCount {
            let pScore = gameEngine.playerScores[i]
            message += "Player \(i + 1): \(pScore)\n"
            if pScore > bestScore {
                bestScore = pScore
                winner = i + 1
            }
        }
        if gameEngine.playerScores[0] == gameEngine.playerScores[1] {
            message += "\nIt's a tie!"
        } else {
            message += "\nPlayer \(winner) wins!"
        }

        // Check for high score (use best score)
        let isHighScore = bestScore > 0 && {
            let topScores = HighScoreManager.shared.getTopScores(for: gameEngine.mode, limit: 10)
            return topScores.isEmpty || bestScore > (topScores.first?.score ?? 0)
        }()

        if isHighScore {
            let highScore = HighScore(playerName: "Player \(winner)", score: bestScore, mode: gameEngine.mode.rawValue, date: Date())
            HighScoreManager.shared.saveScore(highScore)
        }

        AudioManager.shared.playSound("fail.wav") {
            DispatchQueue.main.async {
                if isHighScore {
                    AudioManager.shared.playMusic("HighScoreHappy.mp3", loops: true)
                } else {
                    AudioManager.shared.playMusic("HighScoreSad.mp3", loops: true)
                }
            }
        }

        let title = isHighScore ? "New High Score!" : "Game Over"
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            AudioManager.shared.stopAll()
            self?.dismiss(animated: true)
        })

        present(alert, animated: true)
    }

    // MARK: - Game Complete (single player - all levels beaten)

    private func handleGameComplete() {
        guard presentedViewController == nil else { return }

        disableDirectTouch()

        AudioManager.shared.stopMusic()
        AudioManager.shared.stopActionCue()
        currentMusicName = nil

        let isHighScore = gameEngine.checkHighScore()

        if isHighScore {
            gameEngine.saveHighScore(playerName: "Player")
        }

        if isHighScore {
            AudioManager.shared.playSound("100percent.wav") {
                DispatchQueue.main.async {
                    AudioManager.shared.playSound("newhighscore.wav") {
                        DispatchQueue.main.async {
                            AudioManager.shared.playMusic("HighScoreHappy.mp3", loops: true)
                        }
                    }
                }
            }
        } else {
            AudioManager.shared.playSound("100percent.wav") {
                DispatchQueue.main.async {
                    AudioManager.shared.playMusic("HighScoreSad.mp3", loops: true)
                }
            }
        }

        let title = isHighScore ? "New High Score!" : "Congratulations!"
        let alert = UIAlertController(
            title: title,
            message: "You completed all levels!\nScore: \(gameEngine.score)",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            AudioManager.shared.stopAll()
            self?.dismiss(animated: true)
        })

        present(alert, animated: true)
    }

    // MARK: - Pass Screen (multiplayer device handoff)

    private func showPassScreen(title: String, detail: String, nextPlayer: Int, onReady: @escaping () -> Void) {
        removePassScreen()
        disableDirectTouch()

        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = .black
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 32)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let detailLabel = UILabel()
        detailLabel.text = detail
        detailLabel.font = UIFont.systemFont(ofSize: 20)
        detailLabel.textColor = .lightGray
        detailLabel.textAlignment = .center
        detailLabel.translatesAutoresizingMaskIntoConstraints = false

        let passLabel = UILabel()
        passLabel.text = "Pass to Player \(nextPlayer)"
        passLabel.font = UIFont.boldSystemFont(ofSize: 28)
        passLabel.textColor = .yellow
        passLabel.textAlignment = .center
        passLabel.translatesAutoresizingMaskIntoConstraints = false

        let tapLabel = UILabel()
        tapLabel.text = "Tap to start"
        tapLabel.font = UIFont.systemFont(ofSize: 18)
        tapLabel.textColor = .gray
        tapLabel.textAlignment = .center
        tapLabel.translatesAutoresizingMaskIntoConstraints = false

        overlay.addSubview(titleLabel)
        overlay.addSubview(detailLabel)
        overlay.addSubview(passLabel)
        overlay.addSubview(tapLabel)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: overlay.centerYAnchor, constant: -80),

            detailLabel.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),

            passLabel.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            passLabel.topAnchor.constraint(equalTo: detailLabel.bottomAnchor, constant: 40),

            tapLabel.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            tapLabel.topAnchor.constraint(equalTo: passLabel.bottomAnchor, constant: 20)
        ])

        // Make accessible for VoiceOver
        overlay.isAccessibilityElement = true
        overlay.accessibilityLabel = "\(title). \(detail). Pass to Player \(nextPlayer). Double tap to start."
        overlay.accessibilityTraits = [.button]

        // Play pass_me sound
        AudioManager.shared.playSound("pass_me.wav")

        // Store callback and add tap recognizer
        passScreenCallback = onReady
        let tap = UITapGestureRecognizer(target: self, action: #selector(passScreenTapped))
        overlay.addGestureRecognizer(tap)

        view.addSubview(overlay)
        passScreenOverlay = overlay

        UIAccessibility.post(notification: .screenChanged, argument: overlay)
    }

    private var passScreenCallback: (() -> Void)?

    @objc private func passScreenTapped() {
        let callback = passScreenCallback
        passScreenCallback = nil
        removePassScreen()
        callback?()
    }

    private func removePassScreen() {
        passScreenOverlay?.removeFromSuperview()
        passScreenOverlay = nil
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        gestureManager.cleanup()
    }
}

// MARK: - Gesture Handling

extension GameViewController: GestureManagerDelegate {
    func gestureDetected(_ action: GameAction) {
        // Ignore gestures unless actively playing with a pending action
        guard gameEngine.gameState == .playing,
              let expectedAction = gameEngine.currentAction else { return }

        // Motion gestures (shake/lift/freeze) come from the accelerometer and can
        // fire accidentally from normal phone handling. Only process them when they
        // match the expected action. Touch gestures (tap/pinch) are deliberate, so
        // a wrong tap/pinch still causes game over.
        if action == .shake || action == .lift || action == .freeze {
            if action != expectedAction {
                return
            }
            if action == .shake {
                // Shake: short grace period so the previous action's motion
                // doesn't false-trigger, but doesn't eat into the response window
                if let ready = shakeReadyTime, Date() < ready {
                    return
                }
            } else if action == .lift {
                // Lift: wait for the full voice cue to finish playing.
                // Prevents residual motion from triggering consecutive lifts.
                if let cueEnd = cueEndTime, Date() < cueEnd {
                    return
                }
            }
            // Freeze: no cue gate needed. Freeze requires deliberate stillness
            // for freezeDuration seconds, so there's no risk of residual motion
            // from a prior action triggering it. The freeze timer resets when
            // each new action appears (resetFreezeState in the binding).
        }

        let success = gameEngine.processAction(action)

        if success {
            if expectedAction != .freeze {
                // Fire-and-forget: play confirm sound without waiting for completion.
                // This keeps action cadence locked to the beat grid.
                AudioManager.shared.playSound(expectedAction.confirmSound)
            }
            // All actions use the same 1-beat gap for consistent rhythm.
            // Freeze has no confirm sound but the gap keeps cadence predictable
            // across consecutive freezes (avoids timer-jitter-induced beat skips).
            gameEngine.continueAfterAction(minBeatGap: 0.5)
        } else {
            // Wrong action - game over.
            // handleGameOver is triggered by the $gameState binding and handles
            // the full audio chain: fail.wav → newhighscore.wav → high score music.
        }
    }
}
