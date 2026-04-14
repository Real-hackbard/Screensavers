program Project1;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Torus in 'Torus.pas',
  Utils in 'Utils.pas';

{$R *.RES}
{$E scr}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
