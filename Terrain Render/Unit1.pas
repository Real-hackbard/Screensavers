unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls,
  Forms, Dialogs, glBmp, OpenGL12, AppEvnts, ExtCtrls, StdCtrls, Math;

type
  TForm1 = class(TForm)
    ApplicationEvents1: TApplicationEvents;
    RotTimer: TTimer;
    FPSTimer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
    procedure FormResize(Sender: TObject);
    procedure RotTimerTimer(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FPSTimerTimer(Sender: TObject);
    procedure FormClick(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
 OldPos: TPoint;
 wglSwapIntervalEXT    : function(interval: TGLint) : BOOL;
 stdcall = nil;

var
  VertexArray   : array of array[0..2] of Single; // Vertex data of the elevation map
  TexCoordArray : array of array[0..1] of Single; // Texture coordinates of the elevation map
  DrawMode      : Byte;
  Form1         : TForm1;
  DC            : HDC;
  RC            : HGLRC;
  Texture       : TglBMP;
  DL            : Cardinal;
  Rot           : Single;
  Frames        : Integer;

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

procedure CreateHeightMap(pFileName : String;pResolution : Integer);
type
 TVertexR = record
  x,y,z : Single;
  end;
var
 HeightData : array of array of Byte;
 Vertex     : array[0..3] of array[0..2] of Single;
 Bmp        : TBitMap;
 x,z,i      : LongInt;
 Resolution : Integer;
 Size       : Integer;
 Ratio      : Single;
const
 VertPos : array[0..3] of array[0..1] of Byte = ((0,0),(0,1),(1,1),(1,0));
begin
  SetLength(VertexArray,0);
  SetLength(TexCoordArray,0);
  Resolution := pResolution;
  Size       := 82;
  Bmp := TBitMap.Create;
  try
   Bmp.LoadFromFile(pFileName);
   Ratio := Bmp.Width/Bmp.Height;
   SetLength(HeightData, Resolution+1);
   for x := 0 to Resolution do
    begin
    SetLength(HeightData[x], Resolution+1);
    for z := 0 to Resolution do
     HeightData[x,z] := Trunc(Bmp.Canvas.Pixels[Trunc(X/Resolution*Bmp.Width),Trunc(Z/Resolution*Bmp.Height)]/ clWhite * 255);
    end;
  finally
   Bmp.Free
  end;

  // Vertexe und Texturcoordinaten generien
  for x := 0 to Resolution-2 do
   for z := 0 to Resolution-2 do
    begin
    for i := 0 to 3 do
     begin
       Vertex[i,0] := ((X + VertPos[I][0])/Resolution*Size-Size/2)*Ratio;
       Vertex[i,2] := (Z + VertPos[I][1])/Resolution*Size-Size/2;
       Vertex[i,1] := HeightData[X + VertPos[I][0],Z + VertPos[I][1]]*4;
       SetLength(TexCoordArray, Length(TexCoordArray)+1);
       TexCoordArray[High(TexCoordArray)][0] := (Vertex[i,0]-Size*Ratio/2)/(Size*Ratio);
       TexCoordArray[High(TexCoordArray)][1] := (-Vertex[i,2]-Size/2)/Size;
       SetLength(VertexArray, Length(VertexArray)+1);
       VertexArray[High(VertexArray)][0] := Vertex[i,0];
       VertexArray[High(VertexArray)][1] := Vertex[i,1]*0.01;
       VertexArray[High(VertexArray)][2] := Vertex[i,2];
     end;
    end;

  // Displayliste generieren
  DL := glGenLists(1);
  glNewList(DL, GL_COMPILE);
   glBegin(GL_QUADS);
   for x := 0 to Resolution-2 do
    for z := 0 to Resolution-2 do
     begin
     for i := 0 to 3 do
      begin
        Vertex[i,0] := ((X + VertPos[I][0])/Resolution*Size-Size/2)*Ratio;
        Vertex[i,2] := (Z + VertPos[I][1])/Resolution*Size-Size/2;
        Vertex[i,1] := HeightData[X + VertPos[I][0],Z + VertPos[I][1]]*4*0.01;
        glTexCoord2f((Vertex[i,0]-Size*Ratio/2)/(Size*Ratio),
                      (-Vertex[i,2]-Size/2)/Size);
        glVertex3fv(@Vertex[i]);
      end;
     end;
   glEnd;
  glEndList;
end;

procedure Draw;
begin
  ActivateRenderingContext(DC, RC);
  glMatrixMode(GL_PROJECTION);
  glViewport(0, 0, Form1.ClientWidth, Form1.ClientHeight);
  glLoadIdentity;
  gluPerspective(45, Form1.ClientWidth/Form1.ClientHeight, 0.1, 512);
  glMatrixMode(GL_MODELVIEW);
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  glLoadIdentity;
  glTranslatef(0,0,-60);
  glRotatef(35, 1, 0, 0);
  glRotatef(Rot, 0 , 1, 0);
  glScalef(1, 1, 1);

  Texture.Bind;
  if DrawMode = 0 then
   begin
     glVertexPointer(3, GL_FLOAT, 12, VertexArray);
     glTexCoordPointer(2, GL_FLOAT, 8, TexCoordArray);
     glEnableClientState(GL_VERTEX_ARRAY);
     glEnableClientState(GL_TEXTURE_COORD_ARRAY);
     if Length(VertexArray) > 0 then
      glDrawArrays(GL_QUADS, 0, Length(VertexArray));
   end
  else
   glCallList(DL);

  SwapBuffers(DC);
  inc(Frames);
  DeActivateRenderingContext;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
 DummyPal : HPalette;
begin
  MakeFormFullscreenAcrossAllMonitors(Form1);
  GetCursorPos(OldPos); // Initialposition

  DC := GetDC(Handle);
  RC := CreateRenderingContext(DC, [opDoubleBuffered],
                            32, 24, 0, 0, 0, 0, DummyPal);
  ActivateRenderingContext(DC, RC);
  glEnable(GL_TEXTURE_2D);
  glEnable(GL_DEPTH_TEST);
  glClearColor(0,0,0,0);
  CreateHeightMap(ExtractFilePath(Application.ExeName) + 'hm.bmp', 64);

  Texture := TglBMP.Create(ExtractFilePath(Application.ExeName) + 'terrain.bmp');
  Texture.GenTexture(True, False);
  DrawMode := 0;
  Frames   := 0;
  wglSwapIntervalEXT := wglGetProcAddress('wglSwapIntervalEXT');
  wglSwapIntervalEXT(0);
  DeActivateRenderingContext;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  Texture.Free;
end;

procedure TForm1.ApplicationEvents1Idle(Sender: TObject;
  var Done: Boolean);
begin
  Done := False;
  Draw;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  if (HandleAllocated) and (DC > 0) and (RC > 0) then
   begin
   ActivateRenderingContext(DC,RC);
   glViewport(0, 0, ClientWidth, ClientHeight);
   glMatrixMode(GL_PROJECTION);
   glLoadIdentity;
   gluPerspective(45, ClientWidth/ClientHeight, 0.1, 100);
   DeactivateRenderingContext;
  end;
end;

procedure TForm1.RotTimerTimer(Sender: TObject);
begin
  Rot := Rot+0.1;
  if Rot > 360 then
   Rot := 0;
end;

procedure TForm1.FormKeyPress(Sender: TObject; var Key: Char);
begin
  //DrawMode := not DrawMode;
  Close();
end;

procedure TForm1.FPSTimerTimer(Sender: TObject);
var
  S : String;
  NewPos: TPoint;
begin
  GetCursorPos(NewPos);
  if (NewPos.X <> OldPos.X) or (NewPos.Y <> OldPos.Y) then
  begin
    // Mouse moved
    Close();
  end;

  case DrawMode of
     0 : S := 'Drawing as VertexArray';
   255 : S := 'Drawing as DisplayList';
  end;
  Caption := 'Terrain Render - FPS : '+IntToStr(Frames)+' '+S;
  Frames := 0;
end;

procedure TForm1.FormClick(Sender: TObject);
begin
  Close();
end;

end.
