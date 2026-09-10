[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repositoryRootPath = [System.IO.Path]::GetFullPath($RepositoryRoot)
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $repositoryRootPath 'dist'
}
$outputDirectoryPath = [System.IO.Path]::GetFullPath($OutputDirectory)

& (Join-Path $PSScriptRoot 'Test-Skill.ps1') -RepositoryRoot $repositoryRootPath

$version = (Get-Content -Raw -LiteralPath (Join-Path $repositoryRootPath 'VERSION')).Trim()
$skillSource = Join-Path $repositoryRootPath 'skills\virtual-ppt-content-generator'
$updaterSource = Join-Path $repositoryRootPath 'skills\virtual-ppt-content-generator-updater'
$updaterSkillContent = Get-Content -Raw -LiteralPath (Join-Path $updaterSource 'SKILL.md')
$updaterVersionMatch = [regex]::Match($updaterSkillContent, '(?m)^version:\s*(?<version>\d+\.\d+\.\d+)\s*$')
if (-not $updaterVersionMatch.Success) {
    throw 'Unable to read updater version.'
}
$updaterVersion = $updaterVersionMatch.Groups['version'].Value

New-Item -ItemType Directory -Path $outputDirectoryPath -Force | Out-Null

function New-SkillReleasePackage {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath,
        [Parameter(Mandatory = $true)][string]$PackageName
    )

    $archivePath = Join-Path $outputDirectoryPath "$PackageName.zip"
    $checksumPath = "$archivePath.sha256"

    if (Test-Path -LiteralPath $archivePath) {
        Remove-Item -LiteralPath $archivePath -Force
    }
    if (Test-Path -LiteralPath $checksumPath) {
        Remove-Item -LiteralPath $checksumPath -Force
    }

    Compress-Archive -LiteralPath $SourcePath -DestinationPath $archivePath -CompressionLevel Optimal
    $checksum = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
    $checksumLine = "$checksum  $([System.IO.Path]::GetFileName($archivePath))"
    Set-Content -LiteralPath $checksumPath -Value $checksumLine -Encoding utf8NoBOM

    Write-Host "Release package: $archivePath"
    Write-Host "SHA-256 file:  $checksumPath"
}

New-SkillReleasePackage -SourcePath $skillSource -PackageName "virtual-ppt-content-generator-v$version"
New-SkillReleasePackage -SourcePath $updaterSource -PackageName "virtual-ppt-content-generator-updater-v$updaterVersion"
