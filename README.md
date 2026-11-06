# Fortnite Queue Bot 🎮

[![Version](https://img.shields.io/badge/version-4.0-purple.svg)](https://github.com/)
[![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-blue.svg)](https://www.microsoft.com/windows)
[![Language](https://img.shields.io/badge/language-AutoHotkey%20v2-334455.svg)](https://www.autohotkey.com/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

An automated matchmaking and queue cycle manager for **Fortnite**, built with **AutoHotkey v2**. Designed for **AFK event & pirate token farming** and early-game chest looting loops, featuring a native **Windows 11 Fluent UI**, **Smart Multitasking** background support, **Resolution Presets**, and **Full Multi-Monitor Auto-Detection**.

---

## 🎯 Use Cases

- **AFK Pirate & Event Token Farming**: Automatically loops into matches to farm early-game chest openings and event tokens on repeat.
- **Hands-Free Matchmaking Loop**: Configurable in-game stay time (e.g., 3–8 minutes) and automatic return-to-lobby cooldown.
- **Uninterrupted Multitasking**: Work, browse, or watch streams on your computer—the bot interacts in the background and restores your active window and mouse cursor in milliseconds.

---

## 🌟 Key Features

- **Lifetime & Session Statistics**: Displays live session metrics (match duration, lobby delay, session rounds, current session uptime) as well as persistent lifetime statistics (total completed rounds across all sessions, cumulative program execution time) directly on the dashboard.
- **Smart Multitasking Mode**: Brings Fortnite to the foreground only for 2–3 seconds to click, then instantly restores your previous active window and mouse position. Includes an optional 3-second audio pre-alert.
- **Full Multi-Monitor Support**: Automatically detects which monitor runs Fortnite (left, right, top, or secondary) and normalizes coordinate offsets seamlessly.
- **1-Click Resolution Presets**: Instant coordinate setup for `1080p` (FHD), `1440p` (2K/QHD), `4K` (UHD), and an `Auto-Detect` button for dynamic scaling.
- **Fluent Gaming UI**: Smooth dark-mode interface (`#0B0E14`) with live round counters, match timers, lifetime metrics, and cycle status.
- **Smart Coordinate Helper (<kbd>F9</kbd>)**: Press <kbd>F9</kbd> in-game to copy exact button coordinates, and paste them directly into Settings (<kbd>Ctrl</kbd> + <kbd>V</kbd>).
- **Portable & Lightweight**: Zero disk files; all preferences and lifetime statistics persist directly in the Windows Registry (`HKCU\Software\FortniteQueueBot`).

---

## 🚀 Quick Start

### Option 1: Standalone Executable (Recommended)
1. Download **`Fortnite Queue Bot.exe`** from the [Releases](https://github.com/) section.
2. Launch Fortnite, then run `Fortnite Queue Bot.exe`.

### Option 2: From Source
1. Install [AutoHotkey v2](https://www.autohotkey.com/v2/).
2. Run `Fortnite Queue Bot.ahk`.

---

## ⚙️ Configuration

In the **SETTINGS** tab:
- **Timings**: Set match duration (minutes to stay in game) and lobby delay (seconds before readying up).
- **Multitasking**: Enable Smart Mode and audio chime pre-alerts.
- **Resolution**: Click your monitor preset (`1080p`, `1440p`, `4K`, or `Auto-Detect`), or customize button coordinates manually.
- Click **Save Settings** to persist your preferences.

---

## ⌨️ Hotkeys

| Shortcut | Action | Description |
| :---: | :--- | :--- |
| <kbd>F8</kbd> *(default)* | **Start / Stop** | Toggles the automated matchmaking cycle (can be changed to `L` or `9`). |
| <kbd>F9</kbd> | **Copy Coordinates** | Copies in-game cursor coordinates to clipboard for easy pasting into Settings. |
| <kbd>F10</kbd> | **Exit** | Immediately closes the bot. |
| <kbd>Esc</kbd> | **Emergency Stop** | Halts the active queue cycle when the bot window is focused. |

---

## 🔨 Building from Source

To compile the script into a standalone `.exe`:
1. Ensure [AutoHotkey v2](https://www.autohotkey.com/v2/) and `Ahk2Exe` are installed.
2. Run **`Compila_EXE.bat`** to build `Fortnite Queue Bot.exe` with the bundled icon.

---

## ⚠️ Disclaimer

This tool is intended for personal automation and testing purposes. Please adhere to the terms of service of the games you play. Use responsibly.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
