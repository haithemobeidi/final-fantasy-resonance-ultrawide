# final-fantasy-resonance-ultrawide — Roadmap

Single track. The spine below is the source of truth for phase status; `docs/CURRENT_STATE.md` cites it, `docs/HANDOFF_LOG.md` carries the history.

## Status at a glance

| Phase | Status | Gate / pointer |
|---|---|---|
| 1. Fix works on the retail build | DONE 2026-10-23 | User-confirmed at 3440x1440: gameplay, menus, battles full width; movies 16:9 by design |
| 2. Distributable installer + README | DONE 2026-10-23 | Nine-run matrix passed on a scratch exe folder; repo public on GitHub |
| 3. Announce | CURRENT | Steam post + comment on PolarWizard issue #1, both the user's to send (L-2) |
| 4. Track upstream and game updates | PENDING | A game update or a PolarWizard retail release invalidates the constants (L-1) |

## Phases

1. **Fix works** — find a working ultrawide approach, repair PolarWizard 0.2.0 for retail, hand-install, user test.
2. **Installer** — the `.bat` (download, verify, patch, verify, install, remove), README with the manual route and the evidence, MIT license.
3. **Announce** — Steam forum post (`STEAM_POST.txt`), a pointer on upstream issue #1.
4. **Maintain** — when the exe or the upstream release changes, re-verify and either update the constants or retire the patch step.
