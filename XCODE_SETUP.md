# Xcode Project Setup (MacinCloud)

This project uses XcodeGen to generate the .xcodeproj file. Run these steps once on MacinCloud.

## Option A: XcodeGen (Recommended)

1. Install XcodeGen if not already available:
   ```bash
   brew install xcodegen
   ```

2. From the project root, generate the Xcode project:
   ```bash
   xcodegen generate
   ```

3. Open the generated project:
   ```bash
   open BirthdayReminders.xcodeproj
   ```

4. In Xcode, select the BirthdayReminders target and verify:
   - Signing & Capabilities > App Groups contains `group.com.birthdayreminders`
   - Signing & Capabilities > Data Protection is set to "Complete Protection"
   - General > Minimum Deployments is iOS 18.0
   - Build Settings > Swift Language Version is 6.0

## Option B: Manual Xcode Setup

1. Open Xcode > File > New > Project > App
   - Product Name: BirthdayReminders
   - Organization Identifier: com
   - Interface: SwiftUI
   - Storage: SwiftData
   - Language: Swift

2. Delete the auto-generated ContentView.swift and Item.swift files

3. Drag the BirthdayReminders/ folder contents into the Xcode project navigator,
   replacing any auto-generated files. Keep "Copy items if needed" unchecked
   if the files are already in the right location.

4. Add Capabilities:
   - Target > Signing & Capabilities > + Capability > App Groups
     - Add: group.com.birthdayreminders
   - Target > Signing & Capabilities > + Capability > Data Protection
     - Select: Complete Protection

5. Set the Info.plist:
   - Target > Build Settings > search "Info.plist" > set to BirthdayReminders/Info.plist

6. Set the Entitlements:
   - Target > Build Settings > search "Entitlements" > set to BirthdayReminders/BirthdayReminders.entitlements

7. Set Deployment Target:
   - Target > General > Minimum Deployments > iOS 18.0

8. Verify no third-party SPM packages are added (Build Phases > Link Binary).
