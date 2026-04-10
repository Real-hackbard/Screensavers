program Project1;

uses
  Forms,
  Windows,
  SysUtils,
  Dialogs,
  Unit1 in 'Unit1.pas' {Form1},
  config in 'config.pas' {FrmConfig};

{ Settings /S normal mode screensaver
              /s preview
              /p xxxxx  preview in the small window + preview handle
              /c:xxxxx  config + handle of the "display properties" window }

{$E SCR}
{$R *.res}

// Screensaver name declaration
{$D SCRNSAVE Ecran de veille de Maurício}

begin
  if hPrevInst = 0   // Handle preview instance = 0 if there is no instance of the program!!!
  then begin
    Application.Initialize;

    case (paramStr(1) + '  ')[2] of   
      'S' : ScreenMode := scrNormal;
      's' : ScreenMode := scrApercu;
      'p' : ScreenMode := scrPreview;
      'c' : ScreenMode := scrConfig;
      else  ScreenMode := scrNormal;
    end;

    if not (ScreenMode = scrConfig)
    then begin
      Application.CreateForm(TForm1, Form1);
  if ScreenMode = scrPreview
      then begin
        // If the handle to the small preview window is not there, we exit
        if ParamCount < 2
        then Application.Terminate;

        // We position our window as a child of the preview:
        PreviewHandle :=StrToInt(ParamStr(2));
        Form1.ParentWindow := PreviewHandle;
        // The property window will close FrmPrin when it no longer needs to. ...
      end
      else
        Form1.Cursor:= -1;  // Hide the cursor!

      // We enlarge the window, either to fill the entire screen or
      // within the preview window.
      Form1.WindowState:=WSMaximized;
    end
    else begin
      Application.CreateForm(TFrmConfig, FrmConfig);
    end;

    Application.Run;
  end;

end.
