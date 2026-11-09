# Phase 1 — Research report (metadata only, no downloads)

- Generated: 2026-11-02T19:xx UTC (see `13-Logs\execution.log` for exact per-tool retrieval times)
- Detected target: **OBS Studio 32.0.1** (64-bit, Windows), installed at `C:\Program Files\obs-studio`, **not portable**
- Hard environment evidence used for every compatibility judgement:
  - **Python on Windows for OBS 32.0.1: `3.8 <= version < 3.11`** — `obs-studio@32.0.1:shared/obs-scripting/cmake/python.cmake` (`if(OS_WINDOWS) find_package(Python 3.8...<3.11 REQUIRED ...)`)
  - **Lua 5.1** — `lua51.dll` shipped in `C:\Program Files\obs-studio\bin\64bit`
  - **Bundled obs-websocket = 5.6.3** — `obs-studio@32.0.1` submodule `plugins/obs-websocket` pinned to `1c9306b1e200704ebe192e06c893dfc06b097c43`, which is exactly tag `5.6.3`
  - **OBS 32 refuses plugins built for a newer OBS** — OBS 32.0.1 release notes ("OBS Studio will no longer load plugins built for a newer release of OBS")

## Registry status table

| # | id | release tag | assets (Windows) | SPDX read from file | OBS compat (evidence) | Maint. | Doc'd capabilities | Proposed |
|---|---|---|---|---|---|---|---|---|
| 1 | advanced-scene-switcher | `1.37.2` (2026-11-01) | `-windows-x64-Installer.exe` 105.2 MB, `-windows-x64-obs32.zip` 153.7 MB, `-windows-x64-portable-obs32.zip` 153.7 MB, `-windows-x64.zip` 153.7 MB (OBS 33+ only) | **GPL-2.0** (`LICENSE`, 18046 B) | SUPPORTED — min OBS 31.1.1 (release notes + forum page) | ACTIVE | HTTP requests, process `Run` action, file/folder watch, hotkeys, MIDI, Twitch API | INCLUDED |
| 2 | rse-obs-scripts | none (no tags, no releases) | — source only, 7 Lua scripts | **no LICENSE file**; MIT declared in each file header only | UNKNOWN | STALE (2024-07-14) | `auto-execute-commands` runs shell commands on OBS start/stop | UNVERIFIED |
| 3 | libre-macros | `4.2.0` (2025-11-15) | — source only | **AGPL-3.0** (`LICENSE.md`, 34283 B) | SUPPORTED — README: works on OBS 32, 28, 27 | ACTIVE | `execute()` command line, `obsffi` native FFI, live reload, auto-run, JS injection, websocket interaction | PENDING-USER (S expected HIGH) |
| 4 | autostarter | `v2.1.0` (2025-02-20) | `autostarter.zip` 39.8 KB, `autostarter.dll` 106.5 KB | **GPL-2.0** (`LICENSE`, 18045 B) | SUPPORTED — README: OBS 30.1.2+, Win10+ | ACTIVE | launches/quits external programs, loadouts, CLI arg | INCLUDED |
| 5 | advanced-timer | `6.0.0` (2023-04-11) | `advanced-timer.lua` 19.6 KB | **GPL-2.0** (`LICENSE`, 18092 B) | UNKNOWN — no version statement | STALE (2023-07-03) | text-source timer, streaming/recording triggers, hotkeys | INCLUDED |
| 6 | obs-counter | `1.2.0` (2025-03-22) | — source only | **MIT** (`LICENSE`, 1068 B) | LIKELY — Python script, README targets OBS ≥28 | ACTIVE | hotkey counter into a text source | INCLUDED |
| 7 | advanced-filename-formatter | `1.5.0` (2026-10-26) | `adv-ff.py` 54.3 KB | **GPL-2.0** (`LICENSE`, 18092 B) | SUPPORTED w/ limit — README: Python ≥3.10; replay-buffer features need OBS ≥33 | ACTIVE | dynamic filename tokens, Python eval of expressions | INCLUDED |
| 8 | local-stream-marker | `v1.13` (2026-06-13) | `local-stream-marker.1.13.zip` 13 KB | **MIT** (`LICENSE`, 1063 B) | UNKNOWN — no version statement | ACTIVE | hotkey markers → CSV with 11 columns | INCLUDED |
| 9 | source-record | `0.4.8` (2026-03-26) | `-windows.zip` 348 KB, `-windows-installer.exe` 2.2 MB | **GPL-2.0** (`LICENSE`, 18092 B) | LIKELY — buildspec obs-studio 29.0.0-beta1 | ACTIVE | records a single source to file, encoder selection | INCLUDED |
| 10 | obs-screen-studio-script | none (no releases) | — source only, `obs-screen-studio.lua` 54.1 KB | **MIT** (`LICENSE`, 1056 B; copyright holder blank) | SUPPORTED — README: OBS 28+, "tested up to 32.x" | ACTIVE | LuaJIT `ffi` (cursor/click tracking), group zoom animation | PENDING-USER (NO-STABLE-RELEASE) |
| 11 | shaderfilter | `2.6.1` (2026-10-24) | `-windows.zip` 4.6 MB, `-windows-installer.exe` 6.3 MB | **GPL-2.0** (`LICENSE`, 18092 B) | LIKELY — buildspec obs-studio 28.0.0-beta1 | ACTIVE | GPU shader filters, custom `.shader` files | PENDING-USER (fork) |
| 12 | filter-hotkeys | `1.0.2` (2021-03-27) | — source only | **MPL-2.0** (`LICENSE`, 16725 B) | UNKNOWN — 2021 script | STALE (2024-08-08) | binds hotkeys to enable/disable/hold filters | INCLUDED |
| 13 | tuna | `1.9.12` (2026-10-24) | `-windows-x64.zip` 7.3 MB, `-windows-x64-Installer.exe` 6.3 MB | **GPL-2.0** (`LICENSE`, 18042 B) | LIKELY — buildspec obs-studio 31.1.0 | ACTIVE | song info via Spotify/MPRIS/WMC/last.fm, **local HTTP server (cpp-httplib)**, cURL, lyrics from lyrics.vrsal.cc | INCLUDED |
| 14 | multi-rtmp | `0.7.4.5` (2026-10-25) **requires OBS 32.2.1** → not usable; newest compatible = `0.7.4` (2026-03-27) | `obs-multi-rtmp-0.7.4.0-windows-x64.zip` 2.0 MB, `-Installer.exe` 1.3 MB | **GPL-2.0** (`LICENSE`, 18092 B) | 0.7.4: LIKELY (buildspec obs-studio 32.0.0). 0.7.4.5: **INCOMPATIBLE** (buildspec 32.2.1) | ACTIVE | multi-destination streaming, per-target keys, export/import incl. keys | PENDING-USER (version choice) |
| 15 | obs-websocket | `5.6.3` = the version bundled in OBS 32.0.1 | none (bundled) | **GPL-2.0** (`LICENSE`, 18045 B) | SUPPORTED — bundled since OBS 28 | ACTIVE | WebSocket API, port 4455, auth, protocol.md 160 KB | DOCS-ONLY |
| 16 | obs-mcp | `v0.2.0` (2026-07-25) | — source only | **Apache-2.0** (`LICENSE`, 11337 B) | SUPPORTED — README badge OBS 28+ | ACTIVE | MCP server, 148 obs-websocket tools, local stdio, `OBS_HOST`/`OBS_PASSWORD` env vars, `install.bat` (pip) | INCLUDED (install needs approval) |

## Publisher checksum availability (R3/D3 input)

| tool | publisher SHA-256 in release notes | platform digest (GitHub) |
|---|---|---|
| advanced-scene-switcher | **yes** — `### Checksums` block lists every asset | yes |
| multi-rtmp 0.7.4 | no (changelog only) | yes |
| multi-rtmp 0.7.4.5 | yes | yes |
| source-record, shaderfilter, tuna, adv-ff, local-stream-marker | no | yes |
| autostarter, advanced-timer | no | no (assets uploaded without digest) |
| libre-macros, obs-counter, filter-hotkeys, rse-obs-scripts, obs-screen-studio, obs-mcp | n/a (no assets) | n/a |

## Fork / renamed-repository findings (R1)

- **shaderfilter** `exeldro/obs-shaderfilter` is a **fork** of `Oncorporation/obs-shaderfilter` (source `nleseul/obs-shaderfilter`). Per §3.1/§6 R1 a fork needs explicit approval → `PENDING-USER`.
- All other 15 repositories are original (not forks), not archived, none redirected away from the registry URL.

## Open questions for the go/no-go

1. **shaderfilter is a fork** — approve including `exeldro/obs-shaderfilter` 2.6.1 (GPL-2.0, actively maintained) or skip it?
2. **multi-rtmp version** — take `0.7.4` (works on OBS 32.0.1) or the newest `0.7.4.5` (needs OBS 32.2.1, will not load on your 32.0.1)?
3. **Source-only tools without a stable release** (`obs-screen-studio-script`, and `rse-obs-scripts` which also lacks a LICENSE file) — approve pinning to a commit, or drop them?
4. **libre-macros** — AGPL-3.0 and documented `execute()`, native FFI, live reload and JS injection. The static review in Phase 2 is expected to rate it HIGH, which means it would move to `10-Unverified\`. Confirm you still want the source snapshot stored.
5. **OBS-configured Python path** — still `UNKNOWN`; paste it when convenient (Tools → Scripts → Python Settings). Note your interpreters 3.12/3.13/3.14/3.15 are **outside** OBS 32.0.1's Windows range (3.8–3.10); `C:\Python38` is the only in-range one detected.
