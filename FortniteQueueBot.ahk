#Requires AutoHotkey v2.0
#SingleInstance Force
CoordMode "Mouse", "Screen"

; Set explicit AppUserModelID so Windows Taskbar associates our custom icon and doesn't group under AutoHotkey
try DllCall("shell32\SetCurrentProcessExplicitAppUserModelID", "WStr", "FortniteQueueBot.App")

; Set Tray and Application Icons
iconPath := A_ScriptDir "\FortniteQueueBot.ico"
if !FileExist(iconPath)
    iconPath := A_ScriptDir "\AutoQueueFN.ico"
try TraySetIcon(iconPath)

; ==========================================================
; Fortnite Queue Bot — Windows 11 Fluent Gaming Dashboard (v4.0)
; ==========================================================

; Windows Registry configuration path (persists settings without creating any files on disk)
REG_SETTINGS := "HKEY_CURRENT_USER\Software\FortniteQueueBot"

; Load persisted settings with defaults fallback
initPlayX     := Integer(RegRead(REG_SETTINGS, "PlayX", 349))
initPlayY     := Integer(RegRead(REG_SETTINGS, "PlayY", 1216))
initOptX      := Integer(RegRead(REG_SETTINGS, "OptionsX", 2237))
initOptY      := Integer(RegRead(REG_SETTINGS, "OptionsY", 97))
initLeaveX    := Integer(RegRead(REG_SETTINGS, "LeaveX", 2075))
initLeaveY    := Integer(RegRead(REG_SETTINGS, "LeaveY", 231))
initGameMin   := Integer(RegRead(REG_SETTINGS, "GameMinutes", 8))
initLobbySec  := Integer(RegRead(REG_SETTINGS, "LobbySeconds", 15))
initHotkey    := RegRead(REG_SETTINGS, "Hotkey", "F8")
if !(initHotkey = "F8" || initHotkey = "L" || initHotkey = "9")
    initHotkey := "F8"

initSmartRestore := Integer(RegRead(REG_SETTINGS, "SmartRestore", 0))
if !(initSmartRestore = 0 || initSmartRestore = 1)
    initSmartRestore := 0

initAudioAlert   := Integer(RegRead(REG_SETTINGS, "AudioAlert", 1))
if !(initAudioAlert = 0 || initAudioAlert = 1)
    initAudioAlert := 1

; Load persisted lifetime statistics across all sessions
initTotalRounds     := Integer(RegRead(REG_SETTINGS, "TotalRounds", 0))
initTotalRuntimeSec := Integer(RegRead(REG_SETTINGS, "TotalRuntimeSec", 0))

PlayBtn     := [initPlayX, initPlayY]
OptionsBtn  := [initOptX, initOptY]
LeaveBtn    := [initLeaveX, initLeaveY]

InGameTime  := initGameMin * 60 * 1000
LoadTime    := 60 * 1000
LobbyTime   := initLobbySec * 1000

running := false
rounds := 0
totalRounds := initTotalRounds
totalRuntimeSec := initTotalRuntimeSec
sessionActiveSec := 0
activeStartTick := 0
matchInProgress := false
phase := "Ready"
phaseTick := 0
gameStartTick := 0
currentPage := "home"
startHotkey := initHotkey
selectedHotkey := initHotkey
smartRestore := initSmartRestore
selectedSmartRestore := initSmartRestore
audioAlert := initAudioAlert
selectedAudioAlert := initAudioAlert

; Theme Colors
BG         := "0B0E14"   ; Midnight black background
HEADER_BG  := "0F131C"   ; Top header navy
PANEL_BG   := "131926"   ; Hero & stat card background
INPUT_BG   := "182030"   ; Inputs and secondary buttons
BORDER     := "222C3F"   ; Fine border lines
TEXT_WHITE := "F8FAFC"   ; Primary text
TEXT_MUTED := "8E9AA8"   ; Secondary / label text
TEXT_DIM   := "566273"   ; Hint & subtitle text
ACCENT     := "7C3AED"   ; Electric violet / purple
ACCENT_RED := "E11D48"   ; Status stopped red
ACCENT_GRN := "10B981"   ; Status running emerald green

; Initialize GDI+
pGdiToken := 0
gdiStartupInput := Buffer(24, 0)
NumPut("UInt", 1, gdiStartupInput, 0)
DllCall("gdiplus\GdiplusStartup", "Ptr*", &pGdiToken, "Ptr", gdiStartupInput, "Ptr", 0)

; Hand cursor handle for smooth hover feedback
hHandCursor := DllCall("user32\LoadCursor", "Ptr", 0, "Int", 32649, "Ptr")
ClickableHwnds := Map()

; ----------------------------------------------------------
; Fluent GDI+ Rounded Rectangle & Button Bitmap Generator
; Uses UnitPoint (3) for genuine Windows font point sizing & bold weights
; ----------------------------------------------------------
CreateRoundedHBitmap(w, h, r, fillColor, borderColor := 0, borderWidth := 1, text := "", fontName := "Segoe UI", fontSize := 10, textColor := 0xFFFFFFFF, bold := false, bgParent := 0xFF0B0E14) {
    DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", w, "Int", h, "Int", 0, "Int", 0x26200A, "Ptr", 0, "Ptr*", &pBitmap := 0)
    DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", pBitmap, "Ptr*", &pGraphics := 0)
    DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", pGraphics, "Int", 4)      ; High-Quality Anti-Alias
    DllCall("gdiplus\GdipSetTextRenderingHint", "Ptr", pGraphics, "Int", 4)  ; AntiAliasGridFit

    ; Clear surface with parent background so smooth rounded corners blend invisibly
    DllCall("gdiplus\GdipGraphicsClear", "Ptr", pGraphics, "UInt", bgParent)

    ; Build smooth rounded path
    DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", &pPath := 0)
    d := r * 2
    DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", 0, "Float", 0, "Float", d, "Float", d, "Float", 180, "Float", 90)
    DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", w - d - 1, "Float", 0, "Float", d, "Float", d, "Float", 270, "Float", 90)
    DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", w - d - 1, "Float", h - d - 1, "Float", d, "Float", d, "Float", 0, "Float", 90)
    DllCall("gdiplus\GdipAddPathArc", "Ptr", pPath, "Float", 0, "Float", h - d - 1, "Float", d, "Float", d, "Float", 90, "Float", 90)
    DllCall("gdiplus\GdipClosePathFigure", "Ptr", pPath)

    ; Fill rounded interior
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", fillColor, "Ptr*", &pBrush := 0)
    DllCall("gdiplus\GdipFillPath", "Ptr", pGraphics, "Ptr", pBrush, "Ptr", pPath)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", pBrush)

    ; Optional border stroke
    if (borderColor != 0 && borderWidth > 0) {
        DllCall("gdiplus\GdipCreatePen1", "UInt", borderColor, "Float", borderWidth, "Int", 2, "Ptr*", &pPen := 0)
        DllCall("gdiplus\GdipDrawPath", "Ptr", pGraphics, "Ptr", pPen, "Ptr", pPath)
        DllCall("gdiplus\GdipDeletePen", "Ptr", pPen)
    }
    DllCall("gdiplus\GdipDeletePath", "Ptr", pPath)

    ; Centered anti-aliased text rendering with true point sizing
    if (text != "") {
        DllCall("gdiplus\GdipCreateFontFamilyFromName", "WStr", fontName, "Ptr", 0, "Ptr*", &pFamily := 0)
        fontStyle := bold ? 1 : 0
        ; UnitPoint = 3 ensures bold, prominent text identical to native Windows controls
        DllCall("gdiplus\GdipCreateFont", "Ptr", pFamily, "Float", fontSize, "Int", fontStyle, "Int", 3, "Ptr*", &pFont := 0)
        DllCall("gdiplus\GdipDeleteFontFamily", "Ptr", pFamily)

        DllCall("gdiplus\GdipCreateStringFormat", "Int", 0, "Int", 0, "Ptr*", &pFormat := 0)
        DllCall("gdiplus\GdipSetStringFormatAlign", "Ptr", pFormat, "Int", 1)     ; Horizontal center
        DllCall("gdiplus\GdipSetStringFormatLineAlign", "Ptr", pFormat, "Int", 1) ; Vertical center

        DllCall("gdiplus\GdipCreateSolidFill", "UInt", textColor, "Ptr*", &pTextBrush := 0)
        layoutRect := Buffer(16, 0)
        NumPut("Float", 0, layoutRect, 0), NumPut("Float", 0, layoutRect, 4), NumPut("Float", w, layoutRect, 8), NumPut("Float", h, layoutRect, 12)

        DllCall("gdiplus\GdipDrawString", "Ptr", pGraphics, "WStr", text, "Int", -1, "Ptr", pFont, "Ptr", layoutRect, "Ptr", pFormat, "Ptr", pTextBrush)

        DllCall("gdiplus\GdipDeleteBrush", "Ptr", pTextBrush)
        DllCall("gdiplus\GdipDeleteStringFormat", "Ptr", pFormat)
        DllCall("gdiplus\GdipDeleteFont", "Ptr", pFont)
    }

    DllCall("gdiplus\GdipDeleteGraphics", "Ptr", pGraphics)
    DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", pBitmap, "Ptr*", &hBitmap := 0, "UInt", bgParent)
    DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)
    return hBitmap
}

; ----------------------------------------------------------
; Pre-render All Fluent Windows 11 UI Bitmaps
; Each control receives a unique HBITMAP handle to avoid Win32 sharing errors
; ----------------------------------------------------------
; Header elements
hVersionBadge    := CreateRoundedHBitmap(42, 20, 6, 0xFF182030, 0xFF2B374E, 1, "v4.0", "Segoe UI", 8, 0xFF8E9AA8, true, 0xFF0F131C)
hTabDashActive   := CreateRoundedHBitmap(140, 36, 10, 0xFF7C3AED, 0, 0, "DASHBOARD", "Segoe UI", 10, 0xFFFFFFFF, true, 0xFF0F131C)
hTabDashInactive := CreateRoundedHBitmap(140, 36, 10, 0xFF141A26, 0xFF222C3F, 1, "DASHBOARD", "Segoe UI", 10, 0xFF8E9AA8, true, 0xFF0F131C)
hTabSetActive    := CreateRoundedHBitmap(140, 36, 10, 0xFF7C3AED, 0, 0, "SETTINGS", "Segoe UI", 10, 0xFFFFFFFF, true, 0xFF0F131C)
hTabSetInactive  := CreateRoundedHBitmap(140, 36, 10, 0xFF141A26, 0xFF222C3F, 1, "SETTINGS", "Segoe UI", 10, 0xFF8E9AA8, true, 0xFF0F131C)
hMinBtn   := CreateRoundedHBitmap(32, 32, 8, 0xFF182030, 0xFF2B374E, 1, Chr(0xE921), "Segoe MDL2 Assets", 10, 0xFF8E9AA8, false, 0xFF0F131C)
hCloseBtn := CreateRoundedHBitmap(32, 32, 8, 0xFF182030, 0xFF2B374E, 1, Chr(0xE8BB), "Segoe MDL2 Assets", 10, 0xFFFF6B81, false, 0xFF0F131C)

; Dashboard cards & buttons (Unique handles per control)
hHeroCard    := CreateRoundedHBitmap(640, 134, 14, 0xFF131926, 0xFF222C3F, 1, "", "", 0, 0, false, 0xFF0B0E14)
hStatusRed   := CreateRoundedHBitmap(4, 114, 2, 0xFFEF4444, 0, 0, "", "", 0, 0, false, 0xFF131926)
hStatusGreen := CreateRoundedHBitmap(4, 114, 2, 0xFF10B981, 0, 0, "", "", 0, 0, false, 0xFF131926)
hStatCard1   := CreateRoundedHBitmap(202, 84, 12, 0xFF131926, 0xFF222C3F, 1, "", "", 0, 0, false, 0xFF0B0E14)
hStatCard2   := CreateRoundedHBitmap(202, 84, 12, 0xFF131926, 0xFF222C3F, 1, "", "", 0, 0, false, 0xFF0B0E14)
hStatCard3   := CreateRoundedHBitmap(202, 84, 12, 0xFF131926, 0xFF222C3F, 1, "", "", 0, 0, false, 0xFF0B0E14)
hStatCard4   := CreateRoundedHBitmap(202, 84, 12, 0xFF131926, 0xFF222C3F, 1, "", "", 0, 0, false, 0xFF0B0E14)
hStatCard5   := CreateRoundedHBitmap(202, 84, 12, 0xFF131926, 0xFF222C3F, 1, "", "", 0, 0, false, 0xFF0B0E14)
hStatCard6   := CreateRoundedHBitmap(202, 84, 12, 0xFF131926, 0xFF222C3F, 1, "", "", 0, 0, false, 0xFF0B0E14)
hFooterStrip := CreateRoundedHBitmap(640, 44, 10, 0xFF101520, 0xFF1E2738, 1, "", "", 0, 0, false, 0xFF0B0E14)

; Dynamic Start Button Generator
MakeStartBtnBmp(isRunning, key) {
    if isRunning
        return CreateRoundedHBitmap(640, 56, 12, 0xFFE11D48, 0, 0, "■   STOP AUTO QUEUE  (" StrUpper(key) ")", "Segoe UI", 12, 0xFFFFFFFF, true, 0xFF0B0E14)
    else
        return CreateRoundedHBitmap(640, 56, 12, 0xFF7C3AED, 0, 0, "▶   START AUTO QUEUE  (" StrUpper(key) ")", "Segoe UI", 12, 0xFFFFFFFF, true, 0xFF0B0E14)
}

; Settings cards (3 cards: Timings, Smart Multitasking, Coordinates & Presets)
hSettingsCard1 := CreateRoundedHBitmap(640, 112, 14, 0xFF131926, 0xFF222C3F, 1, "", "", 0, 0, false, 0xFF0B0E14)
hSettingsCard2 := CreateRoundedHBitmap(640, 94, 14, 0xFF131926, 0xFF222C3F, 1, "", "", 0, 0, false, 0xFF0B0E14)
hSettingsCard3 := CreateRoundedHBitmap(640, 144, 14, 0xFF131926, 0xFF222C3F, 1, "", "", 0, 0, false, 0xFF0B0E14)

; Inputs backgrounds
hInputBox_Duration := CreateRoundedHBitmap(102, 34, 8, 0xFF182030, 0xFF2B374E, 1, "", "", 0, 0, false, 0xFF131926)
hInputBox_Lobby    := CreateRoundedHBitmap(102, 34, 8, 0xFF182030, 0xFF2B374E, 1, "", "", 0, 0, false, 0xFF131926)
hInputBox_PlayX    := CreateRoundedHBitmap(72, 34, 8, 0xFF182030, 0xFF2B374E, 1, "", "", 0, 0, false, 0xFF131926)
hInputBox_PlayY    := CreateRoundedHBitmap(72, 34, 8, 0xFF182030, 0xFF2B374E, 1, "", "", 0, 0, false, 0xFF131926)
hInputBox_OptX     := CreateRoundedHBitmap(72, 34, 8, 0xFF182030, 0xFF2B374E, 1, "", "", 0, 0, false, 0xFF131926)
hInputBox_OptY     := CreateRoundedHBitmap(72, 34, 8, 0xFF182030, 0xFF2B374E, 1, "", "", 0, 0, false, 0xFF131926)
hInputBox_LeaveX   := CreateRoundedHBitmap(72, 34, 8, 0xFF182030, 0xFF2B374E, 1, "", "", 0, 0, false, 0xFF131926)
hInputBox_LeaveY   := CreateRoundedHBitmap(72, 34, 8, 0xFF182030, 0xFF2B374E, 1, "", "", 0, 0, false, 0xFF131926)

; Hotkey pill buttons
hPillActive_F8   := CreateRoundedHBitmap(52, 34, 8, 0xFF7C3AED, 0, 0, "F8", "Segoe UI", 10, 0xFFFFFFFF, true, 0xFF131926)
hPillInactive_F8 := CreateRoundedHBitmap(52, 34, 8, 0xFF182030, 0xFF2B374E, 1, "F8", "Segoe UI", 10, 0xFF8E9AA8, true, 0xFF131926)
hPillActive_L    := CreateRoundedHBitmap(52, 34, 8, 0xFF7C3AED, 0, 0, "L", "Segoe UI", 10, 0xFFFFFFFF, true, 0xFF131926)
hPillInactive_L  := CreateRoundedHBitmap(52, 34, 8, 0xFF182030, 0xFF2B374E, 1, "L", "Segoe UI", 10, 0xFF8E9AA8, true, 0xFF131926)
hPillActive_9    := CreateRoundedHBitmap(52, 34, 8, 0xFF7C3AED, 0, 0, "9", "Segoe UI", 10, 0xFFFFFFFF, true, 0xFF131926)
hPillInactive_9  := CreateRoundedHBitmap(52, 34, 8, 0xFF182030, 0xFF2B374E, 1, "9", "Segoe UI", 10, 0xFF8E9AA8, true, 0xFF131926)

; Smart Multitasking pill buttons
hPillActive_SmartOn    := CreateRoundedHBitmap(80, 28, 6, 0xFF10B981, 0, 0, "ENABLED", "Segoe UI", 8, 0xFFFFFFFF, true, 0xFF131926)
hPillInactive_SmartOn  := CreateRoundedHBitmap(80, 28, 6, 0xFF182030, 0xFF2B374E, 1, "ENABLED", "Segoe UI", 8, 0xFF8E9AA8, true, 0xFF131926)
hPillActive_SmartOff   := CreateRoundedHBitmap(90, 28, 6, 0xFFE11D48, 0, 0, "DISABLED", "Segoe UI", 8, 0xFFFFFFFF, true, 0xFF131926)
hPillInactive_SmartOff := CreateRoundedHBitmap(90, 28, 6, 0xFF182030, 0xFF2B374E, 1, "DISABLED", "Segoe UI", 8, 0xFF8E9AA8, true, 0xFF131926)

; Audio Pre-alert pill buttons
hPillActive_AudioOn    := CreateRoundedHBitmap(78, 28, 6, 0xFF7C3AED, 0, 0, "BEEP ON", "Segoe UI", 9, 0xFFFFFFFF, true, 0xFF131926)
hPillInactive_AudioOn  := CreateRoundedHBitmap(78, 28, 6, 0xFF182030, 0xFF2B374E, 1, "BEEP ON", "Segoe UI", 9, 0xFF8E9AA8, true, 0xFF131926)
hPillActive_AudioOff   := CreateRoundedHBitmap(70, 28, 6, 0xFF64748B, 0, 0, "MUTED", "Segoe UI", 9, 0xFFFFFFFF, true, 0xFF131926)
hPillInactive_AudioOff := CreateRoundedHBitmap(70, 28, 6, 0xFF182030, 0xFF2B374E, 1, "MUTED", "Segoe UI", 9, 0xFF8E9AA8, true, 0xFF131926)

; Resolution Preset pill buttons
hPillActive_1080p   := CreateRoundedHBitmap(68, 26, 6, 0xFF7C3AED, 0, 0, "1080p", "Segoe UI", 9, 0xFFFFFFFF, true, 0xFF131926)
hPillInactive_1080p := CreateRoundedHBitmap(68, 26, 6, 0xFF182030, 0xFF2B374E, 1, "1080p", "Segoe UI", 9, 0xFF8E9AA8, true, 0xFF131926)

hPillActive_1440p   := CreateRoundedHBitmap(84, 26, 6, 0xFF7C3AED, 0, 0, "1440p (2K)", "Segoe UI", 8, 0xFFFFFFFF, true, 0xFF131926)
hPillInactive_1440p := CreateRoundedHBitmap(84, 26, 6, 0xFF182030, 0xFF2B374E, 1, "1440p (2K)", "Segoe UI", 8, 0xFF8E9AA8, true, 0xFF131926)

hPillActive_4K      := CreateRoundedHBitmap(54, 26, 6, 0xFF7C3AED, 0, 0, "4K", "Segoe UI", 9, 0xFFFFFFFF, true, 0xFF131926)
hPillInactive_4K    := CreateRoundedHBitmap(54, 26, 6, 0xFF182030, 0xFF2B374E, 1, "4K", "Segoe UI", 9, 0xFF8E9AA8, true, 0xFF131926)

hBtn_Auto           := CreateRoundedHBitmap(108, 26, 6, 0xFF7C3AED, 0, 0, "⚡ AUTO-DETECT", "Segoe UI", 8, 0xFFFFFFFF, true, 0xFF131926)

; Settings action buttons
hSaveBtn       := CreateRoundedHBitmap(310, 42, 12, 0xFF7C3AED, 0, 0, "SAVE SETTINGS", "Segoe UI", 11, 0xFFFFFFFF, true, 0xFF0B0E14)
hResetBtn      := CreateRoundedHBitmap(310, 42, 12, 0xFF182030, 0xFF2B374E, 1, "RESET DEFAULTS", "Segoe UI", 11, 0xFF8E9AA8, true, 0xFF0B0E14)
hResetStatsBtn := CreateRoundedHBitmap(240, 30, 8, 0xFF182030, 0xFF2B374E, 1, "🗑   RESET LIFETIME STATS", "Segoe UI", 8, 0xFFE11D48, true, 0xFF0B0E14)

; ==========================================================
; Main GUI Construction
; ==========================================================
MainGui := Gui("-Caption +MinimizeBox +Border", "Fortnite Queue Bot")
MainGui.BackColor := BG
try MainGui.SetIcon(iconPath)
MainGui.MarginX := 0
MainGui.MarginY := 0

; ----------------------------------------------------------
; Top Header & Window Background Brushes
; Drawn directly via WM_ERASEBKGND so no controls ever cover buttons/tabs
; ----------------------------------------------------------
hBrushHeader := DllCall("gdi32\CreateSolidBrush", "UInt", 0x1C130F, "Ptr") ; 0x0F131C BGR
hBrushBorder := DllCall("gdi32\CreateSolidBrush", "UInt", 0x3F2C22, "Ptr") ; 0x222C3F BGR
hBrushBody   := DllCall("gdi32\CreateSolidBrush", "UInt", 0x140E0B, "Ptr") ; 0x0B0E14 BGR

OnMessage(0x0014, WM_ERASEBKGND)
WM_ERASEBKGND(wParam, lParam, msg, hwnd) {
    global MainGui, hBrushHeader, hBrushBorder, hBrushBody
    if (!IsSet(MainGui) || hwnd != MainGui.Hwnd)
        return
    hdc := wParam
    rH := Buffer(16, 0)
    NumPut("Int", 0, rH, 0), NumPut("Int", 0, rH, 4), NumPut("Int", 700, rH, 8), NumPut("Int", 59, rH, 12)
    DllCall("user32\FillRect", "Ptr", hdc, "Ptr", rH, "Ptr", hBrushHeader)
    rB := Buffer(16, 0)
    NumPut("Int", 0, rB, 0), NumPut("Int", 59, rB, 4), NumPut("Int", 700, rB, 8), NumPut("Int", 60, rB, 12)
    DllCall("user32\FillRect", "Ptr", hdc, "Ptr", rB, "Ptr", hBrushBorder)
    rBody := Buffer(16, 0)
    NumPut("Int", 0, rBody, 0), NumPut("Int", 60, rBody, 4), NumPut("Int", 700, rBody, 8), NumPut("Int", 650, rBody, 12)
    DllCall("user32\FillRect", "Ptr", hdc, "Ptr", rBody, "Ptr", hBrushBody)
    return 1
}

; Brand Title (Clicking opens GitHub repository)
Brand := MainGui.AddText("x26 y17 w166 h28 Background0F131C cF8FAFC +0x100", "Fortnite Queue Bot")
Brand.SetFont("s13 Bold", "Segoe UI")
Brand.OnEvent("Click", (*) => Run("https://github.com/prompts2repo/Fortnite-Queue-Bot"))
ClickableHwnds[Brand.Hwnd] := true

; Helper to swap bitmap on Picture control safely without Win32/AHK handle invalidation
SetCtrlBitmap(ctrl, hBitmap, deletePrevious := false) {
    oldHbm := SendMessage(0x172, 0, hBitmap, ctrl.Hwnd)
    if (deletePrevious && oldHbm)
        DllCall("gdi32\DeleteObject", "Ptr", oldHbm)
    DllCall("user32\InvalidateRect", "Ptr", ctrl.Hwnd, "Ptr", 0, "Int", 1)
}

; Safe Picture control creator: avoids AHK taking ownership or deleting HBITMAP handles
AddCustomPicture(options, hBitmap) {
    ctrl := MainGui.AddPicture(options . " +0x0E")
    SetCtrlBitmap(ctrl, hBitmap)
    return ctrl
}

; Version Badge (Clicking opens GitHub repository)
VersionBadge := AddCustomPicture("x196 y19 w42 h20", hVersionBadge)
VersionBadge.OnEvent("Click", (*) => Run("https://github.com/prompts2repo/Fortnite-Queue-Bot"))
ClickableHwnds[VersionBadge.Hwnd] := true

; Navigation Tabs
NavHome := AddCustomPicture("x275 y12 w140 h36", hTabDashActive)
NavHome.OnEvent("Click", (*) => ShowPage("home"))
ClickableHwnds[NavHome.Hwnd] := true

NavSettings := AddCustomPicture("x425 y12 w140 h36", hTabSetInactive)
NavSettings.OnEvent("Click", (*) => ShowPage("settings"))
ClickableHwnds[NavSettings.Hwnd] := true

; Window Control Buttons
MinBtn := AddCustomPicture("x616 y14 w32 h32", hMinBtn)
MinBtn.OnEvent("Click", (*) => WinMinimize("ahk_id " MainGui.Hwnd))
ClickableHwnds[MinBtn.Hwnd] := true

CloseBtn := AddCustomPicture("x652 y14 w32 h32", hCloseBtn)
CloseBtn.OnEvent("Click", (*) => ExitApp())
ClickableHwnds[CloseBtn.Hwnd] := true

; ==========================================================
; PAGE 1: DASHBOARD
; ==========================================================

; Hero Card
HeroPic := AddCustomPicture("x30 y74 w640 h134", hHeroCard)
StatusStripe := AddCustomPicture("x44 y84 w4 h114", hStatusRed)

StatusEyebrow := MainGui.AddText("x58 y86 w240 h16 Background131926 c8E9AA8", "SYSTEM STATUS")
StatusEyebrow.SetFont("s8 Bold", "Segoe UI")
StatusDot := MainGui.AddText("x58 y106 w18 h28 Background131926 cEF4444", "●")
StatusDot.SetFont("s16 Bold", "Segoe UI")
StatusText := MainGui.AddText("x80 y104 w260 h30 Background131926 cF8FAFC", "STOPPED")
StatusText.SetFont("s16 Bold", "Segoe UI")
PhaseText := MainGui.AddText("x58 y136 w310 h56 Background131926 c94A3B8", "Ready to queue. Press Start or hit " StrUpper(startHotkey) " to begin automated matchmaking.")
PhaseText.SetFont("s9", "Segoe UI")

Divider := MainGui.AddText("x390 y84 w1 h114 Background1E2738")

TimerLabel := MainGui.AddText("x415 y86 w230 h16 Background131926 c8E9AA8", "CYCLE COUNTDOWN")
TimerLabel.SetFont("s8 Bold", "Segoe UI")
TimerText := MainGui.AddText("x415 y104 w230 h44 Background131926 cF8FAFC", "08:00")
TimerText.SetFont("s26 Bold", "Segoe UI")
TimerSub := MainGui.AddText("x415 y154 w230 h16 Background131926 c566273", "Next match trigger / return timer")
TimerSub.SetFont("s8", "Segoe UI")

; Row 1: Session & Timing Metric Cards
Stat1Pic := AddCustomPicture("x30 y218 w202 h84", hStatCard1)
Stat1Lbl := MainGui.AddText("x46 y228 w170 h15 Background131926 c8E9AA8", "⏱   MATCH TIME")
Stat1Lbl.SetFont("s8 Bold", "Segoe UI")
GameValue := MainGui.AddText("x46 y245 w170 h28 Background131926 cF8FAFC", "08:00")
GameValue.SetFont("s15 Bold", "Segoe UI")
Stat1Sub := MainGui.AddText("x46 y275 w170 h15 Background131926 c566273", "in-game duration")
Stat1Sub.SetFont("s8", "Segoe UI")

Stat2Pic := AddCustomPicture("x249 y218 w202 h84", hStatCard2)
Stat2Lbl := MainGui.AddText("x265 y228 w170 h15 Background131926 c8E9AA8", "⏳   LOBBY DELAY")
Stat2Lbl.SetFont("s8 Bold", "Segoe UI")
LobbyValue := MainGui.AddText("x265 y245 w170 h28 Background131926 cF8FAFC", "00:15")
LobbyValue.SetFont("s15 Bold", "Segoe UI")
Stat2Sub := MainGui.AddText("x265 y275 w170 h15 Background131926 c566273", "return cooldown")
Stat2Sub.SetFont("s8", "Segoe UI")

Stat3Pic := AddCustomPicture("x468 y218 w202 h84", hStatCard3)
Stat3Lbl := MainGui.AddText("x484 y228 w170 h15 Background131926 c8E9AA8", "🎯   SESSION ROUNDS")
Stat3Lbl.SetFont("s8 Bold", "Segoe UI")
RoundsValue := MainGui.AddText("x484 y245 w170 h28 Background131926 cF8FAFC", "0")
RoundsValue.SetFont("s15 Bold", "Segoe UI")
Stat3Sub := MainGui.AddText("x484 y275 w170 h15 Background131926 c566273", "rounds this session")
Stat3Sub.SetFont("s8", "Segoe UI")

; Row 2: Lifetime & Session Time Metric Cards
Stat4Pic := AddCustomPicture("x30 y312 w202 h84", hStatCard4)
Stat4Lbl := MainGui.AddText("x46 y322 w170 h15 Background131926 c8E9AA8", "⌛   SESSION TIME")
Stat4Lbl.SetFont("s8 Bold", "Segoe UI")
SessionTimeValue := MainGui.AddText("x46 y339 w170 h28 Background131926 cF8FAFC", "00:00:00")
SessionTimeValue.SetFont("s15 Bold", "Segoe UI")
Stat4Sub := MainGui.AddText("x46 y369 w170 h15 Background131926 c566273", "active queue duration")
Stat4Sub.SetFont("s8", "Segoe UI")

Stat5Pic := AddCustomPicture("x249 y312 w202 h84", hStatCard5)
Stat5Lbl := MainGui.AddText("x265 y322 w170 h15 Background131926 c8E9AA8", "👑   TOTAL ROUNDS")
Stat5Lbl.SetFont("s8 Bold", "Segoe UI")
TotalRoundsValue := MainGui.AddText("x265 y339 w170 h28 Background131926 cF8FAFC", String(initTotalRounds))
TotalRoundsValue.SetFont("s15 Bold", "Segoe UI")
Stat5Sub := MainGui.AddText("x265 y369 w170 h15 Background131926 c566273", "all-time completed")
Stat5Sub.SetFont("s8", "Segoe UI")

Stat6Pic := AddCustomPicture("x468 y312 w202 h84", hStatCard6)
Stat6Lbl := MainGui.AddText("x484 y322 w170 h15 Background131926 c8E9AA8", "🌐   TOTAL RUNTIME")
Stat6Lbl.SetFont("s8 Bold", "Segoe UI")
TotalRuntimeValue := MainGui.AddText("x484 y339 w170 h28 Background131926 cF8FAFC", FormatRuntime(initTotalRuntimeSec))
TotalRuntimeValue.SetFont("s15 Bold", "Segoe UI")
Stat6Sub := MainGui.AddText("x484 y369 w170 h15 Background131926 c566273", "lifetime queue execution")
Stat6Sub.SetFont("s8", "Segoe UI")

; Hero Action Button
hStartCurBmp := MakeStartBtnBmp(false, startHotkey)
StartBtn := AddCustomPicture("x30 y408 w640 h56", hStartCurBmp)
StartBtn.OnEvent("Click", (*) => ToggleRunning())
ClickableHwnds[StartBtn.Hwnd] := true

; Hotkey Footer Strip
FooterPic := AddCustomPicture("x30 y472 w640 h44", hFooterStrip)
HomeHint := MainGui.AddText("x30 y484 w640 h20 Background101520 c8E9AA8 Center", "[ " StrUpper(startHotkey) " ]  START / STOP      •      [ F9 ]  COPY COORDS      •      [ F10 ]  EXIT")
HomeHint.SetFont("s8 Bold", "Segoe UI")

; Multitasking Indicator Line
HomeMultitaskTag := MainGui.AddText("x30 y524 w640 h20 Background0B0E14 c8E9AA8 Center", "⚡ SMART MULTITASKING: DISABLED  (Enable in Settings to use PC during matches)")
HomeMultitaskTag.SetFont("s8 Bold", "Segoe UI")

HomeControls := [HeroPic, StatusStripe, StatusEyebrow, StatusDot, StatusText, PhaseText, Divider, TimerLabel, TimerText, TimerSub
    , Stat1Pic, Stat1Lbl, GameValue, Stat1Sub
    , Stat2Pic, Stat2Lbl, LobbyValue, Stat2Sub
    , Stat3Pic, Stat3Lbl, RoundsValue, Stat3Sub
    , Stat4Pic, Stat4Lbl, SessionTimeValue, Stat4Sub
    , Stat5Pic, Stat5Lbl, TotalRoundsValue, Stat5Sub
    , Stat6Pic, Stat6Lbl, TotalRuntimeValue, Stat6Sub
    , StartBtn, FooterPic, HomeHint, HomeMultitaskTag]

; ==========================================================
; PAGE 2: SETTINGS
; ==========================================================

; Card 1: Cycle Timings & Keybind
Card1Pic := AddCustomPicture("x30 y74 w640 h112 Hidden", hSettingsCard1)
TimingHead := MainGui.AddText("x50 y86 w500 h18 Background131926 cF8FAFC Hidden", "CYCLE TIMINGS && HOTKEY")
TimingHead.SetFont("s9 Bold", "Segoe UI")
TimingSub := MainGui.AddText("x50 y104 w500 h16 Background131926 c8E9AA8 Hidden", "Adjust active match duration, lobby return delay, and hotkey toggle.")
TimingSub.SetFont("s8", "Segoe UI")

; Match Duration Box
GameLabel := MainGui.AddText("x50 y122 w130 h16 Background131926 c8E9AA8 Hidden", "MATCH DURATION")
GameLabel.SetFont("s8 Bold", "Segoe UI")
GameBoxPic := AddCustomPicture("x50 y140 w102 h34 Hidden", hInputBox_Duration)
GameEdit := MainGui.AddEdit("x56 y146 w90 h22 -VScroll -E0x200 Background182030 cF8FAFC Center Hidden", String(initGameMin))
GameEdit.SetFont("s11 Bold", "Segoe UI")
GameBoxPic.OnEvent("Click", (*) => (ControlFocus(GameEdit), SelectAllText(GameEdit)))
GameUnit := MainGui.AddText("x160 y148 w34 h20 Background131926 c8E9AA8 Hidden", "min")
GameUnit.SetFont("s9 Bold", "Segoe UI")

; Lobby Delay Box
LobbyLabel := MainGui.AddText("x240 y122 w130 h16 Background131926 c8E9AA8 Hidden", "LOBBY DELAY")
LobbyLabel.SetFont("s8 Bold", "Segoe UI")
LobbyBoxPic := AddCustomPicture("x240 y140 w102 h34 Hidden", hInputBox_Lobby)
LobbyEdit := MainGui.AddEdit("x246 y146 w90 h22 -VScroll -E0x200 Background182030 cF8FAFC Center Hidden", String(initLobbySec))
LobbyEdit.SetFont("s11 Bold", "Segoe UI")
LobbyBoxPic.OnEvent("Click", (*) => (ControlFocus(LobbyEdit), SelectAllText(LobbyEdit)))
LobbyUnit := MainGui.AddText("x350 y148 w34 h20 Background131926 c8E9AA8 Hidden", "sec")
LobbyUnit.SetFont("s9 Bold", "Segoe UI")

; Keybind Selector Pills
HotkeyLabel := MainGui.AddText("x440 y122 w200 h16 Background131926 c8E9AA8 Hidden", "START / STOP KEY")
HotkeyLabel.SetFont("s8 Bold", "Segoe UI")
KeyBtn_F8 := AddCustomPicture("x440 y140 w52 h34 Hidden", initHotkey = "F8" ? hPillActive_F8 : hPillInactive_F8)
KeyBtn_F8.OnEvent("Click", (*) => SelectKey("F8"))
ClickableHwnds[KeyBtn_F8.Hwnd] := true

KeyBtn_L := AddCustomPicture("x498 y140 w52 h34 Hidden", initHotkey = "L" ? hPillActive_L : hPillInactive_L)
KeyBtn_L.OnEvent("Click", (*) => SelectKey("L"))
ClickableHwnds[KeyBtn_L.Hwnd] := true

KeyBtn_9 := AddCustomPicture("x556 y140 w52 h34 Hidden", initHotkey = "9" ? hPillActive_9 : hPillInactive_9)
KeyBtn_9.OnEvent("Click", (*) => SelectKey("9"))
ClickableHwnds[KeyBtn_9.Hwnd] := true

; Card 2: Smart Multitasking (PC Background Use)
Card2Pic := AddCustomPicture("x30 y194 w640 h94 Hidden", hSettingsCard2)
MultiHead := MainGui.AddText("x50 y204 w500 h18 Background131926 cF8FAFC Hidden", "SMART MULTITASKING (BACKGROUND PC USE)")
MultiHead.SetFont("s9 Bold", "Segoe UI")
MultiSub := MainGui.AddText("x50 y222 w580 h16 Background131926 c8E9AA8 Hidden", "Restores active window and cursor position after each action to allow normal PC use.")
MultiSub.SetFont("s8", "Segoe UI")

; Smart Mode Toggle Pills
SmartLabel := MainGui.AddText("x50 y240 w150 h14 Background131926 c8E9AA8 Hidden", "SMART MODE")
SmartLabel.SetFont("s8 Bold", "Segoe UI")
SmartBtn_On := AddCustomPicture("x50 y256 w80 h28 Hidden", initSmartRestore = 1 ? hPillActive_SmartOn : hPillInactive_SmartOn)
SmartBtn_On.OnEvent("Click", (*) => SelectSmartRestore(1))
ClickableHwnds[SmartBtn_On.Hwnd] := true

SmartBtn_Off := AddCustomPicture("x136 y256 w90 h28 Hidden", initSmartRestore = 0 ? hPillActive_SmartOff : hPillInactive_SmartOff)
SmartBtn_Off.OnEvent("Click", (*) => SelectSmartRestore(0))
ClickableHwnds[SmartBtn_Off.Hwnd] := true

; Audio Pre-alert Toggle Pills
AudioLabel := MainGui.AddText("x250 y240 w160 h14 Background131926 c8E9AA8 Hidden", "AUDIO PRE-ALERT (3s)")
AudioLabel.SetFont("s8 Bold", "Segoe UI")
AudioBtn_On := AddCustomPicture("x250 y256 w78 h28 Hidden", initAudioAlert = 1 ? hPillActive_AudioOn : hPillInactive_AudioOn)
AudioBtn_On.OnEvent("Click", (*) => SelectAudioAlert(1))
ClickableHwnds[AudioBtn_On.Hwnd] := true

AudioBtn_Off := AddCustomPicture("x334 y256 w70 h28 Hidden", initAudioAlert = 0 ? hPillActive_AudioOff : hPillInactive_AudioOff)
AudioBtn_Off.OnEvent("Click", (*) => SelectAudioAlert(0))
ClickableHwnds[AudioBtn_Off.Hwnd] := true

; Multi Info Tag
MultiInfo := MainGui.AddText("x424 y244 w236 h40 Background131926 c566273 Hidden", "⚡ 3s countdown warning + instant window & cursor position restore.")
MultiInfo.SetFont("s8", "Segoe UI")

; Card 3: Fortnite Coordinates & Resolution Presets
Card3Pic := AddCustomPicture("x30 y296 w640 h144 Hidden", hSettingsCard3)
CoordHead := MainGui.AddText("x50 y306 w500 h18 Background131926 cF8FAFC Hidden", "FORTNITE BUTTON COORDINATES")
CoordHead.SetFont("s9 Bold", "Segoe UI")
CoordSub := MainGui.AddText("x50 y324 w500 h16 Background131926 c8E9AA8 Hidden", "Canvas pixel coordinates. Automatically offsets to any monitor Fortnite is on.")
CoordSub.SetFont("s8", "Segoe UI")

; Row 2: Resolution Preset Buttons
PresetLbl := MainGui.AddText("x50 y346 w65 h20 Background131926 c8E9AA8 Hidden", "PRESETS:")
PresetLbl.SetFont("s8 Bold", "Segoe UI")

initPreset := DetectInitialPreset()

Btn_1080p := AddCustomPicture("x118 y342 w68 h26 Hidden", initPreset = "1080" ? hPillActive_1080p : hPillInactive_1080p)
Btn_1080p.OnEvent("Click", (*) => ApplyPreset("1080"))
ClickableHwnds[Btn_1080p.Hwnd] := true

Btn_1440p := AddCustomPicture("x192 y342 w84 h26 Hidden", initPreset = "1440" ? hPillActive_1440p : hPillInactive_1440p)
Btn_1440p.OnEvent("Click", (*) => ApplyPreset("1440"))
ClickableHwnds[Btn_1440p.Hwnd] := true

Btn_4K := AddCustomPicture("x282 y342 w54 h26 Hidden", initPreset = "4K" ? hPillActive_4K : hPillInactive_4K)
Btn_4K.OnEvent("Click", (*) => ApplyPreset("4K"))
ClickableHwnds[Btn_4K.Hwnd] := true

Btn_Auto := AddCustomPicture("x342 y342 w108 h26 Hidden", hBtn_Auto)
Btn_Auto.OnEvent("Click", (*) => ApplyAutoDetect())
ClickableHwnds[Btn_Auto.Hwnd] := true

PresetHint := MainGui.AddText("x458 y347 w210 h16 Background131926 c566273 Hidden", "Click to auto-fill coordinates")
PresetHint.SetFont("s8", "Segoe UI")

; Row 3: Coordinate Inputs
; Play Button Coordinates (Col 1)
PlayLabel := MainGui.AddText("x50 y374 w180 h14 Background131926 c8E9AA8 Hidden", "PLAY BUTTON (LOBBY)")
PlayLabel.SetFont("s8 Bold", "Segoe UI")

PlayXTag := MainGui.AddText("x50 y393 w16 h32 Background131926 c8E9AA8 Center +0x200 Hidden", "X")
PlayXTag.SetFont("s9 Bold", "Segoe UI")
PlayXBoxPic := AddCustomPicture("x68 y392 w72 h34 Hidden", hInputBox_PlayX)
PlayX := MainGui.AddEdit("x72 y398 w64 h22 -VScroll -E0x200 Background182030 cF8FAFC Center Hidden", String(initPlayX))
PlayX.SetFont("s10 Bold", "Segoe UI")
PlayXBoxPic.OnEvent("Click", (*) => (ControlFocus(PlayX), SelectAllText(PlayX)))

PlayYTag := MainGui.AddText("x144 y393 w16 h32 Background131926 c8E9AA8 Center +0x200 Hidden", "Y")
PlayYTag.SetFont("s9 Bold", "Segoe UI")
PlayYBoxPic := AddCustomPicture("x162 y392 w72 h34 Hidden", hInputBox_PlayY)
PlayY := MainGui.AddEdit("x166 y398 w64 h22 -VScroll -E0x200 Background182030 cF8FAFC Center Hidden", String(initPlayY))
PlayY.SetFont("s10 Bold", "Segoe UI")
PlayYBoxPic.OnEvent("Click", (*) => (ControlFocus(PlayY), SelectAllText(PlayY)))

; Options / Menu Button Coordinates (Col 2)
OptionsLabel := MainGui.AddText("x254 y374 w180 h14 Background131926 c8E9AA8 Hidden", "OPTIONS MENU (ESC)")
OptionsLabel.SetFont("s8 Bold", "Segoe UI")

OptionsXTag := MainGui.AddText("x254 y393 w16 h32 Background131926 c8E9AA8 Center +0x200 Hidden", "X")
OptionsXTag.SetFont("s9 Bold", "Segoe UI")
OptionsXBoxPic := AddCustomPicture("x272 y392 w72 h34 Hidden", hInputBox_OptX)
OptionsX := MainGui.AddEdit("x276 y398 w64 h22 -VScroll -E0x200 Background182030 cF8FAFC Center Hidden", String(initOptX))
OptionsX.SetFont("s10 Bold", "Segoe UI")
OptionsXBoxPic.OnEvent("Click", (*) => (ControlFocus(OptionsX), SelectAllText(OptionsX)))

OptionsYTag := MainGui.AddText("x348 y393 w16 h32 Background131926 c8E9AA8 Center +0x200 Hidden", "Y")
OptionsYTag.SetFont("s9 Bold", "Segoe UI")
OptionsYBoxPic := AddCustomPicture("x366 y392 w72 h34 Hidden", hInputBox_OptY)
OptionsY := MainGui.AddEdit("x370 y398 w64 h22 -VScroll -E0x200 Background182030 cF8FAFC Center Hidden", String(initOptY))
OptionsY.SetFont("s10 Bold", "Segoe UI")
OptionsYBoxPic.OnEvent("Click", (*) => (ControlFocus(OptionsY), SelectAllText(OptionsY)))

; Leave Button Coordinates (Col 3)
LeaveLabel := MainGui.AddText("x458 y374 w180 h14 Background131926 c8E9AA8 Hidden", "RETURN TO LOBBY")
LeaveLabel.SetFont("s8 Bold", "Segoe UI")

LeaveXTag := MainGui.AddText("x458 y393 w16 h32 Background131926 c8E9AA8 Center +0x200 Hidden", "X")
LeaveXTag.SetFont("s9 Bold", "Segoe UI")
LeaveXBoxPic := AddCustomPicture("x476 y392 w72 h34 Hidden", hInputBox_LeaveX)
LeaveX := MainGui.AddEdit("x480 y398 w64 h22 -VScroll -E0x200 Background182030 cF8FAFC Center Hidden", String(initLeaveX))
LeaveX.SetFont("s10 Bold", "Segoe UI")
LeaveXBoxPic.OnEvent("Click", (*) => (ControlFocus(LeaveX), SelectAllText(LeaveX)))

LeaveYTag := MainGui.AddText("x552 y393 w16 h32 Background131926 c8E9AA8 Center +0x200 Hidden", "Y")
LeaveYTag.SetFont("s9 Bold", "Segoe UI")
LeaveYBoxPic := AddCustomPicture("x570 y392 w72 h34 Hidden", hInputBox_LeaveY)
LeaveY := MainGui.AddEdit("x574 y398 w64 h22 -VScroll -E0x200 Background182030 cF8FAFC Center Hidden", String(initLeaveY))
LeaveY.SetFont("s10 Bold", "Segoe UI")
LeaveYBoxPic.OnEvent("Click", (*) => (ControlFocus(LeaveY), SelectAllText(LeaveY)))

; Auto-select all text on click or focus for convenient numeric input & instant deletion
SelectAllText(ctrlOrHwnd, *) {
    h := IsObject(ctrlOrHwnd) ? ctrlOrHwnd.Hwnd : ctrlOrHwnd
    PostMessage 0x00B1, 0, -1, h ; EM_SETSEL: select all
}

SettingsEdits := Map(
    GameEdit.Hwnd, GameEdit,
    LobbyEdit.Hwnd, LobbyEdit,
    PlayX.Hwnd, PlayX,
    PlayY.Hwnd, PlayY,
    OptionsX.Hwnd, OptionsX,
    OptionsY.Hwnd, OptionsY,
    LeaveX.Hwnd, LeaveX,
    LeaveY.Hwnd, LeaveY
)
for h, ctrl in SettingsEdits {
    ctrl.OnEvent("Focus", SelectAllText)
}

; Auto-split pasted coordinates into X and Y
HandleCoordChange(ctrlX, ctrlY, label, ctrl, *) {
    static inChange := false
    if inChange
        return
    val := Trim(ctrl.Value)
    if RegExMatch(val, "(\d+)\D+(\d+)", &m) {
        inChange := true
        ctrlX.Value := m[1]
        ctrlY.Value := m[2]
        inChange := false
        SetPresetHighlight("")
        ToolTip "Coordinates auto-split (" label "):`nX: " m[1] "   Y: " m[2]
        SetTimer () => ToolTip(), -2000
    }
}
PlayX.OnEvent("Change", HandleCoordChange.Bind(PlayX, PlayY, "Play"))
PlayY.OnEvent("Change", HandleCoordChange.Bind(PlayX, PlayY, "Play"))
OptionsX.OnEvent("Change", HandleCoordChange.Bind(OptionsX, OptionsY, "Options"))
OptionsY.OnEvent("Change", HandleCoordChange.Bind(OptionsX, OptionsY, "Options"))
LeaveX.OnEvent("Change", HandleCoordChange.Bind(LeaveX, LeaveY, "Lobby"))
LeaveY.OnEvent("Change", HandleCoordChange.Bind(LeaveX, LeaveY, "Lobby"))

; Action Buttons
SaveBtn := AddCustomPicture("x30 y446 w310 h42 Hidden", hSaveBtn)
SaveBtn.OnEvent("Click", (*) => SaveSettings())
ClickableHwnds[SaveBtn.Hwnd] := true

ResetBtn := AddCustomPicture("x360 y446 w310 h42 Hidden", hResetBtn)
ResetBtn.OnEvent("Click", (*) => ResetSettings())
ClickableHwnds[ResetBtn.Hwnd] := true

ResetStatsBtn := AddCustomPicture("x230 y496 w240 h30 Hidden", hResetStatsBtn)
ResetStatsBtn.OnEvent("Click", (*) => ResetLifetimeStats())
ClickableHwnds[ResetStatsBtn.Hwnd] := true

SettingsHint := MainGui.AddText("x30 y532 w640 h16 Background0B0E14 c566273 Center Hidden", "Changes take effect starting on the next queue cycle.")
SettingsHint.SetFont("s8", "Segoe UI")

SettingsControls := [Card1Pic, TimingHead, TimingSub, GameLabel, GameBoxPic, GameEdit, GameUnit
    , LobbyLabel, LobbyBoxPic, LobbyEdit, LobbyUnit
    , HotkeyLabel, KeyBtn_F8, KeyBtn_L, KeyBtn_9
    , Card2Pic, MultiHead, MultiSub, SmartLabel, SmartBtn_On, SmartBtn_Off, AudioLabel, AudioBtn_On, AudioBtn_Off, MultiInfo
    , Card3Pic, CoordHead, CoordSub, PresetLbl, Btn_1080p, Btn_1440p, Btn_4K, Btn_Auto, PresetHint
    , PlayLabel, PlayXTag, PlayXBoxPic, PlayX, PlayYTag, PlayYBoxPic, PlayY
    , OptionsLabel, OptionsXTag, OptionsXBoxPic, OptionsX, OptionsYTag, OptionsYBoxPic, OptionsY
    , LeaveLabel, LeaveXTag, LeaveXBoxPic, LeaveX, LeaveYTag, LeaveYBoxPic, LeaveY
    , SaveBtn, ResetBtn, ResetStatsBtn, SettingsHint]

; ==========================================================
; Window Events & Dragging
; ==========================================================
MainGui.OnEvent("Close", (*) => ExitApp())
MainGui.OnEvent("Escape", (*) => ToggleRunning())

; Native Windows 11 Dragging
OnMessage(0x84, WM_NCHITTEST)
WM_NCHITTEST(wParam, lParam, msg, hwnd) {
    global MainGui
    ptX := lParam << 48 >> 48
    ptY := lParam << 32 >> 48
    WinGetPos &wx, &wy,,, "ahk_id " MainGui.Hwnd
    relX := ptX - wx
    relY := ptY - wy
    if relY <= 60 {
        if (relX >= 26 && relX <= 240 && relY >= 14 && relY <= 48)
            return 1 ; Let Brand title & version badge receive clicks to open repository
        if (relX >= 270 && relX <= 570) || relX >= 610
            return 1 ; Let tabs and control buttons receive clicks
        return 2 ; Top header drag (HTCAPTION)
    }
}

OnMessage(0x201, WM_LBUTTONDOWN)
WM_LBUTTONDOWN(wParam, lParam, msg, hwnd) {
    global MainGui, MinBtn, CloseBtn, NavHome, NavSettings, Brand, VersionBadge
    if (hwnd == MinBtn.Hwnd || hwnd == CloseBtn.Hwnd || hwnd == NavHome.Hwnd || hwnd == NavSettings.Hwnd || hwnd == Brand.Hwnd || hwnd == VersionBadge.Hwnd)
        return
    CoordMode "Mouse", "Window"
    MouseGetPos &mx, &my
    CoordMode "Mouse", "Screen"
    if (my <= 60 && !(mx >= 26 && mx <= 240 && my >= 14 && my <= 48) && !(mx >= 270 && mx <= 570) && mx < 610) {
        DllCall("user32\ReleaseCapture")
        PostMessage 0xA1, 2,,, "ahk_id " MainGui.Hwnd ; WM_NCLBUTTONDOWN, HTCAPTION
    }
}

; Hover Hand Cursor
OnMessage(0x0020, WM_SETCURSOR)
WM_SETCURSOR(wParam, lParam, msg, hwnd) {
    global hHandCursor, ClickableHwnds
    if ClickableHwnds.Has(wParam) {
        DllCall("user32\SetCursor", "Ptr", hHandCursor)
        return true
    }
}

; Auto-select all text on mouse click in any settings input box
OnMessage(0x0202, WM_LBUTTONUP)
WM_LBUTTONUP(wParam, lParam, msg, hwnd) {
    global SettingsEdits
    if SettingsEdits.Has(hwnd) {
        SelectAllText(hwnd)
    }
}

; ==========================================================
; Show Window & Apply Native Windows 11 Styling
; ==========================================================
MainGui.Show("w700 h565")

; Windows 11 Native Rounded Corners via DWM (DWMWA_WINDOW_CORNER_PREFERENCE = 33, DWMWCP_ROUND = 2)
try DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", MainGui.Hwnd, "UInt", 33, "Int*", 2, "UInt", 4)

; Windows 11 Native Drop Shadow
margins := Buffer(16, 0)
NumPut("Int", 1, margins, 0), NumPut("Int", 1, margins, 4), NumPut("Int", 1, margins, 8), NumPut("Int", 1, margins, 12)
try DllCall("dwmapi\DwmExtendFrameIntoClientArea", "Ptr", MainGui.Hwnd, "Ptr", margins)

; Periodic UI Updater (Timer 250ms with state-diffing)
SetTimer UpdateUI, 250

; Global Hotkeys
HotIf HotkeyContext
Hotkey(startHotkey, ToggleRunning, "On")
HotIf

; Smart Multi-Monitor F9: automatically calculates coordinates relative to Fortnite canvas
F9:: {
    CoordMode "Mouse", "Screen"
    MouseGetPos &mx, &my
    fnExe := "ahk_exe FortniteClient-Win64-Shipping.exe"

    ox := 0, oy := 0
    isInsideGame := false
    if WinActive(fnExe) {
        if GetFortniteOrigin(&fox, &foy, &fw, &fh) {
            ox := fox
            oy := foy
            isInsideGame := true
        }
    }

    relX := mx - ox
    relY := my - oy

    A_Clipboard := relX ", " relY
    if isInsideGame && (ox != 0 || oy != 0) {
        ToolTip "Coordinates copied (Fortnite Canvas):`nX: " relX "   Y: " relY "`n(Adjusted for display at X: " ox ", Y: " oy ")"
    } else {
        ToolTip "Coordinates copied:`nX: " relX "   Y: " relY
    }
    SetTimer () => ToolTip(), -2500
}
F10::ExitApp

; Smart paste inside GUI: automatically splits "X, Y" (e.g. copied via F9) into separate X and Y fields
#HotIf WinActive("ahk_id " MainGui.Hwnd)
$^v:: {
    global PlayX, PlayY, OptionsX, OptionsY, LeaveX, LeaveY, MainGui
    fCtrl := MainGui.FocusedCtrl
    clip := Trim(A_Clipboard)
    if (fCtrl && RegExMatch(clip, "(\d+)\D+(\d+)", &m)) {
        if (fCtrl == PlayX || fCtrl == PlayY) {
            PlayX.Value := m[1]
            PlayY.Value := m[2]
            SetPresetHighlight("")
            ToolTip "Coordinates auto-split (Play):`nX: " m[1] "   Y: " m[2]
            SetTimer () => ToolTip(), -2000
            return
        }
        if (fCtrl == OptionsX || fCtrl == OptionsY) {
            OptionsX.Value := m[1]
            OptionsY.Value := m[2]
            SetPresetHighlight("")
            ToolTip "Coordinates auto-split (Options):`nX: " m[1] "   Y: " m[2]
            SetTimer () => ToolTip(), -2000
            return
        }
        if (fCtrl == LeaveX || fCtrl == LeaveY) {
            LeaveX.Value := m[1]
            LeaveY.Value := m[2]
            SetPresetHighlight("")
            ToolTip "Coordinates auto-split (Lobby):`nX: " m[1] "   Y: " m[2]
            SetTimer () => ToolTip(), -2000
            return
        }
    }
    Send "^v"
}

; Ensure Backspace always deletes immediately even if caret lands at position 0
$Backspace:: {
    global MainGui, SettingsEdits
    fCtrl := MainGui.FocusedCtrl
    if (fCtrl && SettingsEdits.Has(fCtrl.Hwnd)) {
        buf := Buffer(8, 0)
        SendMessage 0x00B0, buf.Ptr, buf.Ptr + 4, fCtrl.Hwnd ; EM_GETSEL
        s := NumGet(buf, 0, "UInt"), e := NumGet(buf, 4, "UInt")
        if (s == 0 && e == 0) {
            val := fCtrl.Value
            if (StrLen(val) > 0) {
                fCtrl.Value := SubStr(val, 1, -1)
                PostMessage 0x00B1, StrLen(fCtrl.Value), StrLen(fCtrl.Value), fCtrl.Hwnd
                return
            }
        }
    }
    Send "{Backspace}"
}
#HotIf

; ==========================================================
; UI Navigation & Control Functions
; ==========================================================
ShowPage(page) {
    global currentPage, HomeControls, SettingsControls, NavHome, NavSettings
    global hTabDashActive, hTabDashInactive, hTabSetActive, hTabSetInactive
    if (page = currentPage)
        return
    currentPage := page

    if (page = "home") {
        for ctrl in SettingsControls
            ctrl.Opt("+Hidden")
        for ctrl in HomeControls
            ctrl.Opt("-Hidden")
        SetCtrlBitmap(NavHome, hTabDashActive)
        SetCtrlBitmap(NavSettings, hTabSetInactive)
    } else {
        for ctrl in HomeControls
            ctrl.Opt("+Hidden")
        for ctrl in SettingsControls
            ctrl.Opt("-Hidden")
        SetCtrlBitmap(NavHome, hTabDashInactive)
        SetCtrlBitmap(NavSettings, hTabSetActive)
    }
}

SelectKey(key) {
    global selectedHotkey, KeyBtn_F8, KeyBtn_L, KeyBtn_9
    global hPillActive_F8, hPillInactive_F8, hPillActive_L, hPillInactive_L, hPillActive_9, hPillInactive_9
    selectedHotkey := key
    SetCtrlBitmap(KeyBtn_F8, key = "F8" ? hPillActive_F8 : hPillInactive_F8)
    SetCtrlBitmap(KeyBtn_L,  key = "L"  ? hPillActive_L  : hPillInactive_L)
    SetCtrlBitmap(KeyBtn_9,  key = "9"  ? hPillActive_9  : hPillInactive_9)
}

SelectSmartRestore(val) {
    global selectedSmartRestore, SmartBtn_On, SmartBtn_Off
    global hPillActive_SmartOn, hPillInactive_SmartOn, hPillActive_SmartOff, hPillInactive_SmartOff
    selectedSmartRestore := val
    SetCtrlBitmap(SmartBtn_On,  val = 1 ? hPillActive_SmartOn  : hPillInactive_SmartOn)
    SetCtrlBitmap(SmartBtn_Off, val = 0 ? hPillActive_SmartOff : hPillInactive_SmartOff)
}

SelectAudioAlert(val) {
    global selectedAudioAlert, AudioBtn_On, AudioBtn_Off
    global hPillActive_AudioOn, hPillInactive_AudioOn, hPillActive_AudioOff, hPillInactive_AudioOff
    selectedAudioAlert := val
    SetCtrlBitmap(AudioBtn_On,  val = 1 ? hPillActive_AudioOn  : hPillInactive_AudioOn)
    SetCtrlBitmap(AudioBtn_Off, val = 0 ? hPillActive_AudioOff : hPillInactive_AudioOff)
}

DetectInitialPreset() {
    global initPlayX, initPlayY, initOptX, initOptY
    if (initPlayX = 262 && initPlayY = 912 && initOptX = 1678 && initOptY = 73)
        return "1080"
    if (initPlayX = 349 && initPlayY = 1216 && initOptX = 2237 && initOptY = 97)
        return "1440"
    if (initPlayX = 524 && initPlayY = 1824 && initOptX = 3356 && initOptY = 146)
        return "4K"
    return ""
}

SetPresetHighlight(activePreset) {
    global Btn_1080p, Btn_1440p, Btn_4K
    global hPillActive_1080p, hPillInactive_1080p
    global hPillActive_1440p, hPillInactive_1440p
    global hPillActive_4K, hPillInactive_4K

    SetCtrlBitmap(Btn_1080p, activePreset = "1080" ? hPillActive_1080p : hPillInactive_1080p)
    SetCtrlBitmap(Btn_1440p, activePreset = "1440" ? hPillActive_1440p : hPillInactive_1440p)
    SetCtrlBitmap(Btn_4K,    activePreset = "4K"   ? hPillActive_4K    : hPillInactive_4K)
}

ApplyPreset(name) {
    global PlayX, PlayY, OptionsX, OptionsY, LeaveX, LeaveY

    if (name = "1080") {
        PlayX.Value := "262"
        PlayY.Value := "912"
        OptionsX.Value := "1678"
        OptionsY.Value := "73"
        LeaveX.Value := "1556"
        LeaveY.Value := "173"
        SetPresetHighlight("1080")
        ToolTip "Applied 1080p (FHD) preset!`nPlay: (262, 912)  Options: (1678, 73)  Leave: (1556, 173)"
    } else if (name = "1440") {
        PlayX.Value := "349"
        PlayY.Value := "1216"
        OptionsX.Value := "2237"
        OptionsY.Value := "97"
        LeaveX.Value := "2075"
        LeaveY.Value := "231"
        SetPresetHighlight("1440")
        ToolTip "Applied 1440p (2K) preset!`nPlay: (349, 1216)  Options: (2237, 97)  Leave: (2075, 231)"
    } else if (name = "4K") {
        PlayX.Value := "524"
        PlayY.Value := "1824"
        OptionsX.Value := "3356"
        OptionsY.Value := "146"
        LeaveX.Value := "3113"
        LeaveY.Value := "347"
        SetPresetHighlight("4K")
        ToolTip "Applied 4K (UHD) preset!`nPlay: (524, 1824)  Options: (3356, 146)  Leave: (3113, 347)"
    }
    SetTimer () => ToolTip(), -2500
}

; Auto-detect display resolution and automatically adapt to Fortnite canvas on any monitor
ApplyAutoDetect() {
    global PlayX, PlayY, OptionsX, OptionsY, LeaveX, LeaveY
    GetFortniteOrigin &ox, &oy, &sw, &sh

    if (sw = 1920 && sh = 1080) {
        ApplyPreset("1080")
        return
    } else if (sw = 2560 && sh = 1440) {
        ApplyPreset("1440")
        return
    } else if (sw = 3840 && sh = 2160) {
        ApplyPreset("4K")
        return
    }

    ; Scale dynamically for custom or ultrawide resolution
    pX := Round(349 * (sw / 2560))
    pY := Round(1216 * (sh / 1440))
    optX := Round(2237 * (sw / 2560))
    optY := Round(97 * (sh / 1440))
    lvX := Round(2075 * (sw / 2560))
    lvY := Round(231 * (sh / 1440))

    PlayX.Value := String(pX)
    PlayY.Value := String(pY)
    OptionsX.Value := String(optX)
    OptionsY.Value := String(optY)
    LeaveX.Value := String(lvX)
    LeaveY.Value := String(lvY)

    SetPresetHighlight("")
    ToolTip "Auto-detected " sw "x" sh " display (Fortnite canvas)!`nCoordinates scaled & updated."
    SetTimer () => ToolTip(), -2500
}

SaveSettings() {
    global InGameTime, LobbyTime, GameEdit, LobbyEdit, PlayBtn, OptionsBtn, LeaveBtn
    global PlayX, PlayY, OptionsX, OptionsY, LeaveX, LeaveY, selectedHotkey, startHotkey, StartBtn, running, REG_SETTINGS
    global smartRestore, selectedSmartRestore, audioAlert, selectedAudioAlert

    gVal := Trim(GameEdit.Value)
    lVal := Trim(LobbyEdit.Value)
    pX := Trim(PlayX.Value)
    pY := Trim(PlayY.Value)
    optX := Trim(OptionsX.Value)
    optY := Trim(OptionsY.Value)
    lvX := Trim(LeaveX.Value)
    lvY := Trim(LeaveY.Value)

    if !IsInteger(gVal) || !IsInteger(lVal) || !IsInteger(pX) || !IsInteger(pY) || !IsInteger(optX) || !IsInteger(optY) || !IsInteger(lvX) || !IsInteger(lvY) {
        MsgBox "Please enter valid numbers in all fields.", "Invalid Settings", "Icon!"
        return
    }
    gameMinutes := Integer(gVal)
    lobbySeconds := Integer(lVal)
    if gameMinutes < 1 || gameMinutes > 180 || lobbySeconds < 0 || lobbySeconds > 600 {
        MsgBox "Enter valid values. Match: 1–180 minutes, lobby: 0–600 seconds.", "Invalid Settings", "Icon!"
        return
    }
    newHotkey := selectedHotkey
    if !(newHotkey = "L" || newHotkey = "9" || newHotkey = "F8") {
        MsgBox "Choose L, 9 or F8 for the Start / Stop hotkey.", "Invalid Hotkey", "Icon!"
        return
    }
    try {
        HotIf HotkeyContext
        Hotkey(newHotkey, ToggleRunning, "On")
        if startHotkey != newHotkey
            Hotkey(startHotkey, "Off")
        HotIf
    } catch as err {
        HotIf
        MsgBox "That key could not be assigned. Choose L, 9 or F8.`n`n" err.Message, "Invalid Hotkey", "Icon!"
        return
    }
    startHotkey := newHotkey

    InGameTime := gameMinutes * 60 * 1000
    LobbyTime := lobbySeconds * 1000
    PlayBtn := [Integer(pX), Integer(pY)]
    OptionsBtn := [Integer(optX), Integer(optY)]
    LeaveBtn := [Integer(lvX), Integer(lvY)]

    smartRestore := selectedSmartRestore
    audioAlert := selectedAudioAlert

    ; Persist settings in Windows Registry (no external files needed, 100% portable single EXE)
    try {
        RegWrite(Integer(pX), "REG_DWORD", REG_SETTINGS, "PlayX")
        RegWrite(Integer(pY), "REG_DWORD", REG_SETTINGS, "PlayY")
        RegWrite(Integer(optX), "REG_DWORD", REG_SETTINGS, "OptionsX")
        RegWrite(Integer(optY), "REG_DWORD", REG_SETTINGS, "OptionsY")
        RegWrite(Integer(lvX), "REG_DWORD", REG_SETTINGS, "LeaveX")
        RegWrite(Integer(lvY), "REG_DWORD", REG_SETTINGS, "LeaveY")
        RegWrite(gameMinutes, "REG_DWORD", REG_SETTINGS, "GameMinutes")
        RegWrite(lobbySeconds, "REG_DWORD", REG_SETTINGS, "LobbySeconds")
        RegWrite(newHotkey, "REG_SZ", REG_SETTINGS, "Hotkey")
        RegWrite(smartRestore, "REG_DWORD", REG_SETTINGS, "SmartRestore")
        RegWrite(audioAlert, "REG_DWORD", REG_SETTINGS, "AudioAlert")
    }

    ; Update Start button graphic with new hotkey
    hNewBmp := MakeStartBtnBmp(running, startHotkey)
    SetCtrlBitmap(StartBtn, hNewBmp, true)

    ToolTip "Settings saved successfully!"
    SetTimer () => ToolTip(), -1500
    UpdateUI()
}

ResetSettings() {
    global GameEdit, LobbyEdit, REG_SETTINGS, totalRounds, initTotalRuntimeSec, sessionActiveSec, activeStartTick, running
    GameEdit.Value := "8"
    LobbyEdit.Value := "15"
    SelectKey("F8")
    SelectSmartRestore(0)
    SelectAudioAlert(1)
    ApplyAutoDetect()
    savedTotalR := totalRounds
    currentRunSec := (running && activeStartTick) ? Floor((A_TickCount - activeStartTick) / 1000) : 0
    savedTotalSec := initTotalRuntimeSec + sessionActiveSec + currentRunSec
    try RegDeleteKey(REG_SETTINGS)
    try {
        RegWrite(savedTotalR, "REG_DWORD", REG_SETTINGS, "TotalRounds")
        RegWrite(savedTotalSec, "REG_DWORD", REG_SETTINGS, "TotalRuntimeSec")
    }
    SaveSettings()
}

ResetLifetimeStats() {
    result := MsgBox("Are you sure you want to reset all lifetime statistics?`n`nTotal Rounds and Total Runtime will be reset to 0.", "Reset Lifetime Stats", "YesNo Icon?")
    if (result = "Yes") {
        global totalRounds, initTotalRuntimeSec, sessionActiveSec, activeStartTick, running, REG_SETTINGS
        totalRounds := 0
        initTotalRuntimeSec := 0
        sessionActiveSec := 0
        if (running)
            activeStartTick := A_TickCount
        else
            activeStartTick := 0
        try {
            RegWrite(0, "REG_DWORD", REG_SETTINGS, "TotalRounds")
            RegWrite(0, "REG_DWORD", REG_SETTINGS, "TotalRuntimeSec")
        }
        UpdateUI()
        ToolTip "Lifetime stats reset to zero."
        SetTimer () => ToolTip(), -2000
    }
}

HotkeyContext(*) {
    global MainGui
    return !WinActive("ahk_id " MainGui.Hwnd)
}

ToggleRunning(*) {
    global running, phase, phaseTick, gameStartTick, activeStartTick, sessionActiveSec, initTotalRuntimeSec, REG_SETTINGS
    global matchInProgress, rounds, totalRounds
    running := !running
    if running {
        phase := "Starting queue..."
        phaseTick := A_TickCount
        gameStartTick := 0
        activeStartTick := A_TickCount
        SetTimer MainLoop, -10
    } else {
        phase := "Stopped"
        phaseTick := A_TickCount
        if (activeStartTick) {
            sessionActiveSec += Floor((A_TickCount - activeStartTick) / 1000)
            activeStartTick := 0
            try RegWrite(initTotalRuntimeSec + sessionActiveSec, "REG_DWORD", REG_SETTINGS, "TotalRuntimeSec")
        }
        if (matchInProgress) {
            matchInProgress := false
            rounds += 1
            totalRounds += 1
            try RegWrite(totalRounds, "REG_DWORD", REG_SETTINGS, "TotalRounds")
        }
        gameStartTick := 0
        ToolTip ; Clear any active countdown tooltip
    }
    UpdateUI()
}

; ----------------------------------------------------------
; Multi-Monitor Dynamic Origin Resolver
; Accurately resolves the virtual screen top-left coordinates of Fortnite
; ----------------------------------------------------------
GetFortniteOrigin(&origX, &origY, &winW, &winH) {
    fnExe := "ahk_exe FortniteClient-Win64-Shipping.exe"
    origX := 0
    origY := 0
    winW := A_ScreenWidth
    winH := A_ScreenHeight

    if WinExist(fnExe) {
        try {
            WinGetClientPos &cx, &cy, &cw, &ch, fnExe
            if (cw > 100 && ch > 100) {
                origX := cx
                origY := cy
                winW := cw
                winH := ch
                return true
            }
        }
        try {
            WinGetPos &wx, &wy, &ww, &wh, fnExe
            if (ww > 100 && wh > 100) {
                origX := wx
                origY := wy
                winW := ww
                winH := wh
                return true
            }
        }
    }
    return false
}

; ----------------------------------------------------------
; Reliable Foreground Window Activator
; Bypasses Windows Foreground Lock restrictions across multiple monitors
; ----------------------------------------------------------
ForceWinActivate(hwnd) {
    if !WinExist("ahk_id " hwnd)
        return false

    curHwnd := WinActive("A")
    if (curHwnd == hwnd)
        return true

    ; Attach this script thread to current foreground window thread so we have full foreground rights
    foreHwnd := DllCall("user32\GetForegroundWindow", "Ptr")
    foreTid := (foreHwnd ? DllCall("user32\GetWindowThreadProcessId", "Ptr", foreHwnd, "Ptr", 0, "UInt") : 0)
    appTid  := DllCall("kernel32\GetCurrentThreadId", "UInt")

    if (foreTid && appTid && foreTid != appTid)
        DllCall("user32\AttachThreadInput", "UInt", appTid, "UInt", foreTid, "Int", 1)

    ; SwitchToThisWindow bypasses foreground restrictions
    DllCall("user32\SwitchToThisWindow", "Ptr", hwnd, "Int", 1)
    DllCall("user32\BringWindowToTop", "Ptr", hwnd)
    DllCall("user32\SetForegroundWindow", "Ptr", hwnd)
    WinActivate "ahk_id " hwnd

    if (foreTid && appTid && foreTid != appTid)
        DllCall("user32\AttachThreadInput", "UInt", appTid, "UInt", foreTid, "Int", 0)

    try WinWaitActive("ahk_id " hwnd,, 1.5)
    Sleep 150
    return WinActive("ahk_id " hwnd)
}

MainLoop() {
    global running, PlayBtn, OptionsBtn, LeaveBtn, InGameTime, LoadTime, LobbyTime, rounds, totalRounds, REG_SETTINGS
    global phase, phaseTick, gameStartTick, matchInProgress
    while running {
        phase := "Searching for a match..."
        phaseTick := A_TickCount
        UpdateUI()
        DoPlayAction()
        if !running
            return
        matchInProgress := true
        if !WaitPhase(LoadTime, "Match loading...")
            return
        gameStartTick := A_TickCount
        if !WaitPhase(InGameTime, "In match", true)
            return
        phase := "Leaving match..."
        phaseTick := A_TickCount
        UpdateUI()
        DoLeaveAction()
        if (matchInProgress) {
            matchInProgress := false
            rounds += 1
            totalRounds += 1
            try RegWrite(totalRounds, "REG_DWORD", REG_SETTINGS, "TotalRounds")
        }
        gameStartTick := 0
        phase := "Lobby cooldown"
        phaseTick := A_TickCount
        UpdateUI()
        if !WaitPhase(LobbyTime, "Lobby cooldown", true)
            return
    }
}

DoPlayAction() {
    global PlayBtn, smartRestore, running
    if !running
        return

    fnExe := "ahk_exe FortniteClient-Win64-Shipping.exe"
    fnHwnd := WinExist(fnExe)
    userHwnd := 0
    savedX := 0, savedY := 0

    if (smartRestore && fnHwnd) {
        userHwnd := WinActive("A")
        CoordMode "Mouse", "Screen"
        MouseGetPos &savedX, &savedY
    }

    if fnHwnd {
        ; Pre-move cursor into Fortnite window on its monitor before activating
        GetFortniteOrigin &ox, &oy, &gw, &gh
        CoordMode "Mouse", "Screen"
        MouseMove ox + PlayBtn[1], oy + PlayBtn[2], 0
        Sleep 100
        ForceWinActivate(fnHwnd)
    }

    ClickAt(PlayBtn)

    if (smartRestore && fnHwnd && userHwnd && userHwnd != fnHwnd) {
        Sleep 250
        if WinExist("ahk_id " userHwnd)
            ForceWinActivate(userHwnd)
        CoordMode "Mouse", "Screen"
        MouseMove savedX, savedY, 0
    }
}

DoLeaveAction() {
    global OptionsBtn, LeaveBtn, smartRestore, running
    if !running
        return

    fnExe := "ahk_exe FortniteClient-Win64-Shipping.exe"
    fnHwnd := WinExist(fnExe)
    userHwnd := 0
    savedX := 0, savedY := 0

    if (smartRestore && fnHwnd) {
        userHwnd := WinActive("A")
        CoordMode "Mouse", "Screen"
        MouseGetPos &savedX, &savedY
    }

    if fnHwnd {
        ; 1. Move mouse cursor inside Fortnite on its monitor BEFORE activating
        GetFortniteOrigin &ox, &oy, &gw, &gh
        optX := ox + OptionsBtn[1]
        optY := oy + OptionsBtn[2]
        CoordMode "Mouse", "Screen"
        MouseMove optX, optY, 0
        Sleep 50

        ; 2. Force foreground activation on Fortnite's window
        ForceWinActivate(fnHwnd)
        Sleep 200
    }

    ; 3. Send ESC using Send (SendInput) with hold duration so Unreal Engine registers it reliably
    Send "{Esc down}"
    Sleep 100
    Send "{Esc up}"
    Sleep 1500

    ; 4. Click Options menu and Leave button
    ClickAt(OptionsBtn)
    Sleep 1500
    ClickAt(LeaveBtn)
    Sleep 1200

    ; 5. Restore previous active window and cursor position if Smart Multitasking is enabled
    if (smartRestore && fnHwnd && userHwnd && userHwnd != fnHwnd) {
        Sleep 250
        if WinExist("ahk_id " userHwnd)
            ForceWinActivate(userHwnd)
        CoordMode "Mouse", "Screen"
        MouseMove savedX, savedY, 0
    }
}

WaitPhase(ms, label, enablePreAlert := false) {
    global running, phase, phaseTick, smartRestore, audioAlert
    phase := label
    phaseTick := A_TickCount
    UpdateUI()
    end := A_TickCount + ms
    alertDone := false

    while A_TickCount < end {
        if !running {
            ToolTip
            return false
        }

        ; Pre-alert 3 seconds before action when Smart Multitasking is active
        if (enablePreAlert && smartRestore && !alertDone && (end - A_TickCount <= 3200)) {
            alertDone := true
            if audioAlert
                SoundBeep 880, 180
            ToolTip "⚡ Fortnite Queue Bot acting in 3s... (cursor will be restored)"
        }

        Sleep 200
    }
    ToolTip
    return true
}

ClickAt(pos) {
    GetFortniteOrigin &ox, &oy, &w, &h
    targetX := ox + pos[1]
    targetY := oy + pos[2]
    CoordMode "Mouse", "Screen"
    MouseMove targetX, targetY, 5
    Sleep 200
    Click
    Sleep 500
}

; High-performance anti-flicker UI updater
UpdateUI(*) {
    global running, phase, phaseTick, gameStartTick, InGameTime, LoadTime, LobbyTime, rounds, totalRounds
    global StatusStripe, StatusDot, StatusText, PhaseText, TimerText, GameValue, LobbyValue, RoundsValue
    global SessionTimeValue, TotalRoundsValue, TotalRuntimeValue
    global StartBtn, HomeHint, startHotkey, hStatusRed, hStatusGreen, HomeMultitaskTag, smartRestore
    global initTotalRuntimeSec, sessionActiveSec, activeStartTick, REG_SETTINGS

    static prevRunning := -1
    static prevPhase := ""
    static prevTimer := ""
    static prevGame := ""
    static prevLobby := ""
    static prevRounds := -1
    static prevSessionTime := ""
    static prevTotalRounds := -1
    static prevTotalRuntime := ""
    static prevHotkey := ""
    static prevSmart := -1
    static lastPersistTick := 0

    ; Calculate active execution time (only accumulates when Auto Queue is active)
    currentRunSec := (running && activeStartTick) ? Floor((A_TickCount - activeStartTick) / 1000) : 0
    curSessionTimeSec := sessionActiveSec + currentRunSec
    curTotalRuntimeSec := initTotalRuntimeSec + curSessionTimeSec

    ; Periodic total runtime registry persistence (every 10 seconds while running)
    if (running && A_TickCount - lastPersistTick >= 10000) {
        lastPersistTick := A_TickCount
        try RegWrite(curTotalRuntimeSec, "REG_DWORD", REG_SETTINGS, "TotalRuntimeSec")
    }

    ; Only update buttons and status badge when running state flips
    if (running != prevRunning) {
        prevRunning := running
        if running {
            SetCtrlBitmap(StatusStripe, hStatusGreen)
            StatusDot.SetFont("c10B981")
            StatusText.Text := "QUEUE ACTIVE"
            hBmp := MakeStartBtnBmp(true, startHotkey)
            SetCtrlBitmap(StartBtn, hBmp, true)
        } else {
            SetCtrlBitmap(StatusStripe, hStatusRed)
            StatusDot.SetFont("cEF4444")
            StatusText.Text := "STOPPED"
            hBmp := MakeStartBtnBmp(false, startHotkey)
            SetCtrlBitmap(StartBtn, hBmp, true)
        }
    }

    ; Phase description text
    currentPhaseText := running ? phase : ("Ready to queue. Press Start or hit " StrUpper(startHotkey) " to begin automated matchmaking.")
    if (currentPhaseText != prevPhase) {
        prevPhase := currentPhaseText
        PhaseText.Text := currentPhaseText
    }

    ; Countdown timer text
    if running {
        remaining := 0
        if phase = "In match" && gameStartTick
            remaining := Max(0, InGameTime - (A_TickCount - gameStartTick))
        else if phase = "Lobby cooldown"
            remaining := Max(0, LobbyTime - (A_TickCount - phaseTick))
        else if InStr(phase, "Match loading")
            remaining := Max(0, LoadTime - (A_TickCount - phaseTick))
        curTimer := FormatTimeLeft(remaining)
    } else {
        curTimer := FormatTimeLeft(InGameTime)
    }

    if (curTimer != prevTimer) {
        prevTimer := curTimer
        TimerText.Text := curTimer
    }

    ; Metric Cards
    curGame := FormatTimeLeft(InGameTime)
    if (curGame != prevGame) {
        prevGame := curGame
        GameValue.Text := curGame
    }

    curLobby := FormatTimeLeft(LobbyTime)
    if (curLobby != prevLobby) {
        prevLobby := curLobby
        LobbyValue.Text := curLobby
    }

    if (rounds != prevRounds) {
        prevRounds := rounds
        RoundsValue.Text := rounds
    }

    curSessionTime := FormatSessionTime(curSessionTimeSec)
    if (curSessionTime != prevSessionTime) {
        prevSessionTime := curSessionTime
        SessionTimeValue.Text := curSessionTime
    }

    if (totalRounds != prevTotalRounds) {
        prevTotalRounds := totalRounds
        TotalRoundsValue.Text := totalRounds
    }

    curTotalRuntime := FormatRuntime(curTotalRuntimeSec)
    if (curTotalRuntime != prevTotalRuntime) {
        prevTotalRuntime := curTotalRuntime
        TotalRuntimeValue.Text := curTotalRuntime
    }

    if (startHotkey != prevHotkey) {
        prevHotkey := startHotkey
        HomeHint.Text := "[ " StrUpper(startHotkey) " ]  START / STOP      •      [ F9 ]  COPY COORDS      •      [ F10 ]  EXIT"
    }

    ; Smart Multitasking tag on dashboard
    if (smartRestore != prevSmart) {
        prevSmart := smartRestore
        if smartRestore {
            HomeMultitaskTag.Text := "⚡ SMART MULTITASKING: ENABLED  (Normal PC use allowed during matches)"
            HomeMultitaskTag.SetFont("c10B981")
        } else {
            HomeMultitaskTag.Text := "⚡ SMART MULTITASKING: DISABLED  (Enable in Settings to use PC during matches)"
            HomeMultitaskTag.SetFont("c8E9AA8")
        }
    }
}

FormatTimeLeft(ms) {
    totalSeconds := Ceil(Max(0, ms) / 1000)
    return Format("{:02}:{:02}", Floor(totalSeconds / 60), Mod(totalSeconds, 60))
}

FormatSessionTime(sec) {
    sec := Max(0, sec)
    hours := Floor(sec / 3600)
    rem := Mod(sec, 3600)
    mins := Floor(rem / 60)
    secs := Mod(rem, 60)
    return Format("{:02}:{:02}:{:02}", hours, mins, secs)
}

FormatRuntime(sec) {
    sec := Max(0, sec)
    days := Floor(sec / 86400)
    rem := Mod(sec, 86400)
    hours := Floor(rem / 3600)
    rem := Mod(rem, 3600)
    mins := Floor(rem / 60)
    secs := Mod(rem, 60)

    if (days > 0)
        return days "d " hours "h " mins "m"
    else if (hours > 0)
        return hours "h " Format("{:02}m", mins) " " Format("{:02}s", secs)
    else
        return Format("{:02}m {:02}s", mins, secs)
}

OnExit SaveOnExit
SaveOnExit(exitReason, exitCode) {
    global initTotalRuntimeSec, sessionActiveSec, activeStartTick, running, matchInProgress, totalRounds, REG_SETTINGS
    try {
        currentRunSec := (running && activeStartTick) ? Floor((A_TickCount - activeStartTick) / 1000) : 0
        finalSec := initTotalRuntimeSec + sessionActiveSec + currentRunSec
        RegWrite(finalSec, "REG_DWORD", REG_SETTINGS, "TotalRuntimeSec")
        if (matchInProgress) {
            matchInProgress := false
            totalRounds += 1
            RegWrite(totalRounds, "REG_DWORD", REG_SETTINGS, "TotalRounds")
        }
    }
}
