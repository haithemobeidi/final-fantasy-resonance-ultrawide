# final-fantasy-resonance-ultrawide — Handoff Log

Append-only. Newest at the bottom. One entry per session.

**Only the newest entry (per track) is ever injected at session start**, which is why
there is no length cap: it is read once, by the session that needs it, and then it is
history. Older entries stay here forever at zero cost. Never edit a past entry.

## Why this shape

It is [I-PASS](https://doi.org/10.1056/NEJMsa1405556), the handoff bundle from the
multicenter trial that cut medical errors 23% and preventable adverse events 30%
across 10,740 admissions — **with no increase in handoff duration**. Its five
elements were chosen because pilot observers found those were the ones most often
missing from real handoffs: illness severity, contingency planning, and receiver
read-back.

The two that a software handoff usually lacks are the last two: **If it fails** and
**Confirm**. A next session that only knows the happy path stalls the moment it
doesn't happen.

Keep it to the delta. A 2026 meta-analysis of 1,590 handovers found errors in ~88%,
with omission the most common — and named *excessive non-essential information* among
the leading contributing factors. Long narrative causes the loss it looks like it
prevents. Do not re-summarize the project; the reader has `CURRENT_STATE.md`.

---

## Format

```
## YYYY-MM-DD HH:MM | <track> | <Phase/Block or area>
**Status:** green | yellow | red — <what was verified, on what, when>
**Changed:** <the delta this session, short>
**Next:** <the first move, with enough context to make it>
**If it fails:** <the contingency — what to try, or what it would mean>
**Confirm:** <the one thing the next session must restate before starting>
```

- **Status** is one word first, so the receiver knows the severity before the detail.
- **Changed** is the delta only. Not the project, not last week.
- **Next** must be actionable without reading anything else. Cite ledger IDs — the
  start hook expands the ones `CURRENT_STATE`'s NEXT ACTION names.
- **If it fails** is the element most often missing and the cheapest to write.
- **Confirm** is the read-back: what the next session states back before starting.
  If it cannot be stated from this entry, the entry is not finished.

Single-track repos drop the `<track>` field. A post-`/end` mini-wrap appends an entry
covering **only** the delta since the previous one.

---

<!-- Entries appended by /end. Never edit past entries. -->

## 2026-10-23 01:32 | Phase 3 Announce
**Status:** green — check_command (tools/check-bat.ps1) passes under Windows PowerShell 5.1 and pwsh 7; secret scan clean; the nine-run install/remove/repair/refuse matrix passed on a scratch exe folder on 2026-10-23; the live install was user-confirmed at 3440x1440 the same day.
**Changed:** Repo created and published at github.com/haithemobeidi/final-fantasy-resonance-ultrawide (a24272d: the .bat, README with the manual route and the offset evidence, MIT). Then bootstrapped with claude-project-template straight onto protocol v2: CLAUDE.md, ROADMAP spine (phases 1 and 2 DONE, 3 CURRENT), DECISIONS with five entries (download-and-patch, refuse on unknown build, HUD forced off, .NET instead of Get-FileHash/Expand-Archive, v2 bootstrap), full codebase index, ledger L-1 and L-2, tools/check-bat.ps1 as check_command, hook verified by synthetic Write and Bash events. Knowledge Base: two lessons committed and pushed (ec2e57e). STEAM_POST.txt drafted (gitignored).
**Next:** L-2. The user pastes STEAM_POST.txt on the Steam forum and leaves a short comment on PolarWizard issue #1 linking the repo. A session's only part afterwards is adding the Steam thread link to README. Nothing else until L-1 triggers.
**If it fails:** A Steam reader reports a launch crash: ask for their exe's PE timestamp or Steam buildid first. A game update (L-1) means new installs are refused by design while existing installs crash until winmm.dll is removed; re-verify both offsets (README, "What it does and why") before changing a constant. The .bat refuses a build it should accept: run tools/check-bat.ps1, then compare BUILD_STAMP and BUILD_SIG in the constants block against the exe bytes before touching anything else.
**Confirm:** The installer is pinned to the retail Steam build of 2026-10-22 (PE 0x6A586B2F, buildid 24250053) and refuses every other exe; [hud] enable stays forced to false because of the upstream use-after-free, not because of the offsets.
