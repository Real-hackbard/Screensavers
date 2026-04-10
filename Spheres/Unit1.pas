unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, AppEvnts, ExtCtrls, Buttons, Math;

type
  TScrMode = (scrNormal, scrApercu, scrPreview, scrConfig);

type
  TForm1 = class(TForm)
    Timer1: TTimer;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormCreate(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ApplicationEvents1Deactivate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    function COLOR_CHANGE(Color:TColor; incR, incG, incB: Integer):TColor;
  public
    { Public declarations }
    procedure DRAW_SCR;
  end;

var
  Form1: TForm1;
  ScreenMode: TScrMode;
  PreviewHandle: hwnd=0;
  MaxD: Word;
  Cont: Boolean;

implementation

{$R *.dfm}
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
  Randomize;
  Cont := True;

  if ScreenMode = scrPreview
  then MaxD :=  20
  else MaxD := 250;

  // We hide the application in the taskbar
  SetWindowLong(Application.Handle, GWL_EXSTYLE, WS_EX_TOOLWINDOW);
end;

procedure TForm1.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if ScreenMode in [scrNormal, scrApercu]
  then Close;
end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if ScreenMode in [scrNormal, scrApercu]
  then Close;
end;

// Warning: This can be executed more than once!
procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  Cont := False;
  CanClose := True;
end;

// Warning: This can be executed more than once!
procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TForm1.ApplicationEvents1Deactivate(Sender: TObject);
begin
  Close;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  DRAW_SCR;
end;

procedure TForm1.DRAW_SCR;
var x, y, d: Integer;
begin
  d := RandomRange(5, MaxD);
  x := RandomRange((-1) * (MaxD Div 2), Form1.Width);
  y := RandomRange((-1) * (MaxD Div 2), Form1.Height);

  Canvas.Brush.Color := RandomRange(clBlack, clBlue);
  Canvas.Pen.Color := Canvas.Brush.Color;
  Canvas.Ellipse(x, y, x+d, y+d);

  while (d > 2) And (Cont) do  // Gradient ...
  begin
    x := x + 1;
    y := y + 1;
    d := d - 2;

    if d < 10
    then Canvas.Brush.Color := COLOR_CHANGE(Canvas.Brush.Color, 10, 10, 10)
    else Canvas.Brush.Color := COLOR_CHANGE(Canvas.Brush.Color, 2, 2, 2);

    Canvas.Pen.Color := Canvas.Brush.Color;
    Canvas.Ellipse(x, y, x+d, y+d);
  end;
end;

function TForm1.COLOR_CHANGE(Color:TColor; incR, incG, incB: Integer):TColor;
var r,g,b: Integer;
begin
  Color:= ColorToRGB(Color);

  r:= GetRValue(Color);
  g:= GetGValue(Color);
  b:= GetBValue(Color);

  r := r + incR;
  g := g + incG;
  b := b + incB;

  If r < 0 Then r := 0; If r > 255 Then r := 255;
  If g < 0 Then g := 0; If g > 255 Then g := 255;
  If b < 0 Then b := 0; If b > 255 Then b := 255;

  RESULT := RGB(r,g,b);
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  MakeFormFullscreenAcrossAllMonitors(Form1);
end;

end.
