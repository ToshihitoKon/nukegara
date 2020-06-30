autoload -Uz compinit promptinit predict-on
compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
promptinit
setopt correct
#predict-on

#source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

PROMPT="%F{white}%K{red}█▓▒░%F{white}%K{red}%B%n@%m%b%k%F{red}█▓▒░%f %F{green}%~%f%}
%(?.%F{green}.%F{red})%?%f %F{yellow}(*>△ <)%(?..<ﾅｰﾝｯ)%f %# "

export LANG=en_US.UTF-8

# anyenv
export PATH="$HOME/.anyenv/bin:$PATH"
eval "$(anyenv init -)"

#mecha mecha benri na setting
bindkey -v # set vimmode
# ヒストリに追加されるコマンド行が古いものと同じなら古いものを削除
setopt hist_ignore_all_dups

# スペースで始まるコマンド行はヒストリリストから削除
setopt hist_ignore_space

# ヒストリを呼び出してから実行する間に一旦編集可能
setopt hist_verify

# 余分な空白は詰めて記録
setopt hist_reduce_blanks  

# 古いコマンドと同じものは無視 
setopt hist_save_no_dups

# historyコマンドは履歴に登録しない
setopt hist_no_store

# 補完時にヒストリを自動的に展開         
setopt hist_expand

# 履歴をインクリメンタルに追加
setopt inc_append_history

# インクリメンタルからの検索
bindkey "^R" history-incremental-search-backward
bindkey "^S" history-incremental-search-forward

# mecha mecha benri na command
alias hibernate="systemctl hibernate"
alias ss='import /home/temama/tmp.png'
alias pbcopy='xsel --clipboard --input'
alias pbpaste='xsel --clipboard --output'
alias localhosting="python -m http.server"
alias temamount="sudo mount -o 'uid=1000,gid=1000'"
alias rm="rm -i"


alias ls="ls --color=always"
#alias ls="tree -L 1 -h -C"
alias tree="tree -L 2 -C"
alias less="less -MR"
alias gcc="gcc -Wall"

alias tweet-pipe="xargs -IXX tweet XX"
alias al_output="xrandr --output HDMI2 --auto --above eDP1; ~/.fehbg"
alias urxvt_pt10="urxvt --font 'xft:Ricty Diminished:size=10:Regular'"
alias urxvt_alpha="urxvt --background '[0]black'"
alias pulse_output_daifuku="export PULSE_SERVER=192.168.150.170"
alias ncmpc="ncmpc --config ~/.config/ncmpc/ncmpc.config"

alias echo-yayoi='echo -n "ζ*'"'"'ヮ'"'"')ζ< ";echo'

# notifies
alias ncftp="echo 'ncftp is not secure! you should use sftp (sftp can recursicve get and put.)'"

#screenfetch

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/temama/google-cloud-sdk/path.zsh.inc' ]; then . '/home/temama/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/temama/google-cloud-sdk/completion.zsh.inc' ]; then . '/home/temama/google-cloud-sdk/completion.zsh.inc'; fi
