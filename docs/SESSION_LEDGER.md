# Session Ledger — open items that must not get lost

> **What this is:** the append-and-strike ledger for session-scoped open loops —
> queued tests, pre-release gates, riders, deferred decisions, watch items.
> Anything phrased like "next session," "before release," "rider," "queued," or
> "check later" gets a line HERE at the moment it's said.
>
> Not bugs (→ the bug doc), not features (→ the backlog), not status (→ the spine).
>
> **Rules** (rationale in the global `PROTOCOL.md`; design reasoning in the
> template's `DESIGN.md`):
>
> - **Append at the moment of queueing; strike at the moment of resolution.**
>   Never wait for `/end`. Long sessions get compacted, and compaction explicitly
>   drops intermediate reasoning — a minute-5 fact does not survive to an hour-4
>   wrap.
>
> - **THE FIRST LINE IS A SELF-CONTAINED TITLE.** This is the one authoring rule
>   that makes the rest work. Session start injects a MANIFEST — every open item's
>   first line, cut to ~110 characters — plus the full text of only the items the
>   NEXT ACTION cites. A future session decides whether to read an item from that
>   line alone, so it has to say what the loop IS. Lead with the headline; put the
>   analysis after.
>
> - **There is NO length cap on an item.** Items stay whole, here, forever. The old
>   600-character cap existed to protect the injection; the manifest protects it
>   now, so nothing needs to be shortened, summarized, or moved to a side file.
>   (A controlled study of progressive disclosure found one level of routing helps
>   and a second, deeper level *"never helps and sometimes breaks accuracy
>   outright"* — so: manifest line → whole item, and no third hop.)
>
> - **Worthiness — all four must hold for a line to earn an ID:** (1) an open loop
>   a future session must act on, with a concrete done-condition; (2) not tracked
>   elsewhere; (3) can't just be done now (under ~10 minutes ⇒ do it); (4) one ID
>   per loop — sub-facts ride the parent.
>
> - **Closed lines MOVE; they are never deleted.** At `/end`, `[x]`/`[-]` lines
>   older than `ledger.move_closed_after_days` are appended to
>   `docs/SESSION_LEDGER_CLOSED.md` — which is never injected and can grow forever.
>   Deleting them breaks every citation that escaped into a commit subject, a
>   handoff entry or the spine: an ID that has escaped into an immutable reference
>   can never be reclaimed, only aliased. On one real project, pruning left 51 of
>   72 spine IDs pointing at nothing.
>
> - **Never rewrite this file. Never renumber. IDs are permanent and never reused.**
>   Lines are appended, or edited in place from `[ ]` to `[x]` (done — append
>   `→ DONE <date>: <one line>`) or `[-]` (dropped — append the reason).
>
> - Don't strike an open item you don't recognise — it may belong to a concurrent
>   session in this same checkout.
>
> - **IDs.** Single-track: `L-1, L-2, …`. **Multi-track:** each track mints with its
>   own prefix and its own counter — `D-1, M-1` — so two sessions can append at
>   once without colliding. The prefix says who WROTE it; a tag right after the ID
>   says who ACTS on it: `→mobile`, `→desktop`, `→all`. No tag = the writer's track.

<!-- Items start here. The first line is the title; continuation lines are body.

Single-track:
- [ ] L-1 (2026-09-08) BACKUP EXPORT HAS NEVER BEEN ROUND-TRIPPED ON A CLEAN INSTALL — done when export → import matches the manifest counts.
  Detail, findings, links, anything at any length go on continuation lines like
  this one. Only the first line is injected at session start.

- [x] L-1 (2026-09-08) BACKUP EXPORT HAS NEVER BEEN ROUND-TRIPPED … → DONE 2026-09-09: passed, counts matched
- [-] L-2 (2026-09-08) MIGRATE X TO Y → dropped 2026-09-10: superseded by Z

Multi-track:
- [ ] D-1 (2026-09-08) SYNC STATUS FLICKERS DURING A FULL COPY-UP — done when the hub mark reads "Backing up" once for the whole run.
- [ ] D-2 →mobile (2026-09-08) SERVER v134 IS LIVE WITH THE WIPE STAMP (migration 0030) — the phone must re-sync before testing wipe-aftermath copy.
- [ ] M-1 →all (2026-09-08) `Entry.milestone` IS NOW NULLABLE IN packages/core — rebuild core and re-run the drift guard before the next commit on either track.
-->

- [ ] L-1 (2026-10-23) A GAME UPDATE OR A POLARWIZARD RETAIL RELEASE INVALIDATES THE INSTALLER'S CONSTANTS — done when the .bat recognises the new build (re-verified offsets, new hashes) or the patch step is retired in favour of an upstream retail build.
  Watch: Steam `appmanifest_3259780.acf` LastUpdated / buildid (currently 24250053), PE TimeDateStamp of FFRS-Win64-Shipping.exe (currently 0x6A586B2F), and https://github.com/PolarWizard/final-fantasy-resonance-fix/releases (currently 0.2.0, demo-built). On a game update the installer refuses by design; the user's live install will crash at launch until winmm.dll is removed or the plugin is re-patched. Re-verification recipe is in README.md "What it does and why" and the KB lesson demo-built-mod-on-a-retail-game-fixed-offsets-crash.md.
  Since 2026-11-08 the live install also loads UE4SS (dwmapi.dll, Nexus 119 AA menu) and Luma/ReShade (dxgi.dll, DLSS preset K via ReShade.ini [Luma] DLSSRenderPreset=11) under Steam launch option -dx11. On a post-update launch crash, triage all three hooks, not only winmm.dll; the added files are listed in Win64\_ffrs_luma_installed_files.txt and FFRS_Luma_Upscaler.bat [2] removes them. That .bat also pins the same PE stamp (the AA mod's supported-inputs.json names buildid 24250053), so a game update makes it refuse too.

- [ ] L-3 (2026-11-08) FFRS_LUMA_UPSCALER.BAT NEEDS ITS ALLY X20 RUN BEFORE THE README ADVERTISES IT — done when the user has run it on the ROG Xbox Ally X20, the game runs in DX11 with Luma, the status lines say whether FSR 4 came up, and the user has decided whether README gets a section for it.
  The script was committed and pushed to the public repo on 2026-11-08 at the user's choice, so the Ally can download it from GitHub; README does not mention it yet.
  Pause B of the Luma work. Pause A passed on this PC 2026-11-08 (scratch matrix: install/download, no-op, local zips, foreign-dxgi refuse, other-build refuse, remove, remove-with-other-UE4SS-mod, VDF no-app-block and existing-option cases, live read-only status). FSR 4 on the Ally is unverified: ASUS ships FSR 4.1 for the Ally X/X20 as a preview GPU driver; Luma bundles amd_fidelityfx_upscaler_dx12.dll 4.1.2 (loader 2.3.0) and reaches it through DX12 interop. ReShade.log line "[Luma] FSR4: Initialized FSR 4.x" without "spoofing" = available; "No FSR 4 upscaler available on this GPU" = not. Luma's Auto order is DLSS, FSR 4, XeSS, FSR 3. Luma's UE mod is native-resolution only, so on the Ally it buys image quality, not frame rate.

- [ ] L-4 (2026-11-08) kbdoc: DLSS 4.5 preset L at native resolution (DLAA) cost ~170 W for no visible gain; use K, and inject DLSS into DX11 UE games with Luma — done when written in the Knowledge Base (new article; nothing on Luma or DLSS presets there yet).
  Measured 2026-11-08, RTX 5090, 3440x1440, VSync on: preset L = 100% GPU, ~580 W (power limit), 83 C, case fans loud; preset K = 69%, ~410 W, 72 C; colours identical to the user. L/M are tuned for Ultra Performance / Performance input resolutions; Luma's own Sunset Overdrive code defaults DLAA to K ("L and M crush hues"). Diagnostic worth keeping: shader-compile hitches on a first DX11 run are CPU work and fade; a GPU pinned at its power limit is real render cost, not cache. Luma UE recipe: game must be on TAA (UE5 games that hide TAA need a UE4SS cvar/menu mod), -dx11, ReShade.ini [Luma] SRUserType 0 None/1 Auto/2 DLSS/3 FSR 3/4 FSR 4/5 XeSS and DLSSRenderPreset 11 = K / 12 = L; Auto order DLSS, FSR 4, XeSS, FSR 3; evidence lines in ReShade.log ("Detected UE4 TAA. Hash", "FSR4: Initialized ..."). "No effect files found" in ReShade is normal for Luma.

- [ ] L-5 (2026-11-08) kbdoc: Steam launch options can be set by script in localconfig.vdf, but only with Steam closed — done when added to steam-library-integration.md (it already covers reading localconfig.vdf).
  Path: userdata/<accountid>/config/localconfig.vdf, key UserLocalConfigStore/Software/Valve/Steam/apps/<appid>/LaunchOptions (block may not exist yet: create it under apps). Steam rewrites the whole file on exit, so an edit made while it runs is lost: `steam.exe -shutdown`, wait for the process to exit, back up, edit, restart. Account id = ActiveUser (HKCU\Software\Valve\Steam\ActiveProcess, 0 when Steam is closed) or the MostRecent SteamID64 in config/loginusers.vdf minus 76561197960265728. File is UTF-8 without BOM, LF. Implementation and tests: FFRS_Luma_Upscaler.bat (SetLaunchArg / VdfFind).

- [ ] L-2 (2026-10-23) ANNOUNCE: STEAM FORUM POST AND A POINTER ON POLARWIZARD ISSUE #1 — done when both are posted and the repo README links the Steam thread.
  STEAM_POST.txt (gitignored) is the BBCode draft, title suggestion at the top. The repo URL in it is live as of 2026-10-23. Issue #1 has two users confirming the crash who would benefit from the link; keep the comment short, credit Darjjj's offsets, and offer the repo as a stopgap until an upstream retail build. Both are outward-facing posts under the user's name: the user sends them, a session only drafts.
