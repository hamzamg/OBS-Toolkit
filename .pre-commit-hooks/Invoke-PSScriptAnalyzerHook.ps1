#Requires -Version 7.0
<#
.SYNOPSIS
    Pre-commit hook: runs PSScriptAnalyzer on the PowerShell files given as
    arguments and fails when Error or Warning findings exist.

.DESCRIPTION
    Called by .pre-commit-config.yaml on changed files. Uses the repository
    PSScriptAnalyzerSettings.psd1. Requires pwsh 7+ and the PSScriptAnalyzer
    module (installed by CI; install locally with:
    Install-Module PSScriptAnalyzer -Scope CurrentUser -Force).
#>
param(
    [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
    [string[]]$Files
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$settings = Join-Path (Get-Location) 'PSScriptAnalyzerSettings.psd1'
if (-not (Test-Path -LiteralPath $settings)) {
    Write-Host "PSScriptAnalyzer hook: settings file not found: $settings"
    exit 1
}

$bad = New-Object System.Collections.Generic.List[object]
foreach ($file in $Files) {
    $issues = Invoke-ScriptAnalyzer -Path $file -Settings $settings
    foreach ($issue in $issues) {
        if ($issue.Severity -in @('Error', 'Warning')) { $bad.Add($issue) }
    }
}

if ($bad.Count -gt 0) {
    Write-Host "PSScriptAnalyzer found $($bad.Count) finding(s):"
    $bad | Format-Table -AutoSize RuleName, Severity, ScriptName, Line, Message | Out-String | Write-Host
    exit 1
}

Write-Host "PSScriptAnalyzer: 0 findings in $($Files.Count) file(s)"
exit 0
