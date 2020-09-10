#!/bin/bash

if pgrep compton &> /dev/null; then
    pkill compton &
else
    compton -b
fi
