vim9script

var state = loft#state#Get()

def Cfg(): dict<any>
  return state.config
enddef

def BorderChars(style: any): list<string>
  if type(style) == v:t_list
    return style
  endif
  if style ==# 'none'
    return []
  elseif style ==# 'single'
    return ['-', '|', '-', '|', '+', '+', '+', '+']
  elseif style ==# 'double'
    return ['═', '║', '═', '║', '╔', '╗', '╝', '╚']
  elseif style ==# 'rounded'
    return ['─', '│', '─', '│', '╭', '╮', '╯', '╰']
  elseif style ==# 'solid'
    return [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ']
  elseif style ==# 'shadow'
    return ['─', '│', '─', '│', '┌', '┐', '┘', '└']
  endif
  return ['─', '│', '─', '│', '╭', '╮', '╯', '╰']
enddef

def PopupTitle(): string
  var base = type(Cfg().window.title) == v:t_string && Cfg().window.title !=# ''
    ? Cfg().window.title
    : ' ⨳⨳ LOFT'
  var footer = type(Cfg().window.footer) == v:t_string && Cfg().window.footer !=# ''
    ? Cfg().window.footer
    : loft#ui#SmartOrderIndicator()
  if footer ==# ''
    return base .. ' ⨳⨳ '
  endif
  return loft#utils#MakePopupTitle(base .. ' ⨳⨳ ', footer)
enddef

def MainSize(): dict<any>
  var count = len(loft#registry#GetRegistry())
  var height = loft#utils#ResolveDim(Cfg().window.height)
  if type(height) == v:t_none
    height = min([count > 0 ? count : 1, float2nr(&lines * 0.8)])
  endif
  var width = loft#utils#ResolveDim(Cfg().window.width, height)
  if type(width) == v:t_none
    width = float2nr(&columns * 0.8)
  endif
  var row = loft#utils#ResolveDim(Cfg().window.row, height, width)
  if type(row) == v:t_none
    row = float2nr((&lines - height) * 0.5)
  endif
  row += get(Cfg().window, 'row_offset', 0)
  var col = loft#utils#ResolveDim(Cfg().window.col, height, width)
  if type(col) == v:t_none
    col = float2nr((&columns - width) * 0.5)
  endif
  col += get(Cfg().window, 'col_offset', 0)
  return {
    width: width,
    height: height,
    row: row,
    col: col,
  }
enddef

def HelpSize(lines: number): dict<any>
  var cfg = Cfg().help_window
  var width = loft#utils#ResolveDim(cfg.width)
  if type(width) == v:t_none
    width = 70
  endif
  var height = loft#utils#ResolveDim(cfg.height)
  if type(height) == v:t_none
    height = min([lines, float2nr(&lines * 0.8)])
  endif
  var row = loft#utils#ResolveDim(cfg.row, height, width)
  if type(row) == v:t_none
    row = float2nr((&lines - height) * 0.5)
  endif
  row += get(cfg, 'row_offset', 0)
  var col = loft#utils#ResolveDim(cfg.col, height, width)
  if type(col) == v:t_none
    col = float2nr((&columns - width) * 0.5)
  endif
  col += get(cfg, 'col_offset', 0)
  return {
    width: width,
    height: height,
    row: row,
    col: col,
  }
enddef

def PopupCursorLine(winid: number): number
  var value = trim(win_execute(winid, 'echo line(".")'))
  return str2nr(value ==# '' ? '1' : value)
enddef

def SetPopupCursorLine(winid: number, line: number): void
  if loft#utils#WindowExists(winid)
    win_execute(winid, 'normal! ' .. max([1, line]) .. 'G0')
  endif
enddef

def LineToRegIdx(line: number, total: number): number
  if get(Cfg(), 'reverse_order', false)
    return total - line + 1
  endif
  return line
enddef

def RegIdxToLine(idx: number, total: number): number
  if get(Cfg(), 'reverse_order', false)
    return total - idx + 1
  endif
  return idx
enddef

def ClearBufferProps(buf: number, count: number): void
  if count > 0
    prop_clear(1, count, {bufnr: buf})
  endif
enddef

def ApplyProp(buf: number, lnum: number, col: number, length: number, prop_type: string, priority: number = 10): void
  if length <= 0
    return
  endif
  prop_add(lnum, col, {
    bufnr: buf,
    type: prop_type,
    length: length,
    priority: priority,
  })
enddef

def InVisualSelection(line: number): bool
  var anchor = state.visual_anchor
  if anchor <= 0
    return false
  endif
  var cursor = PopupCursorLine(state.main_popup)
  var lo = min([anchor, cursor])
  var hi = max([anchor, cursor])
  return line >= lo && line <= hi
enddef

def RenderEntries(): void
  if !loft#utils#WindowExists(state.main_popup)
    return
  endif
  var registry = loft#registry#GetRegistry()
  var count = len(registry)
  if count == 0
    popup_settext(state.main_popup, ['  No buffers — press q to close'])
    return
  endif
  var width = MainSize().width
  var info_map: dict<dict<any>> = {}
  for info in getbufinfo({buflisted: 1})
    info_map[string(info.bufnr)] = info
  endfor
  var lines: list<string> = []
  for display_pos in range(1, count)
    var reg_idx = LineToRegIdx(display_pos, count)
    var buf = registry[reg_idx - 1]
    var info = get(info_map, string(buf), {})
    if empty(info)
      continue
    endif
    var bufname = info.name !=# '' ? info.name : '[No Name]'
    var flags = ''
    var mark = loft#ui#GetBufferMark(buf)
    if mark !=# ''
      flags ..= mark
    endif
    if getbufvar(buf, '&modified', 0)
      flags ..= '[+]'
    endif
    if state.last_buf_before_loft == buf
      flags ..= '●'
    endif
    var line = printf('%s>{%d}%s', flags, buf, fnamemodify(bufname, ':.'))
    var pad = width - strdisplaywidth(line)
    if pad > 0
      line ..= repeat(' ', pad)
    endif
    add(lines, line)
  endfor
  popup_settext(state.main_popup, lines)
  ClearBufferProps(state.main_bufnr, len(lines))
  for lnum in range(1, len(lines))
    var reg_idx = LineToRegIdx(lnum, len(lines))
    var buf = registry[reg_idx - 1]
    var line = lines[lnum - 1]
    var col = 1
    var mark = loft#ui#GetBufferMark(buf)
    if state.last_buf_before_loft == buf
      ApplyProp(state.main_bufnr, lnum, 1, strlen(line), 'LoftCurrentBufferProp')
    elseif mark !=# ''
      ApplyProp(state.main_bufnr, lnum, 1, strlen(line), 'LoftMarkedBufferProp')
    endif
    if InVisualSelection(lnum)
      ApplyProp(state.main_bufnr, lnum, 1, strlen(line), 'LoftVisualSelectionProp', 15)
    endif
    if mark !=# ''
      ApplyProp(state.main_bufnr, lnum, col, strlen(mark), 'LoftMarkProp', 20)
      col += strlen(mark)
    endif
    if getbufvar(buf, '&modified', 0)
      ApplyProp(state.main_bufnr, lnum, col, 3, 'LoftModifiedProp', 20)
      col += 3
    endif
    if state.last_buf_before_loft == buf
      ApplyProp(state.main_bufnr, lnum, col, strlen('●'), 'LoftCurrentIndicatorProp', 20)
      col += strlen('●')
    endif
    col += 1
    var token = '{' .. buf .. '}'
    ApplyProp(state.main_bufnr, lnum, col, strlen(token), 'LoftBufferNumberProp', 20)
  endfor
enddef

def ClampCursor(): void
  if !loft#utils#WindowExists(state.main_popup)
    return
  endif
  var count = len(loft#registry#GetRegistry())
  if count == 0
    return
  endif
  var line = PopupCursorLine(state.main_popup)
  SetPopupCursorLine(state.main_popup, min([line, count]))
enddef

def CancelMoveTimer(): void
  if state.move_timer > 0
    timer_stop(state.move_timer)
    state.move_timer = -1
  endif
enddef

def StartMoveTimer(): void
  CancelMoveTimer()
  var timeout = get(Cfg(), 'ui_timeout_on_curr_buf_move', 800)
  if timeout <= 0
    return
  endif
  state.move_timer = timer_start(timeout, (_) => loft#ui#Close())
enddef

def ConfirmForceDelete(count: number): bool
  if !get(Cfg(), 'confirm_force_delete', true)
    return true
  endif
  var msg = count == 1
    ? 'Force delete 1 buffer? Unsaved changes will be lost.'
    : printf('Force delete %d buffers? Unsaved changes will be lost.', count)
  return confirm(msg, "&Yes\n&No", 2) == 1
enddef

def DeleteEntry(force: bool): void
  var registry = loft#registry#GetRegistry()
  var count = len(registry)
  if count == 0
    return
  endif
  var line = PopupCursorLine(state.main_popup)
  var reg_idx = LineToRegIdx(line, count)
  var buf = registry[reg_idx - 1]
  if buf == state.last_buf_before_loft && !get(Cfg(), 'allow_delete_current_buffer', true)
    loft#utils#Notify('Loft: deleting the current buffer is disabled (allow_delete_current_buffer = false)', 'warn')
    return
  endif
  if force && !ConfirmForceDelete(1)
    loft#utils#Notify('Loft: force delete cancelled.')
    return
  endif
  var deleted_current = buf == state.last_buf_before_loft
  loft#actions#CloseBuffer({
    force: force,
    buffer: buf,
  })
  if deleted_current && loft#utils#WindowExists(state.last_win_before_loft)
    state.last_buf_before_loft = winbufnr(state.last_win_before_loft)
  endif
  RenderEntries()
  loft#ui#Reposition()
  ClampCursor()
enddef

def DeleteSelected(force: bool, start_line: number, end_line: number): void
  var registry = loft#registry#GetRegistry()
  var count = len(registry)
  if count == 0
    return
  endif
  var bufs: list<number> = []
  var lo = min([start_line, end_line])
  var hi = max([start_line, end_line])
  for line in range(lo, hi)
    var reg_idx = LineToRegIdx(line, count)
    var buf = registry[reg_idx - 1]
    if buf == state.last_buf_before_loft && !get(Cfg(), 'allow_delete_current_buffer', true)
      loft#utils#Notify('Loft: deleting the current buffer is disabled (allow_delete_current_buffer = false)', 'warn')
    elseif buf > 0
      add(bufs, buf)
    endif
  endfor
  if empty(bufs)
    return
  endif
  if force && !ConfirmForceDelete(len(bufs))
    loft#utils#Notify('Loft: force delete cancelled.')
    return
  endif
  var deleted_current = false
  for buf in bufs
    if buf == state.last_buf_before_loft
      deleted_current = true
    endif
    loft#actions#CloseBuffer({
      force: force,
      buffer: buf,
    })
  endfor
  if deleted_current && loft#utils#WindowExists(state.last_win_before_loft)
    state.last_buf_before_loft = winbufnr(state.last_win_before_loft)
  endif
  RenderEntries()
  loft#ui#Reposition()
  ClampCursor()
enddef

def MoveCursor(delta: number): void
  var count = len(loft#registry#GetRegistry())
  if count == 0
    return
  endif
  var current = PopupCursorLine(state.main_popup)
  var target = ((current + delta - 1) % count) + 1
  if target < 1
    target += count
  endif
  SetPopupCursorLine(state.main_popup, target)
  if state.visual_anchor > 0
    RenderEntries()
  endif
enddef

def MoveEntryUp(): void
  var count = len(loft#registry#GetRegistry())
  if count == 0
    return
  endif
  var current = PopupCursorLine(state.main_popup)
  var reg_idx = LineToRegIdx(current, count)
  if get(Cfg(), 'reverse_order', false)
    loft#registry#MoveBufferDown(reg_idx, true)
  else
    loft#registry#MoveBufferUp(reg_idx, true)
  endif
  SetPopupCursorLine(state.main_popup, current > 1 ? current - 1 : count)
  RenderEntries()
enddef

def MoveEntryDown(): void
  var count = len(loft#registry#GetRegistry())
  if count == 0
    return
  endif
  var current = PopupCursorLine(state.main_popup)
  var reg_idx = LineToRegIdx(current, count)
  if get(Cfg(), 'reverse_order', false)
    loft#registry#MoveBufferUp(reg_idx, true)
  else
    loft#registry#MoveBufferDown(reg_idx, true)
  endif
  SetPopupCursorLine(state.main_popup, current < count ? current + 1 : 1)
  RenderEntries()
enddef

def SelectEntry(): void
  var count = len(loft#registry#GetRegistry())
  if count == 0
    return
  endif
  var line = PopupCursorLine(state.main_popup)
  var reg_idx = LineToRegIdx(line, count)
  var selected = loft#registry#GetRegistry()[reg_idx - 1]
  loft#registry#PauseUpdate()
  loft#ui#Close_all()
  var target = loft#utils#WindowExists(state.last_win_before_loft) ? state.last_win_before_loft : win_getid()
  if loft#utils#WindowExists(target)
    win_gotoid(target)
    execute 'buffer ' .. selected
  endif
  loft#registry#ResumeUpdate()
enddef

def ToggleMarkEntry(): void
  var count = len(loft#registry#GetRegistry())
  if count == 0
    return
  endif
  var line = PopupCursorLine(state.main_popup)
  var reg_idx = LineToRegIdx(line, count)
  var buf = loft#registry#GetRegistry()[reg_idx - 1]
  if buf > 0
    loft#registry#ToggleMarkBuffer(buf)
    RenderEntries()
  endif
enddef

def MoveToMarked(direction: string): void
  var registry = loft#registry#GetRegistry()
  var count = len(registry)
  if count == 0
    return
  endif
  var line = PopupCursorLine(state.main_popup)
  var reg_idx = LineToRegIdx(line, count)
  var current_buf = registry[reg_idx - 1]
  var registry_dir = direction
  if get(Cfg(), 'reverse_order', false)
    registry_dir = direction ==# 'up' ? 'next' : 'prev'
  else
    registry_dir = direction ==# 'up' ? 'prev' : 'next'
  endif
  var goto_buf = loft#registry#GetMarkedBuffer(registry_dir, current_buf)
  if goto_buf <= 0
    return
  endif
  var idx = loft#utils#GetIndex(registry, goto_buf)
  if idx > 0
    SetPopupCursorLine(state.main_popup, RegIdxToLine(idx, count))
  endif
enddef

def HelpLines(): list<string>
  var lines = [
    ' ⨳⨳ LOFT HELP ⨳⨳ ',
    '`loft.vim` streamlines buffer management while you focus on your code',
    '',
    'Keymaps:',
  ]
  var descs = {
    move_up: 'Move cursor up',
    move_down: 'Move cursor down',
    move_entry_up: 'Move entry up',
    move_entry_down: 'Move entry down',
    delete_entry: 'Delete entry (+buffer)',
    force_delete_entry: 'Force delete entry (+buffer, no save)',
    select_entry: 'Select entry (+buffer)',
    close: 'Close Loft',
    toggle_mark_entry: 'Toggle entry mark status',
    toggle_smart_order: 'Toggle smart order status',
    show_help: 'Show this help',
    move_up_to_marked_entry: 'Move up to the next marked entry',
    move_down_to_marked_entry: 'Move down to the next marked entry',
  }
  for [key, action] in items(Cfg().keymaps.ui)
    if !(type(action) == v:t_bool && action == false) && type(action) == v:t_string && has_key(descs, action)
      add(lines, printf('  %s: %s', key, descs[action]))
    endif
  endfor
  add(lines, '  v/V: start or clear range selection')
  if has_key(Cfg().keymaps, 'ui_visual')
    for [key, action] in items(Cfg().keymaps.ui_visual)
      if !(type(action) == v:t_bool && action == false) && type(action) == v:t_string
        var desc = action ==# 'delete_selected_entries'
          ? 'Delete selected entries (+buffers)'
          : 'Force delete selected entries (no save)'
        add(lines, printf('  %s (range): %s', key, desc))
      endif
    endfor
  endif
  for [key, value] in items(Cfg().keymaps.general)
    if !(type(value) == v:t_bool && value == false) && type(value) == v:t_dict
      add(lines, printf('  %s: %s', key, get(value, 'desc', 'No description')))
    endif
  endfor
  lines += [
    '',
    'Commands:',
    ' :LoftToggle',
    ' :LoftToggleSmartOrder',
    ' :LoftToggleMark',
    ' :LoftCloseOthers[!]',
    ' :LoftCloseUnmarked[!]',
  ]
  return lines
enddef

export def ShowHelp(): void
  if get(Cfg().help_window, 'disable', false)
    return
  endif
  if loft#utils#WindowExists(state.help_popup)
    return
  endif
  var lines = HelpLines()
  state.help_content_height = len(lines)
  var size = HelpSize(len(lines))
  var opts = {
    pos: 'topleft',
    line: size.row + 1,
    col: size.col + 1,
    minwidth: size.width,
    maxwidth: size.width,
    minheight: size.height,
    maxheight: size.height,
    wrap: false,
    drag: false,
    resize: false,
    mapping: false,
    filter: 'loft#ui#HelpFilter',
    cursorline: false,
    scrollbar: false,
    zindex: get(Cfg().help_window, 'zindex', get(Cfg().window, 'zindex', 100) + 10),
    title: ' ⨳⨳ LOFT HELP ⨳⨳ ',
    padding: [0, 0, 0, 0],
    highlight: 'Normal',
  }
  var borderchars = BorderChars(get(Cfg().help_window, 'border', get(Cfg().window, 'border', 'rounded')))
  if !empty(borderchars)
    opts.border = [1, 1, 1, 1]
    opts.borderchars = borderchars
  endif
  state.help_popup = popup_create(lines, opts)
  state.help_bufnr = winbufnr(state.help_popup)
enddef

export def CloseHelp(): void
  if loft#utils#WindowExists(state.help_popup)
    popup_close(state.help_popup)
  endif
  state.help_popup = 0
  state.help_bufnr = -1
enddef

export def HelpFilter(id: number, key: string): bool
  if key ==# '?' || key ==# 'q' || key ==# "\<CR>" || key ==# "\<Esc>"
    loft#ui#CloseHelp()
    return true
  endif
  loft#ui#CloseHelp()
  return loft#ui#MainFilter(state.main_popup, key)
enddef

def NormalizeKey(key: string): string
  return key
enddef

def HandleUnknownKey(key: string): bool
  loft#ui#Close_all()
  return false
enddef

export def MainFilter(id: number, key: string): bool
  if id != state.main_popup
    return false
  endif
  var normalized = NormalizeKey(key)
  if normalized ==# 'v' || normalized ==# 'V'
    if state.visual_anchor > 0
      state.visual_anchor = 0
    else
      state.visual_anchor = PopupCursorLine(id)
    endif
    state.pending_keys = ''
    state.count_prefix = ''
    RenderEntries()
    return true
  endif
  if normalized =~# '^[1-9]$' && state.pending_keys ==# ''
    state.count_prefix ..= normalized
    return true
  endif
  if normalized ==# '0' && state.pending_keys ==# '' && state.count_prefix !=# ''
    state.count_prefix ..= normalized
    return true
  endif
  if normalized ==# 'd' && state.visual_anchor == 0 && state.pending_keys ==# ''
    state.pending_keys = 'd'
    return true
  endif
  var count = state.count_prefix ==# '' ? 1 : str2nr(state.count_prefix)
  state.count_prefix = ''
  if state.pending_keys ==# 'd'
    state.pending_keys = ''
    if normalized ==# 'd'
      DeleteEntry(false)
      return true
    endif
  endif
  if state.visual_anchor > 0 && (normalized ==# 'd' || normalized ==# 'D')
    var start_line = state.visual_anchor
    var end_line = PopupCursorLine(id)
    state.visual_anchor = 0
    DeleteSelected(normalized ==# 'D', start_line, end_line)
    return true
  endif
  if normalized ==# 'j'
    MoveCursor(count)
    return true
  elseif normalized ==# 'k'
    MoveCursor(-count)
    return true
  elseif normalized ==# "\<C-j>"
    MoveEntryDown()
    return true
  elseif normalized ==# "\<C-k>"
    MoveEntryUp()
    return true
  elseif normalized ==# 'D'
    DeleteEntry(true)
    return true
  elseif normalized ==# "\<CR>"
    SelectEntry()
    return true
  elseif normalized ==# 'm'
    ToggleMarkEntry()
    return true
  elseif normalized ==# "\<C-s>"
    loft#ui#Toggle_smart_order()
    return true
  elseif normalized ==# '?'
    if loft#utils#WindowExists(state.help_popup)
      loft#ui#CloseHelp()
    else
      loft#ui#ShowHelp()
    endif
    return true
  elseif normalized ==# "\<M-k>"
    MoveToMarked('up')
    return true
  elseif normalized ==# "\<M-j>"
    MoveToMarked('down')
    return true
  elseif normalized ==# 'q'
    loft#ui#Close_all()
    return true
  elseif normalized ==# "\<Esc>"
    if state.visual_anchor > 0
      state.visual_anchor = 0
      RenderEntries()
    else
      loft#ui#Close_all()
    endif
    return true
  endif
  return HandleUnknownKey(normalized)
enddef

def PositionCursor(): void
  var registry = loft#registry#GetRegistry()
  var count = len(registry)
  if count == 0
    return
  endif
  var open_at = get(Cfg(), 'open_at', 'current')
  var target = 1
  if open_at ==# 'cursor' && state.saved_cursor_line > 0
    target = min([state.saved_cursor_line, count])
  elseif open_at ==# 'top'
    target = 1
  elseif open_at ==# 'bottom'
    target = count
  elseif open_at ==# 'middle'
    target = float2nr(ceil(count / 2.0))
  else
    var idx = loft#utils#GetIndex(registry, state.last_buf_before_loft)
    target = idx > 0 ? RegIdxToLine(idx, count) : 1
  endif
  SetPopupCursorLine(state.main_popup, target)
enddef

def PopupOptions(size: dict<any>): dict<any>
  var opts = {
    pos: 'topleft',
    line: size.row + 1,
    col: size.col + 1,
    minwidth: size.width,
    maxwidth: size.width,
    minheight: size.height,
    maxheight: size.height,
    wrap: false,
    drag: false,
    resize: false,
    mapping: false,
    filter: 'loft#ui#MainFilter',
    filtermode: 'a',
    cursorline: true,
    scrollbar: false,
    zindex: get(Cfg().window, 'zindex', 100),
    title: PopupTitle(),
    padding: [0, 0, 0, 0],
    highlight: 'Normal',
  }
  var borderchars = BorderChars(get(Cfg().window, 'border', 'rounded'))
  if !empty(borderchars)
    opts.border = [1, 1, 1, 1]
    opts.borderchars = borderchars
  endif
  return opts
enddef

export def Open(): void
  loft#EnsureSetup()
  state.last_win_before_loft = win_getid()
  state.last_buf_before_loft = bufnr('%')
  loft#registry#Clean()
  if loft#utils#WindowExists(state.main_popup)
    return
  endif
  state.visual_anchor = 0
  state.pending_keys = ''
  state.count_prefix = ''
  var size = MainSize()
  state.main_popup = popup_create([''], PopupOptions(size))
  state.main_bufnr = winbufnr(state.main_popup)
  RenderEntries()
  PositionCursor()
enddef

export def Close(): void
  CancelMoveTimer()
  if loft#utils#WindowExists(state.main_popup)
    state.saved_cursor_line = PopupCursorLine(state.main_popup)
    state.update_paused_once = true
    popup_close(state.main_popup)
  endif
  state.main_popup = 0
  state.main_bufnr = -1
  state.visual_anchor = 0
  state.pending_keys = ''
  state.count_prefix = ''
enddef

export def CloseAll(): void
  loft#ui#CloseHelp()
  loft#ui#Close()
enddef

export def Toggle(): void
  if loft#ui#IsOpen()
    loft#ui#Close_all()
  else
    loft#ui#Open()
  endif
enddef

export def IsOpen(): bool
  return loft#utils#WindowExists(state.main_popup)
enddef

export def ToggleSmartOrder(): bool
  var new_state = loft#registry#ToggleSmartOrder()
  if loft#utils#WindowExists(state.main_popup)
    popup_setoptions(state.main_popup, {
      title: PopupTitle(),
    })
  endif
  return new_state
enddef

export def GetBufferMark(buffer: number = -1): string
  var buf = buffer > 0 ? buffer : bufnr('%')
  if loft#registry#IsBufferMarked(buf)
    var mark = '(✓)'
    if get(Cfg(), 'show_marked_mapping_num', true)
      var idx = loft#registry#GetMarkedBuffer_keymap_index(buf)
      if idx > 0
        var solid = ['➊', '➋', '➌', '➍', '➎', '➏', '➐', '➑', '➒']
        var outline = ['➀', '➁', '➂', '➃', '➄', '➅', '➆', '➇', '➈']
        var nums = get(Cfg(), 'marked_mapping_num_style', 'solid') ==# 'outline' ? outline : solid
        return nums[idx - 1] .. mark
      endif
    endif
    return mark
  endif
  return ''
enddef

export def SmartOrderIndicator(): string
  return loft#registry#IsSmartOrderOn() ? '⟅⇅⟆' : ''
enddef

export def MoveBufferUp(): void
  loft#registry#Clean()
  var registry = loft#registry#GetRegistry()
  var count = len(registry)
  if count == 0
    return
  endif
  var buf = bufnr('%')
  var idx = loft#utils#GetIndex(registry, buf)
  if idx == 0
    return
  endif
  if get(Cfg(), 'ui_timeout_on_curr_buf_move', 800) > 0
    if !loft#ui#IsOpen()
      loft#ui#Open()
    endif
    StartMoveTimer()
  endif
  loft#registry#MoveBufferUp(idx, true)
  if loft#ui#IsOpen()
    var new_idx = idx > 1 ? idx - 1 : count
    SetPopupCursorLine(state.main_popup, RegIdxToLine(new_idx, count))
    RenderEntries()
  endif
enddef

export def MoveBufferDown(): void
  loft#registry#Clean()
  var registry = loft#registry#GetRegistry()
  var count = len(registry)
  if count == 0
    return
  endif
  var buf = bufnr('%')
  var idx = loft#utils#GetIndex(registry, buf)
  if idx == 0
    return
  endif
  if get(Cfg(), 'ui_timeout_on_curr_buf_move', 800) > 0
    if !loft#ui#IsOpen()
      loft#ui#Open()
    endif
    StartMoveTimer()
  endif
  loft#registry#MoveBufferDown(idx, true)
  if loft#ui#IsOpen()
    var new_idx = idx < count ? idx + 1 : 1
    SetPopupCursorLine(state.main_popup, RegIdxToLine(new_idx, count))
    RenderEntries()
  endif
enddef

export def Reposition(): void
  if loft#utils#WindowExists(state.main_popup)
    var size = MainSize()
    popup_move(state.main_popup, {
      line: size.row + 1,
      col: size.col + 1,
      minwidth: size.width,
      maxwidth: size.width,
      minheight: size.height,
      maxheight: size.height,
    })
    popup_setoptions(state.main_popup, {
      title: PopupTitle(),
    })
    RenderEntries()
    ClampCursor()
  endif
  if loft#utils#WindowExists(state.help_popup)
    var help_size = HelpSize(state.help_content_height > 0 ? state.help_content_height : 10)
    popup_move(state.help_popup, {
      line: help_size.row + 1,
      col: help_size.col + 1,
      minwidth: help_size.width,
      maxwidth: help_size.width,
      minheight: help_size.height,
      maxheight: help_size.height,
    })
  endif
enddef
