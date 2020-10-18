command! -nargs=+ -buffer -complete=customlist,goadapt#complete GoGuard call goguard#do(<f-args>)
