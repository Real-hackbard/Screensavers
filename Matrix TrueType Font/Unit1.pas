unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls;

// A word is a sequence of characters that appears on the screen
type
	TMot = record
  Chaine : String;         // If the font is small, then normal chain
  Column : Integer;        // Column index on the screen
	Red, Green, Blue : Byte; // Word color
  Index : Double;          // Y coordinate of the lowest character in the word (the one that appears first on the screen)
  Length : Integer;        // Number of characters in the string
  SizeFont : Integer;      // Font size
  Speed : Double;          // Descent speed
end;

type
  TForm1 = class(TForm)
    Timer1: TTimer;
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormDestroy(Sender: TObject);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
  private
    { Declarations privates }
    List : TList;
    SavePoint : TPoint;
    NbColumns : Integer;
    NbLines : Integer;
    ArrayString : Array of String;
    procedure CreateWord;
  public
    { Declarations public }
  end;

var
  Form1: TForm1;

implementation

const
  NbMotCreate = 20; // Number of words created during Form.Create
  NbMotMax = 80;    // Maximum number of words to avoid overloading the window

{$R *.DFM}
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

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
	Close;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
	Index, Index2 : Integer;
  PMot : ^TMot;
begin
	// Each word descends (according to its speed).
	for Index := 0 to List.Count - 1 do
  begin
    PMot := List.Items[Index];
		Canvas.Font.Size := PMot.SizeFont;

    // Select TrueType Font Name
    if PMot.SizeFont = 23 then
      Font.Name := 'Impact'
    else
      Font.Name := 'Impact';

    for Index2 := 0 to PMot.Length - 1 do
    begin
      // We begin by erasing each previous character (we copy it in black).
      Canvas.Font.Color := clBlack;
      Canvas.TextOut(10 + PMot.Column * 20,
                     5 + Round((PMot.Index - PMot.Speed - Index2) * 20),
                     Copy(PMot.Chaine, Index2 + 1, 1));
      // We create a white to green gradient on the first 4 characters
      Canvas.Font.Color:= RGB(PMot.Red, PMot.Green, PMot.Blue);
      if Index2 > 4 then Canvas.Font.Color := RGB(PMot.Red, PMot.Green, PMot.Blue)
      else Canvas.Font.Color := RGB((PMot.Red + (4 - Index2) * (255 - PMot.Red) div 4),
                                    (PMot.Green + (4 - Index2) * (255 - PMot.Green) div 4),
                                    (PMot.Blue + (4 - Index2) * (255 - PMot.Blue) div 4));
      // We add the character to the screen
      Canvas.TextOut(10 + PMot.Column * 20,
                     5 + Round((PMot.Index - Index2) * 20),
                     Copy(PMot.Chaine, Index2 + 1, 1));
    end;
    PMot.Index := PMot.Index + PMot.Speed;
  end;

  // We remove words that are off-screen
	for Index := List.Count - 1 downto 0 do
  begin
    PMot := List.Items[Index];
  	if PMot.Index - PMot.Length >= NbLines then
    begin
      Dispose(List.Items[Index]);
      List.Delete(Index);
    end;
	end;

  // We limit the number of words on the screen to avoid overloading it
  if List.Count >= NbMotMax then Exit;

  // Otherwise, we add 1 word
  CreateWord;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
	Index : Integer;
begin
  MakeFormFullscreenAcrossAllMonitors(Form1);
  Randomize;
  List := TList.Create;
  //WindowState := wsMaximized;

  SavePoint.x := Mouse.CursorPos.x;
  SavePoint.y := Mouse.CursorPos.y;
  NbColumns := Round(Screen.DesktopWidth / 20);
  NbLines := Round(Screen.DesktopHeight / 20);

  Setlength(ArrayString, 5);
  ArrayString[0] := ' SU DNUORA LLA SI XIRTAM EHT';
  ArrayString[1] := ' NOISIVELET HCTAW UOY NEHW EREHT SI TI';
  ArrayString[2] := ' OEN DLROWMAERD A NI EVIL UOY';
  ArrayString[3] := ' ENO EHT SI EH';
  ArrayString[4] := ' SUEHPROM YTINIRT OEN';

  for Index := 0 to NbMotCreate - 1 do CreateWord;
end;

procedure TForm1.FormKeyPress(Sender: TObject; var Key: Char);
begin
	Close;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FreeAndNil(List);
end;

procedure TForm1.CreateWord;
var
	Index : Integer;
  PMot : ^TMot;
  ColonneTrouvee : Boolean;
  ChoixColonne : Integer;
  PMot2 : ^TMot;
  NombreTest : Integer;
begin
	// Different parameters are randomly assigned to each word
  // The different parameters are fairly self-explanatory.
  New(PMot);
  PMot.Chaine := '';

  // We are looking for an empty column
  // If we haven't found any after 10 attempts, then too bad.
	// (to avoid an infinite loop)
  NombreTest := 0;
  ColonneTrouvee := False;
  ChoixColonne := 0;
	while (not ColonneTrouvee) and (NombreTest < 10) do
  begin
    ChoixColonne := Random(NbColumns);
    Inc(NombreTest, 1);
    if List.Count = 0 then ColonneTrouvee := True;
    for Index := 0 to List.Count - 1 do
    begin
      PMot2 := List.Items[Index];
      if PMot2.Column = ChoixColonne then
      begin
        if PMot2.Index - PMot2.Length >= 1 then
        begin
  	      ColonneTrouvee := True;
	        Break;
        end
        else Break;
      end
      else if Index = List.Count - 1 then ColonneTrouvee := True;
    end;
  end;

  PMot.Column := ChoixColonne;
  PMot.Green := Random(155) + 100;
  PMot.Red := 20 + 105 * (PMot.Green - 100) div 155;
  PMot.Blue := 20 + 105 * (PMot.Green - 100) div 155;
  PMot.SizeFont := Round(9 + 4 * (PMot.Green - 100) / 155);
  PMot.Index := 0;
  PMot.Speed := Random(5) / 10 + 0.4;

  if PMot.SizeFont <> 13 then
  begin
  	if Random(2) = 0 then
    begin
		  PMot.Chaine := ArrayString[Random(5)];
		  PMot.Length := Length(PMot.Chaine);
    end
    else begin
      PMot.Length := Random(20) + 10;
      for Index := 0 to PMot.Length - 1 do
      PMot.Chaine := PMot.Chaine + Chr(97 + Random(26));
    end;
  end
  else begin
	  PMot.Length := Random(20) + 10;
	  for Index := 0 to PMot.Length - 1 do
  	PMot.Chaine := PMot.Chaine + Chr(-32 + 97 + Random(26));
  end;

  List.Add(PMot);
end;

procedure TForm1.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
	// If you move the mouse, it quits
	if (X <> SavePoint.x) or (Y <> SavePoint.y) then Close;
end;

end.
