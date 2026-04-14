unit Torus;

interface
uses
  Windows, Graphics, Utils, Classes;

const
 { Play with the following values }

  FRONT_LIMIT = 24;
  BACK_LIMIT  = 1;
  SIZE_LIMITER = 8000;
  START_DIST = 1.1;
  DISTANCE_SPEED = 6;
  ORIG_ARC_INC = 0.01;

  { the next two values can gobble up memory  along with TORUS_COUNT in U_Main }
  MAX_NUM_TURNS = 10;
  MAX_STEPS_PER_TURN = 22;

  { you can't chage these }
  MAX_NUM_POINTS = MAX_NUM_TURNS * MAX_STEPS_PER_TURN;
  TraceA = 1;
  OldA   = 2;



type
  tDotSet = array[0..MAX_NUM_POINTS] of tPoint;
  tTraceSet = array[TraceA..OldA] of tDotSet;

  tDataRec = record
               NumImages,
               Speed:integer;
             end;

  tTorusRec = record
                RollEnabled:boolean;    // enable roll OR dive
                TorusRotation,
                TorusRotationSpeed:real;
                NumTurns,
                StepsPerTurn:integer;

                HoopAngleInc,
                CylinderAngleInc,
                DiveAngle,              // north / south ROLL
                RollAngle,              // east  / west  ROLL
                RollOrDiveAngleInc:     // change in Roll/Dive angle
                       real;
                TurnRotation,
                TurnRotationSpeed:integer;
                DirX,             // direction centre moves ( x,y )
                DirY:Integer;
                Traces:tTraceSet;
                AimColour,
                TheColour:tColor;
                DistanceSpeed,
                Distance,
                MidX,             // centre of torus ( x.y )
                MidY:real;
                NumPoints:integer;
                Hoop,
                Cylinder:integer;
                Distx3,
                Disty3:real;
                SpeedX,           // speed centre moves ( x,y )
                SpeedY:real;

                OrigArcInc,
                OrigArc:real;

              end; { tTorusRec }

{ the only Two procedures "seen" from outside }
Procedure MoveTorus(var aTorus:tTorusRec);
procedure InitTorus(Var aTorus:tTorusRec;W,H:integer;IsSMall:boolean);
var
  LeftWall,
  RightWall,
  TopWall,
  BottomWall:integer;


implementation


var
    OrigX,
    OrigY,
    ScMidX,
    ScMidY:integer;
    CosRollAngle,
    CosDiveAngle,
    SinRollAngle,
    SinDiveAngle:real;
    DistanceSquared:real;
    OrigRadX,
    OrigRadY:integer;

{ ------------------------------------------------------------------------ }
function GetSpeed:real;
var
  C:real;
begin
  C := ( random * DISTANCE_SPEED ) + 0.1;
  GetSpeed := C;
end;
{ ------------------------------------------------------------------------ }
function PlotPlace(A0,A2:real;T:tTorusRec):tPoint;
var
  x0,y0,
  x2,y2:real;

begin
  with T do
  begin
     x0 := ( MyCos(A0) * ( CosRollAngle * Hoop ));
     y0 := ( MySin(A0) * ( CosDiveAngle * Hoop ));

     x2 := x0 +
         ((MySin(A2) * (Cylinder * MyCos(A0))) * CosRollAngle) +
         ( MyCos(A2) *  Cylinder * SinRollAngle);

     y2 := y0 +
         ((MySin(A2) * (Cylinder * MySin(A0))) * CosDiveAngle) +
         ( MyCos(A2) *  Cylinder * SinDiveAngle);

     x2 := x2 * DistanceSquared;
     y2 := y2 * DistanceSquared;

     PlotPlace := Point(round(x2 + Distx3 ) + OrigX,
                        round(y2 + Disty3 ) + OrigY );
  end;
end;
{ ------------------------------------------------------------------------ }
Procedure MoveTorus(var aTorus:tTorusRec);
{  ***********************************************
looks big ... but most of it is just moving things
around and bouncing off walls
************************************************** }
var
  Counter:integer;
  NewSpeed,
  HoopAngle,
  CylinderAngle:real;
begin
  with aTorus do
  begin
     OrigArc := OrigArc + ( OrigArcInc );
     while ( OrigArc > FULL_CIRCLE ) do
        OrigArc := OrigArc - FULL_CIRCLE;
     while ( OrigArc < 0 ) do
        OrigArc := OrigArc + FULL_CIRCLE;
     OrigX := round( ScMidX + ( MySin(OrigArc) * OrigRadX ));
     OrigY := round( ScMidY + ( MyCos(OrigArc) * OrigRadY ));

    { change the colour }
    TheColour := SlideColours(TheColour,AimColour);
    if (TheColour = AimColour) then
       AimColour := RandomColour;

    { Rotate the turns  }
       TurnRotation := TurnRotation + TurnRotationSpeed;
       while TurnRotation > FULL_CIRCLE do
          TurnRotation := TurnRotation - FULL_CIRCLE;

    { Rotat the Torus }
    TorusRotation := TorusRotation + TorusRotationSpeed;
    while TorusRotation > FULL_CIRCLE do
       TorusRotation := TorusRotation - FULL_CIRCLE;



    { Change the Roll or Dive Angle }
      if RollEnabled then
      begin
         RollAngle := RollAngle + RollOrDiveAngleInc;
         while RollAngle > FULL_CIRCLE do
            RollAngle := RollAngle - FULL_CIRCLE;
         if int(RollAngle) = 0 then
         begin
            RollEnabled := not RollEnabled;
            RollOrDiveAngleInc := random * 3 + 0.01;
            TorusRotationSpeed  := random(8) + 0.01;
         end;
      end
      else
      begin
         DiveAngle := DiveAngle + RollOrDiveAngleInc;
         while DiveAngle > FULL_CIRCLE do
            DiveAngle := DiveAngle - FULL_CIRCLE;
         if int(DiveAngle) = 0 then
         begin
            RollEnabled := not RollEnabled;
            RollOrDiveAngleInc := random * 3 + 0.01;
         end
      end;

    { move the Axil }

       { change the distance (Z) }
      distance := distance + DistanceSpeed;
      if ( ( Distance > FRONT_LIMIT )  or ( Distance < BACK_LIMIT )) then
      begin
         DistanceSpeed := -DistanceSpeed;
         distance := distance + DistanceSpeed;
         newSpeed := GetSpeed / 160;
         if ( DistanceSpeed > 0 ) then
           DistanceSpeed := NewSpeed
         Else
           DistanceSpeed := -NewSpeed;
      end;


      { Change x pos }
      MidX := MidX + ( SpeedX * DirX );
      if ( ( MidX < LeftWall ) or ( MidX > RightWall ) ) then
      begin
        DirX := -DirX;
        MidX := MidX + ( SpeedX * DirX );
        SpeedX := GetSpeed;
      end;

      { change y pos }
      MidY := MidY + ( SpeedY * DirY );
      if ( ( MidY < TopWall ) or ( MidY > BottomWall ) ) then
      begin
        DirY := -DirY;
        MidY := MidY + ( SpeedY * DirY );
        SpeedY := GetSpeed;
      end;

    { END move the Axil }

    { Remember the old trace }
    Traces[OldA] := Traces[TraceA];

    { Plot the New Places }
    CosRollAngle := MyCos(RollAngle);
    SinRollAngle := MySin(RollAngle);
    CosDiveAngle := MyCos(DiveAngle);
    SinDiveAngle := MySin(DiveAngle);

     HoopAngle := TorusRotation;
     CylinderAngle := TurnRotation;

     while ( HoopAngle > FULL_CIRCLE ) do HoopAngle := HoopAngle - FULL_CIRCLE;
     while ( CylinderAngle > FULL_CIRCLE ) do CylinderAngle := CylinderAngle - FULL_CIRCLE;

     DistanceSquared := (Distance * Distance * Distance / SIZE_LIMITER);
     Distx3 := MidX * DistanceSquared;
     Disty3  := MidY * DistanceSquared;

     Traces[TraceA][0] := PlotPlace(HoopAngle,CylinderAngle,aTorus);

     for Counter := 1 to NumPoints do
     begin
        HoopAngle := HoopAngle + HoopAngleInc;
        while ( HoopAngle > FULL_CIRCLE ) do HoopAngle := HoopAngle - FULL_CIRCLE;
        CylinderAngle := CylinderAngle + CylinderAngleInc;
        while ( CylinderAngle > FULL_CIRCLE ) do
           CylinderAngle := CylinderAngle - FULL_CIRCLE;
        Traces[TraceA][Counter] := PlotPlace(HoopAngle,CylinderAngle,aTorus);
     end; { for }

     for Counter := ( NumPoints + 1 ) to MAX_NUM_POINTS do
        Traces[TraceA][Counter] := Traces[TraceA][Counter - 1];

  end; { with aTorus }
end;  { MoveTorus  }
{ ------------------------------------------------------------------------ }
procedure InitTorus(Var aTorus:tTorusRec;W,H:integer;IsSMall:boolean);
                    { W = Screen.width:   H = Screen.Height }
var
  i0,
  i2,
  c:integer;
begin
  C := H div 2;
  LeftWall := - W - C;
  RightWall := W + C;
  TopWall :=  - H - C;
  BottomWall := H + C;
  OrigRadX := W div 16 * 4;
  OrigRadY := H div 16 * 6;
  with aTorus do
  begin
    OrigArc := ( Random * FULL_CIRCLE ) ;
    OrigArcInc := Random * 0.7;
    if ( ( Random * 10 ) > 5 ) then
       OrigArcInc := -OrigArcInc;
    ScMidX := W div 2;
    ScMidY := h div 2;
    DistanceSpeed := GetSpeed;
    Distance := START_DIST;

    TheColour := RandomColour;
    AimColour := RandomColour;

    RollAngle := 0;
    DiveAngle := 0;
    TurnRotation := 0;
    TurnRotationSpeed := random(5) + 1;

    TorusRotation := 0;
    TorusRotationSpeed  := random(5) + 0.01;

    RollOrDiveAngleInc := random * 3 + 0.01;

    { ================================ }
    c := H div 20;
    if IsSmall then
       i0 := round(Int(random * 3)) + 1
    else
       i0 := round(Int(random * 16)) + 1;

    Hoop := C * i0;
    i2 := round(Int(random * (i0 - 1)) + 1);
    Cylinder := C * i2;
    { ================================ }
    MidX := 0;
    MidY := 0;

    NumTurns := round(int(random *   MAX_NUM_TURNS) + 1);
    StepsPerTurn := round(int(random *  MAX_STEPS_PER_TURN) + 1);
    if ( StepsPerTurn > 19 ) then
      StepsPerTurn := 4;

    if ( StepsPerTurn > 16 ) then
      StepsPerTurn := 3;

    if ( StepsPerTurn > 12 ) then
      StepsPerTurn := 2;

    NumPoints := NumTurns * StepsPerTurn;
    HoopAngleInc := FULL_CIRCLE / NumPoints;
    CylinderAngleInc:= FULL_CIRCLE / StepsPerTurn;

    SpeedX := GetSpeed;
    SpeedY := GetSpeed;
    c := random(10);
    if ( C > 5 ) then
       DirX := 1
    else
       DirX := -1;
    c := random(10);
    if ( C > 5 ) then
       DirY := 1
    else
       DirY := -1;

    RollEnabled := ( DirY > 0 );
  end; { with }
end; { InitTorus }
{ ------------------------------------------------------------------------ }




end.
