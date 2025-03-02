; RunCmdWithExpect(command, expect, timeout := 0.25)
; RunCmd(command, timeout := 0.25)
; RunThisAsAdmin()
; WinShutDown()
; WinSleep()

#Include %A_ScriptDir%\lib\text\Text.ahk

RunCmdWithExpect(command, expect, timeout := 0.25)
{
    Return IsTextIncluding(RunCmd(command, timeout), expect)
}

RunCmd(command,  timeout:=0.25, ByRef nExitCode:=0) {
    DllCall("CreatePipe", PtrP, hStdOutRd, PtrP, hStdOutWr, Ptr, 0, UInt, 0)
    DllCall("SetHandleInformation", Ptr,hStdOutWr, UInt,1, UInt,1)
    VarSetCapacity(pi, (A_PtrSize == 4) ? 16 : 24, 0)
    siSz := VarSetCapacity(si, (A_PtrSize == 4) ? 68 : 104, 0)
    NumPut(siSz, si, 0, "UInt")
    NumPut(0x100, si, (A_PtrSize == 4) ? 44 : 60, "UInt")
    NumPut( hStdOutWr, si, (A_PtrSize == 4) ? 60 : 88, "Ptr")
    NumPut( hStdOutWr, si, (A_PtrSize == 4) ? 64 : 96, "Ptr")
    If (!DllCall("CreateProcess", Ptr, 0, Ptr, &command, Ptr, 0, Ptr, 0, Int, True, UInt, 0x08000000, Ptr, 0, Ptr, 0, Ptr, &si, Ptr, &pi) )
        Return ""
            , DllCall( "CloseHandle", Ptr,hStdOutWr )
            , DllCall( "CloseHandle", Ptr,hStdOutRd )
    DllCall("CloseHandle", Ptr, hStdOutWr) ; The write pipe must be closed before reading the stdout.
    outputStr := ""
    While ( 1 )
    { ; Before reading, we check if the pipe has been written to, so we avoid freezings.
        If (!DllCall("PeekNamedPipe", Ptr, hStdOutRd, Ptr, 0, UInt, 0, Ptr, 0, UIntP, nTot, Ptr, 0) )
            Break
        If (!nTot)
        { ; If the pipe buffer is empty, sleep and continue checking.
            Sleep, 100
            Continue
        } ; Pipe buffer is not empty, so we can read it.
        VarSetCapacity(sTemp, nTot + 1)
        DllCall("ReadFile", Ptr, hStdOutRd, Ptr, &sTemp, UInt, nTot, PtrP, nSize, Ptr, 0)
        outputStr .= StrGet(&sTemp, nSize, "CP0")
    }

    ; * SKAN has managed the exit code through SetLastError.
    DllCall( "GetExitCodeProcess", Ptr,NumGet(pi,0), UIntP,nExitCode )
    DllCall( "CloseHandle",        Ptr,NumGet(pi,0)                  )
    DllCall( "CloseHandle",        Ptr,NumGet(pi,A_PtrSize)          )
    DllCall( "CloseHandle",        Ptr,hStdOutRd                     )
    Return Trim(outputStr," `n`r`t")
}

; 运行 cmd 命令并返回运行结果
; 注意, 耗时的 cmd 指令可能会导致延迟返回等奇怪问题
; 会影响剪贴板的使用
global isRunning_System := False
RunCmd1(command, timeout := 0.25)
{
    If (!command)
        Return ""
    While (isRunning_System)
        Sleep, 1
    isRunning_System := True

    ClipSaved := ClipboardAll ; 把剪贴板的所有内容 (任何格式)

    Clipboard := "" ; 清除

    Run % ComSpec " /c chcp 65001 && " . command . " | CLIP", , Hide
    ClipWait, timeout

    result := Clipboard
    Clipboard := ClipSaved ; 使用 Clipboard (不是 ClipboardAll)
    isRunning_System := False
    Return result
}

RunThisAsAdmin()
{
    if !(A_IsAdmin || InStr(DllCall("GetCommandLine", "Str"), ".exe /r"))
        RunWait % "*RunAs " ( _ := A_IsCompiled ? """" : A_AhkPath " /r """) A_ScriptFullPath (_ ? """" : """ /r")
}

WinShutDown()
{
    Shutdown, 1
}

WinSleep()
{
    DllCall("PowrProf\SetSuspendState", "int", 0, "int", 0, "int", 0)
}