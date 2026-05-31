# Dotfiles

This repo is managed with `chezmoi`.

## Bootstrap

```bash
./script/chezmoi bootstrap
```

The wrapper prefers package managers (`brew`, `apt`, `pacman`, `dnf`, `zypper`, `apk`) and falls back to official install scripts. It bootstraps `chezmoi`, installs `starship`, and runs the official unattended Oh My Zsh install script when `~/.oh-my-zsh` is missing.

Before first apply during bootstrap, existing managed target files are backed up to `~/.chezmoi-backup/<timestamp>/`.

Set `RUN_OH_MY_ZSH_INSTALLER=0` to skip running the Oh My Zsh installer.
Set `RUN_STARSHIP_INSTALLER=0` to skip installing Starship during bootstrap.
Set `BACKUP_EXISTING_DOTFILES=0` to skip creating bootstrap backups.

`apply -R` refreshes externals (for example `~/.oh-my-zsh`, optional work overlays, and optional opencode repos).

## Daily usage

```bash
./script/chezmoi diff
./script/chezmoi apply
./script/chezmoi update
./script/chezmoi edit ~/.zshrc
```

## Shell helpers

If you use the included zsh configuration, you also get the Codex-powered shell helpers.
See `chezmoi/README.md` for usage, examples, and safety behavior of `cxp`, `??`, `wtf`, Alt-C, and Alt-E.

## Source layout

- `chezmoi/` is the active chezmoi source state for this repo.
- Shell config is modularized with `*.d` patterns:
  - `~/.bash_profile.d/*.bash`
  - `~/.bashrc.d/*.bash`
  - `~/.zshrc.d/*.zsh`

## Private work overlay

Set machine-local data in `~/.config/chezmoi/chezmoi.toml`:

```toml
[data]
isWork = true
workDotfilesRepo = "git@git.company.com:team/dotfiles-private.git"
workDotfilesPath = ".config/work-dotfiles"
```

When enabled, work snippets are sourced from:

- `~/.config/work-dotfiles/bashrc.d/*.bash`
- `~/.config/work-dotfiles/zshrc.d/*.zsh`

See `chezmoi/README.md` for the full layout and onboarding details.
