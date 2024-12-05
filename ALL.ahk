#Include %A_ScriptDir%\Message.ahk
#Include %A_ScriptDir%\CodeParser.ahk
#Include %A_ScriptDir%\Text.ahk
#Include %A_ScriptDir%\System.ahk
#Include %A_ScriptDir%\GDUT.ahk
#Include %A_ScriptDir%\Net.ahk
#Include %A_ScriptDir%\ConfigTools.ahk
#Include %A_ScriptDir%\FileTools.ahk

; global localhostPath := A_ScriptDir . "\base_url.txt"

; Chrome_Run(url)
; {
;     ChromeInst := new Chrome("C:\Users\" . A_UserName . "\AppData\Local\Microsoft\Edge\User Data", url)
;     Return ChromeInst
; }

; Action_LoaclTunnel(port := "3000")
; {
;     result := GetUrl_NewLoaclTunnel()

;     If (!result)
;         Return

;     oldUrl := GetUrl_OnLocalFile()

;     If (result != oldUrl)
;         FileOpen(localhostPath, "w").Write(result).Close()

;     Clipboard := result
;     ST_Show("localhost", "successfully run`n" . result, 1000)
; }

; GetUrl_OnLocalFile()
; {
;     FileRead, url, %localhostPath%
;     Return url
; }

; GetUrl_NewLoaclTunnel(port := "3000")
; {
;     ; Run % ComSpec " /c lt --port 3000", , Maximize
;     Run % ComSpec " /c ssh -R 80:localhost:" . port . " localhost.run`nyes`n", , Maximize
;     ; Run % ComSpec " /c ssh -R 80:localhost:3000 NIKI@localhost.run`nyes`n", , Maximize

;     Sleep, 1000

;     SetTitleMatchMode, 2
;     IfWinExist, cmd.exe
;     {
;         BlockInput, On
;         WinMaximize
;     }
;     Else
;         Return ""

;     Sleep, 500
;     WinGetPos, X, Y, Width, Height, A

;     StartX := (X + Width) * 0.8
;     StartY := (Y + Height) * 0.8
;     EndX := X
;     EndY := Y

;     While !result
;     {
;         Click, %StartX%, %StartY%, Down ; 按下鼠标左键
;         SetDefaultMouseSpeed, 3
;         Click, %EndX%, %EndY%, Up ; 释放鼠标左键

;         Sleep, 200
;         result := ""
;         previous := ClipboardAll ; backup

;         Clipboard := ""
;         SendInput, ^c
;         ClipWait, 0.5

;         result := Clipboard
;         result := Trim(result, "`n`r ")
;         result := FilterText(result, "(http.+?.life)")
;         Clipboard := previous ; restitute
;     }

;     ; SetDefaultMouseSpeed, 0
;     ; Click, %Width%, %Y%

;     WinMinimize
;     BlockInput, Off

;     Return result
; }
