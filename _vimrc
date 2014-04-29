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

" NeoBundle自体の管理
NeoBundleFetch 'Shougo/neobundle.vim'

" ステータスラインに情報を表示 → もう力はいらない
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

" gcc or C-_でトグル
NeoBundle 'tomtom/tcomment_vim'

" やっぱりVimはかっこよくなければならない
set t_Co=256
NeoBundle 'tomasr/molokai'
colorscheme molokai

" 翻訳
NeoBundleLazy 'mattn/excitetranslate-vim', {
      \ 'depends': 'mattn/webapi-vim',
      \ 'autoload' : { 'commands': ['ExciteTranslate']}
      \ }

" カーソルキー使うってやっぱなんか、ありえない？みたいな
NeoBundle 'https://github.com/kazuph/gips-vim.git'

" ctrlpがないとかどんな苦行
NeoBundle 'kien/ctrlp.vim.git'
let g:ctrlp_map = '<c-f>' " yankringとかぶるんだよ・・・
let g:ctrlp_max_height = &lines
set wildignore+=*/tmp/*,*.so,*.swp,*.zip
let g:ctrlp_custom_ignore = {
  \ 'dir':  '\v[\/]\.?(local|extlib|git|hg|svn|bundle)$',
  \ }

" 依存が少ないyankringらしい
NeoBundle 'LeafCage/yankround.vim'
nmap p <Plug>(yankround-p)
nmap P <Plug>(yankround-P)
nmap <C-p> <Plug>(yankround-prev)
nmap <C-n> <Plug>(yankround-next)
let g:yankround_max_history = 50
nnoremap ,yp :<C-u>CtrlPYankRound<CR>

" ()や''でくくったりするための補助
" text-objectの支援
" di' で'の中身を削除
" da' で'も含めて削df
" cs'" cs"' などと囲っているものに対する操作ができる
" visualモードのときはSを代用
NeoBundle "tpope/vim-surround"

" テキストオブジェクトを使い倒す
NeoBundle 'kana/vim-operator-user.git'
NeoBundle 'kana/vim-operator-replace.git'
map R  <Plug>(operator-replace)

" キャメルケースをスネークケースに置き換える
" ※Cは元々行末まで置き換えるキー
NeoBundle 'tyru/operator-camelize.vim'
map C <Plug>(operator-camelize-toggle)

" キャメル・アンダースコア記法を扱いやすく
" ,w ,e ,b
" v,w
" d,w
NeoBundle 'bkad/CamelCaseMotion.git'
map w ,w
map e ,e
map b ,b

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

" ST2のようにテキスト操作
" ctrl+nで選択
" NeoBundle 'terryma/vim-multiple-cursors.git'

" ヤンクの履歴を参照したい
NeoBundle 'kana/vim-fakeclip.git'
NeoBundle 'LeafCage/yankround.vim'
nnoremap <space><space>y :YRShow<CR>

" 正規表現をPerl風に
" :%S///gc
NeoBundle 'othree/eregex.vim'
" nnoremap / :<C-u>M/

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
NeoBundle 'thinca/vim-qfreplace'

" 僕だってtag使ってみたい
NeoBundle 'szw/vim-tags'
let g:vim_tags_project_tags_command = "/usr/local/bin/ctags -R {OPTIONS} {DIRECTORY} 2>/dev/null"
let g:vim_tags_gems_tags_command = "/usr/local/bin/ctags -R {OPTIONS} `bundle show --paths` 2>/dev/null"

NeoBundle 'vim-scripts/taglist.vim'
set tags=./tags,tags,../tags
let Tlist_Show_One_File = 1
let Tlist_Use_Right_Window = 1
let Tlist_Exit_OnlyWindow = 1
nnoremap <silent> <Space><Space>t :TlistToggle<CR>

NeoBundle "majutsushi/tagbar"
nnoremap <C-t> :TagbarToggle<CR>
nnoremap <C-]> g<C-]>

" 爆速のgrepであるagを使いたい
NeoBundle 'rking/ag.vim'
nnoremap gg/  :<C-u>Ag <C-R><C-w><CR>
vnoremap gg/ y:<C-u>Ag <C-R>"<CR>

" 賢いf
NeoBundle 'rhysd/clever-f.vim'

" gitの差分を表示するぜ
NeoBundle 'airblade/vim-gitgutter'
nnoremap <silent> ,gg :<C-u>GitGutterToggle<CR>
nnoremap <silent> ,gh :<C-u>GitGutterLineHighlightsToggle<CR>

" \rで開いているコードを実行
NeoBundle "thinca/vim-quickrun.git"
let g:quickrun_config            = {}
let g:quickrun_config.markdown   = {
      \   'outputter' : 'null',
      \   'command'   : 'open',
      \   'exec'      : '%c %s',
      \ }

let g:quickrun_config.coffee = {'command' : 'coffee',  'exec' : ['%c -cbp %s']}

" Programming perl
NeoBundle "c9s/perlomni.vim"
NeoBundle "mattn/perlvalidate-vim.git"
NeoBundle "vim-perl/vim-perl"
NeoBundle "y-uuki/perl-local-lib-path.vim"
autocmd FileType perl PerlLocalLibPath
nnoremap ,pt <Esc>:%! perltidy -se<CR>
vnoremap ,pt <Esc>:'<,'>! perltidy -se<CR>

" cpanfile用
" NeoBundle 'moznion/vim-cpanfile'
" NeoBundle 'moznion/syntastic-cpanfile'

" ()や''でくくったりするための補助
" text-objectの支援
" vi' で'の中身を選択
" va' で'も含めて選択 だが
" cs'" cs"' などと囲っているものに対する操作ができる
" visualモードのときはSを代用
NeoBundle "tpope/vim-surround"

" Rubyでのコーディングを楽にする
NeoBundle "tpope/vim-rails"
NeoBundle 'vim-ruby/vim-ruby'
NeoBundle 'tpope/vim-cucumber'
NeoBundle 'slim-template/vim-slim'
NeoBundle "dbext.vim"
autocmd BufEnter * if exists("b:rails_root") | NeoCompleteSetFileType ruby.rails | endif
autocmd BufEnter * if (expand("%") =~ "_spec\.rb$") || (expand("%") =~ "^spec.*\.rb$") | NeoCompleteSetFileType ruby.rspec | endif
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
NeoBundle "AndrewRadev/switch.vim"
nnoremap ! :Switch<cr>
let s:switch_definition = {
      \ '*': [
      \   ['is', 'are']
      \ ],
      \ 'ruby,eruby,haml' : [
      \   ['if', 'unless'],
      \   ['while', 'until'],
      \   ['.blank?', '.present?'],
      \   ['include', 'extend'],
      \   ['class', 'module'],
      \   ['.inject', '.delete_if'],
      \   ['.map', '.map!'],
      \   ['attr_accessor', 'attr_reader', 'attr_writer'],
      \ ],
      \ 'Gemfile,Berksfile' : [
      \   ['=', '<', '<=', '>', '>=', '~>'],
      \ ],
      \ 'ruby.application_template' : [
      \   ['yes?', 'no?'],
      \   ['lib', 'initializer', 'file', 'vendor', 'rakefile'],
      \   ['controller', 'model', 'view', 'migration', 'scaffold'],
      \ ],
      \ 'erb,html,php' : [
      \   { '<!--\([a-zA-Z0-9 /]\+\)--></\(div\|ul\|li\|a\)>' : '</\2><!--\1-->' },
      \ ],
      \ 'rails' : [
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
      \ ],
      \ 'rspec': [
      \   ['describe', 'context', 'specific', 'example'],
      \   ['before', 'after'],
      \   ['be_true', 'be_false'],
      \   ['get', 'post', 'put', 'delete'],
      \   ['==', 'eql', 'equal'],
      \   { '\.should_not': '\.should' },
      \   ['\.to_not', '\.to'],
      \   { '\([^. ]\+\)\.should\(_not\|\)': 'expect(\1)\.to\2' },
      \   { 'expect(\([^. ]\+\))\.to\(_not\|\)': '\1.should\2' },
      \ ],
      \ 'markdown' : [
      \   ['[ ]', '[x]']
      \ ]
      \ }

" %の拡張
NeoBundle "tmhedberg/matchit.git"

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
        \   'unite_sources' : ['snippet', 'neosnippet/user', 'neosnippet/runtime'],
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

  " if !exists('g:neocomplete#text_mode_filetypes')
  "   let g:neocomplete#text_mode_filetypes = {}
  " endif
  "
  " let g:neocomplete#text_mode_filetypes = {
  "       \ 'rst': 1,
  "       \ 'vimrc': 1,
  "       \ 'perl': 1,
  "       \ 'ruby': 1,
  "       \ 'javascript': 1,
  "       \ 'coffee': 1,
  "       \ 'markdown': 1,
  "       \ 'gitrebase': 1,
  "       \ 'gitcommit': 1,
  "       \ 'vcs-commit': 1,
  "       \ 'hybrid': 1,
  "       \ 'text': 1,
  "       \ 'help': 1,
  "       \ 'tex': 1,
  "       \ }

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
nnoremap <Space>s  :<C-u>setl spell!<CR>

" すべてを破壊したいあなたに
NeoBundle 'Shougo/unite.vim',  '',  'default'
NeoBundle 'basyura/unite-rails'
NeoBundle 'kmnk/vim-unite-giti'
NeoBundle 'tsukkee/unite-tag'
NeoBundle 'ujihisa/unite-colorscheme'
NeoBundle 'h1mesuke/unite-outline'

" まーくだうん
NeoBundle "tpope/vim-markdown"
autocmd BufNewFile, BufRead *.{md, mdwn, mkd, mkdn, mark*} set filetype=markdown

" 整列を割と自動でやってくれる
" 例えば:Alignta = で=でそろえてくれる
NeoBundle 'h1mesuke/vim-alignta.git'
xnoremap <silent> a: :Alignta  01 :<CR>
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
NeoBundle 'deris/vim-duzzle'

" CSSのデザインをライブで行う
NeoBundle 'mattn/livestyle-vim'

" 選択部分のキーワードを*を押して検索
NeoBundle 'thinca/vim-visualstar'

" カーソルのある場所でfiletypeを適宜変更する
" NeoBundle 'osyo-manga/vim-precious'
" NeoBundle 'Shougo/context_filetype.vim'
" NeoBundle 'kana/vim-textobj-user'
" nmap <Space><Space>q <Plug>(precious-quickrun-op)
" omap ic <Plug>(textobj-precious-i)
" vmap ic <Plug>(textobj-precious-i)

" 日本語固定モード
NeoBundle 'fuenor/im_control.vim'
"<C-^>でIM制御が行える場合の設定
let IM_CtrlMode = 4
""ctrl+jで日本語入力固定モードをOnOff
inoremap <silent> <C-j> <C-^><C-r>=IMState('FixMode')<CR>

" Vimのキーバインドでfiling
NeoBundle 'Shougo/vimfiler'
let s:bundle = neobundle#get('vimfiler')
function! s:bundle.hooks.on_source(bundle)
  let g:vimfiler_as_default_explorer = 1
  let g:vimfiler_safe_mode_by_default = 0
endfunction

nnoremap <Space>v :VimFiler -split -simple -winwidth=35 -no-quit<CR>

NeoBundle 'scrooloose/nerdtree'
nnoremap <Space>n :NERDTreeToggle<CR>

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

" Vimshellしたい
NeoBundle 'Shougo/vimshell.vim.git'

" MATRIX的な
NeoBundle 'matrix.vim--Yang'

" 走り幅跳びする
NeoBundle 'mattn/habatobi-vim'

" 置換をかっこ良くする
" NeoBundle 'osyo-manga/vim-over'
" nnoremap <silent> ,vo :OverCommandLine<CR>%s/

" テンプレート集
NeoBundle 'mattn/sonictemplate-vim'

" codic
NeoBundle 'koron/codic-vim'
NeoBundle 'rhysd/unite-codic.vim'

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

" for go
exe "set runtimepath+=".globpath($GOPATH,  "src/github.com/nsf/gocode/vim")
" NeoBundleLazy 'Blackrush/vim-gocode', {"autoload": {"filetypes": ['go']}}
auto BufWritePre *.go Fmt

" 複数開いているウィンドウに瞬時に移動する
NeoBundle 't9md/vim-choosewin'
nmap  -  <Plug>(choosewin)
let g:choosewin_overlay_enable = 1
let g:choosewin_overlay_clear_multibyte = 1
let g:choosewin_color_overlay = {
      \ 'gui': ['DodgerBlue3', 'DodgerBlue3' ],
      \ 'cterm': [ 25, 25 ]
      \ }
let g:choosewin_color_overlay_current = {
      \ 'gui': ['firebrick1', 'firebrick1' ],
      \ 'cterm': [ 124, 124 ]
      \ }
let g:choosewin_blink_on_land      = 0
let g:choosewin_statusline_replace = 0
let g:choosewin_tabline_replace    = 0

NeoBundle 'aharisu/vim-gdev'

" 同一ファイル内のdiffを確認する
NeoBundle 'adie/BlockDiff'

" NeoBundle 'Valloric/YouCompleteMe',  {
"       \ 'build' : {
"       \     'mac' : 'git submodule update --init --recursive && ./install.sh',
"       \    },
"       \ }
" let g:ycm_key_list_select_completion = ['',  '<Down>']
" let g:ycm_key_list_previous_completion = ['',  '<Up>']

" ファイル名と内容をもとにファイルタイププラグインを有効にする
filetype plugin indent on
" ハイライトON
syntax on

" まだインストールしていないプラグインをインストールしてくれる
NeoBundleCheck

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
" source: Uniteから各種pluginへのinteface
nnoremap <silent> ,us :Unite source<CR>
" ファイル一覧
" nnoremap <silent> ,uf :<C-u>UniteWithBufferDir -buffer-name=files file<CR>
nnoremap <silent> ,f  :<C-u>Unite file_rec/async:!<CR>
" ブックマーク一覧
nnoremap <silent> ,ub :<C-u>Unite bookmark<CR>
" ブックマーク追加
nnoremap <silent> ,ua :<C-u>UniteBookmarkAdd<CR>
" yank一覧
nnoremap <silent> ,y :<C-u>Unite -buffer-name=register register<CR>
" 常用セット
nnoremap <silent> ,uu :<C-u>Unite buffer file_mru file_rec/async:!<CR>
" tag
nnoremap <silent> ,ut :Unite tag/include<CR>
" unite-grep
nnoremap <silent> ,ug :Unite -no-quit -winheight=15 grep<CR>
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
" codic
nnoremap <silent> ,cd :Unite codic<CR>

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
au BufNewFile,BufRead *.scss       set filetype=scss
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

