unit Unit1;

interface

uses
  OpenGL, Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, Math;

type
  plane_point = record
    x, y, h : GlFloat;
  end;
  plane = array[0..3] of plane_point;
  TForm1 = class(TForm)
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure DrawGLScene();   //Draws an OpenGL scene on request
    function  wierdsincos(x,y:glfloat):glfloat;
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormClick(Sender: TObject);
  private
    adjust: GLfloat;
    { Private declarations }
  public
    { Public declarations }
  end;

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

procedure setupPixelFormat(DC:HDC);
const
  pfd:TPIXELFORMATDESCRIPTOR = (
	nSize:sizeof(TPIXELFORMATDESCRIPTOR);	            // size
	nVersion:1;				                                // version
	dwFlags:PFD_SUPPORT_OPENGL or PFD_DRAW_TO_WINDOW or
                PFD_DOUBLEBUFFER;		                // support double-buffering
	iPixelType:PFD_TYPE_RGBA;		                      // color type
	cColorBits:16;				                            // prefered color depth
	cRedBits:0; cRedShift:0;		                      // color bits (ignored)
        cGreenBits:0;  cGreenShift:0;
        cBlueBits:0; cBlueShift:0;
        cAlphaBits:0;  cAlphaShift:0;               // no alpha buffer
        cAccumBits: 0;
        cAccumRedBits: 0;  		                      // no accumulation buffer,
        cAccumGreenBits: 0;                         // accum bits (ignored)
        cAccumBlueBits: 0;
        cAccumAlphaBits: 0;
	cDepthBits:16;				                            // depth buffer
	cStencilBits:0;				                            // no stencil buffer
	cAuxBuffers:0;				                            // no auxiliary buffers
	iLayerType:PFD_MAIN_PLANE;                        // main layer
        bReserved: 0;
    dwLayerMask: 0;
    dwVisibleMask: 0;
    dwDamageMask: 0;                      // no layer, visible, damage masks */
    );
var
  pixelFormat:integer;
begin
  pixelFormat := ChoosePixelFormat(DC, @pfd);
  if (pixelFormat = 0) then begin
	MessageBox(WindowFromDC(DC), 'ChoosePixelFormat failed.', 'Error',
		MB_ICONERROR or MB_OK);
	exit;
  end;
  if (SetPixelFormat(DC, pixelFormat, @pfd) <> TRUE) then begin
	MessageBox(WindowFromDC(DC), 'SetPixelFormat failed.', 'Error',
		MB_ICONERROR or MB_OK);
	exit;
  end;
end;

procedure GLInit;
var
  Width, Height : GLsizei;
begin
   Width := Form1.ClientWidth;
   Height := Form1.ClientHeight;
   glShadeModel(GL_SMOOTH);
   glClearColor(0.0, 0.0, 0.0, 0.5);
   glClearDepth(1.0);
   glEnable(GL_DEPTH_TEST);
   glDepthFunc(GL_LEQUAL);
   glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST);
   glViewport(0, 0, Width, Height);
   glMatrixMode(GL_PROJECTION);
   glLoadIdentity();
   gluPerspective(40.0,Width/Height,0.1,100.0);
   glMatrixMode(GL_MODELVIEW);
   glLoadIdentity;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  DC:HDC;
  RC:HGLRC;
begin
 MakeFormFullscreenAcrossAllMonitors(Form1);
 GetCursorPos(OldPos);      // Initialposition

 DrawGLScene;
 DC:=GetDC(Handle);         //Actually, you can use any widowed control here
 SetupPixelFormat(DC);
 RC:=wglCreateContext(DC);  //mache das DC als OpenGL Fenster
 wglMakeCurrent(DC, RC);    //aktiviere OpenGL Fenster
 GLInit;
end;

procedure get_c_place(var inc,h,r1,g1,b1,r2,g2,b2,r,g,b : glfloat);
var
  val : glfloat;
//1 colors is low colors (r1 g1 b1), 2 colors is high (r2 g2 b2)
begin
  val := 0;
  if (h > 0) and (h <= 2) then //blou
      val := h;
  if (h > 2) and (h <= 4) then //groen
      val := h - 2;
  if (h >4) and (h <= 6) then  //geel
      val := h - 4;
  if (h > 6) and (h <= 8) then // oranje
      val := h - 6;
  if r1 > r2 then
    begin
      r := r1 - (((r1 - r2)/inc)*val)
    end;
  if r2 > r1 then
    begin
      r := (((r2 - r1)/inc)*val) + r1;
    end;
  if g1 > g2 then
    begin
      g := g1 - (((g1 - g2)/inc)*val)
    end;
  if g2 > g1 then
    begin
      g := (((g2 - g1)/inc)*val) + g1;
    end;
  if b1 > b2 then
    begin
      b := b1 - (((b1 - b2)/inc)*val)
    end;
  if b2 > b1 then
    begin
      b := (((b2 - b1)/inc)*val) + b1;
    end;
end;

procedure get_c(var r,g,b, h :GlFloat);
var
  rr, gr, br : glfloat;
  rg, gg, bg : glfloat;
  ry, gy, by : glfloat;
  ro, go, bo : glfloat;
  rb, gb, bb : glfloat;
  {r, g, b,} inc : glfloat;
begin
  inc := 2;
 { size := size * 0.25;
  x := (size + 0.05)*x;
  z := (size + 0.05)*-z;
  y := 0;  }
  //koud blou
  rb := 16;
  gb := 115;
  bb := 224;
  //groen
  rg := 20;
  gg := 225;
  bg := 15;
  //Geel
  ry := 222;
  gy := 240;
  by := 0;
  //Oranje
  ro := 233;
  go := 159;
  bo := 7;
  //Rooi
  rr := 255;
  gr := 15;
  br := 15;
  if h > 8 then h := 8;  //maak seker hy is nie out of range nie
  if h <= 0 then h := 0;
  if (h > 0) and (h <= 2) then       //blou
      get_c_place(inc,h,rb,gb,bb,rg,gg,bg,r,g,b);
  if (h > 2) and (h <= 4) then       //groen
      get_c_place(inc,h,rg,gg,bg,ry,gy,by,r,g,b);
  if (h >4) and (h <= 6) then     //geel
      get_c_place(inc,h,ry,gy,by,ro,go,bo,r,g,b);
  if (h > 6) and (h <= 8) then // oranje
      get_c_place(inc,h,ro,go,bo,rr,gr,br,r,g,b);
  r := r /255;
  g := g /255;
  b := b /255;
end;

procedure draw_bar(x,y,z,h,size: GLfloat);
var
  r, g, b : glfloat;
begin
  size := size * 0.25;
  x := (size + 0.05)*x;
  z := (size + 0.05)*-z;
  y := 0;
  get_c(r,g,b,h);
  glLoadIdentity();
  glTranslatef(0,-1.5,-5);
  glRotatef(45.0,0.0,1.0,0.0);
  glRotatef(45.0,1.0,0.0,1.0);
  glTranslatef(x,y,z);
  
  glBegin(GL_QUADS);
    glColor3f(r-0.04,g-0.04,b-0.04);
    glVertex3f(size,0.0,0.0);          //Front face
    glVertex3f(size,size*h,0.0);
    glVertex3f(0.0,size*h,0.0);
    glVertex3f(0.0,0.0,0.0);

    glColor3f(r,g,b);                  // Side face
    glVertex3f(0.0,0.0,0.0);
    glVertex3f(0.0,size*h,0.0);
    glVertex3f(0.0,size*h,-size);
    glVertex3f(0.0,0.0,-size);

    glColor3f(r+0.04,g+0.04,b+0.04);   // Top face
    glVertex3f(0.0,size*h,0.0);
    glVertex3f(0.0,size*h,-size);
    glVertex3f(size,size*h,-size);
    glVertex3f(size,size*h,0.0);
  glEnd();
end;

procedure draw_plane(spot:plane;size : GlFloat);
var
  r, g, b, y ,h : glfloat;
  k, l : integer;
begin
  size := size * 0.285;
  for k := 0 to 4 do
    begin
      spot[k].x := (size*spot[k].x);
      spot[k].y := (size*spot[k].y)*(-1);
    end;
  y := 0;
  glLoadIdentity();
  glTranslatef(0,-1.5,-5);
  glRotatef(45.0,0.0,1.0,0.0);
  glRotatef(45.0,1.0,0.0,1.0);
  glTranslatef(spot[0].x,y,spot[0].y);

  glBegin(GL_QUADS);
    get_c(r,g,b,spot[0].h);
    glColor3f(r,g,b);
    glVertex3f(0.0,size*spot[0].h,0.0);

    get_c(r,g,b,spot[1].h);
    glColor3f(r,g,b);
    glVertex3f(0.0,size*spot[1].h,-size);

    get_c(r,g,b,spot[2].h);
    glColor3f(r,g,b);
    glVertex3f(size,size*spot[2].h,-size);

    get_c(r,g,b,spot[3].h);
    glColor3f(r,g,b);
    glVertex3f(size,size*spot[3].h,0.0);
  glEnd();
end;

function TForm1.wierdsincos(x,y:glfloat):glfloat;
begin
  wierdsincos := 4+ (((4*cos(((11.25*pi*x)/180)-adjust))+
                        (4*sin(((11.25*y*pi)/180)+adjust)))/2);
end;

procedure TForm1.DrawGLScene();
var
  k, l, r: integer;
  h : GLfloat;
  spot : plane;
begin
   glClearColor(0.0,0.0,0.0,0.5);
   glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
   glLoadIdentity();

    for k := 0 to 7 do
         for l := 0 to 7 do
           begin
               begin
                 h := wierdsincos(k,l);
                 if h > 8 then h := h - 8;
                 draw_bar(k,0.0,l,h,1);
               end;
           end;

    for k := 0 to 7 do
         for l := 0 to 7 do
           begin
               begin
                 spot[0].h := wierdsincos(k,l);
                 spot[0].x := k;
                 spot[0].y := l;
                 spot[3].h := wierdsincos(k+1,l);
                 spot[3].x := k + 1;
                 spot[3].y := l;
                 spot[2].h := wierdsincos(k+1,l+1);
                 spot[2].x := k + 1;
                 spot[2].y := l + 1;
                 spot[1].h := wierdsincos(k,l+1);
                 spot[1].x := k;
                 spot[1].y := l + 1;
               end;
             end;


   SwapBuffers(wglGetCurrentDC);
   glLoadIdentity();
end;

procedure TForm1.FormPaint(Sender: TObject);
begin
 DrawGLScene;
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

  adjust := adjust + 0.02;
  DrawGLScene;
end;

procedure TForm1.FormKeyPress(Sender: TObject; var Key: Char);
begin
  Application.Terminate;
end;

procedure TForm1.FormClick(Sender: TObject);
begin
  Application.Terminate;
end;

end.
