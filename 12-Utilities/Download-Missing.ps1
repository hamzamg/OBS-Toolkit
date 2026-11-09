#Requires -Version 7.0
<#
.SYNOPSIS
    Restores library files that are missing locally, starting with the two that
    GitHub cannot hold in git.

.DESCRIPTION
    Two files in this library are not tracked by git because GitHub rejects
    files larger than 100 MB:
      - advanced-scene-switcher-1.37.2-windows-x64-Installer.exe (105.20 MB)
      - scene example/obs-zoom-blured-bg.psd (93.86 MB)
    They stay on disk here and are verified by Test-Library.ps1, but a fresh
    clone of the repo will not contain them. This script brings them back.

    Default mode is check-only: it reads MANIFEST.json, checks every recorded
    asset (and the one git-excluded snapshot file), and prints what is missing,
    what is present and matching, and what is present but different. It
    downloads nothing.

    With -Apply it downloads the missing files:
      - Downloaded assets come from the recorded `url` in MANIFEST.json
        (github.com release assets). SHA-256 is computed on the downloaded
        bytes and, when a reference digest exists in the manifest, must match
        before the file is kept. A mismatch deletes the download.
      - The psd file is not a recorded asset. It is restored by cloning the
        upstream repository at the pinned commit into a temporary folder and
        copying that one file. Its provenance is the pinned commit, not a hash.

    The script never overwrites an existing file whose hash differs; it reports
    it and leaves it alone. It never installs anything, never runs anything,
    and never touches OBS.

    Network access happens only when -Apply is used, and only to the URLs
    recorded in MANIFEST.json (github.com) or to the upstream repository.

.PARAMETER Apply
    Actually download and restore. Without it the script only lists findings.

.PARAMETER Tool
    Restrict the work to one or more tool ids from MANIFEST.json (for example
    advanced-scene-switcher or obs-screen-studio-script).

.PARAMETER Json
    Print the per-file result as JSON instead of a table.

.EXAMPLE
    pwsh -NoProfile -ExecutionPolicy Bypass -File .\12-Utilities\Download-Missing.ps1

.EXAMPLE
    .\Download-Missing.ps1 -Apply -WhatIf

.EXAMPLE
    .\Download-Missing.ps1 -Apply -Tool advanced-scene-switcher

.EXAMPLE
    .\Download-Missing.ps1 -Apply -Tool obs-screen-studio-script

.NOTES
    Exit codes: 0 = nothing missing or everything restored, 1 = at least one
    file could not be restored or a present file does not match the manifest,
    2 = script error (bad parameter, missing manifest).
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter()]
    [switch]$Apply,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string[]]$Tool,

    [Parameter()]
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'Common.psm1') -Force

$script:UserAgent = 'OBS-Toolkit/1.0 (+https://github.com)'

function Test-OfficialHost {
    <#
    .SYNOPSIS
        Returns true when the URL host is one of the official sources.
    #>
    param([AllowNull()][string]$Url)
    if ([string]::IsNullOrWhiteSpace($Url)) { return $false }
    try {
        $hostName = ([System.Uri]$Url).Host
    }
    catch { return $false }
    return $hostName -in @('github.com', 'api.github.com', 'objects.githubusercontent.com',
                       'raw.githubusercontent.com', 'obsproject.com')
}

function Get-RestorePlan {
    <#
    .SYNOPSIS
        Builds the list of files to check: every recorded asset, plus the one
        git-excluded snapshot file.

    .DESCRIPTION
        The psd file is described by a hardcoded entry because the manifest
        records the snapshot as a commit, not as a file list. Its restore
        source is derived from the manifest repository URL and commit_sha.
    #>
    param($Man)

    $plan = New-Object System.Collections.Generic.List[object]

    foreach ($tool in $Man.tools) {
        foreach ($asset in @($tool.assets)) {
            $plan.Add([pscustomobject]@{
                ToolId     = [string]$tool.id
                ToolName   = [string]$tool.name
                FileName   = [string]$asset.filename
                LocalPath  = [string]$asset.local_path
                Url        = [string]$asset.url
                SizeBytes  = [long]$asset.size_bytes
                Sha256     = [string]$asset.sha256
                Reference  = if ($null -ne $asset.reference_checksum) { [string]$asset.reference_checksum.source } else { $null }
                Restore    = 'download'
            })
        }
    }

    foreach ($tool in $Man.tools) {
        if ([string]$tool.id -ne 'obs-screen-studio-script') { continue }
        $snap = $tool.source_snapshot
        if (-not $snap) { continue }
        $repoUrl = [string]$tool.repository.url
        $m = [regex]::Match($repoUrl, '^https?://github\.com/(?<owner>[^/]+)/(?<repo>[^/]+?)(?:\.git)?/?$')
        if (-not $m.Success) { continue }
        $rawUrl = "https://raw.githubusercontent.com/$($m.Groups['owner'].Value)/$($m.Groups['repo'].Value)/$($snap.commit_sha)/scene%20example/obs-zoom-blured-bg.psd"
        $plan.Add([pscustomobject]@{
            ToolId     = [string]$tool.id
            ToolName   = [string]$tool.name
            FileName   = 'obs-zoom-blured-bg.psd'
            LocalPath  = "05-Screen-Production/OBS-Screen-Studio/Source/$($snap.commit_sha)/scene example/obs-zoom-blured-bg.psd"
            Url        = $rawUrl
            SizeBytes  = [long]98417984
            Sha256     = $null
            Reference  = $null
            Restore    = 'download'
        })
    }

    return $plan
}

function Invoke-DownloadFile {
    <#
    .SYNOPSIS
        Downloads one file to a .partial, verifies it, and moves it in place.
    #>
    param(
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$TargetPath
    )

    $parent = Split-Path -Parent $TargetPath
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }

    $partial = $TargetPath + '.partial'
    if (Test-Path -LiteralPath $partial) { Remove-Item -LiteralPath $partial -Force }

    Write-Host ("  downloading {0}" -f ([System.Uri]$Url).Host) -ForegroundColor DarkGray
    Invoke-WebRequest -Uri $Url -OutFile $partial -TimeoutSec 900 `
        -Headers @{ 'User-Agent' = $script:UserAgent } -ErrorAction Stop
    $sha = (Get-FileHash -LiteralPath $partial -Algorithm SHA256).Hash.ToLower()
    return @{ Path = $partial; Sha256 = $sha }
}

try {
    $root = Get-ToolkitRoot
    $man = Get-ToolkitManifest

    if ($Tool) {
        foreach ($id in $Tool) {
            if ($id -notin @($man.tools.id)) {
                Write-ToolkitError "unknown tool id: $id"
                exit 2
            }
        }
    }

    $scope = if ($Tool) { @($man.tools | Where-Object { $_.id -in $Tool }) } else { @($man.tools) }
    $plan = Get-RestorePlan -Man ([pscustomobject]@{ tools = $scope })

    $results = New-Object System.Collections.Generic.List[object]
    $failure = $false

    foreach ($item in $plan) {
        $absPath = Join-Path $root ($item.LocalPath -replace '/', '\')
        $entry = [pscustomobject]@{
            tool       = $item.ToolId
            file       = $item.FileName
            path       = $item.LocalPath
            status     = ''
            detail     = ''
        }

        if (Test-Path -LiteralPath $absPath) {
            if ($item.Sha256) {
                $sha = (Get-FileHash -LiteralPath $absPath -Algorithm SHA256).Hash.ToLower()
                if ($sha -eq $item.Sha256) {
                    $entry.status = 'present'
                    $entry.detail = 'hash matches manifest'
                }
                else {
                    $entry.status = 'mismatch'
                    $entry.detail = 'present but SHA-256 differs; not overwritten'
                    $failure = $true
                }
            }
            else {
                $entry.status = 'present'
                $entry.detail = 'pinned-commit provenance (no hash recorded)'
            }
        }
        else {
            if (-not $Apply) {
                $entry.status = 'missing'
                $entry.detail = "not on disk; would download from $([System.Uri]$item.Url | Select-Object -ExpandProperty Host)"
            }
            elseif (-not (Test-OfficialHost $item.Url)) {
                $entry.status = 'failed'
                $entry.detail = "URL host is not an official source; refusing: $($item.Url)"
                $failure = $true
            }
            elseif (-not $PSCmdlet.ShouldProcess($item.LocalPath, 'Download missing file')) {
                $entry.status = 'missing'
                $entry.detail = 'whatif'
            }
            else {
                try {
                    $got = Invoke-DownloadFile -Url $item.Url -TargetPath $absPath
                    if ($item.Sha256 -and $got.Sha256 -ne $item.Sha256) {
                        Remove-Item -LiteralPath $got.Path -Force
                        $entry.status = 'failed'
                        $entry.detail = 'downloaded SHA-256 does not match manifest; download deleted'
                        $failure = $true
                    }
                    else {
                        Move-Item -LiteralPath $got.Path -Destination $absPath -Force
                        $entry.status = 'restored'
                        $entry.detail = if ($item.Sha256) { 'hash matches manifest' } else { 'pinned-commit provenance (no hash recorded)' }
                    }
                }
                catch {
                    if (Test-Path -LiteralPath ($absPath + '.partial')) { Remove-Item -LiteralPath ($absPath + '.partial') -Force }
                    $entry.status = 'failed'
                    $entry.detail = $_.Exception.Message
                    $failure = $true
                }
            }
        }

        $results.Add($entry)
    }

    if ($Json) {
        [pscustomobject]@{
            generated_at_utc = Get-ToolkitTimestamp
            apply            = [bool]$Apply
            files            = @($results.ToArray())
        } | ConvertTo-Json -Depth 5
    }
    else {
        Write-Host ''
        $modeText = if ($Apply) { 'Restore missing files (apply)' } else { 'Missing files check (read-only)' }
        Write-Host $modeText -ForegroundColor Cyan
        Write-Host ''
        Write-Host ("{0,-32} {1,-10} {2,-28} {3}" -f 'TOOL', 'STATUS', 'FILE', 'DETAIL')
        Write-Host ('-' * 110)
        foreach ($r in $results) {
            Write-Host ("{0,-32} {1,-10} {2,-28} {3}" -f $r.tool, $r.status, $r.file, $r.detail)
        }
        $restored = @($results | Where-Object status -eq 'restored').Count
        $missing = @($results | Where-Object status -eq 'missing').Count
        $mismatch = @($results | Where-Object status -eq 'mismatch').Count
        $failed = @($results | Where-Object status -eq 'failed').Count
        Write-Host ''
        Write-Host ("checked={0} restored={1} missing={2} mismatch={3} failed={4}" -f $results.Count, $restored, $missing, $mismatch, $failed)

        if (-not $Apply -and $missing -gt 0) {
            Write-Host 'Nothing was downloaded. To restore the missing files:' -ForegroundColor Cyan
            Write-Host '  .\Download-Missing.ps1 -Apply'
            Write-Host 'Review each file with -Tool <id> first (see the table above).' -ForegroundColor Yellow
        }
    }

    $action = if ($Apply) { 'download-missing' } else { 'download-missing-dryrun' }
    $logStatus = if ($failure) { 'fail' } else { 'ok' }
    Write-ToolkitLog -Phase 'utilities' -ToolId '-' -Action $action -Target 'MANIFEST.json' `
        -Status $logStatus `
        -Detail ("checked={0} restored={1} missing={2} mismatch={3} failed={4}" -f `
            $results.Count,
            @($results | Where-Object status -eq 'restored').Count,
            @($results | Where-Object status -eq 'missing').Count,
            @($results | Where-Object status -eq 'mismatch').Count,
            @($results | Where-Object status -eq 'failed').Count)

    $exitCode = if ($failure) { 1 } else { 0 }
    exit $exitCode
}
catch {
    Write-ToolkitError $_.Exception.Message
    try { Write-ToolkitLog -Phase 'utilities' -ToolId '-' -Action 'download-missing' -Target 'error' -Status fail -Detail $_.Exception.Message } catch { }
    exit 2
}
