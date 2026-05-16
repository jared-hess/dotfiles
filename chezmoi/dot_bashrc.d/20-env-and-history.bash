shared_shell_env="$HOME/.config/shell/env.sh"
if [[ -f "$shared_shell_env" ]]; then
  source "$shared_shell_env"
fi

export HISTCONTROL="ignoredups:erasedups"
shopt -s histappend
