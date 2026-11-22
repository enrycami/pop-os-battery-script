#!/usr/bin/env bash

# This script is used to set the power profile on pop_os and retain it after reboot.

# state file to store user chosen power profile, AC_FLAG to keep track of plugged state
STATE_FILE="/var/lib/power-profile/last_profile"
AC_FLAG="/run/power-profile-ac.flag"

# install and uninstall block
INSTALL_PATH="/usr/local/bin/power-profile.sh"
SERVICE_PATH="/etc/systemd/system/power-profile.service"

if [ "${1:-}" = "install" ]; then
    cp "$0" "$INSTALL_PATH"
    chmod +x "$INSTALL_PATH"

    cat <<'EOF' > "$SERVICE_PATH"

[Unit]
Description=Persist System76 Power Profile
After=system76-power.service dbus.service
Requires=system76-power.service

[Service]
Type=simple
ExecStart=/usr/local/bin/power-profile.sh
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now power-profile.service
    exit 0

elif [ "${1:-}" = "uninstall" ]; then
    systemctl disable --now power-profile.service 2>/dev/null || true
    rm -f "$SERVICE_PATH"
    systemctl daemon-reload
    # remove all files created by script
    rm -f "$INSTALL_PATH"
    rm -f "$AC_FLAG"
    rm -rf "$(dirname "$STATE_FILE")"
    exit 0
fi

# create last_profile if missing, giving it initial value of balanced
if [ ! -f "$STATE_FILE" ]; then
    mkdir -p "$(dirname "$STATE_FILE")"
    printf '%s\n' "balanced" > "$STATE_FILE"
fi

# read and validate state file before applying change
read -r saved_profile < "$STATE_FILE"
case "$saved_profile" in
    battery|balanced|performance)
        system76-power profile "$saved_profile"
        ;;
    *)
        system76-power profile balanced
        ;;
esac

# switch to performance when AC is plugged in, then switch back to previous state when unplugged
stdbuf -oL upower --monitor | while IFS= read -r line; do
    case "$line" in
        *line_power_AC*)
            ac_online=$(upower -i /org/freedesktop/UPower/devices/line_power_AC | awk '/online:/ {print $2}')
            if [ "$ac_online" = "yes" ] && [ ! -e "$AC_FLAG" ]; then
                # create flag to skip saving automatic performance switch
                : > "$AC_FLAG"
                system76-power profile performance
            elif [ "$ac_online" = "no" ]; then
                rm -f "$AC_FLAG"
                read -r saved_profile < "$STATE_FILE"
                case "$saved_profile" in
                    battery|balanced|performance)
                        system76-power profile "$saved_profile"
                        ;;
                    *)
                        system76-power profile balanced
                        ;;
                esac
            fi
            ;;
    esac
done &

# monitor com.system76.PowerDaemon for changes to power profile
stdbuf -oL gdbus monitor --system --dest com.system76.PowerDaemon --object-path /com/system76/PowerDaemon | while IFS= read -r line; do
    case "$line" in
        *PowerProfileSwitch*)
        [ -e "$AC_FLAG" ] && continue
        # extract and sanitize profile, then write it to STATE_FILE
        power_profile=$(awk -F"'" '{print $2}' <<<"$line")
        power_profile="${power_profile,,}"
        case "$power_profile" in
            battery|balanced|performance)
            printf '%s\n' "$power_profile" > "$STATE_FILE"
            ;;
        esac
        ;;
    esac
done