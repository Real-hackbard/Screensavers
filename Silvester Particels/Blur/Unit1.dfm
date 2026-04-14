object Form1: TForm1
  Left = 393
  Top = 184
  Cursor = -1
  BorderStyle = bsNone
  Caption = 'Blur'
  ClientHeight = 223
  ClientWidth = 298
  Color = clBlack
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  WindowState = wsMaximized
  OnClick = FormClick
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyPress = FormKeyPress
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Timer: TTimer
    Interval = 33
    OnTimer = TimerTimer
    Left = 24
    Top = 32
  end
end
