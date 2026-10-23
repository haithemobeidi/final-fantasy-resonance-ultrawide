# final-fantasy-resonance-ultrawide — Decisions

Append-only log of technical and process decisions with rationale. Newest at the bottom. Never rewrite a past entry; supersede it with a new one that names what it replaces. Read on demand; not auto-loaded.

Entry shape: **Decision** (what) / **Why** (the evidence or the incident) / **How to apply** (what a future session does differently). Date every entry.

---

## 2026-10-23 — Bootstrapped from claude-project-template, directly on protocol v2

**Decision:** Adopt the session protocol (global work style + protocol imported from the Knowledge Base; per-project settings in `.claude/protocol.json`; hook-enforced codebase index; moment-of-event ledger). `protocol_version` is 2 from the first commit; no v1 documents ever existed here, so `migrate-docs-v2.py` has nothing to do.

**Why:** Re-deriving these per project is wasted ceremony, and copies drift. The template's documents already have the v2 shape.

**How to apply:** Project differences go in `CLAUDE.md` and `protocol.json`. The scripts stay byte-identical to the template; `check-template-drift.py` reports when they are behind. `push_policy` is `ask`.

---

## 2026-10-23 — Download-and-patch at install time; never redistribute binaries

**Decision:** The repo contains a `.bat`, a README and a license. The installer downloads PolarWizard's official 0.2.0 zip from GitHub, checks its SHA-256, rewrites five 4-byte immediates in the plugin, checks the result's SHA-256, and only then writes into the game folder.

**Why:** A patched DLL attached to a forum post asks strangers to trust an unsigned binary from an unknown account, and strips the author's name off their own work. A script whose every line is readable, pinned to upstream's hashes, is the same trust surface as upstream plus 13 bytes you can diff.

**How to apply:** New upstream release: pin the new zip hash, re-derive the patch counts, or drop the patch step if upstream is retail-built. `.gitignore` blocks `*.dll`, `*.asi`, `*.zip`, `*.bak` so a binary cannot slip into a commit.

---

## 2026-10-23 — Refuse on any exe other than the one build the constants were verified against

**Decision:** `CheckBuild` requires both the PE `TimeDateStamp` (`0x6A586B2F`) and the 17 `AppendString` prologue bytes at file offset `0x13757A0`. Anything else is a refusal with a pointer to upstream's release page. No "continue anyway".

**Why:** The whole incident this repo exists for is a plugin with offsets from one exe being run against another. A game update will move `GObjects` and `AppendString` again; writing the current constants into that install reproduces the launch crash, now with the user believing it was fixed.

**How to apply:** On a new build, re-verify both offsets (signature hit count for the function, RIP-relative reference count for the global) before touching the constants block. Update the README evidence table in the same commit.

---

## 2026-10-23 — `[hud] enable` is forced off by the installer

**Decision:** The installer writes `[hud] enable = false` into the TOML even if the user had it on, and says so.

**Why:** On 21:9 the HUD already fills the screen once the bars are gone; the option only shrinks it into a box for 32:9. Its code path holds a raw render-target pointer across garbage collection and crashes on the second battle transition (documented on upstream issue #1). Fixing the five offsets does not fix that.

**How to apply:** Lift the override only when an upstream release fixes the encounter path and someone has run two battles on retail with it on.

---

## 2026-10-23 — .NET calls instead of `Get-FileHash` and `Expand-Archive`

**Decision:** Hashing uses `[Security.Cryptography.SHA256]::Create().ComputeHash($stream)`; extraction uses `[IO.Compression.ZipFile]::ExtractToDirectory` after `Add-Type -AssemblyName System.IO.Compression.FileSystem`.

**Why:** Both cmdlets are script-module functions. On the `.bat` to `powershell -Command ... Invoke-Expression` path they resolved to "not recognized" during the test matrix, even though a plain child shell found them. The .NET types are present in 5.1 and 7 alike.

**How to apply:** Any new file or archive operation in the `.bat` goes through .NET, not a module cmdlet. Test the `.bat` by double-click or `cmd /c`, not by pasting the PowerShell body into a console.
