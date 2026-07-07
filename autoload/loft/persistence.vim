vim9script

var state = loft#state#Get()

def Cfg(): dict<any>
  return state.config.persistence
enddef

def DefaultPath(path: any): string
  if type(path) == v:t_string && path !=# ''
    return path
  endif
  var data_dir = expand('~/.vim/loft')
  mkdir(data_dir, 'p')
  return data_dir .. '/' .. sha256(getcwd()) .. '.json'
enddef

export def GetPath(): string
  return DefaultPath(get(Cfg(), 'path', v:none))
enddef

export def Save(): void
  if !get(Cfg(), 'enabled', false)
    return
  endif
  var order: list<string> = []
  var marks: list<string> = []
  for buf in loft#registry#GetRegistry()
    var name = bufname(buf)
    if name !=# ''
      add(order, name)
      if loft#registry#IsBufferMarked(buf)
        add(marks, name)
      endif
    endif
  endfor
  var data = json_encode({
    order: order,
    marks: marks,
    smart_order: loft#registry#IsSmartOrderOn(),
  })
  writefile([data], loft#persistence#GetPath())
enddef

export def Restore(): void
  if !get(Cfg(), 'enabled', false)
    return
  endif
  var path = loft#persistence#GetPath()
  if !filereadable(path)
    return
  endif
  var lines = readfile(path)
  if empty(lines)
    return
  endif
  var ok = true
  var data: dict<any> = {}
  try
    data = json_decode(join(lines, "\n"))
  catch
    ok = false
  endtry
  if !ok || type(data) != v:t_dict
    return
  endif
  var path_to_buf: dict<number> = {}
  for buf in loft#utils#GetAllValidBuffers()
    var name = bufname(buf)
    if name !=# ''
      path_to_buf[name] = buf
    endif
  endfor
  if type(get(data, 'order', [])) == v:t_list
    var ordered: list<number> = []
    var seen: dict<bool> = {}
    for saved_path in data.order
      if has_key(path_to_buf, saved_path)
        var buf = path_to_buf[saved_path]
        if !has_key(seen, string(buf))
          add(ordered, buf)
          seen[string(buf)] = true
        endif
      endif
    endfor
    for buf in loft#registry#GetRegistry()
      if !has_key(seen, string(buf))
        add(ordered, buf)
        seen[string(buf)] = true
      endif
    endfor
    state.registry = ordered
    loft#events#RegistryChanged()
  endif
  if type(get(data, 'marks', [])) == v:t_list
    var mark_set: dict<bool> = {}
    for saved_path in data.marks
      mark_set[saved_path] = true
    endfor
    for buf in loft#registry#GetRegistry()
      var name = bufname(buf)
      if name !=# '' && has_key(mark_set, name) && !loft#registry#IsBufferMarked(buf)
        loft#registry#ToggleMarkBuffer(buf)
      endif
    endfor
  endif
  if type(get(data, 'smart_order', v:none)) == v:t_bool && data.smart_order != loft#registry#IsSmartOrderOn()
    loft#registry#ToggleSmartOrder()
  endif
enddef
