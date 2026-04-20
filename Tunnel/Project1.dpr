program Project1;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  BMP in 'BMP.pas',
  Vectors in 'Vectors.pas';

{$R *.Res}
{$E scr}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
