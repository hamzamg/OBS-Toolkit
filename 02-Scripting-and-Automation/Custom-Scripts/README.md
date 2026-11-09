# Custom Scripts

**This folder is yours.** It is empty on purpose.

- Put scripts **you** wrote here, or scripts you are editing.
- Never put downloaded code here. Downloaded and audited tools live under their
  own category folder (`01-…` to `08-…`), and unresolved ones live in
  `10-Unverified\`. Keeping your work separate means you can always tell what
  this library reviewed from what you wrote later.
- Nothing here is covered by `MANIFEST.json` or `11-Checksums\SHA256SUMS.txt`.
  If you want a script tracked, copy it into a tool folder and add it to the
  manifest with `12-Utilities\Generate-Manifest.ps1`.

## Suggested layout

```
Custom-Scripts/
├── README.md
├── lua/
│   └── my-script.lua
└── python/
    └── my_script.py
```

## Minimal Lua skeleton

```lua
obs = obslua

function script_description()
    return "One line that says what this does."
end

function script_properties()
    local props = obs.obs_properties_create()
    -- add controls here
    return props
end

function script_defaults(settings)
end

function script_update(settings)
end

function script_load(settings)
end

function script_save(settings)
end

function script_unload()
end
```

## Minimal Python skeleton

```python
import obspython as obs

def script_description():
    return "One line that says what this does."

def script_properties():
    props = obs.obs_properties_create()
    return props

def script_defaults(settings):
    pass

def script_update(settings):
    pass

def script_load(settings):
    pass

def script_save(settings):
    pass

def script_unload():
    pass
```

## Before you load your own script

- Test with one scene collection you can throw away.
- Read `../00-Documentation/OBS_SCRIPTING_GUIDE.md` for load order and debugging.
- Read `../00-Documentation/SECURITY_GUIDE.md` before sharing a script: anything
  that reads a file, opens a socket or starts a process deserves a second look,
  even when you wrote it.
- Script settings are stored in the **scene collection**, not next to the file.
  Back it up before you iterate.
