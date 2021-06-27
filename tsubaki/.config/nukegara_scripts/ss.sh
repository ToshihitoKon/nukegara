#!/usr/bin/env bash
set -e

# X window system
import -silent ~/tmp.png

# wayland
#geo=$(slurp)
#grim -g "$geo" ~/tmp.png

cat ~/tmp.png | xclip -selection clipboard -t image/png
notify-send -a utils "screenshot copied"
