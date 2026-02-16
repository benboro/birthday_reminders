# Xcode Project Setup

This project uses XcodeGen to generate the `.xcodeproj` from `project.yml`. The `.xcodeproj` is gitignored and must be regenerated on each new machine or MacinCloud session.

## Getting Started

1. Clone the repository:
   ```bash
   git clone <your-repo-url>
   cd birthday_reminders
   ```

2. Generate the Xcode project (see options below)

3. Open the generated project:
   ```bash
   open BirthdayReminders.xcodeproj
   ```

4. In Xcode, select each target and configure **Signing & Capabilities**:
   - Check **Automatically manage signing**
   - Select your team (Personal Team for free Apple ID)

5. Verify the following are set (these come from `project.yml` but worth confirming):
   - Signing & Capabilities > App Groups contains `group.com.birthdayreminders`
   - Signing & Capabilities > Data Protection is set to "Complete Protection"
   - General > Minimum Deployments is iOS 18.0
   - Build Settings > Swift Language Version is 6.0

## XcodeGen: Option A — Homebrew

If you have Homebrew and sufficient permissions:

```bash
brew install xcodegen
xcodegen generate
```

## XcodeGen: Option B — Direct Binary Download

If you don't have permissions to install via Homebrew (common on MacinCloud):

1. Download the latest release zip from https://github.com/yonaskolb/XcodeGen/releases
2. Unzip it:
   ```bash
   cd /tmp
   unzip ~/Downloads/xcodegen.zip
   ```
3. Run the binary directly from the project root:
   ```bash
   cd /path/to/birthday_reminders
   /tmp/xcodegen/bin/xcodegen generate
   ```

## Option C: Manual Xcode Setup

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
