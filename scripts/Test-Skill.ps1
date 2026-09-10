[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repositoryRootPath = [System.IO.Path]::GetFullPath($RepositoryRoot)
$skillPath = Join-Path $repositoryRootPath 'skills\virtual-ppt-content-generator'
$skillFile = Join-Path $skillPath 'SKILL.md'
$updaterPath = Join-Path $repositoryRootPath 'skills\virtual-ppt-content-generator-updater'
$updaterSkillFile = Join-Path $updaterPath 'SKILL.md'
$updaterScriptFile = Join-Path $updaterPath 'scripts\update.ps1'
$updaterSourceFile = Join-Path $updaterPath 'references\update-source.json'
$versionFile = Join-Path $repositoryRootPath 'VERSION'

$requiredFiles = @(
    'SKILL.md',
    'references\CONTENT_PATTERNS.md',
    'references\CONTENT_VARIATION.md',
    'references\EXAMPLE.md',
    'references\INDUSTRY_MODULES.md',
    'references\REALISM_RULES.md',
    'references\SCENE_MODELS.md'
)

foreach ($relativePath in $requiredFiles) {
    $requiredPath = Join-Path $skillPath $relativePath
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Missing required file: $relativePath"
    }
}

foreach ($updaterRequiredPath in @($updaterSkillFile, $updaterScriptFile, $updaterSourceFile)) {
    if (-not (Test-Path -LiteralPath $updaterRequiredPath -PathType Leaf)) {
        throw "Missing updater file: $updaterRequiredPath"
    }
}

if (-not (Test-Path -LiteralPath $versionFile -PathType Leaf)) {
    throw 'Missing repository VERSION file.'
}

$skillContent = Get-Content -Raw -LiteralPath $skillFile
$frontmatterMatch = [regex]::Match(
    $skillContent,
    '\A---\r?\n(?<frontmatter>.*?)\r?\n---(?:\r?\n|\z)',
    [System.Text.RegularExpressions.RegexOptions]::Singleline
)

if (-not $frontmatterMatch.Success) {
    throw 'SKILL.md has invalid or missing YAML frontmatter delimiters.'
}

$frontmatter = $frontmatterMatch.Groups['frontmatter'].Value

if ($frontmatter -notmatch '(?m)^name:\s*virtual-ppt-content-generator\s*$') {
    throw 'SKILL.md name must be virtual-ppt-content-generator.'
}

if ($frontmatter -notmatch '(?m)^description:\s*\S.+$') {
    throw 'SKILL.md must contain a non-empty description.'
}

$skillVersionMatch = [regex]::Match($frontmatter, '(?m)^version:\s*(?<version>\d+\.\d+\.\d+)\s*$')
if (-not $skillVersionMatch.Success) {
    throw 'SKILL.md must contain a semantic version such as 2.6.0.'
}

$repositoryVersion = (Get-Content -Raw -LiteralPath $versionFile).Trim()
$skillVersion = $skillVersionMatch.Groups['version'].Value

try {
    [void][version]$repositoryVersion
    [void][version]$skillVersion
} catch {
    throw 'VERSION and SKILL.md version must both be valid semantic versions.'
}

if ($repositoryVersion -ne $skillVersion) {
    throw "Version mismatch: VERSION=$repositoryVersion, SKILL.md=$skillVersion"
}

if ($skillContent -match '(?m)^\s*\[TODO:[^\]]*\]\s*$') {
    throw 'SKILL.md contains an unfinished TODO placeholder.'
}

$updaterContent = Get-Content -Raw -LiteralPath $updaterSkillFile
if ($updaterContent -notmatch '(?m)^name:\s*virtual-ppt-content-generator-updater\s*$') {
    throw 'Updater Skill has an invalid name.'
}
if ($updaterContent -notmatch '(?m)^version:\s*\d+\.\d+\.\d+\s*$') {
    throw 'Updater Skill must contain a semantic version.'
}

$updaterSource = Get-Content -Raw -LiteralPath $updaterSourceFile | ConvertFrom-Json
if ($updaterSource.repository -ne 'muzisanjin0405/virtual-ppt-content-generator') {
    throw 'Updater repository is not the expected official repository.'
}
if ($updaterSource.skill_name -ne 'virtual-ppt-content-generator') {
    throw 'Updater target Skill name is invalid.'
}

Write-Host "Skill validation passed: virtual-ppt-content-generator v$skillVersion"
Write-Host 'Updater validation passed: virtual-ppt-content-generator-updater'
