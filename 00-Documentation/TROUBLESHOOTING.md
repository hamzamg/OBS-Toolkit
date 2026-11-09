# Troubleshooting

Symptoms, causes, and the shortest check for each. Start with the OBS log:
**Help → Log Files → View Current Log**. It records which modules loaded and
which failed.

Log location: `%APPDATA%\obs-studio\logs\` (installed) or
`<root>\config\obs-studio\logs\` (portable).

## Top five

1. **Script does not load** — read the Script Log tab, not just the main log.
2. **Python not found / wrong version** — **Tools → Scripts → Python Settings**;
   must be 64-bit and 3.8–3.10 for OBS 32.
3. **Plugin does not appear** — wrong folder, wrong architecture, or built for a
   newer OBS major version.
4. **OBS crashes after an install** — remove the new DLL, start OBS, read the log.
5. **WebSocket client cannot connect** — server disabled, wrong port, wrong
   password, or client protocol mismatch.

---

## Scripts

### The script is not in the list after `+`

- The picker filters by extension. Use **All files** and select the exact file.
- OBS 32's script list shows the file name, not the script description. Scroll.
- If the file is on a network share, copy it local; OBS may fail to read it.

### "attempt to index a nil value"

The script expects a source, group, or setting that does not exist yet.

1. Create the target (for example a text source) first.
2. Remove and re-add the script so `script_load` runs again.
3. Check the script's own README for required preconditions. Filter Hotkeys, for
   example, requires the real filters to exist **before** the hotkey filter is
   added.

### Script loads but does nothing

- Hotkeys are not bound: **Settings → Hotkeys**, search for the script name.
- The script needs OBS to have focus for its hotkeys.
- A required setting is empty (target source, output folder).
- The Script Log may show a caught error only when the action runs — trigger it
  and re-read the log.

### Script settings disappeared

Script properties are stored in the **scene collection**. Switching collections,
or restoring an older one, changes them. Restore the collection that had the
settings.

### "attempt to call a nil value (field 'ffi')"

The script needs LuaJIT FFI. OBS 32 ships LuaJIT, so this usually means the script
was loaded into a different Lua host. Load it through OBS, not a standalone Lua.

### OBS crashes when the script loads

A property value can crash OBS. Local Stream Marker documents this for an invalid
`Datetime Format`.

1. Close OBS.
2. Restore the scene collection from backup (or remove the script entry from a
   copy of the collection).
3. Re-add the script and leave the default values.

---

## Python

### Python Settings tab is missing

The OBS build has no Python support. Reinstall OBS with the Python component.
This library does not modify OBS.

### "Python not found" or the path is rejected

- The path must point at `python.exe` (or `python3.exe`), not a folder.
- It must be **64-bit** for 64-bit OBS. Check:

```powershell
& 'C:\Python38\python.exe' -c "import sys,platform;print(sys.version);print(platform.architecture())"
```

- It must be inside OBS 32's range: **3.8 ≤ version < 3.11**. 3.12+ is rejected.

### `ModuleNotFoundError: No module named 'obspython'`

OBS injects `obspython`. Seeing this error means the script was run outside OBS,
or the interpreter is not the one OBS configured. Load it through **Tools →
Scripts**.

### `ModuleNotFoundError` for a third-party package

The package is missing from the **selected** interpreter, not from your system
Python. Install it into that interpreter (an action that needs your approval):

```powershell
& 'C:\Python38\python.exe' -m pip install <package>
```

### Advanced Filename Formatter needs 3.10

OBS 32 accepts 3.8–3.10 and the script requires 3.10+. No 3.10 x64 interpreter is
installed on this machine. Either install one (approval needed) or skip the tool.
Do not upgrade `C:\Python38` to 3.10 if other scripts depend on 3.8.

---

## Plugins

### The plugin does not appear anywhere

Check, in order:

1. **Architecture** — a `32bit` DLL in `obs-plugins\64bit\` never loads. Use the
   `64bit` file.
2. **Folder** — the DLL must be in `obs-plugins\64bit\`, not in
   `obs-plugins\` or `data\`.
3. **Data folder** — some plugins need `data\obs-plugins\<name>\` (locale files,
   effects, examples). Without it the UI may be blank or the plugin may fail.
4. **OBS major version** — a plugin built against a newer OBS than yours is
   refused. `COMPATIBILITY.md` lists build targets.
5. **Log** — search for the plugin name. "Failed to load" plus a module name is
   the clearest signal.

### "not a valid Win32 application"

Architecture mismatch, or a truncated download. Re-verify the hash with
`12-Utilities\Verify-Checksums.ps1`.

### OBS crashes at startup after an install

1. Close OBS (check Task Manager for `obs64.exe`).
2. Move the new DLL out of `obs-plugins\64bit\` and its data folder out of
   `data\obs-plugins\`.
3. Start OBS. If it starts, the plugin is the cause.
4. Read the newest log for the exception. If OBS 32 offers **Help → Safe Mode** at
   startup, use it to load without third-party plugins.
5. Try the previous version from this library, or leave the tool uninstalled.

### A plugin loads but its dock/menu item is missing

Some plugins add a **Docks** entry rather than a **Tools** entry, and some only
appear when a source of the right type exists. Check the tool's `TOOL_INFO.md`
section 8 for where its UI is documented.

### Multi-RTMP refuses to load

The pinned version `0.7.4` is built against OBS 32.0.0. Releases `0.7.4.1` and
newer pin OBS 32.2.1 and will not load on 32.0.1. Do not upgrade the plugin until
OBS is 32.2.1 or newer.

---

## WebSocket

### Client cannot connect

Check each of these:

1. **Server enabled?** **Tools → WebSocket Server Settings**. The dialog says
   whether it is running.
2. **Port** — default 4455. Confirm what is listening:

```powershell
Get-NetTCPConnection -LocalPort 4455 -ErrorAction SilentlyContinue |
  Select-Object LocalAddress,LocalPort,State
```

1. **Password** — authentication is on by default; a wrong password looks like a
   connection failure in most clients.
2. **Firewall** — a local connection to `127.0.0.1` does not need a rule. If you
   are connecting from another machine, stop: do not open the port. Use a local
   client instead.
3. **Protocol version** — clients written for WebSocket 4.x do not speak 5.x.
   OBS 32 bundles 5.6.3; see
   `08-Remote-Control-and-AI/OBS-WebSocket/Documentation/protocol.md`.

### "Connection closed" immediately after authenticating

Usually a client protocol mismatch or a second client with the same session.
Close other clients and retry.

---

## Version incompatibilities

| Symptom | Cause | Fix |
|---|---|---|
| Plugin loads on OBS 31 but not 32 | Built for an older API and not rebuilt | Use a release built for 32, or skip |
| Plugin built for 32.2.1 does not load on 32.0.1 | OBS refuses newer plugin API | Pin the older release (Multi-RTMP `0.7.4`) |
| Python script fails after an OBS upgrade | OBS's Python range changed | Re-check the range for the new OBS |
| Lua script fails after an OBS upgrade | API change | Check the project for a newer release |

After any OBS major upgrade, re-run `12-Utilities\Get-OBSInfo.ps1` and re-check
`COMPATIBILITY.md` before reinstalling anything.

---

## Utilities

### "running scripts is disabled on this system"

Use a process-scoped bypass; do not change the machine policy:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\12-Utilities\Test-Library.ps1
```

### `Verify-Checksums.ps1` exits 1

It found a missing, extra, or mismatched file. Read its dated report in
`13-Logs\`; the first mismatch is usually the real problem.

### Long path errors

Extract or clone to a shorter root such as `C:\OBS-Toolkit`. See
`WINDOWS_SETUP.md`.

## Related guides

- `INSTALLATION_GUIDE.md`
- `OBS_SCRIPTING_GUIDE.md`
- `SECURITY_GUIDE.md`
- `COMPATIBILITY.md`
