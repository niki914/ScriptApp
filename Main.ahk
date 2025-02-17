#Include %A_ScriptDir%\ALL.ahk
global EditorPath := A_ScriptDir . "\ConfigEditor.ahk"

#Hotstring EndChars \

; #NoTrayIcon ; 不显示小图标
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
Thread, Interrupt, 0
; 加快脚本运行速度的设置

RunThisAsAdmin()

global fileContents := {}
    , manifest := []
    , password := A_Args[1]

    ; , lastReloadTime := A_Args[2]
    , lastReloadTime := A_TickCount ; 不启用密码过期功能

ReadConfigsToScript(password, fileContents, manifest, lastReloadTime)

adminType := A_IsAdmin ? "(admin)" : ""
FT_Show("hello! " . A_UserName . " " . adminType, 1500)

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

OnMessage(0x11, "OnSystemLogoff")

If (studentNumber && studentPassword)
    GDUT_KeepAlive()

RunAhk(A_ScriptDir . "\ADB-UDP.ahk")

Return

; 当系统关机, 注销或休眠, 实测是有回调的, 但是无法阻止这个进程 (网上的文章是可以的, 原因未知)
OnSystemLogoff(wParam, lParam)
{
    ; ENDSESSION_LOGOFF := 0x80000000
    ; LOGGer_PATH := A_Desktop . "\ahk_temp" . A_TickCount . ".txt"

    ; if (lParam & ENDSESSION_LOGOFF)
    ;     msg := "`n注销: " . A_Now
    ; else ; 系统正在关机或重启.
    ;     msg := "`n关机: " . A_Now

    ; WriteStringToFile(LOGGer_PATH, msg)
    Return True
}

; ::ct::
;     Action_LoaclTunnel()
; Return

; ::shut::
;     WinShutDown()
; Return

::adb::
    RunAhk(A_ScriptDir . "\ADB-UDP.ahk")
Return

::pg::
    ST_Show(Ping("https://connectivitycheck.platform.hicloud.com/generate_204", 3), "PING", 800)
Return

::usb::
    RunWithSplashText("F:\")
Return

::md::
    name := IB("为 Markdown 文件命名:")
    If (name == "")
        Return
    mdPath := A_Desktop . "\" . name . ".md"
    GetEmptyFile(mdPath).Close()
    RunWithSplashText(mdPath)
Return
::lh::
    RunPenetration("1234")
Return

::sl::
    WinSleep()
Return

::cy::
    Run, %A_ScriptDir%\Crypter.ahk
Return

::ed::
    RunAhk(EditorPath, password . " " . lastReloadTime)
Return

::ex::
ExitApp

::rd::
    t := GetFuncDescriptionInFile()
    If (t)
        Clipboard := t
Return

::read::
    t := ReadFileDescriptionForFolder()
    If (t)
        Clipboard := t
Return

; 快速输出 ip
::ip::
    SendInput % GetIP()
Return

:*:``12::
:*:21``::
    RunAhk(A_ScriptFullPath, password . " " . lastReloadTime)
Return
; 通过 powershell 脚本启动热点
::hs::
    ; 需要设置权限才能运行脚本, 运行结束后还原权限设置
    ; Set-ExecutionPolicy Unrestricted
    ; Set-ExecutionPolicy Restricted
    RunCmd("powershell.exe -Command Set-ExecutionPolicy Unrestricted")
    ST_Show(RunCmd("powershell.exe -Command D:; cd " . A_ScriptDir . "\lib\my_shell" . "; .\hotspot.ps1", 2), "", 1000)
    RunCmd("powershell.exe -Command Set-ExecutionPolicy Restricted")
Return

; 断 wifi
::dc::
    DisconnectWifi()
Return

; 连校园网
::lk::
    ST_Show(GDUT(), "gdut", 800)
Return

;----以下是快捷键----

!d::
    ClipSaved := ClipboardAll
    Clipboard := ""

    Send ^c
    ClipWait, 0.3
    if ErrorLevel
    {
        MB("复制失败")
        Clipboard := ClipSaved
        Return
    }

    cliped := Clipboard
    Clipboard := ClipSaved

    paths := []

    ; 解析剪贴板内容，支持多行（多个文件）
    Loop, Parse, cliped, `n, `r
    {
        if A_LoopField  ; 如果行不为空
            paths.Push(A_LoopField)
    }

    CreateShortcuts(paths)
Return

^!F::
    t := GetSelectedText()
    If (t == "")
        t := IB("What To Search?", "Everything")
    MB(EQuery(t))
Return

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
    If (!FileExist(vsPAth) || !FileExist(A_ScriptDir))
        Return
    Run %vsPAth% %A_ScriptDir%
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
    Return
    ::bd::
        SendInput, Build APK(s)
    Return
#IfWinActive

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; OnSystemLogoff(wParam, lParam)
; GetSelectedText()
; WaitForKey()
; Translate(bingKey := "", deeplKey := "")
; RunUrl(title, url)
; SendString(str)
; RunWithSplashText(path)
; RunWaitString(command)
; RunLocalHost(url)
; RunPenetration(port := "3000")

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
        FT_Show("翻译失败, 请检查密钥或网络", 2000)
        ; MB("翻译失败, 请检查密钥或网络")
        Return
    }

    FT_Show(result)
    ; ST_Show(result, "press 'c' to copy")

    key := WaitForKey()
    if (key == "c" || key == "C")
        Clipboard := result

    FT_Dismiss()
    ; ST_Dismiss()
}

; 尝试通过剪贴板生成一个 api 并访问
; 当前实现直接搜索和翻译
RunUrl(title, url)
{
    content := GetSelectedText()
    if (RegExReplace(content, "\s") == "")
    {
        content := IB("What To " . title "?", title)
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
        child := FindLastChild(path)
        re := EQuery(child)
        If (re)
        {
            Clipboard := re
            MB("找到了: " . re . " , 已复制到剪贴板")
            RunAhk(EditorPath, password . " " . lastReloadTime)
        }
        Else
            MB("在此计算机上找不到: " . path)
    }
}

RunWaitString(command)
{
    head :="
    (
        #NoTrayIcon
        #SingleInstance force
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
    )"
    tail := "`nExitApp"
    order := head . "`n" . command . tail
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

RunPenetration(port := "3000")
{
    timeout_RP := 20 * 1000 ; 20s 的超时
    order := "ssh -R 80:localhost:" . port . " localhost.run"

    Run cmd.exe

    Sleep, 1000
    SendInput % order
    SendInput, {Enter}
    SendInput, {Enter}

    SetTitleMatchMode, 2
    IfWinExist, cmd.exe
    {
        BlockInput, On
        WinMaximize
    }
    Else
    {
        Return ""
    }

    Sleep, 500
    WinGetPos, X, Y, Width, Height, A

    StartX := (X + Width) * 0.8
    StartY := (Y + Height) * 0.8
    EndX := X
    EndY := Y

    startTime_RP := A_TickCount
    ; 模拟人选中的动作直到选中的内容包含内网穿透的地址
    While 1
    {
        SetDefaultMouseSpeed, 0
        Click, %StartX%, %StartY%, Down ; 按下鼠标左键
        SetDefaultMouseSpeed, 20
        Click, %EndX%, %EndY%, Up ; 释放鼠标

        result := ""
        previous := ClipboardAll ; backup

        Clipboard := ""
        SendInput, ^c
        ClipWait, 0.5

        result := Clipboard
        result := Trim(result, "`n`r ")
        result := FilterText(result, "(http.+?.life)")

        Clipboard := previous ; restitute

        If (result)
        {
            Clipboard := result
            Break
        }
        If (A_TickCount - startTime_RP >= timeout_RP)
            Break

        Sleep, 500
    }

    WinMinimize
    BlockInput, Off

    Return result
}

; ; 以下为弃用热字符串(已集成至 json 配置文件内)

; ::wlan::
;     Run % ComSpec " /c ncpa.cpl", , Hide
; Return

; ; 快速启动网易云 localhost
; ::wyy::
;     Run %ComSpec% /c npx NeteaseCloudMusicApi, , Minimize
; Return

; ; 脚本目录
; ::app::
;     Run % A_ScriptDir
; Return

; ::ex::
; ExitApp

; 本机高级系统属性
; ::se::
;     Run sysdm.cpl
; Return

; ; 重启资源管理器
; ::rf::
;     RunWait %ComSpec% /c taskkill /f /im explorer.exe & start explorer.exe, , Hide
; Return

; ; 使本机睡眠
; ::sl::
;     DllCall("PowrProf\SetSuspendState", "int", 0, "int", 0, "int", 0)
; Return