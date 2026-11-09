#Requires -Version 7.0
<#
.SYNOPSIS
    Runs the Definition-of-Done checks against the library and writes
    13-Logs/qa-result.json.

.DESCRIPTION
    Automates the twelve checks in the task brief:
      1  layout and manifest path consistency
      2  MANIFEST.json parses and validates against MANIFEST.schema.json
      3  every asset exists, has the recorded size, and matches both the manifest
         SHA-256 and SHA256SUMS.txt
      4  every INCLUDED tool has a confirmed license, a complete TOOL_INFO.md, a
         finished security review and a pinned source snapshot
      5  every non-INCLUDED tool is quarantined or justified in the reports
      6  no duplicate asset hashes and no superseded version presented as current
      7  Markdown relative links, table columns and code fences
      8  README, LICENSES, COMPATIBILITY and DOWNLOAD_REPORT agree with the manifest
      9  secrets scan of the library-authored files
      10 OBS tripwire against 13-Logs/obs-baseline.json
      11 execution log shows no downloaded content was run and nothing was installed
      12 every PowerShell script parses, and the log states what was run

    It reads the library and writes only 13-Logs/qa-result.json and a log line.
    It does not modify any other file, does not touch OBS, and does not use the
    network.

.PARAMETER SkipTripwire
    Skip check 10 (useful when OBS is not installed on the current machine).

.PARAMETER Quiet
    Print only the summary.

.EXAMPLE
    pwsh -NoProfile -ExecutionPolicy Bypass -File .\12-Utilities\Test-Library.ps1

.EXAMPLE
    .\Test-Library.ps1 -SkipTripwire -Quiet

.NOTES
    Exit codes: 0 = every check passed, 1 = at least one check failed,
    2 = script error.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [switch]$SkipTripwire,

    [Parameter()]
    [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'Common.psm1') -Force

$script:ToolInfoSections = @(
    'Identity', 'Decision', 'License', 'Compatibility', 'Assets', 'What it does',
    'Dependencies', 'Manual installation (not performed)', 'Uninstallation and rollback',
    'Security and privacy review', 'Maintenance and known limitations', 'Open questions'
)

function New-Check {
    param([int]$Id, [string]$Name)
    return [pscustomobject]@{
        id       = $Id
        name     = $Name
        status   = 'PASS'
        detail   = ''
        findings = [System.Collections.Generic.List[string]]::new()
    }
}

function Add-Finding {
    param($Check, [string]$Message)
    $Check.findings.Add($Message)
    $Check.status = 'FAIL'
}

function Get-RelForward {
    param([string]$Root, [string]$FullName)
    return ($FullName.Substring($Root.Length + 1) -replace '\\', '/')
}

function Read-ManifestOrThrow {
    $path = Join-Path (Get-ToolkitRoot) 'MANIFEST.json'
    if (-not (Test-Path -LiteralPath $path)) { throw "MANIFEST.json not found at $path" }
    return Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
}

function Split-TableRow {
    param([string]$Line)
    $t = $Line.Trim()
    if ($t.StartsWith('|')) { $t = $t.Substring(1) }
    if ($t.EndsWith('|')) { $t = $t.Substring(0, $t.Length - 1) }
    $cells = [System.Collections.Generic.List[string]]::new()
    $sb = New-Object System.Text.StringBuilder
    for ($i = 0; $i -lt $t.Length; $i++) {
        $ch = $t[$i]
        if ($ch -eq '\' -and ($i + 1) -lt $t.Length -and $t[$i + 1] -eq '|') {
            [void]$sb.Append('|'); $i++; continue
        }
        if ($ch -eq '|') { $cells.Add($sb.ToString()); [void]$sb.Clear(); continue }
        [void]$sb.Append($ch)
    }
    $cells.Add($sb.ToString())
    return , $cells
}

function Test-SeparatorRow {
    param([string]$Line)
    return ($Line -match '^[\s|:\-]+$' -and $Line -match '-')
}

function Get-FenceMask {
    param([string[]]$Lines)
    $mask = New-Object bool[] $Lines.Count
    $inside = $false
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^\s*(```|~~~)') {
            $mask[$i] = $true
            $inside = -not $inside
            continue
        }
        $mask[$i] = $inside
    }
    return [pscustomobject]@{ mask = $mask; balanced = (-not $inside) }
}

# ---------------------------------------------------------------------------
# Check 1: layout
# ---------------------------------------------------------------------------
function Invoke-LayoutCheck {
    param($Man, [string]$Root)
    $c = New-Check 1 'Layout and manifest path consistency'

    $requiredFiles = @(
        'README.md', 'README.ar.md', 'CHANGELOG.md', 'LICENSES.md', 'COMPATIBILITY.md',
        'DOWNLOAD_REPORT.md', 'FINAL_REPORT.md', 'MANIFEST.json', 'MANIFEST.schema.json',
        '11-Checksums/SHA256SUMS.txt', '11-Checksums/VERIFICATION_REPORT.md',
        '13-Logs/execution.log', '13-Logs/state.json', '13-Logs/obs-baseline.json',
        '12-Utilities/Common.psm1'
    )
    foreach ($rel in $requiredFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $Root ($rel -replace '/', '\')))) {
            Add-Finding $c "missing required file: $rel"
        }
    }
    $guides = @('INSTALLATION_GUIDE.md', 'WINDOWS_SETUP.md', 'OBS_SCRIPTING_GUIDE.md',
        'OBS_BACKUP_GUIDE.md', 'SECURITY_GUIDE.md', 'TROUBLESHOOTING.md', 'UPDATE_GUIDE.md', 'GLOSSARY.md')
    foreach ($g in $guides) {
        if (-not (Test-Path -LiteralPath (Join-Path $Root "00-Documentation\$g"))) {
            Add-Finding $c "missing guide: 00-Documentation/$g"
        }
    }

    $allowedExtras = @{
        '01-Scene-Management'            = @()
        '02-Scripting-and-Automation'    = @('Custom-Scripts')
        '03-Timers-and-Counters'         = @()
        '04-Recording-and-Organization'  = @()
        '05-Screen-Production'           = @()
        '06-Audio-and-Media'             = @()
        '07-Streaming'                   = @()
        '08-Remote-Control-and-AI'       = @()
        '09-Optional-Tools'              = @()
        '10-Unverified'                  = @('README.md')
    }

    foreach ($tool in $Man.tools) {
        $folderRel = $tool.folder -replace '\\', '/'
        $folderAbs = Join-Path $Root ($folderRel -replace '/', '\')
        if (-not (Test-Path -LiteralPath $folderAbs)) {
            Add-Finding $c "tool folder missing: $folderRel"
            continue
        }
        if (-not (Test-Path -LiteralPath (Join-Path $folderAbs 'TOOL_INFO.md'))) {
            Add-Finding $c "TOOL_INFO.md missing in $folderRel"
        }

        $assetPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($a in $tool.assets) {
            [void]$assetPaths.Add($a.local_path)
            if (-not (Test-Path -LiteralPath (Join-Path $Root ($a.local_path -replace '/', '\')))) {
                Add-Finding $c "asset path missing: $($a.local_path)"
            }
        }

        $downloads = Join-Path $folderAbs 'Downloads'
        if (Test-Path -LiteralPath $downloads) {
            foreach ($f in (Get-ChildItem -LiteralPath $downloads -Recurse -File -Force)) {
                $rel = Get-RelForward -Root $Root -FullName $f.FullName
                if (-not $assetPaths.Contains($rel)) {
                    Add-Finding $c "file under Downloads not referenced by the manifest: $rel"
                }
            }
        }

        if ($tool.source_snapshot -and $tool.source_snapshot.local_path) {
            $srcRel = [string]$tool.source_snapshot.local_path
            $srcAbs = Join-Path $Root ($srcRel -replace '/', '\')
            if (-not (Test-Path -LiteralPath $srcAbs)) {
                Add-Finding $c "source snapshot missing: $srcRel"
            }
            else {
                $srcRoot = Join-Path $folderAbs 'Source'
                if (Test-Path -LiteralPath $srcRoot) {
                    foreach ($f in (Get-ChildItem -LiteralPath $srcRoot -Recurse -File -Force)) {
                        $rel = Get-RelForward -Root $Root -FullName $f.FullName
                        if (-not ($rel -eq $srcRel -or $rel.StartsWith($srcRel + '/'))) {
                            Add-Finding $c "file under Source is outside the pinned snapshot: $rel"
                        }
                    }
                }
            }
        }

        if ($tool.license -and $tool.license.file_path) {
            if (-not (Test-Path -LiteralPath (Join-Path $Root ($tool.license.file_path -replace '/', '\')))) {
                Add-Finding $c "license file missing: $($tool.license.file_path)"
            }
        }
    }

    $topDirs = Get-ChildItem -LiteralPath $Root -Directory | Where-Object { $_.Name -match '^\d{2}-' }
    foreach ($d in $topDirs) {
        if ($d.Name -eq '00-Documentation' -or $d.Name -eq '11-Checksums' -or $d.Name -eq '12-Utilities' -or $d.Name -eq '13-Logs') { continue }
        $expected = @($Man.tools | Where-Object { ($_.folder -replace '\\', '/').StartsWith($d.Name + '/') } |
            ForEach-Object { (($_.folder -replace '\\', '/') -split '/')[1] })
        $extras = if ($allowedExtras.ContainsKey($d.Name)) { $allowedExtras[$d.Name] } else { @() }
        foreach ($sub in (Get-ChildItem -LiteralPath $d.FullName -Directory)) {
            if ($sub.Name -in $expected) { continue }
            if ($sub.Name -in $extras) { continue }
            Add-Finding $c "unexpected folder in $($d.Name): $($sub.Name)"
        }
    }

    $c.detail = "tools=$($Man.tools.Count) required-files=$($requiredFiles.Count + $guides.Count)"
    return $c
}

# ---------------------------------------------------------------------------
# Check 2: schema
# ---------------------------------------------------------------------------
function Invoke-SchemaCheck {
    param([string]$Root)
    $c = New-Check 2 'MANIFEST.json parses and validates against the schema'
    $manifestPath = Join-Path $Root 'MANIFEST.json'
    $schemaPath = Join-Path $Root 'MANIFEST.schema.json'
    try {
        $json = Get-Content -LiteralPath $manifestPath -Raw
        $ok = Test-Json -Json $json -SchemaFile $schemaPath -ErrorAction Stop
        if (-not $ok) { Add-Finding $c 'Test-Json returned false' }
    }
    catch {
        Add-Finding $c $_.Exception.Message
    }
    $c.detail = 'draft-07 schema'
    return $c
}

# ---------------------------------------------------------------------------
# Check 3: assets
# ---------------------------------------------------------------------------
function Invoke-AssetCheck {
    param($Man, [string]$Root)
    $c = New-Check 3 'Assets: exists, size, SHA-256, SHA256SUMS.txt'
    $sumsPath = Join-Path $Root '11-Checksums\SHA256SUMS.txt'
    $sums = @{}
    if (Test-Path -LiteralPath $sumsPath) {
        foreach ($line in (Get-Content -LiteralPath $sumsPath)) {
            if ($line -match '^(?<h>[0-9a-f]{64})  (?<p>.+)$') { $sums[$Matches['p']] = $Matches['h'] }
        }
    }
    else { Add-Finding $c 'SHA256SUMS.txt missing' }

    $count = 0
    foreach ($tool in $Man.tools) {
        foreach ($a in $tool.assets) {
            $count++
            $full = Join-Path $Root ($a.local_path -replace '/', '\')
            if (-not (Test-Path -LiteralPath $full)) {
                Add-Finding $c "missing: $($a.local_path)"; continue
            }
            $size = (Get-Item -LiteralPath $full).Length
            if ($size -ne $a.size_bytes) {
                Add-Finding $c "size mismatch: $($a.local_path) (manifest $($a.size_bytes), disk $size)"
            }
            $hash = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash.ToLower()
            if ($hash -ne $a.sha256) {
                Add-Finding $c "hash differs from manifest: $($a.local_path)"
            }
            if (-not $sums.ContainsKey($a.local_path)) {
                Add-Finding $c "not listed in SHA256SUMS.txt: $($a.local_path)"
            }
            elseif ($sums[$a.local_path] -ne $a.sha256) {
                Add-Finding $c "SHA256SUMS.txt disagrees with manifest: $($a.local_path)"
            }
        }
    }
    $c.detail = "assets=$count"
    return $c
}

# ---------------------------------------------------------------------------
# Check 4: INCLUDED completeness
# ---------------------------------------------------------------------------
function Invoke-IncludedCheck {
    param($Man, [string]$Root)
    $c = New-Check 4 'INCLUDED tools are complete'
    $included = @($Man.tools | Where-Object { $_.decision -eq 'INCLUDED' })
    foreach ($tool in $included) {
        $folderAbs = Join-Path $Root (($tool.folder -replace '/', '\'))

        if (-not $tool.license.spdx) { Add-Finding $c "$($tool.id): no SPDX id" }
        if ($tool.license.status -ne 'CONFIRMED') { Add-Finding $c "$($tool.id): license status is $($tool.license.status)" }
        if (-not $tool.license.file_path) { Add-Finding $c "$($tool.id): no saved license file" }
        elseif (-not (Test-Path -LiteralPath (Join-Path $Root ($tool.license.file_path -replace '/', '\')))) {
            Add-Finding $c "$($tool.id): saved license file missing"
        }

        $infoPath = Join-Path $folderAbs 'TOOL_INFO.md'
        if (-not (Test-Path -LiteralPath $infoPath)) {
            Add-Finding $c "$($tool.id): TOOL_INFO.md missing"
        }
        else {
            $headings = @(Get-Content -LiteralPath $infoPath | Select-String -Pattern '^## (\d+)\. ' |
                ForEach-Object { $_.Line })
            if ($headings.Count -ne 12) {
                Add-Finding $c "$($tool.id): TOOL_INFO.md has $($headings.Count) numbered sections, expected 12"
            }
            else {
                for ($i = 0; $i -lt 12; $i++) {
                    $expected = ('## {0}. {1}' -f ($i + 1), $script:ToolInfoSections[$i])
                    if ($headings[$i].Trim() -ne $expected) {
                        Add-Finding $c "$($tool.id): section $($i + 1) is '$($headings[$i])', expected '$expected'"
                    }
                }
            }
        }

        if (-not $tool.security) { Add-Finding $c "$($tool.id): no security block" }
        else {
            if ($tool.security.risk_level -notin @('LOW', 'MEDIUM', 'HIGH')) { Add-Finding $c "$($tool.id): invalid risk level" }
            if ([string]::IsNullOrWhiteSpace([string]$tool.security.network_access)) { Add-Finding $c "$($tool.id): network_access is empty" }
            if ($null -eq $tool.security.spawns_processes) { Add-Finding $c "$($tool.id): spawns_processes is null" }
            if (@($tool.security.findings).Count -eq 0) { Add-Finding $c "$($tool.id): no security findings recorded" }
            foreach ($f in $tool.security.findings) {
                if ([string]::IsNullOrWhiteSpace([string]$f.category) -or
                    [string]::IsNullOrWhiteSpace([string]$f.location) -or
                    [string]::IsNullOrWhiteSpace([string]$f.note)) {
                    Add-Finding $c "$($tool.id): incomplete security finding"
                }
            }
        }

        if ($tool.type -ne 'docs-only') {
            if (-not $tool.source_snapshot -or -not $tool.source_snapshot.local_path) {
                Add-Finding $c "$($tool.id): no pinned source snapshot"
            }
        }

        if ([string]::IsNullOrWhiteSpace([string]$tool.decision_reason)) { Add-Finding $c "$($tool.id): empty decision_reason" }
        if ($tool.compatibility.status -notin @('SUPPORTED', 'LIKELY', 'UNKNOWN', 'INCOMPATIBLE')) {
            Add-Finding $c "$($tool.id): invalid compatibility status"
        }
    }
    $c.detail = "included=$($included.Count)"
    return $c
}

# ---------------------------------------------------------------------------
# Check 5: non-INCLUDED placement
# ---------------------------------------------------------------------------
function Invoke-NonIncludedCheck {
    param($Man, [string]$Root)
    $c = New-Check 5 'Non-INCLUDED tools are quarantined or justified'
    $readme = if (Test-Path -LiteralPath (Join-Path $Root 'README.md')) { Get-Content -LiteralPath (Join-Path $Root 'README.md') -Raw } else { '' }
    $dl = if (Test-Path -LiteralPath (Join-Path $Root 'DOWNLOAD_REPORT.md')) { Get-Content -LiteralPath (Join-Path $Root 'DOWNLOAD_REPORT.md') -Raw } else { '' }
    $non = @($Man.tools | Where-Object { $_.decision -ne 'INCLUDED' })
    foreach ($tool in $non) {
        $folder = $tool.folder -replace '\\', '/'
        if ($tool.decision -in @('REJECTED', 'UNAVAILABLE')) {
            if ([string]::IsNullOrWhiteSpace([string]$tool.decision_reason)) {
                Add-Finding $c "$($tool.id): $($tool.decision) without a reason"
            }
            if (-not $readme.Contains($tool.name)) { Add-Finding $c "$($tool.id): not mentioned in README.md" }
            if (-not $dl.Contains($tool.name)) { Add-Finding $c "$($tool.id): not mentioned in DOWNLOAD_REPORT.md" }
        }
        elseif ($tool.decision -eq 'DOCS-ONLY') {
            # A DOCS-ONLY tool may stay in its normal category folder (nothing is
            # installed), but only with an explicit justification on record.
            if ([string]::IsNullOrWhiteSpace([string]$tool.decision_reason)) {
                Add-Finding $c "$($tool.id): DOCS-ONLY without a justification"
            }
            if (-not $readme.Contains($tool.name)) { Add-Finding $c "$($tool.id): not mentioned in README.md" }
            if (-not $dl.Contains($tool.name)) { Add-Finding $c "$($tool.id): not mentioned in DOWNLOAD_REPORT.md" }
        }
        else {
            if (-not $folder.StartsWith('10-Unverified/')) {
                Add-Finding $c "$($tool.id): decision $($tool.decision) but folder is $folder"
            }
            if (-not (Test-Path -LiteralPath (Join-Path $Root (($tool.folder -replace '/', '\') + '\TOOL_INFO.md')))) {
                Add-Finding $c "$($tool.id): TOOL_INFO.md missing"
            }
            if (-not $readme.Contains($tool.name)) { Add-Finding $c "$($tool.id): not mentioned in README.md" }
            if (-not $dl.Contains($tool.name)) { Add-Finding $c "$($tool.id): not mentioned in DOWNLOAD_REPORT.md" }
        }
    }
    $c.detail = "non-included=$($non.Count)"
    return $c
}

# ---------------------------------------------------------------------------
# Check 6: duplicates and current version
# ---------------------------------------------------------------------------
function Invoke-DuplicateCheck {
    param($Man, [string]$Root)
    $c = New-Check 6 'No duplicate assets and no superseded version presented as current'
    $byHash = @{}
    foreach ($tool in $Man.tools) {
        foreach ($a in $tool.assets) {
            if (-not $byHash.ContainsKey($a.sha256)) { $byHash[$a.sha256] = [System.Collections.Generic.List[string]]::new() }
            $byHash[$a.sha256].Add($a.local_path)
        }
    }
    foreach ($h in $byHash.Keys) {
        if ($byHash[$h].Count -gt 1) {
            Add-Finding $c ("duplicate asset hash {0}: {1}" -f $h.Substring(0, 16), ($byHash[$h] -join ', '))
        }
    }

    $readme = if (Test-Path -LiteralPath (Join-Path $Root 'README.md')) { Get-Content -LiteralPath (Join-Path $Root 'README.md') -Raw } else { '' }
    foreach ($tool in $Man.tools) {
        if (@($tool.assets).Count -eq 0) { continue }
        $tag = [string]$tool.release.tag
        if (-not $tag) { Add-Finding $c "$($tool.id): has assets but no release tag"; continue }

        $versions = @($tool.assets | ForEach-Object {
                $parts = ([string]$_.local_path -replace '\\', '/') -split '/'
                $i = [Array]::IndexOf($parts, 'Downloads')
                if ($i -ge 0 -and ($i + 1) -lt $parts.Length) { $parts[$i + 1] } else { $null }
            } | Where-Object { $_ } | Sort-Object -Unique)
        if ($versions -notcontains $tag) {
            Add-Finding $c "$($tool.id): release tag $tag has no matching Downloads/<version> folder"
        }

        $info = Join-Path $Root (($tool.folder -replace '/', '\') + '\TOOL_INFO.md')
        if (Test-Path -LiteralPath $info) {
            $text = Get-Content -LiteralPath $info -Raw
            if (-not $text.Contains($tag)) { Add-Finding $c "$($tool.id): TOOL_INFO.md does not mention the current version $tag" }
        }
        $nameEsc = [regex]::Escape($tool.name)
        $row = @($readme -split "`n" | Where-Object { $_ -match ('^\|\s*\[' + $nameEsc + '\]\(') })
        if ($row.Count -eq 1 -and -not $row[0].Contains($tag)) {
            Add-Finding $c "$($tool.id): README catalog row does not show the current version $tag"
        }
    }
    $c.detail = "asset-hashes=$($byHash.Count)"
    return $c
}

# ---------------------------------------------------------------------------
# Check 7: Markdown
# ---------------------------------------------------------------------------
function Invoke-MarkdownCheck {
    param($Man, [string]$Root)
    $c = New-Check 7 'Markdown links, tables and fences'

    $files = [System.Collections.Generic.List[string]]::new()
    foreach ($f in (Get-ChildItem -LiteralPath $Root -Filter '*.md' -File)) { $files.Add($f.FullName) }
    foreach ($dirName in @('00-Documentation', '10-Unverified')) {
        $dir = Join-Path $Root $dirName
        if (Test-Path -LiteralPath $dir) {
            foreach ($f in (Get-ChildItem -LiteralPath $dir -Recurse -Filter '*.md' -File)) {
                if ($dirName -eq '10-Unverified' -and $f.Name -ne 'README.md' -and
                    -not ($f.FullName -like '*\TOOL_INFO.md')) { continue }
                $files.Add($f.FullName)
            }
        }
    }
    foreach ($tool in $Man.tools) {
        $info = Join-Path $Root (($tool.folder -replace '/', '\') + '\TOOL_INFO.md')
        if (Test-Path -LiteralPath $info) { $files.Add($info) }
    }
    $custom = Join-Path $Root '02-Scripting-and-Automation\Custom-Scripts\README.md'
    if (Test-Path -LiteralPath $custom) { $files.Add($custom) }

    $checked = 0
    foreach ($file in ($files | Sort-Object -Unique)) {
        $checked++
        $rel = Get-RelForward -Root $Root -FullName $file
        $lines = Get-Content -LiteralPath $file
        $fence = Get-FenceMask -Lines $lines
        if (-not $fence.balanced) { Add-Finding $c "${rel}: unclosed code fence" }

        $inTable = $false
        $tableCols = -1
        $tableStart = 0
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            if ($fence.mask[$i]) {
                $inTable = $false
                continue
            }

            if ($line -match '^\s*\|') {
                if (-not $inTable) { $inTable = $true; $tableStart = $i + 1; $tableCols = -1 }
                if (Test-SeparatorRow $line) { continue }
                $cells = Split-TableRow $line
                if ($tableCols -lt 0) { $tableCols = $cells.Count }
                elseif ($cells.Count -ne $tableCols) {
                    Add-Finding $c ("{0}:{1}: table has {2} columns, expected {3}" -f $rel, ($i + 1), $cells.Count, $tableCols)
                }
            }
            else {
                $inTable = $false
            }

            $linkMatches = [regex]::Matches($line, '!?\[[^\]]*\]\(\s*(?<t><[^>]*>|[^)\s]+)')
            foreach ($m in $linkMatches) {
                $target = $m.Groups['t'].Value.Trim()
                if ($target.StartsWith('<') -and $target.EndsWith('>')) { $target = $target.Substring(1, $target.Length - 2) }
                if ([string]::IsNullOrWhiteSpace($target)) { continue }
                if ($target -match '^(?i)(https?://|mailto:|tel:|data:|#)') { continue }
                if ($target.Contains('{{') -or $target.Contains('{')) { continue }
                $pathPart = ($target -split '#')[0]
                $pathPart = ($pathPart -split '\?')[0]
                if ([string]::IsNullOrWhiteSpace($pathPart)) { continue }
                $pathPart = [System.Uri]::UnescapeDataString($pathPart)
                $pathPart = $pathPart -replace '/', '\'
                $resolved = [System.IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $file) $pathPart))
                if (-not (Test-Path -LiteralPath $resolved)) {
                    Add-Finding $c ("{0}:{1}: link target not found: {2}" -f $rel, ($i + 1), $target)
                }
            }
        }
    }
    $c.detail = "files=$checked"
    return $c
}

# ---------------------------------------------------------------------------
# Check 8: generated documents agree with the manifest
# ---------------------------------------------------------------------------
function Invoke-DocConsistencyCheck {
    param($Man, [string]$Root)
    $c = New-Check 8 'README, LICENSES, COMPATIBILITY, DOWNLOAD_REPORT agree with the manifest'

    $readmePath = Join-Path $Root 'README.md'
    $licPath = Join-Path $Root 'LICENSES.md'
    $cmpPath = Join-Path $Root 'COMPATIBILITY.md'
    $dlPath = Join-Path $Root 'DOWNLOAD_REPORT.md'
    foreach ($p in @($readmePath, $licPath, $cmpPath, $dlPath)) {
        if (-not (Test-Path -LiteralPath $p)) { Add-Finding $c "missing $([System.IO.Path]::GetFileName($p))"; return $c }
    }

    $readme = Get-Content -LiteralPath $readmePath -Raw
    $lic = Get-Content -LiteralPath $licPath -Raw
    $cmp = Get-Content -LiteralPath $cmpPath -Raw
    $dl = Get-Content -LiteralPath $dlPath -Raw

    $catalogRows = @($readme -split "`n" | Where-Object { $_ -match '^\|\s*\[.+\]\(.+TOOL_INFO\.md\)' })
    if ($catalogRows.Count -ne $Man.tools.Count) {
        Add-Finding $c "README catalog has $($catalogRows.Count) rows, manifest has $($Man.tools.Count) tools"
    }

    $decisionCounts = @{}
    foreach ($g in ($Man.tools | Group-Object decision)) { $decisionCounts[$g.Name] = $g.Count }
    foreach ($word in @('INCLUDED', 'UNVERIFIED', 'REJECTED', 'UNAVAILABLE', 'DOCS-ONLY', 'PENDING-USER')) {
        $expected = if ($decisionCounts.ContainsKey($word)) { $decisionCounts[$word] } else { 0 }
        $m = [regex]::Match($readme, '\|\s*`' + [regex]::Escape($word) + '`\s*\|\s*(\d+)\s*\|')
        if (-not $m.Success) { Add-Finding $c "README scope table has no row for $word" }
        elseif ([int]$m.Groups[1].Value -ne $expected) {
            Add-Finding $c "README says $word=$($m.Groups[1].Value), manifest says $expected"
        }
    }

    $licHeadings = @($lic -split "`n" | Where-Object { $_ -match '^###\s+(.+)$' } | ForEach-Object { $_.Trim() })
    foreach ($tool in $Man.tools) {
        if (-not ($licHeadings -contains ('### ' + $tool.name))) { Add-Finding $c "LICENSES.md has no section for $($tool.name)" }
        if ($tool.license.spdx -and -not $lic.Contains($tool.license.spdx)) { Add-Finding $c "LICENSES.md does not mention $($tool.license.spdx)" }
    }

    foreach ($tool in $Man.tools) {
        $nameEsc = [regex]::Escape($tool.name)
        if (-not ($cmp -match ('(?m)^\|\s*' + $nameEsc + '\s*\|'))) {
            Add-Finding $c "COMPATIBILITY.md has no matrix row for $($tool.name)"
        }
    }

    $assetRows = @($dl -split "`n" | Where-Object { $_ -match '^\|\s*[^|]+\|\s*`[^`]+`\s*\|\s*[\d,]+\s*\|\s*`[0-9a-f]{16}…`' })
    $assetCount = @($Man.tools | ForEach-Object { $_.assets }).Count
    if ($assetRows.Count -ne $assetCount) {
        Add-Finding $c "DOWNLOAD_REPORT.md has $($assetRows.Count) asset rows, manifest has $assetCount assets"
    }

    foreach ($tool in $Man.tools) {
        $nameEsc = [regex]::Escape($tool.name)
        $row = @($readme -split "`n" | Where-Object { $_ -match ('^\|\s*\[' + $nameEsc + '\]\(') })
        if ($row.Count -eq 1) {
            foreach ($value in @([string]$tool.decision, [string]$tool.compatibility.status, [string]$tool.maintenance_status)) {
                if (-not $row[0].Contains($value)) { Add-Finding $c "README catalog row for $($tool.id) lacks $value" }
            }
        }
    }

    $c.detail = "tools=$($Man.tools.Count) assets=$assetCount"
    return $c
}

# ---------------------------------------------------------------------------
# Check 9: secrets
# ---------------------------------------------------------------------------
function Invoke-SecretsCheck {
    param($Man, [string]$Root)
    $c = New-Check 9 'Secrets and username scan'

    $extensions = @('.md', '.json', '.txt', '.log', '.ps1', '.psm1', '.yml', '.yaml', '.ini', '.toml', '.cfg')
    $files = [System.Collections.Generic.List[string]]::new()
    foreach ($f in (Get-ChildItem -LiteralPath $Root -File -Force)) { if ($f.Extension -in $extensions) { $files.Add($f.FullName) } }
    foreach ($dirName in @('00-Documentation', '11-Checksums', '12-Utilities', '13-Logs')) {
        $dir = Join-Path $Root $dirName
        if (-not (Test-Path -LiteralPath $dir)) { continue }
        foreach ($f in (Get-ChildItem -LiteralPath $dir -Recurse -File -Force)) {
            if ($f.FullName -like '*\13-Logs\cache\*') { continue }
            if ($f.Extension -in $extensions) { $files.Add($f.FullName) }
        }
    }
    foreach ($tool in $Man.tools) {
        $info = Join-Path $Root (($tool.folder -replace '/', '\') + '\TOOL_INFO.md')
        if (Test-Path -LiteralPath $info) { $files.Add($info) }
    }
    foreach ($extra in @('10-Unverified\README.md', '02-Scripting-and-Automation\Custom-Scripts\README.md')) {
        $p = Join-Path $Root $extra
        if (Test-Path -LiteralPath $p) { $files.Add($p) }
    }

    $patterns = @(
        @{ name = 'secret assignment'; regex = '(?i)\b(stream[_-]?key|password|passphrase|secret|api[_-]?key|auth[_-]?token|access[_-]?token)\b\s*[:=]\s*["'']?(?<v>[A-Za-z0-9_\-\.\+/]{12,})' },
        @{ name = 'GitHub token'; regex = '\b(gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,})\b' },
        @{ name = 'AWS access key'; regex = '\bAKIA[0-9A-Z]{16}\b' },
        @{ name = 'bearer token'; regex = '(?i)\bBearer\s+[A-Za-z0-9\-._~\+/]{20,}' }
    )

    $scanned = 0
    $user = $env:USERNAME
    foreach ($file in ($files | Sort-Object -Unique)) {
        $scanned++
        $rel = Get-RelForward -Root $Root -FullName $file
        $lineNo = 0
        foreach ($line in (Get-Content -LiteralPath $file)) {
            $lineNo++
            if ($user -and $line -match [regex]::Escape($user)) {
                Add-Finding $c ("{0}:{1}: Windows username found" -f $rel, $lineNo)
            }
            foreach ($p in $patterns) {
                if ($line -match $p.regex) {
                    Add-Finding $c ("{0}:{1}: possible {2}" -f $rel, $lineNo, $p.name)
                }
            }
        }
    }
    $c.detail = "files-scanned=$scanned patterns=$($patterns.Count)"
    return $c
}

# ---------------------------------------------------------------------------
# Check 10: OBS tripwire
# ---------------------------------------------------------------------------
function Get-DirSnapshot {
    param([string]$Dir)
    $map = @{}
    if (-not (Test-Path -LiteralPath $Dir)) { return $map }
    foreach ($item in (Get-ChildItem -LiteralPath $Dir -Recurse -Force -ErrorAction SilentlyContinue)) {
        $rel = '/' + ($item.FullName.Substring($Dir.Length).TrimStart('\') -replace '\\', '/')
        $map[$rel] = [pscustomobject]@{
            d = $item.PSIsContainer
            s = if ($item.PSIsContainer) { $null } else { [long]$item.Length }
            t = $item.LastWriteTimeUtc.ToString('o')
        }
    }
    return $map
}

function Invoke-TripwireCheck {
    param([string]$Root)
    $c = New-Check 10 'OBS tripwire against the Phase 0 baseline'
    $baselinePath = Join-Path $Root '13-Logs\obs-baseline.json'
    if (-not (Test-Path -LiteralPath $baselinePath)) { Add-Finding $c 'obs-baseline.json missing'; return $c }
    $baseline = Get-Content -LiteralPath $baselinePath -Raw | ConvertFrom-Json

    $obsDir = [string]$baseline.obs_install_dir
    $dataDir = [string]$baseline.obs_data_dir
    if (-not (Test-Path -LiteralPath $obsDir)) { Add-Finding $c "OBS install dir not present: $obsDir"; return $c }

    # The baseline stores paths with the username replaced by <user>, so it can be
    # committed. Resolve it for the current account before comparing.
    if ($dataDir.Contains('<user>')) {
        $dataDir = $dataDir.Replace('<user>', $env:USERNAME)
    }
    if (-not (Test-Path -LiteralPath $dataDir)) {
        $fallback = Join-Path $env:APPDATA 'obs-studio'
        if (Test-Path -LiteralPath $fallback) { $dataDir = $fallback }
        else { Add-Finding $c "OBS data dir not present: $dataDir"; return $c }
    }

    $baseInstall = @{}
    foreach ($e in $baseline.install) { $baseInstall[[string]$e.p] = $e }
    $curInstall = Get-DirSnapshot -Dir $obsDir

    foreach ($k in $curInstall.Keys) {
        if (-not $baseInstall.ContainsKey($k)) { Add-Finding $c "install: added $k"; continue }
        $e = $baseInstall[$k]
        if ([bool]$e.d -ne $curInstall[$k].d) { Add-Finding $c "install: type changed $k" }
        elseif (-not $curInstall[$k].d -and [string]$e.s -ne [string]$curInstall[$k].s) {
            Add-Finding $c "install: size changed $k"
        }
    }
    foreach ($k in $baseInstall.Keys) {
        if (-not $curInstall.ContainsKey($k)) { Add-Finding $c "install: removed $k" }
    }

    $ignored = @($baseline.ignored_prefixes)
    $isIgnored = {
        param([string]$p)
        foreach ($prefix in $ignored) {
            if ($p -eq $prefix -or $p.StartsWith($prefix + '/')) { return $true }
        }
        return $false
    }

    $baseData = @{}
    foreach ($e in $baseline.data) {
        $p = [string]$e.p
        if (-not (& $isIgnored $p)) { $baseData[$p] = $e }
    }
    $curDataAll = Get-DirSnapshot -Dir $dataDir
    $curData = @{}
    foreach ($k in $curDataAll.Keys) {
        if (-not (& $isIgnored $k)) { $curData[$k] = $curDataAll[$k] }
    }
    foreach ($k in $curData.Keys) {
        if (-not $baseData.ContainsKey($k)) { Add-Finding $c "data: added $k"; continue }
        $e = $baseData[$k]
        if ([bool]$e.d -ne $curData[$k].d) { Add-Finding $c "data: type changed $k" }
        elseif (-not $curData[$k].d -and [string]$e.s -ne [string]$curData[$k].s) { Add-Finding $c "data: size changed $k" }
    }
    foreach ($k in $baseData.Keys) {
        if (-not $curData.ContainsKey($k)) { Add-Finding $c "data: removed $k" }
    }

    $c.detail = "install=$($curInstall.Count) data-compared=$($curData.Count) ignored=$($ignored.Count)"
    return $c
}

# ---------------------------------------------------------------------------
# Check 11: execution log and honesty fields
# ---------------------------------------------------------------------------
function Invoke-ExecutionLogCheck {
    param($Man, [string]$Root)
    $c = New-Check 11 'Execution log shows nothing downloaded was run and nothing was installed'
    $logPath = Join-Path $Root '13-Logs\execution.log'
    if (-not (Test-Path -LiteralPath $logPath)) { Add-Finding $c 'execution.log missing'; return $c }

    $lines = @(Get-Content -LiteralPath $logPath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($lines.Count -eq 0) { Add-Finding $c 'execution.log is empty'; return $c }

    $actions = [System.Collections.Generic.HashSet[string]]::new()
    $parsed = 0
    foreach ($line in $lines) {
        $m = [regex]::Match($line, '^(?<ts>[^|]+)\|(?<phase>[^|]+)\|(?<tool>[^|]+)\|(?<action>[^|]+)\|(?<target>[^|]+)\|(?<status>[^|]+)\|(?<detail>.*)$')
        if (-not $m.Success) { continue }
        $parsed++
        $action = $m.Groups['action'].Value.Trim()
        $target = $m.Groups['target'].Value.Trim()
        $detail = $m.Groups['detail'].Value.Trim()
        [void]$actions.Add($action)

        if ($action -match '(?i)^(execute|run|install|launch|start-process|invoke-expression)') {
            Add-Finding $c "action '$action' in the log suggests downloaded content was run"
        }
        # Downloading an installer is allowed; running one is not. Match execution
        # markers only, so a file name that contains "installer" is not a finding.
        foreach ($needle in @('obs64.exe', 'Start-Process', 'Invoke-Expression')) {
            if ($target -like "*$needle*" -or $detail -like "*$needle*") {
                Add-Finding $c "log mentions $needle (action $action)"
            }
        }
        if ($detail -match '(?i)\b(executed|launched|installed)\b') {
            Add-Finding $c "log says '$($Matches[1])' (action $action)"
        }
    }
    if ($parsed -eq 0) { Add-Finding $c 'no log line matched the expected 7-field format' }

    foreach ($tool in $Man.tools) {
        if ($tool.installation_status -ne 'not-installed') {
            Add-Finding $c "$($tool.id): installation_status is $($tool.installation_status)"
        }
        if ($tool.tested_by_agent -ne $false) {
            Add-Finding $c "$($tool.id): tested_by_agent is $($tool.tested_by_agent)"
        }
    }

    $c.detail = "lines=$($lines.Count) parsed=$parsed distinct-actions=$($actions.Count)"
    return $c
}

# ---------------------------------------------------------------------------
# Check 12: PowerShell parse and run evidence
# ---------------------------------------------------------------------------
function Invoke-ScriptCheck {
    param([string]$Root)
    $c = New-Check 12 'PowerShell scripts parse and their run state is recorded'
    $scriptDir = Join-Path $Root '12-Utilities'
    $scripts = @(Get-ChildItem -LiteralPath $scriptDir -Recurse -File | Where-Object { $_.Extension -in @('.ps1', '.psm1') } | Sort-Object FullName)
    if ($scripts.Count -eq 0) { Add-Finding $c 'no PowerShell scripts found'; return $c }

    $logPath = Join-Path $Root '13-Logs\execution.log'
    $logText = if (Test-Path -LiteralPath $logPath) { Get-Content -LiteralPath $logPath -Raw } else { '' }

    $actionByScript = @{
        'Get-OBSInfo.ps1'       = 'detect-obs'
        'Verify-Checksums.ps1'  = 'verify-checksums'
        'Generate-Manifest.ps1' = 'generate-manifest'
        'Update-Library.ps1'    = 'update-library'
        'Download-Missing.ps1'  = 'download-missing'
        'Backup-OBS.ps1'        = 'backup-obs'
        'Test-Library.ps1'      = 'test-library'
        'Open-README.ps1'       = 'open-readme'
    }

    $parsed = 0
    $runEvidence = [System.Collections.Generic.List[string]]::new()
    $noEvidence = [System.Collections.Generic.List[string]]::new()
    foreach ($s in $scripts) {
        $tokens = $null
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($s.FullName, [ref]$tokens, [ref]$errors) | Out-Null
        if ($errors -and $errors.Count -gt 0) {
            foreach ($e in $errors) { Add-Finding $c ("{0}: parse error line {1}: {2}" -f $s.Name, $e.Extent.StartLineNumber, $e.Message) }
        }
        else { $parsed++ }

        $action = $actionByScript[$s.Name]
        if ($action) {
            if ($logText -match [regex]::Escape($action)) { $runEvidence.Add($s.Name) }
            else { $noEvidence.Add($s.Name) }
        }
    }

    $c.detail = "scripts=$($scripts.Count) parsed=$parsed logged=$($runEvidence.Count) not-logged=$($noEvidence.Count)"
    if ($noEvidence.Count -gt 0) {
        $c.detail += '; not logged: ' + ($noEvidence -join ', ')
    }
    return $c
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
try {
    $root = Get-ToolkitRoot
    $man = Read-ManifestOrThrow

    $checks = [System.Collections.Generic.List[object]]::new()
    $checks.Add((Invoke-LayoutCheck -Man $man -Root $root))
    $checks.Add((Invoke-SchemaCheck -Root $root))
    $checks.Add((Invoke-AssetCheck -Man $man -Root $root))
    $checks.Add((Invoke-IncludedCheck -Man $man -Root $root))
    $checks.Add((Invoke-NonIncludedCheck -Man $man -Root $root))
    $checks.Add((Invoke-DuplicateCheck -Man $man -Root $root))
    $checks.Add((Invoke-MarkdownCheck -Man $man -Root $root))
    $checks.Add((Invoke-DocConsistencyCheck -Man $man -Root $root))
    $checks.Add((Invoke-SecretsCheck -Man $man -Root $root))
    if ($SkipTripwire) {
        $t = New-Check 10 'OBS tripwire against the Phase 0 baseline'
        $t.status = 'SKIP'
        $t.detail = 'skipped by -SkipTripwire'
        $checks.Add($t)
    }
    else {
        $checks.Add((Invoke-TripwireCheck -Root $root))
    }
    $checks.Add((Invoke-ExecutionLogCheck -Man $man -Root $root))
    $checks.Add((Invoke-ScriptCheck -Root $root))

    $checks = @($checks | Sort-Object id)
    $failed = @($checks | Where-Object { $_.status -eq 'FAIL' })
    $skipped = @($checks | Where-Object { $_.status -eq 'SKIP' })
    $passed = @($checks | Where-Object { $_.status -eq 'PASS' })

    $report = [pscustomobject]@{
        generated_at_utc = Get-ToolkitTimestamp
        library_root     = '<library>'
        tools            = $man.tools.Count
        assets           = @($man.tools.assets | Measure-Object).Count
        summary          = [pscustomobject]@{
            pass = $passed.Count
            fail = $failed.Count
            skip = $skipped.Count
        }
        checks           = @($checks | ForEach-Object {
                [pscustomobject]@{
                    id       = $_.id
                    name     = $_.name
                    status   = $_.status
                    detail   = $_.detail
                    findings = @($_.findings)
                }
            })
    }

    $reportPath = Join-Path $root '13-Logs\qa-result.json'
    $report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $reportPath -Encoding utf8NoBOM

    if (-not $Quiet) {
        Write-Host ''
        Write-Host 'OBS Toolkit QA' -ForegroundColor Cyan
        Write-Host ('-' * 78) -ForegroundColor DarkGray
        foreach ($chk in $checks) {
            $color = switch ($chk.status) { 'PASS' { 'Green' } 'FAIL' { 'Red' } default { 'Yellow' } }
            Write-Host ("[{0}] {1,2}. {2}" -f $chk.status, $chk.id, $chk.name) -ForegroundColor $color
            if ($chk.detail) { Write-Host ("       {0}" -f $chk.detail) -ForegroundColor DarkGray }
            foreach ($f in $chk.findings) { Write-Host ("       - {0}" -f $f) -ForegroundColor Red }
        }
        Write-Host ('-' * 78) -ForegroundColor DarkGray
    }
    Write-Host ("QA: {0} pass, {1} fail, {2} skip" -f $passed.Count, $failed.Count, $skipped.Count) `
        -ForegroundColor $(if ($failed.Count -eq 0) { 'Green' } else { 'Red' })
    Write-Host ("Report: {0}" -f $reportPath)

    Write-ToolkitLog -Phase 'qa' -ToolId '-' -Action 'test-library' -Target 'qa-result.json' `
        -Status $(if ($failed.Count -eq 0) { 'ok' } else { 'fail' }) `
        -Detail ("pass={0} fail={1} skip={2}" -f $passed.Count, $failed.Count, $skipped.Count)

    if ($failed.Count -gt 0) { exit 1 }
    exit 0
}
catch {
    Write-ToolkitError $_.Exception.Message
    try { Write-ToolkitLog -Phase 'qa' -ToolId '-' -Action 'test-library' -Target 'error' -Status fail -Detail $_.Exception.Message } catch { }
    exit 2
}
