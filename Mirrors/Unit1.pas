unit Unit1;

interface

uses
  Windows, OpenGLForm, OpenGL, Forms, BMP, SysUtils, Math, Classes,
  ExtCtrls;

type
  TForm1 = class(TOpenGLWindow)
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  end;

var
  Form1: TForm1;
  OldPos: TPoint;

const
  NUM_BLOCKS = 5;    // Color Boxes
  NUM_SAMPLES = 10;  // Mirrors

var
  Tex    : GLuInt;
  Time   : Single;
  Envmap : GLuInt;
  Blocks : GLuInt;

procedure glGenTextures(N: GLSizei; Textures: PGLuInt); stdcall; external OpenGL32;
procedure glBindTexture(Target: GLEnum; Texture: GLuInt); stdcall; external OpenGL32;
procedure glCopyTexImage2D(Target: Cardinal; Level: Integer; Format: Cardinal; X, Y, Width, Height, Border: Integer); stdcall; external OpenGL32;
procedure glCopyTexSubImage2D(Target: Cardinal; Level, XOffset, YOffset, X, Y, Width, Height: Integer); stdcall; external OpenGL32;

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

procedure InitBlocks;
var
  I: Integer;
begin
  // Render lots of coloured blocks
  RandSeed := 345816;

  Blocks := glGenLists(1);
  glNewList(Blocks, GL_COMPILE);

  for I := 0 to NUM_BLOCKS - 1 do begin
    glPushMatrix;

    glTranslatef((Random - 0.5) * 2.0,
      (Random - 0.5) * 2.0,
      (Random - 0.5) * 2.0);
    glColor3f(Random, Random, Random);
    glScalef(Random * 0.1 + 0.3, Random * 0.1 + 0.3, 1.0);
    glRotatef(Random * 180.0,
      Random, Random, Random);

    glBegin(GL_QUADS);
    glTexCoord2f( 0.0,  0.0); glVertex2f(-0.5, -0.5);
    glTexCoord2f( 0.0,  1.0); glVertex2f(-0.5,  0.5);
    glTexCoord2f( 1.0,  1.0); glVertex2f( 0.5,  0.5);
    glTexCoord2f( 1.0,  0.0); glVertex2f( 0.5, -0.5);
    glEnd;

    glPopMatrix;
  end;

  glEndList;
end;

procedure CreateTexture;
begin
  // Push the attribute stacks.
  glPushAttrib(GL_ALL_ATTRIB_BITS);

  // Update the viewport
  glViewport(0, 0, 256, 256);

  // Clear the color buffer
  glClearColor(0.6, 0.2, 0.2, 0.0);
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

  // Set up the projection matrix
  glMatrixMode(GL_PROJECTION);
  glPushMatrix;
  glLoadIdentity;
  gluPerspective(45.0, 1.0, 0.1, 100.0);

  // Reset the modelview matrix
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glTranslatef(0.0, 0.0, -2.0);
  glRotatef(Time * 3.0, 1, 0, 0);
  glRotatef(Time * 4.0, 0, 1, 0);
  glRotatef(Time * 5.0, 0, 0, 1);

  // Enable env mapping
  glEnable(GL_TEXTURE_GEN_S);
  glEnable(GL_TEXTURE_GEN_T);
  glTexGeni(GL_S, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP);
  glTexGeni(GL_T, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP);

  // Render again, using the envmap.
  glBindTexture(GL_TEXTURE_2D, Envmap);
  glCallList(Blocks);

  // Disable env mapping
  glDisable(GL_TEXTURE_GEN_S);
  glDisable(GL_TEXTURE_GEN_T);

  // Reset the projection matrix
  glMatrixMode(GL_PROJECTION);
  glPopMatrix;

  if Tex > 0 then begin
    // Copy the screen to the texture
    glBindTexture(GL_TEXTURE_2D, Tex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glCopyTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 0, 0, 256, 256);
  end else begin
    // Create a new texture if needed
    glGenTextures(1, @Tex);
    glBindTexture(GL_TEXTURE_2D, Tex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 0, 0, 256, 256, 0);
  end;

  // Pop the attribute stacks.
  glPopAttrib;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  MakeFormFullscreenAcrossAllMonitors(Form1);
  GetCursorPos(OldPos); // Initialposition
  
  // Set up texturing
  glEnable(GL_TEXTURE_2D);
  LoadBMP(ExtractFilePath(Application.ExeName) + 'Back02.bmp', Envmap);

  // Create the display list
  InitBlocks;

  // Select the correct blend equation
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE);
end;

procedure TForm1.FormPaint(Sender: TObject);
var
  I: Integer;
begin
  // Get the current time
  Time := GetTickCount / 1000.0;

  // Create the texture
  CreateTexture;

  // Clear the colour buffers
  glClearColor(0.11, 0.0, 0.0, 0.0);
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

  // Update the modelview matrix
  glLoadIdentity;
  glTranslatef(0.0, 0.0, -1.5);
  glRotatef(Time * 3.0, 1, 0, 0);
  glRotatef(Time * 4.0, 0, 1, 0);
  glRotatef(Time * 5.0, 0, 0, 1);

  // Select the texture and color
  glColor4f(1.0, 1.0, 1.0, 0.5);
  glBindTexture(GL_TEXTURE_2D, Tex);

  for I := 0 to NUM_SAMPLES - 1 do begin
    glPushMatrix;
    glTranslatef(0.0, 0.0, I / (NUM_SAMPLES - 1) - 0.5);
    glBegin(GL_QUADS);
    glTexCoord2f( 0.0,  0.0); glVertex2f(-0.5, -0.5);
    glTexCoord2f( 0.0,  1.0); glVertex2f(-0.5,  0.5);
    glTexCoord2f( 1.0,  1.0); glVertex2f( 0.5,  0.5);
    glTexCoord2f( 1.0,  0.0); glVertex2f( 0.5, -0.5);
    glEnd;
    glPopMatrix;
  end;
  DoSwapBuffers;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  if ClientHeight = 0 then ClientHeight := 1;
  glViewport(0, 0, ClientWidth, ClientHeight);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  gluPerspective(60, ClientWidth / ClientHeight, 0.1, 1000.0);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
end;

procedure TForm1.FormKeyPress(Sender: TObject; var Key: Char);
begin
  Close();
end;

procedure TForm1.FormClick(Sender: TObject);
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
