#Requires -Version 7.0
<#
.SYNOPSIS
    Copies the OBS user configuration to a timestamped folder outside this library.

.DESCRIPTION
    Backs up the parts of %APPDATA%\obs-studio that cannot be re-downloaded:
    basic\ (profiles and scene collections), plugin_config\, plugin_manager\ and
    global.ini. It never opens the contents of those files; it only enumerates
    names and sizes and copies them.

    Default mode is a dry run: it prints the source, the destination it would use,
    the item list and the total size, and changes nothing. A real copy requires
    -Execute plus typing BACKUP at the prompt.

    Safety rules enforced here:
      - the destination must be outside the library root,
      - the destination must be an absolute path,
      - a timestamped subfolder is created and the script fails if it already
        exists (it never overwrites an older backup),
      - the result contains stream keys and tokens; the script says so and does
        not encrypt (use BitLocker or a password-protected archive).

    This script does not install, modify or launch OBS.

.PARAMETER Destination
    Parent folder for the backup, for example D:\OBS-Backups. Required for
    -Execute. Must be outside the library.

.PARAMETER DataDir
    OBS configuration folder. Defaults to %APPDATA%\obs-studio.

.PARAMETER Execute
    Perform the copy. Without it the script is a dry run.

.PARAMETER IncludeLogs
    Also copy logs\. Off by default: logs are not needed for a restore and can
    contain absolute paths.

.EXAMPLE
    pwsh -NoProfile -ExecutionPolicy Bypass -File .\12-Utilities\Backup-OBS.ps1

.EXAMPLE
    .\Backup-OBS.ps1 -Destination 'D:\OBS-Backups' -Execute

.EXAMPLE
    .\Backup-OBS.ps1 -Destination 'D:\OBS-Backups' -Execute -WhatIf

.NOTES
    Exit codes: 0 = dry run completed or backup written, 1 = refused or failed,
    2 = script error.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Destination,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$DataDir,

    [Parameter()]
    [switch]$Execute,

    [Parameter()]
    [switch]$IncludeLogs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'Common.psm1') -Force

function Get-ItemSize {
    param([Parameter(Mandatory)][string]$Path)
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        return [long](Get-Item -LiteralPath $Path).Length
    }
    $sum = (Get-ChildItem -LiteralPath $Path -Recurse -File -Force -ErrorAction SilentlyContinue |
        Measure-Object -Property Length -Sum).Sum
    if ($null -eq $sum) { return [long]0 }
    return [long]$sum
}

function Get-FileCount {
    param([Parameter(Mandatory)][string]$Path)
    if (Test-Path -LiteralPath $Path -PathType Leaf) { return 1 }
    return @(Get-ChildItem -LiteralPath $Path -Recurse -File -Force -ErrorAction SilentlyContinue).Count
}

try {
    $root = Get-ToolkitRoot

    if (-not $DataDir) {
        $DataDir = Join-Path $env:APPDATA 'obs-studio'
    }
    if (-not (Test-Path -LiteralPath $DataDir)) {
        Write-ToolkitError "OBS configuration folder not found: $DataDir"
        exit 1
    }
    $DataDir = (Resolve-Path -LiteralPath $DataDir).Path

    $candidates = @('basic', 'plugin_config', 'plugin_manager', 'global.ini')
    if ($IncludeLogs) { $candidates += 'logs' }

    $items = [System.Collections.Generic.List[object]]::new()
    foreach ($name in $candidates) {
        $src = Join-Path $DataDir $name
        if (-not (Test-Path -LiteralPath $src)) { continue }
        $kind = if (Test-Path -LiteralPath $src -PathType Leaf) { 'file' } else { 'folder' }
        $items.Add([pscustomobject]@{
            name  = $name
            path  = $src
            kind  = $kind
            bytes = (Get-ItemSize -Path $src)
            files = (Get-FileCount -Path $src)
        })
    }

    if ($items.Count -eq 0) {
        Write-ToolkitError "none of the expected items exist under $DataDir (looked for: $($candidates -join ', '))"
        exit 1
    }

    $totalBytes = ($items | Measure-Object -Property bytes -Sum).Sum
    $totalFiles = ($items | Measure-Object -Property files -Sum).Sum
    $stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')

    $destParent = $null
    $target = $null
    if ($Destination) {
        if (-not [System.IO.Path]::IsPathRooted($Destination)) {
            Write-ToolkitError "Destination must be an absolute path: $Destination"
            exit 1
        }
        $destParent = [System.IO.Path]::GetFullPath($Destination)
        if (Test-PathUnder -Path $destParent -Parent $root) {
            Write-ToolkitError "Destination must be outside the library root ($root). A backup contains secrets and must not be stored in a shareable library."
            exit 1
        }
        $target = Join-Path $destParent ("OBS-Backup-$stamp")
    }

    Write-Host ''
    Write-Host 'OBS configuration backup' -ForegroundColor Cyan
    Write-Host ("  source      : {0}" -f $DataDir)
    Write-Host ("  items       : {0} item(s), {1} file(s), {2}" -f $items.Count, $totalFiles, (Format-ByteSize -Bytes $totalBytes))
    foreach ($i in $items) {
        Write-Host ("    - {0,-16} {1,-7} {2,10}  {3} file(s)" -f $i.name, $i.kind, (Format-ByteSize -Bytes $i.bytes), $i.files)
    }
    if ($target) {
        Write-Host ("  destination : {0}" -f $target)
    }
    else {
        Write-Host '  destination : (not set; pass -Destination <absolute path outside the library>)'
    }
    Write-Host ''
    Write-Host 'WARNING: this backup contains stream keys, the OBS WebSocket password and' -ForegroundColor Yellow
    Write-Host 'plugin tokens. Store it outside this library, on an encrypted volume, and' -ForegroundColor Yellow
    Write-Host 'never upload it to a public share, a chat or a repository.' -ForegroundColor Yellow
    Write-Host ''

    if (-not $Execute) {
        Write-Host 'Dry run: nothing was copied. Re-run with -Execute and a destination to perform the backup.' -ForegroundColor Cyan
        Write-ToolkitLog -Phase 'utilities' -ToolId '-' -Action 'backup-obs-dryrun' -Target $DataDir -Status ok `
            -Detail ("items={0} files={1} bytes={2}" -f $items.Count, $totalFiles, $totalBytes)
        exit 0
    }

    if (-not $target) {
        Write-ToolkitError '-Execute requires -Destination with an absolute path outside the library.'
        exit 1
    }
    if (Test-Path -LiteralPath $target) {
        Write-ToolkitError "backup folder already exists; refusing to overwrite: $target"
        exit 1
    }

    if (-not $WhatIfPreference) {
        $answer = Read-Host "Type BACKUP to copy $totalFiles file(s) to $target"
        if ($answer -ne 'BACKUP') {
            Write-Host 'Confirmation not given; nothing was copied.' -ForegroundColor Yellow
            Write-ToolkitLog -Phase 'utilities' -ToolId '-' -Action 'backup-obs' -Target $target -Status skip -Detail 'confirmation declined'
            exit 1
        }
    }

    if (-not $PSCmdlet.ShouldProcess($target, "Copy $totalFiles file(s), $totalBytes bytes")) {
        exit 0
    }

    New-Item -ItemType Directory -Path $target -Force | Out-Null
    $copied = [System.Collections.Generic.List[object]]::new()
    foreach ($i in $items) {
        $dst = Join-Path $target $i.name
        if ($i.kind -eq 'folder') {
            Copy-Item -LiteralPath $i.path -Destination $target -Recurse -Force
        }
        else {
            Copy-Item -LiteralPath $i.path -Destination $dst -Force
        }
        $copied.Add([pscustomobject]@{ name = $i.name; kind = $i.kind; bytes = $i.bytes; files = $i.files })
    }

    $report = [pscustomobject]@{
        generated_at_utc = Get-ToolkitTimestamp
        source           = $DataDir
        destination      = $target
        items            = @($copied)
        total_files      = $totalFiles
        total_bytes      = $totalBytes
        encrypted        = $false
        note             = 'Contains secrets. Encrypt before moving off this machine; this script does not encrypt.'
    }
    $logDir = Join-Path $root '13-Logs'
    if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    $reportPath = Join-Path $logDir ("backup-$stamp.json")
    $report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $reportPath -Encoding utf8NoBOM

    Write-Host ''
    Write-Host ("Backup written to {0}" -f $target) -ForegroundColor Green
    Write-Host ("Report: {0}" -f $reportPath)
    Write-Host 'Encrypt the folder before storing it anywhere else.' -ForegroundColor Yellow

    Write-ToolkitLog -Phase 'utilities' -ToolId '-' -Action 'backup-obs' -Target $target -Status ok `
        -Detail ("items={0} files={1} bytes={2} encrypted=false" -f $items.Count, $totalFiles, $totalBytes)
    exit 0
}
catch {
    Write-ToolkitError $_.Exception.Message
    try { Write-ToolkitLog -Phase 'utilities' -ToolId '-' -Action 'backup-obs' -Target 'error' -Status fail -Detail $_.Exception.Message } catch { }
    exit 2
}
