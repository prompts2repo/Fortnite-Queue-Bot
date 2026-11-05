# Fortnite Queue Bot 🎮

[![Version](https://img.shields.io/badge/version-3.9-purple.svg)](https://github.com/)
[![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-blue.svg)](https://www.microsoft.com/windows)
[![Language](https://img.shields.io/badge/language-AutoHotkey%20v2-334455.svg)](https://www.autohotkey.com/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

An automated matchmaking and queue cycle manager for **Fortnite**, built with **AutoHotkey v2** and featuring a native **Windows 11 Fluent Gaming UI**, **Smart Multitasking** background support, **Resolution Presets**, and **Full Multi-Monitor Auto-Detection**.

---

## 🌟 Key Features

- **Full Multi-Monitor Auto-Detection (v3.9)**:
  - Automatically detects which monitor Fortnite is running on (primary, secondary, left, right, top, or bottom).
  - Calculates virtual screen offsets in real time—coordinates in Settings remain standard and positive (relative to the game canvas), regardless of your display setup.
  - **Smart <kbd>F9</kbd> Multi-Monitor Copier**: pressing <kbd>F9</kbd> inside Fortnite automatically subtracts monitor offsets, copying clean canvas-relative coordinates ready for pasting.

- **Resolution Presets & Auto-Detect (v3.8)**:
  - **1-Click Presets**: instantaneous coordinate configuration for `1080p` (FHD), `1440p` (2K/QHD), and `4K` (UHD).
  - **Smart Auto-Detect**: automatically identifies your active display resolution (or the active Fortnite window) and calculates proportional coordinates dynamically.
  - **Manual Override**: full freedom to fine-tune individual X and Y values or paste copied coordinates (<kbd>Ctrl</kbd> + <kbd>V</kbd>) for custom scaling or ultrawide (21:9) monitors.

- **Smart Multitasking Mode (v3.7)**:
  - Freely browse the web, watch videos, or work during matches!
  - **3-Second Pre-Alert**: plays a discreet audio beep and displays a non-intrusive on-screen notification before the bot interacts.
  - **Focus & Cursor Restoration**: brings Fortnite forward only for the 2–3 seconds required to click, then immediately restores your previous active window and places your mouse cursor back to its exact coordinates on your working monitor.
  - Fully optional: can be toggled on or off at any time in Settings.

- **Windows 11 Fluent Gaming Interface**:
  - High-performance GDI+ vector graphics rendering with smooth rounded corners and anti-aliasing.
  - Dark midnight theme (`#0B0E14`) with dynamic accent lighting.
  - Live animated cycle countdown, active match duration, lobby delay, and round counter.
  - State-diffing UI updates at 250ms for 0% CPU overhead and zero screen flicker.

- **Customizable Cycle Timings**:
  - In-game match duration (minutes).
  - Post-match lobby return cooldown (seconds).

- **Flexible Coordinate Mapping**:
  - Customizable screen pixel positions for the Lobby **Play** button, **ESC / Options** menu, and **Return to Lobby** button.
  - **Smart Coordinate Paste**: automatically splits copied `X, Y` coordinates (e.g., copied via <kbd>F9</kbd>) into separate X and Y fields.

- **Zero Disk Footprint**:
  - Configuration persists directly in the Windows Registry (`HKEY_CURRENT_USER\Software\FortniteQueueBot`).
  - No temporary configuration or cache files created on disk.

- **1-Click Compilation**:
  - Includes `Compila_EXE.bat` for instant compilation into a standalone portable executable with custom icon.

---

## 📁 Repository Structure

| File | Description |
| :--- | :--- |
| `Fortnite Queue Bot.ahk` | Main application source script (AutoHotkey v2). |
| `Fortnite Queue Bot.ico` | Application icon embedded into compiled builds and taskbar. |
| `Compila_EXE.bat` | 1-click batch compiler script using Ahk2Exe. |
| `README.md` | Project documentation and user guide. |
| `.gitignore` | Git rules excluding build artifacts and IDE cache. |

---

## 🚀 Getting Started

### Prerequisites

- **Operating System**: Windows 10 or Windows 11 (64-bit).
- **Game**: Fortnite installed and running (`FortniteClient-Win64-Shipping.exe`).
- **Runtime** (if running from source): [AutoHotkey v2](https://www.autohotkey.com/v2/) (v2.0+).

### Running the Application

1. **Standalone Executable**: Download the compiled `Fortnite Queue Bot.exe` from the [Releases](https://github.com/) section and double-click to run. No installation required.
2. **From Source**: Double-click `Fortnite Queue Bot.ahk` (requires AutoHotkey v2 installed).

---

## ⚙️ Configuration & Settings

Navigate to the **SETTINGS** tab in the top navigation bar to configure:

1. **Cycle Timings & Hotkey**:
   - **Match Duration**: duration in minutes the bot waits before exiting a match (default: 8 min).
   - **Lobby Delay**: cooldown delay in seconds before queueing into the next match (default: 15 sec).
   - **Start / Stop Key**: choose between <kbd>F8</kbd>, <kbd>L</kbd>, or <kbd>9</kbd>.
2. **Smart Multitasking**:
   - **Smart Mode**: `ENABLED` or `DISABLED` (restores active window & mouse cursor).
   - **Audio Pre-Alert**: `BEEP ON` or `MUTED` (plays a chime 3 seconds prior to automated clicks).
3. **Fortnite Button Coordinates & Resolution Presets**:
   - Select your monitor resolution with 1 click:
     - `1080p` *(FHD: 1920 × 1080)*
     - `1440p (2K)` *(QHD: 2560 × 1440)*
     - `4K` *(UHD: 3840 × 2160)*
     - `⚡ AUTO-DETECT` *(automatically measures your display resolution and scales coordinates)*
   - Or manually customize pixel coordinates for **Play Button**, **Options Menu**, and **Return to Lobby**.
   - Press <kbd>F9</kbd> while hovering over any button in-game to copy its exact coordinates to your clipboard, then click any X/Y box and press <kbd>Ctrl</kbd> + <kbd>V</kbd> to paste.

Press **SAVE SETTINGS** to apply changes.

---

## ⌨️ Hotkeys Reference

| Shortcut | Action | Description |
| :---: | :--- | :--- |
| <kbd>F8</kbd> *(default)* | **Start / Stop** | Toggles automated matchmaking cycle on or off (customizable to `L` or `9`). |
| <kbd>F9</kbd> | **Copy Coordinates** | Copies current cursor coordinates (`X, Y`) relative to the game canvas to the Windows clipboard. |
| <kbd>F10</kbd> | **Exit** | Immediately closes the application. |
| <kbd>Esc</kbd> | **Emergency Stop** | Halts the active queue cycle when the application window is focused. |

---

## 🔨 Building from Source

To compile `Fortnite Queue Bot.ahk` into a standalone `.exe`:

1. Ensure [AutoHotkey v2](https://www.autohotkey.com/v2/) is installed along with the Ahk2Exe compiler.
2. Double-click **`Compila_EXE.bat`**.
3. The script will automatically detect your AutoHotkey installation, attach `Fortnite Queue Bot.ico`, and generate a fresh `Fortnite Queue Bot.exe`.

---

## ⚠️ Disclaimer

This tool is intended for personal workflow automation and testing purposes. Please adhere to the terms of service of the games you play. Use responsibly.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
