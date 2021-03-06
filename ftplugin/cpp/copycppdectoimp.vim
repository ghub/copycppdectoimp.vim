if exists("b:loaded_copycppdectoimp")
    finish
endif
let b:loaded_copycppdectoimp = 1

if !exists("*s:GrabFromHeaderPasteInSource()")
function s:GrabFromHeaderPasteInSource()
    if expand("%:e") =~? "h.*"

        let SaveL = line(".")
        let SaveC = virtcol(".")

        execute ":normal! H"
        let SaveT = line('.')
        execute ":normal! ".SaveL."G"

        let StartLine = 0
        if stridx(getline('.'), '(') > -1
            execute "normal! 0f("
        else
            execute "/("
            execute "normal! 0f("
            let StartLine = -1
        endif

        let EndLine = searchpair('(', '', ').\{-};', 'rW')
        let StartLine += searchpair('(', '', ')', 'bW')

        if EndLine == 0 || StartLine == 0
            echo "GHPH: ERROR: Sorry this does not look like a function decloration, missing '(' and or ')' with trailing ';'"
            return
        endif

        :let Was_Reg_l = @l

        execute ":".StartLine.",".EndLine."yank l"
        :let s:LineWithDecloration = @l
        :let @l=Was_Reg_l

        let s:LineWithDeclorationSize = ( (EndLine - StartLine) + 1)

        let s:ClassName = ""
        let mx='\(\<class\>\|\<struct\>\|\<namespace\>\)\s\{-}\(\<\I\i*\)\s\{-}.*'
        while 1
            if searchpair('{','','}', 'bW') > 0
                if search('\%(\<class\>\|\<struct\>\|\<namespace\>\).\{-}\n\=\s\{-}{', 'bW') > 0
                    let DaLine = getline('.')
                    let Lummox = matchstr(DaLine, mx)

                    let FoundType = substitute(Lummox, mx, '\1', '')
                    let FoundClassName = substitute(Lummox, mx, '\2', '')

                    if FoundType !=? 'namespace' && FoundType != ''
                        let s:ClassName = FoundClassName.'::'.s:ClassName
                    endif
                else
                    echo confirm("copycppdectoimp.vim:DEV:Found {} but no class/struct\nIf this was a proper function and you think it should have worked, email me the (member) function/class setup and I'll see if I can get it to work.(email is in this file)")
                endif
            else
                break
            endif
        endwhile

        :execute ":normal! ".SaveT."Gzt"
        :execute ":normal! ".SaveL."G"
        :execute ":normal! ".SaveC."|"

    else

        if !exists("s:LineWithDecloration")
            echo "GHPH: ERROR: I do not have an implimentation to work with!"
            return
        endif

        let SaveL = line(".")

        execute ":normal! H"
        let SaveT = line('.')
        execute ":normal! ".SaveL."G"

        :let Was_Reg_n = @n
        :let @n=@/

        :let Was_Reg_l = @l
        :let @l = s:LineWithDecloration

        execute 'normal! "lP'
        :let @l=Was_Reg_l

        let SaveReport = &report
        setlocal report=9999
        let Save2L = line(".")
        execute ':'.Save2L.','.(Save2L+s:LineWithDeclorationSize-1).'s/\s\{-}\/[/*].\{-}$//e'
        :execute ":normal! ".Save2L."G"
        execute "setlocal report=".SaveReport

        if s:LineWithDeclorationSize > 1
            :execute ':normal! '.s:LineWithDeclorationSize.'J'
            execute ':s/\t\+/ /ge'
            execute ':s/\(\i(\) /\1/e'
        endif

        let Was_EqualPrg = &equalprg

        set equalprg=""
        execute ':normal! =='
        execute "set equalprg=".Was_EqualPrg

        execute ':s/\<virtual\>\s*//e'
        execute ':s/\<static\>\s*//e'

        execute ':s/)\s\{-}=\s\{-}0\s\{-};/);/e'
        execute ':s/\<explicit\>\s*//e'
        execute ':s/\s\{-}=\s\{-}[^,)]\{1,}//ge'

        let @/=@n
        let @n=Was_Reg_n
        execute ":normal! ".SaveT."Gzt"
        execute ":normal! ".SaveL."G"

        if s:ClassName !=# ""
            if stridx(getline('.'), '~') > -1
                execute ':normal! 0f(F~'
            else
                execute ':normal! 0f(b'
            endif
            execute ':normal! i'.s:ClassName
        endif

        :execute ":normal! f;s\<cr>{\<cr>}\<esc>k"
    endif

endfunc
endif

:command -buffer GHPH call <SID>GrabFromHeaderPasteInSource()
