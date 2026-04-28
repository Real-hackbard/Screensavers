unit RapidUI;

interface

uses
  Classes, Windows, Graphics, OpenGL, GLInit, Messages, SysUtils,Controls,

  PNGraphics, Dialogs,Forms,hyMaths,Math;
const
  BrightTrans = 140;

type
  THyPixel = record
               case Integer of
                 1:(R,G,B:Byte);
                 2:(HolePart:TColor);
              end;
  THyBorderStyle = (hbsNone,hbsRaised,hbsLowered,hbsFlat);
  TRapidProgressBarStyle=(rpgsSplit,rpgsSmooth);
  TRapidScrollBarKind = (rsbkVetical,rsbkHorizontal);
  THyPixels = array of array of TColor4ub;
  TByteArray2D = array of array of byte;
  THyTexture = Class(TObject)
  private
    FPixels : array of array of TColor4ub;
    FTextureID: GLuint;
    FHeight: Integer;
    FWidth: Integer;
    FTransparentColor: THyPixel;
    procedure SetHeight(const Value: Integer);
    procedure SetWidth(const Value: Integer);
    procedure SetTransparentColor(const Value: THyPixel);
    function GetPixel(X, Y: Integer): TColor4ub;
    procedure SetPixel(X, Y: Integer; const Value: TColor4ub);
  public
    constructor Create;
    procedure Free;
    procedure Bind;
    procedure Generate;
    procedure LoadFromFile(FileName:String);
    procedure LoadFromBitmap(Bit:TBitmap);
    procedure AddAlphaMask(aMask:TByteArray2D);
    procedure AddBrightnessMask(bMask:TByteArray2D);
    procedure SubstitueImage(nPixels:THyPixels);
    property Pixels[X,Y:Integer]:TColor4ub read GetPixel write SetPixel;
    property TextureID:GLuint read FTextureID;
    property Width:Integer read FWidth write SetWidth;
    property Height:Integer read FHeight write SetHeight;
    property TransparentColor:THyPixel read FTransparentColor
             write SetTransparentColor;
  end;

  TRapidControl = Class(TObject)
  private
    FLeft: Integer;
    FHeight: Integer;
    FTop: Integer;
    FWidth: Integer;
    FOnMouseMove: TMouseMoveEvent;
    FParent: TRapidControl;
    FFocused: Boolean;
    FVisible: Boolean;
    FEnabled: Boolean;
    FBorderWeight: Integer;
    FForeColor: TColor4ub;
    FBorderColor: TColor4ub;
    FBackColor: TColor4ub;
    FBorderStyle: THyBorderStyle;
    FOnMouseDown: TMouseEvent;
    FOnMouseUp: TMouseEvent;
    FOnClick: TNotifyEvent;
    FOnDblClick: TNotifyEvent;
    FOnMouseOut: TNotifyEvent;
    IsMouseIn : Boolean;
    FOnMouseIn: TNotifyEvent;
    FName: String;
    UIForm:TRapidControl;
    procedure SetOnMouseMove(const Value: TMouseMoveEvent);
    procedure SetParent(const Value: TRapidControl);
    function GetBrighterColor(CurColor:TColor4ub;Trans:Short):TColor4ub;
    procedure SetForeColor(const Value: TColor4ub);
  protected
    procedure MousePosition(X,Y:Integer);virtual;
    procedure DoClick;virtual;
    procedure DoDblClick; virtual;
    procedure DoMouseDown(Button: TMouseButton;Shift: TShiftState;X,Y:Integer);virtual;
    procedure DoMouseUp(Button: TMouseButton;Shift: TShiftState;X,Y:Integer);virtual;
    procedure DoKeyPress(Key:Char);virtual;
    procedure DoKeyDown(var Key: Word;Shift: TShiftState);virtual;
  public
    constructor Create;Virtual;
    procedure Free;virtual;
    property Name : String read FName write FName;
    property Enabled :Boolean read FEnabled write FEnabled;
    property Visible : Boolean read FVisible write FVisible;
    property BorderStyle:THyBorderStyle read FBorderStyle write FBorderStyle;
    property BorderWeight:Integer read FBorderWeight write FBorderWeight;
    property BorderColor : TColor4ub read FBorderColor write FBorderColor;
    property BackColor : TColor4ub read FBackColor write FBackColor;
    property ForeColor : TColor4ub read FForeColor write SetForeColor;
    property Width : Integer read FWidth write FWidth;
    property Height : Integer read FHeight write FHeight;
    property Left : Integer read FLeft write FLeft;
    property Top : Integer read FTop write FTop;
    property Parent : TRapidControl read FParent write SetParent;
    property OnClick:TNotifyEvent read FOnClick write FOnClick;
    property OnDblClick:TNotifyEvent read FOnDblClick write FOnDblClick;
    property Focused :Boolean read FFocused write FFocused;
    property OnMouseIn : TNotifyEvent read FOnMouseIn write FOnMouseIn;
    property OnMouseOut : TNotifyEvent read FOnMouseOut write FOnMouseOut;
    property OnMouseDown : TMouseEvent read FOnMouseDown write FOnMouseDown;
    property OnMouseUp : TMouseEvent read FOnMouseUp write FOnMouseUp;
    property OnMouseMove : TMouseMoveEvent read FOnMouseMove write SetOnMouseMove;
    procedure Paint(absL,absT:Integer); Virtual;
  end;

  TRapidControls = class(TObject)
  private
    FOwner:TRapidControl;
    FControls:array of TRapidControl;
    FCount: Integer;
    FInheriteStyle: Boolean;
    UIForm:TRapidControl;
    function GetControl(I: Integer): TRapidControl;
  public
    constructor Create(AOwner:TRapidControl);
    procedure Free;
    procedure FreeControls;
    procedure AddControl(nControl:TRapidControl);
    procedure RemoveControl(Name:String);overload;
    procedure RemoveControl(Index:Integer);overload;
    function NameExists(Name:String):Boolean;
    property Controls[I:Integer]:TRapidControl read GetControl;
    property Count:Integer read FCount;
    property InheriteParentSyle:Boolean read FInheriteStyle write FInheriteStyle;
  end;

  TRapidContainer = class(TRapidControl)
  protected
     FControls : TRapidControls;
    ComboDropped:Boolean;
    procedure MousePosition(X,Y:Integer);override;
    procedure DoClick;override;
    procedure DoDblClick;override;
    procedure DoMouseDown(Button: TMouseButton;Shift: TShiftState;X,Y:Integer);override;
    procedure DoMouseUp(Button: TMouseButton;Shift: TShiftState;X,Y:Integer);override;
    procedure DoKeyPress(Key:Char);override;
    procedure DoKeyDown(var Key: Word;Shift: TShiftState);override;
    procedure SetUIForm(Form:TRapidContainer);
  public
     procedure Free;override;
     procedure Paint(absL,absT:Integer);Override;
     property Controls : TRapidControls Read FControls;

  end;

  TRapidForm = class(TRapidContainer)
  private
    FClipRect: TRect;
    fFPS:TFPSCounter;
    function GetFPS: Single;
    function GetRenderSpeedString: String;
  protected
  public
    constructor Create(mForm:TForm);
    procedure ProcessMousePosition(X,Y:Integer);
    procedure ProcessClick;
    procedure ProcessDblClick;
    procedure ProcessMouseDown(Button: TMouseButton;
                               Shift: TShiftState;X,Y:Integer);
    procedure ProcessMouseUp(Button: TMouseButton;
                             Shift: TShiftState;X,Y:Integer);
    procedure ProcessKeyPress(Key:Char);
    procedure ProcessKeyDown(var Key:Word;Shift:TShiftState);
    procedure Free;override;
    procedure Paint(absL:Integer=0;absT:Integer=0);override;
    procedure BeginUIDrawing;
    procedure EndUIDrawing;
    property RenderSpeedString:String read GetRenderSpeedString;
    property FPS:Single read GetFPS;
    property ClipRect:TRect read FClipRect write FClipRect;
  end;

  TRapidLabel = class(TRapidControl)
  private

    FCaption: String;
    rpdFont:TRapidFont;
    FDrawShadow: Boolean;
    FAutoShadowColor: Boolean;
    FShadowOffset: Integer;
    FShadowColor: TColor4ub;
    FAutoSize: Boolean;
    procedure SetCaption(const Value: String);
    procedure SetFont(const Value: TFont);
    function GetRealHeight: Integer;
    function GetRealWidth: Integer;
    function GetFont: TFont;
  public
    constructor Create;override;
    procedure Free;override;
    procedure ResetText;
    function TextWidth(S:String):Integer;
    function TextHeight(S:String):Integer;
    property Caption : String read FCaption write SetCaption;
    property AutoSize:Boolean read FAutoSize write FAutoSize;
    property DrawShadow:Boolean read FDrawShadow write FDrawShadow;
    property ShadowOffset:Integer read FShadowOffset write FShadowOffset;
    property AutoShadowColor:Boolean read FAutoShadowColor write FAutoShadowColor;
    property ShadowColor:TColor4ub read FShadowColor write FShadowColor;
    property RealHeight:Integer read GetRealHeight;
    property RealWidth :Integer read GetRealWidth;
    property Font : TFont read GetFont write SetFont;
    procedure Paint(absL,absT:Integer);override;

  end;

  TRapidButton = class(TRapidControl)
  private
    FLabel:TRapidLabel;
    FAutoBorder: Boolean;
    function GetCaption: String;
    procedure SetCaption(const Value: String);
    function GetFont: TFont;
    procedure SetFont(const Value: TFont);
  protected
    procedure MousePosition(X,Y:Integer);override;
    procedure DoMouseDown(Button: TMouseButton;Shift: TShiftState;
                          X,Y:Integer);Override;
    procedure DoMouseUp(Button: TMouseButton;Shift: TShiftState;
                          X,Y:Integer);Override;
  public
    constructor Create;override;
    procedure Free;override;
    procedure Paint(absL,absT:Integer);Override;
    property AutoBorder : Boolean Read FAutoBorder write FAutoBorder;
    property Font:TFont read GetFont write SetFont;
    property Caption : String read GetCaption write SetCaption;
  end;

  TRapidCheckBox = class(TRapidControl)
  private
    FlblCheck:TRapidLabel;
    FlblCaption:TRapidLabel;
    FCheckBox : TRapidControl;
    FChecked: Boolean;
    FCheckColor: TColor4ub;
    FOnBeforeUnTicked: TNotifyEvent;
    FOnAfterTicked: TNotifyEvent;
    FTickColor: TColor4ub;
    FOnChanged: TNotifyEvent;
    function GetCaption: String;
    procedure SetCaption(const Value: String);virtual;

    procedure SetChecked(const Value: Boolean);virtual;
    function GetFont: TFont;
    procedure SetFont(const Value: TFont);
    function GetAutoShadowColor: Boolean;
    function GetDrawShadow: Boolean;
    function GetShadowColor: TColor4ub;
    function GetShadowOffset: Integer;
    procedure SetAutoShadowColor(const Value: Boolean);
    procedure SetDrawShadow(const Value: Boolean);
    procedure SetShadowColor(const Value: TColor4ub);
    procedure SetShadowOffset(const Value: Integer);
  protected
    procedure DoMouseDown(Button: TMouseButton;Shift: TShiftState;
                          X,Y:Integer);override;
  public
    constructor Create;Override;
    procedure Free;override;
    procedure Paint(absL,absT:Integer); override;
    property Checked:Boolean read FChecked write SetChecked;
    property Caption:String read GetCaption write SetCaption;
    property Font:TFont read GetFont write SetFont;
    property DrawShadow:Boolean read GetDrawShadow write SetDrawShadow;
    property AutoShadowColor:Boolean read GetAutoShadowColor write SetAutoShadowColor;
    property ShadowOffset :Integer read GetShadowOffset write SetShadowOffset;
    property ShadowColor:TColor4ub read GetShadowColor write SetShadowColor;
    property BoxColor:TColor4ub read FCheckColor write FCheckColor;
    property TickColor:TColor4ub read FTickColor write FTickColor;
    property OnAfterTicked:TNotifyEvent read FOnAfterTicked write FOnAfterTicked;
    property OnBeforeUnTicked:TNotifyEvent read FOnBeforeUnTicked write FOnBeforeUnTicked;
    property OnChanged:TNotifyEvent read FOnChanged write FOnChanged;
  end;
  TRapidRadioBox=class(TRapidCheckBox)
  private
    procedure SetCaption(const Value: String);override;
    procedure SetChecked(const Value: Boolean);override;
  protected
    procedure DoMouseDown(Button: TMouseButton;Shift: TShiftState;
                          X,Y:Integer);override;
  public
    constructor Create;override;
    procedure Paint(absL,absT:Integer);override;
  end;

  TRapidProgressBar=Class(TRapidControl)
  private
    FValue: Integer;
    FMax: Integer;
    FStyle: TRapidProgressBarStyle;
    FColor: TColor4ub;
    procedure SetValue(const Value: Integer);virtual;

  public
    constructor Create;override;
    procedure Paint(absL,absT:Integer);override;
    property ProgressColor:TColor4ub read FColor write FColor;
    property Style:TRapidProgressBarStyle read FStyle write FStyle;
    property Value:Integer read FValue write SetValue;
    property Max : Integer read FMax write FMax;
  end;

  TRapidSlideBar=class(TRapidProgressBar)
  private
    IsMouseDown:Boolean;
    FSliderSize: Integer;
    FSlide : TRapidControl;
    FBar : TRapidControl;
    FOnChanged: TNotifyEvent;
    procedure SetValue(const Value:Integer);override;
  protected
    procedure DoMouseDown(Button: TMouseButton;Shift: TShiftState;
                          X,Y:Integer);override;
    procedure DoMouseUp(Button: TMouseButton;Shift: TShiftState;
                          X,Y:Integer);override;
    procedure MousePosition(X,Y:Integer);override;

  public

    constructor Create;override;
    procedure Free;override;
    procedure Paint(absL,absT:Integer);override;
    property SliderSize:Integer read FSliderSize write FSliderSize;
    property OnChanged:TNotifyEvent read FOnChanged write FOnChanged;
  end;

  TRapidScrollBar = class(TRapidControl)
  private
    btnDec : TRapidButton;
    btnInc : TRapidButton;
    FScroll :TRapidControl;
    FValue: Integer;
    FMin: Integer;
    FButtonHeight: Integer;
    FMax: Integer;
    FOnChanged: TNotifyEvent;
    FKind: TRapidScrollBarKind;
    FScrollColor: TColor4ub;
    IsMouseDown:Boolean;
    FPageSize: Integer;
    FLargeChange: Word;
    FSmallChange: Word;
    OriMousePos:Integer;
    OriValue : Integer;
    procedure SetMax(const Value: Integer);
    procedure SetMin(const Value: Integer);
    procedure SetKind(const Value: TRapidScrollBarKind);
    procedure SetValue(const Value: Integer);
    procedure btnDecClick(Sender:TObject);
    procedure btnIncClick(Sender:TObject);
  protected
    procedure DoMouseDown(Button: TMouseButton;Shift: TShiftState;
                          X,Y:Integer);override;
    procedure DoMouseUp(Button: TMouseButton;Shift: TShiftState;
                          X,Y:Integer);override;
    procedure MousePosition(X,Y:Integer);override;
  public
    constructor Create;override;
    procedure Free;override;
    procedure Paint(absL,absT:Integer);override;
    property OnChanged:TNotifyEvent read FOnChanged write FOnChanged;
    property LargeChange:Word read FLargeChange write FLargeChange;
    property SmallChange:Word read FSmallChange write FSmallChange;
    property ScrollColor:TColor4ub read FScrollColor write FScrollColor;
    property Kind :TRapidScrollBarKind read FKind write SetKind;
    property PageSize:Integer read FPageSize write FPageSize;
    property Min:Integer read FMin write SetMin;
    property Max:Integer read FMax write SetMax;
    property Value:Integer read FValue write SetValue;
    property ButtonHeight:Integer read FButtonHeight write FButtonHeight;

  end;

  TRapidListBox=Class(TRapidControl)
  private
    FItems: TStringList;
    FScroll:TRapidScrollBar;
    FLabels:Array of TRapidLabel;
    FLineHeight: Integer;
    FFont: TFont;
    curMouseIdx:Integer;
    SelectedIdx:Integer;
    FDrawHighLight: Boolean;
    FHighLightColor: TColor4ub;
    FSelectedColor: TColor4ub;
    FOnChanged: TNotifyEvent;
    FOnItemMouseDown: TNotifyEvent;
    procedure SetFont(const Value: TFont);
    function GetCount: Integer;
  protected
    procedure DoMouseDown(Button: TMouseButton;Shift: TShiftState;
                          X,Y:Integer);override;
    procedure DoMouseUp(Button: TMouseButton;Shift: TShiftState;
                          X,Y:Integer);override;
    procedure MousePosition(X,Y:Integer);override;
  public
    constructor Create;override;
    procedure Free;override;
    procedure Refresh;
    procedure Paint(absL,absT:Integer);override;
    procedure AddItem(s:String);
    procedure RemoveItem(Index:Integer);
    function HitTest(X,Y:Integer):Integer;
    property HighLightColor:TColor4ub read FHighLightColor write FHighLightColor;
    property SelectedColor:TColor4ub read FSelectedColor write FSelectedColor;
    property DrawHighLight :Boolean read FDrawHighLight write FDrawHighLight;
    property Items:TStringList read FItems write FItems;
    property SelectedIndex:Integer read SelectedIdx write SelectedIdx;
    property Font : TFont read FFont write SetFont;
    property LineHeight :Integer read FLineHeight;
    property Count:Integer read GetCount;
    property OnChanged:TNotifyEvent read FOnChanged write FOnChanged;
    property OnItemMouseDown:TNotifyEvent read FOnItemMouseDown write FOnItemMouseDown;
  end;

  TRapidComboBox=class(TRapidControl)
  private
    FList:TRapidListBox;
    FButton:TRapidButton;
    FShowList:Boolean;
    FMaxListLength: Integer;
    FButtonBackColor: TColor4ub;
    FButtonBorderStyle: THyBorderStyle;
    FButtonBorderColor: TColor4ub;
    FListColor: TColor4ub;
    FOnChanged: TNotifyEvent;
    FButtonForeColor: TColor4ub;
    FOnListPopup: TNotifyEvent;
    FOnListHangOn: TNotifyEvent;
    function GetCount: Integer;
    function GetDrawHighLight: Boolean;
    function GetFont: TFont;
    function GetHighLightColor: TColor4ub;
    function GetIndex: Integer;
    function GetItems: TStringList;
    function GetLineHeight: Integer;
    function GetSelectedColor: TColor4ub;
    function GetText: String;
    procedure SetDrawHighLight(const Value: Boolean);
    procedure SetFont(const Value: TFont);
    procedure SetHighLightColor(const Value: TColor4ub);
    procedure SetIndex(const Value: Integer);
    procedure SetItems(const Value: TStringList);
    procedure SetSelectedColor(const Value: TColor4ub);
    procedure DoChanged(Sender:TObject);
    procedure ListItemMouseDown(Sender:TObject);
    procedure SetShowList(const Value: Boolean);
  protected
    procedure DoMouseDown(Button: TMouseButton;Shift: TShiftState;
                          X,Y:Integer);override;
    procedure DoMouseUp(Button: TMouseButton;Shift: TShiftState;
                          X,Y:Integer);override;
    procedure MousePosition(X,Y:Integer);override;
  public
    constructor Create;override;
    procedure Free;override;
    procedure Paint(absL,absT:Integer);override;
    procedure PaintList(absL,absT:Integer);
    procedure Refresh;
    procedure AddItem(s:String);
    procedure RemoveItem(Index:Integer);
    procedure PopList;
    property Text:String read GetText;
    property ItemIndex:Integer read GetIndex write SetIndex;
    property Count:Integer read GetCount;
    property ButtonBackColor:TColor4ub read FButtonBackColor write FButtonBackColor;
    property ButtonBorderStyle:THyBorderStyle read FButtonBorderStyle write FButtonBorderStyle;
    property ButtonBorderColor:TColor4ub read FButtonBorderColor write FButtonBorderColor;
    property ButtonForeColor:TColor4ub read FButtonForeColor write FButtonForeColor;
    property ListColor : TColor4ub read FListColor write FListColor;
    property HighLightColor:TColor4ub read GetHighLightColor write SetHighLightColor;
    property SelectedColor:TColor4ub read GetSelectedColor write SetSelectedColor;
    property ShowList:Boolean read FShowList write SetShowList;
    property DrawHighLight :Boolean read GetDrawHighLight write SetDrawHighLight;
    property Items:TStringList read GetItems write SetItems;
    property Font : TFont read GetFont write SetFont;
    property MaxListLength:Integer read FMaxListLength write FMaxListLength;
    property LineHeight :Integer read GetLineHeight;
    property OnChanged:TNotifyEvent read FOnChanged write FOnChanged;
    property OnListPopup:TNotifyEvent read FOnListPopup write FOnListPopup;
    property OnListHangOn:TNotifyEvent read FOnListHangOn write FOnListHangOn;

  end;

  TRapidInputBox = Class(TRapidControl)
  private
    lblText:TRapidLabel;
    lstSPos:Integer;
    FLocked: Boolean;
    FSelCount: Integer;
    FSelStart: Integer;
    FPos: Integer;
    IsMouseDown:Boolean;
    OriX,OriY:Integer;
    OriPos:Integer;
    FText: String;
    Frames:Integer;
    FOnChanged: TNotifyEvent;
    function GetFont: TFont;
    procedure SetFont(const Value: TFont);
    procedure SetText(const Value: String);
    function GetPosAtPoint(X, Y: Integer): Integer;
  protected
    procedure DoKeyPress(Key:char);override;
    procedure DoKeyDown(var Key:Word;Shift:TShiftState);override;
    procedure DoMouseDown(Button: TMouseButton;Shift: TShiftState;
                          X,Y:Integer);override;
    procedure DoMouseUp(Button: TMouseButton;Shift: TShiftState;
                          X,Y:Integer);override;
    procedure MousePosition(X,Y:Integer);override;
  public
    constructor Create;override;
    procedure Free;override;
    procedure Paint(absL,absT:Integer);override;
    property OnChanged:TNotifyEvent read FOnChanged write FOnChanged;
    property Text:String read FText write SetText;
    property CursorPos:Integer read FPos write FPos;
    property SelStart:Integer read FSelStart write FSelStart;
    property SelCount:Integer read FSelCount write FSelCount;
    property Locked :Boolean read FLocked write FLocked;
    property Font :TFont read GetFont write SetFont;
  end;
implementation

function CalcTextureSize(aW: Integer): Integer;
begin
  if aw>512 then
    result:=1024
  else
  begin
    if aw>256 then
      result:=512
    else
    begin
      if aw>128 then
        result:=256
      else
      begin
        if aw>64 then
          result:=128
        else
        begin
          if aw>32 then
             result:=64
          else
          begin
            if aw>16 then
              result:=32
            else
              result:=16;
          end;
        end;
      end;
    end;
  end;
end;

procedure GLDrawQuads(Color:TColor4ub;X1,X2,Y1,Y2:Integer);
begin
  glColor4ub(Color.R,Color.G,Color.B,Color.A);
  glBegin(GL_QUADS);
    glVertex2i(X1,Y1);
    glVertex2i(X2,Y1);
    glVertex2i(X2,Y2);
    glVertex2i(X1,Y2);
  glEnd;
end;

procedure GLDrawCircle(BorderColor:TColor4ub;FillColor:TColor4ub;X,Y:Integer;
                       BorderWidth:Integer;R:Integer);
var SinRs,CosRs:Single; i:Integer;  stepL:Single;
begin
  StepL := 2*Pi / (r*4);
  glColor4ub(BorderColor.R,BorderColor.G,BorderColor.B,BorderColor.A);
  glBegin(GL_TRIANGLE_FAN);
    glVertex2f(X,Y);
    for i := 0 to r*4 do
    begin
      CosRs := Cos(i*StepL);
      SinRs := Sin(i*StepL);
      glVertex2f(X+CosRs*R,Y+SinRs*R);
    end;
  glEnd;
  glColor4ub(FillColor.R,FillColor.G,FillColor.B,FillColor.A);
  glBegin(GL_TRIANGLE_FAN);
    glVertex2f(X,Y);
    for i := 0 to r do
    begin
      CosRs := Cos(i*StepL);
      SinRs := Sin(i*StepL);
      glVertex2f(X+CosRs*(R-BorderWidth),Y+SinRs*(R-BorderWidth));
    end;
  glEnd;
end;
{ TRapidControl }

constructor TRapidControl.Create;
begin
  FParent := nil;
  FBorderWeight:=1;
  FBorderStyle := hbsFlat;
  FBorderColor := Color4ub(250,250,250,255);
  FBackColor := Color4ub(50,50,50,255);
  FForeColor := Color4ub(250,250,250,255);
  FEnabled := True;
  FVisible := True;
  FFocused:=False;
  FLeft:=0;
  FTop := 0;
  FHeight:=0;
  FWidth :=0;
  IsMouseIn := False;
end;

procedure TRapidControl.DoClick;
begin
  if FEnabled and FVisible then
  if IsMouseIn and Assigned(FOnClick) then
    FOnClick(Self);
end;

procedure TRapidControl.DoDblClick;
begin
  if FEnabled and FVisible then
  if IsMouseIn and Assigned(FOnDblClick) then
    FOnDblClick(Self);
end;

procedure TRapidControl.DoKeyDown(var Key: Word; Shift: TShiftState);
begin

end;

procedure TRapidControl.DoKeyPress(Key: Char);
begin
end;

procedure TRapidControl.DoMouseDown(Button: TMouseButton;Shift: TShiftState;
                                    X,Y:Integer);
begin
  if FEnabled and FVisible then
  if IsMouseIn then
  begin
    if Assigned(FOnMouseDown) then
      FOnMouseDown(Self,Button,Shift,X-FLeft,Y-FTop);
  end;
end;

procedure TRapidControl.DoMouseUp(Button: TMouseButton;Shift: TShiftState;
                                  X,Y:Integer);
begin
  if FEnabled and FVisible then
  if IsMouseIn then
  begin
    if Assigned(FOnMouseUp) then
       FOnMouseUp(Self,Button,Shift,X-Fleft,Y-FTop);
    if Assigned(FOnClick) then
       FOnClick(Self);
  end;

end;



procedure TRapidControl.Free;
begin

end;

function TRapidControl.GetBrighterColor(CurColor: TColor4ub;
  Trans: Short):TColor4ub;
begin
  Result.A := CurColor.A;
  if Trans>0 then
  begin
    if CurColor.R + Trans>255 then
      Result.R := 255
    else
      Result.R := CurColor.R+Trans;

    if CurColor.G + Trans>255 then
      Result.G := 255
    else
      Result.G := CurColor.G+Trans;

    if CurColor.B + Trans>255 then
      Result.B := 255
    else
      Result.B := CurColor.B+Trans;
  end
  else
  begin
    if CurColor.R + Trans<0 then
      Result.R := 0
    else
      Result.R := CurColor.R+Trans;

    if CurColor.G + Trans<0 then
      Result.G := 0
    else
      Result.G := CurColor.G+Trans;

    if CurColor.G + Trans<0 then
      Result.B := 0
    else
      Result.B := CurColor.B+Trans;
  end;
end;

procedure TRapidControl.MousePosition(X, Y: Integer);
var lstMouseIn:Boolean;
begin
  lstMouseIn:=IsMouseIn;
  if FEnabled and FVisible then
  if (X>FLeft) and (X<FLeft+FWidth) and (Y>FTop) and (Y<FTop+FHeight) then
  begin
    IsMouseIn := True;
    if Assigned(FOnMouseIn) and Not(lstMouseIn) then
      FOnMouseIn(self);
    if assigned(FOnMouseMove) then
      FOnMouseMove(self,[],X-FLeft,Y-FTop);
    
  end
  else
  begin
    if IsMouseIn then
    begin
      IsMouseIn := False;
      if Assigned(FOnMouseOut) then
        FOnMouseOut(self);
    end;
  end;
end;

procedure TRapidControl.Paint(absL,absT:Integer);
var bdColor:TColor4ub;
begin
  //Draw Plane:
  if not FVisible then exit;
  glBegin(GL_QUADS);
    glColor4ub(FBackColor.R,FBackColor.G,FBackColor.B,FBackColor.A);
    glVertex2i(absL,absT);
    glVertex2i(absL+FWidth,absT);
    glVertex2i(absL+FWidth,absT+FHeight);
    glVertex2i(absL,absT+FHeight);
  glEnd;

  //Draw Border:
  glLineWidth(FBorderWeight);

    if FBorderStyle = hbsRaised then
    begin
      bdColor := GetBrighterColor(FBorderColor,BrightTrans);
      glColor4ub(bdColor.R,bdColor.G,bdColor.B,bdColor.A);
      glBegin(GL_LINES);
        glColor4ub(bdColor.R,bdColor.G,bdColor.B,bdColor.A);
        glVertex2i(absL,absT);
        glVertex2i(absL,absT+FHeight);

        glVertex2i(absL,absT);
        glVertex2i(absL+FWidth,absT);
      glEnd;

      bdColor := GetBrighterColor(FBorderColor,-BrightTrans);
      glColor4ub(bdColor.R,bdColor.G,bdColor.B,bdColor.A);
      glBegin(GL_LINES);
        glColor4ub(bdColor.R,bdColor.G,bdColor.B,bdColor.A);
        glVertex2i(absL,absT+FHeight);
        glVertex2i(absL+FWidth,absT+FHeight);

        glVertex2i(absL+FWidth,absT);
        glVertex2i(absL+FWidth,absT+FHeight);
      glEnd;
    end
    else if FBorderStyle = hbsLowered then
    begin
      bdColor := GetBrighterColor(FBorderColor,-BrightTrans);
      glColor4ub(bdColor.R,bdColor.G,bdColor.B,bdColor.A);
      glBegin(GL_LINES);
        glVertex2i(absL,absT);
        glVertex2i(absL,absT+FHeight);

        glVertex2i(absL,absT);
        glVertex2i(absL+FWidth,absT);
      glEnd;

      bdColor := GetBrighterColor(FBorderColor,BrightTrans);
      glColor4ub(bdColor.R,bdColor.G,bdColor.B,bdColor.A);
      glBegin(GL_LINES);
        glVertex2i(absL,absT+FHeight);
        glVertex2i(absL+FWidth,absT+FHeight);

        glVertex2i(absL+FWidth,absT);
        glVertex2i(absL+FWidth,absT+FHeight);
      glEnd;
    end
    else if FBorderStyle = hbsFlat then
    begin
      bdColor := GetBrighterColor(FBorderColor,0);
      glColor4ub(bdColor.R,bdColor.G,bdColor.B,bdColor.A);
      glBegin(GL_LINES);
        glVertex2i(absL,absT);
        glVertex2i(absL,absT+FHeight);

        glVertex2i(absL,absT);
        glVertex2i(absL+FWidth,absT);
      glEnd;

      glBegin(GL_LINES);
        glVertex2i(absL,absT+FHeight);
        glVertex2i(absL+FWidth,absT+FHeight);

        glVertex2i(absL+FWidth,absT);
        glVertex2i(absL+FWidth,absT+FHeight);
      glEnd;
    end;

end;

procedure TRapidControl.SetForeColor(const Value: TColor4ub);
begin
  FForeColor := Value;
end;

procedure TRapidControl.SetOnMouseMove(const Value: TMouseMoveEvent);
begin
  FOnMouseMove := Value;
end;

procedure TRapidControl.SetParent(const Value: TRapidControl);
begin
  FParent := Value;
end;

{ TRapidContainer }
procedure TRapidContainer.DoClick;
var i:Integer;
begin
  inherited;
  if IsMouseIn then
  for i := 0 to FControls.Count-1 do
  begin
    FControls.Controls[i].DoClick;
  end;
end;

procedure TRapidContainer.DoDblClick;
var i:Integer;
begin
  inherited;
  if IsMouseIn then
  for i := 0 to FControls.Count-1 do
  begin
    FControls.Controls[i].DoDblClick;
  end;
end;

procedure TRapidContainer.DoKeyDown(var Key: Word; Shift: TShiftState);
var i:Integer;
begin
  inherited;
  if FFocused then
  for i := 0 to FControls.Count-1 do
  begin
    FControls.Controls[i].DoKeyDown(Key,Shift);
  end;
end;

procedure TRapidContainer.DoKeyPress(Key: Char);
var i:Integer;
begin
  inherited;
  if FFocused then
  for i := 0 to FControls.Count-1 do
  begin
    FControls.Controls[i].DoKeyPress(Key);
  end;
end;

procedure TRapidContainer.DoMouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var i:Integer;
begin
  inherited;
  if IsMouseIn then
  begin
    FFocused:=True;
    for i := 0 to FControls.Count-1 do
    begin
      if ComboDropped and (not (FControls.Controls[i] is TRapidComboBox)) then
        Continue;
      FControls.Controls[i].Focused := FControls.Controls[i].IsMouseIn; 
      FControls.Controls[i].DoMouseDown(Button,Shift,X-FLeft,Y-FTop);
    end;
  end;
end;

procedure TRapidContainer.DoMouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var i:Integer;
begin
  inherited;
  if IsMouseIn then
  for i := 0 to FControls.Count-1 do
  begin
    FControls.Controls[i].DoMouseUp(Button,Shift,X-FLeft,Y-FTop);
  end;
end;

procedure TRapidContainer.Free;
begin
  FControls.FreeControls;
  FControls.Free;
end;

procedure TRapidContainer.MousePosition(X, Y: Integer);
var i:Integer;
begin
  inherited;
  if IsMouseIn then
  for i := 0 to FControls.Count-1 do
  begin
    FControls.Controls[i].MousePosition(X-FLeft,Y-FTop);
  end;
end;

procedure TRapidContainer.Paint(absL,absT:Integer);
var i:Integer;
begin
  if not Visible then exit;
  inherited Paint(absL,absT);
  for i := 0 to FControls.Count -1 do
  begin
    with FControls.Controls[i] do
    begin
      Paint(absL+Left,absT+Top);
    end;
  end;
  for i := 0 to FControls.Count -1 do
  begin
    with FControls.Controls[i] do
    begin
      if FControls.Controls[i] is TRapidComboBox then
      (FControls.Controls[i] as TRapidComboBox).PaintList(absL+Left,absT+Top); 
    end;
  end;
end;

procedure TRapidContainer.SetUIForm(Form: TRapidContainer);
var i:Integer;
begin
  UIForm:=Form;
  for i := 0 to FControls.Count-1 do
  begin
    FControls.Controls[i].UIForm:=Form;
  end;
end;

{ TRapidControls }
procedure TRapidControls.AddControl(nControl: TRapidControl);
begin
  Inc(FCount);
  SetLength(FControls,FCount);
  nControl.Parent := FOwner;
  FControls[FCount-1] := nControl;
  nControl.Name := Copy(nControl.ClassName,2,Length(nControl.ClassName)-1)+
                   IntToStr(FCount-1);
  nControl.UIForm := UIForm;
  if FInheriteStyle then
  With FControls[FCount-1] do
  begin
    BorderStyle := FOwner.BorderStyle;
    BorderColor := FOwner.BorderColor;
    ForeColor := FOwner.ForeColor;
    BackColor := FOwner.BackColor;
    BorderWeight := FOwner.BorderWeight;
  end;
end;

constructor TRapidControls.Create(AOwner:TRapidControl);
begin
  FOwner:= AOwner;
  FCount := 0;
end;

procedure TRapidControls.Free;
begin
  SetLength(FControls,0);
end;

procedure TRapidControls.FreeControls;
var i :Integer;
begin
  for i := 0 to FCount-1 do
  begin
    FControls[i].Free;
  end;
  FCount := 0;
  SetLength(FControls,0);
end;

function TRapidControls.GetControl(I: Integer): TRapidControl;
begin
  Result := FControls[I];
end;

function TRapidControls.NameExists(Name: String): Boolean;
var i:Integer;
begin
  Result := False;
  for i:= 0 to FCount-1 do
  begin
    if UpperCase(FControls[i].Name)=UpperCase(Name) then
    begin
      Result := True;
      exit;
    end;
  end;
end;

procedure TRapidControls.RemoveControl(Index: Integer);
var i:Integer;
begin
  if Index<0 then
  begin
    ShowMessage('Error');
    Exit;
  end;
  if Index>FCount-1 then
  begin
    ShowMessage('Error');
    Exit;
  end;
  FControls[Index].Free;
  FControls[Index] := nil;
  for i := Index to FCount -1 do
  begin
    FControls[i] := FControls[i+1];
  end;

  SetLength(FControls,FCount-1);
  FCount := FCount-1;
end;

procedure TRapidControls.RemoveControl(Name: String);
var i :Integer; 
begin
  Name := Uppercase(Name);
  for i := 0 to FCount-1 do
  begin
    if Uppercase(FControls[i].Name)=Name then
    begin
      RemoveControl(i);
      exit;
    end;
  end;
end;

{ TRapidForm }

procedure TRapidForm.BeginUIDrawing;
var ViewPort : array[0..3] of Integer;
begin
  glPushAttrib(GL_ALL_ATTRIB_BITS);
  glDisable(GL_CULL_FACE);
  glDisable(GL_DEPTH_TEST);
  glDisable(GL_LIGHTING);
  glDisable(GL_FOG);

  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
  glMatrixMode(GL_PROJECTION);
    glPushMatrix;
    glLoadIdentity;
    glGetIntegerv(GL_VIEWPORT,@ViewPort);
    glOrtho(ViewPort[0],ViewPort[2],ViewPort[3],ViewPort[1],1,-1);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
end;

constructor TRapidForm.Create(mForm:TForm);
begin
  inherited Create;
  TRapidControl(self).Create;
  FClipRect := mForm.ClientRect;
  BorderStyle := hbsNone;
  BackColor := Color4ub(100,100,100,200);
  ForeColor := Color4ub(222,222,222,200);
  FControls:=TRapidControls.Create(Self);
  Height := FClipRect.Bottom;
  Width := FClipRect.Right;
  FControls.UIForm:=Self;
  fFPS:=TFPSCounter.Create;
end;

procedure TRapidForm.EndUIDrawing;
begin
  glPopAttrib;
  glMatrixMode(GL_PROJECTION);
    glPopMatrix;
  glMatrixMode(GL_MODELVIEW);
  fFPS.FinishRender;
end;


procedure TRapidForm.Free;
begin
  inherited;
  fFPS.Free;
end;

function TRapidForm.GetFPS: Single;
begin
  result := fFPS.FPS;
end;

function TRapidForm.GetRenderSpeedString: String;
begin
  Result:=FFPs.Speed;
end;

procedure TRapidForm.Paint(absL:Integer=0;absT:Integer=0);
begin
  inherited;
end;

procedure TRapidForm.ProcessClick;
begin
  DoClick;
end;

procedure TRapidForm.ProcessDblClick;
begin
  DoDblClick;
end;

procedure TRapidForm.ProcessKeyDown(var Key: Word; Shift: TShiftState);
begin
  DoKeyDown(Key,Shift);
end;

procedure TRapidForm.ProcessKeyPress(Key: Char);
begin
  DoKeyPress(Key);
end;

procedure TRapidForm.ProcessMouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  DoMouseDown(Button,Shift,X,Y);
end;

procedure TRapidForm.ProcessMousePosition(X, Y: Integer);
begin
  MousePosition(X,Y);
end;

procedure TRapidForm.ProcessMouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  DoMouseUp(Button,Shift,X,Y);
end;

{ TRapidLabel }

constructor TRapidLabel.Create();
begin
  Inherited Create;
  rpdFont := TRapidFont.Create;
  Font.Name := 'Verdana';
  Font.Color := RGB(127,127,127);
  Font.Size := 9;
  FBackColor.A := 0;
  FForeColor := Color4UB(255,255,255,200);
  FBorderStyle := hbsNone;
  DrawShadow:=True;
  ShadowOffset := 1;
  AutoShadowColor:=True;
  FAutoSize:=True;
end;

procedure TRapidLabel.Free;
begin
  rpdFont.Free;
end;

function TRapidLabel.GetFont: TFont;
begin
  result := rpdFont.Font;
end;

function TRapidLabel.GetRealHeight: Integer;
begin
  Result := rpdFont.RealHeight;
end;

function TRapidLabel.GetRealWidth: Integer;
begin
  Result := rpdFont.RealWidth;
end;

procedure TRapidLabel.Paint(absL,absT:Integer);
begin
  inherited;
  if FVisible then
  begin
    if FDrawShadow then
    begin
      if FAutoShadowColor then
      begin
        FShadowColor:=GetBrighterColor(FForeColor,-255);
        FShadowColor.A := (FForeColor.R+FForeColor.G+FForeColor.B)div 3;
      end;
      rpdFont.FontColor := FShadowColor;
      rpdFont.TextOut(absL+FShadowOffset,absT+FShadowOffset);
    end;
    rpdFont.FontColor := FForeColor;
    rpdFont.TextOut(absL,absT);
  end;
end;

procedure TRapidLabel.ResetText;
begin
  SetCaption(FCaption);
end;

procedure TRapidLabel.SetCaption(const Value: String);
begin
  FCaption := Value;
  if Not FAutoSize then
  begin
    rpdFont.ClipText := True;
    rpdFont.ClipHeight := FHeight;
    rpdFont.ClipWidth := FWidth;
  end
  else
  begin
    rpdFont.ClipText := False;
  end;
  rpdFont.Text := FCaption;
end;

procedure TRapidLabel.SetFont(const Value: TFont);
begin
  rpdFont.Font := Value;
end;

function TRapidLabel.TextHeight(S: String): Integer;
begin
  Result:=rpdFont.TextHeight(S); 
end;

function TRapidLabel.TextWidth(S: String): Integer;
begin
  Result:=rpdFont.TextWidth(S); 
end;

{ TRapidButton }

constructor TRapidButton.Create;
begin
  Inherited;
  FLabel:=TRapidLabel.Create;
  FBorderStyle := hbsRaised;
  FBackColor := Color4ub(200,200,200,220);
  FForeColor := Color4ub(0,0,0,220);
  FBorderColor := FBackColor;
  FAutoBorder:=True;
  FLabel.AutoSize := False;
end;

procedure TRapidButton.DoMouseDown(Button: TMouseButton;Shift: TShiftState;
  X,Y:Integer);
begin
  inherited;
  if FEnabled and FVisible then
  If IsMouseIn and FAutoBorder then
  FBorderStyle := hbsLowered;
end;

procedure TRapidButton.DoMouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  if FAutoBorder then
  FBorderStyle := hbsRaised;
  inherited;
end;

procedure TRapidButton.Free;
begin
  FLabel.Free;
end;

function TRapidButton.GetCaption: String;
begin
  result := FLabel.Caption;
end;

function TRapidButton.GetFont: TFont;
begin
  Result := FLabel.Font;
end;

procedure TRapidButton.MousePosition(X, Y: Integer);
var lstMouseIn :Boolean;
begin
  lstMouseIn := IsMouseIn;
  inherited;
  if lstMouseIn and not IsMouseIn then
  begin
    if FAutoBorder then
    FBorderStyle := hbsRaised;
  end;
end;

procedure TRapidButton.Paint(absL,absT:Integer);
var dX,dy:Integer;
begin
  inherited;
  dX:= (FWidth - FLabel.RealWidth) div 2 ;
  dY:= (FHeight - FLabel.RealHeight) div 2;
  if dx<1 then dx:=1;
  FLabel.BorderStyle := hbsNone;
  FLabel.ForeColor := FForeColor;
  if FEnabled then
  begin
    FLabel.DrawShadow := False;
  end
  else
  begin
    if FAutoBorder then
    FBorderStyle := hbsRaised;
    FLabel.DrawShadow := True;
    FLabel.ShadowColor := GetBrighterColor(FForeColor,255);
    FLabel.ForeColor := GetBrighterColor(FForeColor,127);
    FLabel.AutoShadowColor := False;
  end;
  if FBorderStyle = hbsLowered then
  begin
    dX := dX + 1;
    dY := dY +1;
  end;
  FLabel.Paint(absL+dx,absT+dY);
end;

procedure TRapidButton.SetCaption(const Value: String);
begin
  FLabel.Height := FHeight;
  FLabel.Width := FWidth-2;
  FLabel.Caption := Value;
end;

procedure TRapidButton.SetFont(const Value: TFont);
begin
  FLabel.Font := Value;
end;

{ TRapidCheckBox }

constructor TRapidCheckBox.Create;
begin
  inherited;
  FBorderStyle := hbsLowered;
  FCheckColor := Color4UB(230,230,230,230);
  
  FForeColor := Color4ub(0,0,0,220);
  FlblCheck := TRapidLabel.Create;
  FlblCaption := TRapidLabel.Create;
  FCheckBox := TRapidControl.Create;
  FTickColor := FForeColor;
  FTickColor.A := 0;
  FlblCheck.Font.Name := 'Wingdings 2';
end;

procedure TRapidCheckBox.DoMouseDown(Button: TMouseButton;Shift: TShiftState;
                          X,Y:Integer);
begin
  inherited;
  if FEnabled and FVisible then
  if IsMouseIn then
  begin
    Checked := Not FChecked;
  end;
end;

procedure TRapidCheckBox.Free;
begin
  FlblCheck.Free;
  FlblCaption.Free;
  FCheckBox.Free;
end;
function TRapidCheckBox.GetAutoShadowColor: Boolean;
begin
  result := FlblCaption.AutoShadowColor;
end;

function TRapidCheckBox.GetCaption: String;
begin
  result := FlblCaption.Caption;
end;

function TRapidCheckBox.GetDrawShadow: Boolean;
begin
  result := FlblCaption.DrawShadow;
end;

function TRapidCheckBox.GetFont: TFont;
begin
  Result := FLblCaption.Font;
end;

function TRapidCheckBox.GetShadowColor: TColor4ub;
begin
  result := FlblCaption.ShadowColor;
end;

function TRapidCheckBox.GetShadowOffset: Integer;
begin
  result := FlblCaption.ShadowOffset;
end;

procedure TRapidCheckBox.Paint(absL, absT: Integer);
begin
  if FLblCheck.Font.Size+6 <> FlblCaption.Font.Size then
  begin
    FlblCheck.Font.Size := FlblCaption.Font.Size+6;
    FlblCheck.ResetText;
  end;
  FlblCheck.ForeColor := FTickColor;
  FlblCaption.ForeColor := FForeColor;
  FCheckBox.BackColor := FCheckColor;
  FCheckBox.BorderStyle := FBorderStyle;
  FCheckBox.BorderWeight := FBorderWeight;
  FCheckBox.BorderColor := FBorderColor;
  FCheckBox.Height := FlblCaption.RealHeight;
  FCheckBox.Width :=FCheckBox.Height;
  FCheckBox.Paint(absL,absT);
  FlblCheck.Paint(absL,absT-FlblCheck.RealHeight div 7);
  FlblCaption.Paint(absL+FCheckBox.Width + FCheckBox.Width div 2,absT);
end;

procedure TRapidCheckBox.SetAutoShadowColor(const Value: Boolean);
begin
  FlblCaption.AutoShadowColor := Value;
end;

procedure TRapidCheckBox.SetCaption(const Value: String);
begin
  FlblCheck.Caption :='P'; //Symbol of tick in font "Wingdings 2"
  FlblCaption.Caption:=Value;
  FHeight := FlblCaption.RealHeight;
  FWidth := FlblCaption.RealWidth + FlblCheck.RealWidth + 5;
end;

procedure TRapidCheckBox.SetChecked(const Value: Boolean);
var Changed:Boolean;
begin
  if FChecked<>Value then
    Changed:=True
  else
    Changed:=False;
  FChecked := Value;
  if Changed then
    if Assigned(FOnChanged) then
      FOnChanged(Self);
  if FChecked then
  begin
    FTickColor.A := 220;
    if Assigned(FOnAfterTicked) then
      FOnAfterTicked(Self);
  end
  else
  begin
    FTickColor.A := 0;
    if Assigned(FOnBeforeUnTicked) then
      FOnBeforeUnTicked(Self);
  end;
end;

procedure TRapidCheckBox.SetDrawShadow(const Value: Boolean);
begin
  FlblCaption.DrawShadow := Value;
end;

procedure TRapidCheckBox.SetFont(const Value: TFont);
begin
  FlblCheck.Font.Name := 'Wingdings 2';
  FlblCaption.Font := Value;
end;

procedure TRapidCheckBox.SetShadowColor(const Value: TColor4ub);
begin
  FlblCaption.ShadowColor := Value;
end;

procedure TRapidCheckBox.SetShadowOffset(const Value: Integer);
begin
  FlblCaption.ShadowOffset := Value;
end;

{ TRapidRadioBox }

constructor TRapidRadioBox.Create;
begin
  inherited;
  FCheckBox.Visible := False;
  FlblCheck.Visible := False;
end;

procedure TRapidRadioBox.DoMouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if FEnabled and FVisible then
  if IsMouseIn then
  begin
    Checked := True;
  end;
end;

procedure TRapidRadioBox.Paint(absL, absT: Integer);
begin
  GLDrawCircle(FBorderColor,FCheckColor,absL+FHeight div 2,absT+FHeight div 2,
               2,FHeight Div 2);
  GLDrawCircle(FTickColor,FTickColor,absL+FHeight div 2,absT+FHeight div 2,
               0,FHeight Div 3);
  inherited;

end;

procedure TRapidRadioBox.SetCaption(const Value: String);
begin
  FlblCheck.Caption :=char(151); //Symbol of Circle in font "Wingdings 2"
  FlblCaption.Caption:=Value;
  FHeight := FlblCaption.RealHeight;
  FWidth := FlblCaption.RealWidth + FlblCheck.RealWidth + 5;
end;

procedure TRapidRadioBox.SetChecked(const Value: Boolean);
var i:Integer; pr:TRapidContainer;
begin
  inherited;
  pr := FParent as TRapidContainer;
  if pr<>nil then
  if Value then
  begin
    for i:= 0 to pr.Controls.Count -1 do
    begin
      if pr.Controls.Controls[i].ClassName = 'TRapidRadioBox' then
        if pr.Controls.Controls[i].Name <> FName then
          (pr.Controls.Controls[i] as TRapidRadioBox).Checked := False; 
    end;
    FChecked :=True;
  end;
end;


{ TRapidProgressBar }

constructor TRapidProgressBar.Create;
begin
  inherited;
  FBorderStyle := hbsLowered;
  FStyle := rpgsSplit;
  FColor := Color4ub(58,110,165,255);
  FHeight := 25;
  FWidth := 100;
end;

procedure TRapidProgressBar.Paint(absL,absT:Integer);
var sW:Integer; sqs,curIdx,i:Integer; X1,x2,y1,y2:Integer;
    barMaxWidth:Integer; nW:Integer;
begin
  inherited;
  if not Visible then exit;
  BarMaxWidth := FWidth -3;

  if FStyle = rpgsSmooth then
  begin
    nw := Round(FValue/FMax * BarMaxWidth);
    glColor4ub(FColor.R,FColor.G,FColor.B,FColor.A);
    glBegin(GL_QUADS);
      glVertex2i(absL+2,absT+1);
      glVertex2i(absL+2+nW,absT+1);
      glVertex2i(absL+2+nW,absT+FHeight-2);
      glVertex2i(absL+2,absT+FHeight-2);
    glEnd;
  end
  else
  begin
    sw:=FHeight div 2;
    sqs := FixNumber((FWidth-2)/(sw+2));
    curIdx:=FixNumber((FWidth-2)*(FValue/FMax)/(sw+2));
    glColor4ub(FColor.R,FColor.G,FColor.B,FColor.A);
    glBegin(GL_QUADS);
    for i := 0 to curIdx-1 do
    begin
      X1:=absL+i*(sw+2)+2;
      Y1:=absT+1;
      Y2:=absT+FHeight-1;
      if sqs>i+1 then
        X2:=X1+Sw
      else
        X2:=absL+FWidth-2;

      glVertex2i(X1,Y1);
      glVertex2i(X2,Y1);
      glVertex2i(X2,Y2);
      glVertex2i(X1,Y2);
    end;
    glEnd;
  end;
end;

procedure TRapidProgressBar.SetValue(const Value: Integer);
begin
  FValue := Value;
  if FValue > FMax then
    FValue := FMax;
  if FValue<0 then FValue :=0;
end;

{ TRapidSlideBar }

constructor TRapidSlideBar.Create;
begin
  inherited;
  FSlide := TRapidControl.Create;
  FBar := TRapidControl.Create;
  FBar.BackColor := FBackColor;
  FSlide.BackColor := FForeColor;
  FBar.BorderStyle := hbsLowered;
  FSlide.BorderStyle := hbsRaised;
  FBorderStyle := hbsNone;
  FForeColor:=Color4ub(180,180,180,255);
  FBackColor := Color4ub(120,120,120,220);
end;

procedure TRapidSlideBar.DoMouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if FVisible and FEnabled then
  if IsMouseIn or FSlide.IsMouseIn then
  begin
    IsMouseIn:=True;
    IsMouseDown := True;
    Value := Round((X-FLeft)/FWidth * FMax);
    if FValue>FMax then
      Value := FMax
    else if FValue<0 then
      Value := 0;
  end;
end;

procedure TRapidSlideBar.DoMouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  IsMouseDown :=False;
end;

procedure TRapidSlideBar.Free;
begin
  FSlide.Free;
  FBar.Free;
end;

procedure TRapidSlideBar.MousePosition(X, Y: Integer);
begin
  inherited;
  FSlide.MousePosition(X-FLeft,Y-FTop);
  if (X>FLeft-FSlide.Width div 2) and (X<FLeft+FWidth+FSlide.Width div 2)
        and (Y>FTop) and (Y<FTop+FHeight) then
    IsMouseIn:=True; 
  if IsMouseDown then
  begin
    Value := Round((X-FLeft)/FWidth * FMax);
    if FValue>FMax then
      Value := FMax
    else if FValue<0 then
      Value := 0;
  end;
end;

procedure TRapidSlideBar.Paint(absL, absT: Integer);
begin
  if not Visible then exit;
  FBar.Height := 3;
  FBar.Width := FWidth;
  FBar.Top := (FHeight-FBar.Height) div 2;
  FBar.BackColor := FBackColor;
  FBar.BorderColor := FBackColor;
  FBar.BorderWeight := FBorderWeight;
  FBar.Paint(AbsL,absT+FBar.Top);

  if FSliderSize>0 then
    FSlide.Width := FSliderSize
  else
    FSlide.Width := Round(FHeight /2.2);
  FSlide.Height := FHeight;
  FSlide.Left := Round(FValue/FMax * FWidth) - FSlide.Width div 2;
  FSlide.Top := Self.Top;
  FSlide.BackColor := FForeColor;
  FSlide.BorderColor := FForeColor;
  FSlide.BorderWeight := FBorderWeight;
  FSlide.Paint(absL+FSlide.Left , absT); 
end;

procedure TRapidSlideBar.SetValue(const Value:Integer);
var Changed:Boolean;
begin
  if FValue<>Value then Changed:=True else Changed:=False;
  inherited;
  if changed then if Assigned(FOnChanged) then FOnChanged(Self);
end;


{ TRapidScrollBar }

procedure TRapidScrollBar.btnDecClick(Sender: TObject);
begin
  Value := FValue - FSmallChange;
end;

procedure TRapidScrollBar.btnIncClick(Sender: TObject);
begin
  Value := FValue + FSmallChange;
end;

constructor TRapidScrollBar.Create;
begin
  inherited;
  FBorderStyle := hbsRaised;
  btnDec := TRapidButton.Create;
  btnInc := TRapidButton.Create;
  FScroll := TRapidControl.Create;
  btnDec.Font.Name := 'Webdings';
  btnInc.Font.Name := 'Webdings';
  FBackColor:=Color4ub(200,200,200,220);
  FScrollColor:=Color4ub(190,180,180,220);
  FForeColor := FScrollColor;
  FMin := 0;
  FMax := 100;
  FValue := 0;
  FPageSize:=20;
  FLargeChange:=20;
  FSmallChange:=1;
  FButtonHeight := 17;
  btnDec.OnClick := btnDecClick;
  btnInc.OnClick := btnIncClick;
  btnDec.FLabel.AutoSize := True;
  btnInc.FLabel.AutoSize := True;
end;

procedure TRapidScrollBar.DoMouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  btnDec.DoMouseDown(Button,Shift,X-FLeft,Y-FTop );
  btnInc.DoMouseDown(Button,Shift,X-FLeft,Y-FTop );
  if IsMouseIn and FVisible and FEnabled then
  begin
    if ((FKind=rsbkVetical)and(Y>FTop+FScroll.Top)and(Y<FTop+FScroll.Top + FScroll.Height))
    or((FKind=rsbkHorizontal)and(X>FLeft+FScroll.Left)and(X<FLeft+FScroll.Left+FScroll.Width)) then
    begin
      IsMouseDown := True;
      if FKind=rsbkVetical then OriMousePos := Y
      else OriMousePos := X;
      OriValue:=FValue;
      exit;
    end;
    if ((FKind = rsbkVetical)and((Y<FTop+FButtonHeight)or(Y>FTop+FHeight-FButtonHeight)))
    or((FKind=rsbkHorizontal)and((X<FLeft+FButtonHeight)or(X>FLeft+FWidth-FButtonHeight))) then
      Exit;
    if FKind  = rsbkHorizontal then
      Value := FValue+FLargeChange*sign(x-FLeft-FScroll.Left)
    else
      Value := FValue+FLargeChange*sign(y-FTop-FScroll.Top);
  end;

end;

procedure TRapidScrollBar.DoMouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  IsMouseDown:=False;
  btnDec.DoMouseUp(Button,Shift,X-FLeft,Y-FTop );
  btnInc.DoMouseUp(Button,Shift,X-FLeft,Y-FTop );
end;

procedure TRapidScrollBar.Free;
begin
  btnDec.Free;
  btnInc.Free;
  FScroll.Free;
end;

procedure TRapidScrollBar.MousePosition(X, Y: Integer);
var PosDelta :Integer;  ValueDelta:Integer;
    ScrollLength:Integer;
begin
  inherited;
  btnDec.MousePosition(X-FLeft,Y-FTop );
  btnInc.MousePosition(X-FLeft,Y-FTop);
  if IsMouseDown then
  begin
    if FKind = rsbkVetical then
    begin
      ScrollLength := FHeight - btnDec.Height - btnInc.Height - FPageSize;
      PosDelta := Y - OriMousePos;
    end
    else
    begin
      ScrollLength := FWidth - btnDec.Width - btnInc.Width - FPageSize;
      PosDelta := X - OriMousePos;
    end;
    ValueDelta := Round((FMax-FMin)/ScrollLength * PosDelta);
    Value := OriValue + ValueDelta;

  end;

end;

procedure TRapidScrollBar.Paint(absL, absT: Integer);
var ScrollLength:Integer;
begin
  if FVisible then
  begin
    if btnDec.Caption ='' then
      SetKind(FKind);
    btnDec.Left := 0;
    btnDec.Top := 0;
    if FKind = rsbkHorizontal then
    begin
      btnDec.Height := FHeight;
      btnDec.Width := FButtonHeight;
      btnInc.Left := FWidth - FButtonHeight;
      btnInc.Width := FButtonHeight;
      btnInc.Height := FHeight;
      btnInc.Top := 0;
      if FPageSize> FWidth - btnDec.Width - btnInc.Width-5 then
        FPageSize:= FWidth - btnDec.Width - btnInc.Width-5;
      ScrollLength := FWidth - btnDec.Width - btnInc.Width - FPageSize;

      FScroll.Width := FPageSize-FBorderWeight*2;
      FScroll.Top := 0;
      FScroll.Height := FHeight;
      FScroll.Left := Round((FValue-FMin)/(FMax-FMin)*ScrollLength)+btnDec.Width+FBorderWeight;
    end
    else
    begin
      btnDec.Width := FWidth;
      btnDec.Height := FButtonHeight;
      btnInc.Top := FHeight - FButtonHeight;
      btnInc.Width := FWidth;
      btnInc.Height := FButtonHeight;
      btnInc.Left := 0;
      if FPageSize>FHeight - btnDec.Height - btnInc.Height-5 then
        FPageSize:=FHeight - btnDec.Height - btnInc.Height-5;
      ScrollLength := FHeight - btnDec.Height - btnInc.Height - FPageSize;

      FScroll.Height := FPageSize-FBorderWeight*2;
      FScroll.Left := 0;
      FScroll.Width := FWidth;
      FScroll.Top := Round((FValue-FMin)/(FMax-FMin)*ScrollLength)+btnDec.Height+FBorderWeight;
    end;
    FScroll.BorderStyle := FBorderStyle;
    FScroll.BorderWeight := FBorderWeight;
    FScroll.BackColor := FScrollColor;
    FScroll.BorderColor := FBorderColor;
    btnDec.BorderColor := FBorderColor;

    btnInc.BorderColor := FBorderColor;
    btnInc.BackColor := FForeColor;
    btnDec.BackColor := FForeColor;
    btnDec.BorderWeight := FBorderWeight;
    btnInc.BorderWeight := FBorderWeight;
    if FBorderStyle <>hbsRaised then
    begin
      btnDec.AutoBorder := False;
      btnInc.AutoBorder := False;
      btnDec.BorderStyle:= FBorderStyle;
      btnInc.BorderStyle := FBorderStyle;
    end
    else
    begin
      btnDec.AutoBorder := True;
      btnInc.AutoBorder := True;
    end;
    glColor4ub(FBackColor.R,FBackColor.G,FBackColor.B,FBackColor.A);
    glBegin(GL_QUADS);
      glVertex2i(absL,absT);
      glVertex2i(absL+FWidth,absT);
      glVertex2i(absL+FWidth,absT+FHeight);
      glVertex2i(absL,absT+FHeight);
    glEnd;
    btnDec.Paint(absL,absT);
    btnInc.Paint(absL+btnInc.Left,absT+btnInc.Top);
    FScroll.Paint(absL+FScroll.Left,absT+FScroll.Top);
  end;
end;

procedure TRapidScrollBar.SetKind(const Value: TRapidScrollBarKind);
begin
  FKind := Value;
  if FKind = rsbkHorizontal then
  begin
    btnDec.Caption := Char(51);//'<'Symbal in Font 'Webdings'
    btnInc.Caption := Char(52);//'>'Symbal in Font 'Webdings'
  end
  else
  begin
    btnDec.Caption := Char(53);//'/\'Symbal in Font 'Webdings'
    btnInc.Caption := Char(54);//'\/'Symbal in Font 'Webdings'
  end;
   
end;

procedure TRapidScrollBar.SetMax(const Value: Integer);
begin
  FMax := Value;
  if FMax<FMin then FMax:=FMin;
  if FValue>FMax then
    FValue := FMax;
end;

procedure TRapidScrollBar.SetMin(const Value: Integer);
begin
  FMin := Value;
  If FValue<FMin then
    FValue := FMin;
end;

procedure TRapidScrollBar.SetValue(const Value: Integer);
var lstValue:Integer;
begin
  lstValue := FValue;
  FValue := Value;
  if FValue > FMax then
    FValue := FMax
  else if FValue< FMin then
    FValue := FMin;
  if FValue<>lstValue then
  begin
    if Assigned(FOnChanged) then
      FOnChanged(Self);
  end;
end;

{ TRapidListBox }

procedure TRapidListBox.AddItem(s: String);
var WidthCut:Integer; i:Integer; wChanged:Boolean;
begin
  wChanged:=False;
  if (FHeight div FLineHeight) <(FItems.Count+1) then
    WidthCut:=FScroll.Width + FBorderWeight*4
  else
    WidthCut:= FBorderWeight*6;
  FItems.Add(S);
  SetLength(FLabels,FItems.Count);
  FLabels[FItems.Count-1] := TRapidLabel.Create;
  FLabels[FItems.Count-1].Font := FFont;
  FLabels[FItems.Count-1].AutoSize := False;
  if FItems.Count > 1 then
  begin
    FLabels[FItems.Count-1].Height := FLabels[0].RealHeight;
    FLabels[FItems.Count-1].Width := FWidth-WidthCut;
    FLabels[FItems.Count-1].Caption := s;
  end
  else
  begin
    FLabels[FItems.Count-1].Caption := s;
    FLabels[FItems.Count-1].Height := FLabels[0].RealHeight;
    FLabels[FItems.Count-1].Width := FWidth-WidthCut;
    FLabels[FItems.Count-1].ResetText;
  end;
  FLineHeight := FLabels[FItems.Count-1].RealHeight+5;
  if FWidth-WidthCut<>FLabels[0].Width then
    wChanged:=True;
  for i := 0 TO FItems.Count -1 do
  begin
    FLabels[i].Width := FWidth-WidthCut;
    if wChanged then FLabels[i].ResetText;
  end;
  FScroll.Max := Items.Count - FHeight div FLineHeight;
end;

constructor TRapidListBox.Create;
begin
  inherited;
  FScroll:=TRapidScrollBar.Create;
  FBorderStyle := hbsLowered;
  FItems := TStringList.Create;
  FFont := TFont.Create;
  FFont.Name := 'Verdana';
  FFont.Size := 9;
  curMouseIdx:=-1;
  SelectedIdx:=-1;
  FSelectedColor := Color4ub(58,69,192,220);
  FHighLightColor := Color4ub(220,170,53,220);
    FScroll.Width := 17;
  FBorderWeight:=1;
  FLineHeight:=17;

end;

procedure TRapidListBox.DoMouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var lstSelIdx:Integer;
begin
  if not (FEnabled and FVisible) then exit;
  inherited;
  FScroll.DoMouseDown(Button,Shift,X-FLeft,Y-FTop);
  if isMouseIn then
  begin
    lstSelIdx:=SelectedIdx;
    if X<FWidth-FScroll.Width+FLeft then
    SelectedIdx:=HitTest(X-Fleft,Y-FTop);
    if SelectedIdx>FItems.Count -1 then
      SelectedIdx:=-1;
    if lstSelIdx<>SelectedIdx then
      if Assigned(FOnChanged) then
        FOnChanged(Self);
    if Not FScroll.IsMouseIn then
      if Assigned(FOnItemMouseDown) then
        FOnItemMouseDown(self);
  end;
end;

procedure TRapidListBox.DoMouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var LstWidth:Integer;
begin
  lstWidth := FWidth;
  if FScroll.Visible then
    FWidth := FWidth - 17;
  inherited;
  FWidth := lstWidth;
  if not (FEnabled and FVisible) then exit;
  FScroll.DoMouseUp(Button,Shift,X-FLeft,Y-FTop);
end;

procedure TRapidListBox.Free;
var i:Integer;
begin
  SetLength(FLabels,FItems.Count);
  for i := 0 to High(FLabels) do
  begin
    if SizeOf(FLabels[i]) >0 then FLabels[i].Free;
  end;
  FScroll.Free;
  FItems.Free;
  SetLength(FLabels,0);
  FFont.Free;
end;

function TRapidListBox.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TRapidListBox.HitTest(X, Y: Integer): Integer;
begin
  result := -1;
  if (Y>0) and (Y<FHeight-1) then
  if (X>0)and(X<FWidth-FScroll.Width) then
  begin
    result := (Y-5) div FLineHeight + FScroll.Value;
  end;
end;

procedure TRapidListBox.MousePosition(X, Y: Integer);
begin
  inherited;
  if not (FEnabled and FVisible) then exit;
  FScroll.MousePosition(X-FLeft,Y-FTop);
  curMouseIdx := HitTest(X-Fleft,y-FTop);
  if curMouseIdx>FItems.Count -1 then
    curMouseIdx:=-1;

end;

procedure TRapidListBox.Paint(absL, absT: Integer);
var i:Integer; loopEnd:Integer;X1,X2,Y1,Y2:Integer;
begin
  if not FVisible then exit;
  FHeight := FHeight div FLineHeight * FLineHeight+2+2;
  FScroll.Width := 17;
  inherited;
  if FItems.Count > 0 then
  begin
    FScroll.BorderWeight := FBorderWeight;
    FScroll.Height := FHeight-FBorderWeight*2;
    FScroll.Top := FBorderWeight;
    FScroll.Left := FWidth-FScroll.Width-FBorderWeight;
    FScroll.Visible := (FHeight div FLineHeight<FItems.Count);
    
    X1:=1;
    if FScroll.Visible then
      X2:=FLabels[0].Width+FBorderWeight*4
    else
      X2:=FWidth - FBorderWeight;
    if FScroll.Visible then
    begin
      FScroll.PageSize := Round((FHeight / FLineHeight) /FItems.Count *90);
      if FScroll.PageSize < 6 then FScroll.PageSize := 6;
    end;
    if FFocused then
    if curMouseIdx>-1 then
    begin
      Y1:=(FLineHeight-FLabels[0].RealHeight)div 2+(curMouseIdx-FScroll.Value)*FLineHeight-1;
      Y2:=Y1+FLabels[0].RealHeight+(FLineHeight-FLabels[0].RealHeight)+2;
      if (Y1>= 0)and(Y1<FHeight-5) then
      GLDrawQuads(FHighLightColor,X1+absL,X2+absL,Y1+absT,Y2+absT);
    end;
    if SelectedIdx>-1 then
    begin
      Y1:=(FLineHeight-FLabels[0].RealHeight)div 2+(SelectedIdx-FScroll.Value)*FLineHeight-1;
      Y2:=Y1+FLabels[0].RealHeight+(FLineHeight-FLabels[0].RealHeight)+3;
      if (Y1>= 0)and(Y1<FHeight-5) then
      GLDrawQuads(FSelectedColor,X1+absL,X2+absL,Y1+absT,Y2+absT);
    end;
    LoopEnd := FScroll.Value + FHeight div FLineHeight;
    if LoopEnd > FItems.Count  then
      LoopEnd := FItems.Count ;
    for i := FScroll.Value to LoopEnd-1 do
    begin
      FLabels[i].ForeColor := FForeColor;
      FLabels[i].Paint(absL+6,absT+FLineHeight-FLabels[0].RealHeight+
      (i-FScroll.Value)*FLineHeight);
    end;
    FScroll.Paint(absL+FScroll.Left,absT+FScroll.Top);
  end;
end;

procedure TRapidListBox.Refresh;
var i:Integer;WidthCut:Integer;
begin
  for i := 0 to High(FLabels) do
  begin
    if FLabels[i].InstanceSize >0 then FLabels[i].Free;
  end;
  if FHeight div FLineHeight <FItems.Count then
    WidthCut:=FScroll.Width + FBorderWeight*4
  else
    WidthCut:= FBorderWeight*6;
  SetLength(FLabels,FItems.Count);
  for i := 0 to FItems.Count-1 do
  begin
    FLabels[i] := TRapidLabel.Create;
    FLabels[i].AutoSize := False;
    FLabels[i].Font := FFont;
    if i>0 then
    begin
      FLabels[i].Height := FLabels[0].RealHeight;
      FLabels[i].Width := FWidth-WidthCut;
      FLabels[i].Caption := FItems.Strings[i];
    end
    else
    begin
      FLabels[i].Caption := FItems.Strings[i];
      FLabels[i].Height := FLabels[0].RealHeight;
      FLabels[i].Width := FWidth-WidthCut;
      FLabels[i].ResetText;
    end;
  end;
  if SelectedIdx>FItems.Count -1 then selectedIdx:=FItems.Count-1;
  if CurMouseIdx>FItems.Count -1 then curMouseIdx := -1;
  if FItems.Count > 0 then
    FLineHeight := FLabels[0].RealHeight + 5;
  FScroll.Kind := rsbkVetical;
  FScroll.Max := Items.Count - FHeight div FLineHeight;
  if FScroll.Max <0 then FScroll.Max := 0;
  FScroll.Value := 0;
end;

procedure TRapidListBox.RemoveItem(Index: Integer);
var WidthCut:Integer; i:Integer; wChanged:Boolean;
begin
  wChanged:=False;
  if FHeight div FLineHeight <(FItems.Count-1) then
    WidthCut:=FScroll.Width + FBorderWeight*4
  else
    WidthCut:= FBorderWeight*6;
  FItems.Delete(Index);
  FLabels[Index].Free;
  for i := Index to High(FLabels) -1 do
  begin
    FLabels[i] := FLabels[i+1];
  end;
  if FItems.Count >0 then
    if FLabels[0].Width <>FWidth-WidthCut then
      wChanged:=True;
  for i := 0 TO FItems.Count -1 do
  begin
    FLabels[i].Width := FWidth-WidthCut;
    if wChanged then
      FLabels[i].ResetText;
  end;

  FScroll.Max := Items.Count - FHeight div FLineHeight;
end;

procedure TRapidListBox.SetFont(const Value: TFont);
begin
  FFont.Assign(Value);
end;

{ TRapidComboBox }

procedure TRapidComboBox.AddItem(s: String);
begin
  if FList.Width = 0 then
    FList.Width:= FWidth;
  if FList.Height = 0 then
    FList.Height := Flist.LineHeight * 6;
  FList.AddItem(s);
end;

constructor TRapidComboBox.Create;
begin
  inherited;
  FList := TRapidListBox.Create;
  FList.OnChanged := DoChanged;
  FButton := TRapidButton.Create;
  FButton.Font.Name := 'Webdings';
  FBorderStyle := hbsLowered;
  FMaxListLength:=6;
  FList.BorderStyle := hbsFlat;
  FList.BorderColor := FBorderColor;
  FList.OnItemMouseDown := ListItemMouseDown;
  FListColor := FBackColor;
  FButtonBackColor := FButton.BackColor ;
  FButtonBorderColor := FButton.BorderColor;
  FButtonBorderStyle := hbsRaised;
  FButtonForeColor := FButton.ForeColor;
end;

procedure TRapidComboBox.DoChanged(Sender: TObject);
begin
  if Assigned(FOnChanged) then
    FOnChanged(Self);
end;

procedure TRapidComboBox.DoMouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Not( FVisible and FEnabled) then exit;
  if IsMouseIn and not ShowList then
  begin
    ShowList:=True;
  end
  else
  begin
  //  if not FList.IsMouseIn then
      ShowList:=False;
  end;
  TRapidContainer(FParent).ComboDropped:=ShowList;
  FButton.DoMouseDown(Button,Shift,X-FLeft,Y-FTop);
  FList.DoMouseDown(Button,Shift,X-FLeft,Y-FTop);
end;

procedure TRapidComboBox.DoMouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  FButton.DoMouseUp(Button,Shift,X-FLeft,Y-FTop);
  FList.DoMouseUp(Button,Shift,X-FLeft,Y-FTop);
end;

procedure TRapidComboBox.Free;
begin
  FList.Free;
  FButton.Free;
end;

function TRapidComboBox.GetCount: Integer;
begin
  Result:= FList.Count;
end;

function TRapidComboBox.GetDrawHighLight: Boolean;
begin
  Result := FList.DrawHighLight;
end;

function TRapidComboBox.GetFont: TFont;
begin
  Result := FList.Font;
end;

function TRapidComboBox.GetHighLightColor: TColor4ub;
begin
  Result := FList.HighLightColor;
end;

function TRapidComboBox.GetIndex: Integer;
begin
  Result := FList.SelectedIdx;
end;

function TRapidComboBox.GetItems: TStringList;
begin
  result := FList.Items;
end;

function TRapidComboBox.GetLineHeight: Integer;
begin
  result := FList.LineHeight;
end;

function TRapidComboBox.GetSelectedColor: TColor4ub;
begin
  result := FList.SelectedColor;
end;

function TRapidComboBox.GetText: String;
begin
  Result := '';
  if (FList.Count>FList.SelectedIdx)and (FList.SelectedIdx >-1) then
  begin
    Result := FList.Items.Strings[FList.SelectedIndex];
  end;
end;

procedure TRapidComboBox.ListItemMouseDown(Sender: TObject);
begin
  ShowList:=False;
end;

procedure TRapidComboBox.MousePosition(X, Y: Integer);
begin
  inherited;
  FButton.MousePosition(X-FLeft,Y-FTop);
  FList.MousePosition(X-FLeft,Y-FTop);
end;

procedure TRapidComboBox.Paint(absL, absT: Integer);
begin
  if not Visible then exit;
  if FHeight<FList.LineHeight + 5 then
    FHeight := FList.LineHeight +5;
  if FWidth<FList.LineHeight - FBorderWeight+50 then
    FWidth := FList.LineHeight - FBorderWeight+50;
  inherited;
  if FButtonBorderStyle <> hbsRaised then
  FButton.BorderStyle := FButtonBorderStyle;
  FButton.BackColor := FButtonBackColor;
  FButton.BorderColor := FButtonBorderColor;
  FButton.ForeColor := FButtonForeColor;
  FButton.Height := FHeight - FBorderWeight*2;
  FButton.Width := FButton.Height;
  FButton.Left := FWidth-Round(FBorderWeight )-FButton.Width;
  FButton.Top := Round(FBorderWeight);

  if FButton.Caption ='' then
    FButton.Caption := Char(54);//'\/' Symbol in Font 'Webdings'
  FButton.Paint(absL+FButton.Left,absT+Fbutton.Top);

end;

procedure TRapidComboBox.PaintList(absL, absT: Integer);
var ListLen:Integer ;
begin
  if not Visible then exit;
  FList.BackColor := FListColor;
  FList.ForeColor := FForeColor;
  FList.Left:=0;
  FList.Top := FHeight;
  FList.Width := FWidth;
  ListLen := FList.Count;
  if ListLen>FMaxListLength then
    ListLen:=FMaxListLength;
  FList.Height := ListLen*FList.LineHeight;
  FList.Visible := ShowList;
  FList.Paint(absL+FList.Left,absT+FList.Top);
  if (FList.Count>FList.SelectedIdx)and (FList.SelectedIdx >-1) then
  begin
    FList.FLabels[FList.SelectedIdx].Paint(absL+FBorderWeight+3,absT+
                 (FHeight-FList.FLabels[FList.SelectedIdx].Height) div 2);
  end;
end;

procedure TRapidComboBox.PopList;
begin
  ShowList:=Not ShowList;
end;

procedure TRapidComboBox.Refresh;
begin
  FList.Refresh;
end;

procedure TRapidComboBox.RemoveItem(Index: Integer);
begin
  FList.RemoveItem(Index);
end;

procedure TRapidComboBox.SetDrawHighLight(const Value: Boolean);
begin
  FList.DrawHighLight := Value;
end;

procedure TRapidComboBox.SetFont(const Value: TFont);
begin
  FList.Font := Value;
end;

procedure TRapidComboBox.SetHighLightColor(const Value: TColor4ub);
begin
  FList.HighLightColor := Value;
end;

procedure TRapidComboBox.SetIndex(const Value: Integer);
begin
  FList.SelectedIdx := Value;
end;

procedure TRapidComboBox.SetItems(const Value: TStringList);
begin
  FList.Items := Value;
end;

procedure TRapidComboBox.SetSelectedColor(const Value: TColor4ub);
begin
  FList.SelectedColor := Value;
end;

procedure TRapidComboBox.SetShowList(const Value: Boolean);
var Changed:Boolean;
begin
  if Value <>FShowList then Changed:=True else Changed:=False;
  FShowList := Value;
  if FShowList and Changed then
  begin
    if Assigned(FOnListPopup) then
      FOnListPopup(Self);
    FList.Focused := True;
  end
  else if Changed then
  begin
    if Assigned(FOnListHangOn) then
    begin
      FShowList:=False;
      FOnListHangOn(Self);
      FList.Focused := False;
    end;
  end;
end;

{ TRapidInputBox }

constructor TRapidInputBox.Create;
begin
  inherited;
  lblText := TRapidLabel.Create;
  FForeColor := Color4ub(0,0,0,220);
  FBackColor := Color4ub(255,255,255,220);
  FBorderColor := Color4ub(127,127,127,220);
  FBorderStyle := hbsLowered;
  FHeight:=20;
  FWidth :=120;
  lstSPos:=1;
  FPos:=0;
  Frames:=0;
end;

procedure TRapidInputBox.DoKeyDown(var Key: Word; Shift: TShiftState);
begin
  Frames:=0;
  if (key=46) or (key=8) then //Delete Key
  begin

    if (FSelStart>0) and (FSelCount>0) then
    begin
      Delete(FText,FSelStart,FSelCount);
      FPos:=FSelStart-1;
    end
    else
      if key=46 then
        Delete(FText,FPos+1,1)
      else
      begin
        Delete(FText,FPos,1);
        FPos:=FPos-1
      end;
    if FPos<0 then FPos:=0;
    FSelStart:=0;
    FSelCount:=0;
    if Assigned(FOnChanged) then FOnChanged(Self);
    Exit;
  end;    
  if ssShift in Shift then
  begin
    if FSelStart=0 then
    begin
      FSelStart:=FPos+1;
      OriPos:=FPos;
    end;
  end
  else
  begin
    FSelStart:=0;
    OriPos:=0;
    FSelCount:=0
  end;
  if key=37 then //Left Key
  begin
    if FPos>0 then FPos:=FPos-1;
    if ssShift in Shift then
    begin
      if FSelStart>0 then
      begin
        if FPos<OriPos then
        begin
          FSelStart:=FPos+1;
          FSelCount:=OriPos-FPos;
        end
        else
        begin
          FSelStart:=OriPos+1;
          FSelCount:=FPos-OriPos;  
        end;
      end;
    end;
  end
  else if key=39 then //Right Key
  begin
    if FPos<Length(FText) then FPos:=FPos+1;
    if ssShift in Shift then
    begin
      if FSelStart>0 then
      begin
        if FPos<OriPos then
        begin
          FSelStart:=FPos+1;
          FSelCount:=OriPos-FPos;
        end
        else
        begin
          FSelStart:=OriPos+1;
          FSelCount:=FPos-OriPos;
        end;
      end;
    end;
  end;
end;

procedure TRapidInputBox.DoKeyPress(Key: Char);
var lstPos:Integer;
begin
  lstPos:=FPos;
  inherited;
  if not FFocused then exit;
  Frames:=0;
{  if FSelStart<0 then FSelStart:=0;
  if FSelStart>Length(FText) then FSelStart:=Length(FText);
  if FSelCount>Length(FText)-FSelStart then FSelCount := Length(FText)-FSelStart;
  if FSelCount<0 then FSelCount:=0;
}
  if ((Ord(Key)>=32) and (Ord(Key)<= 127)) then
  begin
    if FSelCount>0 then
    begin
      Delete(FText,FSelStart,FSelCount);
      FPos:=FSelStart-1;
    end;
    FSelStart:=0;
    FSelCount:=0;
    Text:=Copy(FText,1,FPos)+Char(Key)+Copy(FText,FPos+1,Length(FText));
    FPos:=FPos+1;
    if Assigned(FOnChanged) then FOnChanged(Self);
  end;
end;

procedure TRapidInputBox.DoMouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if IsMouseIn then
  begin
    IsMouseDown:=True;
    OriX:=X-FLeft;
    OriY:=Y-FTop;
    OriPos:=GetPosAtPoint(OriX,OriY);
    FPos:=OriPos;
    SelStart:=0;
    SelCount:=0;
  end;
end;

procedure TRapidInputBox.DoMouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  IsMouseDown:=False;
end;

procedure TRapidInputBox.Free;
begin
  inherited;
  lblText.Free;
end;

function TRapidInputBox.GetFont: TFont;
begin
  result := lblText.Font;
end;

function TRapidInputBox.GetPosAtPoint(X,Y:Integer):Integer;
var i:Integer;
begin
  i:=0;
  while (lstSPos+i<=Length(FText))
        and (lblText.TextWidth(Copy(FText,lstSPos,i))<X-lblText.Left) do
    i:=i+1;
  result := lstSPos+i-1;

end;

procedure TRapidInputBox.MousePosition(X, Y: Integer);
var curX,curY:Integer;  curPos:Integer;
begin
  inherited;
  if IsMouseDown then
  begin
    curX:=X-FLeft;
    curY:=Y-FTop;
    FPos:=GetPosAtPoint(curX,curY);
    if (curX<lblText.Left) and (FPos>0)  then
      FPos:=FPos-1;
    if (curX>FWidth) and (FPos<Length(FText)) then
      FPos:=FPos+1;
    curPos:=FPos+1;
    if FPos<OriPos then
    begin
      FSelStart:=curPos;
      FSelCount:=OriPos-FPos;
    end
    else
    begin
      FSelStart:=OriPos+1;
      FSelCount:=FPos-OriPos;
    end;
  end;
end;

procedure TRapidInputBox.Paint(absL, absT: Integer);
var X,Y,X1,Y1,minHeight:Integer;ShowCursor:Boolean;
  function GetPosLeft(StartPos:Integer;CurPos:Integer):Integer;
  begin
    result:=lblText.TextWidth(Copy(FText,StartPos,CurPos-StartPos));
  end;
begin
  inherited;
  if not (FVisible and FEnabled) then exit;
  lblText.Left := FBorderWeight*5;
  if FText<>'' then
  begin
    lblText.ForeColor := FForeColor;
    if FPos+1<lstSPos then
    begin
      lstSPos:=FPos-3;
      if lstSPos <= 0 then lstSPos:=1;
    end
    else
      While GetPosLeft(lstSPos,FPos)> FWidth- FBorderWeight*5-5 do
        lstSPos:=lstSPos+1;
    minHeight:=lblText.TextHeight(FText)+FBorderWeight*4+6;
    if FHeight<minHeight then
      FHeight:=minHeight;
    lblText.AutoSize := False;

    lblText.Width := FWidth - FBorderWeight*5;
    lblText.Height := FHeight;
    lblText.Caption := Copy(FText,lstSPos,Length(FText));
    lblText.Top := (FHeight-lblText.RealHeight) div 2;
    if FFocused and (FSelCount>0) then
    begin
      x:=GetPosLeft(lstSPos,FSelStart);
      X:=X+lblText.Left;
      Y:=FBorderWeight+1;
      Y1:=Y+FHeight-FBorderWeight*4-3;
      X1:=X+lblText.TextWidth(Copy(FText,FSelStart,FSelCount));
      if X<FBorderWeight then X1:=FBorderWeight;
      if X1>FWidth-FBorderWeight*2 then X1:=FWidth-FBorderWeight*2;
      GLDrawQuads(Color4ub(140,140,250,220),X+absL,X1+absL,Y+absT,Y1+absT);
    end;
    lblText.Paint(absL+lblText.Left,absT+lblText.Top);
  end;

   if odd(Frames div Round(TRapidForm(UIForm).FPS/2)) then
     ShowCursor:=False
   else
     ShowCursor:=True;
   if Frames div Round(TRapidForm(UIForm).FPS/2)> 3 then
     Frames:=0;

  if FFocused and ShowCursor then
  begin
    X:=GetPosLeft(lstSPos,FPos+1);
    X:=X+lblText.Left;
    Y:=FBorderWeight+1;
    glColor4ub(FForeColor.r,FForeColor.g,FForeColor.B,FForeColor.A);
    glLineWidth(2);
    glBegin(GL_LINES);
      glVertex2i(absL+X,absT+y);
      glVertex2i(absL+X,absT+Y+FHeight-FBorderWeight*4-3);
    glEnd;

  end;
  Frames:=Frames+1;
end;

procedure TRapidInputBox.SetFont(const Value: TFont);
begin
  lblText.Font := Value;
end;

procedure TRapidInputBox.SetText(const Value: String);
begin
  FText := Value;
end;

{ THyTexture }

procedure THyTexture.AddAlphaMask(aMask: TByteArray2D);
var i,j,ei,ej:Integer;
begin
  ei := High(aMask);
  ej := High(aMask[0]);
  if ei > High(FPixels) then
    ei := High(FPixels);
  if ej > High(FPixels[0]) then
    ej := High(FPixels[0]);
  for i := 0 to ei do
  begin
    for j := 0 to ej do
    begin
      FPixels[i,j].A := aMask[i,j];
    end;
  end;
end;

procedure THyTexture.AddBrightnessMask(bMask: TByteArray2D);
var i,j,ei,ej:Integer;

  function ByteFix(X:Integer):Byte;
  begin
    if X>255 then
      result := 255
    else
    begin
      if X<0 then
        Result := 0
      else
        Result := X;
    end;
  end;

begin
  ei := High(bMask);
  ej := High(bMask[0]);
  if ei > High(FPixels) then
    ei := High(FPixels);
  if ej > High(FPixels[0]) then
    ej := High(FPixels[0]);
  for i := 0 to ei do
  begin
    for j := 0 to ej do
    begin
      FPixels[i,j].R :=ByteFix(FPixels[i,j].R + bMask[i,j]);
      FPixels[i,j].G :=ByteFix(FPixels[i,j].G + bMask[i,j]);
      FPixels[i,j].B :=ByteFix(FPixels[i,j].B + bMask[i,j]);
    end;
  end;
end;

procedure THyTexture.Bind;
begin
  glBindTexture(GL_TEXTURE_2D,FTextureID);
end;

constructor THyTexture.Create;
begin
  FHeight:=0;
  FWidth:=0;
  FTextureID:=0;
end;

procedure THyTexture.Free;
begin
  SetLength(FPixels,0,0);
  glDeleteTextures(1,@FTextureID);
end;

procedure THyTexture.Generate;
var pxs:array of Byte;
    m:Integer;i,j:Integer;
    Texture:GLUint;
begin
  SetLength(pxs,CalcTextureSize(Height)*CalcTextureSize(Width)*4);
  m:=0;
  for i := 0 to FHeight - 1 do
  begin
    for j:=0 to FWidth- 1 do
    begin
      pxs[m]:=FPixels[j,i].R;
      pxs[m+1]:=FPixels[j,i].G;
      pxs[m+2]:=FPixels[j,i].B;
      pxs[m+3]:=FPixels[j,i].A;
      m:=m+4;
    end;
  end;
  glGenTextures(1,@Texture);
  glBindTexture(GL_TEXTURE_2D,Texture);
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_LINEAR);
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_REPEAT);
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_REPEAT);
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_ENV_MODE,GL_MODULATE);
    gluBuild2DMipmaps(GL_TEXTURE_2D,4,CalcTextureSize(FWidth),
     CalcTextureSize(FHeight),GL_RGBA,GL_UNSIGNED_BYTE,pxs);
  FTextureID := texture;
end;

function THyTexture.GetPixel(X, Y: Integer): TColor4ub;
begin
  result := FPixels[x,y];
end;

procedure THyTexture.LoadFromBitmap(Bit: TBitmap);
var Pix:TRapidPixels;pixPtr:TRapidPixelPointer;
    i,j:Integer;
begin
  ReadPixels(Bit,Pix,PixPtr);
  SetLength(FPixels,CalcTextureSize(Bit.Width),CalcTextureSize(Bit.Height));
  FWidth := Bit.Width;
  FHeight := Bit.Height;
  for i := 0 to FHeight -1 do
  begin
    for j := 0 to FWidth-1 do
    begin
      FPixels[j,i].R := Pix[j,i].R;
      FPixels[j,i].G := Pix[j,i].G;
      FPixels[j,i].B := Pix[j,i].B;
      FPixels[j,i].A := 255;
    end;
  end;
  Generate;
end;

procedure THyTexture.LoadFromFile(FileName: String);
var Pic:TPicture;
begin
  Pic:=TPicture.Create;
  try
    Pic.LoadFromFile(FileName);
    LoadFromBitmap(Pic.Bitmap);  
  finally
    pic.Free;
  end;
end;

procedure THyTexture.SetHeight(const Value: Integer);
begin
  SetLength(FPixels,CalcTextureSize(FWidth),CalcTextureSize(Value));
  FHeight := Value;
end;

procedure THyTexture.SetPixel(X, Y: Integer; const Value: TColor4ub);
begin
  FPixels[x,y] := Value;
end;

procedure THyTexture.SetTransparentColor(const Value: THyPixel);
var i,j:Integer;
begin
  for i := 0 to FWidth -1 do
    for j:=0 to FHeight -1 do
    begin
      if (FPixels[i,j].R = value.R) and (FPixels[i,j].G = value.G)
         and (FPixels[i,j].B = value.B) then
      begin
        FPixels[i,j].A := 0;
      end;
    end;
end;

procedure THyTexture.SetWidth(const Value: Integer);
begin
  SetLength(FPixels,CalcTextureSize(Value),CalcTextureSize(FHeight));
  FWidth := Value;
end;

procedure THyTexture.SubstitueImage(nPixels: THyPixels);
var i,j:Integer;
begin
  Height := High(FPixels)+1;
  Width := High(FPixels[0])+1;
  for i := 0 to CalcTextureSize(FWidth) do
    for j := 0 to CalcTextureSize(FHeight) do
    begin
      FPixels[i,j].R :=0;
      FPixels[i,j].G :=0;
      FPixels[i,j].B :=0;
      FPixels[i,j].A :=0;
    end;
  for i := 0 to FWidth - 1 do
    for j:= 0 to FHeight -1 do
    begin
      FPixels[i,j].R := nPixels[i,j].R;
      FPixels[i,j].G := nPixels[i,j].G;
      FPixels[i,j].B := nPixels[i,j].B;
      FPixels[i,j].A := nPixels[i,j].A;
    end;
 Generate;   
end;

end.
