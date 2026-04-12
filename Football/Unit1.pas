unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Math;

type
  TForm1 = class(TForm)
    Timer1: TTimer;
    Image1: TImage;
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormShow(Sender: TObject);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
  private

    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  px, py, lx, ly:single;
  OldPos: TPoint;

implementation

{$R *.dfm}
{$E scr}
procedure MakeFormFullscreenAcrossAllMonitors(Form: TForm);
begin
  Form.BorderStyle := bsNone;
  Form.WindowState := wsNormal; // Make sure it is not maximized

  // Use the virtual screen boundaries
  Form.Left := 0;
  Form.Top := 0;
  Form.Width := Screen.DesktopWidth;
  Form.Height := Screen.DesktopHeight;

  // Optional: If this still doesn't take precedence over everything,
  // consider the taskbar.
  // or use Form.BringToFront.
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Form1.DoubleBuffered := true;
  GetCursorPos(OldPos); // Initialposition
  px:=10;
  py:=10;
  lx:=10;
  ly:=10;

  Form1.Width := Screen.DesktopWidth;
  MakeFormFullscreenAcrossAllMonitors(Form1);

  Form1.TransparentColor:=true;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  NewPos: TPoint;
begin
  px:=px+lx;
  py:=py+ly;

  Image1.Left:= round (px);
  Image1.Top:= round (py);

  if px > Screen.DesktopWidth - Form1.Image1.Width then
  lx:=-lx;
  if px < 0 then
  lx:=-lx;

  if py > Screen.DesktopHeight - Form1.Image1.Width then
  ly:=-ly;
  if py < 0 then
  ly:=-ly;

  GetCursorPos(NewPos);
  if (NewPos.X <> OldPos.X) or (NewPos.Y <> OldPos.Y) then
  begin
    // Mouse moved
    Application.Terminate;
  end;

end;
procedure TForm1.FormKeyPress(Sender: TObject; var Key: Char);
begin
  Close();
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  MakeFormFullscreenAcrossAllMonitors(Form1);
end;

procedure TForm1.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
  NewPos: TPoint;
begin
  GetCursorPos(NewPos);
  if (NewPos.X <> OldPos.X) or (NewPos.Y <> OldPos.Y) then
  begin
    // Maus hat sich bewegt
    Application.Terminate;
  end;
end;

end.
