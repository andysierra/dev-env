" neovim reutiliza la config de vim (~/.vimrc + ~/.vim). Variante Linux de ../../nvim/init.vim:
" alla el runtimepath apuntaba a $HOME/vim (sin punto) y con comillas que vim no expande.
set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath=&runtimepath
source ~/.vimrc
