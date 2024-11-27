/*
  模版:

  1. module := LoadLibrary - dll name
  2. call functions - dll name \ function name
  3. FreeLibrary - module

*/
global KB := 1024
global MAX_STRING_LEN := 256

; 模块的相对名称
; ../Dll/LibA/LibA32.dll -> libA/libA
global Name_Everything := "everything\Everything"
global Head_Everything := DllPathBuilder(Name_Everything) . "\Everything_"

; 设置新的查找
EveryThing_Set(pattern) {
  Everything_Prepare()

  query := "file:" . pattern

  ; 查询内容
  DllCall(Head_Everything . "SetSearch", "Str", query)

  ; https://www.voidtools.com/support/everything/sdk/everything_setrequestflags/
  ; 所需参数 - 文件名以及路径
  DllCall(Head_Everything . "SetRequestFlags", "int", (0x00000001 | 0x00000002)) ; 这两个参数具有规定的意义, 可以在文档上查看

  ; 进行查询 - 必须在查询前设置好查询偏好
  DllCall(Head_Everything . "Query", "int", 1)
}

; 必须在设置了搜索后调用, 返回结果的 str 数组
Everything_Query()
{
  Everything_Prepare()

  i := 0
  result := []
  While(True)
  {
    VarSetCapacity(output, MAX_STRING_LEN) ; dll 结果存储必须使用此函数开辟空间, 此处给 256 字节

    ; 读取结果
    DllCall(Head_Everything . "GetResultFullPathName", "int", i, "Str", output, "int", MAX_STRING_LEN)
    If (output)
      result[i] := output
    Else
      Return result
    i++
  }
}

Everything_Prepare()
{
  LoadModule(Name_Everything)
}

Everything_Free()
{
  FreeModule(Name_Everything)
}

; 加载模块到内存
; 如果你的 dll 在脚本根目录下, 名为 A.dll, 传入 "A" 即可
LoadModule(name) {
  dll := DllPathBuilder(name)

  ; 尝试获取已加载模块的句柄
  dllModule := DllCall("GetModuleHandle", "Str", dll, "Ptr")

  ; 检查 DLL 是否已被加载
  ; 如果未加载,则加载 DLL
  if (!dllModule)
    dllModule := DllCall("LoadLibrary", "Str", dll, "Ptr")

  Return dllModule
}

; 卸载模块
; 如果你的 dll 在脚本根目录下, 名为 A.dll, 传入 "A" 即可
FreeModule(name)
{
  dll := DllPathBuilder(name)
  dllModule := DllCall("GetModuleHandle", "Str", dll, "Ptr")

  ; 如果之前加载了 DLL,则在函数结束时卸载它
  if (dllModule)
    DllCall("FreeLibrary", "Ptr", dllModule)
}

; 根据 dll 文件名返回一个完整的文件路径 (根据机器选择位数)
DllPathBuilder(dllName)
{
  dllName .= A_PtrSize = 8 ? "64.dll" : "32.dll"
  Return A_ScriptDir . "\Dll\" . dllName
}