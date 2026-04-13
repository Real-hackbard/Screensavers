program Project1;

uses
  Forms,
  Graphics,
  SysUtils,
  Windows,
  Unit1 in 'Unit1.pas' {Form1},
  Config in 'Config.pas' {Form2};

type
 TScreenMode=(scrNormal, scrApercu, scrPreview,scrConfig); // Display type requested by Windows

var
 ScreenMode: TScreenMode;
 PreviewHandle: HWND;  // Preview window handle (in the computer image!)

{$E scr}
{$R *.res}

begin
 // Hide the application in the taskbar
 SetWindowLong(Application.Handle, GWL_EXSTYLE, WS_EX_TOOLWINDOW);
 Application.Title := ''; // No titleccvbvbCCBVCVBXCVBCDFS
 // High priority (to go faster)
 SetPriorityClass(GetCurrentProcess, HIGH_PRIORITY_CLASS);

 // Handle preview instance = 0 if there is no instance of the program!!!
 if hPrevInst = 0
  then
   begin
    Application.Initialize;

    case (paramStr(1) + ' ')[2] of
     'S' : ScreenMode := scrNormal;
     's' : ScreenMode := scrApercu;  // ScreenMode is defined based on the received parameter.
     'p' : ScreenMode := scrPreview;
     'c' : ScreenMode := scrConfig;
  else ScreenMode := scrNormal;  // If no settings are configured, normal display will be displayed.
 end;

 if not (ScreenMode = scrConfig) // If no configuration is displayed
  then
   begin
    ShowWindow(FindWindow('Shell_TrayWnd', nil), SW_HIDE);  // Hide the taskbar
  Application.CreateForm(TForm1, Form1);
  // We create the main record

    if ScreenMode = scrPreview
     then begin
     // If the handle to the small preview window is not there, we exit
      ShowWindow(FindWindow('Shell_TrayWnd', nil), SW_RESTORE);
      if ParamCount < 2
       then Application.Terminate;

  // We position our window as a child of the preview:
   PreviewHandle :=StrToInt(ParamStr(2));
   Form1.ParentWindow := PreviewHandle;
  // The property window will close the MainForm when it no longer needs to...
   end
   else
   Form1.Cursor:= -1; // Hide the cursor!

  // We enlarge the window, either to fill the entire screen or within the preview window.
  Form1.WindowState:=WSMaximized;
 end
  else begin
   // We're putting the taskbar back in place.
   ShowWindow(FindWindow('Shell_TrayWnd', nil), SW_RESTORE);
   // The configuration sheet is displayed.
  Application.CreateForm(TForm2, Form2);
  end;

  // We launch the application
  Application.Run;
  // We're putting the taskbar back.
  ShowWindow(FindWindow('Shell_TrayWnd', nil), SW_RESTORE);
 end;
end.
