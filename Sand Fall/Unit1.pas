unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Math, inifiles;


Type TssMode = ( ssAffiche , ssConfig , ssMotDePasse , ssPrevisu );


Const
 Vitesse_Maxi=200;
 Ralentissement=10;


Var
  // How the application works
  ssMode      : TssMode = ssAffiche;

  // Value of the parameters passed to the program
  Param1      : String;
  Param2      : String;



type
  TForm1 = class(TForm)
    Timer: TTimer;
    PaintBox1: TPaintBox;
    Image1: TImage;
    procedure FormCreate(Sender: TObject);
    procedure FormClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure TimerTimer(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject);
  private
    { Declarations privates }
    w,h:integer;
    dx:integer;
    count:integer;
    BackColor:integer;
    WallColor:integer;
    palette:array[0..360] of longint;
    v:array of integer;
    LastN:integer;
    CountN:integer;
    procedure DoSand;
    function GetBackGround:integer;
    function countMoving:integer;
  public
    { Declarations public }
    bitmap:tbitmap;
    procedure iniPicture;
  end;

var
  Form1:TForm1;
  mousepos:tpoint;


implementation

{$R *.dfm}

type
  PQuadArray = ^TQuadArray;
  TQuadArray = array [Byte] of longint;
  TGrain =record Pt:tpoint;
  V:TPoint;
  color:integer;
  actif:boolean;
end;

// managing the search for the number of colors and the most frequent color
//===============================================================================
type
 PTreeColor=^TTreeColor;
 TTreeColor=record
                count:integer;
                bit0,bit1:PTreeColor;
               end;

procedure newleaf(var feuille:PTreeColor);
begin
 new(feuille);
 feuille.count:=0;
 feuille.bit0:=nil;
 feuille.bit1:=nil;
end;

function ClasseCouleur(c:dword;level:byte;feuille:PTreeColor):integer;

begin
 if level=0 then
  begin
   inc(feuille.count);
   result:=feuille.count;
   exit;
  end;

 if c and 1=0 then
  begin
   if feuille.bit0=nil then newleaf(feuille.bit0);
   result:=ClasseCouleur(c shr 1,level-1,feuille.bit0);
  end
 else
  begin
   if feuille.bit1=nil then newleaf(feuille.bit1);
   result:=ClasseCouleur(c shr 1,level-1,feuille.bit1);
  end;
end;

procedure EffaceArbre(feuille:PTreeColor);
begin
 if feuille=nil then exit;
 EffaceArbre(feuille.bit0);
 EffaceArbre(feuille.bit1);
 dispose(feuille);
end;

function Tform1.GetBackGround:integer;
var
 i:integer;
 n,m:integer;
 q:PQuadArray;
 arbre:PTreeColor;
begin
 m:=0;
 result:=$FFFFFF;
 newleaf(arbre);

 q:=bitmap.scanline[h-1];
 for i:=0 to w*h-1 do
  begin
   n:=ClasseCouleur(q[i],32,arbre);
   if n>m then begin m:=n;result:=q[i]; end;
  end;
 EffaceArbre(arbre);
end;

// counts the number of moving pixels
//===============================================================================
function Tform1.countMoving:integer;
var
 i,n:integer;
begin
 n:=0;
 for i:=0 to w*h-1 do if v[i]<>0 then inc(n);
 result:=n;
end;


procedure TForm1.DoSand;
var
 x,y,tx,ox:integer;
 a,b,c,d,e,ia,ib,ic,id:integer;
 bg,wc:integer;
 q:PQuadArray;
 px1,py1,px2,py2:integer;
 tv:integer;

 //=============================================
 // = -1: It's not possible to fall here
 // = X: position of the possible arrival square
 function tombe(index,n:integer):integer;
 // index position where the grain is
 // number of squares to move down
 var
  pe,i,linedown:integer;
 begin
  // Speed ??prevents us from falling further.
  linedown:=index-w;
  if n=0 then
   begin
    result:=index;
   end
  else
  // We've landed on sand.
  if q[linedown]<>BG then
   begin
    // Yes, can the grain go even further?
    pe:=0;
    if q[linedown-1]<>bg then pe:=pe+1;
    if q[linedown+1]<>bg then pe:=pe+2;
    // just an obstacle in the middle, the grain falls to the left or right
    if pe=0 then pe:=random(2)+1;
    // the 8 possibilities
    case pe of
     // the grain of sand falls to the right
     1: result:=tombe(linedown+1,n-1);
     // the grain of sand falls to the left
     2: result:=tombe(linedown-1,n-1);
     // the grain is stopped by q[index]
     3: begin tv:=0; result:=index; end;
    end;
   end
  else
  // There's no sand underneath, we fall a little further on...
   begin
    result:=tombe(linedown,n-1);
   end;
 end;

 procedure tombeN(ida:integer);
 var
  r:integer;
 begin
  tv:=v[ida]+1;
  r:=tombe(ida,tv div Ralentissement+1);
  if r<>-1 then
   begin
    if tv>Vitesse_Maxi then tv:=Vitesse_Maxi;
    q[r]:=q[ida];
    v[r]:=tv;
    q[ida]:=BG;
    v[ida]:=0;
   end
  else
   v[ida]:=0;
 end;

 //=============================================
 // moves a grain of sand from ida to idb
 // (we assume that idb is empty)
 procedure tombeAB(ida,idb:integer);
 begin
  v[idb]:=v[ida];
  q[idb]:=q[ida];
  v[ida]:=0;
  q[ida]:=BG;
 end;

begin
 bg:=BackColor;
 wc:=WallColor;
 q:=bitmap.scanline[h-1];

 // We scan the image from bottom to top,
 // Otherwise, grains of sand could suddenly fall from top to bottom...
 dx:=-dx;
 if dx=1 then ox:=1 else ox:=w-2;

 for y:=0 to h-3 do
  begin
   x:=ox;
   for tx:=0 to w-3 do
    begin
        // Note that the bitmap is upside down.
        // therefore y+1 is above y
        ib:=x+w*y;
        ia:=ib+w;
        ic:=ib-1;
        id:=ia-1;

        a:=q[ia];
        b:=q[ib];
        c:=q[ic];
        d:=q[id];

        e:=0;
        // e = configuration of the 4 points a,b,c,d
        // d a  =>  8 1
        // c b  =>  4 2
        if (a<>bg) then e:=e+1;
        if (b<>bg) then e:=e+2;
        if (c<>bg) then e:=e+4;
        if (d<>bg) then e:=e+8;
        if (a=wc)  then e:=e+100-1;
        if (b=wc)  then e:=e+200-2;
        if (c=wc)  then e:=e+400-4;
        if (d=wc)  then e:=e+800-8;
        if (e>=100) and (e<=199) then e:=e-100;
        if (e>=800) and (e<=899) then e:=e-800;
        if (e>=900) and (e<=999) then e:=e-900;
        case e of
          // cases where there is nothing to be done
          // X wall, O grain of sand
          // .. .. .. .. .O .. O. XX X. XX XX .X XX XX
          // .O O. OO XO XO OX OX XX XX X. .X XX XO 0X
          2,4,6,402,403,204,212,800,1500,1400,1300,1100,700,1302,1104,
          // .X X. .X X. .X X. .X X.
          // .X X. X. .X OX XO XO OX
          300,1200,500,1000,304,1202,502,1004:;
          // In this case, the sand is blocked, therefore the speed is zero.
          601,7,205,1401,1203,1001,1005:begin v[ia]:=0;  end;
          608,14,410,708,312,508,510:begin v[ib]:=0; end;
          609,15,411,213:begin v[ia]:=0; v[id]:=0; end;
          //==================
          // a falls towards c
          // .O       ..
          // .X gives OX
          201: begin tombeAB(ia,ic); end;
          //==================
          // d falls towards b
          // O.       ..
          // X. gives XO
          408: begin tombeAB(id,ib); end;
          //==================
          // a falls towards b
          // .O .O OO XO
          // O. X. X. X.
          5,401,409,1201: begin tombeN(ia); end;
          //==================
          // a falls at b or (d falls at c and c is pushed to b)
          // da       d.    .a
          // c. give that or dc
          13:
           if random(2)=0 then
            begin tombeN(ia); end
           else
            begin tombeAB(ic,ib);tombeAB(id,ic); end;
          //==================
          // d falls towards c
          // O. O. OO OX
          // .O .X .X .X
          10,208,209,308: begin tombeN(id); end;
          //==================
          // d falls into c or (a falls into b and b is pushed into c)
          // da       .a    d.
          // .b gives db or ba
          11:
           if random(2)=0 then
            begin tombeN(id); end
           else
            begin tombeAB(ib,ic);tombeAB(ia,ib); end;
          //==================
          // a falls at c or (a falls at b and b is pushed to c)
          3:
           if random(2)=0 then
            begin tombeAB(ia,ic); end
           else
            begin tombeAB(ib,ic);tombeAB(ia,ib); end;
          //==================
          // d falls into b or (d falls into c and c is pushed into b)
          12:
           if random(2)=0 then
            begin tombeAB(id,ib); end
           else
            begin tombeAB(ic,ib);tombeAB(id,ic); end;
          //==================
          // the grains fall to dust
          1:begin tombeN(ia); end;
          8:begin tombeN(id); end;
          9:begin tombeN(ia); tombeN(id); end;
        end;
        // advances or retreats depending on the direction of travel (dx).
        x:=x+dx;
    end;
  end;
end;

procedure Tform1.iniPicture;
begin
 w:=Bitmap.Width;
 h:=Bitmap.Height;
 bitmap.PixelFormat:=pf32bit;
 BackColor:=GetBackGround;
 if BackColor=0 then WallColor:=$FFFFFF else WallColor:=0;
 Bitmap.Width:=Bitmap.Width+2;
 Bitmap.Height:=Bitmap.Height+2;
 Bitmap.Canvas.Draw(1,1,Bitmap);
 w:=w+2;
 h:=h+2;
 bitmap.Canvas.Brush.Color:=WallColor;
 bitmap.Canvas.FrameRect(rect(0,0,w,h));
 bitmap.Canvas.Brush.Color:=0;
 setlength(v,w*h);
 timer.Enabled:=true;
end;

procedure TForm1.PaintBox1Paint(Sender: TObject);
begin
 Paintbox1.canvas.draw(-1,-1,bitmap);
end;

procedure TForm1.FormCreate(Sender: TObject);
var
 i:integer;
begin
 bitmap:=tbitmap.Create;
 DoubleBuffered:=true;
 dx:=1;
 count:=0;
 BackColor:=$FFFFFF;
 WallColor:=$000000;
 GetCursorPos(mousepos);

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

procedure TForm1.FormClick(Sender: TObject);
begin
 if ssmode=ssPrevisu then exit;
 Close;
end;

procedure TForm1.FormKeyPress(Sender: TObject; var Key: Char);
begin
 if ssmode=ssPrevisu then exit;
 Close;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
 inherited;
 bitmap.Free;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
 //ShowWindow(Application.Handle,SW_HIDE);
end;

procedure TForm1.TimerTimer(Sender: TObject);
var
 n:integer;
 q:pquadarray;
 tmp:tbitmap;
 i:integer;
begin
 DoSand;
 Paintbox1.canvas.draw(-1,-1,bitmap);
 n:=countMoving;

 if lastN=n then
  begin
   inc(CountN);
   if CountN>30*5 then
    begin
     bitmap.Canvas.CopyRect(rect(0,h-1,w-1,0),bitmap.Canvas,rect(0,0,w-1,h-1));
     CountN:=0;
     LastN:=0;
    end;
  end
 else
  begin
   LastN:=n;
   CountN:=0;
  end;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 timer.Enabled:=false;
 application.Terminate;
end;

procedure TForm1.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
pt:tpoint;
begin
 if ssmode=ssPrevisu then exit;
 GetCursorPos(pt);
 if abs(sqr(pt.x-mousepos.X)+sqr(pt.y-mousepos.Y))>25 then close;
end;

end.
