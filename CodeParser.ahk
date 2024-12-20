; GetFuncDescriptionInFile(filePath := "")
; ReadFileDescriptionForFolder()
; FilterFuncName(str)
; IsArrIncluding(array, expect)


#Include %A_ScriptDir%\lib\text\Text.ahk

global kw_CodeParser := ["for", "if", "loop", "else", "else if", "while", "switch", "try", "catch", "when"]



; 识别函数定义的正则
; 必须加个括号在外面才能保存
; [A-Z] A-Z 任意字符
; \w 等效于 [a-zA-Z0-9_]
; {xxx}* {xxx} 可以出现若干次 [0, +)
; [^\n\r()] 不可以是 : \n, \r, (, ), 除此之外的字符均可
; \s 空白符
; (?=xxx) 正向预查是否有 'xxx'
; (?<=xxx) 反向预查

; 查找一个文件内所有函数的定义, 有可能识别错误
GetFuncDescriptionInFile(filePath := "")
{
  If (!FileExist(filePath))
    FileSelectFile, filePath, 3, , 选择一个文件 ; 1 + 2 文件、路径都必须存在

  If (!FileExist(filePath))
    Return ""

  SplitPath, filePath, , , fileExt
  FileRead, fileContent, %filePath%

  pos := 1 ;起始位置

  If (fileExt = "ahk") ; .ahk
    pattern := "((?<=[\n|\r])\s*\w*\s*\([^\n\r()]*\)\s*(?={))"
  Else If (fileExt = "kt") ; .kt
    pattern := "((?<=fun)[ |<].+?\s*?\([\s|\S]*?\)\s*?(?=[:={]))"
  Else
    Return "" ; 还未适配其他语言

  Loop
  {
    oldPos := pos
    newPos := RegExMatch(fileContent, pattern, match, pos)
    pos := newPos + StrLen(match1)

    re := Trim(match1, "`n`t`r ")

    ; 筛选出为非内置关键字的函数
    ; 逻辑: 提取函数名字串, 转小写后与设定的关键字数组比对, 如果不是关键字并且不是空字串则拼接到字符串内
    If (re && !IsArrIncluding(kw_CodeParser, FilterFuncName(re)))
      result .= re . "`n"
  } Until (oldPos = pos) ; 字串指针位置不再变化则终止

  Return Trim(result, " `n`t`r")
}

; 读取一个目录下的文本文件并提取函数定义
ReadFileDescriptionForFolder()
{
  result := RunFolder("GetFuncDescriptionInFile")
  If (!result.Count())
    Return

  content := ""
  for index, value in result
    content .= "[" . index . "]`n" . value . "`n`n"

  Return content
}

; 提取函数名
FilterFuncName(str)
{
  pattern := "(\w*\s*(?=\())"
  filter := FilterText(str, pattern)
  Return Trim(filter, "`n`t`r ")
}

; 检查数组中是否存在某元素
IsArrIncluding(array, expect)
{
  StringLower, expect, expect
  for index, value in array
  {
    StringLower, value, value
    If (value == expect)
      Return true
  }
  Return False
}