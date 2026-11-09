#Requires -Version 7.0
<#
.SYNOPSIS
    Verifies every file listed in 11-Checksums/SHA256SUMS.txt and cross-checks MANIFEST.json.

.DESCRIPTION
    Recomputes SHA-256 for every line in SHA256SUMS.txt and reports:
      - missing files (listed but absent),
      - mismatched files (hash differs),
      - extra files (present in a Downloads/ or Documentation/ folder but not listed),
      - manifest disagreements (asset path absent from the sums file, hash or size
        differs from the manifest, or a recorded license/source path is missing).

    Writes a dated JSON report to 13-Logs and prints a summary. Read-only with
    respect to the library content; it only writes its own report and a log line.

.PARAMETER SkipManifest
    Skip the MANIFEST.json cross-check and verify SHA256SUMS.txt only.

.PARAMETER ReportPath
    Optional report path. Defaults to 13-Logs/verify-<timestamp>.json.

.EXAMPLE
    pwsh -NoProfile -ExecutionPolicy Bypass -File .\12-Utilities\Verify-Checksums.ps1

.EXAMPLE
    .\Verify-Checksums.ps1 -SkipManifest -Verbose

.NOTES
    Exit codes: 0 = no findings, 1 = findings, 2 = script error.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [switch]$SkipManifest,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ReportPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'Common.psm1') -Force

try {
    $root = Get-ToolkitRoot
    $sumsPath = Join-Path $root '11-Checksums\SHA256SUMS.txt'
    if (-not (Test-Path -LiteralPath $sumsPath)) {
        throw "SHA256SUMS.txt not found at $sumsPath"
    }

    $findings = [System.Collections.Generic.List[object]]::new()
    $listed = @{}
    $checked = 0

    foreach ($line in (Get-Content -LiteralPath $sumsPath)) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $m = [regex]::Match($line, '^(?<hash>[0-9a-fA-F]{64})  (?<path>.+)$')
        if (-not $m.Success) {
            $findings.Add([pscustomobject]@{ kind = 'malformed-line'; path = $line; detail = 'expected "<64-hex>  <path>"' })
            continue
        }
        $expected = $m.Groups['hash'].Value.ToLower()
        $rel = $m.Groups['path'].Value
        $listed[$rel] = $expected
        $checked++

        try { $full = Resolve-ToolkitPath -RelativePath $rel }
        catch {
            $findings.Add([pscustomobject]@{ kind = 'outside-root'; path = $rel; detail = $_.Exception.Message })
            continue
        }

        if (-not (Test-Path -LiteralPath $full)) {
            $findings.Add([pscustomobject]@{ kind = 'missing'; path = $rel; detail = 'listed in SHA256SUMS.txt but not on disk' })
            continue
        }
        $actual = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash.ToLower()
        if ($actual -ne $expected) {
            $findings.Add([pscustomobject]@{ kind = 'mismatch'; path = $rel; detail = "expected $expected got $actual" })
        }
    }

    # Extra files inside the checksummed scope
    $scopeRoots = @()
    foreach ($tool in (Get-ToolkitManifest).tools) {
        foreach ($sub in @('Downloads', 'Documentation')) {
            $p = Join-Path $root (($tool.folder -replace '/', '\')) | Join-Path -ChildPath $sub
            if (Test-Path -LiteralPath $p) { $scopeRoots += $p }
        }
    }
    $onDisk = [System.Collections.Generic.List[string]]::new()
    foreach ($dir in $scopeRoots) {
        foreach ($f in (Get-ChildItem -LiteralPath $dir -Recurse -File -Force)) {
            $onDisk.Add(($f.FullName.Substring($root.Length + 1) -replace '\\', '/'))
        }
    }
    foreach ($rel in $onDisk) {
        if (-not $listed.ContainsKey($rel)) {
            $findings.Add([pscustomobject]@{ kind = 'extra'; path = $rel; detail = 'present in Downloads/ or Documentation/ but not in SHA256SUMS.txt' })
        }
    }

    if (-not $SkipManifest) {
        $man = Get-ToolkitManifest
        foreach ($tool in $man.tools) {
            foreach ($asset in $tool.assets) {
                if (-not $listed.ContainsKey($asset.local_path)) {
                    $findings.Add([pscustomobject]@{ kind = 'manifest-not-listed'; path = $asset.local_path; detail = "asset of $($tool.id) is not in SHA256SUMS.txt" })
                    continue
                }
                if ($listed[$asset.local_path] -ne $asset.sha256) {
                    $findings.Add([pscustomobject]@{ kind = 'manifest-hash-differs'; path = $asset.local_path; detail = 'manifest sha256 differs from SHA256SUMS.txt' })
                }
                try { $full = Resolve-ToolkitPath -RelativePath $asset.local_path }
                catch { $findings.Add([pscustomobject]@{ kind = 'outside-root'; path = $asset.local_path; detail = $_.Exception.Message }); continue }
                if (Test-Path -LiteralPath $full) {
                    $size = (Get-Item -LiteralPath $full).Length
                    if ($size -ne $asset.size_bytes) {
                        $findings.Add([pscustomobject]@{ kind = 'size'; path = $asset.local_path; detail = "manifest $($asset.size_bytes) bytes, disk $size bytes" })
                    }
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
        }
    }

    if (-not $ReportPath) {
        $stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
        $ReportPath = Join-Path $root "13-Logs\verify-$stamp.json"
    }
    $ReportPath = [System.IO.Path]::GetFullPath($ReportPath)
    $report = [pscustomobject]@{
        generated_at_utc = Get-ToolkitTimestamp
        sums_file        = '11-Checksums/SHA256SUMS.txt'
        files_listed     = $checked
        manifest_checked = (-not $SkipManifest)
        finding_count    = $findings.Count
        findings         = @($findings)
    }
    $outDir = Split-Path -Parent $ReportPath
    if ($outDir -and -not (Test-Path -LiteralPath $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
    $report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $ReportPath -Encoding utf8NoBOM

    Write-Host ''
    Write-Host ("Files listed : {0}" -f $checked)
    Write-Host ("Manifest     : {0}" -f $(if ($SkipManifest) { 'skipped' } else { 'cross-checked' }))
    Write-Host ("Findings     : {0}" -f $findings.Count) -ForegroundColor $(if ($findings.Count -eq 0) { 'Green' } else { 'Yellow' })
    foreach ($f in $findings) {
        Write-Host ("  [{0}] {1} — {2}" -f $f.kind, $f.path, $f.detail)
    }
    Write-Host ("Report       : {0}" -f $ReportPath)

    if ($findings.Count -eq 0) {
        Write-ToolkitLog -Phase 'utilities' -ToolId '-' -Action 'verify-checksums' -Target 'SHA256SUMS.txt' -Status ok -Detail ("files={0} findings=0" -f $checked)
        exit 0
    }
    Write-ToolkitLog -Phase 'utilities' -ToolId '-' -Action 'verify-checksums' -Target 'SHA256SUMS.txt' -Status fail -Detail ("files={0} findings={1}" -f $checked, $findings.Count)
    exit 1
}
catch {
    Write-ToolkitError $_.Exception.Message
    try { Write-ToolkitLog -Phase 'utilities' -ToolId '-' -Action 'verify-checksums' -Target 'error' -Status fail -Detail $_.Exception.Message } catch { }
    exit 2
}
