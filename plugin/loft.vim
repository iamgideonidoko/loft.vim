if exists('g:loaded_loft')
  finish
endif
let g:loaded_loft = 1

command! -nargs=0 LoftToggle call loft#ui#Toggle()
command! -nargs=0 LoftToggleSmartOrder call loft#actions#ToggleSmartOrder({})
command! -nargs=0 LoftToggleMark call loft#actions#ToggleMarkCurrentBuffer({})
command! -bang -nargs=0 LoftCloseOthers call loft#actions#CloseOthers({'force': <bang>0})
command! -bang -nargs=0 LoftCloseUnmarked call loft#actions#CloseUnmarked({'force': <bang>0})

call loft#Setup(get(g:, 'loft_config', {}))
