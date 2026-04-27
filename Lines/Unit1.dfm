object Form1: TForm1
  Left = 440
  Top = 155
  Width = 591
  Height = 478
  Caption = 'Lines'
  Color = clBlack
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyPress = FormKeyPress
  OnMouseDown = FormMouseDown
  OnPaint = PaintBox1Paint
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object Timer1: TTimer
    Interval = 30
    OnTimer = Timer1Timer
    Left = 84
    Top = 84
  end
end
