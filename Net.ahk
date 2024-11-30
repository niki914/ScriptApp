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

#Include CMD.ahk
#Include Text.ahk
#Include Libs\JSON.ahk

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
    If (obj.code != "")
        Return obj.code != -1
    Else
        Return False
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

IsWifiNear(ssid)
{
    Return RunCmdWithExpect("netsh wlan show networks mode=bssid", ssid)
}

IsWifiConnected(ssid)
{
    Return GetCurrentWifi() = ssid
}

GetCurrentWifi()
{
    result := RunCmd("netsh wlan show interfaces")
    Return FilterText(result, "SSID\s+:\s(.+)") ; "" 则是未连接
}

ConnectWifi(ssid)
{
    Return RunCmdWithExpect("netsh wlan connect name=" . ssid, "已")
}

; 展示结果
DisconnectWifi()
{
    Return RunCmd("netsh wlan disconnect")
}