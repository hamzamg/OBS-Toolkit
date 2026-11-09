# Final report

Generated 2026-11-09 from `MANIFEST.json` plus a filesystem scan. Every count, version
and status below is read from the manifest; only the size and file totals come
from disk. The library is at `C:\Users\<user>\Documents\Project\OBS-Toolkit`.

Nothing was installed, executed, configured or runtime-tested. OBS was not modified.

## 1. Projects researched

| Decision | Count | Meaning |
| --- | ---: | --- |
| `INCLUDED` | 13 | verified enough to use, with a pinned snapshot |
| `UNVERIFIED` | 1 | metadata only; a trust question is unresolved |
| `REJECTED` | 0 | evaluated and deliberately not kept |
| `UNAVAILABLE` | 0 | no usable release or source could be obtained |
| `DOCS-ONLY` | 1 | already ships with OBS; documentation only |
| `PENDING-USER` | 1 | waiting for an explicit user decision |
| **Total** | **16** | |

Risk: 6 LOW, 9 MEDIUM, 1 HIGH. Maintenance: 11 ACTIVE, 5 STALE.

## 2. Assets

| Outcome | Count |
| --- | ---: |
| Downloaded and hashed | 9 |
| Failed | 0 |
| No asset needed (source-only, script-only or docs-only) | 7 |
| **Total bytes downloaded** | **125,348,099 B (119.54 MB)** |

The tools with no downloaded asset, and why:

- **RSE OBS Scripts** (UNVERIFIED): the script lives in the pinned source snapshot; no release asset is published.
- **Libre Macros** (PENDING-USER): the script lives in the pinned source snapshot; no release asset is published.
- **OBS Counter** (INCLUDED): the script lives in the pinned source snapshot; no release asset is published.
- **OBS Screen Studio** (INCLUDED): the script lives in the pinned source snapshot; no release asset is published.
- **Filter Hotkeys** (INCLUDED): the script lives in the pinned source snapshot; no release asset is published.
- **OBS WebSocket** (DOCS-ONLY): ships with OBS; only documentation is snapshotted.
- **OBS-MCP** (INCLUDED): a Python package kept as a pinned source snapshot; installed by the user later.

## 3. Checksums

| Verification status | Assets | Meaning |
| --- | ---: | --- |
| `VERIFIED` | 2 | an independent reference (publisher hash or signed digest) matched |
| `INTEGRITY-ONLY` | 5 | the platform digest matched; no publisher signature |
| `COMPUTED-ONLY` | 2 | only our own SHA-256 exists; nothing to compare it with |
| `FAILED` | 0 | a reference existed and did not match |

Every asset also matches its recorded size and the value in `11-Checksums/SHA256SUMS.txt`;
`12-Utilities/Verify-Checksums.ps1` recomputes all 57 listed files on demand.

## 4. Licenses

15 of 16 tools have an SPDX identifier confirmed from a license file saved at the pinned ref.

**Gap:** RSE OBS Scripts has no license file in the repository (status `ABSENT`). The Lua headers say MIT, but a claim without the text is not confirmation, so the tool is quarantined.

## 5. Size on disk

| Measure | Value |
| --- | ---: |
| Files | 2,273 |
| Bytes | 331,253,579 |
| Human | 315.91 MB |

Most of the size is upstream source snapshots, not binaries: the Scene Switcher and
OBS Screen Studio snapshots dominate, and the latter includes a 98 MB design file
that ships in the upstream repository.

## 6. Tools that need your approval before use

Approval is per action, not per tool. The full list for each tool is in its
`TOOL_INFO.md` section 2 and in `approval_required_for` in the manifest.

| Tool | Decision | Risk | First gate |
| --- | --- | --- | --- |
| Advanced Scene Switcher | `INCLUDED` | MEDIUM | Installing the plugin or running its installer |
| RSE OBS Scripts | `UNVERIFIED` | MEDIUM | Downloading or using an UNVERIFIED tool (license unresolved) |
| Libre Macros | `PENDING-USER` | HIGH | Downloading or using a PENDING-USER tool rated HIGH |
| Autostarter | `INCLUDED` | MEDIUM | Installing the plugin |
| Advanced Timer | `INCLUDED` | LOW | Installing the script |
| OBS Counter | `INCLUDED` | LOW | Installing the script and configuring OBS's Python path |
| Advanced Filename Formatter | `INCLUDED` | MEDIUM | Installing the script |
| Local Stream Marker | `INCLUDED` | LOW | Installing the script |
| Source Record | `INCLUDED` | LOW | Installing the plugin |
| OBS Screen Studio | `INCLUDED` | MEDIUM | Installing the script |
| Shaderfilter | `INCLUDED` | LOW | Installing the plugin |
| Filter Hotkeys | `INCLUDED` | LOW | Installing the script |
| Tuna | `INCLUDED` | MEDIUM | Installing the plugin |
| Multi-RTMP | `INCLUDED` | MEDIUM | Installing the plugin |
| OBS WebSocket | `DOCS-ONLY` | MEDIUM | Enabling the WebSocket server |
| OBS-MCP | `INCLUDED` | MEDIUM | Installing the Python dependencies |

Three gates are not ordinary installation approvals:

- **libre-macros (`PENDING-USER`, HIGH).** Do not download or use it until you decide
  whether you accept a console that compiles dynamic Lua, creates processes through
  FFI, and ships a helper with a hardcoded WebSocket password.
- **rse-obs-scripts (`UNVERIFIED`).** No license text in the repository; and
  `auto-execute-commands.lua` runs shell commands at OBS start and shutdown.
- **obs-mcp (`INCLUDED`, Apache-2.0).** It lets an AI client control OBS, including
  starting streams and deleting scenes. Configure it deliberately, not by default.

## 7. Unavailable or incompatible projects

| Tool | Status | Reason |
| --- | --- | --- |
| multi-rtmp | pinned to 0.7.4 | Releases from 0.7.4.1 target OBS 32.2.1; the installed OBS is 32.0.1. The 0.7.4 buildspec is 32.0.0. Newer versions are not downloaded. |
| obs-websocket | `DOCS-ONLY` | Bundled with OBS 32.0.1 at 5.6.3 (submodule `1c9306b1`). The tag has no release object, so there is no binary to download. |
| rse-obs-scripts | `UNVERIFIED` | No LICENSE or COPYING file; the license cannot be confirmed. |
| libre-macros | `PENDING-USER` | HIGH risk; waiting for an explicit decision. |
| advanced-filename-formatter | `INCLUDED`, dependency gap | Needs Python 3.10; only 3.8 is inside the OBS range on this machine, and no 3.10 is installed. The first-run `pip install` needs network access. |

Nothing was rejected outright: every candidate resolved to a real repository.

## 8. Not done

- Nothing was installed. No installer, archive or script was executed.
- OBS was not started, stopped, configured or updated. No profile, scene, filter,
  hotkey, script, plugin or WebSocket setting was changed.
- `global.ini`, `basic\profiles\**`, `plugin_config\**` and scene JSON were never opened.
- No registry key, PATH entry, firewall rule or Defender exclusion was touched.
- Nothing was runtime-tested. Compatibility is inferred from buildspecs, release
  notes and bundled versions, not from loading the tools in OBS.

The one intentional exception to "no network": `Update-Library.ps1` queries
`api.github.com` when you run it, and caches the responses. It was run in
check-only mode; nothing was downloaded by it.

## 9. Known gaps

1. **OBS Python path is `UNKNOWN`.** It lives in `global.ini`, which this audit does
   not open. Read it in OBS under Tools > Scripts > Python Settings and compare it
   with `Get-OBSInfo.ps1` output.
2. **advanced-timer asset differs from the repository file at tag 6.0.0**
   (20,020 B release asset versus 20,598 B in the source tree). The release asset
   is what is recorded and hashed; the difference is documented in its `TOOL_INFO.md`.
3. **`docs.obsproject.com` was unreachable** from this machine. Documentation came
   from the upstream `docs/` folders in the pinned snapshots and from
   `raw.githubusercontent.com`, not from the rendered site.
4. **Phase 0 log line counts.** The `baseline-snapshot` line in `execution.log`
   records 2,122 install entries and 23 data entries; `obs-baseline.json` holds
   2,209 and 38. The JSON is the file the tripwire compares against, and it still
   reports zero differences. The log line is a historical annotation and was not
   rewritten.
5. **Two assets are `COMPUTED-ONLY`** (autostarter, advanced-timer): no publisher
   hash or signature exists, so their SHA-256 proves integrity over time but not
   provenance.
6. **No runtime test.** Every compatibility value is an inference.

## 10. Recommended next steps

1. Read `README.md` section "Before you install" and `00-Documentation/SECURITY_GUIDE.md`.
2. Run `.\12-Utilities\Get-OBSInfo.ps1` and compare its Python list with OBS Tools >
   Scripts > Python Settings. Decide which interpreter OBS should use (only 3.8 to
   3.10 is supported by OBS 32).
3. Run `.\12-Utilities\Backup-OBS.ps1` as a dry run, then with `-Destination` and
   `-Execute` to make a restore point outside this library. Encrypt it.
4. Run `.\12-Utilities\Test-Library.ps1` to re-run the Definition-of-Done checks on
   your machine.
5. Install in the README order, one tool at a time, starting with the LOW-risk
   scripts (advanced-timer, obs-counter, local-stream-marker, filter-hotkeys).
   Restart OBS and confirm each tool before adding the next.
6. Decide on `libre-macros` (HIGH, `PENDING-USER`) and `rse-obs-scripts`
   (`UNVERIFIED`). Until then, leave them in `10-Unverified`.
7. Before any update, read `<tool>/TOOL_INFO.md` section 4. `Update-Library.ps1`
   checks for newer releases but cannot tell you whether they support OBS 32.0.1.

## 11. Where the evidence is

| What | Where |
| --- | --- |
| Single source of truth | `MANIFEST.json` (validated by `MANIFEST.schema.json`) |
| Per-tool detail | `<tool folder>/TOOL_INFO.md` |
| Per-tool hashes | `<tool folder>/Checksums.txt` |
| All hashes | `11-Checksums/SHA256SUMS.txt` |
| Verification summary | `11-Checksums/VERIFICATION_REPORT.md` |
| Download record | `DOWNLOAD_REPORT.md` |
| License record | `LICENSES.md` |
| Compatibility matrix | `COMPATIBILITY.md` |
| Static security scans | `13-Logs/cache/security/` |
| OBS tripwire baseline | `13-Logs/obs-baseline.json` |
| QA result | `13-Logs/qa-result.json` |
| Action log | `13-Logs/execution.log` |

