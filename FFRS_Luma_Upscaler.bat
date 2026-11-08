@echo off
REM ===========================================================================
REM  FINAL FANTASY RESONANCE  --  Luma upscaler setup (DLSS / FSR 4 / XeSS)
REM  https://github.com/haithemobeidi/final-fantasy-resonance-ultrawide
REM
REM  Replaces the game's TAA with DLSS (NVIDIA), FSR 4 / FSR 3 (AMD) or XeSS,
REM  running at native resolution (DLAA-style anti-aliasing). Three open
REM  projects do the work; this script only fetches, verifies and places them:
REM  - Luma for Unreal Engine (github.com/Filoppi/Luma-Framework, by Filoppi,
REM    Izueh and Pumbo). Ships ReShade 6.8 (crosire) as dxgi.dll, the Luma
REM    add-on, and NVIDIA / AMD / Intel upscaler runtimes. DX11 only.
REM  - Anti-Aliasing Options by jmroon (github.com/jmroon/ffres-mods, MIT).
REM    Adds TAA to the game's AA Method menu; Luma needs the game on TAA.
REM    Comes with UE4SS (github.com/UE4SS-RE/RE-UE4SS) as dwmapi.dll.
REM  - Steam launch option -dx11 (the game runs DX12 by default).
REM
REM  This script:
REM  - downloads both zips from GitHub and checks their SHA-256 (or uses
REM    copies of the same zips placed next to this file)
REM  - refuses on any game build other than the retail Steam build of
REM    2026-10-22: the AA mod replaces a menu table built from that build
REM  - refuses to overwrite any file it did not put there (another ReShade
REM    or UE4SS install, for example)
REM  - sets DLSS preset K the first time (preset L cost ~170 W more on an
REM    RTX 5090 at native resolution, with no visible gain)
REM  - adds -dx11 to the game's Steam launch options; Steam has to close for
REM    a few seconds for that, and the script asks first
REM  - has a Remove option that deletes exactly what it added
REM
REM  Works alongside the ultrawide fix (FFRS_Ultrawide_Fix.bat, PolarWizard's
REM  fix with Darjjj's retail offsets); neither needs the other.
REM
REM  Everything below the marker line is plain PowerShell. Read it first if
REM  you like - you should always check scripts before running them.
REM ===========================================================================
set "FFRS_DIR=%~dp0"
set "FFRS_SELF=%~f0"
set "FFRS_ARG=%~1"
REM (paths passed via env vars: an apostrophe in the path breaks '%~f0' quoting)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$c=Get-Content -LiteralPath $env:FFRS_SELF -Raw; $m=[char]35+'===BEGIN-POWERSHELL==='; $i=$c.LastIndexOf($m); Invoke-Expression $c.Substring($i+$m.Length)"
echo.
if "%~1"=="" pause
exit /b

#===BEGIN-POWERSHELL===

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
try { $Host.UI.RawUI.WindowTitle = 'FINAL FANTASY RESONANCE - Luma upscaler setup' } catch {}

function Say($msg, $col = 'Gray') { Write-Host $msg -ForegroundColor $col }

Say ""
Say "  ==========================================================" Cyan
Say "   FINAL FANTASY RESONANCE  -  Luma upscaler (DLSS/FSR/XeSS)" Cyan
Say "  ==========================================================" Cyan
Say ""

# ---------------------------------------------------------------- constants --
$GAME_FOLDER  = 'FINAL FANTASY RESONANCE'
$EXE_NAME     = 'FFRS-Win64-Shipping.exe'
$STEAM_APPID  = '3259780'
# Retail Steam build of 2026-10-22 (buildid 24250053): the exe's PE TimeDateStamp.
# The AA mod's supported-inputs.json names the same buildid.
$BUILD_STAMP  = [uint32]0x6A586B2F

$LUMA_ZIP     = 'Luma-Unreal_Engine.zip'
$LUMA_URL     = 'https://github.com/Filoppi/Luma-Framework/releases/download/latest-801/Luma-Unreal_Engine.zip'
$LUMA_SHA     = '44B579D3A3DCEE483DBBA3BFEF69CFAFE1C102794B135D77864E67AACB7B0C90'
$AA_ZIP       = 'Anti-Aliasing-Options-1.0.1-Standalone.zip'
$AA_URL       = 'https://github.com/jmroon/ffres-mods/releases/download/anti-aliasing-options-v1.0.1/Anti-Aliasing-Options-1.0.1-Standalone.zip'
$AA_SHA       = 'D1D206E50824675C1364266E22C0AD4DDD51F3267C65A033B08B1C6B2A730030'

$LAUNCH_ARG   = '-dx11'
$DLSS_PRESET  = '11'     # K. Luma's values: 0 Default, 10 J, 11 K, 12 L, 13 M
$MANIFEST     = '_ffrs_luma_installed_files.txt'

$SR_NAMES     = @{ '0' = 'None (off)'; '1' = 'Auto'; '2' = 'DLSS'; '3' = 'FSR 3'; '4' = 'FSR 4'; '5' = 'XeSS' }
$PRESET_NAMES = @{ '0' = 'Default'; '5' = 'E'; '6' = 'F'; '10' = 'J'; '11' = 'K'; '12' = 'L'; '13' = 'M' }

# ------------------------------------------------------------------ helpers --
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Sha256Stream($s) {
    $h = [System.Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($h.ComputeHash($s)) -replace '-', '') } finally { $h.Dispose() }
}
function Sha256File([string]$p) {
    # .NET directly: Get-FileHash is a script-module function in Windows PowerShell and
    # does not resolve when module auto-loading is unavailable (seen when launched from pwsh 7).
    $fs = [System.IO.File]::OpenRead($p)
    try { return (Sha256Stream $fs) } finally { $fs.Close() }
}
function Sha256Entry($e) {
    $s = $e.Open()
    try { return (Sha256Stream $s) } finally { $s.Close() }
}

function CheckBuild([string]$exePath) {
    $fs = [System.IO.File]::Open($exePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try {
        $hdr = New-Object byte[] 4096
        [void]$fs.Read($hdr, 0, 4096)
        if ($hdr[0] -ne 0x4D -or $hdr[1] -ne 0x5A) { return 'NOT-AN-EXE' }
        $peOff = [BitConverter]::ToInt32($hdr, 0x3C)
        if ($peOff -lt 0 -or $peOff -gt 4000) { return 'NOT-AN-EXE' }
        if ([BitConverter]::ToUInt32($hdr, $peOff + 8) -eq $BUILD_STAMP) { return 'RETAIL' }
        return 'OTHER-BUILD'
    } finally { $fs.Close() }
}

# ReShade.ini: read or add one key in one section; everything else is left alone.
function IniSection([string]$t, [string]$section) {
    return [regex]::Match($t, '(?ms)^\[' + [regex]::Escape($section) + '\][^\r\n]*\r?\n(.*?)(?=^\[|\z)')
}
function IniGet([string]$path, [string]$section, [string]$key) {
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    $m = IniSection ([System.IO.File]::ReadAllText($path)) $section
    if (-not $m.Success) { return $null }
    $k = [regex]::Match($m.Groups[1].Value, '(?m)^\s*' + [regex]::Escape($key) + '\s*=\s*([^\r\n]*?)\s*$')
    if ($k.Success) { return $k.Groups[1].Value } else { return $null }
}
function IniEnsure([string]$path, [string]$section, [string]$key, [string]$value) {
    $ascii = New-Object System.Text.ASCIIEncoding
    if (-not (Test-Path -LiteralPath $path)) {
        [System.IO.File]::WriteAllText($path, "[$section]`r`n$key=$value`r`n", $ascii); return 'CREATED'
    }
    if ($null -ne (IniGet $path $section $key)) { return 'KEPT' }
    $t = [System.IO.File]::ReadAllText($path)
    $m = IniSection $t $section
    if ($m.Success) { $t = $t.Insert($m.Groups[1].Index, "$key=$value`r`n") }
    else {
        if ($t.Length -gt 0 -and -not $t.EndsWith("`n")) { $t += "`r`n" }
        $t += "`r`n[$section]`r`n$key=$value`r`n"
    }
    [System.IO.File]::WriteAllText($path, $t, $ascii)
    return 'ADDED'
}

# ------------------------------------------------- Steam launch option (VDF) --
# localconfig.vdf is Valve KeyValues text: one "key" or "key" "value" per line, braces
# on their own lines. The app's block sits at UserLocalConfigStore/Software/Valve/Steam/apps.
function SteamPath {
    try { return ((Get-ItemProperty -Path 'HKCU:\Software\Valve\Steam' -Name SteamPath -ErrorAction Stop).SteamPath -replace '/', '\') } catch { return $null }
}
function SteamUserConfig([string]$steam) {
    if ($env:FFRS_STEAM_LOCALCONFIG) { return $env:FFRS_STEAM_LOCALCONFIG }   # test hook: a copy; Steam is never touched
    if (-not $steam) { return $null }
    $id = 0
    try { $id = [uint64](Get-ItemProperty -Path 'HKCU:\Software\Valve\Steam\ActiveProcess' -Name ActiveUser -ErrorAction Stop).ActiveUser } catch {}
    if ($id -eq 0) {
        $lu = Join-Path $steam 'config\loginusers.vdf'
        if (Test-Path -LiteralPath $lu) {
            foreach ($m in [regex]::Matches((Get-Content -LiteralPath $lu -Raw), '(?s)"(\d{17})"\s*\{(.*?)\}')) {
                if ($m.Groups[2].Value -match '"MostRecent"\s+"1"') { $id = [uint64]$m.Groups[1].Value - [uint64]76561197960265728; break }
            }
        }
    }
    if ($id -ne 0) {
        $p = Join-Path $steam "userdata\$id\config\localconfig.vdf"
        if (Test-Path -LiteralPath $p) { return $p }
    }
    $ud = Join-Path $steam 'userdata'
    if (Test-Path -LiteralPath $ud) {
        $all = @(Get-ChildItem -LiteralPath $ud -Directory | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'config\localconfig.vdf') })
        if ($all.Count -eq 1) { return (Join-Path $all[0].FullName 'config\localconfig.vdf') }
    }
    return $null
}
function VdfFind([string[]]$lines) {
    $r = @{ AppsOpen = -1; AppOpen = -1; Launch = -1; LaunchValue = $null }
    $stack = New-Object System.Collections.Generic.List[string]
    $pending = ''
    $appsPath = 'userlocalconfigstore/software/valve/steam/apps'
    $appPath = "$appsPath/$STEAM_APPID"
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $t = $lines[$i].Trim()
        if ($t -eq '{') {
            $stack.Add($pending); $pending = ''
            $p = ($stack -join '/').ToLowerInvariant()
            if ($p -eq $appsPath) { $r.AppsOpen = $i }
            if ($p -eq $appPath) { $r.AppOpen = $i }
            continue
        }
        if ($t -eq '}') { if ($stack.Count -gt 0) { $stack.RemoveAt($stack.Count - 1) }; continue }
        $m = [regex]::Match($t, '^"((?:[^"\\]|\\.)*)"(?:\s+"((?:[^"\\]|\\.)*)")?$')
        if (-not $m.Success) { continue }
        if ($m.Groups[2].Success) {
            if ((($stack -join '/').ToLowerInvariant() -eq $appPath) -and $m.Groups[1].Value -ieq 'LaunchOptions') {
                $r.Launch = $i; $r.LaunchValue = $m.Groups[2].Value
            }
        } else { $pending = $m.Groups[1].Value }
    }
    return $r
}
function VdfRead([string]$path) {
    $raw = [System.IO.File]::ReadAllText($path)
    $nl = "`n"; if ($raw.Contains("`r`n")) { $nl = "`r`n" }
    return @{ Lines = [regex]::Split($raw, '\r?\n'); NL = $nl }
}
function HasLaunchArg([string]$v) { return ($null -ne $v -and $v -match ('(?i)(^|\s)' + [regex]::Escape($LAUNCH_ARG) + '(\s|$)')) }
function GetLaunchOptions([string]$path) {
    $v = VdfRead $path
    return (VdfFind $v.Lines).LaunchValue
}
function SetLaunchArg([string]$path, [bool]$add) {
    $v = VdfRead $path
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.AddRange([string[]]$v.Lines)
    $f = VdfFind $lines.ToArray()
    if ($add) {
        if (HasLaunchArg $f.LaunchValue) { return 'ALREADY' }
        if ($f.Launch -ge 0) {
            $ind = [regex]::Match($lines[$f.Launch], '^\s*').Value
            $lines[$f.Launch] = $ind + '"LaunchOptions"' + "`t`t" + '"' + ($f.LaunchValue + ' ' + $LAUNCH_ARG).Trim() + '"'
        } elseif ($f.AppOpen -ge 0) {
            $ind = [regex]::Match($lines[$f.AppOpen], '^\s*').Value + "`t"
            $lines.Insert($f.AppOpen + 1, $ind + '"LaunchOptions"' + "`t`t" + '"' + $LAUNCH_ARG + '"')
        } elseif ($f.AppsOpen -ge 0) {
            $ind = [regex]::Match($lines[$f.AppsOpen], '^\s*').Value + "`t"
            $lines.InsertRange($f.AppsOpen + 1, [string[]]@(
                ($ind + '"' + $STEAM_APPID + '"'), ($ind + '{'),
                ($ind + "`t" + '"LaunchOptions"' + "`t`t" + '"' + $LAUNCH_ARG + '"'), ($ind + '}')))
        } else { return 'NO-APPS' }
    } else {
        if (-not (HasLaunchArg $f.LaunchValue)) { return 'ABSENT' }
        $nv = ([regex]::Replace($f.LaunchValue, ('(?i)(^|\s)' + [regex]::Escape($LAUNCH_ARG) + '(?=\s|$)'), ' ') -replace '\s{2,}', ' ').Trim()
        $ind = [regex]::Match($lines[$f.Launch], '^\s*').Value
        $lines[$f.Launch] = $ind + '"LaunchOptions"' + "`t`t" + '"' + $nv + '"'
    }
    [System.IO.File]::WriteAllText($path, ($lines.ToArray() -join $v.NL), (New-Object System.Text.UTF8Encoding $false))
    return 'CHANGED'
}
function SayManualLaunch([bool]$add) {
    if ($add) { Say "  Set it by hand: Steam > right-click FINAL FANTASY RESONANCE > Properties >" Yellow; Say "  General > Launch Options, and type:  $LAUNCH_ARG" Yellow }
    else { Say "  Remove it by hand: Steam > right-click the game > Properties > Launch Options." Yellow }
}
function ApplyLaunchArg([string]$steam, [bool]$add) {
    $cfg = SteamUserConfig $steam
    if (-not $cfg) { Say "  Could not find your Steam user config." Yellow; SayManualLaunch $add; return }
    $has = HasLaunchArg (GetLaunchOptions $cfg)
    if ($add -and $has) { Say "  Steam launch option $LAUNCH_ARG is already set." Green; return }
    if (-not $add -and -not $has) { return }
    $closed = $false
    if (-not $env:FFRS_STEAM_LOCALCONFIG -and (Get-Process -Name 'steam' -ErrorAction SilentlyContinue)) {
        $verb = 'add'; if (-not $add) { $verb = 'remove' }
        $ans = $env:FFRS_CLOSE_STEAM
        if (-not $ans -and -not $env:FFRS_ARG) { $ans = Read-Host "  Steam must close for a few seconds to $verb $LAUNCH_ARG. Close and reopen Steam now? [Y/N]" }
        if ($ans -notmatch '^(?i)(y|yes)$') { SayManualLaunch $add; return }
        Say "  Closing Steam..." DarkGray
        Start-Process -FilePath (Join-Path $steam 'steam.exe') -ArgumentList '-shutdown'
        $t = 0
        while ((Get-Process -Name 'steam' -ErrorAction SilentlyContinue) -and $t -lt 90) { Start-Sleep -Seconds 1; $t++ }
        if (Get-Process -Name 'steam' -ErrorAction SilentlyContinue) { Say "  Steam did not close." Red; SayManualLaunch $add; return }
        $closed = $true
    }
    try {
        Copy-Item -LiteralPath $cfg -Destination "$cfg.ffrs-luma.bak" -Force
        $r = SetLaunchArg $cfg $add
        switch ($r) {
            'CHANGED' { if ($add) { Say "  Steam launch option $LAUNCH_ARG added (backup: localconfig.vdf.ffrs-luma.bak)." Green } else { Say "  Steam launch option $LAUNCH_ARG removed." Green } }
            'NO-APPS' { Say "  Steam's config has no apps section yet (launch the game once first)." Yellow; SayManualLaunch $add }
        }
    } catch { Say "  Could not edit Steam's config: $($_.Exception.Message)" Red; SayManualLaunch $add }
    finally {
        if ($closed) { Say "  Starting Steam again..." DarkGray; Start-Process -FilePath (Join-Path $steam 'steam.exe') }
    }
}

# ------------------------------------------------------------- GPU (info) --
function GpuNames {
    $names = @()
    try { $names = @(Get-CimInstance -ClassName Win32_VideoController -ErrorAction Stop | ForEach-Object { $_.Name }) } catch {}
    if ($names.Count -eq 0) {
        try {
            $cls = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
            $names = @(Get-ChildItem -LiteralPath $cls -ErrorAction Stop | ForEach-Object { (Get-ItemProperty -LiteralPath $_.PSPath -Name DriverDesc -ErrorAction SilentlyContinue).DriverDesc } | Where-Object { $_ })
        } catch {}
    }
    return @($names | Where-Object { $_ -notmatch 'Basic|Virtual|Remote|Parsec|Meta' } | Select-Object -Unique)
}

# ---------------------------------------------------------------- find game --
# 1) FFRS_GAME_DIR (an explicit Win64 folder)  2) next to this .bat, or this .bat
# in the game's root folder  3) any Steam library listed in libraryfolders.vdf
$steam = SteamPath
$win64 = $null
if ($env:FFRS_GAME_DIR -and (Test-Path -LiteralPath (Join-Path $env:FFRS_GAME_DIR $EXE_NAME))) { $win64 = $env:FFRS_GAME_DIR }
if (-not $win64 -and $env:FFRS_DIR) {
    $here = $env:FFRS_DIR.TrimEnd('\')
    foreach ($cand in @($here, (Join-Path $here 'FFRS\Binaries\Win64'))) {
        if (Test-Path -LiteralPath (Join-Path $cand $EXE_NAME)) { $win64 = $cand; break }
    }
}
if (-not $win64 -and $steam) {
    $libs = @($steam)
    $vdf = Join-Path $steam 'steamapps\libraryfolders.vdf'
    if (Test-Path -LiteralPath $vdf) {
        foreach ($m in [regex]::Matches((Get-Content -LiteralPath $vdf -Raw), '"path"\s+"([^"]+)"')) { $libs += $m.Groups[1].Value -replace '\\\\', '\' }
    }
    foreach ($lib in $libs) {
        $cand = Join-Path $lib "steamapps\common\$GAME_FOLDER\FFRS\Binaries\Win64"
        if (Test-Path -LiteralPath (Join-Path $cand $EXE_NAME)) { $win64 = $cand; break }
    }
}
if (-not $win64) {
    Say "  Could not find the game. Put this .bat in the game folder (the one" Red
    Say "  with FFRS.exe; Steam: right-click the game > Manage > Browse local" Yellow
    Say "  files) and run it again." Yellow
    return
}
$win64    = (Resolve-Path -LiteralPath $win64).ProviderPath.TrimEnd('\')
$gameRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $win64))
$manifest = Join-Path $win64 $MANIFEST
$iniPath  = Join-Path $win64 'ReShade.ini'
$logPath  = Join-Path $win64 'ReShade.log'
Say "  Game found:" Green
Say "    $win64"
Say ""

# ------------------------------------------------------------------- status --
$build = CheckBuild (Join-Path $win64 $EXE_NAME)
$lumaOn = (Test-Path -LiteralPath (Join-Path $win64 'Luma-Unreal Engine.addon')) -and (Test-Path -LiteralPath (Join-Path $win64 'dxgi.dll'))
$aaOn   = (Test-Path -LiteralPath (Join-Path $win64 'dwmapi.dll')) -and (Test-Path -LiteralPath (Join-Path $win64 'ue4ss\Mods\AntiAliasingOptions\Scripts\main.lua'))
$cfg = SteamUserConfig $steam
$launch = $null; if ($cfg) { try { $launch = GetLaunchOptions $cfg } catch {} }

switch ($build) {
    'RETAIL'      { Say "  Game build:     retail Steam build of 2026-10-22 (supported)" Green }
    'OTHER-BUILD' { Say "  Game build:     NOT the build this script knows (updated game?)" Red }
    default       { Say "  Game build:     $EXE_NAME is not a valid executable" Red }
}
if ($lumaOn) { Say "  Luma:           installed (dxgi.dll = ReShade + Luma add-on)" Green } else { Say "  Luma:           not installed" Yellow }
if ($aaOn)   { Say "  AA menu mod:    installed (adds TAA to AA Method; UE4SS)" Green } else { Say "  AA menu mod:    not installed" Yellow }
if (-not $cfg) { Say "  Steam option:   could not find Steam's user config" Yellow }
elseif (HasLaunchArg $launch) { Say "  Steam option:   $LAUNCH_ARG is set" Green }
else { Say "  Steam option:   $LAUNCH_ARG is NOT set (Luma only works in DX11)" Yellow }
if ($lumaOn) {
    $sr = IniGet $iniPath 'Luma' 'SRUserType'; if ($null -eq $sr) { $sr = '1' }
    $pr = IniGet $iniPath 'Luma' 'DLSSRenderPreset'; if ($null -eq $pr) { $pr = '0' }
    $srN = $SR_NAMES[$sr]; if (-not $srN) { $srN = "value $sr" }
    $prN = $PRESET_NAMES[$pr]; if (-not $prN) { $prN = "value $pr" }
    Say "  Upscaler:       $srN   (DLSS preset: $prN)" Gray
}
$gpus = GpuNames
if ($gpus.Count -gt 0) { Say "  GPU:            $($gpus -join ', ')" Gray }

# What the last launch did, from ReShade's log (Luma writes its lines there).
if ($lumaOn -and (Test-Path -LiteralPath $logPath)) {
    $log = Get-Content -LiteralPath $logPath
    Say ""
    Say "  Last launch ($((Get-Item -LiteralPath $logPath).LastWriteTime.ToString('yyyy-MM-dd HH:mm'))):" Gray
    if ($log -match 'Registered add-on "Luma"') { Say "    Luma loaded." Green } else { Say "    Luma did not load (was the game started with $LAUNCH_ARG?)" Red }
    if ($log -match '\[Luma\] UE4: Detected UE4 TAA\. Hash') { Say "    Luma found TAA in use and replaced it." Green }
    else { Say "    TAA not seen yet: in game set Graphics Settings > AA Method to TAA." Yellow }
    $fsr4 = @($log | Where-Object { $_ -match '\[Luma\] FSR4: ' } | Select-Object -Last 1)
    if ($fsr4.Count -gt 0) {
        $line = ($fsr4[0] -replace '^.*\[Luma\] FSR4: ', '')
        if ($line -match '^Initialized' -and $line -notmatch 'spoofing') { Say "    FSR 4: $line" Green } else { Say "    FSR 4: $line" DarkGray }
    }
    $xess = @($log | Where-Object { $_ -match '\[Luma\] XeSS: ' } | Select-Object -Last 1)
    if ($xess.Count -gt 0) { Say "    XeSS: $($xess[0] -replace '^.*\[Luma\] XeSS: ', '')" DarkGray }
    Say "    The Home key shows which upscaler Luma picked (Add-ons tab)." DarkGray
}

$installed = ($lumaOn -and $aaOn -and (HasLaunchArg $launch))
Say ""
if ($installed) { Say "  Current status:  INSTALLED" Green }
elseif (-not $lumaOn -and -not $aaOn) { Say "  Current status:  not installed" Yellow }
else { Say "  Current status:  partly installed or needs repair" Yellow }
Say ""
Say "  [1]  Install / repair"
Say "  [2]  Remove (deletes only what this script added)"
Say "  [3]  Exit"
Say ""
$choice = $env:FFRS_ARG
if (-not $choice) { $choice = Read-Host "  Choose" }
switch -Regex ($choice) {
    '^(1|install|repair)$'        { $choice = '1' }
    '^(2|remove|undo|uninstall)$' { $choice = '2' }
    default                       { $choice = '3' }
}
# Only a running copy of THIS install blocks (a process whose path we cannot read counts as this one).
$running = @(Get-Process -Name 'FFRS-Win64-Shipping', 'FFRS' -ErrorAction SilentlyContinue | Where-Object { -not $_.Path -or $_.Path -like "$gameRoot\*" })
if ($choice -ne '3' -and $running.Count -gt 0) {
    Say ""; Say "  The game is currently RUNNING. Close it first, then re-run this." Red
    return
}

# ------------------------------------------------------------------ install --
if ($choice -eq '1') {
    Say ""
    if ($build -ne 'RETAIL') {
        Say "  The game exe is not the retail build the AA menu mod was made for." Red
        Say "  Refusing to guess. Nothing was installed. If the game was updated, check" Yellow
        Say "  https://github.com/jmroon/ffres-mods/releases for a newer release first." Yellow
        return
    }

    # -- get both zips (a copy next to this .bat wins over a download), verify each
    $tmp = Join-Path $env:TEMP 'ffrs-luma'
    New-Item -ItemType Directory -Force -Path $tmp | Out-Null
    $zips = @()
    foreach ($z in @(@{ Name = $LUMA_ZIP; Url = $LUMA_URL; Sha = $LUMA_SHA; Label = 'Luma (build 801)' },
                     @{ Name = $AA_ZIP;   Url = $AA_URL;   Sha = $AA_SHA;   Label = 'Anti-Aliasing Options 1.0.1' })) {
        $path = $null
        if ($env:FFRS_DIR) { $p = Join-Path $env:FFRS_DIR $z.Name; if (Test-Path -LiteralPath $p) { $path = $p; Say "  Using the zip next to this script: $($z.Name)" DarkGray } }
        if (-not $path) {
            $path = Join-Path $tmp $z.Name
            if ((Test-Path -LiteralPath $path) -and (Sha256File $path) -ne $z.Sha) { Remove-Item -LiteralPath $path -Force }
            if (-not (Test-Path -LiteralPath $path)) {
                Say "  Downloading $($z.Label) from GitHub..." DarkGray
                try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}
                try { Invoke-WebRequest -Uri $z.Url -OutFile $path -UseBasicParsing }
                catch {
                    Say "  Download failed: $($_.Exception.Message)" Red
                    Say "  Download it yourself and put the zip next to this .bat:" Yellow
                    Say "    $($z.Url)" Yellow
                    return
                }
            }
        }
        $got = Sha256File $path
        if ($got -ne $z.Sha) {
            Say "  $($z.Name): SHA-256 does not match the release this script was written for." Red
            Say "    expected $($z.Sha)" DarkGray
            Say "    got      $got" DarkGray
            Say "  Nothing was installed." Yellow
            return
        }
        $zips += @{ Path = $path; Luma = ($z.Name -eq $LUMA_ZIP) }
    }

    # -- plan every file; refuse if anything already there differs from ours
    $plan = @(); $conflicts = @(); $present = 0
    foreach ($z in $zips) {
        $za = [System.IO.Compression.ZipFile]::OpenRead($z.Path)
        try {
            foreach ($e in $za.Entries) {
                if (-not $e.Name) { continue }
                if ($z.Luma) { $rel = 'FFRS\Binaries\Win64\' + ($e.FullName -replace '/', '\') }
                else {
                    if ($e.FullName -notlike 'FFRS/*') { continue }   # README.txt stays out of the game root
                    $rel = $e.FullName -replace '/', '\'
                }
                $dest = Join-Path $gameRoot $rel
                if (Test-Path -LiteralPath $dest) {
                    if ((Sha256File $dest) -eq (Sha256Entry $e)) { $present++ } else { $conflicts += $rel }
                } else { $plan += @{ Zip = $z.Path; Entry = $e.FullName; Rel = $rel; Dest = $dest } }
            }
        } finally { $za.Dispose() }
    }
    if ($conflicts.Count -gt 0) {
        Say "  These files already exist and are not the ones this script installs:" Red
        foreach ($c in $conflicts) { Say "    $c" Yellow }
        Say "  Another ReShade or UE4SS install, or a different version? Refusing to" Yellow
        Say "  overwrite. Nothing was installed." Yellow
        return
    }

    # -- write
    $written = @()
    try {
        foreach ($g in ($plan | Group-Object { $_.Zip })) {
            $za = [System.IO.Compression.ZipFile]::OpenRead($g.Name)
            try {
                foreach ($p in $g.Group) {
                    $dir = Split-Path -Parent $p.Dest
                    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
                    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($za.GetEntry($p.Entry), $p.Dest, $false)
                    $written += $p.Rel
                }
            } finally { $za.Dispose() }
        }
        $iniWas = Test-Path -LiteralPath $iniPath
        $iniR = IniEnsure $iniPath 'Luma' 'DLSSRenderPreset' $DLSS_PRESET
        if (-not $iniWas) { $written += 'FFRS\Binaries\Win64\ReShade.ini' }
    } catch {
        Say "  Could not write to the game folder: $($_.Exception.Message)" Red
        Say "  Right-click this file and pick 'Run as administrator'. Then run it again" Yellow
        Say "  (or choose [2] to clean up what was written)." Yellow
        if ($written.Count -gt 0) { Add-Content -LiteralPath $manifest -Value $written -Encoding ASCII }
        return
    }
    $old = @(); if (Test-Path -LiteralPath $manifest) { $old = @(Get-Content -LiteralPath $manifest | Where-Object { $_ -and $_ -notmatch '^#' }) }
    $all = @($old + $written + @($plan | ForEach-Object { $_.Rel })) | Select-Object -Unique
    # files that were already present and identical are ours too (an earlier install)
    foreach ($z in $zips) {
        $za = [System.IO.Compression.ZipFile]::OpenRead($z.Path)
        try { foreach ($e in $za.Entries) { if ($e.Name) {
            if ($z.Luma) { $all += 'FFRS\Binaries\Win64\' + ($e.FullName -replace '/', '\') }
            elseif ($e.FullName -like 'FFRS/*') { $all += ($e.FullName -replace '/', '\') } } } }
        finally { $za.Dispose() }
    }
    $all = @($all | Select-Object -Unique)
    $hdr = @('# Files added by FFRS_Luma_Upscaler.bat. Paths are relative to the game folder (the one with FFRS.exe).',
             '# The script''s Remove option deletes exactly these, plus the logs and caches ReShade, Luma and UE4SS write.')
    Set-Content -LiteralPath $manifest -Value ($hdr + $all) -Encoding ASCII

    if ($written.Count -eq 0) { Say "  Mod files: already installed ($present files checked)." Green }
    else { Say "  Mod files: $($written.Count) written, $present already in place." Green }
    if ($iniR -eq 'KEPT') { Say "  DLSS preset: keeping your existing choice." DarkGray }
    else { Say "  DLSS preset: K (change it any time in the Home overlay)." DarkGray }

    Say ""
    ApplyLaunchArg $steam $true
    Say ""
    Say "  NEXT, in the game:" Cyan
    Say "    1. Graphics Settings > AA Method > TAA, then Apply (Luma replaces TAA)." Gray
    Say "    2. Press Home for the ReShade/Luma overlay; the Add-ons tab shows the" Gray
    Say "       upscaler. 'No effect files found' on the first tab is normal." Gray
    Say "    3. The first session in DX11 stutters while shaders compile; it settles." Gray
    # Luma tries DLSS first, so the AMD note only matters on a machine without an NVIDIA GPU
    # (a desktop CPU's integrated Radeon shows up here too).
    if ((($gpus -join ' ') -match 'AMD|Radeon') -and (($gpus -join ' ') -notmatch 'NVIDIA')) {
        Say ""
        Say "  AMD: Luma picks FSR 4 when the driver offers it, else FSR 3. On the ROG Xbox" Cyan
        Say "  Ally X / X20, FSR 4 needs ASUS's FSR 4 GPU driver. After one launch, run this" Cyan
        Say "  again: the status lines show whether FSR 4 came up." Cyan
    }
}

# ------------------------------------------------------------------- remove --
elseif ($choice -eq '2') {
    Say ""
    if (-not (Test-Path -LiteralPath $manifest)) {
        Say "  Nothing to remove: no $MANIFEST in the game folder." Yellow
        ApplyLaunchArg $steam $false
        return
    }
    $files = @(Get-Content -LiteralPath $manifest | Where-Object { $_ -and $_ -notmatch '^#' })
    # Keep shared loaders when something else still uses them.
    $keep = @()
    $ueMods = Join-Path $win64 'ue4ss\Mods'
    if (Test-Path -LiteralPath $ueMods) {
        $others = @(Get-ChildItem -LiteralPath $ueMods -Directory | Where-Object { $_.Name -notin @('AntiAliasingOptions', 'shared') })
        if ($others.Count -gt 0) {
            $keep += @('FFRS\Binaries\Win64\dwmapi.dll', 'FFRS\Binaries\Win64\ue4ss\UE4SS.dll', 'FFRS\Binaries\Win64\ue4ss\UE4SS-settings.ini',
                       'FFRS\Binaries\Win64\ue4ss\LICENSE', 'FFRS\Binaries\Win64\ue4ss\Mods\mods.txt', 'FFRS\Binaries\Win64\ue4ss\Mods\shared\UEHelpers\UEHelpers.lua')
            Say "  UE4SS left in place: other UE4SS mods still use it ($(($others | ForEach-Object { $_.Name }) -join ', '))." Yellow
        }
    }
    $removed = 0
    try {
        foreach ($rel in $files) {
            if ($keep -contains $rel) { continue }
            $p = Join-Path $gameRoot $rel
            if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Force; $removed++ }
        }
        # what ReShade, Luma and UE4SS write at runtime
        foreach ($rel in @('ReShade.log', 'ReShade.log1', 'ReShadePreset.ini', 'ue4ss\UE4SS.log')) {
            $p = Join-Path $win64 $rel
            if ((Test-Path -LiteralPath $p) -and -not ($rel -eq 'ue4ss\UE4SS.log' -and $keep.Count -gt 0)) { Remove-Item -LiteralPath $p -Force; $removed++ }
        }
        $lumaDir = Join-Path $win64 'Luma'
        if (Test-Path -LiteralPath $lumaDir) { Remove-Item -LiteralPath $lumaDir -Recurse -Force }   # shaders + compiled cache
        # prune folders this script created, deepest first, if now empty
        $dirs = @($files | ForEach-Object { $d = Split-Path -Parent $_; while ($d -and $d -notin @('FFRS\Binaries\Win64', 'FFRS\Binaries', 'FFRS', 'FFRS\Content', 'FFRS\Content\Paks')) { $d; $d = Split-Path -Parent $d } } | Select-Object -Unique | Sort-Object { $_.Length } -Descending)
        foreach ($d in $dirs) {
            $p = Join-Path $gameRoot $d
            if ((Test-Path -LiteralPath $p) -and -not (Get-ChildItem -LiteralPath $p -Force | Select-Object -First 1)) { Remove-Item -LiteralPath $p -Force }
        }
        Remove-Item -LiteralPath $manifest -Force
    } catch {
        Say "  Could not delete from the game folder: $($_.Exception.Message)" Red
        Say "  Right-click this file and pick 'Run as administrator'." Yellow
        return
    }
    Say "  Removed $removed files (and Luma's shader folder)." Green
    Say ""
    ApplyLaunchArg $steam $false
    Say ""
    Say "  The game is back to its own anti-aliasing. If you picked TAA, set AA Method" Gray
    Say "  again in game (without the mod the menu shows the game's own choices)." Gray
}

else { Say ""; Say "  Nothing changed." DarkGray }
