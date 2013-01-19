"------------------------------------
" NeoBundle settings
"------------------------------------
set nocompatible
filetype off
filetype plugin indent off
set rtp+=~/dotfiles/neobundle.git/
if has('vim_starting')
  set runtimepath+=~/dotfiles/neobundle.vim
  call neobundle#rc(expand('~/.vim/'))
endif

" NeoBundleをNeoBundleで管理する(非推奨)
" NeoBundle 'Shougo/neobundle.vim'

" 選択部分のキーワードを*を押して検索
NeoBundle 'thinca/vim-visualstar'

" Vimperator風に移動できる
" 実行：\\bで後方へ移動、\\wで前方へ移動
NeoBundle 'Lokaltog/vim-easymotion'
"嫌だったのでspace spaceに変更
let g:EasyMotion_leader_key = '<Space><Space>'

" 簡単にコメントアウトする
" gcc or C-_でトグル
NeoBundle 'tomtom/tcomment_vim'

" エラーチェックする
" 読み込み遅いし保存時に待たされるのでやめた
" perl, rubyは素の状態でもErrorチェックしてくれるみたい
" javascriptとかはJlitとかいれましょう
" rubyは保存時に勝手にチェックしてくれた！
NeoBundle 'scrooloose/syntastic.git'
let g:syntastic_mode_map = { 'mode': 'passive',
      \ 'active_filetypes': ['perl', 'javascript'],
      \ 'passive_filetypes': [] }
let g:syntastic_enable_signs=1
let g:syntastic_auto_loc_list=2
autocmd BufWritePre * :Errors
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

" color shcheme
NeoBundle 'ujihisa/unite-colorscheme'
NeoBundle 'ujihisa/unite-font'
NeoBundle 'tomasr/molokai'
NeoBundle 'altercation/solarized'
colorscheme molokai

" outline機能を試す
NeoBundle 'h1mesuke/unite-outline'
NeoBundle 'VOoM'

" Shogoさんの力を借りる
NeoBundle 'Shougo/vimproc', {
      \     'build': {
      \        'windows': 'make_mingw64.mak',
      \        'unix': 'make -f make_unix.mak',
      \        'mac': 'make -f make_mac.mak'
      \     }
      \   }

NeoBundle 'Shougo/neocomplcache'
NeoBundle 'tsukkee/unite-tag.git'
autocmd BufEnter *
\   if empty(&buftype)
\|      nnoremap <buffer> <C-]> :<C-u>UniteWithCursorWord -immediately tag<CR>
\|  endif
NeoBundle 'Shougo/neosnippet'
NeoBundle 'honza/snipmate-snippets.git'

NeoBundle 'Shougo/vimfiler.git'
let g:vimfiler_as_default_explorer = 1
nnoremap ,vf :VimFiler -split -simple -winwidth=35 -no-quit<CR>
let g:vimfiler_safe_mode_by_default = 0

" Uniteでファイル検索
autocmd FileType vimfiler
        \ nnoremap <buffer><silent>/
        \ :<C-u>Unite file -default-action=vimfiler<CR>

NeoBundle 'Shougo/vimshell.git'
nnoremap ,vs :VimShell<CR>

NeoBundle 'Shougo/unite.vim'
NeoBundle 'Sixeight/unite-grep.git'
NeoBundle 'thinca/vim-qfreplace.git'

" 別にいらないけど入れてみた。いらなかった。
" NeoBundle 'ack.vim'
set grepprg=ack\ -a

" APIのドキュメントを参照する
" Shift+K
NeoBundle 'thinca/vim-ref'

" 正規表現をPerl風に
" :%S///gc
NeoBundle 'othree/eregex.vim'
nnoremap / :M/

" ヤンクを辿れるようにする
NeoBundle "YankRing.vim"
let g:yankring_manual_clipboard_check = 0
let g:yankring_max_history = 30
let g:yankring_max_display = 70
" Yankの履歴参照
nmap ,y ;YRShow<CR>

" 英語の補完を行う
NeoBundle 'ujihisa/neco-look.git'

" \rで開いているコードを実行
NeoBundle "thinca/vim-quickrun.git"
" for quickrun.vim
let g:quickrun_config = {
      \   'objc': {
      \     'command': 'clang',
      \     'exec': ['%c %s -o %s:p:r -framework Foundation', '%s:p:r %a', 'rm -f %s:p:r'],
      \     'tempfile': '{tempname()}.m',
      \   }
      \ }

" VimからRSecを実行する
NeoBundle "skwp/vim-rspec.git"
" let g:RspecKeyma,=0
nnoremap <silent> ,rs :RunSpec<CR>
nnoremap <silent> ,rl :RunSpecLine<CR>

" vimでzencodingする
" Ctrl+y,
NeoBundle "mattn/zencoding-vim.git"
let g:user_zen_settings = { 'indentation' : '    ', }

" Programming perl
NeoBundle "vim-perl/vim-perl.git"
NeoBundle "c9s/perlomni.vim"
NeoBundle "mattn/perlvalidate-vim.git"
NeoBundle "petdance/vim-perl"
NeoBundle "y-uuki/unite-perl-module.vim"
NeoBundle "y-uuki/perl-local-lib-path.vim"
autocmd FileType perl PerlLocalLibPath

" ()や''でくくったりするための補助
" text-objectの支援
" vi' で'の中身を選択
" va' で'も含めて選択 だが
" cs'" cs"' などと囲っているものに対する操作ができる
" visualモードのときはSを代用
NeoBundle "tpope/vim-surround"

" %の拡張
NeoBundle "tmhedberg/matchit.git"

" =と押して = となるようにする他
NeoBundle "smartchr"
" inoremap <expr> = smartchr#loop(' = ', '=', ' == ')
inoremap <expr> , smartchr#one_of(', ', ',')

" 色々な入力補助
NeoBundle "kana/vim-smartinput.git"

" endfunction とかを自動入力
NeoBundle 'tpope/vim-endwise'

" 前回の操作を.で繰り返す
NeoBundle 'repeat.vim'

" HatenaをVimから投稿
NeoBundle 'motemen/hatena-vim'
let g:hatena_user = 'kazuph1986'

" Ruby環境
NeoBundle 'vim-ruby/vim-ruby.git'
NeoBundle 'tpope/vim-rails.git'
NeoBundle 'taichouchou2/vim-rsense'
let g:rubycomplete_buffer_loading = 1
let g:rubycomplete_classes_in_global = 1
let g:rubycomplete_rails = 1
imap <C-o> <C-x><C-o>

" Vimでプレゼンする？
NeoBundle 'thinca/vim-showtime.git'

" undo treeを表示する
NeoBundle 'sjl/gundo.vim.git'
nnoremap <F5> :GundoToggle<CR>

" 整列を割と自動でやってくれる
" 例えば:Alignta = で=でそろえてくれる
NeoBundle 'h1mesuke/vim-alignta.git'
set ambiwidth=double
xnoremap <silent> a: :Alignta  01 :<CR>
xnoremap al :Alignta<Space>

" キャメル・アンダースコア記法を扱いやすく
" ,w ,e ,b
" v,w
" d,w
NeoBundle 'bkad/CamelCaseMotion.git'
map w ,w
map e ,e
map b ,b

" ステータスラインをかっこ良く
NeoBundle 'Lokaltog/vim-powerline'

" ステータスラインでハァハァしたかったからやった。後悔はしていない。
NeoBundle 'mattn/hahhah-vim.git'

" vimからgitをいじる
NeoBundle 'kmnk/vim-unite-giti.git'

" svnコミット時にDiffを出す
NeoBundle 'svn.vim'

" 読み込みの遅延を測定する
" 以下で実行
" :BenchVimrc
NeoBundle 'mattn/benchvimrc-vim.git'

" HTML5
NeoBundle 'othree/html5.vim.git'

" テキストオブジェクトで置換
NeoBundle 'kana/vim-operator-replace.git'
NeoBundle 'kana/vim-operator-user.git'
map R  <Plug>(operator-replace)

" ファイルを曖昧文字から探し出す
NeoBundle 'kien/ctrlp.vim.git'
let g:ctrlp_custom_ignore = {
  \ 'dir':  '\v[\/]\.?(extlib|git|hg|svn)$',
  \ }

" メモを簡単に取る
NeoBundle 'glidenote/memolist.vim'
let g:memolist_path = $HOME . "/Dropbox/アプリ/memolist"
let g:memolist_qfixgrep = 1
nnoremap <silent> ,mn :MemoNew<CR>
nnoremap <silent> ,ml :MemoList<CR>
nnoremap <silent> ,mg :MemoGrep<CR>
nnoremap <silent> ,mf :exe "CtrlP" g:memolist_path<cr><f5>

" grep結果をプレビュー付きで表示
NeoBundle 'fuenor/qfixgrep.git'
let MyGrep_Key = ''
let QFix_Height = 10

" DayOne投稿用(開発中)
NeoBundle 'kazuph/dayone.vim'
nnoremap <silent> ,dn :DayOneNew<CR>
nnoremap <silent> ,dl :DayOneList<CR>
nnoremap <silent> ,dg :DayOneGrep<CR>

" RubyMotionの設定
NeoBundle 'rcyrus/snipmate-snippets-rubymotion.git'

" Haskell
NeoBundle 'haskell.vim'
NeoBundle 'dag/vim2hs.git'
NeoBundle 'eagletmt/ghcmod-vim.git'
NeoBundle 'ujihisa/neco-ghc.git'

"-------------------------------------------------------------------setting neocomplcache
" Disable AutoComplPop.
let g:acp_enableAtStartup = 0
" Use neocomplcache.
let g:neocomplcache_enable_at_startup = 1
" Use smartcase.
let g:neocomplcache_enable_smart_case = 1
" Use camel case completion.
let g:neocomplcache_enable_camel_case_completion = 1
" Use underbar completion.
let g:neocomplcache_enable_underbar_completion = 1
" Set minimum syntax keyword length.
let g:neocomplcache_min_syntax_length = 3
let g:neocomplcache_lock_buffer_name_pattern = '\*ku\*'

" let g:neosnippet#snippets_directory='~/dotfiles/snippets'
let g:neosnippet#snippets_directory='~/.vim/snipmate-snippets/snippets, ~/dotfiles/snippets,  ~/.vim/snipmate-snippets-rubymotion/snippets'

" Define dictionary.
let g:neocomplcache_dictionary_filetype_lists = {
      \ 'default' : '',
      \ 'vimshell' : $HOME.'/.vimshell_hist',
      \ 'perl'     : $HOME . '/dotfiles/dict/perl.dict',
      \ 'ruby'     : $HOME . '/dotfiles/dict/ruby.dict',
      \ 'scheme'   : $HOME.'/.gosh_completions'
      \ }

" Define keyword.
if !exists('g:neocomplcache_keyword_patterns')
  let g:neocomplcache_keyword_patterns = {}
endif
let g:neocomplcache_keyword_patterns['default'] = '\h\w*'

" Plugin key-mappings.
inoremap <expr><C-g>     neocomplcache#undo_completion()
inoremap <expr><C-l>     neocomplcache#complete_common_string()

" Recommended key-mappings.
" <CR>: close popup and save indent.
inoremap <expr><CR>  neocomplcache#close_popup() . "\<CR>"
" <TAB>: completion.
" inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
inoremap <expr><S-TAB>  pumvisible() ? "\<C-p>" : "\<S-TAB>"
" <C-h>, <BS>: close popup and delete backword char.
inoremap <expr><C-h> neocomplcache#smart_close_popup()."\<C-h>"
inoremap <expr><BS> neocomplcache#smart_close_popup()."\<C-h>"
inoremap <expr><C-y>  neocomplcache#close_popup()
inoremap <expr><C-e>  neocomplcache#cancel_popup()

" Enable omni completion.
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
" autocmd FileType ruby setlocal omnifunc=rubycomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags

" rubyの設定
" if !exists('g:neocomplcache_omni_functions')
"   let g:neocomplcache_omni_functions = {}
" endif
" let g:neocomplcache_omni_functions.ruby = 'RSenseCompleteFunction'

" Enable heavy omni completion.
if !exists('g:neocomplcache_omni_patterns')
  let g:neocomplcache_omni_patterns = {}
endif
" let g:neocomplcache_omni_patterns.ruby = '[^. *\t]\.\h\w*\|\h\w*::'
"autocmd FileType ruby setlocal omnifunc=rubycomplete#Complete
let g:neocomplcache_omni_patterns.php = '[^. \t]->\h\w*\|\h\w*::'
let g:neocomplcache_omni_patterns.c = '\%(\.\|->\)\h\w*'
let g:neocomplcache_omni_patterns.cpp = '\h\w*\%(\.\|->\)\h\w*\|\h\w*::'
" let g:neocomplcache_omni_patterns.ruby = '[^. *\t]\.\w*\|\h\w*::'

" Plugin key-mappings.
imap <C-k>     <Plug>(neosnippet_expand_or_jump)
smap <C-k>     <Plug>(neosnippet_expand_or_jump)

" SuperTab like snippets behavior.
imap <expr><TAB> neosnippet#jumpable() ? "\<Plug>(neosnippet_expand_or_jump)" : pumvisible() ? "\<C-n>" : "\<TAB>"
smap <expr><TAB> neosnippet#jumpable() ? "\<Plug>(neosnippet_expand_or_jump)" : "\<TAB>"

" For snippet_complete marker.
if has('conceal')
  set conceallevel=2 concealcursor=i
endif

"------------------------------------------------------ unite.vim
let g:unite_update_time = 1000
" 入力モードで開始する
let g:unite_enable_start_insert=1
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
" unite-grep
nnoremap <silent> ,ug :Unite grep<CR>
" source
nnoremap <silent> ,us :Unite source<CR>
" ref
nnoremap <silent> ,ur :Unite ref/
" color scheme の変更
nnoremap <silent> ,uc :Unite colorscheme<CR>
" outline表示
nnoremap <silent> ,uo :Unite outline<CR>
" giti表示
nnoremap <silent> ,ug :Unite giti<CR>
" status
nnoremap <silent> ,gs :Unite giti/status<CR>
" log
nnoremap <silent> ,gl :Unite giti/log<CR>

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

"--------------------------------------------------------------------------
" BasicSetting
"--------------------------------------------------------------------------
" ファイル名と内容をもとにファイルタイププラグインを有効にする
filetype plugin indent on
" ハイライトON
syntax on
" 認識されないっぽいファイルタイプを追加
au BufNewFile,BufRead *.psgi set filetype=perl
au BufNewFile,BufRead *.ejs set filetype=html
au BufNewFile,BufRead *.ep set filetype=html
au BufNewFile,BufRead *.pde set filetype=processing
au BufNewFile,BufRead *.erb set filetype=html
au BufNewFile,BufRead *.tt set filetype=html
au BufNewFile,BufRead *.tt2 set filetype=html
au BufRead, BufNewFile *.scss set filetype=scss

" ファイルエンコーディング
set fileencodings=ucs-bom,utf-8,iso-2022-jp,sjis,cp932,euc-jp,cp20932
set encoding=utf-8
" 未保存のバッファでも裏に保持
set hidden
" コマンドラインでの補完候補が表示されるようになる
set wildmenu
" コマンドをステータス行に表示
set showcmd
" 検索語を強調表示
set hlsearch
" 検索時に大文字・小文字を区別しない。ただし、検索後に大文字小文字が
" 混在しているときは区別する
set ignorecase
set smartcase
" オートインデント
set autoindent
set smartindent

" 画面最下行にルーラーを表示する
set ruler

" ステータスラインを常に表示する
set laststatus=2

" <F11>キーで'paste'と'nopaste'を切り替える
set pastetoggle=<F11>

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
autocmd FileType xhtml      setlocal sw=4 sts=4 ts=4 et
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
set t_Co=256

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

" CTRL-hjklでウィンドウ移動
nnoremap 0 ^
nnoremap 9 $

"カーソルを表示行で移動する。物理行移動は<C-n>, <C-p>
nnoremap j gj
nnoremap k gk

" スクロールしても常にカーソルが中央にあるようにする
" 飽きた
" set scrolloff=1000

" visualmodeでインテントを＞＜の連打で変更できるようにする
vnoremap < <gv
vnoremap > >gv

" インサートモード中に抜け出す
inoremap jj <Esc><Esc>
inoremap kk <Esc><Esc>

" ファイルを開いた時に最後のカーソル位置を再現する
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif

" 無限undo
if has('persistent_undo')
  set undodir=~/.vim/undo
  set undofile
endif

" OS依存
" OSのクリップボードを使用する
set clipboard+=unnamed

" ターミナルでマウスを使用できるようにする
set mouse=a
set guioptions+=a
set ttymouse=xterm2

" テンプレートの設定
autocmd BufNewFile *.rb 0r ~/dotfiles/templates/rb.tpl
autocmd BufNewFile *.pl 0r ~/dotfiles/templates/pl.tpl

" .vimrcを瞬時に開く
nnoremap <Space><Space>. :sp $MYVIMRC<CR>

" vimrcの設定を反映
nnoremap <Space><Space>.. :<C-u>source $MYVIMRC<CR>

" 念の為C-cでEsc
inoremap <C-c> <Esc>

" vimscriptのリロード
" nnoremap <silent> <Space>r :<C-u>execute "source " expand("%:p")<CR>

" テキスト全選択
nnoremap <silent> <S-C-a> gg<S-v>G

" 検索語が真ん中に来るようにする
nmap n nzz
nmap N Nzz
nmap * *zz
nmap # #zz
nmap g* g*zz
nmap g# g#zz

" ヘルプを3倍の速度で引く
nnoremap <C-h>  :<C-u>help<Space><C-r><C-w><CR>

" ヘルプを日本語に
set helplang=ja

" カーソル以下の単語を置換
nnoremap g/ :<C-u>%s/\<<C-R><C-w>\>//gc<Left><Left><Left>

" ビジュアルモードで選択した部分を置換
vnoremap g/ y:<C-u>%s/\<<C-R>"\>//gc<Left><Left><Left>"

" スムーススクロール
" let s:scroll_time_ms = 100
" let s:scroll_precision = 8
" function! CohamaSmoothScroll(dir, windiv, factor)
"   let cl = &cursorline
"   set nocursorline
"   let height = winheight(0) / a:windiv
"   let n = height / s:scroll_precision
"   if n <= 0
"     let n = 1
"   endif
"   let wait_per_one_move_ms = s:scroll_time_ms / s:scroll_precision * a:factor
"   let i = 0
"   let scroll_command = a:dir == "down" ?
"         \ "normal " . n . "\<C-E>" . n ."j" :
"         \ "normal " . n . "\<C-Y>" . n ."k"
"   while i < s:scroll_precision
"     let i = i + 1
"     execute scroll_command
"     execute "sleep " . wait_per_one_move_ms . "m"
"     redraw
"   endwhile
"   let &cursorline = cl
"   echo "My Smooth Scroll"
" endfunction
" nnoremap <silent> <C-d> :call CohamaSmoothScroll("down", 2, 1)<CR>
" nnoremap <silent> <C-u> :call CohamaSmoothScroll("up", 2, 1)<CR>
" nnoremap <silent> <C-f> :call CohamaSmoothScroll("down", 1, 2)<CR>
" nnoremap <silent> <C-b> :call CohamaSmoothScroll("up", 1, 2)<CR>

" 行末までをヤンク
nmap Y y$

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


