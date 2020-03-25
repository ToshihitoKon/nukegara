PATH="${PATH}:/home/temama/.gem/ruby/2.4.0/bin"

#alias ls="ls --color=always"
alias ls="tree -L 1 -h -C"
alias rm="rm -i"
alias tree="tree -L 2 -C"
alias less="less -MR"
alias wifi-menu="sudo ip link set wlp4s0 down; sudo wifi-menu"
alias gcc="gcc -Wall"

alias pbcopy='xsel --clipboard --input'
alias pbpaste='xsel --clipboard --output'
alias ss='import /home/temama/tmp.png'

alias al_output="xrandr --output HDMI2 --auto --right-of eDP1; ~/.fehbg"
alias urxvt_pt10="urxvt --font 'xft:Ricty Diminished:size=10:Regular'"
alias urxvt_alpha="urxvt --background '[0]black'"
alias pulse_output_daifuku="export PULSE_SERVER=192.168.150.170"

#alias google-chrome="google-chrome-stable --force-device-scale-factor=1.15"
alias ffplay="ffplay -nodisp -autoexit"

alias ✓="echo checked!"
alias echo-yayoi='echo -n "ζ*'"'"'ヮ'"'"')ζ< ";echo'

alias git='expr $(cat ~/.expgit/exp) + 10 > ~/.expgit/exp; echo current gitexp is $(cat ~/.expgit/exp).; git'
export LANG=ja_JP.UTF-8

alias kinpatsu="export PROMPT=\"${PROMPT}%F{yellow}\""

# notifys
alias ncftp="echo 'ncftp is not secure! you should use sftp (sftp can recursicve get and put.)'"

#screenfetch

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/home/temama/.sdkman"
[[ -s "/home/temama/.sdkman/bin/sdkman-init.sh" ]] && source "/home/temama/.sdkman/bin/sdkman-init.sh"
