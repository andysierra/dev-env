set number
set mouse=a
set numberwidth=1
set clipboard=unnamedplus
syntax enable
set showcmd
set ruler
set encoding=utf-8
set showmatch
set sw=2
set relativenumber
set laststatus=2
set cursorline
set whichwrap=<,>,[,]

runtime plugins.vim

" gruvbox_contrast_dark debe ir ANTES de colorscheme (despues no tiene efecto)
let g:gruvbox_contrast_dark = "hard"
silent! colorscheme gruvbox
let NERDTreeQuitOnOpen = 1
let g:airline_powerline_fonts=1

" ------------------------------------
" ATAJOS PERSONALIZADOS:
" ejemplo <Leader>w :w<CR>

let mapleader=" "
nmap <Leader>s <Plug>(easymotion-s2)
nmap <Leader>n :NERDTreeFind<CR>
nmap <Leader>b :bp<CR>
nmap <Leader>f :FZF<CR>
nmap <Leader>c :cd..<CR>
