; GDUT_KeepAlive()
; GDUT_Kill()
; GDUT()
; GDUT_Connect()
; GDUT_Login()

#Include Net.ahk
#Include Message.ahk

global ssid_GDUT := "gdut"
    , retryCount_GDUT := 5
    , loginHeadUrl := ""
    , loginTailUrl := ""
    , isWorking_GDUT := False

; 在连接了校园网并且网络不可用的时候自动登录
GDUT_KeepAlive()
{
    SetTimer, Tag_GDUT, 5000
    Return

    Tag_GDUT:
    If (isWorking_GDUT)
        Return
    isWorking_GDUT := True
    If (!Ping("https://connectivitycheck.platform.hicloud.com/generate_204", 2) && GetCurrentWifi() == "gdut")
        ST_Show(GDUT_Login(), "gdut", 800)
    isWorking_GDUT := False
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
    }
    Return "gdut wifi was not connected"
}

; 连接 gdut wifi
GDUT_Connect()
{
    If (!IsWifiNear(ssid_GDUT))
        Return False
    Loop % retryCount_GDUT
        If (IsWifiConnected(ssid_GDUT))
            Return True
    Return False ; 尝试无果
}

; get 登录 gdut
GDUT_Login()
{
    url := loginHeadUrl . GetIP("10") . loginTailUrl
    result := GetRequest(url)
    msg := FilterText(result.text, "i)""msg""\s*:\s*""(.+?)""")
    Return msg
}