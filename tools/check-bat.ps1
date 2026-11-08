# check_command for this repo. The .bat IS the product, so "does it build" means:
#   1. every line ending is CRLF (cmd misparses LF-only batch files around labels and parentheses),
#   2. the file is pure ASCII (cmd prints anything else wrong under the OEM code page),
#   3. the PowerShell marker appears exactly once,
#   4. the embedded PowerShell parses under the host that runs it.
# Exit 0 = fine, exit 1 = stop the wrap. Runs on Windows PowerShell 5.1 and pwsh 7.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$bats = @(Get-ChildItem -LiteralPath $root -Filter '*.bat' -File)
if ($bats.Count -eq 0) { Write-Host "check: no .bat files in $root"; exit 1 }
$failed = $false
$marker = '#===BEGIN-POWERSHELL==='

foreach ($f in $bats) {
    $name = $f.Name
    $bytes = [IO.File]::ReadAllBytes($f.FullName)
    $text = [Text.Encoding]::GetEncoding(28591).GetString($bytes)
    $bad = $false

    $lfOnly = [regex]::Matches($text, "(?<!`r)`n").Count
    if ($lfOnly -gt 0) { Write-Host "check: ${name}: $lfOnly LF-only line ending(s); the .bat must be CRLF (see .gitattributes)"; $bad = $true }

    $nonAscii = @($bytes | Where-Object { $_ -gt 127 }).Count
    if ($nonAscii -gt 0) { Write-Host "check: ${name}: $nonAscii non-ASCII byte(s); keep it 7-bit so cmd prints it correctly"; $bad = $true }

    $hits = [regex]::Matches($text, [regex]::Escape($marker)).Count
    if ($hits -ne 1) { Write-Host "check: ${name}: marker '$marker' found $hits time(s), expected exactly 1"; $bad = $true }

    if ($hits -ge 1) {
        $ps = $text.Substring($text.IndexOf($marker) + $marker.Length)
        $tokens = $null; $errors = $null
        [System.Management.Automation.Language.Parser]::ParseInput($ps, [ref]$tokens, [ref]$errors) | Out-Null
        if ($errors -and $errors.Count -gt 0) {
            foreach ($e in $errors) { Write-Host ("check: {0}: PowerShell parse error (embedded line {1}): {2}" -f $name, $e.Extent.StartLineNumber, $e.Message) }
            $bad = $true
        }
    }
    if ($bad) { $failed = $true }
    else { Write-Host ("check: {0} OK ({1} bytes, CRLF, ASCII, embedded PowerShell parses under {2})" -f $name, $bytes.Length, $PSVersionTable.PSVersion) }
}

if ($failed) { exit 1 }
exit 0
