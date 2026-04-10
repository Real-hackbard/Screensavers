object Form1: TForm1
  Left = 499
  Top = 188
  BorderStyle = bsNone
  Caption = 'Sand Case'
  ClientHeight = 261
  ClientWidth = 368
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  OnClick = FormClick
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyPress = FormKeyPress
  OnMouseMove = FormMouseMove
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object PaintBox1: TPaintBox
    Left = 0
    Top = 0
    Width = 368
    Height = 261
    Align = alClient
    OnClick = FormClick
    OnMouseMove = FormMouseMove
    OnPaint = PaintBox1Paint
  end
  object Image1: TImage
    Left = 0
    Top = 0
    Width = 152
    Height = 112
    AutoSize = True
    Visible = False
  end
  object Timer: TTimer
    Interval = 33
    OnTimer = TimerTimer
    Left = 216
    Top = 72
  end
end
