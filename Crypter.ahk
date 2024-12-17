#Include %A_ScriptDir%\FileTools.ahk
#Include %A_ScriptDir%\Message.ahk

#NoTrayIcon ; 不显示小图标
#SingleInstance force ; 单例模式

#NoEnv
#MaxHotkeysPerInterval 99000000
#HotkeyInterval 99000000
#KeyHistory 0
ListLines Off
Process, Priority, , A
SetBatchLines, -1
SetKeyDelay, -1, -1
SetMouseDelay, -1
SetDefaultMouseSpeed, 0
SetWinDelay, -1
SetControlDelay, -1
SendMode Input

OnMessage(4564, "SetProgress")

global tWidth := 70
    , eWidth := 300
    , bWidth := 80
    , xMargin := 10
    , yMargin := 10
    , pWidth := xMargin + bWidth + eWidth
    , maxWidth := tWidth + eWidth + bWidth
    , realMaxWidth := maxWidth + xMargin
    , halfWidth := maxWidth / 2

    , sec := 1000
    , min := 1000 * 60
    , hour := 1000 * 60 * 60
    , day := 1000 * 60 * 60 * 24

    , Hwnd_Cryper := "XOR"
    , BufferSize_Crypter := 4096

Gui, Add, Text, x%xMargin% w%tWidth%, 原文件:
Gui, Add, Edit, x+ w%eWidth% vInputFile
Gui, Add, Button, x+%xMargin% w%bWidth% gBrowseInput, 浏览...

Gui, Add, Text, x%xMargin% y+%yMargin% w%tWidth%, 输出文件:
Gui, Add, Edit, x+ w%eWidth% vOutputFile
Gui, Add, Button, x+%xMargin% w%bWidth% gBrowseOutput, 浏览...

Gui, Add, Text, x%xMargin% y+%yMargin% w%tWidth%, 密钥:
Gui, Add, Edit, x+ w%pWidth% vPassword

Gui, Add, Button, x%xMargin% y+%yMargin% w%halfWidth% gCrypt, XOR
Gui, Add, Button, x+%xMargin% w%halfWidth% gSwitch, 调转文件

Gui, Add, Progress, x%xMargin% y+%yMargin% w%realMaxWidth% h20 vProgressBar

Gui, Show, , %Hwnd_Cryper%

return

GuiClose:
ExitApp

BrowseInput:
    FileSelectFile, SelectedFile, 3,, 选择原文件
    if (SelectedFile != "")
        GuiControl,, InputFile, %SelectedFile%
return

BrowseOutput:
    FileSelectFile, SelectedFile, S16,, 选择输出文件, All Files (*.*)
    if (SelectedFile != "")
        GuiControl,, OutputFile, %SelectedFile%
return

Switch:
    Gui, Submit, NoHide
    i := InputFile
    o := OutputFile
    GuiControl,, InputFile, %o%
    GuiControl,, OutputFile, %i%
Return

Crypt:
    Gui, Submit, NoHide
    GuiControl,, ProgressBar, 0
    if (InputFile == "" or OutputFile == "" or Password == "")
    {
        MB("请填写所有字段")
        return
    }
    XORFile_Cypter(InputFile, OutputFile, Password)
; if (GetType(result) == "number")
; {
;     SetProgress(100)
;     If (result > day)
;         time := (result / day) . " 天"
;     Else If (result > hour)
;         time := (result / hour ) . " 时"
;     Else If (result > min)
;         time := (result / min) . " 分"
;     Else If (result > sec)
;         time := (result / sec) . " 秒"
;     Else
;         time := result . " 毫秒"
;     MB("操作完成, 耗时: " . time)
; }
; else
; {
;     MB("操作失败: " . result)
; }
return

XORFile_Cypter(inFilePath, outFilePath, password)
{
    If (inFilePath == outFilePath)
        Return "设置了相同的路径, 这是一个不安全的操作"
    size := GetFileSize(inFilePath)
    order := "r := DllCall(""Libs\XOR.dll\XORFile"", ""Str"",""" . inFilePath
        . """, ""Str"",""" . outFilePath
        . """, ""Str"",""" . password
        . """, ""Int""," . BufferSize_Crypter
        . ", ""int64""," . size
        . ", ""Str"",""" . Hwnd_Cryper . """)`nMsgBox, 262144, XOR , %r%"
    RunOnNewThread(order)
}

SetProgress(v)
{
    GuiControl,, ProgressBar, %v%
}

XORFileTelling1(inFilePath, outFilePath, password)
{
    bufferSize := 2048
    tick := A_TickCount

    If (inFilePath == outFilePath)
        Return "设置了相同的路径, 这是一个不安全的操作"
    If (GetType(bufferSize) != "number" || bufferSize <= 0)
        Return "缓存大小设置有误: " . bufferSize
    If (!FileExist(inFilePath))
        Return "原文件不存在"

    fileIn := FileOpen(inFilePath, "r")
    fileOut := GetEmptyFile(outFilePath)

    if(!fileIn || !fileOut)
    {
        if (fileIn)
            fileIn.Close()
        if (fileOut)
            fileOut.Close()
        Return "文件获取失败"
    }

    VarSetCapacity(buffer, bufferSize)

    pwBytes := StrSplit(password)
    pwLength := StrLen(password)

    fileSize := fileIn.Length
    processedBytes := 0

    ; 读取、加密并写入
    while (bytesRead := fileIn.RawRead(&buffer, bufferSize))
    {
        Loop % bytesRead ; 对每个字节进行异或操作
        {
            pwIndex := Mod(A_Index - 1, pwLength) + 1
            dataByte := NumGet(buffer, A_Index - 1, "UChar")
            pwByte := Asc(pwBytes[pwIndex])
            encryptedByte := dataByte ^ pwByte
            NumPut(encryptedByte, buffer, A_Index - 1, "UChar")
        }

        fileOut.RawWrite(&buffer, bytesRead)
        processedBytes += bytesRead
        progress := Round((processedBytes / fileSize) * 100)
        GuiControl,, ProgressBar, %progress%
    }

    fileIn.Close()
    fileOut.Close()
    GuiControl,, ProgressBar, 100
    Return (A_TickCount - tick)
}

RunOnNewThread(command)
{
    head := "#NoTrayIcon`n#SingleInstance force`n#NoEnv`n#MaxHotkeysPerInterval 99000000`n#HotkeyInterval 99000000`n#KeyHistory 0`nListLines Off`nProcess, Priority, , A`nSetBatchLines, -1`nSetKeyDelay, -1, -1`nSetMouseDelay, -1`nSetDefaultMouseSpeed, 0`nSetWinDelay, -1`nSetControlDelay, -1`nSendMode Input`n"
    tail := "`nExitApp"
    order := head . command . tail
    tempFile := A_ScriptDir . "\~tmp_" . A_TickCount . ".ahk"
    FileDelete %tempFile% ; 删除旧的临时文件(如果存在)
    FileAppend, %order%, %tempFile% ; 将代码写入临时文件
    RunWait %A_AhkPath% /r "%tempFile%"
    FileDelete %tempFile%
}