#Include %A_ScriptDir%\lib\socket\Socket.ahk
#Include %A_ScriptDir%\lib\message\Message.ahk
#Include %A_ScriptDir%\System.ahk

#Persistent
#SingleInstance, force
; #NoTrayIcon ; 不显示小图标

RunThisAsAdmin()

try
{
    global RECEIVER_PORT := 44455

    ; 建立接收对象
    global myUdpIn := New SocketUDP()  ; 创建一个新的 udp 对象 "myUdpIn"

    myUdpIn.bind(["0.0.0.0", RECEIVER_PORT])  ; "addr_any"为接收所有IP，也可接受指定IP推送
    myUdpIn.onRecv := Func("RecvCallback")  ; 对传入消息执行回调 "RecvCallback"。

    FT_Show("hello! Adb service", 1500)

    RecvCallback(this)
    {
        receivedText := this.RecvText()
        FT_Show(receivedText, 3000)
        ; hello${ipv4}
        androidIp := FilterText(receivedText, "^hello(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})$")
        If (androidIp)
        {
            adbResult := RunCmd("adb connect " . androidIp . ":" . "5555", 20)
            FT_Show(adbResult, 3000)
        }
        Else
        {
            FT_Show("来自" . RECEIVER_PORT . "端口的未知请求: " . receivedText, 3000)
        }
    }
}
Catch
{
    ExitApp
}
