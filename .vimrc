execute pathogen#infect()
syntax on
filetype plugin indent on
set background=dark
colorscheme solarized
set undofile
set undodir=~/.vim_undo

" Powerline config
let powerline_dir = $POWERLINE_DIR
execute "set rtp+=" . powerline_dir . "/bindings/vim/"

" Always show statusline
set laststatus=2

" Use 256 colours (Use this setting only if your terminal supports 256 colours)
set t_Co=256

" Clipper setting
" Bind <leader>y to forward last-yanked text to Clipper
nnoremap <leader>y :call system('ncat localhost 8377', @0)<CR>

" Mouse mode
set mouse=a

