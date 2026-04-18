unit Vectors;

interface

type
  TVector = array[0..2] of Single;

{ Find the cross product of two vectors }
function vtrCross(V1, V2: TVector): TVector;
{ Subtracts V2 from V1 }
function vtrSubtract(V1, V2: TVector): TVector;
{ Normalizes a vector }
function vtrNormalize(V: TVector): TVector;

implementation

function vtrSubtract(V1, V2: TVector): TVector;
begin
  Result[0] := V1[0] - V2[0];
  Result[1] := V1[1] - V2[1];
  Result[2] := V1[2] - V2[2];
end;

function vtrLength(V: TVector): Single;
begin
  Result := Sqrt(Sqr(V[0]) + Sqr(V[1]) + Sqr(V[2]));
end;

function vtrCross(V1, V2: TVector): TVector;
begin
  Result[0] := V1[1] * V2[2] - V1[2] * V2[1];
  Result[1] := V1[2] * V2[0] - V1[0] * V2[2];
  Result[2] := V1[0] * V2[1] - V1[1] * V2[0];
end;

function vtrNormalize(V: TVector): TVector;
var
  Len: Single;
begin
  Len := vtrLength(V);
  if (Len <> 0.0) then begin
    Result[0] := V[0] / Len;
    Result[1] := V[1] / Len;
    Result[2] := V[2] / Len;
  end else
    Result := V;
end;

end.
