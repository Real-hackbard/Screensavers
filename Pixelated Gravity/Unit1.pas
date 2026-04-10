unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, uGravityWindow;

type
  TForm1 = class(TForm)
    Timer1: TTimer;
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
  private
    FGravityWindow: TGravityWindow;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}
procedure MakeFormFullscreenAcrossAllMonitors(Form: TForm);
begin
  Form.BorderStyle := bsNone;
  Form.WindowState := wsNormal; // Make sure it is not maximized

  // Use the virtual screen boundaries
  Form.Left := 0;
  Form.Top := 0;
  Form.Width := Screen.DesktopWidth;
  Form.Height := Screen.DesktopHeight;

  // Optional: If this still doesn't take precedence over
  // everything, consider the taskbar.
  // or use Form.BringToFront.
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FGravityWindow := TGravityWindow.Create(@Form1);
  Timer1.Enabled := True;

  MakeFormFullscreenAcrossAllMonitors(Form1);
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FGravityWindow.Free;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  FGravityWindow.Resize;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  Canvas.Draw(0, 0, FGravityWindow.GetFrame);
end;

procedure TForm1.FormClick(Sender: TObject);
begin
  Close();
end;

procedure TForm1.FormKeyPress(Sender: TObject; var Key: Char);
begin
  Close();
end;

end.

