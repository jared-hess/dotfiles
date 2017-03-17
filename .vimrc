execute pathogen#infect()
" Update the helptags, somehow these can get out of sync
Helptags
syntax on
filetype plugin indent on
set backspace=indent,eol,start
set smartcase

" Colorscheme
set background=dark
colorscheme solarized

" Set undofile if it is supported. Create dirs if they don't exist.
if has('persistent_undo')
  set undodir=~/.vim_undo
  call system('mkdir -p ' . &undodir)
  set undofile
endif

" Tab stuff
set expandtab
set shiftwidth=2
set softtabstop=2

" Powerline config
let powerline_dir = $POWERLINE_DIR
execute "set rtp+=" . powerline_dir . "/bindings/vim/"

" Gives some time to use the leader. For nerdcommenter because I'm a slow
" typist :(
set timeout timeoutlen=3000

" Always show statusline
set laststatus=2

" Use 256 colours (Use this setting only if your terminal supports 256 colours)
set t_Co=256

" Clipper setting
" Bind <leader>y to forward last-yanked text to Clipper
nnoremap <leader>y :call system('ncat localhost 8377', @0)<CR>
" Re-bind yy and y to do default action, plus forward to clipper. We'll see if
" this breaks anything...
nmap yy yy:call system('ncat localhost 8377', @0)<CR>
vmap y y:call system('ncat localhost 8377', @0)<CR>

" Mouse mode
set mouse=a

" https://xkcd.com/1806/
map <C-ScrollWheelUp> u
map <C-ScrollWheelDown> <C-R>

" Nerdtree on open
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
