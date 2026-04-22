unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, TFrustumClass, dglOpenGL, ExtCtrls, AppEvnts, StdCtrls, Math;

type
  TForm1 = class(TForm)
    ApplicationEvents1: TApplicationEvents;
    FPSTimer: TTimer;
    BubbleTimer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
    procedure FPSTimerTimer(Sender: TObject);
    procedure BubbleTimerTimer(Sender: TObject);
    procedure FormClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
  public
    RC : HGLRC;
    DC : HDC;
  end;

var
  Form1       : TForm1;
  Sphere      : array of record
                 x,y,z,Radius : Single;
                 R,G,B        : Single;
                 Speed        : Single;
                end;
  Frames      : Integer;
  Cnt         : Integer;
  FrustumCull : Boolean;
  Anim        : Boolean;
  OldPos      : TPoint;

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

procedure SpawnSpheres(pNum : Integer);
var
 i : Integer;
begin
  SetLength(Sphere, pNum);
  for i := 0 to High(Sphere) do
   with Sphere[i] do
   begin
    x      := Random(10000)/100-Random(10000)/100;
    y      := Random(10000)/100-Random(10000)/100;
    z      := Random(10000)/100-Random(10000)/100;
    r      := Random;
    g      := Random;
    b      := Random;
    Speed  := Random;
    Radius := Random;
   end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  MakeFormFullscreenAcrossAllMonitors(Form1);
  GetCursorPos(OldPos); // Initialposition

  FrustumCull := True;
  Anim        := True;
  InitOpenGL;
  DC := GetDC(Form1.Handle);
  RC := CreateRenderingContext(DC, [opDoubleBuffered], 32, 24, 0, 0, 0, 0);
  ActivateRenderingContext(DC, RC);
  glClearColor(0,0,0,0);
  glEnable(GL_NORMALIZE);
  glEnable(GL_LIGHTING);
  glEnable(GL_DEPTH_TEST);
  SpawnSpheres(2000);
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  DeactivateRenderingContext;
  DestroyRenderingContext(RC);
  ReleaseDC(Handle, DC);
end;

procedure TForm1.ApplicationEvents1Idle(Sender: TObject;  var Done: Boolean);
var
  Q : PGLUQuadric;
  i : Integer;
begin
  if Length(Sphere) = 0 then exit;

  Done := False;
  Cnt  := 0;
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  glViewport(0, 0, Form1.ClientWidth, Form1.ClientHeight);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  gluPerspective(45, Form1.ClientWidth/Form1.ClientHeight, 0.1, 1024);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glEnable(GL_LIGHT0);
  glEnable(GL_LIGHTING);
  glEnable(GL_COLOR_MATERIAL);
  glTranslatef(0,0,-100);

  Frustum.Calculate;

  Q := gluNewQuadric;
  for i := 0 to High(Sphere) do
   with Sphere[i] do
    if Frustum.IsSphereWithin(x,y,z,Radius) or not FrustumCull then
     begin
       glPushMatrix;
        glColor3f(r,g,b);
        glTranslatef(x,y,z);
        gluSphere(Q, Radius, 16, 16);
       inc(Cnt);
       glPopMatrix;
     end;

  SwapBuffers(DC);
  inc(Frames);
  gluDeleteQuadric(Q);
end;

procedure TForm1.FPSTimerTimer(Sender: TObject);
var
  NewPos: TPoint;
begin
  GetCursorPos(NewPos);
  if (NewPos.X <> OldPos.X) or (NewPos.Y <> OldPos.Y) then
  begin
    // Mouse moved
    Application.Terminate;
  end;

  // fps output
  // Caption := +IntToStr(Frames)+' FPS';
  // Label1.Caption := 'Spheres  drawn : '+IntToStr(Cnt)+
  //                   ' ('+IntToStr(Round(Cnt/Length(Sphere)*100))+'%)';
  Frames := 0;
end;

procedure TForm1.BubbleTimerTimer(Sender: TObject);
var
  i : Integer;
begin
  if not Anim then exit;

  for i := 0 to High(Sphere) do
   with Sphere[i] do
    begin
      y := y + 0.25*Speed;
      x := x+(Random-Random)/5;
      if y > 150 then
       begin
         x      := Random(10000)/100-Random(10000)/100;
         y      := -75;
         z      := Random(10000)/100;
         r      := Random;
         g      := Random;
         b      := Random;
         Speed  := Random;
         Radius := Random;
       end;
   end;
end;

procedure TForm1.FormClick(Sender: TObject);
begin
  Close();
end;

procedure TForm1.FormKeyPress(Sender: TObject; var Key: Char);
begin
  Close();
end;

end.
