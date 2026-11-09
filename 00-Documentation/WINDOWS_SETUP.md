# Windows Setup

Windows 11 x64 specifics that affect this library and the tools in it. This guide
does not change any Windows setting; it explains what you will see and what to
expect.

## Where OBS keeps its files

### Installed OBS (detected)

| What | Path |
|---|---|
| Program and plugins | `C:\Program Files\obs-studio` |
| Plugin DLLs | `C:\Program Files\obs-studio\obs-plugins\64bit` |
| Plugin data | `C:\Program Files\obs-studio\data\obs-plugins\<plugin>` |
| Logs | `%APPDATA%\obs-studio\logs` |
| Profiles | `%APPDATA%\obs-studio\basic\profiles` |
| Scene collections | `%APPDATA%\obs-studio\basic\scenes` |
| Per-plugin settings | `%APPDATA%\obs-studio\plugin_config` |
| Global settings | `%APPDATA%\obs-studio\global.ini` |

`global.ini`, the profile folder, the scene-collection folder and
`plugin_config` are treated as private by this audit. They can contain stream
keys, WebSocket passwords and API tokens. Do not commit them, paste them into a
chat, or include them in a shared archive.

### Portable OBS

Everything lives under the portable root:

| What | Path |
|---|---|
| Program and plugins | `<root>` |
| Plugin DLLs | `<root>\obs-plugins\64bit` |
| Plugin data | `<root>\data\obs-plugins\<plugin>` |
| Configuration | `<root>\config\obs-studio` |

## Permissions

- Writing to `C:\Program Files\obs-studio` requires an elevated process. The
  plugin installers prompt for UAC themselves; a manual copy needs an
  administrator PowerShell or Explorer window.
- `%APPDATA%\obs-studio` and `%USERPROFILE%\Documents` are writable by your user.
  Scripts and backups belong there.
- This library is self-contained and needs no elevation to verify, read, or
  back up.

## SmartScreen and Defender

- **Never disable SmartScreen or Microsoft Defender to install a tool.** If
  SmartScreen warns about a file, stop and verify the SHA-256 against
  `MANIFEST.json` and `11-Checksums\SHA256SUMS.txt` first. A warning is not proof
  of malice, and a clean scan is not proof of safety, but a mismatch is proof
  that the file is not the one this library recorded.
- Unsigned plugin DLLs are normal in the OBS ecosystem. `TOOL_INFO.md` records
  which assets are Authenticode-signed and which are not.
- Downloaded zips may carry the Mark-of-the-Web. Extract them with Explorer or
  `Expand-Archive`; do not run anything from inside the zip.
- The audit ran a Defender scan over the library and recorded the result in
  `FINAL_REPORT.md`. Re-run your own scan if you add files.

## PowerShell 7 for the utilities

The utilities in `12-Utilities\` require **PowerShell 7.0 or newer** (`pwsh`).
Windows PowerShell 5.1 is not supported.

Check what you have:

```powershell
$PSVersionTable.PSVersion
Get-Command pwsh -ErrorAction SilentlyContinue
```

If `pwsh` is missing, install PowerShell 7 from Microsoft's official release page.
Installing software is an action that needs your approval; this library does not
do it.

### Execution policy

Do **not** change the machine-wide execution policy. Run a script without
touching policy by using the `-File` form with a bypass scoped to that one
process:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\12-Utilities\Verify-Checksums.ps1
```

Or dot-source after setting a process-scoped policy:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\12-Utilities\Test-Library.ps1
```

`-Scope Process` lasts only for that window. It is the least invasive option and
is what the examples in this library assume.

## Long paths

Deep source snapshots can exceed the legacy 260-character path limit. Windows 11
usually has long paths enabled, but if extraction fails:

- Extract to a short root such as `C:\OBS-Toolkit` instead of a deep
  `Documents\Project\...` path, or
- Enable long paths (administrator, machine-wide change — needs your approval):

```powershell
# Requires an elevated shell. This is a system change; the library does not run it.
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' `
  -Name LongPathsEnabled -Value 1
```

This library was built at `C:\Users\<user>\Documents\Project\OBS-Toolkit` without
needing that change.

## Runtime requirements per tool type

| Type | Runtime | Notes |
|---|---|---|
| Plugin (DLL) | Visual C++ runtime, as required by the plugin | Most OBS plugins link the same runtime OBS already ships. A missing runtime shows as a load failure in the OBS log. |
| Lua script | Lua 5.1 (LuaJIT) inside OBS | Nothing to install. |
| Python script | 64-bit Python in the OBS 32 range (3.8–3.10) | Configure it in **Tools → Scripts → Python Settings**. |
| MCP server | Python 3.10+ as a separate process | Not the OBS-embedded interpreter. |

## Antivirus and network behavior

- Tuna runs a local HTTP server (default `0.0.0.0:1608`). Windows Firewall may
  prompt the first time it listens. **A firewall rule is optional and needs your
  approval**; the safe answer is to deny public access, or to avoid the server
  entirely and use a text/image source.
- OBS WebSocket listens on `127.0.0.1:4455` when enabled. Do not create an inbound
  rule for it.
- Advanced Scene Switcher can make HTTP requests when a macro uses an HTTP
  action; that is outbound traffic to the URL you configure.

## Related guides

- `INSTALLATION_GUIDE.md` — per-type install steps.
- `OBS_BACKUP_GUIDE.md` — backup locations and restore.
- `SECURITY_GUIDE.md` — verifying downloads and hardening.
