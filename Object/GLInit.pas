unit GLInit;

interface

uses
   OpenGL, Forms, Classes, Windows, SysUtils, Graphics, PNGraphics,hyMaths;
const
 //complement for OPENGL.pas
  GL_BGR_EXT                                 = $80E0;
  GL_BGRA_EXT                                = $80E1;

  // polygon offset
  GL_POLYGON_OFFSET_UNITS                    = $2A00;
  GL_POLYGON_OFFSET_POINT                    = $2A01;
  GL_POLYGON_OFFSET_LINE                     = $2A02;
  GL_POLYGON_OFFSET_FILL                     = $8037;
  GL_POLYGON_OFFSET_FACTOR                   = $8038;

  ifSupportOpenGL= PFD_SUPPORT_OPENGL;
  ifDrawToWindow = PFD_DRAW_TO_WINDOW;
  ifDrawToBitmap = PFD_DRAW_TO_BITMAP;
  ifSupportGDI   = PFD_SUPPORT_GDI;
  ifNeedPalette  = PFD_NEED_PALETTE;
  ifDoubleBuffer = PFD_DOUBLEBUFFER;
  StdDoubleBuffer = PFD_SUPPORT_OPENGL or PFD_DRAW_TO_WINDOW or 
                         PFD_DOUBLEBUFFER;
type
  TRapidGLPixels = array of Byte;
  TColor4ub = record
                R,G,B,A:Byte;
              end;
  TCameraPositon = record
                     X:Single;
                     Y:Single;
                     Z:Single;
                   end;
  TCameraOrientation = record
                         X:Single;
                         Y:Single;
                         Z:Single;
                       end;
  TRapidFontAnim = (rfaFadeIn,rfaFadeOut,rfaFresh);
  TCamera = Class(TObject)
  private
    FSpeed: Single;
    TurnP: Single;
  public
    Position:T3DVector;
    Orientation:T3DVector;
    property WalkSpeed:Single read FSpeed Write FSpeed;
    property TurnPrecision:Single  read TurnP write TurnP;
    constructor Create;
    procedure PowerOn;
    procedure LookUp;
    procedure LookDown;
    procedure TurnLeft;
    procedure TurnRight;
    procedure GoAhead;
    procedure GoBack;
    procedure LookUpDegress(Deg:Single);
    procedure TurnAngle(a: single);
  end;

  TOpenGLInit = class(TObject)
  private
    FHDC: THandle;
    DC: HDC;
    HRC :HGLRC ;
    procedure InitializeOpenGL(ColorBits:Byte;DrawFlags:DWord);
    procedure TerminateOpenGL;
  public
    Constructor Create(Handle:THandle;ColorBits:Byte;DrawFlags:DWord);
    procedure SetViewPort(Width,Height:Integer);
    procedure SetPerspective(Degree,Height,Width:Integer;FarZ:Single);
    procedure Free;
    property DestHDC : THandle read FHDC;
    property CurrentDC : HDC read DC;
  end;
  TFPSCounter = Class(TObject)
  private
    Frames:Integer;
    curTime:Integer;
    stTime :Integer;
    fFPS : Single;
    function GetSpeed: String;
  public
    property FPS:Single read fFPS;
    property Speed:String read GetSpeed;
    procedure FinishRender;
    constructor Create;
    procedure free;
  end;
  TRapidFont = class(TObject)
  private
  { Private-Deklarationen}
    FText: String;
    FColor: TColor4ub;
    
    FRealWidth: Integer;
    FRealHeight: Integer;
    PixPtr:TRapidPixelPointer;
    Pixs:TRapidPixels;
    lstH,lstW:Integer;
    FClipText: Boolean;
    FClipWidth: Integer;
    FClipHeight: Integer;

    procedure SetFont(const Value: TFont);
    procedure SetText(const Value: String);
    function CalcHeight(aH:Integer):Integer;
    function CalcWidth(aW:Integer):Integer;
    function GetHeight: Integer;
    function GetWidth: Integer;
    function GetFont: TFont;
  public
  { Public-Deklarationen}
    Bit : TBitmap;
    TexFont : GLuint;
    constructor Create;
    procedure Free;

    procedure TextOut(x,y:Integer);
    procedure AdvancedFrame(TimeDelta:Integer;Anim:TRapidFontAnim;Speed:Integer);
    function TextHeight(S: String):Integer;
    function TextWidth(S: String):Integer;

    property Font : TFont read GetFont write SetFont;
    property FontColor : TColor4ub read FColor write FColor;
    property Text : String Read FText write SetText;
    property ClipHeight:Integer read FClipHeight write FClipHeight;
    property ClipWidth:Integer read FClipWidth write FClipWidth;
    property ClipText:Boolean read FClipText write FClipText;
    property Height : Integer read GetHeight;
    property Width : Integer read GetWidth;
    property RealWidth:Integer read FRealWidth;
    property RealHeight:Integer read FRealHeight;
  end;

procedure glBindTexture(target: GLEnum; texture: GLuint);
          stdcall; external opengl32;
procedure glDeleteTextures(n: GLsizei; textures: PGLuint);
          stdcall; external opengl32;
procedure glGenTextures(n: GLsizei; textures: PGLuint);
          stdcall; external opengl32;
function glIsTexture(texture: GLuint): GLboolean;
          stdcall; external opengl32;
procedure glPolygonOffset(factor, units: GLfloat);
          stdcall; external opengl32;
function gluBuild2DMipmaps(target: GLEnum; components, width, height: GLint;
          format, atype: GLEnum; Data: Pointer): GLint; stdcall; external GLU32;

function Color4ub(R,G,B,A:Byte):TColor4ub;
Function LoadTexture(FileName:String;MinFilter:GLenum;
          MagFilter:GLenum;wrap:GLenum):GLuint;
Function LoadTextureFromBitmap(Bit:TBitmap;MinFilter:GLenum;
          MagFilter:GLenum;wrap:GLenum):GLuint;
function LoadTextureFromPointer(PixPtr:TRapidPixelPointer;Width,Height:Integer;
          MinFilter:GLenum;MagFilter:GLenum;wrap:GLenum):GLuint;
function LoadAlphaTextureFromPointer(PixPtr:TRapidPixelPointer;
          Alpha:Byte;Width,Height:Integer;MinFilter:GLenum;MagFilter:GLenum;
          Wrap:GLenum):GLuint;
Function LoadFontTextureFromBitmap(Bit:TBitmap;FontColor:TColor4ub;
          MinFilter:GLenum;MagFilter:GLenum;Wrap:GLenum):GLuint;

procedure ReadBitmap(Bit:TBitmap;var Pix:array of Byte;Alpha:Byte;PixPtr:TRapidPixelS);

implementation

function Color4ub(R,G,B,A:Byte):TColor4ub;
begin
  Result.R := R;
  Result.G := G;
  Result.B := B;
  Result.A := A;
end;

procedure ReadBitmap(Bit:TBitmap;var Pix:array of Byte;Alpha:Byte;PixPtr:TRapidPixelS);
var
  i,j:Integer;
  k:Integer;
  w:Integer;
begin
  w:=Bit.Width *4;
  for i := 0 to Bit.Height -1 do
  begin
    for j := 0 to Bit.Width - 1 do
    begin
      k:=i*w + j*4;
      Pix[k] :=PixPtr[j,i].R;
      Pix[k+1] :=PixPtr[j,i].G;
      Pix[k+2] :=PixPtr[j,i].B;
      Pix[k+3] :=alpha;
    end;
  end;
end;

function LoadAlphaTextureFromPointer(PixPtr:TRapidPixelPointer;
          Alpha:Byte;Width,Height:Integer; MinFilter:GLenum;
          MagFilter:GLenum;Wrap:GLenum):GLuint;
var
  Texture:GLuint;
  Pixels: array of Byte;
  i,j:Integer;
  k:Integer;
begin
  SetLength(Pixels,Height*Width*4);
  k:=0;
  for i := 0 to Width -1 do
  begin
    for j := 0 to Height -1 do
    begin
      Pixels[k] := PixPtr[j][i*3+2];
      Pixels[k+1] := PixPtr[j][i*3+1];
      Pixels[k+2] := PixPtr[j][i*3];
      Pixels[k+3] := Alpha;
      k := k+4;
    end;
  end;
  glGenTextures(1,@Texture);
  glBindTexture(GL_TEXTURE_2D,Texture);
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,magFilter);
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,minFilter);
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,wrap);
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,wrap);
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_ENV_MODE,GL_MODULATE);

  if (minFilter = GL_LINEAR) or (minFilter = GL_NEAREST) then
    glTexImage2D(GL_TEXTURE_2D,0,4,Width,Height,0,GL_RGBA,
               GL_UNSIGNED_BYTE,Pixels)
  else
    GLInit.gluBuild2DMipmaps(GL_TEXTURE_2D,
                                          4,
                                          Width,
                                          Height,
                                          GL_RGBA,GL_UNSIGNED_BYTE,
                                          Pixels);
  result := texture;
end;

function LoadTextureFromPointer(PixPtr:TRapidPixelPointer;Width,Height:Integer;
          MinFilter:GLenum;MagFilter:GLenum;wrap:GLenum):GLuint;
var
  Texture:GLuint;
  Pixels: array of Byte;
  i,j:Integer;
  k:Integer;
begin
  SetLength(Pixels,Height*Width*3);
  k:=0;
  
  for i := 0 to Width -1 do
  begin
    for j :=Height-1  downto 0 do
    begin
      Pixels[k] := PixPtr[j][i*3+2];
      Pixels[k+1] := PixPtr[j][i*3+1];
      Pixels[k+2] := PixPtr[j][i*3];
      k := k+3;
    end;
  end;
  glGenTextures(1,@Texture);
  glBindTexture(GL_TEXTURE_2D,Texture);
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,magFilter);
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,minFilter);
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,wrap);
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,wrap);
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_ENV_MODE,GL_MODULATE);
  if (minFilter = GL_LINEAR) or (minFilter = GL_NEAREST) then
    glTexImage2D(GL_TEXTURE_2D,0,3,Width,Height,0,GL_RGB,
               GL_UNSIGNED_BYTE,Pixels)
  else
    GLInit.gluBuild2DMipmaps(GL_TEXTURE_2D,3,
                            Width,
                            Height,
                            GL_RGB,
                            GL_UNSIGNED_BYTE,
                            Pixels);
  result := texture;
end;

Function LoadTextureFromBitmap(Bit:TBitmap;MinFilter:GLenum;
      MagFilter:GLenum;wrap:GLenum):GLuint;
var
  Px:TRapidPixels;
  PixPtr:TRapidPixelPointer;
begin
  ReadPixels(Bit,Px,PixPtr);
  result := LoadTextureFromPointer(PixPtr,Bit.Width,Bit.Height,
                                    MinFilter,MagFilter,Wrap);
end;

Function LoadTexture(FileName:String;MinFilter:GLenum;
          MagFilter:GLenum;wrap:GLenum):GLuint;
var
  Bit:TBitmap;
begin
  Bit:=TBitmap.Create;
  try
    Bit.PixelFormat := pf24Bit;
    Bit.loadfromFile(FileName);
    Result := LoadTextureFromBitmap(Bit,MinFilter,MagFilter,wrap);
  finally
    Bit.Free;
  end;
end;
Function LoadFontTextureFromPointer(PixPtr:TRapidPixelPointer;W,H:Integer;
  FontColor:TColor4ub;MinFilter:GLenum;MagFilter:GLenum;Wrap:GLenum):GLuint;
var
  Pixels:Array of Byte;
  i,j,k:Integer;
  Texture:GLUint;
begin
  SetLength(Pixels,H*W*4);
  k:=0;
   for j := 0 to H-1 do
   begin
     for i := 0 to  W -1 do
     begin
      if (PixPtr[j][i*3]=255) then
      begin
        Pixels[k]   := 0;
        Pixels[k+1] := 0;
        Pixels[k+2] := 0;
        Pixels[k+3] := 0;
      end
      else
      begin
        Pixels[k] := 255;
        Pixels[k+1] := 255;
        Pixels[k+2] := 255;
        Pixels[k+3] := 255-PixPtr[j][i*3];
      end;

      k := k+4;
    end;
  end;
  glGenTextures(1,@Texture);
  glBindTexture(GL_TEXTURE_2D,Texture);
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,magFilter);
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,minFilter);
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,wrap);
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,wrap);
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_ENV_MODE,GL_MODULATE);
  if (minFilter = GL_LINEAR) or (minFilter = GL_NEAREST) then
    glTexImage2D(GL_TEXTURE_2D,0,4,W,H,0,GL_RGBA,
               GL_UNSIGNED_BYTE,Pixels)
  else
    GLInit.gluBuild2DMipmaps(GL_TEXTURE_2D,4,W,H,GL_RGBA,GL_UNSIGNED_BYTE,Pixels);
  result := texture;
end;

Function LoadFontTextureFromBitmap(Bit:TBitmap;FontColor:TColor4ub;
        MinFilter:GLenum;MagFilter:GLenum;Wrap:GLenum):GLuint;
var
  PixPtr:TRapidPixelPointer;
  Pxs:TRapidPixels;
  W,H:Integer;
begin
  ReadPixels(Bit,Pxs,PixPtr);
  W:=Bit.Width;
  H:=Bit.Height;
  Result:=LoadFontTextureFromPointer(PixPtr,W,H,FontColor,MinFilter,MagFilter,Wrap);
end;

{ TOpenGLInit }

constructor TOpenGLInit.Create(Handle:THandle;ColorBits: Byte; DrawFlags: DWord);
begin
  FHDC := Handle;
  InitializeOpenGL(ColorBits,DrawFlags);
end;

procedure TOpenGLInit.Free;
begin
  TerminateOpenGL;
end;

procedure TOpenGLInit.InitializeOpenGL(ColorBits: Byte; DrawFlags: DWord);
var
  pfd:TPIXELFORMATDESCRIPTOR;
  pixelFormat:integer;
begin
  DC := GetDC(FHDC);
  if dc = 0 then
    DC := FHDC;
  with pfd do
  begin
    nSize:=sizeof(TPIXELFORMATDESCRIPTOR); // size
    nVersion:=1;                           // version
    dwFlags:=DrawFlags;                    // support double-buffering
    iPixelType:=PFD_TYPE_RGBA;             // color type
    cColorBits:=ColorBits;                 // preferred color depth
    cRedBits:=0;
    cRedShift:=0;                          // color bits (ignored)
    cGreenBits:=0;
    cGreenShift:=0;
    cBlueBits:=0;
    cBlueShift:=0;
    cAlphaBits:=0;
    cAlphaShift:=0;                        // no alpha buffer
    cAccumBits:=0;
    cAccumRedBits:=0;                      // no accumulation buffer,
    cAccumGreenBits:=0;                    // accum bits (ignored)
    cAccumBlueBits:=0;
    cAccumAlphaBits:=0;
    cDepthBits:=16;                        // depth buffer
    cStencilBits:=0;                       // no stencil buffer
    cAuxBuffers:=0;                        // no auxiliary buffers
    iLayerType:=PFD_MAIN_PLANE;            // main layer
    bReserved:=0;
    dwLayerMask:=0;
    dwVisibleMask:=0;
    dwDamageMask:=0;
  end;                    
  pixelFormat := ChoosePixelFormat(DC, @pfd);
  if (pixelFormat = 0) then
    exit;
  if (SetPixelFormat(DC, pixelFormat, @pfd) <> TRUE) then
    exit;
  hRc := wglCreateContext(DC);
  wglMakeCurrent(DC,HRC);
end;

procedure TOpenGLInit.SetPerspective(Degree, Height, Width: Integer;
  FarZ: Single);
begin
  glMatrixMode(GL_PROJECTION);
  gluPerspective(Degree,Width/Height,1,FarZ);
  glMatrixMode(GL_MODELVIEW);
end;

procedure TOpenGLInit.SetViewPort(Width, Height: Integer);
begin
  glViewPort(0,0,Width,Height);
end;

procedure TOpenGLInit.TerminateOpenGL;
begin
  wglMakeCurrent(DC,HRC);
  wglDeleteContext(hRc);
  ReleaseDC(FHDC,DC);
end;

{ TFPSCounter }

constructor TFPSCounter.Create;
begin
  stTime := GetTickCount;
  FFPS:=2;
end;

procedure TFPSCounter.FinishRender;
begin
  Frames := Frames+1;
  if Frames>10 then
  begin
    curTime := GetTickCount;
    fFPS := Frames/((curTime-stTime)/1000);
    Frames:=0;
    stTime := GetTickCount;
  end;
  if FFPS<2 then FFPS:=2;
end;

procedure TFPSCounter.free;
begin

end;

function TFPSCounter.GetSpeed: String;
var
  S:String;
begin
  str(FFPS:5:2,S);
  Result := S + ' fps';
end;

{ TCamera }

constructor TCamera.Create;
begin
  TurnP := 14;
  FSpeed := 4;
end;

procedure TCamera.GoAhead;
var
  PosV,DeltaX,DeltaZ:Single;
begin
  PosV := FSpeed;
  DeltaX :=0.1*posv*sin(pi/180*(Orientation.y));
  DeltaZ :=0.1*posv*cos(pi/180*(Orientation.y));
  Position.X := Position.X + deltax;
  Position.Z := Position.Z - deltaz;
end;

procedure TCamera.GoBack;
var
  PosV,DeltaX,DeltaZ:Single;
begin
  PosV := -FSpeed;
  DeltaX :=0.1*posv*sin(pi/180*(Orientation.y));
  DeltaZ :=0.1*posv*cos(pi/180*(Orientation.y));
  Position.X := Position.X + deltax;
  Position.Z := Position.Z - deltaz;
end;

procedure TCamera.LookDown;
begin
  Orientation.X := Orientation.X + TurnP*0.01745;
end;

procedure TCamera.LookUp;
begin
  Orientation.X := Orientation.X - TurnP*0.01745;
end;

procedure TCamera.LookUpDegress(Deg: Single);
begin
  Orientation.X := Orientation.X + Deg*0.01745;
end;

procedure TCamera.PowerOn;
begin
  glRotatef(Orientation.X,1,0,0);
  glRotatef(Orientation.Y,0,1,0);
  glRotatef(Orientation.Z,0,0,1);
  glTranslatef(-Position.X,-Position.Y,-Position.Z);
end;

procedure TCamera.TurnAngle(a : Single);
begin
  Orientation.y := Orientation.y+a;
end;

procedure TCamera.TurnLeft;
var
  Ang:Single;
begin
  ang := -TurnP*0.01745;
  Orientation.y := ang+Orientation.y;
end;

procedure TCamera.TurnRight;
var
  Ang:Single;
begin
  ang := TurnP*0.01745;
  Orientation.y := ang+Orientation.y;
end;

{ TRapidFont }

constructor TRapidFont.Create;
begin
  Bit := TBitmap.Create;
  lstW:=0;
  lstH:=0;
end;

procedure TRapidFont.Free;
begin
  glDeleteTextures(1,@TexFont);
  Bit.Free;
end;

procedure TRapidFont.SetFont(const Value: TFont);
begin
  Bit.Canvas.Font.Assign(Value) ;
end;

procedure TRapidFont.SetText(const Value: String);
var
  nH,nW:Integer;
  SizeChanged:Boolean;
  txtRect:TRect;
begin
  FText := Value;
  SizeChanged:=False;
  glDeleteTextures(1,@TexFont);
  Bit.Canvas.Font.Color := clBlack;
  FRealHeight:=TextHeight(FText);
  FRealWidth := TextWidth(FText);
  if Pos('&',FText)>0 then
    FRealWidth :=FRealWidth - Bit.Canvas.TextWidth('&'); 
  nW := CalcWidth(FRealWidth);
  nH := CalcHeight(FRealHeight);
  if  nW <>lstW then
  begin
    Bit.Width := nW;
    SizeChanged:=True;
  end;
  if nH<>lstH then
  begin
    Bit.Height := nH;
    SizeChanged:=True;
  end;
  if SizeChanged then
    ReadPixels(Bit,Pixs,PixPtr);
  Bit.Canvas.Brush.Style := bsSolid;
  Bit.Canvas.FillRect(Bit.Canvas.ClipRect);
  if not ClipText then
    txtRect := Rect(0,0,FRealWidth,FRealHeight)
  else
    txtRect := rect(0,0,ClipWidth,ClipHeight);
    // If Bit.Canvas.Font.Name <>'Wingdings 2' then
    DrawText(Bit.Canvas.Handle,PChar(FText),Length(FText),
           txtRect,0);
    //  else
    //  Bit.Canvas.TextOut(0,0,FText);
  TexFont:=LoadFontTextureFromPointer( PixPtr,nW,nH,Color4ub(0,0,0,255),
                                    GL_LINEAR_MIPMAP_LINEAR,GL_LINEAR,GL_REPEAT);
end;


function TRapidFont.TextWidth(S:String):Integer;
begin
  Result := Bit.Canvas.TextWidth(S);
end;

function TRapidFont.TextHeight(S:String):Integer;
begin
  Result := Bit.Canvas.TextHeight(S);
end;

procedure TRapidFont.TextOut(x, y: Integer);
var
  W,H:Integer;
begin
  W:=Bit.Width;
  H:=Bit.Height;
  glPushAttrib(GL_ALL_ATTRIB_BITS);
  glDisable(GL_CULL_FACE);
  glDisable(GL_DEPTH_TEST);
  glDisable(GL_LIGHTING);
  glDisable(GL_FOG);
  glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
  glEnable(GL_BLEND);
  glEnable(GL_TEXTURE_2D);
  if glIsEnabled(GL_TEXTURE_2D) then
  begin
    glBindTexture(GL_TEXTURE_2D,texFont);
    glColor4ub(FColor.R,FColor.G ,FColor.B,FColor.A);
    glBegin(GL_QUADS);
    glTexCoord2f(0,0);
    glVertex2i(x,y);
    glTexCoord2f(1,0);
    glVertex2i(x+W,y);
    glTexCoord2f(1,1);
    glVertex2i(x+W,y+H);
    glTexCoord2f(0,1);
    glVertex2i(x,y+H);
    glEnd;
  end;
  glPopAttrib;
end;

function TRapidFont.CalcHeight(aH: Integer): Integer;
begin
  result:=calcWidth(ah);
end;

function TRapidFont.CalcWidth(aW: Integer): Integer;
begin
  if aw>512 then
    result:=1024
  else
  begin
    if aw>256 then
      result:=512
    else
    begin
      if aw>128 then
        result:=256
      else
      begin
        if aw>64 then
          result:=128
        else
        begin
          if aw>32 then
             result:=64
          else
          begin
            if aw>16 then
              result:=32
            else
              result:=16;
          end;
        end;
      end;
    end;
  end;
end;

function TRapidFont.GetHeight: Integer;
begin
  result:=Bit.Height;
end;

function TRapidFont.GetWidth: Integer;
begin
  Result:=Bit.Width;
end;


procedure TRapidFont.AdvancedFrame(TimeDelta: Integer;
  Anim: TRapidFontAnim;Speed:Integer);
begin

end;

function TRapidFont.GetFont: TFont;
begin
  result := Bit.Canvas.Font;
end;

end.

