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

## Automating with Task Scheduler

To automatically run this script when your network profile changes (e.g., when connecting or disconnecting from a network), you can set up a Task Scheduler task triggered by specific Windows events:

- **Log:** Microsoft-Windows-NetworkProfile/Operational
- **Event IDs:** 10000 (Network connected), 10001 (Network disconnected)

### Steps to Add the Task

1. Open **Task Scheduler** and select **Create Task...**
2. On the **General** tab:
	- Set a name (e.g., "Switch WireGuard on Network Change").
	- Select **Run with highest privileges**.
	- **Check** "Run whether user is logged on or not" to run the script in the background and hide the console window.
3. On the **Triggers** tab, add two separate triggers:

	- Click **New...** for the first trigger:
	  - Set **Begin the task** to **On an event**.
	  - Set **Log** to `Microsoft-Windows-NetworkProfile/Operational`.
	  - Set **Source** to `NetworkProfile`.
	  - Set **Event ID** to `10000` (numbers only, one per trigger).

	- Click **New...** again for the second trigger:
	  - Set the same options, but set **Event ID** to `10001`.

	> **Note:** Task Scheduler only allows a single numeric Event ID per trigger. You must create a separate trigger for each event you want to handle.
4. On the **Actions** tab, click **New...**
	- Set **Action** to **Start a program**.
	- Set **Program/script** to the location of `pwsh.exe`.
	- Set **Add arguments** to:
	  ```
	  -ExecutionPolicy Bypass -File "<full-path-to>\Switch-WireGuard.ps1" -TunnelName <TunnelName> -IpMask <IpMask>
	  ```
	  Replace `<full-path-to>`, `<TunnelName>`, and `<IpMask>` with your actual values.
5. Adjust **Conditions** and **Settings** as needed.
6. Click **OK** to save the task.

The script will now run automatically when you connect to or disconnect from a network.

## License
MIT
