object Form2: TForm2
  Left = 518
  Top = 187
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'Screensaver setup'
  ClientHeight = 163
  ClientWidth = 369
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Verdana'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 32
    Top = 8
    Width = 322
    Height = 29
    Caption = 'Airplane screensaver setup'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -24
    Font.Name = 'Verdana'
    Font.Style = []
    ParentFont = False
  end
  object Label2: TLabel
    Left = 40
    Top = 56
    Width = 63
    Height = 18
    Caption = 'Speed :'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Verdana'
    Font.Style = []
    ParentFont = False
  end
  object Label3: TLabel
    Left = 96
    Top = 80
    Width = 38
    Height = 18
    Caption = 'Slow'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Verdana'
    Font.Style = []
    ParentFont = False
  end
  object Label4: TLabel
    Left = 312
    Top = 80
    Width = 34
    Height = 18
    Caption = 'Fast'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Verdana'
    Font.Style = []
    ParentFont = False
  end
  object ScrollBar1: TScrollBar
    Left = 112
    Top = 56
    Width = 217
    Height = 13
    Max = 6
    Min = 1
    PageSize = 0
    Position = 1
    TabOrder = 1
  end
  object BitBtn1: TBitBtn
    Left = 112
    Top = 120
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 0
    OnClick = BitBtn1Click
    NumGlyphs = 2
  end
end
