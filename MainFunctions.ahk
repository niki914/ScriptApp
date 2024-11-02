global keywords := ["for", "if", "loop", "else", "else if", "while", "switch", "try", "catch", "when"]

Action_Translate()
{
    rawText := GetText_Clipboard()
    str := ParseCamel(rawText)

    if (ErrorLevel || RegExReplace(str, "\s") == "")
    {
        Return
    }
    else
    {
        str := BingTranslate(str)
        ShowSplashText("press C to copy", str)

        Input, key, L1, {Tab}{BackSpace}{LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}{AppsKey}{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}{Left}{Right}{Up}{Down}{Home}{End}{PgUp}{PgDn}{Del}{Ins}{BS}{Capslock}{Numlock}{PrintScreen}{Pause}
        if (key = "c")
            Clipboard := str

        CloseWin()
    }
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

BuildHotstrings_Send(values)
{
    BuildHotstrings(values, "Send_Arr")
}

BuildHotStrings_Run(values)
{
    BuildHotstrings(values, "Run_Arr")
}

; 为一个数组的所有值创建为调用 funcName 热字符串
BuildHotstrings(values, funcName)
{
    for key in values
        BuildHotstring(funcName, values, key)
}

; 动态创建热字符串
; 主要为了配置文件中的键值而设计
BuildHotstring(funcName, values, key)
{
    if(key = "default")
        Return

    hotstring := ":*:" key "\"
    Hotstring(hotstring, Func(funcName).Bind(values, key))
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

Ping(host)
{
    Return RunCmd_IsValueExisted("ping -n 1 -w 1000 " . host, "(0%") ; '(0% 丢失)'
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

; fast msgbox
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

; 运行数组的一个值并通过 splash text 反馈
Run_Arr(array, key)
{
    Run_ShowingSplashText(array[key])
}

; 运行并通过 splash text 反馈
Run_ShowingSplashText(path)
{
    Run % path
    ShowSplashText("", "√", 800)
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

; 发送数组中的一个值
Send_Arr(array, key)
{
    SendInput % array[key]
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
        ClipWait 2
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