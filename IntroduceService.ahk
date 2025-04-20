#Include %A_ScriptDir%\lib\socket\Socket.ahk
#Include %A_ScriptDir%\lib\message\Message.ahk
#Include %A_ScriptDir%\System.ahk
#Include %A_ScriptDir%\Net.ahk

#Persistent
#SingleInstance, force
; #NoTrayIcon ; 不显示小图标

RunThisAsAdmin()

try
{
    global SEND_PORT :=4444
        , RECEIVER_PORT := 44444

    ; 建立接收对象
    global myUdpIn := New SocketUDP()  ; 创建一个新的 udp 对象 "myUdpIn"
    myUdpIn.bind(["0.0.0.0", RECEIVER_PORT])  ; "addr_any"为接收所有IP，也可接受指定IP推送
    myUdpIn.onRecv := Func("RecvCallback")  ; 对传入消息执行回调 "RecvCallback"。

    ; 建立发送对象
    global myUdpOut := New SocketUDP()  ; 创建一个新的 udp 对象 "myUdpOut"
    myUdpOut.Connect(["255.255.255.255", SEND_PORT])  ; "addr_broadcast"为整个局域网发送广播，也可指定IP发送【支持动态域名】
    myUdpOut.EnableBroadcast() ; 开启广播消息

    FT_Show("hello! Introduce service", 1500)

    ; SetTimer, INTRODUCE, 30000 ; 接近 60 hz
    ; INTRODUCE:
    ;     myUdpOut.SendText(SocketResponseText())
    ; Return

    RecvCallback(this)
    {
        receivedText := this.RecvText()

        ; hello${ipv4}:${port}
        addr := FilterText(receivedText, "^hello(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d{1,5})$")
        If (addr) {
            parts := StrSplit(addr, ":")
            ip := parts[1]
            port := parts[2]

            FT_Show("hello! " . ip . ": " . port, 2000)

            tcpSock := new SocketTCP()

            target := [ip, port]
            if (tcpSock.Connect(target)){
                tcpSock.SendText(SocketResponseText())
                tcpSock.Disconnect()
            }
        }else{
            FT_Show("来自" . RECEIVER_PORT . "端口的未知请求: " . receivedText, 3000)
        }
    }

    SocketResponseText(){
        message := "hello! " . A_ComputerName . " " . GetIP("10")["以太网"]
        Return message
    }
}
Catch
{
    ExitApp
}