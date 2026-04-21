object Form1: TForm1
  Left = 375
  Top = 161
  Width = 648
  Height = 514
  Caption = 'VertexArray vs. DisplayList'
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
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object ApplicationEvents1: TApplicationEvents
    OnIdle = ApplicationEvents1Idle
    Left = 24
    Top = 36
  end
  object RotTimer: TTimer
    Interval = 15
    OnTimer = RotTimerTimer
    Left = 56
    Top = 36
  end
  object FPSTimer: TTimer
    Interval = 1
    OnTimer = FPSTimerTimer
    Left = 88
    Top = 36
  end
end
