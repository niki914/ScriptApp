global keywords := ["for", "if", "loop", "else", "else if", "while", "switch", "try", "catch", "when"]
; global localhostPath := A_ScriptDir . "\base_url.txt"
global WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")

; Chrome_Run(url)
; {
;     ChromeInst := new Chrome("C:\Users\" . A_UserName . "\AppData\Local\Microsoft\Edge\User Data", url)
;     Return ChromeInst
; }

; Action_LoaclTunnel(port := "3000")
; {
;     result := GetUrl_NewLoaclTunnel()

;     If (!result)
;         Return

;     oldUrl := GetUrl_OnLocalFile()

;     If (result != oldUrl)
;         FileOpen(localhostPath, "w").Write(result).Close()

;     Clipboard := result
;     ShowSplashText("localhost", "successfully run`n" . result, 1000)
; }

; GetUrl_OnLocalFile()
; {
;     FileRead, url, %localhostPath%
;     Return url
; }

; GetUrl_NewLoaclTunnel(port := "3000")
; {
;     ; Run % ComSpec " /c lt --port 3000", , Maximize
;     Run % ComSpec " /c ssh -R 80:localhost:" . port . " localhost.run`nyes`n", , Maximize
;     ; Run % ComSpec " /c ssh -R 80:localhost:3000 NIKI@localhost.run`nyes`n", , Maximize

;     Sleep, 1000

;     SetTitleMatchMode, 2
;     IfWinExist, cmd.exe
;     {
;         BlockInput, On
;         WinMaximize
;     }
;     Else
;         Return ""

;     Sleep, 500
;     WinGetPos, X, Y, Width, Height, A

;     StartX := (X + Width) * 0.8
;     StartY := (Y + Height) * 0.8
;     EndX := X
;     EndY := Y

;     While !result
;     {
;         Click, %StartX%, %StartY%, Down ; 按下鼠标左键
;         SetDefaultMouseSpeed, 3
;         Click, %EndX%, %EndY%, Up ; 释放鼠标左键

;         Sleep, 200
;         result := ""
;         previous := ClipboardAll ; backup

;         Clipboard := ""
;         SendInput, ^c
;         ClipWait, 0.5

;         result := Clipboard
;         result := Trim(result, "`n`r ")
;         result := Filter(result, "(http.+?.life)")
;         Clipboard := previous ; restitute
;     }

;     ; SetDefaultMouseSpeed, 0
;     ; Click, %Width%, %Y%

;     WinMinimize
;     BlockInput, Off

;     Return result
; }

Action_Translate()
{
    rawText := GetText_Clipboard()
    str := ParseCamel(rawText)

    if (ErrorLevel || RegExReplace(str, "\s") == "")
        Return

    str := BingTranslate(str)
    ShowSplashText("press C to copy", str)

    Input, key, L1, {Tab}{BackSpace}{LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}{AppsKey}{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}{Left}{Right}{Up}{Down}{Home}{End}{PgUp}{PgDn}{Del}{Ins}{BS}{Capslock}{Numlock}{PrintScreen}{Pause}
    if (key = "c")
        Clipboard := str

    CloseWin()
}

; 尝试通过剪贴板生成一个 api 并访问
; 当前实现直接搜索和翻译
Action_UseBrowser(title, url)
{
    content := GetText_Clipboard()
    if (ErrorLevel || RegExReplace(content, "\s") == "")
    {
        InputBox content, %title%, What To %title%?, , 330, 130
        if (content == "")
            Return
    }
    Run %url%%content% ; 'https://xxx.com?q=' + 'content'
}

; bing 翻译 api
BingTranslate(text)
{
    langfrom := RegExMatch(text, "[\x{4e00}-\x{9fa5}]") ? "zh-CN": "en"
    langto := langfrom = "en" ? "zh-CN" : "en"

    ; 构建完整的翻译 api
    url := "http://api.microsofttranslator.com/v2/Http.svc/Translate?appId="
        . "74FE953EB48E1487E94F4BF9C425B6290FF2DA48"
        . "&from="
        . RegExReplace(langfrom, "S)-.*$")
        . "&to="
        . RegExReplace(langto, "S)-.*$")
        . "&text=" text

    rawResponse := Web_Get(url)
    ; <string xmlns="http://schemas.microsoft.com/2003/10/Serialization/">Persistent   </string>
    response := Filter(rawResponse, "((?<=>).*?(?=</string>))")

    If (!rawResponse)
        Return "error;("
    If (!response)
        Return "no response;)"

    return response
}

; 检查并在当注册表值不一致(或无)时写入
Menu_Check(key, value, data) {
    RegRead, existingValue, % key, % value
    if (existingValue != data)
        RegWrite, % RegType ? RegType : "REG_SZ", % key, % value, % data
}

; 写入注册表菜单项
; 文件类型 - 菜单项名 - 文件类型的新键 - 新键的命令
; "Directory\shell\Parse"
; "my action"
; "myKey"
; "cmd /c cd /d "yourPath""
Menu_Put(type, actionName, key, command)
{
    commandKey := type . "\" . key
    Menu_Check("HKCR", type, actionName)
    Menu_Check("HKCR", commandKey, command)
}

; Menu_Receive()
; {
;     if A_ScriptHwnd != A_UniqueID ; 如果不是重新启动
;     {
;         param := A_ScriptHwnd ? A_ScriptHwnd : 1
;         if param = a
;             a(A_ScriptHwnd ? A_ScriptHwnd : A_ScriptFullPath)
;         else if param = b
;             b(A_ScriptHwnd ? A_ScriptHwnd : A_ScriptFullPath)
;     }
; }

; Menu_Put()
; {
;     ; 为文件夹添加"解析"右键菜单项
;     folderKey := "Directory\shell\Parse"
;     folderValue := ""
;     folderData := "解析"
;     Menu_Check("HKCR", folderKey, folderData)
;     folderCommandKey := folderKey "\command"
;     folderCommandData := "%A_AhkPath% """"""%A_ScriptFullPath%"""" ""a"" ""%V"""
;     Menu_Check("HKCR", folderCommandKey, folderCommandData)

;     ; 为 .ahk 和 .kt 文件添加"解析文件"右键菜单项
;     fileKey := ".ahk\shell\ParseFile"
;     fileValue := ""
;     fileData := "解析文件"
;     Menu_Check("HKCR", fileKey, fileData)
;     fileCommandKey := fileKey "\command"
;     fileCommandData := "%A_AhkPath% " """"%A_ScriptFullPath%"""" ""b"" ""%1"""
;     Menu_Check("HKCR", fileCommandKey, fileCommandData)

;     ktKey := ".kt\shell\ParseFile"
;     ktValue := ""
;     ktData := "解析文件"
;     Menu_Check("HKCR", ktKey, ktData)
;     ktCommandKey := ktKey "\command"
;     Menu_Check("HKCR", ktCommandKey, fileCommandData)
; }

Ping(url, timeout := 1)
{
    result := -1
    Try
    {
        ; WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        WebRequest.Open("GET", url, true, "", "", 1000)
        WebRequest.Send()
        WebRequest.WaitForResponse(timeout)

        result := WebRequest.Status

        WebRequest.Close()
        ; ObjRelease(WebRequest)

        Return result
    }
    Catch
    {
        Return result
    }
}

Web_Get(url, timeOut := 1500)
{
    Try
    {
        result := ""

        WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        WebRequest.Open("GET", url, true, "", "", timeOut)
        WebRequest.Send()
        WebRequest.WaitForResponse()

        result := WebRequest.ResponseText
        ObjRelease(WebRequest)

        Return result
    }
    Catch
    {
        Return ""
    }
}

CloseWin()
{
    Progress, Off
    SplashTextOff
}

Msg(content)
{
    MsgBox, 262144, , %content%
}

; 解析驼峰字符串为英文句段
; 效果: ‘StrSplit(str, A_Space)’ -> 'Str split ( str , A _ Space )'
; 当内容为全大写的单词则会全部拆开
ParseCamel(str)
{
    result := ""
    words := StrSplit(str, A_Space) ; 预处理: 按空格拆分为数组

    for index, word in words
    { ; 遍历
        if (index > 1)
            result .= A_Space ; 处理下一个数组元素前插入空格

        position := 1
        len := StrLen(word) ; 用于判断循环

        while (position <= len)
        {
            ; position 对应的字符
            thisChar := SubStr(word, position, 1)
            ; position + 1 对应的字符
            nextChar := (position < len) ? SubStr(word, position + 1, 1) : ""

            thisCharIsLowercase := RegExMatch(thisChar, "^[a-z]$")
            thisCharIsUppercase := RegExMatch(thisChar, "^[A-Z]$")
            thisCharIsLetter := thisCharIsLowercase || thisCharIsUppercase

            ; 非首字符并且是大写则转化为小写
            if (position > 1 && thisCharIsUppercase)
            {
                result .= Format("{:L}", thisChar)
            }
            Else
            {
                ; 否则不处理
                result .= thisChar
            }

            ; 下一字符不是小写或空格(空格不需要再加空格), 或者当前字符不是字母, 则插入空格
            if (!RegExMatch(nextChar, "^[a-z ]$") || !thisCharIsLetter)
                result .= A_Space

            position++
        }
    }

    return result
}

; 映射 sendInput
SendString(str)
{
    SendInput % str
}

; 运行并通过 splash text 反馈
RunWithSplashText(path)
{
    Run % path
    ShowSplashText("", "√", 800)
}

RunWaitString(command)
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

; 选中一段 url 比如 '/login/refresh' 或 'login/refresh'
; 已经处理了是否开头是否为 '/'
; 便于网易云 api 的调试
Run_OnLocalHost(url) {
    content := GetText_Clipboard()
    if (ErrorLevel || RegExReplace(content, "\s") == "")
        Return
    ; 检查起始字符是否为 '/'
    if (SubStr(content, 1, 1) != "/")
        content := "/" . content
    Run %url%%content%
}

; 运行 cmd 命令并检查结果是否包含期望的值
RunCmd_IsValueExisted(order, hope := "")
{
    cmdInfo := GetText_Clipboard(order)

    If (hope = "")
        Return True
    Else
        Return InStr(cmdInfo, hope, False, 1, 1) > 0 ; check if "cmdInfo" is including "hope"
}

; 运行 cmd 命令并返回运行结果
RunCmd_GetFullResult(order)
{
    Return GetText_Clipboard(order)
}

; 遍历选定目录下的所有文件, 并将所有文件用函数实例 funcInstance 运行, 然后将结果压入 result
Run_Folder(folderPath := "", funcInstance := "") {
    FileSelectFolder, folderPath, , 3, 选择一个文件夹

    If (!folderPath || !FileExist(folderPath))
        Return

    result := {}

    Loop, %folderPath%\*.*, 0, 1 ; 遍历文件夹,不进入子文件夹
    {
        If (funcInstance) {
            Try {
                r := %funcInstance%(A_LoopFileFullPath)
                If (r)
                    result[A_LoopFileName] := r
            }
            Catch {
                Msg(A_LoopFileName . "解析失败")
            }
        }
    }

    Loop, %folderPath%\*.*, 2, 1 ; 遍历子文件夹
    {
        If A_LoopFileIsDir {
            subResult := Run_Folder(A_LoopFileFullPath, funcInstance)
            For index, value in subResult
                result[index] := value
        }
    }

    Return result ; for index, value in result
}

; 读取一个目录下的文本文件, 并提取函数定义并写入新的 txt 文件内
ReadFunctionsInFolder()
{
    result := Run_Folder("", Func("ReadFunctionsInFile"))

    If (!result)
        Return

    FileSelectFile, savePath, S, file.txt, Save file, Text Documents (*.txt)
    If (!savePath)
        Return

    content := ""
    for index, value in result
    {
        content .= "[" . index . "]`n" . value . "`n`n"
    }

    If (!content)
        Return

    FileOpen(savePath, "w").Write(content).Close()

    Run % savePath
}

StrReverse(str) {
    static rev := A_IsUnicode ? "_wcsrev" : "_strrev"
    DllCall("msvcrt.dll\" rev, "Ptr", &str, "CDECL")
    return str
}

; 查找一个文件内所有函数的定义, 有可能识别错误
ReadFunctionsInFile(filePath := "")
{
    If (!filePath)
        FileSelectFile, filePath, 3, , 选择文件 ; 1 + 2 文件、路径都必须存在

    if (!FileExist(filePath))
        Return ""

    SplitPath, filePath, , , fileExt
    FileRead, fileContent, %filePath%

    pattern := ""
    pos := 1 ;起始位置

    If (fileExt = "ahk")
        pattern := "((?<=[\n|\r])\s*\w*\s*\([^\n\r()]*\)\s*(?={))"
    Else If (fileExt = "kt")
        pattern := "((?<=fun)[ |<].+?\s*?\([\s|\S]*?\)\s*?(?=[:={]))"
    Else
        Return ""
    ; 识别函数定义的正则
    ; 必须加个括号在外面才能保存
    ; [A-Z] A-Z 任意字符
    ; \w 等效于 [a-zA-Z0-9_]
    ; {xxx}* {xxx} 可以出现若干次 [0, +)
    ; [^\n\r()] 不可以是 : \n, \r, (, ), 除此之外的字符均可
    ; \s 空白符
    ; (?=xxx) 正向预查是否有 'xxx'
    ; (?<=xxx) 反向预查

    Loop
    {
        oldPos := pos
        newPos := RegExMatch(fileContent, pattern, match, pos)

        pos := newPos + StrLen(match1)

        r := Trim(match1, "`n`r ")
        If (r && !CheckInclude_Arr(keywords, MapFuncName(r))) ; 筛除空字串以及关键字(将 r 的函数名与 keywords 遍历比较)
            result .= r . "`n"

        If (oldPos = pos)
            Break ;位置不再变化则终止
    }

    Return result
}

Filter(str, pattern)
{
    RegExMatch(str, pattern, result)
    Return result1
}

MapFuncName(fullStr)
{
    pattern := "(\w*\s*(?=\())"
    Return Trim(Filter(fullStr, pattern), "`n`r ")
}

CheckInclude_Arr(array, hope)
{
    StringLower, hope, hope
    for index, value in array
    {
        StringLower, value, value
        if (value == hope)
            Return true
    }
    Return False
}

ShowSplashText(title, message, timeout := 0)
{
    CloseWin()

    splashWidth := 700

    ; Msg(StrLen(message))

    splashHeight := 300

    SplashTextOn, splashWidth, splashHeight

    splashWidth *= 0.75
    Sleep, 60
    Progress, B ZH0 FM12 WM500 FS15 WS200 W%splashWidth%, `n%message%`n, %title%
    if (timeout)
        SetTimer, CloseAction, -%timeout%
    Return

    CloseAction:
    CloseWin()
    Return ; 必要的
}

Wifi_IsNear(ssid)
{
    Return RunCmd_IsValueExisted("netsh wlan show networks mode=bssid", ssid)
}

Wifi_IsConnected(ssid)
{
    Return Wifi_Current() = ssid
}

Wifi_Current()
{
    result := RunCmd_GetFullResult("netsh wlan show interfaces")
    Return Filter(result, "SSID\s+:\s(.+)") ; "" -> 未连接
}

Wifi_Connect(ssid, notify := False)
{
    msg := RunCmd_GetFullResult("netsh wlan connect name=" . ssid)
    result := InStr(msg, "已", False, 1, 1) > 0
    If (msg && notify)
        ShowSplashText("", msg, 800)

    Return result
}

; 展示结果
Wifi_Disconnect(notify := False)
{
    msg := RunCmd_GetFullResult("netsh wlan disconnect")
    If (notify)
        ShowSplashText("", msg, 800)
}

; 获取 ipv4 地址
GetIPAddress()
{
    str := ""
    objWMIService := ComObjGet("winmgmts:{impersonationLevel = impersonate}!\\.\root\cimv2")
    colItems := objWMIService.ExecQuery("Select * from Win32_NetworkAdapterConfiguration WHERE IPEnabled = True")._NewEnum
    while colItems[objItem]
    {
        Return % objItem.IPAddress[0]
    }
}

; 读取剪贴板
; 或者运行 cmd 命令并通过剪贴板获取结果
GetText_Clipboard(order := "")
{
    result := ""
    previous := ClipboardAll ; backup

    Clipboard := "" ; clear

    If (order) ; using CMD
    {
        RunWait % ComSpec " /c " . order . " | CLIP", , Hide
    }
    Else ; directly copy
    {
        Send, ^c
        ClipWait, 0.3
    }

    result := Clipboard
    Clipboard := previous ; restitute
    Return result
}