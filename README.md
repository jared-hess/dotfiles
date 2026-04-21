# Dotfiles

This repo is managed with `chezmoi`.

## Bootstrap

```bash
brew install chezmoi
chezmoi init --source "$HOME/repos/dotfiles/chezmoi"
chezmoi apply -R
```

`-R` refreshes externals (for example `~/.oh-my-zsh` and optional work overlays).

## Daily usage

```bash
chezmoi diff
chezmoi apply
chezmoi update
chezmoi edit ~/.zshrc
```

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
