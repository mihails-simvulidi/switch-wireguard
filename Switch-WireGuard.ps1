param (
    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z0-9_-]+$')]
    [string]$TunnelName,

    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9.*]+$')]
    [string]$IpMask
)

try {
    $IsInNetwork = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -like $IpMask }
}
catch {
    Write-Error "Failed to get network addresses: $_"
    exit 1
}

try {
    $ServiceName = "WireGuardTunnel`$$TunnelName"
    if ($IsInNetwork) {
        Write-Host "IP matching '$IpMask' found. Stopping service '$ServiceName'..."
        Stop-Service -Name $ServiceName -ErrorAction Stop
        Write-Host "Service '$ServiceName' stopped."
    }
    else {
        Write-Host "IP matching '$IpMask' not found. Starting service '$ServiceName'..."
        Start-Service -Name $ServiceName -ErrorAction Stop
        Write-Host "Service '$ServiceName' started."
    }
}
catch {
    Write-Error "Failed to manage service '$ServiceName': $_"
    exit 1
}
