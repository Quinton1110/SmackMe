//
//  AudioManager.swift
//  SmackMe
//
//  Handles all audio playback
//

import AVFoundation
import Foundation

final class AudioManager: NSObject, AVAudioPlayerDelegate {
    static let shared = AudioManager()

    private var musicPlayer: AVAudioPlayer?
    private var actionCuePlayer: AVAudioPlayer?
    private var feedbackPlayer: AVAudioPlayer?

    /// Completion handler called when the current feedback sound finishes playing.
    private var feedbackCompletion: (() -> Void)?

    private override init() {
        super.init()
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    private func findAudioURL(for fileName: String) -> URL? {
        let supportedExtensions = ["wav", "mp3", "m4a", "aac", "caf"]

        // Try to split filename into name + extension
        for ext in supportedExtensions {
            if fileName.lowercased().hasSuffix(".\(ext)") {
                let name = String(fileName.dropLast(ext.count + 1))
                if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                    return url
                }
            }
        }

        // No extension match - try the filename as-is with each extension
        for ext in supportedExtensions {
            if let url = Bundle.main.url(forResource: fileName, withExtension: ext) {
                return url
            }
        }

        return nil
    }

    // MARK: - AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if player === feedbackPlayer {
            let completion = feedbackCompletion
            feedbackCompletion = nil
            completion?()
        }
    }

    // MARK: - Background Music (looping level music, or one-shot high score music)

    func playMusic(_ musicName: String, loops: Bool = true) {
        stopMusic()

        print("[AudioManager] playMusic requested: '\(musicName)' loops=\(loops)")

        guard let url = findAudioURL(for: musicName) else {
            print("[AudioManager] Music file NOT FOUND: \(musicName)")
            return
        }

        print("[AudioManager] playMusic found URL: \(url.lastPathComponent)")

        do {
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.numberOfLoops = loops ? -1 : 0
            musicPlayer?.prepareToPlay() // Pre-buffer to minimize startup latency
            musicPlayer?.play()
        } catch {
            print("Failed to play music \(musicName): \(error)")
        }
    }

    /// Current playback position in the music track (accounts for looping).
    /// Used by the game engine to snap actions to beat boundaries.
    var musicCurrentTime: TimeInterval {
        return musicPlayer?.currentTime ?? 0
    }

    func stopMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
    }

    /// Stops ALL audio: music, action cue, and feedback (including pending
    /// completion chains). Use when leaving the game screen to prevent
    /// stale completion handlers from starting music after dismissal.
    func stopAll() {
        musicPlayer?.stop()
        musicPlayer = nil
        actionCuePlayer?.stop()
        actionCuePlayer = nil
        feedbackPlayer?.stop()
        feedbackPlayer = nil
        feedbackCompletion = nil
    }

    // MARK: - Action Cue (robot voice: "Smack me!", etc.) - one at a time

    /// Play the BPM-matched cue file at its recorded speed.
    func playActionCue(_ soundName: String) {
        actionCuePlayer?.stop()
        actionCuePlayer = nil

        guard let url = findAudioURL(for: soundName) else {
            print("[AudioManager] Action cue NOT FOUND: \(soundName)")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            actionCuePlayer = player
            player.play()
        } catch {
            print("Failed to play action cue \(soundName): \(error)")
        }
    }

    /// Duration of the currently loaded action cue (seconds, natural speed).
    var actionCueDuration: TimeInterval {
        return actionCuePlayer?.duration ?? 0
    }

    func stopActionCue() {
        actionCuePlayer?.stop()
        actionCuePlayer = nil
    }

    // MARK: - Feedback & SFX (confirm, fail, interlude, newhighscore, etc.)

    /// Play a sound effect. Optionally provide a completion handler that fires
    /// when the sound finishes playing (used to chain sounds properly).
    func playSound(_ soundName: String, completion: (() -> Void)? = nil) {
        feedbackPlayer?.stop()
        feedbackCompletion = nil

        guard let url = findAudioURL(for: soundName) else {
            print("Sound file not found: \(soundName)")
            completion?()
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            feedbackPlayer = player
            player.delegate = self
            feedbackCompletion = completion
            player.play()
        } catch {
            print("Failed to play sound \(soundName): \(error)")
            completion?()
        }
    }

    // MARK: - Pause / Resume

    func pauseMusic() {
        musicPlayer?.pause()
    }

    func resumeMusic() {
        musicPlayer?.play()
    }

    // MARK: - Volume Control

    func setMusicVolume(_ volume: Float) {
        musicPlayer?.volume = volume
    }
}
