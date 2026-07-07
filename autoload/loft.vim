vim9script

var state = loft#state#Get()

def SetupColorSchemeAutocmd(): void
  execute 'augroup LoftHighlights'
  execute 'autocmd!'
  execute 'autocmd ColorScheme * call loft#highlights#Setup()'
  execute 'augroup END'
enddef

def SetupRegistryAutocmds(): void
  execute 'augroup LoftRegistry'
  execute 'autocmd!'
  execute 'autocmd BufEnter * call loft#registry#Update()'
  execute 'autocmd FocusGained * if get(state.config, "auto_delete_missing_file_bufs", true) | call loft#registry#Clean() | endif'
  execute 'augroup END'
enddef

def SetupUiAutocmds(): void
  execute 'augroup LoftUi'
  execute 'autocmd!'
  execute 'autocmd VimResized * call loft#ui#Reposition()'
  execute 'augroup END'
enddef

def SetupPersistenceAutocmds(): void
  execute 'augroup LoftPersistence'
  execute 'autocmd!'
  if get(state.config.persistence, 'enabled', false)
    execute 'autocmd VimLeavePre * call loft#persistence#Save()'
    execute 'autocmd SessionLoadPost * call loft#persistence#Restore()'
    execute 'autocmd User PersistenceLoadPost call loft#persistence#Restore()'
    execute 'autocmd User PersistedLoadPost call loft#persistence#Restore()'
    execute 'autocmd User ResessionLoadPost call loft#persistence#Restore()'
    execute 'autocmd VimEnter * call loft#persistence#Restore()'
  endif
  execute 'augroup END'
enddef

def ClearMappings(keys: list<string>): void
  for key in keys
    execute 'silent! nunmap ' .. key
  endfor
enddef

def ApplyGeneralMappings(): void
  ClearMappings(state.general_mapping_keys_prev)
  state.general_mapping_keys = []
  var dispatch = {
    open_loft: '<Cmd>call loft#actions#OpenLoft()<CR>',
    switch_to_next_buffer: '<Cmd>call loft#actions#SwitchToNextBuffer()<CR>',
    switch_to_prev_buffer: '<Cmd>call loft#actions#SwitchToPrevBuffer()<CR>',
    close_buffer: '<Cmd>call loft#actions#CloseBuffer({})<CR>',
    force_close_buffer: '<Cmd>call loft#actions#CloseBuffer({"force": v:true})<CR>',
    switch_to_next_marked_buffer: '<Cmd>call loft#actions#SwitchToNextMarkedBuffer()<CR>',
    switch_to_prev_marked_buffer: '<Cmd>call loft#actions#SwitchToPrevMarkedBuffer()<CR>',
    toggle_mark_current_buffer: '<Cmd>call loft#actions#ToggleMarkCurrentBuffer({})<CR>',
    toggle_smart_order: '<Cmd>call loft#actions#ToggleSmartOrder({})<CR>',
    switch_to_alt_buffer: '<Cmd>call loft#actions#SwitchToAltBuffer()<CR>',
    move_buffer_up: '<Cmd>call loft#actions#MoveBufferUp()<CR>',
    move_buffer_down: '<Cmd>call loft#actions#MoveBufferDown()<CR>',
  }
  for [key, value] in items(state.config.keymaps.general)
    if !(type(value) == v:t_bool && value == false) && type(value) == v:t_dict && has_key(dispatch, get(value, 'kind', ''))
      execute printf('nnoremap <silent> %s %s', key, dispatch[value.kind])
      add(state.general_mapping_keys, key)
    endif
  endfor
  state.general_mapping_keys_prev = copy(state.general_mapping_keys)
enddef

export def Setup(opts: dict<any> = {}): void
  state.config = loft#config#Merge(opts)
  state.general_mappings = deepcopy(state.config.keymaps.general)
  loft#highlights#Setup()
  SetupColorSchemeAutocmd()
  loft#registry#Setup()
  SetupRegistryAutocmds()
  SetupUiAutocmds()
  SetupPersistenceAutocmds()
  ApplyGeneralMappings()
  state.initialized = true
enddef

export def EnsureSetup(): void
  if !state.initialized
    loft#Setup(get(g:, 'loft_config', {}))
  endif
enddef
