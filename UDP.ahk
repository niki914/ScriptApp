#Include %A_ScriptDir%\lib\socket\Socket.ahk
class UDPSocket
{
    __New(port := 0, bindAddr := "0.0.0.0") {
        this.socket := new SocketUDP()
        this.port := port
        this.bindAddr := bindAddr
        this.handlers := {}
    }

    ; 开始监听指定端口
    Listen() {
        try {
            ; 绑定到指定地址和端口
            this.socket.Bind([this.bindAddr, this.port])
            ; 注册接收回调
            this.socket.onRecv := this.OnReceive.Bind(this)
            return true
        } catch e {
            MsgBox % "监听失败: " e.message
            return false
        }
    }

    ; 启用广播
    EnableBroadcast() {
        try {
            this.socket.SetBroadcast(true)
            return true
        } catch e {
            MsgBox % "启用广播失败: " e.message
            return false
        }
    }

    ; 发送数据到指定地址
    SendTo(data, ip, port) {
        try {
            this.socket.SendText(data)
            return true
        } catch e {
            MsgBox % "发送失败: " e.message
            return false
        }
    }

    ; 发送广播
    Broadcast(data, port) {
        try {
            this.EnableBroadcast()
            return this.SendTo(data, "255.255.255.255", port)
        } catch e {
            MsgBox % "广播失败: " e.message
            return false
        }
    }

    ; 注册消息处理函数
    OnMessage(callback) {
        this.handlers.Push(callback)
    }

    ; 接收数据的回调函数
    OnReceive() {
        try {
            data := this.socket.RecvText()
            ; 调用所有注册的处理函数
            for index, handler in this.handlers {
                handler.Call(data)
            }
        } catch e {
            MsgBox % "接收数据失败: " e.message
        }
    }

    ; 关闭连接
    Close() {
        try {
            this.socket.Disconnect()
            return true
        } catch e {
            MsgBox % "关闭失败: " e.message
            return false
        }
    }
}

; 创建服务端（监听）
server := new UDPSocket(5000)  ; 监听5000端口
server.OnMessage(Func("HandleMessage"))  ; 注册消息处理函数
server.Listen()

; 创建客户端（发送）
client := new UDPSocket()
client.SendTo("Hello", "127.0.0.1", 5000)  ; 发送到特定IP
client.Broadcast("Hello Everyone", 5000)    ; 发送广播

; 消息处理函数
HandleMessage(data) {
    MsgBox % "收到数据: " data
}