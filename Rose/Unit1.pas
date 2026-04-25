unit Unit1;

interface

uses
  Windows, SysUtils, Classes, Graphics, Forms, OpenGL, Utils, TriD, Dialogs,
  Math, ExtCtrls;

type
  TSurface=class
    LocalRepere:TRepere;
    Vertexes:array of array of TVertex;
    na,nb:integer;
    constructor Create(r:TRepere;_na,_nb:integer);
    procedure MakeNormal;
    procedure DrawVertex(v:TVertex);
    procedure Draw;virtual;
    destructor Destroy;override;
  end;

  TPetale=class(TSurface)
    rz,t1,t2,s1,s2,r1,r2,z1:GlFloat;
    Color1,Color2:TVect;
    Openings,Thetas1,Thetas2:array of GlFloat;
    LocalRepere:TRepere;
    constructor Create(r:TRepere;_na,_nb:integer;
    o1,o2,_t1,_t2:GlFloat;c1,c2:TVect);
    procedure AdjustParam(a,b:integer);
    function Vertex(x,y:GlFloat):TVect;
    procedure MakeVertexes;
    destructor Destroy;override;
  end;

  TTige=class(TSurface)
    Color:TVect;
    Concav:TVect;
    ButRepere:TVect;
    Feuilles:TList;
    constructor Create(r:TRepere;_na,_nb:integer;
    con,col:TVect;NF:integer);
    procedure Draw;override;
    destructor Destroy;override;
  end;

  TFeuille=class(TSurface)
  end;

  TBoutton=class(TSurface)
    Petales:TList;
    constructor Create(p,u,v,w:TVect);
    procedure Draw;override;
    destructor Destroy;override;
  end;

  TForm1 = class(TForm)
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
  public
    t:cardinal;
    AmbientMaterial:array[0..3] of GLFloat;
    DiffuseMaterial:array[0..3] of GLFloat;
    SpecularMaterial:array[0..3] of GLFloat;
    lightPosition:array[0..3] of GLFloat;
    Stop:bool;
    Timing:integer;
    IdTexture:integer;
    PTexture:PChar;
    Centre:TVect;
    Running:bool;
    Tige:TTige;
    procedure MainLoop;
    procedure DrawAll;
    procedure ExtractTexFromBitmap(bitmap:tbitmap);
  end;

var
  Form1: TForm1;
  OldPos: TPoint;

const
  GL_VERTEX_ARRAY                   = $8074;
  AmbientLight:array[0..3] of GLfloat=(1,1,1,1);
  DiffuseLight:array[0..3] of GLfloat=(1,1,1,1);
  SpecularLight:Array[0..3] of GLfloat=(1,1,1,1);

  Tcoord:array[0..7,0..2] of GlFloat=
        ((-0.5,-0.5,-0.5),
        (0.5,-0.5,-0.5),
        (0.5,0.5,-0.5),
        (-0.5,0.5,-0.5),
        (-0.5,-0.5,0.5),
        (0.5,-0.5,0.5),
        (0.5,0.5,0.5),
        (-0.5,0.5,0.5));

  Tcolors:array[0..5,0..2] of GlFLoat=
        ((1.0,0.0,0.0),
        (0.0,1.0,0.0),
        (0.0,0.0,1.0),
        (0.0,1.0,1.0),
        (1.0,1.0,0.0),
        (1.0,0.0,1.0));

  Tnum:array[0..5,0..3] of GLubyte=
    ((0,1,2,3),
    (1,5,6,2),
    (4,5,6,7),
    (0,4,7,3),
    (0,1,5,4),
    (2,6,7,3));

implementation

{$R *.dfm}
{$R RTex.RES}


Procedure glBindTexture(target:GLEnum;texture:GLuint);Stdcall;External 'OpenGL32.dll';
Procedure glGenTextures(n:GLsizei;Textures:PGLuint);Stdcall;External 'OpenGL32.dll';
Procedure glDeleteTextures(n:GLsizei;textures: PGLuint);Stdcall;External 'OpenGL32.dll';

constructor TSurface.Create(r:TRepere;_na,_nb:integer);
var
  a:integer;
begin
  LocalRepere:=r;
  setlength(Vertexes,0);
  na:=_na;
  nb:=_nb;
  setlength(Vertexes,na);

  for a:=0 to na-1 do
    setlength(vertexes[a],nb);
end;

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

procedure TSurface.MakeNormal;
var
  a,b:integer;
begin
  for a:=0 to high(Vertexes) do begin
    if a=0 then begin
      for b:=0 to high(Vertexes[0]) do begin
        if b=0 then
          Vertexes[0][0].n:=UnitV(Crossp(Sub(Vertexes[0][1].p,Vertexes[0][0].p),
                                         Sub(Vertexes[1][0].p,Vertexes[0][0].p)))
        else
          Vertexes[0][b].n:=UnitV(Crossp(Sub(Vertexes[0][b].p,Vertexes[0][b-1].p),
                                         Sub(Vertexes[1][b].p,Vertexes[0][b].p)));
      end;
    end else begin
      for b:=0 to high(Vertexes[0]) do begin
        if b=0 then
          Vertexes[a][0].n:=UnitV(Crossp(Sub(Vertexes[a][1].p,Vertexes[a][0].p),
                                         Sub(Vertexes[a][0].p,Vertexes[a-1][0].p)))
        else
          Vertexes[a][b].n:=UnitV(Crossp(Sub(Vertexes[a][b].p,Vertexes[a][b-1].p),
                                         Sub(Vertexes[a][b].p,Vertexes[a-1][b].p)));
      end;
    end;
  end;
end;

procedure TSurface.DrawVertex(v:TVertex);
var
  u:TVect;
begin
  Form1.DiffuseMaterial[0]:=v.c.x;
  Form1.DiffuseMaterial[1]:=v.c.y;
  Form1.DiffuseMaterial[2]:=v.c.z;
  glMaterialfv(GL_FRONT_AND_BACK,GL_DIFFUSE,@Form1.DiffuseMaterial);
  Form1.AmbientMaterial[0]:=Form1.DiffuseMaterial[0]*0.2;
  Form1.AmbientMaterial[1]:=Form1.DiffuseMaterial[1]*0.2;
  Form1.AmbientMaterial[2]:=Form1.DiffuseMaterial[2]*0.2;
  glMaterialfv(GL_FRONT_AND_BACK,GL_AMBIENT,@Form1.AmbientMaterial);
  u:=Repere(v.n,Vect(0,0,0),LocalRepere.x,LocalRepere.y,LocalRepere.z);
  glNormal3f(u.x,u.y,u.z);
  u:=Repere(v.p,LocalRepere.p,LocalRepere.x,LocalRepere.y,LocalRepere.z);
  glVertex3f(u.x,u.y,u.z);
end;

procedure TSurface.Draw;
var
  a,b:integer;
begin
  if high(Vertexes)<1 then Exit;
  for a:=0 to high(Vertexes)-1 do begin
    glBegin(GL_QUAD_STRIP);
    for b:=0 to high(Vertexes[0]) do begin
      glTexCoord2f(a/(na-1),b/(nb-1));
      DrawVertex(Vertexes[a][b]);
      glTexCoord2f((a+1)/(na-1),b/(nb-1));
      DrawVertex(Vertexes[a+1][b]);
    end;
    glEnd;
  end;
end;

destructor TSurface.Destroy;
var
  a:integer;
begin
  for a:=0 to high(vertexes) do
    setlength(vertexes[a],0);
  setlength(Vertexes,0);
end;

procedure TPetale.AdjustParam(a,b:integer);
var
  t,u:GlFloat;
begin
  t:=b/(nb-1);
  u:=a/(na-1);
  if u>t then t:=u;
  u:=1-a/(na-1);
  if u>t then t:=u;
  u:=exp(-0.001*Form1.Timing);
  t:=u+(Openings[a]-0.2*exp(-5*(1-t)))*(1-u);
  t1:=Thetas1[b];
  t2:=Thetas2[b];
  s1:=0.5*sin(pi*t);
  r1:=-t;
  s2:=0.3+0.2*t;
  r2:=0.9*sqr(1-t);
  rz:=1+sqrt(t);
end;

constructor TPetale.Create(r:TRepere;_na,_nb:integer;o1,o2,_t1,_t2:GlFloat;c1,c2:TVect);
var
  a,b:integer;
  t,dt:GlFloat;
begin
  inherited Create(r,_na,_nb);
  Color1:=c1;
  Color2:=c2;
  setlength(openings,na);
  for a:=0 to na-1 do Openings[a]:=o1*(a/na)+o2*(1-(a/na));
  setlength(Thetas1,nb);
  setlength(Thetas2,nb);
  t:=(_t1+_t2)/2;
  dt:=_t2-_t1;
  for b:=0 to nb-1 do begin
    Thetas1[b]:=t-dt*(1.3-exp(-20*(1-b/(nb-1))));
    Thetas2[b]:=t+dt*(1.3-exp(-20*(1-b/(nb-1))));
  end;
end;

function TPetale.Vertex(x,y:GlFloat):TVect;
var
  Theta,z,r:GlFloat;
begin
  Theta:=t1*x+(1-x)*t2;
  z:=y*rz;
  r:=(1-exp(-5*y))+r1*sqr((seuil(y,s1)/(1.0001-s1)))+
          r2*sqr((seuil(y,s2)/(1.0001-s2)));

  Result.z:=0.8*r*cos(Theta);
  Result.y:=0.8*r*sin(Theta);
  Result.x:=z;
end;

procedure TPetale.MakeVertexes;
var
  a,b:integer;
  t,u:GlFloat;
begin
  for a:=0 to na-1 do
    for b:=0 to nb-1 do begin
      AdjustParam(a,b);
      with vertexes[a][b] do begin
        p:=Vertex(a/(na-1),b/(nb-1));
        t:=b/(nb-1);
        u:=a/(na-1);
        if u>t then t:=u;
        u:=1-a/(na-1);
        if u>t then t:=u;
        t:=exp(-10*(1-t));
        c:=Add(Scale(Color2,t),Scale(Color1,1-t));
      end;
    end;
  MakeNormal;
end;

destructor TPetale.Destroy;
begin
  setlength(Openings,0);
  setlength(Thetas1,0);
  setlength(Thetas2,0);
  inherited Destroy;
end;

constructor TTige.Create(r:TRepere;_na,_nb:integer;con,col:TVect;NF:integer);
var
  a,b:integer;
  u,v,w:TVect;
begin
  inherited Create(r,3*_na,3*_nb);
  Feuilles:=TList.Create;
  Concav:=Con;
  Color:=col;
  for a:=0 to na-1 do begin
    for b:=0 to nb-1 do
      with vertexes[a][b] do begin
        p:=Add(vect(10*(a/(na-1)),0.05*(2-a/(na-1))*cos(2*pi*b/(nb-1)),0.05*(2-a/(na-1))*sin(2*pi*b/(nb-1))),Scale(con,sqr(1-a/(na-1))));
        c:=Scale(Color,0.5+0.5*(1-a/(na-1)));
      end;
  end;
  u:=Vect(0,1,0);
  v:=Vect(1,0,0);
  w:=unitv(crossp(u,v));
  Feuilles.Add(TBoutton.Create(Repere(Vect(0,0,0),Vect(0,-1.1,0),r.x,r.y,r.z),u,v,w));
  MakeNormal;
end;

procedure TTige.Draw;
var
  a:integer;
begin
  inherited Draw;
  for a:=0 to Feuilles.Count-1 do
    TSurface(Feuilles[a]).Draw;
end;

destructor TTige.Destroy;
var
  a:integer;
begin
  for a:=0 to Feuilles.Count-1 do
    TSurface(Feuilles[a]).Destroy;
  Feuilles.Destroy;
  inherited Destroy;
end;

constructor TBoutton.Create(p,u,v,w:TVect);
var
  a,aa,bb:integer;
  r,s,t,rr:GlFloat;
  c1,c2,c3:TVect;
  n:integer;
begin
  Form1.Centre:=add(p,u);
  Randomize;
  c1:=Vect(sqrt(random),sqr(random),sqr(random));
  c2:=Vect(sqr(random),sqr(random),sqrt(random));
  c3:=Vect(sqr(random),sqrt(random),sqr(random));
  Petales:=TList.create;
  rr:=sqr(sqr(random))*0.5;
  if rr<0.2 then rr:=0.2;
  aa:=random(10)+10;
  bb:=random(40)+40;
  n:=4+random(4);
  for a:=0 to n-1 do
  begin
    r:=(a/(n-1));
    r:=rr*(1-r)+r*1+0.1*random;
    s:=2*pi*a*aa/bb+random*pi/5;
    t:=0.5+0.5*a/(n-1);
    Petales.Add(TPetale.Create(MakeRepere(p,u,v,w),20,20,r,r+0.5/(n-1),
                                          s,s+pi*(2+random)/n,
                                          Add(c1,Scale(c3,t)),Add(Scale(c1,1-t),
                                          Scale(c2,t))));
  end;
  for a:=0 to n-1 do
  begin
    r:=(a/(n-1));
    r:=rr*(1-r)+r*1+0.1*random;
    s:=2*pi/3+2*pi*a*aa/bb+random*pi/5;
    t:=0.5+0.5*a/(n-1);
    Petales.Add(TPetale.Create(MakeRepere(p,u,v,w),20,20,r,r+0.5/(n-1),
                                          s,s+pi*(2+random)/n,
                                          Add(c1,Scale(c3,t)),Add(Scale(c1,1-t),
                                          Scale(c2,t))));
  end;
  for a:=0 to n-1 do
  begin
    r:=(a/(n-1));
    r:=rr*(1-r)+r*1+0.1*random;
    s:=4*pi/3+2*pi*a*aa/bb+random*pi/5;
    t:=0.5+0.5*a/(n-1);
    Petales.Add(TPetale.Create(MakeRepere(p,u,v,w),20,20,r,r+0.5/(n-1),
                                          s,s+pi*(2+random)/n,
                                          Add(c1,Scale(c3,t)),Add(Scale(c1,1-t),
                                          Scale(c2,t))));
  end;
end;

procedure TBoutton.Draw;
var
  a:integer;
begin
  glEnable(GL_TEXTURE_2D);
  for a:=0 to Petales.Count-1 do begin
    TPetale(Petales[a]).MakeVertexes;
    TPetale(Petales[a]).Draw;
  end;
end;

destructor TBoutton.Destroy;
var
  a:integer;
begin
  for a:=0 to Petales.Count-1 do TPetale(Petales[a]).Destroy;
  Petales.Destroy;
end;

procedure Tform1.MainLoop;
var
  p:TBitmap;
begin
  if Running then Exit;
  Running:=true;
  p:=TBitmap.Create;
  p.LoadFromResourceName(0,'TexRose');
  ExtractTexFromBitmap(p);
  p.Free;
  glClearColor(0,0,0,0);
  glEnable(GL_NORMALIZE);
  glEnable(GL_DEPTH_TEST);
  glLightfv(GL_LIGHT0,GL_AMBIENT,@AmbientLight);
  glLightfv(GL_LIGHT0,GL_DIFFUSE,@DiffuseLight);
  glLightfv(GL_LIGHT0,GL_SPECULAR,@SpecularLight);
  glLightfv(GL_LIGHT1,GL_AMBIENT,@AmbientLight);
  glLightfv(GL_LIGHT1,GL_DIFFUSE,@DiffuseLight);
  glLightfv(GL_LIGHT1,GL_SPECULAR,@SpecularLight);
  glEnable(GL_LIGHTING);
  glEnable(GL_LIGHT0);
  glEnable(GL_LIGHT1);
  Stop:=false;
  SpecularMaterial[0]:=0.2;
  SpecularMaterial[1]:=0.5;
  SpecularMaterial[2]:=0.3;
  SpecularMaterial[3]:=1;
  AmbientMaterial[3]:=1;
  DiffuseMaterial[3]:=1;
  glMaterialfv(GL_FRONT_AND_BACK,GL_SPECULAR,@SpecularMaterial);
  glMaterialf(GL_FRONT_AND_BACK,GL_SHININESS,30);
  randomize;
  t:=gettickcount;
  glEnable(GL_POLYGON_SMOOTH);
  while not stop do begin
    Timing:=gettickcount-t;
    LightPosition[0]:=2;
    LightPosition[1]:=-2;
    LightPosition[2]:=-10;
    LightPosition[3]:=1;
    glLightfv(GL_LIGHT0,GL_POSITION,@LightPosition);
    LightPosition[0]:=2;
    LightPosition[1]:=-2;
    LightPosition[2]:=10;
    LightPosition[3]:=1;
    glLightfv(GL_LIGHT1,GL_POSITION,@LightPosition);
    DrawAll;
    SwapBuffers(canvas.handle);
    application.ProcessMessages;
  end;
end;

procedure TForm1.DrawAll;
const
  r:single=0.01;
begin
  glClear(GL_DEPTH_BUFFER_BIT or GL_COLOR_BUFFER_BIT);
  glLoadIdentity();
  gluLookAt(4*cos(Timing*0.001),3,4*sin(Timing*0.001),0,-1,0,
                      cos(Timing*0.001),2,sin(Timing*0.001));
  glPushMatrix;
  glBindTexture(GL_TEXTURE_2D,IdTexture);
  Tige.Draw;
  glpopmatrix;
  glFlush();
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  o,r:single;
begin
  MakeFormFullscreenAcrossAllMonitors(Form1);
  GetCursorPos(OldPos); // Initialposition

  Randomize;
  InitOpenGL(Form1.Canvas.Handle,16,true);
  glGenTextures(1,@IdTexture);
  glBindTexture(GL_TEXTURE_2D,IdTexture);

  glViewport(0,0, Width, Height);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  gluPerspective(50, Width / Height,3,12);
  glMatrixMode(GL_MODELVIEW);

  stop:=false;
  Running:=false;

  t:=gettickcount;
  if Assigned(Tige) then Tige.Destroy;
  r:=0.2*random+0.5;
  o:=2*pi*(random);
  Tige:=TTige.Create(MakeRepere(vect(0,-11,0),
                                vect(0,1,0),
                                vect(1,0,0),
                                vect(0,0,1)),10,8,
                                Vect(0,r*cos(o),r*sin(o)),
                                Vect(0,random*0.4+0.2,0),0);

end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  Terminer;
  Tige.Destroy;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  glViewport(0,0, Width, Height);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  gluPerspective(50, Width / Height,3,12);
  glMatrixMode(GL_MODELVIEW);
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  MainLoop;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Stop:=true;
end;

procedure TForm1.ExtractTexFromBitmap(bitmap:tbitmap);
var
  a,b,x,y:integer;
  q:^TByteArray;
begin
  if assigned(PTexture) then freemem(PTexture);
  bitmap.PixelFormat:=pf24bit;
  x:=bitmap.Width;
  y:=bitmap.Height;
  getmem(PTexture,4*x*y);

  for a:=0 to y-1 do begin
    q:=bitmap.ScanLine[a];
    for b:=0 to x-1 do begin
      PByte(PChar(PTexture)+4*(y*b+a))^:=q^[3*b+2];
      PByte(PChar(PTexture)+4*(y*b+a)+1)^:=q^[3*b+1];
      PByte(PChar(PTexture)+4*(y*b+a)+2)^:=q^[3*b];
      PByte(PChar(PTexture)+4*(y*b+a)+3)^:=255;
    end;
  end;

  glPixelStorei(GL_UNPACK_ALIGNMENT,0);
  glBindTexture(GL_TEXTURE_2D,IdTexture);
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_REPEAT);
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_REPEAT);
  glTexImage2d(GL_TEXTURE_2D,0,GL_RGB,y,x,0,GL_RGBA,GL_UNSIGNED_BYTE,PTexture);
end;

procedure TForm1.FormClick(Sender: TObject);
var
  o,r:single;
begin
  { Random Rosesfor a MOuse click
  t:=gettickcount;
  if Assigned(Tige) then Tige.Destroy;
  r:=0.2*random+0.5;
  o:=2*pi*(random);
  Tige:=TTige.Create(MakeRepere(vect(0,-11,0),
                                vect(0,1,0),
                                vect(1,0,0),
                                vect(0,0,1)),10,8,
                                Vect(0,r*cos(o),r*sin(o)),
                                Vect(0,random*0.4+0.2,0),0);
                                }
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
    Close;
  end;
end;

end.
