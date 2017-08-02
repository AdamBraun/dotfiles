"-----------------------------------------------------------------------------}}}
"PRIVATES                                                                      {{{ 
"--------------------------------------------------------------------------------
function! s:get_git_root()
    if exists('*fugitive#repo')
        try
            return fugitive#repo().tree()
        catch
        endtry
    endif
    let root = split(system('git rev-parse --show-toplevel'), '\n')[0]
    return v:shell_error ? '' : root
endfunction

"-----------------------------------------------------------------------------}}}
"BUFFERS                                                                      {{{
"--------------------------------------------------------------------------------
let s:root = expand('<sfile>:p:h:h')
function! utils#buffers_all()
    return range(1, bufnr('$'))
endfunction

function! utils#buffers_names(_range)
    return map(a:_range, 'bufname(v:val)')
endfunction

function! utils#buffers_listed()
    let bufnumbers = filter(utils#buffers_all(), 'buflisted(v:val) && getbufvar(v:val, "&filetype") != "qf"')
    let bufnames = map(bufnumbers, 'bufname(v:val)')
    return bufnames
endfunction

function! utils#buffers_listedReadableFile()
    let buflisted = utils#buffers_listed()
    let readables = filter(buflisted, 'filereadable(v:val)')
    return readables
endfunction

function! s:buflisted()
    return filter(range(1, bufnr('$')), 'buflisted(v:val) && getbufvar(v:val, "&filetype") != "qf"')
endfunction
function! s:sort_buffers(...)
    let [b1, b2] = map(copy(a:000), 'get(g:fzf#vim#buffers, v:val, v:val)')
    " Using minus between a float and a number in a sort function causes an error
    return b1 < b2 ? 1 : -1
endfunction
function! s:list_buffers(...)
    let bufs = sort(s:buflisted(), 's:sort_buffers')
    return bufs
endfunction

function! utils#buf_delete_current()
    let listedbuffers=s:list_buffers()
    let bufnextnr = 1
    let currbuffname = expand('%')
    if(bufname('%') =~? 'NERD_tree')
        let bufnextnr = 0
        " buffer! #
    endif
    if(len(listedbuffers) > bufnextnr)
        let l:bufnext = listedbuffers[bufnextnr]
        let alternate = listedbuffers[bufnextnr]
    endif
    if(len(listedbuffers) > bufnextnr + 1)
        let alternate = listedbuffers[bufnextnr + 1]
    endif
    if exists('l:bufnext')
        if bufnextnr
            :BD
        endif
        execute 'buffer '.l:bufnext
        let @#=bufname(alternate)
    else
        echom 'last buffer'
    endif
endfunction
"-----------------------------------------------------------------------------}}}
"SNIP-MATE                                                                    {{{ 
"--------------------------------------------------------------------------------
function! utils#snipdefinition()
    let snippetFileName = s:root.'/snippets/'.&ft.'.snippets' 
    split
    execute 'edit '.snippetFileName
    nmap <buffer>q :quit<cr>
    if ! filereadable(snippetFileName)
        echoerr 'no snippet found for '.&ft
    endif
endfunction

"-----------------------------------------------------------------------------}}}
"BASEDIRS                                                                     {{{ 
"--------------------------------------------------------------------------------
function! utils#get_root_directory()
    return s:root
endfunction

function! utils#get_git_root_directory()
    return s:get_git_root()
endfunction

function! utils#get_bin_directory()
    return s:root.'/bin'
endfunction

"-----------------------------------------------------------------------------}}}
"SHELL                                                                      {{{ 
"--------------------------------------------------------------------------------
function! s:shell_cmd_completed(...) dict
    wincmd P
    setlocal modifiable
    call append(line('$'), self.shell)
    call append(line('$'), '########################FINISHED########################')
    normal! G
    setlocal nomodifiable
    if exists(':DimInactiveBufferOn')
        " DimInactiveBufferOn
    endif
    wincmd p
endfunction

function! s:JobHandler(job_id, data, event) dict
    let str = join(a:data)
    wincmd P
    call append(line('$'), str)
    normal! G
    wincmd p
endfunction

function! utils#run_shell_command(cmdline, bang)
    let expanded_cmdline = a:cmdline
    if a:bang
        let expanded_cmdline = 'source ~/.zshrc; loadall; [[ -f .nvmrc ]] && nvm use $(cat .nvmrc); '.expanded_cmdline
    endif
    " echo a:cmdline
    for part in split(a:cmdline, ' ')
        if part[0] =~ '\v[%#<]'
            let expanded_part = fnameescape(expand(part))
            let expanded_cmdline = substitute(expanded_cmdline, part, expanded_part, '')
        endif
    endfor
    let s:shell_tmp_output = tempname()
    execute 'pedit '.s:shell_tmp_output
    wincmd P
    wincmd J
    if exists(':DimInactiveBufferOff')
        DimInactiveBufferOff
    endif
    if exists(':AnsiEsc')
        AnsiEsc
    endif
    setlocal modifiable
    setlocal nobuflisted
    nnoremap <buffer>q :bd<cr>
    wincmd p
    let s:callbacks = {
    \ 'on_stdout': function('s:JobHandler'),
    \ 'on_stderr': function('s:JobHandler'),
    \ 'on_exit': function('s:shell_cmd_completed'),
    \ 'shell': expanded_cmdline
    \ }
    call jobstart(expanded_cmdline, s:callbacks)
endfunction

"-----------------------------------------------------------------------------}}}
"GENERAL                                                                      {{{ 
"--------------------------------------------------------------------------------
function! s:focusTerminalIfVisible()
    let tabPageNum = tabpagenr()
    let buflist = tabpagebuflist(tabPageNum)

    for i in range(1, len(buflist))
        if bufname(buflist[i-1]) =~ '^term://'
            " let winnr = buflist[i]
            execute i.'wincmd w'

            return 1
        endif
    endfor
endfunction
function! utils#toTerminal()
    if !s:focusTerminalIfVisible()
        let bufnames = utils#buffers_names(utils#buffers_all())
        call utils#isTerminal('', '')
        let term = filter(bufnames, 'v:val =~ ''^term://''')
        if get(term, 0, '') != ''
            execute 'e '.term[0]
        else
            te
        endif
    endif
    startinsert
endfunction

function! utils#restoreAlternateFile()
    let alternate = expand('#')
    if ! len(alternate) || alternate == expand('%') || alternate =~ 'term://' || alternate =~ 'NERD_tree'
        let listedbuffers=utils#buffers_listed()
        if len(listedbuffers) > 1
            if expand(bufname(listedbuffers[1])) == expand('%')
                "ListBuffers has not been updated yet
                let @#=bufname(listedbuffers[0])
                return
            endif
            let @#=bufname(listedbuffers[1])
        endif
    endif
endfunction

function! utils#open_in_webstorm()
    :call system('webstorm --line '.getpos('.')[1].' '.expand('%:p')) 
endfunction

function! utils#isTerminal(_, filename)
    return a:filename =~ '^term://'
endfunction

function! utils#cursor_ping(...)
    let _cursorline = &cursorline
    let _cursorcolumn = &cursorcolumn
    set cursorline 
    if !a:0
        set cursorcolumn
    endif
    redraw
    sleep 350m
    let &cursorline = _cursorline
    let &cursorcolumn = _cursorcolumn
endfunction

" Window movement shortcuts
" move to the window in the direction shown, or create a new window
function! utils#win_move(key)
    let t:curwin = winnr()
    echo 'windMove'
    exec "wincmd ".a:key
    if (t:curwin == winnr())
        if (match(a:key,'[jk]'))
            wincmd v
        else
            wincmd s
        endif
        exec "wincmd ".a:key
    endif
endfunction

function! utils#toggle_window_to_nerd_tree()
    "need to commit change in nerdtree and relate to it for this commit
    " see sudavid4/nerdtree commit 909cf25722f206f82128554c7c6dd1ed34a95949 is needed for this to work properly
    if ! exists('t:NERDTreeBuffName')
        NERDTreeToggle
        sleep 100m
    endif
    if g:NERDTree.IsOpen()
        NERDTreeClose
        sleep 100m
    endif
    "this is likely useless since sudavid4/nerdtree commit 909cf25722f206f82128554c7c6dd1ed34a95949 
    let w:dontsavescreenstate = 1
    let currfile = expand('%:p:t')
    edit %:p:h
    call search(currfile)
endfunction

function! utils#get_project_root(dirname)
    if a:dirname =~ $DOTFILES.'/config/nvim'
        return $DOTFILES.'/config/nvim'
    endif
    let foundRoot = isdirectory(a:dirname.'/.git') || filereadable(a:dirname.'/package.json')
    if foundRoot
        return a:dirname
    elseif a:dirname == '/'
        return
    else
        " walk to the top of the dir tree
        let l:parentDir = strpart(a:dirname, 0, strridx(a:dirname, '/'))
        if isdirectory(l:parentDir)
            return utils#get_project_root(l:parentDir)
        endif
    endif
endfunction

function! utils#cd_project_root(dirname)
    let projRoot = utils#get_project_root(a:dirname)
    if isdirectory(projRoot)
        execute 'cd '.projRoot
    else
        execute 'cd '.a:dirname
    endif
endfunction
