<#
.SYNOPSIS
    DroidBoost - Undo Script (PowerShell)
.DESCRIPTION
    Restores all disabled bloatware apps, animation scales, and default settings on Android TV.
.PARAMETER TvIp
    The IP address of your Android TV (e.g. 192.168.0.107).
.PARAMETER AdbPath
    Optional explicit path to adb.exe. If omitted, auto-discovery is performed.
.EXAMPLE
    .\undo.ps1 -TvIp "192.168.0.107"
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $false)]
    [string]$TvIp,

    [Parameter(Mandatory = $false)]
    [string]$AdbPath
)

$ErrorActionPreference = "Stop"

function Find-Adb {
    param([string]$ExplicitPath)
    if ($ExplicitPath -and (Test-Path $ExplicitPath)) { return (Resolve-Path $ExplicitPath).Path }
    $cmd = Get-Command "adb.exe" -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $candidates = @(
        "$env:USERPROFILE\Downloads\platform-tools-latest-windows\platform-tools\adb.exe",
        "$env:USERPROFILE\Downloads\platform-tools\adb.exe",
        "C:\platform-tools\adb.exe",
        "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
    )
    foreach ($path in $candidates) { if (Test-Path $path) { return $path } }
    return $null
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "               DROIDBOOST - UNDO / RESTORE                " -ForegroundColor Yellow -BackgroundColor Black
Write-Host "==========================================================" -ForegroundColor Cyan

$adb = Find-Adb -ExplicitPath $AdbPath
if (-not $adb) {
    $userAdb = Read-Host "Please enter the full path to adb.exe"
    if ($userAdb -and (Test-Path $userAdb)) { $adb = (Resolve-Path $userAdb).Path } else { exit 1 }
}

if (-not $TvIp) {
    $TvIp = Read-Host "Enter your Android TV IP address (e.g. 192.168.0.107)"
    if (-not $TvIp) { exit 1 }
}

$tvTarget = if ($TvIp.Contains(":")) { $TvIp } else { "$TvIp:5555" }

Write-Host "[*] Connecting to TV at $tvTarget..." -ForegroundColor Cyan
& $adb connect $tvTarget | Out-Null
Start-Sleep -Seconds 1

# Check connection
$devicesOutput = & $adb devices
if ($devicesOutput -notmatch "$tvTarget\s+device") {
    Write-Host "[-] Could not connect to $tvTarget. Make sure TV is on and debugging is enabled." -ForegroundColor Red
    exit 1
}

Write-Host "[+] Connected!" -ForegroundColor Green

# 1. Fetch apps recorded on TV
Write-Host "`n[*] Reading disabled package history from TV..." -ForegroundColor Cyan
$tvHistory = & $adb -s $tvTarget shell "cat /data/local/tmp/droidboost-disabled.txt 2>/dev/null"

# Also load config list in case file was cleared
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path (Split-Path -Parent $scriptDir) "configs\bloatware-list.json"
$knownBloat = @()
if (Test-Path $configPath) {
    try {
        $cfg = Get-Content $configPath -Raw | ConvertFrom-Json
        $knownBloat = $cfg.safe_to_disable | ForEach-Object { $_.package }
    } catch {}
}

$packagesToEnable = [System.Collections.Generic.HashSet[string]]::new()
if ($tvHistory) {
    foreach ($line in ($tvHistory -split "`n")) {
        $clean = $line.Trim()
        if ($clean) { [void]$packagesToEnable.Add($clean) }
    }
}
foreach ($p in $knownBloat) {
    if ($p) { [void]$packagesToEnable.Add($p) }
}

# Also check launcher
[void]$packagesToEnable.Add("com.google.android.tvlauncher")

Write-Host "[*] Re-enabling packages..." -ForegroundColor Cyan
$count = 0
foreach ($pkg in $packagesToEnable) {
    $res = & $adb -s $tvTarget shell "pm enable $pkg" 2>&1
    if ($res -match "new state:\s*enabled") {
        Write-Host "    [+] Restored: $pkg" -ForegroundColor Green
        $count++
    }
}
Write-Host "[+] Restored $count packages." -ForegroundColor Green

# 2. Restore Animation Settings
Write-Host "`n[*] Restoring default animation scales (1.0x)..." -ForegroundColor Cyan
& $adb -s $tvTarget shell "settings put global window_animation_scale 1"
& $adb -s $tvTarget shell "settings put global transition_animation_scale 1"
& $adb -s $tvTarget shell "settings put global animator_duration_scale 1"

# 3. Restore Screensaver
Write-Host "[*] Restoring screensaver..." -ForegroundColor Cyan
& $adb -s $tvTarget shell "settings put secure screensaver_enabled 1"

# Clean up TV log
& $adb -s $tvTarget shell "rm -f /data/local/tmp/droidboost-disabled.txt" 2>$null

Write-Host "`n[+] All default settings and apps have been restored!" -ForegroundColor Green

$rebootAns = Read-Host "`nReboot TV now to apply changes? (y/n)"
if ($rebootAns -match "^[yY]") {
    Write-Host "[*] Rebooting TV..." -ForegroundColor Yellow
    & $adb -s $tvTarget reboot
}
