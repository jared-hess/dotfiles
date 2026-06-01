Describe 'git worktree shell helpers'
  # SC1090: SOURCE path is computed from repo root.
  # SC2034: GWT_ROOT is consumed by the sourced zsh helper.
  # SC2329: helpers are invoked indirectly by ShellSpec `When run`.
  # shellcheck disable=SC1090,SC2034,SC2329
  REPO_ROOT="${PWD}"
  SHELL_HELPER="$REPO_ROOT/chezmoi/dot_zshrc.d/66-git-worktree.zsh"

  source_module() {
    # shellcheck disable=SC1090
    . "$SHELL_HELPER"
  }

  source_module_success() {
    source_module
    whence -w gwtw
    whence -w gwtcd
    whence -w gwtl
    whence -w gwtrm
    whence -w _gwt_target_path
    whence -w _gwt_complete_gwtw
    whence -w _gwt_complete_managed_worktree
  }

  source_module_overrides_worktree_aliases() {
    alias gwtrm='git worktree remove'
    source_module
    whence -w gwtrm
  }

  source_module_registers_completion_functions() {
    # shellcheck disable=SC2329
    compdef() {
      print -r -- "$*"
    }

    source_module
  }

  branch_slug_different_when_colliding_chars() {
    source_module
    local feature_slash
    local feature_dash
    local feature_underscore

    feature_slash=$(_gwt_branch_slug "feature/foo")
    feature_dash=$(_gwt_branch_slug "feature-foo")
    feature_underscore=$(_gwt_branch_slug "feature_foo")

    [[ "$feature_slash" != "$feature_dash" &&
       "$feature_slash" != "$feature_underscore" &&
       "$feature_dash" != "$feature_underscore" ]]
  }

  branch_slug_deterministic() {
    source_module
    local first
    local second

    first=$(_gwt_branch_slug "feature/foo")
    second=$(_gwt_branch_slug "feature/foo")

    [[ "$first" == "$second" ]]
  }

  slugs_do_not_contain_path_separators() {
    source_module
    local repo_slug
    local branch_slug

    export GWT_REPO_SLUG="org/repo"
    repo_slug="$(_gwt_repo_slug)"
    branch_slug="$(_gwt_branch_slug "feature/foo")"

    [[ "$repo_slug" != */* && "$branch_slug" != */* ]]
  }

  root_override_uses_exact_configured_root() {
    source_module
    local tmp
    local repo
    local configured_root
    local target

    tmp="$(mktemp -d)"
    repo="$tmp/repo"
    init_git_repo "$repo"
    configured_root="$tmp/custom-root"
    export GWT_ROOT="$configured_root"

    cd "$repo" || return 1
    target="$(_gwt_target_path "feature/root-override")"

    [[ "$target" == "$configured_root"/* ]]
  }

  root_override_tilde_expands_to_home() {
    local tmp
    local fake_home
    local target
    local HOME
    local GWT_ROOT

    source_module
    tmp="$(mktemp -d)"
    fake_home="$tmp/fake-home"
    mkdir -p "$fake_home"

    HOME="$fake_home"
    # shellcheck disable=SC2088
    GWT_ROOT="~/custom-root"
    target="$(_gwt_root)"

    [[ "$target" == "$fake_home/custom-root" ]]
  }

  repo_slug_override_disambiguates_same_basename_repos() {
    source_module
    local tmp
    local repo_one
    local repo_two
    local path_one
    local path_two

    tmp="$(mktemp -d)"
    repo_one="$tmp/org-one/repo"
    repo_two="$tmp/org-two/repo"
    init_git_repo "$repo_one"
    init_git_repo "$repo_two"
    export GWT_ROOT="$tmp/worktrees"

    cd "$repo_one" || return 1
    export GWT_REPO_SLUG="org-one-repo"
    path_one="$(_gwt_target_path "feature/shared")"

    cd "$repo_two" || return 1
    export GWT_REPO_SLUG="org-two-repo"
    path_two="$(_gwt_target_path "feature/shared")"

    [[ "$path_one" == "$tmp/worktrees/org-one-repo"/* &&
       "$path_two" == "$tmp/worktrees/org-two-repo"/* &&
       "$path_one" != "$path_two" ]]
  }

  completion_candidates_include_local_and_origin_branches() {
    source_module
    local tmp
    local repo
    local branch_candidates
    local base_candidates

    tmp="$(mktemp -d)"
    repo="$tmp/repo"
    init_git_repo "$repo"
    git -C "$repo" branch local-ready
    git -C "$repo" update-ref refs/remotes/origin/remote-ready HEAD
    git -C "$repo" tag v1.0.0

    cd "$repo" || return 1
    branch_candidates="$(_gwt_branch_completion_candidates)"
    base_candidates="$(_gwt_base_completion_candidates)"

    [[ "$branch_candidates" == *local-ready* &&
       "$branch_candidates" == *remote-ready* &&
       "$branch_candidates" != *origin/remote-ready* &&
       "$base_candidates" == *origin/remote-ready* &&
       "$base_candidates" == *v1.0.0* ]]
  }

  completion_candidates_include_managed_worktree_queries() {
    source_module
    local tmp
    local repo
    local branch
    local target
    local candidates

    tmp="$(mktemp -d)"
    repo="$tmp/repo"
    init_git_repo "$repo"
    export GWT_ROOT="$tmp/worktrees"

    cd "$repo" || return 1
    branch="feature/complete-me"
    target="$(_gwt_target_path "$branch")"
    gwtw "$branch" >/dev/null || return 1
    cd "$repo" || return 1
    candidates="$(_gwt_managed_worktree_completion_candidates)"

    [[ "$candidates" == *"$branch"* && "$candidates" == *"$target"* ]]
  }

  public_command_surface_stays_limited() {
    source_module

    whence -w gwtw >/dev/null || return 1
    whence -w gwtcd >/dev/null || return 1
    whence -w gwtl >/dev/null || return 1
    whence -w gwtrm >/dev/null || return 1
    ! whence -w gwt >/dev/null 2>&1 || return 1
    ! whence -w gwtls >/dev/null 2>&1 || return 1
    ! whence -w gwtclean >/dev/null 2>&1 || return 1
  }

  init_git_repo() {
    local repo="$1"

    mkdir -p "$repo"
    git -C "$repo" init -q
    git -C "$repo" symbolic-ref HEAD refs/heads/main
    git -C "$repo" config user.email shellspec@example.invalid
    git -C "$repo" config user.name ShellSpec
    printf '%s\n' initial > "$repo/README.md"
    git -C "$repo" add README.md
    git -C "$repo" commit -q -m initial
  }

  gwtw_creates_branch_from_head() {
    source_module
    local tmp
    local repo
    local expected

    tmp="$(mktemp -d)"
    repo="$tmp/repo"
    init_git_repo "$repo"
    export GWT_ROOT="$tmp/worktrees"

    cd "$repo" || return 1
    expected="$(_gwt_target_path feature/new)"
    gwtw feature/new >/dev/null || return 1

    [[ "$PWD" == "$expected" && "$(git branch --show-current)" == "feature/new" ]]
  }

  gwtw_adds_existing_local_branch() {
    source_module
    local tmp
    local repo
    local expected

    tmp="$(mktemp -d)"
    repo="$tmp/repo"
    init_git_repo "$repo"
    export GWT_ROOT="$tmp/worktrees"
    git -C "$repo" branch local-ready

    cd "$repo" || return 1
    expected="$(_gwt_target_path local-ready)"
    gwtw local-ready >/dev/null || return 1

    [[ "$PWD" == "$expected" && "$(git branch --show-current)" == "local-ready" ]]
  }

  gwtw_reuses_registered_worktree() {
    source_module
    local tmp
    local repo
    local expected
    local first_pwd

    tmp="$(mktemp -d)"
    repo="$tmp/repo"
    init_git_repo "$repo"
    export GWT_ROOT="$tmp/worktrees"

    cd "$repo" || return 1
    expected="$(_gwt_target_path reuse/me)"
    gwtw reuse/me >/dev/null || return 1
    first_pwd="$PWD"
    cd "$repo" || return 1
    gwtw reuse/me >/dev/null || return 1

    [[ "$PWD" == "$expected" && "$PWD" == "$first_pwd" ]]
  }

  gwtw_requires_branch_argument() {
    source_module
    gwtw
  }

  gwtw_fails_outside_git() {
    source_module
    local tmp

    tmp="$(mktemp -d)"
    cd "$tmp" || return 1
    gwtw nowhere
  }

  gwtw_refuses_target_path_collision() {
    source_module
    local tmp
    local repo
    local target

    tmp="$(mktemp -d)"
    repo="$tmp/repo"
    init_git_repo "$repo"
    export GWT_ROOT="$tmp/worktrees"

    cd "$repo" || return 1
    target="$(_gwt_target_path collide/me)"
    mkdir -p "$target"
    gwtw collide/me
  }

  gwtw_preserves_dirty_current_worktree() {
    source_module
    local tmp
    local repo
    local before
    local after

    tmp="$(mktemp -d)"
    repo="$tmp/repo"
    init_git_repo "$repo"
    export GWT_ROOT="$tmp/worktrees"
    printf '%s\n' dirty >> "$repo/README.md"

    cd "$repo" || return 1
    before="$(git -C "$repo" status --short)"
    gwtw feature/dirty >/dev/null || return 1
    after="$(git -C "$repo" status --short)"

    [[ "$before" == *"README.md"* && "$after" == "$before" ]]
  }

  gwtw_creates_branch_from_detached_head() {
    source_module
    local tmp
    local repo

    tmp="$(mktemp -d)"
    repo="$tmp/repo"
    init_git_repo "$repo"
    export GWT_ROOT="$tmp/worktrees"

    git -C "$repo" checkout --detach -q
    cd "$repo" || return 1
    gwtw feature/from-detached >/dev/null || return 1

    [[ "$(git branch --show-current)" == "feature/from-detached" ]]
  }

  gwtw_unborn_repo_fails_before_target_creation() {
    source_module
    local tmp
    local repo
    local target

    tmp="$(mktemp -d)"
    repo="$tmp/repo"
    mkdir -p "$repo"
    git -C "$repo" init -q
    git -C "$repo" symbolic-ref HEAD refs/heads/main
    export GWT_ROOT="$tmp/worktrees"

    cd "$repo" || return 1
    target="$(_gwt_target_path feature/unborn)"
    gwtw feature/unborn
    local status=$?

    [[ $status -ne 0 && ! -e "$target" ]] || return 1
    return "$status"
  }

  gwtw_origin_branch_creates_local_tracking_branch() {
    source_module
    local tmp
    local source_repo
    local remote_repo
    local clone_repo
    local upstream

    tmp="$(mktemp -d)"
    source_repo="$tmp/source"
    remote_repo="$tmp/remote.git"
    clone_repo="$tmp/clone"
    init_git_repo "$source_repo"
    git -C "$source_repo" checkout -q -b remote-ready
    printf '%s\n' remote > "$source_repo/remote.txt"
    git -C "$source_repo" add remote.txt
    git -C "$source_repo" commit -q -m remote-ready
    git clone --bare -q "$source_repo" "$remote_repo"
    git clone -q "$remote_repo" "$clone_repo"
    git -C "$clone_repo" checkout -q main
    git -C "$clone_repo" branch -D remote-ready >/dev/null 2>&1 || true
    export GWT_ROOT="$tmp/worktrees"

    cd "$clone_repo" || return 1
    gwtw remote-ready >/dev/null || return 1
    upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}')"

    [[ "$(git branch --show-current)" == "remote-ready" && "$upstream" == "origin/remote-ready" ]]
  }

  gwtw_explicit_base_precedes_origin_branch() {
    source_module
    local tmp
    local source_repo
    local remote_repo
    local clone_repo
    local has_remote_file
    local upstream_status

    tmp="$(mktemp -d)"
    source_repo="$tmp/source"
    remote_repo="$tmp/remote.git"
    clone_repo="$tmp/clone"
    init_git_repo "$source_repo"
    git -C "$source_repo" checkout -q -b precedence
    printf '%s\n' remote > "$source_repo/remote-only.txt"
    git -C "$source_repo" add remote-only.txt
    git -C "$source_repo" commit -q -m precedence
    git clone --bare -q "$source_repo" "$remote_repo"
    git clone -q "$remote_repo" "$clone_repo"
    git -C "$clone_repo" checkout -q main
    git -C "$clone_repo" branch -D precedence >/dev/null 2>&1 || true
    export GWT_ROOT="$tmp/worktrees"

    cd "$clone_repo" || return 1
    gwtw precedence main >/dev/null || return 1
    [[ -e remote-only.txt ]] && has_remote_file=yes || has_remote_file=no
    git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1 && upstream_status=yes || upstream_status=no

    [[ "$(git branch --show-current)" == "precedence" &&
       "$has_remote_file" == "no" &&
       "$upstream_status" == "no" ]]
  }

  gwtl_lists_managed_worktrees_with_tab_separated_rows() {
    source_module
    local tmp
    local repo
    local branch_one
    local branch_two
    local path_one
    local path_two
    local output
    local tab=$'\t'

    tmp="$(mktemp -d)"
    repo="$tmp/repo"
    init_git_repo "$repo"
    export GWT_ROOT="$tmp/worktrees"

    cd "$repo" || return 1
    branch_one="feature/alpha"
    branch_two="feature/beta"
    gwtw "$branch_one" >/dev/null
    cd "$repo" || return 1
    gwtw "$branch_two" >/dev/null

    path_one="$(_gwt_target_path "$branch_one")"
    path_two="$(_gwt_target_path "$branch_two")"
    output="$(gwtl)"

    [[ "$output" == *"${branch_one}${tab}${path_one}"* ]]
    [[ "$output" == *"${branch_two}${tab}${path_two}"* ]]
    [[ "$output" != *"main${tab}"* ]]
  }

  gwtcd_switches_to_exact_match() {
    source_module
    local tmp
    local repo
    local query_branch
    local target

    tmp="$(mktemp -d)"
    repo="$tmp/repo"
    init_git_repo "$repo"
    export GWT_ROOT="$tmp/worktrees"

    cd "$repo" || return 1
    query_branch="feature/exact-match"
    target="$(_gwt_target_path "$query_branch")"
    gwtw "$query_branch" >/dev/null
    cd "$repo" || return 1

    gwtcd "$query_branch"

    [[ "$PWD" == "$target" && "$(git branch --show-current)" == "$query_branch" ]]
  }

  gwtcd_no_query_switches_when_single() {
    source_module
    local tmp
    local repo
    local query_branch
    local target

    tmp="$(mktemp -d)"
    repo="$tmp/repo"
    init_git_repo "$repo"
    export GWT_ROOT="$tmp/worktrees"

    cd "$repo" || return 1
    query_branch="feature/single"
    target="$(_gwt_target_path "$query_branch")"
    gwtw "$query_branch" >/dev/null
    cd "$repo" || return 1

    gwtcd

    [[ "$PWD" == "$target" && "$(git branch --show-current)" == "$query_branch" ]]
  }

  gwtcd_switches_to_exact_path_match() {
    source_module
    local tmp
    local repo
    local query_branch
    local target

    tmp="$(mktemp -d)"
    repo="$tmp/repo"
    init_git_repo "$repo"
    export GWT_ROOT="$tmp/worktrees"

    cd "$repo" || return 1
    query_branch="feature/path-match"
    target="$(_gwt_target_path "$query_branch")"
    gwtw "$query_branch" >/dev/null
    cd "$repo" || return 1

    gwtcd "$target"

    [[ "$PWD" == "$target" && "$(git branch --show-current)" == "$query_branch" ]]
  }

  gwtcd_ambiguous_query_fails() {
    source_module
    local tmp
    local repo

    tmp="$(mktemp -d)"
    repo="$tmp/repo"
    init_git_repo "$repo"
    export GWT_ROOT="$tmp/worktrees"

    cd "$repo" || return 1
    gwtw "feature/one" >/dev/null
    cd "$repo" || return 1
    gwtw "feature/two" >/dev/null

    gwtcd "feature"
  }

  gwtcd_no_query_fails_with_multiple_managed() {
    source_module
    local tmp
    local repo

    tmp="$(mktemp -d)"
    repo="$tmp/repo"
    init_git_repo "$repo"
    export GWT_ROOT="$tmp/worktrees"

    cd "$repo" || return 1
    gwtw "feature/one" >/dev/null
    cd "$repo" || return 1
    gwtw "feature/two" >/dev/null

    gwtcd
  }

  gwtrm_removes_a_managed_worktree() {
    source_module
    local tmp
    local repo
    local query_branch
    local target

    tmp="$(mktemp -d)"
    repo="$tmp/repo"
    init_git_repo "$repo"
    export GWT_ROOT="$tmp/worktrees"

    cd "$repo" || return 1
    query_branch="feature/remove-me"
    target="$(_gwt_target_path "$query_branch")"
    gwtw "$query_branch" >/dev/null

    gwtrm "$query_branch"

    [[ ! -d "$target" ]]
  }

  gwtrm_refuses_current_worktree() {
    source_module
    local tmp
    local repo
    local query_branch
    local target

    tmp="$(mktemp -d)"
    repo="$tmp/repo"
    init_git_repo "$repo"
    export GWT_ROOT="$tmp/worktrees"

    cd "$repo" || return 1
    query_branch="feature/current"
    target="$(_gwt_target_path "$query_branch")"
    gwtw "$query_branch" >/dev/null

    cd "$target" || return 1
    gwtrm "$query_branch"
  }

  gwtrm_refuses_unmanaged_path() {
    source_module
    local tmp
    local repo
    local unmanaged

    tmp="$(mktemp -d)"
    repo="$tmp/repo"
    init_git_repo "$repo"
    export GWT_ROOT="$tmp/worktrees"

    cd "$repo" || return 1
    unmanaged="$tmp/unmanaged"
    mkdir -p "$unmanaged"

    gwtrm "$unmanaged"
  }

  It 'sources the module and exposes shell entrypoints'
    When run source_module_success
    The status should be success
  End

  It 'sources when Oh My Zsh git worktree aliases already exist'
    When run source_module_overrides_worktree_aliases
    The status should be success
    The stdout should include 'gwtrm: function'
  End

  It 'registers zsh completions when compdef is available'
    When run source_module_registers_completion_functions
    The status should be success
    The stdout should include '_gwt_complete_gwtw gwtw'
    The stdout should include '_gwt_complete_managed_worktree gwtcd gwtrm'
    The stdout should include '_gwt_complete_no_args gwtl'
  End

  It 'generates distinct branch slugs for similar branch names'
    When run branch_slug_different_when_colliding_chars
    The status should be success
  End

  It 'keeps branch slug generation deterministic'
    When run branch_slug_deterministic
    The status should be success
  End

  It 'removes path separators from repo and branch slugs'
    When run slugs_do_not_contain_path_separators
    The status should be success
  End

  It 'uses the exact configured GWT_ROOT for target paths'
    When run root_override_uses_exact_configured_root
    The status should be success
  End

  It 'expands a leading ~ in GWT_ROOT against HOME'
    When run root_override_tilde_expands_to_home
    The status should be success
  End

  It 'uses GWT_REPO_SLUG to disambiguate same-basename repositories'
    When run repo_slug_override_disambiguates_same_basename_repos
    The status should be success
  End

  It 'builds branch and base completion candidates'
    When run completion_candidates_include_local_and_origin_branches
    The status should be success
  End

  It 'builds managed worktree completion candidates'
    When run completion_candidates_include_managed_worktree_queries
    The status should be success
  End

  It 'keeps the public command surface limited to documented commands'
    When run public_command_surface_stays_limited
    The status should be success
  End

  It 'creates a new branch worktree from current HEAD and cd changes into it'
    When run gwtw_creates_branch_from_head
    The status should be success
  End

  It 'attaches an existing local branch worktree and cd changes into it'
    When run gwtw_adds_existing_local_branch
    The status should be success
  End

  It 'reuses an existing registered branch worktree'
    When run gwtw_reuses_registered_worktree
    The status should be success
  End

  It 'requires a branch argument'
    When run gwtw_requires_branch_argument
    The status should be failure
    The stderr should include 'git-worktree: usage: gwtw <branch> [base]'
  End

  It 'fails outside a git repository'
    When run gwtw_fails_outside_git
    The status should be failure
    The stderr should include 'git-worktree: not inside a git repository'
  End

  It 'refuses a target path collision that is not the registered worktree'
    When run gwtw_refuses_target_path_collision
    The status should be failure
    The stderr should include 'git-worktree: target path already exists and is not a registered worktree'
  End

  It 'preserves dirty state in the current worktree when creating another worktree'
    When run gwtw_preserves_dirty_current_worktree
    The status should be success
  End

  It 'creates a new branch worktree from detached HEAD when commits exist'
    When run gwtw_creates_branch_from_detached_head
    The status should be success
  End

  It 'fails clearly in an unborn repository before target creation'
    When run gwtw_unborn_repo_fails_before_target_creation
    The status should be failure
    The stderr should include 'git-worktree: cannot create worktree from HEAD because repository has no commits'
  End

  It 'creates a local tracking branch from origin when no local branch or base exists'
    When run gwtw_origin_branch_creates_local_tracking_branch
    The status should be success
  End

  It 'honors explicit base before an origin branch with the same name'
    When run gwtw_explicit_base_precedes_origin_branch
    The status should be success
  End

  It 'lists managed worktrees as tab-separated rows'
    When run gwtl_lists_managed_worktrees_with_tab_separated_rows
    The status should be success
    The stdout should include 'feature/alpha\t'
    The stdout should include 'feature/beta\t'
    The stdout should not include 'main\t'
  End

  It 'switches to exact branch match'
    When run gwtcd_switches_to_exact_match
    The status should be success
  End

  It 'switches to the single managed worktree when no query is provided'
    When run gwtcd_no_query_switches_when_single
    The status should be success
  End

  It 'errors when multiple managed worktrees exist and no query is provided'
    When run gwtcd_no_query_fails_with_multiple_managed
    The status should be failure
    The stderr should include 'git-worktree: multiple worktrees; pass branch or path'
    The stdout should include 'feature/one'
    The stdout should include 'feature/two'
  End

  It 'switches to exact path match'
    When run gwtcd_switches_to_exact_path_match
    The status should be success
  End

  It 'fails ambiguous gwtcd query with clear message'
    When run gwtcd_ambiguous_query_fails
    The status should be failure
    The stderr should include 'git-worktree: ambiguous query'
  End

  It 'removes a managed worktree by branch'
    When run gwtrm_removes_a_managed_worktree
    The status should be success
  End

  It 'refuses to remove current worktree'
    When run gwtrm_refuses_current_worktree
    The status should be failure
    The stderr should include 'git-worktree: cannot remove current worktree'
  End

  It 'refuses unmanaged path removal'
    When run gwtrm_refuses_unmanaged_path
    The status should be failure
    The stderr should include 'git-worktree: no matching managed worktree found for'
  End
End
