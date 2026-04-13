unit Config;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Spin, IniFiles, ExtCtrls;

type
  TForm2 = class(TForm)
    ConfigGrpBox: TGroupBox;
    NbBlood: TLabel;
    NbBloodEdit: TSpinEdit;
    Grav: TLabel;
    GravEdit: TComboBox;
    Blood: TLabel;
    BloodEdit: TComboBox;
    SepBevel1: TBevel;
    Speed: TLabel;
    SpeedEdit: TComboBox;
    Length: TLabel;
    LengthEdit: TComboBox;
    Size: TLabel;
    SizeEdit: TComboBox;
    ApplyBtn: TButton;
    CloseBtn: TButton;
    procedure FormCreate(Sender: TObject);
    procedure CloseBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ApplyBtnClick(Sender: TObject);
  private
    { Declarations privates }
  public
    { Declarations public }
    procedure GetConfig;
    procedure SetConfig;
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

procedure TForm2.GetConfig;
begin
 with TIniFile.Create(ExtractFilePath(Application.ExeName) + 'BloodSaver.ini') do
  begin
   NbBloodEdit.Value := ReadInteger('BloodOptions', 'NbBlood', 20);
   GravEdit.ItemIndex := ReadInteger('BloodOptions', 'Gravity', 0);
   BloodEdit.ItemIndex := ReadInteger('BloodOptions', 'Color', 0);  // On récupère tout
   SpeedEdit.ItemIndex := ReadInteger('BloodOptions', 'Speed', 1);
   LengthEdit.ItemIndex := ReadInteger('BloodOptions', 'Length', 1);
   SizeEdit.ItemIndex := ReadInteger('BloodOptions', 'Size', 1);
  end;
end;

procedure TForm2.SetConfig;
begin
 with TIniFile.Create(ExtractFilePath(Application.ExeName) + 'BloodSaver.ini') do
  begin
   WriteInteger('BloodOptions', 'NbBlood', NbBloodEdit.Value);
   WriteInteger('BloodOptions', 'Gravity', GravEdit.ItemIndex);
   WriteInteger('BloodOptions', 'Color', BloodEdit.ItemIndex);  // We write everything
   WriteInteger('BloodOptions', 'Speed', SpeedEdit.ItemIndex);
   WriteInteger('BloodOptions', 'Length', LengthEdit.ItemIndex);
   WriteInteger('BloodOptions', 'Size', SizeEdit.ItemIndex);
  end;
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
 DoubleBuffered := True; // We avoid flickering
 ConfigGrpBox.DoubleBuffered := True;
end;

procedure TForm2.CloseBtnClick(Sender: TObject);
begin
 Application.Terminate; // We avoid the flickering. We leave.
end;

procedure TForm2.FormShow(Sender: TObject);
begin
 GetConfig; // We're gathering information.
end;

procedure TForm2.ApplyBtnClick(Sender: TObject);
begin
 SetConfig; // We apply and we leave
 Application.Terminate;
end;

end.
