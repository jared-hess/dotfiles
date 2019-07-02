#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

complete -C /usr/local/bin/mc mc
