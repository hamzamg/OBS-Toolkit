# Licenses

Generated from `MANIFEST.json` on 2026-11-09T17:35:51Z. `INTENDED_USE = personal` (one user, one machine, no redistribution).

**This is not legal advice.** It records what the saved license files say and what the common
obligations are. If you redistribute a tool, a modified version, or a bundle that contains one,
read the actual license text in that tool's `Documentation\` folder and, for anything
non-trivial, ask a lawyer.

## Summary

| Tool | SPDX | License file | Ref | Status |
|---|---|---|---|---|
| Advanced Scene Switcher | `GPL-2.0-or-later` | `01-Scene-Management/Advanced-Scene-Switcher/Documentation/LICENSE` | release `1.37.2` | `CONFIRMED` |
| RSE OBS Scripts | `UNKNOWN` | none | commit `59191d2ca89b1c7affd6f440da8a4b780d53c5ae` | `ABSENT` |
| Libre Macros | `AGPL-3.0-or-later` | `10-Unverified/Libre-Macros/Documentation/LICENSE.md` | release `4.2.0` | `CONFIRMED` |
| Autostarter | `GPL-2.0-or-later` | `02-Scripting-and-Automation/Autostarter/Documentation/LICENSE` | release `v2.1.0` | `CONFIRMED` |
| Advanced Timer | `GPL-2.0-only` | `03-Timers-and-Counters/Advanced-Timer/Documentation/LICENSE` | release `6.0.0` | `CONFIRMED` |
| OBS Counter | `MIT` | `03-Timers-and-Counters/OBS-Counter/Documentation/LICENSE` | release `1.2.0` | `CONFIRMED` |
| Advanced Filename Formatter | `GPL-2.0-or-later` | `04-Recording-and-Organization/Advanced-Filename-Formatter/Documentation/LICENSE` | release `1.5.0` | `CONFIRMED` |
| Local Stream Marker | `MIT` | `04-Recording-and-Organization/Local-Stream-Marker/Documentation/LICENSE` | release `v1.13` | `CONFIRMED` |
| Source Record | `GPL-2.0-or-later` | `04-Recording-and-Organization/Source-Record/Documentation/LICENSE` | release `0.4.8` | `CONFIRMED` |
| OBS Screen Studio | `MIT` | `05-Screen-Production/OBS-Screen-Studio/Documentation/LICENSE` | commit `5739bc01f0d503f08b3fb21ddbfebfd42d387dcf` | `CONFIRMED` |
| Shaderfilter | `GPL-2.0-only` | `05-Screen-Production/Shaderfilter/Documentation/LICENSE` | release `2.6.1` | `CONFIRMED` |
| Filter Hotkeys | `MPL-2.0` | `06-Audio-and-Media/Filter-Hotkeys/Documentation/LICENSE` | release `1.0.2` | `CONFIRMED` |
| Tuna | `GPL-2.0-or-later` | `06-Audio-and-Media/Tuna/Documentation/LICENSE` | release `1.9.12` | `CONFIRMED` |
| Multi-RTMP | `GPL-2.0-or-later` | `07-Streaming/Multi-RTMP/Documentation/LICENSE` | release `0.7.4` | `CONFIRMED` |
| OBS WebSocket | `GPL-2.0-or-later` | `08-Remote-Control-and-AI/OBS-WebSocket/Documentation/LICENSE` | release `5.6.3` | `CONFIRMED` |
| OBS-MCP | `Apache-2.0` | `08-Remote-Control-and-AI/OBS-MCP/Documentation/LICENSE` | release `v0.2.0` | `CONFIRMED` |

Confirmed from a saved license file: **15 of 16**. The exception is RSE OBS Scripts,
whose file headers claim MIT but which has no `LICENSE` file at the pinned commit; it is
`UNVERIFIED` and quarantined.

## Per tool

### Advanced Scene Switcher

| Field | Value |
|---|---|
| SPDX | `GPL-2.0-or-later` |
| Saved file | `01-Scene-Management/Advanced-Scene-Switcher/Documentation/LICENSE` |
| Read at | release `1.37.2` |
| Status | `CONFIRMED` |

**Obligations (personal use).** Strong copyleft: distributing a modified version or a work based on it requires the source under GPL-2.0 or a later version, plus the license text. Private use creates no distribution obligation.

**Third-party components.**

| Component | License | Note |
|---|---|---|
| libcurl | curl (MIT-like) | Loaded at runtime as libcurl.dll by lib/curl-helper.cpp:11; not bundled in the source snapshot. |
| Qt 6 | UNKNOWN (provided by OBS) | Linked at build time; the DLLs ship with OBS Studio, not with this plugin. |

The saved LICENSE is the GPL version 2 text; source headers add 'or (at your option) any later version', hence GPL-2.0-or-later.

### RSE OBS Scripts

| Field | Value |
|---|---|
| SPDX | `UNKNOWN` |
| Saved file | none |
| Read at | commit `59191d2ca89b1c7affd6f440da8a4b780d53c5ae` |
| Status | `ABSENT` |

**Obligations (personal use).** UNKNOWN — no license text was confirmed, so no obligations can be stated. Do not redistribute.

**Third-party components.** None identified in the pinned snapshot.

Each script header states 'Distributed under MIT license <https://spdx.org/licenses/MIT.html>' (for example auto-execute-commands.lua:5), but no license file exists at the pinned commit, so the license status stays UNVERIFIED.

### Libre Macros

| Field | Value |
|---|---|
| SPDX | `AGPL-3.0-or-later` |
| Saved file | `10-Unverified/Libre-Macros/Documentation/LICENSE.md` |
| Read at | release `4.2.0` |
| Status | `CONFIRMED` |

**Obligations (personal use).** Strongest copyleft here: distribution triggers source availability, and running a modified version as a network service must offer its source to users. Private local use creates no distribution obligation.

**Third-party components.** None identified in the pinned snapshot.

AGPL v3 text with 'any later version' in source headers. AGPL network-copyleft obligations are the strongest in this library.

### Autostarter

| Field | Value |
|---|---|
| SPDX | `GPL-2.0-or-later` |
| Saved file | `02-Scripting-and-Automation/Autostarter/Documentation/LICENSE` |
| Read at | release `v2.1.0` |
| Status | `CONFIRMED` |

**Obligations (personal use).** Strong copyleft: distributing a modified version or a work based on it requires the source under GPL-2.0 or a later version, plus the license text. Private use creates no distribution obligation.

**Third-party components.**

| Component | License | Note |
|---|---|---|
| Qt 6 | UNKNOWN (provided by OBS) | Linked at build time (CMakeLists.txt:25); DLLs ship with OBS. |

GPLv2 text plus 'any later version' in source headers.

### Advanced Timer

| Field | Value |
|---|---|
| SPDX | `GPL-2.0-only` |
| Saved file | `03-Timers-and-Counters/Advanced-Timer/Documentation/LICENSE` |
| Read at | release `6.0.0` |
| Status | `CONFIRMED` |

**Obligations (personal use).** Strong copyleft, version 2 only: distributing a modified version or a work based on it requires the source under GPL-2.0 and the license text. Private use creates no distribution obligation.

**Third-party components.** None identified in the pinned snapshot.

GPLv2 text; no 'any later version' statement found in the script headers.

### OBS Counter

| Field | Value |
|---|---|
| SPDX | `MIT` |
| Saved file | `03-Timers-and-Counters/OBS-Counter/Documentation/LICENSE` |
| Read at | release `1.2.0` |
| Status | `CONFIRMED` |

**Obligations (personal use).** Attribution: keep the copyright line and the license text when you redistribute. No copyleft. No warranty.

**Third-party components.** None identified in the pinned snapshot.

MIT License, Copyright (c) 2020 HQupgradeHQ.

### Advanced Filename Formatter

| Field | Value |
|---|---|
| SPDX | `GPL-2.0-or-later` |
| Saved file | `04-Recording-and-Organization/Advanced-Filename-Formatter/Documentation/LICENSE` |
| Read at | release `1.5.0` |
| Status | `CONFIRMED` |

**Obligations (personal use).** Strong copyleft: distributing a modified version or a work based on it requires the source under GPL-2.0 or a later version, plus the license text. Private use creates no distribution obligation.

**Third-party components.**

| Component | License | Note |
|---|---|---|
| pyparsing | MIT | Declared at runtime; installed with pip --target into the OBS Python path when missing (adv-ff.py:62-98). |

GPLv2 text plus 'any later version' in source headers.

### Local Stream Marker

| Field | Value |
|---|---|
| SPDX | `MIT` |
| Saved file | `04-Recording-and-Organization/Local-Stream-Marker/Documentation/LICENSE` |
| Read at | release `v1.13` |
| Status | `CONFIRMED` |

**Obligations (personal use).** Attribution: keep the copyright line and the license text when you redistribute. No copyleft. No warranty.

**Third-party components.** None identified in the pinned snapshot.

MIT License, Copyright (c) 2022 Archie.

### Source Record

| Field | Value |
|---|---|
| SPDX | `GPL-2.0-or-later` |
| Saved file | `04-Recording-and-Organization/Source-Record/Documentation/LICENSE` |
| Read at | release `0.4.8` |
| Status | `CONFIRMED` |

**Obligations (personal use).** Strong copyleft: distributing a modified version or a work based on it requires the source under GPL-2.0 or a later version, plus the license text. Private use creates no distribution obligation.

**Third-party components.** None identified in the pinned snapshot.

GPLv2 text plus 'any later version' in source headers.

### OBS Screen Studio

| Field | Value |
|---|---|
| SPDX | `MIT` |
| Saved file | `05-Screen-Production/OBS-Screen-Studio/Documentation/LICENSE` |
| Read at | commit `5739bc01f0d503f08b3fb21ddbfebfd42d387dcf` |
| Status | `CONFIRMED` |

**Obligations (personal use).** Attribution: keep the copyright line and the license text when you redistribute. No copyleft. No warranty.

**Third-party components.** None identified in the pinned snapshot.

MIT License text with 'Copyright (c) 2026' and no holder name. The grant is unambiguous; the holder line is blank.

### Shaderfilter

| Field | Value |
|---|---|
| SPDX | `GPL-2.0-only` |
| Saved file | `05-Screen-Production/Shaderfilter/Documentation/LICENSE` |
| Read at | release `2.6.1` |
| Status | `CONFIRMED` |

**Obligations (personal use).** Strong copyleft, version 2 only: distributing a modified version or a work based on it requires the source under GPL-2.0 and the license text. Private use creates no distribution obligation.

**Third-party components.**

| Component | License | Note |
|---|---|---|
| Bundled example shaders (165 .shader/.effect files) | Mixed: repo GPL-2.0, 6 files explicit GPLv2, 3 files MIT | Six files carry an explicit GNU GPLv2 header (e.g. data/examples/circle-mask-filter.shader:5). Three carry MIT (clock_digital_nixie.shader:38; the Ashima webgl-noise block in fire-3.effect:165). The rest carry no header and inherit the repository license. |

GPLv2 text; no 'any later version' statement found. MIT-licensed shader fragments are compatible with GPLv2 redistribution but keep their attribution.

### Filter Hotkeys

| Field | Value |
|---|---|
| SPDX | `MPL-2.0` |
| Saved file | `06-Audio-and-Media/Filter-Hotkeys/Documentation/LICENSE` |
| Read at | release `1.0.2` |
| Status | `CONFIRMED` |

**Obligations (personal use).** File-level copyleft: a modified MPL file that you distribute must stay under MPL-2.0 and its source must be available. Larger works may use other licenses. Keep notices.

**Third-party components.** None identified in the pinned snapshot.

Mozilla Public License Version 2.0. File-level copyleft: modified files must stay MPL-2.0.

### Tuna

| Field | Value |
|---|---|
| SPDX | `GPL-2.0-or-later` |
| Saved file | `06-Audio-and-Media/Tuna/Documentation/LICENSE` |
| Read at | release `1.9.12` |
| Status | `CONFIRMED` |

**Obligations (personal use).** Strong copyleft: distributing a modified version or a work based on it requires the source under GPL-2.0 or a later version, plus the license text. Private use creates no distribution obligation.

**Third-party components.**

| Component | License | Note |
|---|---|---|
| cpp-httplib | MIT | Bundled at deps/cpp-httplib/httplib.h; header states 'Copyright (c) 2022 Yuji Hirose ... MIT License'. |
| TagLib | UNKNOWN (not bundled in snapshot) | Credited in README for metadata extraction; license file not present locally. |
| libmpdclient | UNKNOWN (not bundled in snapshot) | Credited in README for MPD connections; license file not present locally. |
| libcurl | UNKNOWN (not bundled in snapshot) | Credited in README for remote content and API calls. |

GPLv2 text plus 'any later version' in source headers.

### Multi-RTMP

| Field | Value |
|---|---|
| SPDX | `GPL-2.0-or-later` |
| Saved file | `07-Streaming/Multi-RTMP/Documentation/LICENSE` |
| Read at | release `0.7.4` |
| Status | `CONFIRMED` |

**Obligations (personal use).** Strong copyleft: distributing a modified version or a work based on it requires the source under GPL-2.0 or a later version, plus the license text. Private use creates no distribution obligation.

**Third-party components.**

| Component | License | Note |
|---|---|---|
| nlohmann/json | MIT | Bundled at dep/nlohmann-json/json.hpp; header declares SPDX-License-Identifier: MIT. |
| Qt 6 | UNKNOWN (provided by OBS) | Linked at build time; DLLs ship with OBS. |

GPLv2 text plus 'any later version' in source headers.

### OBS WebSocket

| Field | Value |
|---|---|
| SPDX | `GPL-2.0-or-later` |
| Saved file | `08-Remote-Control-and-AI/OBS-WebSocket/Documentation/LICENSE` |
| Read at | release `5.6.3` |
| Status | `CONFIRMED` |

**Obligations (personal use).** Strong copyleft: distributing a modified version or a work based on it requires the source under GPL-2.0 or a later version, plus the license text. Private use creates no distribution obligation.

**Third-party components.** None identified in the pinned snapshot.

Tag 5.6.3 exists without a GitHub release object, so the protocol docs were read at the tag. GPLv2 text plus 'any later version'.

### OBS-MCP

| Field | Value |
|---|---|
| SPDX | `Apache-2.0` |
| Saved file | `08-Remote-Control-and-AI/OBS-MCP/Documentation/LICENSE` |
| Read at | release `v0.2.0` |
| Status | `CONFIRMED` |

**Obligations (personal use).** Attribution: keep the license, copyright notices and any NOTICE file; state changes. Patent grant included. No copyleft.

**Third-party components.** None identified in the pinned snapshot.

Apache License 2.0. Python dependencies are declared in pyproject.toml and installed by the user.

## Notes that apply to the whole library

- Every tool here is loaded by OBS, which is itself GPL-2.0-or-later. Loading a plugin or
  script into your own OBS does not create a distribution.
- Source snapshots are stored for audit and rollback. They keep their original license files;
  do not remove those files.
- `MANIFEST.json` records the SPDX identifier and the exact file the identifier was read from.
  Where a project's README and its `LICENSE` disagree, the `LICENSE` file wins and the
  disagreement is noted in the tool record.
- Bundled example content can carry different licenses from the plugin. Shaderfilter is the
  recorded case: 6 examples carry a GPLv2 header, 3 carry MIT, and the rest inherit the
  repository license.

See also: `00-Documentation/SECURITY_GUIDE.md` and `COMPATIBILITY.md`.
