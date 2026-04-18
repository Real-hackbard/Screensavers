unit Unit1;

interface

uses
  Windows, OpenGLForm, OpenGL, Forms, BMP, Vectors, Math, Classes, ExtCtrls,
  SysUtils;

type
  TForm1 = class(TOpenGLWindow)
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure Timer1Timer(Sender: TObject);
    procedure FormClick(Sender: TObject);
  end;

var
  Form1: TForm1;
  OldPos: TPoint;

const
  d1 = 20;                        { Torus options }
  d2 = 20;
  w: Single = 0.4;
  r: Single = 0.8;

  NUM_SAMPLES = 20;               { Number of samples }
  BLUR_DISTANCE = 0.6;            { Ammount of blur }

var
  Time: Single;
  Tex: array[0..2] of GLuInt;                  { Texture IDs }
  Nrm: array[0..d1, 0..d2] of TVector;         { Torus data }
  Pos: array[-1..d1+1, -1..d2+1] of TVector;

procedure glGenTextures(N: GLSizei; Textures: PGLuInt); stdcall; external OpenGL32;
procedure glBindTexture(Target: GLEnum; Texture: GLuInt); stdcall; external OpenGL32;
procedure glCopyTexImage2D(Target: Cardinal; Level: Integer;
  Format: Cardinal; X, Y, Width, Height, Border: Integer); stdcall; external OpenGL32;
procedure glCopyTexSubImage2D(Target: Cardinal;
  Level, XOffset, YOffset, X, Y, Width, Height: Integer); stdcall; external OpenGL32;

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

{ Get the position vector of a point on the torus }
function GetVertex(s, t: Single): TVector;
var
  w2: Single;
begin
  w2 := (Cos(s * 4 * Pi + Time * 6.5) +
         Cos(s * 6 * Pi + Time * 7.5) +
         Cos(t * 4 * Pi + Time * 8.5) +
         Cos(t * 6 * Pi + Time * 9.5) + 8.0) / 8.0;

  Result[1] := w * w2 * Sin(s * 2 * Pi);
  Result[2] := w * w2 * Cos(s * 2 * Pi) + r;

  Result[0] := Result[2] * Cos(t * 2 * Pi);
  Result[2] := Result[2] * Sin(t * 2 * Pi);
end;

{ Get the normal at the point (s, t) }
function GetNormal(s, t: Integer): TVector;
var
  V1, V2: TVector;
begin
  V1 := vtrSubtract(Pos[s + 1, t], Pos[s - 1, t]);
  V2 := vtrSubtract(Pos[s, t + 1], Pos[s, t - 1]);
  Result := vtrCross(V1, V2);
  Result := vtrNormalize(Result);
end;

{ Create the torus data }
procedure CreateTorus;
var
  I, J: Integer;
begin
  for I := -1 to d1 + 1 do
    for J := -1 to d2 + 1 do
      Pos[I, J] := GetVertex(I / d1, J / d2);

  for I := 0 to d1 do
    for J := 0 to d2 do
      Nrm[I, J] := GetNormal(I, J);
end;

{ Render the torus data }
procedure RenderTorus;
var
  I, J: Integer;
begin
  for I := 0 to d1 - 1 do begin
    glBegin(GL_QUAD_STRIP);
    for J := 0 to d2 do begin
      glTexCoord2f(I / d1, J / d2);
      glNormal3fv(@Nrm[I, J]);
      glVertex3fv(@Pos[I, J]);

      glTexCoord2f((I + 1) / d1, J / d2);
      glNormal3fv(@Nrm[I + 1, J]);
      glVertex3fv(@Pos[I + 1, J]);
    end;
    glEnd;
  end;
end;

{ Render the torus with environment mapping }
procedure RenderEnvironmentMappedTorus;
begin
  glDisable(GL_BLEND);
  glBindTexture(GL_TEXTURE_2D, Tex[0]);
  RenderTorus;

  glEnable(GL_TEXTURE_GEN_S);
  glEnable(GL_TEXTURE_GEN_T);

  glEnable(GL_BLEND);
  glBindTexture(GL_TEXTURE_2D, Tex[1]);
  RenderTorus;

  glDisable(GL_TEXTURE_GEN_S);
  glDisable(GL_TEXTURE_GEN_T);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  MakeFormFullscreenAcrossAllMonitors(Form1);
  GetCursorPos(OldPos); // Initialposition

  { Set up lighting }
  glEnable(GL_LIGHT0);
  glEnable(GL_LIGHTING);

  { Set up texturing }
  glEnable(GL_TEXTURE_2D);
  LoadBMP(ExtractFilePath(Application.ExeName) + 'Texture.bmp', Tex[0]);
  LoadBMP(ExtractFilePath(Application.ExeName) + 'tex.bmp', Tex[1]);

  { Set up blending }
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE);

  { Set up environment mapping }
  glTexGeni(GL_S, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP);
  glTexGeni(GL_T, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP);

  { Set up depth testing }
  glEnable(GL_DEPTH_TEST);
  glDepthFunc(GL_LEQUAL);
end;

{ Render the image and copy it to a texture }
procedure CreateTexture;
begin
  { Push the attribute stacks }
  glPushAttrib(GL_ALL_ATTRIB_BITS);

  { Set up the viewport }
  glViewport(0, 0, 128, 128);

  { Clear the buffers }
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

  { Set up the matrix stacks }
  glMatrixMode(GL_PROJECTION);
  glPushMatrix;
  glLoadIdentity;
  gluPerspective(45, 1.33, 0.1, 100.0);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glTranslatef(0.0, 0.0, -4.0);
  glRotatef(Time * 30.0, 1, 0, 0);
  glRotatef(Time * 40.0, 0, 1, 0);
  glRotatef(Time * 50.0, 0, 0, 1);

  { Render the environment mapped torus }
  RenderEnvironmentMappedTorus;

  { Restore the matrix stacks }
  glMatrixMode(GL_PROJECTION);
  glPopMatrix;

  glMatrixMode(GL_MODELVIEW);

  { Copy the image to a texture }
  if Tex[2] > 0 then begin
    glBindTexture(GL_TEXTURE_2D, Tex[2]);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glCopyTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 0, 0, 128, 128);
  end else begin
    glGenTextures(1, @Tex[2]);
    glBindTexture(GL_TEXTURE_2D, Tex[2]);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 0, 0, 128, 128, 0);
  end;

  { Restore the attribute stacks }
  glPopAttrib;
end;

procedure TForm1.FormPaint(Sender: TObject);
var
  I: Integer;
  A1, A2: Single;
begin
  { Get the current time }
  Time := GetTickCount / 1000.0;

  glEnable(GL_LIGHTING);
  glEnable(GL_DEPTH_TEST);

  { Create the torus }
  CreateTorus;

  { Create the texture }
  CreateTexture;

  { Clear the buffers }
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  gluPerspective(45, 1.33, 0.1, 100.0);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glTranslatef(0.0, 0.0, -4.0);
  glRotatef(Time * 30.0, 1, 0, 0);
  glRotatef(Time * 40.0, 0, 1, 0);
  glRotatef(Time * 50.0, 0, 0, 1);

  { Render the object as usual }
  RenderEnvironmentMappedTorus;

  glDisable(GL_LIGHTING);
  glDisable(GL_DEPTH_TEST);

  { Select the texture }
  glBindTexture(GL_TEXTURE_2D, Tex[2]);
  glColor4f(1.0, 1.0, 1.0, 1 / NUM_SAMPLES);

  { Switch to ortho mode }
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  gluOrtho2d(-1.33, 1.33, -1, 1);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;

  A1 := 1.0;
  A2 := 1.0 / (NUM_SAMPLES - 1) * BLUR_DISTANCE;

  { Render a number of quads, starting at the
    centre of the screen and moving outwards }
  for I := 0 to NUM_SAMPLES do begin
    A1 := A1 + A2;

    glBegin(GL_QUADS);
    glTexCoord2f(0.0, 0.0); glVertex2f(-A1, -A1);
    glTexCoord2f(1.0, 0.0); glVertex2f( A1, -A1);
    glTexCoord2f(1.0, 1.0); glVertex2f( A1,  A1);
    glTexCoord2f(0.0, 1.0); glVertex2f(-A1,  A1);
    glEnd;
  end;

  DoSwapBuffers;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  glViewport(0, 0, ClientWidth, ClientHeight);
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

procedure TForm1.FormClick(Sender: TObject);
begin
  Close();
end;

end.
