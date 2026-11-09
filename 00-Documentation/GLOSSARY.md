# Glossary | مسرد المصطلحات

Technical terms used in this library. The Arabic column is a working translation,
not an official OBS translation; where OBS's own Arabic UI uses a different word,
the English term and the code/path are what matter.

| English | العربية | Definition |
|---|---|---|
| Asset | ملف الإصدار | A file attached to a GitHub release (installer, zip, script). Its name is never changed here. |
| Authenticode | توقيع أوثنتيكود | Microsoft's code-signing format. A valid signature shows who signed a DLL/EXE and that it was not altered after signing. |
| Checksum (SHA-256) | بصمة الملف | A 64-hex-digit fingerprint of a file's bytes. A different hash means a different file. |
| Commit SHA | بصمة الإصدار البرمجي | The 40-hex identifier of one exact source state in Git. Used here to pin source snapshots. |
| Copyleft | حقوق متبقية | A license rule that requires derivative works to keep the same license (GPL, AGPL, MPL at file level). |
| DOCS-ONLY | توثيق فقط | Decision for a tool that is not downloaded because OBS already bundles it; only its documentation is stored. |
| Dock | لوحة عائمة | A panel inside the OBS window that a plugin can add (for example a scene switcher dock). |
| FFI | واجهة استدعاء أجنبية | Foreign Function Interface: Lua code calling native Windows functions directly. Powerful and risky. |
| Filter | مرشح | An effect applied to a source (blur, color correction, shader). |
| Fork | نسخة متفرعة | A copy of a project maintained by someone else. Treated as a different project here. |
| GPL-2.0-only | رخصة جنو العامة 2 فقط | Strong copyleft, version 2 only. Distribution of a modified work requires source under the same license. |
| GPL-2.0-or-later | رخصة جنو العامة 2 أو أحدث | Same, but the recipient may choose a later GPL version. |
| AGPL-3.0-or-later | رخصة جنو العمومية الأفيرو 3 | Strongest copyleft here: network use of a modified version also triggers source availability. |
| MIT | رخصة MIT | Permissive: keep the notice, no copyleft, no warranty. |
| Apache-2.0 | رخصة أباتشي 2 | Permissive with an explicit patent grant and notice requirements. |
| MPL-2.0 | رخصة موزيلا العامة 2 | File-level copyleft: modified MPL files stay MPL; larger works may use other licenses. |
| Hotkey | مفتاح اختصار | A key combination OBS binds to an action. Script hotkeys appear under Settings → Hotkeys. |
| INCLUDED | مُدرَج | Decision: the tool passed license, integrity, compatibility and security checks. |
| Integrity-only | سلامة فقط | Verification where the hash matches GitHub's platform digest but there is no publisher checksum or signature. |
| LuaJIT | لوا جيت | The fast Lua 5.1 implementation OBS embeds. Provides `ffi` and `jit`. |
| Manifest | البيان | `MANIFEST.json`, the single source of truth for every fact in this library. |
| MCP | بروتوكول سياق النموذج | Model Context Protocol: a standard way for an AI client to call tools exposed by a local server. |
| OBS WebSocket | ويب سوكيت OBS | The API bundled with OBS that lets external programs control it. Port 4455 by default. |
| PENDING-USER | بانتظار قرار المستخدم | Decision: parked because it needs an explicit user decision (for example a HIGH-risk tool). |
| Plugin | إضافة | A native DLL that OBS loads from `obs-plugins\64bit`. |
| Portable OBS | OBS محمول | An OBS install that keeps its configuration inside its own folder (`config\obs-studio`). |
| Python Settings | إعدادات بايثون | The OBS dialog that selects the interpreter used by Python scripts. |
| Replay Buffer | مخزن الإعادة | OBS's rolling buffer that saves the last N seconds on demand. Some features need OBS 33+. |
| Risk level | مستوى الخطر | `LOW`/`MEDIUM`/`HIGH`, derived from what the reviewed source can do. Not a safety guarantee. |
| Scene collection | مجموعة المشاهد | The file holding scenes, sources, filters and script settings. |
| Script Log | سجل النصوص | The OBS tab that shows errors from Lua/Python scripts. |
| SHA256SUMS | ملف البصمات | `11-Checksums\SHA256SUMS.txt`, a `sha256sum -c`-compatible list of every asset and doc. |
| Snapshot | لقطة | A pinned copy of a source tree at one commit, without `.git`. |
| SPDX | معرّف الرخصة | A standard short identifier for a license, for example `GPL-2.0-or-later`. |
| STALE | قديم | Maintenance status: no release or commit within 18 months. |
| Stream key | مفتاح البث | A secret that authorizes streaming to a service. Stored in the OBS profile. |
| SUPPORTED / LIKELY / UNKNOWN | مدعوم / محتمل / غير معروف | Compatibility status against the detected OBS 32.0.1. |
| Tripwire | كاشف التغيير | A before/after metadata snapshot used to prove the audit did not modify OBS. |
| UNVERIFIED | غير مُتحقَّق | Decision: license or security status is unresolved; stored in `10-Unverified\`. |
| VERIFIED | مُتحقَّق | Verification where the hash matches a publisher checksum and/or a valid signature. |
| WebSocket | ويب سوكيت | A persistent two-way connection used by OBS WebSocket clients. |

## Reading the status words

| Word | Where it appears | Meaning |
|---|---|---|
| `INCLUDED` | decision | Passed all checks |
| `UNVERIFIED` | decision | License or security unresolved |
| `REJECTED` | decision | Failed a check; not stored |
| `UNAVAILABLE` | decision | Official source no longer offers it |
| `DOCS-ONLY` | decision | Bundled with OBS; docs only |
| `PENDING-USER` | decision | Needs your explicit decision |
| `SUPPORTED` | compatibility | Documented to work with OBS 32.0.1 |
| `LIKELY` | compatibility | Built for an older OBS; no documented break |
| `UNKNOWN` | compatibility | No evidence either way |
| `INCOMPATIBLE` | compatibility | Documented to require a different OBS |
| `ACTIVE` | maintenance | Release or commit within 18 months |
| `STALE` | maintenance | Nothing within 18 months |
| `ARCHIVED` | maintenance | Repository archived |
| `DEPRECATED` | maintenance | Author says do not use |
| `VERIFIED` | verification | Publisher checksum and/or signature matched |
| `INTEGRITY-ONLY` | verification | Platform digest matched only |
| `COMPUTED-ONLY` | verification | We hashed it; nothing to compare |
| `FAILED` | verification | Did not match |
| `NOT-DOWNLOADED` | verification | No asset exists |
| `LOW` / `MEDIUM` / `HIGH` | risk | Capability found in the reviewed source |
