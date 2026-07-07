vim9script

def Cfg(): dict<any>
  return loft#state#Get().config
enddef

def CreateScratchBuffer(winid: number): number
  var save = win_getid()
  if loft#utils#WindowExists(winid)
    win_gotoid(winid)
  endif
  enew
  setlocal buftype=nofile bufhidden=wipe noswapfile
  var buf = bufnr('%')
  if loft#utils#WindowExists(save)
    win_gotoid(save)
  endif
  return buf
enddef

def SetWinBuffer(winid: number, buf: number): void
  var save = win_getid()
  if !loft#utils#WindowExists(winid)
    return
  endif
  win_gotoid(winid)
  execute 'buffer ' .. buf
  if loft#utils#WindowExists(save)
    win_gotoid(save)
  endif
enddef

export def CloseBuffer(opts: dict<any> = {}): void
  loft#EnsureSetup()
  var force = !!get(opts, 'force', false)
  var current_buf = get(opts, 'buffer', -1)
  if current_buf <= 0
    current_buf = bufnr('%')
  endif
  if !force && getbufvar(current_buf, '&modified', 0)
    loft#utils#Notify('Buffer is modified. Force required.', 'error')
    return
  endif
  if !force && getbufvar(current_buf, '&buftype', '') ==# 'terminal'
    loft#utils#Notify('Buffer is a terminal. Force required.', 'error')
    return
  endif
  loft#registry#Clean()
  var registry = loft#registry#GetRegistry()
  var alt_buf = bufnr('#')
  var next_buf = -1
  var found = false
  for buf in registry
    if found
      next_buf = buf
      break
    endif
    if buf == current_buf
      found = true
    endif
  endfor
  if len(registry) > 1 && next_buf <= 0
    next_buf = registry[0]
  endif
  if next_buf == current_buf
    next_buf = -1
  endif
  loft#registry#PauseUpdate()
  for winid in win_findbuf(current_buf)
    if loft#utils#IsBufferValid(alt_buf, !get(Cfg(), 'auto_delete_missing_file_bufs', true)) && alt_buf != current_buf
      SetWinBuffer(winid, alt_buf)
    elseif next_buf > 0
      SetWinBuffer(winid, next_buf)
    else
      SetWinBuffer(winid, CreateScratchBuffer(winid))
    endif
  endfor
  execute 'silent! ' .. (force ? 'bdelete!' : 'bdelete') .. ' ' .. current_buf
  loft#registry#ResumeUpdate()
  loft#registry#Clean()
enddef

export def SwitchToBuffer(buf: number): void
  if !loft#utils#IsBufferValid(buf, !get(Cfg(), 'auto_delete_missing_file_bufs', true))
    return
  endif
  loft#registry#PauseUpdate()
  execute 'buffer ' .. buf
  loft#registry#ResumeUpdate()
enddef

export def SwitchToNextBuffer(): void
  loft#EnsureSetup()
  loft#registry#Clean()
  var next_buf = loft#registry#GetNextBuffer()
  if next_buf <= 0
    if !loft#utils#IsBufferValid(bufnr('%'), !get(Cfg(), 'auto_delete_missing_file_bufs', true))
      && get(Cfg(), 'close_invalid_buf_on_switch', true)
      loft#actions#CloseBuffer({force: true})
    endif
    return
  endif
  loft#registry#PauseUpdate()
  execute 'silent! buffer ' .. next_buf
  loft#registry#ResumeUpdate()
  loft#events#BufferSwitch(next_buf, 'next')
enddef

export def SwitchToPrevBuffer(): void
  loft#EnsureSetup()
  loft#registry#Clean()
  var prev_buf = loft#registry#GetPrevBuffer()
  if prev_buf <= 0
    if !loft#utils#IsBufferValid(bufnr('%'), !get(Cfg(), 'auto_delete_missing_file_bufs', true))
      && get(Cfg(), 'close_invalid_buf_on_switch', true)
      loft#actions#CloseBuffer({force: true})
    endif
    return
  endif
  loft#registry#PauseUpdate()
  execute 'silent! buffer ' .. prev_buf
  loft#registry#ResumeUpdate()
  loft#events#BufferSwitch(prev_buf, 'prev')
enddef

export def OpenLoft(): void
  loft#EnsureSetup()
  loft#ui#Open()
enddef

export def SwitchToNextMarkedBuffer(): void
  loft#EnsureSetup()
  loft#registry#Clean()
  var buf = loft#registry#GetMarkedBuffer('next')
  if buf <= 0
    return
  endif
  loft#registry#PauseUpdate()
  execute 'buffer ' .. buf
  loft#registry#ResumeUpdate()
  loft#events#BufferSwitch(buf, 'marked_next')
enddef

export def SwitchToPrevMarkedBuffer(): void
  loft#EnsureSetup()
  loft#registry#Clean()
  var buf = loft#registry#GetMarkedBuffer('prev')
  if buf <= 0
    return
  endif
  loft#registry#PauseUpdate()
  execute 'buffer ' .. buf
  loft#registry#ResumeUpdate()
  loft#events#BufferSwitch(buf, 'marked_prev')
enddef

export def ToggleMarkCurrentBuffer(opts: dict<any> = {}): void
  loft#EnsureSetup()
  var notify = get(opts, 'notify', true)
  var buf = bufnr('%')
  if !loft#utils#IsBufferValid(buf, !get(Cfg(), 'auto_delete_missing_file_bufs', true))
    return
  endif
  var marked = loft#registry#ToggleMarkBuffer(buf)
  if notify
    loft#utils#Notify(marked ? 'Marked' : 'Unmarked')
  endif
enddef

export def ToggleSmartOrder(opts: dict<any> = {}): void
  loft#EnsureSetup()
  var notify = get(opts, 'notify', true)
  var new_state = loft#ui#Toggle_smart_order()
  if !loft#ui#IsOpen() && notify
    loft#utils#Notify(new_state ? 'Smart Order is ON' : 'Smart Order is OFF')
  endif
enddef

export def SwitchToAltBuffer(): void
  loft#EnsureSetup()
  var alt_buf = bufnr('#')
  if alt_buf < 1 || !bufexists(alt_buf)
    loft#utils#Notify('No alternate buffer', 'error')
    return
  endif
  loft#registry#PauseUpdate()
  execute 'buffer #'
  loft#registry#ResumeUpdate()
  loft#events#BufferSwitch(bufnr('%'), 'alt')
enddef

export def MoveBufferUp(): void
  loft#EnsureSetup()
  loft#ui#MoveBufferUp()
enddef

export def MoveBufferDown(): void
  loft#EnsureSetup()
  loft#ui#MoveBufferDown()
enddef

export def CloseOthers(opts: dict<any> = {}): void
  loft#EnsureSetup()
  var force = !!get(opts, 'force', false)
  loft#registry#Clean()
  var current = bufnr('%')
  var targets: list<number> = []
  for buf in loft#registry#GetRegistry()
    if buf != current
      add(targets, buf)
    endif
  endfor
  for buf in targets
    loft#actions#CloseBuffer({
      force: force,
      buffer: buf,
    })
  endfor
enddef

export def CloseUnmarked(opts: dict<any> = {}): void
  loft#EnsureSetup()
  var force = !!get(opts, 'force', false)
  loft#registry#Clean()
  var targets: list<number> = []
  for buf in loft#registry#GetRegistry()
    if !loft#registry#IsBufferMarked(buf)
      add(targets, buf)
    endif
  endfor
  for buf in targets
    loft#actions#CloseBuffer({
      force: force,
      buffer: buf,
    })
  endfor
enddef
