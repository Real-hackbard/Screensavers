unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, IniFiles, Config;

type
  TConfig=record
   CfNbBlood, CfColor: Integer;
   CfLength, CfSize, CfSpeed, CfGravity: Single;
  end;

  TBlood=record
   X, Y, DX, DY, V: Single;
   Size: Integer;
   Color: TColor;
  end;

type
  TForm1 = class(TForm)
    Timer1: TTimer;
    Image1: TImage;
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
  private
    { Private-Deklarationen}
  public
    { Public-Deklarationen}
    procedure GetConfig;
    procedure CreateBlood(X, Y: Integer);
    function IsBloodOut: Boolean;
  end;

var
  Form1: TForm1;
  Config: TConfig;
  MaxBlood: Integer;
  Blood: array of TBlood;

implementation

{$R *.dfm}
{$E scr}
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

procedure TForm1.GetConfig; // We retrieve the configuration information
var
 A, B, C, D: Integer; // Temporary variables
begin
 with TIniFile.Create(ExtractFilePath(Application.ExeName) + 'BloodSaver.ini') do
  begin
   Config.CfNbBlood := ReadInteger('BloodOptions', 'NbBlood', 80); // Number of drops
   A := ReadInteger('BloodOptions', 'Gravity', 0); // Type of severity
   case A of
    0: Config.CfGravity := 1;   // Terrestrial
    1: Config.CfGravity := 0.18;// Lunar
    2: Config.CfGravity := 1.7; // Forte
    3: Config.CfGravity := 0.3; // Weak
    4: Config.CfGravity := 0;   // Zero
   end;
   // Color... processed later
   Config.CfColor := ReadInteger('BloodOptions', 'Color', 0);
   B := ReadInteger('BloodOptions', 'Speed', 1); // Speed
   case B of
    0: Config.CfSpeed := 0.5; // Weak
    1: Config.CfSpeed := 1;   // Normal
    2: Config.CfSpeed := 2;   // High
   end;
   C := ReadInteger('BloodOptions', 'Length', 1);  // Scope
   case C of
    0: Config.CfLength := 0.5; // Weak
    1: Config.CfLength := 1;   // Normal
    2: Config.CfLength := 2;   // High
   end;
   D := ReadInteger('BloodOptions', 'Size', 1); // Size
   case D of
    0: Config.CfSize := 1; // Weak
    1: Config.CfSize := 2; // Normal
    2: Config.CfSize := 3; // High
   end;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
 // OPTIONS
 GetConfig; // we retrieve the information

 DoubleBuffered := True;        // Avoids flickering
 randomize;                     // random number engine
 MaxBlood := Config.CfNbBlood;  // Number of drops
 SetLength(Blood, MaxBlood);    // The size of the drop array is fixed.
 CreateBlood(random(Screen.DesktopWidth), random(Screen.DesktopHeight)); // We create the drops!
end;

function TForm1.IsBloodOut: Boolean; // Check if all the drops are OFF
Var
 I: Integer;
begin
 Result := True; // default YES
 for I := 0 to MaxBlood - 1 do
   begin
    if PtInRect(ClientRect, Point(Round(Blood[I].X), Round(Blood[I].Y))) then
     begin
     // If only one drop is in the visible rectangle, we set False and exit.
      Result := False;
      Exit;
     end;
   end;
end;

procedure TForm1.CreateBlood(X, Y: Integer);  // We create blood
Var
 I: Integer;
begin
 for I := 0 to MaxBlood - 1 do
   begin
    // That's it... apart from the 'With' part, otherwise there's confusion
    // with X in Blood and X in the function.
    Blood[I].X := X;
    Blood[I].Y := Y;
    with Blood[I] do
     begin
      DX := (random(12) - 6) * Config.CfLength; // Calculating the X range
      DY := (random(12) - 6) * Config.CfLength; // Calculation of the Y range
      V := (random(2) + 1) * Config.CfSpeed;    // Speed ??calculation
      Size := Round((random(3) + 2) * Config.cfSize);  // Size calculation

      case Config.CfColor of   // According to color
       0: Color := rgb(random(76) + 180, 0, 0);
       1: Color := rgb(0, random(76) + 180, 0);
       2: Color := rgb(0, 0, random(76) + 180); // Various colors obtained...
       3: Color := rgb(random(76) + 180, random(76) + 180, random(76) + 180);
       4: Color := rgb(random(256), random(256), random(256));
      end;
    end;
   end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
Var
 I: Integer;
begin
 BitBlt(Image1.Canvas.Handle, 0, 0, Width, Height, Image1.Canvas.Handle, 0, 0, BLACKNESS);
 if IsBloodOut then CreateBlood(random(Width), random(Height));
 // We fill it with black!
 for I := 0 to MaxBlood - 1 do // For every drop
  begin
   Blood[I].X := Blood[I].X + (Blood[I].DX * Blood[I].V); // We calculate the evolution of its position
   Blood[I].Y := Blood[I].Y + (Blood[I].DY * Blood[I].V);
   Blood[I].DY := Blood[I].DY + Config.CfGravity;     // We fix gravity
   Image1.Canvas.Brush.Color := Blood[I].Color;
   Image1.Canvas.Pen.Color := Blood[I].Color;         // We fix its color as the canvas color
   Image1.Canvas.Ellipse(Round(Blood[I].X) - Blood[I].Size div 2,
      Round(Blood[I].Y) - Blood[I].Size div 2,
      Round(Blood[I].X) + Blood[I].Size div 2,
      Round(Blood[I].Y) + Blood[I].Size div 2);
    // We draw an ellipse!
  end;
end;

procedure TForm1.Image1Click(Sender: TObject);
begin
 Application.Terminate; // We leave
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  MakeFormFullscreenAcrossAllMonitors(Form1);
end;

procedure TForm1.FormKeyPress(Sender: TObject; var Key: Char);
begin
  Close();
end;

end.
