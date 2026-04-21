unit GLTypes;

{ (c)2003, by Paul TOTH <tothpaul@free.fr> }

{
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
}

interface

uses
 DelphiGL;

type
 TVector=packed record
  x,y,z:single;
 end;

 TRotation=packed record
  a,x,y,z:single;
 end;

 TQuaternion=packed record
  x,y,z,w:single;
 end;

 TMatrix=array[0..15] of single;

 TVector3f=TVector;
 TVector4f=TQuaternion;

 TColor4f=record
  Red,Green,Blue,Alpha:single;
 end;

procedure AddVectors(var v:TVector; const v1:TVector);
procedure BlendVector(var v:TVector; Factor:single; const v1:TVector);
procedure RotateVector(var v:TVector; const q:TQuaternion);

procedure BlendQuaternion(var q:TQuaternion; Factor:single; q1:TQuaternion);
procedure QuaternionDotQuaternion(var q:TQuaternion; const q1:TQuaternion);
procedure QuaternionDotVector(var q:TQuaternion; const v:TVector);

procedure QuaternionToMatrix(const q:TQuaternion; var M:TMatrix);
procedure QuaternionToRotation(const q:TQuaternion; var R:TRotation);
procedure RotationToQuaternion(const r:TRotation; var q:TQuaternion);
procedure MatrixToRotation(const m:TMatrix; var R:TRotation);
function MatrixTranslation(const m:TMatrix):TVector;

function Transform(const v:TVector; const m:TMatrix):TVector;
function RotateOnly(const v:TVector; const m:TMatrix):TVector;
procedure GetRotateMatrix(const m1:TMatrix; var m2:TMatrix);

procedure glQuaternion(const q:TQuaternion);

function CrossProduct(const v1,v2:TVector):TVector;
function DotProduct(const v1,v2:TVector):single;
function VectorLength(const v:TVector):single;
procedure Normalize(var v:TVector);

function SqrDistance(const v1,v2:TVector3f):double;
function Distance(const v1,v2:TVector3f):single;

procedure inc3f(var v1:TVector3f; const v2:TVector3f);
procedure dec3f(var v1:TVector3f; const v2:TVector3f);
function  add3f(const v1,v2:TVector3f):TVector3f;
function  sub3f(const v1,v2:TVector3f):TVector3f;
function  mul3f(const v:TVector3f; factor:single):TVector3f;
procedure scale3f(var v:TVector3f; factor:single);

procedure inc4f(var v1:TVector4f; const v2:TVector4f);
function  sub4f(const v1,v2:TVector4f):TVector4f;
function  mul4f(const v:TVector4f; factor:single):TVector4f;

implementation

//uses
// Math;

function ArcTan2(const Y, X: Extended): Extended;
asm
        FLD     Y
        FLD     X
        FPATAN
        FWAIT
end;

function ArcCos(const X: Extended): Extended;
begin
  Result := ArcTan2(Sqrt(1 - X * X), X);
end;


procedure inc3f(var v1:TVector3f; const v2:TVector3f);
begin
 v1.x:=v1.x+v2.x;
 v1.y:=v1.y+v2.y;
 v1.z:=v1.z+v2.z;
end;

procedure dec3f(var v1:TVector3f; const v2:TVector3f);
begin
 v1.x:=v1.x-v2.x;
 v1.y:=v1.y-v2.y;
 v1.z:=v1.z-v2.z;
end;

function  add3f(const v1,v2:TVector3f):TVector3f;
begin
 Result.x:=v1.x+v2.x;
 Result.y:=v1.y+v2.y;
 Result.z:=v1.z+v2.z;
end;

function  sub3f(const v1,v2:TVector3f):TVector3f;
begin
 Result.x:=v1.x-v2.x;
 Result.y:=v1.y-v2.y;
 Result.z:=v1.z-v2.z;
end;

function  mul3f(const v:TVector3f; factor:single):TVector3f;
begin
 Result.x:=v.x*factor;
 Result.y:=v.y*factor;
 Result.z:=v.z*factor;
end;

procedure scale3f(var v:TVector3f; factor:single);
begin
 v.x:=v.x*factor;
 v.y:=v.y*factor;
 v.z:=v.z*factor;
end;

procedure inc4f(var v1:TVector4f; const v2:TVector4f);
begin
 v1.x:=v1.x+v2.x;
 v1.y:=v1.y+v2.y;
 v1.z:=v1.z+v2.z;
 v1.w:=v1.w+v2.w;
end;

function  sub4f(const v1,v2:TVector4f):TVector4f;
begin
 Result.x:=v1.x-v2.x;
 Result.y:=v1.y-v2.y;
 Result.z:=v1.z-v2.z;
 Result.w:=v1.w-v2.w;
end;

function  mul4f(const v:TVector4f; factor:single):TVector4f;
begin
 Result.x:=v.x*factor;
 Result.y:=v.y*factor;
 Result.z:=v.z*factor;
 Result.w:=v.w*factor;
end;

procedure AddVectors(var V:TVector; const V1:TVector);
begin
 v.x:=v.x+v1.x;
 v.y:=v.y+v1.y;
 v.z:=v.z+v1.z;
end;

procedure BlendVector(var v:TVector; Factor:single; const v1:TVector);
begin
 v.x:= v.x + Factor * (v1.x - v.x);
 v.y:= v.y + Factor * (v1.y - v.y);
 v.z:= v.z + Factor * (v1.z - v.z);
end;

procedure RotateVector(var v:TVector; const q:TQuaternion);
var
 q2:TQuaternion;
begin
 q2.x:=-q.x;
 q2.y:=-q.y;
 q2.z:=-q.z;
 q2.w:=+q.w;
 QuaternionDotVector(q2,v);
 QuaternionDotQuaternion(q2,q);
 v.x:=q2.x;
 v.y:=q2.y;
 v.z:=q2.z;
end;

procedure BlendQuaternion(var q:TQuaternion; Factor:single; q1:TQuaternion);
var
 Norm:single;
 Flip:boolean;
 InvFactor:Single;
 Theta:Single;
 Scale:Single;
begin
 Norm:=q.x * q1.x + q.y * q1.y + q.z * q1.z + q.w * q1.w;
 Flip:=(Norm < 0.0);
 if Flip then Norm:=-Norm;
 if (1.0 - Norm < 0.000001) then begin
  InvFactor:=1.0 - Factor;
 end else begin
  Theta:=ArcCos(Norm);
  Scale:=1.0/sin(Theta);
  InvFactor:=sin((1.0 - Factor) * Theta) * Scale;
  Factor:=sin(Factor * Theta) * Scale;
 end;
 if (Flip) then Factor:=-Factor;
 q.x:= InvFactor * q.x + Factor * q1.x;
 q.y:= InvFactor * q.y + Factor * q1.y;
 q.z:= InvFactor * q.z + Factor * q1.z;
 q.w:= InvFactor * q.w + Factor * q1.w;
end;

procedure QuaternionDotQuaternion(var q:TQuaternion; const q1:TQuaternion);
var
 x,y,z,w:Single;
begin
 x:=q.x;
 y:=q.y;
 z:=q.z;
 w:=q.w;

 q.x:= w * q1.x + x * q1.w + y * q1.z - z * q1.y;
 q.y:= w * q1.y - x * q1.z + y * q1.w + z * q1.x;
 q.z:= w * q1.z + x * q1.y - y * q1.x + z * q1.w;
 q.w:= w * q1.w - x * q1.x - y * q1.y - z * q1.z;
end;

procedure QuaternionDotVector(var q:TQuaternion; const v:TVector);
var
 x,y,z,w:Single;
begin
 x:=q.x;
 y:=q.y;
 z:=q.z;
 w:=q.w;

 q.x:= w * v.x           + y * v.z - z * v.y;
 q.y:= w * v.y - x * v.z           + z * v.x;
 q.z:= w * v.z + x * v.y - y * v.x;
 q.w:=         - x * v.x - y * v.y - z * v.z;
end;

procedure QuaternionToMatrix(const q:TQuaternion; var M:TMatrix);
var
 xx,yy,zz,zw:single;
 xy,yz,yw   :single;
 xz,xw      :single;
begin
 xx:=q.x*q.x; xy:=q.x*q.y; xz:=q.x*q.z; xw:=q.x*q.w;
 yy:=q.y*q.y; yz:=q.y*q.z; yw:=q.y*q.w;
 zz:=q.z*q.z; zw:=q.z*q.w;

 m[00]:=1-2*(yy+zz);
 m[01]:=  2*(xy+zw);
 m[02]:=  2*(xz-yw);
 m[03]:=  0;

 m[04]:=  2*(xy-zw);
 m[05]:=1-2*(xx+zz);
 m[06]:=  2*(yz+xw);
 m[07]:=  0;

 m[08]:=  2*(xz+yw);
 m[09]:=  2*(yz-xw);
 m[10]:=1-2*(xx+yy);
 m[11]:=  0;

 m[12]:=  0;
 m[13]:=  0;
 m[14]:=  0;
 m[15]:=  1;
end;

procedure QuaternionToRotation(const q:TQuaternion; var R:TRotation);
var
 Scale:single;
begin
 Scale:=1/(q.x*q.x+q.y*q.y+q.z*q.z);
 r.a:=2*ArcCos(q.w);
 r.x:=q.x*Scale;
 r.y:=q.y*Scale;
 r.z:=q.z*Scale;
end;

procedure RotationToQuaternion(const r:TRotation; var q:TQuaternion);
var
 s,c:Extended;
begin
 SinCos(r.a/2,s,c);
 q.x:=s*r.x;
 q.y:=s*r.y;
 q.z:=s*r.z;
 q.w:=c;
end;

procedure MatrixToRotation(const m:TMatrix; var R:TRotation);
var
 d:single;
begin
 R.a:=arccos((m[00] + m[05] + m[10] - 1)/2);
 d:=sqrt(sqr(m[09] - m[06])+sqr(m[02] - m[08])+sqr(m[04] - m[01]));
 R.x:=(m[09] - m[06])/d;
 R.y:=(m[02] - m[08])/d;
 R.z:=(m[04] - m[01])/d;
end;

function MatrixTranslation(const m:TMatrix):TVector;
begin
 Result.x:=m[12];
 Result.y:=m[13];
 Result.z:=m[14];
end;

function Transform(const v:TVector; const m:TMatrix):TVector;
begin
 Result.x:=v.x*m[0]+v.y*m[4]+v.z*m[ 8]+m[12];
 Result.y:=v.x*m[1]+v.y*m[5]+v.z*m[ 9]+m[13];
 Result.z:=v.x*m[2]+v.y*m[6]+v.z*m[10]+m[14];
end;

function RotateOnly(const v:TVector; const m:TMatrix):TVector;
begin
 Result.x:=v.x*m[0]+v.y*m[4]+v.z*m[ 8];
 Result.y:=v.x*m[1]+v.y*m[5]+v.z*m[ 9];
 Result.z:=v.x*m[2]+v.y*m[6]+v.z*m[10];
end;

procedure GetRotateMatrix(const m1:TMatrix; var m2:TMatrix);
begin
 m2:=m1;
 m2[12]:=0;
 m2[13]:=0;
 m2[14]:=0;
end;

procedure glQuaternion(const q:TQuaternion);
var
 tw,scale:single;
begin
 tw:=2*ArcCos(q.w);
 scale:=1/(q.x*q.x+q.y*q.y+q.z*q.z);
 glRotatef(tw*180/PI,q.x*scale,q.y*scale,q.z*scale);
end;

function CrossProduct(const v1,v2:TVector):TVector;
begin
 Result.X := v1.X*v2.Z - v1.Z*v2.Y;
 Result.Y := v1.Z*v2.X - v1.X*v2.Z;
 Result.Z := v1.X*v2.Y - v1.Y*v2.X;
end;

function DotProduct(const v1,v2:TVector):single;
begin
 Result:=(v1.X*v2.X) + (v1.Y*v2.Y) + (v1.Z*v2.Z);
end;

function VectorLength(const v:TVector):single;
begin
 Result:=sqrt(v.x*v.x+v.y*v.y+v.z*v.z);
end;

procedure Normalize(var v:TVector);
var
 len:single;
begin
 len:=VectorLength(v);
 if len>0 then len:=1/len;
 v.x:=v.x*len;
 v.y:=v.y*len;
 v.z:=v.z*len;
end;

function SqrDistance(const v1,v2:TVector3f):double;
var
 dx,dy,dz:double;
begin
 dx:=v1.x-v2.x;
 dy:=v1.y-v2.y;
 dz:=v1.z-v2.z;
 result:=(dx*dx)+(dy*dy)+(dz*dz);
end;

function Distance(const v1,v2:TVector3f):single;
begin
 Result:=sqrt(SqrDistance(v1,v2));
end;

end.

