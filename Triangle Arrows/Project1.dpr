program Project1;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  GLContexts in 'GLContexts.pas',
  DelphiGL in 'DelphiGL.pas',
  Flock in 'Flock.pas',
  Vector in 'Vector.pas',
  GLTypes in 'GLTypes.pas';

{$R *.res}
{$E scr}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

