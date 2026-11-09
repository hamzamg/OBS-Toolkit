<!-- Pull request checklist for this repository. -->

## What this change does

<!-- One or two sentences. Never paste secrets, tokens, or private paths. -->

## Checklist

- [ ] Branch name follows the convention (`feat/...`, `fix/...`, `docs/...`, `chore/...`).
- [ ] `pwsh -NoProfile -ExecutionPolicy Bypass -File .\12-Utilities\Test-Library.ps1` passes (12/12).
- [ ] `pwsh -NoProfile -ExecutionPolicy Bypass -File .\12-Utilities\Verify-Checksums.ps1` reports 0 findings (run when files under `Downloads/` or `Documentation/` changed).
- [ ] Markdown still passes `npx -y markdownlint "**/*.md" --config .markdownlint.json`.
- [ ] `CHANGELOG.md` has an entry under `[Unreleased]`.
- [ ] No secrets, keys, or `C:\Users\<user>` paths were added anywhere.
- [ ] Nothing that was downloaded has been run or installed (prove it with `13-Logs/execution.log`).

## Verification

<!-- Paste the QA line (for example: QA: 12 pass, 0 fail, 0 skip) and any script output that is relevant. -->
