# Installation Guide

This is the canonical guide for installing the tools in this library. Each
`TOOL_INFO.md` repeats the short version for its own tool and links here for the
general rules. **This library installs nothing** — every step below is yours to
run, later, by hand.

Detected environment (read-only, Phase 0):

| Item | Value |
|---|---|
| OBS Studio | 32.0.1, x64, non-portable |
| Install directory | `C:\Program Files\obs-studio` |
| OBS Lua | 5.1 (LuaJIT) |
| OBS Python range | 3.8 ≤ version < 3.11 (64-bit only) |
| Bundled OBS WebSocket | 5.6.3 |

## The three rules that apply to every section

1. **Back up first.** Follow `OBS_BACKUP_GUIDE.md`. A plugin can prevent OBS from
   starting; a scene-collection backup is how you get back to a working state.
2. **Install one tool at a time.** Restart OBS, confirm the tool loaded, use it
   once, then continue. Two new tools at once make a failure ambiguous.
3. **Keep the library as the source of truth.** Install from
   `<Tool>\Downloads\<version>\`, not from a file you found elsewhere. Re-verify
   with `12-Utilities\Verify-Checksums.ps1` before you copy anything into OBS.

## Where OBS keeps things

### Installed OBS (the detected case)

```
C:\Program Files\obs-studio\
├── bin\64bit\obs64.exe
├── obs-plugins\64bit\           <- plugin DLLs go here
└── data\obs-plugins\<name>\     <- plugin data (locale, effects, examples)

%APPDATA%\obs-studio\            <- per-user configuration
├── global.ini                   <- do not open; this audit does not read it
├── basic\profiles\              <- profiles (stream settings, output settings)
├── basic\scenes\                <- scene collections (sources, filters, script settings)
├── plugin_config\               <- per-plugin settings (may contain secrets)
└── logs\                        <- OBS logs
```

Writing to `C:\Program Files\obs-studio` needs an elevated shell (or the
installer's own UAC prompt). The `%APPDATA%` folder is writable by your user.

### Portable OBS

```
<portable root>\
├── bin\64bit\obs64.exe
├── obs-plugins\64bit\
├── data\obs-plugins\<name>\
└── config\obs-studio\           <- per-user configuration lives inside the tree
```

The relative layout is identical, so any zip whose root is
`obs-plugins\` + `data\` extracts cleanly into either root. A tool that ships an
installer may only know the system path; extract the zip instead.

### Per-user plugin layout

Recent OBS versions can also load a plugin from
`%APPDATA%\obs-studio\plugins\<name>\bin\64bit\<plugin>.dll` with data in
`%APPDATA%\obs-studio\plugins\<name>\data\`. This is convenient because it needs
no administrator rights, but **it was not verified against the official OBS
documentation for 32.0.1 from this machine** (`docs.obsproject.com` was
unreachable during the audit). Prefer the install-directory layout unless you
have confirmed the per-user path works in your build. The same caution applies
to the `ProgramData` layout (`C:\ProgramData\obs-studio\plugins\<name>\bin\64bit`).

---

## 1. Lua scripts

Tools in this category: Advanced Timer, Local Stream Marker, Filter Hotkeys,
OBS Screen Studio, RSE OBS Scripts, Libre Macros.

### Prerequisites

- OBS 32.0.1 ships Lua 5.1 (LuaJIT). Scripts that need FFI (OBS Screen Studio)
  depend on that build; do not substitute a different Lua.
- A folder you control for scripts, for example
  `%USERPROFILE%\Documents\OBS-Scripts\`. Never put downloaded files inside
  `%APPDATA%\obs-studio\`.

### Steps

1. Back up (`OBS_BACKUP_GUIDE.md`).
2. Copy the `.lua` file(s) from the tool's `Downloads\<version>\` (or its pinned
   `Source\<ref>\` when the tool has no release asset) into your scripts folder.
3. In OBS: **Tools → Scripts → Scripts tab → +** and select the file.
4. Open the **Script Log** tab and confirm there is no error.
5. Configure the script's properties, then **Apply**.

### Confirm it loaded

- The script appears in the Scripts list without a red error.
- The Script Log shows no `attempt to index a nil value`, `module not found`, or
  syntax error.
- The script's properties panel renders.

### Uninstall and rollback

1. **Tools → Scripts**, select the script, click **−**.
2. Delete the `.lua` file if you no longer want it.
3. Script settings live in the scene collection, so restoring a backed-up
   collection restores the previous configuration.

---

## 2. Python scripts

Tools in this category: OBS Counter, Advanced Filename Formatter.

### Prerequisites

- **64-bit Python for 64-bit OBS.** A 32-bit interpreter will not load.
- The interpreter must be inside the range the *detected* OBS supports:
  **3.8 ≤ version < 3.11**. On this machine only `C:\Python38\python.exe`
  qualifies (3.12, 3.13, 3.14, 3.15 are too new; the 3.8 x86 install is the wrong
  architecture).
- Advanced Filename Formatter additionally requires **3.10 or newer**, so on OBS
  32 it needs a 3.10 x64 interpreter, which is **not installed**. That is a
  blocking prerequisite, not a bug.

### Steps

1. Back up the scene collection.
2. Copy the `.py` file from `Downloads\<version>\` (or `Source\<ref>\`) into your
   scripts folder.
3. In OBS: **Tools → Scripts → Python Settings**. Select the interpreter path.
   If the Python Settings tab is missing, the OBS build has no Python support —
   reinstall OBS with the Python component.
4. **Scripts tab → +** and select the `.py` file.
5. Configure the properties and **Apply**.

### Confirm it loaded

- The Script Log shows no `ImportError`, `ModuleNotFoundError`, or
  architecture error.
- The properties panel renders and the script's controls respond.

### Uninstall and rollback

1. **Tools → Scripts**, select the script, click **−**.
2. Delete the `.py` file.
3. If the script installed packages into OBS's interpreter, remove them only if
   nothing else uses that interpreter.

### Notes on OBS's embedded Python

OBS embeds its own Python runtime loader. Changing the interpreter path does not
change the system `PATH`, and installing packages with `pip` into that
interpreter affects every script that uses it. Prefer a dedicated 3.10 x64
interpreter for Advanced Filename Formatter rather than upgrading `C:\Python38`.

---

## 3. Plugins (C/C++ DLL)

Tools in this category: Advanced Scene Switcher, Autostarter, Source Record,
Shaderfilter, Tuna, Multi-RTMP.

### Prerequisites

- Match the architecture: `64bit` DLL into 64-bit OBS.
- Match the OBS major version. A plugin built against a newer OBS than the one
  you run will be refused. `COMPATIBILITY.md` records the build target for each
  plugin.
- Close OBS before copying files. A loaded DLL cannot be replaced.

### Two archive shapes — do not assume one

**Shape A — installer (`.exe`)**

Advanced Scene Switcher ships an installer. Run it, let it detect
`C:\Program Files\obs-studio`, and accept the UAC prompt. Check the release notes
for which OBS versions the installer supports before running it.

**Shape B — plain zip**

Most plugins ship a zip with one of two internal layouts:

```
# Layout 1: OBS-relative (Source Record, Shaderfilter, Multi-RTMP)
obs-plugins/64bit/<plugin>.dll
data/obs-plugins/<plugin>/...

# Layout 2: flattened (Autostarter)
autostarter.dll

# Layout 3: vendor root (Tuna)
tuna/tuna.dll
tuna/data/...
```

Extract Layout 1 into the OBS root. For Layout 2, copy the DLL into
`obs-plugins\64bit\`. For Layout 3, copy `tuna\tuna.dll` to
`obs-plugins\64bit\` and the *contents* of `tuna\data\` to
`data\obs-plugins\tuna\`.

### Steps

1. Back up.
2. Close OBS completely (check Task Manager for `obs64.exe`).
3. Extract or run the installer as described above.
4. Start OBS.
5. Read **Help → Log Files → View Current Log** and search for the plugin name.

### Confirm it loaded

- The log contains a line loading the module, with no "Failed to load" or
  "not a valid Win32 application".
- The plugin's UI appears where the README says it should (a dock, a filter
  entry, or a Tools menu item).
- For a filter plugin: add a filter to a test source and look for the entry.

### Uninstall and rollback

1. Close OBS.
2. Delete the DLL from `obs-plugins\64bit\` and the folder from
   `data\obs-plugins\<plugin>\`. If an installer was used, prefer its uninstaller.
3. Start OBS and confirm the module is gone from the log.
4. Rollback: reinstall the previous version from this library's
   `Downloads\<old-version>\`, or restore your own backup of the two paths.

---

## 4. External applications and servers

Tool in this category: OBS-MCP (a Python MCP server run as a separate process).

### Prerequisites

- Python 3.10 or newer as a **separate** interpreter. The OBS 3.8–3.10 limit
  applies only to OBS's embedded interpreter.
- OBS WebSocket enabled locally with a password (see section 5).

### Steps (not performed by this library)

1. Create an isolated environment in a folder you control:
   `python -m venv .venv`, then activate it.
2. Install from the pinned snapshot:
   `pip install -e "08-Remote-Control-and-AI\OBS-MCP\Source\v0.2.0"`.
   Installing packages is an action that needs your approval.
3. Add an MCP client entry that starts the server over stdio and passes
   `OBS_HOST=127.0.0.1`, `OBS_PORT=4455`, and `OBS_PASSWORD` from the client's
   environment block. Never commit real credentials.
4. Test a read-only tool before enabling anything destructive.

### Confirm it loaded

- The MCP client lists the OBS tools.
- A read-only call (for example "get version") succeeds.
- The OBS WebSocket log shows the client connected from `127.0.0.1`.

### Uninstall and rollback

1. Remove the client entry.
2. Delete the virtual environment.
3. Rotate the WebSocket password if it was stored in a config file.

---

## 5. OBS WebSocket (DOCS-ONLY)

OBS 32.0.1 bundles OBS WebSocket 5.6.3. There is nothing to install.

1. **Tools → WebSocket Server Settings**.
2. Leave the server **off** until a client needs it.
3. When enabled: keep authentication on, use a unique strong password, and leave
   the port at 4455 unless it is taken.
4. Confirm the dialog shows "Server running" and a client connects on
   `127.0.0.1:4455`.

Never forward port 4455, never expose it through a tunnel, and never bind it to a
public interface. See `SECURITY_GUIDE.md`.

---

## 6. Checking that a plugin did not break OBS

If OBS crashes or hangs right after an install:

1. Close OBS.
2. Move the new DLL out of `obs-plugins\64bit\` (and its data folder out of
   `data\obs-plugins\`).
3. Start OBS. If it starts, the plugin is the cause; the version is probably
   incompatible. Check `COMPATIBILITY.md` and the plugin's release notes.
4. If OBS still fails, read the newest file in `%APPDATA%\obs-studio\logs\`.
   OBS 32 also offers **Help → Safe Mode** at startup, which loads without
   third-party plugins.

## Related guides

- `OBS_BACKUP_GUIDE.md` — what to back up and how to restore.
- `OBS_SCRIPTING_GUIDE.md` — how OBS loads scripts and how to debug them.
- `SECURITY_GUIDE.md` — how to review a script before you load it.
- `TROUBLESHOOTING.md` — when something does not appear or does not load.
- `COMPATIBILITY.md` — per-tool OBS range and architecture.
