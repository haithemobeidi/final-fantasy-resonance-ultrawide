# final-fantasy-resonance-ultrawide — Current State

**Current phase:** Phase 5 Luma upscaler setup — pause A passed on the PC, Ally X20 run pending
**Build status:** working — check_command passes on both .bat files; ultrawide installer unchanged since 2026-10-23; FFRS_Luma_Upscaler.bat passed its scratch matrix on the RTX 5090 PC 2026-11-08 (not yet run on AMD hardware)

_Last updated: 2026-11-08 02:15_

> This file is the state of the PRODUCT, not the state of the session. Session narrative goes in `docs/HANDOFF_LOG.md`; ledger status is cited by ID, never restated; the phase list is the spine in `ROADMAP.md`. Overwrite at `/end` after re-reading from disk; never append.

---

## 📍 NEXT ACTION

The user runs `FFRS_Luma_Upscaler.bat` on the ROG Xbox Ally X20 (with ASUS's FSR 4 preview GPU driver installed), launches the game once, sets AA Method to TAA, then runs the .bat again and reports its status lines; that run decides whether README advertises the script (L-3). Still open in parallel, both the user's: the announcement (L-2) and the game-update watch (L-1).

## Shipped

| Track | Version | Where | Notes |
|---|---|---|---|
| ultrawide installer | 1.0 | public, https://github.com/haithemobeidi/final-fantasy-resonance-ultrawide | Targets PolarWizard 0.2.0 on the retail Steam build of 2026-10-22 (buildid 24250053, PE stamp 0x6A586B2F). Refuses any other build |
| Luma upscaler setup | 0.1 | in the public repo, not in README | `FFRS_Luma_Upscaler.bat`: Luma UE build 801 + Anti-Aliasing Options 1.0.1 Standalone + Steam `-dx11` + DLSS preset K. Same build pin. README section waits for the Ally run (L-3) |

## Build status

Working. `tools/check-bat.ps1` (now checks every root `.bat`) passes under Windows PowerShell 5.1 and pwsh 7. The Luma script passed, on a scratch copy of the game folder and copies of Steam's localconfig.vdf: fresh install with download, re-install no-op, zips next to the .bat, foreign dxgi.dll refusal, other-build refusal, remove, remove with another UE4SS mod present, VDF with no app block, VDF with an existing launch option; plus a read-only status run on the live install found through Steam. Never run on AMD hardware: FSR 4 on the Ally is unverified.

The live install on this machine: ultrawide fix (hand-patched plugin 5909f649…, `[hud] enable = false`) + Luma + AA menu mod, Steam launch option `-dx11`, DLSS preset K, in-game AA Method TAA, frame cap 120. User-confirmed working 2026-11-08 (DX11, full width, Luma replaced TAA per ReShade.log). Added files listed in `Win64\_ffrs_luma_installed_files.txt`. Steam config backup from the manual edit: `userdata\84600902\config\localconfig.vdf.bak-2026-11-08-before-dx11`.

## Active blockers

None.

## Open loops

open: L-1, L-2, L-3, L-4, L-5 — see `docs/SESSION_LEDGER.md`
