# final-fantasy-resonance-ultrawide — Project file

> One `.bat` that makes PolarWizard's ultrawide fix run on the retail Steam build of FINAL FANTASY RESONANCE.

**This file augments the global rules** (work style + session protocol, auto-loaded from the Knowledge Base on every machine). It holds ONLY what is different about this project. Before adding a line: does it contradict a global rule (then it goes in *Overrides*), is it actionable (trigger and action), is it specific to this project (else it belongs in the Knowledge Base)?

Everything the scripts need lives in `.claude/protocol.json`, not here.

---

## What this is

A distributable installer for other players. FINAL FANTASY RESONANCE (Unreal Engine 5, Steam appid 3259780) pillarboxes everything wider than 16:9. PolarWizard's open-source `final-fantasy-resonance-fix` removes the bars, but its 0.2.0 release was built against the demo and crashes the retail game at launch because five addresses baked into the plugin moved. This repo ships a `.bat` that downloads PolarWizard's official zip, verifies it, rewrites those five addresses, verifies the result, and installs it next to the game exe. No binaries are redistributed. `ROADMAP.md` holds the spine, `DECISIONS.md` the reasons.

## Locked stack

| Area | Choice |
|---|---|
| Installer | A single Windows `.bat` whose PowerShell body follows the `#===BEGIN-POWERSHELL===` marker; the batch half reads itself and runs the body with `Invoke-Expression` |
| PowerShell target | Windows PowerShell 5.1 (`powershell.exe`), which every Windows 10/11 has. pwsh 7 must also work, but 5.1 is the floor |
| Hashing and zip | .NET directly: `SHA256.ComputeHash(stream)`, `ZipFile.ExtractToDirectory`. Never `Get-FileHash` or `Expand-Archive` (script-module functions that fail to resolve on the `Invoke-Expression` path) |
| Game discovery | `FFRS_GAME_DIR` env override, then the `.bat`'s own folder, then Steam's `HKCU:\Software\Valve\Steam` + `libraryfolders.vdf` |
| Upstream payload | PolarWizard release zip 0.2.0, downloaded at install time with its SHA-256 pinned in the constants block |
| Verification tooling | Python one-offs (signature scan, RIP-relative reference count) in the session scratchpad; not part of the repo |
| Repo shape | Flat folder, no build step. `check_command` is `tools/check-bat.ps1` |

**Stack-specific quality rules** (the global ones always apply):
- The `.bat` stays CRLF (`.gitattributes` enforces it) and 7-bit ASCII. `tools/check-bat.ps1` fails the wrap otherwise.
- The embedded PowerShell must parse under 5.1: no `??`, no ternary, no `?.`, no `-File`-only tricks.
- Paths cross from batch to PowerShell through environment variables only. Never interpolate a path into the `-Command` string (apostrophes in folder names break it).
- Every constant a game update can move (hashes, offsets, PE timestamp, signature bytes) lives in the constants block at the top of the PowerShell body, nowhere else.

## Where the code is

| Path | What it is | Status |
|---|---|---|
| `FFRS_Ultrawide_Fix.bat` | The whole product: status, install/repair, remove | active |
| `tools/check-bat.ps1` | `check_command`: CRLF, ASCII, marker count, embedded PowerShell parses | active |
| `README.md` | Install guide, manual hex-editor route, the offset evidence table, credits | active |
| `STEAM_POST.txt` | Steam BBCode announcement draft. Gitignored, local only | local |

## How to run and test

The user launches the real game; Claude never installs into the live game folder during a test.

```
powershell -NoProfile -ExecutionPolicy Bypass -File tools/check-bat.ps1        # check_command
set FFRS_GAME_DIR=<scratch copy of FFRS\Binaries\Win64>  then  FFRS_Ultrawide_Fix.bat 1   # install, non-interactive
FFRS_Ultrawide_Fix.bat 2                                                      # remove
FFRS_Ultrawide_Fix.bat 3                                                      # status only
```

Scratch copy: a folder holding only `FFRS-Win64-Shipping.exe` (495 MB) copied from the live install. The nine-run matrix that has to pass before a release: stock → install (download) → install again (no-op) → remove; demo plugin with `[hud] enable = true` → install (backup written, patched, flag forced off); corrupted plugin → install repairs with backup; other build (patched PE timestamp) → refuse; zip next to the `.bat` → used instead of downloading; status run with no `FFRS_GAME_DIR` → finds the live install through Steam and reports it.

## Project rules

- **When the game's exe changes** (new PE `TimeDateStamp`) → do not loosen `CheckBuild`. Re-verify both offsets first: `AppendString` by a single signature hit at the claimed RVA, `GObjects` by RIP-relative reference count (retail scored 1,070 vs 0 for the demo address). Then update the constants block and the README table together.
- **When PolarWizard ships a retail-built release** → prefer retiring the byte patch: the installer downloads the new zip, pins its hash, and writes it unpatched. Keep the refusal logic.
- **`[hud] enable` stays forced to `false`** until upstream fixes the render-target use-after-free in the encounter path (crash on the second battle). The imm32 patch does not fix that.
- **Never commit binaries.** `.gitignore` blocks `*.dll`, `*.asi`, `*.zip`, `*.bak`. The repo holds the `.bat`, the README and the license; the installer fetches and verifies the rest.
- **When editing user-facing copy** (README, Steam post, `.bat` console output) → no em-dashes, plain ASCII in the `.bat`, and name PolarWizard and Darjjj wherever the fix is described.
- **A refusal stays a refusal.** Unknown build, foreign `winmm.dll`, hash mismatch, wrong patch counts: the script stops without writing. Do not add "continue anyway" prompts.

## Overrides of global rules

None.

## Where things live

| Thing | Where |
|---|---|
| Live install (this machine) | `F:\SteamLibrary\steamapps\common\FINAL FANTASY RESONANCE\FFRS\Binaries\Win64` |
| Published repo | https://github.com/haithemobeidi/final-fantasy-resonance-ultrawide |
| Upstream fix and the retail-crash thread | https://github.com/PolarWizard/final-fantasy-resonance-fix (issue #1) |
| Prior art, same `.bat` shape | `../castlevania-belmonts-curse-ultrawide` |
| Knowledge Base lessons from this work | `demo-built-mod-on-a-retail-game-fixed-offsets-crash.md`, `unreal-ultrawide-two-layers-and-steam-delivery.md` |

## Navigation docs — read on demand, never auto-load

| Doc | Read when |
|---|---|
| `docs/CODEBASE_INDEX.md` — one line per file | Locating something. |
| `README.md` — the offset evidence | Before touching any constant in the `.bat`. |

## Subagents — read-only by design

`.claude/agents/` ships `planner`, `reviewer`, `explorer`. All read-only; the main session makes every edit.
