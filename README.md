# FINAL FANTASY RESONANCE ultrawide fix (retail Steam build)

Removes the 16:9 pillarbox in the PC version of *FINAL FANTASY RESONANCE* (Steam) so the game fills a **21:9 or 32:9** monitor (2560x1080, 3440x1440, 3840x1600, 5120x1440). Gameplay, menus and in-engine cutscenes use the whole screen. Pre-rendered movies stay at their native 16:9 with bars at the sides, on purpose.

This is not a new fix. It is [PolarWizard's open-source `final-fantasy-resonance-fix`](https://github.com/PolarWizard/final-fantasy-resonance-fix) (MIT) made to work on the **retail** game. Its 0.2.0 release was built against the demo and crashes the retail build the moment it launches ([issue #1](https://github.com/PolarWizard/final-fantasy-resonance-fix/issues/1)). Five addresses inside its plugin need to change. One `.bat` file does that for you, and you can also do it by hand with a hex editor (below).

No game file is modified. The fix is a loader DLL and a plugin that sit next to the game's exe. Steam's **Verify integrity of game files** leaves them alone. Deleting `winmm.dll` turns the whole thing off.

## Install

1. Download [`FFRS_Ultrawide_Fix.bat`](./FFRS_Ultrawide_Fix.bat) and put it in the game folder (Steam: right-click the game, then **Manage → Browse local files**). If it is left somewhere else, it searches your Steam libraries for the game.
2. Close the game, double-click the `.bat` and choose **1**. It downloads PolarWizard's official 0.2.0 zip from GitHub, checks its SHA-256, patches the plugin, and installs it. No internet? Download the zip yourself from [the release page](https://github.com/PolarWizard/final-fantasy-resonance-fix/releases/tag/0.2.0) and put it next to the `.bat`.
3. Start the game. In **Options → Graphics**, pick your monitor's native resolution (borderless or fullscreen both work).

To remove it, run the `.bat` again and choose **2**. It deletes exactly what it added.

**After a game update:** the five addresses move again and the game would crash at launch. Run the `.bat`, choose **2** to remove the fix, and check [PolarWizard's releases](https://github.com/PolarWizard/final-fantasy-resonance-fix/releases) for a build made for the new version. The script checks the exe before installing and refuses to write to a build it does not recognise.

## Do it by hand (no script)

1. Download `final-fantasy-resonance-fix_0.2.0.zip` from [the release page](https://github.com/PolarWizard/final-fantasy-resonance-fix/releases/tag/0.2.0) and extract it.
2. Open `scripts\final_fantasy_resonance_fix.asi` in a hex editor such as [HxD](https://mh-nexus.de/en/hxd/).
3. **Search → Replace**, datatype **Hex-values**, **Replace all**:

   | Find | Replace with | Expected count |
   |---|---|---|
   | `50 6D D7 09` | `D0 4D D8 09` | 4 |
   | `60 63 37 01` | `A0 63 37 01` | 1 |

   If either count is different, stop. You have a different version of the plugin than this guide was written for.
4. Save. The file's SHA-256 should now be `5909f6498e23bed0c0b91e054b04b02ea784ea7f07140c1f9a20b43bc7b4a28e`.
5. Copy `winmm.dll` and the `scripts` folder into `...\FINAL FANTASY RESONANCE\FFRS\Binaries\Win64` (the folder with `FFRS-Win64-Shipping.exe`, **not** the one with `FFRS.exe`).
6. Leave `[hud] enable = false` in `scripts\final_fantasy_resonance_fix.toml`. See "HUD" below.

## What it does and why

The game is Unreal Engine 5. Its camera is told to hold a 16:9 frame (`bConstrainAspectRatio`), which is what draws the bars, and the engine's axis constraint would otherwise crop the top and bottom on a wider screen. PolarWizard's plugin patches both at startup by scanning for the instructions, so those two patches survived the move from demo to retail without any change. What did not survive is the part that talks to the game's object system.

The plugin was built with an SDK generated from the **demo** exe by [Dumper-7](https://github.com/Encryqed/Dumper-7). That SDK bakes in fixed offsets for two engine globals. On the retail exe those offsets point into the middle of unrelated code. The first time the movie or HUD feature looks up an object name, the game faults, which is the `0xc0000005` at offset `0x1376360` in the Windows Application event log.

| What | Demo offset (in the 0.2.0 plugin) | Retail offset (Steam build of 2026-10-22) | Occurrences patched |
|---|---|---|---|
| `GObjects` (the engine's object table) | `0x09D76D50` | `0x09D84DD0` | 4 |
| `FName::AppendString` (name lookup) | `0x01376360` | `0x013763A0` | 1 |

The retail values were first posted by **Darjjj** in [issue #1](https://github.com/PolarWizard/final-fantasy-resonance-fix/issues/1), who read them from the running game. This repo re-verified both against the retail exe without running anything:

- `AppendString` by signature. The function's opening bytes (`48 89 5C 24 10 48 89 74 24 18 57 48 83 EC 20 80 3D ...`) occur exactly once in the exe, at `0x013763A0`. The demo offset lands mid-function.
- `GObjects` by use. Code in the exe references `0x09D84DD0` 1,070 times through RIP-relative addressing and references the demo address `0x09D76D50` zero times.

The plugin also carries the demo's `GNames`, `GWorld` and `ProcessEvent` offsets in its SDK, but the compiled code never uses them, so they are left alone.

The script finds the game through the Steam registry key and `libraryfolders.vdf`, checks the exe's PE timestamp (`0x6A586B2F`) and the `AppendString` prologue at its known offset, downloads the official zip and compares its SHA-256, patches the five values only if it finds exactly four and one, compares the result's hash, and only then writes into the game folder. Anything unexpected makes it stop without writing.

## HUD

On a 21:9 monitor the HUD already spans the full width once the bars are gone, so there is nothing to configure. The plugin's `[hud]` option exists to **shrink** the HUD into a centred box (its demo shows 32:9 going to 21:9 and then 16:9). That code path has a second, separate bug on retail: it keeps a raw pointer to a render target that the engine garbage-collects between battles, which crashes on the second battle transition (also analysed in issue #1). The installer forces `[hud] enable = false` and leaves it there. 32:9 users who want a boxed HUD will have to wait for an upstream release.

## Known limits

- Verified only on the retail Steam build of 2026-10-22 (Steam buildid 24250053), at 3440x1440. Other 21:9 and 32:9 resolutions should behave the same, since the fix removes the constraint rather than hardcoding a ratio.
- Pre-rendered movies stay 16:9 with side bars. That is PolarWizard's `[movies]` feature doing its job. Turning it off makes them stretch.
- The HUD box option is unavailable (see above).
- `winmm.dll` is a proxy DLL (ThirteenAG's Ultimate ASI Loader). If another mod already uses a `winmm.dll` in that folder, the script refuses and you will need to combine them by hand.
- Some antivirus products dislike proxy DLLs on principle. Windows Defender reported no threats on these files. The loader is open source and its hash is checked by the script.

## Credits

- [PolarWizard](https://github.com/PolarWizard/final-fantasy-resonance-fix) wrote the fix. All the actual work is theirs. MIT.
- [Darjjj](https://github.com/PolarWizard/final-fantasy-resonance-fix/issues/1) found the root cause on retail, read the new offsets from memory, and documented the HUD-path crash.
- [ThirteenAG](https://github.com/ThirteenAG/Ultimate-ASI-Loader) for the Ultimate ASI Loader. MIT.
- [Dumper-7](https://github.com/Encryqed/Dumper-7), which PolarWizard's fix is built on.

## Disclaimer

This is an unofficial fan fix, not affiliated with or endorsed by Square Enix. It adds files to your local install and does not change any game file. Use it at your own risk. No game files or third-party binaries are distributed in this repo; the script downloads PolarWizard's release from GitHub and verifies it.

## License

[MIT](./LICENSE) for the script and this document. PolarWizard's fix and the Ultimate ASI Loader carry their own MIT licenses, which the installer copies into the `scripts` folder next to the plugin.
