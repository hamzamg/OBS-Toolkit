## Added

- **One-click installers (`install.sh` / `install.bat`).** Check for Python (offer to install it if missing), install `obs-mcp`, verify the installed `obs-mcp` command actually resolves to the Python just used (catches stale/shadowed installs on machines with multiple Pythons), and optionally write the config for Claude Desktop and/or LM Studio automatically — no manual JSON editing required for a first-time setup.
- **`diagnose_av_health` pipeline tool.** Pulls `GetStats` + `GetStreamStatus` + `GetRecordStatus` in one call and interprets the render-skip/output-skip/congestion ratios instead of returning raw numbers — distinguishes a GPU/scene bottleneck from an encoder bottleneck from a network bottleneck, and flags low disk space before it silently kills a recording. **148 tools total now.**

## Fixed

- **Concurrent tool calls could corrupt results.** `obsws-python`'s request layer does a bare send-then-recv with no request-ID matching, so two overlapping calls could each read the other's response off the socket. `OBSClient.execute()` now serializes every call (connect included) through one lock.
- **The OBS WebSocket password was logged in plaintext** on every connect. `obsws_python`'s logger is now capped at `WARNING` so this never reaches stderr.
- **An ordinary OBS-side error (bad scene name, out-of-range value) forced a full reconnect on the next call**, identically to an actual dropped connection — even though the socket was still healthy. Only a real connection failure resets the client now.
- **`clean_audio_input` could append the Noise Gate after a pre-existing Compressor/Suppression filter**, inverting the gate-first ordering the whole tool exists to guarantee. It now anchors its three managed stages as an adjacent, correctly-ordered group regardless of what already existed on the input.

**Full Changelog**: https://github.com/xDarkzx/OBS_MCP/compare/v0.1.0...v0.2.0

