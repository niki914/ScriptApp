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

; 运行 cmd 命令并返回运行结果
; 注意, 耗时的 cmd 指令可能会导致延迟返回等奇怪问题
; 会影响剪贴板的使用
global isRunning_System := False
RunCmd(command, timeout := 0.25)
{
    If (!command)
        Return ""
    While (isRunning_System)
        Sleep, 1
    isRunning_System := True

    ClipSaved := ClipboardAll ; 把剪贴板的所有内容 (任何格式)

    Clipboard := "" ; 清除

    Run % ComSpec " /c " . command . " | CLIP", , Hide
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