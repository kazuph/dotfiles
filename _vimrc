"----------------------------------------------------------------------------------------
" Vim Plugin Settings
" bran new vimrc 2013/07/07
"       ___           ___           ___           ___           ___           ___
"      /\__\         /\  \         /\  \         /\__\         /\  \         /\__\
"     / /  /        /  \  \        \ \  \       / /  /        /  \  \       / /  /
"    / /__/        / /\ \  \        \ \  \     / /  /        / /\ \  \     / /__/
"   /  \__\____   /  \~\ \  \        \ \  \   / /  /  ___   /  \~\ \  \   /  \  \ ___
"  / /\     \__\ / /\ \ \ \__\ _______\ \__\ / /__/  /\__\ / /\ \ \ \__\ / /\ \  /\__\
"  \/_| |~~|~    \/__\ \/ /  / \        /__/ \ \  \ / /  / \/__\ \/ /  / \/__\ \/ /  /
"     | |  |          \  /  /   \ \~~\~~      \ \  / /  /       \  /  /       \  /  /
"     | |  |          / /  /     \ \  \        \ \/ /  /         \/__/        / /  /
"     | |  |         / /  /       \ \__\        \  /  /                      / /  /
"      \|__|         \/__/         \/__/         \/__/                       \/__/
"       ___                       ___           ___           ___
"      /\__\          ___        /\__\         /\  \         /\  \
"     / /  /         /\  \      /  |  |       /  \  \       /  \  \
"    / /  /          \ \  \    / | |  |      / /\ \  \     / /\ \  \
"   / /__/  ___      /  \__\  / /| |__|__   /  \~\ \  \   / /  \ \  \
"   | |  | /\__\  __/ /\/__/ / / |    \__\ / /\ \ \ \__\ / /__/ \ \__\
"   | |  |/ /  / /\/ /  /    \/__/~~/ /  / \/_|  \/ /  / \ \  \  \/__/
"   | |__/ /  /  \  /__/           / /  /     | |  /  /   \ \  \
"    \    /__/    \ \__\          / /  /      | |\/__/     \ \  \
"     ~~~~         \/__/         / /  /       | |  |        \ \__\
"                                \/__/         \|__|         \/__/
"
"----------------------------------------------------------------------------------------

set nocompatible
filetype plugin indent off

" for go
if $GOROOT != ''
  set rtp+=$GOROOT/misc/vim
endif

set rtp+=~/dotfiles/neobundle.git/
if has('vim_starting')
  set runtimepath+=~/dotfiles/neobundle.vim
  call neobundle#rc(expand('~/.vim/'))
endif

" No.1 ステータスラインに情報を表示 → もう力はいらない
" NeoBundle 'Lokaltog/vim-powerline.git'
NeoBundle 'bling/vim-airline'
let g:airline_theme='light'
let g:airline_left_sep = '⮀'
let g:airline_left_alt_sep = '⮁'
let g:airline_right_sep = '⮂'
let g:airline_right_alt_sep = '⮃'
let g:airline_branch_prefix = '⭠'
let g:airline_readonly_symbol = '⭤'
let g:airline_linecolumn_prefix = '⭡'

" ﾊｧﾊｧ...ﾊｧﾊｧ...
NeoBundle 'mattn/hahhah-vim'
NeoBundle 'mattn/vim-airline-hahhah'

" No.2 gcc or C-_でトグル
NeoBundle 'tomtom/tcomment_vim'

" No.3 やっぱりVimはかっこよくなければならない
set t_Co=256
NeoBundle 'tomasr/molokai'
colorscheme molokai

" No.4 カーソルキー使うってやっぱなんか、ありえない？みたいな
NeoBundle 'https://github.com/kazuph/gips-vim.git'

" No.5 ctrlpがないとかどんな苦行
NeoBundle 'kien/ctrlp.vim.git'
let g:ctrlp_map = '<c-f>' " yankringとかぶるんだよ・・・
let g:ctrlp_max_height = &lines
let g:ctrlp_custom_ignore = {
  \ 'dir':  '\v[\/]\.?(local|extlib|git|hg|svn)$',
  \ }

" No.6 ()や''でくくったりするための補助
" text-objectの支援
" di' で'の中身を削除
" da' で'も含めて削df
" cs'" cs"' などと囲っているものに対する操作ができる
" visualモードのときはSを代用
NeoBundle "tpope/vim-surround"

" No.7 テキストオブジェクトを使い倒す
NeoBundle 'kana/vim-operator-user.git'
NeoBundle 'kana/vim-operator-replace.git'
map R  <Plug>(operator-replace)
" キャメルケースをスネークケースに置き換える
" ※Cは元々行末まで置き換えるキー
NeoBundle 'tyru/operator-camelize.vim'
map C <Plug>(operator-camelize-toggle)

" No.9  ","と押して", "としてくれる優しさ
NeoBundle "smartchr"
inoremap <expr> , smartchr#one_of(', ', ',')
autocmd FileType perl inoremap <buffer> <expr> . smartchr#loop('.',  '->')
autocmd FileType perl inoremap <buffer> <expr> = smartchr#loop('=',  '=>')

" No.10 カーソルジェットコースター
NeoBundle 'rhysd/accelerated-jk.git'
let g:accelerated_jk_acceleration_table = [10,5,3]
nmap j <Plug>(accelerated_jk_gj)
nmap k <Plug>(accelerated_jk_gk)

" No.11 ST2のようにテキスト操作
" ctrl+nで選択
NeoBundle 'terryma/vim-multiple-cursors.git'

" No.12 yankを異なるWindow間でも共有したい(screenやtmuxを使う場合に便利)
" MacVimを使ってるならあまり意味ないかも
NeoBundle 'yanktmp.vim'
nnoremap <silent>sy :call YanktmpYank()<CR>
nnoremap <silent>sp :call YanktmpPaste_p()<CR>
nnoremap <silent>sP :call YanktmpPaste_P()<CR>

" No.13 ヤンクの履歴を参照したい
NeoBundle 'kana/vim-fakeclip.git'
NeoBundle 'YankRing.vim'
nnoremap <space><space>y :YRShow<CR>

" No.14 正規表現をPerl風に
" :%S///gc
NeoBundle 'othree/eregex.vim'
" nnoremap / :<C-u>M/

" No.15 memoはやっぱりVimからやろ
NeoBundle 'glidenote/memolist.vim'
nnoremap ,mn :MemoNew<cr>
nnoremap ,mg :MemoGrep<cr>
nnoremap ,ml :MemoList<CR>
nnoremap ,mf :exe "CtrlP" g:memolist_path<cr><f5>
let g:memolist_path = "~/Dropbox/memo"

" No.16 爆速のgrepであるagを使いたい
NeoBundle 'rking/ag.vim'
nnoremap gg/  :<C-u>Ag <C-R><C-w><CR>
vnoremap gg/ y:<C-u>Ag <C-R>"<CR>

" No.17 grep後に置換したい
NeoBundle 'thinca/vim-qfreplace'

" No.18 僕だってtag使ってみたい
NeoBundle 'vim-scripts/taglist.vim'
set tags=./tags,tags,../tags
" let Tlist_Ctags_Cmd = "/usr/local/bin/ctags"  " ctagsのコマンド
let Tlist_Show_One_File = 1
let Tlist_Use_Right_Window = 1
let Tlist_Exit_OnlyWindow = 1
nnoremap <silent> <Space><Space>t :TlistToggle<CR>

" No.17 爆速のgrepであるagを使いたい
NeoBundle 'rking/ag.vim'
nnoremap gg/  :<C-u>Ag <C-R><C-w><CR>
vnoremap gg/ y:<C-u>Ag <C-R>"<CR>

" No.18 賢いf
NeoBundle 'rhysd/clever-f.vim'

" No.19 gitの差分を表示するぜ
NeoBundle 'airblade/vim-gitgutter'
nnoremap <silent> ,gg :<C-u>GitGutterToggle<CR>
nnoremap <silent> ,gh :<C-u>GitGutterLineHighlightsToggle<CR>

" No.20 \rで開いているコードを実行
NeoBundle "thinca/vim-quickrun.git"
let g:quickrun_config            = {}
let g:quickrun_config.markdown   = {
      \   'outputter' : 'null',
      \   'command'   : 'open',
      \   'exec'      : '%c %s',
      \ }

" No.21 Programming perl
NeoBundle "c9s/perlomni.vim"
NeoBundle "mattn/perlvalidate-vim.git"
NeoBundle "petdance/vim-perl"
NeoBundle "y-uuki/perl-local-lib-path.vim"
autocmd FileType perl PerlLocalLibPath
nnoremap ,pt <Esc>:%! perltidy -se<CR>
vnoremap ,pt <Esc>:'<,'>! perltidy -se<CR>

" cpanfile用
NeoBundle 'moznion/vim-cpanfile'
NeoBundle 'moznion/syntastic-cpanfile'

" 全般的に文法チェック
" NeoBundle 'scrooloose/syntastic.git'

" ()や''でくくったりするための補助
" text-objectの支援
" vi' で'の中身を選択
" va' で'も含めて選択 だが
" cs'" cs"' などと囲っているものに対する操作ができる
" visualモードのときはSを代用
NeoBundle "tpope/vim-surround"

" %の拡張
NeoBundle "tmhedberg/matchit.git"

" No.22 APIのドキュメントを参照する
" Shift+K
NeoBundle 'thinca/vim-ref'
let g:ref_open = 'vsplit'
let g:ref_refe_cmd = "rurema"
let g:ref_refe_version = 2

" No.23 Rubyでのコーディングを楽にする
" endを自動挿入
NeoBundleLazy 'alpaca-tc/vim-endwise.git', {
      \ 'autoload' : {
      \   'insert' : 1,
      \ }}

" do endを%移動
NeoBundleLazy 'edsono/vim-matchit', { 'autoload' : {
      \ 'filetypes': ['ruby', 'html'],
      \ }}

" No.24 括弧入力するのだるい時
NeoBundle "kana/vim-smartinput"

" No.25 vimでzencodingする
" Ctrl+y,で展開
NeoBundle "mattn/zencoding-vim.git"
let g:user_zen_settings = { 'indentation' : '    ', }

" No.26 ついに闇の力に手を染めるとき
NeoBundle 'Shougo/vimproc', {
      \ 'build' : {
      \     'mac' : 'make -f make_mac.mak',
      \     'unix' : 'make -f make_unix.mak',
      \    },
      \ }
if has("lua")
  NeoBundleLazy 'Shougo/neocomplete', { 'autoload' : {
        \   'insert' : 1,
        \ }}
else
  NeoBundleLazy 'Shougo/neocomplete', {
        \ 'autoload' : {
        \   'insert' : 1,
        \ },
        \ }
endif
NeoBundleLazy 'Shougo/neosnippet', {
      \ 'autoload' : {
      \   'commands' : ['NeoSnippetEdit', 'NeoSnippetSource'],
      \   'filetypes' : 'snippet',
      \   'insert' : 1,
      \   'unite_sources' : ['snippet', 'neosnippet/user', 'neosnippet/runtime'],
      \ }}

" No.27 すべてを破壊したいあなたに
NeoBundle 'Shougo/unite.vim',  '',  'default'

" No.28 まーくだうん
NeoBundle "tpope/vim-markdown"

" No.29 整列を割と自動でやってくれる
" 例えば:Alignta = で=でそろえてくれる
NeoBundle 'h1mesuke/vim-alignta.git'
xnoremap <silent> a: :Alignta  01 :<CR>
xnoremap al :Alignta<Space>

" No.30 シンタックスチェックを非同期で
" 他vim-quickrunとvimprocに依存
NeoBundle "scrooloose/syntastic"
" NeoBundle "osyo-manga/vim-watchdogs"
" NeoBundle "osyo-manga/shabadou.vim"
" NeoBundle "cohama/vim-hier"
" let g:watchdogs_check_BufWritePost_enable = 1
" " let g:quickrun_config = {
" "       \   'watchdogs_checker/_' : {
" "       \       'outputter/quickfix/open_cmd' : '',
" "       \   }
" "       \ }
" call watchdogs#setup(g:quickrun_config)

" No.31 ゲーム。結構難しい
NeoBundle 'deris/vim-duzzle'

" No.32 CSSのデザインをライブで行う
NeoBundle 'mattn/livestyle-vim'

" No.33 Tag使いになりたい
NeoBundle "majutsushi/tagbar"
nnoremap <C-t> :TagbarToggle<CR>
nnoremap <C-]> g<C-]>

" No.34 選択部分のキーワードを*を押して検索
NeoBundle 'thinca/vim-visualstar'

" No.35 カーソルのある場所でfiletypeを適宜変更する
NeoBundle 'osyo-manga/vim-precious'
NeoBundle 'Shougo/context_filetype.vim'
NeoBundle 'kana/vim-textobj-user'
nmap <Space><Space>q <Plug>(precious-quickrun-op)
omap ic <Plug>(textobj-precious-i)
vmap ic <Plug>(textobj-precious-i)

" No.36 日本語固定モード
NeoBundle 'fuenor/im_control.vim'
"<C-^>でIM制御が行える場合の設定
let IM_CtrlMode = 4
""ctrl+jで日本語入力固定モードをOnOff
inoremap <silent> <C-j> <C-^><C-r>=IMState('FixMode')<CR>"

" No.37 Vimのキーバインドでfiling
NeoBundleLazy 'Shougo/vimfiler', {
\   'autoload' : { 'commands' : [ 'VimFiler' ] },
\   'depends': [ 'Shougo/unite.vim' ],
\ }
let s:bundle = neobundle#get('vimfiler')
function! s:bundle.hooks.on_source(bundle)
  let g:vimfiler_as_default_explorer = 1
  let g:vimfiler_safe_mode_by_default = 0
endfunction
nnoremap ,vf :VimFiler -split -simple -winwidth=35 -no-quit<CR>
autocmd FileType vimfiler
        \ nnoremap <buffer><silent>/
        \ :<C-u>Unite file -default-action=vimfiler<CR>

" もう僕には何が起きてるかわからない
NeoBundleLazy 'Shougo/vimshell', {
\   'autoload' : { 'commands' : [ 'VimShell' ] },
\   'depends': [ 'Shougo/vimproc' ],
\ }
let s:bundle = neobundle#get('vimshell')
function! s:bundle.hooks.on_source(bundle)
endfunction
nnoremap ,vs :VimShell<CR>

" Vimでプレゼンする？
NeoBundle 'thinca/vim-showtime.git'

" 自動でセーブする
NeoBundle 'vim-auto-save'
let g:auto_save = 1

"------------------------------------------------------ unite.vim
let s:bundle = neobundle#get('unite.vim')
function! s:bundle.hooks.on_source(bundle)
  let g:unite_update_time = 1000
  let g:unite_enable_start_insert=1
  let g:unite_source_file_mru_filename_format = ''
  let g:unite_source_grep_default_opts = "-Hn --color=never"
  let g:loaded_unite_source_bookmark = 1
  let g:loaded_unite_source_tab = 1
  let g:loaded_unite_source_window = 1
  " the silver searcher を unite-grep のバックエンドにする
  if executable('ag')
    let g:unite_source_grep_command = 'ag'
    let g:unite_source_grep_default_opts = '--nocolor --nogroup --column'
    let g:unite_source_grep_recursive_opt = ''
    let g:unite_source_grep_max_candidates = 200
  endif

  " ウィンドウを分割して開く
  au FileType unite nnoremap <silent> <buffer> <expr> <C-j> unite#do_action('split')
  au FileType unite inoremap <silent> <buffer> <expr> <C-j> unite#do_action('split')
  " ウィンドウを縦に分割して開く
  au FileType unite nnoremap <silent> <buffer> <expr> <C-l> unite#do_action('vsplit')
  au FileType unite inoremap <silent> <buffer> <expr> <C-l> unite#do_action('vsplit')
  au FileType unite nnoremap <silent> <buffer> <ESC><ESC> q
  au FileType unite inoremap <silent> <buffer> <ESC><ESC> <ESC>q

  autocmd FileType unite call s:unite_my_settings()
  function! s:unite_my_settings()
    " Overwrite settings.
    imap <buffer> jj <Plug>(unite_insert_leave)
    imap <buffer> <ESC> <ESC><ESC>
    imap <buffer> <C-w> <Plug>(unite_delete_backward_path)
    nnoremap <buffer> t G
    startinsert
  endfunction
  call unite#custom_default_action('source/bookmark/directory', 'vimfiler')
endfunction
" ファイル一覧
nnoremap <silent> ,uf :<C-u>UniteWithBufferDir -buffer-name=files file<CR>
" ブックマーク一覧
nnoremap <silent> ,ub :<C-u>Unite bookmark<CR>
" ブックマーク追加
nnoremap <silent> ,ua :<C-u>UniteBookmarkAdd<CR>
" yank一覧
nnoremap <silent> ,uy :<C-u>Unite -buffer-name=register register<CR>
" 常用セット
nnoremap <silent> ,uu :<C-u>Unite buffer file_mru<CR>
" tag
nnoremap <silent> ,ut :Unite tag/include<CR>
" unite-grep
nnoremap <silent> ,ug :Unite -no-quit -winheight=15 grep<CR>
" source
nnoremap <silent> ,us :Unite source<CR>
" ref
nnoremap <silent> ,ur :Unite ref/
" color scheme の変更
nnoremap <silent> ,uc :Unite colorscheme<CR>
" outline表示
nnoremap <silent> ,uo : <C-u>Unite -no-quit -vertical -winwidth=30 outline<CR>
" git status
nnoremap <silent> ,gs :Unite giti/status<CR>
" git log
nnoremap <silent> ,gl :Unite giti/log<CR>

"--------------------------------------------------------------------------
" neocomplate
"--------------------------------------------------------------------------
" Disable AutoComplPop.
let g:acp_enableAtStartup = 0
" Use neocomplete.
let g:neocomplete#enable_at_startup = 1
" Use smartcase.
let g:neocomplete#enable_smart_case = 1
" Set minimum syntax keyword length.
let g:neocomplete#sources#syntax#min_keyword_length = 3
let g:neocomplete#lock_buffer_name_pattern = '\*ku\*'

" for snippets
let g:neosnippet#enable_snipmate_compatibility = 1
let g:neosnippet#snippets_directory='~/.vim/snipmate-snippets/snippets, ~/dotfiles/snippets,  ~/.vim/snipmate-snippets-rubymotion/snippets'

" Define dictionary.
let g:neocomplete#sources#dictionary#dictionaries = {
    \ 'default' : '',
    \ 'vimshell' : $HOME.'/.vimshell_hist',
    \ 'perl'     : $HOME . '/dotfiles/dict/perl.dict',
    \ 'ruby'     : $HOME . '/dotfiles/dict/ruby.dict',
    \ 'scheme'   : $HOME.'/.gosh_completions',
    \ 'cpanfile' : $HOME . '/.vim/bundle/vim-cpanfile/dict/cpanfile.dict'
        \ }

" Define keyword.
if !exists('g:neocomplete#keyword_patterns')
    let g:neocomplete#keyword_patterns = {}
endif
let g:neocomplete#keyword_patterns['default'] = '\h\w*'
let g:neocomplete#keyword_patterns.perl = '\h\w*->\h\w*\|\h\w*::\w*'

" Plugin key-mappings.
inoremap <expr><C-g>     neocomplete#undo_completion()
inoremap <expr><C-l>     neocomplete#complete_common_string()

" Recommended key-mappings.
" <CR>: close popup and save indent.
inoremap <silent> <CR> <C-r>=<SID>my_cr_function()<CR>
function! s:my_cr_function()
  return neocomplete#smart_close_popup() . "\<CR>"
  " For no inserting <CR> key.
  "return pumvisible() ? neocomplete#close_popup() : "\<CR>"
endfunction
" <TAB>: completion.
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
" <C-h>, <BS>: close popup and delete backword char.
inoremap <expr><C-h> neocomplete#smart_close_popup()."\<C-h>"
inoremap <expr><BS> neocomplete#smart_close_popup()."\<C-h>"
inoremap <expr><C-y>  neocomplete#close_popup()
inoremap <expr><C-e>  neocomplete#cancel_popup()

" Enable omni completion.
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags

" Enable heavy omni completion.
if !exists('g:neocomplete#sources#omni#input_patterns')
  let g:neocomplete#sources#omni#input_patterns = {}
endif
let g:neocomplete#sources#omni#input_patterns.php = '[^. \t]->\h\w*\|\h\w*::'
let g:neocomplete#sources#omni#input_patterns.c = '[^.[:digit:] *\t]\%(\.\|->\)'
let g:neocomplete#sources#omni#input_patterns.cpp = '[^.[:digit:] *\t]\%(\.\|->\)\|\h\w*::'
let g:neocomplete#sources#omni#input_patterns.perl = '\h\w*->\h\w*|\h\w*::'
let g:neocomplete#sources#omni#input_patterns.go = '\h\w*\.\?'

" For perlomni.vim setting.
" https://github.com/c9s/perlomni.vim
let g:neocomplete#sources#omni#input_patterns.perl = '\h\w*->\h\w*\|\h\w*::'

" <TAB>: completion.
imap <expr><TAB> pumvisible() ? "\<C-n>" : neosnippet#jumpable() ? "\<Plug>(neosnippet_expand_or_jump)" : "\<TAB>"
smap <expr><TAB> neosnippet#jumpable() ? "\<Plug>(neosnippet_expand_or_jump)" : "\<TAB>"
inoremap <expr><S-TAB>  pumvisible() ? "\<C-p>" : "\<S-TAB>"

" Plugin key-mappings.
imap <C-k>     <Plug>(neosnippet_expand_or_jump)
smap <C-k>     <Plug>(neosnippet_expand_or_jump)

" For snippet_complete marker.
if has('conceal')
  set conceallevel=2 concealcursor=i
endif

" ctags
let g:neocomplcache_ctags_arguments_list = {
  \ 'perl' : '-R -h ".pm"',
  \ }

"--------------------------------------------------------------------------
" No.0 BasicSetting
"--------------------------------------------------------------------------
" ファイル名と内容をもとにファイルタイププラグインを有効にする
filetype plugin indent on
" ハイライトON
syntax on

" ヘルプを3倍の速度で引く
nnoremap <C-h>  :<C-u>help<Space><C-r><C-w><CR>

" 認識されないっぽいファイルタイプを追加
au BufNewFile,BufRead *.psgi       set filetype=perl
au BufNewFile,BufRead *.t          set filetype=perl
au BufNewFile,BufRead *.ejs        set filetype=html
au BufNewFile,BufRead *.ep         set filetype=html
au BufNewFile,BufRead *.pde        set filetype=processing
au BufNewFile,BufRead *.erb        set filetype=html
au BufNewFile,BufRead *.tt         set filetype=html
au BufNewFile,BufRead *.tt2        set filetype=html
au BufNewFile,BufRead *.scss       set filetype=scss
au BufNewFile,BufRead Guardfile    set filetype=ruby
au BufNewFile,BufRead cpanfile     set filetype=perl
au BufRead, BufNewFile jquery.*.js set ft=javascript syntax=jquery

" ファイルエンコーディング
let $LANG='ja_JP.UTF-8'
set encoding=utf-8
set fileencodings=ucs-bom,utf-8,iso-2022-jp,sjis,cp932,euc-jp,cp20932

" 検索語を強調表示
set hlsearch
" 検索時に大文字・小文字を区別しない
set ignorecase
" ただし、検索後に大文字小文字が
" 混在しているときは区別する
set smartcase

" 未保存のバッファでも裏に保持
set hidden

" コマンドラインでの補完候補が表示されるようになる
set wildmenu

" コマンドをステータス行に表示
set showcmd

" オートインデント
set autoindent
set smartindent

" 10進法でインクリメント
set nf=""

" 画面最下行にルーラーを表示する
set ruler

" ステータスラインを常に表示する
set laststatus=2

" Ctrl+eで'paste'と'nopaste'を切り替える
set pastetoggle=<C-e>

set cindent
set tabstop=4
set shiftwidth=4
autocmd FileType apache     setlocal sw=4 sts=4 ts=4 et
autocmd FileType aspvbs     setlocal sw=4 sts=4 ts=4 et
autocmd FileType c          setlocal sw=4 sts=4 ts=4 et
autocmd FileType cpp        setlocal sw=4 sts=4 ts=4 et
autocmd FileType cs         setlocal sw=4 sts=4 ts=4 et
autocmd FileType css        setlocal sw=2 sts=2 ts=2 et
autocmd FileType diff       setlocal sw=4 sts=4 ts=4 et
autocmd FileType eruby      setlocal sw=4 sts=4 ts=4 et
autocmd FileType html       setlocal sw=2 sts=2 ts=2 et
autocmd FileType java       setlocal sw=4 sts=4 ts=4 et
autocmd FileType javascript setlocal sw=2 sts=2 ts=2 et
autocmd FileType coffee     setlocal sw=2 sts=2 ts=2 et
autocmd FileType perl       setlocal sw=4 sts=4 ts=4 et
autocmd FileType php        setlocal sw=4 sts=4 ts=4 et
autocmd FileType python     setlocal sw=4 sts=4 ts=4 et
autocmd FileType ruby       setlocal sw=2 sts=2 ts=2 et
autocmd FileType haml       setlocal sw=2 sts=2 ts=2 et
autocmd FileType sh         setlocal sw=4 sts=4 ts=4 et
autocmd FileType sql        setlocal sw=4 sts=4 ts=4 et
autocmd FileType vb         setlocal sw=4 sts=4 ts=4 et
autocmd FileType vim        setlocal sw=2 sts=2 ts=2 et
autocmd FileType wsh        setlocal sw=4 sts=4 ts=4 et
autocmd FileType xhtml      setlocal sw=2 sts=2 ts=2 et
autocmd FileType xml        setlocal sw=4 sts=4 ts=4 et
autocmd FileType yaml       setlocal sw=2 sts=2 ts=2 et
autocmd FileType zsh        setlocal sw=4 sts=4 ts=4 et
autocmd FileType scala      setlocal sw=2 sts=2 ts=2 et
autocmd FileType scheme     setlocal sw=2 sts=2 ts=2 et

set autoread
set expandtab
set cmdheight=2
set showmode                     " 現在のモードを表示
set modelines=0                  " モードラインは無効
set showmatch
set number
set list
set listchars=tab:»-,trail:-,nbsp:%
set display=uhex
set noimdisableactivate

" 全角スペースの表示
highlight ZenkakuSpace cterm=underline ctermfg=lightblue guibg=darkgray
match ZenkakuSpace /　/

" カーソル行をハイライト
set cursorline
" カレントウィンドウにのみ罫線を引く
augroup cch
  autocmd! cch
  autocmd WinLeave * set nocursorline
  autocmd WinEnter,BufRead * set cursorline
augroup END

hi clear CursorLine
hi CursorLine gui=underline
highlight CursorLine ctermbg=black guibg=black

" コマンド実行中は再描画しない
set lazyredraw

nnoremap <ESC><ESC> :nohlsearch<CR><ESC>

" これで保存やコマンドを速く打てるようになる
" 未設定のVimではもたつくので訓練すること
noremap ; :
noremap : ;

" 保存時に行末の空白を除去する
autocmd BufWritePre * :%s/\s\+$//ge
" 保存時にtabをスペースに変換する
autocmd BufWritePre * :%s/\t/    /ge

" vimgrep検索時に結果一覧を自動的に開く
augroup grepopen
  autocmd!
  autocmd QuickFixCmdPost vimgrep cw
  autocmd QuickFixCmdPost grep cw
augroup END

" quickfixの修正
nnoremap ]q :cnext<CR>
nnoremap [q :cprevious<CR>
nnoremap [Q :<C-u>cfirst<CR>
nnoremap ]Q :<C-u>clast<CR>

" 0で行頭、9で行末
" こういうのは記号じゃなくて数字がいい
nnoremap 0 ^
nnoremap 9 $

"カーソルを表示行で移動する。物理行移動は<C-n>, <C-p>
" 今はaccelerated-jkがあるからいいや
" nnoremap j gj
" nnoremap k gk

" visualmodeでインテントを＞＜の連打で変更できるようにする
vnoremap < <gv
vnoremap > >gv

" ファイルを開いた時に最後のカーソル位置を再現する
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif

" 無限undo
if has('persistent_undo')
  set undodir=~/.vim/undo
  set undofile
endif

" OS依存
" OSのクリップボードを使用する
" set clipboard=unnamed
set clipboard+=unnamedplus,unnamed

" ターミナルでマウスを使用できるようにする
set mouse=a
set guioptions+=a
set ttymouse=xterm2

" テンプレートの設定
autocmd BufNewFile *.rb 0r ~/dotfiles/templates/rb.tpl
autocmd BufNewFile *.pl 0r ~/dotfiles/templates/pl.tpl

" .vimrcを瞬時に開く
nnoremap <Space><Space>. :e $MYVIMRC<CR>

" snippets/perl.snipを瞬時に開く
nnoremap <Space><Space>ps :e $HOME/dotfiles/snippets/perl.snip<CR>
nnoremap <Space><Space>pd :e $HOME/dotfiles/dict/perl.dict<CR>

" snippets/ruby.snipを瞬時に開く
nnoremap <Space><Space>rs :e $HOME/dotfiles/snippets/ruby.snip<CR>
nnoremap <Space><Space>rd :e $HOME/dotfiles/dict/ruby.dict<CR>

" vimrcの設定を反映
nnoremap <Space><Space>.. :<C-u>source $MYVIMRC<CR>

" 念の為C-cでEsc
inoremap <C-c> <Esc>

" 検索語が真ん中に来るようにする
nmap n nzz
nmap N Nzz
nmap * *zz
nmap # #zz
nmap g* g*zz
nmap g# g#zz

" ヘルプを日本語に
set helplang=ja

" カーソル下の単語を置換
nnoremap g/ :<C-u>%s/<C-R><C-w>//gc<Left><Left><Left>

" ビジュアルモードで選択した部分を置換
vnoremap g/ y:<C-u>%s/<C-R>"//gc<Left><Left><Left>

" 行末までをヤンク
nnoremap Y y$

" コマンドモードのマッピング
cmap <C-a> <Home>
cmap <C-b> <Left>
cmap <C-f> <Right>
cmap <C-d> <Del>

" インサートモードのマッピング
inoremap <C-e> <End>
inoremap <C-a> <C-o>^
inoremap <C-f> <Right>
inoremap <C-b> <Left>
inoremap <C-d> <Del>

" バックアップを取らない
set nobackup

" no bell
set vb t_vb=

" :CDでカレントディレクトリを移動する
command! -nargs=? -complete=dir -bang CD  call s:ChangeCurrentDir('<args>', '<bang>')
function! s:ChangeCurrentDir(directory, bang)
  if a:directory == ''
    lcd %:p:h
  else
    execute 'lcd' . a:directory
  endif

  if a:bang == ''
    pwd
  endif
endfunction
nnoremap <silent><Space>cd :<C-u>CD<CR>

