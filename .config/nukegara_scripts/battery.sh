#!/usr/bin/env bash
cd `dirname $0`
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus"

battery_level=battery_level
level_threshold=20
level_before=`cat $battery_level`
level_current=`cat /sys/class/power_supply/BAT0/capacity`
echo $level_current > $battery_level

if [ $level_current -lt $level_threshold ]; then
    if [ ! $level_before -lt $level_threshold ]; then
        notify-send "Battery warning" "残り$level_current%"
    fi
fi

battery_status=battery_status
status_threshold=20
status_before=`cat $battery_status`
status_current=`cat /sys/class/power_supply/BAT0/status`
echo $status_current > $battery_status

if [ "$status_before" != "$status_current" ]; then
    notify-send "Battery status change" "$status_current"
fi
