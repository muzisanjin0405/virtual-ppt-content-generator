# Virtual PPT Content Generator

这是一个用于生成虚拟 PPT 完整中文文案的 Codex Skill。它会先建立统一的虚拟项目世界观和数据账本，再按照场景、行业、受众与决策目标生成逐页内容。

当前版本：`2.6.0`

## 仓库结构

```text
.
├─ .github/workflows/release.yml
├─ scripts/
│  ├─ Build-Release.ps1
│  ├─ Install-Or-Update.ps1
│  └─ Test-Skill.ps1
├─ skills/
│  ├─ virtual-ppt-content-generator/
│  │  ├─ SKILL.md
│  │  └─ references/
│  └─ virtual-ppt-content-generator-updater/
│     ├─ SKILL.md
│     ├─ references/update-source.json
│     └─ scripts/update.ps1
├─ .gitignore
├─ README.md
└─ VERSION
```

Codex 可安装的 Skill 位于：

```text
skills/virtual-ppt-content-generator
```

## 从 GitHub 安装

在 Codex 中一次性安装主 Skill 与更新器 Skill：

```text
$skill-installer
请从以下 GitHub 仓库安装两个 Skill：
https://github.com/muzisanjin0405/virtual-ppt-content-generator/tree/main/skills/virtual-ppt-content-generator
https://github.com/muzisanjin0405/virtual-ppt-content-generator/tree/main/skills/virtual-ppt-content-generator-updater
```

也可以从 GitHub Release 安装或更新：

```powershell
.\scripts\Install-Or-Update.ps1
```

更新脚本会下载最新正式 Release，校验 SHA-256，在安装前保留旧版本备份；如果安装失败，会尝试恢复原版本。

安装更新器后，用户可以直接在 Codex 中输入：

```text
$virtual-ppt-content-generator-updater
```

上述命令会检查并安装最新正式版本。若只想检查、不修改本地文件：

```text
$virtual-ppt-content-generator-updater 只检查版本
```

## 本地校验

```powershell
.\scripts\Test-Skill.ps1
```

校验内容包括：

- Skill 目录和必要参考文件是否完整；
- `SKILL.md` frontmatter 是否包含正确名称、描述与版本；
- 根目录 `VERSION` 是否与 Skill 版本一致；
- 是否残留未完成的 TODO 占位符。

## 创建发布包

```powershell
.\scripts\Build-Release.ps1
```

默认输出：

```text
dist/virtual-ppt-content-generator-v2.6.0.zip
dist/virtual-ppt-content-generator-v2.6.0.zip.sha256
dist/virtual-ppt-content-generator-updater-v1.0.0.zip
dist/virtual-ppt-content-generator-updater-v1.0.0.zip.sha256
```

ZIP 内保留 `virtual-ppt-content-generator/` 顶层目录，可直接解压到 Codex skills 目录。

## 发布新版本

1. 修改 Skill 内容。
2. 同步更新根目录 `VERSION` 与 `SKILL.md` 中的 `version`。
3. 执行 `Test-Skill.ps1`。
4. 提交修改，并创建与版本一致的标签。

```powershell
git tag v2.6.1
git push origin main
git push origin v2.6.1
```

推送 `v*` 标签后，GitHub Actions 会自动完成校验、打包、SHA-256 生成和 Release 发布。

## 更新策略

- `main` 用于下一版本开发，也提供两个 Skill 的首次安装路径；
- GitHub Release 用于稳定版本分发；
- 更新器只读取最新正式 Release，不自动安装草稿版或预发布版；
- 每次发布都应递增语义版本号；
- 不建议让用户在已安装目录中直接修改文件。

## 授权说明

本仓库暂未包含许可证文件。公开发布前，请根据你的分发与修改许可要求选择并添加合适的开源或商业许可证。
