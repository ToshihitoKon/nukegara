#!/usr/bin/env bash
set bell-style none

mouse_x=`xdotool getmouselocation | sed -e 's/x:\([0-9]\+\) .*/\1/g'`
window_width=200
window_x=$(($mouse_x - $window_width / 2))

contents=`cat << EOS
utils
^ca(1,~/.config/nukegara_scripts/ss.sh)[screenshot]^ca()
EOS
`
echo -e "${contents}" | dzen2 \
    -p -x $window_x -y "30" -w $window_width -l "2" \
    -sa 'c' -ta 'c' \
    -title-name "$0" \
    -e 'onstart=uncollapse;button1=exit;leaveslave=exit'
