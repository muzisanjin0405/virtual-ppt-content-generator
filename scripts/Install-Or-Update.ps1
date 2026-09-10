[CmdletBinding()]
param(
    [ValidatePattern('^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$')]
    [string]$Repository = 'muzisanjin0405/virtual-ppt-content-generator',

    [string]$SkillRoot
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$skillName = 'virtual-ppt-content-generator'

if ([string]::IsNullOrWhiteSpace($SkillRoot)) {
    $codexHomeValue = [Environment]::GetEnvironmentVariable('CODEX_HOME')
    if ([string]::IsNullOrWhiteSpace($codexHomeValue)) {
        $codexHomeValue = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.codex'
    }
    $SkillRoot = Join-Path $codexHomeValue 'skills'
}

$skillRootPath = [System.IO.Path]::GetFullPath($SkillRoot)
$destinationPath = Join-Path $skillRootPath $skillName
$apiHeaders = @{
    Accept = 'application/vnd.github+json'
    'User-Agent' = 'virtual-ppt-content-generator-updater'
    'X-GitHub-Api-Version' = '2022-11-28'
}

$githubToken = [Environment]::GetEnvironmentVariable('GITHUB_TOKEN')
if (-not [string]::IsNullOrWhiteSpace($githubToken)) {
    $apiHeaders.Authorization = "Bearer $githubToken"
}

$releaseUrl = "https://api.github.com/repos/$Repository/releases/latest"
$release = Invoke-RestMethod -Uri $releaseUrl -Headers $apiHeaders
$releaseVersionText = ([string]$release.tag_name).TrimStart('v')

try {
    $releaseVersion = [version]$releaseVersionText
} catch {
    throw "Latest release tag is not a semantic version: $($release.tag_name)"
}

$archiveName = "virtual-ppt-content-generator-v$releaseVersionText.zip"
$checksumName = "$archiveName.sha256"
$archiveAsset = $release.assets | Where-Object { $_.name -eq $archiveName } | Select-Object -First 1
$checksumAsset = $release.assets | Where-Object { $_.name -eq $checksumName } | Select-Object -First 1

if ($null -eq $archiveAsset -or $null -eq $checksumAsset) {
    throw "Release $($release.tag_name) does not contain $archiveName and $checksumName."
}

$currentVersion = $null
$currentSkillFile = Join-Path $destinationPath 'SKILL.md'
if (Test-Path -LiteralPath $currentSkillFile -PathType Leaf) {
    $currentContent = Get-Content -Raw -LiteralPath $currentSkillFile
    $currentMatch = [regex]::Match($currentContent, '(?m)^version:\s*(?<version>\d+\.\d+\.\d+)\s*$')
    if ($currentMatch.Success) {
        $currentVersion = [version]$currentMatch.Groups['version'].Value
    }
}

if ($null -ne $currentVersion -and $currentVersion -ge $releaseVersion) {
    Write-Host "Already up to date: v$currentVersion"
    return
}

$temporaryBase = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
$temporaryWork = Join-Path $temporaryBase ("vppt-skill-" + [guid]::NewGuid().ToString('N'))
$downloadedArchive = Join-Path $temporaryWork $archiveName
$downloadedChecksum = Join-Path $temporaryWork $checksumName
$expandedRoot = Join-Path $temporaryWork 'expanded'
$stagedPath = Join-Path $skillRootPath (".$skillName-staging-" + [guid]::NewGuid().ToString('N'))
$backupPath = $null
$destinationMoved = $false

try {
    New-Item -ItemType Directory -Path $temporaryWork -Force | Out-Null
    New-Item -ItemType Directory -Path $expandedRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $skillRootPath -Force | Out-Null

    Invoke-WebRequest -Uri $archiveAsset.browser_download_url -Headers $apiHeaders -OutFile $downloadedArchive
    Invoke-WebRequest -Uri $checksumAsset.browser_download_url -Headers $apiHeaders -OutFile $downloadedChecksum

    $expectedChecksum = ((Get-Content -Raw -LiteralPath $downloadedChecksum).Trim() -split '\s+')[0].ToLowerInvariant()
    $actualChecksum = (Get-FileHash -LiteralPath $downloadedArchive -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($expectedChecksum -ne $actualChecksum) {
        throw 'Downloaded archive failed SHA-256 verification.'
    }

    Expand-Archive -LiteralPath $downloadedArchive -DestinationPath $expandedRoot
    $expandedSkillPath = Join-Path $expandedRoot $skillName
    $expandedSkillFile = Join-Path $expandedSkillPath 'SKILL.md'
    if (-not (Test-Path -LiteralPath $expandedSkillFile -PathType Leaf)) {
        throw 'Release archive does not contain the expected Skill directory.'
    }

    $expandedContent = Get-Content -Raw -LiteralPath $expandedSkillFile
    $expandedVersionMatch = [regex]::Match($expandedContent, '(?m)^version:\s*(?<version>\d+\.\d+\.\d+)\s*$')
    if (-not $expandedVersionMatch.Success -or $expandedVersionMatch.Groups['version'].Value -ne $releaseVersionText) {
        throw 'Release tag and SKILL.md version do not match.'
    }

    Copy-Item -LiteralPath $expandedSkillPath -Destination $stagedPath -Recurse

    if (Test-Path -LiteralPath $destinationPath) {
        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $backupPath = Join-Path $skillRootPath (".$skillName-backup-$timestamp")
        Move-Item -LiteralPath $destinationPath -Destination $backupPath
        $destinationMoved = $true
    }

    Move-Item -LiteralPath $stagedPath -Destination $destinationPath
    $destinationMoved = $false

    Write-Host "Installed $skillName v$releaseVersionText"
    if ($null -ne $backupPath) {
        Write-Host "Previous version backup: $backupPath"
    }
    Write-Host 'The updated Skill will be available on the next Codex turn.'
} catch {
    if ($destinationMoved -and $null -ne $backupPath -and -not (Test-Path -LiteralPath $destinationPath)) {
        Move-Item -LiteralPath $backupPath -Destination $destinationPath
    }
    throw
} finally {
    $resolvedTemporaryWork = [System.IO.Path]::GetFullPath($temporaryWork)
    $temporaryLeaf = Split-Path -Leaf $resolvedTemporaryWork
    if (
        $resolvedTemporaryWork.StartsWith($temporaryBase, [System.StringComparison]::OrdinalIgnoreCase) -and
        $temporaryLeaf.StartsWith('vppt-skill-', [System.StringComparison]::OrdinalIgnoreCase) -and
        (Test-Path -LiteralPath $resolvedTemporaryWork)
    ) {
        Remove-Item -LiteralPath $resolvedTemporaryWork -Recurse -Force
    }

    $resolvedStagedPath = [System.IO.Path]::GetFullPath($stagedPath)
    if (
        (Split-Path -Parent $resolvedStagedPath) -eq $skillRootPath -and
        (Split-Path -Leaf $resolvedStagedPath).StartsWith(".$skillName-staging-") -and
        (Test-Path -LiteralPath $resolvedStagedPath)
    ) {
        Remove-Item -LiteralPath $resolvedStagedPath -Recurse -Force
    }
}
