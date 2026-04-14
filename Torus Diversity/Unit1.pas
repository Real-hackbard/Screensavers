unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, Torus, Math;

const

   { play around with the following values...  but think of memory }
   TORUS_COUNT = 26;
   THE_DELAY = 10;


type
  TForm1 = class(TForm)
    Timer1: TTimer;


    procedure FormCreate(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure Timer1Timer(Sender: TObject);
    procedure FormClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure DrawTheTrace(T:tTorusRec;Trace:tDotSet;Col:tColor;WhereTo:integer);
    procedure MoveTheTorus;
    procedure ReStartAllTorus;
  end;

var
  Form1: TForm1;
  OldPos: TPoint;

implementation

{$R *.dfm}
{$E scr}

var
  InitDone:boolean;
  OneTorus:array[1..TORUS_COUNT] of tTorusRec;

procedure MakeFormFullscreenAcrossAllMonitors(Form: TForm);
begin
  Form.BorderStyle := bsNone;
  Form.WindowState := wsNormal; // Make sure it is not maximized

  // Use the virtual screen boundaries
  Form.Left := 0;
  Form.Top := 0;
  Form.Width := Screen.DesktopWidth;
  Form.Height := Screen.DesktopHeight;

  // Optional: If this still doesn't take precedence over everything,
  // consider the taskbar.
  // or use Form.BringToFront.
end;

{  ----------------------------------------------------------------------- }
procedure TForm1.DrawTheTrace(T:tTorusRec;Trace:tDotSet;Col:tColor;WhereTo:integer);
var
  counter:integer;
begin
   with canvas,T do
   begin
      brush.color := clBlack;
      pen.color := Col;
      MoveTo(Trace[0].x,Trace[0].y);
      for Counter := 1 to WhereTo do
         LineTo(Trace[Counter].x,Trace[Counter].y);
   end;
end;
{  ----------------------------------------------------------------------- }
procedure TForm1.MoveTheTorus;
var
  C:integer;
begin
     for C := 1 to TORUS_COUNT do
     begin
          if ( ( random * 10000) < 2  ) then  { init this one all over }
               { play with the value 10000 < 2 }
          begin
             { un-draw it ( draw it black ) }
             DrawTheTrace(OneTorus[c],OneTorus[c].Traces[TraceA],
                           clBlack,OneTorus[c].NumPoints);
             InitTorus(OneTorus[C],Width,Height,true);
          end;

          MoveTorus(OneTorus[c]);
          { un-draw the last set of points ( draw it black ) }
          DrawTheTrace(OneTorus[c],OneTorus[c].Traces[OldA],
                       clBlack,OneTorus[c].NumPoints);
          { draw it }
          DrawTheTrace(OneTorus[c],OneTorus[c].Traces[TraceA],
                       OneTorus[c].TheColour,OneTorus[c].NumPoints);
     end;  { for }
end;
{  ----------------------------------------------------------------------- }
procedure TForm1.ReStartAllTorus;
var
  c:integer;
begin
   randomize;
   for C := 1 to TORUS_COUNT do
      InitTorus(OneTorus[C],Width,Height,true);
   InitDone := true;
   Timer1.Interval := THE_DELAY;
end;
{  ----------------------------------------------------------------------- }
procedure TForm1.FormCreate(Sender: TObject);
begin
  DoubleBuffered := true;
  //WindowState :=  wsMaximized;
  BorderStyle := bsNone;  { ***** see TForm1.FormKeyPress }
  Color := clBlack;
  Cursor := crNone;
  InitDone := false;
  Timer1.interval := 100;
  GetCursorPos(OldPos); // Initialposition
  MakeFormFullscreenAcrossAllMonitors(Form1);
end;
{  ----------------------------------------------------------------------- }
procedure TForm1.FormKeyPress(Sender: TObject; var Key: Char);
begin
   close;
end;
{  ----------------------------------------------------------------------- }
procedure TForm1.Timer1Timer(Sender: TObject);
var
  NewPos: TPoint;
begin
  GetCursorPos(NewPos);
  if (NewPos.X <> OldPos.X) or (NewPos.Y <> OldPos.Y) then
  begin
    Close()
  end;

   if Not InitDone then
   begin
     ReStartAllTorus;
   end
   else
   begin
     MoveTheTorus;
   end;
end;

procedure TForm1.FormClick(Sender: TObject);
begin
  Close();
end;

end.
