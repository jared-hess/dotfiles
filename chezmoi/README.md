# Chezmoi Layout

This directory is a dedicated chezmoi source tree for moving this repo from the bare-git checkout model to a modular chezmoi workflow.

The shell setup uses `*.d/` directories so machine-specific fragments can be layered cleanly.

## Initialize

```bash
chezmoi init --source "$HOME/repos/dotfiles/chezmoi"
chezmoi apply
```

## Structure

- `dot_bash_profile` and `dot_bashrc.tmpl` load `~/.bash_profile.d/*.bash` and `~/.bashrc.d/*.bash`
- `dot_zshrc.tmpl` loads `~/.zshrc.d/*.zsh`, sets `ZSH_CUSTOM` to `~/.config/oh-my-zsh/custom`, and templates plugins/theme from data
- `.chezmoiexternal.toml.tmpl` keeps `~/.oh-my-zsh` up to date and optionally pulls a private work repo
- `dot_config/shell/path.sh` is sourced by both shells for shared PATH setup
- `dot_config/shell/env.sh` is sourced from shell env fragments for shared environment variables
- `dot_config/shell/aliases.sh` is sourced from shell alias fragments for shared aliases/functions (including conditional `vim`/`vi` -> `nvim`)
- `dot_config/starship.toml` defines the shared Starship prompt config

## Codex shell helpers (Zsh)

These helpers are in the Zsh fragment `chezmoi/dot_zshrc.d/65-codex.zsh` and are available once this dotfiles set is sourced in Zsh.

### Prerequisites

- `zsh`
- Codex CLI installed and available on PATH
- Authenticated with `codex login` for AI-powered features
- `ShellSpec`, only for local `./script/test-shell` verification

If `ShellSpec` is missing, `./script/test-shell` prints:

```text
script/test-shell: shellspec not found. Install ShellSpec and retry.
```

### Usage

- `cxp` sends the current input into Codex for review or transformation.

```bash
git diff | cxp 'review this diff'
```

- `??` uses your current text prompt to rewrite the current command line.

```bash
?? find all files over 100MB under this repo
```

`??` requires two Enter steps. The first Enter transforms the buffer to a proposed command; it does not run it. Review the new line, then press Enter again to execute.

- `wtf` explains a command before you run it.

```bash
wtf 'find . -type f -name "*.pyc" -delete'
```

### Output behavior

Default helper output is quiet on success. On a successful `codex` call, only the final assistant response is printed.
This suppresses Codex CLI ceremony, such as startup banners, warnings, and token summaries.

For raw streaming output and full Codex noise, set:

```bash
CODEX_SHELL_VERBOSE=1
```

while running your helper command.

### Keybindings

- `Alt-C` transforms the current buffer with Codex while preserving your current command context.
- `Alt-E` explains the current buffer command in-place and preserves the current buffer.

### Safety model

These helpers use your existing Codex authentication from `codex login`. No API key setup is required.

- No token, auth-file, or credential handling is added by the shell helpers.
- All generated commands are reviewed by default and **not** auto-run.
- All Codex invocations are sent through:

```text
codex exec --color never --sandbox read-only --ephemeral --skip-git-repo-check --output-last-message <tmpfile> -
```

This keeps command generation in a read-only sandbox and keeps default output concise.

Enable `CODEX_SHELL_VERBOSE=1` to bypass quiet capture and use raw
`codex exec --sandbox read-only --ephemeral --skip-git-repo-check -` output
for debugging.

## Git worktree helpers (Zsh)

These helpers are in the Zsh fragment `chezmoi/dot_zshrc.d/66-git-worktree.zsh` and are available once this dotfiles set is sourced in Zsh.

### Prerequisites

- `zsh`
- `git` with worktree support

### Loading

The `66-git-worktree.zsh` file is installed as `~/.zshrc.d/66-git-worktree.zsh` and loaded from your Zsh startup flow via `~/.zshrc.d/*.zsh` after `chezmoi apply`.

### Commands

- `gwtw <branch> [base]` creates and switches to a worktree for `<branch>`.
- `gwtcd [query]` switches to a matching managed worktree.
- `gwtl` lists managed worktrees for the current repository.
- `gwtrm <branch-or-path>` removes a matching managed worktree.

Each command supports `-h` and `--help` for usage, behavior, and examples.

### Layout and configuration

By default, worktrees are placed under:

```text
${GWT_ROOT:-$HOME/worktrees}/${repo-slug}/${branch-slug}
```

You can override behavior with these environment variables:

- `GWT_ROOT`: base directory for all managed worktrees. The default is `~/worktrees`.
- `GWT_REPO_SLUG`: optional slug override when repo names would collide.

### Branch behavior

- Existing local branches are reused.
- If `<branch>` does not exist locally and `origin/<branch>` exists, `gwtw` creates a local tracking branch and then creates the worktree.
- If no local or remote branch matches, a new branch is created from `[base]` when provided.
- If `[base]` is omitted, a new branch is created from the current `HEAD`.

### Safety behavior

- No destructive git operations are advertised for these helpers.
- Existing managed paths are not overwritten.
- Removal does not force delete paths.
- A dirty source tree is allowed when switching or creating worktrees, and the dirty state is preserved.

### Examples

```bash
gwtw feature/demo
gwtw bugfix origin/main
gwtcd feature/demo
gwtl
gwtrm feature/demo
```

## Private Work Overlay

Defaults are in `.chezmoidata.yaml` and can be overridden locally in `~/.config/chezmoi/chezmoi.toml`.

Local example:

```toml
[data]
isWork = true
workDotfilesRepo = "git@git.company.com:team/dotfiles-private.git"
workDotfilesPath = ".config/work-dotfiles"
workZshPlugins = ["kubectl", "docker"]
```

When `isWork = true`, chezmoi will manage a private external repo at `~/.config/work-dotfiles`.

By default, chezmoi also manages `~/.oh-my-zsh` as an external git repo and uses `~/.config/oh-my-zsh/custom` for user customizations.

The public shell configs source optional work snippets from that repo:

- `~/.config/work-dotfiles/bashrc.d/*.bash`
- `~/.config/work-dotfiles/zshrc.d/*.zsh`

This keeps sensitive snippets out of the public repo while still composing a single runtime shell config.

## Optional Opencode Repo

Opencode can be fully optional and repo-scoped per machine.

Local example (personal machine):

```toml
[data]
opencodeEnabled = true
opencodeRepo = "git@github.com:you/opencode-personal-private.git"
opencodePath = ".config/opencode"
```

Local example (work machine):

```toml
[data]
opencodeEnabled = true
opencodeRepo = "git@git.company.com:team/opencode-work.git"
opencodePath = ".config/opencode"
```

If `opencodeEnabled` is `false` (default), chezmoi does not manage opencode at all.

## Onboard New Config

Public-safe config:

```bash
chezmoi add ~/.config/myapp/config.toml
chezmoi cd
git add .
git commit -m "Add myapp config"
```

Work-private config:

```bash
chezmoi apply -R
mkdir -p ~/.config/work-dotfiles/myapp
cp ~/.config/myapp/config.toml ~/.config/work-dotfiles/myapp/config.toml
git -C ~/.config/work-dotfiles add myapp/config.toml
git -C ~/.config/work-dotfiles commit -m "Add myapp work config"
git -C ~/.config/work-dotfiles push
```
