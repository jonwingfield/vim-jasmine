
sign define failedJasmineTest text=F texthl=Failed
sign define passedJasmineTest text=P texthl=Passed

command! -bang RunTests call jasmine#RunTests()
command! -bang RunTopLevelTest call jasmine#RunTopLevelTest()
command! -bang RunTestInBrowser call jasmine#RunTestInBrowser()

nnoremap <silent> <return> :call RunTests()<CR>
nnoremap <silent> <S-return> :call RunTopLevelTest()<CR>
nnoremap <silent> <leader>rt :call RunTestInBrowser()<CR>

