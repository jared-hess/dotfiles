if [[ -f "$HOME/.iterm2_shell_integration.bash" ]]; then
  source "$HOME/.iterm2_shell_integration.bash"
fi

if command -v mc >/dev/null 2>&1; then
  complete -C "$(command -v mc)" mc 2>/dev/null || true
fi
