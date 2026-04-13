object Form2: TForm2
  Left = 473
  Top = 161
  BorderStyle = bsSingle
  Caption = 'Configuration'
  ClientHeight = 145
  ClientWidth = 457
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object ConfigGrpBox: TGroupBox
    Left = 8
    Top = 8
    Width = 441
    Height = 129
    Caption = ' Global configuration '
    TabOrder = 0
    object NbBlood: TLabel
      Left = 8
      Top = 24
      Width = 128
      Height = 13
      Caption = 'Number of drops of blood: :'
    end
    object Grav: TLabel
      Left = 8
      Top = 56
      Width = 47
      Height = 13
      Caption = 'Severity: :'
    end
    object Blood: TLabel
      Left = 8
      Top = 88
      Width = 62
      Height = 13
      Caption = 'Blood color: :'
    end
    object SepBevel1: TBevel
      Left = 208
      Top = 16
      Width = 2
      Height = 105
    end
    object Speed: TLabel
      Left = 224
      Top = 24
      Width = 37
      Height = 13
      Caption = 'Speed :'
    end
    object Length: TLabel
      Left = 224
      Top = 48
      Width = 37
      Height = 13
      Caption = 'Scope :'
    end
    object Size: TLabel
      Left = 224
      Top = 72
      Width = 26
      Height = 13
      Caption = 'Size :'
    end
    object NbBloodEdit: TSpinEdit
      Left = 148
      Top = 21
      Width = 53
      Height = 22
      MaxValue = 255
      MinValue = 1
      TabOrder = 0
      Value = 1
    end
    object GravEdit: TComboBox
      Left = 56
      Top = 53
      Width = 141
      Height = 21
      Style = csDropDownList
      ItemHeight = 13
      ItemIndex = 0
      TabOrder = 1
      Text = 'Earth'#39's gravity'
      Items.Strings = (
        'Earth'#39's gravity'
        'Moon'#39's gravity'
        'Strong gravity'
        'Weak gravity'
        'No gravity')
    end
    object BloodEdit: TComboBox
      Left = 80
      Top = 86
      Width = 112
      Height = 21
      Style = csDropDownList
      ItemHeight = 13
      ItemIndex = 0
      TabOrder = 2
      Text = 'Red'
      Items.Strings = (
        'Red'
        'Green'
        'Blue'
        'White'
        'Random')
    end
    object SpeedEdit: TComboBox
      Left = 272
      Top = 21
      Width = 157
      Height = 21
      Style = csDropDownList
      ItemHeight = 13
      ItemIndex = 1
      TabOrder = 3
      Text = 'Normal'
      Items.Strings = (
        'Low'
        'Normal'
        'High')
    end
    object LengthEdit: TComboBox
      Left = 272
      Top = 45
      Width = 157
      Height = 21
      Style = csDropDownList
      ItemHeight = 13
      ItemIndex = 1
      TabOrder = 4
      Text = 'Normal'
      Items.Strings = (
        'Low'
        'Normal'
        'High')
    end
    object SizeEdit: TComboBox
      Left = 272
      Top = 69
      Width = 157
      Height = 21
      Style = csDropDownList
      ItemHeight = 13
      ItemIndex = 1
      TabOrder = 5
      Text = 'Normal'
      Items.Strings = (
        'Low'
        'Normal'
        'High')
    end
    object ApplyBtn: TButton
      Left = 224
      Top = 96
      Width = 105
      Height = 25
      Caption = 'Apply'
      TabOrder = 6
      OnClick = ApplyBtnClick
    end
    object CloseBtn: TButton
      Left = 336
      Top = 96
      Width = 97
      Height = 25
      Caption = 'Close'
      TabOrder = 7
      OnClick = CloseBtnClick
    end
  end
end
