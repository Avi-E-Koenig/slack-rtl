@echo off
rem Double-click to install or rebuild "Slack (RTL)". Extra options: -Status, -Startup, -RefreshProfile, -Uninstall.
rem Bypasses the PowerShell script execution policy for this one script only.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0slack-rtl-desktop.ps1" %*
echo.
pause
