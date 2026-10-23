# check_command for this repo. The .bat IS the product, so "does it build" means:
#   1. every line ending is CRLF (cmd misparses LF-only batch files around labels and parentheses),
#   2. the file is pure ASCII (cmd prints anything else wrong under the OEM code page),
#   3. the PowerShell marker appears exactly once,
#   4. the embedded PowerShell parses under the host that runs it.
# Exit 0 = fine, exit 1 = stop the wrap. Runs on Windows PowerShell 5.1 and pwsh 7.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$bat = Join-Path $root 'FFRS_Ultrawide_Fix.bat'
if (-not (Test-Path -LiteralPath $bat)) { Write-Host "check: $bat is missing"; exit 1 }

$bytes = [IO.File]::ReadAllBytes($bat)
$text = [Text.Encoding]::GetEncoding(28591).GetString($bytes)
$failed = $false

$lfOnly = [regex]::Matches($text, "(?<!`r)`n").Count
if ($lfOnly -gt 0) { Write-Host "check: $lfOnly LF-only line ending(s); the .bat must be CRLF (see .gitattributes)"; $failed = $true }

$nonAscii = @($bytes | Where-Object { $_ -gt 127 }).Count
if ($nonAscii -gt 0) { Write-Host "check: $nonAscii non-ASCII byte(s) in the .bat; keep it 7-bit so cmd prints it correctly"; $failed = $true }

$marker = '#===BEGIN-POWERSHELL==='
$hits = [regex]::Matches($text, [regex]::Escape($marker)).Count
if ($hits -ne 1) { Write-Host "check: marker '$marker' found $hits time(s), expected exactly 1"; $failed = $true }

if ($hits -ge 1) {
    $ps = $text.Substring($text.IndexOf($marker) + $marker.Length)
    $tokens = $null; $errors = $null
    [System.Management.Automation.Language.Parser]::ParseInput($ps, [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors -and $errors.Count -gt 0) {
        foreach ($e in $errors) { Write-Host ("check: PowerShell parse error (embedded line {0}): {1}" -f $e.Extent.StartLineNumber, $e.Message) }
        $failed = $true
    }
}

if ($failed) { exit 1 }
Write-Host ("check: OK ({0} bytes, CRLF, ASCII, embedded PowerShell parses under {1})" -f $bytes.Length, $PSVersionTable.PSVersion)
exit 0
