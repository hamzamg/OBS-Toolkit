# OBS Backup Guide

A plugin that stops OBS from starting is recoverable in minutes **if** you have a
backup. Without one it can mean rebuilding a scene collection from memory. Back
up before the first install and before every plugin upgrade.

## What to back up

| Item | Installed OBS path | Portable OBS path | Why |
|---|---|---|---|
| Scene collections | `%APPDATA%\obs-studio\basic\scenes` | `<root>\config\obs-studio\basic\scenes` | Sources, filters, script settings, hotkeys |
| Profiles | `%APPDATA%\obs-studio\basic\profiles` | `<root>\config\obs-studio\basic\profiles` | Output, audio, video, stream settings |
| Global settings | `%APPDATA%\obs-studio\global.ini` | `<root>\config\obs-studio\global.ini` | Theme, language, paths, WebSocket settings |
| Per-plugin config | `%APPDATA%\obs-studio\plugin_config` | `<root>\config\obs-studio\plugin_config` | Plugin state (may hold tokens) |
| Plugin manager list | `%APPDATA%\obs-studio\plugin_manager` | `<root>\config\obs-studio\plugin_manager` | Installed-module registry |

You do **not** need to back up the program folder (`C:\Program Files\obs-studio`).
It is replaceable from the OBS installer, and this library keeps the plugin
binaries you added.

## The backup contains secrets

A backup of `basic\profiles` and `plugin_config` can contain:

- stream keys for every configured service,
- the OBS WebSocket password,
- Spotify/Last.fm tokens (Tuna),
- Multi-RTMP stream keys in `obs-multi-rtmp.json`,
- service API keys.

Therefore:

- Store backups **outside this library**. The library is meant to be shareable and
  scanned for secrets; a backup is not.
- Encrypt the archive (BitLocker-protected volume, or a password-protected 7-Zip
  archive). Windows' built-in `Compress-Archive` does **not** encrypt.
- Never upload a backup to a public share, a chat, or a repository.
- Delete old backups you no longer need; a stale backup is still a secret.

## Manual backup

1. Close OBS completely.
2. In Explorer, open `%APPDATA%\obs-studio`.
3. Copy `basic`, `plugin_config`, `plugin_manager` and `global.ini` to a
   timestamped folder outside the library, for example
   `D:\OBS-Backups\2026-11-09T12-00-00Z\`.
4. Compress and encrypt that folder.
5. Record the OBS version and the list of plugins you had installed.

## Scripted backup

`12-Utilities\Backup-OBS.ps1` automates the copy:

```powershell
# Dry run: lists what would be copied and the total size. Changes nothing.
pwsh -NoProfile -ExecutionPolicy Bypass -File .\12-Utilities\Backup-OBS.ps1

# Real copy: requires typed confirmation and a destination outside the library.
pwsh -NoProfile -ExecutionPolicy Bypass -File .\12-Utilities\Backup-OBS.ps1 `
  -Destination 'D:\OBS-Backups'
```

The script:

- defaults to a dry run,
- refuses to write inside the library,
- creates a timestamped subfolder and **fails if it already exists** (it never
  overwrites an older backup),
- prints the size before copying,
- warns that the result contains secrets,
- does not encrypt — encrypt the result yourself.

## Restore

1. Close OBS.
2. Copy the current `%APPDATA%\obs-studio` aside as a safety copy.
3. Restore the backed-up `basic`, `plugin_config`, `plugin_manager` and
   `global.ini` into `%APPDATA%\obs-studio`.
4. Start OBS and confirm your scenes and profile are present.
5. If the restore was to recover from a bad plugin, also remove that plugin's DLL
   and data folder (see `INSTALLATION_GUIDE.md`).

Restoring an **older** OBS configuration into a **newer** OBS can be rejected or
migrated. Restore a backup made with the same or an older OBS version, and read
the OBS log after the first start.

## Rollback after a bad install

The minimal rollback is often enough:

1. Close OBS.
2. Remove the new plugin's DLL and data folder.
3. Start OBS. Your scene collection is untouched, because a plugin's presence is
   not stored in it.
4. If OBS still fails, restore the scene collection and profile from backup.

## Schedule

- Before the first tool install.
- Before every plugin upgrade.
- Before a Windows or OBS major upgrade.
- Monthly, if you stream regularly.

## Related guides

- `INSTALLATION_GUIDE.md` — install steps that assume a backup.
- `UPDATE_GUIDE.md` — why an upgrade needs a fresh backup.
- `SECURITY_GUIDE.md` — secret handling.
