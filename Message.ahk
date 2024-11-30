; FT_Show(message, time := 0)
; FT_Dismiss()
; MB(message, title := "")
; TT_Show(message, pid := 1, x := "", y := "")
; TT_Dismiss(pid := 1)
; ST_Show(message, title := "", time := 0, width := 0, height := 0)
; ST_Dismiss()

global pid_FT := 20
  , width_ST_Defauult := 700
  , height_ST_Default := 300

; 跟随鼠标的 tool tip
FT_Show(message, time := 0)
{
  global start_FT := A_TickCount
    , time_FT := time
    , text_FT := message

  SetTimer, Tag_FT, 12 ; 接近 60 hz
  Return

  Tag_FT:
  If (A_TickCount - start_FT > time_FT && time_FT > 0) ; 当超时
  {
    SetTimer, Tag_FT, Off
    ToolTip, , , , pid_FT
  }
  Else ; 未满足消失条件, 刷新
  {
    ToolTip, %text_FT%, , , pid_FT
  }

  Return
}

FT_Dismiss()
{
  SetTimer, Tag_FT, Off
  ToolTip, , , , pid_FT
}

; msgbox
MB(message, title := "")
{
  MsgBox, 262144, %title% , %message%
}

; tool tip
TT_Show(message, pid := 1, x := "", y := "")
{
  ToolTip, %message%, x, y, pid
}

TT_Dismiss(pid := 1)
{
  ToolTip, , , , pid
}

; splash text
ST_Show(message, title := "", time := 0, width := 0, height := 0)
{
  ST_Dismiss()

  global width_ST := width > 0 ? width : width_ST_Defauult
    , height_ST := height > 0 ? height : height_ST_Default

  SplashTextOn, width_ST, height_ST

  width_ST *= 0.75

  Sleep, 100
  Progress, B ZH0 FM12 WM500 FS15 WS200 W%width_ST%, `n%message%`n, %title%

  If (time)
    SetTimer, Tag_ST, -%time%
  Return

  Tag_ST:
  ST_Dismiss()
  Return
}

ST_Dismiss()
{
  Progress, Off
  SplashTextOff
}