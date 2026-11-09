#Requires -Version 7.0
<#
.SYNOPSIS
    Opens the library README in the default local application.

.DESCRIPTION
    Opens README.md (or README.ar.md with -Arabic) with the program Windows has
    registered for .md files, falling back to Notepad when no association exists.
    With -Path it opens a specific file inside the library instead.

    The script only opens local files. It never opens a URL, never launches a
    downloaded tool, and never touches OBS. Paths are resolved under the library
    root so it cannot be pointed at an arbitrary file outside the library.

.PARAMETER Arabic
    Open README.ar.md instead of README.md.

.PARAMETER Path
    A path relative to the library root, for example
    '00-Documentation\SECURITY_GUIDE.md'. Must resolve inside the library.

.PARAMETER Print
    Print the resolved path and exit without launching anything.

.EXAMPLE
    pwsh -NoProfile -ExecutionPolicy Bypass -File .\12-Utilities\Open-README.ps1

.EXAMPLE
    .\Open-README.ps1 -Arabic

.EXAMPLE
    .\Open-README.ps1 -Path '00-Documentation\INSTALLATION_GUIDE.md'

.EXAMPLE
    .\Open-README.ps1 -Print

.NOTES
    Exit codes: 0 = opened or printed, 1 = file not found or outside the library,
    2 = script error.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [switch]$Arabic,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Path,

    [Parameter()]
    [switch]$Print
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'Common.psm1') -Force

try {
    $root = Get-ToolkitRoot

    if ($Path) {
        if ([System.IO.Path]::IsPathRooted($Path)) {
            Write-ToolkitError "Path must be relative to the library root: $Path"
            exit 1
        }
        $target = [System.IO.Path]::GetFullPath((Join-Path $root $Path))
        if (-not (Test-PathUnder -Path $target -Parent $root)) {
            Write-ToolkitError "Path resolves outside the library root: $Path"
            exit 1
        }
    }
    else {
        $name = if ($Arabic) { 'README.ar.md' } else { 'README.md' }
        $target = Join-Path $root $name
    }

    if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
        Write-ToolkitError "file not found: $target"
        exit 1
    }

    $relative = $target.Substring($root.Length).TrimStart('\', '/') -replace '\\', '/'
    Write-Host ("{0}" -f $relative) -ForegroundColor Cyan
    Write-Host ("{0}" -f $target) -ForegroundColor DarkGray

    if ($Print) {
        Write-Host 'Print only: nothing was launched.' -ForegroundColor DarkGray
        Write-ToolkitLog -Phase 'utilities' -ToolId '-' -Action 'open-readme' -Target $relative -Status ok -Detail 'print-only'
        exit 0
    }

    $extension = [System.IO.Path]::GetExtension($target)
    $association = $null
    try { $association = (Get-ItemProperty -LiteralPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$extension\UserChoice" -ErrorAction Stop).ProgId } catch { }

    if ($association) {
        Write-Host ("Opening with the registered handler ({0}) ..." -f $association) -ForegroundColor DarkGray
        Invoke-Item -LiteralPath $target
        $detail = "handler=$association"
    }
    else {
        Write-Host 'No .md association found; opening with Notepad.' -ForegroundColor DarkGray
        Start-Process -FilePath 'notepad.exe' -ArgumentList @($target)
        $detail = 'handler=notepad'
    }

    Write-ToolkitLog -Phase 'utilities' -ToolId '-' -Action 'open-readme' -Target $relative -Status ok -Detail $detail
    exit 0
}
catch {
    Write-ToolkitError $_.Exception.Message
    try { Write-ToolkitLog -Phase 'utilities' -ToolId '-' -Action 'open-readme' -Target 'error' -Status fail -Detail $_.Exception.Message } catch { }
    exit 2
}
