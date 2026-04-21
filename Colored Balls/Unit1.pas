unit Unit1;

interface

uses
  Windows, OpenGLForm, OpenGL, Forms, Classes, Controls, Math, ExtCtrls;

type
  PSelection = ^TSelection;    // TSelection holds information
  TSelection = record          // from the hit record
    Names: Integer;            // The number of names in this hit
    zNear: Integer;            // Near z value
    zFar: Integer;             // Far z value
    ID: Integer;               // ID of the item picked
  end;

  TForm1 = class(TOpenGLWindow)
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormResize(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  end;

var
  q: gluQuadricObj;                   // Quadric object
  Shapes: array[0..6] of Boolean;     // Flags for each object

var
  Form1: TForm1;
  OldPos: TPoint;

implementation

{$R *.DFM}
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

procedure TForm1.FormCreate(Sender: TObject);
begin
  MakeFormFullscreenAcrossAllMonitors(Form1);
  GetCursorPos(OldPos); // Initialposition

  // Create the quadric object
  q := gluNewQuadric;

  // Enable lighting
  glEnable(GL_LIGHTING);
  glEnable(GL_LIGHT0);

  // Enable colour tracking
  glEnable(GL_COLOR_MATERIAL);                     
  glColorMaterial(GL_FRONT, GL_AMBIENT_AND_DIFFUSE);

  glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
  glShadeModel(GL_SMOOTH);
  glClearColor(0, 0, 0, 0);

  glEnable(GL_DEPTH_TEST);
  glClearDepth(1);
  glDepthFunc(GL_LESS);
end;

(*---

  RenderShapes;
  Renders the objects and sets up the name stack

---*)

procedure RenderShapes;
var
  Time: Single;
begin
  Time := GetTickCount / 300;
  glTranslatef(0, 0, -3);
  glRotatef(Time * 7.0, 1, 0, 0);
  glRotatef(Time * 8.0, 0, 1, 0);
  glRotatef(Time * 9.0, 0, 0, 1);

  glLoadName(0);
  if Shapes[0] then
    glColor3f(0.0, 0.0, 1.0) else
    glColor3f(0.0, 0.0, 0.5);
  glTranslatef(-1.0, 0.0, 0.0);
  gluSphere(q, 0.2, 16, 16);

  glLoadName(1);
  if Shapes[1] then
    glColor3f(0.0, 1.0, 0.0) else
    glColor3f(0.0, 0.5, 0.0);
  glTranslatef(2.0, 0.0, 0.0);
  gluSphere(q, 0.2, 16, 16);

  glLoadName(2);
  if Shapes[2] then
    glColor3f(0.0, 1.0, 1.0) else
    glColor3f(0.0, 0.5, 0.5);
  glTranslatef(-1.0, 0.0, 1.0);
  gluSphere(q, 0.2, 16, 16);

  glLoadName(3);
  if Shapes[3] then
    glColor3f(1.0, 1.0, 0.0) else
    glColor3f(0.5, 0.5, 0.0);
  glTranslatef(0.0, 0.0, -2.0);
  gluSphere(q, 0.2, 16, 16);

  glLoadName(4);
  if Shapes[4] then
    glColor3f(1.0, 0.5, 0.0) else
    glColor3f(0.5, 0.2, 0.0);
  glTranslatef(0.0, 1.0, 1.0);
  gluSphere(q, 0.2, 16, 16);

  glLoadName(5);
  if Shapes[5] then
    glColor3f(1.0, 0.0, 1.0) else
    glColor3f(0.5, 0.0, 0.5);
  glTranslatef(0.0, -2.0, 0.0);
  gluSphere(q, 0.2, 16, 16);

  glLoadName(6);
  if Shapes[6] then
    glColor3f(1.0, 0.0, 0.0) else
    glColor3f(0.5, 0.0, 0.0);
  glTranslatef(0.0, 1.0, 0.0);
  gluSphere(q, 0.3, 16, 16);
end;

procedure TForm1.FormPaint(Sender: TObject);
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  glLoadIdentity;
  RenderShapes;    // Render the shapes as usual
  DoSwapBuffers;
end;

(*---

  ProcessHits

  Processes the hit record
  Hits is the number of hits, as returned by glRenderMode
  Data is a pointer to the selection buffer

---*)

procedure ProcessHits(Hits: Integer; Data: PSelection);
var
  I: Integer;
  ID: Integer;                                     // Object ID
  zNear: Integer;                                  // Near z value
begin
  if (Hits = 0) then Exit;                         // Exit if the hit record is empty

  ID := Data.ID;                                   // Set up the initial object ID
  zNear := Data.zNear;                             // Set up the initial z value

  for I := 0 to Hits - 2 do begin                  // For each hit ...
    Inc(Data);                                     // Move to the next hit
    if (Data.zNear < zNear) then begin             // Test the near z value in order to find the
      ID := Data.ID;                               // hit nearest to the camera
      zNear := Data.zNear;
    end;
  end;

  Shapes[ID] := not Shapes[ID];                    // Toggle the flag corresponding to the nearest
                                                   // object.
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  if ClientHeight = 0 then ClientHeight := 1;
  glViewport(0, 0, ClientWidth, ClientHeight);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  gluPerspective(45.0, ClientWidth / ClientHeight, 0.1, 100.0);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
end;

(*---

  FormMouseDown

  Processes mouse events

---*)

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Hits: Integer;                                   // The number of hits
  Viewport: array[0..3] of Integer;                // The OpenGL viewport
  Data: array[0..2] of TSelection;                 // The selection buffer
begin
  { Use this section to Pickup Graphics with the mouse

  glGetIntegerv(GL_VIEWPORT, @Viewport);           // Get the current viewport

  glSelectBuffer(SizeOf(Data), @Data);             // Set up the selection buffer
  glRenderMode(GL_SELECT);                         // Enter selection mode

  glInitNames;                                     // Initialize the name stack
  glPushName(DWORD(-1));                           // Push a null name onto the stack

  glMatrixMode(GL_PROJECTION);                     // Set up the projection matrix
  glPushMatrix;
  glLoadIdentity;
  gluPickMatrix(X, Viewport[3] - Y, 2.0, 2.0,      // Set up a 2 pixel picking matrix
    @Viewport);
  gluPerspective(45.0, ClientWidth / ClientHeight, // Use a perspective projection
    0.1, 100.0);

  glMatrixMode(GL_MODELVIEW);                      // Reset the modelview matrix
  glLoadIdentity;
  RenderShapes;                                    // Render the scene

  glMatrixMode(GL_PROJECTION);                     // Reset the projection matrix
  glPopMatrix;

  glMatrixMode(GL_MODELVIEW);                      // Return to the modelview matrix
  Hits := glRenderMode(GL_RENDER);                 // Exit selection mode and get the number of hits
  ProcessHits(Hits, @Data);                        // Process the selection data
  }

end;

procedure TForm1.FormKeyPress(Sender: TObject; var Key: Char);
begin
  Close();
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  gluDeleteQuadric(q);                             // Delete the quadric
end;

procedure TForm1.FormClick(Sender: TObject);
begin
  Close();
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  NewPos: TPoint;
begin
  GetCursorPos(NewPos);
  if (NewPos.X <> OldPos.X) or (NewPos.Y <> OldPos.Y) then
  begin
    // Mouse moved
    Application.Terminate;
  end;
end;

end.
