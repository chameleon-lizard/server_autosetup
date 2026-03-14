" ============================================================================
" Minimal .vimrc, no plugins
" Requires: Vim 8.2.1381+ (matchfuzzy + popup)
" ============================================================================

set nocompatible
set number
set hidden
set laststatus=2
set cursorline
set wildmenu
set wildmode=longest:full,full
set incsearch
set hlsearch
set ignorecase
set smartcase
set encoding=utf-8
set backspace=indent,eol,start
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set autoindent

if !isdirectory($HOME . '/.vim/undodir')
  call mkdir($HOME . '/.vim/undodir', 'p')
endif
set undofile
set undodir=~/.vim/undodir

if !isdirectory($HOME . '/.vim/swapdir')
  call mkdir($HOME . '/.vim/swapdir', 'p')
endif
set directory=~/.vim/swapdir//

set ttimeoutlen=25

set wildignore+=*/.git/*,*/node_modules/*,*/__pycache__/*
set wildignore+=*.pyc,*.pyo,*.o,*.obj,*.so,*.a
set wildignore+=*.swp,*.swo,*.DS_Store
set wildignore+=*.egg-info/*,*/.mypy_cache/*,*/.venv/*

augroup format_options
  autocmd!
  autocmd FileType * setlocal formatoptions-=o formatoptions-=r formatoptions+=j
augroup END

syntax enable
colorscheme habamax
highlight CursorLine cterm=NONE ctermbg=236 guibg=#303030

" ── Statusline colors ─────────────────────────────────────────
highlight StlNormal  cterm=bold ctermbg=66  ctermfg=235 guibg=#5f8787 guifg=#262626
highlight StlInsert  cterm=bold ctermbg=108 ctermfg=235 guibg=#87af87 guifg=#262626
highlight StlVisual  cterm=bold ctermbg=172 ctermfg=235 guibg=#d78700 guifg=#262626
highlight StlReplace cterm=bold ctermbg=131 ctermfg=235 guibg=#af5f5f guifg=#262626
highlight StlFile    cterm=NONE ctermbg=238 ctermfg=250 guibg=#444444 guifg=#bcbcbc
highlight StlMid     cterm=NONE ctermbg=236 ctermfg=243 guibg=#303030 guifg=#767676
highlight StlPos     cterm=NONE ctermbg=238 ctermfg=250 guibg=#444444 guifg=#bcbcbc

function! StlMode() abort
  let l:m = mode()
  if l:m ==# 'n'
    return '%#StlNormal# NORMAL '
  elseif l:m ==# 'i'
    return '%#StlInsert# INSERT '
  elseif l:m ==# 'R'
    return '%#StlReplace# REPLACE '
  elseif l:m =~# '[vV]' || l:m ==# "\<C-v>"
    return '%#StlVisual# VISUAL '
  endif
  return '%#StlNormal# ' . toupper(l:m) . ' '
endfunction

set noshowmode
set statusline=
set statusline+=%{%StlMode()%}
set statusline+=%#StlFile#\ %f\ %m
set statusline+=%#StlMid#%=
set statusline+=%#StlPos#\ l%l\ \|\ c%c

let mapleader = " "

nnoremap <C-l> :nohlsearch<CR>

" Open visually selected path in a new buffer: Leader + o
function! s:OpenSelectedPath() abort
  let l:reg_save = getreg('"')
  let l:type_save = getregtype('"')
  normal! gvy
  let l:path = trim(getreg('"'))
  call setreg('"', l:reg_save, l:type_save)
  execute 'edit ' . fnameescape(l:path)
endfunction

vnoremap <silent> <Leader>o :<C-u>call <SID>OpenSelectedPath()<CR>

" ============================================================================
" 1. netrw: sidebar toggle via Ctrl+N
" ============================================================================
let g:netrw_banner    = 0
let g:netrw_liststyle = 3       " tree view
let g:netrw_browse_split = 4   " open files in previous window
let g:netrw_altv      = 1       " vertical split
let g:netrw_winsize   = 25      " panel width 25%

nnoremap <C-n> :Lexplore<CR>

function! s:NetrwRefreshWindow(winid) abort
  let l:save_winid = win_getid()

  if a:winid != 0 && win_gotoid(a:winid) && &filetype ==# 'netrw'
    call s:NetrwCall('LocalBrowseRefresh', [])
  endif

  if l:save_winid != win_getid()
    call win_gotoid(l:save_winid)
  endif
endfunction

function! s:NetrwCall(name, args) abort
  let l:map = maparg('<Plug>NetrwRefresh', 'n', 0, 1)
  if empty(l:map) || !has_key(l:map, 'sid')
    return ''
  endif

  let l:func = '<SNR>' . l:map.sid . '_' . a:name
  if !exists('*' . l:func)
    return ''
  endif

  return call(function(l:func), a:args)
endfunction

function! s:NetrwTargetDir() abort
  let l:base_dir = exists('b:netrw_curdir') ? b:netrw_curdir : getcwd()
  let l:entry = s:NetrwCall('NetrwGetWord', [])
  if type(l:entry) != type('') || empty(l:entry)
    return l:base_dir
  endif

  let l:path = s:NetrwCall('NetrwBrowseChgDir', [1, l:entry, 1, 1])
  if type(l:path) != type('') || empty(l:path)
    return l:base_dir
  endif

  return isdirectory(l:path) ? l:path : fnamemodify(l:path, ':h')
endfunction

function! s:NetrwCreateHere() abort
  let l:netrw_winid = win_getid()
  let l:edit_winid = winnr('#') > 0 ? win_getid(winnr('#')) : 0
  let l:target_dir = simplify(s:NetrwTargetDir())
  let l:default_path = l:target_dir =~# '/$' ? l:target_dir : l:target_dir . '/'

  call inputsave()
  let l:path = input('New file: ', l:default_path, 'file')
  call inputrestore()
  redraw
  if empty(l:path)
    return
  endif

  let l:path = fnamemodify(l:path, ':p')
  if getftype(l:path) !=# ''
    echo 'Already exists: ' . l:path
    return
  endif

  call writefile([], l:path)

  if l:edit_winid != 0 && l:edit_winid != l:netrw_winid && win_gotoid(l:edit_winid)
  elseif winnr('$') > 1
    wincmd p
  endif

  execute 'edit ' . fnameescape(l:path)
  call s:NetrwRefreshWindow(l:netrw_winid)
endfunction

" netrw keybinds: a = create file, d = delete file/dir
augroup netrw_custom
  autocmd!
  autocmd FileType netrw nnoremap <buffer> <silent> a :call <SID>NetrwCreateHere()<CR>
  autocmd FileType netrw nmap <buffer> d D
  autocmd FileType netrw setlocal statusline=%#StlMid#\ netrw
augroup END

" Wipe leftover empty unnamed buffers when a real file is opened
function! s:WipeEmptyBuffers() abort
  for l:b in range(1, bufnr('$'))
    if buflisted(l:b) && empty(bufname(l:b)) && !getbufvar(l:b, '&modified') && l:b != bufnr('%')
      execute 'bwipeout' l:b
    endif
  endfor
endfunction

augroup wipe_empty
  autocmd!
  autocmd BufReadPost * call s:WipeEmptyBuffers()
augroup END

" ============================================================================
" 2. Buffers: Tab/Shift+Tab cycling + visual tabline
" ============================================================================
nnoremap <Tab> :bnext<CR>
nnoremap <S-Tab> :bprevious<CR>

" Close current buffer: Leader + x
nnoremap <Leader>x :bp<bar>bd #<CR>

" Duplicate current file: Leader + d
function! s:DuplicateFile() abort
  let l:src = expand('%:p')
  if empty(l:src) | echo 'No file to duplicate' | return | endif
  let l:default = expand('%:p:r') . '.new.' . expand('%:e')
  if empty(expand('%:e')) | let l:default = l:src . '.new' | endif
  let l:dst = input('Copy to: ', l:default, 'file')
  if empty(l:dst) | return | endif
  call writefile(readfile(l:src, 'b'), l:dst, 'b')
  execute 'edit ' . fnameescape(l:dst)
  echo 'Created: ' . l:dst
endfunction

nnoremap <silent> <Leader>d :call <SID>DuplicateFile()<CR>

set showtabline=2

function! BufferTabLine()
  let s = ''
  let l:current = bufnr('%')
  for i in range(1, bufnr('$'))
    if !buflisted(i) | continue | endif
    if empty(bufname(i)) && !getbufvar(i, '&modified') | continue | endif
    let l:name = fnamemodify(bufname(i), ':t')
    if empty(l:name) | let l:name = '[No Name]' | endif
    let l:modified = getbufvar(i, '&modified') ? ' +' : ''
    if i == l:current
      let s .= '%#TabLineSel# ' . l:name . l:modified . ' %#TabLine#|'
    else
      let s .= '%#TabLine# ' . l:name . l:modified . ' |'
    endif
  endfor
  return s . '%#TabLineFill#'
endfunction

set tabline=%!BufferTabLine()

" ============================================================================
" 3. Comment toggle: Space + / (normal and visual mode)
" ============================================================================
let s:comment_map = {
  \ 'python': '#', 'sh': '#', 'bash': '#', 'yaml': '#', 'ruby': '#',
  \ 'vim': '"', 'lua': '--',
  \ 'javascript': '//', 'typescript': '//', 'c': '//', 'cpp': '//',
  \ 'java': '//', 'go': '//', 'rust': '//',
  \ }

augroup set_comment_char
  autocmd!
  autocmd FileType * let b:comment_char = get(s:comment_map, &filetype, '#')
augroup END

function! s:ToggleComment(line1, line2) abort
  let l:cc = get(b:, 'comment_char', '#')
  let l:all_commented = 1
  for l:lnum in range(a:line1, a:line2)
    let l:line = getline(l:lnum)
    if l:line =~# '^\s*$' | continue | endif
    if l:line !~# '^\s*' . escape(l:cc, '/\*')
      let l:all_commented = 0
      break
    endif
  endfor
  for l:lnum in range(a:line1, a:line2)
    let l:line = getline(l:lnum)
    if l:line =~# '^\s*$' | continue | endif
    if l:all_commented
      call setline(l:lnum, substitute(l:line, '^\(\s*\)' . escape(l:cc, '/\*') . '\s\?', '\1', ''))
    else
      call setline(l:lnum, substitute(l:line, '^\(\s*\)', '\1' . l:cc . ' ', ''))
    endif
  endfor
endfunction

command! -range ToggleComment call s:ToggleComment(<line1>, <line2>)
nnoremap <silent> <Leader>/ :ToggleComment<CR>
vnoremap <silent> <Leader>/ :ToggleComment<CR>

" ============================================================================
" 4. Copy to system clipboard: Ctrl+Y (native locally, OSC 52 over SSH)
" ============================================================================
function! s:UseNativeClipboard() abort
  return has('clipboard')
    \ && empty($SSH_CONNECTION)
    \ && empty($SSH_CLIENT)
    \ && empty($SSH_TTY)
endfunction

function! s:Osc52Sequence(text) abort
  let l:encoded = substitute(system('base64', a:text), '\n', '', 'g')
  let l:osc52 = "\x1b]52;c;" . l:encoded . "\x07"

  if exists('$TMUX') && !empty($TMUX)
    return "\x1bPtmux;" . substitute(l:osc52, "\x1b", "\x1b\x1b", 'g') . "\x1b\\"
  endif

  if &term =~# '^screen'
    return "\x1bP" . l:osc52 . "\x1b\\"
  endif

  return l:osc52
endfunction

function! s:ClipboardYank(text) abort
  if s:UseNativeClipboard()
    let @+ = a:text
  else
    call writefile([s:Osc52Sequence(a:text)], '/dev/tty', 'b')
  endif
  let l:preview = substitute(a:text, '\n', ' ', 'g')
  echo 'Copied: ' . l:preview
endfunction

nnoremap <silent> <C-y> :call <SID>ClipboardYank(getreg('"'))<CR>
vnoremap <silent> <C-y> y:<C-u>call <SID>ClipboardYank(getreg('"'))<CR>

" ============================================================================
" 5. Copy absolute file path: Ctrl+P
" ============================================================================
nnoremap <silent> <C-p> :call <SID>ClipboardYank(expand('%:p'))<CR>

" ============================================================================
" 6. Run current file directly: :RunThis / :runthis
"    Adds shebang automatically if missing (via `which`).
"    Prints "Not runnable file" for non-script filetypes.
" ============================================================================
let s:shebang_map = {
  \ 'python':     'python3',
  \ 'sh':         'sh',
  \ 'bash':       'bash',
  \ 'ruby':       'ruby',
  \ 'javascript': 'node',
  \ 'lua':        'lua',
  \ 'perl':       'perl',
  \ }

function! s:RunThis() abort
  let l:path = expand('%:p')
  if empty(l:path)
    echo 'No file to run'
    return
  endif

  if &modified
    update
  endif

  if getline(1) !~# '^#!'
    let l:ft = &filetype
    if !has_key(s:shebang_map, l:ft)
      echo 'Not runnable file'
      return
    endif
    let l:bin = s:shebang_map[l:ft]
    let l:interp = trim(system('which ' . shellescape(l:bin)))
    if empty(l:interp) || v:shell_error != 0
      echo 'Interpreter not found: ' . l:bin
      return
    endif
    call append(0, '#!' . l:interp)
    write
  endif

  call system('chmod u+x ' . shellescape(l:path))
  if v:shell_error != 0
    echo 'Failed to make file executable: ' . l:path
    return
  endif

  let l:dir = fnamemodify(l:path, ':h')
  let l:file = fnamemodify(l:path, ':t')
  execute '!cd ' . shellescape(l:dir) . ' && ./' . shellescape(l:file)
endfunction

command! RunThis call <SID>RunThis()
cnoreabbrev <expr> runthis getcmdtype() ==# ':' && getcmdline() ==# 'runthis' ? 'RunThis' : 'runthis'

" ============================================================================
" 7. Autocomplete popup after 3+ characters
" ============================================================================
set completeopt=menuone,noinsert,noselect
set shortmess+=c

inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <CR>    pumvisible() ? "\<C-y>" : "\<CR>"

function! s:TriggerAutoComplete() abort
  if pumvisible() | return | endif
  let l:col = col('.') - 1
  if l:col < 3 | return | endif
  let l:line = getline('.')
  let l:word = matchstr(l:line[:l:col - 1], '\k\+$')
  if len(l:word) >= 3
    call feedkeys("\<C-n>", 'n')
  endif
endfunction

augroup auto_complete
  autocmd!
  autocmd TextChangedI * call s:TriggerAutoComplete()
augroup END

" ============================================================================
" 8. Fuzzy finder via popup_menu + matchfuzzy
"    Space + F + A  —  file name search
"    Space + F + W  —  grep inside files
" ============================================================================

let s:fz_all_items = []
let s:fz_filtered  = []
let s:fz_query     = ''
let s:fz_mode      = ''
let s:fz_popup     = 0
let s:fz_job       = v:null
let s:fz_timer     = 0
let s:fz_indexing  = 0

function! s:FuzzyFiles() abort
  call s:FuzzyStop()
  let s:fz_all_items = []
  let s:fz_query     = ''
  let s:fz_mode      = 'files'
  let s:fz_filtered  = []
  let s:fz_indexing  = 1

  call s:FuzzyShowPopup()

  let s:fz_job = job_start(
    \ ['find', '.', '-type', 'f',
    \  '-not', '-path', '*/.git/*',
    \  '-not', '-path', '*/node_modules/*',
    \  '-not', '-path', '*/__pycache__/*',
    \  '-not', '-path', '*/.mypy_cache/*',
    \  '-not', '-path', '*/.venv/*'],
    \ #{out_cb: function('s:FuzzyOnStdout'),
    \   close_cb: function('s:FuzzyOnClose'),
    \   err_io: 'null'})

  let s:fz_timer = timer_start(100, function('s:FuzzyRefresh'), #{repeat: -1})
endfunction

function! s:FuzzyOnStdout(ch, msg) abort
  call add(s:fz_all_items, a:msg)
endfunction

function! s:FuzzyOnClose(ch) abort
  let s:fz_indexing = 0
endfunction

function! s:FuzzyRefresh(timer) abort
  if s:fz_popup == 0 | call timer_stop(a:timer) | return | endif
  call s:FuzzyUpdatePopup()
  if !s:fz_indexing
    call timer_stop(a:timer)
    let s:fz_timer = 0
    call s:FuzzyUpdatePopup()
  endif
endfunction

function! s:FuzzyStop() abort
  if s:fz_timer != 0
    call timer_stop(s:fz_timer)
    let s:fz_timer = 0
  endif
  if type(s:fz_job) == type(v:null)
  elseif job_status(s:fz_job) ==# 'run'
    call job_stop(s:fz_job)
  endif
  let s:fz_job = v:null
endfunction

function! s:FuzzyGrep() abort
  call s:FuzzyStop()
  let l:pattern = input('Grep pattern: ')
  redraw
  if empty(l:pattern) | return | endif

  let s:fz_all_items = []
  let s:fz_query     = ''
  let s:fz_mode      = 'grep'
  let s:fz_filtered  = []
  let s:fz_indexing  = 1

  call s:FuzzyShowPopup()

  let s:fz_job = job_start(
    \ ['grep', '-rn', l:pattern,
    \  '--include=*',
    \  '--exclude-dir=.git',
    \  '--exclude-dir=node_modules',
    \  '--exclude-dir=__pycache__', '.'],
    \ #{out_cb: function('s:FuzzyOnStdout'),
    \   close_cb: function('s:FuzzyOnClose'),
    \   err_io: 'null'})

  let s:fz_timer = timer_start(100, function('s:FuzzyRefresh'), #{repeat: -1})
endfunction

function! s:FuzzyShowPopup() abort
  let l:display = ['  (indexing...)']
  let l:title = s:FuzzyTitle()
  let s:fz_popup = popup_menu(l:display, #{
    \ filter:   function('s:FuzzyFilterKey'),
    \ callback: function('s:FuzzyOnSelect'),
    \ maxheight: 25,
    \ minwidth:  80,
    \ maxwidth:  120,
    \ border:    [],
    \ title:     l:title,
    \ padding:   [0, 1, 0, 1],
    \ pos:       'center',
    \ })
endfunction

function! s:FuzzyTitle() abort
  let l:labels = #{files: ' Files', grep: ' Grep', buffers: ' Buffers'}
  let l:label = get(l:labels, s:fz_mode, ' Search')
  let l:idx = s:fz_indexing ? ' ...' : ''
  return l:label . '  [' . s:fz_query . ']  (' . len(s:fz_filtered) . l:idx . ') '
endfunction

function! s:FuzzyUpdatePopup() abort
  if s:fz_popup == 0 | return | endif
  if empty(s:fz_query)
    let s:fz_filtered = s:fz_all_items[:99]
  else
    let s:fz_filtered = matchfuzzy(s:fz_all_items, s:fz_query)[:99]
  endif
  let l:display = empty(s:fz_filtered)
    \ ? [s:fz_indexing ? '  (indexing...)' : '  (no matches)']
    \ : s:fz_filtered
  call popup_settext(s:fz_popup, l:display)
  call popup_setoptions(s:fz_popup, #{title: s:FuzzyTitle()})
endfunction

function! s:FuzzyFilterKey(id, key) abort
  if a:key ==# "\<CR>" || a:key ==# "\<C-j>" || a:key ==# "\<Down>"
    \ || a:key ==# "\<C-k>" || a:key ==# "\<Up>"
    return popup_filter_menu(a:id, a:key ==# "\<C-j>" ? "\<Down>" : a:key ==# "\<C-k>" ? "\<Up>" : a:key)
  endif

  if a:key ==# "\<Esc>" || a:key ==# "\<C-c>"
    call popup_close(a:id, -1)
    return 1
  endif

  if a:key ==# "\<BS>"
    if !empty(s:fz_query)
      let s:fz_query = s:fz_query[:-2]
    endif
  elseif len(a:key) == 1 && a:key =~# '[[:print:]]'
    let s:fz_query .= a:key
  else
    return 0
  endif

  call s:FuzzyUpdatePopup()
  return 1
endfunction

function! s:FuzzyOnSelect(id, result) abort
  let s:fz_popup = 0
  call s:FuzzyStop()

  if a:result < 1 || a:result > len(s:fz_filtered)
    return
  endif
  let l:item = s:fz_filtered[a:result - 1]

  if s:fz_mode ==# 'buffers'
    let l:bufnr = str2nr(split(l:item, "\t")[0])
    execute 'buffer ' . l:bufnr
  elseif s:fz_mode ==# 'grep'
    let l:parts = split(l:item, ':')
    if len(l:parts) >= 2
      execute 'edit ' . fnameescape(l:parts[0])
      execute l:parts[1]
      normal! zz
    endif
  else
    execute 'edit ' . fnameescape(l:item)
  endif
endfunction

function! s:FuzzyBuffers() abort
  call s:FuzzyStop()
  let s:fz_all_items = []
  let s:fz_query     = ''
  let s:fz_mode      = 'buffers'
  let s:fz_indexing  = 0

  for l:b in range(1, bufnr('$'))
    if !buflisted(l:b) | continue | endif
    let l:name = bufname(l:b)
    if empty(l:name) && !getbufvar(l:b, '&modified') | continue | endif
    let l:label = empty(l:name) ? '[No Name]' : fnamemodify(l:name, ':~:.')
    let l:mod   = getbufvar(l:b, '&modified') ? ' [+]' : ''
    call add(s:fz_all_items, l:b . "\t" . l:label . l:mod)
  endfor

  let s:fz_filtered = copy(s:fz_all_items)
  call s:FuzzyShowPopup()
endfunction

nnoremap <silent> <Leader>fa :call <SID>FuzzyFiles()<CR>
nnoremap <silent> <Leader>fw :call <SID>FuzzyGrep()<CR>
nnoremap <silent> <Leader>fb :call <SID>FuzzyBuffers()<CR>
