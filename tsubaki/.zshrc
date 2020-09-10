export LANG=en_US.UTF-8
source ~/.zplug/init.zsh

bindkey -v # set vimmode

autoload -Uz compinit promptinit vcs_info colors add-zsh-hook
compinit
promptinit
colors

# 補完関連
zstyle ':completion:*' menu true select interactive
setopt ALWAYS_TO_END
unsetopt AUTO_LIST
zstyle ':completion:*' completer _complete _all_matches
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' verbose yes
zstyle ':completion:*:messages' format '%F{YELLOW}%d'$DEFAULT
zstyle ':completion:*:warnings' format '%F{RED}No matches for:''%F{YELLOW} %d'$DEFAULT
zstyle ':completion:*:descriptions' format '%F{YELLOW}completing %B%d%b'$DEFAULT
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:descriptions' format '%F{yellow}Completing %B%d%b%f'$DEFAULT
# マッチ種別を別々に表示
zstyle ':completion:*' group-name ''
# LS_COLORSを設定しておく
export LS_COLORS='di=33:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
# ファイル補完候補に色を付ける
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# manの補完をセクション番号別に表示させる
zstyle ':completion:*:manuals' separate-sections true
setopt magic_equal_subst     # コマンドラインの引数で --prefix=/usr などの = 以降でも補完できる

zmodload zsh/complist
# ^IはTABキーと同一の挙動をする
bindkey -v '^I' expand-or-complete 
bindkey -M menuselect '^I' vi-forward-char
bindkey -M menuselect '^L' vi-forward-char
bindkey -M menuselect '^H' vi-backward-char


# vcs
setopt prompt_subst
zstyle ':vcs_info:*' max-exports 3
zstyle ':vcs_info:git:*' stagedstr "%F{yellow}!"
zstyle ':vcs_info:git:*' unstagedstr "%F{red}+"
zstyle ':vcs_info:*' formats " [%F{green}%s:%c%u%b%F{224}]"
zstyle ':vcs_info:*' actionformats '[%b|%a]'
zstyle ':vcs_info:*' check-for-changes true
precmd_vcs_info() {
    vcs_info
}
add-zsh-hook precmd precmd_vcs_info

TMOUT=1
TRAPALRM() {
    if [ "$WIDGET" != "expand-or-complete" ]; then
        zle reset-prompt
    fi
}


PROMPT='%B%U%F{224} [ %D{%Y.%m.%d %H:%M:%S} ] [ %F{green}%~%F{224} ]${vcs_info_msg_0_}%u%b
%(?.%F{green}.%F{red})%?%f %F{yellow}(*>△ <)%(?..<ﾅｰﾝｯ)%f %# '
PROMPT2="%F{yellow}(*>△ <)..%f > "

export PATH="$HOME/.anyenv/bin:$PATH"
eval "$(anyenv init -)"


# history search
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^p" history-beginning-search-backward-end
bindkey "^O" history-beginning-search-forward-end

setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_verify
setopt hist_reduce_blanks
setopt hist_save_no_dups
setopt hist_no_store
setopt hist_expand
setopt inc_append_history

HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000

# anyenv
export PATH="$HOME/.anyenv/bin:$PATH"
eval "$(anyenv init -)"


# mecha mecha benri na command
alias hibernate="systemctl hibernate"
alias ss='import /home/temama/tmp.png'
alias pbcopy='xsel --clipboard --input'
alias pbpaste='xsel --clipboard --output'
alias localhosting="python -m http.server"
alias temamount="sudo mount -o 'uid=1000,gid=1000'"

alias rm="rm -i"
alias less="less -MR"
alias ls="ls --color=always"
alias gcc="gcc -Wall"

alias echo-yayoi='echo -n "ζ*'"'"'ヮ'"'"')ζ< ";echo'

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/temama/google-cloud-sdk/path.zsh.inc' ]; then . '/home/temama/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/temama/google-cloud-sdk/completion.zsh.inc' ]; then . '/home/temama/google-cloud-sdk/completion.zsh.inc'; fi
