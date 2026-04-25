Unit Utils;

Interface

Uses
  Windows, SysUtils, OpenGL;

    { Initializing/Finalizing OpenGL }
     Function InitOpenGL( DC :HDC; ColorBits :Integer;
                          DoubleBuffer :Boolean ) :Boolean;
     Procedure Terminer;


Implementation
Var
   hDCGlobal   :HDC;    {Graphical context of the window}
   GLContext   :HGLRC;  {Gateway for using OpenGL on the window}



Function InitOpenGL( DC :HDC; ColorBits :Integer;
                     DoubleBuffer :Boolean ) :Boolean;
{Objective: Initialize OpenGL under the graphical context passed as a parameter.
 Parameters:

             DC           :Graphical address of the component that is about to be
                           linked to OpenGL
             ColorBits    :Number of bits for a color
             DoubleBuffer :Enabling double buffering or not.}

Var
    PixelFormat    :TPixelFormatDescriptor; {Pixel format}
    cPixelFormat   :Integer;                {Pixel format index found}
begin
     {Pixel format index found}
     FillChar( PixelFormat, SizeOf(PixelFormat), 0 );
     With PixelFormat Do
     Begin
          nSize      := Sizeof(TPixelFormatDescriptor);
          If DoubleBuffer Then
             dwFlags    := PFD_DOUBLEBUFFER or PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL
          Else
              dwFlags    := PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL;
          iLayerType := PFD_MAIN_PLANE;
          iPixelType := PFD_TYPE_RGBA;
          nVersion   := 1;
          cColorBits := 16;
          CdepthBits := 16;
     End;

     {Retrieving the DC passed as a parameter, into a Global variable.}
     hDCGlobal := DC;

     {Selection of the appropriate pixel format for the DC received as a parameter.}
     cPixelFormat := ChoosePixelFormat(DC, @PixelFormat);

     {Check if the index of the supported pixel format has been found}
     Result := cPixelFormat <> 0;
     If Not Result Then
     Begin
          MessageBox(0, pChar(SysErrorMessage(GetLastError)),
                     'Init OpenGL', mb_OK);
          Exit;
     End;

     {Check if the pixel format found can be applied to the DC}
     Result := SetPixelFormat( DC, cPixelFormat, @PixelFormat);
     If Not Result Then
     Begin
          MessageBox(0, pChar(SysErrorMessage(GetLastError)),
                    'Init OpenGL', mb_OK);
          Exit;
     End;

     {Check if OpenGL creates the gateway that will allow it to draw
      on this DC.}
     GLContext := wglCreateContext( DC );
     Result := GLContext <> 0;
     If Not Result Then
     Begin
          MessageBox(0, pChar(SysErrorMessage(GetLastError)),
                    'Init OpenGL', mb_OK);
          Exit;
     End;

     {Check if OpenGL can use this DC for drawing.}
     Result := wglMakeCurrent( DC, GLContext );
     If Not Result Then
     Begin
          MessageBox(0, pChar(SysErrorMessage(GetLastError)),
                    'Init OpenGL', mb_OK);
          Exit;
     End;
End;

Procedure Terminer;
{Objective: To break the link with OpenGL.}
Begin
     {Removal of the link between OpenGL and our application.}
     If Not wglMakeCurrent( hDCGlobal, 0 ) Then
     Begin
          MessageBox(0, pChar(SysErrorMessage(GetLastError)),
                    'Init OpenGL', mb_OK);
          Exit;
     End;

     If Not wglDeleteContext( GLContext ) Then
     Begin
          MessageBox(0, pChar(SysErrorMessage(GetLastError)),
                    'Init OpenGL', mb_OK);
          Exit;
     End;
End;

end.
