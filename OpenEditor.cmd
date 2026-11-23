@echo off
setlocal
if exist "%~dp0.tools\godot\Godot_v4.7.2-stable_win64.exe" (
    start "" "%~dp0.tools\godot\Godot_v4.7.2-stable_win64.exe" --editor --path "%~dp0."
    exit /b 0
)
echo Run python tools\setup_runtime.py first, then try again.
pause
