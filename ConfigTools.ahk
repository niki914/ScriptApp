#Include Filer.ahk
#Include Libs\JSON.ahk
#Include MainFunctions.ahk

global POOL_RUNNABLE := {}
    , POOL_CODE := {}
    , POOL_STATIC := {}
    , POOL_HOTSTRING := {}

GetType(v) {
    If (IsObject(v))
    {
        If (v.Length())
            Return "array"
        If (v.Count())
            Return "object"
        Return "clazz"
    }
    If v is Number
        Return "number"
    If (v != "")
        Return "string"
    Return "undifined"
}

IsParsable(v)
{
    type := GetType(v)
    Return type == "array" || type == "object"
}

IsUrl(str)
{
    return RegExMatch(str, "i)^https?://") > 0
}

PraseObject(obj, parent := "")
{
    If (!IsParsable(obj)) ; 不可解析
        Return

    str := obj["value"]

    If (GetType(str) == "string") ; 当设置了 value 属性时
    {
        type := obj["type"]

        If (type == "hotString")
            POOL_HOTSTRING[parent] := str
        Else If (type == "runnable")
            POOL_RUNNABLE[parent] := str
        Else If (type == "code")
            POOL_CODE[parent] := str
        Else ; 全部当作 static 处理
            POOL_STATIC[parent] := str

        Return
    }

    for key, value in obj
        If (IsParsable(value)) ; 递归解析
        {
            PraseObject(value, key)
        }
        Else ; 值是基本类型
        {
            If (GetType(key) == "string")
                POOL_STATIC[key] := value
        }
}

BuildRunnables()
{
    For Key, value in POOL_RUNNABLE
        BuildHotstring("RunWithSplashText", key, value)
}

BuildHotStrings()
{
    for key, value in POOL_HOTSTRING
        BuildHotstring("SendString", key, value)
}

BuildCodes()
{
    For Key, value in POOL_CODE
        BuildHotstring("RunWaitString", key, value)
}

BuildHotstring(funcName, key, value)
{
    hotstring := ":*:" key "\"
    Hotstring(hotstring, Func(funcName).Bind(value))
}

ConfigsReload(cPath, cDefault, password, ByRef contents, ByRef manifest)
{
    isFirst := GetFileSize(cPath) <= 0

    If (isFirst)
        Guidance()

    If (isFirst && !IsJson(cDefault))
    {
        MsgBox, 默认配置表不是合法的json语句，脚本将退出！
        ExitApp
    }

    While 1
    {
        If (A_Index != 1)
            password := RequirePassword("密码错误, 请重试!") ; 要求输入密码

        If (password == -1)
            ExitApp

        configs := ReadCryptedJsonString(cPath, password, cDefault)
        If (!configs)
            Continue

        manifest := JSON.Load(configs)
        If (ReadConfigFiles(manifest, password, contents, "{}"))
            Break
    }
}

ConfigsInit(cPath, cDefault, ByRef password, ByRef contents, ByRef manifest)
{
    isFirst := GetFileSize(cPath) <= 0

    If (isFirst)
        Guidance()

    If (isFirst && !IsJson(cDefault))
    {
        MsgBox, 默认配置表不是合法的json语句，脚本将退出！
        ExitApp
    }

    While 1
    {
        If (A_Index == 1)
        {
            If (isFirst)
                msg := "设置一个密码"
            Else
                msg := "请输入密码"
        }
        Else
        {
            If (isFirst)
            {
                MsgBox, 未知错误🥲
                ExitApp
            }
            Else
                msg := "密码不正确，请重试"
        }

        password := RequirePassword(msg) ; 要求输入密码

        If (password == -1)
            ExitApp

        configs := ReadCryptedJsonString(cPath, password, cDefault)
        If (!configs)
            Continue

        manifest := JSON.Load(configs)
        If (ReadConfigFiles(manifest, password, contents, "{}"))
            Break
    }
}

; hotString
; static
; runnable
; code
Guidance()
{
    Msg("输入 ""ed\"" 可以打开编辑器，可以用 json 编辑工具编辑完成后再粘贴")
    Msg("使用高级功能的话需要设置两个变量:`n""type"": $str`n""value"": $str")
    Msg("type:`n hotString => 可展开的热字符串`n static => 内部的静态变量`n runnable =>可运行路径, 完整的文件路径和url均可 `n code => ahk代码`n`n必须为其中之一，否则视作static")
    Msg("示例: `n{`n""vs"":{""type"":""runnable"",""value"": ""D:\vscode.exe""}`n}")
}

; 要求输入密码
RequirePassword(msg)
{
    InputBox, str, , %msg%:
    if ErrorLevel ; 用户按下取消或关闭窗口
        Return -1
    Return str
}

; 文件大小
GetFileSize(filePath)
{
    FileGetSize, fileSize, %filePath%
    if (ErrorLevel)
        return -1 ; 表示错误
    return fileSize
}

; 读取加密文件为 json 字串
ReadCryptedJsonString(path, password, default)
{
    jsonObj := ReadCyptedJSON(path, password, default)
    If (jsonObj == 0)
        Return ""

    str := JSON.Dump(jsonObj)
    If (str == """""")
        str := "{}"
    Return str
}

; 读取并返回 json 对象
ReadCyptedJSON(path, password, default)
{
    Try
    {
        bytes := ReadCryptedFile(path, password, default)
        str := BytesToString(bytes, "UTF-8")
        obj := JSON.Load(str)
        Return obj
    }
    Catch
    {
        Return 0
    }
}

IsJson(str)
{
    Try
    {
        j := JSON.Load(str)
        s := JSON.Dump(j)
        Return True
    }
    Catch
    {
        Return False
    }
}

WriteCryptedJsonString(path, str, password)
{
    Try
    {
        j := JSON.Load(str)
        s := JSON.Dump(j)
        WriteCryptedJSON(path, j, password)
        Return True
    }
    Catch
    {
        Return False
    }
}

; 写入 json 对象
WriteCryptedJSON(path, obj, password)
{
    Try
    {
        If (!IsObject(obj))
            Return -1

        str := JSON.Dump(obj)
        bytes := StringToBytes(str, "UTF-8")
        Return WriteCryptFile(path, bytes, password)
    }
    Catch
    {
        Return -1
    }
}

; 读取加密文件为字节数组
ReadCryptedFile(path, password, default)
{
    f := new Filer(path)
    bytes := f.ReadBytes()
    decrypt := CryptBytes(bytes, password)
    f.Close()
    If (!bytes.Length())
    {
        defults := StringToBytes(default, "UTF-8")
        WriteCryptFile(path, defults, password)
        Return ReadCryptedFile(path, password, default)
    }
    Else
    {
        Return decrypt
    }
}

; 写入加密的字节数组到文件
WriteCryptFile(path, bytes, password)
{
    f := new Filer(path)
    encrypt := CryptBytes(bytes, password)
    count := f.WriteBytes(encrypt)
    f.Close()
    Return count
}

; 写入加密的字节数组到文件
AppendCryptFile(path, bytes, password)
{
    f := new Filer(path)
    encrypt := CryptBytes(bytes, password)
    count := f.AppendBytes(encrypt)
    f.Close()
    Return count
}

; 对字节数组进行异或运算并返回结果
CryptBytes(bytes, password)
{
    pwLength := StrLen(password)
    length := bytes.Length()
    encryptedBytes := []

    Loop % length
    {
        dataChar := bytes[A_Index]
        pwChar := NumGet(&password, Mod(A_Index - 1, pwLength), "UChar")
        encryptedBytes.Push(dataChar ^ pwChar)
    }

    Return encryptedBytes
}

; 字节数组转字符串
BytesToString(bytes, encoding := "UTF-8") {
    length := bytes.Length()
    VarSetCapacity(buffer, length, 0) ; 用 0 初始化片区确保使用干净的内存区。。。。。。

    Loop % length
    {
        NumPut(bytes[A_Index], buffer, A_Index - 1, "UChar")
    }

    result := StrGet(&buffer, encoding)
    actualLength := StrLen(result)
    Return SubStr(result, 1, actualLength)
}

; 字符串转字节数组
StringToBytes(str, encoding := "UTF-8") {
    length := StrPut(str, encoding) - 1
    VarSetCapacity(buffer, length, 0)

    StrPut(str, &buffer, length + 1, encoding)

    bytes := []
    Loop % length
    {
        bytes.Push(NumGet(buffer, A_Index - 1, "UChar"))
    }

    return bytes
}

; 生成配置文件路径
GetConfigPath(name)
{
    Return A_ScriptDir . "\Config\" . name . ".cy"
}

; 根据字符串数组读取配置文件并返回读取到的对象
; 返回值表示密码是否正确
ReadConfigFiles(manifest, password, ByRef outObj, default)
{
    contents := {}
    ok := True
    for _, configName in manifest
    {
        path := GetConfigPath(configName)
        jsonStr := ReadCryptedJsonString(path, password, default)
        If (!jsonStr)
        {
            ok := False
            Continue
        }

        contents[configName] := jsonStr
    }

    outObj := contents
    Return ok
}