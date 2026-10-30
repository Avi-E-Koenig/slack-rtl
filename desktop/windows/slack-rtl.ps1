<#
.SYNOPSIS
  Starts the Slack desktop app with Hebrew/RTL support (Windows).

.DESCRIPTION
  Browser extensions can't run inside the Slack desktop app (Electron). This
  script starts a separate "Slack (RTL)" instance with a local-only DevTools
  port and keeps injecting ../../extension/rtl.css into every Slack window
  (re-injecting after reloads) until it exits. Nothing in Slack's install
  folder is modified, so Slack updates don't break it.

  Slack refuses a debugging port on its default profile (a deliberate guard
  that protects your normal session), so this instance uses its own profile
  folder (-ProfileDir). Log in there once; your normal Slack is untouched and
  can keep running alongside it.

  SECURITY: while it runs, any program on this computer can attach to the
  debugging port (127.0.0.1 only, never the network) and control this Slack
  instance. Only use it on a machine you trust.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File slack-rtl.ps1
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File slack-rtl.ps1 -CreateShortcut
#>
param(
  [int]$Port = 9229,
  [string]$ProfileDir = (Join-Path $env:LOCALAPPDATA 'SlackRTL'),
  [string]$CssPath = (Join-Path $PSScriptRoot '..\..\extension\rtl.css'),
  [switch]$CreateShortcut
)
$ErrorActionPreference = 'Stop'

if ($CreateShortcut) {
  $lnk = Join-Path ([Environment]::GetFolderPath('Programs')) 'Slack (RTL).lnk'
  $shell = New-Object -ComObject WScript.Shell
  $s = $shell.CreateShortcut($lnk)
  $s.TargetPath = 'powershell.exe'
  $s.Arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`""
  $s.WorkingDirectory = $PSScriptRoot
  $s.Description = 'Slack with Hebrew/RTL support'
  $s.Save()
  Write-Host "Shortcut created: $lnk"
  return
}

function Find-Slack {
  $candidates = @(
    (Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\Slack.exe'),  # Microsoft Store install (app alias)
    (Join-Path $env:LOCALAPPDATA 'slack\slack.exe'),                  # per-user installer
    (Join-Path $env:ProgramFiles 'Slack\slack.exe')                   # machine-wide installer
  )
  foreach ($c in $candidates) { if (Test-Path $c) { return $c } }
  throw 'Slack desktop app not found.'
}

function Invoke-Cdp([string]$WsUrl, [string]$Expression) {
  # One Runtime.evaluate call over the DevTools WebSocket.
  $ws = New-Object System.Net.WebSockets.ClientWebSocket
  $ct = [Threading.CancellationToken]::None
  try {
    $ws.ConnectAsync([Uri]$WsUrl, $ct).Wait(5000) | Out-Null
    $msg = @{ id = 1; method = 'Runtime.evaluate'; params = @{ expression = $Expression; returnByValue = $true } } | ConvertTo-Json -Compress -Depth 5
    $bytes = [Text.Encoding]::UTF8.GetBytes($msg)
    $ws.SendAsync((New-Object ArraySegment[byte] -ArgumentList @(, $bytes)), 'Text', $true, $ct).Wait(5000) | Out-Null
    $buf = New-Object byte[] 65536
    $sb = New-Object Text.StringBuilder
    do {
      $r = $ws.ReceiveAsync((New-Object ArraySegment[byte] -ArgumentList @(, $buf)), $ct)
      if (-not $r.Wait(5000)) { break }
      [void]$sb.Append([Text.Encoding]::UTF8.GetString($buf, 0, $r.Result.Count))
    } until ($r.Result.EndOfMessage)
    return $sb.ToString()
  } finally {
    $ws.Dispose()
  }
}

$css = [IO.File]::ReadAllText((Resolve-Path $CssPath), [Text.Encoding]::UTF8)
$cssJson = $css | ConvertTo-Json  # JSON string literal = valid JS string literal
$inject = @"
(() => {
  const css = $cssJson;
  let s = document.getElementById('slack-rtl-css');
  if (!s) { s = document.createElement('style'); s.id = 'slack-rtl-css'; (document.head || document.documentElement).appendChild(s); }
  if (s.textContent !== css) s.textContent = css;
  return location.host;
})()
"@

New-Item -ItemType Directory -Force -Path $ProfileDir | Out-Null
Start-Process (Find-Slack) -ArgumentList "--user-data-dir=`"$ProfileDir`"", "--remote-debugging-port=$Port", '--remote-debugging-address=127.0.0.1'

$seen = $false; $misses = 0
while ($true) {
  Start-Sleep -Seconds 3
  try {
    $targets = Invoke-RestMethod "http://127.0.0.1:$Port/json" -TimeoutSec 3
    $seen = $true; $misses = 0
  } catch {
    if ($seen -and ++$misses -ge 3) { break }  # this Slack instance quit: stop too
    if (-not $seen -and ++$misses -ge 40) { throw "Slack didn't open port $Port within 2 minutes." }
    continue
  }
  foreach ($t in $targets) {
    if ($t.type -eq 'page' -and $t.url -like 'https://app.slack.com/*' -and $t.webSocketDebuggerUrl) {
      try { Invoke-Cdp $t.webSocketDebuggerUrl $inject | Out-Null } catch { }
    }
  }
}
