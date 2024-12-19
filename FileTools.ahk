; ReadBytes(path, batchSize := 4096)
; WriteBytes(path, bytes, batches := 4096)
; AppendBytes(path, bytes, batchSize := 4096)
; CryptBytes(bytes, password)
; GetType(v)
; GetEmptyFile(path)
; GetAppendFile(path, create := False)
; GetReadFile(path, create := False)
; GetFileSize(path)
; XORFile(inFilePath, outFilePath, password, bufferSize := 4096)

#Include %A_ScriptDir%\Text.ahk

WriteStringToFile(path, str)
{
    file := GetEmptyFile(path)
    If (!file)
        Return 0
    file.Write(str)
    file.Close()
    Return 1
}

; 读取文件为字节数组, batches 为单次缓存数量
ReadBytes(path, batchSize := 4096) {
    file := GetReadFile(path)

    If (!file || !file.Length)
        Return []

    fileSize := file.Length
    mod := Mod(fileSize, batchSize)
    bytes := []

    file.Pos := 0
    VarSetCapacity(buffer, batchSize, 0)

    Loop % (fileSize // batchSize)
    {
        bytesRead := file.RawRead(&buffer, batchSize)
        if (bytesRead != batchSize)
            Return bytes + bytesRead

        offset := (A_Index - 1) * batchSize
        Loop % batchSize
            bytes[offset + A_Index] := NumGet(buffer, A_Index-1, "UChar")
    }

    if (mod <= 0)
        Return bytes

    ; 处理剩余的字节
    bytesRead := file.RawRead(&buffer, mod)
    if (bytesRead != mod)
        Return bytes + bytesRead

    offset := fileSize - mod
    Loop % mod
        bytes[offset + A_Index] := NumGet(buffer, A_Index-1, "UChar")

    Return bytes
}

; 初始化文件并写入字节数组
WriteBytes(path, bytes, batches := 4096)
{
    file := GetEmptyFile(path)
    file.Close()
    AppendBytes(path, bytes, batches)
}

; 拼接字节数组至文件
AppendBytes(path, bytes, batchSize := 4096) {
    file := GetAppendFile(path, True)

    If (!file || !bytes.Length() || !file.Seek(0, 2))
        Return 0

    bytesLength := bytes.Length()
    bytesWritten := 0
    mod := Mod(bytesLength, batchSize)

    VarSetCapacity(buffer, batchSize, 0)

    Loop % (bytesLength // batchSize)
    {
        offset := (A_Index - 1) * batchSize
        Loop % batchSize
            NumPut(bytes[offset + A_Index], buffer, A_Index - 1, "UChar")

        written := file.RawWrite(&buffer, batchSize)
        if (written != batchSize)
            Return bytesLength + written

        bytesWritten += written
    }

    ; 处理剩余的字节
    if (mod <= 0)
        Return bytesWritten

    offset := bytesLength - mod
    Loop % mod
        NumPut(bytes[offset + A_Index], buffer, A_Index - 1, "UChar")

    written := file.RawWrite(&buffer, mod)
    if (written != mod)
        Return bytesLength + written

    bytesWritten += written

    Return bytesWritten
}

; 用字符串作为密码加密字节数组
CryptBytes(bytes, password) {
    ; 将密码转换为字节数组
    pwBytes := StringToBytes(password)
    pwLength := pwBytes.Length()
    length := bytes.Length()
    encryptedBytes := []

    Loop % length
    {
        keyIndex := Mod(A_Index - 1, pwLength) + 1
        encryptedBytes.Push(bytes[A_Index] ^ pwBytes[keyIndex])
    }

    Return encryptedBytes
}

; 获取变量的类型
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

; 获取空文件实例
GetEmptyFile(path)
{
    SplitPath, path,, dir

    if (!FileExist(dir))
    {
        FileCreateDir, %dir%
        if (ErrorLevel)
            return 0
    }

    If(FileExist(path))
        FileDelete, %path%

    Return FileOpen(path, "rw")
}

; 获取文件实例
GetAppendFile(path, create := False)
{
    If (FileExist(path) || create)
        Return FileOpen(path, "a")
    Else
        Return GetEmptyFile(path)
}

; 获取文件实例
GetReadFile(path, create := False)
{
    If (FileExist(path) || create)
        Return FileOpen(path, "r")
    Else
        Return GetEmptyFile(path)
}

; 获取文件大小
GetFileSize(path)
{
    FileGetSize, size, %path%
    if (ErrorLevel)
        return -1 ; 表示错误
    return size
}

XORFile(inFilePath, outFilePath, password, bufferSize := 4096)
{
    return DllCall("Libs\XOR.dll\XORFile", "Str", inFilePath, "Str", outFilePath, "Str", password, "Int", bufferSize)
}

; ; 异或加密一个文件到指定路径, 默认缓存大小为 10M
; XORFile(inFilePath, outFilePath, password, bufferSize := 4096) {
;     If (GetType(bufferSize) != "number" || bufferSize <= 0)
;         Return "invalid buffer size"
;     If (!FileExist(inFilePath))
;         Return "input file not found"

;     fileIn := GetReadFile(inFilePath)
;     fileOut := GetEmptyFile(outFilePath)

;     if(!fileIn || !fileOut)
;     {
;         fileIn.Close()
;         fileOut.Close()
;         Return "cannot get files"
;     }

;     VarSetCapacity(buffer, bufferSize)

;     pwBytes := StringToBytes(password)
;     pwLength := pwBytes.Length()

;     ; 读取、加密并写入
;     while (bytesRead := fileIn.RawRead(&buffer, bufferSize))
;     {
;         Loop % bytesRead ; 对每个字节进行异或操作
;         {
;             pwIndex := Mod(A_Index - 1, pwLength) + 1
;             dataByte := NumGet(buffer, A_Index - 1, "UChar") ; 已经读至缓冲区的字节
;             pwByte := pwBytes[pwIndex]
;             encryptedByte := dataByte ^ pwByte
;             NumPut(encryptedByte, buffer, A_Index - 1, "UChar")

;             passwordIndex++
;         }

;         fileOut.RawWrite(&buffer, bytesRead)
;     }

;     fileIn.Close()
;     fileOut.Close()
;     Return "success"
; }