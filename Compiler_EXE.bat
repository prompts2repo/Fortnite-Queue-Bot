@echo off
setlocal
title Compiler - Fortnite Queue Bot

echo ==========================================================
echo        FORTNITE QUEUE BOT COMPILER (Ahk2Exe)
echo ==========================================================
echo.

cd /d "%~dp0"

set "SRC_AHK=FortniteQueueBot.ahk"
set "OUT_EXE=FortniteQueueBot.exe"
set "ICO_FILE=FortniteQueueBot.ico"

if not exist "%SRC_AHK%" goto NO_SRC

set "AHK2EXE="
if exist "B:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" set "AHK2EXE=B:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"
if "%AHK2EXE%"=="" if exist "C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" set "AHK2EXE=C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"
if "%AHK2EXE%"=="" if exist "%ProgramFiles%\AutoHotkey\Compiler\Ahk2Exe.exe" set "AHK2EXE=%ProgramFiles%\AutoHotkey\Compiler\Ahk2Exe.exe"

if "%AHK2EXE%"=="" goto NO_COMPILER

set "BASE_BIN="
if exist "B:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" set "BASE_BIN=B:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
if "%BASE_BIN%"=="" if exist "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" set "BASE_BIN=C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
if "%BASE_BIN%"=="" if exist "%ProgramFiles%\AutoHotkey\v2\AutoHotkey64.exe" set "BASE_BIN=%ProgramFiles%\AutoHotkey\v2\AutoHotkey64.exe"

if "%BASE_BIN%"=="" goto NO_BASE

echo [1/3] Closing any running instances of "%OUT_EXE%"...
taskkill /F /IM "%OUT_EXE%" >nul 2>&1

echo [2/3] Compiling with Ahk2Exe...
echo       - Source:      %SRC_AHK%
echo       - Icon:        %ICO_FILE%
echo       - Output:      %OUT_EXE%
echo.

if exist "%ICO_FILE%" (
    "%AHK2EXE%" /silent /in "%SRC_AHK%" /out "%OUT_EXE%" /icon "%ICO_FILE%" /base "%BASE_BIN%"
) else (
    "%AHK2EXE%" /silent /in "%SRC_AHK%" /out "%OUT_EXE%" /base "%BASE_BIN%"
)

if errorlevel 1 goto BUILD_ERROR

echo [3/3] Compilation completed successfully!
echo.
echo ==========================================================
echo  [OK] Generated file: "%OUT_EXE%"
echo ==========================================================
echo.
goto END

:NO_SRC
echo [ERROR] Source file not found: %SRC_AHK%
goto FAIL

:NO_COMPILER
echo [ERROR] Ahk2Exe.exe not found in AutoHotkey\Compiler directory!
goto FAIL

:NO_BASE
echo [ERROR] AutoHotkey64.exe base binary not found!
goto FAIL

:BUILD_ERROR
echo [ERROR] Compilation failed.
goto FAIL

:FAIL
echo.
echo [WARNING] An issue occurred during compilation.
echo.

:END
pause
