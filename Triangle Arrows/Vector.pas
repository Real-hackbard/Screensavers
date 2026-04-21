unit Vector;

interface

uses
    Classes;

const
     FloatError = 0.001;

type
  TVector = class(TPersistent)
  { Purpose: To encapsulate a vector }
  private
    { Private declarations }
    FX: Single;
    FY: Single;
    FZ: Single;
  protected
    { Protected declarations }
    procedure SetX(const Value: Single); virtual;
    procedure SetY(const Value: Single); virtual;
    procedure SetZ(const Value: Single); virtual;
    procedure Change; virtual;
  public
    { Public declarations }
    constructor Create; overload; virtual;
    constructor Create( const X, Y, Z: Single ); overload;
    constructor Create( const Vector: TVector ); overload;
    procedure Assign(Source: TPersistent); override;
    procedure Add( const Vector: TVector ); overload;
    procedure Add( const Value: Single ); overload;
    procedure Clear; virtual;
    procedure CrossProduct( const Vector: TVector ); overload;
    procedure CrossProduct( const X, Y, Z: Single ); overload;
    procedure Divide( const Vector: TVector ); overload;
    procedure Divide( const Value: Single ); overload;
    function DotProduct( const Vector: TVector ): Single; overload;
    function DotProduct( const X, Y, Z: Single ): Single; overload;
    function DistanceTo( const Vector: TVector ): Single; overload;
    function DistanceTo( const X, Y, Z: Single ): Single; overload;
    function DistanceSqrTo( const Vector: TVector ): Double; overload;
    function DistanceSqrTo( const X, Y, Z: Single ): Double; overload;
    function Equals( const Vector: TVector ): Boolean; overload;
    function Equals( const X, Y, Z: Single ): Boolean; overload;
    function EqualsStar( const Vector: TVector ): Boolean; overload;
    function EqualsStar( const X, Y, Z: Single ): Boolean; overload;
    procedure Multiply( const Vector: TVector ); overload;
    procedure Multiply( const Value: Single ); overload;
    procedure Normalize;
    function Length: Single;
    procedure SetMagnitudeOfVector( const Velocity: Single );
    procedure SetXYZ( const X, Y, Z: Single );
    procedure Subtract( const Vector: TVector ); overload;
    procedure Subtract( const Value: Single ); overload;
  published
    { Published declarations }
    property X: Single read FX write SetX;
    property Y: Single read FY write SetY;
    property Z: Single read FZ write SetZ;
  end; { TVector }

implementation

{ TVector }

procedure TVector.Add(const Vector: TVector);
begin
     FX := FX + Vector.X;
     FY := FY + Vector.Y;
     FZ := FZ + Vector.Z;
     Change;
end;

procedure TVector.Add(const Value: Single);
begin
     FX := FX + Value;
     FY := FY + Value;
     FZ := FZ + Value;
     Change;
end;

procedure TVector.Assign(Source: TPersistent);
begin
     if Source is TVector then
     begin
          FX := TVector(Source).X;
          FY := TVector(Source).Y;
          FZ := TVector(Source).Z;
          Change;
          Exit;
     end;
     inherited;
end;

procedure TVector.Clear;
begin
     FX := 0;
     FY := 0;
     FZ := 0;
     Change;
end;

constructor TVector.Create(const Vector: TVector);
begin
     inherited Create;
     FX := Vector.X;
     FY := Vector.Y;
     FZ := Vector.Z;
end;

constructor TVector.Create(const X, Y, Z: Single);
begin
     inherited Create;
     FX := X;
     FY := Y;
     FZ := Z;
end;

constructor TVector.Create;
begin
     inherited Create;
end;

procedure TVector.CrossProduct(const Vector: TVector);
var
   tempX, tempY, tempZ: Single;
begin
     tempX := X * Vector.Z - Z*Vector.Y;
     tempY := Z * Vector.X - X*Vector.Z;
     tempZ := X * Vector.Y - Y*Vector.X;
     SetXYZ( tempX, tempY, tempZ );
end;

procedure TVector.CrossProduct(const X, Y, Z: Single);
var
   tempX, tempY, tempZ: Single;
begin
     tempX := FX * Z - FZ*Y;
     tempY := FZ * X - FX*Z;
     tempZ := FX * Y - FY*X;
     SetXYZ( tempX, tempY, tempZ );
end;

function TVector.DistanceTo(const Vector: TVector): Single;
begin
     result := Sqrt( Sqr(X-Vector.X) +
                     Sqr(Y-Vector.Y) +
                     Sqr(Z-Vector.Z) );
end;

function TVector.DistanceSqrTo(const Vector: TVector): Double;
begin
     result := Sqr(X-Vector.X) +
               Sqr(Y-Vector.Y) +
               Sqr(Z-Vector.Z);
end;

function TVector.DistanceSqrTo(const X, Y, Z: Single): Double;
begin
     result := Sqr(FX-X) +
               Sqr(FY-Y) +
               Sqr(FZ-Z);
end;

function TVector.DistanceTo(const X, Y, Z: Single): Single;
begin
     result := Sqrt( Sqr(FX-X) +
                     Sqr(FY-Y) +
                     Sqr(FZ-Z) );
end;

procedure TVector.Divide(const Vector: TVector);
begin
     FX := X / Vector.X;
     FY := Y / Vector.Y;
     FZ := Z / Vector.Z;
     Change;
end;

procedure TVector.Divide(const Value: Single);
begin
     FX := X / Value;
     FY := Y / Value;
     FZ := Z / Value;
     Change;
end;

function TVector.DotProduct(const Vector: TVector): Single;
begin
     result := (X*Vector.X) + (Y*Vector.Y) + (Z*Vector.Z);
end;

function TVector.DotProduct(const X, Y, Z: Single): Single;
begin
     result := (FX*X) + (FY*Y) + (FZ*Z);
end;

function TVector.Equals(const X, Y, Z: Single): Boolean;
begin
     result := (FX >= (X-FloatError)) and
               (FX <= (X+FloatError)) and
               (FY >= (Y-FloatError)) and
               (FY <= (Y+FloatError)) and
               (FZ >= (Z-FloatError)) and
               (FZ <= (Z+FloatError));
end;

function TVector.Equals(const Vector: TVector): Boolean;
begin
     result := (FX >= (Vector.X-FloatError)) and
               (FX <= (Vector.X+FloatError)) and
               (FY >= (Vector.Y-FloatError)) and
               (FY <= (Vector.Y+FloatError)) and
               (FZ >= (Vector.Z-FloatError)) and
               (FZ <= (Vector.Z+FloatError));
end;

function TVector.EqualsStar(const X, Y, Z: Single): Boolean;
var
   v1, v2: TVector;
begin
     // see if vectors point in same direction
     v1 := TVector.Create(X,Y,Z);
     v2 := TVector.Create(Self);
     try
        v1.Normalize;
        v2.Normalize;
        result := v1.Equals( v2 );
     finally
        v1.Free;
        v2.Free;
     end;
end;

function TVector.EqualsStar(const Vector: TVector): Boolean;
var
   v1, v2: TVector;
begin
     // see if vectors point in same direction
     v1 := TVector.Create(Vector);
     v2 := TVector.Create(Self);
     try
        v1.Normalize;
        v2.Normalize;
        result := v1.Equals( v2 );
     finally
        v1.Free;
        v2.Free;
     end;
end;

function TVector.Length: Single;
begin
     result := Sqrt( X*X + Y*Y + Z*Z );
end;

procedure TVector.Multiply(const Vector: TVector);
begin
     FX := X * Vector.X;
     FY := Y * Vector.Y;
     FZ := Z * Vector.Z;
     Change;
end;

procedure TVector.Multiply(const Value: Single);
begin
     FX := X * Value;
     FY := Y * Value;
     FZ := Z * Value;
     Change;
end;

procedure TVector.Normalize;
var
   m: Double;
begin
     M := Length;
     if m > 0 then
        m := 1 / m
     else
         m := 0;
     FX := X * m;
     FY := Y * m;
     FZ := Z * m;
     Change;
end;

procedure TVector.SetMagnitudeOfVector(const Velocity: Single);
begin
     Normalize;
     FX := X * Velocity;
     FY := Y * Velocity;
     FZ := Z * Velocity;
     Change;
end;

procedure TVector.SetXYZ(const X, Y, Z: Single);
begin
     FX := x;
     FY := y;
     FZ := z;
     Change;
end;

procedure TVector.Subtract(const Vector: TVector);
begin
     FX := FX - Vector.X;
     FY := FY - Vector.Y;
     FZ := FZ - Vector.Z;
     Change;
end;

procedure TVector.Subtract(const Value: Single);
begin
     FX := FX - Value;
     FY := FY - Value;
     FZ := FZ - Value;
     Change;
end;

procedure TVector.SetX(const Value: Single);
begin
  FX := Value;
  Change;
end;

procedure TVector.SetY(const Value: Single);
begin
  FY := Value;
  Change;
end;

procedure TVector.SetZ(const Value: Single);
begin
  FZ := Value;
  Change;
end;

procedure TVector.Change;
begin

end;

end.
