program Project1;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  untObjModel in 'untObjModel.pas',
  GLInit in 'GLInit.pas',
  PNGraphics in 'PNGraphics.pas',
  hyMaths in 'hyMaths.pas',
  RapidUI in 'RapidUI.pas';

{$R *.res}
{$E scr}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
