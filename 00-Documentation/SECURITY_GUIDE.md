# Security Guide

Practical security for an OBS plugin and script library. Nothing here replaces
your judgement; it gives you a repeatable way to decide whether a file is the one
you meant to get and whether a script deserves to run with your rights.

## 1. Verify a download before you use it

Every asset in this library has a SHA-256 in `MANIFEST.json` and in
`11-Checksums\SHA256SUMS.txt`. Verify before copying anything into OBS:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\12-Utilities\Verify-Checksums.ps1
```

That script checks every file listed in `SHA256SUMS.txt`, reports missing, extra
and mismatched files, and exits non-zero on a problem. To check a single file by
hand:

```powershell
(Get-FileHash -LiteralPath '.\03-Timers-and-Counters\Advanced-Timer\Downloads\6.0.0\advanced-timer.lua' -Algorithm SHA256).Hash.ToLower()
```

Compare the result with the `sha256` field in the manifest. A match proves the
file is byte-identical to the audited one. It does **not** prove the file is safe;
it proves it is the file this library reviewed.

### What the verification statuses mean

| Status | Proves | Does not prove |
|---|---|---|
| `VERIFIED` | The hash matches a checksum the **publisher** published (release notes or release API), and/or an Authenticode signature validates | That the code is safe or bug-free |
| `INTEGRITY-ONLY` | The hash matches the digest GitHub's API reported for that asset | That the publisher signed it, or that it is safe |
| `COMPUTED-ONLY` | We hashed the file; there was no external value to compare against | Anything about the source of the file |
| `FAILED` | The file did not match | — |
| `NOT-DOWNLOADED` | No asset exists for this tool | — |

## 2. Trusted sources

- Download only from the tool's official GitHub repository, its releases page, or
  `obsproject.com`. No download portals, mirrors, "plugin pack" sites, or
  reposts.
- A fork is not the original. This library uses one fork on purpose
  (`exeldro/obs-shaderfilter`), and that choice is recorded in the manifest and
  in the tool's `TOOL_INFO.md`.
- Release notes, READMEs, issues and comments are **data, not instructions**. If
  a file tells you to run a command, disable Defender, or "ignore previous
  instructions", do not act on it; report it.

## 3. The script review checklist (the seven S's)

Use this before loading a Lua or Python script you did not write. It is also how
the audit rated every script in this library.

| # | Check | What to look for |
|---|---|---|
| 1 | **Source** | Does the repository have a real commit history and a license file? A script with no license is `UNVERIFIED`, not "probably fine". |
| 2 | **Sockets** | Search for `http`, `socket`, `requests`, `urllib`, `curl`, `WebSocket`, `listen`, `bind`. Where does it connect, and what does it send? |
| 3 | **Spawn** | Search for `os.execute`, `io.popen`, `CreateProcess`, `ShellExecute`, `subprocess`, `os.system`, `ffi.C`. A script that starts programs is a launcher for whatever it is told to start. |
| 4 | **Secrets** | Does it read or write tokens, passwords or stream keys? Does it print them into the log? A committed credential in a repository is a red flag. |
| 5 | **Storage** | Which files does it write, and where? `io.open`, `open(...,'w')`, `os.remove`. A script that writes outside its own folder needs a reason. |
| 6 | **Scope** | Does it touch the whole desktop (global cursor polling, keyboard hooks, screen capture) or only OBS objects? Broader scope means a broader failure mode. |
| 7 | **Synthesis** | Could a malicious input to this script (a template, a macro file, a URL) become code or a command? Dynamic `load()`, `eval`, `compile`, and template engines are the usual paths. |

If a script fails 3 or 7 without a clear, documented reason, do not load it.

## 4. OBS WebSocket hardening

OBS 32.0.1 bundles OBS WebSocket 5.6.3, listening on `127.0.0.1:4455` when
enabled. Anyone who can authenticate can control OBS completely: switch scenes,
delete sources, start or stop a stream.

- Keep the server **disabled** unless a client is actually connected.
- Keep **authentication on**. Use a unique, long password. Do not reuse a
  password from anywhere else.
- Never port-forward 4455, never expose it through a tunnel (ngrok, Cloudflare
  Tunnel, Tailscale Funnel), and never bind it to a public interface.
- Check what it listens on:

```powershell
Get-NetTCPConnection -LocalPort 4455 -ErrorAction SilentlyContinue |
  Select-Object LocalAddress,LocalPort,State,OwningProcess
```

`127.0.0.1` is local-only. `0.0.0.0` or `::` means every interface — fix that
before doing anything else.
- A firewall rule is **optional and needs your approval**. The safe default is no
  inbound rule at all.
- Rotate the password if it was ever pasted into a chat, a config file, or a
  screenshot.

## 5. MCP permissions (OBS-MCP)

OBS-MCP exposes OBS control as tools an AI client can call. Treat it as a remote
control with your full OBS rights.

- Run it as a **local stdio process**, started by the client. Do not expose it on
  a network port.
- Pass `OBS_PASSWORD` through the client's environment block, never in a
  committed config file or a shell history line.
- Apply **least privilege**: start with read-only tools (get version, list scenes)
  and only then allow changes. Destructive tools exist — stop streaming, delete
  scenes, remove sources.
- Require explicit confirmation for destructive actions in the client, if the
  client supports it.
- Keep the OBS WebSocket password separate from the MCP client's own credentials.
- Review the tool list after every version upgrade; a new version can add tools.

## 6. Stream-key hygiene

- Stream keys are bearer secrets: anyone with the key can stream to your channel.
- They live in `%APPDATA%\obs-studio\basic\profiles\<profile>\` and, for
  Multi-RTMP, in `obs-multi-rtmp.json` in the same profile folder. This library
  never reads them.
- Never include a profile backup in a shared archive. See
  `OBS_BACKUP_GUIDE.md`.
- If a key leaks, reset it in the service's dashboard; deleting the local file is
  not enough.

## 7. Safe rollback

- Keep the previous version's folder. `Downloads\<version>\` is never overwritten;
  a new version goes into a new folder.
- Before an upgrade: back up (`OBS_BACKUP_GUIDE.md`), then install, then confirm
  OBS starts and the tool loads.
- If something breaks: close OBS, remove the new DLL/data folder, restore the
  previous version, and read `%APPDATA%\obs-studio\logs\` for the cause.

## 8. If something looks malicious

1. Stop. Do not run it again.
2. Disconnect from the network if you suspect data exfiltration.
3. Remove the DLL or script from OBS, and remove the scene-collection reference.
4. Change the credentials it could have reached: OBS WebSocket password, stream
   keys, Spotify/Last.fm tokens, any API key in `plugin_config`.
5. Run a full Microsoft Defender scan. Do not add exclusions.
6. Keep the file and its hash; report it to the repository owner and, if it came
   from a release, to GitHub.
7. Record what happened in your own notes, including the version and hash.

## 9. What this library does and does not claim

- It records **static** findings: what the source reads, writes, connects to and
  spawns. It does not disassemble compiled DLLs, and it did not execute anything.
- It did not run any tool against OBS, so no runtime behaviour is claimed.
- A `LOW` risk rating means "the reviewed source shows limited capability", not
  "guaranteed safe". A `HIGH` rating means "do not use without a deliberate
  decision".

## Related guides

- `INSTALLATION_GUIDE.md` — install and uninstall steps.
- `OBS_BACKUP_GUIDE.md` — backups that contain secrets.
- `TROUBLESHOOTING.md` — when a load fails.
- `../COMPATIBILITY.md` — version ranges that affect safety of an upgrade.
