" let g:dein#auto_recache = 1
let mapleader = "\<Space>"

" reset augroup
augroup MyAutoCmd
  autocmd!
augroup END

" dein settings {{{
if &compatible
  set nocompatible
endif

" dein.vimのディレクトリ
let s:dein_dir = expand('~/.cache/dein')
let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'

" なければgit clone
if !isdirectory(s:dein_repo_dir)
  execute '!git clone https://github.com/Shougo/dein.vim' s:dein_repo_dir
endif
execute 'set runtimepath^=' . s:dein_repo_dir

if dein#load_state(s:dein_dir)
  call dein#begin(s:dein_dir)

  " 管理するプラグインを記述したファイル
  let s:toml = '~/dotfiles/.dein.toml'
  let s:comp = '~/dotfiles/.dein.comp.toml'
  " let s:comp = '~/dotfiles/.dein.ddc.toml'
  let s:lazy_toml = '~/dotfiles/.dein_lazy.toml'
  call dein#load_toml(s:toml, {'lazy': 0})
  call dein#load_toml(s:comp, {'lazy': 0})
  call dein#load_toml(s:lazy_toml, {'lazy': 1})

  call dein#end()
  call dein#save_state()
endif

if dein#check_install()
  call dein#install()
endif
" }}}

"" plugin remove check {{{
let s:removed_plugins = dein#check_clean()
if len(s:removed_plugins) > 0
  " call map(dein#check_clean(), "delete(v:val, 'rf')")
  call map(s:removed_plugins, "delete(v:val, 'rf')")
  call dein#recache_runtimepath()
endif
" }}}

filetype plugin indent on
syntax enable
set termguicolors
set number             "行番号を表示
set autoindent         "改行時に自動でインデントする
set tabstop=2          "タブを何文字の空白に変換するか
set shiftwidth=2       "自動インデント時に入力する空白の数
set expandtab          "タブ入力を空白に変換
set splitright         "画面を縦分割する際に右に開く
set clipboard=unnamed,unnamedplus  "yank した文字列をクリップボードにコピー
set hls                "検索した文字をハイライトする
set ambiwidth=single
set guifont=Hack\ Nerd\ Font:h15

" WSL yank support
let s:clip = '/mnt/c/Windows/System32/clip.exe'  " change this path according to your mount point
if executable(s:clip)
    augroup WSLYank
        autocmd!
        autocmd TextYankPost * if v:event.operator ==# 'y' | call system(s:clip, @0) | endif
    augroup END
endif

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

" .vimrcを瞬時に開く
nnoremap <Space><Space>. :e ~/.config/nvim/init.vim<CR>

" vimrcの設定を反映
nnoremap <Space><Space>.. :<C-u>source ~/.config/nvim/init.vim<CR>

" カーソル下の単語を置換
nnoremap g/ :<C-u>%s/<C-R><C-w>//gc<Left><Left><Left>

" ビジュアルモードで選択した部分を置換
vnoremap g/ y:<C-u>%s/<C-R>"//gc<Left><Left><Left>
noremap  <Space><Space>ad y:<C-u>:g/^$/d<CR>

" 行末までをヤンク
nnoremap Y y$

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

" visualmodeでインテントを＞＜の連打で変更できるようにする
vnoremap < <gv
vnoremap > >gv

" ファイルを開いた時に最後のカーソル位置を再現する
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif

" 無限undo
if has('persistent_undo')
  set undodir=~/.cache/undo
  set undofile
endif

" ターミナルでマウスを使用できるようにする
set mouse=a
set guioptions+=a

" 全角スペースの表示
highlight ZenkakuSpace cterm=underline ctermfg=lightblue guibg=darkgray
match ZenkakuSpace /　/

hi clear CursorLine
hi CursorLine gui=underline
highlight CursorLine ctermbg=black guibg=black

" コマンド実行中は再描画しない
set lazyredraw
set ttyfast

" 検索時のハイライトを解除する
" and
" quickfixを閉じる
nnoremap <ESC><ESC> :nohlsearch<CR> <cmd>ccl<CR> :lua for _, win in ipairs(vim.api.nvim_list_wins()) do local config = vim.api.nvim_win_get_config(win); if config.relative ~= "" then vim.api.nvim_win_close(win, false); print('Closing window', win) end end<CR><ESC>

" 検索時に次にいかないようにする
nmap * *N

" 保存時に行末の空白を除去する
autocmd BufWritePre * :%s/\s\+$//ge
" autocmd BufWritePre * :%s/\//g

" Set internal encoding of vim, not needed on neovim, since coc.nvim using some
" unicode characters in the file autoload/float.vim
set encoding=utf-8

" TextEdit might fail if hidden is not set.
set hidden

" Some servers have issues with backup files, see #649.
set nobackup
set nowritebackup

" Give more space for displaying messages.
set cmdheight=2

" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

" Don't pass messages to |ins-completion-menu|.
set signcolumn=yes

" set completeopt+=noselect
set completeopt=menuone,noinsert,noselect
set shortmess+=c

" 検索
set ignorecase
set smartcase

" 爆速のgrepであるagを使いたい
" nnoremap gg/  :<C-u>Ag <C-R><C-w><CR>
" vnoremap gg/ y:<C-u>Ag <C-R>"<CR>

let s:stop_time = 10

function! s:down(timer) abort
  execute "normal! 3\<C-e>3j"
endfunction

function! s:up(timer) abort
  execute "normal! 3\<C-y>3k"
endfunction

function! s:smooth_scroll(fn) abort
  let working_timer = get(s:, 'smooth_scroll_timer', 0)
  if !empty(timer_info(working_timer))
    call timer_stop(working_timer)
  endif
  if (a:fn ==# 'down' && line('$') == line('w$')) ||
        \ (a:fn ==# 'up' && line('w0') == 1)
    return
  endif
  let s:smooth_scroll_timer = timer_start(s:stop_time, function('s:' . a:fn), {'repeat' : &scroll/3})
endfunction

nnoremap <silent> <C-u> <cmd>call <SID>smooth_scroll('up')<CR>
nnoremap <silent> <C-d> <cmd>call <SID>smooth_scroll('down')<CR>
vnoremap <silent> <C-u> <cmd>call <SID>smooth_scroll('up')<CR>
vnoremap <silent> <C-d> <cmd>call <SID>smooth_scroll('down')<CR>

if exists('$WAYLAND_DISPLAY')
  " clipboard on wayland with newline fix
  let g:clipboard = {
    \   'name': 'WL-Clipboard with ^M Trim',
    \   'copy': {
    \      '+': 'wl-copy --foreground --type text/plain',
    \      '*': 'wl-copy --foreground --type text/plain --primary',
    \    },
    \   'paste': {
    \      '+': {-> systemlist('wl-paste --no-newline | sed -e "s/\r$//"', '', 1)},
    \      '*': {-> systemlist('wl-paste --no-newline --primary | sed -e "s/\r$//"', '', 1)},
    \   },
    \   'cache_enabled': 1,
    \ }
endif


tnoremap <Esc> <C-\><C-n>
command! -nargs=* T split | wincmd j | resize 20 | terminal <args>
autocmd TermOpen * startinsert

set pumblend=10      " 0 〜 100 が指定できます。ドキュメントによると 5 〜 30 くらいが適当だそうです。

" 以下はおまけ。ここでは Denite の設定を載せていますが、
" 同様の仕組みで任意のウィンドウを半透明化できるでしょう。
augroup transparent-windows
  autocmd!
  autocmd FileType denite set winblend=10  " こちらも 5 〜 30 で試してみてください。
  autocmd FileType denite-filter set winblend=10
augroup END

" macm Edit.Paste key=<nop>
tmap <D-v> <C-w>"+
nnoremap <D-v> "+p
vnoremap <D-v> "+p
inoremap <D-v> <C-R><C-O>+
cnoremap <D-v> <C-R><C-O>+
