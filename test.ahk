#NoEnv
#Include MainFunnctions.ahk
#SingleInstance, Force
SendMode, Input
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir%

Show(path)
{
    r := ReadFunctionsInFile(path)
    ShowSplashText("", r, 20000)
}