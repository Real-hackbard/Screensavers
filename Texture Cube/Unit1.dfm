object Form1: TForm1
  Left = 331
  Top = 162
  BorderStyle = bsNone
  Caption = 'Texture Cube'
  ClientHeight = 320
  ClientWidth = 350
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClick = FormClick
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyPress = FormKeyPress
  OnResize = FormResize
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object ApplicationEvents1: TApplicationEvents
    OnIdle = ApplicationEvents1Idle
    Left = 6
    Top = 3
  end
  object Timer1: TTimer
    Interval = 10
    OnTimer = Timer1Timer
    Left = 39
    Top = 3
  end
  object Timer2: TTimer
    OnTimer = Timer2Timer
    Left = 72
    Top = 3
  end
end
