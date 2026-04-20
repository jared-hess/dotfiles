# Dotfiles Management

This repo uses a bare git repository (`$HOME/.dotfiles`) with your home directory as the working tree.

`install_dotfiles.sh` is now a small management CLI that handles bootstrap, updates, conflict backups, and submodule syncing.

This branch also includes an in-repo chezmoi source tree under `chezmoi/` for migration testing.

## Quick start

```bash
./install_dotfiles.sh bootstrap
```

If checkout conflicts are found, the script automatically moves conflicting files to a timestamped backup directory under `~/.dotfiles-backup/` and retries.

## Daily commands

```bash
./install_dotfiles.sh status
./install_dotfiles.sh update
./install_dotfiles.sh submodules
./install_dotfiles.sh config <git args>
./install_dotfiles.sh doctor
```

Useful alias:

```bash
alias config='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
```

## Environment overrides

Set these if you want to customize paths or repository source:

- `DOTFILES_REPO_URL` (default: `git@github.com:jared-hess/dotfiles.git`)
- `DOTFILES_GIT_DIR` (default: `$HOME/.dotfiles`)
- `DOTFILES_WORK_TREE` (default: `$HOME`)
- `DOTFILES_BACKUP_ROOT` (default: `$HOME/.dotfiles-backup`)

Example:

```bash
DOTFILES_REPO_URL=git@github.com:my-org/dotfiles.git ./install_dotfiles.sh bootstrap
```
