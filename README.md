# Switch-WireGuard

A simple PowerShell script to toggle a WireGuard tunnel based on the presence of a specific IPv4 address in your network configuration.

## Usage

```powershell
./Switch-WireGuard.ps1 -TunnelName <TunnelName> -IpMask <IpMask>
```

- `-TunnelName` (**required**): The name of the WireGuard tunnel service (e.g., `MyTunnel`). Only letters, numbers, underscores, and hyphens are allowed.
- `-IpMask` (**required**): The IPv4 address or mask to check for (e.g., `10.0.0.*`). Only digits, dots, and asterisks are allowed.

## How it works

- The script validates your input for allowed characters.
- If the specified IP mask is found among your active IPv4 addresses, the script stops the WireGuard tunnel service.
- If the IP mask is not found, the script starts the WireGuard tunnel service.
- The script prints status messages and error details to the console.


## Example

```powershell
./Switch-WireGuard.ps1 -TunnelName MyTunnel -IpMask 10.0.0.*
```

This will start or stop the `WireGuardTunnel$MyTunnel` service depending on whether an IP in the `10.0.0.*` range is present.

## Requirements
- PowerShell
- WireGuard installed as a Windows service
- Administrator privileges

## Error Handling
If an error occurs (e.g., invalid input, service not found, or insufficient permissions), the script will print an error message and exit.

## License
MIT
