//
//  GameModels.swift
//  SmackMe
//
//  Rebuilt for 64-bit iOS
//

import Foundation
import UIKit

// MARK: - Game Action Types
enum GameAction: String, CaseIterable {
    case smack = "Smack"
    case pinch = "Pinch"
    case shake = "Shake"
    case lift = "Lift"
    case freeze = "Freeze"

    var commandImage: String {
        switch self {
        case .smack: return "command_smackme.png"
        case .pinch: return "command_pinchme.png"
        case .shake: return "command_shakeme.png"
        case .lift: return "command_liftme.png"
        case .freeze: return "command_freezeme.png"
        }
    }

    func animationImages(for bpm: Int) -> [String] {
        switch self {
        case .smack:
            return ["smackme_robot_smackme01_trans.png", "smackme_robot_smackme02_trans.png"]
        case .pinch:
            return ["smackme_robot_pinchme01_trans.png", "smackme_robot_pinchme02_trans.png"]
        case .shake:
            return ["smackme_robot_shakeme01_trans.png", "smackme_robot_shakeme02_trans.png"]
        case .lift:
            return ["smackme_robot_liftme01_trans.png", "smackme_robot_liftme02_trans.png"]
        case .freeze:
            return ["smackme_robot_freeze01_trans.png", "smackme_robot_freeze02_trans.png"]
        }
    }

    func soundKey(for bpm: Int) -> String {
        return "\(bpm)\(self.rawValue)"
    }

    var voiceOverText: String {
        switch self {
        case .smack:  return "Smack me!"
        case .pinch:  return "Pinch me!"
        case .shake:  return "Shake me!"
        case .lift:   return "Lift me!"
        case .freeze: return "Freeze!"
        }
    }

    /// Each action has a specific confirm sound (from original AppProperties.plist).
    /// The plist cycles [confirm1, confirm2, confirm3] across the 5 actions.
    var confirmSound: String {
        switch self {
        case .pinch:  return "confirm1.wav"
        case .smack:  return "confirm2.wav"
        case .shake:  return "confirm3.wav"
        case .lift:   return "confirm1.wav"
        case .freeze: return "confirm2.wav"
        }
    }
}

// MARK: - Level Configuration
struct Level {
    let bpm: Int
    let music: String
    let backgroundImage: String
    let readyImage: String
    let actionsRequired: Int

    var beatInterval: TimeInterval {
        return 60.0 / Double(bpm)
    }
}

// MARK: - Game Mode (difficulty)
enum GameMode: String {
    case threeActionsNormal = "3 Actions - Normal"
    case fourActionsNormal = "4 Actions - Normal"
    case fourActionsInsane = "4 Actions - Insane"
    case marathon = "Marathon"

    var name: String {
        return self.rawValue
    }

    var displayName: String {
        switch self {
        case .threeActionsNormal: return "Easy"
        case .fourActionsNormal:  return "Medium"
        case .fourActionsInsane:  return "Hard"
        case .marathon:           return "Marathon"
        }
    }

    var actions: [GameAction] {
        switch self {
        case .threeActionsNormal:
            return [.pinch, .smack, .shake]
        case .fourActionsNormal, .fourActionsInsane, .marathon:
            return [.pinch, .smack, .shake, .lift, .freeze]
        }
    }

    // Level structure from original AppProperties.plist
    var levels: [Level] {
        let backgrounds = [
            "smackme_robot_bg_starburst.png",
            "smackme_robot_bg_robotpattern.png",
            "smackme_robot_bg_nuclear.png",
            "smackme_robot_bg_biohazard.png",
            "smackme_robot_bg_sprokets.png",
            "smackme_robot_bg_circles.png",
            "smackme_robot_bg_07_pulse&ripples.png"
        ]
        let readyImages = [
            "smackme_robot_round01_trans.png",
            "smackme_robot_round02_trans.png",
            "smackme_robot_round03_trans.png",
            "smackme_robot_round04_trans.png"
        ]

        let bpms: [Int]
        let actions: [Int]

        switch self {
        case .threeActionsNormal:
            // 6 levels: 100–220
            bpms =    [100, 140, 160, 180, 200, 220]
            actions = [  5,  10,  13,  15,  17,  22]
        case .fourActionsNormal:
            // 7 levels: 180–300
            bpms =    [180, 200, 220, 240, 260, 280, 300]
            actions = [ 16,  18,  20,  22,  22,  24,  28]
        case .fourActionsInsane:
            // 7 levels: 240–360
            bpms =    [240, 260, 280, 300, 320, 340, 360]
            actions = [ 20,  26,  28,  30,  30,  32,  34]
        case .marathon:
            // 13 levels: every BPM from Easy through Hard, each doubled in length
            bpms =    [100, 140, 160, 180, 200, 220, 240, 260, 280, 300, 320, 340, 360]
            actions = [ 10,  20,  26,  32,  36,  40,  40,  52,  56,  56,  60,  64,  68]
        }

        return zip(bpms, actions).enumerated().map { i, pair in
            Level(bpm: pair.0, music: "\(pair.0)Music.wav",
                  backgroundImage: backgrounds[i % backgrounds.count],
                  readyImage: readyImages[i % readyImages.count],
                  actionsRequired: pair.1)
        }
    }
}

// MARK: - High Score
struct HighScore: Codable {
    let playerName: String
    let score: Int
    let mode: String
    let date: Date
}

class HighScoreManager {
    static let shared = HighScoreManager()
    private let fileName = "highScores.json"

    private var fileURL: URL {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentDirectory.appendingPathComponent(fileName)
    }

    func saveScore(_ score: HighScore) {
        var scores = loadScores()
        scores.append(score)
        scores.sort { $0.score > $1.score }

        if let data = try? JSONEncoder().encode(scores) {
            try? data.write(to: fileURL)
        }
    }

    func loadScores() -> [HighScore] {
        guard let data = try? Data(contentsOf: fileURL),
              let scores = try? JSONDecoder().decode([HighScore].self, from: data) else {
            return []
        }
        return scores
    }

    func getTopScores(for mode: GameMode, limit: Int = 10) -> [HighScore] {
        let allScores = loadScores()
        let modeScores = allScores.filter { $0.mode == mode.rawValue }
        return Array(modeScores.prefix(limit))
    }

    func clearAllScores() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
