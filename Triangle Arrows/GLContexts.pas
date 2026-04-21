unit GLContexts;

{ (c)2004, by Paul TOTH <tothpaul@free.fr> }

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

{-$DEFINE CHECKTEXTURES}

interface

uses
 Windows,Classes,SysUtils, Graphics,
 DelphiGL, GLTypes, GLUtils;

type
// Class automatiquement notifiée lors de la création/Destruction du contexte OpenGL
 TGLNotified=class
 private
  fOwnerList:TList;
  fCreated:boolean;
 protected
  procedure CreateGL;  virtual;
  procedure DestroyGL; virtual;
 public
  constructor Create; virtual;
  destructor Destroy; override;
 end;

// Class permettant d'associer une notification OpenGL a une méthode
 TGLNotifier=class(TGLNotified)
 private
  EOnCreate :TNotifyEvent;
  EOnDestroy:TNotifyEvent;
 protected
  procedure CreateGL;  override;
  procedure DestroyGL; override;
 public
  constructor Create(OnCreate,OnDestroy:TNotifyEvent); reintroduce;
 end;

// Contexte OpenGL, probablement une seule instance par application
 TGLContext=class
 private
  fChilds:TList;   // Liste des objets à notifier (TGLNotified)
  fWnd   :THandle; // Window Handle
  fDC    :THandle; // Device Context
  fGL    :THandle; // OpenGL Context
  fWidth :integer;
  fHeight:integer;
  fColor :TColor4f;
  fDepth :single;
  fSwaped:boolean;
  fZNear :double;
  fZFar  :double;
  fFieldOfView:double;
 public
  constructor Create(ZNear,ZFar,FieldOfView:double);
  destructor Destroy; override;
  procedure Setup(HWnd:THandle; AWidth,AHeight:integer);
  procedure CreateFontList(hFont:HFont; First,Count:integer);
  procedure Resize(AWidth,AHeight:integer);
  procedure Project2D;
  procedure Project3D;
  procedure DestroyGL;
  function Invalidate:boolean;
  procedure Swap;
  property Width:integer read fWidth;
  property Height:integer read fHeight;
 end;

 TGLTexture=class(TGLNotified)
 private
  fHandle  :integer;
  fLoaded  :boolean;
  fFileName:string;
  fTransparent:integer;
 protected
  procedure CreateGL;  override;
  procedure DestroyGL; override;
 public
  constructor Create(AFileName:string; Transparent:TColor=clNone); reintroduce;
  procedure Bind;
 end;

var
 GLContext:TGLContext;

implementation

{$IFDEF CHECKTEXTURES}
uses
 GLObjects;
{$ENDIF}

//----------------------------------------------------------------------------//

var
 NotifyList:TList=nil;

constructor TGLNotified.Create;
begin
 if NotifyList=nil then NotifyList:=TList.Create;
 fOwnerList:=NotifyList;
 fOwnerList.Add(Self);
end;

destructor TGLNotified.Destroy;
begin
 if fCreated then DestroyGL;
 fOwnerList.Remove(Self);
 inherited;
end;

procedure TGLNotified.CreateGL;
begin
 fCreated:=True;
end;

procedure TGLNotified.DestroyGL;
begin
 fCreated:=False;
end;

//----------------------------------------------------------------------------//
constructor TGLNotifier.Create(OnCreate,OnDestroy:TNotifyEvent);
begin
 EOnCreate:=OnCreate;
 EOnDestroy:=OnDestroy;
 inherited Create;
end;

procedure TGLNotifier.CreateGL;
begin
 inherited;
 if Assigned(EOnCreate) then EOnCreate(Self);
end;

procedure TGLNotifier.DestroyGL;
begin
 inherited;
 if Assigned(EOnDestroy) then EOnDestroy(Self);
end;

//----------------------------------------------------------------------------//

constructor TGLContext.Create(ZNear,ZFar,FieldOfView:double);
begin
 if NotifyList=nil then NotifyList:=TList.Create;
 fChilds:=NotifyList;
 GLContext:=Self;
 fDepth:=1;
 fZNear:=ZNear;
 fZFar :=ZFar;
 fFieldOfView:=FieldOfView;
end;

destructor TGLContext.Destroy;
{$IFDEF CHECKTEXTURES}
var
 i:integer;
{$ENDIF} 
begin
 DestroyGL;
 if fChilds.Count>0 then begin
 {$IFDEF CHECKTEXTURES}
  AllocConsole;
  for i:=0 to fChilds.Count-1 do begin
   WriteLn(TObject(fChilds[i]).ClassName);
   if TObject(fChilds[i]) is TGLTexture then begin
    with TGLTexture(fChilds[i]) do WriteLn(' ',FileName,' [',Locks,']');
   end;
  end;
  ReadLn;
 {$ENDIF}
  raise Exception.Create('GLContext childs list not empty ('+IntToStr(fChilds.Count)+') at destruction');
 end;
 if NotifyList=fChilds then NotifyList:=nil;
 fChilds.Free;
 GLContext:=nil;
 inherited;
end;

procedure TGLContext.Setup(HWnd:THandle; AWidth,AHeight:integer);
var
 pfd:TPIXELFORMATDESCRIPTOR;
 pixelformat:integer;
 i:integer;
begin
 DestroyGL;
 fWnd:=HWnd;
 fDC:=GetDC(fWnd);
 if fDC=0 then RaiseLastOSError;
 FillChar(pfd,SizeOf(pfd),0);
 pfd.nSize       := sizeof(pfd);
 pfd.nVersion    := 1;
 pfd.dwFlags     := PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER;
 pfd.iLayerType  := PFD_MAIN_PLANE;
 pfd.iPixelType  := PFD_TYPE_RGBA;
 pfd.cColorBits  := 32;
 pfd.iLayerType  := PFD_MAIN_PLANE;
 pfd.cDepthBits  := 32;
 pixelformat:=ChoosePixelFormat(fDC, @pfd);
 if PixelFormat=0 then RaiseLastOSError;
 if not SetPixelFormat(fDC, pixelformat, @pfd) then RaiseLastOSError;
 fGL:=wglCreateContext(fDC);
 wglMakeCurrent(fDC,fGL);
 with fColor do glClearColor(Red,Green,Blue,Alpha);
 glClearDepth(fDepth);
 Resize(AWidth,AHeight);
 glClear(GL_COLOR_BUFFER_BIT);
 for i:=fChilds.Count-1 downto 0 do TGLNotified(fChilds[i]).CreateGL;
 fSwaped:=True;
end;

procedure TGLContext.CreateFontList(hFont:HFont; First,Count:integer);
begin
 SelectObject(fDC,hFont);
// wglUseFontBitmaps(fDC,First,Count,First);
 wglUseFontOutlines(fDC,First,Count,First,0,0,WGL_FONT_POLYGONS,nil);
end;

procedure TGLContext.Resize(AWidth,AHeight:integer);
begin
 if fGL<>0 then begin
  fWidth :=AWidth;
  fHeight:=AHeight;
  glViewport(0, 0, fWidth, fHeight);
 end;
end;

procedure TGLContext.Project2D;
begin
 if fGL<>0 then begin
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  glOrtho(0, fWidth, fHeight, 0, -1, 1);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
 end;
end;

procedure TGLContext.Project3D;
begin
 if (fGL<>0)and(fHeight<>0) then begin
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  gluPerspective(fFieldOfView,fWidth/fHeight,fZNear,fZFar);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
 end;
end;

procedure TGLContext.DestroyGL;
var
 i:integer;
begin
 if fGL<>0 then begin
  for i:=fChilds.Count-1 downto 0 do TGLNotified(fChilds[i]).DestroyGL;
  wglMakeCurrent(fDC,0);
  wglDeleteContext(fGL);
  fGL:=0;
 end;
 if fDC<>0 then begin
  ReleaseDC(fWnd,fDC);
  fDC:=0;
 end;
end;

function TGLContext.Invalidate:boolean;
begin
 Result:=(fGL<>0);
 if Result {and fSwaped} then begin
  fSwaped:=False;
  InvalidateRect(fWnd,nil,False);
  //UpdateWindow(fWnd); //??!!
 end;
end;

procedure TGLContext.Swap;
begin
 if fDC=0 then exit;
// glFlush;
 SwapBuffers(fDC);
 ValidateRect(fWnd,nil);
 fSwaped:=True;
end;

//----------------------------------------------------------------------------//
constructor TGLTexture.Create(AFileName:string; Transparent:TColor=clNone);
begin
 inherited Create;
 fFileName:=AFileName;
 fTransparent:=Transparent;
 if (GLContext<>nil)and(GLContext.fGL<>0) then CreateGL;
end;

procedure TGLTexture.CreateGL;
var
 Bitmap:TBitmap;
 p :pointer;
 pi:pinteger;
 x,y,c:integer;
 w,h:integer;
 w2:integer;
begin
 inherited;
 if fLoaded=False then begin
  glGenTextures(1,@fHandle);
  fLoaded:=True;
 end;
 glBindTexture(GL_TEXTURE_2D,fHandle);
 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
 Bitmap:=TBitmap.Create;
 try
  Bitmap.LoadFromFile(fFileName);
  Bitmap.PixelFormat:=pf32Bit;
  w:=Bitmap.width; w2:=PowerOf2(w);
  h:=Bitmap.Height;
  Bitmap.Width :=w2;
  Bitmap.Height:=PowerOf2(h);
  p:=Bitmap.ScanLine[Bitmap.Height-1];
  pi:=p;
  for y:=h to Bitmap.Height-1 do begin
   FillChar(pi^,4*w2,0);
   inc(pi,w2);
  end;
  for y:=0 to h-1 do begin
   for x:=0 to w-1 do begin
    c:=(pi^) and $ffffff;
    if c=fTransparent then begin
     c:=0;
    end else begin
     c:=integer($ff000000)+c and $00ff00+ c shr 16+(c and $ff) shl 16;
    end;
    pi^:=c;
    inc(pi);
   end;
   FillChar(pi^,4*(w2-w),0);
   inc(pi,w2-w);
  end;
  glTexImage2D(GL_TEXTURE_2D, 0, 4, Bitmap.Width, Bitmap.Height,0, GL_RGBA, GL_UNSIGNED_BYTE,p);
 finally
  Bitmap.Free;
 end;
end;

procedure TGLTexture.DestroyGL;
begin
 if fLoaded then begin
  glDeleteTextures(1,fHandle);
  fLoaded:=False;
 end;
 inherited;
end;

procedure TGLTexture.Bind;
begin
 glBindTexture(GL_TEXTURE_2D,fHandle);
end;

end.
