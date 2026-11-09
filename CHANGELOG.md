# Changelog

All dates are UTC. This file follows the spirit of Keep a Changelog: one entry
per change, newest first. It records library changes, not OBS changes.

## [Unreleased]

### Added

- Repository hygiene: `.gitignore` now excludes dated `13-Logs/verify-*.json`
  reports (regenerable artifacts), Dependabot watches GitHub Actions weekly,
  and a CodeQL workflow scans the Actions language only (PowerShell stays under
  PSScriptAnalyzer — CodeQL does not analyze it). `ci.yml` gained a
  "Confirm restore completeness" dry-run of `Download-Missing.ps1` after the
  gate.
- `AGENTS.md`: project workflow rules — update before working, one branch per
  task, plan and approval before starting, verify then push and open a PR, and
  merge only after an explicit yes.
- `AGENTS.md` scope rule: the library root is the only work boundary; never
  search or read outside the project without the user's explicit approval.
- Environment baseline (format/lint/CI): `.editorconfig`, `.gitattributes`,
  `PSScriptAnalyzerSettings.psd1`, `.markdownlint.json`, CI workflow
  (`.github/workflows/ci.yml`, ubuntu + pwsh), and pre-commit hooks
  (`.pre-commit-config.yaml` + `.pre-commit-hooks/`). Also a project-local
  `opencode.json` with GitHub + Context7 MCP servers, and a "Local checks"
  section in `README.md`.
- Governance files: `SECURITY.md` (supported versions, private vulnerability
  reporting, scope) and `.github/pull_request_template.md` (QA checklist aligned
  with `Test-Library.ps1`).

### Changed

- CI (`ci.yml`): removed the `actions/setup-pwsh` step — that action does not
  exist; `pwsh` ships preinstalled on `ubuntu-latest` runners. Also fixed the
  invalid `Set-PSRepository -InstallationPolicy` value (`TrustedRepository` →
  `Trusted`) in the PSScriptAnalyzer install step.
- CI now restores the two git-excluded files with
  `Download-Missing.ps1 -Apply` before running the gate, so assets, checksums
  and the library are fully verified on fresh checkouts (and the restore tool
  is itself exercised on every run).
- `Test-Library.ps1` Check 9: the `13-Logs/cache` exclusion is now
  separator-agnostic (it never matched on Linux, which scanned the evidence
  cache and false-positived on a documented finding).
- `Test-Library.ps1`: Check 9 also ignores a username that appears only inside
  URLs (the public GitHub handle in the Star History chart link); names outside
  URLs are still reported. Check 10 (OBS tripwire) skips on CI runners
  (`$env:CI` set) so the gate can run on ubuntu-latest.
- Checksum hashing is now line-ending independent: the shared
  `Get-ToolkitFileHash` hashes LF-normalized content for text files (git blobs
  are LF, while Windows checkouts are CRLF), and exact bytes for binaries.
  `SHA256SUMS.txt` and per-tool `Checksums.txt` were regenerated; asset
  provenance (vs `MANIFEST.json`) is unchanged.
- `12-Utilities/Download-Missing.ps1`: restores files that are missing locally.
  A fresh clone lacks the two git-excluded files (SceneSwitcher installer,
  105.20 MB, and an upstream psd, 93.86 MB) because GitHub rejects files over
  100 MB. Read-only by default; downloads with `-Apply` only from the URLs
  recorded in `MANIFEST.json`, verifies SHA-256 before keeping a file, never
  overwrites a mismatch, and reports the psd's pinned-commit provenance
  explicitly (it has no hash in the manifest).
- Two files larger than GitHub's 100 MB per-file limit are excluded from git
  via `.gitignore` and remain only in the local library (they are still
  verified by `Test-Library.ps1`): the SceneSwitcher 1.37.2 installer
  (105.20 MB, re-downloadable with `Update-Library.ps1`) and an upstream
  design asset inside the OBS Screen Studio source snapshot (93.86 MB).

## [2026-11-09] Phase 5 - final gate

### Added

- `FINAL_REPORT.md`: eleven sections covering every §12 bullet, with all counts
  and versions computed from `MANIFEST.json` by script and sizes from disk.
- `CHANGELOG.md` (this file).
- `13-Logs/state.json` in its final form: phase 5, per-tool statuses matching
  the manifest, final decision, verification, risk and maintenance counts.

### Changed

- `Test-Library.ps1` now treats a `DOCS-ONLY` tool that stays in its category
  folder as acceptable when the decision carries an explicit justification; it
  still requires the tool to appear in `README.md` and `DOWNLOAD_REPORT.md`.
- `DOWNLOAD_REPORT.md` gained a "Documentation-only" table so every tool is
  mentioned; the asset total line is computed from the manifest instead of a
  fixed number.
- `13-Logs/cache/security/libre-macros.json`: the committed WebSocket password
  literal copied from the upstream helper was replaced by `<redacted>`; the
  `credentials` finding itself is unchanged and the upstream source snapshot
  is untouched.

### Security

- Final gate: `Test-Library.ps1` reports 12 pass, 0 fail, 0 skip;
  `Verify-Checksums.ps1` recomputes all 57 listed files with 0 findings;
  `Generate-Manifest.ps1 -CheckOnly` reports 0 findings.
- A secret and username scan of every authored file (everything except
  upstream `Source/` snapshots) reports 0 findings. The six hits inside
  upstream snapshots are locale UI strings, except one hardcoded WebSocket
  password in the libre-macros helper, which is already documented as a HIGH
  finding in that tool's `TOOL_INFO.md` and never reproduced in authored text.
- The OBS tripwire against the Phase 0 baseline compares clean: no file in the
  install tree or the compared data folder changed.
- Nothing was placed into OBS, nothing from `Downloads/` was run, and the
  library was committed to git only after the gate passed.

## [2026-11-09] Phase 4 - utilities

### Added

- `12-Utilities/Common.psm1` with `Get-ToolkitRoot`, `Get-ToolkitTimestamp`,
  `Format-ByteSize`, `Resolve-ToolkitPath`, `Test-PathUnder`,
  `Get-ToolkitManifest`, `Write-ToolkitLog`, `Write-ToolkitError` and
  `Protect-ToolkitText`.
- `12-Utilities/Get-OBSInfo.ps1`: read-only detection of the OBS install,
  architecture, portable flag, bundled modules, Python interpreters and port
  4455; writes `13-Logs/obs-info.json` with the username replaced by `<user>`.
- `12-Utilities/Verify-Checksums.ps1`: recomputes every line of
  `11-Checksums/SHA256SUMS.txt`, finds unlisted files under `Downloads/` and
  `Documentation/`, and cross-checks the manifest paths, sizes and hashes.
- `12-Utilities/Generate-Manifest.ps1`: validates the manifest against the
  schema and regenerates `SHA256SUMS.txt` (read-only with `-CheckOnly`).
- `12-Utilities/Update-Library.ps1`: read-only update check by default; a new
  version is only recorded with `-Apply -Tool <id>` after `-WhatIf` and
  confirmation, into a new `Downloads/<version>/` folder, never overwriting the
  old one. Caches API responses in `13-Logs/cache/api/` and honours
  `X-RateLimit-Remaining`.
- `12-Utilities/Backup-OBS.ps1`: dry run by default; with `-Execute`, a typed
  `BACKUP` confirmation and an absolute destination outside the library, it
  copies `basic`, `plugin_config`, `plugin_manager` and `global.ini` without
  opening them.
- `12-Utilities/Test-Library.ps1`: the twelve Definition-of-Done checks, writing
  `13-Logs/qa-result.json`.
- `12-Utilities/Open-README.ps1`: opens `README.md`, `README.ar.md` or a named
  guide locally; refuses paths outside the library and never opens a URL.

### Fixed

- `Get-OBSInfo.ps1` now parses both `py -0p` layouts (`-V:3.15 *` and
  `-3.15-64`) and records the interpreter architecture.
- Collection helpers now use `[System.Collections.Generic.List[T]]::new()`
  instead of `New-Object`. On this PowerShell 7.6.9 build, wrapping a
  `New-Object`-created `List[object]` in `@()` throws
  `ArgumentException: Argument types do not match`.
- `Update-Library.ps1` sorts releases on a real `DateTime`. The previous
  culture-formatted string sort picked an older release as "newest" (for
  example SceneSwitcher 1.8.2 over 1.37.2).
- Error paths use `Write-ToolkitError`, so the documented exit codes are
  actually returned: 0 success, 1 refusal or finding, 2 script error.
  `Write-Error` under `$ErrorActionPreference = 'Stop'` aborted before `exit 2`.

### Security

- Every utility refuses to write outside the library except `Backup-OBS.ps1`,
  which refuses to write *inside* it.
- No utility installs, launches or configures OBS, and none reads
  `global.ini`, `basic\profiles\**`, `plugin_config\**` or scene JSON.
- The only network caller is `Update-Library.ps1`, and only on request.

## [2026-11-09] Phase 3 - documentation

### Added

- `00-Documentation/` guides: `INSTALLATION_GUIDE.md`, `WINDOWS_SETUP.md`,
  `OBS_SCRIPTING_GUIDE.md`, `OBS_BACKUP_GUIDE.md`, `SECURITY_GUIDE.md`,
  `TROUBLESHOOTING.md`, `UPDATE_GUIDE.md` and `GLOSSARY.md`.
- `README.md` (English) and `README.ar.md` (Arabic), generated from
  `MANIFEST.json` plus authored prose.
- `LICENSES.md`, `COMPATIBILITY.md`, `DOWNLOAD_REPORT.md` and
  `11-Checksums/VERIFICATION_REPORT.md`, generated from the manifest.
- One `TOOL_INFO.md` per tool with the twelve fixed sections, plus a per-tool
  `Checksums.txt`.
- `02-Scripting-and-Automation/Custom-Scripts/README.md` and
  `10-Unverified/README.md`.

### Changed

- The guides are the canonical home for procedures; the README links to them
  instead of repeating them.
- Every count, version and status in the generated documents comes from the
  manifest, so the manifest remains the single source of truth.

### Security

- The Windows username was replaced by `<user>` in every authored file; a scan
  reports zero remaining occurrences.

## [2026-11-02] Phase 2 - acquisition

### Added

- Nine release assets downloaded to `Downloads/<version>/` and hashed:
  advanced-scene-switcher, autostarter, advanced-timer, advanced-filename-formatter,
  local-stream-marker, source-record, shaderfilter, tuna and multi-rtmp.
- Fifteen source snapshots pinned to a tag or commit under `Source/<ref>/`
  with `.git` removed.
- Upstream documentation snapshots under each `Documentation/` folder.
- `MANIFEST.schema.json` (draft-07) and `MANIFEST.json` describing all sixteen
  tools, their assets, licenses, compatibility, security review and sources.
- `13-Logs/cache/security/` static scan results per tool.

### Changed

- Source folders named after branches were renamed to their commit SHA.
- Non-`INCLUDED` tools were moved to `10-Unverified/`.
- `multi-rtmp` was pinned to `0.7.4`: releases from `0.7.4.1` target OBS 32.2.1
  and are incompatible with the detected OBS 32.0.1.
- `obs-websocket` was recorded as `DOCS-ONLY`: it ships with OBS 32.0.1 at
  version 5.6.3 and the tag has no release object to download.

### Security

- Every archive was listed before extraction and checked for absolute paths,
  `..` traversal and symlinks.
- Authenticode was checked for every `.exe`, `.dll` and `.msi`; results are
  recorded per asset.
- `libre-macros` was rated HIGH and moved to `10-Unverified` as `PENDING-USER`.
- `rse-obs-scripts` was marked `UNVERIFIED`: the repository has no license file.

## [2026-11-02] Phase 1 - registry resolution

### Added

- `13-Logs/phase1-report.md` and `13-Logs/cache/research/phase1.json` resolving
  all sixteen candidate projects: repository, owner, default branch, archived
  and fork flags, last commit and last release dates.

### Changed

- The shaderfilter fork `exeldro/obs-shaderfilter` was approved for use.

## [2026-11-02] Phase 0 - detection and skeleton

### Added

- `13-Logs/obs-baseline.json`: a metadata-only tripwire snapshot of the OBS
  install and data folders, with profiles, scenes, `global.ini`, logs and
  plugin configuration excluded from comparison.
- `13-Logs/state.json`, `13-Logs/execution.log` and `13-Logs/download.log`.
- The directory skeleton: `00-Documentation` through `13-Logs` and sixteen tool
  folders.

### Notes

- OBS 32.0.1 x64 was detected at `C:\Program Files\obs-studio` in non-portable
  mode. No bundled third-party plugins were found.
- The Python path configured inside OBS is `UNKNOWN`: it lives in `global.ini`,
  which this audit does not open. Only `C:\Python38` falls inside the OBS 32
  range (3.8 to 3.10).
