unit Flock;

interface

uses
  Classes, Vector;

Const
  Half_PI = 3.14159 / 2;

Type
  TApplyChangeEvent = procedure (Sender: TObject; const Accumulator, Change: TVector ) of object;
  TFlockingBehavior = (fbSeparation, fbAlignment, fbCohesion, fbAvoidance);
  TFlockingBehaviors = set of TFlockingBehavior;
  TCustomFlock = class;
  TBoid = class(TCollectionItem)
  { Purpose: To encapsulate an individual member of a flock }
  private
    { Private declarations }
    FOldPosition: TVector;
    FPosition: TVector;
    FOrientation: TVector;
    FVelocity: TVector;
    FOldVelocity: TVector;
    FFlock: TCustomFlock;
    FNearestFlockMateDist: Single;
    FNearestFlockMate: TBoid;
    FSpeed: Single;
    FNearestEnemyDist: Single;
    FNearestEnemy: TBoid;
    FTag: Integer;
    procedure SetOrientation(const Value: TVector);
    procedure SetPosition(const Value: TVector);
    procedure SetVelocity(const Value: TVector);
    procedure SetSpeed(const Value: Single);
  protected
    { Protected declarations }
    { Flocking behaviors }
    procedure ApplyFlockingRules( const Accumulator: TVector ); virtual;
    procedure ApplyCruising( const Accumulator: TVector ); virtual;
    procedure ApplySeparation( const Accumulator: TVector ); virtual;
    procedure ApplyAlignment( const Accumulator: TVector ); virtual;
    procedure ApplyCohesion( const Accumulator: TVector ); virtual;
    procedure ApplyAvoidance( const Accumulator: TVector ); virtual;
    procedure Executing; virtual;
    procedure Executed; virtual;
    procedure SeeEnemyFlocks; virtual;
    procedure SeeFlockmates; virtual;
    procedure ComputeOrientation; virtual;
    procedure UpdateVelocity( const Accumulator: TVector ); virtual;
    procedure WorldBound; virtual;
    property OldPosition: TVector read FOldPosition;
    property OldVelocity: TVector read FOldVelocity;
  public
    { Public declarations }
    procedure Assign( Source: TPersistent ); override;
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
    procedure Execute; virtual;
    property Flock: TCustomFlock read FFlock;
    property NearestEnemy: TBoid read FNearestEnemy;
    property NearestEnemyDist: Single read FNearestEnemyDist;
    property NearestFlockMate: TBoid read FNearestFlockMate;
    property NearestFlockMateDist: Single read FNearestFlockMateDist;
  published
    { Published declarations }
    property Orientation: TVector read FOrientation write SetOrientation;
    property Position: TVector read FPosition write SetPosition;
    property Speed: Single read FSpeed write SetSpeed;
    property Tag: Integer read FTag write FTag;
    property Velocity: TVector read FVelocity write SetVelocity;
  end; { TBoid }
  TBoidClass = class of TBoid;
  TBoidEvent = procedure ( Sender: TObject; const Boid: TBoid ) of object;
  TBoidApplyChangeEvent = procedure (Sender: TObject; const Boid: TBoid; const Accumulator, Change: TVector ) of object;

  TFlockCollection = class(TCollection)
  { Purpose: To encapsulate a collection of boids.  This collection will manage
    adding, deleting, and tracking boids automatically }
  private
    { Private declarations }
    FFlock: TCustomFlock;
    function GetItem(Index: Integer): TBoid;
    procedure SetItem(Index: Integer; Value: TBoid);
  protected
    { Protected declarations }
    function GetOwner: TPersistent; override;
    procedure Update(Item: TCollectionItem); override;
    property Flock: TCustomFlock read FFlock;
  public
    { Public declarations }
    constructor Create(Flock: TCustomFlock); overload;
    constructor Create(Flock: TCustomFlock; BoidClass: TBoidClass); overload; virtual;
    function Add: TBoid;
    procedure Clear;
    procedure Delete(Index: Integer);
    function Insert(Index: Integer): TBoid;
    property Items[Index: Integer]: TBoid read GetItem write SetItem; default;
  published
    { Published declarations }
  end; { TFlockCollection }

  TFlockVector = class(TVector)
  { Purpose: To provide a vector that informs the flock when it changes.  Used
    for position and velocity in TCustomFlock }
  private
    { Private Declarations }
    FFlock: TCustomFlock;
  protected
    { Protected Declarations }
    procedure Change; override;
  public
    { Public Declarations }
    constructor Create( Flock: TCustomFlock );
    property Flock: TCustomFlock read FFlock;
  published
    { Published Declarations }
  end; { TFlockVector }

  TFlockWorld = class;
  TAutoCalcProperty = (acpPosition, acpVelocity);
  TAutoCalcProperties = set of TAutoCalcProperty;
  TCustomFlock = class(TComponent)
  { Purpose: To encapsulate a flock (made up of TBoids) }
  private
    { Private declarations }
    FBoids: TFlockCollection;
    FOnChange: TNotifyEvent;
    FOnBoidChange: TBoidEvent;
    FSeparationDistance: Single;
    FMinUrgency: Single;
    FMaxUrgency: Single;
    FPosition: TVector;
    FMaxSpeed: Single;
    FDesiredSpeed: Single;
    FMaxChange: Single;
    FWorld: TFlockWorld;
    FBehaviors: TFlockingBehaviors;
    FStrengthAlignment: Single;
    FStrengthSeparation: Single;
    FStrengthCohesion: Single;
    FVelocity: TVector;
    FAvoidanceDistance: Single;
    FStrengthAvoidance: Single;
    FAutoCalcProperties: TAutoCalcProperties;
    FUpdateCount: Integer;
    FOnExecuted: TNotifyEvent;
    FOnExecuting: TNotifyEvent;
    FOnBoidDelete: TBoidEvent;
    FOnBoidAdded: TBoidEvent;
    FOnClear: TNotifyEvent;
    FOnApplyAvoidance: TBoidApplyChangeEvent;
    FOnApplyCohesion: TBoidApplyChangeEvent;
    FOnApplySeparation: TBoidApplyChangeEvent;
    FOnApplyAlignment: TBoidApplyChangeEvent;
    FOnBoidExecuted: TBoidEvent;
    FOnBoidExecuting: TBoidEvent;
    FMinTimeToMaxSpeed: Single;
    procedure SetWorld(const Value: TFlockWorld);
    procedure SetBoids(const Value: TFlockCollection);
    procedure SetMaxUrgency(const Value: Single);
    procedure SetMinUrgency(const Value: Single);
    procedure SetMaxChange(const Value: Single);
    procedure SetMaxSpeed(const Value: Single);
  protected
    { Protected declarations }
    procedure BoidAdded( const Boid: TBoid ); virtual;
    procedure BoidApplyRule( const Boid: TBoid; const Rule: TFlockingBehavior;
                             const Accumulator, Change: TVector ); virtual;
    procedure BoidDelete( const Boid: TBoid ); virtual;
    procedure BoidClear; virtual;
    procedure BoidExecuted( const Boid: TBoid ); virtual;
    procedure BoidExecuting( const Boid: TBoid ); virtual;
    procedure Executed; virtual;
    procedure Executing; virtual;
    procedure BoidChange( Boid: TBoid ) ; virtual;
    procedure Change; virtual;
    procedure VectorChange( Sender: TVector ); virtual;
    function CreateFlock: TFlockCollection; dynamic;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    procedure SetPosition(const Value: TVector); virtual;
    procedure SetVelocity(const Value: TVector); virtual;
    procedure SetAvoidanceDistance(const Value: Single); virtual;
    procedure SetSeparationDistance(const Value: Single); virtual;
  public
    { Public declarations }
    procedure Assign( Source: TPersistent ); override;
    constructor Create( AOwner: TComponent ); override;
    destructor Destroy; override;
    procedure Execute; virtual;
    procedure BeginUpdate; virtual;
    procedure EndUpdate; virtual;
    property MinTimeToMaxSpeed: Single read FMinTimeToMaxSpeed;
    property AutoCalcProperties: TAutoCalcProperties read FAutoCalcProperties write FAutoCalcProperties default [acpPosition, acpVelocity];
    property Boids: TFlockCollection read FBoids write SetBoids;
    property DesiredSpeed: Single read FDesiredSpeed write FDesiredSpeed;
    property Behaviors: TFlockingBehaviors read FBehaviors write FBehaviors default [fbSeparation..fbCohesion];
    property MaxChange: Single read FMaxChange write SetMaxChange;
    property MaxSpeed: Single read FMaxSpeed write SetMaxSpeed;
    property MaxUrgency: Single read FMaxUrgency write SetMaxUrgency;
    property MinUrgency: Single read FMinUrgency write SetMinUrgency;
    property Position: TVector read FPosition write SetPosition;
    property Velocity: TVector read FVelocity write SetVelocity;
    property OnBoidAdded: TBoidEvent read FOnBoidAdded write FOnBoidAdded;
    property OnBoidDelete: TBoidEvent read FOnBoidDelete write FOnBoidDelete;
    property OnBoidExecuted: TBoidEvent read FOnBoidExecuted write FOnBoidExecuted;
    property OnBoidExecuting: TBoidEvent read FOnBoidExecuting write FOnBoidExecuting;
    property OnApplyAvoidance: TBoidApplyChangeEvent read FOnApplyAvoidance write FOnApplyAvoidance;
    property OnApplyAlignment: TBoidApplyChangeEvent read FOnApplyAlignment write FOnApplyAlignment;
    property OnApplyCohesion: TBoidApplyChangeEvent read FOnApplyCohesion write FOnApplyCohesion;
    property OnApplySeparation: TBoidApplyChangeEvent read FOnApplySeparation write FOnApplySeparation;
    property OnClear: TNotifyEvent read FOnClear write FOnClear;
    property OnBoidChange: TBoidEvent read FOnBoidChange write FOnBoidChange;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnExecuting: TNotifyEvent read FOnExecuting write FOnExecuting;
    property OnExecuted: TNotifyEvent read FOnExecuted write FOnExecuted;
    property AvoidanceDistance: Single read FAvoidanceDistance write SetAvoidanceDistance;
    property SeparationDistance: Single read FSeparationDistance write SetSeparationDistance;
    property StrengthAlignment: Single read FStrengthAlignment write FStrengthAlignment;
    property StrengthAvoidance: Single read FStrengthAvoidance write FStrengthAvoidance;
    property StrengthSeparation: Single read FStrengthSeparation write FStrengthSeparation;
    property StrengthCohesion: Single read FStrengthCohesion write FStrengthCohesion;
    property World: TFlockWorld read FWorld write SetWorld;
  published
    { Published declarations }
  end; { TCustomFlock }

  TArrow = class(TCustomFlock)
  private
    { Private Declarations }
  protected
    { Protected Declarations }
  public
    { Public Declarations }
  published
    { Published Declarations }
    // property DesiredSpeed  commented out since ApplyCruising is not being used
    property AutoCalcProperties;
    property Boids;
    property Behaviors;
    property MaxChange;
    property MaxSpeed;
    property MaxUrgency;
    property MinUrgency;
    property Position;
    property Velocity;
    property OnBoidAdded;
    property OnBoidDelete;
    property OnBoidExecuted;
    property OnBoidExecuting;
    property OnApplyAvoidance;
    property OnApplyAlignment;
    property OnApplyCohesion;
    property OnApplySeparation;
    property OnClear;
    property OnExecuting;
    property OnExecuted;
    property OnBoidChange;
    property OnChange;
    property AvoidanceDistance;
    property SeparationDistance;
    property StrengthAlignment;
    property StrengthAvoidance;
    property StrengthSeparation;
    property StrengthCohesion;
    property World;
  end; { TFlock }

  TFlockWorld = class(TComponent)
  { Purpose: To define the boundaries and phenomena of the flock world.
    Only one flock world is allowed in this implementation. }
  private
    { Private declarations }
    FGravity: Single;
    FOrigin: TVector;
    FDimension: TVector;
    FFlocks: TList;
    procedure SetDimension(const Value: TVector);
    procedure SetOrigin(const Value: TVector);
    function GetFlock(Index: Integer): TCustomFlock;
    function GetFlockCount: Integer;
  protected
    { Protected declarations }
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    property Flocks: TList read FFlocks;
  public
    { Public declarations }
    constructor Create( AOwner: TComponent ); override;
    destructor Destroy; override;
    property Flock[Index: Integer]: TCustomFlock read GetFlock;
    property FlockCount: Integer read GetFlockCount;
  published
    { Published declarations }
    property Dimension: TVector read FDimension write SetDimension;
    property Gravity: Single read FGravity write FGravity;
    property Origin: TVector read FOrigin write SetOrigin;
  end; { TFlockWorld }

  function Sign( const Val: Single ): Integer;

implementation

uses
   Math;
function Sign( const Val: Single ): Integer;
begin
     if Val < 0 then
        result := -1
     else if Val > 0 then
         result := 1
     else
         result := 0;
end;

{ TBoid }

procedure TBoid.Assign(Source: TPersistent);
begin
     if Source is TBoid then
     begin
          FTag := TBoid(Source).Tag;
          FOldPosition.Assign( TBoid(Source).FOldPosition );
          FPosition.Assign( TBoid(Source).Position );
          FOrientation.Assign( TBoid(Source).Orientation );
          FVelocity.Assign( TBoid(Source).Velocity );
          FOldVelocity.Assign( TBoid(Source).FOldVelocity );
          FSpeed := TBoid(Source).FSpeed;
          Changed(False);
          Exit;
     end;
     inherited Assign( Source );
end;

procedure TBoid.ComputeOrientation;
var
   roll, pitch, yaw: Single;
   Temp: TVector;
   LateralDir: TVector;
   LateralMag: Single;
   SqrtVel: Double;
begin
     // Determine the direction of the lateral acceleration.
     Temp := TVector.Create( Velocity );
     LateralDir := TVector.Create( Velocity );
     try
        Temp.Subtract( OldVelocity );
        LateralDir.CrossProduct( Temp );
        LateralDir.CrossProduct( Velocity );
        LateralDir.Normalize;
        // Set the lateral acceleration's magnitude.
        // The magnitude is the vector
        // projection of the appliedAcceleration vector
        // onto the direction of the lateral acceleration.
        Temp.Assign( Velocity );
        Temp.Subtract( OldVelocity );
        LateralMag := Temp.DotProduct( LateralDir );

        // compute roll
        if lateralMag = 0 then Roll := 0
        else Roll := -arctan2(Flock.World.Gravity, lateralMag) + HALF_PI;
        // compute pitch
        SqrtVel := sqrt((Velocity.z*Velocity.z) + (Velocity.x*Velocity.x));
        if SqrtVel = 0 then
           Pitch := -arctan(0)
        else
            Pitch := -arctan(Velocity.y / SqrtVel);
        // compute yaw
        yaw := arctan2(Velocity.x, Velocity.z);
        Orientation.SetXYZ( Pitch, Yaw, Roll );
     finally
        Temp.Free;
        LateralDir.Free;
     end;
end;

constructor TBoid.Create(Collection: TCollection);
begin
     inherited Create( Collection );
     FFlock := (Collection as TFlockCollection).Flock;
     FOrientation := TVector.Create;
     FPosition := TVector.Create;
     FVelocity := TVector.Create;
     FOldPosition := TVector.Create;
     FOldVelocity := TVector.Create;
end;

destructor TBoid.Destroy;
begin
     FOrientation.Free;
     FPosition.Free;
     FVelocity.Free;
     FOldPosition.Free;
     FOldVelocity.Free;
     inherited Destroy;
end;

procedure TBoid.ApplyCruising(const Accumulator: TVector);
// Create a vector that the flock mate would follow if no other units
// were in a flock
var
   Change: TVector;
   Diff, Urgency: Single;
   Jitter: Single;
begin
     // Copy the heading of nearest flock mate
     Change := TVector.Create( Velocity );
     try
        Diff := (Speed - Flock.DesiredSpeed) / Flock.MaxSpeed;
        Urgency := Abs(Diff);
        if Urgency < Flock.MinUrgency then Urgency := Flock.MinUrgency
        else if Urgency > Flock.MaxUrgency then Urgency := Flock.MaxUrgency;

        // Add in some randomness in X, Y, or Z
        Jitter := Random;
        if Jitter < 0.45 then
           Change.X := Change.X + (Flock.MinUrgency*Sign(Diff))
        else if Jitter < 0.9 then
           Change.Z := Change.X + (Flock.MinUrgency*Sign(Diff))
        else
           Change.Y := Change.X + (Flock.MinUrgency*Sign(Diff));

        // normalize change to look more natural
        Change.SetMagnitudeOfVector(Urgency*(-Sign(Diff)));
        // Add Change to Accumulator
        Accumulator.Add( Change );
     finally
        Change.Free;
     end;
end;

procedure TBoid.ApplyAvoidance(const Accumulator: TVector);
var
   Change: TVector;
begin
     if Flock.StrengthAvoidance = 0 then Exit;
     // Flocking Rule: Avoidance
     if NearestEnemyDist >= Flock.AvoidanceDistance then
        Change := TVector.Create
     else
         // Try to avoid enemy flocks          
         Change := TVector.Create( Position );
     try
        if NearestEnemyDist < Flock.AvoidanceDistance then
        begin
             // compute vector towards our nearest enemy
             Change.Subtract( NearestEnemy.Position );
             Change.SetMagnitudeOfVector( Flock.MaxUrgency * Flock.StrengthAvoidance );
        end;
        // Add Change to Accumulator
        if Flock <> nil then
           Flock.BoidApplyRule( Self, fbAvoidance, Accumulator, Change );
        Accumulator.Add( Change );
     finally
        Change.Free;
     end;

end;

procedure TBoid.ApplySeparation(const Accumulator: TVector);
var
   Ratio: Single;
   Change: TVector;
begin
     if Flock.StrengthSeparation = 0 then Exit;
     // Flocking Rule: Separation
     // Try to avoid boid colliding with its flockmates
     Change := TVector.Create( NearestFlockMate.Position );
     try
        // compute vector towards our nearest flock mate
        Change.Subtract( Position );
        // Compute ratio of nearest flock mate to separation distance
        // and ensure it is in range of MinUrgency..MaxUrgency
        Ratio := NearestFlockMateDist / Flock.SeparationDistance;
        if Ratio < Flock.MinUrgency then Ratio := Flock.MinUrgency
        else if Ratio > Flock.MaxUrgency then Ratio := Flock.MaxUrgency;

        Ratio := Ratio * Flock.StrengthSeparation;
        // Are we too close to nearest flockmate?  Then Move Away
        if NearestFlockMateDist < Flock.SeparationDistance then
           Change.SetMagnitudeOfVector(-Ratio)
        // Are we too far from nearest flockmate?  Then Move Closer
        else if NearestFlockMateDist > Flock.SeparationDistance then
           Change.SetMagnitudeOfVector(Ratio)
        else // just right
             Change.Clear;
        // Add Change to Accumulator
        if Flock <> nil then
           Flock.BoidApplyRule( Self, fbSeparation, Accumulator, Change );
        Accumulator.Add( Change );
     finally
        Change.Free;
     end;
end;

procedure TBoid.ApplyAlignment(const Accumulator: TVector);
var
   Change: TVector;
begin
     if Flock.StrengthAlignment = 0 then Exit;
     // Flocking Rule: Alignment
     // Try to align boid's heading with its flockmates
     // Copy the heading of the flock
     Change := TVector.Create( Flock.Velocity );
     try
        // normalize change to look more natural
        Change.SetMagnitudeOfVector(Flock.MinUrgency * Flock.StrengthAlignment );
        // Add Change to Accumulator
        if Flock <> nil then
           Flock.BoidApplyRule( Self, fbAlignment, Accumulator, Change );
        Accumulator.Add( Change );
     finally
        Change.Free;
     end;
end;

procedure TBoid.SeeFlockmates;
var
   i: Integer;
   Dist: Single;
begin
     // Unlike S. Woodcock's implementation, we are just going to
     // concern ourself with the nearest flock mate.  All flock mates
     // are considered visible
     FNearestFlockmate := nil;
     FNearestFlockmateDist := MaxInt;
     for i := 0 to Flock.Boids.Count - 1 do
         if Flock.Boids[i] <> Self then
         begin
              Dist := Position.DistanceSqrTo( Flock.Boids[i].Position );
              if Dist < NearestFlockMateDist then
              begin
                   FNearestFlockMateDist := Dist;
                   FNearestFlockMate := Flock.Boids[i];
              end;
         end;
     FNearestFlockMateDist := Sqrt(NearestFlockMateDist);
end;

procedure TBoid.SeeEnemyFlocks;
var
   i, j: Integer;
   Dist: Single;
   AFlock: TCustomFlock;
begin
     // Unlike S. Woodcock's implementation, we are just going to
     // concern ourself with the nearest enemy flock member.  All flock members
     // are considered visible
     FNearestEnemy := nil;
     FNearestEnemyDist := MaxInt;
     for j := 0 to Flock.World.FlockCount - 1 do
     begin
       if Flock.World.Flock[j] <> Flock then
       begin
         AFlock := Flock.World.Flock[j];
         for i := 0 to AFlock.Boids.Count - 1 do
         begin
              Dist := Position.DistanceSqrTo( AFlock.Boids[i].Position );
              if Dist < FNearestEnemyDist then
              begin
                   FNearestEnemyDist := Dist;
                   FNearestEnemy := AFlock.Boids[i];
              end;
         end;
       end;
     end;
     FNearestEnemyDist := Sqrt(FNearestEnemyDist);
end;

procedure TBoid.SetOrientation(const Value: TVector);
begin
  FOrientation.Assign( Value );
  Changed(False);
end;

procedure TBoid.SetPosition(const Value: TVector);
begin
  FPosition.Assign( Value );
  Changed(False);
end;

procedure TBoid.SetVelocity(const Value: TVector);
begin
  FVelocity.Assign( Value );
  Changed(False);
end;

procedure TBoid.ApplyCohesion(const Accumulator: TVector);
var
   Change: TVector;
begin
     if Flock.StrengthCohesion = 0 then Exit;
     // Flocking Rule: Cohesion
     // Try to go toward where all the flockmates are (the flock's center point)
     // Copy the position of center of flock
     Change := TVector.Create( Flock.Position );
     try
        // Average with our position
        Change.Subtract( Position );
        // normalize change to look more natural
        Change.SetMagnitudeOfVector(Flock.MinUrgency*Flock.StrengthCohesion);
        // Add Change to Accumulator
        if Flock <> nil then
           Flock.BoidApplyRule( Self, fbCohesion, Accumulator, Change );
        Accumulator.Add( Change );
     finally
        Change.Free;
     end;
end;

procedure TBoid.Execute;
{ The update method is where all the actual flocking is done.  It is called
  every time period and the boid updates its position based on its flocking
  behaviors }
var
   Accum: TVector;
begin
     Executing;
     // Save Current position
     FOldPosition.Assign( Position );
     // Flocking Rules
     Accum := TVector.Create;
     try
        // Update position based on velocity
        FPosition.Add( Velocity );
        // Flocking Rules
        ApplyFlockingRules( Accum );
        UpdateVelocity( Accum );
        Speed := Velocity.Length;
        if Speed > Flock.MaxSpeed then
        begin
             FSpeed := Flock.MaxSpeed;
             Velocity.SetMagnitudeOfVector(Speed);
        end;
        // Compute Orientation
        ComputeOrientation;
        WorldBound;
     finally
        Accum.Free;
     end;
     Executed;
end;

procedure TBoid.WorldBound;
begin
     if (Flock = nil) or (Flock.World = nil) then Exit;
     if Position.X < Flock.World.Origin.X then Position.X := Flock.World.Dimension.X
     else if Position.X > Flock.World.Dimension.X then Position.X := Flock.World.Origin.X;

     if Position.Y < Flock.World.Origin.Y then Position.Y := Flock.World.Dimension.Y
     else if Position.Y > Flock.World.Dimension.Y then Position.Y := Flock.World.Origin.Y;

     if Position.Z < Flock.World.Origin.Z then Position.Z := Flock.World.Dimension.Z
     else if Position.Z > Flock.World.Dimension.Z then Position.Z := Flock.World.Origin.Z;
end;

procedure TBoid.ApplyFlockingRules(const Accumulator: TVector);
begin
     // Look for flock mates
     SeeFlockmates;
     //          Implement Rule #1 (Separation)
     // Try to maintain our desired separation distance from our nearest flockmate
     if fbSeparation in Flock.Behaviors then
        ApplySeparation( Accumulator );
     //          Implement Rule #2 (Alignment).
     // Try to move the same way our nearest flockmate does
     if fbAlignment in Flock.Behaviors then
        ApplyAlignment( Accumulator );
     //          Implement Rule #3 (Cohesion).
     // Try to move towards the center of the flock
     if fbCohesion in Flock.Behaviors then
        ApplyCohesion( Accumulator );
     //          Implement Rule #4 (Avoidance).
     // Try to move away from enemies
     if fbAvoidance in Flock.Behaviors then
     begin
          SeeEnemyFlocks;
          ApplyAvoidance( Accumulator );
     end;

     // ApplyCruising
     // Add in where we would go without anyone else around
     //ApplyCruising( Accumulator );
end;

procedure TBoid.SetSpeed(const Value: Single);
begin
     if Speed <> Value then
     begin
          FSpeed := Value;
          Changed(False);
     end;
end;

procedure TBoid.Executed;
begin
     if Flock <> nil then Flock.BoidExecuted(Self);
end;

procedure TBoid.Executing;
begin
     if Flock <> nil then Flock.BoidExecuting(Self);
end;

procedure TBoid.UpdateVelocity(const Accumulator: TVector);
begin
     // Ok, now limit speeds
     if Accumulator.Length > Flock.MaxChange then
        Accumulator.SetMagnitudeOfVector(Flock.MaxChange);
     // Save old velocity
     FOldVelocity.Assign( Velocity );

     // Calculate new velocity and constrain it
     Velocity.Add( Accumulator );
     //Velocity.Y := Velocity.Y * Flock.MaxUrgency;
end;

{ TFlockCollection }

function TFlockCollection.Add: TBoid;
begin
     result := TBoid(inherited Add);
     if Flock <> nil then Flock.BoidAdded(result);
end;

constructor TFlockCollection.Create(Flock: TCustomFlock);
begin
     Create(Flock, TBoid);
end;

procedure TFlockCollection.Clear;
begin
     inherited Clear;
     if Flock <> nil then Flock.BoidClear;
end;

constructor TFlockCollection.Create(Flock: TCustomFlock; BoidClass: TBoidClass);
begin
     inherited Create( BoidClass );
     FFlock := Flock;
end;

procedure TFlockCollection.Delete(Index: Integer);
begin
     if Flock <> nil then Flock.BoidDelete(Items[Index]);
     inherited Delete(Index);
end;

function TFlockCollection.GetItem(Index: Integer): TBoid;
begin
     result := TBoid(inherited GetItem(Index));
end;

function TFlockCollection.GetOwner: TPersistent;
begin
     result := FFlock;
end;

function TFlockCollection.Insert(Index: Integer): TBoid;
begin
     result := TBoid(inherited Insert(Index));
     if Flock <> nil then Flock.BoidAdded(result);
end;

procedure TFlockCollection.SetItem(Index: Integer; Value: TBoid);
begin
     inherited SetItem(Index, Value);
end;

procedure TFlockCollection.Update(Item: TCollectionItem);
begin
     inherited Update(Item);
     if Item = nil then     // whole flock list changed somehow
        FFlock.Change
     else
         FFlock.BoidChange( TBoid(Item) );
end;

{ TCustomFlock }

procedure TCustomFlock.Assign(Source: TPersistent);
begin
     if Source is TCustomFlock then
     begin
          BeginUpdate;
          try
             World := TCustomFlock(Source).World;
             FAutoCalcProperties := TCustomFlock(Source).AutoCalcProperties;
             FBoids.Assign( TCustomFlock(Source).Boids );
             FDesiredSpeed := TCustomFlock(Source).FDesiredSpeed;
             FBehaviors := TCustomFlock(Source).FBehaviors;
             FMaxChange := TCustomFlock(Source).FMaxChange;
             FMaxSpeed := TCustomFlock(Source).FMaxSpeed;
             FMaxUrgency := TCustomFlock(Source).FMaxUrgency;
             FMinUrgency := TCustomFlock(Source).FMinUrgency;
             FPosition.Assign( TCustomFlock(Source).Position );
             FVelocity.Assign( TCustomFlock(Source).Velocity );
             FAvoidanceDistance := TCustomFlock(Source).FAvoidanceDistance;
             FSeparationDistance := TCustomFlock(Source).FSeparationDistance;
             FStrengthAlignment := TCustomFlock(Source).FStrengthAlignment;
             FStrengthAvoidance := TCustomFlock(Source).FStrengthAvoidance;
             FStrengthSeparation := TCustomFlock(Source).FStrengthSeparation;
             FStrengthCohesion := TCustomFlock(Source).FStrengthCohesion;
          finally
             EndUpdate;
          end;
     end
     else
         inherited Assign(Source);
end;

procedure TCustomFlock.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TCustomFlock.BoidChange(Boid: TBoid);
begin
     if Assigned(FOnBoidChange) then FOnBoidChange(Self, Boid);
end;

procedure TCustomFlock.Change;
begin
     if FUpdateCount > 0 then Exit;
     if Assigned(FOnChange) then FOnChange(Self);
end;

constructor TCustomFlock.Create(AOwner: TComponent);
begin
     inherited Create(AOwner);
     FAutoCalcProperties := [Low(TAutoCalcProperty)..High(TAutoCalcProperty)];
     FMinUrgency := 0.05;
     FMaxUrgency := 0.1;
     FMaxSpeed := 1;
     FDesiredSpeed := MaxSpeed/2;
     FMaxChange := MaxSpeed*MaxUrgency;
     FMinTimeToMaxSpeed := MaxSpeed / MaxChange;
     FAvoidanceDistance := 6;
     FSeparationDistance := 3;
     FPosition := TFlockVector.Create(Self);
     FVelocity := TFlockVector.Create(Self);
     FBehaviors := [Low(TFlockingBehavior)..High(TFlockingBehavior)];
     FStrengthAlignment := 1;
     FStrengthAvoidance := 1;
     FStrengthSeparation := 1;
     FStrengthCohesion := 1;
     FBoids := CreateFlock;
end;

function TCustomFlock.CreateFlock: TFlockCollection;
begin
     result := TFlockCollection.Create(Self);
end;

destructor TCustomFlock.Destroy;
begin
     FBoids.Free;
     FPosition.Free;
     FVelocity.Free;
     inherited Destroy;
end;

procedure TCustomFlock.EndUpdate;
begin
  Dec(FUpdateCount);
  Change;
end;

procedure TCustomFlock.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
     inherited Notification( AComponent, Operation );
     if (Operation = opRemove) and
        (AComponent = World) then
        World := nil;
end;

procedure TCustomFlock.SetBoids(const Value: TFlockCollection);
begin
     FBoids.Assign( Value );
end;

procedure TCustomFlock.SetMaxUrgency(const Value: Single);
begin
     if Value <> MaxUrgency then
     begin
          FMaxUrgency := Value;
          if MaxUrgency < MinUrgency then
             FMinUrgency := Value;
     end;
end;

procedure TCustomFlock.SetMinUrgency(const Value: Single);
begin
     if Value <> FMinUrgency then
     begin
          FMinUrgency := Value;
          if MaxUrgency < MinUrgency then
             FMaxUrgency := Value;
     end;
end;

procedure TCustomFlock.SetPosition(const Value: TVector);
begin
  FPosition.Assign( Value );
end;

procedure TCustomFlock.SetVelocity(const Value: TVector);
begin
  FVelocity.Assign( Value );
end;

procedure TCustomFlock.SetWorld(const Value: TFlockWorld);
begin
     if World <> Value then
     begin
          if World <> nil then
          begin
               World.RemoveFreeNotification(Self);
               World.Flocks.Remove(Self);
          end;
          FWorld := Value;
          if Value <> nil then
          begin
               Value.FreeNotification( Self );
               Value.Flocks.Add(Self);
          end;
     end;
end;

procedure TCustomFlock.Execute;
var
   i: Integer;
begin
  BeginUpdate;
  try
     Executing;
     if (([acpPosition, acpVelocity] * AutoCalcProperties) <> []) and
        (Boids.Count > 0) then
     begin
          // Find new position of flock by averaging all the flockmates positions
          if acpPosition in AutoCalcProperties then
             Position := Boids[0].Position;
          if acpVelocity in AutoCalcProperties then
             Velocity := Boids[0].Velocity;
          for i := 1 to Boids.Count - 1 do
          begin
               if acpPosition in AutoCalcProperties then
                  Position.Add( Boids[i].Position );
               if acpVelocity in AutoCalcProperties then
                  Velocity.Add( Boids[i].Velocity );
          end;
          if acpPosition in AutoCalcProperties then
             Position.Divide( Boids.Count );
          if acpVelocity in AutoCalcProperties then
             Velocity.Divide( Boids.Count );
     end;
     // Update every member of the flock for the time period
     for i := 0 to Boids.Count - 1 do
         Boids[i].Execute;
     Executed;
  finally
     EndUpdate;
  end;
end;

procedure TCustomFlock.Executed;
begin
     if Assigned(OnExecuted) then OnExecuted(Self)
end;

procedure TCustomFlock.Executing;
begin
     if Assigned(OnExecuting) then OnExecuting(Self)
end;

procedure TCustomFlock.BoidAdded(const Boid: TBoid);
begin
     if Assigned(FOnBoidAdded) then FOnBoidAdded( Self, Boid );
end;

procedure TCustomFlock.BoidClear;
begin
     if Assigned(FOnClear) then FOnClear(Self);
end;

procedure TCustomFlock.BoidDelete(const Boid: TBoid);
begin
     if Assigned(FOnBoidDelete) then FOnBoidDelete( Self, Boid );
end;

procedure TCustomFlock.BoidApplyRule(const Boid: TBoid;
  const Rule: TFlockingBehavior; const Accumulator, Change: TVector);
begin
     case Rule of
          fbSeparation:
            if Assigned(FOnApplySeparation) then FOnApplySeparation( Self, Boid, Accumulator, Change );
          fbAlignment:
            if Assigned(FOnApplyAlignment) then FOnApplyAlignment( Self, Boid, Accumulator, Change );
          fbCohesion:
            if Assigned(FOnApplyCohesion) then FOnApplyCohesion( Self, Boid, Accumulator, Change );
          fbAvoidance:
            if Assigned(FOnApplyAvoidance) then FOnApplyAvoidance( Self, Boid, Accumulator, Change );
     end;
end;

procedure TCustomFlock.BoidExecuted( const Boid: TBoid );
begin
     if Assigned(FOnBoidExecuted) then FOnBoidExecuted( Self, Boid );
end;

procedure TCustomFlock.BoidExecuting( const Boid: TBoid );
begin
     if Assigned(FOnBoidExecuting) then FOnBoidExecuting( Self, Boid );
end;

procedure TCustomFlock.SetMaxChange(const Value: Single);
begin
     if Value <> MaxChange then
     begin
          if Value < 0.00001 then
             FMaxChange := 0.00001
          else
             FMaxChange := Value;
          FMinTimeToMaxSpeed := MaxSpeed / MaxChange
     end;
end;

procedure TCustomFlock.SetMaxSpeed(const Value: Single);
begin
     if Value <> MaxSpeed then
     begin
          if Value < 0 then
             FMaxSpeed := 0
          else
              FMaxSpeed := Value;
          FMinTimeToMaxSpeed := MaxSpeed / MaxChange
     end;
end;

procedure TCustomFlock.VectorChange( Sender: TVector );
begin

end;

procedure TCustomFlock.SetAvoidanceDistance(const Value: Single);
begin
     if Value < 0 then
         FAvoidanceDistance := 0
     else
         FAvoidanceDistance := Value;
end;

procedure TCustomFlock.SetSeparationDistance(const Value: Single);
begin
     if Value < 0 then
         FSeparationDistance := 0
     else
         FSeparationDistance := Value;
end;

{ TFlockWorld }

constructor TFlockWorld.Create(AOwner: TComponent);
begin
     inherited Create( AOwner );
     FOrigin := TVector.Create;
     FDimension := TVector.Create( 100, 100, 100 );
     FGravity := 9.806650;
     FFlocks := TList.Create;
end;

destructor TFlockWorld.Destroy;
begin
     FOrigin.Free;
     FDimension.Free;
     FFlocks.Free;
     inherited Destroy;
end;

function TFlockWorld.GetFlock(Index: Integer): TCustomFlock;
begin
     result := TCustomFlock(Flocks[Index]);
end;

function TFlockWorld.GetFlockCount: Integer;
begin
     result := Flocks.Count;
end;

procedure TFlockWorld.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
     inherited Notification( AComponent, Operation );
     if AComponent is TCustomFlock then
        if Operation = opRemove then
           Flocks.Remove( AComponent );
end;

procedure TFlockWorld.SetDimension(const Value: TVector);
begin
     FDimension.Assign( Value );
end;

procedure TFlockWorld.SetOrigin(const Value: TVector);
begin
     FOrigin.Assign( Value );
end;

{ TFlockVector }

procedure TFlockVector.Change;
begin
     Flock.VectorChange(Self);
end;

constructor TFlockVector.Create(Flock: TCustomFlock);
begin
     inherited Create;
     FFlock := Flock;
end;

end.

