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
- `.chezmoiexternal.toml.tmpl` keeps `~/.oh-my-zsh`, custom plugins, and optional private repos up to date
- `dot_local/bin/executable_*` installs executable commands into `~/.local/bin`
- `dot_config/shell/path.sh` is sourced by both shells for shared PATH setup
- `dot_config/shell/env.sh` is sourced from shell env fragments for shared environment variables
- `dot_config/shell/aliases.sh` is sourced from shell alias fragments for shared aliases/functions (including conditional `vim`/`vi` -> `nvim`)
- `dot_config/starship.toml` defines the shared Starship prompt config

## Managed Commands

- `ocw <branch-name>` creates or reuses a worktree for the current repo, then runs
  `opencode <worktree-path>`. Worktrees default to
  `~/worktrees/<repo-name>/<branch-name>` and branch from the current branch;
  use `--base-branch` or `--worktree-root` to override either default.
  `BASE_BRANCH` and `WORKTREE_ROOT` are also supported as environment fallbacks.

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
