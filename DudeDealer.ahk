#Include Libs\Crypt.ahk
#Include MainFunctions.ahk

global dudesPath := A_AppData . "\WannaTakeThisDownTown"
global configsDefault := "1<[]>configs`n2<[]>paths`n3<[]>privacies`n4<[]>urls`n5<[]>apps"
global appsDefault := "1<[]>AutoBackup.ahk`n2<[]>DudeDealer.ahk`n3<[]>Main.ahk`n4<[]>MainFunctions.ahk`n5<[]>NetworkActions.ahk"
global othersDefault := "default<[]>default"

global globalValues := {}
globalValues["\configs.dude"] := configsDefault
globalValues["\apps.dude"] := appsDefault
globalValues["\nameless.dude"] := othersDefauecklt

; 传入生文本返回键值对
SimpleReader(content)
{
    values := {}
    Loop, Parse, content, `n, `r ; 分割文本为循环的方式
    {
        if (Trim(A_LoopField) = "")
        {
            continue
        }

        position := InStr(A_LoopField, "<[]>")

        if (position > 0) {
            key := Trim(SubStr(A_LoopField, 1, position - 1))
            value := Trim(SubStr(A_LoopField, position + 4))
            values[key] := value
        }
    }

    Return values
}

; 仅仅返回默认的键值对
DefaultReader(filePath)
{
    for key, value in globalValues ; globalValues -> ["/a.dude"] to "assd<[]>asasfafs"
    {
        if (filePath = dudesPath . key) ; 如果有事先设置的值则使用
        {
            Return SimpleReader(value)
        }
    }

    Return SimpleReader(othersDefault) ; 若没有则使用一个简单键值对
}

; 写入默认值
DefautWriter(filePath, password)
{
    if(FileExist(filePath))
    {
        FileDelete, %filePath%
    }

    for key, value in globalValues
    {
        if (filePath = dudesPath . key)
        {
            Return RawWriter(filePath, value, password)
        }
    }

    RawWriter(filePath, othersDefault, password)
}

; 通过路径和文本读取文件
FullDudeReader(filePath, password)
{
    password := FormatPassword(filePath, password) ; 获取"真密码"
    readable := Readable(filePath, password) ; 生文本
    if(!FileExist(filePath)) ; 写的一坨 这里是检查文件若不存在则创建以 password 为密码的默认文件
    {
        DefautWriter(filePath, password)
        ShowSplashText("Full Reader", """" . filePath . """: write default data", 1500)
        Return DefaultReader(filePath)
    }
    if(readable = "")
    {
        Return DefaultReader(filePath)
    }
    else
    {
        Return SimpleReader(readable)
    }
}

; 直接清除原文件内容并写入 content
RawWriter(filePath, content, password, tell := False){
    password := FormatPassword(filePath, password)

    content := Encrypt(content, password) ; encrypt raw text into "AS7ASBBSJW..."

    if (FileExist(filePath))
    {
        FileDelete, %filePath% ; delete first
    }
    Try
    {
        FileAppend, , %filePath%
        FileAppend, %content%, %filePath%
        if(tell)
        {
            ShowSplashText("Raw Writer", """" . filePath . """: successful", 1500)
        }
        Return True
    }
    Catch
    {
        ShowSplashText("Raw Writer", """" . filePath . """: failed", 1500)
        Return False
    }
}

; 未被使用，，，，我服了
; 修改文件的函数没有使用这个函数所以可以覆盖旧值
FullDudeWriter(filePath, values, password)
{
    password := FormatPassword(filePath, password) ; real password
    content := "" ; raw text

    existingValues := FullDudeReader(filePath, password) ; pairs that existed

    for key, value in values
    {
        if existingValues.HasKey(key)
        {
            ; if existed then override the old value
            content .= key "<[]>" existingValues[key] "`n"
        }
        else
        {
            ; directly write into content
            content .= key "<[]>" value "`n"
        }
    }

    RawWriter(filePath, content, password) ; write the raw text into file
}

; editor
UpdateData(list, password) {
    global
    pw := password
    lt := list
    nm := lt.MaxIndex()
    editable := False

    Gui, Destroy
    Gui, Font, s14
    Gui, Add, DropDownList, vChoice gOnChoiceChange
    Loop % nm
    {
        GuiControl, , Choice, % lt[A_Index]
    }
    Gui, Add, Edit, vEdited r30 w600 h20
    Gui, Add, Button, gDoSave w80 h30, Save
    Gui, Add, Button, gDoCancel x+20 w80 h30, Cancel
    Gui, Show,, Editing Dudes
    Return

    OnChoiceChange:
    Gui, Submit, NoHide
    Loop % nm
    {
        if(lt[A_Index] = Choice)
        {
            address := FormatAddress(lt[A_Index])
            if ( Readable(address, pw) != "")
            {
                editable := True
            }
            else
            {
                ShowSplashText("Change Password", "wrong password", 2000)
                Gui, Destroy
                Return
            }
            GuiControl, Text, Edited, % FormatData(FullDudeReader(address, pw))
        }
    }
    Return

    DoSave:
    Gui, Submit, NoHide
    if (Choice = "")
    {
        Msg("haven't choose file!")
        Return
    }
    Loop % nm
    {
        if(lt[A_Index] = Choice)
        {
            address := FormatAddress(lt[A_Index])
            FormatAddress(lt[A_Index])
            RawWriter(address, Edited, pw, True)
        }
    }
    Return

    DoCancel:
    GuiClose:
    GuiEscape:
    Gui, Destroy
    Return
}

; change the data to different password
ChangePassword(password){
    configs := FullDudeReader(dudesPath . "\configs.dude","default")
    count := configs.MaxIndex()
    old := ""
    InputBox, old, , Enter your old password:
    Loop % count
    {
        address := FormatAddress(configs[A_Index])
        if(Readable(address, old) = "")
        {
            ShowSplashText("Change Password", "wrong password", 2000)
            Return password
        }
    }
    new := ""
    InputBox, new, , Enter your new password:

    Try
    {

        Loop % count
        {
            ; MsgBox, % configs[A_Index]
            address := FormatAddress(configs[A_Index])
            values := FullDudeReader(address, old)
            str := FormatData(values)
            RawWriter(address, str, new)
        }
        ShowSplashText("Change Password", "successful", 1000)
        Return new
    }
    Catch
    {
        ShowSplashText("Change Password", "wrong password", 1000)
        Return password
    }
}

; ask to enter password
PasswordInput()
{
    InputBox, str, , Enter your password:`n`nOr set a new password:
    Return str
}

; 又设置了一次密码
; 用密码解密文件, 成功时返回生文本 ‘asdsa<[]>asdas\n...’
Readable(filePath, password)
{
    password := FormatPassword(filePath, password)
    FileRead, str, %filePath%
    Return Decrypt(str, password)
}

; 检查是否为某些不使用密码的文件, 如果是则把密码改为默认密码
FormatPassword(filePath, password)
{
    for key, value in globalValues
    {
        if (filePath = dudesPath . key)
        {
            Return "default"
        }
    }
    Return password
}

; 将键值对对象解析为一个字符串
FormatData(values)
{
    content := ""
    for key, value in values
    {
        content .= key "<[]>" value "`n"
    }
    Return content
}

; 传入文件名返回 '.../.../.../name.dude'
FormatAddress(name)
{
    return dudesPath "\" name ".dude"
}

; 加密字符串, 应该不会走到 catch 块
; AES-256
Encrypt(str, password)
{
    Try
    {
        values := Crypt.Encrypt.StrEncrypt(str, password, 3, 1)
        Return values
    }
    Catch
    {
        Return ""
    }
}

; 解析出错则返回空字串
; AES-256
Decrypt(str, password)
{
    Try
    {
        values := Crypt.Encrypt.StrDecrypt(str, password, 3, 1)
        Return values
    }
    Catch
    {
        Return ""
    }
}