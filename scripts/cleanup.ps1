<#
.SYNOPSIS
    DroidBoost - Android TV Performance Optimizer & Bloatware Remover (PowerShell)
.DESCRIPTION
    Safely disables background bloatware, eliminates laggy animations, and optimizes
    Android TV / Google TV performance over ADB without root.
.PARAMETER TvIp
    The IP address of your Android TV (e.g. 192.168.0.107).
.PARAMETER AdbPath
    Optional explicit path to adb.exe. If omitted, auto-discovery is performed.
.PARAMETER SkipPrompts
    Run non-interactively, auto-confirming safe package disables.
.PARAMETER NoReboot
    Do not reboot the TV after completion.
.EXAMPLE
    .\cleanup.ps1 -TvIp "192.168.0.107"
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $false)]
    [string]$TvIp,

    [Parameter(Mandatory = $false)]
    [string]$AdbPath,

    [switch]$SkipPrompts,
    [switch]$NoReboot
)

$ErrorActionPreference = "Stop"

function Write-Banner {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "   🚀 DROIDBOOST - Android TV Cleanup & Speed Optimizer   " -ForegroundColor Yellow -BackgroundColor Black
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host " No root needed | No apps deleted | 100% reversible" -ForegroundColor Gray
    Write-Host ""
}

function Find-Adb {
    param([string]$ExplicitPath)

    if ($ExplicitPath -and (Test-Path $ExplicitPath)) {
        return (Resolve-Path $ExplicitPath).Path
    }

    # 1. Check in PATH
    $cmd = Get-Command "adb.exe" -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    # 2. Check current directory / parent folders
    $localAdb = Get-ChildItem -Path (Get-Location) -Filter "adb.exe" -Recurse -Depth 2 -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($localAdb) { return $localAdb.FullName }

    # 3. Check common Windows download locations
    $candidates = @(
        "$env:USERPROFILE\Downloads\platform-tools-latest-windows\platform-tools\adb.exe",
        "$env:USERPROFILE\Downloads\platform-tools\adb.exe",
        "C:\platform-tools\adb.exe",
        "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
    )

    foreach ($path in $candidates) {
        if (Test-Path $path) { return $path }
    }

    return $null
}

function Get-TvMemory {
    param([string]$Adb, [string]$Device)
    try {
        $memInfo = & $Adb -s $Device shell "cat /proc/meminfo" 2>$null
        $total = [regex]::Match($memInfo, "MemTotal:\s+(\d+)\s+kB").Groups[1].Value
        $available = [regex]::Match($memInfo, "MemAvailable:\s+(\d+)\s+kB").Groups[1].Value
        $swapTotal = [regex]::Match($memInfo, "SwapTotal:\s+(\d+)\s+kB").Groups[1].Value
        $swapFree = [regex]::Match($memInfo, "SwapFree:\s+(\d+)\s+kB").Groups[1].Value

        $totalMb = [math]::Round([int64]$total / 1024)
        $availMb = [math]::Round([int64]$available / 1024)
        $swapUsedMb = [math]::Round(([int64]$swapTotal - [int64]$swapFree) / 1024)

        return @{
            TotalMb    = $totalMb
            AvailMb    = $availMb
            SwapUsedMb = $swapUsedMb
        }
    } catch {
        return $null
    }
}

Write-Banner

# 1. Locate ADB
$adb = Find-Adb -ExplicitPath $AdbPath
if (-not $adb) {
    Write-Host "[!] adb.exe was not found automatically." -ForegroundColor Red
    $userAdb = Read-Host "Please enter the full path to adb.exe (or press Enter to exit)"
    if ($userAdb -and (Test-Path $userAdb)) {
        $adb = (Resolve-Path $userAdb).Path
    } else {
        Write-Host "[-] Could not find ADB. Download it from:" -ForegroundColor Yellow
        Write-Host "    https://developer.android.com/tools/releases/platform-tools" -ForegroundColor White
        exit 1
    }
}

Write-Host "[+] Using ADB: $adb" -ForegroundColor Green

# 2. Get TV IP
if (-not $TvIp) {
    $TvIp = Read-Host "Enter your Android TV IP address (e.g. 192.168.0.107)"
    if (-not $TvIp) {
        Write-Host "[-] TV IP address is required." -ForegroundColor Red
        exit 1
    }
}

$tvTarget = if ($TvIp.Contains(":")) { $TvIp } else { "$TvIp:5555" }

# 3. Connect to TV
Write-Host "`n[*] Connecting to TV at $tvTarget..." -ForegroundColor Cyan
& $adb connect $tvTarget | Out-Null
Start-Sleep -Seconds 1

$devicesOutput = & $adb devices
if ($devicesOutput -match "$tvTarget\s+unauthorized") {
    Write-Host "[!] Device is unauthorized." -ForegroundColor Yellow
    Write-Host "    Please check your TV screen and select 'Always allow from this computer', then press OK." -ForegroundColor White
    Read-Host "Press Enter once you have accepted the prompt on your TV"
    & $adb connect $tvTarget | Out-Null
}

$devicesOutput = & $adb devices
if ($devicesOutput -notmatch "$tvTarget\s+device") {
    Write-Host "[-] Could not connect to $tvTarget. Please check:" -ForegroundColor Red
    Write-Host "    1. TV is turned on and connected to the same Wi-Fi." -ForegroundColor White
    Write-Host "    2. Developer Options -> USB Debugging is ON." -ForegroundColor White
    Write-Host "    3. The IP address ($TvIp) is correct." -ForegroundColor White
    exit 1
}

Write-Host "[+] Successfully connected to TV!" -ForegroundColor Green

# 4. Check initial memory
Write-Host "`n[*] Checking TV memory status..." -ForegroundColor Cyan
$memBefore = Get-TvMemory -Adb $adb -Device $tvTarget
if ($memBefore) {
    Write-Host "    Total RAM:     $($memBefore.TotalMb) MB" -ForegroundColor White
    Write-Host "    Available RAM: $($memBefore.AvailMb) MB" -ForegroundColor White
    Write-Host "    Swap Used:     $($memBefore.SwapUsedMb) MB" -ForegroundColor White
}

# 5. Load bloatware catalog
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path (Split-Path -Parent $scriptDir) "configs\bloatware-list.json"

$safeList = @()
$protectedList = @(
    "android", "com.android.systemui", "com.android.tv.settings",
    "com.google.android.gms", "com.android.vending", "com.android.bluetooth",
    "com.google.android.inputmethod.latin", "com.mediatek.tvinput"
)

if (Test-Path $configPath) {
    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        $safeList = $config.safe_to_disable
        if ($config.protected) { $protectedList = $config.protected }
    } catch {
        Write-Host "[!] Could not load config JSON, using built-in defaults." -ForegroundColor Yellow
    }
}

# 6. Fetch installed packages on TV
Write-Host "`n[*] Scanning packages on TV..." -ForegroundColor Cyan
$installedRaw = & $adb -s $tvTarget shell "pm list packages"
$installed = @()
foreach ($line in $installedRaw) {
    if ($line -match "^package:(.+)$") {
        $installed += $matches[1].Trim()
    }
}

Write-Host "[+] Found $($installed.Count) total packages installed." -ForegroundColor Green

# Match safe candidates
$candidates = @()
foreach ($item in $safeList) {
    $pkg = $item.package
    if ($installed -contains $pkg) {
        $candidates += $item
    }
}

Write-Host "`n[*] Found $($candidates.Count) known bloatware apps installed on this TV:" -ForegroundColor Cyan
$candidates | Format-Table -Property @{Label="App Name"; Expression={$_.name}},
                                   @{Label="Package"; Expression={$_.package}},
                                   @{Label="Category"; Expression={$_.category}} | Out-String | Write-Host

if ($candidates.Count -eq 0) {
    Write-Host "[+] No known bloatware packages detected! Your TV is already quite clean." -ForegroundColor Green
} else {
    $proceed = $true
    if (-not $SkipPrompts) {
        $ans = Read-Host "Do you want to disable these $($candidates.Count) bloatware apps? (y/n)"
        if ($ans -notmatch "^[yY]") {
            $proceed = $false
            Write-Host "[*] Skipping package disabling." -ForegroundColor Yellow
        }
    }

    if ($proceed) {
        $disabledLog = @()
        Write-Host "`n[*] Disabling bloatware packages safely (user-space disable)..." -ForegroundColor Cyan
        foreach ($c in $candidates) {
            $pkg = $c.package
            if ($protectedList -contains $pkg) {
                Write-Host "    [SKIP] $pkg is in the protected list." -ForegroundColor Yellow
                continue
            }

            Write-Host "    [-] Disabling $($c.name) ($pkg)..." -NoNewline
            $result = & $adb -s $tvTarget shell "pm disable-user --user 0 $pkg" 2>&1
            if ($result -match "new state:\s*disabled") {
                Write-Host " [OK]" -ForegroundColor Green
                $disabledLog += $pkg
                # Record on TV
                & $adb -s $tvTarget shell "echo $pkg >> /data/local/tmp/droidboost-disabled.txt" 2>$null
            } else {
                Write-Host " [SKIPPED/FAILED]" -ForegroundColor Yellow
            }
        }
        Write-Host "[+] Successfully disabled $($disabledLog.Count) bloatware apps." -ForegroundColor Green
    }
}

# 7. Apply Speed / Performance Tweaks
Write-Host "`n[*] Applying Performance & Animation Tweaks..." -ForegroundColor Cyan

Write-Host "    [*] Setting Window animation scale -> 0 (instant)"
& $adb -s $tvTarget shell "settings put global window_animation_scale 0" | Out-Null

Write-Host "    [*] Setting Transition animation scale -> 0 (instant)"
& $adb -s $tvTarget shell "settings put global transition_animation_scale 0" | Out-Null

Write-Host "    [*] Setting Animator duration scale -> 0 (instant)"
& $adb -s $tvTarget shell "settings put global animator_duration_scale 0" | Out-Null

Write-Host "    [*] Disabling background screensaver (saves RAM)"
& $adb -s $tvTarget shell "settings put secure screensaver_enabled 0" | Out-Null

Write-Host "    [*] Setting Screen Off timeout to 5 minutes"
& $adb -s $tvTarget shell "settings put system screen_off_timeout 300000" | Out-Null

Write-Host "[+] System tweaks applied successfully." -ForegroundColor Green

# 8. Check Memory After
Start-Sleep -Seconds 2
$memAfter = Get-TvMemory -Adb $adb -Device $tvTarget
if ($memAfter -and $memBefore) {
    Write-Host "`n==========================================================" -ForegroundColor Cyan
    Write-Host "                   PERFORMANCE SUMMARY                    " -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "  Available RAM: $($memBefore.AvailMb) MB  ->  $($memAfter.AvailMb) MB" -ForegroundColor Green
    Write-Host "  Swap Memory:   $($memBefore.SwapUsedMb) MB  ->  $($memAfter.SwapUsedMb) MB" -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Cyan
}

# 9. Reboot recommendation
if (-not $NoReboot) {
    $doReboot = $true
    if (-not $SkipPrompts) {
        $ans = Read-Host "`nDo you want to reboot the TV now to apply all optimizations? (y/n)"
        if ($ans -notmatch "^[yY]") {
            $doReboot = $false
        }
    }

    if ($doReboot) {
        Write-Host "[*] Rebooting TV now..." -ForegroundColor Yellow
        & $adb -s $tvTarget reboot
        Write-Host "[+] TV is rebooting. Please wait about 30-45 seconds." -ForegroundColor Green
    } else {
        Write-Host "[*] You can reboot your TV manually whenever you are ready." -ForegroundColor Gray
    }
}

Write-Host "`n[+] DroidBoost cleanup complete!" -ForegroundColor Green
Write-Host "    If you ever want to undo changes, run: .\undo.ps1 -TvIp $TvIp`n" -ForegroundColor White
