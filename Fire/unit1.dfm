object Form1: TForm1
  Left = 515
  Top = 167
  Width = 317
  Height = 342
  Caption = 'Fire'
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
  PixelsPerInch = 96
  TextHeight = 13
  object Timer1: TTimer
    Interval = 35
    OnTimer = Timer1Timer
    Left = 32
    Top = 24
  end
end
