export LANG=en_US.UTF-8
export PATH="/Users/toshihitokon/.bin/:$PATH"
export PATH="/opt/homebrew/opt/openssl@1.1/bin:$PATH"
export EDITOR=nvim
export LESS='-RSX +G'
export FZF_DEFAULT_OPTS='--reverse --highlight-line'

autoload -Uz compinit promptinit vcs_info colors add-zsh-hook
compinit
promptinit
colors

source ~/.zplug/init.zsh
zplug 'zplug/zplug', hook-build:'zplug --self-manage'
zplug "zsh-users/zsh-syntax-highlighting"
zplug "zsh-users/zsh-autosuggestions"
zplug "zsh-users/zsh-completions"
zplug "chrissicool/zsh-256color"
zplug "Aloxaf/fzf-tab"
if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi
zplug load


# 補完関連
# zstyle ':completion:*' menu true select interactive
zstyle ":completion:*:commands" rehash 1
# zstyle ':completion:*' completer _complete _all_matches
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
# zstyle ':completion:*:messages' format '%F{YELLOW}%d'$DEFAULT
# zstyle ':completion:*:warnings' format '%F{RED}No matches for:''%F{YELLOW} %d'$DEFAULT
# zstyle ':completion:*:descriptions' format '%F{YELLOW}completing %B%d%b'$DEFAULT
# zstyle ':completion:*:options' description 'yes'
# zstyle ':completion:*:descriptions' format '%F{yellow}Completing %B%d%b%f'$DEFAULT
# zstyle ':completion:*' group-name '' # マッチ種別を別々に表示
# zstyle ':completion:*:manuals' separate-sections true
setopt magic_equal_subst     # コマンドラインの引数で --prefix=/usr などの = 以降でも補完できる
setopt ALWAYS_TO_END
setopt auto_param_slash
setopt list_types
setopt complete_in_word
unsetopt AUTO_LIST

# LS_COLORSを設定しておく
export LS_COLORS='\
di=33:\
ln=35:\
so=32:\
pi=33:\
ex=31:\
bd=46;34:\
cd=43;34:\
su=41;30:\
sg=46;30:\
tw=42;30:\
ow=43;30'

### fzf-tab settings https://github.com/Aloxaf/fzf-tab
zstyle ':completion:*:git-checkout:*' sort false # disable sort when completing `git checkout`
# set descriptions format to enable group support
# NOTE: don't use escape sequences (like '%F{red}%d%f') here, fzf-tab will ignore them
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no
# preview directory's content with eza when completing cd
# zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:cd:*' continuous-trigger 'tab'
# custom fzf flags
# NOTE: fzf-tab does not follow FZF_DEFAULT_OPTS by default
zstyle ':fzf-tab:*' fzf-flags --color=fg:2,fg+:3 --bind=tab:accept
# To make fzf-tab follow FZF_DEFAULT_OPTS.
# NOTE: This may lead to unexpected behavior since some flags break this plugin. See Aloxaf/fzf-tab#455.
zstyle ':fzf-tab:*' use-fzf-default-opts yes
# switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup

# manual load completion files
# complete -C '/opt/homebrew/bin/aws_completer' aws

# zmodload zsh/complist
# ^IはTABキーと同一の挙動をする
# bindkey -v '^I' expand-or-complete 
# bindkey -M menuselect '^I' vi-forward-char
# bindkey -M menuselect '^L' vi-forward-char
# bindkey -M menuselect '^H' vi-backward-char

bindkey '^H' backward-delete-char
# bindkey '^?' backward-delete-char

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

add_newline() {
  if [[ -z $PS1_NEWLINE_LOGIN ]]; then
    PS1_NEWLINE_LOGIN=true
  else
    local current_time=$(date "+%H:%M:%S")
    local remaining_width=$(($(tput cols) - ${#current_time} - 6))  # 6文字分（左右の空白＋ハイフン）
    local left_hyphens=2
    local right_hyphens=$((remaining_width - left_hyphens))
    
    printf "  \033[90m"  # 左の2文字空白
    printf "%s" "$(printf '%.0s─' $(seq 1 $left_hyphens))"  # 左の2文字ハイフン
    printf " %s " "$current_time"  # 時刻表示（前後に空白）
    printf "%s" "$(printf '%.0s─' $(seq 1 $right_hyphens))"  # 残りのハイフン
    printf "\033[0m  \n"  # 右の2文字空白
  fi
}
add-zsh-hook precmd add_newline

aws_vault_info() {
    if [ ! -z "${AWS_VAULT}" ]; then
        echo " [ aws: %F{green}${AWS_VAULT}%f ]"
    fi
}

envchain_info() {
    if [ ! -z "${ENVCHAIN_ENV}" ]; then
        echo " [ env: %F{green}${ENVCHAIN_ENV}%f ]"
    fi
}

# shorten path: /Users/toshihitokon/ -> /Use/toshihitokon/
shorten_path() {
  local path=${PWD/#$HOME/\~}
  local shortened_path=""
  local dir
  local dirs=("${(s:/:)path}")

  for dir in "${dirs[@]}"; do
    if [[ $dir == "${dirs[-1]}" ]]; then
      shortened_path+="$dir"
    else
      shortened_path+="${dir:0:3}/"
    fi
  done

  echo "${shortened_path}/"
}

PROMPT='%B%U%F{224} [ %D{%Y/%m/%d %H:%M:%S} ] [ %F{green}$(shorten_path)%F{224} ]${vcs_info_msg_0_}$(aws_vault_info)$(envchain_info)%u%b
%(?.%F{green}.%F{red})%?%f %F{yellow}(*>△<)%(?..<ﾅｰﾝｯ)%f %# '
PROMPT2="%F{yellow}(*>△<)..%f > "

# history search
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^p" history-beginning-search-backward-end
bindkey "^o" history-beginning-search-forward-end

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

# mecha mecha benri na command
alias hibernate="systemctl hibernate"
alias ss='~/.config/nukegara_scripts/ss.sh'
alias localhosting="python -m http.server"
alias temamount="sudo mount -o 'uid=1000,gid=1000'"
alias tma="tmux a -t \$(tmux ls | grep -v attached | fzf --tmux | sed -e 's/^\\(.*\\)[?:] .*$/\\1/g')"

alias rm="rm -i"
alias less="less -MR"
alias ls="ls --color=always -1"
alias gcc="gcc -Wall"

alias echo-yayoi='echo -n "ζ*'"'"'ヮ'"'"')ζ< ";echo'

export PATH="/Users/toshihitokon/.asdf/shims:$PATH"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/toshihitokon/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/toshihitokon/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/toshihitokon/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/toshihitokon/google-cloud-sdk/completion.zsh.inc'; fi
export PATH="/opt/homebrew/opt/unzip/bin:$PATH"

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/toshihitokon/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)
