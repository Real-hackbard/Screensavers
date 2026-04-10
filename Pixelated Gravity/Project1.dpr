program Project1;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  uGravityWindow in 'uGravityWindow.pas';

{$R *.res}
{$E scr}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

