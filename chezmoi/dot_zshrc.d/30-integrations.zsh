if [[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

if command -v dircolors >/dev/null 2>&1; then
  eval "$(dircolors "$HOME/.dir_colors")"
elif command -v gdircolors >/dev/null 2>&1; then
  eval "$(gdircolors "$HOME/.dir_colors")"
fi
