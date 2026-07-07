vim9script

def Fire(name: string, data: dict<any> = {}): void
  g:loft_last_event = {
    name: name,
    data: deepcopy(data),
  }
  execute 'silent! doautocmd <nomodeline> User ' .. name
enddef

export def BufferMark(buffer: number, mark_state: bool): void
  Fire('LoftBufferMark', {
    buffer: buffer,
    mark_state: mark_state,
  })
enddef

export def SmartOrderToggle(smart_order_state: bool): void
  Fire('LoftSmartOrderToggle', {
    smart_order_state: smart_order_state,
  })
enddef

export def RegistryChanged(): void
  Fire('LoftRegistryChanged')
enddef

export def BufferSwitch(buffer: number, source: string): void
  Fire('LoftBufferSwitch', {
    buffer: buffer,
    source: source,
  })
enddef
