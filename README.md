# Plato — Disappearing Notes

Notes that vanish. Like Snapchat, but for your thoughts.

Write it down. Set a timer. Watch it disappear. Simple as that.

## Features

- **Disappearing notes** — every note self-destructs after a timer you choose (5 min to 7 days)
- **Live countdown** — watch the time tick down on each note
- **Burn on demand** — don't want to wait? Destroy a note instantly
- **Bauhaus, dark first** — Jost type, numbered sections, thick rules and flat colour fields. Each note's life is drawn in the three primaries: cobalt while fresh, yellow as it fades, ember when it's about to go. Light and System appearances are in Settings.

## Getting Started

1. Open `PlatoNotes.xcodeproj` in Xcode 15+
2. Build and run on iOS 17+ simulator or device
3. Start writing notes that vanish

The app icon is rendered in Blender: `blender -b -P tools/icon_render.py -- b out.png 1024`.

## Tech Stack

- SwiftUI
- SwiftData
- iOS 17+
- Zero network calls. Zero cloud. Zero tracking.
