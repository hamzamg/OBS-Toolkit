#Requires -Version 7.0
<#
.SYNOPSIS
    Validates MANIFEST.json and regenerates every checksum file from disk.

.DESCRIPTION
    Steps:
      1. Parse MANIFEST.json and validate it against MANIFEST.schema.json with
         Test-Json -SchemaFile.
      2. Regenerate each tool's Checksums.txt from its manifest assets plus every
         file under its Documentation/ folder.
      3. Regenerate 11-Checksums/SHA256SUMS.txt from the union of those, plus
         MANIFEST.json and MANIFEST.schema.json.
      4. Report missing manifest paths and orphan files under Downloads/.

    It never edits license, compatibility or security fields. It does not download
    anything and does not touch OBS.

.PARAMETER SkipSchema
    Skip the JSON Schema validation step (checksums are still regenerated).

.PARAMETER CheckOnly
    Validate and report only; write no checksum file.

.EXAMPLE
    pwsh -NoProfile -ExecutionPolicy Bypass -File .\12-Utilities\Generate-Manifest.ps1

.EXAMPLE
    .\Generate-Manifest.ps1 -CheckOnly

.EXAMPLE
    .\Generate-Manifest.ps1 -WhatIf

.NOTES
    Exit codes: 0 = valid and consistent, 1 = findings, 2 = script error.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter()]
    [switch]$SkipSchema,

    [Parameter()]
    [switch]$CheckOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'Common.psm1') -Force

function Get-RelativeForwardPath {
    param([string]$Root, [string]$FullName)
    return ($FullName.Substring($Root.Length + 1) -replace '\\', '/')
}

try {
    $root = Get-ToolkitRoot
    $manifestPath = Join-Path $root 'MANIFEST.json'
    $schemaPath = Join-Path $root 'MANIFEST.schema.json'

    if (-not (Test-Path -LiteralPath $manifestPath)) { throw "MANIFEST.json not found at $manifestPath" }
    if (-not (Test-Path -LiteralPath $schemaPath)) { throw "MANIFEST.schema.json not found at $schemaPath" }

    $findings = [System.Collections.Generic.List[object]]::new()

    if (-not $SkipSchema) {
        $json = Get-Content -LiteralPath $manifestPath -Raw
        $schemaValid = $false
        try {
            $schemaValid = Test-Json -Json $json -SchemaFile $schemaPath -ErrorAction Stop
        }
        catch {
            $findings.Add([pscustomobject]@{ kind = 'schema-error'; path = 'MANIFEST.json'; detail = $_.Exception.Message })
        }
        if (-not $schemaValid -and $findings.Count -eq 0) {
            $findings.Add([pscustomobject]@{ kind = 'schema-invalid'; path = 'MANIFEST.json'; detail = 'does not validate against MANIFEST.schema.json' })
        }
    }

    $man = Get-ToolkitManifest

    # Missing paths and orphans
    $assetPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($tool in $man.tools) {
        foreach ($asset in $tool.assets) {
            [void]$assetPaths.Add($asset.local_path)
            try { $full = Resolve-ToolkitPath -RelativePath $asset.local_path }
            catch { $findings.Add([pscustomobject]@{ kind = 'outside-root'; path = $asset.local_path; detail = $_.Exception.Message }); continue }
            if (-not (Test-Path -LiteralPath $full)) {
                $findings.Add([pscustomobject]@{ kind = 'missing-asset'; path = $asset.local_path; detail = "asset of $($tool.id) is missing" })
            }
        }
        if ($tool.source_snapshot.local_path) {
            try {
                $full = Resolve-ToolkitPath -RelativePath $tool.source_snapshot.local_path
                if (-not (Test-Path -LiteralPath $full)) {
                    $findings.Add([pscustomobject]@{ kind = 'missing-source'; path = $tool.source_snapshot.local_path; detail = "source snapshot of $($tool.id) is missing" })
                }
            }
            catch { $findings.Add([pscustomobject]@{ kind = 'outside-root'; path = $tool.source_snapshot.local_path; detail = $_.Exception.Message }) }
        }
        if ($tool.license.file_path) {
            try {
                $full = Resolve-ToolkitPath -RelativePath $tool.license.file_path
                if (-not (Test-Path -LiteralPath $full)) {
                    $findings.Add([pscustomobject]@{ kind = 'missing-license'; path = $tool.license.file_path; detail = "license file of $($tool.id) is missing" })
                }
            }
            catch { $findings.Add([pscustomobject]@{ kind = 'outside-root'; path = $tool.license.file_path; detail = $_.Exception.Message }) }
        }

        $downloadsDir = Join-Path $root (($tool.folder -replace '/', '\')) | Join-Path -ChildPath 'Downloads'
        if (Test-Path -LiteralPath $downloadsDir) {
            foreach ($f in (Get-ChildItem -LiteralPath $downloadsDir -Recurse -File -Force)) {
                $rel = Get-RelativeForwardPath -Root $root -FullName $f.FullName
                if (-not $assetPaths.Contains($rel)) {
                    $findings.Add([pscustomobject]@{ kind = 'orphan-asset'; path = $rel; detail = "not referenced by MANIFEST.json ($($tool.id))" })
                }
            }
        }
    }

    if ($CheckOnly) {
        Write-Host ''
        Write-Host 'Check-only mode: no checksum file was written.' -ForegroundColor Cyan
    }
    else {
        $sumLines = [System.Collections.Generic.List[string]]::new()

        foreach ($tool in $man.tools) {
            $folderAbs = Join-Path $root ($tool.folder -replace '/', '\')
            $targets = [System.Collections.Generic.List[string]]::new()
            foreach ($asset in $tool.assets) { $targets.Add($asset.local_path) }
            $docDir = Join-Path $folderAbs 'Documentation'
            if (Test-Path -LiteralPath $docDir) {
                foreach ($f in (Get-ChildItem -LiteralPath $docDir -Recurse -File | Sort-Object FullName)) {
                    $targets.Add((Get-RelativeForwardPath -Root $root -FullName $f.FullName))
                }
            }

            $lines = [System.Collections.Generic.List[string]]::new()
            foreach ($rel in $targets) {
                $full = Resolve-ToolkitPath -RelativePath $rel
                if (-not (Test-Path -LiteralPath $full)) { continue }
                $hash = Get-ToolkitFileHash -Path $full
                $lines.Add("$hash  $rel")
                $sumLines.Add("$hash  $rel")
            }

            $checksumsPath = Join-Path $folderAbs 'Checksums.txt'
            if ($PSCmdlet.ShouldProcess($checksumsPath, 'Write per-tool Checksums.txt')) {
                ($lines -join "`n") + "`n" | Set-Content -LiteralPath $checksumsPath -Encoding utf8NoBOM
            }
        }

        foreach ($name in @('MANIFEST.json', 'MANIFEST.schema.json')) {
            $hash = Get-ToolkitFileHash -Path (Join-Path $root $name)
            $sumLines.Add("$hash  $name")
        }

        $sumsPath = Join-Path $root '11-Checksums\SHA256SUMS.txt'
        if ($PSCmdlet.ShouldProcess($sumsPath, 'Write SHA256SUMS.txt')) {
            $sumsDir = Split-Path -Parent $sumsPath
            if (-not (Test-Path -LiteralPath $sumsDir)) { New-Item -ItemType Directory -Path $sumsDir -Force | Out-Null }
            ($sumLines | Sort-Object -Unique) -join "`n" | Set-Content -LiteralPath $sumsPath -Encoding utf8NoBOM
            Write-Host ("SHA256SUMS.txt written: {0} lines" -f @($sumLines | Sort-Object -Unique).Count)
        }
    }

    Write-Host ''
    Write-Host ("Tools        : {0}" -f $man.tools.Count)
    Write-Host ("Schema       : {0}" -f $(if ($SkipSchema) { 'skipped' } else { 'checked' }))
    Write-Host ("Findings     : {0}" -f $findings.Count) -ForegroundColor $(if ($findings.Count -eq 0) { 'Green' } else { 'Yellow' })
    foreach ($f in $findings) { Write-Host ("  [{0}] {1} — {2}" -f $f.kind, $f.path, $f.detail) }

    if ($findings.Count -eq 0) {
        Write-ToolkitLog -Phase 'utilities' -ToolId '-' -Action 'generate-manifest' -Target 'MANIFEST.json' -Status ok -Detail ("tools={0} checkOnly={1}" -f $man.tools.Count, [bool]$CheckOnly)
        exit 0
    }
    Write-ToolkitLog -Phase 'utilities' -ToolId '-' -Action 'generate-manifest' -Target 'MANIFEST.json' -Status fail -Detail ("findings={0}" -f $findings.Count)
    exit 1
}
catch {
    Write-ToolkitError $_.Exception.Message
    try { Write-ToolkitLog -Phase 'utilities' -ToolId '-' -Action 'generate-manifest' -Target 'error' -Status fail -Detail $_.Exception.Message } catch { }
    exit 2
}
