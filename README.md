# pop-os-battery-script
PopOS script to maintain power profile after boot
# Pop!_OS Power Profile Persistence Daemon

A lightweight Bash daemon for **Pop!_OS** that persists your chosen `system76-power` profile across reboots, switches to `performance` when plugged into AC power, and restores your saved profile when unplugged.

## Features

- **Reboot persistence:** Saves your selected profile (`battery`, `balanced`, or `performance`) to `/var/lib/power-profile/last_profile` and reapplies it on boot.
- **Automatic AC switching:** Switches to `performance` when AC power is connected and restores your saved profile when unplugged.
- **Automatic install:** Includes built-in `install` and `uninstall` subcommands and runs as a `systemd` service.

## Requirements

- Pop!_OS (tested on 24.04 only)
- root access for installing and managing the service

## Install

Download the script, make the script executable, and run the installer:

```bash
chmod +x power-profile.sh
sudo ./power-profile.sh install
```

This copies the script to `/usr/local/bin/power-profile.sh`, creates `/etc/systemd/system/power-profile.service`, and enables and starts the service immediately.

### Verify Install

Check if the service is running with:

```bash
systemctl status power-profile.service
```

## Uninstall

To stop the service and remove the installed script and unit file:

```bash
sudo ./power-profile.sh uninstall
```

This will remove all files created by the script.