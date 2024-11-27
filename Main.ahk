#Include ALL.ahk

; #Include Lao\Chrome\Chrome.ahk

#NoTrayIcon ; 不显示小图标
#SingleInstance force ; 单例模式

; 加快脚本运行速度的设置
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
DllCall("ntdll\ZwSetTimerResolution", "Int", 5000, "Int", 1, "Int*", MyCurrentTimerResolution) ; setting the Windows Timer Resolution to 0.5ms, THIS IS A GLOBAL CHANGE
; 加快脚本运行速度的设置

;TODO 封装 file 读写、网络请求、json加密存取、消息封装：tooltip、splash、msgbox

global configsDefaultJson := "[""configs"",""You can write anything as a new config file!""]"
    , fileContents := {}
    , manifest := []
    , password := A_Args[1]

If (password) ; 带密码启动
    ConfigsReload(GetConfigPath("configs"), configsDefaultJson, password, fileContents, manifest)
Else
    ConfigsInit(GetConfigPath("configs"), configsDefaultJson, password, fileContents, manifest)

ST_Show("please wait")

For index, value in manifest
{
    obj := JSON.Load(fileContents[value])
    InitPools(obj)
}

BuildHotStrings()
BuildRunnables()
BuildCodes()

global vsPAth := POOL_RUNNABLE.vs
    , studentNumber := POOL_HOTSTRING["no"]
    , studentPassword := POOL_HOTSTRING["pw"]

loginHeadUrl := POOL_STATIC["login1"] . studentNumber . POOL_STATIC["login2"] . studentPassword . POOL_STATIC["login3"]
loginTailUrl := POOL_STATIC["login4"]

ST_Dismiss()
If (studentNumber && studentPassword)
    GDUT_KeepAlive()
Return

; :*:ct\::
;     Action_LoaclTunnel()
; Return

:*:ed\::
    Run, ConfigEditor.ahk
Return

:*:rd\::
    t := GetFuncDescriptionInFile()
    If (t)
        Clipboard := t
Return

:*:read\::
    t := ReadFileDescriptionForFolder()
    If (t)
        Clipboard := t
Return

; 快速输出 ip
:*:ip\::
    SendInput % GetIP()
Return

:*:``12::
    Run, %A_AhkPath% Main.ahk %password%
Return

; 通过 powershell 脚本启动热点
:*:hs\::
    ; 需要设置权限才能运行脚本, 运行结束后还原权限设置
    ; Set-ExecutionPolicy Unrestricted
    ; Set-ExecutionPolicy Restricted
    RunCmd("powershell.exe -Command Set-ExecutionPolicy Unrestricted")
    ST_Show(RunCmd("powershell.exe -Command D:; cd " . A_ScriptDir . "; .\hotspot.ps1"), "", 1500)
    RunCmd("powershell.exe -Command Set-ExecutionPolicy Restricted")
Return

; 断 wifi
:*:dc\::
    DisconnectWifi()
Return

; 连校园网
:*:lk\::
    ST_Show(GDUT(), "gdut", 800)
Return

;----以下是快捷键----

^!S:: ; ctrl + shift + s -> bing 搜索选中的文本
    RunUrl("Search", POOL_STATIC.bingSearch) ; sc -> search
Return

^!T::
    RunUrl("Translate", POOL_STATIC.bingTranslate) ; ts -> translate
Return

#T::
    Translate(POOL_STATIC.bing, POOL_STATIC.deepl)
Return

^!W:: ; 发送 alt + F4 慎用
    SendInput !{F4}
Return

; b站的跳过太慢了于是写了这个点击一次相当于点击 4 次
; 只要按住 '/' 再连点左右键即可
~Right & /::
    Loop 4
    {
        Sleep 10
        SendInput {Right}
    }
Return
~left & /::
    Loop 4
    {
        Sleep 10
        SendInput {left}
    }
Return

; 设置音量 - 同理
~Up & /::
    SoundSet +5
Return
~Down & /::
    SoundSet -5
Return

^`:: ; 编辑 Main.ahk
    Run %vsPAth% %A_ScriptFullPath%
Return

Alt & x:: ; 右键点击事件
    SendInput {AppsKey}
Return

; 相互映射 [代码格式化] 快捷键
#IfWinActive ahk_exe Code.exe
    ^!l::
        Send !+f
    return
#IfWinActive

#IfWinActive ahk_exe studio64.exe
    !+f::
        Send ^!l
    return
    :*:bd\::
        SendInput, Build APK(s)
    Return
#IfWinActive

; 通过剪贴板获取鼠标选取的文本
GetSelectedText()
{

    ClipSaved := ClipboardAll ; 把剪贴板的所有内容 (任何格式)

    Clipboard := "" ; 清除

    Send, ^c
    ClipWait, 0.3

    clip := Clipboard
    Clipboard := ClipSaved ; 使用 Clipboard (不是 ClipboardAll)

    Return clip
}

; 等待按下键盘的一个按键并返回它的名字, 不保证全部按键的捕捉
WaitForKey()
{
    ; L1 指识别一个键击
    Input, key, L1, {Space}{Enter}{Tab}{BackSpace}{LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}{AppsKey}{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}{Left}{Right}{Up}{Down}{Home}{End}{PgUp}{PgDn}{Del}{Ins}{BS}{Capslock}{Numlock}{PrintScreen}{Pause}

    ; 上面一堆键名是额外的暂停符号, 会被捕捉至 error level, 最后再用正则解析出来
    If (!key && ErrorLevel)
        key := FilterText(ErrorLevel, "((?<=:).*$)")
    Return key
}

; bing & deepl 翻译, 将鼠标选中的文字翻译, 中英互译
Translate(bingKey := "", deeplKey := "")
{
    text := GetSelectedText()
    text := ParseCamelText(text)
    isCN := IsCN(text)
    result := "no response `;("
    hasResult := False

    if (RegExReplace(text, "\s") == "")
        Return

    If (bingKey && !hasResult)
    {
        from := isCN ? "zh-CN": "en"
        to := !isCN ? "zh-CN" : "en"
        bing := Bing(text, bingKey, from, to)
        If (bing.text)
        {
            hasResult := True
            result := bing.text
        }
    }

    If (deeplKey && !hasResult)
    {
        from := isCN ? "ZH": "EN"
        to := !isCN ? "ZH-HANS" : "EN-US"
        deepl := DeepL(text, deeplKey, from, to)
        If (deepl.text)
        {
            hasResult := True
            result := deepl.text
        }
    }
    If (!hasResult)
    {
        MB("翻译失败, 请检查密钥或网络")
        Return
    }

    ST_Show(result, "press 'c' to copy")

    key := WaitForKey()
    if (key == "c" || key == "C")
        Clipboard := result

    ST_Dismiss()
}

; 尝试通过剪贴板生成一个 api 并访问
; 当前实现直接搜索和翻译
RunUrl(title, url)
{
    content := GetSelectedText()
    if ( RegExReplace(content, "\s") == "")
    {
        InputBox content, %title%, What To %title%?, , 330, 130
        if (content == "")
            Return
    }
    Run %url%%content% ; 'https://xxx.com?q=' + 'content'
}

; 映射 sendInput
SendString(str)
{
    SendInput % str
}

; 运行并通过 splash text 反馈
RunWithSplashText(path)
{
    Try
    {
        Run % path
        ST_Show("✔", "", 800)
    }
    Catch
    {
        ST_Show("✖", "", 800)
    }
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
RunLocalHost(url)
{
    content := GetSelectedText()
    if (ErrorLevel || RegExReplace(content, "\s") == "")
        Return
    ; 检查起始字符是否为 '/'
    if (SubStr(content, 1, 1) != "/")
        content := "/" . content
    Run %url%%content%
}

RunFolder(funcInstance, path := "")
{
    func := Func(funcInstance)
    if (!IsFunc(func))
        return {}

    if (!path || !FileExist(path))
    {
        FileSelectFolder, path,, 3, 选择一个文件夹
        if (!path) ; 取消
            return {}
    }

    result := {}
    RunFuncForDirectory(path, func, result)
    return result
}

RunFuncForDirectory(path, funcInstance, ByRef result)
{
    Loop, %path%\*.*, 0, 1
    {
        If (A_LoopFileIsDir)
            RunFuncForDirectory(A_LoopFileLongPath, funcInstance, result) ; 递归子目录
        Else
        {
            Try
            {
                if (r := %funcInstance%(A_LoopFileFullPath))
                    result[A_LoopFileLongPath] := r
            }
            Catch
            {
                Return
            }
        }
    }
}

; ; 以下为弃用热字符串(已集成至 json 配置文件内)

; :*:wlan\::
;     Run % ComSpec " /c ncpa.cpl", , Hide
; Return

; ; 快速启动网易云 localhost
; :*:wyy\::
;     Run %ComSpec% /c npx NeteaseCloudMusicApi, , Minimize
; Return

; ; 脚本目录
; :*:app\::
;     Run % A_ScriptDir
; Return

; :*:ex\::
; ExitApp

; 本机高级系统属性
; :*:se\::
;     Run sysdm.cpl
; Return

; ; 重启资源管理器
; :*:rf\::
;     RunWait %ComSpec% /c taskkill /f /im explorer.exe & start explorer.exe, , Hide
; Return

; ; 使本机睡眠
; :*:sl\::
;     DllCall("PowrProf\SetSuspendState", "int", 0, "int", 0, "int", 0)
; Return