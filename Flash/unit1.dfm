object Form1: TForm1
  Left = 487
  Top = 266
  Width = 238
  Height = 194
  Caption = 'Flash'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyPress = FormKeyPress
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object Timer1: TTimer
    Interval = 80
    OnTimer = Timer1Timer
    Left = 24
    Top = 24
  end
end
