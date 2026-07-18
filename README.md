# SmackMe - Rebuilt for 64-bit iOS

A faithful recreation of the classic iOS rhythm game "SmackMe" (originally "TwistMe"), rebuilt from scratch for modern 64-bit iOS devices.

## About This Project

This rebuild began in March 2026 as an experiment with Claude Code, recreating the classic accessible game from the ground up in modern Swift. It's now open source so anyone can pitch in and help bring SmackMe back to modern iOS. Contributions, fixes, and pull requests are all welcome - let's bring this classic back together.

## 🕹️ For Those Who Just Want to Play

If you only want to play and have no interest in building anything, you can sideload the prebuilt app straight onto your iPhone:

1. Download the latest SmackMe unsigned IPA from the [Releases](https://github.com/Quinton1110/SmackMe/releases) page.
2. Install a sideloading tool on your computer, such as [AltStore](https://altstore.io/) or [Sideloadly](https://sideloadly.io/).
3. Connect your iPhone, open the tool, and sideload the IPA using your Apple ID.
4. On your iPhone, open Settings, then General, then VPN and Device Management, and trust your developer profile.
5. Launch SmackMe and play.

Note: with a free Apple ID, sideloaded apps keep working for 7 days before they need a refresh. AltStore can refresh automatically over Wi-Fi so it stays installed.

## 🎮 What is SmackMe?

SmackMe is a fast-paced rhythm game where you respond to on-screen commands by performing physical gestures on your iPhone. As the tempo increases, the challenge intensifies!

### Game Actions
- **Smack** - Tap the screen
- **Pinch** - Pinch gesture
- **Shake** - Shake the device
- **Lift** - Lift the device up
- **Freeze** - Hold the device completely still

### Game Modes
1. **3 Actions - Normal** (100-220 BPM) - Smack, Pinch, Shake only
2. **4 Actions - Normal** (180-300 BPM) - All 5 actions
3. **4 Actions - Insane** (320-360 BPM) - Lightning fast!
4. **2 Player Mode** - Pass and play with a friend

## 📂 Project Structure

```
SmackMeRebuild/
├── AppDelegate.swift              # App entry point
├── Models/
│   ├── GameModels.swift          # Game data structures
│   └── GameEngine.swift          # Core game logic
├── Controllers/
│   ├── MainMenuViewController.swift
│   └── GameViewController.swift  # Main gameplay screen
├── Utilities/
│   ├── GestureManager.swift      # Gesture detection
│   └── AudioManager.swift        # Sound playback
├── Assets.xcassets/              # All game images (50+ PNG files)
├── Sounds/                       # All audio files (90+ files)
├── Info.plist                    # App configuration
├── CREATE_PROJECT.md             # Setup instructions
└── README.md                     # This file
```

## 🔧 Technology Stack

- **Language**: Swift 5
- **Frameworks**:
  - UIKit for UI
  - Combine for reactive programming
  - AVFoundation for audio
  - CoreMotion for device motion detection
- **Minimum iOS Version**: iOS 15.0
- **Architecture**: arm64 (64-bit)

## 🚀 Getting Started

### Prerequisites
- macOS with Xcode 14+ installed
- An iPhone running iOS 15.0 or later (for testing)
- Apple Developer account (free account works for 7-day sideloading)

### Setup Instructions

**See [CREATE_PROJECT.md](CREATE_PROJECT.md) for detailed step-by-step instructions.**

Quick summary:
1. Open Xcode and create a new iOS App project
2. Add all the Swift files from this directory
3. Import assets and sounds
4. Configure build settings for 64-bit
5. Build and run!

## 📱 Sideloading to Your iPhone

### Option 1: Direct from Xcode (7 days)
1. Connect your iPhone via USB
2. Select your device in Xcode
3. Build and run (Cmd+R)
4. Trust the developer profile on your iPhone

### Option 2: AltStore (7 days, auto-refresh)
1. Install [AltStore](https://altstore.io/)
2. Export the app as .ipa from Xcode
3. Sideload via AltStore

### Option 3: Developer Account (1 year)
- Sign up for Apple Developer Program ($99/year)
- Apps stay installed for 1 year without refresh

## 🎯 Features Implemented

✅ All original game mechanics
✅ All 4 game modes
✅ Gesture recognition (tap, pinch, shake, lift, freeze)
✅ BPM-based rhythm system (100-360 BPM)
✅ High score tracking
✅ All original audio and visual assets
✅ Modern 64-bit architecture
✅ iOS 15+ compatibility

## 🎨 Assets

All original game assets have been preserved:
- **Images**: 50+ PNG files including robot animations, backgrounds, and UI elements
- **Audio**: 90+ sound effects and music files
  - BPM-specific action sounds (100-360 BPM)
  - Background music tracks
  - Confirmation sounds
  - Game over and success sounds
- **Font**: Original custom font (uni05_53.ttf)

## 📋 Original Game Info

- **Original Name**: TwistMe
- **Published As**: SmackMe
- **Developer**: Fun Mobility
- **Original Release**: ~2012
- **Original Platform**: iOS (32-bit, armv6/armv7)

## 🔨 Rebuilding Details

This project was completely rebuilt from scratch by analyzing the original compiled binary. No source code was available, so everything was recreated by:

1. Extracting and analyzing the game's property lists
2. Examining the compiled binary structure
3. Reverse-engineering the game mechanics
4. Recreating all code in modern Swift
5. Implementing modern iOS frameworks and patterns

## 🐛 Known Issues / Future Improvements

- [ ] Add haptic feedback for actions
- [ ] Add Game Center integration for leaderboards
- [ ] Add tutorial mode for new players
- [ ] Improve gesture detection thresholds
- [ ] Add accessibility features
- [ ] Add dark mode support

## 📝 License

The original game assets (images, sounds, music) are © Fun Mobility.

This rebuilt source code is provided for educational purposes and personal use only. If you plan to distribute this app, ensure you have appropriate rights to the original assets.

## 🙏 Credits

- **Original Game**: Fun Mobility
- **Rebuild**: Claude Code (2026)
- **Purpose**: Preserving classic iOS gaming history and making it playable on modern devices

---

Enjoy playing SmackMe on your modern iPhone! 🎮🤖
