; GetFuncDescriptionInFile(filePath := "")
; FilterFuncName(str)
; IsArrIncluding(array, expect)

#Include Text.ahk

; 识别函数定义的正则
; 必须加个括号在外面才能保存
; [A-Z] A-Z 任意字符
; \w 等效于 [a-zA-Z0-9_]
; {xxx}* {xxx} 可以出现若干次 [0, +)
; [^\n\r()] 不可以是 : \n, \r, (, ), 除此之外的字符均可
; \s 空白符
; (?=xxx) 正向预查是否有 'xxx'
; (?<=xxx) 反向预查

global keywords_CodeParser := ["for", "if", "loop", "else", "else if", "while", "switch", "try", "catch", "when"]

; 查找一个文件内所有函数的定义, 有可能识别错误
GetFuncDescriptionInFile(filePath := "")
{
  If (!FileExist(filePath))
    FileSelectFile, filePath, 3, , 选择一个文件 ; 1 + 2 文件、路径都必须存在

  if (!FileExist(filePath))
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

    r := Trim(match1, "`n`r ")
    If (r && !IsArrIncluding(keywords_CodeParser, FilterFuncName(r))) ; 筛选出为非内置关键字的函数
      result .= r . "`n"
  } Until (oldPos = pos) ; 位置不再变化则终止

  Return result
}

; 提取函数名
FilterFuncName(str)
{
  pattern := "(\w*\s*(?=\())"
  filter := FilterText(str, pattern)
  Return Trim(filter, "`n`r ")
}

; 检查数组中是否存在某元素
IsArrIncluding(array, expect)
{
  StringLower, expect, expect
  for index, value in array
  {
    StringLower, value, value
    if (value == expect)
      Return true
  }
  Return False
}