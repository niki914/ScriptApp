; Modified from: https://www.autohotkey.com/boards/viewtopic.php?f=6&t=35120
class Socket {
	static WM_SOCKET := 0x9987, MSG_PEEK := 2
	static FD_READ := 1, FD_ACCEPT := 8, FD_CLOSE := 32
	static Blocking := True, BlockSleep := 20, AsyncBlockSleep := 40

	__New(Socket:=-1) {
		static Init
		if !Init {
			DllCall("LoadLibrary", "Str", "Ws2_32", "Ptr")
			, VarSetCapacity(WSAData, 394+A_PtrSize)
			if (Error := DllCall("Ws2_32\WSAStartup", "UShort", 0x0202, "Ptr", &WSAData))
				throw Exception("Error starting Winsock",, Error)
			if (NumGet(WSAData, 2, "UShort") != 0x0202)
				throw Exception("Winsock version 2.2 not available")
			Init := True
		}
		this.Socket := Socket
	}

	__Delete() {
		if (this.Socket != -1)
			this.Disconnect()
	}

	Connect(Address) {
		if (this.Socket != -1)
			return -1
		Next := pAddrInfo := this.GetAddrInfo(Address)
		While Next {
			ai_addrlen := NumGet(Next+0, 16, "UPtr")
			, ai_addr := NumGet(Next+0, 16+(2*A_PtrSize), "Ptr")
			if ((this.Socket := DllCall("Ws2_32\socket", "int", NumGet(Next+0, 4, "int"), "int", this.SocketType, "int", this.ProtocolId, "Uint")) != -1) {
				if (DllCall("Ws2_32\WSAConnect", "Uint", this.Socket, "Ptr", ai_addr, "Uint", ai_addrlen, "Ptr", 0, "Ptr", 0, "Ptr", 0, "Ptr", 0, "int") == 0) {
					DllCall("Ws2_32\freeaddrinfo", "Ptr", pAddrInfo)  ; TODO: Error Handling
					return this.EventProcRegister(this.FD_READ | this.FD_CLOSE)
				}
				this.Disconnect()
			}
			Next := NumGet(Next+0, 16+(3*A_PtrSize), "Ptr")
		}
		return 0
	}

	Bind(Address) {
		if (this.Socket != -1)
			return 0
		Next := pAddrInfo := this.GetAddrInfo(Address)
		While Next {
			ai_addrlen := NumGet(Next+0, 16, "UPtr")
			, ai_addr := NumGet(Next+0, 16+(2*A_PtrSize), "Ptr")
			if ((this.Socket := DllCall("Ws2_32\socket", "int", NumGet(Next+0, 4, "int"), "int", this.SocketType, "int", this.ProtocolId, "Uint")) != -1) {
				if (DllCall("Ws2_32\bind", "Uint", this.Socket, "Ptr", ai_addr, "Uint", ai_addrlen, "int") == 0) {
					DllCall("Ws2_32\freeaddrinfo", "Ptr", pAddrInfo)  ; TODO: ERROR HANDLING
					return this.EventProcRegister(this.FD_READ | this.FD_ACCEPT | this.FD_CLOSE)
				}
				this.Disconnect()
			}
			Next := NumGet(Next+0, 16+(3*A_PtrSize), "Ptr")
		}
		throw Exception("Error binding")
	}

	Listen(backlog=32) {
		return DllCall("Ws2_32\listen", "Uint", this.Socket, "int", backlog) == 0
	}

	Accept() {
		if ((s := DllCall("Ws2_32\accept", "Uint", this.Socket, "Ptr", 0, "Ptr", 0, "Ptr")) == -1)
			throw Exception("Error calling accept",, this.GetLastError())
		Sock := new Socket(s)
		, Sock.ProtocolId := this.ProtocolId
		, Sock.SocketType := this.SocketType
		, Sock.EventProcRegister(this.FD_READ | this.FD_CLOSE)
		return Sock
	}

	Disconnect() {
		; Return 0 if not connected
		if (this.Socket == -1)
			return 0

		; Unregister the socket event handler and close the socket
		this.EventProcUnregister()
		if (DllCall("Ws2_32\closesocket", "Uint", this.Socket, "int") == -1)
			throw Exception("Error closing socket",, this.GetLastError())
		this.Socket := -1
		return 1
	}

	MsgSize() {
		static FIONREAD := 0x4004667F
		if (DllCall("Ws2_32\ioctlsocket", "Uint", this.Socket, "Uint", FIONREAD, "UInt*", argp) == -1)
			throw Exception("Error calling ioctlsocket",, this.GetLastError())
		return argp
	}

	Send(pBuffer, BufSize, Flags:=0) {
		if ((r := DllCall("Ws2_32\send", "Uint", this.Socket, "Ptr", pBuffer, "int", BufSize, "int", Flags)) == -1)
			return 0
		return r
	}

	SendText(Text, Encoding:="UTF-8") {
		VarSetCapacity(Buffer, StrPut(Text, Encoding) * ((Encoding="UTF-16"||Encoding="CP1200") ? 2 : 1))
		return this.Send(&Buffer, StrPut(Text, &Buffer, Encoding) - 1)
	}

	SendHex(Hex*) {
		VarSetCapacity(binary, Hex.Length(), 0)
		Loop % Hex.Length()
			NumPut(Hex[A_Index], binary, A_Index-1, "UChar")
		return this.Send(&binary, Hex.Length())
	}

	Recv(ByRef Buffer, BufSize:=0, Flags:=0, AsyncLabel:="") {
		if (AsyncLabel="") {
			While (!(Length := this.MsgSize()) && this.Blocking)
				Sleep, this.BlockSleep
		 } else {
			__AsyncEmpty := ObjBindMethod(this, "Recv", Buffer, BufSize, Flags, AsyncLabel)
			if (!(Length := this.MsgSize()) && this.Blocking) {
				this.AsyncWait := 1
				SetTimer %__AsyncEmpty%, % "-" this.AsyncBlockSleep
				Return
			 } else {
				SetTimer %__AsyncEmpty%, Delete
				this.AsyncWait := 0
			}
		}

		if !Length
			return 0

		if !BufSize
			BufSize := Length
		VarSetCapacity(Buffer, BufSize)
		, VarSetCapacity(from, 16, 0)
		, r := DllCall("ws2_32\recvfrom", "Ptr", this.Socket, "Ptr", &Buffer, "int", BufSize, "int", 0, "Ptr", &from, "Int*", 16)
		, this.Port := DllCall("ws2_32\htons", "UShort", NumGet(from, 2, "UShort"), "UShort")
		, this.IPfrom := DllCall("ws2_32\inet_ntoa", "Uint", NumGet(from, 4, "Uint"), "AStr")

		if (r <= 0)
			return 0

		this.AsyncRecvBuf := Buffer

		if IsLabel(AsyncLabel)
			SetTimer %AsyncLabel%, -1

		return this.AsyncRecvLength := r
	}

	GetRecvIPfrom() {
		return this.IPfrom
	}

	GetRecvPort() {
		return this.Port
	}

	AsyncRecv(AsyncLabel:="") {
		if !this.AsyncWait
			this.Recv(Buffer, 0, 0, AsyncLabel)
	}

	AsyncText(Encoding:="UTF-8") {
		Buffer := this.AsyncRecvBuf
		return StrGet(&Buffer, this.AsyncRecvLength, Encoding)
	}

	AsyncBuf() {
		return this.AsyncRecvBuf
	}

	AsyncLength() {
		return this.AsyncRecvLength
	}

	AsyncEmpty() {
		this.AsyncRecvLength := this.AsyncRecvBuf := ""
	}

	RecvText(BufSize:=0, Flags:=0, Encoding:="UTF-8") {
		if (Length := this.Recv(Buffer, BufSize, flags))
			return StrGet(&Buffer, Length, Encoding)
		return
	}

	RecvHex() {
		if (bytes := this.Recv(addr)) {
			DllCall("crypt32\CryptBinaryToStringW", "Ptr", &addr, "Uint", bytes, "Uint", 0x40000004, "Ptr", 0, "Uint*", chars)
			, VarSetCapacity(hex, chars * 2)
			, DllCall("crypt32\CryptBinaryToStringW", "Ptr", &addr, "Uint", bytes, "Uint", 0x40000004, "Str", hex, "Uint*", chars)
			return Format("{:U}", hex)
		}
	}

	; https://www.autohotkey.com/boards/viewtopic.php?p=28453
	; "package_size"可增加到 4096KB。尽管 8192KB 理论上是可能的，但随后会发生错误。
	SendFilePackages(filepath, package_size := 8192) {
		file := FileOpen(filepath, "r")
		, VarSetCapacity(buf, file.length)
		, file.RawRead(&buf, file.length)
		Stringsplit, filepath, filepath, \
		filename := filepath%filepath0%  ; Dateiname Rausfiltern
		, len := file.length
		, pos := &buf
		, this.SendText(filename ":" len ":" package_size)  ; Header
		, this.RecvText() 

		While (len > 0)
			current_len := (len>=package_size) ? package_size : len
			, this.Send(pos, current_len)
			, len -= current_len  
			, pos += current_len
			, this.RecvText()

		file.close()
	}

	RecvFilePackages(filepath:="") {
		Header := this.RecvText()
		, Header := StrSplit(Header, ":")
		, num_packages := Ceil(Header[2] / Header[3])  ; Anzahl der Packete aufgerundet 

		if (filepath="") {
			if FileExist(A_ScriptDir "\" Header[1])
				filepath := A_ScriptDir "\Bak-" Header[1]
			 else
				filepath := A_ScriptDir "\" Header[1]
		} else
			filepath := RTrim(filepath, "\") "\" Header[1]

		file := FileOpen(filepath, "w") 
		, this.SendText("#")

		Loop %num_packages% {
			len := this.Recv(Buffer)
			, file.RawWrite(&Buffer, len)
			if (A_Index = num_packages)
				file.close()
			this.SendText("#")
		}
	}

	RecvLine(BufSize:=0, Flags:=0, Encoding:="UTF-8", KeepEnd:=False) {
		While !(i := InStr(this.RecvText(BufSize, Flags|this.MSG_PEEK, Encoding), "`n")) {
			if !this.Blocking
				return
			Sleep, this.BlockSleep
		}
		if KeepEnd
			return this.RecvText(i, Flags, Encoding)
		 else
			return RTrim(this.RecvText(i, Flags, Encoding), "`r`n")
	}

	GetAddrInfo(Address) {
		Host := Address[1], Port := Address[2]
		VarSetCapacity(Hints, 16+(4*A_PtrSize), 0)
		, NumPut(this.SocketType, Hints, 8, "int")
		, NumPut(this.ProtocolId, Hints, 12, "int")
		if (Error := DllCall("Ws2_32\getaddrinfo", "AStr", Host, "AStr", Port, "Ptr", &Hints, "Ptr*", Result))
			throw Exception("Error calling GetAddrInfo",, Error)
		return Result
	}

	OnMessage(wParam, lParam, Msg, hWnd) {
		Critical
		if (Msg != this.WM_SOCKET || wParam != this.Socket)
			return
		if (lParam & this.FD_READ)
			this.onRecv()
		 else if (lParam & this.FD_ACCEPT)
			this.onAccept()
		 else if (lParam & this.FD_CLOSE)
			this.EventProcUnregister(), this.OnDisconnect()
	}

	EventProcRegister(lEvent) {
		Rtn := this.AsyncSelect(lEvent)
		if !this.Bound
			this.Bound := this.OnMessage.Bind(this)
			, OnMessage(this.WM_SOCKET, this.Bound)
		Return Rtn
	}

	EventProcUnregister() {
		this.AsyncSelect(0)
		if this.Bound
			OnMessage(this.WM_SOCKET, this.Bound, 0)
			, this.Bound := False
	}

	AsyncSelect(lEvent) {
		if (DllCall("Ws2_32\WSAAsyncSelect", "Uint", this.Socket, "Ptr", A_ScriptHwnd, "Uint", this.WM_SOCKET, "Uint", lEvent) == -1)
			throw Exception("Error calling WSAAsyncSelect",, this.GetLastError())
		Return 1
	}

	GetLastError() {
		return DllCall("Ws2_32\WSAGetLastError")
	}
}

class SocketTCP extends Socket {
	static ProtocolId := 6  ; IPPROTO_TCP
	static SocketType := 1  ; SOCK_STREAM
}

class SocketUDP extends Socket {
	static ProtocolId := 17  ; IPPROTO_UDP
	static SocketType := 2  ; SOCK_DGRAM

	EnableBroadcast() {
		VarSetCapacity(optval, 4, 0) && NumPut(1, optval, 0, "Uint")
		if (DllCall("ws2_32\setsockopt", "Ptr", this.Socket, "int", 0xFFFF, "int", 0x0020, "Ptr", &optval, "int", 4) = 0)
			return 1
		return 0
	}

	DisableBroadcast() {
		VarSetCapacity(optval, 4, 0)
		if (DllCall("ws2_32\setsockopt", "Ptr", this.Socket, "int", 0xFFFF, "int", 0x0020, "Ptr", &optval, "int", 4) = 0)
			return 1
		return 0
	}
}