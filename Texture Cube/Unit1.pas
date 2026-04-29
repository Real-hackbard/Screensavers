unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, dglOpenGL, AppEvnts, GLBmp, ExtCtrls, StdCtrls, Math;

type
  TForm1 = class(TForm)
    ApplicationEvents1: TApplicationEvents;
    Timer1: TTimer;
    Timer2: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
    procedure Timer1Timer(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormShow(Sender: TObject);
    procedure FormClick(Sender: TObject);
  private
  { Private-Deklarationen}
  public
  { Public-Deklarationen}
    FDC    : HDC;
    FRC    : HGLRC;
    List   : Cardinal;
    yrot   : TGLFloat;
    Frames : Integer;
    procedure GLInit;
    procedure LoadSkyBox(pComponents : Cardinal);
    procedure GenerateSkyBox(pWidth, pHeight, pLength : TGLFloat);
    procedure DrawScene;
  end;

var
  Form1         : TForm1;
  SkyBoxTexture : Array[0..5] of TGLBmp;
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

procedure TForm1.FormCreate(Sender: TObject);
begin
  GetCursorPos(OldPos); // Initialposition

  InitOpenGL;
  // Get a handle from our Window
  FDC := GetDC(Handle);

  // Generate our rendering context with a color depth of 32Bpp
  FRC := CreateRenderingContext(FDC, [opDoubleBuffered], 32, 24, 0, 0, 0, 0);
  ActivateRenderingContext(FDC, FRC);
  Frames := 0;
  GLInit;
  LoadSkyBox(GL_RGBA);
end;

// =============================================================================
// Sets up all needed OpenGL properties
// =============================================================================
procedure TForm1.GLInit;
begin
  glEnable(GL_TEXTURE_2D);
  glEnable(GL_DEPTH_TEST);
end;

// =============================================================================
// Loads all textures used for the skybox
// =============================================================================
procedure TForm1.LoadSkyBox(pComponents : Cardinal);
const
 SkyBoxName : array[0..5] of String = ('BK', 'FR', 'DN', 'UP', 'LF', 'RT');
var
 i   : Integer;
begin
  // Now we load the images and generate our textures
  for i := 0 to High(SkyBoxTexture) do
   begin
   if SkyBoxTexture[i] = nil then
    begin
    SkyBoxTexture[i] := TGLBmp.Create;
    SkyBoxTexture[i].LoadImage(ExtractFilePath(Application.ExeName) +
                              'Images\' + SkyBoxName[i]+'.jpg');
    end;
   with SkyBoxTexture[i] do
    begin
    // If the texture object already exists, we should delete it
     begin
     if TextureID > 0 then
      glDeleteTextures(1, @TextureID);
     glGenTextures(1, @TextureID);
     glBindTexture(GL_TEXTURE_2D, TextureID);
     // Set the minification and magnification to the best filtering methods
     glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
     glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
                     GL_LINEAR_MIPMAP_LINEAR);
     // Set both texture coordinates to GL_CLAMP_TO_EDGE for seamless borders
     glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
     glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
     // Now we generate our mipmaps
     gluBuild2DMipmaps(GL_TEXTURE_2D, pComponents, GetWidth, GetHeight,
                       GL_RGBA, GL_UNSIGNED_BYTE, GetData);
     end;
    end;
   end;
  GenerateSkyBox(60, 60, 60);
end;

// =============================================================================
// Generates a Displaylist for the skybox
// =============================================================================
procedure TForm1.GenerateSkyBox(pWidth, pHeight, pLength : TGLFloat);
var
  px,py,pz : TGLFloat;
begin
  List := glGenLists(1);
  glNewList(List, GL_COMPILE);
   px := - pWidth  / 2;
   py := - pHeight / 2;
   pz := - pLength / 2;
   // Back
   SkyBoxTexture[0].Bind;
   glBegin(GL_QUADS);
    glTexCoord2f(0, 0); glVertex3f(px,          py,           pz);
    glTexCoord2f(0, 1); glVertex3f(px,          py + pHeight, pz);
    glTexCoord2f(1, 1); glVertex3f(px + pWidth, py + pHeight, pz);
    glTexCoord2f(1, 0); glVertex3f(px + pWidth, py,           pz);
   glEnd;
   // Front
   SkyBoxTexture[1].Bind;
   glBegin(GL_QUADS);
    glTexCoord2f(1, 0); glVertex3f(px,	      py,           pz + pLength);
    glTexCoord2f(1, 1); glVertex3f(px,          py + pHeight, pz + pLength);
    glTexCoord2f(0, 1); glVertex3f(px + pWidth, py + pHeight, pz + pLength);
    glTexCoord2f(0, 0); glVertex3f(px + pWidth, py,           pz + pLength);
   glEnd;
   // Bottom
   SkyBoxTexture[2].Bind;
   glBegin(GL_QUADS);
    glTexCoord2f(0, 1); glVertex3f(px,	      py, pz);
    glTexCoord2f(0, 0); glVertex3f(px,	      py, pz + pLength);
    glTexCoord2f(1, 0); glVertex3f(px + pWidth, py, pz + pLength);
    glTexCoord2f(0, 0); glVertex3f(px + pWidth, py, pz);
   glEnd;
   // Top
   SkyBoxTexture[3].Bind;
   glBegin(GL_QUADS);
    glTexCoord2f(0, 0); glVertex3f(px,          py + pHeight, pz);
    glTexCoord2f(0, 1); glVertex3f(px,          py + pHeight, pz + pLength);
    glTexCoord2f(1, 1); glVertex3f(px + pWidth, py + pHeight, pz + pLength);
    glTexCoord2f(1, 0); glVertex3f(px + pWidth, py + pHeight, pz);
   glEnd;
   // Left
   SkyBoxTexture[4].Bind;
   glBegin(GL_QUADS);
    glTexCoord2f(1, 0); glVertex3f(px, py,           pz);
    glTexCoord2f(0, 0); glVertex3f(px, py,           pz + pLength);
    glTexCoord2f(0, 1); glVertex3f(px, py + pHeight, pz + pLength);
    glTexCoord2f(1, 1); glVertex3f(px, py + pHeight, pz);
   glEnd;
   // Right
   SkyBoxTexture[5].Bind;
   glBegin(GL_QUADS);
    glTexCoord2f(0, 0); glVertex3f(px + pWidth, py,           pz);
    glTexCoord2f(1, 0); glVertex3f(px + pWidth, py,           pz + pLength);
    glTexCoord2f(1, 1); glVertex3f(px + pWidth, py + pHeight, pz + pLength);
    glTexCoord2f(0, 1); glVertex3f(px + pWidth, py + pHeight, pz);
   glEnd;
  glEndList;
end;

// =============================================================================
// Draws the Scene
// =============================================================================
procedure TForm1.DrawScene;
begin
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glClear(GL_DEPTH_BUFFER_BIT or GL_COLOR_BUFFER_BIT);
  glTranslatef(0, 0, -150);
  glRotatef(yrot, 1, 1, 0);
  // Call the Displaylist of our Skybox
  glCallList(List);
  SwapBuffers(FDC);
end;

procedure TForm1.ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
begin
  DrawScene;
  Done := False;
  inc(Frames);
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

  yrot := yrot + 0.1;
  if yrot > 360 then
   yrot := 0;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  if HandleAllocated then
   begin
     glViewport(0, 0, Screen.DesktopWidth, Screen.DesktopHeight);
     glMatrixMode(GL_PROJECTION);
     glLoadIdentity;
     gluPerspective(45, Screen.DesktopWidth/Screen.DesktopHeight, 0.1, 1000);
   end;
end;

procedure TForm1.Timer2Timer(Sender: TObject);
begin
  // Get fps count
  // Caption := IntToStr(Frames)+' FPS';
  Frames := 0;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  DeactivateRenderingContext;
  wglDeleteContext(FRC);
  ReleaseDC(Handle, FDC);
end;

procedure TForm1.FormKeyPress(Sender: TObject; var Key: Char);
begin
  Close();
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  MakeFormFullscreenAcrossAllMonitors(Form1);
end;

procedure TForm1.FormClick(Sender: TObject);
begin
  Close();
end;

end.
