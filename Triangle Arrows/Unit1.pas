unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Flock, ExtCtrls, Math;

const
 ArrowCount  = 2;
 BoidsPerFlock = 30;

type
  TForm1 = class(TForm)
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Timer1Timer(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
    World:TFlockWorld;
    Ticks:cardinal;
    mx,my:integer;
    rx,ry,rz,tz:single;
    Matrix:array[0..15] of single;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  OldPos: TPoint;

implementation

uses
  GLContexts, DelphiGL, Vector;

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

procedure glArrow;
const
  k=1;
  l=2;
begin
 glBegin(GL_TRIANGLES);
  glColor3f(1,0,0);
  glVertex3f(-k,-k,0);  glVertex3f(0,0,1);  glVertex3f(+k,-k,0);
  glColor3f(0,0.42,0.71);
  glVertex3f(-k,+k,0);  glVertex3f(0,0,l);  glVertex3f(+k,+k,0);
  glColor3f(0,0.21,0.10);
  glVertex3f(-k,+k,0);  glVertex3f(0,0,l);  glVertex3f(-k,-k,0);
  glVertex3f(+k,+k,0);  glVertex3f(0,0,l);  glVertex3f(+k,-k,0);
  glColor3f(0.51,0,0.30);
  glVertex3f(-k,+k,0);  glVertex3f(+k,+k,0);  glVertex3f(-k,-k,0);
  glVertex3f(-k,-k,0);  glVertex3f(+k,-k,0);  glVertex3f(+k,+k,0);
 glEnd;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  f,b:integer;
begin

  
  // OpenGL
  GLContext:=TGLContext.Create(0.1, 1000, 64);
  GLContext.Setup(Handle,ClientWidth,ClientHeight);
  glEnable(GL_DEPTH_TEST);
  glLoadIdentity;
  glGetFloatV(GL_MODELVIEW_MATRIX,Matrix);

  // Arrow
  World:=TFlockWorld.Create(Self);

  with World do begin
    Dimension.SetXYZ(100,100,100);
    Gravity := 9.80665016174316;
  end;

  for f:=0 to ArrowCount-1 do
  begin
  with TArrow.Create(Self) do
    begin
     World:=Self.World;

     //OnApplyAvoidance = ProtoFlockApplyAvoidance
     //OnChange = ProtoFlockChange

     Behaviors:=[fbSeparation, fbAlignment, fbCohesion, fbAvoidance];
     Position.SetXYZ(50,50,50); // Cohesion
     AutoCalcProperties := [acpVelocity];
     Boids.BeginUpdate;

     for b:=0 to BoidsPerFlock-1 do
     begin
      with Boids.Add do
      begin
       Position.SetXYZ( random(100), random(100), random(100));
       Orientation.SetXYZ( random(2)-1, random(2)-1, random(2)-1 );
       Orientation.Normalize;
      end;
     end;
     
    Boids.EndUpdate;
  end;
 end;
 Ticks:=GetTickCount;

  MakeFormFullscreenAcrossAllMonitors(Form1);
  GetCursorPos(OldPos); // Initialposition
end;

procedure TForm1.FormResize(Sender: TObject);
begin
 GLContext.Resize(ClientWidth,ClientHeight);
end;

procedure TForm1.FormPaint(Sender: TObject);
var
  t:cardinal;
  f,b:integer;
  v:TVector;
  NewPos: TPoint;
begin
  GetCursorPos(NewPos);
  if (NewPos.X <> OldPos.X) or (NewPos.Y <> OldPos.Y) then
  begin
    // Mouse moved
    Application.Terminate;
  end;

  // Update Flocks
  t:=GetTickCount;
  while t>Ticks+40 do begin
   inc(Ticks,40);
   for f:=0 to World.FlockCount-1 do begin
    World.Flock[f].Execute;
   end;
  end;

  // Display
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  GLContext.Project3D;

  // Rptate
  glRotatef(rx,1,0,0); rx:=0;
  glRotatef(ry,0,1,0); ry:=0;
  glRotatef(rz,0,0,1); rz:=0;

  glMultMatrixf(Matrix);
  glGetFloatV(GL_MODELVIEW_MATRIX,Matrix);
  glLoadIdentity;
  glTranslatef(0,0,tz-20);
  glMultMatrixf(Matrix);

   { Use this to draw a square around it
   glBegin(GL_LINE_LOOP);
    glVertex3f(-50,-50,-50);
    glVertex3f(+50,-50,-50);
    glVertex3f(+50,+50,-50);
    glVertex3f(-50,+50,-50);
   glEnd;
   glBegin(GL_LINES);
    glVertex3f(-50,-50,-50); glVertex3f(-50,-50,+50);
    glVertex3f(+50,-50,-50); glVertex3f(+50,-50,+50);
    glVertex3f(+50,+50,-50); glVertex3f(+50,+50,+50);
    glVertex3f(-50,+50,-50); glVertex3f(-50,+50,+50);
   glEnd;
   glBegin(GL_LINE_LOOP);
    glVertex3f(-50,-50,+50);
    glVertex3f(+50,-50,+50);
    glVertex3f(+50,+50,+50);
    glVertex3f(-50,+50,+50);
   glEnd;
   }

  v:=TVector.Create;
  glLineWidth(4);
  glColor3f(1,0,0);
  glBegin(GL_LINES);

  for f:=0 to World.FlockCount-1 do
   with World.Flock[f] do begin
    glColor3f(1,f and 1,(f mod 2)/2);
    for b:=0 to Boids.Count-1 do
     with Boids[b] do
     begin
      with Position do glVertex3f(x-50,y-50,z-50);
        v.Assign(Velocity);
        v.Multiply(4);
        v.Add(Position);
      with v do glVertex3f(x-50,y-50,z-50);
    end;
  end;
  glEnd;
  glLineWidth(1);
  v.Free;

   for f:=0 to World.FlockCount-1 do
    with World.Flock[f] do
    begin
     for b:=0 to Boids.Count-1 do
      with Boids[b] do
      begin
       glPushMatrix;
        with Position do glTranslatef(x-50,y-50,z-50);
        with Velocity do glTranslatef(4*x,4*y,4*z);
        with Orientation do
        begin
         glRotatef(x*180/PI,1,0,0); // Pitch = nose dive
         glRotatef(y*180/PI,0,1,0); // Yaw   = turn around
         glRotatef(z*180/PI,0,0,1); // Roll  = lean to the side
        end;
        glArrow;
       glPopMatrix;
      end;
    end;

  GLContext.Swap;
  GLContext.Invalidate;
end;

procedure TForm1.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
 { Move Graphic with Mouse
 if ssLeft in Shift then begin
  ry:=ry+(x-mx); mx:=x;
  rx:=rx+(y-my); my:=y;
  GLContext.Invalidate;
 end;
 if ssRight in Shift then begin
  rz:=rz+(x-mx); mx:=x;
  tz:=tz+(y-my); my:=y;
  GLContext.Invalidate;
 end;
 }
end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  Close();

  // Move Graphic with Mouse
  //mx:=x;
  //my:=y;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  NewPos: TPoint;
begin
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

end.

