object Form1: TForm1
  Left = 604
  Top = 166
  BorderStyle = bsNone
  Caption = 'Pixel Swarm'
  ClientHeight = 320
  ClientWidth = 466
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  WindowState = wsMaximized
  OnClick = FormClick
  OnCreate = FormCreate
  OnResize = FormResize
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Timer1: TTimer
    Interval = 25
    OnTimer = Timer1Timer
    Left = 64
    Top = 56
  end
end
