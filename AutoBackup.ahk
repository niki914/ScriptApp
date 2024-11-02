#Include MainFunctions.ahk
#Include DllUtils.ahk

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

    EveryThing_Set("winRAR.exe")
    path_WinRAR := Everything_Query()[0]

    EveryThing_Set("7z.exe")
    path_7Z := Everything_Query()[0]

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
    Else
    {
        ShowSplashText("backup", "在您的设备上找不到 winRAR 或 7z, 无法备份", 2000)
    }
}