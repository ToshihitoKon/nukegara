#!/usr/bin/env bash

import ~/tmp.png
cat ~/tmp.png | xclip -selection clipboard -t image/png
notify-send -a utils "screenshot copied"
