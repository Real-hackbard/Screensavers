object Form1: TForm1
  Left = 467
  Top = 184
  Width = 514
  Height = 480
  Caption = 'Object Loader'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClick = FormClick
  OnClose = FormClose
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object tmrRender: TTimer
    Interval = 35
    OnTimer = tmrRenderTimer
    Left = 32
    Top = 32
  end
  object tmrKey: TTimer
    Interval = 1
    OnTimer = tmrKeyTimer
    Left = 72
    Top = 32
  end
end
