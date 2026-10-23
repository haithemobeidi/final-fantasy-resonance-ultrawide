@echo off
REM ===========================================================================
REM  FINAL FANTASY RESONANCE  --  Ultrawide Fix for the retail Steam build
REM  https://github.com/haithemobeidi/final-fantasy-resonance-ultrawide
REM
REM  The game is Unreal Engine 5 and pillarboxes everything wider than 16:9.
REM  PolarWizard's open-source fix removes the bars and keeps pre-rendered
REM  movies at 16:9 (github.com/PolarWizard/final-fantasy-resonance-fix, MIT),
REM  but its 0.2.0 release was built against the DEMO. Five addresses inside
REM  its plugin point at where the demo exe kept two engine tables; on the
REM  retail exe they land in the middle of unrelated code and the game crashes
REM  at launch (Windows error log: fault offset 0x1376360).
REM
REM  This script:
REM  - downloads the official 0.2.0 zip from GitHub and checks its SHA-256
REM    (or uses a copy of that zip placed next to this file)
REM  - checks the game exe is the retail build the new addresses were read
REM    from (PE timestamp 0x6A586B2F) and refuses on any other build
REM  - rewrites the five addresses inside the plugin (4x GObjects,
REM    1x AppendString) and refuses unless it finds exactly those five
REM  - installs the loader (winmm.dll = ThirteenAG's Ultimate ASI Loader) and
REM    the patched plugin + config into FFRS\Binaries\Win64
REM  - keeps the plugin's HUD option off: that code path has a separate bug
REM    on retail (crash on the second battle transition). On a 21:9 screen
REM    the HUD already spans the full width without it.
REM  - has a Remove option that deletes exactly what it added
REM
REM  No game file is modified. Steam's "Verify integrity of game files"
REM  leaves added files alone. A game update moves the addresses, and the
REM  script will then refuse rather than guess.
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
try { $Host.UI.RawUI.WindowTitle = 'FINAL FANTASY RESONANCE - Ultrawide Fix (retail build)' } catch {}

function Say($msg, $col = 'Gray') { Write-Host $msg -ForegroundColor $col }

Say ""
Say "  ==========================================================" Cyan
Say "   FINAL FANTASY RESONANCE  -  Ultrawide Fix (retail build)" Cyan
Say "  ==========================================================" Cyan
Say ""

# ---------------------------------------------------------------- constants --
$GAME_FOLDER    = 'FINAL FANTASY RESONANCE'
$EXE_NAME       = 'FFRS-Win64-Shipping.exe'
$PLUGIN         = 'final_fantasy_resonance_fix'
$ZIP_NAME       = 'final-fantasy-resonance-fix_0.2.0.zip'
$ZIP_URL        = "https://github.com/PolarWizard/final-fantasy-resonance-fix/releases/download/0.2.0/$ZIP_NAME"
$ZIP_SHA        = 'E0228B176661523B2E6442805B478BC6B2CB89553F867DBA9C09C86ED314D0A9'
$ASI_SHA_DEMO   = '031260A889F4011764A269E0BC53FDE553BDDFF0A305FF0F614C4E665DF852A5'
$ASI_SHA_RETAIL = '5909F6498E23BED0C0B91E054B04B02EA784EA7F07140C1F9A20B43BC7B4A28E'
$LOADER_SHA     = 'FA266E3513D02C08A1B808F28C10538A489EAFFAA4B0707F7CC1066E71B5AFD7'

# Retail Steam build of 2026-10-22 (Steam buildid 24250053): the exe's PE
# TimeDateStamp, and the first 17 bytes of FName::AppendString, which sits at
# file offset 0x13757A0 (RVA 0x13763A0) in that build. Both must match.
$BUILD_STAMP    = [uint32]0x6A586B2F
$BUILD_SIG_OFF  = 0x13757A0
$BUILD_SIG      = '48 89 5C 24 10 48 89 74 24 18 57 48 83 EC 20 80 3D'

# The five 32-bit immediates inside the plugin (exe-relative offsets, little-endian).
# Demo values from the plugin as shipped; retail values from GitHub issue #1 on
# PolarWizard's repo, re-verified against the retail exe (AppendString by its
# signature, GObjects by its 1070 code references vs 0 for the demo address).
$DEMO_GOBJ   = '50 6D D7 09'; $RETAIL_GOBJ = 'D0 4D D8 09'   # GObjects     0x09D76D50 -> 0x09D84DD0  (x4)
$DEMO_APPS   = '60 63 37 01'; $RETAIL_APPS = 'A0 63 37 01'   # AppendString 0x01376360 -> 0x013763A0  (x1)

# ------------------------------------------------------------------ helpers --
# latin-1 maps bytes 0-255 to chars 0-255 one-to-one, so string IndexOf is a byte search
$latin1 = [System.Text.Encoding]::GetEncoding(28591)
function HexToBytes([string]$h) {
    $h = $h -replace '\s', ''
    $out = New-Object byte[] ($h.Length / 2)
    for ($i = 0; $i -lt $out.Length; $i++) { $out[$i] = [Convert]::ToByte($h.Substring($i * 2, 2), 16) }
    return ,$out
}
function FindAll([string]$hay, [string]$hex) {
    $needle = $latin1.GetString((HexToBytes $hex))
    $hits = @(); $i = -1
    while (($i = $hay.IndexOf($needle, $i + 1, [StringComparison]::Ordinal)) -ge 0) { $hits += $i }
    return ,$hits
}
function Sha256Bytes([byte[]]$b) {
    $h = [System.Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($h.ComputeHash($b)) -replace '-', '') } finally { $h.Dispose() }
}
function Sha256File([string]$p) {
    # .NET directly: Get-FileHash is a script-module function in Windows PowerShell and
    # does not resolve when module auto-loading is unavailable (seen when launched from pwsh 7).
    $fs = [System.IO.File]::OpenRead($p)
    try { $h = [System.Security.Cryptography.SHA256]::Create(); try { return ([BitConverter]::ToString($h.ComputeHash($fs)) -replace '-', '') } finally { $h.Dispose() } }
    finally { $fs.Close() }
}

function ClassifyAsi([byte[]]$b) {
    $hay = $latin1.GetString($b)
    $dg = (FindAll $hay $DEMO_GOBJ).Count;   $da = (FindAll $hay $DEMO_APPS).Count
    $rg = (FindAll $hay $RETAIL_GOBJ).Count; $ra = (FindAll $hay $RETAIL_APPS).Count
    if ($dg -eq 4 -and $da -eq 1 -and $rg -eq 0 -and $ra -eq 0) { return 'DEMO' }
    if ($dg -eq 0 -and $da -eq 0 -and $rg -eq 4 -and $ra -eq 1) { return 'RETAIL' }
    return 'UNKNOWN'
}
function ReplaceAll([byte[]]$b, [string]$hay, [string]$oldHex, [string]$newHex) {
    $new = HexToBytes $newHex
    foreach ($o in (FindAll $hay $oldHex)) { [Array]::Copy($new, 0, $b, $o, $new.Length) }
}
function PatchAsi([byte[]]$b) {
    $hay = $latin1.GetString($b)
    ReplaceAll $b $hay $DEMO_GOBJ $RETAIL_GOBJ
    ReplaceAll $b $hay $DEMO_APPS $RETAIL_APPS
}

function CheckBuild([string]$exePath) {
    $fs = [System.IO.File]::Open($exePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try {
        $hdr = New-Object byte[] 4096
        [void]$fs.Read($hdr, 0, 4096)
        if ($hdr[0] -ne 0x4D -or $hdr[1] -ne 0x5A) { return 'NOT-AN-EXE' }
        $peOff = [BitConverter]::ToInt32($hdr, 0x3C)
        if ($peOff -lt 0 -or $peOff -gt 4000) { return 'NOT-AN-EXE' }
        $stamp = [BitConverter]::ToUInt32($hdr, $peOff + 8)
        if ($fs.Length -le ($BUILD_SIG_OFF + 32)) { return 'OTHER-BUILD' }
        [void]$fs.Seek($BUILD_SIG_OFF, [System.IO.SeekOrigin]::Begin)
        $probe = New-Object byte[] 17
        [void]$fs.Read($probe, 0, 17)
        $sig = ([BitConverter]::ToString($probe) -replace '-', ' ')
        if ($stamp -eq $BUILD_STAMP -and $sig -eq $BUILD_SIG) { return 'RETAIL' }
        return 'OTHER-BUILD'
    } finally { $fs.Close() }
}

# TOML: the [hud] section only. Everything else in the user's config is left alone.
function HudSection([string]$t) {
    $m = [regex]::Match($t, '(?ms)^\[hud\][^\r\n]*\r?\n(.*?)(?=^\[|\z)')
    if ($m.Success) { return $m } else { return $null }
}
function HudEnabled([string]$t) {
    $m = HudSection $t
    return ($m -ne $null -and $m.Groups[1].Value -match '(?m)^\s*enable\s*=\s*true')
}
function DisableHud([string]$t) {
    $m = HudSection $t
    if ($m -eq $null) { return $t }
    $fixed = [regex]::Replace($m.Groups[1].Value, '(?m)^(\s*enable\s*=\s*)true', '${1}false')
    return $t.Substring(0, $m.Groups[1].Index) + $fixed + $t.Substring($m.Groups[1].Index + $m.Groups[1].Length)
}

# ---------------------------------------------------------------- find game --
# 1) FFRS_GAME_DIR (an explicit Win64 folder)  2) next to this .bat, or this .bat
# in the game's root folder  3) any Steam library listed in libraryfolders.vdf
$win64 = $null
if ($env:FFRS_GAME_DIR -and (Test-Path -LiteralPath (Join-Path $env:FFRS_GAME_DIR $EXE_NAME))) { $win64 = $env:FFRS_GAME_DIR }
if (-not $win64 -and $env:FFRS_DIR) {
    $here = $env:FFRS_DIR.TrimEnd('\')
    foreach ($cand in @($here, (Join-Path $here 'FFRS\Binaries\Win64'))) {
        if (Test-Path -LiteralPath (Join-Path $cand $EXE_NAME)) { $win64 = $cand; break }
    }
}
if (-not $win64) {
    $steam = $null
    try { $steam = (Get-ItemProperty -Path 'HKCU:\Software\Valve\Steam' -Name SteamPath -ErrorAction Stop).SteamPath } catch {}
    if ($steam) {
        $libs = @($steam)
        $vdf = Join-Path $steam 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $vdf) {
            foreach ($m in [regex]::Matches((Get-Content -LiteralPath $vdf -Raw), '"path"\s+"([^"]+)"')) {
                $libs += $m.Groups[1].Value -replace '\\\\', '\'
            }
        }
        foreach ($lib in $libs) {
            $cand = Join-Path $lib "steamapps\common\$GAME_FOLDER\FFRS\Binaries\Win64"
            if (Test-Path -LiteralPath (Join-Path $cand $EXE_NAME)) { $win64 = $cand; break }
        }
    }
}
if (-not $win64) {
    Say "  Could not find the game. Put this .bat in the game folder (the one" Red
    Say "  with FFRS.exe; Steam: right-click the game > Manage > Browse local" Yellow
    Say "  files) and run it again." Yellow
    return
}
$exe = Join-Path $win64 $EXE_NAME
Say "  Game found:" Green
Say "    $win64"
Say ""

# ------------------------------------------------------------ running check --
if (Get-Process -Name 'FFRS-Win64-Shipping', 'FFRS' -ErrorAction SilentlyContinue) {
    Say "  The game is currently RUNNING. Close it first, then re-run this." Red
    return
}

# ------------------------------------------------------------------- status --
$build = CheckBuild $exe

$loaderPath = Join-Path $win64 'winmm.dll'
$scriptsDir = Join-Path $win64 'scripts'
$asiPath    = Join-Path $scriptsDir "$PLUGIN.asi"
$tomlPath   = Join-Path $scriptsDir "$PLUGIN.toml"
$bakPath    = Join-Path $scriptsDir "$PLUGIN.asi.bak"     # not .asi, so the loader ignores it
$extras     = @((Join-Path $scriptsDir "$PLUGIN.log"), (Join-Path $scriptsDir "${PLUGIN}_README.txt"), (Join-Path $scriptsDir "${PLUGIN}_LICENSES.txt"))

$loaderState = 'NONE'
if (Test-Path -LiteralPath $loaderPath) {
    $company = (Get-Item -LiteralPath $loaderPath).VersionInfo.CompanyName
    if ($company -eq 'ThirteenAG') { $loaderState = 'ASI-LOADER' } else { $loaderState = 'FOREIGN' }
}
$asiState = 'NONE'
if (Test-Path -LiteralPath $asiPath) { $asiState = ClassifyAsi ([System.IO.File]::ReadAllBytes($asiPath)) }
$hudOn = $false
if (Test-Path -LiteralPath $tomlPath) { $hudOn = HudEnabled (Get-Content -LiteralPath $tomlPath -Raw) }

switch ($build) {
    'RETAIL'      { Say "  Game build:   retail Steam build of 2026-10-22 (supported)" Green }
    'OTHER-BUILD' { Say "  Game build:   NOT the build this script knows (updated game?)" Red }
    default       { Say "  Game build:   $EXE_NAME is not a valid executable" Red }
}
switch ($loaderState) {
    'NONE'       { Say "  Loader:       not installed" Yellow }
    'ASI-LOADER' { Say "  Loader:       winmm.dll = Ultimate ASI Loader (ok)" Green }
    'FOREIGN'    { Say "  Loader:       winmm.dll present but it is NOT the Ultimate ASI Loader" Red }
}
switch ($asiState) {
    'NONE'    { Say "  Plugin:       not installed" Yellow }
    'DEMO'    { Say "  Plugin:       PolarWizard 0.2.0 as shipped (demo addresses - crashes retail)" Red }
    'RETAIL'  { Say "  Plugin:       PolarWizard 0.2.0 with retail addresses (ok)" Green }
    'UNKNOWN' { Say "  Plugin:       present but not a version this script recognises" Red }
}
if ($hudOn) { Say "  Config:       [hud] enable = true  <- crashes on retail; the installer turns it off" Red }

$applied = ($build -eq 'RETAIL' -and $loaderState -eq 'ASI-LOADER' -and $asiState -eq 'RETAIL' -and -not $hudOn)
Say ""
if ($applied) { Say "  Current status:  ULTRAWIDE FIX IS INSTALLED" Green }
elseif ($asiState -eq 'NONE' -and $loaderState -eq 'NONE') { Say "  Current status:  not installed (stock 16:9 pillarbox)" Yellow }
else { Say "  Current status:  partly installed or needs repair" Yellow }
Say ""
Say "  [1]  Install / repair the ultrawide fix"
Say "  [2]  Remove it (deletes only what this script added)"
Say "  [3]  Exit"
Say ""
$choice = $env:FFRS_ARG
if (-not $choice) { $choice = Read-Host "  Choose" }
switch -Regex ($choice) {
    '^(1|install|repair)$'        { $choice = '1' }
    '^(2|remove|undo|uninstall)$' { $choice = '2' }
    default                       { $choice = '3' }
}

# ------------------------------------------------------------------ install --
if ($choice -eq '1') {
    Say ""
    if ($build -ne 'RETAIL') {
        Say "  The game exe is not the retail build these addresses were taken from." Red
        Say "  Refusing to guess. Nothing was installed. If the game was updated," Yellow
        Say "  check https://github.com/PolarWizard/final-fantasy-resonance-fix/releases" Yellow
        Say "  for a newer release first." Yellow
        return
    }
    if ($loaderState -eq 'FOREIGN') {
        Say "  A different winmm.dll is already in the game folder (another mod?)." Red
        Say "  Refusing to overwrite it. Remove that mod first, or install this one by hand." Yellow
        return
    }
    if ($applied) { Say "  Already installed - nothing to do." Green; return }

    # -- get the official zip (a copy next to this .bat wins over a download)
    $zip = $null
    foreach ($d in @($env:FFRS_DIR, $win64)) {
        if ($d) { $p = Join-Path $d $ZIP_NAME; if (Test-Path -LiteralPath $p) { $zip = $p; break } }
    }
    $tmp = Join-Path $env:TEMP 'ffrs-ultrawide-fix'
    New-Item -ItemType Directory -Force -Path $tmp | Out-Null
    if (-not $zip) {
        $zip = Join-Path $tmp $ZIP_NAME
        if ((Test-Path -LiteralPath $zip) -and (Sha256File $zip) -ne $ZIP_SHA) { Remove-Item -LiteralPath $zip -Force }
        if (-not (Test-Path -LiteralPath $zip)) {
            Say "  Downloading PolarWizard's fix 0.2.0 from GitHub..." DarkGray
            try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}
            try { Invoke-WebRequest -Uri $ZIP_URL -OutFile $zip -UseBasicParsing }
            catch {
                Say "  Download failed: $($_.Exception.Message)" Red
                Say "  Download it yourself from the URL below and put the zip next to this .bat:" Yellow
                Say "    $ZIP_URL" Yellow
                return
            }
        }
    } else { Say "  Using the zip next to this script: $zip" DarkGray }
    $zipSha = Sha256File $zip
    if ($zipSha -ne $ZIP_SHA) {
        Say "  The zip's SHA-256 does not match the 0.2.0 release this script was written for." Red
        Say "    expected $ZIP_SHA" DarkGray
        Say "    got      $zipSha" DarkGray
        Say "  Nothing was installed." Yellow
        return
    }

    # -- extract and verify every file we are about to use
    $ext = Join-Path $tmp 'extract'
    if (Test-Path -LiteralPath $ext) { Remove-Item -LiteralPath $ext -Recurse -Force }
    # .NET directly for the same reason as Sha256File (Expand-Archive is a script module too)
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zip, $ext)
    $srcLoader = Join-Path $ext 'winmm.dll'
    $srcAsi    = Join-Path $ext "scripts\$PLUGIN.asi"
    $srcToml   = Join-Path $ext "scripts\$PLUGIN.toml"
    foreach ($f in @($srcLoader, $srcAsi, $srcToml)) {
        if (-not (Test-Path -LiteralPath $f)) { Say "  The zip does not contain $(Split-Path $f -Leaf). Nothing was installed." Red; return }
    }
    if ((Sha256File $srcLoader) -ne $LOADER_SHA) { Say "  winmm.dll in the zip is not the expected Ultimate ASI Loader build. Nothing was installed." Red; return }
    $asi = [System.IO.File]::ReadAllBytes($srcAsi)
    if ((Sha256Bytes $asi) -ne $ASI_SHA_DEMO -or (ClassifyAsi $asi) -ne 'DEMO') {
        Say "  The plugin in the zip is not the 0.2.0 build this script knows. Nothing was installed." Red; return
    }

    # -- the actual fix: five 4-byte immediates
    PatchAsi $asi
    if ((ClassifyAsi $asi) -ne 'RETAIL' -or (Sha256Bytes $asi) -ne $ASI_SHA_RETAIL) {
        Say "  Patching did not produce the expected result. Nothing was installed." Red; return
    }
    Say "  Plugin patched: 4x GObjects + 1x AppendString -> retail addresses (13 bytes)." DarkGray

    # -- write into the game folder
    try {
        New-Item -ItemType Directory -Force -Path $scriptsDir | Out-Null
        if ($asiState -ne 'NONE') {
            Copy-Item -LiteralPath $asiPath -Destination $bakPath -Force
            Say "  Previous plugin kept as $PLUGIN.asi.bak (the loader ignores it)." DarkGray
        }
        [System.IO.File]::WriteAllBytes($asiPath, $asi)
        if ($loaderState -eq 'NONE') { Copy-Item -LiteralPath $srcLoader -Destination $loaderPath -Force }
        if (-not (Test-Path -LiteralPath $tomlPath)) { Copy-Item -LiteralPath $srcToml -Destination $tomlPath -Force }
        Copy-Item -LiteralPath (Join-Path $ext 'README.txt') -Destination (Join-Path $scriptsDir "${PLUGIN}_README.txt") -Force
        Copy-Item -LiteralPath (Join-Path $ext 'LICENSES')   -Destination (Join-Path $scriptsDir "${PLUGIN}_LICENSES.txt") -Force
        $t = Get-Content -LiteralPath $tomlPath -Raw
        if (HudEnabled $t) {
            [System.IO.File]::WriteAllText($tomlPath, (DisableHud $t), (New-Object System.Text.UTF8Encoding $false))
            Say "  Config: [hud] enable set to false (that code path still crashes on retail)." Yellow
        }
    } catch {
        Say "  Could not write to the game folder: $($_.Exception.Message)" Red
        Say "  Right-click this file and pick 'Run as administrator'." Yellow
        return
    }
    Remove-Item -LiteralPath $ext -Recurse -Force -ErrorAction SilentlyContinue

    Say "  SUCCESS - ultrawide fix installed." Green
    Say ""
    Say "  Installed into $win64" Gray
    Say "    winmm.dll                          (Ultimate ASI Loader 9.7.4, ThirteenAG)" DarkGray
    Say "    scripts\$PLUGIN.asi   (PolarWizard 0.2.0, retail addresses)" DarkGray
    Say "    scripts\$PLUGIN.toml  (config; leave [hud] enable = false)" DarkGray
    Say ""
    Say "  In game: Options > Graphics > set your monitor's native resolution" Gray
    Say "  (borderless or fullscreen). Gameplay and menus fill the screen;" Gray
    Say "  pre-rendered movies stay 16:9 on purpose." Gray
    Say ""
    Say "  NOTE: a game update will move these addresses and the game would" Yellow
    Say "  crash at launch again. Run this file and choose [2] to remove the fix," Yellow
    Say "  then check PolarWizard's GitHub for a release built for the new version." Yellow
}

# ------------------------------------------------------------------- remove --
elseif ($choice -eq '2') {
    Say ""
    $removed = @()
    try {
        foreach ($f in (@($asiPath, $tomlPath, $bakPath) + $extras)) {
            if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force; $removed += (Split-Path $f -Leaf) }
        }
        $othersInScripts = $false
        if (Test-Path -LiteralPath $scriptsDir) {
            if (Get-ChildItem -LiteralPath $scriptsDir -Force | Select-Object -First 1) { $othersInScripts = $true }
            else { Remove-Item -LiteralPath $scriptsDir -Force; $removed += 'scripts\' }
        }
        if ($loaderState -eq 'ASI-LOADER') {
            if ($othersInScripts) { Say "  winmm.dll left in place: other .asi mods still use it." Yellow }
            else { Remove-Item -LiteralPath $loaderPath -Force; $removed += 'winmm.dll' }
        } elseif ($loaderState -eq 'FOREIGN') {
            Say "  winmm.dll left in place: it is not the Ultimate ASI Loader, so it belongs to something else." Yellow
        }
    } catch {
        Say "  Could not delete from the game folder: $($_.Exception.Message)" Red
        Say "  Right-click this file and pick 'Run as administrator'." Yellow
        return
    }
    if ($removed.Count -gt 0) {
        Say "  Removed: $($removed -join ', ')" Green
        Say "  The game is back to stock (16:9 pillarbox)." Green
    } else {
        Say "  Nothing to remove - the fix was not installed." Yellow
    }
}

else { Say ""; Say "  Nothing changed." DarkGray }
