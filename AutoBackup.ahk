#Include MainFunctions.ahk

global parentPath := "D:\A_BACKUPS\AhkBackups\"
global dudesPath := A_AppData . "\WannaTakeThisDownTown"
global scriptPath := A_ScriptDir

ZipFileNameBuilder(customTag, fileType)
{
    time := %A_YYYY%%A_MM%%A_DD%
    Return parentPath . customTag . "_" . time . "." . fileType
}

CommandBuilder_WinRAR(zipTag, folderName)
{
    Return "a -af -r -ep1 """ . ZipFileNameBuilder(zipTag, "rar") . """ """ . folderName . """" ; [cmd] "xxx.zip" ".../.../xxx"
}

CommandBuilder_7Z(zipTag, folderName)
{
    Return "a -t7z -r -y """ . ZipFileNameBuilder(zipTag, "7z") . """ """ . folderName . """" ; [cmd] "xxx.zip" ".../.../xxx"
}

BackUp()
{
    currentTime = %A_YYYY%%A_MM%%A_DD%

    If !FileExist(parentPath)
        FileCreateDir, %parentPath%

    cmd_ZipDudes := ""
    cmd_ZipScript := ""

    path_WinRAR := SearchFile_EveryThing("winrar", "exe")
    path_7Z := SearchFile_EveryThing("7z", "exe")

    If (path_WinRAR)
    {
        cmd_ZipDudes := CommandBuilder_WinRAR("DUDES", dudesPath)
        cmd_ZipScript := CommandBuilder_WinRAR("SCRIPTS", scriptPath)
        RunWait, %path_WinRAR% %cmd_ZipDudes%, , Hide
        RunWait, %path_WinRAR% %cmd_ZipScript%, , Hide
    }
    Else If (path_7Z)
    {
        cmd_ZipDudes := CommandBuilder_7Z("DUDES", dudesPath)
        cmd_ZipScript := CommandBuilder_7Z("SCRIPTS", scriptPath)
        RunWait, %path_7Z% %cmd_ZipDudes%, , Hide
        RunWait, %path_7Z% %cmd_ZipScript%, , Hide
    }
}