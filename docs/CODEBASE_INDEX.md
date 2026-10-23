# final-fantasy-resonance-ultrawide — Codebase Index

**Purpose:** A one-line description of every meaningful file in the project. Future sessions read this to understand what each file does without re-reading the source.

**Maintenance:** Enforced by a `PostToolUse` hook. When you Write or Edit a file that is not listed here, its path is queued in `.claude/pending-index-updates.txt`; `/end` refuses to complete until every queued path has a row. `validate-index.py` (run at `/end`) flags rows whose files no longer exist.

**Last updated:** 2026-10-23

---

## Project root

| File | Purpose |
|---|---|
| `FFRS_Ultrawide_Fix.bat` | The product. Batch header + embedded PowerShell: finds the game, checks the exe build, downloads and hash-checks PolarWizard's 0.2.0 zip, rewrites the five demo offsets to retail, hash-checks the result, installs loader + plugin + config, forces `[hud] enable = false`; option 2 removes exactly what it added |
| `README.md` | Player-facing guide: install, remove, manual hex-editor route, what the two offsets are and how they were verified, HUD note, known limits, credits |
| `LICENSE` | MIT, for the script and the docs |
| `STEAM_POST.txt` | Steam forum announcement draft in BBCode. Gitignored; lives only on this machine |
| `CLAUDE.md` | Project file — what is different about this project; augments the global work style + protocol |
| `ROADMAP.md` | Four phases; holds the "Status at a glance" spine (source of truth for phase status) |
| `DECISIONS.md` | Append-only decision log with rationale |
| `.gitattributes` | Forces CRLF on `*.bat` so the batch half parses on every checkout |
| `.gitignore` | Protocol state, Python bytecode, every binary type the installer handles, the Steam draft |

## tools/

| File | Purpose |
|---|---|
| `tools/check-bat.ps1` | `check_command`: fails if the `.bat` has LF-only endings, non-ASCII bytes, a missing or duplicated PowerShell marker, or embedded PowerShell that does not parse |

## docs/

| File | Purpose |
|---|---|
| `docs/CURRENT_STATE.md` | Product state: NEXT ACTION, shipped version, build status, blockers, open-loop pointer. Overwritten at `/end`. |
| `docs/HANDOFF_LOG.md` | Append-only I-PASS entry per session. |
| `docs/SESSION_LEDGER.md` | Append-and-strike ledger of open loops; written at the moment of the event. |
| `docs/CODEBASE_INDEX.md` | This file. |

## .claude/

| File | Purpose |
|---|---|
| `.claude/protocol.json` | Per-project settings the protocol scripts read (check command, push policy, skip paths, ledger caps, tracks). The only protocol file edited per project. |
| `.claude/settings.json` | Hook wiring (SessionStart / PostToolUse / Stop) + statusline. Identical across projects. |
| `.claude/agents/planner.md` | Read-only planner subagent — implementation plans with declared pause-points. |
| `.claude/agents/reviewer.md` | Read-only reviewer subagent — independent diff review against the rules. |
| `.claude/agents/explorer.md` | Read-only explorer subagent — adjacent questions with `file:line` citations. |
| `.claude/scripts/protocol_config.py` | Shared loader for `protocol.json` + template-drift helpers; imported by every script. |
| `.claude/scripts/session-start-context.py` | SessionStart hook — worktree guard, global-install check, fetch + stale refusal, injects state docs + tracks + cross-check directive. |
| `.claude/scripts/track-new-file.py` | PostToolUse hook — queues unindexed paths to `pending-index-updates.txt`. |
| `.claude/scripts/stop-clean-tree-check.py` | Stop hook — blocks a stop when a Session commit just landed and this track's files are still dirty. |
| `.claude/scripts/validate-index.py` | `/end` Step 1c — flags index rows pointing at deleted files. |
| `.claude/scripts/scan-secrets.py` | `/end` Step 0c — content-based secret scan of everything heading for a commit; `--history` audits everything pushable. |
| `.claude/scripts/check-template-drift.py` | Compares this project's protocol machinery against the Knowledge Base template; `--sync` resyncs. |
| `.claude/scripts/check-file-caps.py` | `/end` Step 0d — line caps on touched code files and a same-basename twin check. |
| `.claude/scripts/check-ledger-refs.py` | `/end` Step 1e — classifies every ledger ID cited in CURRENT_STATE and the spine as open / struck / absent. |
| `.claude/scripts/check-payload-budget.py` | `/end` Step 3b — assembled session-start payload against `payload.target_chars` and the hook part count. |
| `.claude/scripts/end-derive.py` | `/end` Step 3 — commits and files touched since the last wrap, grouped by track. |
| `.claude/scripts/ledger-archive.py` | `/end` Step 1d — moves closed ledger lines to `docs/SESSION_LEDGER_CLOSED.md`. |
| `.claude/scripts/migrate-docs-v2.py` | One-time v1 → v2 document migration. Not needed here: bootstrapped on v2. |
| `.claude/scripts/statusline.py` | Statusline — phase + build status from CURRENT_STATE, branch + dirty count from git. |
