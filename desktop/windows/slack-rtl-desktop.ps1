<#
.SYNOPSIS
  EXPERIMENTAL: builds "Slack (RTL)", a patched copy of your installed Slack
  desktop app with Hebrew/RTL support (Windows).

.DESCRIPTION
  Browser extensions can't run inside the Slack desktop app, so this script
  builds a separate copy of it that loads ../../extension/rtl.css itself:

    1. Copies your installed Slack app to %LOCALAPPDATA%\SlackRTL\app.
       Your installed Slack is never modified.
    2. Adds a few lines to the copy's startup code (inside resources\app.asar)
       that insert rtl.css into every app.slack.com page.
    3. Turns off the copy's built-in "app.asar must be unmodified" check
       (the EnableEmbeddedAsarIntegrityValidation Electron fuse in the copied
       Slack.exe), otherwise the copy refuses to start.
    4. On first install, copies your Slack profile (including your sign-in) to
       %LOCALAPPDATA%\SlackRTL\profile, so the copy opens already signed in.
       The copy and your normal Slack never share a profile.
    5. Creates "Slack (RTL)" shortcuts on the desktop and in the Start menu,
       with this project's own icon (slack-rtl.ico), not Slack's logo.

  Slack does not update the copy. After Slack updates itself, run this script
  again to rebuild the copy from the new version (your RTL profile is kept).

.EXAMPLE
  slack-rtl-desktop.cmd                 # install, or rebuild after a Slack update
.EXAMPLE
  slack-rtl-desktop.cmd -Startup        # also start Slack (RTL) when you sign in to Windows
.EXAMPLE
  slack-rtl-desktop.cmd -Status         # show what is installed; changes nothing
.EXAMPLE
  slack-rtl-desktop.cmd -RefreshProfile # re-copy your profile from the normal Slack
.EXAMPLE
  slack-rtl-desktop.cmd -Uninstall      # remove the copy, its profile and shortcuts
#>
param(
  [switch]$Status,
  [switch]$Uninstall,
  [switch]$Startup,
  [switch]$RefreshProfile,
  [string]$CssPath = (Join-Path $PSScriptRoot '..\..\extension\rtl.css')
)
$ErrorActionPreference = 'Stop'

$Root        = Join-Path $env:LOCALAPPDATA 'SlackRTL'
$AppDir      = Join-Path $Root 'app'
$ProfileDir  = Join-Path $Root 'profile'
$StateFile   = Join-Path $Root 'install.json'
$IconPath    = Join-Path $Root 'slack-rtl.ico'
$IconSource  = Join-Path $PSScriptRoot 'slack-rtl.ico'
$ShortcutName = 'Slack (RTL).lnk'
$MenuLnk     = Join-Path ([Environment]::GetFolderPath('Programs')) $ShortcutName
$StartupLnk  = Join-Path ([Environment]::GetFolderPath('Startup')) $ShortcutName
$DesktopLnk  = Join-Path ([Environment]::GetFolderPath('Desktop')) $ShortcutName
$Marker      = '/* slack-rtl-desktop inject */'
$FuseSentinel = 'dL7pKGdnNz796PbbjQWNKmHXBZaB9tsX'
$FuseAsarIntegrityIndex = 4   # EnableEmbeddedAsarIntegrityValidation (Electron fuse schema v1)
# Profile folders that are safe to skip (caches Slack rebuilds by itself).
$ProfileSkip = @('Cache', 'Code Cache', 'GPUCache', 'GrShaderCache', 'ShaderCache', 'DawnGraphiteCache',
                 'DawnWebGPUCache', 'GPUPersistentCache', 'Crashpad', 'logs')

function Say($msg, $color = 'Gray') { Write-Host $msg -ForegroundColor $color }
function Fail($msg) { Write-Host ''; Write-Host "ERROR: $msg" -ForegroundColor Red; exit 1 }

# ---------------------------------------------------------------- find Slack

function Find-Slack {
  $pkg = Get-AppxPackage -Name 'com.tinyspeck.slackdesktop' -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($pkg) {
    return [pscustomobject]@{
      Kind    = 'Microsoft Store'
      AppDir  = Join-Path $pkg.InstallLocation 'app'
      Profile = Join-Path $env:LOCALAPPDATA "Packages\$($pkg.PackageFamilyName)\LocalCache\Roaming\Slack"
      Version = [string]$pkg.Version
    }
  }
  $squirrel = Join-Path $env:LOCALAPPDATA 'slack'
  $latest = Get-ChildItem $squirrel -Directory -Filter 'app-*' -ErrorAction SilentlyContinue |
    Sort-Object { try { [version]($_.Name -replace '^app-', '') } catch { [version]'0.0' } } |
    Select-Object -Last 1
  if ($latest) {
    return [pscustomobject]@{
      Kind = 'slack.com download'; AppDir = $latest.FullName
      Profile = Join-Path $env:APPDATA 'Slack'; Version = $latest.Name -replace '^app-', ''
    }
  }
  $machine = Join-Path $env:ProgramFiles 'Slack'
  if (Test-Path (Join-Path $machine 'slack.exe')) {
    return [pscustomobject]@{
      Kind = 'machine-wide (MSI)'; AppDir = $machine
      Profile = Join-Path $env:APPDATA 'Slack'
      Version = (Get-Item (Join-Path $machine 'slack.exe')).VersionInfo.ProductVersion
    }
  }
  return $null
}

function Get-SlackProcesses {
  Get-Process -Name slack -ErrorAction SilentlyContinue
}

# ------------------------------------------------------------- asar helpers
# asar layout: [uint32 4][uint32 headerPickleSize] then a pickle holding
# [uint32 payload][uint32 jsonLength][json][padding]; file data follows.
# Offsets in the JSON are relative to the start of the data.

function Read-AsarHeader($path) {
  $fs = [IO.File]::OpenRead($path)
  try {
    $br = New-Object IO.BinaryReader($fs)
    [void]$br.ReadUInt32(); $pickleSize = $br.ReadUInt32()
    [void]$br.ReadUInt32(); $jsonLen = $br.ReadUInt32()
    $json = [Text.Encoding]::UTF8.GetString($br.ReadBytes($jsonLen))
    return [pscustomobject]@{ Json = $json; DataStart = [int64](8 + $pickleSize); Length = $fs.Length }
  } finally { $fs.Dispose() }
}

function Get-AsarEntry($headerObj, [string]$innerPath) {
  $node = $headerObj
  foreach ($part in ($innerPath -split '/')) {
    if (-not $node.files) { return $null }
    $node = $node.files.$part
    if (-not $node) { return $null }
  }
  return $node
}

function Read-AsarFile($path, $header, $entry) {
  $fs = [IO.File]::OpenRead($path)
  try {
    [void]$fs.Seek($header.DataStart + [int64]$entry.offset, 'Begin')
    $buf = New-Object byte[] ([int]$entry.size)
    $read = 0
    while ($read -lt $buf.Length) { $read += $fs.Read($buf, $read, $buf.Length - $read) }
    return $buf
  } finally { $fs.Dispose() }
}

function Get-Sha256Hex([byte[]]$bytes, [int]$start = 0, [int]$count = -1) {
  if ($count -lt 0) { $count = $bytes.Length }
  $sha = [Security.Cryptography.SHA256]::Create()
  try { return (($sha.ComputeHash($bytes, $start, $count) | ForEach-Object { $_.ToString('x2') }) -join '') }
  finally { $sha.Dispose() }
}

# Replaces one packed file inside an asar without repacking: the new bytes are
# appended after the existing data and only that entry in the header changes.
function Set-AsarFile($asarPath, [string]$innerPath, [byte[]]$newBytes) {
  $header = Read-AsarHeader $asarPath
  $entry = Get-AsarEntry ($header.Json | ConvertFrom-Json) $innerPath
  if (-not $entry -or $entry.unpacked) { Fail "Unexpected Slack layout: '$innerPath' not found in app.asar." }

  $name = ($innerPath -split '/')[-1]
  $pattern = '"' + [regex]::Escape($name) + '":\{"size":' + $entry.size + ',"offset":"' + $entry.offset +
             '","integrity":\{[^{}]*\}\}'
  $found = [regex]::Matches($header.Json, $pattern)
  if ($found.Count -ne 1) { Fail "Unexpected Slack layout: could not locate '$innerPath' in the app.asar header." }

  $blockSize = 4194304
  $blocks = @()
  for ($i = 0; $i -lt $newBytes.Length; $i += $blockSize) {
    $blocks += '"' + (Get-Sha256Hex $newBytes $i ([Math]::Min($blockSize, $newBytes.Length - $i))) + '"'
  }
  $newOffset = $header.Length - $header.DataStart
  $replacement = '"' + $name + '":{"size":' + $newBytes.Length + ',"offset":"' + $newOffset +
    '","integrity":{"algorithm":"SHA256","hash":"' + (Get-Sha256Hex $newBytes) +
    '","blockSize":' + $blockSize + ',"blocks":[' + ($blocks -join ',') + ']}}'
  $json = $header.Json.Substring(0, $found[0].Index) + $replacement +
          $header.Json.Substring($found[0].Index + $found[0].Length)

  $jsonBytes = [Text.Encoding]::UTF8.GetBytes($json)
  $padded = [int]([Math]::Ceiling($jsonBytes.Length / 4) * 4)
  $tmp = "$asarPath.tmp"
  $out = [IO.File]::Create($tmp)
  $in = [IO.File]::OpenRead($asarPath)
  try {
    $bw = New-Object IO.BinaryWriter($out)
    $bw.Write([uint32]4); $bw.Write([uint32](8 + $padded))
    $bw.Write([uint32](4 + $padded)); $bw.Write([uint32]$jsonBytes.Length)
    $bw.Write($jsonBytes); $bw.Write((New-Object byte[] ($padded - $jsonBytes.Length)))
    $bw.Flush()
    [void]$in.Seek($header.DataStart, 'Begin')
    $in.CopyTo($out)
    $out.Write($newBytes, 0, $newBytes.Length)
  } finally { $in.Dispose(); $out.Dispose() }
  Move-Item -Force $tmp $asarPath
}

# ------------------------------------------------------------- fuse helpers
# Electron stores its fuses after a fixed sentinel string in the executable:
# [sentinel][version byte][count byte][one byte per fuse: '0' off, '1' on].

function Find-FuseWire($exePath) {
  $enc = [Text.Encoding]::GetEncoding(28591)   # 1 byte <-> 1 char
  $fs = [IO.File]::OpenRead($exePath)
  try {
    $chunk = 16MB; $overlap = 64
    $buf = New-Object byte[] $chunk
    $pos = [int64]0
    while ($true) {
      [void]$fs.Seek($pos, 'Begin')
      $n = $fs.Read($buf, 0, $chunk)
      if ($n -le 0) { break }
      $i = $enc.GetString($buf, 0, $n).IndexOf($FuseSentinel, [StringComparison]::Ordinal)
      if ($i -ge 0) {
        $at = $pos + $i + $FuseSentinel.Length
        [void]$fs.Seek($at, 'Begin')
        $version = $fs.ReadByte(); $count = $fs.ReadByte()
        $wire = New-Object byte[] $count
        [void]$fs.Read($wire, 0, $count)
        return [pscustomobject]@{ Offset = $at + 2; Version = $version; Wire = $enc.GetString($wire) }
      }
      if ($n -lt $chunk) { break }
      $pos += $chunk - $overlap
    }
  } finally { $fs.Dispose() }
  return $null
}

function Disable-AsarIntegrityFuse($exePath) {
  $f = Find-FuseWire $exePath
  if (-not $f -or $f.Version -ne 1 -or $f.Wire.Length -le $FuseAsarIntegrityIndex) {
    Fail 'Unexpected Slack.exe: Electron fuses not found or in an unknown format.'
  }
  $current = $f.Wire[$FuseAsarIntegrityIndex]
  if ($current -eq '0') { return 'already off' }
  if ($current -ne '1') { Fail "Unexpected fuse value '$current' in Slack.exe." }
  $fs = [IO.File]::Open($exePath, 'Open', 'ReadWrite')
  try { [void]$fs.Seek($f.Offset + $FuseAsarIntegrityIndex, 'Begin'); $fs.WriteByte([byte][char]'0') }
  finally { $fs.Dispose() }
  return 'turned off'
}

# ------------------------------------------------------------------ actions

function Remove-Shortcuts {
  foreach ($l in @($MenuLnk, $DesktopLnk, $StartupLnk)) { if (Test-Path $l) { Remove-Item -Force $l } }
}

function New-Shortcut($lnkPath) {
  $shell = New-Object -ComObject WScript.Shell
  $s = $shell.CreateShortcut($lnkPath)
  $s.TargetPath = Join-Path $AppDir 'slack.exe'
  $s.Arguments = "--user-data-dir=`"$ProfileDir`""
  $s.WorkingDirectory = $AppDir
  $s.IconLocation = "$IconPath,0"
  $s.Description = 'Slack with Hebrew/RTL support (patched copy)'
  $s.Save()
}

function Invoke-Robocopy([string[]]$robocopyArgs) {
  & robocopy.exe @robocopyArgs /NFL /NDL /NJH /NJS /NP /R:1 /W:1 | Out-Null
  if ($LASTEXITCODE -ge 8) { Fail "Copy failed (robocopy exit code $LASTEXITCODE)." }
}

function Show-Status {
  $slack = Find-Slack
  if ($slack) { Say "Installed Slack : $($slack.Version) ($($slack.Kind))" } else { Say 'Installed Slack : not found' }
  if (Test-Path $StateFile) {
    $st = Get-Content $StateFile -Raw | ConvertFrom-Json
    Say "Slack (RTL)     : built from $($st.SourceVersion) on $($st.BuiltAt)"
    if ($slack -and $slack.Version -ne $st.SourceVersion) {
      Say 'Slack has updated since the copy was built. Run the installer again to rebuild.' Yellow
    }
  } else { Say 'Slack (RTL)     : not installed' }
  $exe = Join-Path $AppDir 'slack.exe'
  if (Test-Path $exe) {
    $f = Find-FuseWire $exe
    if ($f) { Say "Integrity check : $(if ($f.Wire[$FuseAsarIntegrityIndex] -eq '0') { 'off (expected)' } else { 'ON - copy will not start' })" }
  }
  Say "Profile         : $(if (Test-Path $ProfileDir) { $ProfileDir } else { 'none' })"
  Say "Shortcuts       : $(@($MenuLnk, $DesktopLnk, $StartupLnk | Where-Object { Test-Path $_ }) -join ', ')"
}

if ($Status) { Show-Status; exit 0 }

if ($Uninstall) {
  if (Get-SlackProcesses | Where-Object { $_.Path -and $_.Path.StartsWith($Root, 'OrdinalIgnoreCase') }) {
    Fail 'Slack (RTL) is running. Quit it first (tray icon -> Quit), then run this again.'
  }
  Remove-Shortcuts
  if (Test-Path $Root) { Remove-Item -Recurse -Force $Root }
  Say 'Slack (RTL) removed. Your normal Slack and its sign-in are untouched.' Green
  exit 0
}

# ------------------------------------------------------------------ install

Say 'Slack (RTL) for the Windows desktop app - EXPERIMENTAL' Cyan
Say ''

$slack = Find-Slack
if (-not $slack) { Fail 'Slack desktop is not installed. Install it (Microsoft Store or slack.com), sign in once, then run this again.' }
Say "Found Slack $($slack.Version) ($($slack.Kind))"

$cssFull = [IO.Path]::GetFullPath($CssPath)
if (-not (Test-Path $cssFull)) { Fail "rtl.css not found at $cssFull. Run this from the downloaded slack-rtl folder." }
if (-not (Test-Path $IconSource)) { Fail "slack-rtl.ico not found next to this script. Run this from the downloaded slack-rtl folder." }

if (Get-SlackProcesses) {
  Fail 'Slack is running. Quit every Slack window first (tray icon next to the clock -> right-click Slack -> Quit), then run this again.'
}

$needProfile = $RefreshProfile -or -not (Test-Path $ProfileDir)
if ($needProfile -and -not (Test-Path (Join-Path $slack.Profile 'Local State'))) {
  Fail 'Your Slack profile was not found. Open Slack normally, sign in to your workspace, quit it, then run this again.'
}

Say '1/5 Copying the Slack app...'
New-Item -ItemType Directory -Force $Root | Out-Null
Invoke-Robocopy @($slack.AppDir, $AppDir, '/MIR')
Get-ChildItem $AppDir -Recurse -File | Where-Object { $_.IsReadOnly } | ForEach-Object { $_.IsReadOnly = $false }

Say '2/5 Adding the RTL fix to the copy...'
$asar = Join-Path $AppDir 'resources\app.asar'
if (-not (Test-Path $asar)) { Fail "Unexpected Slack layout: $asar not found." }
$header = Read-AsarHeader $asar
$headerObj = $header.Json | ConvertFrom-Json
$pkgEntry = Get-AsarEntry $headerObj 'package.json'
if (-not $pkgEntry) { Fail 'Unexpected Slack layout: package.json not found in app.asar.' }
$pkgJson = [Text.Encoding]::UTF8.GetString((Read-AsarFile $asar $header $pkgEntry)) | ConvertFrom-Json
$main = ([string]$pkgJson.main) -replace '^\./', ''
if (-not $main) { $main = 'index.js' }
$mainEntry = Get-AsarEntry $headerObj $main
if (-not $mainEntry) { Fail "Unexpected Slack layout: main script '$main' not found in app.asar." }
$mainText = [Text.Encoding]::UTF8.GetString((Read-AsarFile $asar $header $mainEntry))
if ($mainText.StartsWith($Marker)) { Fail 'The source Slack app is already patched. Reinstall Slack, then run this again.' }

$css = [IO.File]::ReadAllText($cssFull)
$cssJs = ConvertTo-Json $css -Compress
$iconJs = ConvertTo-Json $IconPath -Compress
$inject = @"
$Marker
;(function(){try{
  const { app } = require('electron');
  const css = $cssJs;
  const inject = (wc) => {
    try { if (/^https:\/\/app\.slack\.com\//.test(wc.getURL())) wc.insertCSS(css).catch(() => {}); } catch (_) {}
  };
  app.on('web-contents-created', (_e, wc) => { wc.on('dom-ready', () => inject(wc)); });
  // Our own icon on the taskbar, so the copy isn't presented with Slack's logo.
  app.on('browser-window-created', (_e, win) => { try { win.setIcon($iconJs); } catch (_) {} });
}catch(e){ console.error('slack-rtl inject failed', e); }})();

"@
$newMain = [Text.Encoding]::UTF8.GetBytes(($inject -replace "`r`n", "`n") + $mainText)
Set-AsarFile $asar $main $newMain

Say '3/5 Turning off the copy''s integrity check...'
$exe = Join-Path $AppDir 'slack.exe'
$fuse = Disable-AsarIntegrityFuse $exe
Say "    integrity check $fuse"

if ($needProfile) {
  Say '4/5 Copying your Slack profile (sign-in included)...'
  Invoke-Robocopy (@($slack.Profile, $ProfileDir, '/MIR', '/XD') + $ProfileSkip)
} else {
  Say '4/5 Keeping the existing Slack (RTL) profile (use -RefreshProfile to re-copy it).'
}

Say '5/5 Creating "Slack (RTL)" shortcuts (desktop and Start menu)...'
Copy-Item -Force $IconSource $IconPath
New-Shortcut $MenuLnk
New-Shortcut $DesktopLnk
if ($Startup) { New-Shortcut $StartupLnk; Say '    also added to Windows startup' }

[pscustomobject]@{
  SourceVersion = $slack.Version; SourceKind = $slack.Kind; SourceAppDir = $slack.AppDir
  BuiltAt = (Get-Date).ToString('yyyy-MM-dd HH:mm')
} | ConvertTo-Json | Set-Content -Encoding UTF8 $StateFile

Say ''
Say 'Done. Open "Slack (RTL)" from your desktop or the Start menu.' Green
Say 'Use it instead of your normal Slack. If both run, you get notifications twice.'
Say 'After Slack updates itself, run this again to rebuild the copy.'
