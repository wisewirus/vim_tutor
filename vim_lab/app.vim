" Vim Lab uses the real editor: no emulated motions or editing shortcuts.
if v:version < 802 || !exists('*json_decode') || !exists('*win_execute')
  echoerr 'Vim Lab needs Vim 8.2+ with JSON support.'
  cquit
endif

set nocompatible encoding=utf-8
set shortmess+=I noswapfile nobackup nowritebackup noundofile
set hidden noerrorbells novisualbell t_vb=
set backspace=indent,eol,start whichwrap= wildmenu
set incsearch hlsearch ignorecase smartcase wrapscan
set laststatus=2 showtabline=2 noshowmode noruler noshowcmd
set splitbelow splitright equalalways
set scrolloff=3 sidescrolloff=5 timeoutlen=500 ttimeoutlen=50
set mouse= lazyredraw
set fillchars=vert:│,eob:\ 
set background=dark
if has('termguicolors') && ($COLORTERM =~# 'truecolor\|24bit' || $TERM =~# 'kitty\|direct\|alacritty')
  set termguicolors
endif

highlight Normal       ctermfg=253 ctermbg=234 guifg=#d5e3df guibg=#11191c
highlight NonText      ctermfg=238 ctermbg=234 guifg=#2a3b3e guibg=#11191c
highlight EndOfBuffer  ctermfg=234 ctermbg=234 guifg=#11191c guibg=#11191c
highlight VertSplit    ctermfg=238 ctermbg=234 guifg=#2a3b3e guibg=#11191c cterm=NONE gui=NONE
highlight LineNr       ctermfg=240 ctermbg=234 guifg=#52676b guibg=#11191c
highlight CursorLineNr ctermfg=121 ctermbg=235 guifg=#80e8bf guibg=#192428 cterm=bold gui=bold
highlight CursorLine   ctermbg=235 guibg=#192428 cterm=NONE gui=NONE
highlight Visual       ctermfg=253 ctermbg=60 guifg=#e3efea guibg=#345854
highlight Search       ctermfg=234 ctermbg=179 guifg=#11191c guibg=#e6c478
highlight IncSearch    ctermfg=234 ctermbg=121 guifg=#11191c guibg=#80e8bf
highlight StatusLine   ctermfg=250 ctermbg=236 guifg=#b7cbc3 guibg=#223034 cterm=NONE gui=NONE
highlight StatusLineNC ctermfg=244 ctermbg=235 guifg=#71878a guibg=#192428 cterm=NONE gui=NONE
highlight TabLineFill  ctermfg=245 ctermbg=235 guifg=#83999b guibg=#192428 cterm=NONE gui=NONE
highlight LabBrand     ctermfg=121 ctermbg=235 guifg=#80e8bf guibg=#192428 cterm=bold gui=bold
highlight LabTitle     ctermfg=255 guifg=#edf5f0 cterm=bold gui=bold
highlight LabAccent    ctermfg=121 guifg=#80e8bf cterm=bold gui=bold
highlight LabMuted     ctermfg=244 guifg=#71878a
highlight LabSoft      ctermfg=250 guifg=#b7cbc3
highlight LabKey       ctermfg=179 guifg=#e6c478
highlight LabRule      ctermfg=238 guifg=#2a3b3e
highlight LabTarget    ctermfg=234 ctermbg=179 guifg=#11191c guibg=#e6c478 cterm=bold gui=bold
highlight LabNormal    ctermfg=234 ctermbg=121 guifg=#11191c guibg=#80e8bf cterm=bold gui=bold
highlight LabInsert    ctermfg=234 ctermbg=179 guifg=#11191c guibg=#e6c478 cterm=bold gui=bold
highlight LabVisual    ctermfg=234 ctermbg=147 guifg=#11191c guibg=#b6b2ef cterm=bold gui=bold

let s:config = json_decode(join(readfile($VIM_LAB_CONFIG), "\n"))
let s:lessons = s:config.lessons
let s:progress = s:config.progress
let s:warning = s:config.warning
let s:selected = s:config.initial
let s:active = -1
let s:sandbox = 0
let s:stage = 0
let s:solved = 0
let s:hint = 0
let s:loading = 0
let s:saves = 0
let s:saves_before_goal = 0
let s:menu_buf = -1
let s:preview_buf = -1
let s:practice_buf = -1
let s:guide_buf = -1
let s:menu_rows = []
let s:message = ''
let s:sid = expand('<SID>')

function! s:Done(index) abort
  return index(s:progress.completed, s:lessons[a:index].id) >= 0
endfunction

function! s:NextUnfinished() abort
  for i in range(len(s:lessons))
    if !s:Done(i)
      return i
    endif
  endfor
  return s:selected
endfunction

function! s:SaveProgress() abort
  let temporary = s:config.progress_path . '.tmp-' . getpid()
  try
    let s:progress.updated_at = strftime('%Y-%m-%dT%H:%M:%S%z')
    if writefile([json_encode(s:progress)], temporary) != 0 || rename(temporary, s:config.progress_path) != 0
      throw 'write failed'
    endif
    let s:warning = ''
  catch
    let s:warning = 'Progress could not be saved. This session still remembers it.'
    call delete(temporary)
  endtry
endfunction

function! s:Add(lines, spans, value, ...) abort
  call add(a:lines, a:value)
  if a:0 && !empty(a:value)
    call add(a:spans, [a:1, len(a:lines)])
  endif
endfunction

function! s:Wrap(value, width) abort
  let result = []
  let current = ''
  for word in split(a:value)
    if !empty(current) && strdisplaywidth(current . ' ' . word) > a:width
      call add(result, current)
      let current = word
    else
      let current .= (empty(current) ? '' : ' ') . word
    endif
  endfor
  if !empty(current)
    call add(result, current)
  endif
  return empty(result) ? [''] : result
endfunction

function! s:Paragraph(lines, spans, value, width, group) abort
  for part in s:Wrap(a:value, max([15, a:width - 4]))
    call s:Add(a:lines, a:spans, '  ' . part, a:group)
  endfor
endfunction

function! s:ApplyPaint() abort
  call clearmatches()
  for item in get(b:, 'lab_spans', [])
    call matchaddpos(item[0], [item[1]], 10)
  endfor
endfunction

function! s:Render(buffer, lines, spans) abort
  if !bufexists(a:buffer)
    return
  endif
  call setbufvar(a:buffer, '&modifiable', 1)
  call setbufline(a:buffer, 1, a:lines)
  if len(getbufline(a:buffer, 1, '$')) > len(a:lines)
    call deletebufline(a:buffer, len(a:lines) + 1, '$')
  endif
  call setbufvar(a:buffer, '&modified', 0)
  call setbufvar(a:buffer, '&modifiable', 0)
  call setbufvar(a:buffer, 'lab_spans', a:spans)
  let window = bufwinid(a:buffer)
  if window != -1
    call win_execute(window, 'call ' . s:sid . 'ApplyPaint()')
  endif
endfunction

function! s:UIBuffer(kind) abort
  setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
  setlocal nonumber norelativenumber nocursorline nowrap nospell
  setlocal undolevels=-1 signcolumn=no foldcolumn=0
  let b:lab_kind = a:kind
  nnoremap <silent><buffer> q :qa!<CR>
  nnoremap <silent><buffer> <CR> :call <SID>OpenSelected()<CR>
  nnoremap <silent><buffer> s :call <SID>Sandbox()<CR>
  nnoremap <silent><buffer> r :call <SID>Resume()<CR>
endfunction

function! VimLabTabline() abort
  let done = len(s:progress.completed)
  let tagline = &columns >= 100 ? '   a little practice, every day' : ''
  return '%#LabBrand#  V I M / L A B  %#TabLineFill#' . tagline
        \ . '%=%#LabBrand# ' . printf('%02d', done) . '%#TabLineFill# / ' . len(s:lessons)
        \ . ' complete   ' . printf('%d', done * 100 / len(s:lessons)) . '%%  '
endfunction

function! VimLabStatus() abort
  let buffer = winbufnr(g:statusline_winid)
  let kind = getbufvar(buffer, 'lab_kind', '')
  if kind ==# 'menu'
    return '%#StatusLine#  j/k select  ↵ open  q quit '
  elseif kind ==# 'preview'
    return '%#StatusLineNC#  Go at your own pace. No timer. '
  elseif kind ==# 'guide'
    return '%#StatusLineNC#  F1 hint  F2 course  F5 reset '
  endif
  let current = mode()
  let label = 'NORMAL'
  let group = 'LabNormal'
  if current =~# '^[iR]'
    let label = current =~# '^R' ? 'REPLACE' : 'INSERT'
    let group = 'LabInsert'
  elseif current =~# '^[vV\x16]'
    let label = 'VISUAL'
    let group = 'LabVisual'
  elseif current ==# 'c'
    let label = 'COMMAND'
    let group = 'LabInsert'
  endif
  let title = s:sandbox ? 'free practice' : s:active >= 0 ? printf('%02d', s:active + 1) . ' / ' . len(s:lessons) : 'practice'
  let action = s:solved ? '  F8 next' : '  F1 hint'
  return '%#' . group . '#  ' . label . '  %#StatusLine#  ' . title . '%m'
        \ . '%=' . action . '   %l:%c  '
endfunction

set tabline=%!VimLabTabline()
set statusline=%!VimLabStatus()

function! s:MenuKeys() abort
  nnoremap <silent><buffer> j :call <SID>Select(1)<CR>
  nnoremap <silent><buffer> k :call <SID>Select(-1)<CR>
  nnoremap <silent><buffer> <Down> :call <SID>Select(1)<CR>
  nnoremap <silent><buffer> <Up> :call <SID>Select(-1)<CR>
  nnoremap <silent><buffer> <Tab> :call <SID>Select(1)<CR>
  nnoremap <silent><buffer> <S-Tab> :call <SID>Select(-1)<CR>
  nnoremap <silent><buffer> <C-d> :call <SID>Select(5)<CR>
  nnoremap <silent><buffer> <C-u> :call <SID>Select(-5)<CR>
  nnoremap <silent><buffer> gg :call <SID>Select(-100)<CR>
  nnoremap <silent><buffer> G :call <SID>Select(100)<CR>
endfunction

function! s:Dashboard() abort
  let s:loading = 1
  let s:active = -1
  let s:sandbox = 0
  let s:solved = 0
  let s:message = ''
  silent! only!
  silent! enew!
  call s:UIBuffer('menu')
  call s:MenuKeys()
  setlocal cursorline
  let s:menu_buf = bufnr('%')
  let menu_window = win_getid()
  let sidebar = &columns >= 88 ? 33 : 30
  execute 'botright vertical ' . max([25, &columns - sidebar - 1]) . 'new'
  call s:UIBuffer('preview')
  let s:preview_buf = bufnr('%')
  call win_gotoid(menu_window)
  let s:loading = 0
  call s:RenderMenu()
  call s:RenderPreview()
  silent! nohlsearch
  redraw!
endfunction

function! s:RenderMenu() abort
  let lines = ['']
  let spans = []
  call s:Add(lines, spans, '  THE COURSE', 'LabAccent')
  call s:Add(lines, spans, '  24 small, guided exercises', 'LabMuted')
  call s:Add(lines, spans, '')
  let done = len(s:progress.completed)
  call s:Add(lines, spans, '  ' . repeat('━', done) . repeat('─', len(s:lessons) - done), 'LabAccent')
  call s:Add(lines, spans, '  ' . done . ' complete · ' . (len(s:lessons) - done) . ' to explore', 'LabMuted')
  let s:menu_rows = []
  let chapter = -1
  for i in range(len(s:lessons))
    let item = s:lessons[i]
    if item.chapter != chapter
      let chapter = item.chapter
      call s:Add(lines, spans, '')
      call s:Add(lines, spans, '  ' . printf('%02d', chapter + 1) . '  ' . toupper(s:config.chapters[chapter]), 'LabMuted')
    endif
    let marker = s:Done(i) ? '✓' : '·'
    call s:Add(lines, spans, '  ' . marker . '  ' . printf('%02d', i + 1) . '  ' . item.title, s:Done(i) ? 'LabSoft' : 'LabMuted')
    call add(s:menu_rows, len(lines))
    if i == s:selected
      call add(spans, ['LabAccent', len(lines)])
    endif
  endfor
  call s:Add(lines, spans, '')
  call s:Add(lines, spans, '  s  Free practice', 'LabKey')
  call s:Add(lines, spans, '  r  Resume learning', 'LabKey')
  call s:Render(s:menu_buf, lines, spans)
  let window = bufwinid(s:menu_buf)
  if window != -1
    call win_execute(window, 'call cursor(' . s:menu_rows[s:selected] . ', 3)')
  endif
endfunction

function! s:RenderPreview() abort
  if !bufexists(s:preview_buf)
    return
  endif
  let item = s:lessons[s:selected]
  let width = winwidth(bufwinid(s:preview_buf))
  let lines = ['']
  let spans = []
  call s:Add(lines, spans, '  LESSON ' . printf('%02d', s:selected + 1) . ' / ' . len(s:lessons), 'LabAccent')
  call s:Add(lines, spans, '')
  call s:Paragraph(lines, spans, item.title, width, 'LabTitle')
  call s:Add(lines, spans, '  ' . s:config.chapters[item.chapter] . ' · about ' . item.minutes . ' min', 'LabMuted')
  call s:Add(lines, spans, '')
  call s:Paragraph(lines, spans, item.intro, width, 'LabSoft')
  call s:Add(lines, spans, '')
  call s:Add(lines, spans, '  YOUR TOOLKIT', 'LabMuted')
  for pair in item.keys
    call s:Paragraph(lines, spans, printf('%-12s', pair[0]) . '  ' . pair[1], width, 'LabKey')
  endfor
  call s:Add(lines, spans, '')
  call s:Add(lines, spans, '  FIRST GOAL', 'LabMuted')
  call s:Paragraph(lines, spans, item.goals[0].prompt, width, 'LabSoft')
  call s:Add(lines, spans, '')
  call s:Add(lines, spans, s:Done(s:selected) ? '  ✓ Completed. Practice it again.' : '  Ready when you are.', 'LabAccent')
  call s:Add(lines, spans, '  Enter  start   ·   r  resume   ·   s  sandbox', 'LabKey')
  if !empty(s:warning)
    call s:Add(lines, spans, '')
    call s:Paragraph(lines, spans, s:warning, width, 'LabKey')
  endif
  call s:Render(s:preview_buf, lines, spans)
  call win_execute(bufwinid(s:preview_buf), 'normal! gg')
endfunction

function! s:Select(delta) abort
  let s:selected = min([len(s:lessons) - 1, max([0, s:selected + a:delta])])
  call s:RenderMenu()
  call s:RenderPreview()
endfunction

function! s:OpenSelected() abort
  if s:active < 0 && !s:sandbox
    call s:OpenLesson(s:selected)
  else
    call s:FocusPractice()
  endif
endfunction

function! s:Resume() abort
  call s:OpenLesson(s:NextUnfinished())
endfunction

function! s:FocusPractice() abort
  let window = bufwinid(s:practice_buf)
  if window != -1
    call win_gotoid(window)
  endif
endfunction

function! s:OpenLesson(index) abort
  let s:selected = a:index
  let s:active = a:index
  let s:sandbox = 0
  let s:lesson = s:lessons[a:index]
  let s:progress.last_lesson = s:lesson.id
  call s:SaveProgress()
  call s:OpenPractice()
endfunction

function! s:Sandbox() abort
  let s:active = -1
  let s:sandbox = 1
  let s:lesson = s:config.sandbox
  call s:OpenPractice()
endfunction

function! s:OpenPractice() abort
  let s:loading = 1
  let s:stage = 0
  let s:solved = 0
  let s:hint = 0
  let s:message = ''
  let s:saves = 0
  let s:saves_before_goal = 0
  silent! only!
  silent! enew!
  let filename = s:config.scratch . '/' . s:lesson.id . '.txt'
  call writefile(s:lesson.lines, filename)
  execute 'silent edit! ' . fnameescape(filename)
  let s:practice_buf = bufnr('%')
  let b:lab_kind = 'practice'
  setlocal bufhidden=wipe noswapfile number norelativenumber cursorline
  setlocal nowrap noautoindent nosmartindent nocindent nospell textwidth=0
  setlocal undolevels=1000 signcolumn=no foldcolumn=0
  setlocal list listchars=tab:›\ ,trail:·,extends:›,precedes:‹
  let b:lab_spans = []
  syntax clear
  syntax match LabMuted /^#.*$/
  syntax region LabKey start=/"/ end=/"/
  let practice_window = win_getid()
  if &columns >= 100
    topleft vertical 38new
    let s:stacked = 0
  else
    execute 'topleft ' . max([5, min([11, &lines / 2])]) . 'new'
    let s:stacked = 1
  endif
  call s:UIBuffer('guide')
  " Enter in the guide returns focus to the practice buffer.
  nnoremap <silent><buffer> <CR> :call <SID>FocusPractice()<CR>
  let s:guide_buf = bufnr('%')
  call win_gotoid(practice_window)
  call cursor(s:lesson.cursor[0], s:lesson.cursor[1])
  silent! nohlsearch
  let @/ = ''
  let s:loading = 0
  call s:RenderGuide()
  call s:PaintTarget()
  redraw!
endfunction

function! s:KeySummary(keys) abort
  return join(map(copy(a:keys), {_, pair -> pair[0] . ' ' . pair[1]}), '  ·  ')
endfunction

function! s:RenderGuide() abort
  if !bufexists(s:guide_buf)
    return
  endif
  let window = bufwinid(s:guide_buf)
  if window == -1
    return
  endif
  let width = winwidth(window)
  let lines = []
  let spans = []
  let header = s:sandbox ? 'FREE PRACTICE' : 'LESSON ' . printf('%02d', s:active + 1) . ' / ' . len(s:lessons) . '  ·  ' . toupper(s:config.chapters[s:lesson.chapter])
  call s:Add(lines, spans, '  ' . header, 'LabAccent')
  call s:Paragraph(lines, spans, s:lesson.title, width, 'LabTitle')
  call s:Add(lines, spans, '')
  if !s:stacked
    call s:Paragraph(lines, spans, s:lesson.intro, width, 'LabSoft')
    call s:Add(lines, spans, '')
    call s:Add(lines, spans, '  YOUR TOOLKIT', 'LabMuted')
    for pair in s:lesson.keys
      call s:Paragraph(lines, spans, pair[0] . '  ·  ' . pair[1], width, 'LabKey')
    endfor
    call s:Add(lines, spans, '')
    call s:Add(lines, spans, '  ' . repeat('─', max([5, width - 4])), 'LabRule')
    call s:Add(lines, spans, '')
  else
    if s:sandbox
      call s:Paragraph(lines, spans, 'h j k l move  ·  i insert  ·  Esc normal  ·  u undo  ·  . repeat', width, 'LabKey')
    else
      call s:Paragraph(lines, spans, s:KeySummary(s:lesson.keys), width, 'LabKey')
    endif
    call s:Add(lines, spans, '')
  endif
  if s:sandbox
    call s:Add(lines, spans, '  Make yourself at home.', 'LabAccent')
    call s:Paragraph(lines, spans, s:lesson.intro, width, 'LabSoft')
    if s:hint && s:stacked
      for pair in s:lesson.keys
        call s:Paragraph(lines, spans, pair[0] . '  ·  ' . pair[1], width, 'LabKey')
      endfor
    endif
  elseif s:solved
    call s:Add(lines, spans, '  ✓  LESSON COMPLETE', 'LabAccent')
    if s:active == len(s:lessons) - 1
      call s:Paragraph(lines, spans, 'You brought the commands together. Keep practicing until they feel familiar.', width, 'LabSoft')
      call s:Add(lines, spans, '  F8  return to the course', 'LabKey')
    else
      call s:Paragraph(lines, spans, 'Next: ' . s:lessons[s:active + 1].title, width, 'LabSoft')
      call s:Add(lines, spans, '  F8  continue when ready', 'LabKey')
    endif
  else
    call s:Add(lines, spans, '  GOAL ' . (s:stage + 1) . ' / ' . len(s:lesson.goals), 'LabAccent')
    call s:Paragraph(lines, spans, s:lesson.goals[s:stage].prompt, width, 'LabTitle')
    if s:hint
      call s:Add(lines, spans, '')
      call s:Paragraph(lines, spans, s:lesson.goals[s:stage].hint, width, 'LabKey')
    else
      call s:Add(lines, spans, '  F1  a hint if you need one', 'LabMuted')
    endif
    if s:stage > 0 && !s:stacked
      call s:Add(lines, spans, '')
      call s:Add(lines, spans, '  ✓ ' . s:stage . ' goal' . (s:stage == 1 ? '' : 's') . ' reached', 'LabAccent')
    endif
  endif
  if !empty(s:message)
    call s:Add(lines, spans, '')
    call s:Paragraph(lines, spans, s:message, width, 'LabKey')
  endif
  if !empty(s:warning)
    call s:Add(lines, spans, '')
    call s:Paragraph(lines, spans, s:warning, width, 'LabKey')
  endif
  call s:Render(s:guide_buf, lines, spans)
  " A stacked guide grows just enough for its current goal and hint.
  if s:stacked
    let height = max([4, min([len(lines), &lines - 9])])
    call win_execute(window, 'resize ' . height)
  endif
  call win_execute(window, 'normal! gg')
  if !s:stacked && !s:sandbox && winheight(window) < len(lines)
    " Keep the current goal visible in short terminals.
    let goal_line = match(lines, '^  \%(GOAL\|✓  LESSON\)') + 1
    if goal_line > 0
      call win_execute(window, 'call cursor(' . goal_line . ', 1) | normal! zb')
    endif
  endif
  redrawstatus
  redrawtabline
endfunction

function! s:PaintPracticeTarget() abort
  call clearmatches()
  if !s:sandbox && !s:solved && s:lesson.goals[s:stage].kind ==# 'cursor'
    let target = s:lesson.goals[s:stage].target
    call matchaddpos('LabTarget', [[target[0], target[1], 1]], 20)
  endif
endfunction

function! s:PaintTarget() abort
  let window = bufwinid(s:practice_buf)
  if window != -1
    call win_execute(window, 'call ' . s:sid . 'PaintPracticeTarget()')
  endif
endfunction

function! s:Check() abort
  if s:loading || s:sandbox || s:active < 0 || s:solved || bufnr('%') != s:practice_buf
    return
  endif
  " Edits are complete once the learner leaves Insert/Visual/Replace mode.
  if mode() =~# '^[iRvV\x16]'
    return
  endif
  let goal = s:lesson.goals[s:stage]
  if goal.kind ==# 'cursor'
    let reached = [line('.'), col('.')] == goal.target && getline(1, '$') == s:lesson.lines
  else
    let reached = getline(1, '$') == goal.target
    if goal.kind ==# 'write'
      let reached = reached && s:saves > s:saves_before_goal
    endif
  endif
  if !reached
    return
  endif
  let s:stage += 1
  let s:hint = 0
  let s:message = ''
  let s:saves_before_goal = s:saves
  if s:stage == len(s:lesson.goals)
    let s:solved = 1
    if !s:Done(s:active)
      call add(s:progress.completed, s:lesson.id)
    endif
    call s:SaveProgress()
  endif
  call s:RenderGuide()
  call s:PaintTarget()
endfunction

function! s:Written() abort
  if !s:loading && bufnr('%') == s:practice_buf
    let s:saves += 1
    call s:Check()
  endif
endfunction

function! s:Hint() abort
  if s:active < 0 && !s:sandbox
    return
  endif
  let s:hint = !s:hint
  call s:RenderGuide()
endfunction

function! s:Reset() abort
  if s:active >= 0 || s:sandbox
    call s:OpenPractice()
  endif
endfunction

function! s:Next() abort
  if s:active < 0
    return
  endif
  call s:Check()
  if !s:solved
    let s:message = 'Finish the current goal first, or use F2 to choose another lesson.'
    call s:RenderGuide()
  elseif s:active + 1 < len(s:lessons)
    call s:OpenLesson(s:active + 1)
  else
    call s:Dashboard()
  endif
endfunction

function! s:Resize() abort
  if s:loading
    return
  endif
  if s:active < 0 && !s:sandbox
    let sidebar = &columns >= 88 ? 33 : 30
    let window = bufwinid(s:menu_buf)
    if window != -1
      call win_execute(window, 'vertical resize ' . sidebar)
    endif
    call s:RenderPreview()
  else
    let guide_window = bufwinid(s:guide_buf)
    if guide_window == -1
      return
    endif
    if (&columns >= 100) == s:stacked
      " Move the existing split without replacing the practice buffer.
      call win_execute(guide_window, &columns >= 100 ? 'wincmd H | vertical resize 38' : 'wincmd K')
      let s:stacked = &columns < 100
    endif
    call s:RenderGuide()
  endif
endfunction

nnoremap <silent> <F1> :call <SID>Hint()<CR>
inoremap <silent> <F1> <C-O>:call <SID>Hint()<CR>
vnoremap <silent> <F1> <Esc>:call <SID>Hint()<CR>
nnoremap <silent> <F2> :call <SID>Dashboard()<CR>
inoremap <silent> <F2> <Esc>:call <SID>Dashboard()<CR>
vnoremap <silent> <F2> <Esc>:call <SID>Dashboard()<CR>
nnoremap <silent> <F5> :call <SID>Reset()<CR>
inoremap <silent> <F5> <Esc>:call <SID>Reset()<CR>
vnoremap <silent> <F5> <Esc>:call <SID>Reset()<CR>
nnoremap <silent> <F8> :call <SID>Next()<CR>
inoremap <silent> <F8> <Esc>:call <SID>Next()<CR>
vnoremap <silent> <F8> <Esc>:call <SID>Next()<CR>

command! Lessons call <SID>Dashboard()
command! Hint call <SID>Hint()
command! Reset call <SID>Reset()
command! Continue call <SID>Next()
command! Sandbox call <SID>Sandbox()

augroup VimLab
  autocmd!
  autocmd CursorMoved,TextChanged,InsertLeave * call <SID>Check()
  autocmd BufWritePost * call <SID>Written()
  autocmd VimResized * call <SID>Resize()
augroup END

if s:config.start ==# 'sandbox'
  call s:Sandbox()
elseif s:config.start ==# 'lesson'
  call s:OpenLesson(s:config.initial)
else
  call s:Dashboard()
endif
