#!/usr/bin/env bash

set -euo pipefail

DOTFILES_REPO_URL="${DOTFILES_REPO_URL:-git@github.com:jared-hess/dotfiles.git}"
DOTFILES_GIT_DIR="${DOTFILES_GIT_DIR:-$HOME/.dotfiles}"
DOTFILES_WORK_TREE="${DOTFILES_WORK_TREE:-$HOME}"
DOTFILES_BACKUP_ROOT="${DOTFILES_BACKUP_ROOT:-$HOME/.dotfiles-backup}"

usage() {
  cat <<'EOF'
Usage: install_dotfiles.sh [command]

Commands:
  bootstrap   Clone and check out dotfiles into $HOME (default)
  status      Show tracked dotfiles git status
  update      Pull latest dotfiles and sync submodules
  submodules  Sync and update submodules recursively
  config      Run a git command against the bare dotfiles repo
  doctor      Validate local dotfiles setup
  help        Show this message

Environment overrides:
  DOTFILES_REPO_URL     Repo URL (default: git@github.com:jared-hess/dotfiles.git)
  DOTFILES_GIT_DIR      Bare repo location (default: $HOME/.dotfiles)
  DOTFILES_WORK_TREE    Checkout target (default: $HOME)
  DOTFILES_BACKUP_ROOT  Conflict backup root (default: $HOME/.dotfiles-backup)

Examples:
  ./install_dotfiles.sh
  ./install_dotfiles.sh status
  ./install_dotfiles.sh config add .zshrc
EOF
}

log() {
  printf '[dotfiles] %s\n' "$*"
}

warn() {
  printf '[dotfiles] WARN: %s\n' "$*" >&2
}

die() {
  printf '[dotfiles] ERROR: %s\n' "$*" >&2
  exit 1
}

git_raw() {
  git --git-dir="$DOTFILES_GIT_DIR" "$@"
}

git_cfg() {
  git --git-dir="$DOTFILES_GIT_DIR" --work-tree="$DOTFILES_WORK_TREE" "$@"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

require_git() {
  command_exists git || die "git is required but was not found on PATH"
}

repo_present() {
  [[ -d "$DOTFILES_GIT_DIR" ]]
}

require_repo() {
  repo_present || die "No dotfiles repo at $DOTFILES_GIT_DIR. Run '$0 bootstrap' first."

  local is_bare
  is_bare="$(git_raw rev-parse --is-bare-repository 2>/dev/null || true)"
  [[ "$is_bare" == "true" ]] || die "$DOTFILES_GIT_DIR exists but is not a bare git repository"
}

clone_repo_if_missing() {
  if repo_present; then
    log "Using existing dotfiles repo at $DOTFILES_GIT_DIR"
    return
  fi

  log "Cloning $DOTFILES_REPO_URL -> $DOTFILES_GIT_DIR"
  git clone --bare "$DOTFILES_REPO_URL" "$DOTFILES_GIT_DIR"
}

collect_checkout_conflicts() {
  local checkout_log="$1"
  local line
  local trimmed
  local in_conflict_block=0

  while IFS= read -r line; do
    case "$line" in
      "The following untracked working tree files would be overwritten by checkout:"|"The following would be overwritten by checkout:"*)
        in_conflict_block=1
        continue
        ;;
      "Please move or remove them before you switch branches."*|"Aborting"*)
        in_conflict_block=0
        continue
        ;;
    esac

    if ((in_conflict_block)); then
      trimmed="${line#"${line%%[![:space:]]*}"}"
      if [[ -n "$trimmed" ]]; then
        printf '%s\n' "$trimmed"
      fi
    fi
  done < "$checkout_log"
}

backup_conflicts_from_log() {
  local checkout_log="$1"
  local backup_dir="$2"
  local source_path
  local target_path
  local relative_path
  local moved=0
  local -a conflicts

  mapfile -t conflicts < <(collect_checkout_conflicts "$checkout_log")
  ((${#conflicts[@]} > 0)) || return 1

  mkdir -p "$backup_dir"
  for relative_path in "${conflicts[@]}"; do
    source_path="$DOTFILES_WORK_TREE/$relative_path"
    if [[ -e "$source_path" || -L "$source_path" ]]; then
      target_path="$backup_dir/$relative_path"
      mkdir -p "$(dirname "$target_path")"
      mv "$source_path" "$target_path"
      log "Backed up $source_path -> $target_path"
      moved=1
    fi
  done

  ((moved == 1))
}

checkout_work_tree() {
  local checkout_log
  local backup_dir

  checkout_log="$(mktemp)"

  if git_cfg checkout > /dev/null 2>"$checkout_log"; then
    rm -f "$checkout_log"
    log "Checked out dotfiles into $DOTFILES_WORK_TREE"
    return
  fi

  backup_dir="$DOTFILES_BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"
  if backup_conflicts_from_log "$checkout_log" "$backup_dir"; then
    log "Moved conflicting files to $backup_dir"
    git_cfg checkout
    rm -f "$checkout_log"
    log "Checked out dotfiles after moving conflicts"
    return
  fi

  cat "$checkout_log" >&2
  rm -f "$checkout_log"
  die "Failed to check out dotfiles. Resolve conflicts and rerun '$0 bootstrap'."
}

configure_repo_defaults() {
  git_cfg config --local status.showUntrackedFiles no
}

update_submodules() {
  git_cfg submodule sync --recursive
  git_cfg submodule update --init --recursive
}

cmd_bootstrap() {
  require_git
  clone_repo_if_missing
  require_repo

  checkout_work_tree
  configure_repo_defaults
  update_submodules

  log "Bootstrap complete"
  log "Use this alias for convenience: alias config='git --git-dir=$DOTFILES_GIT_DIR --work-tree=$DOTFILES_WORK_TREE'"
}

cmd_status() {
  require_repo
  git_cfg status --short --branch
}

cmd_update() {
  require_repo
  git_cfg pull --ff-only --recurse-submodules
  update_submodules
  log "Dotfiles updated"
}

cmd_submodules() {
  require_repo
  update_submodules
  log "Submodules synced"
}

cmd_config() {
  require_repo
  (($# > 0)) || die "Usage: $0 config <git args>"
  git_cfg "$@"
}

cmd_doctor() {
  require_git

  printf 'git_binary=%s\n' "$(command -v git)"
  printf 'repo=%s\n' "$DOTFILES_GIT_DIR"
  printf 'work_tree=%s\n' "$DOTFILES_WORK_TREE"
  printf 'backup_root=%s\n' "$DOTFILES_BACKUP_ROOT"

  if repo_present; then
    if [[ "$(git_raw rev-parse --is-bare-repository 2>/dev/null || true)" == "true" ]]; then
      printf 'repo_state=ok (bare)\n'
    else
      printf 'repo_state=invalid (not bare)\n'
    fi
  else
    printf 'repo_state=missing\n'
  fi

  if [[ -d "$DOTFILES_WORK_TREE" ]]; then
    printf 'work_tree_state=ok\n'
  else
    printf 'work_tree_state=missing\n'
  fi
}

main() {
  local command="${1:-bootstrap}"
  case "$command" in
    bootstrap|install)
      shift
      cmd_bootstrap "$@"
      ;;
    status)
      shift
      cmd_status "$@"
      ;;
    update)
      shift
      cmd_update "$@"
      ;;
    submodules)
      shift
      cmd_submodules "$@"
      ;;
    config)
      shift
      cmd_config "$@"
      ;;
    doctor)
      shift
      cmd_doctor "$@"
      ;;
    help|-h|--help)
      usage
      ;;
    *)
      die "Unknown command '$command'. Run '$0 help' for usage."
      ;;
  esac
}

main "$@"
