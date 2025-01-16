; GDUT_KeepAlive()
; GDUT_Kill()
; GDUT()
; GDUT_Connect()
; GDUT_Login()

#Include %A_ScriptDir%\Net.ahk
#Include %A_ScriptDir%\lib\message\Message.ahk

global ssid_GDUT := "gdut"
    , retryCount_GDUT := 5
    , loginHeadUrl := ""
    , loginTailUrl := ""
    , isDone_GDUT := True

; 在连接了校园网并且网络不可用的时候自动登录
GDUT_KeepAlive()
{
    Gosub, Tag_GDUT
    SetTimer, Tag_GDUT, 10000
    Return

    Tag_GDUT:
    If (!isDone_GDUT)
        Return
    isDone_GDUT := False
    pingCode_GDUT := Ping("https://connectivitycheck.platform.hicloud.com/generate_204", 3)

    If (pingCode_GDUT == 0 && GetCurrentWifi() == "gdut")
        GDUT_Login()
    isDone_GDUT := True
    Return
}

GDUT_Kill()
{
    SetTimer, Tag_GDUT, Off
}

GDUT()
{
    Loop % retryCount_GDUT
    {
        If(GDUT_Connect())
            Return GDUT_Login()
        Sleep, 200
    }
    Return "gdut wifi was not connected"
}

; 连接 gdut wifi
GDUT_Connect()
{
    If (!IsWifiNear(ssid_GDUT))
        Return False
    Loop % retryCount_GDUT
    {
        If (IsWifiConnected(ssid_GDUT))
            Return True
        Sleep, 200
    }
    Return False ; 尝试无果
}

; get 登录 gdut
GDUT_Login()
{
    If (!loginHeadUrl)
    {
        MB("还未设置校园网 baseurl, 请看 main.ahk 中的 loginHeadUrl 参数")
        Return ""
    }
    url := loginHeadUrl . GetIP("10") . loginTailUrl
    result := GetRequest(url)
    msg := FilterText(result.text, "i)""msg""\s*:\s*""(.+?)""")
    Return msg
}