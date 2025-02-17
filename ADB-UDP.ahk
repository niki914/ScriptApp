#Include %A_ScriptDir%\lib\socket\Socket.ahk
#Include %A_ScriptDir%\lib\message\Message.ahk
#Include %A_ScriptDir%\System.ahk

#Persistent
#SingleInstance, force
#NoTrayIcon ; 不显示小图标

global RECEIVER_PORT := 55555
    , ADB_DEVICE_PORT := 5555

; 建立接收对象
global myUdpIn := New SocketUDP()  ; 创建一个新的 udp 对象 "myUdpIn"

myUdpIn.bind(["addr_any", RECEIVER_PORT])  ; "addr_any"为接收所有IP，也可接受指定IP推送
myUdpIn.onRecv := Func("RecvCallback")  ; 对传入消息执行回调 "RecvCallback"。

; 建立发送对象
global myUdpOut := New SocketUDP()  ; 创建一个新的 udp 对象 "myUdpOut"
myUdpOut.Connect(["addr_broadcast", RECEIVER_PORT])  ; "addr_broadcast"为整个局域网发送广播，也可指定IP发送【支持动态域名】
myUdpOut.EnableBroadcast() ; 开启广播消息

RecvCallback(this)
{
    receivedText := this.RecvText()
    ; hello${ipv4}
    androidIp := FilterText(receivedText, "^hello(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})$")
    If (androidIp)
    {
        adbResult := RunCmd("adb connect " . androidIp . ":" . ADB_DEVICE_PORT, 20)
        FT_Show(adbResult, 3000)
    }
    Else
    {
        FT_Show("来自" . RECEIVER_PORT . "端口的未知请求: " . receivedText, 3000)
    }

    ;     ; 发送回复消息
    ;     replyMsg := "hi" . localIP
    ;     myUdpOut.SendText(replyMsg)
}