# final-fantasy-resonance-ultrawide — Current State

**Current phase:** Phase 3 Announce — installer published, Steam post not yet made
**Build status:** working — check_command passes; nine-run matrix passed on a scratch exe folder 2026-10-23; live install user-confirmed at 3440x1440 on 2026-10-23

_Last updated: 2026-10-23 01:30_

> This file is the state of the PRODUCT, not the state of the session. Session narrative goes in `docs/HANDOFF_LOG.md`; ledger status is cited by ID, never restated; the phase list is the spine in `ROADMAP.md`. Overwrite at `/end` after re-reading from disk; never append.

---

## 📍 NEXT ACTION

Send the announcement: paste `STEAM_POST.txt` on the Steam forum and leave a pointer on PolarWizard issue #1 (L-2). Then nothing until the exe or the upstream release changes (L-1).

## Shipped

| Track | Version | Where | Notes |
|---|---|---|---|
| installer | 1.0 | public, https://github.com/haithemobeidi/final-fantasy-resonance-ultrawide | Targets PolarWizard 0.2.0 on the retail Steam build of 2026-10-22 (buildid 24250053, PE stamp 0x6A586B2F). Refuses any other build |

## Build status

Working. `tools/check-bat.ps1` passes under Windows PowerShell 5.1 and pwsh 7. The nine-run install/remove/repair/refuse matrix passed on 2026-10-23 against a scratch copy of the exe folder, never the live install. The live install on this machine runs the hand-patched plugin (sha256 5909f649…) with `[movies] enable = true`, `[hud] enable = false`, confirmed by the user.

## Active blockers

None.

## Open loops

open: L-1, L-2 — see `docs/SESSION_LEDGER.md`
