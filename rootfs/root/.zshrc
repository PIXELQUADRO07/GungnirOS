# GungnirOS Oh-My-Zsh Configuration
export ZSH="$HOME/.oh-my-zsh"
export ZSH_THEME="robbyrussell"

# Plugins (stub)
plugins=(git debian systemd)

# Minimal source
[ -f "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"

# Aliases
alias ys='pacman -Ss'
alias yi='pacman -S'
alias yq='pacman -Q'
alias yii='pacman -Qi'
