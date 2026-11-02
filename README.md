# Plato — Disappearing Notes

Notes that vanish. Like Snapchat, but for your thoughts.

Write it down. Set a timer. Watch it disappear. Simple as that.

## Features

- **Disappearing notes** — every note self-destructs after a timer you choose (5 min to 7 days)
- **Live countdown** — watch the time tick down on each note
- **Burn on demand** — don't want to wait? Destroy a note instantly
- **Native and light** — SF Pro, inset-grouped lists and system colours, with Light (default), Dark and System in Settings. Each note has a ring that drains and text that fades as its time runs out, in a warm sienna accent taken from the wax-tablet icon.
- **Tip Jar** — Settings has an optional "Support Plato" sheet with four consumable tips (StoreKit 2). Tips are optional, unlock nothing, and are not tax-deductible. Plato stays free.

## Getting Started

1. The project is generated from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen): run `xcodegen generate` after adding files
2. Open `PlatoNotes.xcodeproj` in Xcode 16+ and run on an iOS 17+ simulator or device. The scheme uses `StoreKit/TipJar.storekit`, so the Tip Jar works locally without App Store Connect
3. Tests: `xcodebuild test -scheme PlatoNotes -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'`

The app icon, Plato's wax tablet of memory from the Theaetetus, is rendered in Blender: `blender -b -P tools/icon_render_v2.py -- a out.png 1024`.

## Tech Stack

- SwiftUI
- SwiftData
- iOS 17+
- StoreKit 2 for the optional Tip Jar
- No servers, no cloud, no tracking. The only network use is the Tip Jar talking to the App Store.
