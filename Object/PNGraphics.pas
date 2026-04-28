unit PNGraphics;

{ -------------------------------------------------------------
 *************** Rapid Planar Graphic Engine ******************
                        Version 1.0
                        For Delphi
 ************************************************************** }

interface

uses
  Classes,Windows,Graphics, SysUtils, Dialogs;

type
  EInvalidPolygon = Class(Exception);
  TRapidAlpha = 0..128;
  TPoints = array of TPoint;
  TRapidPixel = record
                Case Integer of
                1:(  B : Byte;
                     G : Byte;
                     R : Byte;
                     A : TRapidAlpha; );
                2:(HoleColorPart:TColor);
                end;
  TRapidColorRGB = record
                  R : Byte;
                  G : Byte;
                  B : Byte;
                  A : TRapidAlpha;
                end;
  TRapidColor = TRapidPixel;
  TRapidPixels = array of array of TRapidPixel;
  PRapidPixels = ^TRapidPixels;
  TRapidPixelPointer = array of PByteArray;
  TRapidBrush = record
                  Color : TRapidColorRGB;
                end;
  TRapidPen = record
                Color : TRapidColorRGB;
              end;
  PLayer = ^TRapidLayer;
  TLayersSet = array of pLayer;
  TRapidCanvas = class(TObject)
    private
      FWidth:Integer;
      FHeight:Integer;
      FPixels : PRapidPixels;
      procedure QuickSort(var P:Tpoints;LargeToSmall:Boolean);
    public
      FPen: TRapidPen;
      FBrush: TRapidBrush;
      Constructor Create(Pixels:PRapidPixels);
      Procedure Free;
      Procedure Circle(x,y:Integer;r:Integer);
      procedure Ellipse(x,y,a,b:Integer);
      {equation of a Ellipse:
                   x/(a^2) + y/(b^2) = 1}
      procedure Polygon(Points:TPoints);
      procedure Line(x1,y1,x2,y2:Integer);
      procedure Rectangle(x1,y1,x2,y2:Integer);
      property Height:Integer Read FHeight write FHeight default 0;
      property Width : Integer read FWidth write FWidth default 0;
  end;
  TRapidLayer = class(TObject)
    private
      FPixels : TRapidPixels;
      FLeft: Integer;
      FAlpha: Integer;
      FTop: Integer;
      FHeight: Integer;
      FWidth: Integer;
      FCanvas: TRapidCanvas;
      FAlphaBlending: Boolean;
      function  GetOrigin: TPoint;
      procedure SetAlpha(const Value: Integer);
      procedure SetHeight(const Value: Integer);
      procedure SetLeft(const Value: Integer);
      procedure SetOrigin(const Value: TPoint);
      procedure SetTop(const Value: Integer);
      procedure SetWidth(const Value: Integer);
    public
      
      Constructor Create(Left,Top,Width,Height:Integer);overload;
      Constructor Create;overload;
      procedure Free;
      procedure Clear;
      procedure CopyFrom(Source:TRapidPixels;X,Y:Integer);
      procedure SelectivityCopy(SourceRect:TRect;Source:TRapidPixels;X,Y:Integer);
      procedure LoadFromBitmap(Bitmap:TBitmap);
    //procedure Zoom(NewWidth,NewHeight:Integer);
      procedure ConvertToBitmap(Bitmap:TBitmap);
      property Canvas : TRapidCanvas read FCanvas;
      property Pixels:TRapidPixels read FPixels write FPixels;
      property Height:Integer Read FHeight write SetHeight;
      property Width : Integer read FWidth write SetWidth;
      property Alpha : Integer read FAlpha write SetAlpha default 127;
      property Left : Integer read FLeft  write SetLeft;
      property Top : Integer read FTop write SetTop;
      property Origin:TPoint read GetOrigin write SetOrigin;
      property AlphaBlending:Boolean read FAlphaBlending write FAlphaBlending default True;
  end;
  TLayers = Class(TObject)
    private
    FLayersSet: TLayersSet;
    FCount: Integer;
    public
      Constructor Create;
      Procedure Free;
      property LayersSet:TLayersSet read FLayersSet;
      property Count:Integer read FCount;
      function FromIndex(Index : Integer) : pLayer;
      procedure Move(IndexOriginal,DestIndex:Integer);
      procedure Append(Layer:pLayer);
      procedure Delete(Index : Integer);
      procedure Swap(Index1,Index2:Integer);
      procedure Insert(Layer:TRapidLayer;Index:Integer);
  end;

  TRapidGraph = Class(TObject)
    private
      FPixels: TRapidPixels;
      FLayers: TLayers;
      BitOut : TBitmap;
      FHeight: Integer;
      FWidth: Integer;
      FPixPtr : TRapidPixelPointer;
      FAlphaBlending: Boolean;
      procedure ReCalculatePixels(AlphaBlend:Boolean=True);
      procedure Clear;
    public
    
      Constructor Create(Bitmap:TBitmap);
      procedure Free;
      procedure Paint(Rect:TRect);
      Function LoadFromFile(FileName:String):Integer;
      procedure SaveToBitmap(Bitmap:TBitmap);
      Function SaveToFile(FileName:String):Integer;
      procedure Zoom(NewWidth,NewHeight:Integer);
      property AlphaBlending : Boolean Read FAlphaBlending write FAlphaBlending default True;
      property Layers : TLayers read FLayers;
      property Pixels : TRapidPixels read FPixels;
      property Height : Integer read FHeight;
      property Width : Integer read FWidth;
  end;
Procedure ReadPixels(Bit : TBitmap; var Pixels : TRapidPixels;
                     var PixPointer:TRapidPixelPointer;ToPixel:Boolean=True);
procedure WritePixels(PixPointer:TRapidPixelPointer;Pixels:TRapidPixels;
                      Height,Width : Integer);
procedure BitmapToGray(Bit:TBitmap);
implementation

{Procedures}
procedure BitmapToGray(Bit:TBitmap);
var pixs:TRapidPixels;PixPtr:TRapidPixelPointer;
    i,j:Integer;  curV:Byte;
begin
  ReadPixels(Bit,pixs,PixPtr);
  for j := 0 to Bit.Height -1 do
  begin
    for i := 0 to Bit.Width -1 do
    begin
      curV:= (Pixs[i,j].R + Pixs[i,j].G + Pixs[i,j].B) div 3;
      PixPtr[j,i*3] := curV;
      PixPtr[j,i*3+1] := curV;
      PixPtr[j,i*3+2] := curV;
    end;
  end;
end;

Procedure ReadPixels(Bit : TBitmap; var Pixels : TRapidPixels;
                     var PixPointer:TRapidPixelPointer;ToPixel:Boolean=True);
var PixPtr:  PbyteArray;
    i, j ,m: Integer;
begin
  SetLength(Pixels,Bit.Width,Bit.Height);
  Bit.PixelFormat := pf24bit;
  Bit.HandleType:=bmDIB;
  SetLength(PixPointer,Bit.Height);
  For i :=0 to Bit.Height-1 do begin
      PixPtr:=Bit.ScanLine[i];
      PixPointer[i] := PixPtr;
      if ToPixel then
      for  j:= 0 to Bit.Width-1 do begin
         m := j*3;
         Pixels[j,i].B := PixPtr[m];
         Pixels[j,i].G := PixPtr[m+1];
         Pixels[j,i].R := PixPtr[m+2];
         Pixels[j,i].A := 128;
      end;
  end;
end;

procedure WritePixels(PixPointer:TRapidPixelPointer;Pixels:TRapidPixels;
                      Height,Width : Integer);
var
  i,j: Integer;
  W,H:Integer;
  CI,IP1,IP2: Integer;
begin
  W:= Width -1;
  H:= Height -1;
  for i := 0 to W do begin
    CI  := i*3;
    IP1 := CI +1;
    IP2 := IP1 + 1;
    for j := 0 to H do begin
      PixPointer[j][CI]  := Pixels[i,j].R;
      PixPointer[j][IP1] := Pixels[i,j].G;
      PixPointer[j][IP2] := Pixels[i,j].B;
    end;
  end;
end;

{ TRapidLayer }

procedure TRapidLayer.Clear;
var i , j :Integer;
begin
  For i := 0 to FWidth-1 do begin
    For j := 0 to FHeight -1 do begin
      FPixels[i,j].R := 255;
      FPixels[i,j].G := 255;
      FPixels[i,j].B := 255;
      FPixels[i,j].A := 0;
    end;
  end;
end;

procedure TRapidLayer.ConvertToBitmap(Bitmap: TBitmap);
var Pixs : TRapidPixels;
    PixPtr : TRapidPixelPointer;
begin
  ReadPixels(Bitmap,Pixs,PixPtr);
  WritePixels(PixPtr,FPixels,FWidth,FHeight);
end;

// this procedure is to copy the pixels from source to current layer
procedure TRapidLayer.CopyFrom(Source: TRapidPixels; X,Y:Integer);
var i,j,h,w:Integer;HU,WU:Integer;
begin
  h := High(Source[0])+y;
  w := High(Source)+x;
  HU := FHeight-1;  // do the numeration before loop
  WU := FWidth -1;
  For i := x to w do
  begin
    if i<0 then Continue; // If Index Out of Range, ignore and continue.
    if i>WU then break;
    for j := y to h do
    begin
      if j<0 then Continue;          
      if j>HU then break;
      FPixels[i,j].R := Source[i,j].R; // Copy Pixel Color
      FPixels[i,j].G := Source[i,j].G;
      FPixels[i,j].B := Source[i,j].B;
      FPixels[i,j].A := Source[i,j].A;
    end;
  end;
end;

constructor TRapidLayer.Create(Left, Top, Width, Height: Integer);
begin
  Create;
  SetHeight(Height);
  SetWidth(Width);
  SetLeft(Left);
  SetTop(Top);
  
end;

constructor TRapidLayer.Create;
begin
  FHeight := 0;
  FWidth := 0;
  FTop := 0;
  FLeft := 0;
  FAlpha := 127;
  FCanvas := TRapidCanvas.Create(@FPixels);
  FAlphaBlending := True;
end;

procedure TRapidLayer.Free;
begin
  FCanvas.Free;
end;

function TRapidLayer.GetOrigin: TPoint;
begin
  Result := Point(FLeft,FTop);
end;

procedure TRapidLayer.LoadFromBitmap(Bitmap: TBitmap);
var PixPtr : TRapidPixelPointer;
begin
  SetLength(FPixels,Bitmap.Width,Bitmap.Height);
  ReadPixels(Bitmap,FPixels,PixPtr);
end;

procedure TRapidLayer.SelectivityCopy(SourceRect: TRect;
  Source: TRapidPixels; X,Y: Integer);
var i,j,h,w:Integer;
    hu,wu:Integer;
    cx,cy : Integer;
begin
  h := High(Source[0]);
  w := High(Source);
  // To validate the validity of SourceRect
  if SourceRect.Left   < 0 then SourceRect.Left   :=0;
  if SourceRect.Top    < 0 then SourceRect.Top    :=0;
  if SourceRect.Right  < 0 then SourceRect.Right  :=0;
  if SourceRect.Bottom < 0 then SourceRect.Bottom :=0;
  if SourceRect.Left   > w then SourceRect.Left   :=w;
  if SourceRect.Top    > h then SourceRect.Top    :=h;
  if SourceRect.Right  > w then SourceRect.Right  :=w;
  if SourceRect.Bottom > h then SourceRect.Bottom :=h;

  cx := SourceRect.Left;
  cy := SourceRect.Top;
  hu := h-1;
  wu := w-1;
  h := SourceRect.Bottom - SourceRect.Top + y;
  w := SourceRect.Right - SourceRect.Left + x;
  for i := x to w do
  begin
    if i < 0  then continue;
    if i > wu then break;
    cy := SourceRect.Top;
    for j := y to h do
    begin
      if j<0 then continue;
      if j>hu then break;
      FPixels[i,j].R := Source[cx,cy].R;
      FPixels[i,j].G := Source[cx,cy].G;
      FPixels[i,j].B := Source[cx,cy].B;
      FPixels[i,j].A := Source[cx,cy].A;
      inc(cy);
    end;
    inc(cx);
  end;
end;

procedure TRapidLayer.SetAlpha(const Value: Integer);
begin
  FAlpha := Value;
end;

procedure TRapidLayer.SetHeight(const Value: Integer);
var LastH : Integer;
    DeltaH :Integer;
    i,j : Integer;
    LHeight : Integer;
begin
  LastH := FHeight -1;
  DeltaH := Value - FHeight;
  FHeight := Value;
  LHeight := FHeight-1;
  SetLength(FPixels,FWidth,FHeight);
  FCanvas.Height := Value;
  if DeltaH>0 then
  begin
    for i := 0 to FWidth-1 do
    begin
      for j := LastH to LHeight do
      begin
        FPixels[i,j].R := 255;
        FPixels[i,j].G := 255;
        FPixels[i,j].B := 255;
        FPixels[i,j].A := 0;
      end;
    end;
  end;
end;

procedure TRapidLayer.SetLeft(const Value: Integer);
begin
  FLeft := Value;
end;

procedure TRapidLayer.SetOrigin(const Value: TPoint);
begin
  FTop := Value.Y;
  FLeft := Value.X;
end;

procedure TRapidLayer.SetTop(const Value: Integer);
begin
  FTop := Value;
end;

procedure TRapidLayer.SetWidth(const Value: Integer);
var DeltaW:Integer;
    LastW : Integer;
    i,j:Integer;
begin
  DeltaW := Value - FWidth;
  FCanvas.Width := value;
  LastW := FWidth;
  if LastW = 0 then LastW := 1;
  FWidth := Value;
  SetLength(FPixels,FWidth,FHeight);
  if DeltaW > 0 then
  begin
    for i := LastW-1 to FWidth-1 do
    begin
      for j := 0 to FHeight-1 do
      begin
        FPixels[i,j].R := 255;
        FPixels[i,j].G := 255;
        FPixels[i,j].B := 255;
        FPixels[i,j].A := 0;
      end;
    end;
  end;
end;

{
procedure TRapidLayer.Zoom(NewWidth, NewHeight: Integer);
var CRow : array of TRapidPixel;
    CCol : array of TRapidPixel;
    i,j,k:Integer;
    lstH,lstW:Integer;   zRate:Extended;
    nPos,lstPos:Integer; cDeltaR,cDeltaG,cDeltaB,cDeltaA:Integer;
    npmlp:Integer;
    jm1:Integer;
begin
  lstH:=FHeight;
  lstW:=FWidth;
  SetHeight(NewHeight);
  SetWidth(NewWidth);
  SetLength(CRow,NewWidth);
  SetLength(CCol,NewHeight);

  ////////////////////////////Width Process////////////////////////////

  zRate:=NewWidth/lstW;
  if NewWidth>lstW then begin
    for i := 0 to lstH-1 do
    begin
      lstPos:=0;
      CRow[0].R := FPixels[0,i].R;
      CRow[0].G := FPixels[0,i].G;
      CRow[0].B := FPixels[0,i].B;
      CRow[0].A := FPixels[0,i].A;
      for j := 1 to lstW-1 do
      begin
        nPos:=Round(zRate *j);
        if nPos>lstPos then
        begin
          jm1 := j-1;
          npMlp := nPos-lstPos;
          cDeltaR := (FPixels[j,i].R -FPixels[jm1,i].R)div npMLp;
          cDeltaG := (FPixels[j,i].G -FPixels[jm1,i].G)div npMLp;
          cDeltaB := (FPixels[j,i].B -FPixels[jm1,i].B)div npMLp;
          cDeltaA := (FPixels[j,i].A -FPixels[jm1,i].A)div npMLp;
          for k := lstPos+1 to nPos do                                     
          begin
            if k = nPos then begin
              CRow[k].R := FPixels[jm1,i].R;
              CRow[k].G := FPixels[jm1,i].G;
              CRow[k].B := FPixels[jm1,i].B;
              CRow[k].A := FPixels[jm1,i].A;
            end
            else begin
              cRow[k].R := CRow[k-1].R+cDeltaR;
              cRow[k].G := CRow[k-1].G+cDeltaG;
              cRow[k].B := CRow[k-1].B+cDeltaB;
              cRow[k].A := CRow[k-1].A+cDeltaA;
            end;{if}
   {       end;{k}
 {       end;{if}
{        for k := 0 to NewWidth-1 do
        begin
          FPixels[k,i] := CRow[k];
        end;
      end;{j}
 {   end;{i}
{  end
  else if NewWidth<lstW then
  begin

{  end;{if}

  //////////////////////// Height Process //////////////////////

{  if NewHeight>lstH then
  begin

  end
  else if NewHeight<lstH then
  begin

 { end;{if}

{end;   }

{ TRapidCanvas }

procedure TRapidCanvas.Circle(x, y, r: Integer);
var a2,b2,r2,a,b,t2a,a2pb2mr2,t4b2,t2b:Integer;
    c:Single;
    i:Integer;
    y1,y2:Integer; Delta:Single;
    lstY1,lstY2:Integer;
    lstPen:TRapidPen;
    amr:Integer;  im1:Integer;

begin
  lstPen:=FPen;
  FPen := TRapidPen(FBrush);
  a:=x;
  b:=y;
  t2b:=y*2;
  a2:=a*a;
  b2:=b*b;
  r2:=r*r;
  t4b2:=4*b2;
  t2a:=x*2;
  a2pb2mr2:=a2+b2-r2;
  amr:=a-r;
  for i := amr to a+r do
  begin
    c := i*(t2a-i)-a2pb2mr2;
    Delta:= sqrt(t4b2+4*c);
    y1:=Round((t2b+Delta)/2);
    y2:=Round((t2b-Delta)/2);
    if y1-y2>3 then
      Line(i,y1-1,i,y2+1);//Fill the circle with Brush Color
    if (i>0) and (i<FWidth-1) and (y1>0) and (y2>0) and (y1<FHeight-1)
             and (y2<FHeight-1) then begin
    FPixels^[i,y1].R := lstPen.Color.R;//Draw the outline(Point)
    FPixels^[i,y1].G := lstPen.Color.G;
    FPixels^[i,y1].B := lstPen.Color.B;
    FPixels^[i,y1].A := lstPen.Color.A;
    FPixels^[i,y2].R := lstPen.Color.R;
    FPixels^[i,y2].G := lstPen.Color.G;
    FPixels^[i,y2].B := lstPen.Color.B;
    FPixels^[i,y2].A := lstPen.Color.A;
    end;
    FPen:=lstPen;
    if (i>amr)and(abs(y1-lstY1)>=1) then begin
      im1:=i-1;
      Line(im1,lstY1,im1,y1);   //Combine Points with Line if y1>lstY1+1
      Line(im1,lstY2,im1,y2);
    end;
    lstY1:=y1;
    lstY2:=y2;
    FPen.Color:=FBrush.Color;
  end;
  FPen:=lstPen;
end;

constructor TRapidCanvas.Create(Pixels: PRapidPixels);
begin
  FPixels := Pixels;
  FPen.Color.R := 0;
  FPen.Color.G := 0;
  FPen.Color.B := 0;
  FPen.Color.A := 128;
  FBrush.Color.R := 0;
  FBrush.Color.G := 0;
  FBrush.Color.B := 0;
  FBrush.Color.A := 128;
end;

procedure TRapidCanvas.Ellipse(x, y, a, b: Integer);
var b2,a2,y02,x02,t2y0,t2x0,y0,t4x02,b2x02,t2a,t2b,c,d:Integer;
    i:Integer;
    x1,x2:integer;
    a2b2,a2t2y0,a2y02:Integer;
    a2b2ma2y02:Integer;
    lstX1,lstX2:Integer; lstPen:TRapidPen;
begin
  lstPen := FPen;
  y0:=y;
  b2 := b*b;
  a2 := a*a;
  y02 := y*y;
  x02 := x*x;
  t2y0 := 2*y0;
  b2x02 := b2*x02;
  t2x0:=x*2;
  t4x02:=4*x02;
  a2b2 := a2*b2;
  a2t2y0 := a2*t2y0;
  a2y02 := a2*y02;
  t2a:=a*2;
  a2b2ma2y02:=a2b2-a2y02;
  t2b := b*2+y-b;
  for i := 0 to b do
  begin
    c:=a*a*b*b-b*b*x*x-a*a*i*i+2*y*a*a*i-a*a*y; //a2b2ma2y02-i*(i-a2t2y0);
    d:=round(c/(b*b));                          //Round((-c-b2x02)/b2);
    x1:= Round(x*2-sqrt(4*x*x+4*d)/2);
    x2 := t2a-(x1-x+a)-x1;
    if abs(x2-x1)>3 then begin
      FPen := TRapidPen(FBrush);
      Line(x1+1,i,x2-1,i);
      Line(x1+1,t2b-i,x2-1,t2b-i);
      if i>0 then begin
        FPen := lstPen;
        if abs(x1-lstX1)>3 then begin
          Line(x1,i,lstx1,i-1);
          Line(x2,i,lstx2,i-1);
          Line(t2b-x1,i,t2b-lstx1,i+1);
          Line(t2b-x2,i,t2b-lstx2,i+1);
        end;
      end;
    end;
    lstX1:=x1;
    lstX2:=x2;
  end;{i}
end;

procedure TRapidCanvas.Free;
begin
end;

procedure TRapidCanvas.Line(x1, y1, x2, y2: Integer);
var CY:Integer; SY : Single;i:Integer; ny1,ny2:Integer;
   nx1,nx2,nny1,nny2:Integer;
begin
  if x2>x1 then begin
    nx2:=x2;
    nx1:=x1;
    ny2:=y2;
    ny1:=y1
  end
  else
  begin
    nx2:=x1;
    nx1:=x2;
    ny2:=y1;
    ny1:=y2;
  end;
  if nx2-nx1 <> 0 then
  begin
    SY := (ny2-ny1)/(nx2-nx1);
    for i := nx1 to nx2 do
    begin
      if i>FWidth-1 then break;
      cy := Round(SY*(i-nx1))+ny1;
      if cy>FHeight-1 then Continue;
      FPixels^[i,cy].R := FPen.Color.R;
      FPixels^[i,cy].G := FPen.Color.G;
      FPixels^[i,cy].B := FPen.Color.B;
      FPixels^[i,cy].A := FPen.Color.A;
    end;
  end
  else
  begin
    if ny1<ny2 then begin nny1 := ny1;nny2:=ny2;end
    else begin nny1 := ny2;nny2:=ny1;end;
    for i := nny1 to nny2 do
    begin
      if i<0 then Continue;
      if nx1<0 then continue;
      if i>FHeight-1 then break;
      if nx1>FWidth-1 then Break;
      FPixels^[nx1,i].R := FPen.Color.R;
      FPixels^[nx1,i].G := FPen.Color.G;
      FPixels^[nx1,i].B := FPen.Color.B;
      FPixels^[nx1,i].A := FPen.Color.A;
     end;
  end;
end;

procedure TRapidCanvas.Polygon(Points: TPoints);
var PLeft:TPoints;PRight:TPoints;P1,P2:TPoint;
    i,j:Integer;cl,cr:TPoint;
    n:Integer; MaxYv,MaxYi,MinYv,MinYi:Integer;
    PRC,PLC:Integer;
    li,ri:Integer;
    lp1,lp2,rp1,rp2:TPoint;
    InvalidPolygonException:EInvalidPolygon;
    y2my1 : Integer;
    lstPen:TRapidPen;
    P1P2K:Single;  LRV:Integer;
    EdgPts:TPoints;
    tmp:TPoint;
begin
  n :=High(Points);
  MaxYv := -MaxInt-1;
  MinYv := MaxInt;
  PRC := 0;
  PLC := 0;
  lstPen := FPen;
  FPen := TRapidPen(FBrush);
  //Step 1: Get the Top and Bottom Point Index:
  for i := 0 to n do
  begin
    
    if Points[i].Y > MaxYv then
    begin
      MaxYv := Points[i].Y;
      MaxYi := i;
    end;{if}
    if Points[i].Y < MinYv then
    begin
      MinYv := Points[i].Y;
      MinYi := i;
    end;{if}
  end;{i}
  P1 := Points[MinYi];
  P2 := Points[MaxYi];

  P1P2K := (p2.X-p1.X)/(p2.Y-p1.Y);
  //Step 2: Intialize PLeft and PRight List (The Top and Bottom Point are
  //        Included into both Point Lists):
  SetLength(PLeft,n+1);
  SetLength(PRight,n+1);
  for i := 0 to n do
  begin
    LRV := Round((Points[i].Y-p1.Y)  * P1P2K) + P1.X;
    if Points[i].X <= LRV then
    begin
      if Points[i].Y <=MaxYv then begin
         PLeft[PLC] := Points[i];
         Inc(PLC);
      end;{if}
    end;{if}
    if Points[i].X >= LRV then
    begin
      if (Points[i].Y <MaxYv) or (Points[i].Y = MaxYv) then begin
         PRight[PRC] := Points[i];
         Inc(PRC);
      end;{if}
    end;{if}
  end;{i}
  SetLength(PLeft,PLC);
  SetLength(PRight,PRC);
  QuickSort(PLeft,True); //True Means From Small To Large
  QuickSort(PRight,False); //False Means From Large To Small
  if PRight[prc-1].Y = PRight[prc-2].Y then
  begin
    if PRight[prc-2].X = Points[MinYi].X then begin
      tmp := PRight[prc-1];
      PRight[prc-1] := PRight[prc-2];
      PRight[prc-2] := tmp;
    end;
  end;
  //Step 3: Draw Lines To Fill The Polygon:
  for i := MinYv+1 to MaxYv-1 do
  begin
    { First, Find tow Points in the tow Points List
              that are in each side of the edge.  }
    for j := 0 to PLC-1 do
    begin
      if PLeft[j].Y > i then
      begin
        li := j;
        Break;
      end;{if}
    end;{j}
   
    for j := PRC-1 downto 0 do
    begin
      if PRight[j].Y > i then
      begin
        if PRight[j+1].Y > i then
          ri := j+1
        else
          ri := j;
        Break;
      end;{if}
    end;{j}
    rp1 := PRight[ri+1];
    rp2 := PRight[ri];
    lp1 := PLeft[li-1];
    lp2 := PLeft[li];

    //Second, Calculate cx,cy
    {Tow-Point Form Equation of Line:
       (y-y1)/(y2-y1)=(x-x1)/(x2-x1) (when x2<>x1, y2<>y1)
    == (y-y1)*(x2-x1) = (y2-y1)*(x-x1) (Benifits any Situation)
    According to this, we can get:
        x = (x2(i-y1)-ix1)/(y2-y1)}
        
    y2my1 := lp2.Y - lp1.Y;
    if lp2.Y =lp1.Y then
      Raise InvalidPolygonException.Create('The Polygon must be a Convex Polygon.');
    if rp2.Y =rp1.Y then
      Raise InvalidPolygonException.Create('The Polygon must be a Convex Polygon.');
    cl.X := Round((i-lp1.Y)*(lp2.x-lp1.x)/(lp2.y-lp1.y))+lp1.x;
    cl.Y := i;
    cr.Y := i;
    cr.X := Round((i-rp1.Y)*(rp2.x-rp1.x)/(rp2.y-rp1.y))+rp1.x;

    //Thrid, Connect them

    if cr.X - cl.X >= 3 then
      Line(cl.X+1,cl.Y,cr.X-1,cr.Y);
    FPixels^[cl.X,cl.Y] := TRapidPixel(lstPen.Color);
    FPixels^[cr.X,cr.Y] := TRapidPixel(lstPen.Color);
  end;{i}
  // Step 4 : Draw Edges:
  FPen := lstPen;
  SetLength(EdgPts,n+1);
  for i := 0 to PLC do
    EdgPts[i] := PLeft[i];
  for i := 1 to prc-1 do
    EdgPts[i+PLC-1] := PRight[i];
  for i := 0 to n do
    Line(EdgPts[i].X,EdgPts[i].Y,EdgPts[i+1].X,EdgPts[i+1].Y) ;
  Line(EdgPts[0].x,EdgPts[0].y,EdgPts[n].x,EdgPts[n].y);
  
end;

procedure TRapidCanvas.QuickSort(var P: Tpoints; LargeToSmall: Boolean);
var i,j:Integer;
   tmp:TPoint;
   n:Integer;
begin
  n:=High(P);
  for i := 0 to n do
  begin
    for j := 0 to i do
    begin
      if Not(LargeToSmall) and (P[i].Y > P[j].Y) then begin
        tmp := P[i];
        P[i] := P[J];
        P[j] := tmp;
      end
      else if LargeToSmall and (P[i].Y < P[j].Y) then begin
        tmp := P[i];
        P[i] := P[J];
        P[j] := tmp;
      end;
    end;
  end;
end;

procedure TRapidCanvas.Rectangle(x1, y1, x2, y2: Integer);
var i,j:Integer;
begin
  Line(x1,y1,x2,y1);
  Line(x1,y1,x1,y2);
  Line(x1,y2,x2,y2);
  Line(x2,y2,x2,y1);
  for i := x1+1 to x2-1 do
  begin
    if i>FWidth-1 then Break;
    if i<0 then Continue;
    for j := y1+1 to y2-1 do
    begin
      if j<0 then continue;
      if j>FHeight-1 then Break;
      FPixels^[i,j].R := FBrush.Color.R;
      FPixels^[i,j].G := FBrush.Color.G;
      FPixels^[i,j].B := FBrush.Color.B;
      FPixels^[i,j].A := FBrush.Color.A;
    end;
  end;
end;

{ TLayers }

procedure TLayers.Append(Layer: pLayer);
begin
  SetLength(FLayersSet,FCount+1);
  FLayersSet[FCount] :=Layer;
  FCount := FCount+1;
end;

constructor TLayers.Create;
begin
  FCount:=0;
end;

procedure TLayers.Delete(Index: Integer);
var i:Integer;
begin
  FLayersSet[Index].Free;
  FLayersSet[Index] := nil;
  if Index<FCount-1 then
  begin
    for i := Index+1 to FCount-1 do
    begin
      FLayersSet[i-1]:=FLayersSet[i];
    end;
  end;
  FCount := FCount-1;
  SetLength(FLayersSet,FCount);
end;

procedure TLayers.Free;
var i:Integer;
begin
  for i := 0 to FCount-1 do
  begin
    FLayersSet[i].Free;
    FLayersSet[i] := Nil;
  end;
  SetLength(FLayersSet,0);
end;

function TLayers.FromIndex(Index: Integer): pLayer;
begin
  Result := LayersSet[Index];
end;

procedure TLayers.Insert(Layer: TRapidLayer; Index: Integer);
var i :Integer;
begin
  SetLength(FLayersSet,FCount+1);
  for i := FCount downto Index+1 do
  begin
    FLayersSet[i] := FLayersSet[i-1];
  end;
  FLayersSet[Index] := @Layer;
  FCount := FCount+1;
end;

procedure TLayers.Move(IndexOriginal, DestIndex: Integer);
var i:Integer;
    tmp :PLayer;
begin
  tmp := FLayersSet[IndexOriginal];
  if DestIndex < IndexOriginal then
  begin
    for i :=IndexOriginal-1 downto DestIndex do
    begin
      FLayersSet[i+1] := FLayersSet[i];
    end;
    FLayersSet[DestIndex] := tmp;
  end
  else
  begin
    for i := IndexOriginal+1 to DestIndex do
    begin
      FLayersSet[i-1] := FLayersSet[i];
    end;
    FLayersSet[DestIndex] := tmp;
  end;
end;

procedure TLayers.Swap(Index1, Index2: Integer);
var tmp:PLayer;
begin
  tmp := FLayersSet[Index1];
  FLayersSet[Index1] := FLayersSet[Index2];
  FLayersSet[Index2]:=tmp;
end;

{ TRapidGraph }

procedure TRapidGraph.Clear;
var i,j:Integer;
begin
  for i := 0 to FHeight-1 do
    for j := 0 to FWidth-1 do
    begin
      FPixels[j,i].R:=255;
      FPixels[j,i].G:=255;
      FPixels[j,i].B:=255;
      FPixels[j,i].A:=128;
    end;
end;

constructor TRapidGraph.Create(Bitmap:TBitmap);
begin
  BitOut := TBitmap.Create;
  BitOut := Bitmap;
  FLayers := TLayers.Create;
  FHeight := Bitmap.Height;
  FWidth := Bitmap.Width;
  SetLength(FPixels,FWidth,FHeight);
  ReadPixels(Bitmap,FPixels,FPixPtr);
end;

procedure TRapidGraph.Free;
begin
  BitOut.Free;
  FLayers.Free;
end;

function TRapidGraph.LoadFromFile(FileName: String): Integer;
begin

end;

procedure TRapidGraph.Paint(Rect:TRect);
var i,j,m:Integer;
   lsttime : longint;
begin
  if FAlphaBlending then
    Clear;
  ReCalculatePixels(FAlphaBlending);
  for i := Rect.Top to Rect.Bottom do
  begin
    for j := Rect.Left  to Rect.Right do
    begin
      m := j*3;
      FPixPtr[i,m] := FPixels[j,i].B;
      FPixPtr[i,m+1] := FPixels[j,i].G;
      FPixPtr[i,m+2] := FPixels[j,i].R;
    end;
  end;
end;

procedure TRapidGraph.ReCalculatePixels(AlphaBlend:Boolean=True);
var k,i,j:Integer; ri,rj:Integer; alpha:LongInt	; alphaa:Longint	;
    iSt,iEn,jSt,jEn:Integer;
begin
  for k := 0 to FLayers.Count -1 do
  begin
    iSt:= FLayers.LayersSet[k].Left;
    iEn:= FLayers.LayersSet[k].Left + FLayers.LayersSet[k].Width -1;
    jSt:= FLayers.LayersSet[k].Top;
    jEn:= FLayers.LayersSet[k].Top + FLayers.LayersSet[k].Height -1;
    alphaa := FLayers.layersSet[k].Alpha;
    ri := -1;
    for i := iSt to iEn do
    begin
      inc(ri);
      if i<0 then Continue;
      if i>FWidth-1 then break;
      rj := -1;
      for j := jSt to jEn do
      begin
        inc(rj);
        if j<0 then Continue;
        if j>FHeight-1 then Break;
        if AlphaBlending and FLayers.LayersSet[k].AlphaBlending  then
        begin
          alpha := FLayers.LayersSet[k].Pixels[ri,rj].A *alphaa div 128;

          FPixels[i,j].R := FPixels[i,j].R +(FLayers.LayersSet[k].Pixels[ri,rj].R
                                       -FPixels[i,j].R)*alpha div 128;
          FPixels[i,j].G := FPixels[i,j].G +(FLayers.LayersSet[k].Pixels[ri,rj].G
                                       -FPixels[i,j].G)*alpha div 128;
          FPixels[i,j].B := FPixels[i,j].B +(FLayers.LayersSet[k].Pixels[ri,rj].B
                                       -FPixels[i,j].B)*alpha div 128;
        end
        else
        begin
          FPixels[i,j].R :=FLayers.LayersSet[k].Pixels[ri,rj].R;
          FPixels[i,j].G := FLayers.LayersSet[k].Pixels[ri,rj].G;
          FPixels[i,j].B := FLayers.LayersSet[k].Pixels[ri,rj].B;
        end;
      end;
    end;
  end;
end;

procedure TRapidGraph.SaveToBitmap(Bitmap: TBitmap);
begin

end;


function TRapidGraph.SaveToFile(FileName: String): Integer;
begin

end;

procedure TRapidGraph.Zoom(NewWidth, NewHeight: Integer);
begin

end;

end.
