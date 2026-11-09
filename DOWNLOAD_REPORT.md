# Download Report

Generated from `MANIFEST.json` on 2026-11-09T17:35:51Z.

Downloads happened only from `github.com` release URLs (including GitHub's release-asset CDN)
and `api.github.com` metadata. No portal, mirror or unofficial fork was used. Nothing was
executed. Every file was hashed before it was recorded.

## Succeeded

| Tool | File | Size (bytes) | SHA-256 (first 16) | Reference | Verification | Downloaded (UTC) |
|---|---|---:|---|---|---|---|
| Advanced Scene Switcher | `advanced-scene-switcher-1.37.2-windows-x64-Installer.exe` | 110,314,092 | `517b6aaa0ef5f9db…` | PUBLISHER (match) | `VERIFIED` | 2026-11-02T19:40:23Z |
| Autostarter | `autostarter.zip` | 40,781 | `c3023dedb7e44122…` | none | `COMPUTED-ONLY` | 2026-11-02T19:39:45Z |
| Advanced Timer | `advanced-timer.lua` | 20,020 | `8df66dea65fa07a7…` | none | `COMPUTED-ONLY` | 2026-11-02T19:38:59Z |
| Advanced Filename Formatter | `adv-ff.py` | 55,569 | `2df6c01410bc080e…` | PLATFORM (match) | `INTEGRITY-ONLY` | 2026-11-02T19:39:46Z |
| Local Stream Marker | `local-stream-marker.1.13.zip` | 13,299 | `777c2ed5e1c237d0…` | PLATFORM (match) | `INTEGRITY-ONLY` | 2026-11-02T19:39:49Z |
| Source Record | `source-record-0.4.8-windows.zip` | 356,380 | `c2e461afc42746bb…` | PLATFORM (match) | `VERIFIED` | 2026-11-02T19:39:50Z |
| Shaderfilter | `obs-shaderfilter-2.6.1-windows.zip` | 4,795,506 | `bdb5af0c8d6afb9b…` | PLATFORM (match) | `INTEGRITY-ONLY` | 2026-11-02T19:39:53Z |
| Tuna | `tuna-1.9.12-windows-x64.zip` | 7,640,564 | `e7bfd593d91d0742…` | PLATFORM (match) | `INTEGRITY-ONLY` | 2026-11-02T19:40:00Z |
| Multi-RTMP | `obs-multi-rtmp-0.7.4.0-windows-x64.zip` | 2,111,888 | `601c014a29622614…` | PLATFORM (match) | `INTEGRITY-ONLY` | 2026-11-02T19:39:10Z |

**9 assets, 119.5 MB total.** All 9 match the manifest and ``SHA256SUMS.txt``.

### Layouts confirmed by archive listing

| Archive | Layout |
|---|---|
| `autostarter.zip` | single `autostarter.dll` |
| `source-record-0.4.8-windows.zip` | `obs-plugins/64bit/*.dll` + `data/obs-plugins/source-record/` |
| `obs-shaderfilter-2.6.1-windows.zip` | `obs-plugins/64bit/*.dll` + `data/obs-plugins/obs-shaderfilter/examples/` (165 files) |
| `obs-multi-rtmp-0.7.4.0-windows-x64.zip` | `obs-plugins/64bit/*.dll` + `data/obs-plugins/obs-multi-rtmp/` |
| `tuna-1.9.12-windows-x64.zip` | `tuna/tuna.dll` + `tuna/data/*` (manual mapping) |
| `local-stream-marker.1.13.zip` | `local-stream-marker.lua` + LICENSE/README/CHANGELOG |
| `advanced-scene-switcher-1.37.2-windows-x64-Installer.exe` | installer; not opened |

## Failed

None. No download attempt returned an error or a truncated file.

## Skipped (no release asset exists)

These tools are stored as a pinned source snapshot only. A source snapshot is identified by its
commit SHA, not by a file hash, because GitHub's generated source archives are not byte-stable.

| Tool | Reason | Snapshot |
|---|---|---|
| RSE OBS Scripts | No releases or tags; source-only and `UNVERIFIED` | `59191d2ca89b1c7affd6f440da8a4b780d53c5ae` |
| Libre Macros | Release has no assets; `PENDING-USER` tool, no asset downloaded | `e56cd6922dc07302915bda02d6972f3ec3be0661` |
| OBS Counter | No release asset; the pinned source snapshot is the installable artifact | `fd9be36fcfacc38e6fa66a076128bf4af91f327e` |
| OBS Screen Studio | No release asset; the pinned source snapshot is the installable artifact | `5739bc01f0d503f08b3fb21ddbfebfd42d387dcf` |
| Filter Hotkeys | No release asset; the pinned source snapshot is the installable artifact | `1b11ae6ae62f9a79959c7700a60f28b9fa8da8e7` |
| OBS-MCP | No release asset; the pinned source snapshot is the installable artifact | `ae557d1f63d61f1717630b9ca9a16284e38dbd24` |

### Documentation-only

| Tool | Reason | Snapshot |
|---|---|---|
| OBS WebSocket | Bundled with OBS; no binary is downloaded, only the documentation at the matching tag | `1c9306b1e200704ebe192e06c893dfc06b097c43` |

## Unavailable

None. Every project in the registry resolved to an official GitHub repository during research.

## Verification failures

None. All 9 assets match the manifest hash, their recorded size, and `11-Checksums/SHA256SUMS.txt`.

### One documented discrepancy (not a failure)

`Advanced-Timer/Downloads/6.0.0/advanced-timer.lua` is 20,020 bytes. The file at tag `6.0.0` in
the repository is 20,598 bytes. Both are preserved: the release asset is what the publisher
attached to the release, and the repository copy is what the tag contains. The library treats
the release asset as the installable file and records the difference in the tool record.

## Incompatible assets

| Asset or feature | Reason |
|---|---|
| Multi-RTMP `0.7.4.1` and newer | Built against OBS 32.2.1; OBS 32.0.1 refuses to load it. Pinned to `0.7.4`. |
| Advanced Scene Switcher `windows-x64.zip` | Documented as OBS 33+ only; not used on the detected OBS. |
| Advanced Filename Formatter Replay Buffer features | Require OBS 33.0.0+; unavailable on 32.0.1. |

These were identified during research and **not downloaded**, except where a tool record says
otherwise. The alternative asset names are recorded in the manifest so you know they exist.

## Quarantined

| Tool | Decision | Risk | Location | Reason |
|---|---|---|---|---|
| RSE OBS Scripts | `UNVERIFIED` | `MEDIUM` | `10-Unverified/RSE-OBS-Scripts` | The repository has no LICENSE or COPYING file; every .lua header only says 'Distributed under MIT license'. A license claim without the license text cannot be confirmed for the collection, so the tool is metadata-only in 10-Unverified. |
| Libre Macros | `PENDING-USER` | `HIGH` | `10-Unverified/Libre-Macros` | Security review rated HIGH: the console compiles and runs dynamic code (console.lua:968, :1783), uses FFI CreateProcessA (console.lua:529-555), and a bundled helper script contains a hardcoded WebSocket password. Moved to 10-Unverified pending an explicit user decision. |

Both are in `10-Unverified\` with the normal per-tool layout, so they can be reviewed and moved
later without re-downloading.

## What was not downloaded

- No Python package, pip wheel, npm package or build dependency.
- No OBS installer or OBS update.
- No `UNVERIFIED` asset. RSE OBS Scripts has no release; Libre Macros has no release asset.
- No unofficial fork or mirror.
