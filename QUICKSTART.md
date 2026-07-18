# SmackMe - Quick Start Guide

Your SmackMe game has been rebuilt and is ready to deploy! Here's what to do next.

## ✅ What's Been Done

All the hard work is complete:
- ✅ **7 Swift source files** - Complete game logic recreated
- ✅ **50 PNG images** - All game assets copied
- ✅ **90 audio files** - All sounds and music ready
- ✅ **Info.plist** - App configuration set for 64-bit
- ✅ **Documentation** - Full setup instructions provided

## 🚀 Next Steps (15-20 minutes)

### Step 1: Verify Files
```bash
cd /Users/quinton/code/SmackMe/SmackMeRebuild
./verify_files.sh
```
You should see all green checkmarks!

### Step 2: Create Xcode Project

**Open Xcode** and create a new project:

1. File → New → Project
2. Select "iOS" → "App"
3. Settings:
   - Product Name: **SmackMe**
   - Team: Select your Apple ID
   - Organization ID: `com.yourname.smackme`
   - Interface: **Storyboard**
   - Language: **Swift**
4. Save to: `/Users/quinton/code/SmackMe/SmackMeRebuild`

### Step 3: Clean Up Default Files

Delete these auto-generated files:
- ❌ ViewController.swift
- ❌ Main.storyboard
- ❌ SceneDelegate.swift (if present)

### Step 4: Add Source Files

Drag the **SmackMeRebuild** folder into your project:
- Check "Copy items if needed"
- Choose "Create groups"
- Add to target: SmackMe

### Step 5: Configure Project

1. **Build Settings**:
   - Click project name → General tab
   - Set minimum iOS to **15.0**
   - Clear the "Main Interface" field

2. **Replace Info.plist**:
   - Use the Info.plist from the SmackMeRebuild folder

3. **Add Frameworks** (should be automatic):
   - AVFoundation
   - CoreMotion
   - Combine

### Step 6: Build & Run

1. Connect your iPhone (or use Simulator)
2. Select your device
3. Press **Cmd+R** to build and run

If using a real iPhone:
- Go to Settings → General → Device Management
- Trust your developer certificate

## 🎮 Testing the Game

Once running, test all features:

1. **Main Menu** - Should show 4 game modes
2. **Start a Game** - Try "3 Actions - Normal"
3. **Test Gestures**:
   - Tap screen when "SMACK" appears
   - Pinch when "PINCH" appears
   - Shake when "SHAKE" appears
   - (4-action modes add LIFT and FREEZE)
4. **Audio** - Music and sound effects should play
5. **High Scores** - Try setting a high score

## 📱 Sideloading for Permanent Use

### Free Method (7 days, needs refresh)
Already done if you built from Xcode!

### AltStore Method (7 days, auto-refresh)
1. Install [AltStore](https://altstore.io/)
2. Export .ipa from Xcode (Product → Archive → Export)
3. Install via AltStore

### Paid Developer ($99/year)
Apps last 1 year without refresh

## 🐛 Troubleshooting

**"No such module" errors**
- Check that frameworks are linked in Build Phases

**Images/sounds not loading**
- Verify assets are added to app target
- Check file names match exactly (case-sensitive)

**Gestures not working**
- Test on a real device (not simulator) for shake/lift/freeze
- Check Settings → Privacy → Motion & Fitness

**Build fails**
- Clean build folder: Product → Clean Build Folder
- Restart Xcode

## 📂 Project Location

```
/Users/quinton/code/SmackMe/SmackMeRebuild/
├── SmackMeRebuild/          ← Add this folder to Xcode
│   ├── AppDelegate.swift
│   ├── Models/
│   ├── Controllers/
│   ├── Utilities/
│   ├── Assets.xcassets/
│   ├── Sounds/
│   └── Info.plist
├── README.md                ← Full documentation
├── CREATE_PROJECT.md        ← Detailed setup guide
└── QUICKSTART.md           ← This file
```

## 🎉 Success!

Once built, you'll have SmackMe running on your modern iPhone!

The game features:
- Rhythm-based gameplay (100-360 BPM)
- 5 gesture types
- 4 game modes
- High score tracking
- All original graphics and sounds

Enjoy your retro gaming experience! 🤖🎮
