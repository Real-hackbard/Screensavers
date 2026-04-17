unit Unit1;

interface

uses
   ShellApi, Messages, Windows, SysUtils, Classes, Controls, Forms,
   StdCtrls, Graphics, ExtCtrls, Math;

type
   TForm1 = class(TForm)
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Timer1Timer(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
   private
    { Private-Deklarationen}
  public
    { Public-Deklarationen}
   end;

var
   Form1: TForm1;
   Fond : TBitMap;
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

Procedure CaptureScreen(Bmp :TBitMap);
var
 c :TCanvas;
 r :TRect;
begin
   c := TCanvas.Create;
   c.Handle := GetWindowDC (GetDesktopWindow);
   try
      r := Rect(0,0,screen.Desktopwidth,screen.Desktopheight);
      Bmp.Width := screen.DesktopWidth;
      Bmp.Height := screen.DesktopHeight;
      Bmp.Canvas.CopyRect(r, c, r);
   finally
      ReleaseDC(0, c.handle);
      c.Free;
   end;
end;         

procedure TForm1.FormCreate(Sender: TObject);
begin
  GetCursorPos(OldPos); // Initial position
  // we create the bitmap
  Fond := TBitMap.Create;
  // we put our capture in this one
  CaptureScreen(Fond);
  // We put the bitmap in the background of the window
  Form1.Brush.Bitmap := Fond;
  // We put the window in the ALWAYS ABOVE position (fsStayOnTop isn't great)
  SetWindowPos(Form1.handle, HWND_TOPMOST, 0,0,width, height,SWP_NOMOVE);

  // We activate the timer
  Timer1.Enabled := True;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
  begin
  // we release the bitmap
   Fond.Free;
  end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  Close();
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  x, y:integer;
  NewPos: TPoint;
begin
  GetCursorPos(NewPos);
  if (NewPos.X <> OldPos.X) or (NewPos.Y <> OldPos.Y) then
  begin
    // Maouse moved
    Close();
  end;

  // random values ??are assigned to x and y, max 5
  randomize;
  x := random(5);
  y := random(5);

  // we reposition the window
  left := x;
  top := y;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  MakeFormFullscreenAcrossAllMonitors(Form1);
end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  Close();
end;

end.

