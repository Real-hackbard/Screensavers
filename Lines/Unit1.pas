unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, GdipApi, GdipClass, Math;

type
  TForm1 = class(TForm)
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
  { Private-Deklarationen}
    fGPG : TGPGraphics;
    fGPP : TGPPen;
    fBBM : TBitmap;
  public
  { Declarations published }
  end;

var
  Form1: TForm1;
  OldPos: TPoint;

implementation

{$R *.dfm}
{$E scr}

const
  DRAWTYPE_BEZIER  = 10;
  DRAWTYPE_DBLLINE = 1;
  DRAWTYPE_POLYGON = 2;

  cDrawType  = DRAWTYPE_BEZIER;

  cMovers    = 14;
  cFollowers = 40;
  cSpeedMax : single = 0.01;
  cSpeedMin : single = 0.05;
  cColorMin = 100;
  cColorMax = 255;
  cColorIncMin = 50;
  cColorIncMax = 250;

type
  pCatchers = ^TCatchers;
  TCatchers = record
    Pos   : TGPPointF;
    Vel   : TGPPointF;
    Color : TGPColor;
    Follow: pCatchers;
  end;

  pMovers = ^TMovers;
  TMovers = record
    Pos : TGPPointF;
    Vel : TGPPointF;
  end;

var
  Catchers  : array[0..cMovers-1, 0..cFollowers-1] of TCatchers;
  Movers    : array[0..cMovers-1] of TMovers;
  LineColor : record
                Ri, Gi, Bi,
                R, G, B : single
              end;

  FPSStartTime   : LongWord = 0;
  FPSCurrentTime : LongWord = 0;
  FPSPassCounter : LongWord = 0;

  MoveXMin,
  MoveXMax,
  MoveYMin,
  MoveYMax : integer;

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
var
  M,F: integer;
  SP : single;
const
  SpdInv : array[0..1] of integer = (1,-1);
begin
  MakeFormFullscreenAcrossAllMonitors(Form1);
  GetCursorPos(OldPos); // Initial position

  { To generate different random numbers each time it's launched }
  Randomize;

  { To avoid animation flickering }
  DoubleBuffered := true;

  { No cursor on the card }
  //Cursor         := crNone;

  { Definition of the movement limits of the Movers }
  MoveXMin := -20;
  MoveYMin := -20;
  MoveXMax := Screen.DesktopWidth + 200;
  MoveYMax := Screen.DesktopHeight + 200;

  { Selection of a starting color and its incrementers. }
  LineColor.Ri := ((Random(cColorIncMax)+cColorIncMin)*0.001) * SpdInv[Random(100) mod 2];
  LineColor.Gi := ((Random(cColorIncMax)+cColorIncMin)*0.001) * SpdInv[Random(100) mod 2];
  LineColor.Bi := ((Random(cColorIncMax)+cColorIncMin)*0.001) * SpdInv[Random(100) mod 2];
  LineColor.R := Random(128)+127;
  LineColor.G := Random(128)+127;
  LineColor.B := Random(128)+127;

  { Initialization of Catchers and Movers
  }
  for M := 0 to cMovers-1 do
  begin
    { The movers are placed randomly within the area defined by
      MoveXMin,MoveXMax et MoveYMin,MoveYMax. }
    Movers[M].Pos.X := Random(MoveXMax-20)+MoveXMin+10;
    Movers[M].Pos.Y := Random(MoveYMax-20)+MoveYMin+10;
    Movers[M].Vel.X := ((Random(525)+275)*0.01)*SpdInv[Random(100) mod 2];
    Movers[M].Vel.Y := ((Random(525)+275)*0.01)*SpdInv[Random(100) mod 2];

    { The Catchers }
    for F := 0 to cFollowers-1 do
    begin
      if F > 0 then
        Catchers[M,F].Follow := @Catchers[M,F-1]
      else
        Catchers[M,F].Follow := nil;

      SP := cSpeedMin + ((cSpeedMax-cSpeedMin)/cFollowers)*(cFollowers-F);

      Catchers[M,F].Pos.X := Random(MoveXMax-60)+MoveXMin+30;
      Catchers[M,F].Pos.Y := Random(MoveYMax-60)+MoveYMin+30;
      Catchers[M,F].Vel.X := SP;
      Catchers[M,F].Vel.Y := SP;

      Catchers[M,F].Color := ARGBMake(round(200/cFollowers*(cFollowers-F)),
                                      round(LineColor.R), round(LineColor.G),
                                      round(LineColor.B));
    end;
  end;

  fGPP := TGPPen.Create(aclWhite);
  fBBM := TBitmap.Create;
  fBBM.Width  := ClientWidth;
  fBBM.Height := ClientHeight;
  fBBM.PixelFormat := pf32bit;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  fGPP.Free;
  fBBM.Free;
end;

procedure TForm1.FormResize(Sender: TObject);
var
  N : integer;
begin
  fBBM.Width  := ClientWidth;
  fBBM.Height := ClientHeight;

  MoveXMax := ClientWidth + 20;
  MoveYMax := ClientHeight + 20;

  for N := Low(Movers) to High(Movers) do
  begin
    Movers[N].Pos.X := ClientWidth shr 1;
    Movers[N].Pos.Y := ClientHeight shr 1;
  end;
end;


procedure TForm1.PaintBox1Paint(Sender: TObject);
var F   : integer;
    Pts : array[0..3] of TGPPointF;
begin
  { Creation of GDI+ Objects }
  fGPG := TGPGraphics.Create(fBBM.Canvas.Handle);

  { Adjusting the display quality }
  fGPG.SetCompositingQuality(CompositingQualityHighSpeed);
  fGPG.SetSmoothingMode(SmoothingModeAntiAlias);
  fGPG.Clear(aclBlack);

  { Incrementing the color of the Catchers }
  LineColor.R := LineColor.R + LineColor.Ri;
  if (LineColor.R <= cColorMin) or (LineColor.R >= cColorMax) then
    LineColor.Ri := LineColor.Ri * -1;

  LineColor.G := LineColor.G + LineColor.Gi;
  if (LineColor.G <= cColorMin) or (LineColor.G >= cColorMax) then
    LineColor.Gi := LineColor.Gi * -1;

  LineColor.B := LineColor.B + LineColor.Bi;
  if (LineColor.B <= cColorMin) or (LineColor.B >= cColorMax) then
    LineColor.Bi := LineColor.Bi * -1;

  { Drawing of the Catchers, here we will use Bézier curves! }
  for F := 0 to cFollowers-1 do
  begin
    { We are redefining the color }
    Catchers[0,F].Color := ARGBMake(ARGBGetAlpha(Catchers[0,F].Color),
                                    round(LineColor.R), round(LineColor.G),
                                    round(LineColor.B));

    fGPP.SetColor(Catchers[0,F].Color);

    { We draw the curves }
    case cDrawType of
      DRAWTYPE_BEZIER  :
        fGPG.DrawBezier(fGPP, Catchers[0,F].Pos, Catchers[1,F].Pos,
                              Catchers[2,F].Pos, Catchers[3,F].Pos);
      DRAWTYPE_DBLLINE :
      begin
        fGPG.DrawLine(fGPP, Catchers[0,F].Pos, Catchers[2,F].Pos);
        fGPG.DrawLine(fGPP, Catchers[1,F].Pos, Catchers[3,F].Pos);
      end;

      DRAWTYPE_POLYGON :
      begin
        Pts[0] := Catchers[0,F].Pos;
        Pts[1] := Catchers[1,F].Pos;
        Pts[2] := Catchers[2,F].Pos;
        Pts[3] := Catchers[3,F].Pos;
        fGPG.DrawPolygon(fGPP, pGPPointF(@Pts), 4);
      end;
    end;
  end;

  { We release the GDI+ objects }
  fGPG.Flush;
  fGPG.Free;

  Canvas.Draw(0,0,fBBM);
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  M, F: integer;
  DX, DY, FPS : single;
  NewPos: TPoint;
begin
  GetCursorPos(NewPos);
  if (NewPos.X <> OldPos.X) or (NewPos.Y <> OldPos.Y) then
  begin
    // Mouse moved
    Close();
  end;


  { FPS Counter }
  if (FPSCurrentTime = 0) and (FPSPassCounter = 0) then
    FPSStartTime := GetTickCount;
  inc(FPSPassCounter);

  { Movement of Catchers and Movers }
  for M := 0 to cMovers-1 do
  begin
    { The Movers operate within a defined area by
      MoveXMin, MoveXMax et MoveYMin, MoveYMax }
    Movers[M].Pos.X := Movers[M].Pos.X + Movers[M].Vel.X;
    if (Movers[M].Pos.X <= MoveXMin) or (Movers[M].Pos.X >= MoveXMax) then
      Movers[M].Vel.X := Movers[M].Vel.X * -1;

    Movers[M].Pos.Y := Movers[M].Pos.Y + Movers[M].Vel.Y;
    if (Movers[M].Pos.Y <= MoveYMin) or (Movers[M].Pos.Y >= MoveYMax) then
      Movers[M].Vel.Y := Movers[M].Vel.Y * -1;

    { The first Catchers (Catchers[M,0]) must catch the Movers }
    DX := Catchers[M, 0].Vel.X*(Movers[M].Pos.X - Catchers[M, 0].Pos.X);
    if DX = 0 then
      Catchers[M, 0].Pos.X := Movers[M].Pos.X
    else
      Catchers[M, 0].Pos.X := Catchers[M, 0].Pos.X + DX;

    DY := Catchers[M, 0].Vel.Y*(Movers[M].Pos.Y - Catchers[M, 0].Pos.Y);
    if DY = 0 then
      Catchers[M, 0].Pos.Y := Movers[M].Pos.Y
    else
      Catchers[M, 0].Pos.Y := Catchers[M, 0].Pos.Y + DY;

    { The other Catchers (Catchers[M, F > 0]) must follow the first Catchers }
    for F := 1 to cFollowers-1 do
      if Catchers[M,F].Follow <> nil then
      begin
        DX := Catchers[M,F].Vel.X*(Catchers[M,F].Follow^.Pos.X - Catchers[M,F].Pos.X);
        if DX = 0 then
          Catchers[M,F].Pos.X := Catchers[M,F].Follow^.Pos.X
        else
          Catchers[M,F].Pos.X := Catchers[M,F].Pos.X + DX;

        DY := Catchers[M,F].Vel.Y*(Catchers[M,F].Follow^.Pos.Y - Catchers[M,F].Pos.Y);
        if DY = 0 then
          Catchers[M,F].Pos.Y := Catchers[M,F].Follow^.Pos.Y
        else
          Catchers[M,F].Pos.Y := Catchers[M,F].Pos.Y + DY;
      end;
  end;

  { FPS Counter }
  FPSCurrentTime := GetTickCount-FPSStartTime;

  if FPSCurrentTime >= 1000 then
  begin
    FPS := 1000/FPSCurrentTime*FPSPassCounter;
    Caption := format('%.2n FPS',[FPS]);
    FPSPassCounter := 0;
    FPSCurrentTime := 0;
  end;

  { Request to redesign }
  Invalidate;
end;

procedure TForm1.FormKeyPress(Sender: TObject; var Key: Char);
begin
  Close();
end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  Close();
end;

end.
