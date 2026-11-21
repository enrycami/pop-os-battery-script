#!/usr/bin/env bash

# This script is used to set the power profile on pop_os and retain it after reboot.

if command -v system76-power >/dev/null 2>&1; then
    system76-power profile battery
fi
