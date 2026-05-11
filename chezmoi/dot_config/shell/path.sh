path_prepend() {
  [ -n "$1" ] || return 0
  [ -d "$1" ] || return 0
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1${PATH:+:$PATH}" ;;
  esac
}

path_append() {
  [ -n "$1" ] || return 0
  [ -d "$1" ] || return 0
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="${PATH:+$PATH:}$1" ;;
  esac
}

path_prepend "$HOME/bin"
path_prepend "$HOME/.opencode/bin"
path_append "$HOME/.local/bin"
path_append "/usr/local/bin"
export PATH
