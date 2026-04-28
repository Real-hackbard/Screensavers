unit untObjModel;

interface

uses Classes, SysUtils, OpenGL, GLinit, RapidUI;

type
  T3DVector = record
                X,Y,Z:Single;
              end;
  T2DVector = record
                X,Y:Single;
              end;
  TFace = record
            MaterialName:String;
            HasNormal:Boolean;
            NormalInfo:record case Integer of
                         1:(NormalIdx:array[1..3] of Integer);
                         2:(Normal:T3DVector);
                       end;
            Vertices:array[1..3] of Integer;
            TexCoords:array[1..3] of Integer;
          end;
  TMaterial = record
                Name:String;
                TextureFile:String;
                Texture:THyTexture;
                Tiling:T3DVector;
                Ambient,Diffuse,Specular:array[1..3] of Single;
              end;
  TMaterials = array of TMaterial;

  TObjModel = class(TObject)
  private
  { Private-Deklarationen}
    Vertices:array of T3DVector;
    Normals: array of T3DVector;
    TexCoords: array of T2DVector;
    Faces:array of TFace;
    Materials:TMaterials;
    FMaterialCount:Integer;
    FHasNormals: Boolean;
    FTextured: Boolean;
    FVertexCount,FFaceCount,FNormalCount,FTexCoordCount:Integer;
    Textures : array of THyTexture;
    TextureCount:Integer;
    CommingMaterialName:String;
    procedure ReadLine(Line:String);

    procedure ProcessMtl(Line:String);
    procedure ReadVertex(Line:String);
    procedure ReadNormal(Line:String);
    procedure ReadTexCoord(Line:String);
    procedure ReadFace(Line:String);
    procedure LoadMaterials(FileName:String);
    procedure ReadMTLine(Line:String);

    function GetLinePrefix(Line:String):String;
    function GetSubString(Line:String;ValueCount:Integer):String;
    function GetSingleValue(Line:String;ValueCount:Integer):Single;
    function GetIntegerValue(Line:String;ValueCount:Integer):Integer;
    function UseMaterial(Name: String):Integer;
  public
  { Public-Deklarationen}
    constructor Create;
    procedure LoadFromFile(FileName:String);
    procedure Render;
    procedure FreeModel;
    procedure Free;
    property HasNormals:Boolean read FHasNormals;
    property Textured:Boolean read FTextured;
  end;

function CalcTriangleNormal(P1,P2,P3:T3DVector):T3DVector;

implementation

function CalcTriangleNormal(P1,P2,P3:T3DVector):T3DVector;
var V1,V2:T3DVector;
function GenVector(EndPos,StartPos:T3DVector):T3DVector;
begin
  result.X := EndPos.X - StartPos.X;
  Result.Y := EndPos.Y - StartPos.Y;
  Result.Z := EndPos.Z - StartPos.Z;
end;
function VectorCross(U,V:T3DVector):T3DVector;
begin
  Result.X := U.Y*V.Z - U.Z*V.Y;
  Result.Y := U.Z*V.X - U.X*V.Z;
  Result.Z := U.X*V.y - U.Y*V.X
end;
function VectorMulLanda(Landa:Single;V:T3DVector):T3DVector;
begin
  result.X := Landa*V.X;
  Result.Y := Landa*V.Y;
  Result.Z := Landa*V.Z;
end;
function VectorLength(V:T3DVector):Single;
begin
  Result := SQRT(V.X*V.X + V.Y *V.Y + V.Z *V.Z);
end;

function Normalize(V:T3DVector):T3DVector;
begin
  Result := VectorMulLanda(1/VectorLength(V),V);
end;

begin
  V1:=GenVector(P2,P1);
  V2:=GenVector(P3,P1);
  Result := Normalize(VectorCross(v1,v2));
end;
{ TObjModel }

constructor TObjModel.Create;
begin
  FNormalCount:=0;
  FVertexCount:=0;
  FFaceCount:=0;
  FTexCoordCount:=0;
end;

procedure TObjModel.Free;
var i :Integer;
begin
  SetLength(Vertices,0);
  SetLength(Normals,0);
  SetLength(TexCoords,0);
  SetLength(Faces,0);
  for i := 0 to TextureCount-1 do
    Textures[i].Free;
end;

function TObjModel.GetIntegerValue(Line: String;
  ValueCount: Integer): Integer;
var Vs:String;
begin
  vs:=GetSubString(Line,ValueCount);
  Result := StrToInt(vs);
end;

function TObjModel.GetLinePrefix(Line: String): String;
begin
  Result := GetSubString(Line,0);
end;

function TObjModel.GetSingleValue(Line: String;
  ValueCount: Integer): Single;
var vs:String; V:Single;Code:Integer;
begin
  vs:=GetSubString(Line,ValueCount);
  Val(vs,V,code);
  if Code = 0 then
    result := V
  else
    Result:=0;
end;

function TObjModel.GetSubString(Line: String; ValueCount: Integer): String;
var fP,eP:Integer; vn:Integer;
    i:Integer;
    function WordCount(Line:String):Integer;
    var i :Integer;
    begin
      Line:=' '+Line;
      Result:=0;
      for i := 1 to Length(Line)-1 do
      begin
        if (Line[i]=' ') and (Line[i+1]<>' ') then
          Result := Result+1;
      end;
    end;
begin
  vn:=0;
  fp:=1;
  ep:=0;
  Line:=Line+' ';
  if ValueCount>0 then
  for i := 2 to Length(Line)-1 do
  begin
    if (Line[i+1]<>' ')and(Line[i] = ' ') then
      Inc(vn);
    if vn=ValueCount then
    begin
      fp := i+1;
      Break;
    end;
  end;
  if ValueCount<WordCount(Line)-1 then
    for i := fp+1 to Length(Line) do
    begin
      if Line[i] = ' ' then
      begin
        ep:=i;
        Break;
      end;
    end
  else
    ep := Length(Line);
  Result := Copy(Line,fp,ep-fp);
end;

procedure TObjModel.LoadFromFile(FileName: String);
var sl:TStringList;
    i:Integer;
begin
  sl:=TStringList.Create;
  try
    FreeModel;
    sl.LoadFromFile(FileName);
    for i := 0 to sl.Count-1 do
    begin
      ReadLine(sl.Strings[i]);
    end;
    SetLength(Vertices,FVertexCount);
    SetLength(Normals,FNormalCount);
    SetLength(TexCoords,FTexCoordCount);
    SetLength(Faces,FFaceCount);
    FHasNormals := (FNormalCount>0);
    FTextured := (TextureCount>0);
    for i := 0 to FFaceCount-1 do
    begin
      if not Faces[i].HasNormal then
      begin
        Faces[i].NormalInfo.Normal := CalcTriangleNormal(
        Vertices[Faces[i].Vertices[1]-1],Vertices[Faces[i].Vertices[2]-1],
        Vertices[Faces[i].Vertices[3]-1]);
      end;
    end;
  finally
    Sl.Free;
  end;
end;

procedure TObjModel.LoadMaterials(FileName: String);
var sl:TStringList;
    i:Integer;
begin
  sl:=TStringList.Create;
  try
    sl.LoadFromFile(FileName);
     for i := 0 to sl.Count-1 do
    begin
      ReadMTLine(sl.Strings[i]);
    end;
  finally
    Sl.Free;
  end;
end;

procedure TObjModel.ProcessMtl(Line: String);
begin
  CommingMaterialName:=GetSubString(Line,1);
end;

procedure TObjModel.ReadFace(Line: String);
var i,j:Integer; subS:String;
    vc:Integer;
    nvs:array[1..3] of String;
  function GetValueCount(S:String):Integer;
  var i:Integer;
  begin
    Result := 1;
    for i := 1 to Length(S) do
    begin
      if S[i] = '/' then
        Inc(Result);
    end;
  end;
  function GetValue(S:String;n:Integer):String;
  var i,fp:Integer;ep:Integer;sc:Integer;sp:array[1..2] of Integer;
  begin
    fp := 1;
    ep := 0;
    sc := 0;
    for i := 1 to Length(S) do
    begin
      if S[i]='/' then
      begin
        inc(SC);
        sp[sc] := i;
      end;
    end;
    if n=1 then
    begin
      Result := Copy(s,1,sp[1]-1);
    end
    else if n=2 then
    begin
      Result := Copy(s,sp[1]+1,sp[2]-sp[1]-1);
    end
    else if n= 3 then
    begin
      Result := Copy(s,sp[2]+1,Length(s)-sp[2]);
    end;
  end;
begin
  Inc(FFaceCount);
  if FFaceCount-1>High(Faces) then
    SetLength(Faces,FFaceCount+50);
  if CommingMaterialName<>'' then
  begin
    Faces[FFaceCount-1].MaterialName := CommingMaterialName;
    CommingMaterialName:='';
  end;
  for i := 1 to 3 do
  begin
    SubS:=GetSubString(Line,i);
    vc := GetValueCount(SubS);
    for j := 1 to vc do
    begin
      nvs[j]:= GetValue(SubS,j);
      if nvs[j]<>'' then
      begin
        if j= 1 then
        begin
          Faces[FFaceCount-1].Vertices[i] := StrToInt(Nvs[1]);
        end
        else
        if j=2 then
        begin
          Faces[FFaceCount-1].TexCoords[i] := StrToInt(Nvs[2]);
        end
        else
        begin
          Faces[FFaceCount-1].HasNormal :=True;
          Faces[FFaceCount-1].NormalInfo.NormalIdx[i] := StrToInt(Nvs[3]);
        end;
      end;
    end;
  end;
end;

procedure TObjModel.ReadLine(Line: String);
var fp:String;
begin
  fp:=GetLinePrefix(Line);
  if fp = 'mtllib' then
    LoadMaterials(GetSubString(Line,1))
  else
  if fp = 'v' then
    ReadVertex(Line)
  else
  if fp = 'vn' then
    ReadNormal(Line)
  else
  if fp = 'vt' then
    ReadTexCoord(Line)
  else
  if fp = 'f' then
    ReadFace(Line)
  else
  if fp = 'usemtl' then
    ProcessMtl(Line);
end;

procedure TObjModel.ReadMTLine(Line: String);
var pf:String;
begin
  pf := Lowercase(GetLinePreFix(Line));
  if pf = 'newmtl' then
  begin
    Inc(FMaterialCount);
    SetLength(Materials,FMaterialCount);
    Materials[FMaterialCount-1].Name := GetSubString(Line,1);

  end
  else if pf = 'ka' then
  begin
    Materials[FMaterialCount-1].Ambient[1] := GetSingleValue(Line,1);
    Materials[FMaterialCount-1].Ambient[2] := GetSingleValue(Line,2);
    Materials[FMaterialCount-1].Ambient[3] := GetSingleValue(Line,3);
  end
  else if pf = 'kd' then
  begin
    Materials[FMaterialCount-1].Diffuse[1] := GetSingleValue(Line,1);
    Materials[FMaterialCount-1].Diffuse[2] := GetSingleValue(Line,2);
    Materials[FMaterialCount-1].Diffuse[3] := GetSingleValue(Line,3);
  end
  else if pf = 'ks' then
  begin
    Materials[FMaterialCount-1].Specular[1] := GetSingleValue(Line,1);
    Materials[FMaterialCount-1].Specular[2] := GetSingleValue(Line,2);
    Materials[FMaterialCount-1].Specular[3] := GetSingleValue(Line,3);
  end
  else if pf = 'txt' then
  begin
    Materials[FMaterialCount-1].TextureFile := GetSubString(Line,1);
    if FileExists(Materials[FMaterialCount-1].TextureFile) then
    begin
      Inc(TextureCount);
      SetLength(Textures,TextureCount);
      Textures[TextureCount-1]:=THyTexture.Create;
      Textures[TextureCount-1].LoadFromFile(Materials[FMaterialCount-1].TextureFile);
      Materials[FMaterialCount-1].Texture := Textures[TextureCount-1];
    end
    else
      Materials[FMaterialCount-1].TextureFile := '';
  end
  else if pf = 'map_kd' then
  begin

    if GetSubString(Line,1) = '-s' then
    begin
      Materials[FMaterialCount-1].Tiling.X:= GetSingleValue(Line,2);
      Materials[FMaterialCount-1].Tiling.Y:= GetSingleValue(Line,3);
      Materials[FMaterialCount-1].Tiling.Z:= GetSingleValue(Line,4);
      ReadMTLine('txt ' + GetSubString(Line,5));
    end
    else
    begin
      Materials[FMaterialCount-1].Tiling.X:= 1;
      Materials[FMaterialCount-1].Tiling.Y:= 1;
      Materials[FMaterialCount-1].Tiling.Z:= 1;
      ReadMTLine('txt ' + GetSubString(Line,1));
    end;
  end;

end;

procedure TObjModel.ReadNormal(Line: String);
begin
  Inc(FNormalCount);
  if FNormalCount-1>High(Normals) then
    SetLength(Normals,FNormalCount+50);
  Normals[FNormalCount-1].X := GetSingleValue(Line,1);
  Normals[FNormalCount-1].Y := GetSingleValue(Line,2);
  Normals[FNormalCount-1].Z := GetSingleValue(Line,3);
end;

procedure TObjModel.ReadTexCoord(Line: String);
begin
  Inc(FTexCoordCount);
  if FTexCoordCount-1>High(TexCoords) then
    SetLength(TexCoords,FTexCoordCount+50);
  TexCoords[FTexCoordCount-1].X := GetSingleValue(Line,1);
  TexCoords[FTexCoordCount-1].Y := GetSingleValue(Line,2);
end;

procedure TObjModel.ReadVertex(Line: String);
begin
  Inc(FVertexCount);
  if FVertexCount-1>High(Vertices) then
    SetLength(Vertices,FVertexCount+50);
  Vertices[FVertexCount-1].X := GetSingleValue(Line,1);
  Vertices[FVertexCount-1].Y := GetSingleValue(Line,2);
  Vertices[FVertexCount-1].Z := GetSingleValue(Line,3);
end;

function TObjModel.UseMaterial(Name:String):Integer;
var idx,i:Integer;
begin
  for i := 0 to FMaterialCount-1 do
  begin
    if Materials[i].Name = Name then
    begin
      idx:=i;
      Result :=i;
      break;
    end;
  end;
  if Materials[idx].TextureFile <>'' then Materials[idx].Texture.Bind;
  glMaterialfv(GL_FRONT,GL_AMBIENT,@Materials[idx].Ambient);
  glMaterialfv(GL_FRONT,GL_DIFFUSE,@Materials[idx].Diffuse);
  glMaterialfv(GL_FRONT,GL_SPECULAR,@Materials[idx].Specular);
end;

procedure TObjModel.Render;
var i,j:Integer; CurMtlIdx:Integer; curMtlTiling:T3DVector;
begin
  for i := 0 to FFaceCount -1 do
  begin
    curMtlTiling.X:=1;
    curMtlTiling.Y:=1;
    curMtlTiling.Z:=1;
    if Faces[i].MaterialName <>'' then
    begin
      CurMtlIdx:=UseMaterial(Faces[i].MaterialName);
      curMtlTiling:=Materials[CurMtlIdx].Tiling;
    end;
    glBegin(GL_TRIANGLES);
      for j := 1 to 3 do
      begin

        if Faces[i].HasNormal  then
          glNormal3fv(@Normals[Faces[i].NormalInfo.NormalIdx[j]-1])
        else
          glNormal3fv(@Faces[i].NormalInfo.Normal);
        if FTextured then
          glTexCoord2d(TexCoords[Faces[i].TexCoords[j]-1].X*curMtlTiling.X,
                       TexCoords[Faces[i].TexCoords[j]-1].Y*curMtlTiling.Y);
        glVertex3fv(@Vertices[Faces[i].Vertices[j]-1]);
      end;
    glEnd;
  end;
end;

procedure TObjModel.FreeModel;
var i : Integer;
begin
  for i := 0 to TextureCount-1 do
  begin
    Textures[i].Free;
  end;
  FNormalCount:=0;
  FVertexCount:=0;
  FFaceCount:=0;
  TextureCount:=0;
  FTexCoordCount:=0;
  FMaterialCount:=0;
  SetLength(Normals,FNormalCount);
  SetLength(Vertices,FVertexCount);
  SetLength(Faces,FFaceCount);
  SetLength(TexCoords,FTexCoordCount);
  SetLength(Materials,FMaterialCount);
  SetLength(Textures,TextureCount);
end;

end.
