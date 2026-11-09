# Project workflow — OBS-Toolkit

## Scope (strict — no searching outside the project)
- Treat the library root (`C:\Users\<user>\Documents\Project\OBS-Toolkit`) as the
  only work boundary for this session.
- Never list, search, read, glob, or grep outside the project root (for example
  other project folders, personal files, or unrelated system directories)
  without the user's explicit request and approval in advance.
- Environment facts come from the documented utilities (`Get-OBSInfo.ps1`,
  `Test-Library.ps1`) and from files inside the library — not from browsing the
  machine.
- If a helper file or generator outside the project is needed (for example the
  document generators in the temp folder), say so and wait for the user's
  approval first. Never reach for it silently.

## Before any work
- `git switch main && git pull --ff-only` (if a remote exists); verify `git status` is clean.
- Create a new branch per task: `feat/...`, `fix/...`, `docs/...`. Never edit `main` directly.

## Plan and approval
- Show a short plan before starting; wait for the user's approval.
- After implementation: verify and test it yourself, update `CHANGELOG.md`, commit with a Conventional Commit message.
- Push the branch and open a Pull Request, but do not merge until asked explicitly (yes/no). After approval, merge, delete the branch, then `git switch main && git pull --ff-only`.

## Safety
- Never put passwords, keys or secrets in code or files. If one appears, stop and warn the user.
- Everything in this project follows the audit rules: never install, run or configure OBS; only the utilities listed in `12-Utilities` may run, and only as documented.
- Final summary in plain language: what was done, what failed, what is waiting on the user.
