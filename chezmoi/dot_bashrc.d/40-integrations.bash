if [[ -f /usr/share/doc/pkgfile/command-not-found.bash ]]; then
  source /usr/share/doc/pkgfile/command-not-found.bash
fi

if [[ -f "$HOME/.autojump/etc/profile.d/autojump.sh" ]]; then
  source "$HOME/.autojump/etc/profile.d/autojump.sh"
fi

v_less_loc=""
for candidate in /usr/share/vim/vim*/macros/less.sh /usr/share/vim/*/macros/less.sh /usr/share/vim/*/less.sh; do
  if [[ -f "$candidate" ]]; then
    v_less_loc="$candidate"
  fi
done
if [[ -n "$v_less_loc" ]]; then
  alias less="$v_less_loc"
fi

if command -v thefuck >/dev/null 2>&1; then
  eval "$(thefuck --alias)"
fi
