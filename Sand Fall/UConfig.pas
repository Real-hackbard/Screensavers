unit UConfig;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Spin, ExtCtrls;

type
  TForm2 = class(TForm)
    Button1: TButton;
    Panel1: TPanel;
    procedure FormShow(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Declarations privates }
  public
    { Declarations public }
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

uses Unit1;

procedure TForm2.FormShow(Sender: TObject);
begin
 ShowWindow(Application.Handle,SW_HIDE);
end;

procedure TForm2.Button1Click(Sender: TObject);
begin
 close;
end;

end.
