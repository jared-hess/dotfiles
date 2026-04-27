# Neovim Plugin Plan

Current plugin set in `init.lua` (managed with `lazy.nvim`):

- `tpope/vim-fugitive`
- `tpope/vim-sleuth`
- `lewis6991/gitsigns.nvim`

Not adding right now:

- solarized theme plugin
- comment plugin (Neovim has native `gc`/`gcc`)

Vim plugin mapping status:

- `nerdtree` -> replaced by native netrw (`:Lexplore` startup behavior)
- `syntastic` -> replaced by Neovim diagnostics (+ later LSP/linter setup)
- `vim-gitgutter` -> replaced by `gitsigns.nvim`
- `vim-sleuth` -> kept
- `vim-fugitive` -> kept
- `nerdcommenter` -> dropped (native commenting)
