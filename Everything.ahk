global E_FILE_NAME = 0x00000001 ; 仅名字
    , E_PATH = 0x00000002 ; 仅路径
    , E_FULL_PATH_AND_FILE_NAME = 0x00000004 ; 完整路径
    , E_EXTENSION = 0x00000008 ; 拓展名
    , E_SIZE = 0x00000010 ; 文件大小

    , E_DATE_CREATED = 0x00000020 ; 创建日期
    , E_DATE_MODIFIED = 0x00000040 ; 最后被更改的日期
    , E_DATE_ACCESSED = 0x00000080 ; 最后被访问的日期
    , E_DATE_RUN = 0x00000800 ; 最后被执行的日期

    , E_ATTRIBUTES = 0x00000100 ; 文件属性, windows 所划定(只读, 压缩文件之类), 没啥用
    , E_FILE_LIST_FILE_NAME = 0x00000200 ; 没啥用
    , E_RUN_COUNT = 0x00000400 ; 没啥用
    , E_DATE_RECENTLY_CHANGED = 0x00001000 ;
    , E_HIGHLIGHTED_FILE_NAME = 0x00002000 ; 没啥用
    , E_HIGHLIGHTED_PATH = 0x00004000 ; 没啥用
    , E_HIGHLIGHTED_FULL_PATH_AND_FILE_NAME = 0x00008000 ; 没啥用

    , E_OK :=	0	; The operation completed successfully.
    , E_ERROR_MEMORY :=	1 ;	Failed to allocate memory for the search query.
    , E_ERROR_IPC :=	2 ;	IPC is not available.
    , E_ERROR_REGISTERCLASSEX :=	3 ;	Failed to register the search query window class.
    , E_ERROR_CREATEWINDOW :=	4 ;	Failed to create the search query window.
    , E_ERROR_CREATETHREAD :=	5 ;	Failed to create the search query thread.
    , E_ERROR_INVALIDINDEX :=	6 ;	Invalid index. The index must be greater or equal to 0 and less than the number of visible results.
    , E_ERROR_INVALIDCALL :=	7 ;	Invalid call.

global E_maxLen := 256
    , E_defaultFlags := (E_EXTENSION | E_FULL_PATH_AND_FILE_NAME)

    ; 以下的完整路径设置是必要的
    , E_pth := A_ScriptDir . "\Libs\Everything" . (A_Is64bitOS ? "64.dll" : "32.dll")
    , E_func := E_pth . "\Everything_"

; 调用 everything dll 搜索关键字并返回收个路径
EQuery(keywords)
{
    Try
    {
        e := new Everything()
        e.SetSearch(keywords)
        e.SetMax(1)
        e.SetRequestFlags(E_defaultFlags)
        e.Query(True)
        Return e.GetFullPath(0)
    }
    Catch
        Return ""
    Finally
    e := ""
}

; 在 query 后立即尝试
class Everything {

    dllModule := 0

    ; 设置一次搜索的最大数量
    SetMax(max)
    {
        DllCall(E_func . "SetMax", "UInt", max + 1) ; ??? 这个设置的值需要加一似乎才是正确的
    }

    SetOffset(offset)
    {
        DllCall(E_func . "SetOffset", "UInt", offset)
    }

    ; 设置进行搜索的参数
    SetRequestFlags(flags)
    {
        DllCall(E_func . "SetRequestFlags", "int", flags) ; 设置搜索项
    }

    ; 设置搜索表达式并准备搜索结果供查询
    SetSearch(keywords)
    {
        query := "file:" . keywords
        DllCall(E_func . "SetSearch", "Str", query)
    }

    ; SetHwnd(hwnd)
    ; {
    ;     DllCall(E_func . "SetReplyWindow", "Ptr", hwnd)
    ; }

    ; SetId(id)
    ; {
    ;     DllCall(E_func . "SetReplyID", "UInt", id)
    ; }

    Query(await := True)
    {
        Return DllCall(E_func . "QueryW", "int", await)
    }

    IsReply(msg, w, l, id)
    {
        Return DllCall(E_func . "IsQueryReply", "UInt", msg, "UPtr", w, "Ptr", l, "UInt", id)
    }

    ; 将查询到的结果数组设置到 arr, 并返回读取到的个数, 出错返回 -1
    GetFullPathsToArr(ByRef arr)
    {
        Try
        {
            arr := []
            i := 0

            While ++i
            {
                output := this.GetFullPath(i)

                if (GetType(output) != "string" || StrLen(output) <= 0) ; 结束读取并返回读取到的个数
                    return arr.Length()
                arr[i] := output
            }
        }
        Catch
        {
            arr := []
            Return -1
        }
        Finally
        {
            this.GetLastError()
        }
    }

    ; 读取完整路径
    GetFullPath(index := 0)
    {
        VarSetCapacity(fp, E_maxLen)
        DllCall(E_func . "GetResultFullPathName", "int", index, "Str", fp, "int", E_maxLen)
        re := StrGet(&fp)
        VarSetCapacity(fp, 0)
        Return re
    }

    ; 读取文件后缀
    GetExtension(index := 0)
    {
        ex := DllCall(E_func . "GetResultExtension", "UInt", index, "Str")
        Return ex
    }

    ; 读取 everything 最后发生的错误
    GetLastError(tell := True)
    {
        lst := DllCall(E_func . "GetLastError", "Int")
        if (lst == E_ERROR_MEMORY)
            msg := "Failed to allocate memory for the search query."
        if (lst == E_ERROR_IPC)
            msg := "IPC is not available."
        if (lst == E_ERROR_REGISTERCLASSEX)
            msg := "Failed to register the search query window class."
        if (lst == E_ERROR_CREATEWINDOW)
            msg := "Failed to create the search query window."
        if (lst == E_ERROR_CREATETHREAD)
            msg := "Failed to create the search query thread."
        if (lst == E_ERROR_INVALIDINDEX)
            msg := "Invalid index. The index must be greater or equal to 0 and less than the number of visible results."
        if (lst == E_ERROR_INVALIDCALL)
            msg := "Invalid call."
        Else
            Return 0

        If (tell)
            MB(msg)
        Return lst
    }

    __New()
    {
        this._LoadDll()
    }

    __Delete()
    {
        this._FreeDll()
    }

    ; 加载 everything dll 至内存
    _LoadDll()
    {
        this.dllModule := DllCall("LoadLibrary", "Str", E_pth, "Ptr")
    }

    ; 释放加载的 dll
    _FreeDll()
    {
        if (this.dllModule)
        {
            DllCall("FreeLibrary", "Ptr", this.dllModule)
            this.dllModule := 0
        }
    }
}