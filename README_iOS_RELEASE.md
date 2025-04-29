# ESP32 LED Controller - iOS Release Guide

## Problem
When running the app through Xcode in Debug mode, the app works fine on the iPhone. However, when closing the app and trying to open it again directly on the phone (without Xcode), it doesn't work. This is because Debug builds are not meant for standalone use and often have dependencies on the development environment.

## Solution
To make the app work independently on your iPhone, you need to build it in Release mode. This guide explains how to do that.

## Changes Made
The project has been updated to use Release configuration for all build actions in the Xcode scheme:
- LaunchAction (when you run the app from Xcode)
- TestAction (when you run tests)
- AnalyzeAction (when you analyze the code)
- ArchiveAction (when you archive the app for distribution)

## How to Build and Install the App

### Method 1: Using Xcode
1. Open the project in Xcode by opening the `ios/Runner.xcworkspace` file
2. Connect your iPhone to your Mac
3. Select your iPhone as the target device in Xcode
4. Click the Run button (▶️) in Xcode
5. The app will be built in Release mode and installed on your iPhone
6. You can now disconnect your iPhone and use the app independently

### Method 2: Using Flutter CLI
1. Connect your iPhone to your Mac
2. Open Terminal
3. Navigate to the project directory
4. Run the following command:
   ```
   flutter build ios --release
   flutter install
   ```
5. The app will be built in Release mode and installed on your iPhone
6. You can now disconnect your iPhone and use the app independently

## Troubleshooting

### App Still Doesn't Work Independently
If the app still doesn't work independently after following the steps above, it might be due to one of the following issues:

1. **Provisioning Profile**: Make sure your app is signed with a valid provisioning profile. In Xcode, go to the "Signing & Capabilities" tab and check that:
   - "Automatically manage signing" is checked
   - Your Apple ID is selected
   - A valid provisioning profile is being used

2. **App Trust**: On your iPhone, you might need to trust the developer certificate:
   - Go to Settings > General > Device Management
   - Find your developer certificate and tap "Trust"

3. **Background Modes**: If your app needs to run in the background (e.g., to maintain Bluetooth connections), make sure the appropriate background modes are enabled in the "Signing & Capabilities" tab in Xcode.

### App Crashes on Launch
If the app crashes when launched directly on the iPhone, it might be due to:

1. **Missing Permissions**: Make sure all required permissions are properly configured in the Info.plist file
2. **Release Mode Issues**: Some code might work in Debug mode but not in Release mode. Check for any debug-only code or dependencies

## Additional Resources
- [Flutter iOS Release Documentation](https://flutter.dev/docs/deployment/ios)
- [Xcode Code Signing Guide](https://developer.apple.com/documentation/xcode/signing-a-mac-app)