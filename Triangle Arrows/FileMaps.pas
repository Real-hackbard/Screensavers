unit FileMaps;

interface

uses
 windows,sysutils;

Type
 TFileMapping=class
 private
  fFile:integer;
  fMap :integer;
  fBase:pointer;
  fSize:Cardinal;
 public
  Constructor Create(AFileName:string);
  Destructor Destroy; override;
  function data(index:Cardinal):pointer;
  property Base:pointer read fBase;
  property Size:Cardinal read fSize;
 end;

implementation

Constructor TFileMapping.Create(AFileName:string);
 begin
  fFile:=CreateFile(PChar(AFileName),GENERIC_READ,FILE_SHARE_READ,nil,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0);
  if fFile=0 then raise Exception.Create('Unable to open '+AFileName);
  fSize:=GetFileSize(fFile,nil);
  if fSize=0 then raise Exception.Create('Empty file '+AFileName);
  fMap :=CreateFileMapping(fFile,nil,PAGE_READONLY,0,0,nil);
  if fMap=0 then raise Exception.Create('Can''t map file '+AFileName);
  fBase:=MapViewOfFile(fMap,FILE_MAP_READ,0,0,0);
  if fBase=nil then raise Exception.Create('Can''t view file '+AFileName);
 end;

Destructor TFileMapping.Destroy;
 begin
  UnMapViewOfFile(fBase);
  CloseHandle(fMap);
  CloseHandle(fFile);
  inherited Destroy;
 end;

function TFileMapping.Data(index:Cardinal):pointer;
 begin
  if {(index<0)or}(index>fSize) then raise Exception.Create('Out of bounds pointer !');
  result:=pointer({integer}cardinal(fBase)+index);
 end;

end.
