#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return
# Path
export PATH="$PATH:$HOME/.local/bin"
#Command Not Found
[[ -s /usr/share/doc/pkgfile/command-not-found.bash ]] && source /usr/share/doc/pkgfile/command-not-found.bash

# Autojump
[[ -s /home/jared/.autojump/etc/profile.d/autojump.sh ]] && source /home/jared/.autojump/etc/profile.d/autojump.sh

# Vim
vLessLoc="$(find /usr/share/vim/ -name less.sh | sort -r | head -1)"
if [ $vLessLoc ]; then
    alias less="$vLessLoc"
fi

# ENV
export PATH=$PATH:~/bin
export EDITOR="vim"
export VISUAL="vim"

alias pacman='sudo pacman'
alias ls='ls --color=auto'
alias update='pacaur -Syu --noedit'
alias detach='tmux detach-client'
eval $(thefuck --alias)

#Dotfile stuff
alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
complete -o bashdefault -o default -o nospace -F __git_wrap__git_main config
# Default PS1
# PS1='[\u@\h \W]\$ '

# Custom PS1
PS1='\[\e]0;\w\a\]\n\[\e[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]\n\$'

# Powerline
export POWERLINE_DIR="$(readlink -f "$((find . -path './.local/lib/python*/site-packages/powerline' | sort -r ; find /usr/lib/ -path '/usr/lib/python*/site-packages/powerline' | sort -r) | head -1)")"
if [ -f "$POWERLINE_DIR"/bindings/bash/powerline.sh ]; then
	source "$POWERLINE_DIR"/bindings/bash/powerline.sh
fi

# History
# Avoid duplicates
export HISTCONTROL=ignoredups:erasedups  
# When the shell exits, append to the history file instead of overwriting it
shopt -s histappend
