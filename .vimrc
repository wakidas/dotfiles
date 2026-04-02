let mapleader = " "

"シンタックスハイライトを有効化
syntax on

"jjでEsc
inoremap <silent> jj <ESC>

"vim\nnnoremap <expr> <Del> pumvisible() ? '<Del>' : '<C-d>'\n

"<C-l>で再描画時ハイライト無効化
nnoremap <silent> <C-l> : <C-u>nohlsearch<CR><C-l>
"コマンドラインのカーソル移動にemacsキーバインド
cnoremap <C-p> <Up>
cnoremap <C-n> <Down>
cnoremap <C-b> <Left>
cnoremap <C-f> <Right>
cnoremap <C-a> <Home>
cnoremap <C-e> <End>

"挿入モード
inoremap <C-d> <Del>
inoremap <C-a> <Home>
inoremap <C-e> <End>
inoremap <C-f> <Right>
inoremap <C-b> <Left>
inoremap <C-k> l<ESC>C

"ノーマルモード
nnoremap <C-a> <Home>
nnoremap <C-e> <End>
nnoremap <C-k> C<Esc>
nnoremap <Leader>o o<Esc>
nnoremap <Leader>O :normal O<Esc>
nnoremap <leader>s :w<CR>
nnoremap <leader>w :tabc<CR>
nnoremap <leader>wo :tabo<CR>
nnoremap <leader>h :tabprev<CR>
nnoremap <leader>l :tabnext<CR>

"x,s,cでヤンクしない
nnoremap x "_x
nnoremap s "_s
nnoremap c "_c
vnoremap x "_x
vnoremap s "_s
vnoremap c "_c

"デフォルトで検索結果をハイライト
set hlsearch
highlight Search ctermbg=39 ctermfg=0
"検索結果をエンター押さなくても常にハイライト
set incsearch
"小文字で検索可能
set smartcase
"ターミナル接続速度UP
set ttyfast
"常にステータス表示
set laststatus=2

"デフォルトで行番号表示
set number

"デフォルトでインデントをスペース
set tabstop=2
set shiftwidth=2
set autoindent

" 変更履歴をセッションまたいで保存
set undofile
set undodir=~/.vim/undodir

" タブ入力で半角スペース挿入
set expandtab

" Vimで、黒い背景に合う色を使おうとする
set background=dark

" カーソルが何行目の何列目にいるか表示する
set ruler

" カーソルがある行をハイライト
set cursorline


"コマンドプロンプト履歴を5000件に
set history=5000

"001のように頭に0がついている数字も10進数としてみなす（通常は8進数）

set nrformats=

"エンターで改行
augroup main
	autocmd!


autocmd main BufWinEnter *
			\  if &modifiable
			\|   nnoremap <buffer> <CR> i<CR><ESC>
			\| else
				\|   nunmap <buffer> <CR>
				\| endif

" tmux_syntax
autocmd BufRead,BufNewFile .tmux.conf set filetype=tmux
autocmd BufRead,BufNewFile *.tmux.conf set filetype=tmux
autocmd BufRead,BufNewFile tmux.conf set filetype=tmux

"空白とインデントを可視化
set list
set listchars=tab:▸\ ,trail:·,nbsp:·
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/

"colorscheme
"colorscheme desert
