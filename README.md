# CXRes

A macOS menu bar app for quickly switching [CrossOver](https://www.codeweavers.com/crossover) Wine virtual desktop resolutions.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 6](https://img.shields.io/badge/Swift-6-orange)
![License: GPL v3](https://img.shields.io/badge/License-GPLv3-green)

## What it does

When running Windows games through CrossOver on macOS, the Wine virtual desktop resolution needs to match your display for the best experience. If you switch between a MacBook screen and an external monitor, you need to change the resolution each time in the CrossOver bottle settings — a tedious multi-step process.

CXRes puts a display icon in your menu bar that lets you switch resolutions with a single click. It directly edits the Wine registry (`user.reg`) in your CrossOver bottle.

## Features

- **Menu bar app** — no dock icon, no windows, always accessible
- **One-click switching** — select a resolution profile from the dropdown
- **Custom profiles** — add as many resolution presets as you need
- **Auto-detect displays** — reads connected display resolutions to create initial profiles
- **Keyboard shortcuts** — ⌘0 for off, ⌘1–⌘9 for profiles
- **Configurable bottle** — works with any CrossOver bottle name
- **Launch at login** — optional auto-start via macOS ServiceManagement
- **Lightweight** — pure Swift, no dependencies, ~200 lines of code

## Screenshot

```
┌─────────────────────────────────┐
│ CrossOver Resolution            │
│─────────────────────────────────│
│ ✓ Off — No Virtual Desktop  ⌘0 │
│   Notebook — 2294x1490      ⌘1 │
│   External — 3840x2160      ⌘2 │
│─────────────────────────────────│
│   Settings…                  ⌘, │
│   Launch at Login               │
│─────────────────────────────────│
│   Quit CXRes                 ⌘Q │
└─────────────────────────────────┘
```

## Requirements

- macOS 14.0 (Sonoma) or later
- [CrossOver](https://www.codeweavers.com/crossover) installed with at least one bottle
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) and Xcode command line tools (for building)

## Build

```bash
# Install XcodeGen if you don't have it
brew install xcodegen

# Clone and build
git clone https://github.com/AugmentedMode/CXRes.git
cd CXRes
xcodegen generate
xcodebuild -project CXRes.xcodeproj -scheme CXRes -configuration Release build SYMROOT=build
```

The built app will be at `build/Release/CXRes.app`.

## Install

```bash
cp -R build/Release/CXRes.app /Applications/
open /Applications/CXRes.app
```

Or simply drag `CXRes.app` to your Applications folder.

## Configuration

Click the menu bar icon → **Settings…** (⌘,) to:

- **Bottle Name** — name of your CrossOver bottle (default: `Steam`). The app reads/writes `~/Library/Application Support/CrossOver/Bottles/<name>/user.reg`
- **Resolution Profiles** — add, edit, or remove resolution presets (format: `WIDTHxHEIGHT`)
- **Detect Displays** — auto-create profiles from currently connected displays
- **Restore Defaults** — reset to built-in Notebook/External profiles

## How it works

CrossOver stores Wine configuration in registry files inside each bottle. The virtual desktop resolution is controlled by two keys:

- `[Software\\Wine\\Explorer]` → `"Desktop"` — set to `"Default"` to enable, `""` to disable
- `[Software\\Wine\\Explorer\\Desktops]` → `"Default"` — the resolution string (e.g. `"3840x2160"`)

CXRes parses and rewrites these sections in `user.reg` while preserving the rest of the file.

## Project structure

```
CXRes/
├── CXResApp.swift          # @main entry point
├── AppDelegate.swift        # Menu bar status item + menu
├── BottleManager.swift      # Wine registry reader/writer
├── Settings.swift           # UserDefaults + ResolutionProfile model
├── SettingsView.swift       # SwiftUI preferences form
├── Info.plist               # LSUIElement (menu bar only)
└── Assets.xcassets/         # App icon
```

## Acknowledgments

This project was built with the help of [Claude](https://claude.ai) by Anthropic.

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).
