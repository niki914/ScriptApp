; FindLastChild(path)
; BytesToString(bytes, encoding := "UTF-8")
; IsCN(text)
; StringToBytes(str, encoding := "UTF-8")
; BytesToBstring(Body, Cset)
; IsTextIncluding(text, expect, caseSensitive := False)
; FilterText(text, pattern)
; ReverseText(text)
; ParseCamelText(text)
; RunFolder(funcInstance, path := "")
; RunFuncForDirectory(path, funcInstance, ByRef result)


; 查找路径字串的最后一个子项
FindLastChild(path)
{
    s := Trim(path, " \/`n")
    re := FilterText(s, "((?<=\\|/)[^\\/]*$)")
    Return re ? re : path
}

; 字节数组转字符串, 默认 utf-8
BytesToString(bytes, encoding := "UTF-8") {
    length := bytes.Length()
    VarSetCapacity(buffer, length, 0) ; 用 0 初始化片区确保使用干净的内存区

    Loop % length
        NumPut(bytes[A_Index], buffer, A_Index - 1, "UChar")

    result := StrGet(&buffer, encoding)
    actualLength := StrLen(result)
    Return SubStr(result, 1, actualLength)
}

IsCN(text)
{
    Return RegExMatch(text, "[\x{4e00}-\x{9fa5}]")
}

; 字符串转字节数组, 默认 utf-8
StringToBytes(str, encoding := "UTF-8") {
    length := StrPut(str, encoding) - 1
    VarSetCapacity(buffer, length, 0)

    StrPut(str, &buffer, length + 1, encoding)

    bytes := []
    Loop % length
        bytes.Push(NumGet(buffer, A_Index - 1, "UChar"))

    return bytes
}

; 将 windows api 的 字节数组编码为字符串
BytesToBstring(Body, Cset) {
    stream := ComObjCreate("ADODB.Stream")
    stream.Type := 1 ; Binary
    stream.Mode := 3 ; Read/Write
    stream.Open()
    stream.Write(Body)
    stream.Position := 0
    stream.Type := 2 ; Text
    stream.Charset := Cset
    text := stream.ReadText()
    stream.Close()
    ObjRelease(stream)
    return text
}

; 检查文本是否包含期望的内容, 默认不区分大小写
IsTextIncluding(text, expect, caseSensitive := False)
{
    Return InStr(text, expect, caseSensitive, 1, 1) > 0 ; 找到的位置是否大于 0
}

; 使用正则表达式筛选出 text 中所包含的期望的部分
FilterText(text, pattern)
{
    RegExMatch(text, pattern, result)
    Return result1 ? result1 : result.Value
}

; 使用 windows api 反转一个字符串
ReverseText(text) {
    static r := A_IsUnicode ? "_wcsrev" : "_strrev"
    DllCall("msvcrt.dll\" r, "Ptr", &text, "CDECL")
    return text
}

; 解析驼峰字符串为英文句段, 用于解析代码
; 效果: "StrSplit(text, A_Space)" --> "Str split ( text , A _ Space )"
; 当内容为全大写的单词则会全部拆开
ParseCamelText(text)
{
    result := ""
    words := StrSplit(text, A_Space) ; 预处理: 按空格拆分为数组

    for index, word in words
    {
        if (index > 1)
            result .= A_Space ; 处理下一个数组元素前插入空格

        position := 1
        len := StrLen(word) ; 用于判断循环

        while (position <= len)
        {
            ; position 对应的字符
            thisChar := SubStr(word, position, 1)
            ; position + 1 对应的字符
            nextChar := (position < len) ? SubStr(word, position + 1, 1) : ""

            thisCharIsLowercase := RegExMatch(thisChar, "^[a-z]$")
            thisCharIsUppercase := RegExMatch(thisChar, "^[A-Z]$")
            thisCharIsLetter := thisCharIsLowercase || thisCharIsUppercase

            ; 非首字符并且是大写则转化为小写
            if (position > 1 && thisCharIsUppercase)
                result .= Format("{:L}", thisChar)
            Else ; 否则不处理
                result .= thisChar

            ; 下一字符不是小写或空格(空格不需要再加空格), 或者当前字符不是字母, 则插入空格
            if (!RegExMatch(nextChar, "^[a-z ]$") || !thisCharIsLetter)
                result .= A_Space

            position++
        }
    }

    return result
}

RunFolder(funcInstance, path := "")
{
    func := Func(funcInstance)
    if (!IsFunc(func))
        return {}

    if (!path || !FileExist(path))
    {
        FileSelectFolder, path,, 3, 选择一个文件夹
        if (!path) ; 取消
            return {}
    }

    result := {}
    RunFuncForDirectory(path, func, result)
    return result
}

RunFuncForDirectory(path, funcInstance, ByRef result)
{
    Loop, %path%\*.*, 0, 1
    {
        If (A_LoopFileIsDir)
            RunFuncForDirectory(A_LoopFileLongPath, funcInstance, result) ; 递归子目录
        Else
        {
            Try
            {
                if (r := %funcInstance%(A_LoopFileFullPath))
                    result[A_LoopFileLongPath] := r
            }
            Catch
            {
                Return
            }
        }
    }
}