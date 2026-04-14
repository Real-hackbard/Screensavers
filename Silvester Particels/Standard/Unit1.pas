unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Math;

type
  TForm1 = class(TForm)
    Timer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure FormClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormShow(Sender: TObject);
  private
    { Private-Deklarationen}
  public
    { Public-Deklarationen}
  end;

const
 MaxT=128;
 SizeLetter=20;
 TableColor:array[0..6] of integer=($000001,$000100,$010000,
                                    $000101,$010100,$010001,
                                    $010101);
 ModeStandby=0;
 ModeWait=1;
 ModeMove=2;
 ModeExplode=3;


const    //GOOD
         //YEAR
 GoodYear:array[1..110] of TPoint=
 ((x:-10;y:0;),(x:-9;y:0;),             // B
  (x:-10;y:1;),(x:-8;y:1;),             // B
  (x:-10;y:2;),(x:-9;y:2;),             // B
  (x:-10;y:3;),(x:-8;y:3;),             // B
  (x:-10;y:4;),(x:-9;y:4;),             // B

  (x:-6;y:0;),(x:-5;y:0;),(x:-4;y:0;),  // O
  (x:-6;y:1;),(x:-4;y:1;),              // O
  (x:-6;y:2;),(x:-4;y:2;),              // O
  (x:-6;y:3;),(x:-4;y:3;),              // O
  (x:-6;y:4;),(x:-5;y:4;),(x:-4;y:4;),  // O

  (x:-2;y:0;),(x:1;y:0;),               // N
  (x:-2;y:1;),(x:-1;y:1;),(x:1;y:1;),   // N
  (x:-2;y:2;),(x: 0;y:2;),(x:1;y:2;),   // N
  (x:-2;y:3;),(x:1;y:3;),               // N
  (x:-2;y:4;),(x:1;y:4;),               // N

  (x:3;y:0;),(x:6;y:0;),                // N
  (x:3;y:1;),(x:4;y:1;),(x:6;y:1;),     // N
  (x:3;y:2;),(x:5;y:2;),(x:6;y:2;),     // N
  (x:3;y:3;),(x:6;y:3;),                // N
  (x:3;y:4;),(x:6;y:4;),                // N

  (x:8;y:0;),(x:9;y:0;),(x:10;y:0;),    // E
  (x:8;y:1;),                           // E
  (x:8;y:2;),(x:9;y:2;),                // E
  (x:8;y:3;),                           // E
  (x:8;y:4;),(x:9;y:4;),(x:10;y:4;),    // E


                (x:-09;y:07;),                // A
  (x:-10;y:08;),              (x:-08;y:08;),  // A
  (x:-10;y:09;),(x:-09;y:09;),(x:-08;y:09;),  // A
  (x:-10;y:10;),              (x:-08;y:10;),  // A
  (x:-10;y:11;),              (x:-08;y:11;),  // A

  (x:-06;y:07;),              (x:-03;y:07;),  // N
  (x:-06;y:08;),(x:-05;y:08;),(x:-03;y:08;),  // N
  (x:-06;y:09;),(x:-04;y:09;),(x:-03;y:09;),  // N
  (x:-06;y:10;),              (x:-03;y:10;),  // N
  (x:-06;y:11;),              (x:-03;y:11;),  // N

  (x:-01;y:07;),             (x:02;y:07;),    // N
  (x:-01;y:08;),(x:00;y:08;),(x:02;y:08;),    // N
  (x:-01;y:09;),(x:01;y:09;),(x:02;y:09;),    // N
  (x:-01;y:10;),             (x:02;y:10;),    // N
  (x:-01;y:11;),             (x:02;y:11;),    // N

  (x:4;y:07;),(x:5;y:07;),(x:6;y:07;),        // E
  (x:4;y:08;),                                // E
  (x:4;y:09;),(x:5;y:09;),                    // E
  (x:4;y:10;),                                // E
  (x:4;y:11;),(x:5;y:11;),(x:6;y:11;),        // E

  (x:8;y:07;),(x:9;y:07;),(x:10;y:07;),       // E
  (x:8;y:08;),                                // E
  (x:8;y:09;),(x:9;y:09;),                    // E
  (x:8;y:10;),                                // E
  (x:8;y:11;),(x:9;y:11;),(x:10;y:11;));      // E


  
type
 TExplosion=record vx,vy,px,py,cl:integer; end;

 TFire=record temps:integer;
             mode:byte;
             color:integer;
             pos:tpoint;        // current position
                                // parametric equation of position
             ax,bx,cx:integer;  // Fx(t)=(ax*tt+bx*t)/cx
             xs,dx:integer;     // Fy(t)=xs+dx*t/maxt
             explosion:array[0..50] of TExplosion;
      end;
 Tlongarray=array[0..0] of TRGBTriple;

var
  Form1: TForm1;
  Fire:array[1..200] of TFire;
  bmp:tbitmap;
  scrsize:tpoint;
  pbmp:^Tlongarray;
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

procedure NewFire(var Fire:TFire);
var
 b,t,tt:integer;
begin
 Fire.temps:=-random(5*MaxT)-1;
 Fire.mode:=Modewait;
 t:=MaxT;
 tt:=random(screen.DesktopHeight-200)+200;
 b:=2*(t+random(t div 2)-t div 4);
 Fire.ax:=tt;
 Fire.bx:=-tt*b;
 Fire.cx:=t*(t-b);
 Fire.xs:=random(screen.DesktopWidth);
 Fire.dx:=random(screen.DesktopWidth)-Fire.xs;
 Fire.color:=TableColor[random(6)];
 Fire.pos:=point(Fire.xs,0);
end;

procedure TForm1.FormCreate(Sender: TObject);
var
 i,b,t,tt:integer;
begin
  GetCursorPos(OldPos); // Initialposition
 bmp:=tbitmap.Create;
 bmp.Width:=screen.DesktopWidth;
 bmp.Height:=screen.DesktopHeight;
 bmp.PixelFormat:=pf24bit;
 pbmp:=bmp.ScanLine[bmp.height-1];
 scrsize:=point(screen.Desktopwidth,screen.DesktopHeight);
 randomize;
 // creating the letters of the message
 for i:=1 to 110 do
  begin
   Fire[i].temps:=-MaxT+random(5);
   Fire[i].mode:=ModeWait;
   t:=MaxT;
   tt:=screen.Height div 2-(GoodYear[i].Y-5)*SizeLetter;
   b:=2*(t+random(t div 2)-t div 4);
   Fire[i].ax:=tt;
   Fire[i].bx:=-tt*b;
   Fire[i].cx:=t*(t-b);

   Fire[i].xs:=random(screen.Width);
   Fire[i].dx:=screen.Width div 2+GoodYear[i].X*SizeLetter-Fire[i].xs;
   Fire[i].color:=$010101;
   Fire[i].pos:=point(Fire[i].xs,0);
  end;
 // the rest of the fireworks
 for i:=111 to 200 do
  begin
   NewFire(Fire[i]);
   Fire[i].temps:=MaxT-random(10*MaxT);
   if Fire[i].temps>=0 then Fire[i].mode:=ModeMove
                      else Fire[i].mode:=ModeWait;
  end;
  
end;

procedure TForm1.TimerTimer(Sender: TObject);
var
 i,t,j,angle,veloc:integer;
 NewPos: TPoint;
begin
  GetCursorPos(NewPos);
  if (NewPos.X <> OldPos.X) or (NewPos.Y <> OldPos.Y) then
  begin
    Application.Terminate;
  end;

 // erase
 for j:=0 to scrsize.y-1 do
 for i:=0 to scrsize.x-1 do
  begin
   pbmp[i+scrsize.x*j].rgbtBlue:=pbmp[i+scrsize.x*j].rgbtBlue*3 div 4;
   pbmp[i+scrsize.x*j].rgbtGreen:=pbmp[i+scrsize.x*j].rgbtGreen*3 div 4;
   pbmp[i+scrsize.x*j].rgbtRed:=pbmp[i+scrsize.x*j].rgbtRed*3 div 4;
  end;

 // recalculate the new positions
 for i:=1 to 200 do
  case Fire[i].mode of
   ModeStandby:;// Nothing
   ModeWait:    // waiting for takeoff
    begin
     inc(Fire[i].temps);
     if Fire[i].temps=0 then Fire[i].mode:=ModeMove;
    end;

   ModeMove:  // rise into the sky
    begin
     inc(Fire[i].temps);
     t:=Fire[i].temps;
     bmp.Canvas.Pen.Color:=Fire[i].color*255;

     bmp.canvas.MoveTo(Fire[i].pos.x,scrsize.Y-Fire[i].pos.y);
     // new position of the rocket
     Fire[i].pos.x:=Fire[i].xs+Fire[i].dx*t div MaxT;
     Fire[i].pos.y:=(Fire[i].ax*t*t + Fire[i].bx*t) div Fire[i].cx;
     bmp.canvas.LineTo(Fire[i].pos.x,scrsize.Y-Fire[i].pos.y);

     // If the time has come, explosion
     if Fire[i].temps=MaxT then
      begin
       // creation of debris
       for j:=0 to 50 do
        begin
         angle:=random(360);
         veloc:=random(64);
         Fire[i].explosion[j].vx:=round(cos(angle*pi/180)*veloc);
         Fire[i].explosion[j].vy:=round(sin(angle*pi/180)*veloc);
         Fire[i].explosion[j].px:=Fire[i].pos.x*64;
         Fire[i].explosion[j].py:=Fire[i].pos.y*64;
        end;
       Fire[i].mode:=ModeExplode;
       Fire[i].temps:=255;
      end;
    end;

   ModeExplode:   // the debris falls back down
    begin
     dec(Fire[i].temps,1);
     if Fire[i].temps<0 then NewFire(Fire[i])
     else
      begin
       for j:=0 to 50 do
        begin
         dec(Fire[i].explosion[j].cl);
         dec(Fire[i].explosion[j].vy);
         Fire[i].explosion[j].px:=Fire[i].explosion[j].px+Fire[i].explosion[j].vx;
         Fire[i].explosion[j].py:=Fire[i].explosion[j].py+Fire[i].explosion[j].vy;
         Fire[i].explosion[j].cl:=Fire[i].color*Fire[i].temps;
         bmp.canvas.Pixels[Fire[i].explosion[j].px div 64,
            scrsize.y-Fire[i].explosion[j].py div 64]:=Fire[i].explosion[j].cl;
        end;
      end;
   end;
  end;// end case;

 canvas.Draw(0,0,bmp);
end;

procedure TForm1.FormClick(Sender: TObject);
begin
  Application.Terminate; // We leave
end;

procedure TForm1.FormKeyPress(Sender: TObject; var Key: Char);
begin
  Application.Terminate; // We leave
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  MakeFormFullscreenAcrossAllMonitors(Form1);
end;

end.
