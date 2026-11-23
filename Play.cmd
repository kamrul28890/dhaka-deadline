@echo off
setlocal
if exist "%~dp0build\v2.0\DhakaDeadline.exe" (
    start "" "%~dp0build\v2.0\DhakaDeadline.exe"
    exit /b 0
)
if exist "%~dp0build\v1.8\DhakaDeadline.exe" (
    start "" "%~dp0build\v1.8\DhakaDeadline.exe"
    exit /b 0
)
if exist "%~dp0build\v1.7\DhakaDeadline.exe" (
    start "" "%~dp0build\v1.7\DhakaDeadline.exe"
    exit /b 0
)
if exist "%~dp0build\v1.6\DhakaDeadline.exe" (
    start "" "%~dp0build\v1.6\DhakaDeadline.exe"
    exit /b 0
)
if exist "%~dp0build\v1.5\DhakaDeadline.exe" (
    start "" "%~dp0build\v1.5\DhakaDeadline.exe"
    exit /b 0
)
if exist "%~dp0build\v1.4\DhakaDeadline.exe" (
    start "" "%~dp0build\v1.4\DhakaDeadline.exe"
    exit /b 0
)
if exist "%~dp0build\v1.3\DhakaDeadline.exe" (
    start "" "%~dp0build\v1.3\DhakaDeadline.exe"
    exit /b 0
)
if exist "%~dp0build\v1.2\DhakaDeadline.exe" (
    start "" "%~dp0build\v1.2\DhakaDeadline.exe"
    exit /b 0
)
if exist "%~dp0build\v1.1\DhakaDeadline.exe" (
    start "" "%~dp0build\v1.1\DhakaDeadline.exe"
    exit /b 0
)
if exist "%~dp0build\v1.0\DhakaDeadline.exe" (
    start "" "%~dp0build\v1.0\DhakaDeadline.exe"
    exit /b 0
)
if exist "%~dp0build\v0.9\DhakaDeadline.exe" (
    start "" "%~dp0build\v0.9\DhakaDeadline.exe"
    exit /b 0
)
if exist "%~dp0build\v0.8\DhakaDeadline.exe" (
    start "" "%~dp0build\v0.8\DhakaDeadline.exe"
    exit /b 0
)
if exist "%~dp0build\v0.7\DhakaDeadline.exe" (
    start "" "%~dp0build\v0.7\DhakaDeadline.exe"
    exit /b 0
)
if exist "%~dp0build\v0.6\DhakaDeadline.exe" (
    start "" "%~dp0build\v0.6\DhakaDeadline.exe"
    exit /b 0
)
if exist "%~dp0build\v0.5\DhakaDeadline.exe" (
    start "" "%~dp0build\v0.5\DhakaDeadline.exe"
    exit /b 0
)
if exist "%~dp0build\v0.4\DhakaDeadline.exe" (
    start "" "%~dp0build\v0.4\DhakaDeadline.exe"
    exit /b 0
)
if exist "%~dp0build\v0.3\DhakaDeadline.exe" (
    start "" "%~dp0build\v0.3\DhakaDeadline.exe"
    exit /b 0
)
if exist "%~dp0build\DhakaDeadline.exe" (
    start "" "%~dp0build\DhakaDeadline.exe"
    exit /b 0
)
if exist "%~dp0.tools\godot\Godot_v4.7.2-stable_win64.exe" (
    start "" "%~dp0.tools\godot\Godot_v4.7.2-stable_win64.exe" --path "%~dp0."
    exit /b 0
)
echo Run python tools\setup_runtime.py first, then try again.
pause
