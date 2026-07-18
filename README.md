# SmackMe

A reboot of the old iOS rhythm game SmackMe (originally released as TwistMe), running on modern 64-bit iPhones.

## About

This started in March 2026 as an experiment with Claude Code, rebuilding the game from scratch in modern Swift since no original source code was available. It's open source now so anyone who remembers the game can help bring it back. Contributions, fixes, and pull requests are welcome.

The game plays but it isn't perfect yet. Check the open issues for what still needs work.

## Just want to play?

You can put the prebuilt app on your iPhone without building anything. Download the latest unsigned IPA from the [Releases](https://github.com/Quinton1110/SmackMe/releases) page, then use one of these tools.

AltStore (stays installed, refreshes itself over Wi-Fi):

1. Install AltServer on your Mac or PC from [altstore.io](https://altstore.io/), then use it to put AltStore on your iPhone.
2. Open AltStore on your iPhone, go to My Apps, tap the plus button, and pick the SmackMe IPA.
3. Sign in with your Apple ID when asked.
4. Wait for it to install, then open SmackMe.
5. Keep AltServer running so AltStore can refresh the app before it expires.

Sideloadly (quick one time install):

1. Install Sideloadly on your Mac or PC from [sideloadly.io](https://sideloadly.io/).
2. Connect your iPhone with a cable and open Sideloadly.
3. Drag the IPA in, enter your Apple ID, and click Start.
4. On your iPhone, open Settings, then General, then VPN and Device Management, and trust your developer profile.
5. Open SmackMe and play.

With a free Apple ID the app stops working after 7 days and has to be reinstalled. A paid Apple Developer account keeps it running for a year.

## How to play

You respond to spoken commands with physical gestures on the phone. The faster the tempo, the harder it gets.

- Smack: tap the screen
- Pinch: pinch gesture
- Shake: shake the device
- Lift: lift the device up
- Freeze: hold the device completely still

Modes:

- 3 Actions, Normal (100 to 220 BPM): Smack, Pinch, Shake
- 4 Actions, Normal (180 to 300 BPM): all five actions
- 4 Actions, Insane (320 to 360 BPM): all five, very fast
- 2 Player: pass and play with a friend

## Building from source

You need a Mac with Xcode 14 or later and an iPhone on iOS 15 or later. Open SmackMeRebuild.xcodeproj, connect your iPhone, pick it as the run destination, and build and run. The first time, you'll have to trust your developer profile on the phone.

It's plain UIKit with Combine, AVFoundation for audio, and CoreMotion for the gesture detection. Targets iOS 15 and up, arm64 only.

## Project layout

```
SmackMeRebuild/
  AppDelegate.swift
  Models/
    GameModels.swift          game data and level config
    GameEngine.swift          core game logic and timing
  Controllers/
    MainMenuViewController.swift
    GameViewController.swift   gameplay screen
  Utilities/
    GestureManager.swift       gesture and motion detection
    AudioManager.swift         sound playback
  Assets.xcassets/             game images
  Sounds/                      audio and music
  Info.plist
```

## About the original

TwistMe, later published as SmackMe, was made by Fun Mobility and released around 2012 for 32-bit iOS. No source was available, so this version was rebuilt by studying the original app's property lists and compiled binary and recreating the mechanics in Swift. All of the original images, sounds, music, and the custom font are kept as they were.

## License

The original game assets (images, sounds, and music) are © Fun Mobility.

The rebuilt source code here is provided for personal and educational use. If you plan to distribute the app, make sure you have the rights to the original assets.
