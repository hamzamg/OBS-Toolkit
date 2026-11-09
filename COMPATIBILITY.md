# Compatibility

Generated from `MANIFEST.json` on 2026-11-09T17:35:51Z. Detected target: **OBS Studio 32.0.1 x64**, non-portable, `C:\Program Files\obs-studio`.

**Plugin binaries are tied to OBS major versions.** A plugin built for a newer OBS than the one
you run is refused, and a plugin built for an older major version usually loads but is not
guaranteed to work. Re-check this table after **every** OBS upgrade.

## Matrix

| Tool | Detected OBS | Documented range | Win 11 x64 | Arch | Python / Lua | Dependencies | Status |
|---|---|---|---|---|---|---|---|
| Advanced Scene Switcher | `32.0.1` | 31.1.1 – 33 | `SUPPORTED` | x64 DLL | n/a | libcurl, Qt 6 (provided by OBS) | `SUPPORTED` |
| RSE OBS Scripts | `32.0.1` | UNKNOWN | `UNKNOWN` | n/a (script) | Lua: 5.1 (LuaJIT) | OBS Lua API (obslua) | `UNKNOWN` |
| Libre Macros | `32.0.1` | 27 – not documented | `LIKELY` | n/a (script) | Python: 3.8-3.10 (OBS 32 range) for the optional Python helpers<br>Lua: 5.1 (LuaJIT) | OBS Lua API (obslua), LuaJIT FFI, Python 3 | `SUPPORTED` |
| Autostarter | `32.0.1` | 30.1.2 – not documented | `SUPPORTED` | x64 DLL | n/a | Qt 6 (provided by OBS) | `SUPPORTED` |
| Advanced Timer | `32.0.1` | UNKNOWN | `LIKELY` | n/a (script) | Lua: 5.1 (LuaJIT) | OBS Lua API (obslua) | `UNKNOWN` |
| OBS Counter | `32.0.1` | 28 – not documented | `LIKELY` | n/a (script) | Python: 3.8-3.10 (OBS 32 range) | OBS Python API (obspython) | `LIKELY` |
| Advanced Filename Formatter | `32.0.1` | UNKNOWN | `SUPPORTED` | n/a (script) | Python: >=3.10 and <3.11 (script requires 3.10+; OBS 32 supports 3.8<=v<3.11) | pyparsing, OBS Python API (obspython) | `SUPPORTED` |
| Local Stream Marker | `32.0.1` | UNKNOWN | `LIKELY` | n/a (script) | Lua: 5.1 (LuaJIT) | OBS Lua API (obslua) | `UNKNOWN` |
| Source Record | `32.0.1` | 29.0.0 – not documented | `SUPPORTED` | x64 DLL | n/a | none | `LIKELY` |
| OBS Screen Studio | `32.0.1` | 28.0.0 – not documented | `LIKELY` | n/a (script) | Lua: 5.1 with LuaJIT FFI | LuaJIT FFI (provided by OBS) | `SUPPORTED` |
| Shaderfilter | `32.0.1` | 28.0.0 – not documented | `SUPPORTED` | x64 DLL | n/a | none | `LIKELY` |
| Filter Hotkeys | `32.0.1` | UNKNOWN | `LIKELY` | n/a (script) | Lua: 5.1 (LuaJIT) | OBS Lua API (obslua) | `UNKNOWN` |
| Tuna | `32.0.1` | 31.1.0 – not documented | `SUPPORTED` | x64 DLL | n/a | cpp-httplib, Qt 6 (provided by OBS), TagLib, libmpdclient, libcurl | `LIKELY` |
| Multi-RTMP | `32.0.1` | 32.0.0 – not documented | `SUPPORTED` | x64 DLL | n/a | nlohmann/json, Qt 6 (provided by OBS) | `LIKELY` |
| OBS WebSocket | `32.0.1` | 28.0.0 – not documented | `SUPPORTED` | n/a | n/a | none | `SUPPORTED` |
| OBS-MCP | `32.0.1` | 28.0.0 – not documented | `SUPPORTED` | n/a (Python) | Python: >=3.10 (external process, not the OBS-embedded interpreter) | mcp[cli], obsws-python, Python | `SUPPORTED` |

### Status words

| Status | Meaning |
|---|---|
| `SUPPORTED` | The publisher documents this OBS version, or the tool ships inside it |
| `LIKELY` | Built for an older OBS; no documented break, not runtime-tested here |
| `UNKNOWN` | No evidence either way |
| `INCOMPATIBLE` | Documented to require a different OBS |

## Per-tool notes and limitations

### Advanced Scene Switcher

`SUPPORTED` — Use the installer for OBS 32. The windows-x64.zip asset is documented as OBS 33+ only; the windows-x64-obs32.zip is the zip alternative for OBS 32.

- Release notes: the minimum supported OBS version is 31.1.1; the installer supports both OBS 32 and OBS 33. — `01-Scene-Management/Advanced-Scene-Switcher/Documentation/RELEASE_NOTES_1.37.2.md`
- buildspec.json pins obs-studio 31.1.1. — `01-Scene-Management/Advanced-Scene-Switcher/Source/1.37.2/buildspec.json`
- The detected OBS is 32.0.1 x64 on Windows 11. — `13-Logs/obs-baseline.json`

### RSE OBS Scripts

`UNKNOWN` — No release and no statement of a supported OBS range. Last commit predates OBS 31.

- Scripts use the OBS Lua API (obslua) only; OBS 32 ships Lua 5.1. — `10-Unverified/RSE-OBS-Scripts/Source/59191d2ca89b1c7affd6f440da8a4b780d53c5ae/auto-execute-commands.lua`

### Libre Macros

`SUPPORTED` — Compatibility is not the blocker; the security rating is.

- README states OBS 27 or newer. — `10-Unverified/Libre-Macros/Documentation/README.snapshot.md`
- The console and helpers are Lua 5.1 / LuaJIT and Python; OBS 32 provides both. — `10-Unverified/Libre-Macros/Source/4.2.0/console.lua`

### Autostarter

`SUPPORTED` — Built against OBS 30.1.2; OBS 32.0.1 is newer and accepts plugins built for older versions.

- README requires OBS Studio 30.1.2 or later. — `02-Scripting-and-Automation/Autostarter/Documentation/README.snapshot.md`
- buildspec.json pins obs-studio 30.1.2. — `02-Scripting-and-Automation/Autostarter/Source/v2.1.0/buildspec.json`

### Advanced Timer

`UNKNOWN` — No documented OBS range. Last release 2023-04-11, before OBS 30; nothing in the script depends on a removed API.

- The script uses only the OBS Lua API (obs.timer_add, obs.hotkey) and is platform-neutral. — `03-Timers-and-Counters/Advanced-Timer/Source/6.0.0/advanced-timer.lua`

### OBS Counter

`LIKELY` — Only C:\Python38 is inside the OBS 32 range on this machine.

- README states OBS 28 or newer and a working OBS Python installation. — `03-Timers-and-Counters/OBS-Counter/Documentation/README.snapshot.md`
- OBS 32 supports Python 3.8 <= v < 3.11 on Windows. — `https://github.com/obsproject/obs-studio/blob/32.0.1/shared/obs-scripting/cmake/python.cmake`

### Advanced Filename Formatter

`SUPPORTED` — On this machine no 3.10 interpreter is installed (3.8, 3.12-3.15). OBS's Python path must point at a 3.10 x64 build before the script can load.

- README requires Python 3.10 or newer. — `04-Recording-and-Organization/Advanced-Filename-Formatter/Documentation/README.snapshot.md`
- OBS 32 supports Python 3.8 <= v < 3.11 on Windows, so 3.10 is the only in-range version that satisfies the script. — `https://github.com/obsproject/obs-studio/blob/32.0.1/shared/obs-scripting/cmake/python.cmake`

### Local Stream Marker

`UNKNOWN` — No documented OBS range. Release is recent (2026-06-13).

- The script uses the OBS Lua API and os.date/os.time only. — `04-Recording-and-Organization/Local-Stream-Marker/Source/v1.13/local-stream-marker.lua`

### Source Record

`LIKELY` — Built against OBS 29; OBS 32.0.1 accepts plugins built for older versions. Re-check after each OBS major upgrade.

- buildspec.json pins obs-studio 29.0.0-beta1; the release ships a Windows x64 DLL. — `04-Recording-and-Organization/Source-Record/Source/0.4.8/buildspec.json`
- Both DLLs carry a valid Authenticode signature from CN=Exeldro. — `04-Recording-and-Organization/Source-Record/Checksums.txt`

### OBS Screen Studio

`SUPPORTED` — No release and no tag; the snapshot is the only artifact. Re-pin before installing if the branch moves.

- README states OBS 28+ and requires the LuaJIT FFI that OBS ships. — `05-Screen-Production/OBS-Screen-Studio/Documentation/README.snapshot.md`
- The script branches on ffi.os == 'Windows' and calls user32 GetCursorPos/GetKeyState. — `05-Screen-Production/OBS-Screen-Studio/Source/5739bc01f0d503f08b3fb21ddbfebfd42d387dcf/obs-screen-studio.lua:126-135`

### Shaderfilter

`LIKELY` — Built against OBS 28; OBS 32 accepts older plugin builds. Re-check after an OBS major upgrade.

- buildspec.json pins obs-studio 28.0.0-beta1; the release ships Windows 32/64-bit DLLs. — `05-Screen-Production/Shaderfilter/Source/2.6.1/buildspec.json`
- OBS 32.0.1 detected on Windows 11 x64. — `13-Logs/obs-baseline.json`

### Filter Hotkeys

`UNKNOWN` — No documented OBS range; last release 2021, last commit 2024. Treat as STALE and re-test after OBS upgrades.

- The script uses only the OBS Lua API (obs_hotkey_register_source). — `06-Audio-and-Media/Filter-Hotkeys/Source/1.0.2/filter_hotkeys_video.lua`

### Tuna

`LIKELY` — Built against OBS 31.1.0; OBS 32 accepts older plugin builds.

- buildspec.json pins obs-studio 31.1.0; the release ships a Windows x64 zip. — `06-Audio-and-Media/Tuna/Source/1.9.12/buildspec.json`
- OBS 32.0.1 detected on Windows 11 x64. — `13-Logs/obs-baseline.json`

### Multi-RTMP

`LIKELY` — Do not upgrade to 0.7.4.1+ until OBS is 32.2.1 or newer. OBS refuses plugins built for a newer version.

- buildspec.json pins obs-studio 32.0.0; OBS 32.0.1 is a patch release in the same series. — `07-Streaming/Multi-RTMP/Source/0.7.4/buildspec.json`
- Releases 0.7.4.1 and newer pin obs-studio 32.2.1, which OBS 32.0.1 refuses. — `13-Logs/phase1-report.md`

### OBS WebSocket

`SUPPORTED` — No installation needed; enable it in OBS under Tools > WebSocket Server Settings.

- OBS 32.0.1's obs-websocket submodule commit is 1c9306b1e200704ebe192e06c893dfc06b097c43, equal to tag 5.6.3. — `13-Logs/cache/api/obs-studio-32.0.1__ws_submodule.json`
- Protocol snapshot matches the bundled version. — `08-Remote-Control-and-AI/OBS-WebSocket/Documentation/protocol.md`

### OBS-MCP

`SUPPORTED` — Runs as a separate Python process started by the AI client, so the OBS 3.8-3.10 limit does not apply; any installed 3.10+ x64 interpreter works.

- pyproject.toml requires Python >=3.10 and depends on mcp[cli]>=1.0.0 and obsws-python>=1.7.0. — `08-Remote-Control-and-AI/OBS-MCP/Source/v0.2.0/pyproject.toml`
- INSTALLATION.md documents OBS WebSocket on localhost:4455 and stdio transport. — `08-Remote-Control-and-AI/OBS-MCP/Source/v0.2.0/INSTALLATION.md`

## Runtime environment on this machine

| Item | Value |
|---|---|
| OBS | 32.0.1 x64, portable=False |
| OBS Lua | 5.1 (LuaJIT) |
| OBS Python range | >=3.8,<3.11 |
| Bundled OBS WebSocket | 5.6.3 |
| Installed Python | 3.15 (x64); 3.14 (x64); 3.13 (x64); 3.12 (x64); 3.8 (x64) at C:\Python38; 3.8 (x86) |

Only `C:\Python38` falls inside the OBS 32 range. The interpreter OBS is actually configured to
use lives in `global.ini`, which this audit does not open; run
`12-Utilities\Get-OBSInfo.ps1` or read **Tools → Scripts → Python Settings** to confirm it.

## Upgrade checklist

1. Note the new OBS version.
2. For every installed plugin, find its build target in this file; if the plugin targets a
   version newer than the new OBS, do not install it.
3. Re-check the Python range; OBS has changed it between majors.
4. Re-check Lua/FFI availability if a script uses `ffi`.
5. Update `MANIFEST.json` only after re-verifying the new assets.
