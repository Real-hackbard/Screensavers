unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Math;

type
  TForm1 = class(TForm)
    Timer1: TTimer;
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Declarations privates }
  public
    { Declarations public }
  end;

type
 TBoide=record
         x,y:integer;
         vx,vy:integer;
        end;


const
 maxboides=500;
 Cursor_attract=300;
 cohesion_attract=100;
 Align_attract=8;
 Separation_repuls=100;
 Speed_Max=200;
 Distance_Max=200*200;
 Angle_Vision=90; // that's 180° in total


var
  Form1: TForm1;
  boides:array[0..maxboides] of TBoide;
  buffer:tbitmap;
  palette:array[0..360] of longint;

implementation

{$R *.dfm}
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

 // check if b1 sees b2
function AngleDeVisionOk(b1,b2:tboide):boolean;
var
 angle:extended;
begin
 b1.x:=b1.x-b2.x;
 b1.y:=b1.y-b2.y;
 angle:=abs(arctan2(b1.x,b1.y)*180/pi);
 result:=(b1.x*b1.x+b1.y*b1.y<Distance_Max) and (angle<=Angle_Vision);
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
 i,j:integer;
 pt:tpoint;
 bx,by,bvx,bvy:integer;
 cohesion,align,separation,center:tpoint;
 c:integer;
begin
 // mouse position
 GetCursorPos(pt);

 // for each boy
 for i:=0 to maxboides do
  begin
   c:=0;
   cohesion.X:=0;
   cohesion.y:=0;
   align.x:=0;
   align.y:=0;
   separation.x:=0;
   separation.y:=0;

   // they observe the behavior of their neighbors
   // we go through the entire list
   for j:=0 to maxboides do
    // if the boides J is in the field of vision of I
    // i.e.: not too far away and in front of him
    if (i<>j) and AngleDeVisionOk(boides[i],boides[j]) then
     begin
      // So we're dealing with the 3 forces that govern group behavior
      c:=c+1;
      // it is getting closer to the center of mass of its neighbors
      cohesion.X:=cohesion.x+boides[j].x;
      cohesion.y:=cohesion.Y+boides[j].y;
      // he aligns his direction with that of others
      align.x:=align.x+boides[j].vx;
      align.y:=align.y+boides[j].vy;
      // but he moves away if there are too many of them
      separation.x:=separation.x-(boides[j].x-boides[i].x);
      separation.y:=separation.y-(boides[j].y-boides[i].y);
     end;

   // If there are neighbors, we finish calculating the averages.
   if c<>0 then
    begin
     cohesion.x:=(cohesion.x div c-boides[i].x) div cohesion_attract;
     cohesion.y:=(cohesion.y div c-boides[i].y) div cohesion_attract;
     align.x:=(align.x div c-boides[i].vx) div Align_attract;
     align.y:=(align.y div c-boides[i].vy) div Align_attract;
     separation.x:=separation.x div Separation_repuls;
     separation.y:=separation.y div Separation_repuls;
    end;


   // the last force pushes them all towards the mouse
   center.x:=(pt.x*10-boides[i].x) div Cursor_attract;
   center.y:=(pt.y*10-boides[i].y) div Cursor_attract;

   // We combine all the information to get the new speed
   boides[i].vx:=boides[i].vx+cohesion.x+align.x+separation.x+center.x;
   boides[i].vy:=boides[i].vy+cohesion.y+align.y+separation.y+center.y;

   // Be careful, if he goes too fast, we'll brake him.
   c:=round(sqrt(boides[i].vx*boides[i].vx+boides[i].vy*boides[i].vy));
   if c>Speed_Max then
    begin
     boides[i].vx:=boides[i].vx*Speed_Max div c;
     boides[i].vy:=boides[i].vy*Speed_Max div c;
    end;

   // we move it according to its speed
   boides[i].x:=boides[i].x+boides[i].vx;
   boides[i].y:=boides[i].y+boides[i].vy;

   // bounce on the edges
   {
   if boides[i].x>clientwidth then boides[i].vx:=-boides[i].vx;
   if boides[i].x<0 then boides[i].vx:=-boides[i].vx;
   if boides[i].y>clientheight then boides[i].vy:=-boides[i].vy;
   if boides[i].y<0 then boides[i].vy:=-boides[i].vy;
   }

   // closed universe
   {
   if boides[i].x>clientwidth then boides[i].x:=boides[i].x-clientwidth;
   if boides[i].x<0 then boides[i].x:=boides[i].x+clientwidth;
   if boides[i].y>clientheight then boides[i].y:=boides[i].y-clientheight;
   if boides[i].y<0 then boides[i].y:=boides[i].y+clientheight;
   }
  end;


 // We clear the buffer and display the booids
 buffer.canvas.Brush.color:=clblack;
 buffer.canvas.FillRect(clientrect);
 for i:=0 to maxboides do
  begin
   bx:=boides[i].x div 10;
   by:=boides[i].y div 10;
   bvx:=boides[i].vx div 10;
   bvy:=boides[i].vy div 10;
   // calculating the direction of movement for the color
   c:=round(arctan2(bvx,bvy)*180/PI)+180;
   buffer.canvas.pen.color:=palette[c];
   // draw a very long speed
   buffer.canvas.MoveTo(bx,by);
   buffer.canvas.lineto(bx+bvx,by+bvy);
  end;

 // displays the result
 canvas.Draw(0,0,buffer);
end;

procedure TForm1.FormCreate(Sender: TObject);
var
 i:integer;
begin
 randomize;
 // we will draw in buffer
 buffer:=tbitmap.Create;
 buffer.Width:=clientwidth;
 buffer.Height:=clientheight;

 // We initialize a speed and a random starting position.
 for i:=0 to maxboides do
  with boides[i] do
   begin
    x:=random(clientwidth*10);
    y:=random(clientheight*10);
    vx:=random(200)-100;
    vy:=random(200)-100;
   end;
 // We create the eyeshadow palette for display
 for i:=0 to 360 do
   Case (i div 60) of
      0,6:palette[i]:=rgb(255,(i Mod 60)*255 div 60,0);
      1: palette[i]:=rgb(255-(i Mod 60)*255 div 60,255,0);
      2: palette[i]:=rgb(0,255,(i Mod 60)*255 div 60);
      3: palette[i]:=rgb(0,255-(i Mod 60)*255 div 60,255);
      4: palette[i]:=rgb((i Mod 60)*255 div 60,0,255);
      5: palette[i]:=rgb(255,0,255-(i Mod 60)*255 div 60);
   end;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
 buffer.Width:=clientwidth;
 buffer.Height:=clientheight;
end;

procedure TForm1.FormClick(Sender: TObject);
begin
 timer1.Free;
 buffer.Free;
 close;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  MakeFormFullscreenAcrossAllMonitors(Form1);
end;

end.
