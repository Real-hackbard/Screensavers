unit Unit1;

interface

uses
  Windows, OpenGLForm, OpenGL, Forms, Graphics, SysUtils, Math, Classes,
  ExtCtrls;

type
  TForm1 = class(TOpenGLWindow)
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  end;

var
  Form1: TForm1;

const
  MaxCube = 3;

var
  Render: GLuInt;                     { Display list }

  Step: Single;                       { Used to calculate the camera position }
  Time, OldTime: Single;

  Direction: (X, Y, Z);               { The direction the camera is moving in }
  Src, Dst: array[0..2] of Integer;   { The source and destination positions }

  dX: Integer = 1;                    { Direction to move on each axis }
  dY: Integer = 1;                    { 1 = move forwards }
  dZ: Integer = 1;                    { 2 = move backwards }

  OldPos: TPoint;

procedure glGenTextures(N: GLSizei; Textures: PGLuInt); stdcall; external OpenGL32;
procedure glBindTexture(Target: GLEnum; Texture: GLuInt); stdcall; external OpenGL32;
procedure glCopyTexImage2D(Target: Cardinal; Level: Integer; Format: Cardinal;
          X, Y, Width, Height, Border: Integer); stdcall; external OpenGL32;
procedure glCopyTexSubImage2D(Target: Cardinal; Level, XOffset, YOffset,
          X, Y, Width, Height: Integer); stdcall; external OpenGL32;
function gluBuild2DMipmaps(Target: Cardinal; Components, Width, Height: Integer;
          Format, AType: Cardinal; const Data: Pointer): Integer; stdcall;
            external 'glu32.dll';

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

{ Create the display list which renders the
  cube field }

procedure InitShapes;
var
  I, J, K: Integer;

  { Render a single cube with normals }

  procedure RenderCube;
  begin
    glBegin(GL_QUADS);
    glNormal3f(1.0, 0.0, 0.0);
    glTexCoord2f(0.0, 0.0); glVertex3f(0.40, 0.00,  0.00);
    glTexCoord2f(1.0, 0.0); glVertex3f(0.40, 0.40,  0.00);
    glTexCoord2f(1.0, 1.0); glVertex3f(0.40, 0.40,  0.40);
    glTexCoord2f(0.0, 1.0); glVertex3f(0.40, 0.00,  0.40);

    glNormal3f(-1.0, 0.0, 0.0);
    glTexCoord2f(0.0, 1.0); glVertex3f(0.00, 0.00, 0.40);
    glTexCoord2f(0.0, 0.0); glVertex3f(0.00, 0.00, 0.00);
    glTexCoord2f(1.0, 0.0); glVertex3f(0.00, 0.40, 0.00);
    glTexCoord2f(1.0, 1.0); glVertex3f(0.00, 0.40, 0.40);

    glNormal3f(0.0, 0.0, -1.0);
    glTexCoord2f(0.0, 1.0); glVertex3f(0.00, 0.40, 0.00);
    glTexCoord2f(1.0, 1.0); glVertex3f(0.40, 0.40, 0.00);
    glTexCoord2f(1.0, 0.0); glVertex3f(0.40, 0.00, 0.00);
    glTexCoord2f(0.0, 0.0); glVertex3f(0.00, 0.00, 0.00);

    glNormal3f(0.0, 0.0, 1.0);
    glTexCoord2f(0.0, 0.0); glVertex3f(0.00, 0.00, 0.40);
    glTexCoord2f(0.0, 1.0); glVertex3f(0.00, 0.40, 0.40);
    glTexCoord2f(1.0, 1.0); glVertex3f(0.40, 0.40, 0.40);
    glTexCoord2f(1.0, 0.0); glVertex3f(0.40, 0.00, 0.40);

    glNormal3f(0.0, 1.0, 0.0);
    glTexCoord2f(0.0, 1.0); glVertex3f(0.40, 0.40, 0.00);
    glTexCoord2f(1.0, 1.0); glVertex3f(0.40, 0.40, 0.40);
    glTexCoord2f(1.0, 0.0); glVertex3f(0.00, 0.40, 0.40);
    glTexCoord2f(0.0, 0.0); glVertex3f(0.00, 0.40, 0.00);

    glNormal3f(0.0, -1.0, 0.0);
    glTexCoord2f(1.0, 1.0); glVertex3f(0.40, 0.00, 0.40);
    glTexCoord2f(1.0, 0.0); glVertex3f(0.00, 0.00, 0.40);
    glTexCoord2f(0.0, 0.0); glVertex3f(0.00, 0.00, 0.00);
    glTexCoord2f(0.0, 1.0); glVertex3f(0.40, 0.00, 0.00);
    glEnd;
  end;

begin
  { Create the display list }

  Render := glGenLists(1);
  glNewList(Render, GL_COMPILE);

  { Draw lots of cubes - we draw more than necessary so
    that when the scene is fogged, the cube field looks
    infinite }

  for I := -3 to MaxCube + 3 do
    for J := -3 to MaxCube + 3 do
      for K := -3 to MaxCube + 3 do begin
        glPushMatrix;

        glTranslatef(I, J, K);              { Translate the cube }
        glTranslatef(-0.75, -0.75, -0.75);  { Shifted slightly so that the camera fits between cubes }
        RenderCube;                         { Render a cube }
        glPopMatrix;
      end;

  glEndList;                                { Close the display list }
end;

{ Load a bitmap as an OpenGL texture }

procedure LoadBMP(Bitmap: TBitmap);
type
  TPixel = array[0..3] of Byte;             { A single pixel represented as an RGBA quad }
var
  X, Y: Integer;
  Src: TPixel;                              { Source pixel }
  Dst: ^TPixel;                             { Destination pixel }
  Data: Pointer;                            { Image data }
begin
  GetMem(Data, Bitmap.Width * Bitmap.Height * 4);   { Assign memory for image }

  Dst := Data;

  for X := 0 to Bitmap.Width - 1 do
    for Y := 0 to Bitmap.Height - 1 do begin
      Src := TPixel(Bitmap.Canvas.Pixels[X, Y]);    { Get a pixel }
      Move(Src, Dst^, 4);                           { Copy the pixel data into memory }
      Inc(Dst);                                     { Move to the next pixel }
    end;

  gluBuild2DMipmaps(GL_TEXTURE_2D, 4, Bitmap.Width, Bitmap.Height, GL_RGBA,
    GL_UNSIGNED_BYTE, Data);                        { Create texture data }

  FreeMem(Data);                                    { Free up memory }
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  Bitmap: TBitmap;
begin
  MakeFormFullscreenAcrossAllMonitors(Form1);
  GetCursorPos(OldPos); // Initialposition

  Bitmap := TBitmap.Create;                         { Load the environment map texture }
  Bitmap.LoadFromFile(ExtractFilePath(Application.ExeName) + 'tex.bmp');
  LoadBMP(Bitmap);
  Bitmap.Free;

  InitShapes;                                       { Create the display list }

  { glViewport(0,0, Screen.DesktopWidth, Screen.DesktopHeight);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluPerspective(50, Width / Height,3,12);
    glMatrixMode(GL_MODELVIEW); }

  glEnable(GL_FOG);                                 { Set up fogging }
  glFogi(GL_FOG_MODE, GL_LINEAR);
  glFogf(GL_FOG_START, 1.0);
  glFogf(GL_FOG_END, 3.0);

  glEnable(GL_LIGHT0);                              { Enable lighting }
  glEnable(GL_LIGHTING);
  glEnable(GL_TEXTURE_2D);                          { Enable texturing }
  glEnable(GL_COLOR_MATERIAL);
  glEnable(GL_TEXTURE_GEN_S);                       { Set up environment mapping }
  glEnable(GL_TEXTURE_GEN_T);
  glTexGeni(GL_S, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP);
  glTexGeni(GL_T, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP);
  glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
  glShadeModel(GL_SMOOTH);
  glEnable(GL_DEPTH_TEST);                          { Set up the depth buffer }
  glDepthFunc(GL_LEQUAL);

end;

procedure TForm1.FormPaint(Sender: TObject);
var
  xPos, yPos, zPos: Single;                         { Camera position }
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  glViewport(0, 0, Width,  Height);

  glLoadIdentity;

  OldTime := Time;                                  { Calculate the time elapsed since the last frame }
  Time := GetTickCount / 4000;
  Step := Step + Time - OldTime;

  if Step >= 1.0 then begin                         { If the camera has finished moving ... }
    Step := 0.0;
    Src := Dst;                                     { Move the source camera position }
    if (Src[0] >= MaxCube) or                       { If the camera is too near the edge then reverse }
      (Src[0] <= 0) then dX := -dX;                 { the direction that it is moving in }
    if (Src[1] >= MaxCube) or
      (Src[1] <= 0) then dY := -dY;
    if (Src[2] >= MaxCube) or
      (Src[2] <= 0) then dZ := -dZ;
    case Direction of                               { Get the new destination }
      X: begin
        Dst[Ord(Y)] := (Dst[Ord(Y)] + dY);
        Dst[Ord(Z)] := (Dst[Ord(Z)] + dZ);
      end;
      Y: begin
        Dst[Ord(X)] := (Dst[Ord(X)] + dX);
        Dst[Ord(Z)] := (Dst[Ord(Z)] + dZ);
      end;
      Z: begin
        Dst[Ord(Y)] := (Dst[Ord(Y)] + dY);
        Dst[Ord(X)] := (Dst[Ord(X)] + dX);
      end;
    end;
    Inc(Direction);                                 { Switch the camera direction }
    if Direction > High(Direction) then
      Direction := Low(Direction);
  end;

  xPos := Src[0] + (Dst[0] - Src[0]) * Step;        { Interpolate to find the new camera position }
  yPos := Src[1] + (Dst[1] - Src[1]) * Step;
  zPos := Src[2] + (Dst[2] - Src[2]) * Step;

  glRotatef(Time * 30.0, 1, 0, 0);                 { Rotate the camera }
  glRotatef(Time * 40.0, 0, 1, 0);
  glRotatef(Time * 50.0, 0, 0, 1);
  glTranslatef(-2.0, -2.0, -2.0);                   { Translate the camera }
  glTranslatef(xPos, yPos, zPos);
  glCallList(Render);                               { Render the cube field }

  DoSwapBuffers;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  if ClientHeight = 0 then ClientHeight := 1;

  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  //glViewport(0, 0, Screen.DesktopWidth, Screen.DesktopHeight);
  gluPerspective(75, Width / Height, 0.1, 100.0);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;

end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  // 1. OpenGL Context deaktivate
  //wglMakeCurrent(0, 0);
end;

procedure TForm1.FormKeyPress(Sender: TObject; var Key: Char);
begin
  Application.Terminate;
end;

procedure TForm1.FormClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  NewPos: TPoint;
begin
  GetCursorPos(NewPos);
  if (NewPos.X <> OldPos.X) or (NewPos.Y <> OldPos.Y) then
  begin
    // Maus moved
    Application.Terminate;
  end;
end;

end.
