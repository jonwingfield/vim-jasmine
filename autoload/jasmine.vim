
function! s:find_test_context()
  let s:line_no = search('^\s*\(it\|describe\|context\).\([''"]\).*\2', 'bcnW')
  if s:line_no 
    let line = getline(s:line_no) 
    let string = matchstr(line,'^\s*it.\([''"]\)\zs.*\ze\1')
    let offset = strlen(matchstr(line,'^\zs\s*\ze\(it\|describe\|context\).\([''"]\).*\2'))
    if (strlen(string)) 
      call cursor(s:line_no-1, 0)
      return s:find_test_name_in_quotes(offset) . " " . string . "." " final period means don't run anything else matching
    else 
      return s:find_test_name_in_quotes(offset+1)
    endif
  else
    return s:find_test_name_in_quotes(1)
  endif
endfunction

let s:search_for = '\(describe\|context\).'

function! s:find_top_level_test()
  let s:line_no = search('^' . s:search_for . '"[^"]*"', 'bcnW')
  if s:line_no
    let line = getline(s:line_no)
    let string = matchstr(line,'^' . s:search_for . '"\zs[^"]*\ze"')
    return string
  else
    return ""
  endif
endfunction

function! s:find_test_name_in_quotes(max_indent)
  let s:line_no = search('^\s\{1,' . max([a:max_indent-1, 1]) . '}' . s:search_for . '"[^"]*"', 'bcnW')
  if s:line_no && a:max_indent > 1
    let line = getline(s:line_no)
    let string = matchstr(line,'^\s*' . s:search_for . '"\zs[^"]*\ze"')
    if match(line, '^\s*context') != -1
      let string = "when " . string
    endif
    call cursor(s:line_no-1, 0)
    return s:find_test_name_in_quotes(a:max_indent-1) . " " . string
  else
    return s:find_top_level_test()
  endif
endfunction

function! jasmine#RunTestInBrowser()
  let save_cursor = getpos(".")
  let test_name = s:find_test_context()
  call setpos('.', save_cursor)
  let s:browser_path = 'C:\Users\jwingfi\AppData\Local\Google\Chrome\Application\chrome.exe '
  let urlEncoded = substitute(test_name, "\\s", "%20", "g")
  exec 'silent !start ' . s:browser_path .
        \ '"file:///C:/code/net/git/SMB/Source/Application/SMB/Scripts/app/test/SpecRunner.html?spec='
        \ . test_name . '"'
endfunction

function! s:call_specrunner(test_name)
	echo "running " . a:test_name
    let urlEncoded = substitute(a:test_name, "\\s", "%20", "g")
    let specRunnerPath = 'file:///C:/code/net/git/SMB/Source/Application/SMB/Scripts/app/test/SpecRunner.html'
    let result = xolox#misc#os#exec({'command': "ansicon phantomjs-1.9.7-windows\\phantomjs.exe phantomjs-testrunner.js \"" . specRunnerPath . "?spec=" . urlEncoded . "&console=1\"", 'check': 0})['stdout']
    call s:set_signs(result)
    echo join(result, "\n")
endfunction

function! s:set_signs(result_list)
  for result in a:result_list
    let failed = matchstr(result, '.*:\s*\zs.*\ze\s*\.\.\.\s*Failed')
    let passed = matchstr(result, '.*:\s*\zs.*\ze\s*\.\.\.\s*Passed')
    " trim space
    let failed = substitute(failed,"^\\s\\+\\|\\s\\+$","","g") 
    let passed = substitute(passed,"^\\s\\+\\|\\s\\+$","","g") 

    let id = 1
    if strlen(failed) 
      let s:line_no = search('^\s\+it.\([''"]\)\s*' . failed . '\s*\1', 'cnw')
      if s:line_no <= 0
        echo "Error: couldnt find failed test: " . failed
        continue 
      endif

      exe 'sign place ' . id . ' line=' . s:line_no . ' name=failedJasmineTest file='
            \. expand('%:p') 
      let id += 1
    elseif strlen(passed)
      let s:line_no = search('^\s\+it.\([''"]\)\s*' . passed . '\s*\1', 'cnw')
      if s:line_no <= 0
        echo "Error: couldnt find passed test: " . passed
        continue 
      endif

      exe 'sign place ' . id . ' line=' . s:line_no . ' name=passedJasmineTest file='
            \. expand('%:p') 
      let id += 1
    endif
  endfor

  redraw!
endfunction

function! jasmine#RunTests()
  if (&filetype == "coffee" || &filetype == "javascript") 
    let save_cursor = getpos(".")
    let test_name = s:find_test_context()
    call setpos('.', save_cursor)
    if (strlen(test_name))
      let s:test_name = test_name
      call s:call_specrunner(test_name)
    else
      if strlen(s:test_name)
	  	  call s:call_specrunner(s:test_name)
	    else
      	echo "No test found to run"
      endif
    end
  endif
endfunction

function! jasmine#RunTopLevelTest()
  if (&filetype == "coffee" || &filetype == "javascript") 
    let test_name = s:find_top_level_test()
    if (strlen(test_name))
      let s:test_name = test_name
      call s:call_specrunner(test_name)
    else
      if strlen(s:test_name)
	  	  call s:call_specrunner(s:test_name)
	    else
      	echo "No test found to run"
      endif
    end
  endif
endfunction

