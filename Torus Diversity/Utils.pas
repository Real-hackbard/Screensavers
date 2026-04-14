unit Utils;

interface

uses Graphics;  // tColor defined in Graphics

const
  FULL_CIRCLE = 360;
  HALF_CIRCLE = 180;
//  TEN_CIRCLES = 3600;

  A_BYTE = 256;
  TWO_BYTES = A_BYTE * A_BYTE;

type
  tColourRec = record
                 R,G,B:byte;
               end;

function RandomColour:tColor;
function SlideColours(FromColour,ToColour:tColor):tColor;
function RGBToColour(R,G,B:Byte):TColor;
function RGBvalues(C:tColor):tColourRec;
function MySin(x:integer):real; overload;
function MySin(x:real):real; overload; //  allow both reals or integers
function MyCos(x:integer):real; overload;
function MyCos(x:real):real; overload;  //  allow both reals or integers

implementation
const
  MULTIPLIER = 10;
  NUM_ELEMENTS = FULL_CIRCLE * MULTIPLIER;
type
   tArcAnswers = array[0..NUM_ELEMENTS] of real;
var
   SinResults,
   CosResults:tArcAnswers;

function MixColours(CR:tColourRec):tColor;
begin
 with CR do
   Result := RGBToColour(R,G,B);
end;

function RandomColour:tColor;
var
  I:integer;
  CR:tColourRec;
begin
  I := round(int(random * 3) + 1);
  with CR do
    begin
    R := round(int(Random * 256));
    G := round(int(Random * 256));
    B := round(int(Random * 256));

    if ( random < 0.5 ) then
    begin
       case I of
          1: R := round(int(Random * 200)) + 53;
          2: G := round(int(Random * 200)) + 53;
          3: B := round(int(Random * 200)) + 53;
       end;
    end;
  end; {  with }
  RandomColour := MixColours(CR);
end;

function RGBDiff(F,T:byte):Integer;
var
  B:integer;
begin
  B := 0;
  if F < T then
    B := 1;
  if F > T then
    B := -1;
  RGBDiff := B;
end;

function SlideColours(FromColour,ToColour:tColor):tColor;
// ---------------------------------------------------------------
// moves each colour (R,G,B) one byte from one colour to the other
// ---------------------------------------------------------------
var
  EndCol,
  FrCol,
  ToCol:tColourRec;
  Change:Integer;
begin
  FrCol := RGBValues(FromColour);
  ToCol := rgbValues(ToColour);
  Change := RGBDiff(FrCol.R,ToCol.R);
  EndCol.R := FrCol.R + Change;
  Change := RGBDiff(FrCol.B,ToCol.B);
  EndCol.B := FrCol.B + Change;
  Change := RGBDiff(FrCol.G,ToCol.G);
  EndCol.G := FrCol.G + Change;
  SlideColours := MixColours(EndCol);
end;

function RGBToColour(R,G,B:Byte):TColor;
begin
  Result := B Shl 16 or
            G Shl  8 or
            R;
end;

function RGBvalues(C:tColor):tColourRec;
var
  CR:tColourRec;
  RedVal,
  BlueVal,
  GreenVal:byte;
  L:longInt;
begin
  L := C;
  BlueVal := L div TWO_BYTES;
  RedVal := L mod TWO_BYTES;
  GreenVal := ( L div A_BYTE ) mod A_BYTE ;
  CR.R := RedVal;
  CR.B := BlueVal;
  CR.G := GreenVal;
  RGBValues := CR;
end;

function GradToDeg(x:real):real;
begin
  result := x * 2 * pi / FULL_CIRCLE;
end;

procedure InitArcAnswers;
var
  c:integer;
begin
  for c := 0 to NUM_ELEMENTS do
  begin
    SinResults[c] := sin(GradToDeg(c / MULTIPLIER));
    CosResults[c] := cos(GradToDeg(c / MULTIPLIER));
  end;
end;

function MySin(x:integer):real; overload;
begin
  while ( x > FULL_CIRCLE ) do
      x := x - FULL_CIRCLE;
  while ( x < 0 ) do
      x := x + FULL_CIRCLE;

  Result := SinResults[x * MULTIPLIER];
end;

function MySin(x:real):real; overload;
begin
  while ( x > FULL_CIRCLE ) do
      x := x - FULL_CIRCLE;
  while ( x < 0 ) do
      x := x + FULL_CIRCLE;
  Result := SinResults[round(x * MULTIPLIER)];
end;

function MyCos(x:integer):real; overload;
begin
  while ( x > FULL_CIRCLE ) do
      x := x - FULL_CIRCLE;
  while ( x < 0 ) do
      x := x + FULL_CIRCLE;
  Result := CosResults[x * MULTIPLIER];
end;

function MyCos(x:real):real; overload;
begin
  while ( x > FULL_CIRCLE ) do
      x := x - FULL_CIRCLE;
  while ( x < 0 ) do
      x := x + FULL_CIRCLE;
  Result := CosResults[round(x * MULTIPLIER)];
end;

{ ===================================================== }
initialization
begin
  InitArcAnswers;
end;


end.
