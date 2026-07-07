call loft#Setup({})

function! s:Reset() abort
  silent! only
  enew!
  file base.txt
  for info in getbufinfo({'buflisted': 1})
    if info.bufnr != bufnr('%')
      execute 'bwipeout!' info.bufnr
    endif
  endfor
  call loft#Setup({})
endfunction

function! s:OpenTemp(name, lines) abort
  let path = tempname() . '-' . a:name
  call writefile(a:lines, path)
  execute 'edit ' . fnameescape(path)
  return path
endfunction

function! s:TestDefaults() abort
  call s:Reset()
  call assert_equal(v:true, loft#state#Get().config.enable_smart_order_by_default)
  call assert_equal('l', loft#state#Get().config.post_leader_marked_mapping)
  call assert_equal(800, loft#state#Get().config.ui_timeout_on_curr_buf_move)
endfunction

function! s:TestRegistryNavigation() abort
  call s:Reset()
  let one = s:OpenTemp('one.txt', ['one'])
  let two = s:OpenTemp('two.txt', ['two'])
  call loft#registry#Clean()
  call assert_equal(2, len(loft#registry#GetRegistry()))
  call loft#actions#SwitchToPrevBuffer()
  call assert_equal(fnamemodify(one, ':t'), expand('%:t'))
  call loft#actions#SwitchToNextBuffer()
  call assert_equal(fnamemodify(two, ':t'), expand('%:t'))
endfunction

function! s:TestMarkingAndRecentMap() abort
  call s:Reset()
  call s:OpenTemp('marked.txt', ['mark'])
  call loft#registry#Clean()
  call loft#actions#ToggleMarkCurrentBuffer({'notify': v:false})
  call assert_true(loft#registry#IsBufferMarked(bufnr('%')))
  call assert_notequal('', maparg('<leader>l1', 'n'))
endfunction

function! s:TestPopupUiSmoke() abort
  call s:Reset()
  call s:OpenTemp('alpha.txt', ['alpha'])
  call s:OpenTemp('beta.txt', ['beta'])
  call loft#registry#Clean()
  call loft#ui#Open()
  call assert_equal(type(loft#ui#SmartOrderIndicator()), v:t_string)
  call assert_equal(type(loft#ui#GetBufferMark()), v:t_string)
  call loft#ui#CloseAll()
endfunction

function! s:TestPersistence() abort
  call s:Reset()
  let tmp = tempname()
  call loft#Setup({'persistence': {'enabled': v:true, 'path': tmp}})
  call s:OpenTemp('persist-a.txt', ['a'])
  call s:OpenTemp('persist-b.txt', ['b'])
  call loft#registry#Clean()
  call loft#actions#ToggleMarkCurrentBuffer({'notify': v:false})
  call loft#persistence#Save()
  call assert_true(filereadable(tmp))
  let data = json_decode(join(readfile(tmp), "\n"))
  call assert_true(!!has_key(data, 'order'))
  call assert_true(!!has_key(data, 'marks'))
  call assert_true(!!has_key(data, 'smart_order'))
  call delete(tmp)
endfunction

call s:TestDefaults()
call s:TestRegistryNavigation()
call s:TestMarkingAndRecentMap()
call s:TestPopupUiSmoke()
call s:TestPersistence()
