# Project workflow — OBS-Toolkit

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
