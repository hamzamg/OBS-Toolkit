# Security Policy

## Supported versions

| Version | Supported   |
| ------- | ----------- |
| 0.x (main branch) | :white_check_mark: |
| < 0.x (anything before) | :x: |

This is a personal, docs-and-tools library. Nothing is served or installed by a
server, and no downloaded tool is ever executed as part of maintenance.

## Reporting a vulnerability

Please report security issues **privately** through GitHub Security Advisories
(the **Security** tab of this repository → **Report a vulnerability**).

Do not open a public issue for a vulnerability, and never include secrets,
tokens, or private paths in any report.

## Scope

In scope:

- `12-Utilities/*.ps1` — the shell utilities (only these run anywhere).
- The `MANIFEST.json` metadata and checksums in `11-Checksums/`.

Out of scope (report upstream instead):

- The downloaded third-party tools in `09-Optional-Tools/` and
  `10-Unverified/`, and their sources in `Source/`. Report to the original
  project.

## What we do

- Nothing is installed, executed, or configured from this repository.
- Checksums are recorded for every asset (`11-Checksums/SHA256SUMS.txt`) and
  can be re-verified at any time with
  `12-Utilities/Verify-Checksums.ps1`.
- Signatures on the patch/release assets are recorded per asset in
  `MANIFEST.json`; tools without verifiable signatures are quarantined in
  `10-Unverified/` until a maintainer reviews them.
