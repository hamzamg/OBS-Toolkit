#Requires -Version 7.0
<#
.SYNOPSIS
    Checks GitHub for newer releases and, on request, downloads one into a new
    version folder and records it in MANIFEST.json.

.DESCRIPTION
    Default mode is -CheckOnly: it reads MANIFEST.json, queries the GitHub releases
    API for each tool (read-only), compares the newest stable release with the
    version recorded in the manifest, and prints a table. It downloads nothing.

    With -Apply -Tool <id> it downloads the selected release asset for that tool
    into <Tool>/Downloads/<tag>/ (never overwriting an older version), computes
    SHA-256, records the platform digest and Authenticode result, appends a new
    asset entry to the manifest (the previous entry stays), updates the release
    fields, appends a CHANGELOG.md entry, and regenerates the checksum files.

    It never installs anything, never touches OBS, and never deletes a file.

    Network access is limited to api.github.com and the GitHub release-asset CDN
    that github.com redirects to. Responses are cached in 13-Logs/cache/api/.
    The script reads X-RateLimit-Remaining and backs off on 403/429; if a cached
    response exists it falls back to it.

.PARAMETER Apply
    Download and record a new version. Requires -Tool.

.PARAMETER Tool
    One or more tool ids from MANIFEST.json (for example multi-rtmp). Used to
    narrow -CheckOnly and required by -Apply.

.PARAMETER Refresh
    Ignore the cached API response and fetch a fresh one.

.PARAMETER Json
    Emit the check result as JSON instead of a table.

.EXAMPLE
    pwsh -NoProfile -ExecutionPolicy Bypass -File .\12-Utilities\Update-Library.ps1

.EXAMPLE
    .\Update-Library.ps1 -Tool multi-rtmp,tuna -Refresh

.EXAMPLE
    .\Update-Library.ps1 -Apply -Tool multi-rtmp -WhatIf

.EXAMPLE
    .\Update-Library.ps1 -Apply -Tool multi-rtmp

.NOTES
    Exit codes: 0 = completed with no error, 1 = at least one tool failed,
    2 = script error (bad parameter, missing manifest).
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter()]
    [switch]$Apply,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string[]]$Tool,

    [Parameter()]
    [switch]$Refresh,

    [Parameter()]
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'Common.psm1') -Force

$script:UserAgent = 'OBS-Toolkit/1.0 (+https://github.com)'
$script:RateRemaining = $null

function ConvertTo-VersionOrNull {
    param([AllowNull()][string]$Tag)
    if ([string]::IsNullOrWhiteSpace($Tag)) { return $null }
    $clean = $Tag.Trim() -replace '^[vV]', ''
    if ($clean -match '^\d+(\.\d+){0,3}$') { return [version]$clean }
    return $null
}

function Test-NewerTag {
    param([string]$Candidate, [AllowNull()][string]$Current)
    $n = ConvertTo-VersionOrNull $Candidate
    $c = ConvertTo-VersionOrNull $Current
    if ($n -and $c) { return ($n -gt $c) }
    if ($n -and -not $c) { return $true }
    if (-not $n -and $c) { return $false }
    return ([string]$Candidate -ne [string]$Current)
}

function Get-RepoSlug {
    param([Parameter(Mandatory)]$Tool)
    $url = [string]$Tool.repository.url
    $m = [regex]::Match($url, '^https?://github\.com/(?<owner>[^/]+)/(?<repo>[^/]+?)(?:\.git)?/?$')
    if (-not $m.Success) { return $null }
    return [pscustomobject]@{ owner = $m.Groups['owner'].Value; repo = $m.Groups['repo'].Value }
}

function Get-GitHubJson {
    param(
        [Parameter(Mandatory)][string]$Uri,
        [Parameter(Mandatory)][string]$CacheFile,
        [switch]$ForceRefresh
    )

    $cachePath = Join-Path (Get-ToolkitRoot) $CacheFile
    $haveCache = Test-Path -LiteralPath $cachePath

    if ($haveCache -and -not $ForceRefresh) {
        try { return (Get-Content -LiteralPath $cachePath -Raw | ConvertFrom-Json -ErrorAction Stop) }
        catch { Write-Verbose "cache unreadable, refetching: $cachePath" }
    }

    $headers = @{ 'User-Agent' = $script:UserAgent; 'Accept' = 'application/vnd.github+json' }
    $responseHeaders = $null
    try {
        $data = Invoke-RestMethod -Uri $Uri -Headers $headers -Method Get -TimeoutSec 60 `
            -ResponseHeadersVariable responseHeaders -ErrorAction Stop
    }
    catch {
        $status = $null
        try { $status = [int]$_.Exception.Response.StatusCode } catch { }
        $hint = ''
        if ($status -eq 403 -or $status -eq 429) {
            $hint = ' (rate limited or forbidden; wait for the hourly reset or use the cache)'
        }
        if ($haveCache) {
            Write-Warning ("GitHub request failed{0}: {1}. Using cached response." -f $hint, $_.Exception.Message)
            return (Get-Content -LiteralPath $cachePath -Raw | ConvertFrom-Json)
        }
        throw ("GitHub request failed{0}: {1}" -f $hint, $_.Exception.Message)
    }

    if ($responseHeaders -and $responseHeaders.ContainsKey('X-RateLimit-Remaining')) {
        $raw = $responseHeaders['X-RateLimit-Remaining']
        if ($raw -is [array]) { $raw = $raw[0] }
        $script:RateRemaining = [int]$raw
    }

    $dir = Split-Path -Parent $cachePath
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    ($data | ConvertTo-Json -Depth 40) | Set-Content -LiteralPath $cachePath -Encoding utf8NoBOM
    return $data
}

function Test-AssetName {
    param([string]$Name)
    if ([string]::IsNullOrWhiteSpace($Name)) { return $false }
    if ($Name -match '(?i)(sha256|sha512|checksums?|\.sha\d*$|\.sig$|\.asc$|\.minisig$|\.pem$|\.txt$|\.json$)') { return $false }
    return ($Name -match '(?i)\.(zip|exe|msi|7z|tar\.gz|tgz|lua|py)$')
}

function Select-ReleaseAsset {
    param(
        [Parameter(Mandatory)]$Release,
        [AllowNull()]$ExistingAssets
    )

    $candidates = @($Release.assets | Where-Object { Test-AssetName $_.name })
    if ($candidates.Count -eq 0) { return $null }

    $shape = $null
    if ($ExistingAssets -and @($ExistingAssets).Count -gt 0) {
        $shape = [string](@($ExistingAssets)[-1].filename)
    }

    $best = $null
    $bestScore = [int]::MinValue
    foreach ($c in $candidates) {
        $score = 0
        $ce = [System.IO.Path]::GetExtension($c.name).ToLowerInvariant()
        if ($shape) {
            $oe = [System.IO.Path]::GetExtension($shape).ToLowerInvariant()
            if ($ce -eq $oe) { $score += 100 }
            $shapeInstaller = ($shape -match '(?i)installer')
            $candInstaller = ($c.name -match '(?i)installer')
            if ($shapeInstaller -eq $candInstaller) { $score += 10 }
        }
        if ($c.name -match '(?i)(windows|win)') { $score += 20 }
        if ($c.name -match '(?i)(x64|64bit|amd64)') { $score += 15 }
        if ($c.name -match '(?i)(x86|32bit|win32)') { $score -= 40 }
        if ($c.name -match '(?i)(source|src)') { $score -= 20 }
        if ($score -gt $bestScore) { $bestScore = $score; $best = $c }
        elseif ($score -eq $bestScore -and $best -and $c.name -lt $best.name) { $best = $c }
    }
    return $best
}

function Get-CommitShaForTag {
    param(
        [Parameter(Mandatory)][string]$Owner,
        [Parameter(Mandatory)][string]$Repo,
        [Parameter(Mandatory)][string]$Tag
    )
    $cacheRel = "13-Logs/cache/api/ref__{0}__{1}__{2}.json" -f $Owner, $Repo, ($Tag -replace '[^A-Za-z0-9._-]', '_')
    try {
        $ref = Get-GitHubJson -Uri ("https://api.github.com/repos/{0}/{1}/git/ref/tags/{2}" -f $Owner, $Repo, $Tag) -CacheFile $cacheRel
    }
    catch { return $null }

    $type = [string]$ref.object.type
    $sha = [string]$ref.object.sha
    if ($type -eq 'tag' -and $sha) {
        $tagCache = "13-Logs/cache/api/tag__{0}__{1}__{2}.json" -f $Owner, $Repo, ($Tag -replace '[^A-Za-z0-9._-]', '_')
        try {
            $tagObj = Get-GitHubJson -Uri ("https://api.github.com/repos/{0}/{1}/git/tags/{2}" -f $Owner, $Repo, $sha) -CacheFile $tagCache
            if ($tagObj.object.sha) { return [string]$tagObj.object.sha }
        }
        catch { return $null }
    }
    if ($sha -match '^[0-9a-f]{40}$') { return $sha }
    return $null
}

function Get-SignatureInfo {
    param([Parameter(Mandatory)][string]$Path)
    $ext = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
    if ($ext -notin @('.exe', '.dll', '.msi')) {
        return [pscustomobject]@{ type = 'none'; status = 'not-checked'; signer = $null }
    }
    try {
        $sig = Get-AuthenticodeSignature -LiteralPath $Path -ErrorAction Stop
        switch ([string]$sig.Status) {
            'Valid' {
                $signer = $null
                if ($sig.SignerCertificate) { $signer = [string]$sig.SignerCertificate.Subject }
                return [pscustomobject]@{ type = 'authenticode'; status = 'valid'; signer = $signer }
            }
            'NotSigned' { return [pscustomobject]@{ type = 'authenticode'; status = 'unsigned'; signer = $null } }
            default { return [pscustomobject]@{ type = 'authenticode'; status = 'invalid'; signer = $null } }
        }
    }
    catch {
        return [pscustomobject]@{ type = 'authenticode'; status = 'invalid'; signer = $null }
    }
}

function Add-ChangelogEntry {
    param(
        [Parameter(Mandatory)][string]$ToolName,
        [Parameter(Mandatory)][string]$Tag,
        [Parameter(Mandatory)][string]$Filename,
        [Parameter(Mandatory)][string]$Sha256,
        [Parameter(Mandatory)][string]$Status
    )

    $path = Join-Path (Get-ToolkitRoot) 'CHANGELOG.md'
    $date = (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd')
    $entry = @(
        "## [$date] - $ToolName $Tag"
        ''
        '### Changed'
        "- Downloaded ``$Filename`` (SHA-256 ``$Sha256``, verification ``$Status``) into a new version folder."
        '- The previous version remains in `MANIFEST.json` and on disk; nothing was overwritten or deleted.'
        '- Updated the release fields and appended the new asset entry in `MANIFEST.json`; regenerated the checksum files.'
        ''
    ) -join "`n"

    if (-not (Test-Path -LiteralPath $path)) {
        $header = @(
            '# Changelog'
            ''
            'All dates are UTC. This file follows the spirit of Keep a Changelog: one'
            'entry per change, newest first. It records library changes, not OBS changes.'
            ''
        ) -join "`n"
        [System.IO.File]::WriteAllText($path, $header + "`n" + $entry, (New-Object System.Text.UTF8Encoding($false)))
        return
    }

    $text = [System.IO.File]::ReadAllText($path)
    $idx = $text.IndexOf("`n## ")
    if ($idx -lt 0) {
        $text = $text.TrimEnd() + "`n`n" + $entry
    }
    else {
        $text = $text.Substring(0, $idx + 1) + $entry + "`n" + $text.Substring($idx + 1)
    }
    [System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($false)))
}

function Invoke-ApplyUpdate {
    param(
        [Parameter(Mandatory)]$ToolObject,
        [Parameter(Mandatory)]$NewestRelease,
        [Parameter(Mandatory)]$Slug
    )

    $tag = [string]$NewestRelease.tag_name
    $asset = Select-ReleaseAsset -Release $NewestRelease -ExistingAssets $ToolObject.assets
    if (-not $asset) {
        throw "release $tag has no asset with a supported extension (.zip/.exe/.msi/.lua/.py)"
    }

    $folderAbs = Join-Path (Get-ToolkitRoot) (($ToolObject.folder -replace '/', '\'))
    $targetDir = Join-Path $folderAbs (Join-Path 'Downloads' $tag)
    $targetPath = Join-Path $targetDir ([string]$asset.name)
    $relPath = (($ToolObject.folder -replace '\\', '/') + "/Downloads/$tag/" + [string]$asset.name)

    if (Test-Path -LiteralPath $targetPath) {
        $existingHash = (Get-FileHash -LiteralPath $targetPath -Algorithm SHA256).Hash.ToLower()
        if ($existingHash -eq ([string]$asset.digest -replace '^sha256:', '')) {
            Write-Host ("  already downloaded and matching: {0}" -f $relPath) -ForegroundColor DarkGray
            return [pscustomobject]@{ applied = $false; reason = 'already-present'; path = $relPath }
        }
        throw "target file already exists with a different hash; refusing to overwrite: $relPath"
    }

    if (-not $PSCmdlet.ShouldProcess($relPath, "Download $tag and record it in MANIFEST.json")) {
        return [pscustomobject]@{ applied = $false; reason = 'whatif'; path = $relPath }
    }

    if (-not (Test-Path -LiteralPath $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    $partial = $targetPath + '.partial'
    Write-Host ("  downloading {0} ..." -f $asset.browser_download_url)
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $partial -TimeoutSec 900 `
        -Headers @{ 'User-Agent' = $script:UserAgent } -ErrorAction Stop
    Move-Item -LiteralPath $partial -Destination $targetPath -Force

    $size = (Get-Item -LiteralPath $targetPath).Length
    $sha = (Get-FileHash -LiteralPath $targetPath -Algorithm SHA256).Hash.ToLower()

    $digest = [string]$asset.digest
    $refSource = 'NONE'
    $refValue = $null
    $refMatch = $null
    if ($digest -match '^sha256:(?<h>[0-9a-f]{64})$') {
        $refSource = 'PLATFORM'
        $refValue = $Matches['h']
        $refMatch = ($sha -eq $refValue)
    }

    $signature = Get-SignatureInfo -Path $targetPath
    $verification = 'COMPUTED-ONLY'
    if ($signature.status -eq 'valid') { $verification = 'VERIFIED' }
    elseif ($refSource -eq 'PLATFORM' -and $refMatch) { $verification = 'INTEGRITY-ONLY' }
    if ($refSource -eq 'PLATFORM' -and $refMatch -eq $false) { $verification = 'FAILED' }

    $alternative = @($NewestRelease.assets | Where-Object { $_.name -ne $asset.name -and (Test-AssetName $_.name) } |
        ForEach-Object { $_.name }) -join ', '
    if ([string]::IsNullOrWhiteSpace($alternative)) { $alternative = $null }

    $newAsset = [pscustomobject]@{
        filename           = [string]$asset.name
        url                = [string]$asset.browser_download_url
        size_bytes         = [long]$size
        downloaded_at      = Get-ToolkitTimestamp
        local_path         = $relPath
        sha256             = $sha
        reference_checksum = [pscustomobject]@{ source = $refSource; value = $refValue; match = $refMatch }
        signature          = [pscustomobject]@{ type = $signature.type; status = $signature.status; signer = $signature.signer }
        verification_status = $verification
        alternative_asset  = $alternative
    }

    $commitSha = Get-CommitShaForTag -Owner $Slug.owner -Repo $Slug.repo -Tag $tag
    $ToolObject.release = [pscustomobject]@{
        tag          = $tag
        url          = [string]$NewestRelease.html_url
        published_at = [string]$NewestRelease.published_at
        prerelease   = [bool]$NewestRelease.prerelease
        commit_sha   = $commitSha
    }
    $ToolObject.assets = @($ToolObject.assets) + $newAsset

    $sourceUrl = "https://api.github.com/repos/{0}/{1}/releases" -f $Slug.owner, $Slug.repo
    $hasSource = @($ToolObject.sources | Where-Object { $_.url -eq $sourceUrl }).Count -gt 0
    if (-not $hasSource) {
        $ToolObject.sources = @($ToolObject.sources) + [pscustomobject]@{
            label            = 'GitHub releases (update check)'
            url              = $sourceUrl
            retrieved_at_utc = Get-ToolkitTimestamp
        }
    }

    Add-ChangelogEntry -ToolName $ToolObject.name -Tag $tag -Filename ([string]$asset.name) -Sha256 $sha -Status $verification

    Write-Host ("  recorded {0} ({1})" -f $relPath, $verification) -ForegroundColor Green
    return [pscustomobject]@{ applied = $true; reason = 'downloaded'; path = $relPath; sha256 = $sha; verification = $verification; size = $size }
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
try {
    $root = Get-ToolkitRoot
    $manifestPath = Join-Path $root 'MANIFEST.json'
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        throw "MANIFEST.json not found at $manifestPath"
    }

    if ($Apply -and (-not $Tool -or $Tool.Count -eq 0)) {
        Write-ToolkitError '-Apply requires -Tool <id> (for example: -Apply -Tool multi-rtmp).'
        exit 2
    }

    $man = Get-ToolkitManifest
    $selected = @($man.tools)
    if ($Tool -and $Tool.Count -gt 0) {
        $selected = @()
        foreach ($id in $Tool) {
            $match = @($man.tools | Where-Object { $_.id -eq $id -or $_.name -eq $id })
            if ($match.Count -eq 0) {
                Write-ToolkitError "unknown tool id: $id"
                exit 2
            }
            $selected += $match
        }
    }

    $results = [System.Collections.Generic.List[object]]::new()
    $failures = 0

    foreach ($t in $selected) {
        $slug = Get-RepoSlug -Tool $t
        if (-not $slug) {
            $results.Add([pscustomobject]@{ id = $t.id; name = $t.name; current = $t.release.tag; newest = $null; status = 'error'; note = 'repository URL is not a github.com repository' })
            $failures++
            continue
        }

        if ($t.type -eq 'docs-only') {
            $results.Add([pscustomobject]@{ id = $t.id; name = $t.name; current = $t.release.tag; newest = $null; status = 'docs-only'; note = 'bundled with OBS; no release asset to update' })
            continue
        }

        $cacheRel = "13-Logs/cache/api/releases__{0}__{1}.json" -f $slug.owner, $slug.repo
        try {
            $releases = Get-GitHubJson -Uri ("https://api.github.com/repos/{0}/{1}/releases?per_page=30" -f $slug.owner, $slug.repo) `
                -CacheFile $cacheRel -ForceRefresh:$Refresh
        }
        catch {
            $results.Add([pscustomobject]@{ id = $t.id; name = $t.name; current = $t.release.tag; newest = $null; status = 'error'; note = $_.Exception.Message })
            $failures++
            continue
        }

        $stable = @($releases | Where-Object { -not $_.draft -and -not $_.prerelease })
        if ($stable.Count -eq 0) {
            $note = if ($t.assets.Count -eq 0) { 'no releases and no assets; source-only tool' } else { 'no stable release published' }
            $results.Add([pscustomobject]@{ id = $t.id; name = $t.name; current = $t.release.tag; newest = $null; status = 'no-release'; note = $note })
            continue
        }

        # ConvertFrom-Json turns ISO-8601 strings into DateTime, so sort on a real
        # DateTime and never on a culture-formatted string (that orders 9/ after 11/).
        # ISO-8601 parses the same way in every culture, so the cast is safe here.
        $newest = $stable | Sort-Object -Property @{ Expression = { [datetime]$_.published_at } },
            @{ Expression = { [datetime]$_.created_at } } -Descending | Select-Object -First 1
        $newestTag = [string]$newest.tag_name
        $isNewer = Test-NewerTag -Candidate $newestTag -Current ([string]$t.release.tag)

        if (-not $isNewer) {
            $results.Add([pscustomobject]@{ id = $t.id; name = $t.name; current = $t.release.tag; newest = $newestTag; status = 'up-to-date'; note = '' })
            continue
        }

        $candidateAsset = Select-ReleaseAsset -Release $newest -ExistingAssets $t.assets
        $note = if ($candidateAsset) { [string]$candidateAsset.name } else { 'no supported asset in the new release' }

        if (-not $Apply) {
            $results.Add([pscustomobject]@{ id = $t.id; name = $t.name; current = $t.release.tag; newest = $newestTag; status = 'update-available'; note = $note })
            continue
        }

        try {
            $outcome = Invoke-ApplyUpdate -ToolObject $t -NewestRelease $newest -Slug $slug
            $results.Add([pscustomobject]@{ id = $t.id; name = $t.name; current = $t.release.tag; newest = $newestTag; status = $(if ($outcome.applied) { 'applied' } else { $outcome.reason }); note = $outcome.path })
        }
        catch {
            $results.Add([pscustomobject]@{ id = $t.id; name = $t.name; current = $t.release.tag; newest = $newestTag; status = 'error'; note = $_.Exception.Message })
            $failures++
        }
    }

    if ($Apply -and -not $WhatIfPreference) {
        $applied = @($results | Where-Object { $_.status -eq 'applied' })
        if ($applied.Count -gt 0) {
            if ($PSCmdlet.ShouldProcess('MANIFEST.json', 'Write updated manifest and regenerate checksums')) {
                ($man | ConvertTo-Json -Depth 40) + "`n" | Set-Content -LiteralPath $manifestPath -Encoding utf8NoBOM
                $gen = Join-Path $PSScriptRoot 'Generate-Manifest.ps1'
                if (Test-Path -LiteralPath $gen) {
                    & $gen
                    if ($LASTEXITCODE -ne 0) {
                        Write-Warning "Generate-Manifest.ps1 exited $LASTEXITCODE; inspect the checksum files."
                        $failures++
                    }
                }
            }
        }
    }

    if ($Json) {
        $payload = [pscustomobject]@{
            generated_at_utc = Get-ToolkitTimestamp
            mode             = $(if ($Apply) { 'apply' } else { 'check' })
            rate_remaining   = $script:RateRemaining
            results          = @($results)
        }
        $payload | ConvertTo-Json -Depth 6
    }
    else {
        Write-Host ''
        Write-Host ("OBS Toolkit update check ({0})" -f $(if ($Apply) { 'apply' } else { 'check-only' })) -ForegroundColor Cyan
        Write-Host ''
        $fmt = '{0,-30} {1,-14} {2,-14} {3,-18} {4}'
        Write-Host ($fmt -f 'TOOL', 'CURRENT', 'NEWEST', 'STATUS', 'NOTE') -ForegroundColor DarkGray
        Write-Host ('-' * 110) -ForegroundColor DarkGray
        foreach ($r in $results) {
            $color = switch ($r.status) {
                'update-available' { 'Yellow' }
                'applied' { 'Green' }
                'up-to-date' { 'DarkGray' }
                'error' { 'Red' }
                default { 'Gray' }
            }
            Write-Host ($fmt -f $r.id, $(if ($r.current) { $r.current } else { '-' }), $(if ($r.newest) { $r.newest } else { '-' }), $r.status, $r.note) -ForegroundColor $color
        }
        Write-Host ''
        if ($null -ne $script:RateRemaining) {
            Write-Host ("GitHub API requests remaining this hour: {0}" -f $script:RateRemaining) -ForegroundColor DarkGray
        }
        if (-not $Apply) {
            $updates = @($results | Where-Object { $_.status -eq 'update-available' })
            if ($updates.Count -gt 0) {
                Write-Host ''
                Write-Host 'Nothing was downloaded. To record one of these versions:' -ForegroundColor Cyan
                foreach ($u in $updates) { Write-Host ("  .\Update-Library.ps1 -Apply -Tool {0}" -f $u.id) }
                Write-Host ''
                Write-Host 'Read <tool>/TOOL_INFO.md section 4 before applying: a newer release may' -ForegroundColor Yellow
                Write-Host 'require a newer OBS than the one installed. This script does not check that.' -ForegroundColor Yellow
            }
        }
    }

    $summary = ("checked={0} update-available={1} applied={2} failures={3}" -f $results.Count,
        @($results | Where-Object { $_.status -eq 'update-available' }).Count,
        @($results | Where-Object { $_.status -eq 'applied' }).Count,
        $failures)
    Write-ToolkitLog -Phase 'utilities' -ToolId '-' -Action 'update-library' -Target $(if ($Apply) { 'apply' } else { 'check-only' }) `
        -Status $(if ($failures -gt 0) { 'fail' } else { 'ok' }) -Detail $summary

    if ($failures -gt 0) { exit 1 }
    exit 0
}
catch {
    Write-ToolkitError $_.Exception.Message
    try { Write-ToolkitLog -Phase 'utilities' -ToolId '-' -Action 'update-library' -Target 'error' -Status fail -Detail $_.Exception.Message } catch { }
    exit 2
}
