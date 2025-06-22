#!/usr/bin/env bash
set -xe

pactlres=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -i 'volume')
volume=$(echo $pactlres | sed -e 's/^Volume.*\/\W\+\([0-9]\+\)%.*$/\1/g')
muted=$(pactl get-sink-mute @DEFAULT_SINK@ | grep yes ||:)

if [ "$muted" ]; then
    volnoti-show --mute
else
    volnoti-show ${volume}
fi
