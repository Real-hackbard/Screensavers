program Project1;

uses
  Forms,
  sysutils,
  Unit1 in 'Unit1.pas' {Form1},
  setup in 'setup.pas' {Form2};

{$R *.RES}
{$E scr}

begin
  //if copy(lowercase(paramstr(1)),0,2)='/s' then Application.CreateForm(TForm1, Form1);
  //if copy(lowercase(paramstr(1)),0,2)='/c' then Application.CreateForm(TForm2, Form2);

  Application.Initialize;
  Application.Title := '';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
