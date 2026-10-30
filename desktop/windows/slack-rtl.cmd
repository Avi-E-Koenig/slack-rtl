@echo off
rem Double-click to start "Slack (RTL)". Bypasses the script execution policy for this script only.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0slack-rtl.ps1" %*
