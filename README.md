# Рус — Learn Russian or Bulgarian in 6 Months

A native SwiftUI app (iPhone + Mac via Catalyst) that teaches **Russian or Bulgarian**
(switchable in Settings) over a structured 26-week curriculum, driven by hourly
notifications: **study prompts in the morning, quiz prompts in the afternoon**, with
spaced-repetition review. Progress, streaks, and reviews are tracked separately per language.

## Features
- **26-week curriculum** (alphabet → A2): greetings, all six cases, verb tenses & aspect,
  motion verbs. Bundled as JSON in `Rus/Resources/Curriculum/`.
- **Hourly reminders** — study 09:00–12:00, quizzes 12:00–20:00 (configurable in Settings).
  Notifications deep-link straight into Study or Test mode.
- **Study mode** — flashcards, grammar explanations, reading passages, ru-RU text-to-speech.
- **Test mode** — 4 question types (RU→EN, EN→RU, listening, type-the-word) graded into an
  SM-2 spaced-repetition engine, so past words resurface when due.
- **Progress** — streaks, per-week completion, quiz accuracy.

## Requirements
- Xcode 16+ (developed on Xcode 26.6), iOS 17+.
- [XcodeGen](https://github.com/yonyz/XcodeGen) (`brew install xcodegen`) — the `.xcodeproj`
  is generated from `project.yml` and is not checked in.

## Build & run

```sh
# Generate the Xcode project (re-run whenever files are added/removed)
xcodegen generate

# Run the unit tests (validates all 26 curriculum weeks + SM-2 math)
xcodebuild -project Rus.xcodeproj -scheme Rus \
  -destination 'platform=iOS Simulator,name=iPhone 17' test

# Build & run in the iOS Simulator
open Rus.xcodeproj   # then ⌘R in Xcode
```

### On your iPhone (free signing)
1. `xcodegen generate && open Rus.xcodeproj`
2. Select the **Rus** target → **Signing & Capabilities** → pick your personal Apple ID team.
3. Plug in your iPhone, choose it as the run destination, press **⌘R**.
4. On first launch, tap **Turn on notifications**.
   > Free provisioning expires after 7 days — re-run from Xcode to refresh it.

### On your Mac (Catalyst)
Easiest: run **`./install-mac.sh`** — it builds, ad-hoc signs, and installs
`/Applications/Rus.app` (double-clickable, no expiry, no Xcode UI). Re-run it to update.

Or from Xcode: choose the **My Mac (Mac Catalyst)** run destination and press ⌘R. Note:
macOS only delivers the hourly reminders while the Mac is awake.

### Switching language
Settings → **Language** → Russian / Bulgarian. The curriculum, voice, titles, and progress
all switch. Each language keeps its own start date and streak.

## Project layout
```
project.yml                     XcodeGen spec (iOS app + Mac Catalyst + test target)
Rus/
  RusApp.swift                  App entry, SwiftData container, background refresh
  Models/                       Curriculum (Codable) + SwiftData progress/SRS models
  Services/                     CurriculumStore, SRSEngine, QuizEngine, SpeechService,
                                NotificationManager, AppRouter
  Features/                     Today, Study, Test, Progress, Settings (SwiftUI)
  Resources/Curriculum/ru/      Russian course.json + week-01..26.json
  Resources/Curriculum/bg/      Bulgarian course.json + week-01..26.json
RusTests/                       Curriculum validation + SM-2 unit tests
```

## Editing the curriculum
Each `week-NN.json` has 7 days (6 study + 1 review). Edit the JSON and re-run the tests —
`CurriculumTests` validates structure (day counts, one review day, required vocab fields)
for every week on disk, so a malformed edit fails fast.
# language
