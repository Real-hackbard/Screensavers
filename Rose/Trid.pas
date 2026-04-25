unit Trid;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, OpenGL, utils, StdCtrls, ExtCtrls, Grids, ComCtrls, ExtDlgs;

type
  TVect=record
    x,y,z:GlFloat;
  end;

  TRepere=record
    p,x,y,z:TVect;
  end;

  TVertex=record
    p,n,c:TVect;
  end;

function Vect(x,y,z:GlFloat):TVect;
function Seuil(x,r:GlFloat):GlFloat;
function Scale(u:TVect;r:GlFloat):TVect;
function Add(u,v:TVect):TVect;
function Sub(u,v:TVect):TVect;
function Norm(u:TVect):GlFloat;
function UnitV(v:TVect):TVect;
function Dotp(u,v:TVect):GlFloat;
function Crossp(u,v:TVect):TVect;
function Repere(v,p,x,y,z:TVect):TVect;
function MakeRepere(p,x,y,z:TVect):TRepere;

implementation

function Vect(x,y,z:GlFloat):TVect;
begin
  Result.x:=x;
  Result.y:=y;
  Result.z:=z;
end;

function Seuil(x,r:GlFloat):GlFloat;
begin
  if x>r then
    Result:=x-r
  else
    Result:=0;
end;

function Scale(u:TVect;r:GlFloat):TVect;
begin
  Result.x:=r*u.x;
  Result.y:=r*u.y;
  Result.z:=r*u.z;
end;

function Add(u,v:TVect):TVect;
begin
  Result.x:=u.x+v.x;
  Result.y:=u.y+v.y;
  Result.z:=u.z+v.z;
end;

function Sub(u,v:TVect):TVect;
begin
  Result.x:=u.x-v.x;
  Result.y:=u.y-v.y;
  Result.z:=u.z-v.z;
end;

function Norm(u:TVect):GlFloat;
begin
  Result:=sqrt(sqr(u.x)+sqr(u.y)+sqr(u.z));
end;

function UnitV(v:TVect):TVect;
begin
  Result:=Scale(v,1/(1E-6+Norm(v)));
end;

function Dotp(u,v:TVect):GlFloat;
begin
  Result:=u.x*v.x+u.y*v.y+u.z*v.z;
end;

function Crossp(u,v:TVect):TVect;
begin
  Result.x:=u.y*v.z-u.z*v.y;
  Result.y:=u.z*v.x-u.x*v.z;
  Result.z:=u.x*v.y-u.y*v.x;
end;

function Repere(v,p,x,y,z:TVect):TVect;
begin
  Result:=Add(Add(p,Scale(x,v.x)),Add(Scale(y,v.y),Scale(z,v.z)));
end;

function MakeRepere(p,x,y,z:TVect):TRepere;
begin
  Result.p:=p;
  Result.x:=x;
  Result.y:=y;
  Result.z:=z;
end;

end.
