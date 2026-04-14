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
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private-Deklarationen}
  public
    { Public-Deklarationen}
  end;

const
 MaxT=256;
 SizeLetter=20;
 ladder=1;

 SizeLetterTableColor:array[0..6] of integer=
 ($000001,$000100,$010000,
  $000101,$010100,$010001,
  $010101);
 ModeStandby=0;
 ModeWait=1;
 ModeMove=2;
 ModeExplode=3;


const    // GOOD
         // YEAR
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
 TExplosion=record vx,vy,px,py:integer; end;

 TFire=record temps:integer;
             mode:byte;
             color:integer;
             pos1:tpoint;        // position at time t-1
             pos2:tpoint;        // position at time t

             // parametric equation of position
             ax,bx,cx:integer;  // Fx(t)=(ax*tt+bx*t)/cx
             xs,dx:integer;     // Fy(t)=xs+dx*t/maxt

             explosion:array[0..50] of TExplosion;
      end;

var
  Form1: TForm1;
  fire:array[1..200] of TFire;
  bmp:tbitmap;
  scrsize:tpoint;
  pbmp,ptmp:PByteArray;
  moderendu:byte=0;
  lastickcount:integer;
  ShowFPS:boolean=false; // Press "F" to Show FPS count
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
 tt:=random(scrsize.y-200)+200;
 b:=2*(t+random(t div 2)-t div 4);
 Fire.ax:=tt;
 Fire.bx:=-tt*b;
 Fire.cx:=t*(t-b);
 Fire.xs:=random(scrsize.x);
 Fire.dx:=random(scrsize.x)-Fire.xs;
 Fire.color:=SizeLetterTableColor[random(6)];
 Fire.pos1:=point(Fire.xs,0);
 Fire.pos2:=point(Fire.xs,0);
end;

procedure TForm1.FormCreate(Sender: TObject);
var
 i,b,t,tt:integer;
begin
 GetCursorPos(OldPos); // Initialposition 
 scrsize:=point(round(screen.DesktopWidth*ladder),
          round(screen.DesktopHeight*ladder));

 // main bitmap for drawing
 bmp:=tbitmap.Create;
 bmp.Width:=scrsize.x;
 bmp.Height:=scrsize.y;
 bmp.PixelFormat:=pf24bit;
 bmp.Canvas.Brush.color:=0;
 bmp.Canvas.FillRect(bmp.Canvas.cliprect);
 pbmp:=bmp.ScanLine[bmp.height-1];

 // Temporary memory allocation for blur
 getmem(ptmp,scrsize.X*scrsize.Y*3);

 randomize;
 // creating the letters of the message
 for i:=1 to 110 do
  begin
   fire[i].temps:=-MaxT+random(5);
   fire[i].mode:=ModeWait;
   t:=MaxT;
   tt:=scrsize.y div 2-(GoodYear[i].Y-5)*SizeLetter;
   b:=2*(t+random(t div 2)-t div 4);
   fire[i].ax:=tt;
   fire[i].bx:=-tt*b;
   fire[i].cx:=t*(t-b);
   fire[i].xs:=random(scrsize.x);
   fire[i].dx:=scrsize.x div 2+GoodYear[i].X*SizeLetter-fire[i].xs;
   fire[i].color:=$010101;
   fire[i].pos1:=point(fire[i].xs,0);
   fire[i].pos2:=point(fire[i].xs,0);
  end;

 // the rest of the fireworks were set off randomly
 for i:=111 to 200 do
  begin
   NewFire(fire[i]);
   fire[i].temps:=MaxT-random(10*MaxT);
   if fire[i].temps>=0 then
    begin
     fire[i].mode:=ModeMove;
     fire[i].pos1.x:=fire[i].xs+fire[i].dx*fire[i].temps div MaxT;
     fire[i].pos1.y:=(fire[i].ax*fire[i].temps*fire[i].temps +
          fire[i].bx*fire[i].temps) div fire[i].cx;
     fire[i].pos2:=fire[i].pos1;
    end
   else fire[i].mode:=ModeWait;
  end;

 SetStretchBltMode(canvas.Handle,HALFTONE);
 bmp.canvas.Font.Color:=clwhite;
end;

procedure vague9assembler;
begin
asm
   push ebx              // backup ebx, edi and esi
   push edi              // something that should always be done at the beginning of the procedure
   push esi

   mov esi,pbmp          // points to both images (reminder: 32 bits/pixel)
   mov edi,ptmp


   mov ebx,scrsize.x     // line size calculation = scrsize.x*3
   mov eax,ebx
   shl ebx,1
   add ebx,eax

   add edi,ebx           // edi points to the second line of tmp
   mov eax,ebx           // saving line size in eax
   sub ebx,3             //

   mov edx,scrsize.y    // calculates the number of bytes to process to blur the entire image
   sub edx,2            // = scrsize.y*3*(scrsize.y-2)
   mul edx              // We do not process the first and last lines
   mov ecx,eax          // saves the result in ecx

  @boucle:              // start of loop

   push esi             // We save the pointer to BMP because we are going to modify it.

   xor eax,eax          // RAZ eax and edx
   xor edx,edx

   mov al,byte ptr [esi]     // We add up the three bottom pixels
   mov dl,byte ptr [esi+4]
   shl dl,1
   add eax,edx
   mov dl,byte ptr [esi+8]
   add eax,edx

   add esi,ebx               // we go up one line
   mov dl,byte ptr [esi]     // we sum the three middle pixels
   shl dl,1
   add eax,edx
   mov dl,byte ptr [esi+4]
   shl dl,2
   add eax,edx
   mov dl,byte ptr [esi+8]
   shl dl,1
   add eax,edx

   add esi,ebx               // we go up one line
   mov dl,byte ptr [esi]     // we sum the three pixels at the top
   add eax,edx
   mov dl,byte ptr [esi+4]
   shl dl,1
   add eax,edx
   mov dl,byte ptr [esi+8]
   add eax,edx

   shr eax,4
   mov [edi],al              // we place the result in ptmp


   pop esi
   inc edi                   // we move by one byte
   inc esi
   loop @boucle              // and we repeat this as long as ecx>0

   pop esi                   // restore esi, edi and ebx registers
   pop edi
   pop ebx
  end;
 move(ptmp^[0],pbmp^[0],scrsize.x*scrsize.y*3);
end;


procedure vague5assembler;
begin
asm
   push ebx               // backup ebx, edi and esi
   push edi               // something that should always be done at the beginning of the procedure
   push esi

   mov esi,pbmp          // points to both images (reminder: 32 bits/pixel)
   mov edi,ptmp


   mov ebx,scrsize.x    // line size calculation = scrsize.x*3
   mov eax,ebx
   shl ebx,1
   add ebx,eax

   add edi,ebx          // edi points to the second line of tmp
   mov eax,ebx          // saving line size in eax
   sub ebx,4            //

   mov edx,scrsize.y    // calculates the number of bytes to process to blur the entire image
   sub edx,2            // = scrsize.y*4*(scrsize.y-2)
   mul edx              // We do not process the first and last lines
   mov ecx,eax          // saves the result in ecx

  @boucle:              // start of loop

   push esi             // We save the pointer to BMP because we are going to modify it.
   xor eax,eax          // RAZ eax and edx
   xor edx,edx

   mov al,byte ptr [esi+4]   // We add up the three bottom pixels

   add esi,ebx               // we go up one line
   mov dl,byte ptr [esi]     // we sum the three middle pixels
   add ax,dx
   mov dl,byte ptr [esi+4]
   shl dl,2
   add ax,dx
   mov dl,byte ptr [esi+8]
   add ax,dx

   add esi,ebx               // we go up one line
   mov dl,byte ptr [esi+4]
   add ax,dx

   shr ax,3
   mov [edi],al              // we place the result in ptmp


   pop esi
   inc edi                   // we move by one byte
   inc esi
   loop @boucle              // and we repeat this as long as ecx>0

   pop esi                   // restore esi, edi and ebx registers
   pop edi
   pop ebx
  end;
 move(ptmp^[0],pbmp^[0],scrsize.x*scrsize.y*3);
end;

procedure fadeassembleur;
asm
   push ebx               // backup ebx and esi
   push esi

   mov esi,pbmp          // points to bmp (reminder: 32 bits/pixel)


   mov ebx,scrsize.x    // line size calculation = scrsize.x*3
   mov eax,ebx
   shl ebx,1
   add eax,ebx

   mov edx,scrsize.y    // calculates the number of bytes to process to erase the entire image
   mul edx
   mov ecx,eax          // saves the result in ecx

  @boucle:              // start of loop
   mov al,[esi]
   sub al,8
   ja @suite
   xor al,al
   @suite:
   mov [esi],al
   inc edi                   // we move by one byte
   inc esi
   loop @boucle              // and we repeat this as long as ecx>0
   pop esi                   // restore esi and ebx registers
   pop ebx
  end;

// The same as above, but in Pascal...
// It's more readable, much, much, much, much, much, much, much, much
// We can surely do better
procedure Flou9Pascal;
var
 i,j,k:integer;
 color:integer;
 l1,l2,l3:integer;
begin
l1:=3;
l2:=scrsize.x*3+3;
l3:=scrsize.x*6+3;
for j:=1 to scrsize.y-2 do
 for i:=0 to scrsize.x-1 do
 for k:=0 to 2 do
  begin
   color:=pbmp[l1-3]      + pbmp[l1  ] shl 1+ pbmp[l1+3]+
          pbmp[l2-3] shl 1+ pbmp[l2  ] shl 2+ pbmp[l2+3] shl 1+
          pbmp[l3-3]      + pbmp[l3  ] shl 1+ pbmp[l3+3];
   ptmp[l2]:=color shr 4;
   inc(l1);
   inc(l2);
   inc(l3);
  end;
 move(ptmp^[0],pbmp^[0],scrsize.x*scrsize.y*3);
end;

var
 incr:boolean=true;
procedure Flou4Pascal;
Var
 i,j,k: Integer;
 color: Integer;
 l1,l2:integer;
begin
 incr:=not incr;
 l1:=0;
 l2:=scrsize.x*2+scrsize.X;
 for j:=scrsize.y-2 downto 0 do
  begin
   if Incr xor Odd(j) then
    begin
     l1:=l1+scrsize.X*2+scrsize.X;
     l2:=l2+scrsize.X*2+scrsize.X;
     Continue;
    end;

   for i:=scrsize.x-1 downto 0 do
    for k:=0 to 2 do
     begin
      color:=(pbmp[l1] + pbmp[l1+3]+
              pbmp[l2] + pbmp[l2+3]) shr 2;

      pbmp[l1  ]:=color;  pbmp[l1+3]:=color;
      pbmp[l2  ]:=color;  pbmp[l2+3]:=color;
      inc(l1);
      inc(l2);
     end;
 end;
end;

procedure TForm1.TimerTimer(Sender: TObject);
var
 i,t,j,k,angle,veloc:integer;
 tickcount:integer;
 NewPos: TPoint;
begin
 GetCursorPos(NewPos);
  if (NewPos.X <> OldPos.X) or (NewPos.Y <> OldPos.Y) then
  begin
    Close();
  end;

 // Before blurring the image, we change the color of the rockets to white to make it look like
 // smoke
 for i:=1 to 200 do
  case fire[i].mode of
   ModeStandby:; // Nothing
   ModeWait:;    // Nothing
   ModeMove:     // rise into the sky
    begin
     bmp.Canvas.Pen.Color:=clwhite;
     bmp.canvas.MoveTo(fire[i].pos1.x,scrsize.Y-fire[i].pos1.y);
     bmp.canvas.LineTo(fire[i].pos2.x,scrsize.Y-fire[i].pos2.y);
    end;
   ModeExplode:;   // Nothing
  end;

 // erase (blur)
 case moderendu of
 0:fillchar(pbmp[0],scrsize.X*scrsize.Y*3,0);
 1:flou9pascal;
 2:vague9assembler;
 3:vague5assembler;
 4:fadeassembleur;
 5:Flou4Pascal;
 end;

 // The image is framed with a black border.
 // The blur filter doesn't work for edges...
 bmp.Canvas.FrameRect(bmp.Canvas.ClipRect);

 // recalculate the new positions
 for i:=1 to 200 do
  case fire[i].mode of
   ModeStandby:;  // Nothing
   ModeWait:      // waiting for takeoff
    begin
     inc(fire[i].temps);
     if fire[i].temps=0 then fire[i].mode:=ModeMove;
    end;

   ModeMove:  // rise into the sky
    begin
     inc(fire[i].temps);
     t:=fire[i].temps;
     // new position of the rocket
     fire[i].pos1:=fire[i].pos2;
     fire[i].pos2.x:=fire[i].xs+fire[i].dx*t div MaxT;
     fire[i].pos2.y:=(fire[i].ax*t*t + fire[i].bx*t) div fire[i].cx;

     bmp.Canvas.Pen.Color:=fire[i].color*255;
     bmp.canvas.MoveTo(fire[i].pos1.x,scrsize.Y-fire[i].pos1.y);
     bmp.canvas.LineTo(fire[i].pos2.x,scrsize.Y-fire[i].pos2.y);
     //bmp.canvas.Pixels[feu[i].pos1.x,scrsize.Y-feu[i].pos1.y]:=feu[i].color*255;

     // If the time has come, explosion
     if fire[i].temps=MaxT then
      begin
       // creation of debris
       for j:=0 to 50 do
        begin
         angle:=random(360);
         veloc:=random(64);
         fire[i].explosion[j].vx:=round(cos(angle*pi/180)*veloc);
         fire[i].explosion[j].vy:=round(sin(angle*pi/180)*veloc);
         fire[i].explosion[j].px:=fire[i].pos2.x*64;
         fire[i].explosion[j].py:=fire[i].pos2.y*64;
        end;
       fire[i].mode:=ModeExplode;
       fire[i].temps:=255;
      end;
    end;

   ModeExplode:   // the debris falls back down
    begin
     dec(fire[i].temps,1);
     if fire[i].temps<0 then NewFire(fire[i])
     else
      begin
       for j:=0 to 50 do
        begin
         dec(fire[i].explosion[j].vy);
         fire[i].explosion[j].px:=fire[i].explosion[j].px+fire[i].explosion[j].vx;
         fire[i].explosion[j].py:=fire[i].explosion[j].py+fire[i].explosion[j].vy;
         bmp.canvas.Pixels[fire[i].explosion[j].px div 64,
                           scrsize.y-fire[i].explosion[j].py div 64]:=fire[i].color*fire[i].temps;
        end;
      end;
   end;
  end;// end case;


 // FPS
 if ShowFPS then
  begin
   tickcount:=gettickcount-lastickcount;
   lastickcount:=gettickcount;
   if tickcount<>0 then
   bmp.canvas.TextOut(0,0,'FPS:'+inttostr(1000 div tickcount));
   case moderendu of
    0:bmp.canvas.TextOut(200,0,'sans effet');
    1:bmp.canvas.TextOut(200,0,'Pascals 9-neighbor matrix filter');
    2:bmp.canvas.TextOut(200,0,'9-neighbor matrix filter Assembler');
    3:bmp.canvas.TextOut(200,0,'9-neighbor matrix filter Assembler');
    4:bmp.canvas.TextOut(200,0,'Matrix Filter Fade Pascal');
    5:bmp.canvas.TextOut(200,0,'2x2 Pascal Matrix Filter');
   end;
  end;

 // image transfer with resizing
 if ladder=1 then
  BitBlt(canvas.Handle,0,0,
          scrsize.X,scrsize.y,bmp.canvas.Handle,0,0,SRCCOPY)
        else
        windows.StretchBlt(canvas.Handle,0,0,
                           clientwidth,
                           clientheight,
                           bmp.canvas.Handle,
                           0,
                           0,
                           scrsize.X,
                           scrsize.Y,
                           SRCCOPY);


end;

procedure TForm1.FormClick(Sender: TObject);
begin
 close;
end;

procedure TForm1.FormKeyPress(Sender: TObject; var Key: Char);
begin
 case key of
  '0'..'9':moderendu:=byte(key)-48;
  'f','F':ShowFPS:=not ShowFPS;
  #27,#13:close;
 end;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
 // memory release
 timer.OnTimer:=nil;
 bmp.Free;
 freemem(ptmp);
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  MakeFormFullscreenAcrossAllMonitors(Form1);
end;

end.
