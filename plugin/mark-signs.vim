
if exists("g:loaded_mark_signs")
  finish
endif
let g:loaded_mark_signs = 1

hi default link MarkSignsHL Identifier
hi default link MarkSignsNumHL CursorLineNr

nnoremap <Plug>(Mark-signs-set) <cmd> lua require('mark-signs').set()<cr>
nnoremap <Plug>(Mark-signs-delete) <cmd> lua require('mark-signs').delete()<cr>

