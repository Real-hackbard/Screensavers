unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, GLInit, RapidUI, untObjModel, ExtCtrls, OpenGL, Math;

type
  TForm1 = class(TForm)
    tmrRender: TTimer;
    tmrKey: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tmrRenderTimer(Sender: TObject);
    procedure tmrKeyTimer(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    procedure SetView;
    procedure SetLights;
    procedure RenderScene;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  glInitor : TOpenGLInit;
  objMdl:TObjModel;
  yDeg,xDeg:Single;
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
  MakeFormFullscreenAcrossAllMonitors(Form1);
  GetCursorPos(OldPos); // Initialposition

  objMdl := TObjModel.Create;
  GLinitor := TOpenGLInit.Create(Handle,24,stdDoubleBuffer);
  SetView;

  // Load Object from File
  // if OpenDialog1.Execute then
  //   objMdl.LoadFromFile(OpenDialog1.FileName);

  objMdl.LoadFromFile(PChar(ExtractFilePath(Application.ExeName) + 'head.obj'));

  SetLights;
end;

procedure TForm1.SetLights;
var
  AmbientLight,DiffuseLight,SpecularLight:array[1..4] of Single;
  LightPos:array[1..4] of Single;
  SpotDir:array[1..3] of Single;
begin
  AmbientLight[1]:=0.3;
  AmbientLight[2]:=0.3;
  AmbientLight[3]:=0.3;
  AmbientLight[4]:=1;
  DiffuseLight[1]:=1;
  DiffuseLight[2]:=1;
  DiffuseLight[3]:=1;
  DiffuseLight[4]:=1;
  SpecularLight[1]:=0.4;
  SpecularLight[2]:=0.4;
  SpecularLight[3]:=0.4;
  SpecularLight[4]:=1;
  LightPos[1]:= 100000;
  LightPos[2]:=100000;
  LightPos[3]:=400;
  LightPos[4]:=1;
  glEnable(GL_LIGHTING);
  glLightfv(GL_LIGHT0,GL_AMBIENT,@AmbientLight);
  glLightfv(GL_LIGHT0,GL_DIFFUSE,@DiffuseLight);
  glLightfv(GL_LIGHT0,GL_SPECULAR,@SpecularLight);
  glLightfv(GL_LIGHT0,GL_POSITION,@LightPos);
  glEnable(GL_LIGHT0);
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  objMdl.Free;
  glInitor.Free;
end;

procedure TForm1.SetView;
begin
  glClearColor(0,0,0,0);
  glViewPort(0,0,ClientWidth,ClientHeight);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  gluPerspective(20,ClientWidth/ClientHeight,1,2200);
  glMatrixMode(GL_MODELVIEW);
end;

procedure TForm1.RenderScene;
begin
  glLoadIdentity;
  glShadeModel(GL_SMOOTH);
  glEnable(GL_DEPTH_TEST);
  glCullFace(gl_front);
  glFrontFace(GL_CW);
  glEnable(GL_CULL_FACE);
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  glTranslate(0,0,-250);
  glRotate(yDeg,0,1,0);
  glRotate(xDeg,1,0,0);
  SetLights;
  glEnable(GL_TEXTURE_2D);
  objMdl.Render;
  swapbuffers(wglGetCurrentDC);
end;

procedure TForm1.tmrRenderTimer(Sender: TObject);
begin
  yDeg:=yDeg+1;
  RenderScene;
end;

procedure TForm1.tmrKeyTimer(Sender: TObject);
var
  NewPos: TPoint;
begin
  GetCursorPos(NewPos);
  if (NewPos.X <> OldPos.X) or (NewPos.Y <> OldPos.Y) then
  begin
    // Mouse moved
    Close();
  end;
  
  { adjust object with cusors
  if GetAsyncKeyState(VK_LEFT)<>0 then
  begin
    yDeg:=yDeg+1;
  end;
  if GetAsyncKeyState(VK_RIGHT)<>0 then
  begin
    yDeg:=yDeg-1;
  end;
  if GetAsyncKeyState(VK_UP)<>0 then
  begin
    xDeg:=xDeg+1;
  end
  else if GetAsyncKeyState(VK_DOWN)<>0 then
  begin
    xDeg:=xDeg-1;
  end;
  }
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  SetView;
end;

procedure TForm1.FormClick(Sender: TObject);
begin
  Close();
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  Close();
end;

end.
