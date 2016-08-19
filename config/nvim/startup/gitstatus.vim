function! DiffWebstorm()
	" set cursor to start of line
	execute 'silent normal! ?^.'."\r"

	" find file name with path
	execute 'silent normal! /\v(\w*(\/|$)(\w|-)*)+'."\r"

	" copy file name to register x
	"execute 
	normal "xy$
	let b:boo=@x
	" open diff in webstorm
	execute '!git difftool -t=webstorm '.b:boo
endfunction
autocmd BufEnter *.git/index nmap <buffer> <silent>q :q<cr>

autocmd BufEnter *.git/index map <buffer> <silent> <leader>d :call DiffWebstorm()<cr>
command! Gdiffw !git difftool -t=webstorm %
