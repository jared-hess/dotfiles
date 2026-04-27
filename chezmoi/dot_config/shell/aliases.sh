have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

if have_cmd gls; then
  alias ls='gls --color=auto'
elif command ls --color=auto -d . >/dev/null 2>&1; then
  alias ls='ls --color=auto'
fi

if have_cmd pacman; then
  alias pacman='sudo pacman'
fi

if have_cmd pacaur; then
  alias update='pacaur -Syu --noedit'
elif have_cmd yay; then
  alias update='yay -Syu'
elif have_cmd paru; then
  alias update='paru -Syu'
fi

if have_cmd tmux; then
  alias detach='tmux detach-client'
fi

if have_cmd chezmoi; then
  alias dot='chezmoi'
fi

if [ -d "$HOME/.dotfiles" ] && have_cmd git; then
  alias config='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
fi

if have_cmd nvim; then
  vim() { command nvim "$@"; }
  vi() { command nvim "$@"; }
fi
