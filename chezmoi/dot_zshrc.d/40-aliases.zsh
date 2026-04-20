alias ls='ls --color=auto'
alias pacman='sudo pacman'
alias update='pacaur -Syu --noedit'
alias detach='tmux detach-client'

if command -v chezmoi >/dev/null 2>&1; then
  alias dot='chezmoi'
fi

if [[ -d "$HOME/.dotfiles" ]]; then
  alias config='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
fi
