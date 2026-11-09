⬇️ [**Jump to downloads**](#user-content-downloads)

# Important notes:
* The minimum supported OBS version is OBS 31.1.1.
* Please make sure to [back up](https://github.com/WarmUpTill/SceneSwitcher/wiki/Saving-and-loading-settings#how-to-create-and-import-a-backup-of-your-settings) your settings!
* If you run into any issues, please either post in the [OBS forums](https://obsproject.com/forum/threads/advanced-scene-switcher.48264/) or create an [issue on GitHub](https://github.com/WarmUpTill/SceneSwitcher/issues/new/choose)!
* Windows users installing via zip archive: The plugin layout changed with OBS 33.
  The `windows-x64.zip` archive is intended for OBS 33 and newer.
  For OBS 32 and older use the `windows-x64-obs32.zip` or `windows-x64-portable-obs32.zip` archives instead.
  The installer supports both OBS 32 and OBS 33.

# 1.37.2 Hotfix Changes:

* Added an Arabic translation. (Moh-01)
* Fixed the plugin not loading after an OBS auto-update.
  It would only load again after rebooting OBS once.
* Fixed a crash when macros run during OBS shutdown.
* Fixed a crash when importing settings.
* Fixed several locale mistakes.

# 1.37.1 Hotfix Changes:

* Fixed flatpak build.

# Additions:

* Added **undo / redo support for macros**.
  Renaming, adding, removing, grouping and modifying macros, as well as adding, removing and changing conditions and actions, can now be undone.
  Undo / redo can be disabled in the "General" tab if not desired or causes unexpected issues.
* Added the option to **prompt users for input when importing macros**.
  When exporting, values such as scenes, sources or file paths that only exist on your setup can be marked as "replaceable".
  Whoever imports the macro will then be asked to supply their own values for each of them.
  Defaults can be provided and a list of options to choose from can be defined.
  This should hopefully make sharing macros across different setups a bit easier.
* Added a **"Now Playing" condition** (Windows only).
  <img width="623" height="345" alt="img" src="https://github.com/user-attachments/assets/8ecbead0-02c4-4391-bdc2-c8fa958ebf7d" />  
  It can check the playback state, title, artist, album and app name of media currently playing on the system, for example in Spotify or a browser.
  The values are also exposed as macro properties.
* Added a **"Create source" action**.
  <img width="605" height="190" alt="img" src="https://github.com/user-attachments/assets/6f29fb0b-87c6-4eb8-bef0-ef7e1332030f" />  
* Macro groups can now be **nested** inside other macro groups.  
  <img width="296" height="97" alt="img" src="https://github.com/user-attachments/assets/bc67e8ac-339b-4903-98c2-208d268d486a" />  
* Added new options to the **"Variable" action**:
  * Current scene
  * Previous scene
  * Preview scene
  * Current transition
  * Date / time
  * Date / time with offset
  * Unix timestamp
  * Time since last scene change
  * JSON array length
  * Set JSON field
  * Format number
* Added an option to the **"Audio" condition** to check if a source is enabled on a specific audio track.
* Added a **"Mono" option** to the "Play audio" action.

# Changes:

* The **"Get user input" option of the "Variable" action** now also supports file, folder, scene and source selection widgets.
* The **"Variables" tab** now shows how many macros use each variable. Hovering over the entry lists the macros.
* The macro search can now **search for macros using a given variable**.
* The macro export dialog now selects the variables used by the exported macros by default.
* Added an option to the "General" tab to **disable blinking of the inactive status** label in the settings window and status dock. (nanopink)
* The selected setting of the "Source" and "Filter" actions and conditions is now kept visible if the source is currently unavailable.
* Improved drag behavior of macro segments. (nanopink)
* The "Cursor" condition now supports drawing a screen region rectangle instead of having to enter the coordinates manually. (nanopink)
* The **dock window name field** in the macro dock settings is now a combo box, making it easier to combine docks into a single dock window without having to know the exact dock window titles beforehand.
* Improved **KWin window detection support for the OBS Flatpak** on Linux.
* Setting Twitch stream tags now supports Unicode letters.
* Added the `AdvancedSceneSwitcherVersion` vendor request to the obs-websocket API, which returns version and commit information.
* Added Ubuntu 26 packages.
* Updated the Chinese translation. (Rygtx)

# Fixes:

* Fixed the "Video" condition not supporting variables properly.
* Fixed the "Source" action not being able to modify settings that were never set before and have no default value (e.g. the text of a newly created text source).
* Fixed potential crashes in the "Speech Recognition" condition.
* Fixed the Twitch token being treated as invalid after loading a broken config.
* Fixed the Twitch token status not reflecting reality if the cached user ID is empty.
* Fixed a crash when rapidly inserting or removing conditions and actions.
* Fixed a crash in the "Run" action on macOS.
* Fixed a crash when changing the scene collection on macOS.
* Fixed a crash on shutdown when using the "Play audio" action.
* Fixed a crash on shutdown related to obs-websocket vendor events. (TheRealAlexV)
* Fixed macro pause hotkey descriptions not showing macro name in the OBS settings.

# Checksums:
    advanced-scene-switcher-1.37.2-macos-universal.pkg: 73e9b636b96ee21891fc7d25e2cec43a651e26bc61958b255c81fb1c1169ad10
    advanced-scene-switcher-1.37.2-macos-universal.tar.xz: 19f7b243e7be0d44ae236e4303e9ac9854012644020f6a23125c3e1fe2fc3e95
    advanced-scene-switcher-1.37.2-source.tar.xz: 3040e5ad483751312e66e6c835448cbfbda7c43d11c4c46d8921a04d4f036a2d
    advanced-scene-switcher-1.37.2-windows-x64-Installer.exe: 517b6aaa0ef5f9db0b3e6dae5ddb8c95744b15ab1d8132dfd0e4c0599390e2cd
    advanced-scene-switcher-1.37.2-windows-x64-obs32.zip: 04f7637265ef0966025bcd2a97a20f328dafc7773568b05ec74f77b6d86bc692
    advanced-scene-switcher-1.37.2-windows-x64-portable-obs32.zip: 82ef4764f73446a5e16f0721e2a24439001511ce453ef206e46002708199afed
    advanced-scene-switcher-1.37.2-windows-x64.zip: 6cac51299d1367a80d00509ac7ad3c1fa12f4807883c0e01db7568aa98a3f28d
    advanced-scene-switcher-1.37.2-x86_64-ubuntu24.04-linux-gnu.ddeb: bbe945c81ba57c6364d6bbc23c7c7696157666cd4fe930f077c192ed8239c8f0
    advanced-scene-switcher-1.37.2-x86_64-ubuntu24.04-linux-gnu.deb: 5ab657a2a958a1d1a2297ad1515f8e49d095965429e9c37cea7c527a6789ebfc
    advanced-scene-switcher-1.37.2-x86_64-ubuntu24.04-linux-gnu.tar.xz: d05fac785f08395863770c1ac925135cf56ce2c2e3c6f9daa2aa5fba27dbfcd9
    advanced-scene-switcher-1.37.2-x86_64-ubuntu26.04-linux-gnu.ddeb: b9b33cbe97a6bac2df596323fa26435162170cacb7db857ff9e2ba96732d1680
    advanced-scene-switcher-1.37.2-x86_64-ubuntu26.04-linux-gnu.deb: 65efa4bb7d7933ca48cf6e48fe5f768d944128642f198f554fa4aa8c664f07e9
    advanced-scene-switcher-1.37.2-x86_64-ubuntu26.04-linux-gnu.tar.xz: 78a64e94e5c97caa4e947c3a490a116128083d591cb5772e76a814e9fe6d8daa

<a name="downloads"></a>
# Downloads:
The installers are listed in the **Assets** section below ↓
