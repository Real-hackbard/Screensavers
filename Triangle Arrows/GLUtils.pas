unit GLUtils;

{ (c)2001-2002, by Paul TOTH <tothpaul@free.fr> }

{
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
}

interface

{-$DEFINE REVERSE_BITMAP}

uses
 Windows,Graphics,Math,
 DelphiGL, FileMaps;

procedure gluColor(Color:integer);
procedure gluCircle(x,y,z,Radius:Single; Steps:integer);
procedure gluArc(x,y,z,Radius:Single; Steps, First,Last:integer);
procedure gluArrow(Len,Width:Single);
procedure gluJauge(x,y,width,height,value,max,color:integer);
procedure glRectangle(x1,y1,x2,y2,color:integer);
procedure gluCube(x,y,z,size:single);

Function PowerOf2(Target:integer):integer;
procedure LoadBitmapTexture(filename:string; id:integer);
procedure TextOut(x,y:integer; s:string);
procedure glTextOut(const s:string);

function Bitmap256ToTexture(FileName:string; TransparentColor:integer):integer;
function BitmapToTexture(Bitmap:TBitmap; Transparent:TColor):integer;

implementation

//----------------------------------------------------------------------------//
procedure rgb2bgr(p:pointer;i:integer);
var
 rgb:pchar;
 t:char;
 x:integer;
begin
 rgb:=p;
 for x:=0 to i-1 do begin
   t:=rgb[0];
   rgb[0]:=rgb[2];
   rgb[2]:=t;
   rgb[3]:=#0;
   inc(integer(rgb),4);
  end;
end;

function Bitmap256ToTexture(FileName:string; TransparentColor:integer):integer;
var
 map:TFileMapping;
 bfh:^TBitmapFileHeader;
 bih:^TBitmapInfoHeader;
 pal:array[#0..#255] of integer;
 pix:pchar;
 tex:array of integer;
 x,y:integer;
 pyw:integer;
 tyw:integer;
begin
 map:=TFileMapping.Create(filename);
 try
  bfh:=map.Base;
  bih:=map.Data(SizeOf(bfh^));
  if bih.biBitCount<>8 then exit;
  move(map.data(SizeOf(bfh^)+bih.biSize)^,pal,sizeof(pal)); // get palette
  rgb2bgr(@pal,256);
  for x:=0 to 255 do if pal[chr(x)]=TransparentColor then pal[chr(x)]:=-1;
  SetLength(tex,bih.biWidth*bih.biHeight);

  pix:=map.data(bfh.bfOffBits);
 {$IFDEF REVERSE_BITMAP}
  pyw:=bih.biHeight*bih.biWidth;
 {$ELSE}
  pyw:=0;
 {$ENDIF}
  tyw:=0;
  for y:=0 to bih.biHeight-1 do begin
  {$IFDEF REVERSE_BITMAP}
   dec(pyw,bih.biWidth);
  {$ENDIF}
   for x:=0 to bih.biWidth-1 do begin
    tex[tyw+x]:=pal[pix[pyw+x]];
   end;
   inc(tyw,bih.biWidth);
  {$IFnDEF REVERSE_BITMAP}
   inc(pyw,bih.biWidth);
  {$ENDIF}
  end;

  glGenTextures(1,@Result);
  glBindTexture(GL_TEXTURE_2D,Result);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexImage2D(GL_TEXTURE_2D, 0, 4, bih.biWidth, bih.biHeight,0, GL_RGBA, GL_UNSIGNED_BYTE,@tex[0]);

  Finalize(Tex);
 finally
  map.Free;
 end;
end;

function BitmapToTexture(Bitmap:TBitmap; Transparent:TColor):integer;
var
 p :pointer;
 pi:pinteger;
 x,y,c:integer;
begin
 glGenTextures(1,@Result);
 glBindTexture(GL_TEXTURE_2D,Result);
 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
 Bitmap.PixelFormat:=pf32Bit;
 p:=Bitmap.ScanLine[Bitmap.Height-1];
 pi:=p;
 for y:=0 to Bitmap.Height-1 do begin
  for x:=0 to Bitmap.Width-1 do begin
   c:=(pi^) and $ffffff;
   if c=Transparent then begin
    c:=clPurple;
   end else begin
    c:=integer($ff000000)+c and $00ff00+ c shr 16+(c and $ff) shl 16;
   end;
   pi^:=c;
   inc(pi);
  end;
 end;
 glTexImage2D(GL_TEXTURE_2D, 0, 4, Bitmap.Width, Bitmap.Height,0, GL_RGBA, GL_UNSIGNED_BYTE,p);
 //Bitmap.SaveToFile('c:\windows\bureau\test.bmp');
end;

//----------------------------------------------------------------------------//

procedure gluCircle(x,y,z,Radius:Single; Steps:integer);
var
 i:integer;
 a,s,c:Extended;
begin
 glBegin(GL_LINE_LOOP);
// glVertex3f(x,y,z);
 a:=2*PI/Steps;
 for i:=0 to Steps-1 do begin
  SinCos(i*a,s,c);
  glVertex3f(x+Radius*c,y+Radius*s,z);
 end;
 //glVertex3f(x+Radius,y,z);
 glEnd;
end;

procedure gluArc(x,y,z,Radius:Single; Steps, First,Last:integer);
var
 i:integer;
 a,s,c:Extended;
begin
 glBegin(GL_LINE_LOOP);
 a:=2*PI/Steps;
 for i:=First to Last do begin
  SinCos(i*a,s,c);
  glVertex3f(x+Radius*c,y+Radius*s,z);
 end;
 glEnd;
end;

procedure gluArrow(Len,Width:Single);
begin
 glBegin(GL_QUADS);
  glVertex3f(0,Len,0);
  glVertex3f(-Width,0,0);
  glVertex3f(0,-Width,0);
  glVertex3f(+Width,0,0);
 glEnd;
end;

procedure gluJauge(x,y,width,height,value,max,color:integer);
var
 x1,y1,x2,y2:integer;
begin
 glRectangle(x-1,y-1,x+width+1,y+height+1,$808080);
 if width>height then begin
  x1:=x;
  y1:=y;
  x2:=x+width-(value*width) div max;
  y2:=y+height;
 end else begin
  x1:=x;
  y1:=y+height-(value*height) div max;
  x2:=x+width;
  y2:=y+height;
 end;
 glBegin(GL_TRIANGLE_STRIP);
  glColor3f(1,1,1);
  glVertex2i(x1,y1);
  gluColor(color);
  glVertex2i(x1,y2);
  glVertex2i(x2,y1);
  gluColor((color and $FEFEFE) shr 1);
  glVertex2i(x2,y2);
 glEnd;
end;

procedure gluColor(color:integer);
begin
 glColor4f(
  ((color shr 16) and 255)/255,
  ((color shr 8 ) and 255)/255,
  ((color       ) and 255)/255,
  ((color shr 24) and 255)/255
 );
end;

procedure glRectangle(x1,y1,x2,y2,color:integer);
begin
 gluColor(Color);
 glBegin(GL_QUADS);
  glVertex2i(x1,y1);
  glVertex2i(x1,y2);
  glVertex2i(x2,y2);
  glVertex2i(x2,y1);
 glEnd;
end;

procedure gluCube(x,y,z,size:single);
begin
 glBegin(GL_LINE_LOOP);
  glVertex3f(x-size,y-size,z-size);
  glVertex3f(x+size,y-size,z-size);
  glVertex3f(x+size,y+size,z-size);
  glVertex3f(x-size,y+size,z-size);
 glEnd;
 glBegin(GL_LINE_LOOP);
  glVertex3f(x-size,y-size,z+size);
  glVertex3f(x+size,y-size,z+size);
  glVertex3f(x+size,y+size,z+size);
  glVertex3f(x-size,y+size,z+size);
 glEnd;
end;

Function PowerOf2(Target:integer):integer;
 begin
  Result:=1;
  while Result<Target do Result:=Result shl 1;
 end;

procedure LoadBitmapTexture(filename:string; id:integer);
var
 map:TFileMapping;
 bih:^TBitmapInfoHeader;
 bfh:^TBitmapFileHeader;
 pal:array[#0..#255] of integer;
 pix:pchar;
 tex:array of integer;
 x,y:integer;
 pyw:integer;
 tyw:integer;
begin
 map:=TFileMapping.Create(filename);

 bih:=map.Data(14);
 move(map.data(14+bih.biSize)^,pal,sizeof(pal)); // get palette
 rgb2bgr(@pal,256);
 setlength(tex,bih.biWidth*bih.biHeight*sizeof(integer));

 bfh:=map.Base;
 pix:=map.data(bfh.bfOffBits);
 pyw:=bih.biHeight*bih.biWidth;
 tyw:=0;
 for y:=0 to bih.biHeight-1 do begin
  dec(pyw,bih.biWidth);
  for x:=0 to bih.biWidth-1 do begin
   tex[tyw+x]:=pal[pix[pyw+x]];
  end;
  inc(tyw,bih.biWidth);
 end;

 glBindTexture(GL_TEXTURE_2D,id);
 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
 glTexImage2D(GL_TEXTURE_2D, 0, 4, bih.biWidth, bih.biHeight,0, GL_RGBA, GL_UNSIGNED_BYTE,@tex[0]);

 Finalize(tex);

 map.Free;
end;

procedure TextOut(x,y:integer; s:string);
 begin
  glRasterPos2f(x,y);
  glCallLists(Length(s),GL_UNSIGNED_BYTE,pchar(s));
 end;

procedure glTextOut(const s:string);
begin
 glPushMatrix;
  glCallLists(Length(s),GL_UNSIGNED_BYTE,@s[1]);
 glPopMatrix;
end;


end.
