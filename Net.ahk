; Bing(text, apiKey, from := "en", to := "zh-CN")
; DeepL(text, apiKey, from := "EN", to := "ZH-HANS")
; Ping(url, timeout := 5)
; GetRequest(url, timeout := 5)
; GetIP(expect := 10)
; IsWifiNear(ssid)
; IsWifiConnected(ssid)
; GetCurrentWifi()
; ConnectWifi(ssid)
; DisconnectWifi()

#Include %A_ScriptDir%\System.ahk
#Include %A_ScriptDir%\lib\text\Text.ahk
#Include %A_ScriptDir%\lib\json\JSON.ahk

; bing api 翻译, 默认美式英语译简中
Bing(text, apiKey, from := "en", to := "zh-CN")
{
    url := "http://api.microsofttranslator.com/v2/Http.svc/Translate?"
        . "appId=" . apiKey
        . "&from=" . from . "&to=" . to
        . "&text=" . text

    response := GetRequest(url)
    code := response.code
    text := response.text
    result := FilterText(text, "((?<=>).*?(?=</string>))") ; 滤出翻译结果字串
    Return {text: result, rawText: text}
}

; deepl api 翻译, 默认美式英语译简中
DeepL(text, apiKey, from := "EN", to := "ZH-HANS")
{
    StringUpper, from, from
    StringUpper, to, to

    obj := {text: [text], source_lang: from, target_lang: to}
    body := JSON.Dump(obj)

    deepl := "https://api-free.deepl.com/v2/translate"

    Try ; deepl 使用 post 方法
    {
        deeplRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        deeplRequest.Open("POST", deepl, False)
        deeplRequest.SetRequestHeader("Content-Type", "application/json")
        deeplRequest.SetRequestHeader("Authorization", "DeepL-Auth-Key " . apiKey)
        deeplRequest.SetRequestHeader("User-Agent", "deepl-java/1.7.0")
        deeplRequest.SetTimeouts(5000, 5000, 5000, 5000)
        deeplRequest.Send(body)

        code := deeplRequest.Status
        codeText := deeplRequest.StatusText
        response := BytesToBstring(deeplRequest.ResponseBody, "UTF-8")

        ObjRelease(deeplRequest)

        j := JSON.Load(response)
        r := j.translations[1].text
        Return {text: r, rawText: response}
    }
    Catch
    {
        Return {text: "", rawText: response}
    }
}

Ping(url, timeout := 5)
{
    obj := GetRequest(url, timeout)
    If (obj.code > 0 && obj.code != "")
        Return obj.code
    Else
        Return 0
}

; 超时参数为秒数
; 返回一个对象 {code, text, time}
GetRequest(url, timeout := 5)
{
    time := A_TickCount

    If timeout Is Number
        timeout := timeout >= 1 ? timeout : 1
    Else
        timeout := 5

    Try
    {
        request := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        request.Open("GET", url, True) ; false 为同步方法
        request.Send()
        request.WaitForResponse(timeout)

        code := request.Status
        body := request.ResponseBody
        text := request.ResponseText
        ObjRelease(request)

        Return {code: code, text: text, time: A_TickCount - time, body: body}
    }
    Catch
    {
        ObjRelease(request)
        Return {code: -1, text: "fail to get", time: A_TickCount - time}
    }
}

; 获取期望的 ipv4 地址 (powered by ai)
GetIP(expect := 10)
{
    ; 使用WMI（Windows Management Instrumentation）连接到Windows系统的管理接口
    objWMIService := ComObjGet("winmgmts:{impersonationLevel = impersonate}!\\.\root\cimv2")

    ; 查询所有启用了IP的网络适配器配置
    colItems := objWMIService.ExecQuery("Select * from Win32_NetworkAdapterConfiguration WHERE IPEnabled = True")._NewEnum
    currentIP := ""

    ; 遍历网络适配器
    while colItems[objItem]
    {
        ; 获取当前IP地址
        currentIP := objItem.IPAddress[0]

        ; 检查IP是否以期望的前缀开头
        if (SubStr(currentIP, 1, StrLen(expect)) = expect)
            return currentIP
    }

    ; 如果没有找到匹配的IP，返回空字符串
    return currentIP
}

IsWifiOn()
{
    r0 := RunCmd("netsh wlan show interfaces")
    r := (IsTextIncluding(r0, "已连接") || IsTextIncluding(r0, "软件 开"))
    Return r
}

IsWifiNear(ssid)
{
    r := RunCmdWithExpect("netsh wlan show networks mode=bssid", ssid)
    Return r
}

IsWifiConnected(ssid)
{
    r := (GetCurrentWifi() == ssid)
    Return r
}

GetCurrentWifi()
{
    r := RunCmd("netsh wlan show interfaces")
    Return FilterText(r, "SSID\s+:\s(.+)") ; "" 则是未连接
}

ConnectWifi(ssid)
{
    r := RunCmdWithExpect("netsh wlan connect name=" . ssid, "已")
    Return r
}

; 展示结果
DisconnectWifi()
{
    r := RunCmd("netsh wlan disconnect")
    Return r
}