---
name: virtual-ppt-content-generator-updater
description: Check and update the installed virtual-ppt-content-generator Skill from its official GitHub Releases. Use when the user explicitly invokes this updater or asks to check, install, upgrade, or update virtual-ppt-content-generator. Do not use for other skills.
metadata:
  short-description: Update virtual-ppt-content-generator from GitHub Releases
version: 1.0.0
---

# Virtual PPT Content Generator Updater

Update only the installed `virtual-ppt-content-generator` Skill from the configured official GitHub repository.

## Source

Read [references/update-source.json](references/update-source.json) before running the updater. The repository, target Skill name, and release asset prefix must match that file. Never substitute a different repository unless the user explicitly provides and authorizes it.

## Commands

Treat an explicit invocation with no additional instruction as authorization to check and install the latest stable version:

```text
$virtual-ppt-content-generator-updater
```

The following wording also checks and installs:

```text
$virtual-ppt-content-generator-updater 检查并更新到最新版
```

When the user says `只检查`、`仅检查`、`check only` or equivalent, run in check-only mode and make no filesystem changes:

```text
$virtual-ppt-content-generator-updater 只检查版本
```

## Execution

Run the bundled PowerShell script from this Skill directory:

```powershell
./scripts/update.ps1
```

For check-only mode:

```powershell
./scripts/update.ps1 -CheckOnly
```

Do not reproduce the updater logic manually when the bundled script is available.

## Safety requirements

- Update only `virtual-ppt-content-generator` under the resolved Codex skills directory.
- Use only the latest non-draft, non-prerelease GitHub Release returned by the configured repository.
- Require both the versioned ZIP asset and its `.sha256` asset.
- Verify SHA-256 before extracting or changing the installed Skill.
- Require the release tag and downloaded `SKILL.md` version to match.
- Do not downgrade when the installed version is equal to or newer than the release.
- Preserve the previous installation as a timestamped backup.
- If replacement fails after backup, restore the previous installation.
- Never remove backups automatically.
- Report network, release, checksum, archive, permission, and validation failures without making unrelated changes.

## Result reporting

Always report:

- installed version, if detected;
- latest stable release version;
- whether no update was needed, an update was available, or installation completed;
- backup path when an existing installation was replaced;
- that the updated Skill becomes available on the next Codex turn.
