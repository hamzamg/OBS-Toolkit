# Update Guide

How to keep this library current without breaking a working OBS setup. The rule
is simple: **a new version goes into a new folder, is verified, and is recorded;
the old version stays until you have confirmed the new one.**

## What "update" means here

Two different things:

1. **Updating the library** — finding out that a tool has a newer release,
   downloading it into `Downloads\<new-version>\`, verifying it, and recording it
   in `MANIFEST.json` and `CHANGELOG.md`. This is safe and reversible.
2. **Updating an installed tool in OBS** — copying the new files into OBS. That is
   an install action: it needs a backup and your approval.

The library never does step 2.

## 1. Check for new versions

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\12-Utilities\Update-Library.ps1
```

Default mode is `-CheckOnly`:

- reads `MANIFEST.json`,
- queries GitHub's releases API (read-only, cached in `13-Logs\cache\`, rate-limit
  aware),
- prints current vs. newest stable for each tool,
- adds a compatibility caution when the new release targets a newer OBS than
  yours,
- **downloads nothing**.

Read the output with three questions in mind:

- Is the new release stable (not a prerelease)?
- Does its release note state a **minimum OBS version** above 32.0.1?
- Is the license still the same?

## 2. Read the release notes

Open the release URL printed by the check. Look for:

- a changed OBS minimum version,
- a new asset name or a changed archive layout,
- a license change,
- security-relevant changes (network, process, new services),
- a note that says the old version is no longer supported.

## 3. Approve and download into a new folder

Downloads happen only with explicit ids:

```powershell
# Downloads one tool into Downloads\<new-version>\ and verifies it.
pwsh -NoProfile -ExecutionPolicy Bypass -File .\12-Utilities\Update-Library.ps1 `
  -Apply -Tool multi-rtmp
```

- The script never deletes or overwrites an older `Downloads\<version>\`.
- It computes SHA-256 and records the platform digest and signature result.
- It updates `MANIFEST.json` and appends a `CHANGELOG.md` entry.
- It does not install anything.

If the new asset fails verification, do not use it. Keep the old version and
record the failure.

## 4. Re-check compatibility before installing

| Change | What to check |
|---|---|
| New plugin release | Its build target vs. your OBS version (`COMPATIBILITY.md`) |
| New Python script | Its Python requirement vs. OBS 32's 3.8–3.10 range |
| New Lua script | Whether it now needs a newer OBS API |
| New MCP server | Its Python requirement and its new tool list |
| New OBS version | Every tool, because plugin binaries are tied to OBS major versions |

**After any OBS upgrade, re-check every plugin before reinstalling it.** A plugin
built for OBS 31 may load on 32, but that is a per-plugin fact, not a rule.

## 5. Update the installed copy (manual)

1. Back up (`OBS_BACKUP_GUIDE.md`).
2. Close OBS.
3. Replace the DLL and data folder with the new version's files, or run the new
   installer.
4. Start OBS, confirm the tool loads, use it once.
5. Keep the old version's folder until you are satisfied.

Rollback: close OBS, restore the old DLL/data folder from
`Downloads\<old-version>\`, restart.

## 6. Re-verify the library

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\12-Utilities\Verify-Checksums.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\12-Utilities\Generate-Manifest.ps1
```

`Generate-Manifest.ps1` validates the manifest against the schema and regenerates
`SHA256SUMS.txt` and each `Checksums.txt` from disk. It flags orphan and missing
files. It never edits license, compatibility or security fields — those are
judgement calls you make and record.

## 7. When not to update

- The new release targets a newer OBS than yours (Multi-RTMP `0.7.4.1+` on OBS
  32.0.1 is the recorded example).
- The project changed license in a way that affects your use.
- The release is a prerelease and you depend on the tool.
- The new version adds a capability you do not want (a listening port, a new
  external service).
- The old version works and the change is cosmetic.

Pinning is a feature. `MANIFEST.json` records the version this library audited;
upgrading is a deliberate act, not an automatic one.

## Cache and rate limits

- API responses are cached in `13-Logs\cache\api\`.
- Unauthenticated GitHub API access allows 60 requests per hour. The check script
  reuses the cache and backs off on `403`/`429`.
- Do not add a personal access token unless you are comfortable storing it; the
  script never asks for one.

## Related guides

- `INSTALLATION_GUIDE.md`
- `OBS_BACKUP_GUIDE.md`
- `COMPATIBILITY.md`
- `SECURITY_GUIDE.md`
