bindkey -v

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

up_key="${key[Up]-}"
down_key="${key[Down]-}"

if [[ -n "$up_key" ]]; then
  bindkey "$up_key" up-line-or-beginning-search
else
  bindkey '^[[A' up-line-or-beginning-search
fi

if [[ -n "$down_key" ]]; then
  bindkey "$down_key" down-line-or-beginning-search
else
  bindkey '^[[B' down-line-or-beginning-search
fi
