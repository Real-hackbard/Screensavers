unit config;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons;

type
  TFrmConfig = class(TForm)
    BtnOk: TBitBtn;
    BtnCancel: TBitBtn;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BtnOkClick(Sender: TObject);
    procedure BtnCancelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmConfig: TFrmConfig;

implementation

{$R *.dfm}

procedure TFrmConfig.FormCreate(Sender: TObject);
begin
  // We hide the application in the taskbar
  SetWindowLong(Application.Handle, GWL_EXSTYLE, WS_EX_TOOLWINDOW);
end;

procedure TFrmConfig.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;  
end;

procedure TFrmConfig.BtnOkClick(Sender: TObject);
begin
  Close;
end;

procedure TFrmConfig.BtnCancelClick(Sender: TObject);
begin
  Close;
end;

end.
