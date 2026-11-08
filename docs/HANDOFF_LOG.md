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

## 2026-11-08 02:15 | Phase 5 Luma upscaler setup
**Status:** green on the PC, untested on AMD — check_command passes on both .bat files (Windows PowerShell 5.1 and pwsh 7); secret scan clean; FFRS_Luma_Upscaler.bat passed its scratch matrix and a read-only live status run on the RTX 5090 PC 2026-11-08; the user confirmed the hand install in game (DX11, full width, Luma on TAA, preset K, 120 fps cap).
**Changed:** Out-of-band request: DLSS injection via Luma. Hand-installed on the live game: Luma for Unreal Engine build 801 (ReShade 6.8 dxgi.dll, NVIDIA-signed nvngx_dlss 310.9.16) + jmroon's Anti-Aliasing Options 1.0.1 Menu (UE4SS dwmapi.dll, byte-identical to official UE4SS v3.0.1-1181) + Steam launch option -dx11 (localconfig.vdf edited with Steam closed, backed up). Preset L measured 100% GPU / ~580 W / 83 C; K measured 69% / ~410 W / 72 C, same look, so K stays. Then built FFRS_Luma_Upscaler.bat (new; committed and pushed at the user's choice so the Ally can download it, not in README) to repeat that on another machine incl. the ROG Xbox Ally X20 (FSR 4 via Luma's DX12 interop); tools/check-bat.ps1 now checks every root .bat. Spine gained phase 5; phase 3 marked WAITING ON USER. CLAUDE.md gained an override: no 500-line target for these single-file .bat tools (user ruling). Ledger: L-1 note extended (three hooks on the live install now), L-3 Ally run, L-4 and L-5 kbdoc lines. Two .claude/scripts files were already dirty at session start (an uncommitted template resync; check-template-drift says up to date).
**Next:** L-3. The user downloads FFRS_Luma_Upscaler.bat from the GitHub repo on the Ally X20, installs ASUS's FSR 4 preview GPU driver, runs [1], launches the game once, sets AA Method to TAA, quits, runs the .bat again and reads the "Last launch" lines. A session then adds a README section if the user wants it advertised.
**If it fails:** "Luma did not load" = the game did not start in DX11: check Steam > Properties > Launch Options shows -dx11 (Ally Steam may run under a different account than the one the script picked; it uses ActiveUser, then loginusers.vdf MostRecent). "No FSR 4 upscaler available on this GPU" = the driver does not expose FSR 4 to Luma's 4.1.2 SDK DLL: Auto falls back to XeSS or FSR 3, still a valid result to report. A refusal naming dxgi.dll or dwmapi.dll = another ReShade/UE4SS install on that machine: remove it first, never overwrite. A crash at launch: run [2] to remove, then report the Windows Application event log entry for FFRS-Win64-Shipping.exe.
**Confirm:** The Luma script is public in the repo but unadvertised (no README section) until the Ally run passes. Luma's UE mod runs at native resolution only, so on the Ally it trades frame rate for image quality.
