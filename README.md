# OBS Toolkit

An offline, audited, reproducible library of free and open-source tools for
**OBS Studio on Windows 11 x64**. It holds original release assets, pinned source
snapshots, license texts, checksums, security reviews and documentation — and it
**installs nothing**.

Detected target: **OBS Studio 32.0.1 x64**, non-portable, at
`C:\Program Files\obs-studio`. Library built 2026-11-09T17:10:14Z.

## 1. Overview

### What this is

A library, not an installer. For every researched project it answers four
questions:

1. What is it and what does it do?
2. Is it free and open source, and what does its license require of you?
3. Is it the file the publisher meant you to have (hash, signature)?
4. Does it work with OBS 32.0.1 on Windows 11 x64, and what can it reach
   (network, processes, files, input)?

You install from it by hand, one tool at a time, after a backup.

### What "free and open source" means here

A tool qualifies only when an **OSI-approved license text is present in the
pinned source snapshot** and its SPDX identifier is recorded. Visible source code
alone is not enough: a repository with no license file is `UNVERIFIED`, not
"open source". That is why RSE OBS Scripts sits in `10-Unverified\`: its headers
claim MIT, but no `LICENSE` file exists at the pinned commit.

### Scope

| | Count |
|---|---|
| Projects researched | 16 |
| `INCLUDED` | 13 |
| `UNVERIFIED` | 1 |
| `PENDING-USER` | 1 |
| `DOCS-ONLY` | 1 |
| `REJECTED` | 0 |
| `UNAVAILABLE` | 0 |
| Release assets downloaded | 9 (119.5 MB) |
| License confirmed from a saved file | 15 of 16 |

Categories: scene management, scripting and automation, timers and counters,
recording and organization, screen production, audio and media, streaming, and
remote control and AI.

### What it is not

- Not a runtime test: nothing was installed, executed or loaded into OBS.
- Not a malware analysis: compiled DLLs were hashed and signature-checked, not
  disassembled.
- Not legal advice: `LICENSES.md` summarises obligations, it does not replace a
  lawyer.

## 2. How to use it in three steps

1. **Verify.** Run the checksum verifier before touching anything:

   ```powershell
   pwsh -NoProfile -ExecutionPolicy Bypass -File .\12-Utilities\Verify-Checksums.ps1
   ```

   Exit code `0` means every file matches `MANIFEST.json`. Anything else, stop
   and read the dated report in `13-Logs\`.

2. **Back up.** OBS profiles and scene collections contain secrets and are the
   only thing you cannot re-download. Dry-run the backup script first, then run it
   for real with a destination outside this library:

   ```powershell
   pwsh -NoProfile -ExecutionPolicy Bypass -File .\12-Utilities\Backup-OBS.ps1
   ```

   See `00-Documentation/OBS_BACKUP_GUIDE.md`.

3. **Install one tool at a time.** Pick from the order in section 6, open that
   tool's `TOOL_INFO.md`, follow section 8 there, restart OBS, confirm it loaded,
   use it once, then continue. Never install two new tools at once.

## 3. Annotated directory tree

```
OBS-Toolkit/
├── README.md                     this file
├── README.ar.md                  Arabic quick start
├── CHANGELOG.md                  phase-by-phase history (UTC dates)
├── LICENSES.md                   per-tool license and obligations
├── COMPATIBILITY.md              per-tool OBS/Python/Lua matrix
├── DOWNLOAD_REPORT.md            what was downloaded, skipped, quarantined
├── FINAL_REPORT.md               phase 5 summary and known gaps
├── MANIFEST.json                 single source of truth
├── MANIFEST.schema.json          JSON Schema draft-07
├── 00-Documentation/             8 guides (install, Windows, scripting, backup,
│                                 security, troubleshooting, updates, glossary)
├── 01-Scene-Management/          Advanced-Scene-Switcher/  RSE-OBS-Scripts/
├── 02-Scripting-and-Automation/  Autostarter/  Custom-Scripts/  Libre-Macros/
├── 03-Timers-and-Counters/       Advanced-Timer/  OBS-Counter/
├── 04-Recording-and-Organization/ Advanced-Filename-Formatter/
│                                 Local-Stream-Marker/  Source-Record/
├── 05-Screen-Production/         OBS-Screen-Studio/  Shaderfilter/
├── 06-Audio-and-Media/           Filter-Hotkeys/  Tuna/
├── 07-Streaming/                 Multi-RTMP/
├── 08-Remote-Control-and-AI/     OBS-WebSocket/  OBS-MCP/
├── 09-Optional-Tools/            only user-approved extras; empty today
├── 10-Unverified/                unresolved license or security (same layout)
├── 11-Checksums/                 SHA256SUMS.txt  VERIFICATION_REPORT.md
├── 12-Utilities/                 Common.psm1 + 7 PowerShell scripts
└── 13-Logs/                      execution.log  state.json  obs-baseline.json
                                  cache/  dated reports
```

Per-tool layout:

```
<Tool>/
├── TOOL_INFO.md                  fixed 12-section record
├── Downloads/<version>/          original assets, names untouched
├── Source/<tag-or-commit>/       pinned snapshot, no .git
├── Documentation/                LICENSE, README snapshot, release notes
└── Checksums.txt                 generated from MANIFEST.json
```

`02-Scripting-and-Automation/Custom-Scripts/` is reserved for your own scripts
and is deliberately empty. Never put downloaded code there.

## 4. Tools catalog

Every researched project, including the ones not included. Generated from
`MANIFEST.json`.

| Tool | Category | Type | License (SPDX) | Version | OBS compatibility | Maintenance | Decision |
|---|---|---|---|---|---|---|---|
| [Advanced Scene Switcher](01-Scene-Management/Advanced-Scene-Switcher/TOOL_INFO.md) | `scene-management` | `plugin` | `GPL-2.0-or-later` | `1.37.2` | `SUPPORTED` | `ACTIVE` | `INCLUDED` |
| [RSE OBS Scripts](10-Unverified/RSE-OBS-Scripts/TOOL_INFO.md) | `scene-management` | `lua-script` | `UNKNOWN` | `commit 59191d2` | `UNKNOWN` | `STALE` | `UNVERIFIED` |
| [Libre Macros](10-Unverified/Libre-Macros/TOOL_INFO.md) | `scripting-and-automation` | `lua-script` | `AGPL-3.0-or-later` | `4.2.0` | `SUPPORTED` | `ACTIVE` | `PENDING-USER` |
| [Autostarter](02-Scripting-and-Automation/Autostarter/TOOL_INFO.md) | `scripting-and-automation` | `plugin` | `GPL-2.0-or-later` | `v2.1.0` | `SUPPORTED` | `STALE` | `INCLUDED` |
| [Advanced Timer](03-Timers-and-Counters/Advanced-Timer/TOOL_INFO.md) | `timers-and-counters` | `lua-script` | `GPL-2.0-only` | `6.0.0` | `UNKNOWN` | `STALE` | `INCLUDED` |
| [OBS Counter](03-Timers-and-Counters/OBS-Counter/TOOL_INFO.md) | `timers-and-counters` | `python-script` | `MIT` | `1.2.0` | `LIKELY` | `STALE` | `INCLUDED` |
| [Advanced Filename Formatter](04-Recording-and-Organization/Advanced-Filename-Formatter/TOOL_INFO.md) | `recording-and-organization` | `python-script` | `GPL-2.0-or-later` | `1.5.0` | `SUPPORTED` | `ACTIVE` | `INCLUDED` |
| [Local Stream Marker](04-Recording-and-Organization/Local-Stream-Marker/TOOL_INFO.md) | `recording-and-organization` | `lua-script` | `MIT` | `v1.13` | `UNKNOWN` | `ACTIVE` | `INCLUDED` |
| [Source Record](04-Recording-and-Organization/Source-Record/TOOL_INFO.md) | `recording-and-organization` | `plugin` | `GPL-2.0-or-later` | `0.4.8` | `LIKELY` | `ACTIVE` | `INCLUDED` |
| [OBS Screen Studio](05-Screen-Production/OBS-Screen-Studio/TOOL_INFO.md) | `screen-production` | `lua-script` | `MIT` | `commit 5739bc0` | `SUPPORTED` | `ACTIVE` | `INCLUDED` |
| [Shaderfilter](05-Screen-Production/Shaderfilter/TOOL_INFO.md) | `screen-production` | `plugin` | `GPL-2.0-only` | `2.6.1` | `LIKELY` | `ACTIVE` | `INCLUDED` |
| [Filter Hotkeys](06-Audio-and-Media/Filter-Hotkeys/TOOL_INFO.md) | `audio-and-media` | `lua-script` | `MPL-2.0` | `1.0.2` | `UNKNOWN` | `STALE` | `INCLUDED` |
| [Tuna](06-Audio-and-Media/Tuna/TOOL_INFO.md) | `audio-and-media` | `plugin` | `GPL-2.0-or-later` | `1.9.12` | `LIKELY` | `ACTIVE` | `INCLUDED` |
| [Multi-RTMP](07-Streaming/Multi-RTMP/TOOL_INFO.md) | `streaming` | `plugin` | `GPL-2.0-or-later` | `0.7.4` | `LIKELY` | `ACTIVE` | `INCLUDED` |
| [OBS WebSocket](08-Remote-Control-and-AI/OBS-WebSocket/TOOL_INFO.md) | `remote-control-and-ai` | `docs-only` | `GPL-2.0-or-later` | `5.6.3` | `SUPPORTED` | `ACTIVE` | `DOCS-ONLY` |
| [OBS-MCP](08-Remote-Control-and-AI/OBS-MCP/TOOL_INFO.md) | `remote-control-and-ai` | `mcp-server` | `Apache-2.0` | `v0.2.0` | `SUPPORTED` | `ACTIVE` | `INCLUDED` |

## 5. Tool summaries

At most five lines each; the link is the full record.

### [Advanced Scene Switcher](01-Scene-Management/Advanced-Scene-Switcher/TOOL_INFO.md)

Rule- and macro-driven scene/source automation: switch on window focus, audio level, media state, clock, hotkey or OBS event. Adds HTTP and "run program" actions, so treat imported macros as code. Built for OBS 31.1.1+; the installer supports 32 and 33.

`INCLUDED` · `plugin` · `GPL-2.0-or-later` · `SUPPORTED` · risk `MEDIUM`

### [RSE OBS Scripts](10-Unverified/RSE-OBS-Scripts/TOOL_INFO.md)

Seven standalone Lua utilities: command hooks, scene cloning, browser refresh, keyboard events to Browser Sources, stats to a text source, and more. No LICENSE file at the pinned commit, so it stays `UNVERIFIED` in `10-Unverified\`.

`UNVERIFIED` · `lua-script` · `` · `UNKNOWN` · risk `MEDIUM`

### [Libre Macros](10-Unverified/Libre-Macros/TOOL_INFO.md)

A Lua console, macro/patch system and live reload for OBS, plus Python helpers over WebSocket. Dynamic code execution and FFI process creation make it `HIGH`; parked as `PENDING-USER` and not recommended.

`PENDING-USER` · `lua-script` · `AGPL-3.0-or-later` · `SUPPORTED` · risk `HIGH`

### [Autostarter](02-Scripting-and-Automation/Autostarter/TOOL_INFO.md)

Named "loadouts" of external programs launched with OBS or from a dock. Command lines are stored in the plugin configuration and started with your rights. `STALE` (last release 2025-02) and `COMPUTED-ONLY` verification.

`INCLUDED` · `plugin` · `GPL-2.0-or-later` · `SUPPORTED` · risk `MEDIUM`

### [Advanced Timer](03-Timers-and-Counters/Advanced-Timer/TOOL_INFO.md)

Countdown, stopwatch, clock/date and stream-state timers rendered into a text source, with hotkeys and formatting tokens. A single Lua script with no network, process or file access. `STALE` but `LOW` risk.

`INCLUDED` · `lua-script` · `GPL-2.0-only` · `UNKNOWN` · risk `LOW`

### [OBS Counter](03-Timers-and-Counters/OBS-Counter/TOOL_INFO.md)

OBS hotkeys increment/decrement a number shown in a text source: death counters, attempt counters, scoreboards. Python script, so it needs a 64-bit interpreter in OBS 32's 3.8–3.10 range.

`INCLUDED` · `python-script` · `MIT` · `LIKELY` · risk `LOW`

### [Advanced Filename Formatter](04-Recording-and-Organization/Advanced-Filename-Formatter/TOOL_INFO.md)

Dynamic recording filename templates (dates, scenes, sources) plus in-place renaming of finished recordings. Requires Python 3.10+, and evaluates templates as code. Replay Buffer features need OBS 33+.

`INCLUDED` · `python-script` · `GPL-2.0-or-later` · `SUPPORTED` · risk `MEDIUM`

### [Local Stream Marker](04-Recording-and-Organization/Local-Stream-Marker/TOOL_INFO.md)

A hotkey writes a CSV marker row with timestamp, scene, visible sources and the recording filename — stream-style chapters for any recording. Pure Lua file I/O; the README warns a bad datetime format can crash OBS.

`INCLUDED` · `lua-script` · `MIT` · `UNKNOWN` · risk `LOW`

### [Source Record](04-Recording-and-Organization/Source-Record/TOOL_INFO.md)

A filter that records one source on its own: clean game feed, camera ISO, or audio-only file alongside the main recording. Each enabled filter starts its own encoder and output. Authenticode-valid, publisher-verified asset.

`INCLUDED` · `plugin` · `GPL-2.0-or-later` · `LIKELY` · risk `LOW`

### [OBS Screen Studio](05-Screen-Production/OBS-Screen-Studio/TOOL_INFO.md)

Screen-studio style click-to-zoom and animated transitions for plain OBS recordings. One ~3,200-line Lua script using LuaJIT FFI to poll the global cursor and mouse buttons. Source-only; the commit is the identity.

`INCLUDED` · `lua-script` · `MIT` · `SUPPORTED` · risk `MEDIUM`

### [Shaderfilter](05-Screen-Production/Shaderfilter/TOOL_INFO.md)

Applies a custom `.shader`/`.effect` file to any source, with shader annotations becoming animatable properties. Ships 165 examples with mixed headers. This library uses the `exeldro` fork, which is recorded as such.

`INCLUDED` · `plugin` · `GPL-2.0-only` · `LIKELY` · risk `LOW`

### [Filter Hotkeys](06-Audio-and-Media/Filter-Hotkeys/TOOL_INFO.md)

Adds a filter that binds hotkeys to other filters on the same source: disable, enable, toggle or hold. Two Lua variants (video and audio). `STALE`; hotkeys are only deregistered after an OBS restart.

`INCLUDED` · `lua-script` · `MPL-2.0` · `UNKNOWN` · risk `LOW`

### [Tuna](06-Audio-and-Media/Tuna/TOOL_INFO.md)

Now-playing overlay data (title, artist, cover, progress) from Spotify, Last.fm, MPD or Windows media sessions, as text/image sources or a local HTTP endpoint. The bundled web server listens on `0.0.0.0:1608` with no authentication by default.

`INCLUDED` · `plugin` · `GPL-2.0-or-later` · `LIKELY` · risk `MEDIUM`

### [Multi-RTMP](07-Streaming/Multi-RTMP/TOOL_INFO.md)

Extra RTMP stream outputs, each with its own service, key and encoder. Pinned to `0.7.4` (OBS 32.0.0) on purpose: `0.7.4.1+` targets OBS 32.2.1 and will not load on 32.0.1. Keys are stored in the OBS profile.

`INCLUDED` · `plugin` · `GPL-2.0-or-later` · `LIKELY` · risk `MEDIUM`

### [OBS WebSocket](08-Remote-Control-and-AI/OBS-WebSocket/TOOL_INFO.md)

The API bundled with OBS 32.0.1 (version 5.6.3). Nothing to install; this entry pins the protocol documentation at the bundled version. Enable it only with authentication on and never expose port 4455.

`DOCS-ONLY` · `docs-only` · `GPL-2.0-or-later` · `SUPPORTED` · risk `MEDIUM`

### [OBS-MCP](08-Remote-Control-and-AI/OBS-MCP/TOOL_INFO.md)

A Model Context Protocol server that exposes OBS control as AI-callable tools over stdio, talking to the local WebSocket. Python 3.10+ as a separate process. Destructive tools exist; start read-only.

`INCLUDED` · `mcp-server` · `Apache-2.0` · `SUPPORTED` · risk `MEDIUM`


## 6. Recommended installation order

Do not install everything. Pick a path and stop when you have what you need.
Every step is: back up → install → restart OBS → confirm it loaded → use once →
continue.

### Beginner path (low risk, no external prerequisites)

| # | Tool | Why here |
|---|---|---|
| 1 | Advanced Timer | A pure Lua script with no I/O. If it loads, your Scripts workflow works and later failures are tool-specific. |
| 2 | Local Stream Marker | Second Lua script, adds a file write to a folder you choose. Proves the script can write where you expect. |
| 3 | Filter Hotkeys | Third Lua script, but needs real filters to exist first; by now you can tell a script bug from a setup mistake. |
| 4 | Source Record | First plugin, and the only `LOW`-risk plugin whose asset is publisher-verified with a valid Authenticode signature. |
| 5 | Shaderfilter | Second plugin, same zip layout. Adds the 165-example shader set; test one example, not all of them. |
| 6 | Advanced Scene Switcher | Biggest payoff, `MEDIUM` risk because macros can make HTTP calls and run programs. Install it after you are comfortable confirming plugin loads. |
| 7 | OBS WebSocket | `DOCS-ONLY`: enable only when a client needs it, with authentication on. |

### Advanced path (needs a prerequisite or accepts a real trade-off)

| # | Tool | Why here |
|---|---|---|
| 1 | OBS Counter | Proves the Python pipeline with the smallest script; needs `C:\Python38\python.exe` selected in Python Settings. |
| 2 | Multi-RTMP | Needs a second ingest and upload headroom; pin `0.7.4` or it will not load on OBS 32.0.1. |
| 3 | Tuna | Only if an overlay needs now-playing data; the web server listens on all interfaces unless you avoid it. |
| 4 | Autostarter | Only after your launch sequence is stable; it starts external programs with your rights, and it is `STALE`. |
| 5 | Advanced Filename Formatter | Blocked until a 3.10 x64 interpreter exists; templates are evaluated as code. |
| 6 | OBS Screen Studio | Source-only and polls the global cursor; use it on a dedicated scene, not a live show, until you trust it. |
| 7 | OBS-MCP | Last, because it hands OBS control to an AI client. Requires WebSocket, Python 3.10+, and a read-only-first policy. |
| — | Libre Macros | Not recommended. `HIGH` risk and `PENDING-USER`; only after an explicit decision and a password rotation. |

## 7. Installation quick reference

| Type | Where it goes | Guide |
|---|---|---|
| Lua script | Any folder you control; added via **Tools → Scripts → +** | `00-Documentation/INSTALLATION_GUIDE.md` §1 |
| Python script | Same, plus **Tools → Scripts → Python Settings** with a 64-bit 3.8–3.10 interpreter | `00-Documentation/INSTALLATION_GUIDE.md` §2 |
| Plugin (zip) | `obs-plugins\64bit\` + `data\obs-plugins\<name>\` under the OBS root | `00-Documentation/INSTALLATION_GUIDE.md` §3 |
| Plugin (installer) | Run it; it finds `C:\Program Files\obs-studio` | `00-Documentation/INSTALLATION_GUIDE.md` §3 |
| External app / MCP | Separate Python environment, started by the client | `00-Documentation/INSTALLATION_GUIDE.md` §4 |
| OBS WebSocket | Nothing to install; enable in **Tools → WebSocket Server Settings** | `00-Documentation/INSTALLATION_GUIDE.md` §5 |

## 8. Summaries of the other guides

### Security and privacy

Static review only: what the pinned source reads, writes, connects to and spawns.
One `HIGH` tool (Libre Macros: dynamic code execution and FFI process creation),
nine `MEDIUM`, six `LOW`. Two tools need a network decision: Tuna's local web
server (default `0.0.0.0:1608`, no auth) and OBS WebSocket (`127.0.0.1:4455`).
Full detail: `00-Documentation/SECURITY_GUIDE.md`.

### Updates

`Update-Library.ps1` checks GitHub releases read-only and caches the responses.
`-Apply -Tool <id>` downloads into a new versioned folder, verifies, and updates
the manifest and changelog. It never deletes an older version and never installs.
Re-check compatibility after every OBS upgrade:
`00-Documentation/UPDATE_GUIDE.md`.

### Backup and rollback

Back up `basic`, `plugin_config`, `plugin_manager` and `global.ini` from
`%APPDATA%\obs-studio` before the first install and before every upgrade.
Backups contain stream keys and tokens: store them outside this library and
encrypt them. `00-Documentation/OBS_BACKUP_GUIDE.md`.

### Top five troubleshooting items

1. A script that does not load: read the **Script Log** tab, not just the main log.
2. Python errors: the interpreter must be 64-bit and 3.8–3.10 for OBS 32.
3. A plugin that does not appear: wrong folder, wrong architecture, or built for a
   newer OBS major version.
4. OBS crashing after an install: remove the new DLL/data folder, start OBS, read
   the newest log.
5. WebSocket clients failing: server disabled, wrong port, wrong password, or a
   4.x client against the bundled 5.6.3 server.

Full list: `00-Documentation/TROUBLESHOOTING.md`.

## 9. Actions that need your approval

Nothing below was done by this library. Each line is an action that requires an
explicit "yes" from you, and each approval covers only that action.

**Advanced Scene Switcher**
- Installing the plugin or running its installer
- Allowing HTTP or WebSocket macro actions to reach the network
- Running external programs from 'Run' macro actions

**RSE OBS Scripts**
- Downloading or using an UNVERIFIED tool (license unresolved)
- Using auto-execute-commands.lua, which runs shell commands at OBS start and shutdown

**Libre Macros**
- Downloading or using a PENDING-USER tool rated HIGH
- Allowing the console to run dynamically supplied Lua code
- Allowing FFI process creation and the bundled WebSocket helper

**Autostarter**
- Installing the plugin
- Letting the plugin start external programs at OBS launch

**Advanced Timer**
- Installing the script

**OBS Counter**
- Installing the script and configuring OBS's Python path

**Advanced Filename Formatter**
- Installing the script
- Allowing the script's first-run pip install (network) or pre-installing pyparsing yourself

**Local Stream Marker**
- Installing the script

**Source Record**
- Installing the plugin

**OBS Screen Studio**
- Installing the script
- Allowing global cursor and mouse-button polling while OBS runs

**Shaderfilter**
- Installing the plugin
- Using the fork rather than the upstream project (already approved)

**Filter Hotkeys**
- Installing the script

**Tuna**
- Installing the plugin
- Enabling the local web server (listens on all interfaces by default)
- Connecting Spotify/Last.fm accounts and storing their tokens

**Multi-RTMP**
- Installing the plugin
- Configuring additional stream destinations (stream keys are stored in the OBS profile)

**OBS WebSocket**
- Enabling the WebSocket server
- Opening port 4455 in any firewall
- Connecting an external client

**OBS-MCP**
- Installing the Python dependencies
- Configuring an MCP client to control OBS
- Letting the AI client start/stop streams or delete scenes


Also requiring approval: installing or changing Python, installing any package,
opening a firewall port, and any system-level change such as enabling Windows
long paths.

## 10. Unverified, unavailable and incompatible projects

### Quarantined or awaiting a decision

### [RSE OBS Scripts](10-Unverified/RSE-OBS-Scripts/TOOL_INFO.md) — `UNVERIFIED`

The repository has no LICENSE or COPYING file; every .lua header only says 'Distributed under MIT license'. A license claim without the license text cannot be confirmed for the collection, so the tool is metadata-only in 10-Unverified.

Location: `10-Unverified/RSE-OBS-Scripts`

### [Libre Macros](10-Unverified/Libre-Macros/TOOL_INFO.md) — `PENDING-USER`

Security review rated HIGH: the console compiles and runs dynamic code (console.lua:968, :1783), uses FFI CreateProcessA (console.lua:529-555), and a bundled helper script contains a hardcoded WebSocket password. Moved to 10-Unverified pending an explicit user decision.

Location: `10-Unverified/Libre-Macros`

### [OBS WebSocket](08-Remote-Control-and-AI/OBS-WebSocket/TOOL_INFO.md) — `DOCS-ONLY`

Bundled with OBS since version 28 and already present in the detected OBS 32.0.1 (submodule commit 1c9306b1 equals tag 5.6.3). No binary is downloaded; only the protocol documentation at the matching tag is snapshotted.

Location: `08-Remote-Control-and-AI/OBS-WebSocket`


### Unavailable

None. Every repository in the registry resolved to an official GitHub repository
at research time.

### Incompatible or pinned

| Item | Reason |
|---|---|
| Multi-RTMP `0.7.4.1` and newer | Built against OBS 32.2.1; OBS 32.0.1 refuses to load it. This library pins `0.7.4`. |
| Advanced Scene Switcher `windows-x64.zip` | Documented as OBS 33+ only. Use the installer or the `obs32` zip on the detected OBS. |
| Advanced Filename Formatter Replay Buffer features | Require OBS 33.0.0 or newer; unavailable on 32.0.1. |
| Advanced Filename Formatter on this machine | Needs Python 3.10; no 3.10 x64 interpreter is installed. |
| Libre Macros | `PENDING-USER`, `HIGH` risk; not downloaded as an asset (the release has none). |

## Verification and provenance

- `MANIFEST.json` is the single source of truth; every table above was generated
  from it.
- `11-Checksums/SHA256SUMS.txt` covers every asset, every `Documentation/` file,
  the manifest and the schema. Source trees are identified by commit SHA, not by
  file hashes, because GitHub source archives are not byte-stable.
- `11-Checksums/VERIFICATION_REPORT.md` explains what each verification status
  proves and does not prove.
- `13-Logs/execution.log` is the append-only record of every operation.
- `13-Logs/obs-baseline.json` is the OBS tripwire baseline; `FINAL_REPORT.md`
  records the comparison.
