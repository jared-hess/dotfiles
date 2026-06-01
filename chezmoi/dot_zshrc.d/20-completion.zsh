if command -v brew >/dev/null 2>&1; then
  FPATH="$(brew --prefix)/share/zsh-completions:$FPATH"
  autoload -Uz compinit
  compinit
fi

autoload -U +X bashcompinit && bashcompinit

if command -v mc >/dev/null 2>&1; then
  complete -o nospace -C "$(command -v mc)" mc
fi

if command -v aws_completer >/dev/null 2>&1; then
  complete -C "$(command -v aws_completer)" aws
  complete -C "$(command -v aws_completer)" awslocal
fi

openclaw_zsh_completion="$HOME/.openclaw/completions/openclaw.zsh"
if [[ -r "$openclaw_zsh_completion" ]]; then
  # shellcheck source=/dev/null
  source "$openclaw_zsh_completion"
fi
