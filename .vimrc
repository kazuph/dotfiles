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
let s:goroot=substitute(system("go env GOROOT"),"\n", "", "g") . "/misc/vim"
if s:goroot != ''
  exe "set runtimepath+=".globpath("/", s:goroot)
  set rtp+=$GOPATH/src/github.com/golang/lint/misc/vim
endif

set rtp+=~/dotfiles/neobundle.git/
if has('vim_starting')
  set runtimepath+=~/dotfiles/neobundle.vim
  call neobundle#rc(expand('~/.vim/'))
endif

" NeoBundle自体の管理
NeoBundleFetch 'Shougo/neobundle.vim'

" ステータスラインに情報を表示 → もう力はいらない
NeoBundle 'Lokaltog/vim-powerline.git'
NeoBundle 'bling/vim-airline'
let g:airline_theme='light'
let g:airline_left_sep = '⮀'
let g:airline_left_alt_sep = '⮁'
let g:airline_right_sep = '⮂'
let g:airline_right_alt_sep = '⮃'
let g:airline_branch_prefix = '⭠'
let g:airline_readonly_symbol = '⭤'
let g:airline_linecolumn_prefix = '⭡'
"
" " ﾊｧﾊｧ...ﾊｧﾊｧ...
NeoBundle 'mattn/hahhah-vim'
" NeoBundle 'mattn/vim-airline-hahhah'

" gcc or C-_でトグル
NeoBundle 'tomtom/tcomment_vim'

" やっぱりVimはかっこよくなければならない
set t_Co=256
NeoBundle 'tomasr/molokai'
colorscheme molokai

" ctrlpでいいと思う
NeoBundle 'kien/ctrlp.vim.git'
let g:ctrlp_map = '<c-f>' " yankringとかぶるので・・・
let g:ctrlp_max_height = &lines
set wildignore+=*/tmp/*,*.so,*.swp,*.zip
let g:ctrlp_custom_ignore = {
  \ 'dir':  '\v[\/]\.?(local|extlib|git|hg|svn|bundle|node_modules)$',
  \ }

" 依存が少ないyankringらしい
NeoBundle 'LeafCage/yankround.vim'
nmap p <Plug>(yankround-p)
nmap P <Plug>(yankround-P)
nmap <C-p> <Plug>(yankround-prev)
nmap <C-n> <Plug>(yankround-next)
let g:yankround_max_history = 100
nnoremap <Space><Space>y :<C-u>CtrlPYankRound<CR>

" ()や''でくくったりするための補助
" text-objectの支援
" di' で'の中身を削除
" da' で'も含めて削df
" cs'" cs"' などと囲っているものに対する操作ができる
" visualモードのときはSを代用
NeoBundle "tpope/vim-surround"

" テキストオブジェクトを使い倒す
NeoBundle 'kana/vim-operator-user.git'

" Rを使ってyankしてるものと置き換え
NeoBundle 'kana/vim-operator-replace.git'
map R  <Plug>(operator-replace)

"  ","と押して", "としてくれる優しさ
NeoBundle "smartchr"
inoremap <expr> , smartchr#one_of(', ', ',')
autocmd FileType perl inoremap <buffer> <expr> . smartchr#loop('.',  '->')
autocmd FileType perl inoremap <buffer> <expr> = smartchr#loop('=',  '=>', '==')

" カーソルジェットコースター
NeoBundle 'rhysd/accelerated-jk.git'
let g:accelerated_jk_acceleration_table = [10,5,3]
nmap j <Plug>(accelerated_jk_gj)
nmap k <Plug>(accelerated_jk_gk)

" ヤンクの履歴を参照したい
NeoBundle 'kana/vim-fakeclip.git'

" 正規表現をPerl風に
" :%S///gc
NeoBundle 'kazuph/eregex.vim'
nnoremap / :<C-u>M/

" memoはやっぱりVimからやろ
NeoBundle 'glidenote/memolist.vim'
nnoremap ,mn :MemoNew<cr>
nnoremap ,mg :MemoGrep<cr>
nnoremap ,ml :MemoList<CR>
nnoremap ,mf :exe "CtrlP" g:memolist_path<cr><f5>
let g:memolist_path = "~/Dropbox/memo"

" 爆速のgrepであるagを使いたい
NeoBundle 'rking/ag.vim'
nnoremap gg/  :<C-u>Ag <C-R><C-w><CR>
vnoremap gg/ y:<C-u>Ag <C-R>"<CR>

" grep後に置換したい
" gg/したあとにQf<TAB>後、編集、保存で一括置換
NeoBundle 'thinca/vim-qfreplace'

" 僕だってtag使ってみたい
" NeoBundle 'szw/vim-tags'
" let g:vim_tags_project_tags_command = "/usr/local/bin/ctags -R {OPTIONS} {DIRECTORY} 2>/dev/null"
" let g:vim_tags_gems_tags_command = "/usr/local/bin/ctags -R {OPTIONS} `bundle show --paths` 2>/dev/null"

NeoBundle 'vim-scripts/taglist.vim'
set tags=./tags,tags,../tags
let Tlist_Show_One_File = 1
let Tlist_Use_Right_Window = 1
let Tlist_Exit_OnlyWindow = 1
nnoremap <silent> <Space><Space>t :TlistToggle<CR>

NeoBundle "majutsushi/tagbar"
nnoremap <C-t> :TagbarToggle<CR>
nnoremap <C-]> g<C-]>

" 賢いf
" NeoBundle 'rhysd/clever-f.vim'

" gitの差分を表示するぜ
" NeoBundle 'airblade/vim-gitgutter'
" nnoremap <silent> ,gg :<C-u>GitGutterToggle<CR>
" nnoremap <silent> ,gh :<C-u>GitGutterLineHighlightsToggle<CR>

" \rで開いているコードを実行
NeoBundle "thinca/vim-quickrun.git"
let g:quickrun_config            = {}
let g:quickrun_config.markdown   = {
      \   'outputter' : 'null',
      \   'command'   : 'open',
      \   'exec'      : '%c %s',
      \ }

let g:quickrun_config.c   = {
      \   "outputter" : "error:buffer:quickfix",
      \   "runner" : "vimproc",
      \   'command'   : './make',
      \   'exec'      : '%c %s:t:r-BCM920736TAG_Q32 download',
      \ }

" CSは実行せずにJSにコンパイル
let g:quickrun_config.coffee = {'command' : 'coffee',  'exec' : ['%c -cbp %s']}

" Programming perl
" NeoBundle "c9s/perlomni.vim"
" NeoBundle "mattn/perlvalidate-vim.git"
" NeoBundle "vim-perl/vim-perl"
" NeoBundle "y-uuki/perl-local-lib-path.vim"
" autocmd FileType perl PerlLocalLibPath
" nnoremap ,pt <Esc>:%! perltidy -se<CR>
" vnoremap ,pt <Esc>:'<,'>! perltidy -se<CR>

" Rubyでのコーディングを楽にする
" NeoBundle "tpope/vim-rails"
" NeoBundle 'vim-ruby/vim-ruby'
" NeoBundle 'slim-template/vim-slim'
" autocmd BufEnter * if exists("b:rails_root") | NeoCompleteSetFileType ruby.rails | endif
" autocmd BufEnter * if (expand("%") =~ "_spec\.rb$") || (expand("%") =~ "^spec.*\.rb$") | NeoCompleteSetFileType ruby.rspec | endif
" autocmd User Rails.view*                 NeoSnippetSource ~/dotfiles/snippets/ruby.rails.view.snip
" autocmd User Rails.view.haml             NeoSnippetSource ~/dotfiles/snippets/haml.rails.view.snip
" autocmd User Rails.view.erb              NeoSnippetSource ~/dotfiles/snippets/eruby.rails.view.snip
" autocmd User Rails.model                 NeoSnippetSource ~/dotfiles/snippets/ruby.rails.model.snip
" autocmd User Rails.controller            NeoSnippetSource ~/dotfiles/snippets/ruby.rails.controller.snip
" autocmd User Rails.db.migration          NeoSnippetSource ~/dotfiles/snippets/ruby.rails.migrate.snip
" autocmd User Rails/config/environment.rb NeoSnippetSource ~/dotfiles/snippets/ruby.rails.environment.snip
" autocmd User Rails/config/routes.rb      NeoSnippetSource ~/dotfiles/snippets/ruby.rails.route.snip
" autocmd User Rails.fixtures.replacement  NeoSnippetSource ~/dotfiles/snippets/ruby.factory_girl.snip
" autocmd User Rails.spec.controller       NeoSnippetSource ~/dotfiles/snippets/ruby.rspec.controller.snip
" autocmd User Rails.spec.model            NeoSnippetSource ~/dotfiles/snippets/ruby.rspec.model.snip
" autocmd User Rails.spec.helper           NeoSnippetSource ~/dotfiles/snippets/ruby.rspec.helper.snip
" autocmd User Rails.spec.feature          NeoSnippetSource ~/dotfiles/snippets/ruby.capybara.snip
" autocmd User Rails.spec.routing          NeoSnippetSource ~/dotfiles/snippets/ruby.rspec.routing.snip
" autocmd User Rails/db/migrate/*          NeoSnippetSource ~/dotfiles/snippets/ruby.rails.migrate.snip

" ノーマルモード時に-でswitch
" { :foo => true } を { foo: true } にすぐ変換できたりする
NeoBundle "AndrewRadev/switch.vim"
nnoremap - :Switch<cr>
let g:switch_custom_definitions =
    \ [
    \   {
    \     '\<\(\l\)\(\l\+\(\u\l\+\)\+\)\>': '\=toupper(submatch(1)) . submatch(2)',
    \     '\<\(\u\l\+\)\(\u\l\+\)\+\>': "\\=tolower(substitute(submatch(0), '\\(\\l\\)\\(\\u\\)', '\\1_\\2', 'g'))",
    \     '\<\(\l\+\)\(_\l\+\)\+\>': '\U\0',
    \     '\<\(\u\+\)\(_\u\+\)\+\>': "\\=tolower(substitute(submatch(0), '_', '-', 'g'))",
    \     '\<\(\l\+\)\(-\l\+\)\+\>': "\\=substitute(submatch(0), '-\\(\\l\\)', '\\u\\1', 'g')",
    \   },
    \   ['is', 'are'],
    \   ['if', 'unless'],
    \   ['while', 'until'],
    \   ['.blank?', '.present?'],
    \   ['include', 'extend'],
    \   ['class', 'module'],
    \   ['.inject', '.delete_if'],
    \   ['.map', '.map!'],
    \   ['attr_accessor', 'attr_reader', 'attr_writer'],
    \   ['=', '<', '<=', '>', '>=', '~>'],
    \   ['yes?', 'no?'],
    \   ['lib', 'initializer', 'file', 'vendor', 'rakefile'],
    \   ['controller', 'model', 'view', 'migration', 'scaffold'],
    \   { '<!--\([a-zA-Z0-9 /]\+\)--></\(div\|ul\|li\|a\)>' : '</\2><!--\1-->' },
    \   [100, ':continue', ':information'],
    \   [101, ':switching_protocols'],
    \   [102, ':processing'],
    \   [200, ':ok', ':success'],
    \   [201, ':created'],
    \   [202, ':accepted'],
    \   [203, ':non_authoritative_information'],
    \   [204, ':no_content'],
    \   [205, ':reset_content'],
    \   [206, ':partial_content'],
    \   [207, ':multi_status'],
    \   [208, ':already_reported'],
    \   [226, ':im_used'],
    \   [300, ':multiple_choices'],
    \   [301, ':moved_permanently'],
    \   [302, ':found'],
    \   [303, ':see_other'],
    \   [304, ':not_modified'],
    \   [305, ':use_proxy'],
    \   [306, ':reserved'],
    \   [307, ':temporary_redirect'],
    \   [308, ':permanent_redirect'],
    \   [400, ':bad_request'],
    \   [401, ':unauthorized'],
    \   [402, ':payment_required'],
    \   [403, ':forbidden'],
    \   [404, ':not_found'],
    \   [405, ':method_not_allowed'],
    \   [406, ':not_acceptable'],
    \   [407, ':proxy_authentication_required'],
    \   [408, ':request_timeout'],
    \   [409, ':conflict'],
    \   [410, ':gone'],
    \   [411, ':length_required'],
    \   [412, ':precondition_failed'],
    \   [413, ':request_entity_too_large'],
    \   [414, ':request_uri_too_long'],
    \   [415, ':unsupported_media_type'],
    \   [416, ':requested_range_not_satisfiable'],
    \   [417, ':expectation_failed'],
    \   [422, ':unprocessable_entity'],
    \   [423, ':precondition_required'],
    \   [424, ':too_many_requests'],
    \   [426, ':request_header_fields_too_large'],
    \   [500, ':internal_server_error'],
    \   [501, ':not_implemented'],
    \   [502, ':bad_gateway'],
    \   [503, ':service_unavailable'],
    \   [504, ':gateway_timeout'],
    \   [505, ':http_version_not_supported'],
    \   [506, ':variant_also_negotiates'],
    \   [507, ':insufficient_storage'],
    \   [508, ':loop_detected'],
    \   [510, ':not_extended'],
    \   [511, ':network_authentication_required'],
    \   ['describe', 'context', 'specific', 'example'],
    \   ['before', 'after'],
    \   ['be_true', 'be_false'],
    \   ['get', 'post', 'put', 'delete'],
    \   ['==', 'eql', 'equal'],
    \   { '\.should_not': '\.should' },
    \   ['\.to_not', '\.to'],
    \   { '\([^. ]\+\)\.should\(_not\|\)': 'expect(\1)\.to\2' },
    \   { 'expect(\([^. ]\+\))\.to\(_not\|\)': '\1.should\2' },
    \   ['[ ]', '[x]'],
    \   ['☐', '☑']
    \ ]

" APIのドキュメントを参照する
" Shift+K
NeoBundle 'thinca/vim-ref'
let g:ref_open = 'vsplit'
let g:ref_refe_cmd = "rurema"
let g:ref_refe_version = 2

" endを自動挿入
NeoBundle 'tpope/vim-endwise.git'

" do endを%移動
NeoBundleLazy 'edsono/vim-matchit', { 'autoload' : {
      \ 'filetypes': ['ruby', 'html'],
      \ }}

" 括弧入力するのだるい時
NeoBundle "kana/vim-smartinput"
NeoBundle 'cohama/vim-smartinput-endwise'

" vimでzencodingする
" Ctrl+y,で展開
NeoBundle "mattn/emmet-vim"
let g:user_zen_settings = { 'indentation' : '    ', }

" ついに闇の力に手を染めるとき
NeoBundle 'Shougo/vimproc', {
      \ 'build' : {
      \     'mac' : 'make -f make_mac.mak',
      \     'unix' : 'make -f make_unix.mak',
      \    },
      \ }

" NeoComplate {{{
if has("lua")
  NeoBundle 'Shougo/neocomplete'
  NeoBundleLazy 'Shougo/neosnippet', {
        \ 'autoload' : {
        \   'commands' : ['NeoSnippetEdit', 'NeoSnippetSource'],
        \   'filetypes' : 'snippet',
        \   'insert' : 1,
        \ }}

  NeoBundle 'Shougo/neosnippet-snippets'
  NeoBundle 'honza/vim-snippets'

  "--------------------------------------------------------------------------
  " neocomplate
  "--------------------------------------------------------------------------
  " let g:neocomplete#force_overwrite_completefunc = 1
  " Disable AutoComplPop.
  let g:acp_enableAtStartup = 0
  " Use neocomplete.
  let g:neocomplete#enable_at_startup = 1
  " Use smartcase.
  let g:neocomplete#enable_smart_case = 1
  " Set minimum syntax keyword length.
  let g:neocomplete#sources#syntax#min_keyword_length = 4
  let g:neocomplete#auto_completion_start_length = 4
  " let g:neocomplete#skip_auto_completion_time = '5.0'
  let g:neocomplete#skip_auto_completion_time = ''
  let g:neocomplete#lock_buffer_name_pattern = '\*ku\*'

  " for snippets
  let g:neosnippet#enable_snipmate_compatibility = 1
  let g:neosnippet#snippets_directory='~/.vim/vim-snippets, ~/dotfiles/snippets'

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
  let g:neocomplete#keyword_patterns['perl'] = '\h\w*->\h\w*\|\h\w*::\w*'
  let g:neocomplete#keyword_patterns['gosh-repl'] = "[[:alpha:]+*/@$_=.!?-][[:alnum:]+*/@$_:=.!?-]*"

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
  " let g:neocomplete#sources#omni#input_patterns.go = '\h\w*\.\?'

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

endif
" NeoComplate end}}}

" 英語補完
NeoBundle 'ujihisa/neco-look'

" スペルチェック
nnoremap <Space>s :<C-u>setl spell!<CR>

" まーくだうん
NeoBundle "tpope/vim-markdown"
autocmd BufNewFile, BufRead *.{md, mdwn, mkd, mkdn, mark*} set filetype=markdown

" 整列を割と自動でやってくれる
" 例えば:Alignta = で=でそろえてくれる
NeoBundle 'h1mesuke/vim-alignta.git'
xnoremap <silent> a: :Alignta 01 :<CR>
xnoremap al :Alignta<Space>

" シンタックスチェックを非同期で
" 他vim-quickrunとvimprocに依存
" NeoBundle "osyo-manga/vim-watchdogs"
" NeoBundle "osyo-manga/shabadou.vim"
" NeoBundle "cohama/vim-hier"
" let g:watchdogs_check_BufWritePost_enable = 1
" let g:quickrun_config = {
"       \   'watchdogs_checker/_' : {
"       \       'outputter/quickfix/open_cmd' : '',
"       \   }
"       \ }
" call watchdogs#setup(g:quickrun_config)

" ゲーム。結構難しい
" NeoBundle 'deris/vim-duzzle'

" CSSのデザインをライブで行う
" NeoBundle 'mattn/livestyle-vim'

" 選択部分のキーワードを*を押して検索
NeoBundle 'thinca/vim-visualstar'

" 日本語固定モード
NeoBundle 'fuenor/im_control.vim'
"<C-^>でIM制御が行える場合の設定
let IM_CtrlMode = 4
""ctrl+jで日本語入力固定モードをOnOff
inoremap <silent> <C-j> <C-^><C-r>=IMState('FixMode')<CR>

" ファイルツリーを表示する。mを押すと、ファイル・ディレクトリの追加・削除・移動ができるのも便利
NeoBundle 'scrooloose/nerdtree'
nnoremap <Space><Space>n :NERDTreeToggle<CR>

" テンプレート集
NeoBundle 'mattn/sonictemplate-vim'

" codic
NeoBundle 'koron/codic-vim'

" gauche
NeoBundle 'aharisu/vim_goshrepl'
NeoBundle 'aharisu/vim-gdev'

" カーソル下の単語を検索
nnoremap cd :<C-u>Codic<CR>

" ビジュアルモードで選択した部分を検索
vnoremap cd y:<C-u>Codic <C-R>"<CR>

" coffee break!
NeoBundle 'kchmck/vim-coffee-script.git'
au BufRead, BufNewFile, BufReadPre *.coffee   set filetype=coffee
let g:quickrun_config['coffee'] = {'command' : 'coffee',  'exec' : ['%c -cbp %s']}

" for golang
" exe "set runtimepath+=".globpath($GOPATH,  "src/github.com/nsf/gocode/vim")
" NeoBundleLazy 'Blackrush/vim-gocode', {"autoload": {"filetypes": ['go']}}
auto BufWritePre *.go execute 'Fmt'
auto BufWritePost *.go execute 'Lint' | cwindow

" 同一ファイル内のdiffを確認する
" NeoBundle 'adie/BlockDiff'

" マークダウンのプレビュー
NeoBundle 'kannokanno/previm'
NeoBundle 'tyru/open-browser.vim'
" let g:previm_open_cmd = 'open -a Safari'
nnoremap <silent><Space><Space>p :PrevimOpen<CR>
nnoremap <silent><Space><Space>l :!open http://localhost:3000<CR>

" Dockerfileのハイライト
NeoBundle "ekalinin/Dockerfile.vim"

" arduino
" <Leader>ac - Compile the current sketch.
" <Leader>ad - Compile and deploy the current sketch.
" <Leader>as - Open a serial port in screen.
NeoBundle "jplaut/vim-arduino-ino.git"
let g:vim_arduino_auto_open_serial = 1

NeoBundle "heavenshell/vim-jsdoc"
" NeoBundle 'Valloric/YouCompleteMe',  {
"       \ 'build' : {
"       \     'mac' : 'git submodule update --init --recursive && ./install.sh',
"       \    },
"       \ }
" let g:ycm_key_list_select_completion = ['',  '<Down>']
" let g:ycm_key_list_previous_completion = ['',  '<Up>']

" HTML5
NeoBundle "othree/html5.vim"
autocmd FileType html :compiler tidy
autocmd FileType html :setlocal makeprg=tidy\ -raw\ -quiet\ -errors\ --gnu-emacs\ yes\ \"%\"

" ファイル名と内容をもとにファイルタイププラグインを有効にする
filetype plugin indent on
" ハイライトON
syntax on

" まだインストールしていないプラグインをインストールしてくれる
NeoBundleCheck

"--------------------------------------------------------------------------
" BasicSetting
"--------------------------------------------------------------------------
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
au BufNewFile,BufRead *.tx         set filetype=html
au BufNewFile,BufRead *.tt2        set filetype=html
au BufNewFile,BufRead *.scss       set filetype=css
au BufNewFile,BufRead Guardfile    set filetype=ruby
au BufNewFile,BufRead Vagrantfile  set filetype=ruby
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
set textwidth=0
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
if exists("noimdisableactivate")
  set noimdisableactivate
endif

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
set ttyfast

nnoremap <ESC><ESC> :nohlsearch<CR><ESC>

" これで保存やコマンドを速く打てるようになる
" 未設定のVimではもたつくので訓練すること
noremap ; :
noremap : ;

" 保存時に行末の空白を除去する
autocmd BufWritePre * :%s/\s\+$//ge
" 保存時にtabをスペースに変換する
" autocmd BufWritePre * :%s/\t/  /ge

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

" snippets/go.snipを瞬時に開く
nnoremap <Space><Space>gs :e $HOME/dotfiles/snippets/go.snip<CR>

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

noremap  <Space><Space>ad y:<C-u>:g/^$/d<CR>

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

" insert mode時に以前編集した文字も削除できるようにする
set bs=start

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

nnoremap <silent><Space><Space>h :r!tail -10000 ~/.zsh_history \| perl -pe 's/^.+;//' \| fzf<CR>

let g:markdown_fenced_languages = [
\  'coffee',
\  'css',
\  'erb=eruby',
\  'javascript',
\  'js=javascript',
\  'json=javascript',
\  'ruby',
\  'c',
\  'ino=c',
\  'perl',
\  'go',
\  'sass',
\  'xml',
\]

command! CopyRelativePath
\ let @*=join(remove( split( expand( '%:p' ), "/" ), len( split( getcwd(), "/" ) ), -1 ), "/") | echo "copied"

command! CopyFullPath
\ let @*=expand('%') | echo "copied"

map <C-i> =

