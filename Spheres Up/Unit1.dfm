object Form1: TForm1
  Left = 319
  Top = 156
  Width = 648
  Height = 514
  Caption = '0 FPS'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnClick = FormClick
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyPress = FormKeyPress
  PixelsPerInch = 96
  TextHeight = 13
  object ApplicationEvents1: TApplicationEvents
    OnIdle = ApplicationEvents1Idle
    Left = 24
    Top = 20
  end
  object FPSTimer: TTimer
    Interval = 1
    OnTimer = FPSTimerTimer
    Left = 64
    Top = 20
  end
  object BubbleTimer: TTimer
    Interval = 25
    OnTimer = BubbleTimerTimer
    Left = 104
    Top = 20
  end
end
