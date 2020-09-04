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
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'Shougo/unite.vim'
Plug 'rking/ag.vim'
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'
Plug 'prettier/vim-prettier', {
  \ 'do': 'yarn install',
  \ 'branch': 'release/1.x',
  \ 'for': [
    \ 'javascript',
    \ 'vue',
    \ 'python'] }
Plug 'mattn/emmet-vim'
Plug 'Shougo/neocomplcache'

Plug 'Shougo/neosnippet.vim'
Plug 'Shougo/neosnippet-snippets'

call plug#end()

" filetype settings
autocmd BufRead,BufNewFile *.js setfiletype js
autocmd BufRead,BufNewFile *.html setfiletype html
autocmd BufRead,BufNewFile *.vue setfiletype vue


" Colorscheme
let g:rehash256 = 1
let g:molokai_original = 1
colorscheme molokai

" statusline format
set laststatus=2
set statusline=[%F]
highlight Statusline cterm=bold ctermbg=DarkGreen ctermfg=White

" go-vim settings
let g:go_fmt_command = "goimports"
let g:go_def_mapping_enabled = 0

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

"" unite for ag
" 大文字小文字を区別しない
" let g:unite_enable_ignore_case = 1
" let g:unite_enable_smart_case = 1

" grep検索
"nnoremap <silent> ,cg :<C-u>Unite grep:. -buffer-name=search-buffer<CR>

" カーソル位置の単語をgrep検索
"nnoremap <silent> <C-g> :<C-u>Unite grep:. -buffer-name=search-buffer<CR><C-R><C-W>

" unite grep に ag(The Silver Searcher) を使う
"if executable('ag')
"  let g:unite_source_grep_command = 'ag'
"  let g:unite_source_grep_default_opts = '--nogroup --nocolor --column'
"  let g:unite_source_grep_recursive_opt = ''
"endif

" Prettier settings
let g:prettier#config#semi = 'false'
let g:prettier#config#single_quote = 'true'

" Clipboard連携
set clipboard&
set clipboard^=unnamedplus
