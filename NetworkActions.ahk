#Include MainFunctions.ahk

global GDUT_SSID := "gdut"
global RETRY_COUNT := 5

GDUT(notify := True)
{
    If(GDUT_TryConnect(notify))
        GDUT_TryLogin(notify)
}

; 尝试连接 gdut
GDUT_TryConnect(notify := True)
{
    count := RETRY_COUNT

    While (count)
    {
        If (Wifi_IsConnected(GDUT_SSID))
            Return True
        If (Wifi_IsNear(GDUT_SSID))
            If (Wifi_Connect(GDUT_SSID, notify))
                Return True
        count--
    }

    If (notify)
        ShowSplashText("GDUT", "failed to connect", 800)
    Return False ; 多次尝试无果
}

GDUT_TryLogin(notify := True)
{
    count := RETRY_COUNT

    While (count)
    {
        Try
        {
            result := ""

            url := loginHeadUrl . GetIPAddress() . loginTailUrl

            result := Web_Get(url)

            If (result)
            {
                If (notify)
                    ShowSplashText("GDUT", GDUT_ParseMsg(result), 800)
                Return True
            }
        }
        Catch
        {
        }
        count--
    }

    If (notify)
        ShowSplashText("GDUT", "failed to login", 800)
    Return False ; 多次尝试无果
}

GDUT_ParseMsg(json)
{
    RegExMatch(json, "i)""msg""\s*:\s*""(.+?)""", data)
    return data1
}