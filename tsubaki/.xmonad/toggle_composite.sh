#!/bin/bash

if pgrep picom &> /dev/null; then
    pkill picom &
else
    picom -b
fi
