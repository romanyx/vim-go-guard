let s:save_cpo = &cpo
set cpo&vim

let g:goguard#cmd = get(g:, 'goguard#cmd', 'go-guard')

function! s:error(msg)
    echohl ErrorMsg | echomsg a:msg | echohl None
endfunction

function! s:check_bin_path(binpath)
    let binpath = a:binpath
    if executable(binpath)
        return binpath
    endif

    " just get the basename
    let basename = fnamemodify(binpath, ":t")

    " check if we have an appropriate bin_path
    let go_bin_path = s:bin_path()
    if empty(go_bin_path)
        return ''
    endif

    let new_binpath = go_bin_path . '/' . basename
    if !executable(new_binpath)
        return ''
    endif

    return new_binpath
endfunction

function! s:bin_path()
    " check if our global custom path is set, if not check if $GOBIN is set so
    " we can use it, otherwise use $GOPATH + '/bin'
    if exists("g:go_bin_path")
        return g:go_bin_path
    elseif !empty($GOBIN)
        return $GOBIN
    elseif !empty($GOPATH)
        return $GOPATH . '/bin'
    endif

    return ''
endfunction

function! s:system(str, ...)
    let command = a:str
    let input = a:0 >= 1 ? a:1 : ''

    if a:0 == 0
        let output = s:has_vimproc() ?
                    \ vimproc#system(command) : system(command)
    elseif a:0 == 1
        let output = s:has_vimproc() ?
                    \ vimproc#system(command, input) : system(command, input)
    else
        " ignores 3rd argument unless you have vimproc.
        let output = s:has_vimproc() ?
                    \ vimproc#system(command, input, a:2) : system(command, input)
    endif

    return output
endfunction

function! s:shell_error()
    return s:has_vimproc() ? vimproc#get_last_status() : v:shell_error
endfunction

function! goguard#guard(action, name)
    let binpath = s:check_bin_path(g:goguard#cmd)
    if empty(binpath)
        call s:error(g:goguard#cmd . ' command is not found. Please check g:goguard#cmd')
        return ''
    endif

    let result = s:system(printf("%s '%s' '%s'", binpath, a:action, a:name))

    if s:shell_error()
        call s:error(binpath . ' command failed: ' . result)
        return ''
    endif

    return result
endfunction

function! s:has_vimproc()
    if !exists('s:exists_vimproc')
        try
            silent call vimproc#version()
            let s:exists_vimproc = 1
        catch
            let s:exists_vimproc = 0
        endtry
    endif
    return s:exists_vimproc
endfunction

function! goguard#do(...)
    if a:0 < 2
	call s:error('GoGuard {action} {function}')
        return
     endif
    let action = join(a:000[:-2], ' ')
    let name = a:000[-1]
    let result = goguard#guard(action, name)

     if result ==# ''
         return
     end

     let pos = getpos('.')
     put =result
     call setpos('.', pos)
     return
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
