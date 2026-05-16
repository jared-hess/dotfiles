local opt = vim.opt
local uv = vim.uv or vim.loop

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end

if uv.fs_stat(lazypath) then
  opt.rtp:prepend(lazypath)
  local ok, lazy = pcall(require, "lazy")
  if ok then
    lazy.setup({
      { "tpope/vim-fugitive" },
      { "tpope/vim-sleuth" },
      {
        "lewis6991/gitsigns.nvim",
        opts = {
          signs_staged_enable = true,
        },
      },
    }, {
      change_detection = {
        notify = false,
      },
    })
  end
end

opt.backspace = { "indent", "eol", "start" }
opt.ignorecase = true
opt.smartcase = true
opt.expandtab = true
opt.shiftwidth = 2
opt.softtabstop = 2
opt.timeout = true
opt.timeoutlen = 3000
opt.laststatus = 2
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.signcolumn = "yes"
opt.undofile = true
local undodir = vim.fn.expand("~/.vim_undo")
opt.undodir = undodir

vim.fn.mkdir(undodir, "p")

opt.background = "dark"
opt.termguicolors = true
vim.cmd("colorscheme habamax")

vim.keymap.set("", "<C-ScrollWheelUp>", "u")
vim.keymap.set("", "<C-ScrollWheelDown>", "<C-r>")

vim.cmd("nnoremap <leader>y :call system('ncat localhost 8377', @0)<CR>")
vim.cmd("nmap yy yy:call system('ncat localhost 8377', @0)<CR>")
vim.cmd("vmap y y:call system('ncat localhost 8377', @0)<CR>")

vim.diagnostic.config({
  underline = true,
  signs = true,
  virtual_text = false,
  update_in_insert = false,
  severity_sort = true,
})

local saw_stdin = false
vim.api.nvim_create_autocmd("StdinReadPre", {
  callback = function()
    saw_stdin = true
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.fn.argc() == 0 and not saw_stdin then
      vim.cmd("Lexplore")
    end
  end,
})
