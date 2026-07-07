vim9script

def StdpathOrFallback(kind: string): string
  if kind ==# 'data'
    return expand('~/.vim')
  elseif kind ==# 'cache' || kind ==# 'run'
    return expand('~/.vim/tmp')
  endif
  return expand('~/.vim')
enddef

export def Notify(msg: string, level: string = 'info'): void
  if level ==# 'error'
    echohl ErrorMsg
  elseif level ==# 'warn'
    echohl WarningMsg
  else
    echohl ModeMsg
  endif
  echomsg msg
  echohl None
enddef

export def BufferExists(buf: number): bool
  return buf > 0 && bufexists(buf)
enddef

export def WindowExists(winid: number): bool
  return winid > 0 && win_id2win(winid) > 0
enddef

export def GetIndex(items: list<any>, needle: any): number
  var idx = index(items, needle)
  return idx >= 0 ? idx + 1 : 0
enddef

export def TableIncludes(items: list<any>, needle: any): bool
  return index(items, needle) >= 0
enddef

export def MergeDistinct(first: list<number>, second: list<number>): list<number>
  var merged: list<number> = []
  var seen: dict<bool> = {}
  for item in first
    if !has_key(seen, string(item))
      add(merged, item)
      seen[string(item)] = true
    endif
  endfor
  for item in second
    if !has_key(seen, string(item))
      add(merged, item)
      seen[string(item)] = true
    endif
  endfor
  return merged
enddef

export def BufferModifiable(buf: number, modifiable: bool): void
  setbufvar(buf, '&readonly', !modifiable)
  setbufvar(buf, '&modifiable', modifiable)
enddef

export def InTempDirectory(file_path: string): bool
  var temp_dirs = [
    StdpathOrFallback('run'),
    StdpathOrFallback('cache'),
    $TMPDIR,
    $TMP,
    $TEMP,
    '/tmp',
    '/var/tmp',
  ]
  for temp_dir in temp_dirs
    if temp_dir !=# '' && stridx(file_path, temp_dir) >= 0
      return true
    endif
  endfor
  return false
enddef

export def BufHasDeletedFile(buffer: number = bufnr('%')): bool
  if buffer < 1 || !bufexists(buffer)
    return false
  endif
  var buftype = getbufvar(buffer, '&buftype', '')
  var file_path = bufname(buffer)
  if buftype !=# '' || file_path ==# '' || getbufvar(buffer, '&modified', 0) || buflisted(buffer) == 0
    return false
  endif
  if loft#utils#InTempDirectory(file_path) || file_path =~# '^\a[\w+.-]*://'
    return false
  endif
  var state = loft#state#Get()
  var now = reltimefloat(reltime())
  var cached = get(state.stat_cache, file_path, {})
  if !empty(cached) && now - get(cached, 't', 0.0) < 2.0
    return !get(cached, 'exists', true)
  endif
  var exists = filereadable(file_path) || isdirectory(file_path)
  state.stat_cache[file_path] = {
    exists: exists,
    t: now,
  }
  return !exists
enddef

export def IsBufferValid(buf: number, skip_deleted_check: bool = false): bool
  if buf < 1 || !bufexists(buf) || buflisted(buf) != 1
    return false
  endif
  if skip_deleted_check
    return true
  endif
  return !loft#utils#BufHasDeletedFile(buf)
enddef

export def GetAllValidBuffers(skip_deleted_check: bool = false): list<number>
  var valid: list<number> = []
  for info in getbufinfo({buflisted: 1})
    if loft#utils#IsBufferValid(info.bufnr, skip_deleted_check)
      add(valid, info.bufnr)
    endif
  endfor
  return valid
enddef

export def IsPopupWindow(winid: number = win_getid()): bool
  return loft#utils#WindowExists(winid) && getwinvar(winid, '&buftype', '') ==# 'popup'
enddef

export def ResolveDim(val: any, height: number = 0, width: number = 0): any
  if type(val) == v:t_func
    return call(val, [height, width])
  endif
  return val
enddef

export def MakePopupTitle(base_title: string, extra: string): string
  if extra ==# ''
    return base_title
  endif
  return base_title .. ' (' .. extra .. ')'
enddef
