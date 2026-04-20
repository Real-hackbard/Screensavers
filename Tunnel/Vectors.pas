unit Vectors;

interface

type
  TVector = array[0..2] of Single;

{ Initialize a vector }
function vtr(X, Y, Z: Single): TVector;
{ Find the length of a vector }
function vtrLength(V: TVector): Single;
{ Multiply a vector by a scalar }
function vtrMult(V: TVector; S: Single): TVector;
{ Find the dot product of two vectors }
function vtrDot(V1, V2: TVector): Single;
{ Find the projection (shadow) of V1 on V2 }
function vtrProjection(V1, V2: TVector): Single;
{ Find the cross product of two vectors }
function vtrCross(V1, V2: TVector): TVector;
{ Add two vectors }
function vtrAdd(V1, V2: TVector): TVector;
{ Subtracts V2 from V1 }
function vtrSubtract(V1, V2: TVector): TVector;
{ Normalizes a vector }
function vtrNormalize(V: TVector): TVector;

implementation

function vtr(X, Y, Z: Single): TVector;
begin
  Result[0] := X;
  Result[1] := Y;
  Result[2] := Z;
end;

function vtrAdd(V1, V2: TVector): TVector;
begin
  Result[0] := V1[0] + V2[0];
  Result[1] := V1[1] + V2[1];
  Result[2] := V1[2] + V2[2];
end;

function vtrSubtract(V1, V2: TVector): TVector;
begin
  Result[0] := V1[0] - V2[0];
  Result[1] := V1[1] - V2[1];
  Result[2] := V1[2] - V2[2];
end;

function vtrMult(V: TVector; S: Single): TVector;
begin
  Result[0] := V[0] * S;
  Result[1] := V[1] * S;
  Result[2] := V[2] * S;
end;

function vtrLength(V: TVector): Single;
begin
  Result := Sqrt(Sqr(V[0]) + Sqr(V[1]) + Sqr(V[2]));
end;

function vtrDot(V1, V2: TVector): Single;
begin
  Result := V1[0] * V2[0] + V1[1] * V2[1] + V1[2] * V2[2];
end;

function vtrProjection(V1, V2: TVector): Single;
begin
  Result := vtrDot(V1, V2) / vtrDot(V2, V2);
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
