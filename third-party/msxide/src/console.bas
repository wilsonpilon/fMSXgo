' Seleciona backend de console no compile-time.
' Forca backend: -d MSX_CONSOLE_WIN ou -d MSX_CONSOLE_NEWT
' Sem forca: Win32 usa console_win, outros usam console_newt.
#Ifdef MSX_CONSOLE_WIN
    #Include Once "console_win.bas"
#Elseif Defined(MSX_CONSOLE_NEWT)
    #Include Once "console_newt.bas"
#Else
    #Ifdef __FB_WIN32__
        #Include Once "console_win.bas"
    #Else
        #Include Once "console_newt.bas"
    #EndIf
#EndIf
