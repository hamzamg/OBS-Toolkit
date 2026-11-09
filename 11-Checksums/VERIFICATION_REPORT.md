# Verification Report

Generated from `MANIFEST.json` on 2026-11-09T17:12:55Z, after recomputing every asset hash from disk.

## What was checked

For every release asset: the file exists, its size matches the manifest, the SHA-256
recomputed from disk equals the manifest value, and it equals the line in
`11-Checksums/SHA256SUMS.txt`. Signature status comes from reading the Authenticode
signature on the downloaded file (not from running it).

## Assets

| Tool | File | Size (bytes) | SHA-256 | Reference source | Reference match | Signature | Status | Downloaded (UTC) |
|---|---|---:|---|---|---|---|---|---|
| Advanced Scene Switcher | `advanced-scene-switcher-1.37.2-windows-x64-Installer.exe` | 110,314,092 | `517b6aaa0ef5f9db0b3e6dae5ddb8c95744b15ab1d8132dfd0e4c0599390e2cd` | PUBLISHER | match | unsigned | `VERIFIED` | 2026-11-02T19:40:23Z |
| Autostarter | `autostarter.zip` | 40,781 | `c3023dedb7e4412237cdd3ac10430f63beee88192c3252e56125c06b23cfc609` | NONE | no reference | unsigned | `COMPUTED-ONLY` | 2026-11-02T19:39:45Z |
| Advanced Timer | `advanced-timer.lua` | 20,020 | `8df66dea65fa07a7e87479fda2961efaed6600c0b3e3cfd87c439f2030562ba9` | NONE | no reference | not checked | `COMPUTED-ONLY` | 2026-11-02T19:38:59Z |
| Advanced Filename Formatter | `adv-ff.py` | 55,569 | `2df6c01410bc080e9ebc915f8f57d0677bc65e234c8844e75c8bb8beebac9563` | PLATFORM | match | not checked | `INTEGRITY-ONLY` | 2026-11-02T19:39:46Z |
| Local Stream Marker | `local-stream-marker.1.13.zip` | 13,299 | `777c2ed5e1c237d0b3384eca01a8c52e156237a3577c8efd549c9e8a81db954b` | PLATFORM | match | not checked | `INTEGRITY-ONLY` | 2026-11-02T19:39:49Z |
| Source Record | `source-record-0.4.8-windows.zip` | 356,380 | `c2e461afc42746bb8f1861f0aaef63c42f5cc436b55da1a21b3b07bc6d014074` | PLATFORM | match | valid — CN=Exeldro, O=Exeldro, L=Woerden, S=Utrecht, C=NL | `VERIFIED` | 2026-11-02T19:39:50Z |
| Shaderfilter | `obs-shaderfilter-2.6.1-windows.zip` | 4,795,506 | `bdb5af0c8d6afb9b488a0dd4235a26786c221fb01d9082786e51aceb0deae37d` | PLATFORM | match | unsigned | `INTEGRITY-ONLY` | 2026-11-02T19:39:53Z |
| Tuna | `tuna-1.9.12-windows-x64.zip` | 7,640,564 | `e7bfd593d91d0742218a107a38b53c801a612dceabbf7b0c41ed8f9e29325d77` | PLATFORM | match | unsigned | `INTEGRITY-ONLY` | 2026-11-02T19:40:00Z |
| Multi-RTMP | `obs-multi-rtmp-0.7.4.0-windows-x64.zip` | 2,111,888 | `601c014a2962261429f736826c441192e3da6f5ceebc7807f10907e8be3326d5` | PLATFORM | match | unsigned | `INTEGRITY-ONLY` | 2026-11-02T19:39:10Z |

**Result: all nine assets verified against the manifest and `SHA256SUMS.txt` at generation time.**

## Per-tool Checksums.txt

Each tool folder has a `Checksums.txt` with `<sha256>  <relative/path>` lines for its own
assets and `Documentation/` files. `11-Checksums/SHA256SUMS.txt` is the union of those plus
`MANIFEST.json` and `MANIFEST.schema.json`. All paths use forward slashes and are relative to
the library root, so `sha256sum -c` works from the root in a POSIX shell.

Source snapshots are **not** hashed file by file. GitHub's generated source archives are not
byte-stable, so a source tree is identified by its commit SHA in `MANIFEST.json`.

## What each status proves — and does not prove

| Status | What it proves | What it does not prove |
|---|---|---|
| `VERIFIED` | The file's SHA-256 matches a value the **publisher** published (release notes or release API) and/or a valid Authenticode signature identifies the signer and shows the file was not altered after signing. | That the code is safe, bug-free, or free of malicious intent. A publisher can sign a bad build. |
| `INTEGRITY-ONLY` | The file's SHA-256 matches the digest **GitHub's API** reported for that release asset. The file is the one GitHub served for that release. | That the publisher signed it, or that the upload was not compromised. GitHub's digest is transport integrity, not authorship. |
| `COMPUTED-ONLY` | We hashed the file and recorded the value. There was no publisher checksum and no usable signature to compare against. | Anything about the file's origin or safety. The hash only lets you detect later changes. |
| `FAILED` | The file did not match the expected value. | — (a failure is a failure) |
| `NOT-DOWNLOADED` | No asset exists for this tool; a pinned source snapshot is the artifact. | Nothing about binaries, because there are none. |

### Signature column

| Value | Meaning |
|---|---|
| `valid — CN=…` | Authenticode signature validates and names the signer. It does not mean the signer is trustworthy, only that the file is theirs and unmodified. |
| `unsigned` | No Authenticode signature. Common for small OBS plugins; the hash is the only integrity check. |
| `not checked` | Not a PE file (a `.lua` or `.py` script), so Authenticode does not apply. |

## Notable verification facts

- **Advanced Scene Switcher** — the 110 MB installer's SHA-256 matches the value published in the
  release notes (`PUBLISHER`). The installer itself is unsigned. The alternative
  `windows-x64-obs32.zip` has a publisher SHA-256 recorded in the manifest but was not downloaded.
- **Source Record** — the zip's hash matches GitHub's platform digest, and both shipped DLLs carry
  a valid Authenticode signature (`CN=Exeldro`). This is the strongest evidence in the library.
- **Autostarter and Advanced Timer** — no publisher checksum and no signature; `COMPUTED-ONLY`.
- **Advanced Timer** — the release asset is 20,020 bytes; the repository file at tag `6.0.0` is
  20,598 bytes. Both are preserved and the release asset is the installable one.
- **OBS WebSocket** — no asset: OBS 32.0.1 bundles 5.6.3. Only documentation is stored, pinned to
  submodule commit `1c9306b1e200704ebe192e06c893dfc06b097c43`.

## How to re-verify

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\12-Utilities\Verify-Checksums.ps1
```

Exit code `0` means every listed file matches. `1` means a finding (missing, extra, or
mismatched file); the dated report in `13-Logs\` names it. `2` means the script itself failed.
