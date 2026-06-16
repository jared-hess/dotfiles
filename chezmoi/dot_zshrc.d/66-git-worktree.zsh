# Git worktree shell helpers.
#
# Public entrypoints:
# - `gwtw <branch> [base]`: create or attach a managed worktree for a branch.
# - `gwtcd <query>`: change shell into an existing managed worktree.
# - `gwtl`: list managed worktrees.
# - `gwtrm <branch-or-path>`: remove a managed worktree.
#
# Private helpers:
# - `_gwt_err`: prints a prefixed error and returns non-zero.
# - `_gwt_have_git`: checks whether `git` exists on PATH.
# - `_gwt_repo_root`: returns current git repository root.
# - `_gwt_repo_slug`: resolves the repo slug (`GWT_REPO_SLUG` override or root basename).
# - `_gwt_branch_slug`: builds a safe branch-based directory slug.
# - `_gwt_root`: resolves worktree root (`GWT_ROOT` override or `~/worktrees`).
# - `_gwt_target_path`: resolves final worktree path for a branch.
# - `_gwt_*_completion_candidates`: build tab-completion candidate lists.
#

_gwt_err() {
  local message="$*"

  print -r -- "git-worktree: ${message}" >&2
  return 1
}

_gwt_have_git() {
  command -v git >/dev/null 2>&1
}

_gwt_repo_root() {
  local root=""

  if ! _gwt_have_git; then
    _gwt_err "git is not available on PATH"
    return 1
  fi

  if ! root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    _gwt_err "not inside a git repository"
    return 1
  fi

  print -r -- "$root"
}

_gwt_repo_slug() {
  local repo_slug=""
  local repo_root=""
  local repo_common_dir=""
  local repo_common_abs=""

  if [[ -n "${GWT_REPO_SLUG-}" ]]; then
    repo_slug="${GWT_REPO_SLUG}"
  else
    if ! repo_root="$(_gwt_repo_root)"; then
      return 1
    fi
    if ! repo_common_dir="$(git -C "$repo_root" rev-parse --git-common-dir 2>/dev/null)"; then
      repo_slug="${repo_root:t}"
    else
      if [[ "$repo_common_dir" = /* ]]; then
        repo_common_abs="$repo_common_dir"
      else
        repo_common_abs="$repo_root/$repo_common_dir"
      fi

      if [[ "$repo_common_abs" == */.git/worktrees/* ]]; then
        repo_common_abs="${repo_common_abs%/.git/worktrees/*}"
      fi

      repo_common_abs="${repo_common_abs%/.git}"
      repo_slug="${repo_common_abs:t}"
    fi
  fi

  if [[ -z "$repo_slug" ]]; then
    _gwt_err "could not determine repo slug"
    return 1
  fi

  repo_slug="${repo_slug//[^A-Za-z0-9._-]/-}"
  while [[ "$repo_slug" == *--* ]]; do
    repo_slug="${repo_slug//--/-}"
  done
  repo_slug="${repo_slug##-}"
  repo_slug="${repo_slug%%-}"

  if [[ -z "$repo_slug" ]]; then
    repo_slug="repo"
  fi

  print -r -- "$repo_slug"
}

_gwt_branch_slug() {
  local branch="${1-}"
  local branch_slug=""
  local branch_hash=""

  if [[ -z "$branch" ]]; then
    _gwt_err "branch is required"
    return 1
  fi

  branch_slug="${branch//[^A-Za-z0-9._-]/-}"
  while [[ "$branch_slug" == *--* ]]; do
    branch_slug="${branch_slug//--/-}"
  done
  branch_slug="${branch_slug##-}"
  branch_slug="${branch_slug%%-}"
  if [[ -z "$branch_slug" ]]; then
    branch_slug="branch"
  fi

  if ! branch_hash="$(printf '%s' "$branch" | git hash-object --stdin 2>/dev/null)"; then
    _gwt_err "failed to compute branch slug hash"
    return 1
  fi

  branch_hash="${branch_hash:0:8}"
  print -r -- "${branch_slug}-${branch_hash}"
}

_gwt_root() {
  local root="${GWT_ROOT-}"

  case "$root" in
    "")
      print -r -- "$HOME/worktrees"
      return
      ;;
    "~")
      print -r -- "$HOME"
      return
      ;;
    "~/"*)
      print -r -- "$HOME/${root#\~/}"
      return
      ;;
    *)
      print -r -- "$root"
      ;;
  esac
}

_gwt_target_path() {
  local branch_slug=""
  local repo_slug=""

  if ! repo_slug="$(_gwt_repo_slug)"; then
    return 1
  fi
  if ! branch_slug="$(_gwt_branch_slug "$1")"; then
    return 1
  fi

  print -r -- "$(_gwt_root)/$repo_slug/$branch_slug"
}

_gwt_managed_root() {
  local repo_slug=""

  if ! repo_slug="$(_gwt_repo_slug)"; then
    return 1
  fi

  print -r -- "$(_gwt_root)/$repo_slug"
}

_gwt_managed_worktree_rows() {
  local repo_root=""
  local managed_root=""
  local worktree_list=""
  local line=""
  local current_path=""
  local current_branch=""

  if ! repo_root="$(_gwt_repo_root)"; then
    return 1
  fi

  if ! managed_root="$(_gwt_managed_root)"; then
    return 1
  fi

  if ! worktree_list="$(git -C "$repo_root" worktree list --porcelain 2>/dev/null)"; then
    _gwt_err "failed to inspect git worktrees"
    return 1
  fi

  while IFS= read -r line; do
    case "$line" in
      worktree\ *)
        current_path="${line#worktree }"
        current_branch=""
        ;;
      branch\ refs/heads/*)
        current_branch="${line#branch refs/heads/}"
        if [[ -n "$current_branch" && "$current_path" == "$managed_root"/* ]]; then
          printf '%s\t%s\n' "$current_branch" "$current_path"
        fi
        ;;
      branch\ \(detached\))
        # Skip detached worktrees so `gwtl` only lists branch-attached worktrees.
        current_branch=""
        ;;
    esac
  done <<< "$worktree_list"
}

_gwt_resolve_managed_worktree() {
  local query="${1-}"
  local managed_count=0
  local exact_branch_count=0
  local exact_path_count=0
  local substring_count=0
  local exact_branch_path=""
  local exact_path_path=""
  local substring_path=""
  local line=""
  local branch=""
  local worktree_path=""
  local rows=""
  local managed_path=""

  if ! rows="$(_gwt_managed_worktree_rows)"; then
    return 1
  fi

  while IFS=$'\t' read -r branch worktree_path; do
    if [[ -z "$branch" || -z "$worktree_path" ]]; then
      continue
    fi

    managed_count=$((managed_count + 1))
    managed_path="$worktree_path"

    if [[ -n "$query" && "$branch" == "$query" ]]; then
      exact_branch_count=$((exact_branch_count + 1))
      exact_branch_path="$worktree_path"
      continue
    fi

    if [[ -n "$query" && "$worktree_path" == "$query" ]]; then
      exact_path_count=$((exact_path_count + 1))
      exact_path_path="$worktree_path"
      continue
    fi

    if [[ -n "$query" && ("$branch" == *"$query"* || "$worktree_path" == *"$query"*) ]]; then
      substring_count=$((substring_count + 1))
      substring_path="$worktree_path"
    fi
  done <<< "$rows"

  if [[ -z "$query" ]]; then
    if ((managed_count == 1)); then
      print -r -- "$managed_path"
      return 0
    fi

    if ((managed_count > 1)); then
      gwtl
      _gwt_err "multiple worktrees; pass branch or path"
      return 1
    fi

    _gwt_err "no managed worktrees found for this repository"
    return 1
  fi

  if ((exact_branch_count > 1)); then
    _gwt_err "ambiguous query '${query}'; multiple exact branch matches"
    return 1
  fi
  if ((exact_branch_count == 1)); then
    print -r -- "$exact_branch_path"
    return 0
  fi

  if ((exact_path_count > 1)); then
    _gwt_err "ambiguous query '${query}'; multiple exact path matches"
    return 1
  fi
  if ((exact_path_count == 1)); then
    print -r -- "$exact_path_path"
    return 0
  fi

  if ((substring_count > 1)); then
    _gwt_err "ambiguous query '${query}'; pass a more specific branch or path"
    return 1
  fi
  if ((substring_count == 1)); then
    print -r -- "$substring_path"
    return 0
  fi

  _gwt_err "no matching managed worktree found for '${query}'"
  return 1
}

_gwt_help() {
  case "${1-}" in
    gwtw)
      cat <<'EOF'
Usage: gwtw <branch> [base]

Create or switch to a managed worktree for <branch>, then cd into it.

Branch behavior:
  - Existing registered worktree: cd to it.
  - Existing local branch: create a worktree for it.
  - Existing origin/<branch>: create a local tracking branch when [base] is omitted.
  - New branch: create from [base], or from current HEAD when [base] is omitted.

Examples:
  gwtw feature/demo
  gwtw feature/demo origin/main
EOF
      ;;
    gwtcd)
      cat <<'EOF'
Usage: gwtcd [query]

Cd into a managed worktree for the current repository.

Query matching:
  - Exact branch name first.
  - Exact path second.
  - Unique substring of branch or path last.
  - With no query, cd only if exactly one managed worktree exists.

Examples:
  gwtcd feature/demo
  gwtcd demo
  gwtcd /path/to/worktree
EOF
      ;;
    gwtl)
      cat <<'EOF'
Usage: gwtl

List managed branch worktrees for the current repository.

Output format:
  <branch><TAB><path>
EOF
      ;;
    gwtrm)
      cat <<'EOF'
Usage: gwtrm <branch-or-path>

Remove a managed worktree for the current repository.

Safety behavior:
  - Refuses unmanaged paths.
  - Refuses to remove the current worktree.
  - Uses git worktree remove without --force.

Examples:
  gwtrm feature/demo
  gwtrm /path/to/worktree
EOF
      ;;
    *)
      _gwt_err "unknown help topic: ${1-}"
      return 1
      ;;
  esac
}

unalias gwtw gwtcd gwtl gwtrm 2>/dev/null || true

gwtw() {
  local branch="${1-}"
  local base="${2-}"
  local repo_root=""
  local repo_slug=""
  local branch_slug=""
  local gwt_root=""
  local target_path=""
  local repo_parent=""
  local worktree_list=""
  local registered_path=""
  local current_path=""
  local current_branch=""

  if [[ "$branch" == "--help" || "$branch" == "-h" ]]; then
    _gwt_help gwtw
    return 0
  fi

  if [[ -z "$branch" ]]; then
    _gwt_err "usage: gwtw <branch> [base]"
    return 1
  fi

  if ! repo_root="$(_gwt_repo_root)"; then
    return 1
  fi
  if ! repo_slug="$(_gwt_repo_slug)"; then
    return 1
  fi
  if ! branch_slug="$(_gwt_branch_slug "$branch")"; then
    return 1
  fi

  gwt_root="$(_gwt_root)"
  repo_parent="$gwt_root/$repo_slug"
  target_path="$repo_parent/$branch_slug"

  if ! worktree_list="$(git -C "$repo_root" worktree list --porcelain 2>/dev/null)"; then
    _gwt_err "failed to inspect git worktrees"
    return 1
  fi

  while IFS= read -r line; do
    case "$line" in
      worktree\ *)
        current_path="${line#worktree }"
        current_branch=""
        ;;
      branch\ refs/heads/*)
        current_branch="${line#branch refs/heads/}"
        if [[ "$current_branch" == "$branch" ]]; then
          registered_path="$current_path"
          break
        fi
        ;;
    esac
  done <<< "$worktree_list"

  if [[ -n "$registered_path" ]]; then
    cd "$registered_path" || {
      _gwt_err "failed to cd to registered worktree: $registered_path"
      return 1
    }
    return 0
  fi

  if [[ -e "$target_path" ]]; then
    _gwt_err "target path already exists and is not a registered worktree for '$branch': $target_path"
    return 1
  fi

  if [[ -z "$base" ]] &&
     ! git -C "$repo_root" show-ref --verify --quiet "refs/heads/$branch" &&
     ! git -C "$repo_root" show-ref --verify --quiet "refs/remotes/origin/$branch" &&
     ! git -C "$repo_root" rev-parse --verify --quiet HEAD^{commit} >/dev/null; then
    _gwt_err "cannot create worktree from HEAD because repository has no commits"
    return 1
  fi

  if ! mkdir -p "$repo_parent"; then
    _gwt_err "failed to create worktree parent: $repo_parent"
    return 1
  fi

  if git -C "$repo_root" show-ref --verify --quiet "refs/heads/$branch"; then
    if ! git -C "$repo_root" worktree add "$target_path" "$branch"; then
      _gwt_err "failed to add worktree for existing branch '$branch'"
      return 1
    fi
  elif [[ -n "$base" ]]; then
    if ! git -C "$repo_root" worktree add -b "$branch" "$target_path" "$base"; then
      _gwt_err "failed to add worktree for new branch '$branch' from '$base'"
      return 1
    fi
  elif git -C "$repo_root" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    if ! git -C "$repo_root" worktree add -b "$branch" --track "$target_path" "origin/$branch"; then
      _gwt_err "failed to add tracking worktree for 'origin/$branch'"
      return 1
    fi
  else
    if ! git -C "$repo_root" worktree add -b "$branch" "$target_path" HEAD; then
      _gwt_err "failed to add worktree for new branch '$branch' from HEAD"
      return 1
    fi
  fi

  cd "$target_path" || {
    _gwt_err "failed to cd to worktree: $target_path"
    return 1
  }
}

gwtcd() {
  local query="${1-}"
  local target=""

  if [[ "$query" == "--help" || "$query" == "-h" ]]; then
    _gwt_help gwtcd
    return 0
  fi

  if ! target="$(_gwt_resolve_managed_worktree "$query")"; then
    return 1
  fi

  cd "$target" || {
    _gwt_err "failed to cd to worktree: $target"
    return 1
  }
}

gwtl() {
  if [[ "${1-}" == "--help" || "${1-}" == "-h" ]]; then
    _gwt_help gwtl
    return 0
  fi

  _gwt_managed_worktree_rows
}

gwtrm() {
  local query="${1-}"
  local target=""
  local repo_root=""

  if [[ "$query" == "--help" || "$query" == "-h" ]]; then
    _gwt_help gwtrm
    return 0
  fi

  if [[ -z "$query" ]]; then
    _gwt_err "usage: gwtrm <branch-or-path>"
    return 1
  fi

  if ! repo_root="$(_gwt_repo_root)"; then
    return 1
  fi

  if ! target="$(_gwt_resolve_managed_worktree "$query")"; then
    return 1
  fi

  if [[ "$target" == "$repo_root" ]]; then
    _gwt_err "cannot remove current worktree"
    return 1
  fi

  if ! git -C "$repo_root" worktree remove "$target"; then
    _gwt_err "failed to remove worktree: $target"
    return 1
  fi
}

_gwt_branch_completion_candidates() {
  local -a candidates refs
  local ref=""
  typeset -U candidates

  if ! _gwt_have_git || ! git rev-parse --git-dir >/dev/null 2>&1; then
    return 1
  fi

  refs=("${(@f)$(git for-each-ref --format='%(refname:short)' refs/heads refs/remotes/origin 2>/dev/null)}")
  for ref in "${refs[@]}"; do
    [[ -z "$ref" || "$ref" == "origin/HEAD" ]] && continue
    if [[ "$ref" == origin/* ]]; then
      candidates+=("${ref#origin/}")
    else
      candidates+=("$ref")
    fi
  done

  (( ${#candidates[@]} )) || return 1
  print -rl -- "${candidates[@]}"
}

_gwt_base_completion_candidates() {
  local -a candidates refs
  local ref=""
  typeset -U candidates

  if ! _gwt_have_git || ! git rev-parse --git-dir >/dev/null 2>&1; then
    return 1
  fi

  refs=("${(@f)$(git for-each-ref --format='%(refname:short)' refs/heads refs/remotes refs/tags 2>/dev/null)}")
  for ref in "${refs[@]}"; do
    [[ -z "$ref" || "$ref" == "origin/HEAD" ]] && continue
    candidates+=("$ref")
  done

  (( ${#candidates[@]} )) || return 1
  print -rl -- "${candidates[@]}"
}

_gwt_managed_worktree_completion_candidates() {
  local -a candidates
  local branch=""
  local path=""
  local rows=""
  typeset -U candidates

  if ! rows="$(_gwt_managed_worktree_rows 2>/dev/null)"; then
    return 1
  fi

  while IFS=$'\t' read -r branch path; do
    [[ -z "$branch" || -z "$path" ]] && continue
    candidates+=("$branch" "$path")
  done <<< "$rows"

  (( ${#candidates[@]} )) || return 1
  print -rl -- "${candidates[@]}"
}

_gwt_complete_branch() {
  local -a candidates

  candidates=("${(@f)$(_gwt_branch_completion_candidates 2>/dev/null)}")
  (( ${#candidates[@]} )) || return 1
  compadd -a candidates
}

_gwt_complete_base() {
  local -a candidates

  candidates=("${(@f)$(_gwt_base_completion_candidates 2>/dev/null)}")
  (( ${#candidates[@]} )) || return 1
  compadd -a candidates
}

_gwt_complete_managed_worktree() {
  local -a candidates

  candidates=("${(@f)$(_gwt_managed_worktree_completion_candidates 2>/dev/null)}")
  (( ${#candidates[@]} )) || return 1
  compadd -a candidates
}

_gwt_complete_gwtw() {
  _arguments \
    '1:branch:_gwt_complete_branch' \
    '2:base:_gwt_complete_base'
}

_gwt_complete_no_args() {
  _arguments '*:: :->none'
}

if (( $+functions[compdef] )); then
  compdef _gwt_complete_gwtw gwtw
  compdef _gwt_complete_managed_worktree gwtcd gwtrm
  compdef _gwt_complete_no_args gwtl
fi
