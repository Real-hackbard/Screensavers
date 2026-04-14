unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls, Buttons;

type
  TForm1 = class(TForm)
    Timer1: TTimer;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    Image4: TImage;
    Image5: TImage;
    Image6: TImage;
    Image7: TImage;
    Image8: TImage;
    Image9: TImage;
    Image10: TImage;
    Image11: TImage;
    Image12: TImage;
    Image13: TImage;
    Image14: TImage;
    Image15: TImage;
    Image16: TImage;
    Image17: TImage;
    Image18: TImage;
    Image19: TImage;
    Image20: TImage;
    Image21: TImage;
    Image22: TImage;
    Image23: TImage;
    Image24: TImage;
    procedure FormClick(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure Timer1Timer(Sender: TObject);

    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
  { Private declarations }
  public
  { Public declarations }
     xscale,yscale: real;
     ypos1,ypos2,ypos3,ypos4,ypos5,ypos6,ypos7:integer;
     procedure choose( var b: Tbitmap;var s:integer; r: boolean);
  end;

var
  Form1: TForm1;
  p1,p2,p3,p4,p5,p6,p7: boolean;
  r1,r2,r3,r4,r5,r6,r7: boolean;
  pos1,pos2,pos3,pos4,pos5,pos6,pos7: integer;
  s1,s2,s3,s4,s5,s6,s7: integer;
  b1,b2,b3,b4,b5,b6,b7:tbitmap;

 implementation

{$R *.DFM}
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

procedure TForm1.FormClick(Sender: TObject);
begin
  close;
end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  close;
end;

procedure TForm1.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if timer1.tag>10 then close;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  close;
end;

procedure TForm1.FormKeyPress(Sender: TObject; var Key: Char);
begin
  close;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  y : integer;
  arect:Trect;
begin
  timer1.tag:=timer1.tag+1;

  y := screen.desktopHeight;

  if p1 then
  begin
   pos1:=pos1-s1;
   if not r1 then
   begin
    arect.Left:=pos1;
    arect.right:=pos1+round(b1.Width*xscale);
    arect.Top:=ypos1;
    arect.bottom:=ypos1+round(b1.height*xscale);
     end else begin
    arect.Left:=round(screen.desktopwidth*xscale)-pos1;
    arect.right:=round(screen.desktopwidth*xscale)-pos1+round(b1.Width*xscale);
    arect.Top:=ypos1;
    arect.bottom:= ypos1+round(b1.height*xscale);
    end;
    canvas.stretchdraw(arect,b1);

   if pos1<-round(screen.desktopwidth*xscale) then
   begin
        pos1:=round(screen.desktopwidth*xscale);
        y:=random (2);
        if y<>0 then r1:=not r1;
          choose(b1,s1,r1);
        end;
  end;

  if p2 then
  begin
   pos2:=pos2-s2;
   if not r2 then
   begin
    arect.Left:=pos2;
    arect.right:=pos2+round(b2.Width*xscale);
    arect.Top:=ypos2;
    arect.bottom:=ypos2+round(b2.height*xscale);
     end else begin
    arect.Left:=round(screen.desktopwidth*xscale)-pos2;
    arect.right:=round(screen.desktopwidth*xscale)-pos2+round(b2.Width*xscale);
    arect.Top:=ypos2;
    arect.bottom:= ypos2+round(b2.height*xscale);
    end;
    canvas.stretchdraw(arect,b2);
   if pos2<-round(screen.desktopwidth*xscale) then
   begin
    pos2:=round(screen.desktopwidth*xscale);
    y:=random (2);

      if y<>0 then r2:=not r2;
        choose(b2,s2,r2);
      end;
  end;

  if p3 then
  begin
   pos3:=pos3-s3;
  if not r3 then
  begin
    arect.Left:=pos3;
    arect.right:=pos3+round(b3.Width*xscale);
    arect.Top:=ypos3;
    arect.bottom:=ypos3+round(b3.height*xscale);
     end else begin
    arect.Left:=round(screen.desktopwidth*xscale)-pos3;
    arect.right:=round(screen.desktopwidth*xscale)-pos3+round(b3.Width*xscale);
    arect.Top:=ypos3;
    arect.bottom:= ypos3+round(b3.height*xscale);
    end;
    canvas.stretchdraw(arect,b3);
   if pos3<-round(screen.desktopwidth*xscale) then
   begin
        pos3:=round(screen.desktopwidth*xscale);
        y:=random (2);
        if y<>0 then r3:=not r3;
        choose(b3,s3,r3);
        end;
  end;

  if p4 then
  begin
   pos4:=pos4-s4;
  if not r4 then
  begin
    arect.Left:=pos4;
    arect.right:=pos4+round(b4.Width*xscale);
    arect.Top:=ypos4;
    arect.bottom:=ypos4+round(b4.height*xscale);
     end else begin
    arect.Left:=round(screen.desktopwidth*xscale)-pos4;
    arect.right:=round(screen.desktopwidth*xscale)-pos4+round(b4.Width*xscale);
    arect.Top:=ypos4;
    arect.bottom:= ypos4+round(b4.height*xscale);
    end;
    canvas.stretchdraw(arect,b4);
   if pos4<-round(screen.desktopwidth*xscale) then
   begin
        pos4:=round(screen.desktopwidth*xscale);
        y:=random (2);
        if y<>0 then r4:=not r4;
        choose(b4,s4,r4);
        end;
  end;

  if p5 then
  begin
   pos5:=pos5-s5;
  if not r5 then
  begin
    arect.Left:=pos5;
    arect.right:=pos5+round(b5.Width*xscale);
    arect.Top:=ypos5;
    arect.bottom:=ypos5+round(b5.height*xscale);
     end else begin
    arect.Left:=round(screen.desktopwidth*xscale)-pos5;
    arect.right:=round(screen.desktopwidth*xscale)-pos5+round(b5.Width*xscale);
    arect.Top:=ypos5;
    arect.bottom:= ypos5+round(b5.height*xscale);
    end;
    canvas.stretchdraw(arect,b5);
   if pos5<-round(screen.desktopwidth*xscale) then
   begin
        pos5:=round(screen.desktopwidth*xscale);
        y:=random (2);
        if y<>0 then r5:=not r5;
        choose(b5,s5,r5);
        end;
  end;

  if p6 then
  begin
   pos6:=pos6-s6;
  if not r6 then
  begin
    arect.Left:=pos6;
    arect.right:=pos6+round(b6.Width*xscale);
    arect.Top:=ypos6;
    arect.bottom:=ypos6+round(b6.height*xscale);
     end else begin
    arect.Left:=round(screen.desktopwidth*xscale)-pos6;
    arect.right:=round(screen.desktopwidth*xscale)-pos6+round(b6.Width*xscale);
    arect.Top:=ypos6;
    arect.bottom:= ypos6+round(b6.height*xscale);
    end;
    canvas.stretchdraw(arect,b6);
   if pos6<-round(screen.desktopwidth*xscale) then
   begin
        pos6:=round(screen.desktopwidth*xscale);
        y:=random (2);
        if y<>0 then r6:=not r6;
        choose(b6,s6,r6);
        end;
  end;

  if p7 then
  begin
   pos7:=pos7-s7;
  if not r7 then
  begin
    arect.Left:=pos7;
    arect.right:=pos7+round(b7.Width*xscale);
    arect.Top:=ypos7;
    arect.bottom:=ypos7+round(b7.height*xscale);
     end else begin
    arect.Left:=round(screen.desktopwidth*xscale)-pos7;
    arect.right:=round(screen.desktopwidth*xscale)-pos7+round(b7.Width*xscale);
    arect.Top:=ypos7;
    arect.bottom:= ypos7+round(b7.height*xscale);
    end;
    canvas.stretchdraw(arect,b7);
   if pos7<-round(screen.desktopwidth*xscale) then
   begin
        pos7:=round(screen.desktopwidth*xscale);
        y:=random (2);
        if y<>0 then r7:=not r7;
        choose(b7,s7,r7);
       end;
  end;

 if timer1.tag> 20 then timer1.tag:=0;
end;

procedure Tform1.choose( var b: Tbitmap;var s :integer ;r : boolean);
var
  x: integer;
begin
   x:= random (12);

  if r then
    x:=2*x+1
  else
    x:=2*x;

 case x of
   0: b:= image1.Picture.Bitmap;
   1: b:= image2.Picture.Bitmap;
   2: b:= image3.Picture.Bitmap;
   3: b:= image4.Picture.Bitmap;
   4: b:= image5.Picture.Bitmap;
   5: b:= image6.Picture.Bitmap;
   6: b:= image7.Picture.Bitmap;
   7: b:= image8.Picture.Bitmap;
   8: b:= image9.Picture.Bitmap;
   9: b:= image10.Picture.Bitmap;
   10: b:= image11.Picture.Bitmap;
   11: b:= image12.Picture.Bitmap;
   12: b:= image13.Picture.Bitmap;
   13: b:= image14.Picture.Bitmap;
   14: b:= image15.Picture.Bitmap;
   15: b:= image16.Picture.Bitmap;
   16: b:= image17.Picture.Bitmap;
   17: b:= image18.Picture.Bitmap;
   18: b:= image19.Picture.Bitmap;
   19: b:= image20.Picture.Bitmap;
   20: b:= image21.Picture.Bitmap;
   21: b:= image22.Picture.Bitmap;
   22: b:= image23.Picture.Bitmap;
   23: b:= image24.Picture.Bitmap;
   end;
   s:=random (3);
   s:=s+1;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  ini:system.text;
  st: string;
  sp,c,wid,hei:integer;
begin
  Form1.DoubleBuffered := True;
  wid:=screen.desktopwidth;
  hei:=screen.desktopheight;
  xscale:= wid / screen.desktopwidth;
  yscale:= hei / screen.desktopheight;

  pos1:=round(screen.desktopwidth*xscale);
  r1:= false;
  pos2:= round(screen.desktopwidth*xscale);
  r2:=false;
  pos3:= round(screen.desktopwidth*xscale);
  r3:=true  ;
  pos4:= round(screen.desktopwidth*xscale);
  r4:=true  ;
  pos5:= round(screen.desktopwidth*xscale);
  r5:=false ;
  pos6:= round(screen.desktopwidth*xscale);

  r6:=false;
  p1:=true;
  p2:=true;
  p3:=true;
  p4:=true;
  p5:=true;
  p6:=true;
  p7:=true;
  randomize;

  b1 := image1.Picture.bitmap;
  b2 := image3.Picture.bitmap;
  b3 := image6.Picture.bitmap;
  b4 := image8.Picture.bitmap;
  b5 := image9.Picture.bitmap;
  b6 := image11.Picture.bitmap;
  b7 := image13.Picture.bitmap;

  s1:=1;
  s2:=2;
  s3:=3;
  s4:=1;
  s5:=2;
  s6:=3;
  s7:=1;

  ypos1:=round(10*yscale);
  ypos2:=round(110*yscale);
  ypos3:=round(210*yscale);
  ypos4:=round(410*yscale);
  ypos5:=round(510*yscale);
  ypos6:=round(710*yscale);
  ypos7:=round(800*yscale);

  assignfile(ini, ExtractFilePath(Application.ExeName) + 'planes.ini');
  try
    reset (ini);
    try
      readln (ini,st);
      val(st,sp,c);
      if (c<>0) or (sp=0) or (sp>6) then sp:=6;
      timer1.interval:= 44-sp*6;
    finally
     closefile(ini);
    end;
   except
       on E:EInouterror do
       begin
       if (c<>0) or (sp=0) or (sp>6) then sp:=6;
       timer1.interval:=44-sp*6;
       try
         rewrite (ini);
         writeln (ini,'6');
         finally
         closefile(ini);
         end;

       end;
    end;
    timer1.enabled:=true;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  MakeFormFullscreenAcrossAllMonitors(Form1);
end;

end.
