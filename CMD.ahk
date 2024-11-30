; RunCmdWithExpect(command, expect, timeout := 0.5)
; RunCmd(command, timeout := 0.5)

#Include Text.ahk

RunCmdWithExpect(command, expect, timeout := 0.3)
{
    Return IsTextIncluding(RunCmd(command, timeout), expect)
}

; 运行 cmd 命令并返回运行结果
; 注意, 耗时的 cmd 指令可能会导致延迟返回等奇怪问题
; 会影响剪贴板的使用
RunCmd(command, timeout := 0.3)
{
    If (!command)
        Return ""

    ClipSaved := ClipboardAll ; 把剪贴板的所有内容 (任何格式)

    Clipboard := "" ; 清除

    Run % ComSpec " /c " . command . " | CLIP", , Hide
    ClipWait, timeout

    result := Clipboard
    Clipboard := ClipSaved ; 使用 Clipboard (不是 ClipboardAll)
    Return result
}