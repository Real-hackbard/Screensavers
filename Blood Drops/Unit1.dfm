object Form1: TForm1
  Left = 626
  Top = 214
  BorderIcons = [biSystemMenu]
  BorderStyle = bsNone
  Caption = 'Blood Saver'
  ClientHeight = 303
  ClientWidth = 450
  Color = clBlack
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  WindowState = wsMaximized
  OnCreate = FormCreate
  OnKeyPress = FormKeyPress
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Image1: TImage
    Left = 0
    Top = 0
    Width = 450
    Height = 303
    Align = alClient
    OnClick = Image1Click
  end
  object Timer1: TTimer
    Interval = 35
    OnTimer = Timer1Timer
    Left = 64
    Top = 96
  end
end
