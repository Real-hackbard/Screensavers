program Project1;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  World in 'World.pas',
  BMP in 'BMP.pas';

{$R *.res}
{$E scr}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

