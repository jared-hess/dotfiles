have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

if have_cmd nvim; then
  export EDITOR='nvim'
  export VISUAL='nvim'
else
  export EDITOR='vim'
  export VISUAL='vim'
fi

export DEFAULT_USER='jared.hess'
