unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  OpenGL, Geometry, ExtCtrls, Math;

type
  TForm1 = class(TForm)
    StartTimer: TTimer;
    FPStimer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure StartTimerTimer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure AppMinimize(Sender: TObject);
    procedure AppRestore(Sender: TObject);
    procedure FPStimerTimer(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

const FOV=90;
      matrixdim=40; //dimension of the matrix (larger=>slower but better)

const
      matAmb1:Tvector = (1.04, 0.5, 1.0, 1.0); //ambient material
      matDif1:Tvector = (1.0, 0.0, 0.9, 1.0); //diffuse
      matSpec1:Tvector = (1.0, 1.0, 1.0, 1.0); //specular
      matEm1:Tvector = (1.0, 0.02, 0.1, 1.0); //emission

const
      light0Ambient:tvector = (0.0, 0.09, 0.2, 1.0);
      light0Diffuse:tvector = (0.0, 0.3, 1.0, 1.0);
      light0Specular:tvector = (0.0, 1.0, 1.0, 1.0);
      light0Position:tvector = (matrixdim, matrixdim, matrixdim, 1.0);
      light0spot:taffinevector = (25,0,25);
var
  Form1: TForm1;
  DC: HDC; HRC: HGLRC;
  vendor,renderer,dims: string;
  animate:boolean=false;
  frametime, starttime: cardinal;
  fps: word;
  gcard: string;
  m: array[0..matrixdim-1, 0..matrixdim-1] of GLfloat;
  maxy, scale, delta, phi : GLfloat;
  shininess:glfloat;
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

procedure ResizeViewport(width,height:longint);
{$DEFINE USE_FRUSTUM}
 var znear, zfar, aspect: GLdouble;
{$IFDEF USE_FRUSTUM}
 var top, right, temp: GLdouble;
{$ENDIF}
begin
  znear := 0.3;
  zfar  := 50;
  glViewport(0, 0, width, height);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();

  aspect := width/height;
  {$IFDEF USE_FRUSTUM}
   temp:=FOV/2 * PI/180;
   right := znear * sin(temp)/cos(temp);
   top := right / aspect;
   glFrustum(-right, right, -top, top, znear, zfar);
  {$ELSE}
   gluPerspective(FOV/aspect, aspect, znear, zfar);
  {$ENDIF}
  glMatrixMode(GL_MODELVIEW);
end;

Procedure SetupGL(width,height:longint);
const
  fogcolor: tVector4f= (0.44, 0.0, 0.0, 1.0);
begin
  glClearColor(0.44, 0.0, 0.0, 1.0);
  glClearDepth(1.0);
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  glShadeModel(GL_SMOOTH);
  glDepthFunc(GL_LEQUAL);
  glFrontFace(GL_CCW);
  glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
  glBlendFunc(GL_src_alpha, GL_ONE_MINUS_SRC_ALPHA);
  glAlphaFunc(GL_GEQUAL, 0.05);

  glenable(GL_COLOR_MATERIAL);
  glenable(GL_DEPTH_TEST);
  gldisable(GL_CULL_FACE);
  glenable(GL_BLEND);
  gldisable(GL_ALPHA_TEST);
  glenable(GL_LIGHTING);
  glEnable(gl_normalize);

  glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
  glHint(GL_FOG_HINT, GL_NICEST);
  //glPolygonOffset(-0.9, 0.0025);

  glFogi(GL_FOG_MODE, GL_linear);
  glFogfv(GL_FOG_COLOR, @fogcolor);
  glFogf(GL_FOG_DENSITY, 1);
  glFogf(GL_FOG_START, matrixdim/3);
  glFogf(GL_FOG_END, matrixdim/1.5);
  glenable(GL_FOG);
  ResizeViewport(width, height);
end;

procedure initmatrix;
var
  tmp1,tmp2: glFloat;
  i,j: word;
begin
  scale:=7;
  for i:=0 to matrixdim-1 do
   for j:=0 to matrixdim-1 do
    begin
    tmp1:=(i-matrixdim/2)*(i-matrixdim/2);
    tmp2:=(j-matrixdim/2)*(j-matrixdim/2);
    m[i,j]:=scale*(3.1416/matrixdim)*sqrt(tmp1+tmp2);
    end;
end;

procedure MainLoop;
var
  x,z: word;
  vec1,vec2,vec3: TAffineVector;
  y1,y2,y3,y4,y5,y6,y7,y8,y9,y10,y11,y12: GLfloat;

begin
  repeat
   starttime:=gettickcount;
   glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

   phi:=delta*0.31416;

   for z:=0 to matrixdim-3 do
    for x:=0 to matrixdim-3 do
     begin
     y1:=sin(m[z,x]-phi);
     y2:=sin(m[z+1,x]-phi);
     y3:=sin(m[z+1,x+1]-phi);
     y4:=sin(m[z,x+1]-phi);

     if x>0 then
      begin
      y5:=sin(m[z, x-1]-phi);
      y6:=sin(m[z+1, x-1]-phi);
      end
     else
      begin
      y5:=y1;
      y6:=y2;
      end;

     y7:=sin(m[z+2, x]-phi);
     y8:=sin(m[z+2, x+1]-phi);
     y9:=sin(m[z+1, x+2]-phi);
     y10:=sin(m[z, x+2]-phi);

     if z>0 then
      begin
      y11:=sin(m[z-1, x+1]-phi);
      y12:=sin(m[z-1, x]-phi);
      end
     else
      begin
      y11:=y4;
      y12:=y1;
      end;


     glBegin(GL_QUADS);

  // Turn off lighting and uncomment the following glColors for alternate 'lighting'
     glColor3f((y1+1)/2+0.4, (y1+1)/2+0.4, (y1+1)/2+0.4);

  //for each vertex, compute an 'average' normal.
     vec1[0]:=2;
     vec1[1]:=y5-y4;
     vec1[2]:=0;
     vec2[0]:=0;
     vec2[1]:=y12-y2;
     vec2[2]:=2;
     VectorNormalize(vec2);
     vec3:=VectorPerpendicular(vec1,vec2);
     glNormal3fv(@vec3);
     glVertex3f(x, y1, z);

  //  glColor3f((y2+1)/2+0.4, (y2+1)/2+0.4, (y2+1)/2+0.4);
     vec1[0]:=2;
     vec1[1]:=y6-y3;
     vec1[2]:=0;
     vec2[0]:=0;
     vec2[1]:=y1-y7;
     vec2[2]:=2;
     VectorNormalize(vec2);
     vec3:=VectorPerpendicular(vec1,vec2);
     glNormal3fv(@vec3);
     glVertex3f(x, y2, z+1);

  //   glColor3f((y3+1)/2+0.4, (y3+1)/2+0.4, (y3+1)/2+0.4);
     vec1[0]:=2;
     vec1[1]:=y2-y9;
     vec1[2]:=0;
     vec2[0]:=0;
     vec2[1]:=y4-y8;
     vec2[2]:=2;
     VectorNormalize(vec2);
     vec3:=VectorPerpendicular(vec1,vec2);
     glNormal3fv(@vec3);
     glVertex3f(x+1, y3, z+1);

  //   glColor3f((y4+1)/2+0.4, (y4+1)/2+0.4, (y4+1)/2+0.4);
     vec1[0]:=2;
     vec1[1]:=y1-y10;
     vec1[2]:=0;
     vec2[0]:=0;
     vec2[1]:=y11-y3;
     vec2[2]:=2;
     VectorNormalize(vec2);
     vec3:=VectorPerpendicular(vec1,vec2);
     glNormal3fv(@vec3);
     glVertex3f(x+1, y4, z);
     glEnd;
     end;

   glFinish;
   SwapBuffers(DC);
   frametime:=gettickcount-starttime;
   delta:=delta+(frametime*3.1416*5)/1000;
   if delta>20.0 then delta:=0.0;
   inc(fps);
   Application.ProcessMessages;
  until not animate;
end;

procedure StartAnimation;
begin
  animate:=true;
  Form1.FPStimer.Enabled:=true;
  MainLoop;
end;

procedure initlights;
begin
  glLightfv(GL_LIGHT0, GL_AMBIENT, @light0Ambient);
  glLightfv(GL_LIGHT0, GL_DIFFUSE, @light0Diffuse);
  glLightfv(GL_LIGHT0, GL_SPECULAR, @light0Specular);
  glLightfv(GL_LIGHT0, GL_POSITION, @light0Position);
  //glLighti(GL_LIGHT0, GL_SPOT_CUTOFF, 90);
  //glLighti(GL_LIGHT0, GL_SPOT_EXPONENT, 5);
  //glLightfv(GL_LIGHT0, GL_SPOT_DIRECTION, @light0spot);
  glLightModelf(GL_LIGHT_MODEL_LOCAL_VIEWER, 1.0);
  glEnable(GL_LIGHT0);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  if not InitOpenGL then halt(1);
  MakeFormFullscreenAcrossAllMonitors(Form1);
  GetCursorPos(OldPos); // Initialposition

  DC := GetDC(handle);
  HRC:=CreateRenderingContext(DC,[opDoubleBuffered],32,0);
  ActivateRenderingContext(DC,HRC);
  SetupGL(Width, Height);

  dims:=inttostr(clientwidth)+'/'+inttostr(clientheight);
  renderer:=StrPas(PChar(glGetString(GL_renderer)));
  vendor:=StrPas(PChar(glGetString(GL_vendor)));
  gcard:=vendor+' '+renderer+' '+dims+' fps: ';
  caption:=gcard;

  Initmatrix;
  delta:=0.0;
  Application.OnMinimize:= AppMinimize;
  Application.OnRestore:= AppRestore;

  shininess:=16;
  glMaterialfv(GL_FRONT, GL_AMBIENT, @matAmb1);
  glMaterialfv(GL_FRONT, GL_DIFFUSE, @matDif1);
  glMaterialfv(GL_FRONT, GL_SPECULAR, @matSpec1);
  glMaterialfv(GL_FRONT, GL_EMISSION, @matEm1);
  glMaterialfv(GL_FRONT, GL_SHININESS, @shininess);

  glScalef(0.85, 0.6, 0.45);
  Initlights;
  gluLookAt(matrixdim/2, 15, 1.36*matrixdim, matrixdim/2, 0, 0, 0,1,0);
  //glRotatef(10, 1, 0, 0);
  //glTranslatef(-matrixdim/2, -6, -1.35*matrixdim);
  StartTimer.Enabled:=true;
end;

procedure TForm1.AppMinimize(Sender: TObject);
begin
  Animate:=false;
  Form1.FPStimer.Enabled:=false;
end;

procedure TForm1.AppRestore(Sender: TObject);
begin
  StartAnimation;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  resizeviewport(Width, Height);
  dims:=inttostr(clientwidth)+'/'+inttostr(clientheight);
  gcard:= vendor+' '+renderer+' '+dims+' fps: ';
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  DestroyRenderingContext(hrc);
  CloseOpenGL;
end;

procedure TForm1.StartTimerTimer(Sender: TObject);
begin
  StartTimer.Enabled:=false;
  StartAnimation;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  animate:=false;
  Form1.FPStimer.Enabled:=false;
  Action:=caFree;
end;

procedure TForm1.FPStimerTimer(Sender: TObject);
var
  NewPos: TPoint;
begin
  GetCursorPos(NewPos);
  if (NewPos.X <> OldPos.X) or (NewPos.Y <> OldPos.Y) then
  begin
    // Mouse moved
    Close();
  end;

  caption:=gcard+inttostr(fps);
  fps:=0;
end;

procedure TForm1.FormKeyPress(Sender: TObject; var Key: Char);
begin
  Close();
end;

end.
