#Include NetworkActions.ahk
#Include MainFunctions.ahk
#Include AutoBackup.ahk
#Include DllUtils.ahk
#Include ConfigTools.ahk

#Include Libs\Crypt.ahk
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

global configsDefaultJson := "[""configs"",""paths"",""urls""]"
    , fileContents := {}
    , manifest := []
    , password := ""

If (A_Args[1])
{
    password := A_Args[1]
    ConfigsReload(GetConfigPath("configs"), configsDefaultJson, password, fileContents, manifest)
}
Else
{
    ConfigsInit(GetConfigPath("configs"), configsDefaultJson, password, fileContents, manifest)
}

ShowSplashText("", "please wait")

For index, value in manifest
{
    obj := JSON.Load(fileContents[value])
    PraseObject(obj)
}

BuildHotStrings()
BuildRunnables()
BuildCodes()

global vsPAth := POOL_RUNNABLE["vs"]

loginHeadUrl := POOL_STATIC["i1"] . POOL_HOTSTRING["no"] . POOL_STATIC["i2"] . POOL_HOTSTRING["sdcd"] . POOL_STATIC["i3"]
loginTailUrl := POOL_STATIC["i4"]

CloseWin()

; Chrome_Run("https://localhost:47990/")

GDUT_KeepAlive()
Return

; :*:ct\::
;     Action_LoaclTunnel()
; Return

:*:rd\::
    t := ReadFunctionsInFile()
    If (t)
        Clipboard := t
Return

:*:read\::
    ReadFunctionsInFolder()
Return

; 快速输出 ip
:*:ip\::
    SendInput % GetIPAddress()
Return

:*:``12::
    Run, %A_AhkPath% Main.ahk %password%
Return

; 通过 powershell 脚本启动热点
:*:hs\::
    ; 需要设置权限才能运行脚本, 运行结束后还原权限设置
    ; Set-ExecutionPolicy Unrestricted
    ; Set-ExecutionPolicy Restricted
    RunCmd_GetFullResult("powershell.exe -Command Set-ExecutionPolicy Unrestricted")
    ShowSplashText("Hotspot", RunCmd_GetFullResult("powershell.exe -Command D:; cd " . A_ScriptDir . "; .\hotspot.ps1"), 1500)
    RunCmd_GetFullResult("powershell.exe -Command Set-ExecutionPolicy Restricted")
Return

; 断 wifi
:*:dc\::
    Wifi_Disconnect()
Return

; 连校园网
:*:lk\::
    Gdut()
Return

;----以下是快捷键----

^!S:: ; ctrl + shift + s -> bing 搜索选中的文本
    Action_UseBrowser("Search", urls["sc"]) ; sc -> search
Return

^!T::
    Action_UseBrowser("Translate", urls["ts"]) ; ts -> translate
Return
#T::
    Action_Translate()
Return
^!Z::
    Run_OnLocalHost(urls["lh"])
Return

^!W:: ; 发送 alt + F4 慎用
    SendInput !{F4}
Return

; b站的跳过太慢了于是写了这个点击一次相当于点击 4 次
; 只要按住 '/' 再连点左右键即可
~Right & /::
    Loop % 4
    {
        Sleep 10
        SendInput {Right}
    }
Return
~left & /::
    Loop % 4
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

; 在连接了校园网并且网络不可用的时候自动登录
GDUT_KeepAlive()
{
    lastPingTime := A_TickCount
    pingCD := 5 * 1000
    While(True)
    {
        If(A_TickCount - lastPingTime > pingCD)
        {
            If (Ping("https://connectivitycheck.platform.hicloud.com/generate_204", 2) == -1 && Wifi_Current() = "gdut")
                GDUT_TryLogin()
            lastPingTime := A_TickCount ; 更新时间戳
        }

        Sleep, 300
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

; :*:ed\::
;     Run, ConfigEditor.ahk
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