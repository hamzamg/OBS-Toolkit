# OBS Scripting Guide

How OBS Studio loads Lua and Python scripts, how to tell whether a script loaded,
and how to debug one. This is background for the script tools in this library:
Advanced Timer, Local Stream Marker, Filter Hotkeys, OBS Screen Studio,
RSE OBS Scripts, Libre Macros (Lua) and OBS Counter, Advanced Filename Formatter
(Python).

Official documentation: <https://docs.obsproject.com/scripting> and
<https://docs.obsproject.com/reference-scripting> — these were **unreachable from
the audit machine**, so the statements below come from the detected OBS build and
from the pinned script sources, not from the docs site.

## Where scripts live

OBS does not copy scripts into its own tree. A script is referenced by absolute
path from the scene collection, so:

- Keep scripts in a folder you control, for example
  `%USERPROFILE%\Documents\OBS-Scripts\`.
- Moving or deleting the file breaks the scene collection's reference; OBS shows
  the script as missing.
- The script's saved properties live in the **scene collection**, not next to the
  script. Back up the collection before you change script settings.

## The Scripts window

**Tools → Scripts** has three tabs:

| Tab | Purpose |
|---|---|
| Scripts | Add (`+`), remove (`−`), reorder, and open a script's properties |
| Script Log | Errors and messages from the scripts in the current session |
| Python Settings | The interpreter path and the Python install used by OBS |

The `+` button opens a file picker. Select a `.lua` or `.py` file. OBS adds it to
the list and runs its `script_load` immediately.

## How loading works

### Lua

- OBS embeds **Lua 5.1 with LuaJIT**. `jit`, `ffi` and `bit` are available.
- OBS calls `script_description()`, then `script_defaults(settings)`, then
  `script_load(settings)`, then `script_update(settings)` on every change.
- `script_properties()` builds the properties panel.
- `script_save(settings)` is called when OBS saves the collection.
- `script_unload()` runs when the script is removed or OBS exits.
- A syntax error stops the script at load and appears in the Script Log with a
  line number.

### Python

- OBS loads scripts through its own embedded Python **3.x** build. On OBS 32 the
  supported range is **3.8 ≤ version < 3.11**, 64-bit only.
- OBS imports the file as a module and calls `script_description()`,
  `script_defaults`, `script_load`, `script_update`, `script_properties`,
  `script_save`, and `script_unload`.
- The `obspython` module is injected by OBS; you do not install it.
- If Python Settings points at a missing or wrong-architecture interpreter, every
  Python script fails with a load error and the Script Log says why.

## Confirm a script loaded

1. The name appears in the **Scripts** tab without an error icon.
2. The **Script Log** tab is empty or shows only informational messages.
3. The properties panel opens when you select the script.
4. The behaviour you expect happens once (a timer ticks, a counter changes, a
   hotkey appears under **Settings → Hotkeys**).

## Reload behavior

- Removing and re-adding a script is the reliable reload. Editing the file on disk
  does not reload it.
- Some scripts register hotkeys and unregister them only at OBS exit (Filter
  Hotkeys documents this). A full OBS restart is the only clean reset.
- Scripts that hold OS resources (file handles, FFI calls) may not release them on
  unload. Restart OBS between experiments.

## Debugging basics

| Symptom | Likely cause | Check |
|---|---|---|
| Script does not appear after `+` | Wrong file extension, or the picker filtered it | Add with **All files** |
| `attempt to index a nil value` | The script expects a source or setting that does not exist yet | Create the text/source first, then reload |
| `module 'obspython' not found` | Python Settings is wrong, or the OBS build has no Python | Fix the interpreter path |
| `ImportError` / `ModuleNotFoundError` | A package is missing from the selected interpreter | Install it into *that* interpreter, with approval |
| `wrong architecture` | 32-bit Python with 64-bit OBS | Use a 64-bit interpreter |
| Script works, hotkeys do nothing | Hotkey not bound, or OBS does not have focus | **Settings → Hotkeys** |
| OBS crashes on load | Invalid property value (for example a bad datetime format) | Remove the script, restore the scene collection, re-add with defaults |

Useful habits:

- Keep one script per experiment so the log is unambiguous.
- Read the Script Log immediately after adding a script; earlier messages scroll.
- Copy the script's `script_description()` text into your notes — it is the
  author's own summary of what the script needs.

## Writing your own scripts

`02-Scripting-and-Automation\Custom-Scripts\` is reserved for your own work. It is
empty on purpose: **never put downloaded code there**, so you can always tell your
scripts from the audited ones. See that folder's `README.md`.

## Related guides

- `INSTALLATION_GUIDE.md` — the mechanical steps for adding a script.
- `SECURITY_GUIDE.md` — how to read a script before you load it.
- `TROUBLESHOOTING.md` — longer symptom list.
