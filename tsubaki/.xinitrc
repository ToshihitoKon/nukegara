#!/bin/sh
if [ -d /etc/X11/xinit/xinitrc.d ] ; then
    for f in /etc/X11/xinit/xinitrc.d/?* ; do
        [ -x "$f" ] && . "$f"
    done
    unset f
fi


[[ -f ~/.Xresources ]] && xrdb -merge -I$HOME ~/.Xresources
[[ -z "$(ps aux | grep mpd | grep -v grep)" ]] && mpd

# input daemon
fcitx-autostart &
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx

# desktop alpharing daemon
picom -b --config ~/.config/picom/picom.conf

# desktop notification daemon
# twmnd &

sh ~/.fehbg &
xinput disable "SynPS/2 Synaptics TouchPad"
xinput set-prop 'pointer:ELECOM ELECOM TrackBall Mouse' 'Coordinate Transformation Matrix' 1 0 0  0 1 0  0 0 1.8
#xinput set-prop "TPPS/2 IBM TrackPoint" "Coordinate Transformation Matrix" 2 0 0 0 2 0 0 0 1

# ???
unclutter &

exec xmonad
# exec startxfce4
