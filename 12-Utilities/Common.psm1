#Requires -Version 7.0
<#
.SYNOPSIS
    Shared helpers for the OBS Toolkit utilities.

.DESCRIPTION
    Loaded by every script in 12-Utilities. Provides the library root, a safe path
    resolver, the manifest loader, and the append-only logger that writes the same
    line format as 13-Logs/execution.log:

        <timestamp> | <phase> | <tool-id> | <action> | <target> | <ok/fail/skip> | <detail>

    The logger replaces the Windows username with <user> and never writes a secret.

.NOTES
    This module performs no installation, no OBS change and no network access.
#>

Set-StrictMode -Version Latest

$script:ToolkitRoot = Split-Path -Parent $PSScriptRoot

function Get-ToolkitRoot {
    <#
    .SYNOPSIS
        Returns the absolute path of the library root.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return $script:ToolkitRoot
}

function Get-ToolkitTimestamp {
    <#
    .SYNOPSIS
        Returns the current UTC time as an ISO-8601 string with a trailing Z.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
}

function Format-ByteSize {
    <#
    .SYNOPSIS
        Formats a byte count as a human-readable size.

    .EXAMPLE
        Format-ByteSize -Bytes 125348099
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateRange(0, [long]::MaxValue)]
        [long]$Bytes
    )

    if ($Bytes -ge 1GB) { return ('{0:N2} GB' -f ($Bytes / 1GB)) }
    if ($Bytes -ge 1MB) { return ('{0:N2} MB' -f ($Bytes / 1MB)) }
    if ($Bytes -ge 1KB) { return ('{0:N1} KB' -f ($Bytes / 1KB)) }
    return "$Bytes B"
}

function Resolve-ToolkitPath {
    <#
    .SYNOPSIS
        Resolves a library-relative path and refuses to escape the library root.

    .DESCRIPTION
        Accepts forward or back slashes. Throws if the resolved path is outside the
        library root, which prevents a manifest typo from reading or writing
        somewhere else on disk.

    .EXAMPLE
        Resolve-ToolkitPath -RelativePath '11-Checksums/SHA256SUMS.txt'
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RelativePath
    )

    $root = Get-ToolkitRoot
    $normalized = $RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar
    $full = [System.IO.Path]::GetFullPath((Join-Path $root $normalized))
    $rootFull = [System.IO.Path]::GetFullPath($root)

    $comparison = [System.StringComparison]::OrdinalIgnoreCase
    $rootWithSep = $rootFull.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $full.StartsWith($rootWithSep, $comparison) -and $full -ne $rootFull) {
        throw "Path escapes the library root: $RelativePath"
    }
    return $full
}

function Test-PathUnder {
    <#
    .SYNOPSIS
        Returns $true when Path is inside (or equal to) Parent.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Parent
    )

    $p = [System.IO.Path]::GetFullPath($Path)
    $q = [System.IO.Path]::GetFullPath($Parent).TrimEnd([System.IO.Path]::DirectorySeparatorChar)
    $comparison = [System.StringComparison]::OrdinalIgnoreCase
    return ($p -eq $q) -or $p.StartsWith($q + [System.IO.Path]::DirectorySeparatorChar, $comparison)
}

function Get-ToolkitManifest {
    <#
    .SYNOPSIS
        Loads MANIFEST.json and returns it as an object.

    .DESCRIPTION
        Throws with a clear message when the manifest is missing or is not valid JSON.
        It does not validate against the schema; Generate-Manifest.ps1 does that.
    #>
    [CmdletBinding()]
    param()

    $path = Join-Path (Get-ToolkitRoot) 'MANIFEST.json'
    if (-not (Test-Path -LiteralPath $path)) {
        throw "MANIFEST.json not found at $path"
    }
    try {
        return Get-Content -LiteralPath $path -Raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "MANIFEST.json is not valid JSON: $($_.Exception.Message)"
    }
}

function Write-ToolkitLog {
    <#
    .SYNOPSIS
        Appends one line to 13-Logs/execution.log.

    .DESCRIPTION
        Line format: <timestamp> | <phase> | <tool-id> | <action> | <target> | <status> | <detail>

        The detail and target are sanitized: the Windows username becomes <user> and
        common secret patterns are redacted. The function creates 13-Logs if needed.
        Logging is allowed to write inside the library without -WhatIf.

    .PARAMETER Phase
        Phase name, for example 'utilities' or 'qa'.

    .PARAMETER ToolId
        Tool id, or '-' when the action is not tool-specific.

    .PARAMETER Action
        Short verb, for example 'verify-checksums' or 'backup-dryrun'.

    .PARAMETER Target
        What the action acted on.

    .PARAMETER Status
        One of ok, fail, skip.

    .PARAMETER Detail
        Free-text detail. Must not contain secrets.

    .EXAMPLE
        Write-ToolkitLog -Phase 'utilities' -ToolId '-' -Action 'verify' -Target 'SHA256SUMS.txt' -Status ok -Detail '57 files'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Phase,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$ToolId,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Action,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Target,
        [Parameter(Mandatory)][ValidateSet('ok', 'fail', 'skip')][string]$Status,
        [Parameter()][string]$Detail = ''
    )

    $logDir = Join-Path (Get-ToolkitRoot) '13-Logs'
    if (-not (Test-Path -LiteralPath $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    $logFile = Join-Path $logDir 'execution.log'

    $cleanTarget = Protect-ToolkitText $Target
    $cleanDetail = Protect-ToolkitText $Detail
    $line = '{0} | {1} | {2} | {3} | {4} | {5} | {6}' -f `
        (Get-ToolkitTimestamp), $Phase, $ToolId, $Action, $cleanTarget, $Status, $cleanDetail

    Add-Content -LiteralPath $logFile -Value $line -Encoding utf8NoBOM
}

function Write-ToolkitError {
    <#
    .SYNOPSIS
        Writes an error line to stderr without creating a terminating error.

    .DESCRIPTION
        The utilities run with $ErrorActionPreference = 'Stop'. In that mode
        Write-Error throws, which aborts the script before its documented exit
        code is applied. This helper writes the same text to stderr and lets the
        caller continue to `exit 1` or `exit 2` as documented.

    .PARAMETER Message
        The message to write. It is sanitized like every other log line.

    .EXAMPLE
        Write-ToolkitError "MANIFEST.json not found at $path"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Message
    )

    $clean = Protect-ToolkitText $Message
    if ($Host.UI -and $Host.UI.PSObject.Methods['WriteErrorLine']) {
        $Host.UI.WriteErrorLine("ERROR: $clean")
    }
    else {
        [Console]::Error.WriteLine("ERROR: $clean")
    }
}

function Get-ToolkitFileHash {
    <#
    .SYNOPSIS
        Computes SHA-256 of a file, normalizing CRLF to LF for text files.

    .DESCRIPTION
        SHA256SUMS.txt must be identical on every machine. Git stores text
        files as LF in blobs, but a Windows checkout (core.autocrlf=true)
        produces CRLF on disk, so hashing raw disk bytes differs per platform.
        This helper hashes LF-normalized content for text files (detected by the
        NUL-byte heuristic git itself uses) and exact bytes for binaries.

        Download provenance is stricter and lives elsewhere: Download-Missing.ps1
        and the manifest cross-checks hash the exact downloaded bytes and never
        normalize, so a tampered binary can never slip through.

    .PARAMETER Path
        Absolute file path.

    .PARAMETER Raw
        Hash the exact bytes (no text normalization). Used for manifest assets.

    .EXAMPLE
        Get-ToolkitFileHash 'MANIFEST.json'
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter()][switch]$Raw
    )

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if (-not $Raw) {
        $isText = $true
        foreach ($b in $bytes) {
            if ($b -eq 0) { $isText = $false; break }
        }
        if ($isText) {
            $text = [System.Text.Encoding]::UTF8.GetString($bytes)
            $normalized = $text -replace "`r`n", "`n"
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($normalized)
        }
    }

    $hasher = [System.Security.Cryptography.SHA256]::Create()
    try {
        $digest = $hasher.ComputeHash($bytes)
    }
    finally {
        $hasher.Dispose()
    }
    return ($digest | ForEach-Object { $_.ToString('x2') } | Join-String -Separator '')
}

function Protect-ToolkitText {
    <#
    .SYNOPSIS
        Replaces the Windows username with <user> and redacts obvious secrets.

    .DESCRIPTION
        Used before anything is written to a log or a report. It is a safety net, not
        a guarantee: never pass a secret to it on purpose.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Text
    )

    $result = $Text
    if ($env:USERNAME) {
        $result = $result -replace [regex]::Escape($env:USERNAME), '<user>'
    }
    $result = $result -replace '(?i)(stream[_-]?key\s*[:=]\s*)\S+', '$1<redacted>'
    $result = $result -replace '(?i)(password\s*[:=]\s*)\S+', '$1<redacted>'
    $result = $result -replace '(?i)(bearer\s+)[A-Za-z0-9._\-]+', '$1<redacted>'
    return $result
}

Export-ModuleMember -Function Get-ToolkitRoot, Get-ToolkitTimestamp, Format-ByteSize, `
    Resolve-ToolkitPath, Test-PathUnder, Get-ToolkitManifest, Write-ToolkitLog, `
    Write-ToolkitError, Protect-ToolkitText, Get-ToolkitFileHash
