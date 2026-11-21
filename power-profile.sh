#!/usr/bin/env bash

# This script is used to set the power profile on pop_os and retain it after reboot.

# state file used to store user chosen power profile
STATE_FILE="/var/lib/power-profile/last_profile"

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