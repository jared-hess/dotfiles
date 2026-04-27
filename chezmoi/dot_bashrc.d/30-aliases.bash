shared_shell_aliases="$HOME/.config/shell/aliases.sh"
if [[ -f "$shared_shell_aliases" ]]; then
  source "$shared_shell_aliases"
fi

if [[ -d "$HOME/.dotfiles" ]]; then
  if declare -F __git_wrap__git_main >/dev/null 2>&1; then
    complete -o bashdefault -o default -o nospace -F __git_wrap__git_main config
  fi
fi
