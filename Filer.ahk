; 处理二进制文件, 不局限于文本文件
class Filer {
    ; 读取文件为字节数组, batches 为单次缓存数量
    ; 以访问第一个字节为例: byte := bytes[1]
    ReadBytes(batches := 256)
    {
        file := this.file
        If (!file.Length)
            Return []

        file.Pos := 0
        bytes := []

        full := file.Length // batches
        mod := Mod(file.Length, batches)

        Loop % full
        {
            file.RawRead(buffer, batches)
            Loop % batches
                bytes.Push(NumGet(buffer, A_Index - 1, "UChar"))
        }

        If (mod > 0) ; 读取余数
        {
            file.RawRead(buffer, mod)
            Loop % mod
                bytes.Push(NumGet(buffer, A_Index - 1, "UChar"))
        }

        Return bytes
    }

    WriteBytes(bytes, batches := 256)
    {
        this.file := this.Recreate()
        Return this.AppendBytes(bytes, batches)
    }

    AppendBytes(bytes, batches := 256)
    {
        file := this.file
        If (!IsObject(bytes) || !bytes.Length())
            Return 0

        If (!file.Seek(0, 2))
            Return

        bytesWritten := 0

        full := bytes.Length() // batches
        mod := Mod(bytes.Length(), batches)

        ; 创建固定大小的缓冲区
        VarSetCapacity(buffer, batches, 0)

        ; 写入完整批次
        Loop % full
        {
            index := (A_Index - 1) * batches
            Loop % batches
            {
                NumPut(bytes[index + A_Index], buffer, A_Index - 1, "UChar")
            }
            bytesWritten += file.RawWrite(buffer, batches)
        }

        ; 写入剩余字节
        If (mod > 0)
        {
            index := full * batches
            Loop % mod
            {
                NumPut(bytes[index + A_Index], buffer, A_Index - 1, "UChar")
            }
            bytesWritten += file.RawWrite(buffer, mod)
        }

        Return bytesWritten
    }

    Recreate()
    {
        path := this.filePath
        SplitPath, path,, dir

        if (!FileExist(dir))
        {
            FileCreateDir, %dir%
            if (ErrorLevel)
                return false
        }
        If(FileExist(path))
            FileDelete, %path%

        Return FileOpen(path, "rw")
    }

    Size()
    {
        If (!this.file)
            Return -1
        Return this.file.Length
    }

    close() {
        this.file.Close()
    }

    __New(path) {
        this.filePath := path

        If (FileExist(path))
            this.file := FileOpen(path, "a")
        Else
            this.file := this.Recreate()

        if (!this.file)
            throw Exception("Failed to open file: " . path)
    }

    __Delete() {
        this.Close()
    }
}