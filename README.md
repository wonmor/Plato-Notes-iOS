# Plato — Disappearing Notes

Notes that vanish. Like Snapchat, but for your thoughts.

Write it down. Set a timer. Watch it disappear. Simple as that.

## Features

- **Disappearing notes** — every note self-destructs after a timer you choose (5 min to 7 days)
- **Live countdown** — watch the time tick down on each note
- **Burn on demand** — don't want to wait? Destroy a note instantly
- **Native and light** — SF Pro, inset-grouped lists and system colours, with Light (default), Dark and System in Settings. Each note has a ring that drains and text that fades as its time runs out, in a warm sienna accent taken from the wax-tablet icon.

## Getting Started

1. Open `PlatoNotes.xcodeproj` in Xcode 15+
2. Build and run on iOS 17+ simulator or device
3. Start writing notes that vanish

The app icon, Plato's wax tablet of memory from the Theaetetus, is rendered in Blender: `blender -b -P tools/icon_render_v2.py -- a out.png 1024`.

## Tech Stack

- SwiftUI
- SwiftData
- iOS 17+
- Zero network calls. Zero cloud. Zero tracking.
