# Unverified Tools

This folder holds tools whose license or security status is **not resolved**. They
are kept because deleting evidence is worse than quarantining it, and because you
may decide to accept the risk knowingly. They use the same per-tool layout as the
rest of the library (`TOOL_INFO.md`, `Source\`, `Documentation\`, `Checksums.txt`).

Nothing here is recommended. Nothing here was executed.

## Contents

| Tool | Decision | Risk | Why it is here | What would resolve it |
|---|---|---|---|---|
| [Libre Macros](Libre-Macros/TOOL_INFO.md) | `PENDING-USER` | `HIGH` | The tool compiles and runs Lua supplied at runtime, can create processes through LuaJIT FFI, and its Python helper contains a committed WebSocket password. AGPL-3.0-or-later is confirmed, so the license is not the blocker — the capability is. | An explicit decision from you to keep or delete it, plus a password rotation if you keep it. |
| [RSE OBS Scripts](RSE-OBS-Scripts/TOOL_INFO.md) | `UNVERIFIED` | `MEDIUM` | No `LICENSE` or `COPYING` file exists at the pinned commit `59191d2`. The file headers claim MIT, but a claim in a header is not a license grant this library can verify. It also has no releases and no tags, and its last commit is beyond the 18-month staleness threshold. | A `LICENSE` file added by the author, or your written acceptance of the header claim. |

## Rules for this folder

1. **Do not copy these files into OBS** without reading the tool record and
   accepting the specific risk it names.
2. Do not treat the presence of a file here as approval. The decision field is
   authoritative: `PENDING-USER` means "waiting for you", `UNVERIFIED` means "not
   confirmed".
3. If you resolve an item, move the whole tool folder into the correct category
   folder, update `MANIFEST.json` (`decision`, `folder`, and the license fields),
   then run `12-Utilities\Generate-Manifest.ps1` and
   `12-Utilities\Verify-Checksums.ps1`.
4. If you delete an item, remove its manifest entry too, then regenerate the
   checksums. Do not leave a manifest path pointing at a missing folder.

## Why the whole folder moves, not just the file

The brief requires every non-`INCLUDED` tool to live under `10-Unverified\`. The
path is part of the record: a reader can tell a tool's status from its location
before opening anything. `TOOL_INFO.md` section 2 states the same thing.

## Related

- `../DOWNLOAD_REPORT.md` — the quarantined section, generated from the manifest.
- `../00-Documentation/SECURITY_GUIDE.md` — the review checklist used here.
- `../00-Documentation/UPDATE_GUIDE.md` — how to re-verify after a change.
