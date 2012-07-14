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
" NeoBundleをNeoBundleで管理する
NeoBundle 'Shougo/neobundle.vim'

" 選択部分のキーワードを*を押して検索
NeoBundle 'thinca/vim-visualstar'

" Vimperator風に移動できる
" 実行：\\bで後方へ移動、\\wで前方へ移動
NeoBundle 'Lokaltog/vim-easymotion'
"嫌だったのでspace spaceに変更
let g:EasyMotion_leader_key  =  '<Space><Space>'

" 簡単にコメントアウトする
" gcc or C-_でトグル
NeoBundle 'tomtom/tcomment_vim'

" エラーチェックする
" perl, rubyは素の状態でもErrorチェックしてくれるみたい
" javascriptとかはJlitとかいれましょう
" rubyは保存時に勝手にチェックしてくれた！
NeoBundle 'https://github.com/scrooloose/syntastic.git'
compiler ruby
compiler perl
let g:syntastic_mode_map = { 'mode': 'passive',
                           \ 'active_filetypes': ['perl', 'ruby', 'javascript'],
                           \ 'passive_filetypes': [] }
let g:syntastic_enable_signs=1
let g:syntastic_auto_loc_list=2
autocmd BufWritePre * :Errors
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

" お気に入りのMolkaiカラーを使用する
NeoBundle 'molokai'
colorscheme molokai
let g:molokai_original = 1

" Shogoさんの力を借りる
" NeoBundleInstall 後に.vim/vimprocディレクトリで
" Mac  : $ make -f make_mac.mak
" Linux: $ make -f make_unix.mak
NeoBundle 'http://github.com/Shougo/vimproc.git'
NeoBundle 'Shougo/neocomplcache'
NeoBundle 'http://github.com/Shougo/neocomplcache-snippets-complete'
NeoBundle 'http://github.com/Shougo/vimfiler.git'

" デフォルトをvimfilerに
let g:vimfiler_as_default_explorer = 1
NeoBundle 'http://github.com/Shougo/vimshell.git'
NeoBundle 'Shougo/unite.vim'
NeoBundle 'Sixeight/unite-grep.vim'
set grepprg=ack\ -a
NeoBundle 'https://github.com/thinca/vim-qfreplace.git'

" APIのドキュメントを参照する
" Shift+K
NeoBundle 'thinca/vim-ref'

" 正規表現をPerl風に
" :%S///gc
NeoBundle 'http://github.com/othree/eregex.vim'
nnoremap / :M/

" ヤンクを辿れるようにする
NeoBundle "YankRing.vim"
let g:yankring_manual_clipboard_check = 0
let g:yankring_max_history = 30
let g:yankring_max_display = 70
" Yankの履歴参照
nmap ,y ;YRShow<CR>

" 英語の補完を行う
NeoBundle 'http://github.com/ujihisa/neco-look.git'

" \yで開いているコードを実行
NeoBundle "http://github.com/thinca/vim-quickrun.git"

" vimでzencodingする
" Ctrl+y,
NeoBundle "https://github.com/mattn/zencoding-vim.git"
let g:user_zen_settings = { 'indentation' : '    ', }

" Programming perl
NeoBundle "http://github.com/hotchpotch/perldoc-vim"
NeoBundle "http://github.com/c9s/perlomni.vim"
NeoBundle "http://github.com/mattn/perlvalidate-vim.git"
NeoBundle "petdance/vim-perl"

" ()や''でくくったりするための補助
" text-objectの支援
" vi' で'の中身を選択
" va' で'も含めて選択 だが
" cs'" cs"' などと囲っているものに対する操作ができる
" visualモードのときはSを代用
NeoBundle "tpope/vim-surround"

" %の拡張
NeoBundle "https://github.com/tmhedberg/matchit.git"

" =と押して = となるようにする他
NeoBundle "smartchr"
" inoremap <expr> = smartchr#loop(' = ', '=', ' == ')
inoremap <expr> , smartchr#one_of(', ', ',')

" 前回の操作を.で繰り返す
NeoBundle 'repeat.vim'

" HatenaをVimから投稿
NeoBundle 'motemen/hatena-vim'
let g:hatena_user = 'kazuph1986'

" Matrix
NeoBundle 'https://github.com/vim-scripts/matrix.vim--Yang.git'

" Ruby環境
NeoBundle 'https://github.com/vim-ruby/vim-ruby.git'
NeoBundle 'https://github.com/tpope/vim-rails.git'

" Vimでプレゼンする？
NeoBundle 'https://github.com/thinca/vim-showtime.git'

" node tree
NeoBundle 'https://github.com/scrooloose/nerdtree.git'
NeoBundle 'jistr/vim-nerdtree-tabs'
map <Space>n <plug>NERDTreeTabsToggle<CR>

" Date型のままインクリメント/デクリメント
NeoBundle 'speeddatin.vim'

" html
NeoBundle 'html5.vim'
NeoBundle 'hail2u/vim-css3-syntax'
NeoBundle 'cakebaker/scss-syntax.vim'

" cssのカラーコードをその色でハイライトして表示
NeoBundle 'css_color.vim'

" undo treeを表示する
NeoBundle 'https://github.com/sjl/gundo.vim.git'
nnoremap <F5> :GundoToggle<CR>

" 整列を割と自動でやってくれる
" 例えば:Alignta = で=でそろえてくれる
NeoBundle 'https://github.com/h1mesuke/vim-alignta.git'
set ambiwidth=double
xnoremap <silent> a: :Alignta  01 :<CR>
xnoremap al :Alignta<Space>

" キャメル・アンダースコア記法を扱いやすく
" ,w ,e ,b
" v,w
" d,w
NeoBundle 'https://github.com/bkad/CamelCaseMotion.git'

" 括弧とか勝手に閉じてくれる
" NeoBundle 'AutoClose'

"-------------------------------------------------------------------setting neocomplcache
" AutoComplPopの補完を無効にする（インストールしてないなら無意味）
let g:acp_enableAtStartup = 0
" neocomplcacheを使う
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

" 辞書定義
let g:neocomplcache_dictionary_filetype_lists = {
    \ 'default'  : '',
    \ 'vimshell' : $HOME.'/.vimshell_hist',
    \ 'perl'     : $HOME . '/.vim/dict/perl.dict',
    \ 'scheme'   : $HOME.'/.gosh_completions'
        \ }

" SuperTab like snippets behavior.
imap <expr><TAB> neocomplcache#sources#snippets_complete#expandable() ? "\<Plug>(neocomplcache_snippets_expand)" : pumvisible() ? "\<C-n>" : "\<TAB>"

" Recommended key-mappings.
" <CR>: close popup and save indent.
inoremap <expr><CR>  neocomplcache#smart_close_popup() . "\<CR>"
" <TAB>: completion.
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
inoremap <expr><S-TAB>  pumvisible() ? "\<C-p>" : "\<S-TAB>"
" <C-h>, <BS>: close popup and delete backword char.
inoremap <expr><C-h> neocomplcache#smart_close_popup()."\<C-h>"
inoremap <expr><BS> neocomplcache#smart_close_popup()."\<C-h>"
inoremap <expr><C-y>  neocomplcache#close_popup()
inoremap <expr><C-e>  neocomplcache#cancel_popup()
let g:neocomplcache_snippets_dir = "~/.vim/snippets"

" Define keyword.
if !exists('g:neocomplcache_keyword_patterns')
    let g:neocomplcache_keyword_patterns = {}
endif
let g:neocomplcache_keyword_patterns['default'] = '\h\w*'

" for snippets
imap <expr><C-k> neocomplcache#sources#snippets_complete#expandable() ? "\<Plug>(neocomplcache_snippets_expand)" : "\<C-n>"
smap <C-k> <Plug>(neocomplcache_snippets_expand)

" <TAB>: completion.
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
inoremap <expr><S-TAB>  pumvisible() ? "\<C-p>" : "\<S-TAB>"

" Enable omni completion.
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
" autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
" autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags

" Enable heavy omni completion.
if !exists('g:neocomplcache_omni_patterns')
  let g:neocomplcache_omni_patterns = {}
endif
let g:neocomplcache_omni_patterns.php = '[^. \t]->\h\w*\|\h\w*::'

"----------------------------------------------------------------------------- unite.vim
let g:unite_update_time = 1000
" 入力モードで開始する
let g:unite_enable_start_insert=1
" ファイル一覧
nnoremap <silent> ,uf :<C-u>UniteWithBufferDir -buffer-name=files file<CR>
" 最近使用したファイル一覧
nnoremap <silent> ,um :<C-u>Unite file_mru<CR>
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
" 全部乗せ
" nnoremap <silent> ,ua :<C-u>UniteWithBufferDir -buffer-name=files buffer file_mru bookmark file<CR>

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
call unite#custom_default_action('source/bookmark/directory' ,  'vimfiler')

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
au BufNewFile,BufRead *.pde set filetype=processing
au BufNewFile,BufRead *.erb set filetype=html
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
" 高速ターミナル接続を行う
set ttyfast

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
" nnoremap <C-j> <C-w>j
" nnoremap <C-k> <C-w>k
" nnoremap <C-l> <C-w>l
" nnoremap <C-h> <C-w>h

"カーソルを表示行で移動する。物理行移動は<C-n>, <C-p>
nnoremap j gj
nnoremap k gk

" visualmodeでインテントを＞＜の連打で変更できるようにする
vnoremap < <gv
vnoremap > >gv

" ファイルを開いた時に最後のカーソル位置を再現する
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif

" OS依存
" OSのクリップボードを使用する
set clipboard+=unnamed
" ターミナルでマウスを使用できるようにする
set mouse=a
set guioptions+=a
set ttymouse=xterm2

"ヤンクした文字は、システムのクリップボードに入れる"
set clipboard=unnamed
