unit Unit1;

interface

uses
  Windows, OpenGLForm, OpenGL, Forms, Classes, Controls, SysUtils,
  BMP, Graphics, Math, ExtCtrls;

type
  TForm1 = class(TOpenGLWindow)
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure Timer1Timer(Sender: TObject);
  end;

var
  Form1: TForm1;

const
  { Size of each 2D lightmap }
  DET_V = 15;

  { Number of 2D lightmaps }
  DET_Z = 5;

  { Edges of lightmap }
  MIN_X = -4.5;
  MAX_X =  4.5;
  MIN_Y = -4.5;
  MAX_Y =  4.5;
  MIN_Z = -4.5;
  MAX_Z =  4.5;

  { How bright the lights are }
  BRIGHTNESS = 1.0;

  { Number of light sources }
  NUM_LIGHTS = 20;

  { Position of OpenGL light source }
  LIGHT: TGLArrayf4 = (0.0, 0.0, 0.0, 1.0);

type
  { Vector }
  TVector = array[0..2] of Single;

  { RGB color }
  TColor = array[0..2] of Byte;

  { Light source }
  TLight = record
    Pos: TVector;
    Color: TColor;
  end;

var
  { GLU quadric for rendering lights }
  q: gluQuadricObj;

  { Used to track position of mouse }
  mX, mY: Integer;
  tX, tY, tM: Single;

  { Camera position and orientation }
  rX: Single = 30.0;
  rY: Single = 30.0;
  Mv: Single = 3.0;

  { texture }
  img : GLuInt;

  { Texture objects for lightmaps }
  Tex: array[0..DET_Z] of GLuInt;

  { Light sources }
  Lights: array[0..NUM_LIGHTS] of TLight;

  { Lightmap data for all lightmaps }
  LightMap: array[0..DET_Z, 0..DET_V, 0..DET_V] of TColor;

  { Mouse Position }
  OldPos: TPoint;

implementation

uses World;

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

{ Calculate the length of a vector }
function VectLength(V: TVector): Single;
begin
  Result := Sqrt(V[0] * V[0] + V[1] * V[1] + V[2] * V[2]);
end;

{ Subtract two vectors }
function VectSub(V1, V2: TVector): TVector;
begin
  Result[0] := V1[0] - V2[0];
  Result[1] := V1[1] - V2[1];
  Result[2] := V1[2] - V2[2];
end;

{ Allocate random colours to light sources }
procedure SetupLights;
var
  I: Integer;
begin
  Randomize;
  for I := 0 to NUM_LIGHTS do
  begin
    Lights[I].Color[0] := Random(256);
    Lights[I].Color[1] := Random(256);
    Lights[I].Color[2] := Random(256);
  end;
end;

{ Calculate the colour of a particular point }
procedure CalculateLighting(P: TVector;
  var R, G, B: Integer);
var
  I: Integer;
  Len: Single;
  Color: Single;
const
  MIN_L = 0.8;
  MAX_L = 2.0;
begin
  R := 0; G := 0; B := 0;

  { For each light source in the scene, calculate
    how much it contributes to lighting this point
    and add on the contribution. }
  for I := 0 to NUM_LIGHTS do
  begin
    Len := VectLength(VectSub(Lights[I].Pos, P));

    if Len < MIN_L then
      Color := 1.0 else
    if Len > MAX_L then
      Color := 0.0 else
      Color := (Len - MAX_L) / (MIN_L - MAX_L);

    R := R + Round(Color * Lights[I].Color[0]);
    G := G + Round(Color * Lights[I].Color[1]);
    B := B + Round(Color * Lights[I].Color[2]);
  end;
end;

{ Create the lightmap textures }
procedure SetupTextures;
var
  I: Integer;
  ii, jj: Integer;
  V: TVector;
  R, G, B: Integer;
begin
  for I := 0 to DET_Z do
  begin
    for ii := 0 to DET_V do
    begin
      for jj := 0 to DET_V do
      begin
        { For each texel in the lightmap, calculate the
          corresponding point in space }
        V[0] := MIN_X + (MAX_X - MIN_X) * jj / DET_V;
        V[1] := MIN_Y + (MAX_Y - MIN_Y) * ii / DET_V;
        V[2] := MIN_Z + (MAX_Z - MIN_Z) * I / DET_Z;

        { Calculate lighting at this point }
        CalculateLighting(V, R, G, B);

        { Clamp large values }
        if R > 255 then R := 255;
        if G > 255 then G := 255;
        if B > 255 then B := 255;

        { Set the lightmap value }
        LightMap[I, ii, jj, 0] := R;
        LightMap[I, ii, jj, 1] := G;
        LightMap[I, ii, jj, 2] := B;
      end;
    end;

    { Create the lightmap texture }
    glBindTexture(GL_TEXTURE_2D, Tex[I]);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, DET_V + 1, DET_V + 1,
      0, GL_RGB, GL_UNSIGNED_BYTE, @LightMap[I]);
  end;
end;

function FindFirstTexture(Z: Single;
  var Amt: Single): Integer;
var
  Temp: Single;
begin
  { For a point in space, find the nearest
    lightmap and calculate how far away it is. }
  Temp := (Z - MIN_Z) / (MAX_Z - MIN_Z) * DET_Z;

  Amt := 1 - Frac(Temp);
  Result := Trunc(Temp);

  { If Z is outside the lightmapped volume, then
    Result < 0 }
  if (Result >= DET_Z) then Result := -1;
end;

procedure RenderTriangle(V1, V2, V3: TVertex);
var
  Amt: Single;
  B1, B2: Single;
  FirstTex: Integer;
  X1, X2, X3: Single;
  Y1, Y2, Y3: Single;
begin
  { Render a lightmapped triangle

    Calculate the X and Y components of each
    position vector of the triangle. }
  X1 := (_Wv[V1.Pos][0] - MIN_X) / (MAX_X - MIN_X);
  X2 := (_Wv[V2.Pos][0] - MIN_X) / (MAX_X - MIN_X);
  X3 := (_Wv[V3.Pos][0] - MIN_X) / (MAX_X - MIN_X);

  Y1 := (_Wv[V1.Pos][1] - MIN_Y) / (MAX_Y - MIN_Y);
  Y2 := (_Wv[V2.Pos][1] - MIN_Y) / (MAX_Y - MIN_Y);
  Y3 := (_Wv[V3.Pos][1] - MIN_Y) / (MAX_Y - MIN_Y);

  { First, render the triangle as usual with
    OpenGL lighting }

  glDisable(GL_BLEND);
  glEnable(GL_LIGHTING);

  glColor3f(1.0, 1.0, 1.0);
  glBindTexture(GL_TEXTURE_2D, img);

  glBegin(GL_TRIANGLES);
  glNormal3fv(@_Wn[V1.Nrm]); glTexCoord2f(V1.v, V1.u); glVertex3fv(@_Wv[V1.Pos]);
  glNormal3fv(@_Wn[V2.Nrm]); glTexCoord2f(V2.v, V2.u); glVertex3fv(@_Wv[V2.Pos]);
  glNormal3fv(@_Wn[V3.Nrm]); glTexCoord2f(V3.v, V3.u); glVertex3fv(@_Wv[V3.Pos]);
  glEnd;

  { Now we blend three more triangles with this one,
    lighting each vertex separately. }

  glEnable(GL_BLEND);
  glDisable(GL_LIGHTING);

  { First vertex }

  FirstTex := FindFirstTexture(_Wv[V1.Pos][2], Amt);
  if (FirstTex < 0) then Exit;

  B1 := BRIGHTNESS * Amt;
  B2 := BRIGHTNESS * (1 - Amt);

  glBindTexture(GL_TEXTURE_2D, Tex[FirstTex]);

  glBegin(GL_TRIANGLES);
  glColor4f(B1, B1, B1, 1.0);
  glTexCoord2f(X1, Y1); glVertex3fv(@_Wv[V1.Pos]);
  glColor4f(B1, B1, B1, 0.0);
  glTexCoord2f(X2, Y2); glVertex3fv(@_Wv[V2.Pos]);
  glTexCoord2f(X3, Y3); glVertex3fv(@_Wv[V3.Pos]);
  glEnd;

  glBindTexture(GL_TEXTURE_2D, Tex[FirstTex + 1]);

  glBegin(GL_TRIANGLES);
  glColor4f(B2, B2, B2, 1.0);
  glTexCoord2f(X1, Y1); glVertex3fv(@_Wv[V1.Pos]);
  glColor4f(B2, B2, B2, 0.0);
  glTexCoord2f(X2, Y2); glVertex3fv(@_Wv[V2.Pos]);
  glTexCoord2f(X3, Y3); glVertex3fv(@_Wv[V3.Pos]);
  glEnd;

  { Second vertex }

  FirstTex := FindFirstTexture(_Wv[V2.Pos][2], Amt);
  if (FirstTex < 0) then Exit;

  B1 := BRIGHTNESS * Amt;
  B2 := BRIGHTNESS * (1 - Amt);

  glBindTexture(GL_TEXTURE_2D, Tex[FirstTex]);

  glBegin(GL_TRIANGLES);
  glColor4f(B1, B1, B1, 1.0);
  glTexCoord2f(X2, Y2); glVertex3fv(@_Wv[V2.Pos]);
  glColor4f(B1, B1, B1, 0.0);
  glTexCoord2f(X1, Y1); glVertex3fv(@_Wv[V1.Pos]);
  glTexCoord2f(X3, Y3); glVertex3fv(@_Wv[V3.Pos]);
  glEnd;

  glBindTexture(GL_TEXTURE_2D, Tex[FirstTex + 1]);

  glBegin(GL_TRIANGLES);
  glColor4f(B2, B2, B2, 1.0);
  glTexCoord2f(X2, Y2); glVertex3fv(@_Wv[V2.Pos]);
  glColor4f(B2, B2, B2, 0.0);
  glTexCoord2f(X1, Y1); glVertex3fv(@_Wv[V1.Pos]);
  glTexCoord2f(X3, Y3); glVertex3fv(@_Wv[V3.Pos]);
  glEnd;

  { Third vertex }

  FirstTex := FindFirstTexture(_Wv[V3.Pos][2], Amt);
  if (FirstTex < 0) then Exit;

  B1 := BRIGHTNESS * Amt;
  B2 := BRIGHTNESS * (1 - Amt);

  glBindTexture(GL_TEXTURE_2D, Tex[FirstTex]);

  glBegin(GL_TRIANGLES);
  glColor4f(B1, B1, B1, 1.0);
  glTexCoord2f(X3, Y3); glVertex3fv(@_Wv[V3.Pos]);
  glColor4f(B1, B1, B1, 0.0);
  glTexCoord2f(X1, Y1); glVertex3fv(@_Wv[V1.Pos]);
  glTexCoord2f(X2, Y2); glVertex3fv(@_Wv[V2.Pos]);
  glEnd;

  glBindTexture(GL_TEXTURE_2D, Tex[FirstTex + 1]);

  glBegin(GL_TRIANGLES);
  glColor4f(B2, B2, B2, 1.0);
  glTexCoord2f(X3, Y3); glVertex3fv(@_Wv[V3.Pos]);
  glColor4f(B2, B2, B2, 0.0);
  glTexCoord2f(X1, Y1); glVertex3fv(@_Wv[V1.Pos]);
  glTexCoord2f(X2, Y2); glVertex3fv(@_Wv[V2.Pos]);
  glEnd;

  glEnable(GL_LIGHTING);
  glDisable(GL_BLEND);

  glColor3f(1.0, 1.0, 1.0);
end;

procedure RenderQuad(I: Integer);
begin
  { Render a quad by splitting it into
    two triangles }
  RenderTriangle(_Wd[I, 0], _Wd[I, 1],
    _Wd[I, 2]);
  RenderTriangle(_Wd[I, 0], _Wd[I, 2],
    _Wd[I, 3]);
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  BMap: TBitmap;
begin
  MakeFormFullscreenAcrossAllMonitors(Form1);
  GetCursorPos(OldPos); // Initialposition

  { Set up the light sources }
  SetupLights;

  glShadeModel(GL_SMOOTH);

  q := gluNewQuadric;

  glEnable(GL_DEPTH_TEST);
  glDepthFunc(GL_LEQUAL);

  glEnable(GL_COLOR_MATERIAL);

  { Set up OpenGL lighting }
  glEnable(GL_LIGHTING);
  glLightfv(GL_LIGHT0, GL_POSITION, @LIGHT);
  glEnable(GL_LIGHT0);

  glBlendFunc(GL_SRC_ALPHA, GL_ONE);

  { Load the bricks texture }
  BMap := TBitmap.Create;
  BMap.LoadFromFile(ExtractFilePath(Application.ExeName) + 'tex.bmp');
  img := LoadBMP(BMap);
  BMap.Free;

  { Set up texturing }
  glEnable(GL_TEXTURE_2D);
  glGenTextures(DET_Z + 1, @Tex);
end;

procedure TForm1.FormPaint(Sender: TObject);
var
  I: Integer;
  Time: Single;
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  glLoadIdentity;

  Time := GetTickCount / 1000.0;

  { Position the camera }
  glTranslatef(0.0, 0.0, -Mv);
  glRotatef(rX, 1.0, 0.0, 0.0);
  glRotatef(rY, 0.0, 1.0, 0.0);

  { Disable texturing }
  glBindTexture(GL_TEXTURE_2D, 0);

  for I := 0 to NUM_LIGHTS do
  begin
    with Lights[I] do
    begin
      { Position each light source }
      Pos[0] := Sin(Time + I * 17) * 2.9;
      Pos[1] := Sin(Time + I * 18) * 2.9;
      Pos[2] := Sin(Time + I * 19) * 2.9;

      { Draw a sphere to represent it }
      glColor3ubv(@Color);
      glPushMatrix;
      glTranslatef(Pos[0], Pos[1], Pos[2]);
      gluSphere(q, 0.1, 16, 16);
      glPopMatrix;
    end;
  end;

  { Create the lightmaps }
  SetupTextures;

  { Render each quad }
  for I := 0 to High(_Wd) do
    RenderQuad(I);

  DoSwapBuffers;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  if ClientHeight = 0 then ClientHeight := 1;
  glViewport(0, 0, ClientWidth, ClientHeight);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  gluPerspective(80, ClientWidth / ClientHeight, 0.5, 10.0);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
end;

procedure TForm1.FormKeyPress(Sender: TObject; var Key: Char);
begin
  Close();
end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  { Save previous values }
  mX := X;
  mY := Y;
  tX := rX;
  tY := rY;
  tM := Mv;
end;

procedure TForm1.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin


  { Move the camera
  if ssLeft in Shift then
  begin
    rY := tY + (X - mX) / ClientWidth * 300.0;
    rX := tX + (Y - mY) / ClientHeight * 300.0;
  end;
  if ssRight in Shift then
  begin
    Mv := tM + (Y - mY) / ClientWidth * 50.0;
    if Mv >  3.0 then Mv :=  3.0;
    if Mv < -2.0 then Mv := -2.0;
  end;     }
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
