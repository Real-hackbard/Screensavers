unit setup;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons,shellapi;
  
type
  TForm2 = class(TForm)
    Label1: TLabel;
    ScrollBar1: TScrollBar;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    BitBtn1: TBitBtn;
    procedure BitBtn1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

{$R *.DFM}

procedure TForm2.BitBtn1Click(Sender: TObject);

var
ini:system.text;
st: string;
begin
assignfile(ini,'c:\planes.ini');
try
  rewrite (ini);
  try
  str(scrollbar1.position,st);
  writeln (ini,st);
  finally
   closefile(ini);
  end;
 except
     on E:EInouterror do
        showmessage ('IO Error');
  end;
close;
end;

procedure TForm2.FormCreate(Sender: TObject);
var
 ini:system.text;
 st: string;
 sp,c: integer;
begin
assignfile(ini,'planes.ini');
try
  reset (ini);
  try
  readln (ini,st);
  val(st,sp,c);
  if sp>6 then sp:=6;
  if sp=0 then sp:=1;
  scrollbar1.position:=sp;
  finally
   closefile(ini);
  end;
 except
       end;
end;

end.
