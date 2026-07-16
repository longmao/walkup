# Walk Up — Xcode Setup Guide

> **You** are reading this on the machine where you'll build the app. The Swift sources are here in `Sources/`, Info.plist in `Resources/`, assets in `Assets.xcassets/`. Xcode needs to generate the `.xcodeproj` (this machine doesn't have Xcode — you'll do that step).

---

## 1. Open Xcode on your Mac

Requires **Xcode 15+** (Swift 5.9, iOS 17 deployment target).

```bash
# Verify
xcodebuild -version   # should print 15.0 or later
```

If Xcode isn't installed: `xcode-select --install` won't give you full Xcode — download from App Store or https://developer.apple.com/download/.

---

## 2. Create the Xcode project (5 minutes, one time)

1. **File → New → Project** (⇧⌘N)
2. **iOS → App** → Next
3. Fill in:
   - Product Name: `StepUp`
   - Team: select your team (the one matching the Apple ID you'll use)
   - Organization Identifier: `walkup` (will become bundle id `com.walkup.StepUp`)
   - Bundle Identifier: auto-fills as `com.walkup.StepUp`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None**
   - **Uncheck** "Include Tests" (faster)
4. Save to **`/Users/vincent/work/ai-fleet-projects/stepup/`** — same directory as this README. **Do NOT check "Create Git repository"** (separate concern).
5. After Xcode creates `StepUp.xcodeproj`, **close Xcode** before the next step.

---

## 3. Replace generated files with the curated ones

The Xcode template generates a `StepUp/` folder with `StepUpApp.swift`, `ContentView.swift`, `Assets.xcassets`, `Preview Content/`. **Delete those** and replace with the files in this repo.

From a terminal in `/Users/vincent/work/ai-fleet-projects/stepup/`:

```bash
# Delete Xcode-generated sources
rm -rf StepUp/ StepUpTests/

# Copy our curated sources in
cp -r Sources StepUp/
cp -r Assets.xcassets StepUp/
mkdir -p StepUp/Preview\ Content
cp Resources/Info.plist StepUp/Info.plist

# Add to Xcode (drag StepUp/ into the project navigator, "Create folder references")
```

Then in Xcode:

1. **Right-click the project root in the navigator → Add Files to "StepUp"...**
2. Select the `StepUp/` folder → Add
3. When prompted, choose **Create folder references** (NOT groups — folder references preserve structure)
4. Repeat for `Preview Content/` (mark as folder reference too)

---

## 4. Set the project settings (one-time)

In Xcode, click the project → **StepUp target → Build Settings**:

- Search `iOS Deployment Target` → set to **17.0**
- Search `Bundle Identifier` → confirm `com.walkup.StepUp`
- Search `Marketing Version` → `1.0.0`
- Search `Current Project Version` → `1`
- Search `Development Language` → `English`

**Signing & Capabilities tab**:
- **Automatically manage signing**: ✅ checked
- **Team**: select your team
- **Bundle Identifier**: `com.walkup.StepUp`

Then **+ Capability** button:
- Add **Background Modes**
- Check **Audio, AirPlay, and Picture in Picture**

---

## 5. Verify build

```bash
# Build for simulator
xcodebuild -project StepUp.xcodeproj -scheme StepUp -destination 'platform=iOS Simulator,name=iPhone 15' build
```

Or just press **⌘R** in Xcode with a simulator selected.

**Test the alarm flow**:
1. Tap "Test alarm now"
2. Walk around the room with the simulator... wait, **CMPedometer doesn't work in simulator**. You need a real device.

For real-device testing, plug in your iPhone, select it as destination, build & run, then walk to test.

---

## 6. App Store Connect setup

1. **App Store Connect** → https://appstoreconnect.apple.com → My Apps → **+** → New App
2. Fill:
   - Platform: iOS
   - Name: **Walk Up — Free Step Alarm** (≤30 chars)
   - Primary Language: English (U.S.)
   - Bundle ID: select `com.walkup.StepUp`
   - SKU: `walkup-001`
   - User Access: Full Access
3. In the new app, fill:
   - **Pricing and Availability**: Free, all countries
   - **App Privacy**: fill the questionnaire (no data collected — since CMPedometer data never leaves the device)
   - **Category**: Primary **Health & Fitness**, Secondary **Productivity**

4. **App Information**:
   - Privacy Policy URL: **https://walkup.app/privacy** (you'll deploy this — see step 7)
   - Subtitle: **Walk to dismiss. No subscription.**

---

## 7. Deploy the privacy policy

The app references `https://walkup.app/privacy`. Pick any host — easiest is **GitHub Pages**:

```bash
# Create a tiny repo for this
mkdir walkup-privacy && cd walkup-privacy
git init
# Copy Resources/privacy-policy.html as index.html
cp /Users/vincent/work/ai-fleet-projects/stepup/Resources/privacy-policy.html index.html
git add . && git commit -m "privacy policy v1"
# Create repo on github.com (longmao account or personal), push, enable Pages on main branch
gh repo create walkup-privacy --public --source=. --remote=origin --push
# Then enable Pages in repo Settings → Pages → Source: main / root
# Your URL will be https://<username>.github.io/walkup-privacy/
```

Update the bundle's Info.plist `CFBundleURLTypes` and `AboutView` link to match your actual deployed URL.

---

## 8. App Store metadata (text ready in `09-positioning.md`)

From `ai-fleet/docs/decisions/step-alarm/09-positioning.md` §⑦:
- Description (paste into App Store Connect):
  ```
  Walk Up is the alarm that makes you actually get up.
  
  Set your wake-up time and a step goal (10-100). When the alarm fires, it won't stop until you've walked the required number of steps. No more hitting snooze.
  
  • Free forever — no subscription, no ads, no in-app purchases
  • Reliable — uses your phone's motion sensor, not the camera, so it works in any light
  • Private — step counting only happens while the alarm is ringing. Steps never leave your device.
  
  Built for people who want to start the day on their feet, not in bed.
  ```

- Keywords: `alarm, walk, steps, fitness, free, wake, pedometer, no-subscription`
- Support URL: same as privacy policy URL (different page if you want)

---

## 9. Submit for review

In Xcode: **Product → Archive** (after setting scheme to "Any iOS Device").

When the Organizer opens:
1. Select the archive → **Distribute App**
2. **App Store Connect** → **Upload**
3. Wait for "Uploaded" status (5-30 min)
4. Back to App Store Connect → My Apps → Walk Up → **+ Version** → fill "What's New" (first release = "First release. Free forever.")
5. **Review Notes** (paste):
   ```
   Walk Up is a single-purpose alarm that requires the user to walk N steps to dismiss.
   Uses CMPedometer (not HealthKit) for step counting. No data leaves the device.
   No third-party SDKs. No ads, no IAP.
   Test by tapping "Test alarm now" on the Alarm tab.
   Background audio mode is used to keep alarm sound playing.
   ```
6. Attach the **1024x1024 icon** (drop into `Assets.xcassets/AppIcon.appiconset/`)
7. Attach the **3 screenshots** (from a real device or simulator running iOS 17+, 6.7" / 6.5" / 5.5" sizes)
8. **Submit for Review**

Expected review time: **24-48 hours** (per Apple's current SLAs).

---

## 10. Post-approval — the 7-day gate

From `09-positioning.md` §⑧. Watch for:
- ≥ 50 downloads in 7 days
- ≤ 15% 1-star
- ≥ 10 comments mentioning "free"
- ≥ 3 mentions of telling friends

If ≥ 6/8 criteria met → v1.1 (AlarmKit iOS 26 + watchOS complications).
If 4-5 → tighten UX + ASO, don't pivot.
If ≤ 3 → pivot mechanic, keep "free + reliable" wedge.

---

## What you actually have in this directory

```
stepup/
├── project.yml              # XcodeGen spec (for future use when you install xcodegen)
├── README.md                # this file
├── Sources/                 # 8 Swift files (the app)
├── Assets.xcassets/         # AppIcon + AccentColor placeholders (drop in your icon)
├── Resources/
│   ├── Info.plist           # iOS bundle config (privacy string + background audio)
│   └── privacy-policy.html  # deploy to walkup.app/privacy
└── (StepUp.xcodeproj)       # you'll generate this in step 2
```

The **8 Swift files** are complete and self-contained. CMPedometer for steps, UNUserNotificationCenter for scheduling, AVAudioPlayer for the alarm tone, full alarm-ringing UI with progress ring + emergency long-press fallback for compliance with App Store Guideline 5.1.1(iv).

---

## TL;DR for the impatient

```bash
# 1. Open Xcode, create new iOS App project "StepUp" with bundle id com.walkup.StepUp
# 2. Delete the Xcode-generated StepUp/ folder
# 3. Drag Sources/, Assets.xcassets/, Resources/Info.plist into the project
# 4. Set deployment target to 17.0, add Background Modes → Audio capability
# 5. Press ⌘R to build, ⌘B to build, Product → Archive to submit
```

That's the entire app. Source files are ~600 lines of Swift total — readable in 20 minutes, ships in a day.