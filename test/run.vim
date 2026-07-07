set rtp^=/Users/macbook/work/loft.vim
source /Users/macbook/work/loft.vim/test/test_loft.vim
if len(v:errors) > 0
  for err in v:errors
    echomsg err
  endfor
  cquit 1
endif
qall!
