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

"dein Scripts-----------------------------
if &compatible
  set nocompatible               " Be iMproved
endif

" Required:
set runtimepath+=$HOME/.dein/repos/github.com/Shougo/dein.vim

" Required:
call dein#begin(expand($HOME . '/.dein'))

let mapleader = "\<Space>"

" Required:
call dein#add('Shougo/dein.vim')
call dein#add('Shougo/vimproc.vim', {
    \ 'build': {
    \     'windows': 'tools\\update-dll-mingw',
    \     'cygwin': 'make -f make_cygwin.mak',
    \     'mac': 'make -f make_mac.mak',
    \     'linux': 'make',
    \     'unix': 'gmake',
    \    }
    \ })

" ステータスラインに情報を表示 → もう力はいらない
" call dein#add('itchyny/lightline.vim')
" let g:lightline = {
"       \ 'component': {
"       \   'readonly': '%{&readonly?"⭤":""}',
"       \ },
"       \ 'separator': { 'left': '⮀', 'right': '⮂' },
"       \ 'subseparator': { 'left': '⮁', 'right': '⮃' }
"       \ }

" YAML
call dein#add('stephpy/vim-yaml')

" gcc or C-_でトグル
call dein#add('tomtom/tcomment_vim')

call dein#add('flazz/vim-colorschemes')
colorscheme molokai
" set background=light
" let g:solarized_termcolors=256
" colorscheme solarized

" ctrlpでいいと思う
call dein#add('ctrlpvim/ctrlp.vim')
let g:ctrlp_map = '<c-f>' " yankringとかぶるので・・・
let g:ctrlp_max_height = &lines
set wildignore+=*/tmp/*,*.so,*.swp,*.zip
let g:ctrlp_custom_ignore = {
  \ 'dir':  '\v[\/]\.?(local|extlib|git|hg|svn|bundle|node_modules)$',
  \ }

" 文法チェック
call dein#add('vim-syntastic/syntastic')

" quickrunする
call dein#add('thinca/vim-quickrun')
let g:quickrun_config = get(g:, 'quickrun_config', {})
let g:quickrun_config._ = {
      \ 'runner'    : 'vimproc',
      \ 'runner/vimproc/updatetime' : 60,
      \ 'outputter' : 'error',
      \ 'outputter/error/success' : 'buffer',
      \ 'outputter/error/error'   : 'quickfix',
      \ 'outputter/buffer/split'  : ':rightbelow 8sp',
      \ 'outputter/buffer/close_on_empty' : 1,
      \ }
let g:quickrun_config.python = {'command' : 'python3'}
" q でquickfixを閉じれるようにする。
au FileType qf nnoremap <silent><buffer>q :quit<CR>

" \r で保存してからquickrunを実行する。
" let g:quickrun_no_default_key_mappings = 1
" nnoremap \r :write<CR>:QuickRun -mode n<CR>
" xnoremap \r :<C-U>write<CR>gv:QuickRun -mode v<CR>

" \r でquickfixを閉じて、保存してからquickrunを実行する。
let g:quickrun_no_default_key_mappings = 1
nnoremap \r :cclose<CR>:write<CR>:QuickRun -mode n<CR>
xnoremap \r :<C-U>cclose<CR>:write<CR>gv:QuickRun -mode v<CR>

" <C-c> でquickrunを停止
nnoremap <expr><silent> <C-c> quickrun#is_running() ? quickrun#sweep_sessions() : "\<C-c>"

" 依存が少ないyankringらしい
" call dein#add('LeafCage/yankround.vim')
" nmap p <Plug>(yankround-p)
" nmap P <Plug>(yankround-P)
" nmap <C-p> <Plug>(yankround-prev)
" nmap <C-n> <Plug>(yankround-next)
" let g:yankround_max_history = 100
" nnoremap <Space><Space>y :<C-u>CtrlPYankRound<CR>

" 正規表現をPerl風に
" :%S///gc
call dein#add('othree/eregex.vim')
call dein#add('haya14busa/incsearch.vim')
map /  <Plug>(incsearch-forward)

" ()や''でくくったりするための補助
" text-objectの支援
" di' で'の中身を削除
" da' で'も含めて削df
" cs'" cs"' などと囲っているものに対する操作ができる
" visualモードのときはSを代用
call dein#add("tpope/vim-surround")

" テキストオブジェクトを使い倒す
call dein#add('kana/vim-operator-user.git')

" Rを使ってyankしてるものと置き換え
call dein#add('kana/vim-operator-replace.git')
map R <Plug>(operator-replace)

" キャメル・アンダースコア記法を扱いやすく
" , w , e , b
" v, w
" d, w
call dein#add('bkad/CamelCaseMotion.git')
map <silent> w <Plug>CamelCaseMotion_w
map <silent> b <Plug>CamelCaseMotion_b
map <silent> e <Plug>CamelCaseMotion_e
map <silent> ge <Plug>CamelCaseMotion_ge
sunmap w
sunmap b
sunmap e
sunmap ge

"  ","と押して", "としてくれる優しさ
call dein#add("vim-scripts/smartchr")
inoremap <expr> , smartchr#one_of(', ', ',')

" カーソルジェットコースター
call dein#add('rhysd/accelerated-jk.git')
let g:accelerated_jk_acceleration_table = [10,5,3]
nmap j <Plug>(accelerated_jk_gj)
nmap k <Plug>(accelerated_jk_gk)

" jkがいないなら
call dein#add('easymotion/vim-easymotion')
nmap s <Plug>(easymotion-s2)
xmap s <Plug>(easymotion-s2)
omap z <Plug>(easymotion-s2)
let g:EasyMotion_smartcase = 1
map <Leader>j <Plug>(easymotion-j)
map <Leader>k <Plug>(easymotion-k)
let g:EasyMotion_startofline = 0
let g:EasyMotion_keys = ';HKLYUIOPNM,QWERTASDGZXCVBJF'
let g:EasyMotion_use_upper = 1
let g:EasyMotion_enter_jump_first = 1
let g:EasyMotion_space_jump_first = 1

" ヤンクの履歴を参照したい
call dein#add('kana/vim-fakeclip.git')

" Vim上でgitを使いたい
call dein#add('lambdalisue/gina.vim')


" memoはやっぱりVimからやろ
call dein#add('glidenote/memolist.vim')
nnoremap ,mn :MemoNew<cr>
nnoremap ,mg :MemoGrep<cr>
nnoremap ,ml :MemoList<CR>
nnoremap ,mf :exe "CtrlP" g:memolist_path<cr><f5>
let g:memolist_ex_cmd = 'NERDTree'
let g:memolist_path = "~/Dropbox/memo"
let g:memolist_fzf = 1

" 爆速のgrepであるagを使いたい
call dein#add('rking/ag.vim')
nnoremap gg/  :<C-u>Ag <C-R><C-w><CR>
vnoremap gg/ y:<C-u>Ag <C-R>"<CR>

" git操作
call dein#add('tpope/vim-fugitive')
call dein#add('gregsexton/gitv')

" sftp
" call dein#add('naoyuki1019/vim-ftpautoupload')

" grep後に置換したい
" gg/したあとにQf<TAB>後、編集、保存で一括置換
call dein#add('thinca/vim-qfreplace')

" 賢いf
call dein#add('rhysd/clever-f.vim')

" gitの差分を表示するぜ
call dein#add('airblade/vim-gitgutter')
nnoremap <silent> ,gg :<C-u>GitGutterToggle<CR>
nnoremap <silent> ,gh :<C-u>GitGutterLineHighlightsToggle<CR>

" ノーマルモード時に-でswitch
" { :foo => true } を { foo: true } にすぐ変換できたりする
call dein#add("AndrewRadev/switch.vim")
let g:switch_mapping = "-"
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

" endを自動挿入
call dein#add('tpope/vim-endwise.git')

" do endを%移動
call dein#add('adelarsq/vim-matchit', { 'autoload' : {
      \ 'filetypes': ['ruby', 'html'],
      \ }})

" 括弧入力するのだるい時
" call dein#add("kana/vim-smartinput")
" call dein#add('cohama/vim-smartinput-endwise')

" Ctrl+y,で展開
call dein#add("mattn/emmet-vim")
let g:user_zen_settings = { 'indentation' : '    ', }

" NeoComplate {{{
call dein#add('Shougo/neocomplete')
call dein#add('Shougo/neosnippet', {
      \ 'autoload' : {
      \   'commands' : ['NeoSnippetEdit', 'NeoSnippetSource'],
      \   'filetypes' : 'snippet',
      \   'insert' : 1,
      \ }})

call dein#add('Shougo/neosnippet-snippets')
call dein#add('honza/vim-snippets')

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
let g:neocomplete#sources#syntax#min_keyword_length = 2
let g:neocomplete#auto_completion_start_length = 2
" let g:neocomplete#skip_auto_completion_time = '5.0'
let g:neocomplete#skip_auto_completion_time = ''
let g:neocomplete#lock_buffer_name_pattern = '\*ku\*'

" for snippets
let g:neosnippet#enable_snipmate_compatibility = 1
let g:neosnippet#snippets_directory='~/.vim/bundle/vim-snippets/snippets,~/.vim/bundle/vim-snippets/snippets/javascript,~/dotfiles/snippets,~/.vim/bundle/neosnippet-snippets/neosnippets'

" Define dictionary.
let g:neocomplete#sources#dictionary#dictionaries = {
      \ 'default' : '',
      \ 'vimshell' : $HOME.'/.vimshell_hist',
      \ 'perl'     : $HOME . '/dotfiles/dict/perl.dict',
      \ 'ruby'     : $HOME . '/dotfiles/dict/ruby.dict',
      \ 'python'   : $HOME . '/dotfiles/dict/python.dict',
      \ 'go'       : $HOME . '/dotfiles/dict/go.dict',
      \ 'js'       : $HOME . '/dotfiles/dict/js.dict',
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
xmap <C-k>     <Plug>(neosnippet_expand_target)

" For snippet_complete marker.
if has('conceal')
  set conceallevel=2 concealcursor=i
endif

" ctags
let g:neocomplcache_ctags_arguments_list = {
      \ 'perl' : '-R -h ".pm"',
      \ }

" NeoComplate end}}}

" 英語補完
call dein#add('ujihisa/neco-look')

" スペルチェック
nnoremap <Space>s :<C-u>setl spell!<CR>

" まーくだうん
call dein#add("tpope/vim-markdown")
autocmd BufNewFile, BufRead *.{md, mdwn, mkd, mkdn, mark*} set filetype=markdown
let g:markdown_syntax_conceal = 0

" 整列を割と自動でやってくれる
" 例えば:Alignta = で=でそろえてくれる
call dein#add('h1mesuke/vim-alignta.git')
xnoremap <silent> a: :Alignta 00 \s<CR>
xnoremap al :Alignta<Space>

" 選択部分のキーワードを*を押して検索
call dein#add('thinca/vim-visualstar')

" 日本語固定モード
call dein#add('fuenor/im_control.vim')
"<C-^>でIM制御が行える場合の設定
let IM_CtrlMode = 4
""ctrl+jで日本語入力固定モードをOnOff
inoremap <silent> <C-j> <C-^><C-r>=IMState('FixMode')<CR>

" devicon ;)
call dein#add('ryanoasis/vim-devicons')
let g:webdevicons_conceal_nerdtree_brackets = 1
let g:WebDevIconsNerdTreeGitPluginForceVAlign = 0
let g:WebDevIconsNerdTreeAfterGlyphPadding = ' '

" ファイルツリーを表示する。mを押すと、ファイル・ディレクトリの追加・削除・移動ができるのも便利
call dein#add('scrooloose/nerdtree')
nnoremap <C-n> :NERDTreeToggle<CR>
call dein#add('tiagofumo/vim-nerdtree-syntax-highlight')
call dein#add('Xuyuanp/nerdtree-git-plugin')

" The fancy start screen for Vim.
call dein#add('mhinz/vim-startify')

" golang
call dein#add('fatih/vim-go')
let g:go_fmt_command = "goimports"
"

" マークダウンのプレビュー
" call dein#add('kannokanno/previm')
call dein#add('kazuph/previm', {'rev': 'feature/add-plantuml-plugin'})
call dein#add('tyru/open-browser.vim')
nnoremap <silent><Space><Space>p :PrevimOpen<CR>
nnoremap <silent><Space><Space>l :!open http://localhost:3000<CR>

" Dockerfileのハイライト
call dein#add("ekalinin/Dockerfile.vim")

" HTML5
call dein#add("othree/html5.vim")
autocmd FileType html :compiler tidy
autocmd FileType html :setlocal makeprg=tidy\ -raw\ -quiet\ -errors\ --gnu-emacs\ yes\ \"%\"

call dein#add('maksimr/vim-jsbeautify')
autocmd FileType javascript noremap <buffer>,cf :call JsBeautify()<cr>
autocmd FileType html       noremap <buffer>,cf :call HtmlBeautify()<cr>
autocmd FileType css        noremap <buffer>,cf :call CSSBeautify()<cr>
autocmd FileType json       noremap <buffer>,cf :call JsonBeautify()<cr>
autocmd FileType jsx        noremap <buffer>,cf :call JsxBeautify()<cr>


call dein#add('elzr/vim-json')
let g:vim_json_syntax_conceal = 0

call dein#add('editorconfig/editorconfig-vim')

call dein#add('millermedeiros/vim-esformatter')
nnoremap <silent> <buffer>,es :Esformatter<CR>
vnoremap <silent> <buffer>,es :EsformatterVisual<CR>

" call dein#add('mattn/vim-rubyfmt')
call dein#add('pangloss/vim-javascript')
" call dein#add('mxw/vim-jsx')
" let g:jsx_ext_required = 0
" let g:jsx_pragma_required = 1
" call dein#add('posva/vim-vue')

" keynoteへのソースのシンタックスハイライトの貼り付け用
" :CopyRTF
call dein#add('zerowidth/vim-copy-as-rtf')

" fzf
call dein#add('junegunn/fzf', { 'build': './install --all', 'merged': 0 })
call dein#add('junegunn/fzf.vim', { 'depends': 'fzf' })
let g:fzf_command_prefix = 'F'
nnoremap <Leader>b :FBuffers<CR>
nnoremap <Leader>x :FCommands<CR>
nnoremap <Leader>f :FGFiles<CR>
nnoremap <Leader>a :FAg<CR>

" for PlantUML
call dein#add("aklt/plantuml-syntax")
let g:plantuml_executable_script = "~/dotfiles/plantuml"
call dein#add("tex/vimpreviewpandoc")

" 常駐化する
call dein#add("thinca/vim-singleton")

augroup filetypedetect
  au! BufRead,BufNewFile *.csv,*.dat	setfiletype csv
augroup END

" If you want to install not installed plugins on startup.
if dein#check_install()
 call dein#install()
endif

" Required:
call dein#end()
call dein#save_state()

"End dein Scripts-------------------------

" ファイル名と内容をもとにファイルタイププラグインを有効にする
filetype plugin indent on
" ハイライトON
syntax on

"--------------------------------------------------------------------------
" BasicSetting
"--------------------------------------------------------------------------
" ヘルプを3倍の速度で引く
nnoremap <C-h>  :<C-u>help<Space><C-r><C-w><CR>

" 認識されないっぽいファイルタイプを追加
au BufNewFile,BufRead *.ejs        set filetype=html
au BufNewFile,BufRead *.ep         set filetype=html
au BufNewFile,BufRead *.pde        set filetype=processing
au BufNewFile,BufRead *.erb        set filetype=html
au BufNewFile,BufRead *.tt         set filetype=html
au BufNewFile,BufRead *.tmpl       set filetype=html
au BufNewFile,BufRead *.tx         set filetype=html
au BufNewFile,BufRead *.tt2        set filetype=html
au BufNewFile,BufRead *.vue*       set filetype=html
au BufNewFile,BufRead *.scss       set filetype=css
au BufNewFile,BufRead Vagrantfile  set filetype=ruby
au BufNewFile,BufRead *.es6        set filetype=javascript.jsx
au BufNewFile,BufRead *.pug        set filetype=pug
au BufNewFile,BufRead *.conf       set filetype=dosini
" au BufNewFile,BufRead *.js         set filetype=javascript.jsx
" au BufNewFile,BufRead *.vue        set filetype=javascript.jsx.css

" ファイルエンコーディング
let $LANG='ja_JP.UTF-8'
set encoding=utf-8
set fileencodings=ucs-bom,utf-8,iso-2022-jp,sjis,cp932,euc-jp,cp20932

" やっぱりVimはかっこよくなければならない
set t_Co=256

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
" set showtabline=2
" set noshowmode

" for powerline
" python from powerline.vim import setup as powerline_setup
" python powerline_setup()
" python del powerline_setup

" Ctrl+eで'paste'と'nopaste'を切り替える
" set pastetoggle=<C-e>
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
autocmd FileType pug        setlocal sw=2 sts=2 ts=2 et
autocmd FileType jsx        setlocal sw=2 sts=2 ts=2 et
autocmd FileType perl       setlocal sw=2 sts=2 ts=2 et
autocmd FileType php        setlocal sw=4 sts=4 ts=4 et
autocmd FileType python     setlocal sw=2 sts=2 ts=2 et
autocmd FileType ruby       setlocal sw=2 sts=2 ts=2 et
autocmd FileType haml       setlocal sw=2 sts=2 ts=2 et
autocmd FileType sh         setlocal sw=4 sts=4 ts=4 et
autocmd FileType sql        setlocal sw=4 sts=4 ts=4 et
autocmd FileType vb         setlocal sw=4 sts=4 ts=4 et
autocmd FileType vim        setlocal sw=2 sts=2 ts=2 et
autocmd FileType wsh        setlocal sw=4 sts=4 ts=4 et
autocmd FileType xhtml      setlocal sw=2 sts=2 ts=2 et
autocmd FileType xml        setlocal sw=2 sts=2 ts=2 et
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
set listchars=tab:»-,trail:-
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
" noremap ; :
" noremap : ;

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
" set ttymouse=xterm2

" テンプレートの設定
autocmd BufNewFile *.rb 0r ~/dotfiles/templates/rb.tpl
autocmd BufNewFile *.pl 0r ~/dotfiles/templates/pl.tpl
autocmd BufNewFile *.py 0r ~/dotfiles/templates/py.tpl

" .vimrcを瞬時に開く
nnoremap <Space><Space>. :e $MYVIMRC<CR>

" snippets/perl.snipを瞬時に開く
nnoremap <Space><Space>pls :e $HOME/dotfiles/snippets/perl.snip<CR>
nnoremap <Space><Space>pld :e $HOME/dotfiles/dict/perl.dict<CR>

" snippets/ruby.snipを瞬時に開く
nnoremap <Space><Space>rbs :e $HOME/dotfiles/snippets/ruby.snip<CR>
nnoremap <Space><Space>rbd :e $HOME/dotfiles/dict/ruby.dict<CR>

" snippets/python.snipを瞬時に開く
nnoremap <Space><Space>pys :e $HOME/dotfiles/snippets/python.snip<CR>
nnoremap <Space><Space>pyd :e $HOME/dotfiles/dict/python.dict<CR>

" snippets/go.snipを瞬時に開く
nnoremap <Space><Space>gos :e $HOME/dotfiles/snippets/go.snip<CR>
nnoremap <Space><Space>god :e $HOME/dotfiles/dict/go.dict<CR>

" snippets/js.snipを瞬時に開く
nnoremap <Space><Space>jss :e $HOME/dotfiles/snippets/js.snip<CR>
nnoremap <Space><Space>jsd :e $HOME/dotfiles/dict/js.dict<CR>

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

nnoremap <silent><Space><Space>h :r!tail -10000 ~/.zhistory \| perl -pe 's/^.+;//' \| fzf<CR>

let g:markdown_fenced_languages = [
\  'css',
\  'erb=eruby',
\  'js=javascript',
\  'json=javascript',
\  'rb=ruby',
\  'py=python',
\  'sh',
\  'sql',
\  'c',
\  'ino=c',
\  'java',
\  'kt=kotlin',
\  'perl',
\  'go',
\  'sass',
\  'html',
\  'xml',
\  'yml=yaml',
\  'conf=dosini',
\  'Dockerfile',
\]

command! CopyRelativePath
\ let @*=join(remove( split( expand( '%:p' ), "/" ), len( split( getcwd(), "/" ) ), -1 ), "/") | echo "copied"

command! CopyFullPath
\ let @*=expand('%') | echo "copied"

set whichwrap=b,s,h,l,<,>,[,]
set backspace=indent,eol,start

" uncrustify
" autocmd FileType c,cpp,objc nnoremap <buffer>,cf :call UncrustifyAuto()<CR>
" autocmd BufWritePre <buffer> :call UncrustifyAuto()

" uncrustifyの設定ファイル
let g:uncrustify_cfg_file_path = '~/.uncrustifyconfig'

" uncrustifyでフォーマットする言語
let g:uncrustify_lang = ""
autocmd FileType c let g:uncrustify_lang = "c"
autocmd FileType cpp let g:uncrustify_lang = "cpp"
autocmd FileType objc let g:uncrustify_lang = "oc"

" Restore cursor position, window position, and last search after running a
" command.
function! Preserve(command)
    " Save the last search.
    let search = @/
    " Save the current cursor position.
    let cursor_position = getpos('.')
    " Save the current window position.
    normal! H
    let window_position = getpos('.')
    call setpos('.', cursor_position)
    " Execute the command.
    execute a:command
    " Restore the last search.
    let @/ = search
    " Restore the previous window position.
    call setpos('.', window_position)
    normal! zt
    " Restore the previous cursor position.
    call setpos('.', cursor_position)
endfunction

" Don't forget to add Uncrustify executable to $PATH (on Unix) or
" %PATH% (on Windows) for this command to work.
function! Uncrustify(language)
    call Preserve(':silent %!uncrustify'.' -q '.' -l '.a:language.' -c '.
                \shellescape(fnamemodify(g:uncrustify_cfg_file_path, ':p')))
endfunction

function! UncrustifyAuto()
    if g:uncrustify_lang != ""
        call Uncrustify(g:uncrustify_lang)
    endif
endfunction

set wildignore+=**/tmp/,*.so,*.swp,*.zip
set scrolloff=3

