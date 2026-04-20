unit Unit1;

interface

uses
  Windows, OpenGLForm, OpenGL, Forms, BMP, Vectors, SysUtils, Math,
  Classes, ExtCtrls;

type
  TForm1 = class(TOpenGLWindow)
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure Timer1Timer(Sender: TObject);
  end;

const
  DETX           = 100;                    { Resolution }
  DETY           = 20;

  TWIST          = 5.0;                    { Twist ammount }
  TLENGTH        = 5.0;                    { Tunnel length }
  RADIUS         = 0.4;                    { Radius of the tube }
  LOOKAHEAD      = 0.1;                    { How far to look ahead }
  SPEED          = 2.0;                    { The speed we move along the tunnel }
                                           
var                                        
  Tex: GLuInt;                             { Texture ID }

  Timer: Single;                           { Timer stuff }
  Time, OldTime: DWORD;

  Ctrl: array[0..3] of TVector;            { Control points }
  Data: array[0..DETX] of TVector;         { Tunnel data }

var
  Form1: TForm1;
  OldPos: TPoint;

implementation

{$R *.DFM}
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

{ Interpolate using Double Linear smoothing }
function Interpolate(P1, P2, P3, Amt: Single): Single;
begin
  Result := (P1 + (P2 - P1) * Amt) * (1 - Amt * Amt) +
            (P2 + (P3 - P2) * (Amt - 1)) * Amt * Amt;
end;

{ Interpolate to find a position along the tunnel }
function InterpolateAlongPath(Amt: Single): TVector;
var
  Pt: Integer;
begin
  Pt := Trunc(Amt);
  Result[0] := Interpolate(Ctrl[Pt][0], Ctrl[Pt + 1][0],
    Ctrl[Pt + 2][0], Frac(Amt));
  Result[1] := Interpolate(Ctrl[Pt][1], Ctrl[Pt + 1][1],
    Ctrl[Pt + 2][1], Frac(Amt));
  Result[2] := Amt * TLENGTH;
end;

{ Render a point on the tunnel }
procedure RenderPoint(I, J: Integer);
var
  Di: TVector;
  Pos: TVector;
  X, Y: TVector;
  Angle: Single;
begin
  Pos := Data[I];

  Di := vtrSubtract(Data[I + 1], Data[I]);

  X := vtr(0, 1, 0);
  Y := vtrCross(Di, X);
  X := vtrCross(Di, Y);

  X := vtrNormalize(X);
  Y := vtrNormalize(Y);

  Angle := J / DETY * Pi * 2.0;

  Pos := vtrAdd(Pos,
    vtrMult(X, Cos(Angle) * RADIUS));
  Pos := vtrAdd(Pos,
    vtrMult(Y, Sin(Angle) * RADIUS));

  glTexCoord2f(I / DETX * 10.0, J / DETY * 4.0);
  glVertex3f(Pos[0], Pos[1], Pos[2]);
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  MakeFormFullscreenAcrossAllMonitors(Form1);
  GetCursorPos(OldPos); // Initialposition
  Randomize;

  { Get the initial time }
  Time := GetTickCount;

  { Set up the control points }
  for I := 0 to High(Ctrl) do
  begin
    Ctrl[I][0] := Random * TWIST;
    Ctrl[I][1] := Random * TWIST;
  end;

  { Load the texture }
  glEnable(GL_TEXTURE_2D);
  LoadBMP(ExtractFilePath(Application.ExeName) + 'RASTER.bmp', Tex);

  { Set up fog }
  glEnable(GL_FOG);
  glFogi(GL_FOG_MODE, GL_LINEAR);
  glFogf(GL_FOG_START, 1.0);
  glFogf(GL_FOG_END, 5.0);

  { Set up depth testing }
  glEnable(GL_DEPTH_TEST);
  glDepthFunc(GL_LEQUAL);
end;

procedure TForm1.FormPaint(Sender: TObject);
var
  I, J: Integer;
  P1, P2: TVector;
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  glLoadIdentity;

  { Update the timer }
  OldTime := Time;
  Time := GetTickCount;
  Timer := Timer + (Time - OldTime) /
    10000.0 * SPEED;

  if Timer >= 1.0 then
  begin
    { Shift all the control points along }
    for I := 0 to High(Ctrl) - 1 do
      Ctrl[I] := Ctrl[I + 1];
    { Set the new control point }
    Ctrl[High(Ctrl)][0] := Random * TWIST;
    Ctrl[High(Ctrl)][1] := Random * TWIST;
    { Reset the timer }
    Timer := Frac(Timer);
  end;

  { Set up the tunnel data }
  for I := 0 to DETX do
  begin
    Data[I] := InterpolateAlongPath(I / DETX * 2.0);
  end;

  { Set up the camera }
  P1 := InterpolateAlongPath(Timer);
  P2 := InterpolateAlongPath(Timer + LOOKAHEAD);
  gluLookAt(P1[0], P1[1], P1[2],
    P2[0], P2[1], P2[2], 0, 1, 0);

  { Select the correct texture }
  glBindTexture(GL_TEXTURE_2D, Tex);

  { Render the tunnel }
  for I := 0 to DETX - 2 do
  begin
    glBegin(GL_QUAD_STRIP);
    for J := 0 to DETY do
    begin
      RenderPoint(I, J);
      RenderPoint(I + 1, J);
    end;
    glEnd;
  end;

  DoSwapBuffers;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  if ClientHeight = 0 then ClientHeight := 1;
  glViewport(0, 0, ClientWidth, ClientHeight);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  gluPerspective(45, ClientWidth / ClientHeight, 0.01, 10.0);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
end;

procedure TForm1.FormKeyPress(Sender: TObject; var Key: Char);
begin
  Close();
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  NewPos: TPoint;
begin
  GetCursorPos(NewPos);
  if (NewPos.X <> OldPos.X) or (NewPos.Y <> OldPos.Y) then
  begin
    // Mouse moved
    Close();
  end;
end;

end.
