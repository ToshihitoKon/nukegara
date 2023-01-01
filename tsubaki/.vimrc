"" vim-plug
" automatic installation
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" packages
call plug#begin('~/.vim/plugged')
" Plug 'w0rp/ale'

" lsp
" Plug 'prabirshrestha/async.vim'
" Plug 'prabirshrestha/asyncomplete.vim'
" Plug 'prabirshrestha/asyncomplete-lsp.vim'
" Plug 'mattn/vim-lsp-settings'

" golang
" Plug 'prabirshrestha/vim-lsp'
" Plug 'mattn/vim-goimports'
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }

" python
Plug 'Vimjas/vim-python-pep8-indent'

" general
Plug 'fatih/molokai'
Plug 'scrooloose/nerdtree'
" Plug 'Shougo/unite.vim'
Plug 'rking/ag.vim'

" git
Plug 'Xuyuanp/nerdtree-git-plugin'
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
" Plug 'Shougo/neosnippet.vim'
" Plug 'Shougo/neosnippet-snippets'

" スクロールをスムーズにしてくれる
Plug 'psliwka/vim-smoothie'

" カラフルな複数ハイライトができる
Plug 't9md/vim-quickhl'
" visualモードで選択した文字列を検索できる
Plug 'thinca/vim-visualstar'

" :Commentaryでコメントアウトできる
Plug 'tpope/vim-commentary'

" Powerlineフォントを使わないお洒落なstatusline
Plug 'itchyny/lightline.vim'

" pug
Plug 'digitaltoad/vim-pug'

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
set statusline=[%F]%m%h%w\ %<[TYPE=%Y]\ %=[POS=%l/%L(%02v)]
hi Statusline cterm=bold ctermbg=DarkGreen ctermfg=White
hi TabLine ctermbg=darkgray ctermfg=white
hi TabLineFill ctermfg=black
hi TabLineSel ctermbg=DarkGreen ctermfg=White

" go-vim settings
" let g:go_fmt_command = "goimports"
" let g:go_def_mapping_enabled = 0

let g:goimports = 1
unlet! g:goimports_simplify

" ale
let g:ale_fixers = {
  \ '*': ['remove_trailing_lines', 'trim_whitespace'],
  \ 'javascript': ['eslint'],
\}
let g:ale_fix_on_save = 1

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
set modelines=5     " vim: が上下5行以内にあれば反映
set ignorecase
set smartcase       " 頭良く検索


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
nnoremap < :tabprevious<CR>
nnoremap > :tabnext<CR>

" Prettier settings
let g:prettier#config#semi = 'false'
let g:prettier#config#single_quote = 'true'

" Clipboard連携
set clipboard&
set clipboard=unnamedplus

" quickhl
" nmap <Space>m <Plug>(quickhl-manual-this)
" xmap <Space>m <Plug>(quickhl-manual-this)
" nmap <Space>w <Plug>(quickhl-manual-this-whole-word)
" xmap <Space>w <Plug>(quickhl-manual-this-whole-word)
" nmap <Space>c <Plug>(quickhl-manual-clear)
" vmap <Space>c <Plug>(quickhl-manual-clear)
" nmap <Space>M <Plug>(quickhl-manual-reset)
" xmap <Space>M <Plug>(quickhl-manual-reset)
" space + j でカーソルのある文字列をハイライトするモードtoggle
nmap <Space>j <Plug>(quickhl-cword-toggle)
" nmap <Space>] <Plug>(quickhl-tag-toggle)
" map H <Plug>(operator-quickhl-manual-this-motion)
