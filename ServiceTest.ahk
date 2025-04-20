#Include %A_ScriptDir%\lib\socket\Socket.ahk
#Include %A_ScriptDir%\lib\message\Message.ahk
#Include %A_ScriptDir%\System.ahk

#SingleInstance, force
; #NoTrayIcon ; 不显示小图标

global ADB_PORT := 55555
global INTRO_PORT := 44444

; 建立接收对象
global adb := New SocketUDP() 
global intro := New SocketUDP()  

adb.bind(["255.255.255.255", ADB_PORT])  ; "addr_any"为接收所有IP，也可接受指定IP推送
intro.bind(["255.255.255.255", INTRO_PORT])  ; "addr_any"为接收所有IP，也可接受指定IP推送

FT_Show("hello! Service Test", 1500)

Sleep, 1500
adb.send("hello, adb!")
Sleep, 5000
intro.send("hello, intro!")
ExitApp