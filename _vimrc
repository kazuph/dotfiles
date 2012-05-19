"------------------------------------
" NeoBundle settings
"------------------------------------
set nocompatible
filetype off
set rtp+=~/dotfiles/neobundle.git/
if has('vim_starting')
    set runtimepath+=~/dotfiles/neobundle.vim
    call neobundle#rc(expand('~/.vim/'))
endif

" 選択部分のキーワードを*を押して検索
NeoBundle 'thinca/vim-visualstar'

" Vimperator風に移動できる
" 実行：\\bで後方へ移動、\\wで前方へ移動
NeoBundle 'Lokaltog/vim-easymotion'

" 簡単にコメントアウトする
" gcc or C-_でトグル
NeoBundle 'tomtom/tcomment_vim'

" エラーチェックする
NeoBundle 'https://github.com/vim-scripts/errormarker.vim.git'
let g:errormarker_errortext = '!!'
let g:errormarker_warningtext = '??'
let g:errormarker_errorgroup = 'Error'
let g:errormarker_warninggroup = 'Warning'
compiler perl
compiler ruby
compiler php
" 保存時にチェックが走る
if !exists('g:flymake_enabled')
    let g:flymake_enabled = 1
    autocmd BufWritePost *.rb, *.pl, *.pm, *.php silent make
endif

" コマンドライン上でWord単位の移動ができるようにする(Emacs風)
NeoBundle 'houtsnip/vim-emacscommandline'
" MacだとAltがMetaKeyとして認識しないので変更
if exists('+macmeta')
    set macmeta
endif

" =と押して = となるようにする他
NeoBundle 'smartchr'
inoremap <expr> = smartchr#loop(' = ', '=', ' == ')
inoremap <expr> , smartchr#one_of(', ', ',')

" お気に入りのMolkaiカラーを使用する
NeoBundle 'molokai'
colorscheme molokai
let g:molokai_original = 1

" インデントに色をつけてわかりやすくする
" NeoBundle 'nathanaelkane/vim-indent-guides'
" let g:indent_guides_enable_on_vim_startup = 1
" let g:indent_guides_color_change_percent = 30
" let g:indent_guides_guide_size = 1

" Shogoさんの力を借りる
NeoBundle 'http://github.com/Shougo/vimproc.git'
NeoBundle 'Shougo/neocomplcache'
NeoBundle 'http://github.com/Shougo/neocomplcache-snippets-complete'
NeoBundle 'http://github.com/Shougo/vimfiler.git'
" デフォルをvimfilerに
let g:vimfiler_as_default_explorer = 1
NeoBundle 'http://github.com/Shougo/vimshell.git'
NeoBundle 'Shougo/unite.vim'

" APIのドキュメントを参照する
NeoBundle 'thinca/vim-ref'

" 正規表現をPerl風に
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
NeoBundle "https://github.com/mattn/zencoding-vim.git"
let g:user_zen_settings = { 'indentation' : '    ', }

" Programming perl
NeoBundle "http://github.com/hotchpotch/perldoc-vim"
NeoBundle "http://github.com/c9s/perlomni.vim"
NeoBundle "http://github.com/mattn/perlvalidate-vim.git"
NeoBundle "petdance/vim-perl"

" ()や''でくくったりするための補助
NeoBundle 'tpope/vim-surround'

" surroundを.で繰り返す
NeoBundle 'repeat.vim'

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

" Define keyword.
if !exists('g:neocomplcache_keyword_patterns')
  let g:neocomplcache_keyword_patterns = {}
endif
let g:neocomplcache_keyword_patterns['default'] = '\h\w*'

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
" バッファ一覧
nnoremap <silent> ,ub :<C-u>Unite buffer_tab<CR>
" レジスタ一覧
nnoremap <silent> ,ur :<C-u>Unite -buffer-name=register register<CR>
" 最近使用したファイル一覧
nnoremap <silent> ,um :<C-u>Unite file_mru<CR>
" 常用セット
nnoremap <silent> ,uu :<C-u>Unite buffer file_mru<CR>
" 全部乗せ
nnoremap <silent> ,ua :<C-u>UniteWithBufferDir -buffer-name=files buffer file_mru bookmark file<CR>

" ウィンドウを分割して開く
au FileType unite nnoremap <silent> <buffer> <expr> <C-j> unite#do_action('split')
au FileType unite inoremap <silent> <buffer> <expr> <C-j> unite#do_action('split')
" ウィンドウを縦に分割して開く
au FileType unite nnoremap <silent> <buffer> <expr> <C-l> unite#do_action('vsplit')
au FileType unite inoremap <silent> <buffer> <expr> <C-l> unite#do_action('vsplit')

autocmd FileType unite call s:unite_my_settings()
function! s:unite_my_settings()
    " Overwrite settings.
    imap <buffer> jj <Plug>(unite_insert_leave)
    imap <buffer> <ESC> <ESC><ESC>
    nnoremap <buffer> t G
    startinsert
endfunction
call unite#custom_default_action('source/bookmark/directory' ,  'vimfiler')

"--------------------------------------------------------------------------BasicSetting
filetype plugin indent on
syntax on
set fileencodings=ucs-bom,utf-8,iso-2022-jp,sjis,cp932,euc-jp,cp20932
set fileencodings=utf-8
set encoding=utf-8
set tabstop=4
set autoindent
set expandtab
set shiftwidth=4
set hlsearch
set number
set cmdheight=2
set mouse=a
set list
set listchars=tab:»-,trail:-,nbsp:%
set t_Co=256
set ttymouse=xterm2
nnoremap <ESC><ESC> :nohlsearch<CR><ESC>
noremap ; :
noremap : ;
au BufNewFile,BufRead *.psgi set filetype=perl
au BufNewFile,BufRead *.ejs set filetype=html
au BufNewFile,BufRead *.pde set filetype=processing
au BufNewFile,BufRead *.erb set filetype=html

" 保存時に行末の空白を除去する
autocmd BufWritePre * :%s/\s\+$//ge
" 保存時にtabをスペースに変換する
autocmd BufWritePre * :%s/\t/    /ge
" vimgrep検索時に結果一覧を自動的に開く
augroup grepopen
    autocmd!
    autocmd QuickFixCmdPost vimgrep cw
augroup END
" CTRL-hjklでウィンドウ移動
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
nnoremap <C-h> <C-w>h

" 数字のインクリメンタルを別にバインド
nmap <C-c> <C-a>

" 0, 9で行頭、行末へ
nmap 0 ^
nmap 9 $

" insert mode での移動
imap  <C-e> <END>
imap  <C-a> <HOME>

" インテントを＞＜の連打で変更できるようにする
vnoremap < <gv
vnoremap > >gv

" ファイルを開いた時に最後のカーソル位置を再現する
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
