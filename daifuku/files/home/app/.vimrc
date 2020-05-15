"" vim-plug
" automatic installation
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" packages
call plug#begin('~/.vim/plugged')
Plug 'fatih/molokai'
Plug 'scrooloose/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
call plug#end()

" Colorscheme
let g:rehash256 = 1
let g:molokai_original = 1
colorscheme molokai

" statusline format
set laststatus=2
set statusline=[%F]
highlight Statusline cterm=bold ctermbg=DarkGreen ctermfg=White

" general
set hidden          " 編集中のバッファを表示していても他のファイルを開ける
set autoread        " 自動バッファリロード
set number          " 行数表示
set nocompatible    " 非vi互換モード
set backspace=indent,eol,start  " BSで消せる文字種を設定
set wildmenu        " コマンド予測を表示
set cursorline      " 行ハイライト
set autoindent      " 自動整形
set expandtab       " \tをspaceに変換して表示
set shiftwidth=4    " indent幅
set tabstop=4       " expandtab時のtab幅
set modeline        " modeline有効
set modelines=5      " vim: が上下5行以内にあれば反映


" search setting
set incsearch       " インクリメンタルサーチ
set hlsearch        " 検索文字ハイライト

" mapping
nnoremap <C-t> :NERDTreeToggle<CR>
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
nnoremap ; /
nnoremap <C-c><C-c> :noh<CR>
