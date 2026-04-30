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

vless_cat_fallback() {
  if [ "$#" -eq 0 ]; then
    if [ -t 0 ]; then
      printf 'Missing filename\n' >&2
      return 1
    fi
    cat
  else
    cat "$@"
  fi
}

find_vim_less_script() {
  local candidate
  for candidate in \
    /usr/share/vim/vim*/macros/less.sh \
    /usr/share/vim/*/macros/less.sh \
    /usr/share/vim/*/less.sh
  do
    if [ -f "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

vless() {
  if have_cmd nvim; then
    if [ -t 1 ]; then
      if [ "$#" -eq 0 ]; then
        if [ -t 0 ]; then
          printf 'Missing filename\n' >&2
          return 1
        fi
        command nvim --cmd 'let no_plugin_maps = 1' -c 'runtime! scripts/less.vim' -
      else
        command nvim --cmd 'let no_plugin_maps = 1' -c 'runtime! scripts/less.vim' "$@"
      fi
    else
      vless_cat_fallback "$@"
    fi
    return
  fi

  if have_cmd vim; then
    if [ -t 1 ]; then
      local vim_less_script
      if vim_less_script="$(find_vim_less_script)"; then
        command "$vim_less_script" "$@"
      elif [ "$#" -eq 0 ]; then
        if [ -t 0 ]; then
          printf 'Missing filename\n' >&2
          return 1
        fi
        command vim --cmd 'let no_plugin_maps = 1' -c 'runtime! macros/less.vim' -
      else
        command vim --cmd 'let no_plugin_maps = 1' -c 'runtime! macros/less.vim' "$@"
      fi
    else
      vless_cat_fallback "$@"
    fi
    return
  fi

  vless_cat_fallback "$@"
}
