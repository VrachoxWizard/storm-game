@echo off
setlocal enabledelayedexpansion

:: ============================================================================
:: Operation Storm - Windows Launcher (Editor Mode)
:: ============================================================================

set "ROOT=%~dp0"
set "GODOT_EXE="

:: 1. Check if 'godot' or 'godot.exe' is available in system PATH
for /f "delims=" %%I in ('where godot.exe 2^>nul') do (
    if exist "%%I" (
        set "GODOT_EXE=%%I"
        goto :found
    )
)

:: 2. Check standard WinGet package location using %LOCALAPPDATA%
if exist "%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe" (
    set "GODOT_EXE=%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe"
    goto :found
)

:: 3. Check for any Godot GUI executable in WinGet Packages
if exist "%LOCALAPPDATA%\Microsoft\WinGet\Packages" (
    for /r "%LOCALAPPDATA%\Microsoft\WinGet\Packages" %%F in (Godot*_win64.exe) do (
        echo %%~nxF | findstr /i "console" >nul
        if errorlevel 1 (
            set "GODOT_EXE=%%F"
            goto :found
        )
    )
)

:: 4. Check Program Files standard installation directories
if exist "%ProgramFiles%\Godot\Godot.exe" (
    set "GODOT_EXE=%ProgramFiles%\Godot\Godot.exe"
    goto :found
)
if exist "%ProgramFiles%\Godot 4\Godot.exe" (
    set "GODOT_EXE=%ProgramFiles%\Godot 4\Godot.exe"
    goto :found
)
if exist "%ProgramFiles(x86)%\Godot\Godot.exe" (
    set "GODOT_EXE=%ProgramFiles(x86)%\Godot\Godot.exe"
    goto :found
)

:: 5. Check Scoop installation directories
if exist "%USERPROFILE%\scoop\apps\godot\current\godot.exe" (
    set "GODOT_EXE=%USERPROFILE%\scoop\apps\godot\current\godot.exe"
    goto :found
)
if exist "%USERPROFILE%\scoop\shims\godot.exe" (
    set "GODOT_EXE=%USERPROFILE%\scoop\shims\godot.exe"
    goto :found
)

:: 6. Hardcoded fallback path
if exist "C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe" (
    set "GODOT_EXE=C:\Users\user1\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe"
    goto :found
)

:not_found
echo ============================================================================
echo Error: Godot 4 executable was not found on this system!
echo ============================================================================
echo Please install Godot 4 via Windows Package Manager:
echo     winget install GodotEngine.GodotEngine
echo.
echo Or download Godot 4 from:
echo     https://godotengine.org/download/
echo ============================================================================
pause
exit /b 1

:found
echo Opening Operation Storm in Godot 4 Editor...
echo Using engine: "%GODOT_EXE%"

start "" "%GODOT_EXE%" -e --path "%ROOT%."
exit /b 0
