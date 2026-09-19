$ErrorActionPreference = Stop

param (
    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z0-9_-]+$')]
    [string]$TunnelName,

    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9.*]+$')]
    [string]$IpMask,

    [Parameter()]
    [string]$ConfigPath
)

function Get-WireGuardExePath {
    $cmd = Get-Command wireguard.exe
    if ($cmd) {
        return $cmd.Source
    }

    $defaultPath = Join-Path $env:ProgramFiles 'WireGuard\wireguard.exe'
    if (Test-Path -LiteralPath $defaultPath) {
        return $defaultPath
    }

    return $null
}

function Get-WireGuardTunnelService {
    param (
        [Parameter(Mandatory)]
        [string]$TunnelName,

        [Parameter()]
        [string]$ConfigPath
    )

    $serviceName = "WireGuardTunnel`$$TunnelName"
    $existing = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($existing) {
        return $serviceName
    }

    Write-Warning "Service '$serviceName' was not found. Attempting to recreate it..."

    $wireguardExe = Get-WireGuardExePath
    if (-not $wireguardExe) {
        throw "wireguard.exe was not found. Install WireGuard or add it to PATH."
    }

    $candidateConfigPaths = @()
    if ($ConfigPath) {
        $candidateConfigPaths += $ConfigPath
    }

    $candidateConfigPaths += @(
        (Join-Path $env:ProgramFiles "WireGuard\Data\Configurations\$TunnelName.conf.dpapi"),
        (Join-Path $env:ProgramFiles "WireGuard\Data\Configurations\$TunnelName.conf"),
        (Join-Path $env:USERPROFILE "Documents\$TunnelName.conf"),
        (Join-Path $PSScriptRoot "$TunnelName.conf")
    )

    $resolvedConfigPath = $candidateConfigPaths |
    Where-Object { $_ -and (Test-Path -LiteralPath $_) } |
    Select-Object -First 1

    if (-not $resolvedConfigPath) {
        throw "Could not find a config file for tunnel '$TunnelName'. Provide -ConfigPath '<path to .conf or .conf.dpapi>' so the service can be recreated."
    }

    Write-Host "Recreating service '$serviceName' from '$resolvedConfigPath'..."
    & $wireguardExe /installtunnelservice $resolvedConfigPath

    $existing = Get-Service -Name $serviceName

    Write-Host "Service '$serviceName' recreated."
    return $serviceName
}

try {
    $IsInNetwork = Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred | Where-Object { $_.IPAddress -like $IpMask }
}
catch {
    Write-Error "Failed to get network addresses: $_"
    exit 1
}

try {
    if ($IsInNetwork) {
        $ServiceName = "WireGuardTunnel`$$TunnelName"
        $ExistingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if (-not $ExistingService) {
            Write-Host "IP matching '$IpMask' found. Service '$ServiceName' does not exist, nothing to stop."
            exit 0
        }

        Write-Host "IP matching '$IpMask' found. Stopping service '$ServiceName'..."
        Stop-Service -Name $ServiceName
        Write-Host "Service '$ServiceName' stopped."
    }
    else {
        if (-not (Test-Connection -ComputerName 1.1.1.1 -Count 1 -Quiet)) {
            Write-Host "No internet connectivity detected, skipping service start."
        }

        $ServiceName = Get-WireGuardTunnelService -TunnelName $TunnelName -ConfigPath $ConfigPath
        Write-Host "IP matching '$IpMask' not found. Starting service '$ServiceName'..."
        Start-Service -Name $ServiceName
        Write-Host "Service '$ServiceName' started."
    }
}
catch {
    Write-Error "Failed to manage service '$ServiceName': $_"
    exit 1
}
