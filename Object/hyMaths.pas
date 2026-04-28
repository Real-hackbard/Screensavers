unit hyMaths;

interface

uses
  SysUtils;

type
  T3DVector = record
                 X,Y,Z:Single;
              end;
  T3DPoint = record
                X,Y,Z:Single;
              end;
  T4DArray = array [0..3] of Single;
  T3DLine = record
              Direction : T3DVector;
              Point: T3DVector;
             end;
  T3DTriangle = record
                  V0,V1,V2:T3DVector;
                end;
  TIsect=Record
            u,v,t:Single;
         end;

function FixNumber(Number:Double):Integer;
function DegToArc(Deg:Single):Single;

////////////////// Distances /////////////////
function Point3DDistance(P1,P2:T3DVector):Double;

///////////===== Vectors======/////////
function Normalize(V:T3DVector):T3DVector;
function VectorDot(V1,V2:T3DVector):Single;
function VectorCross(U,V:T3DVector):T3DVector;
function VectorLength(V:T3DVector):Single;
function VectorMulLanda(Landa:Single;V:T3DVector):T3DVector;
function VectorDiv(V:T3DVector;Landa:Single):T3DVector;
function VectorPlus(V1,V2:T3DVector):T3DVector;
function VectorMinus(V1,V2:T3DVector):T3DVector;
function GenVector(EndPos,StartPos:T3DVector):T3DVector;
function CreateVector(X,Y,Z:Single):T3DVector;
function Gen4DArray(V1,V2,V3,V4:Single):T4DArray;
function CalcTriangleNormal(P1,P2,P3:T3DVector):T3DVector;

function LineTriangleInsect(Tri:T3DTriangle;Line:T3DLine;var Info:TIsect;
  epsilon:Single;var Intersection:T3DVector):Boolean;
implementation

function VectorDiv(V:T3DVector;Landa:Single):T3DVector;
begin
  Result.X := V.X/Landa;
  Result.Y := V.Y/Landa;
  Result.Z := V.Z/Landa;
end;

function DegToArc(Deg:Single):Single;
begin
  Result := Deg/180*PI;
end;

function Point3DDistance(P1,P2:T3DVector):Double;
begin
  Result := SQRT(SQR(P2.X-P1.X)+SQR(P2.Y-P1.Y)+SQR(P2.Z-P1.Z));
end;

function FixNumber(Number:Double):Integer;
var rndRs:Integer;
begin
  rndRs:=Round(Number);
  if rndRs<Number then
    result := rndRs+1
  else
    result := RndRs;
end;

function VectorDot(V1,V2:T3DVector):Single;
begin
  result:= V1.X * V2.X + V1.Y *V2.Y + V1.Z * V2.Z;
end;

function VectorPlus(V1,V2:T3DVector):T3DVector;
begin
  result.X := v1.X + v2.X;
  result.Y := v1.Y + v2.Y;
  result.Z := v1.Z + v2.Z;
end;

function VectorMinus(V1,V2:T3DVector):T3DVector;
begin
  result.X := v1.X - v2.X;
  result.Y := v1.Y - v2.Y;
  result.Z := v1.Z - v2.Z;
end;

function GenVector(EndPos,StartPos:T3DVector):T3DVector;
begin
  result.X := EndPos.X - StartPos.X;
  Result.Y := EndPos.Y - StartPos.Y;
  Result.Z := EndPos.Z - StartPos.Z;
end;

function CreateVector(X,Y,Z:Single):T3DVector;
begin
  Result.X :=x;
  Result.Y :=Y;
  Result.Z :=Z;
end;
function VectorMulLanda(Landa:Single;V:T3DVector):T3DVector;
begin
  result.X := Landa*V.X;
  Result.Y := Landa*V.Y;
  Result.Z := Landa*V.Z;
end;

function Gen4DArray(V1,V2,V3,V4:Single):T4DArray;
begin
  Result[0] := V1;
  Result[1] := V2;
  Result[2] := V3;
  Result[3] := V4;
end;

function VectorCross(U,V:T3DVector):T3DVector;
begin
  Result.X := U.Y*V.Z - U.Z*V.Y;
  Result.Y := U.Z*V.X - U.X*V.Z;
  Result.Z := U.X*V.y - U.Y*V.X
end;

function Normalize(V:T3DVector):T3DVector;
begin
  Result := VectorMulLanda(1/VectorLength(V),V);
end;

function VectorLength(V:T3DVector):Single;
begin
  Result := SQRT(V.X*V.X + V.Y *V.Y + V.Z *V.Z);
end;

function CalcTriangleNormal(P1,P2,P3:T3DVector):T3DVector;
var
  V1,V2:T3DVector;
begin
  V1:=GenVector(P2,P1);
  V2:=GenVector(P3,P1);
  Result := Normalize(VectorCross(v1,v2));
end;

function LineTriangleInsect(Tri:T3DTriangle;Line:T3DLine;var Info:TIsect;
  epsilon:Single;var Intersection:T3DVector):Boolean;
var
  e1,e2,p,s,q:T3DVector;
  t,u,v,tmp:Single;
begin
  e1 := GenVector(Tri.V1,Tri.V0);
  e2 := GenVector(Tri.V2,Tri.V0);
  p := VectorCross(Line.Direction,e2);
  tmp := VectorDot(p,e1);

  if (tmp>-epsilon) and (tmp<epsilon) then
  begin
    result := False;
    exit;
  end;

  tmp := 1/tmp;
  s := VectorMinus(Line.Point,Tri.V0);
  u:= tmp*VectorDot(s,p);
  if (u<0)or(u>1) then
  begin
    result := False;
    exit;
  end;
  q := VectorCross(s,e1);
  v := tmp*VectorDot(Normalize(Line.Direction),q);
  if (v<0) or (v>1) then
  begin
    result := False;
    exit;
  end;

  t := tmp*vectordot(e2,q);
  info.u := u;
  info.v := v;
  info.t := t;
  Intersection := VectorPlus(Line.Point,VectorMulLanda(t,Line.Direction));
  Result:=True;
end;
end.
