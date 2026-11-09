#Requires -Version 7.0
<#
.SYNOPSIS
    Detects the local OBS Studio installation, read-only, and writes a JSON snapshot.

.DESCRIPTION
    Reports the OBS install path, version, architecture, portable flag, plugin module
    names, installed Python interpreters, and whether TCP port 4455 is listening and
    on which address.

    It does not launch OBS, read profiles or scenes, change any setting, or touch the
    network. It writes only inside 13-Logs.

    What it cannot read, and where to look in OBS instead:
      - The Python interpreter OBS is configured to use. That value lives in
        global.ini, which this toolkit does not open. Read it in
        OBS > Tools > Scripts > Python Settings.
      - The OBS WebSocket server state, port and password. Read them in
        OBS > Tools > WebSocket Server Settings.

.PARAMETER InstallPath
    Optional OBS install directory. When omitted, the default locations and the
    uninstall registry keys are checked.

.PARAMETER OutputPath
    Optional JSON output path. Defaults to 13-Logs/obs-info.json.

.EXAMPLE
    pwsh -NoProfile -ExecutionPolicy Bypass -File .\12-Utilities\Get-OBSInfo.ps1

.EXAMPLE
    .\Get-OBSInfo.ps1 -InstallPath 'D:\OBS-Portable' -Verbose

.NOTES
    Exit codes: 0 = information collected, 1 = OBS not found, 2 = script error.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$InstallPath,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'Common.psm1') -Force

function Get-PeMachine {
    <#
    .SYNOPSIS
        Reads the PE COFF machine field from an executable without running it.
    #>
    param([Parameter(Mandatory)][string]$Path)

    try {
        $fs = [System.IO.File]::OpenRead($Path)
        try {
            $br = [System.IO.BinaryReader]::new($fs)
            $fs.Position = 0x3C
            $peOffset = $br.ReadInt32()
            if ($peOffset -le 0 -or $peOffset -gt ($fs.Length - 6)) { return 'UNKNOWN' }
            $fs.Position = $peOffset
            $sig = $br.ReadUInt32()
            if ($sig -ne 0x00004550) { return 'UNKNOWN' }
            $machine = $br.ReadUInt16()
            switch ($machine) {
                0x8664 { return 'x64' }
                0x014C { return 'x86' }
                0xAA64 { return 'ARM64' }
                default { return ('UNKNOWN (0x{0:X4})' -f $machine) }
            }
        }
        finally { $fs.Dispose() }
    }
    catch { return 'UNKNOWN' }
}

function Find-ObsInstall {
    param([string]$Hint)

    $candidates = [System.Collections.Generic.List[string]]::new()
    if ($Hint) { $candidates.Add($Hint) }
    if (${env:ProgramFiles}) { $candidates.Add((Join-Path ${env:ProgramFiles} 'obs-studio')) }
    if (${env:ProgramFiles(x86)}) { $candidates.Add((Join-Path ${env:ProgramFiles(x86)} 'obs-studio')) }

    $registryRoots = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    foreach ($key in $registryRoots) {
        try {
            $entries = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue |
                Where-Object { $_.PSObject.Properties.Name -contains 'DisplayName' -and $_.DisplayName -like 'OBS Studio*' }
            foreach ($e in $entries) {
                if ($e.PSObject.Properties.Name -contains 'InstallLocation' -and $e.InstallLocation) {
                    $candidates.Add($e.InstallLocation)
                }
            }
        }
        catch { continue }
    }

    foreach ($c in $candidates) {
        if (-not $c) { continue }
        $exe = Join-Path $c 'bin\64bit\obs64.exe'
        if (Test-Path -LiteralPath $exe) { return (Resolve-Path -LiteralPath $c).Path }
    }
    return $null
}

function Get-PythonInterpreters {
    <#
    .SYNOPSIS
        Lists the Python interpreters the launcher knows about.

    .DESCRIPTION
        Parses both launcher layouts:
          -V:3.15 *   C:\Python315\python.exe      (Python 3.13+ launcher)
          -3.15-64    C:\Python315\python.exe      (older launcher)
        A -32 suffix means a 32-bit interpreter. Nothing is executed: the launcher
        only prints its registry, and the path is recorded without running it.
    #>
    $result = [System.Collections.Generic.List[object]]::new()
    $py = Get-Command py -ErrorAction SilentlyContinue
    if ($py) {
        try {
            $lines = & py -0p 2>$null
            foreach ($line in $lines) {
                $m = [regex]::Match($line, '^\s*-?(?:V:)?(?<ver>\d+\.\d+)(?<bits>-\d+)?\s*\*?\s+(?<path>[A-Za-z]:\\.+?)\s*$')
                if ($m.Success) {
                    $arch = if ($m.Groups['bits'].Value -eq '-32') { 'x86' } else { 'x64' }
                    $result.Add([pscustomobject]@{
                        version = $m.Groups['ver'].Value
                        arch    = $arch
                        path    = $m.Groups['path'].Value.Trim()
                        source  = 'py -0p'
                    })
                }
            }
        }
        catch { }
    }
    if ($result.Count -eq 0) {
        foreach ($name in @('python', 'python3')) {
            $cmd = Get-Command $name -ErrorAction SilentlyContinue
            if ($cmd) {
                $result.Add([pscustomobject]@{ version = 'UNKNOWN'; arch = 'UNKNOWN'; path = $cmd.Source; source = 'PATH' })
                break
            }
        }
    }
    return $result
}

try {
    $root = Get-ToolkitRoot

    if ($InstallPath) {
        $hinted = Join-Path $InstallPath 'bin\64bit\obs64.exe'
        if (-not (Test-Path -LiteralPath $hinted)) {
            Write-ToolkitError "no bin\64bit\obs64.exe under the supplied -InstallPath: $InstallPath"
            exit 1
        }
    }

    $obsDir = Find-ObsInstall -Hint $InstallPath
    if (-not $obsDir) {
        Write-Host 'OBS Studio was not found in the default locations or the uninstall registry.' -ForegroundColor Yellow
        Write-Host 'Pass -InstallPath with the OBS folder that contains bin\64bit\obs64.exe.'
        Write-ToolkitLog -Phase 'utilities' -ToolId '-' -Action 'detect-obs' -Target 'default-locations' -Status fail -Detail 'OBS not found'
        exit 1
    }

    $exe = Join-Path $obsDir 'bin\64bit\obs64.exe'
    $version = 'UNKNOWN'
    try { $version = (Get-Item -LiteralPath $exe).VersionInfo.FileVersion } catch { }

    $arch = Get-PeMachine -Path $exe

    $portableMarker = Join-Path $obsDir 'portable_mode.txt'
    $portableConfig = Join-Path $obsDir 'config\obs-studio'
    $isPortable = (Test-Path -LiteralPath $portableMarker) -or (Test-Path -LiteralPath $portableConfig)

    $pluginDir = Join-Path $obsDir 'obs-plugins\64bit'
    $modules = @()
    if (Test-Path -LiteralPath $pluginDir) {
        $modules = Get-ChildItem -LiteralPath $pluginDir -Filter '*.dll' -File |
            Sort-Object Name | Select-Object -ExpandProperty Name
    }

    $python = @(Get-PythonInterpreters | ForEach-Object {
            [pscustomobject]@{
                version = $_.version
                arch    = $_.arch
                path    = Protect-ToolkitText -Text $_.path
                source  = $_.source
            }
        })

    $port4455 = @()
    try {
        $port4455 = Get-NetTCPConnection -LocalPort 4455 -ErrorAction SilentlyContinue |
            Select-Object LocalAddress, LocalPort, State, OwningProcess
    }
    catch { }

    $dataDir = if ($isPortable) { Join-Path $obsDir 'config\obs-studio' } else { Join-Path $env:APPDATA 'obs-studio' }
    $logDir = Join-Path $dataDir 'logs'
    $newestLog = $null
    if (Test-Path -LiteralPath $logDir) {
        $newestLog = Get-ChildItem -LiteralPath $logDir -Filter '*.txt' -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
    }

    $info = [pscustomobject]@{
        generated_at_utc        = Get-ToolkitTimestamp
        obs_install_dir         = (Protect-ToolkitText -Text $obsDir)
        obs_executable          = (Protect-ToolkitText -Text $exe)
        obs_version             = $version
        obs_arch                = $arch
        obs_portable            = [bool]$isPortable
        portable_marker         = (Test-Path -LiteralPath $portableMarker)
        data_dir                = (Protect-ToolkitText -Text $dataDir)
        log_dir                 = (Protect-ToolkitText -Text $logDir)
        newest_log              = if ($newestLog) { $newestLog.Name } else { $null }
        plugin_module_count     = @($modules).Count
        plugin_modules          = @($modules)
        python_interpreters     = $python
        port_4455_listening     = (@($port4455).Count -gt 0)
        port_4455_connections   = @($port4455 | ForEach-Object {
                [pscustomobject]@{
                    local_address = $_.LocalAddress
                    local_port    = $_.LocalPort
                    state         = [string]$_.State
                    owning_pid    = $_.OwningProcess
                }
            })
        not_readable            = @(
            'OBS configured Python path (global.ini is not opened; read it in Tools > Scripts > Python Settings)',
            'OBS WebSocket enabled state, port and password (read them in Tools > WebSocket Server Settings)',
            'Profiles, scene collections and plugin configuration (private data, never opened)'
        )
    }

    if (-not $OutputPath) {
        $OutputPath = Join-Path $root '13-Logs\obs-info.json'
    }
    $OutputPath = [System.IO.Path]::GetFullPath($OutputPath)
    $outDir = Split-Path -Parent $OutputPath
    if ($outDir -and -not (Test-Path -LiteralPath $outDir)) {
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    }
    $info | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputPath -Encoding utf8NoBOM

    Write-Host ''
    Write-Host 'OBS Studio' -ForegroundColor Cyan
    Write-Host ("  install dir : {0}" -f $info.obs_install_dir)
    Write-Host ("  version     : {0}" -f $info.obs_version)
    Write-Host ("  architecture: {0}" -f $info.obs_arch)
    Write-Host ("  portable    : {0}" -f $info.obs_portable)
    Write-Host ("  data dir    : {0}" -f $info.data_dir)
    Write-Host ("  newest log  : {0}" -f ($(if ($info.newest_log) { $info.newest_log } else { 'none' })))
    Write-Host ("  modules     : {0} DLL(s) in obs-plugins\64bit" -f $info.plugin_module_count)
    Write-Host ''
    Write-Host 'Python interpreters' -ForegroundColor Cyan
    if ($python.Count -eq 0) { Write-Host '  none found via py -0p or PATH' }
    foreach ($p in $python) { Write-Host ("  {0,-8} {1,-4} {2}" -f $p.version, $p.arch, $p.path) }
    Write-Host ''
    Write-Host 'Port 4455 (OBS WebSocket default)' -ForegroundColor Cyan
    if ($info.port_4455_listening) {
        foreach ($c in $info.port_4455_connections) {
            Write-Host ("  {0}:{1} {2} pid={3}" -f $c.local_address, $c.local_port, $c.state, $c.owning_pid)
        }
    }
    else {
        Write-Host '  not listening'
    }
    Write-Host ''
    Write-Host 'Not readable by this script' -ForegroundColor Cyan
    foreach ($n in $info.not_readable) { Write-Host ("  - {0}" -f $n) }
    Write-Host ''
    Write-Host ("JSON written to {0}" -f (Protect-ToolkitText -Text $OutputPath))

    Write-ToolkitLog -Phase 'utilities' -ToolId '-' -Action 'detect-obs' -Target $info.obs_install_dir -Status ok -Detail ("version={0} arch={1} portable={2} modules={3} port4455={4}" -f $info.obs_version, $info.obs_arch, $info.obs_portable, $info.plugin_module_count, $info.port_4455_listening)
    exit 0
}
catch {
    Write-ToolkitError $_.Exception.Message
    try { Write-ToolkitLog -Phase 'utilities' -ToolId '-' -Action 'detect-obs' -Target 'error' -Status fail -Detail $_.Exception.Message } catch { }
    exit 2
}
