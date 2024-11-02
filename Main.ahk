#Include DudeDealer.ahk
#Include NetworkActions.ahk
#Include MainFunctions.ahk
#Include AutoBackup.ahk
#Include DllUtils.ahk

#Include Libs\Crypt.ahk

#NoTrayIcon ; 不显示小图标

#SingleInstance force ; 单例模式

global dudesPath := A_AppData . "\WannaTakeThisDownTown" ; 配置文件的路径
global password := PasswordInput() ; 要求输入密码
; global password :=  ; 要求输入密码

ShowSplashText("", "please wait")

if !FileExist(dudesPath)
    FileCreateDir, %dudesPath%

Sleep 300

global configs := FullDudeReader(dudesPath . "\configs.dude","")
global apps := FullDudeReader(dudesPath . "\apps.dude","")
global privacies := FullDudeReader(dudesPath . "\privacies.dude", password)
global paths := FullDudeReader(dudesPath . "\paths.dude", password)
global urls := FullDudeReader(dudesPath . "\urls.dude", password)
global nameless := FullDudeReader(dudesPath . "\nameless.dude", "")

global vsPAth := paths["vs"]

global loginHeadUrl := urls["i1"] . privacies["no"] . urls["i2"] . privacies["sdcd"] . urls["i3"]
global loginTailUrl := urls["i4"]
global logoutHeadUrl := urls["o1"]
global logoutTailUrl := urls["o2"]

; class Person {
; static defaultAge := 18  ; 静态属性

; name := ""  ; 实例属性
; age := 0

; __New(name, age := "") {
; 构造函数
; this.name := name
; if (age != "") {
; this.age := age
;     } else {
;         this.age := Person.defaultAge  ; 访问静态属性
;     }
; }

; sayHello() {
;     ; 实例方法
;     MsgBox % "Hello, my name is " this.name " and I'm " this.age " years old."
; }
; }

; p1 := new Person("John", 25)
; p2 := new Person("Jane")

; 调用方法
; p1.sayHello()
; p2.sayHello()

if(ObjCount(privacies) != 1)
{
    BuildHotstrings_Send(privacies)
    BuildHotStrings_Run(paths)
    BuildHotStrings_Run(urls)
}
CloseWin()

Menu_Put(".ahk", "查询", "shell", "scan")
; Menu_Put(".ahk", "查询", "shell", A_AhkPath . " " . A_ScriptDir . "\test.ahk"" ""show"" ""%1""")

GDUT_KeepAlive()
Return

; 在连接了校园网并且网络不可用的时候自动登录
GDUT_KeepAlive()
{
    While(True)
    {
        If (!Ping("bing.com"))
        {
            If (Wifi_Current() = "gdut")
                GDUT_TryLogin(False)
        }
        Sleep, 5000
    }
}

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

; 快速启动网易云 localhost
:*:wyy\::
    Run %ComSpec% /c npx NeteaseCloudMusicApi, , Minimize
Return

; 脚本目录
:*:app\::
    Run % A_ScriptDir
Return

:*:``12::
    Reload
Return

; 手动备份
:*:bu\::
    BackUp()
Return

:*:ed\::
    UpdateData(configs, password)
Return

:*:dd\::
    Run % dudesPath
Return

:*:cg\::
    password := ChangePassword(password)
Return

:*:ex\::
ExitApp

; 本机高级系统属性
:*:se\::
    Run sysdm.cpl
Return

; 重启资源管理器
:*:rf\::
    RunWait %ComSpec% /c taskkill /f /im explorer.exe & start explorer.exe, , Hide
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

; 使本机睡眠
:*:sl\::
    DllCall("PowrProf\SetSuspendState", "int", 0, "int", 0, "int", 0)
Return

; 断 wifi
:*:dc\::
    Wifi_Disconnect()
Return

; 连校园网
:*:lk\::
    Gdut()
Return

; 快速在后台启动 shizuku
:*:szk\::
    RunWait %ComSpec% /c adb devices, , Hide
    RunWait %ComSpec% /c adb shell sh /storage/emulated/0/Android/data/moe.shizuku.privileged.api/start.sh, , Hide
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

^1:: ; 编辑所有的 ahk 脚本
    Loop % apps.MaxIndex()
    {
        a := A_ScriptDir "/" apps[A_Index]
        Run %vsPAth% %a%
    }
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
#IfWinActive