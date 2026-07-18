//
//  MainMenuViewController.swift
//  SmackMe
//
//  Main menu and mode selection
//

import UIKit

class MainMenuViewController: UIViewController {
    private let titleLabel = UILabel()
    private let playerModeControl = UISegmentedControl(items: ["1 Player", "2 Players"])
    private let stackView = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Restart intro music when returning from a game, credits, or high scores
        playIntroMusic()
    }

    private func setupUI() {
        titleLabel.text = "SmackMe"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 48)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // Player mode toggle
        playerModeControl.selectedSegmentIndex = 0
        playerModeControl.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        playerModeControl.selectedSegmentTintColor = UIColor(white: 0.3, alpha: 1.0)
        playerModeControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        playerModeControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        playerModeControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playerModeControl)

        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        addMenuButton(title: "Easy", action: { [weak self] in self?.startGame(mode: .threeActionsNormal) })
        addMenuButton(title: "Medium", action: { [weak self] in self?.startGame(mode: .fourActionsNormal) })
        addMenuButton(title: "Hard", action: { [weak self] in self?.startGame(mode: .fourActionsInsane) })
        addMenuButton(title: "Marathon", action: { [weak self] in self?.startGame(mode: .marathon) })
        addMenuButton(title: "High Scores", action: { [weak self] in self?.showHighScores() })
        addMenuButton(title: "Credits", action: { [weak self] in self?.showCredits() })

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            playerModeControl.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            playerModeControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playerModeControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60),
            playerModeControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -60),
            playerModeControl.heightAnchor.constraint(equalToConstant: 44),

            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.topAnchor.constraint(equalTo: playerModeControl.bottomAnchor, constant: 30),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }

    private func addMenuButton(title: String, action: @escaping () -> Void) {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true

        button.addAction(UIAction { _ in action() }, for: .touchUpInside)

        stackView.addArrangedSubview(button)
    }

    private var selectedPlayerCount: Int {
        return playerModeControl.selectedSegmentIndex + 1  // 1 or 2
    }

    private func startGame(mode: GameMode) {
        AudioManager.shared.stopMusic()

        let gameVC = GameViewController(mode: mode, playerCount: selectedPlayerCount)
        gameVC.modalPresentationStyle = .fullScreen
        present(gameVC, animated: true)
    }

    private func showHighScores() {
        let highScoresVC = HighScoresViewController()
        navigationController?.pushViewController(highScoresVC, animated: true)
    }

    private func showCredits() {
        let creditsVC = CreditsViewController()
        creditsVC.modalPresentationStyle = .fullScreen
        present(creditsVC, animated: true)
    }

    private func playIntroMusic() {
        AudioManager.shared.playMusic("introduction.mp3")
    }
}

class HighScoresViewController: UIViewController {
    private let tableView = UITableView()
    private var scores: [HighScore] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black
        title = "High Scores"

        // Nav bar items
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Reset",
            style: .plain,
            target: self,
            action: #selector(resetScores)
        )

        setupTableView()
        loadScores()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Show the nav bar (MainMenu hides it)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    @objc private func resetScores() {
        let alert = UIAlertController(
            title: "Reset Scores",
            message: "Are you sure you want to clear all high scores?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { [weak self] _ in
            HighScoreManager.shared.clearAllScores()
            self?.loadScores()
        })
        present(alert, animated: true)
    }

    private func setupTableView() {
        tableView.backgroundColor = .black
        tableView.separatorColor = .white
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ScoreCell")
        tableView.dataSource = self
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadScores() {
        scores = HighScoreManager.shared.loadScores()
        tableView.reloadData()
    }
}

extension HighScoresViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scores.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScoreCell", for: indexPath)
        let score = scores[indexPath.row]

        cell.backgroundColor = .black
        cell.textLabel?.textColor = .white
        cell.textLabel?.text = "\(indexPath.row + 1). \(score.playerName) - \(score.score) (\(score.mode))"

        return cell
    }
}

class CreditsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        let creditsLabel = UILabel()
        creditsLabel.text = """
        SmackMe

        Rebuilt for 64-bit iOS

        Original Game Assets
        © Fun Mobility

        Rebuilt with Claude Code
        2026
        """
        creditsLabel.numberOfLines = 0
        creditsLabel.textAlignment = .center
        creditsLabel.textColor = .white
        creditsLabel.font = UIFont.systemFont(ofSize: 18)
        creditsLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(creditsLabel)

        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Close", for: .normal)
        closeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addAction(UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        }, for: .touchUpInside)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            creditsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            creditsLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            creditsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            creditsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            closeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            closeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        AudioManager.shared.playMusic("Credits.mp3", loops: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AudioManager.shared.stopMusic()
    }
}
