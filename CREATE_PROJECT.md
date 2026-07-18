# SmackMe - Creating the Xcode Project

All the source code and assets have been created! Now you need to create the Xcode project and add these files.

## Option 1: Manual Setup in Xcode (Recommended)

1. **Open Xcode**

2. **Create New Project**
   - File → New → Project
   - Choose "iOS" → "App"
   - Click "Next"

3. **Project Settings**
   - Product Name: `SmackMe`
   - Team: Select your Apple Developer team (or leave as "None" for now)
   - Organization Identifier: `com.yourname.smackme` (or similar)
   - Interface: **Storyboard** (we'll replace this with code)
   - Language: **Swift**
   - Uncheck "Use Core Data"
   - Uncheck "Include Tests"
   - Click "Next"

4. **Save Location**
   - Save to: `/Users/quinton/code/SmackMe/SmackMeRebuild`
   - Important: Uncheck "Create Git repository" if you don't need it
   - Click "Create"

5. **Delete Default Files**
   - In the project navigator, delete:
     - `ViewController.swift`
     - `Main.storyboard`
     - `SceneDelegate.swift` (if present)
   - Move to Trash

6. **Add Source Files**
   - Drag the `SmackMeRebuild` folder (the one containing all the .swift files) into your project
   - When prompted:
     - ✅ "Copy items if needed"
     - ✅ "Create groups"
     - ✅ Add to target: SmackMe
   - Click "Finish"

7. **Add Assets**
   - Select `Assets.xcassets` in the project navigator
   - Drag all the .png files from `SmackMeRebuild/SmackMeRebuild/Assets.xcassets/` into the asset catalog

8. **Add Sounds**
   - Drag the `Sounds` folder into your project
   - When prompted:
     - ✅ "Copy items if needed"
     - ✅ "Create folder references"
     - ✅ Add to target: SmackMe
   - Click "Finish"

9. **Update Project Settings**
   - Click on the project name in the navigator
   - Select the "SmackMe" target
   - Go to "General" tab:
     - Deployment Info:
       - iOS Deployment Target: **iOS 15.0** (or higher)
       - iPhone Orientation: **Portrait** only
   - Go to "Build Settings" tab:
     - Set "Architectures" to "Standard architectures (arm64)"
     - Search for "Main" and clear the "Main Interface" field (delete "Main")

10. **Update Info.plist**
    - Replace the auto-generated Info.plist with the one from `SmackMeRebuild/SmackMeRebuild/Info.plist`

11. **Add Required Frameworks**
    - Select your target
    - Go to "Frameworks, Libraries, and Embedded Content"
    - Click the "+" button and add:
      - AVFoundation.framework
      - CoreMotion.framework
      - Combine.framework (should be included by default)

12. **Build and Run**
    - Connect your iPhone or use the Simulator
    - Select your device from the device dropdown
    - Click the "Run" button (▶) or press Cmd+R

## Option 2: Use Automated Script (Coming Soon)

We can create an automated setup script, but manual setup is most reliable for now.

## Troubleshooting

### Build Errors
- Make sure all .swift files are added to the target
- Check that all assets are properly imported
- Verify that the deployment target is iOS 15.0 or higher

### Missing Images/Sounds
- Check that all assets are in the asset catalog
- Verify that sound files have the correct file extensions in code

### Sideloading to iPhone

1. **Free Apple ID Method** (7-day signing):
   - Connect iPhone via USB
   - Select your iPhone as the destination
   - In "Signing & Capabilities", select your Team
   - Click Run
   - On iPhone: Settings → General → VPN & Device Management → Trust your developer account

2. **AltStore Method** (7-day, auto-refresh):
   - Build the app in Xcode
   - Export as .ipa file
   - Install AltStore on your iPhone
   - Use AltStore to sideload the .ipa

3. **Paid Apple Developer Account** (1-year signing):
   - Sign up for Apple Developer Program ($99/year)
   - Use your developer account in Xcode
   - App will stay installed for 1 year

## Next Steps

Once the project builds successfully:
1. Test all gestures (tap, pinch, shake, lift, freeze)
2. Verify audio playback
3. Test different game modes
4. Save high scores

Enjoy playing SmackMe on your modern 64-bit iPhone! 🎮
