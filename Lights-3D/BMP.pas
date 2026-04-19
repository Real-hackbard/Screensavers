unit BMP;

interface

uses Windows, OpenGL, SysUtils, Graphics;

function LoadBMP(Bitmap: TBitmap): GLuInt;

procedure glGenTextures(N: GLSizei; Textures: PGLuInt); stdcall; external opengl32;
procedure glBindTexture(Target: GLEnum; Texture: GLuInt); stdcall; external opengl32;
function gluBuild2DMipmaps(Target: GLEnum; Components: GLInt; Width: GLInt; Height: GLInt; Format: GLEnum; _Type: GLEnum; Data: Pointer): GLInt; stdcall; external glu32;

implementation

function LoadBMP(Bitmap: TBitmap): GLuInt;
type
  TPixel = array[0..3] of Byte;
var
  X, Y: Integer;
  Src: TPixel;            { Source pixel }
  Dst: ^TPixel;           { Destination pixel }
  Data: Pointer;          { Texture data }
begin
  { Assign memory for the texture data }
  GetMem(Data, Bitmap.Width * Bitmap.Height * 4);

  { Start copying at the first pixel location }
  Dst := Data;

  for X := 0 to Bitmap.Width - 1 do
    for Y := 0 to Bitmap.Height - 1 do begin
      { Get the value of the pixel at (X, Y) }
      Src := TPixel(Bitmap.Canvas.Pixels[X, Y]);
      { Copy source pixel to destination pixel }
      Move(Src, Dst^, 4);
      { Increment the destination }
      Inc(Dst);
    end;

  { Create an OpenGL texture object }
  glGenTextures(1, @Result);
  glBindTexture(GL_TEXTURE_2D, Result);
  gluBuild2DMipmaps(GL_TEXTURE_2D, 4, Bitmap.Width, Bitmap.Height, GL_RGBA,
    GL_UNSIGNED_BYTE, Data);

  { Free the texture data }
  FreeMem(Data);
end;

end.


