vim9script

var state = loft#state#Get()

def Cfg(): dict<any>
  return state.config
enddef

def IsExcluded(buf: number): bool
  var excluded = get(Cfg(), 'exclude_buftypes', [])
  if empty(excluded)
    return false
  endif
  var buftype = getbufvar(buf, '&buftype', '')
  return index(excluded, buftype) >= 0
enddef

def RemoveFromRegistry(buf: number): void
  var idx = index(state.registry, buf)
  if idx >= 0
    remove(state.registry, idx)
  endif
enddef

def MarkedBuffers(): list<number>
  var marked: list<number> = []
  for buf in loft#registry#GetRegistry()
    if loft#registry#IsBufferMarked(buf)
      add(marked, buf)
    endif
  endfor
  return marked
enddef

def ClearRecentMarkedMappings(): void
  for key in state.recent_mark_keys
    execute 'silent! nunmap ' .. key
  endfor
  state.recent_mark_keys = []
enddef

def OnChange(): void
  loft#registry#KeymapRecentMarkedBuffers()
  loft#events#RegistryChanged()
enddef

export def Setup(): void
  state.registry = []
  state.update_paused = false
  state.update_paused_once = false
  state.is_smart_order_on = get(Cfg(), 'enable_smart_order_by_default', true)
  state.prev_winid = 0
  loft#registry#Clean()
enddef

export def GetRegistry(): list<number>
  return state.registry
enddef

export def PauseUpdate(): void
  state.update_paused = true
enddef

export def ResumeUpdate(): void
  state.update_paused = false
enddef

export def Update(buffer: number = -1): void
  var current_buf = bufnr('%')
  var buf = buffer > 0 ? buffer : current_buf
  if loft#utils#IsPopupWindow() || state.update_paused
    state.update_paused_once = false
    return
  endif
  if state.update_paused_once
    state.update_paused_once = false
    return
  endif
  var skip_deleted = !get(Cfg(), 'auto_delete_missing_file_bufs', true)
  if !loft#utils#IsBufferValid(buf, skip_deleted) || IsExcluded(buf)
    return
  endif
  var current_win = win_getid()
  var is_window_switch = state.prev_winid > 0 && current_win != state.prev_winid
  state.prev_winid = current_win

  current_buf = bufnr('%')
  buf = buffer > 0 ? buffer : current_buf
  var alt_buf = buf == current_buf ? bufnr('#') : -1
  var is_buffer_in_registry = index(state.registry, buf) >= 0
  var is_alt_in_registry = index(state.registry, alt_buf) >= 0
  var allow_smart_order = !is_window_switch || get(Cfg(), 'smart_order_on_window_switch', false)
  var should_smart_order_buf = state.is_smart_order_on
    && allow_smart_order
    && (!loft#registry#IsBufferMarked(buf) || get(Cfg(), 'smart_order_marked_bufs', false))
  var should_smart_order_alt_buf = should_smart_order_buf
    && get(Cfg(), 'smart_order_alt_bufs', true)
    && is_alt_in_registry
    && loft#utils#IsBufferValid(alt_buf, skip_deleted)
    && (!loft#registry#IsBufferMarked(alt_buf) || get(Cfg(), 'smart_order_marked_bufs', false))

  if is_buffer_in_registry && !should_smart_order_buf
    return
  endif
  if should_smart_order_buf
    RemoveFromRegistry(buf)
  endif
  if should_smart_order_alt_buf && alt_buf != buf
    RemoveFromRegistry(alt_buf)
    add(state.registry, alt_buf)
  endif
  add(state.registry, buf)
  loft#registry#Clean()
enddef

export def Clean(delete_missing: any = v:none): void
  var do_delete = type(delete_missing) == v:t_none
    ? get(Cfg(), 'auto_delete_missing_file_bufs', true)
    : !!delete_missing
  var skip_deleted = !do_delete
  var valid_registry: list<number> = []
  for buf in copy(state.registry)
    if loft#utils#IsBufferValid(buf, skip_deleted) && !IsExcluded(buf)
      add(valid_registry, buf)
    endif
  endfor
  if do_delete
    for buf in copy(state.registry)
      if loft#utils#BufHasDeletedFile(buf)
        execute 'silent! bdelete! ' .. buf
      endif
    endfor
  endif
  var all_valid: list<number> = []
  for buf in loft#utils#GetAllValidBuffers(skip_deleted)
    if !IsExcluded(buf)
      add(all_valid, buf)
    endif
  endfor
  state.registry = loft#utils#MergeDistinct(valid_registry, all_valid)
  OnChange()
enddef

export def GetNextBuffer(): number
  var registry = loft#registry#GetRegistry()
  var current_idx = loft#utils#GetIndex(registry, bufnr('%'))
  if current_idx == 0
    return -1
  endif
  if empty(registry)
    return -1
  endif
  if get(Cfg(), 'reverse_order', false)
    var next_idx = current_idx - 1
    if next_idx < 1
      next_idx = len(registry)
    endif
    return registry[next_idx - 1]
  endif
  return registry[current_idx % len(registry)]
enddef

export def GetPrevBuffer(): number
  var registry = loft#registry#GetRegistry()
  var current_idx = loft#utils#GetIndex(registry, bufnr('%'))
  if current_idx == 0
    return -1
  endif
  if empty(registry)
    return -1
  endif
  if get(Cfg(), 'reverse_order', false)
    return registry[current_idx % len(registry)]
  endif
  var prev_idx = current_idx - 1
  if prev_idx < 1
    prev_idx = len(registry)
  endif
  return registry[prev_idx - 1]
enddef

export def MoveBufferUp(buf_idx: number, cyclic: bool = false): void
  if buf_idx > 1
    var tmp = state.registry[buf_idx - 1]
    state.registry[buf_idx - 1] = state.registry[buf_idx - 2]
    state.registry[buf_idx - 2] = tmp
  elseif cyclic && len(state.registry) > 0
    var first = remove(state.registry, 0)
    add(state.registry, first)
  endif
  OnChange()
enddef

export def MoveBufferDown(buf_idx: number, cyclic: bool = false): void
  if buf_idx < len(state.registry)
    var tmp = state.registry[buf_idx - 1]
    state.registry[buf_idx - 1] = state.registry[buf_idx]
    state.registry[buf_idx] = tmp
  elseif cyclic && len(state.registry) > 0
    var last = remove(state.registry, -1)
    insert(state.registry, last, 0)
  endif
  OnChange()
enddef

export def IsBufferMarked(buffer: number): bool
  return !!getbufvar(buffer, loft#constants#MarkStateId(), false)
enddef

export def ToggleMarkBuffer(buffer: number): bool
  var new_state = !loft#registry#IsBufferMarked(buffer)
  setbufvar(buffer, loft#constants#MarkStateId(), new_state)
  loft#events#BufferMark(buffer, new_state)
  OnChange()
  return new_state
enddef

export def GetMarkedBuffer(direction: string, buffer: number = -1): number
  var registry = loft#registry#GetRegistry()
  var current_buf = buffer > 0 ? buffer : bufnr('%')
  var current_idx = loft#utils#GetIndex(registry, current_buf)
  if empty(registry)
    return -1
  endif
  var count = len(registry)
  for i in range(1, count)
    var delta = direction ==# 'prev' ? -i : i
    var idx = ((current_idx > 0 ? current_idx : 1) + delta - 1) % count
    if idx < 0
      idx += count
    endif
    var buf = registry[idx]
    if loft#registry#IsBufferMarked(buf)
      return buf
    endif
  endfor
  return -1
enddef

export def GetMarkedBufferKeymapIndex(buffer: number = -1): number
  var buf = buffer > 0 ? buffer : bufnr('%')
  var marked = MarkedBuffers()
  var count = 1
  var i = len(marked) - 1
  while i >= 0 && count <= 9
    if marked[i] == buf
      return count
    endif
    count += 1
    i -= 1
  endwhile
  return 0
enddef

export def IsSmartOrderOn(): bool
  return state.is_smart_order_on
enddef

export def ToggleSmartOrder(): bool
  state.is_smart_order_on = !state.is_smart_order_on
  loft#events#SmartOrderToggle(state.is_smart_order_on)
  return state.is_smart_order_on
enddef

export def KeymapRecentMarkedBuffers(): void
  ClearRecentMarkedMappings()
  if !get(Cfg(), 'enable_recent_marked_mapping', true)
    return
  endif
  var prefix = '<leader>' .. get(Cfg(), 'post_leader_marked_mapping', 'l')
  state.recent_mark_prefix = prefix
  var marked = MarkedBuffers()
  var count = 1
  var i = len(marked) - 1
  while i >= 0 && count <= 9
    var buf = marked[i]
    if loft#utils#IsBufferValid(buf, !get(Cfg(), 'auto_delete_missing_file_bufs', true))
      var key = prefix .. count
      execute printf('nnoremap <silent> %s <Cmd>call loft#actions#SwitchToBuffer(%d)<CR>', key, buf)
      add(state.recent_mark_keys, key)
      count += 1
    endif
    i -= 1
  endwhile
enddef
