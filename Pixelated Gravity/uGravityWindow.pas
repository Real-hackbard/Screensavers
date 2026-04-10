unit uGravityWindow;

interface

uses
  Classes, SysUtils, Forms, Windows, Graphics, Math;

const
  PIXEL_COUNT = 1000;

type
  TRealPoint = record
    X, Y: Real;
  end;

  TARGB = packed record
    B, G, R, A: Byte;
  end;

  { I know there's the TRGBQuad type, but the TRGBQuad type has the
    variables 'rgbRed', 'rgbGreen', 'rgbBlue' and 'rgbReserved'. But
    A, R, G and B are much more readable, don't you think? :)
  }

  PMyPixel = ^TMyPixel;
  TMyPixel = record
    Position, Speed: TRealPoint;
    OriginalColor, FilteredColor: TARGB;
  end;

  PForm = ^TForm;

  TGravityWindow = class(TObject)
  public
    constructor Create(const Form: PForm);
    destructor Destroy; override;
    procedure Resize;
    function GetFrame: TBitmap;
  private
    FBitmap: TBitmap;
    FRows: array of PByteArray;
    FPixels: array[0..PIXEL_COUNT - 1] of TMyPixel;
    FLastTime: Integer;
    FCursor: TPoint;
    FForm: PForm;
    // Init
    procedure InitBitmap;
    procedure InitPixels;
    procedure SetBitmapSize;
    // Draw
    procedure ClearBitmap;
    procedure ZeroBitmap(Bitmap: Pointer; Count: Integer);
    procedure BlurBitmap;
    procedure BlurRow(ThisRow, NextRow: Pointer; Width: Integer);
    procedure DrawPixels;
    procedure ApplyColorFilter;
    procedure SetPixel(Location, Value: DWORD);
    // Move
    procedure MovePixels;
    procedure UpdatePixel(const Pixel: PMyPixel; const ElapsedTime: Real);
  end;

implementation

{============================ EVENTS ================================}

constructor TGravityWindow.Create(const Form: PForm);
begin
  inherited Create;
  FForm := Form; // Pointer to the form
  InitBitmap;
  InitPixels;
  FLastTime := GetTickCount; // For measuring the time between frames
end;

destructor TGravityWindow.Destroy;
begin
  FBitmap.Free;
  inherited;
end;

{============================ PUBLIC ================================}

procedure TGravityWindow.Resize;
begin
  SetBitmapSize;
end;

function TGravityWindow.GetFrame: TBitmap;
begin
  MovePixels;
  DrawPixels;
  Result := FBitmap;
end;

{============================ INITIALIZATION ========================}

procedure TGravityWindow.InitBitmap;
begin
  FBitmap := TBitmap.Create;
  FBitmap.PixelFormat := pf32bit;
  SetBitmapSize;
end;

procedure TGravityWindow.SetBitmapSize;
var
  y: Integer;
begin
  FBitmap.Width := FForm.ClientWidth;
  FBitmap.Height := FForm.ClientHeight;

  { Make an array of pointers to each row of the bitmap. We will
    need these pointers pretty often, so preparing them in an array
    should speed things up. }

  SetLength(FRows, FForm.ClientHeight);
  for y := 0 to FForm.ClientHeight - 1 do
    FRows[y] := FBitmap.ScanLine[y];

  ClearBitmap;
end;

procedure TGravityWindow.InitPixels;
var
  i: Integer;
begin
  Randomize;
  for i := 0 to PIXEL_COUNT - 1 do
    with FPixels[i] do
    begin
      Position.X := Random(FForm.ClientWidth);
      Position.Y := Random(FForm.ClientHeight);

      Speed.X := Random(200) - 100;
      Speed.Y := Random(200) - 100;

      FilteredColor.A := 0; // Alpha-channels, not used
      OriginalColor.A := 0;

      OriginalColor.R := Random(255);
      OriginalColor.G := Random(255);
      OriginalColor.B := Random(255);
    end;
end;

{============================ MOVEMENT ==============================}

procedure TGravityWindow.MovePixels;
var
  now: Integer; // Current time in milliseconds
  elapsedTime: Real; // Elapsed time since last frame in seconds
  i: Integer;
begin
  GetCursorPos(FCursor);

  now := GetTickCount;
  elapsedTime := (now - FLastTime) / 1000;
  FLastTime := now;

  { Now we know the gravity target (the cursor position) and the
    elapsed time. Let's move the pixels around! }

  for i := 0 to PIXEL_COUNT - 1 do
    UpdatePixel(@FPixels[i], elapsedTime);
end;

procedure TGravityWindow.UpdatePixel(const Pixel: PMyPixel; const ElapsedTime: Real);
var
  vector: TRealPoint;
begin
  { Determine direction to move in. In other words, a vector from
    the pixel to the cursor. }

  vector.X := FCursor.X - (FForm.ClientOrigin.X + Pixel.Position.X);
  vector.Y := FCursor.Y - (FForm.ClientOrigin.Y + Pixel.Position.Y);

  { Increase the speed in that direction. This change in speed
    depends on the elapsed time. }

  Pixel.Speed.X := Pixel.Speed.X + vector.X * ElapsedTime;
  Pixel.Speed.Y := Pixel.Speed.Y + vector.Y * ElapsedTime;

  { Add some randomness to the speed, this makes the pixels swirl
    around a bit. :) }

  Pixel.Speed.X := Pixel.Speed.X + 100 * (Random - 0.5) * ElapsedTime;
  Pixel.Speed.Y := Pixel.Speed.Y + 100 * (Random - 0.5) * ElapsedTime;

  { Slow them down a little, otherwise they would keep rotating
    around the center of gravity or keep bouncing against walls.
    This also depends on the elapsed time since the last frame. }

  Pixel.Speed.X := (1 - 0.1 * ElapsedTime) * Pixel.Speed.X;
  Pixel.Speed.Y := (1 - 0.1 * ElapsedTime) * Pixel.Speed.Y;

  { Alright, now we know the new speed of this pixel. Time to move
    the pixel to it's new position! Of course this movement also
    depends on the elapsed time. }

  Pixel.Position.X := Pixel.Position.X + Pixel.Speed.X * ElapsedTime;
  Pixel.Position.Y := Pixel.Position.Y + Pixel.Speed.Y * ElapsedTime;

  { Now let's see if we have bounced against a wall... If the pixel went
    for example 20 pixels past a side, we put the pixel back 20 pixels
    inside the wall, plus we reverse the speed. }

  if Pixel.Position.X < 0 then { Left border }
  begin
    Pixel.Position.X := -Pixel.Position.X;

    { Let's change the speed when a pixel hits a wall! By applying a
      random factor of -50% to +50%, it either slows down to half
      its original speed, or it speeds up by 50%, or anything in
      between. This looks really explosive when pixels hit a wall.
      They will fly everywhere! }
      
    Pixel.Speed.X := -1 * (0.5 + Random) * Pixel.Speed.X;
  end;

  if Pixel.Position.Y < 0 then { Top border }
  begin
    Pixel.Position.Y := -Pixel.Position.Y;
    Pixel.Speed.Y := -1 * (0.5 + Random) * Pixel.Speed.Y;
  end;

  if Pixel.Position.X >= FForm.ClientWidth then { Right border }
  begin
    Pixel.Position.X := -Pixel.Position.X + 2 * FForm.ClientWidth;
    Pixel.Speed.X := -1 * (0.5 + Random) * Pixel.Speed.X;
  end;

  if Pixel.Position.Y >= FForm.ClientHeight then { Bottom border }
  begin
    Pixel.Position.Y := -Pixel.Position.Y + 2 * FForm.ClientHeight;
    Pixel.Speed.Y := -1 * (0.5 + Random) * Pixel.Speed.Y;
  end;
end;

{============================ CLEARING ==============================}

procedure TGravityWindow.ClearBitmap;
var
  w, h: Integer;
begin
  w := FBitmap.Width;
  h := FBitmap.Height;

  ZeroBitmap(FRows[h - 1], w * h);
end;

procedure TGravityWindow.ZeroBitmap(Bitmap: Pointer; Count: Integer); assembler;
asm
  { I think this is the fastest way to clear a bitmap.
    EDX holds the pointer to the bitmap. ECX hold the Count value. }

  mov edi, edx
  xor eax, eax
  rep stosd

  { "mov edi, edx" (move Bitmap -> EDI)
      This stores the Bitmap pointer in EDI (Destination Index).

    "xor eax, eax" (eXclusive OR of EAX and EAX)
      An exclusive or of a number on itself always results in 0.
      This is faster than 'mov eax, 0'. We only do this once for
      clearing the whole frame, so you will not notice ANY change in
      speed whatsoever in this application, but this is just for
      educational purposes. We are working with graphics here, and
      working with graphics demands any optimization you can find.
      Besides, there's no reason why we would not use this
      method, right?

    "rep stosd" (repeat store string double)
      This is where the magic happens. REP STOSD does multiple
      things: it stores EAX into [EDI], then it increases EDI by 4,
      then it decreases ECX (the counter) and finally if the counter
      is not 0, it repeats itself. Great all-in-one instruction!

    Basically REP STOSD is the same as this:

      repeat
        Integer(Bitmap^) := 0;
        inc(Integer(Bitmap), 4);
        dec(Count);
      until (Count = 0);

    Or in ASM:

      @myLoop:          Label of the start of the loop
        mov [edx], 0    Put 0 in [edx]
        inc edx, 4      Move 4 bytes forward to the next pixel,
        dec ecx         decrease the counter by 1,
        jnz @myLoop     and repeat, as long as ECX is not zero.

    Or this:

      @myLoop:
        mov [edx], 0
        inc edx, 4
        loop @myLoop    'loop' takes care of decreasing the counter.

    But using REP STOSD is easier to read and faster for big chunks
    of memory. Here is an interesting discussion and test of
    different approaches for zero-ing a piece of memory:

    http://www.masm32.com/board/index.php?topic=6576.0
  }
end;

{============================ DRAWING ===============================}

procedure TGravityWindow.DrawPixels;
var
  i, x, y, w, h: Cardinal;
  p: PMyPixel;
  location, color: DWORD;
begin
  { You can choose between ClearBitmap and BlurBitmap. }

  //ClearBitmap;
  BlurBitmap;

  w := FForm.ClientWidth;
  h := FForm.ClientHeight;

  ApplyColorFilter;

  for i := 0 to PIXEL_COUNT - 1 do
  begin
    p := @FPixels[i];

    { This assigns a pointer to the pixel. We call it 'p'. Using a
      simple pointer like this instead of using the full
      'FPixels[i]' all the time, makes the code much more readable.
      Next we check if the pixel is within the frame borders, just
      to be sure. Resizing the window to a smaller size may put
      pixels outside the window. Even when we would not resize the
      window, it never hurts to double-check the position of each
      pixel. All this checking does have impact on the speed of the
      application of course and there is probably a faster solution.
      In the ideal situation, I would convert the whole application
      to assembler, but this a delphi contest and I want to leave
      some actual pascal in here. ;) }

    if (p.Position.X < 0) or (p.Position.X >= w) or
      (p.Position.Y < 0) or (p.Position.Y >= h) then continue;

    y := Floor(p.Position.Y);
    x := Floor(p.Position.X);

    { We need the exact memory location of the pixel. FRows[y]
      points to the start of the row. Every pixel uses 4 bytes, so
      the actual memory offset is 4 times X. To multiply by 4, we
      can simply shift 2 bits to the left. I typecast our own
      packed color record to a DWORD, because that's what this
      packed color record actually is in the bitmap, a double word. }

    location := DWORD(FRows[y]) + x shl 2;
    color := DWORD(p.FilteredColor);
    SetPixel(location, color);

    { We can not simply do something like 'location^ := color'
      because that only sets 1 byte. And we want to set 4 bytes at
      once. We could do something like:

      FRows[y][x shl 2 +0] := p.Color.A;
      FRows[y][x shl 2 +1] := p.Color.R;
      FRows[y][x shl 2 +2] := p.Color.G;
      FRows[y][x shl 2 +3] := p.Color.B;

      But I can't imagine that that's faster. So I use a really
      small asm routine to set 4 bytes at once. }
  end;
end;

procedure TGravityWindow.ApplyColorFilter;
var
  tc, interval, fraction, i: Integer;
begin
  tc := GetTickCount;
  interval := (tc and (4 * 16384 - 1)) shr 14; // 4 intervals of 16 seconds
  fraction := tc and 16383; // time within an interval

  if interval = 0 then // First interval, red/green --> blue/green
    for i := 0 to PIXEL_COUNT - 1 do
      with FPixels[i] do
      begin
        FilteredColor.R := (OriginalColor.R * (16384 - fraction)) shr 14;
        FilteredColor.G := OriginalColor.G; // fixed
        FilteredColor.B := (OriginalColor.B * fraction) shr 14;
      end;

  if interval = 1 then // Second interval, blue/green --> blue/red
    for i := 0 to PIXEL_COUNT - 1 do
      with FPixels[i] do
      begin
        FilteredColor.R := (OriginalColor.R * fraction) shr 14;
        FilteredColor.G := (OriginalColor.G * (16384 - fraction)) shr 14;
        FilteredColor.B := OriginalColor.B; // fixed
      end;

  if interval = 2 then // Third interval, blue/red --> all colors
    for i := 0 to PIXEL_COUNT - 1 do
      with FPixels[i] do
      begin
        FilteredColor.R := OriginalColor.R;
        FilteredColor.G := (OriginalColor.G * fraction) shr 14;
        FilteredColor.B := OriginalColor.B;
      end;

  if interval = 3 then // Fourth interval, all colors --> red/green
    for i := 0 to PIXEL_COUNT - 1 do
      with FPixels[i] do
      begin
        FilteredColor.R := OriginalColor.R;
        FilteredColor.G := OriginalColor.G;
        FilteredColor.B := (OriginalColor.B * (16384 - fraction)) shr 14;
      end;
end;

procedure TGravityWindow.SetPixel(Location, Value: DWORD); assembler;
asm
  mov [edx], ecx
end;

procedure TGravityWindow.BlurBitmap;
var
  y, offset: Cardinal;
  w, h: Integer;
begin
  w := FForm.ClientWidth;
  h := FForm.ClientHeight;

  { We take 1 pixel, plus the 3 pixels below this top pixel, like this...

        +---+
        | 1 |
    +---+---+---+
    | 2 | 3 | 4 |
    +---+---+---+

    ...and then we take the average and put that back in the top
    pixel. We skip the bottom row of the bitmap (because obviously
    there are no pixels to average below the bottom row) and we skip
    the left and right column, because they have no pixels left and
    right of them. }

  for y := 0 to h - 2 do
    BlurRow(FRows[y], FRows[y + 1], w);

  // Make the left, right and bottom borders black
  offset := 4 * (w - 1); // the x value of the right border
  for y := 0 to h - 2 do
  begin
    SetPixel(DWORD(FRows[y]), 0); // left
    SetPixel(DWORD(FRows[y]) + offset, 0); // right
  end;

  ZeroBitmap(FRows[h - 1], w);
end;

procedure TGravityWindow.BlurRow(ThisRow, NextRow: Pointer; Width: Integer); assembler;
asm
  { The first and second arguments are always put in the
    registers EDX and ECX. The rest is accessible through their
    variable names as we will see in a moment.

    So EAX = available, EBX = reserved, EDX = ThisRow, ECX = NextRow.

    At the end of this procedure, EBX must still contain the same
    value as EBX had at the start. That's a requirement in pure
    assembler functions, because EBX contains the memory location to
    where the application should jump back to, once this procedure
    has ended. But we need EBX for ourselves! So we push EBX onto the
    stack to save it. At the end of this procedure, we will pull
    this original value of EBX off the stack, so that EBX has its
    original value again. }

  push ebx

  { Now EAX = available, EBX = available, ECX = row 2, EDX = row 1.
    We need ECX as the counter register, so we move the current
    contents of EBX (which is the pointer to row 2) onto EBX. }

  mov ebx, ecx

  { Now EAX = available, EBX = row 2, ECX = available, EDX = row 1.
    Now we will put the Width argument of this procedure into ECX.
    That's our pixel counter for the loop. }

  mov ecx, Width

  //  |    Pixel 1    |    Pixel 2    |    Pixel 3    |

  //  +---+---+---+---+---+---+---+---+---+---+---+---+
  //  | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |10 |11 |12 |  Row 1 ('ThisRow')
  //  +---+---+---+---+---+---+---+---+---+---+---+---+
  //  | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |10 |11 |12 |  Row 2 ('NextRow')
  //  +---+---+---+---+---+---+---+---+---+---+---+---+
  //
  //    A   B   G   R   A   B   G   R   A   B   G   R

  { These are the first 3 pixels of 2 lines (or rows, whatever you
    wanna call them.) Every pixel takes up 4 bytes: Red, green, blue
    and an alpha channel. The order is ABGR. The alpha channel is
    not being used. So we have have 4 bytes per pixel, which means
    this is a 32 bits bitmap. (4 * 8 bits = 32 bits.) We could have
    used a 24 bits bitmap (with 3 bytes per pixel), but 32 bits
    bitmaps are often easier to handle, because working with 4 bytes
    is often easier/faster than 3 bytes. For example, dividing by 4
    is easier and faster than dividing by 3. Dividing by 4 can
    simply be done by shifting a value 2 bits to the right, whereas
    dividing by 3 takes an actual calculation. There are more
    examples to think of, so working with 32 bits bitmaps is usually
    easier and faster to work with when you do graphics.

    The idea is to average 4 pixels: Pixel 2 from row 1, and the 3
    pixels from row 2. Why are we adding the center pixel from
    row 1? Because then we have 4 pixels and like I just explained,
    averaging 4 pixels (dividing by 4) is much faster than dividing
    by 3. This difference in speed will not make much of a
    difference, if you use it for just a handful divisions, but when
    you're having like a 1280x1024 screen and you want to reach at
    least 25 FPS, then we're facing about 98 million divisions per
    second. Do the math. ;)

        +---+
        | 1 |
    +---+---+---+
    | 2 | 3 | 4 |
    +---+---+---+

    So that is what we do. We calculate take the average of these 4
    values and put that average back into byte 1, the top pixel. The
    leftmost pixel in a row does not have a pixel at its bottom
    left (that would lay outside of the bitmap), which is why we
    skip the leftmost pixel in reach row. The same counts for the
    rightmost pixel in each row. So we will loop through all the
    pixels in the row, except the leftmost and rightmost pixel.
    Therefore, we need to subtract 2 from the counter. }

  sub ecx, 2

  { EAX = available, EBX = row 2, ECX = counter, EDX = row 1.

    The pointer in row 1 is still pointing to the pixel left of
    byte 1 so we need to move the pointer forward by 1 pixel.
    That's 4 bytes of course: RGBA. }

  add edx, 4

  { Alright, we're all set. Time to start the blurring loop! Or
    actually I should say loops. We have an 'outer loop' and
    an 'inner loop'. The outer loop walks through all the pixels,
    one by one. The inner loop repeats 3 times for every pixel: once
    for red, for green and for blue. We skip the alpha channel. }

  @outerLoop:                 { the start of the 'pixel loop' }

    push ecx                  { Save the pixel counter, we
                                need ECX for the inner loop. }

    mov ecx, 3                { Set the counter to 3. }

  @innerLoop:                 { start of the 'RGB loop' }

    xor eax, eax              { We will use EAX to calculate the
                                sum of the 4 bytes. First we set EAX
                                to 0. We could do 'mov eax, 0' but
                                it is usual to do that with xor. }

  { Now we will calculate the sum of the 4 bytes.

        +---+
        | 1 |
    +---+---+---+
    | 2 | 3 | 4 |
    +---+---+---+
  }

    mov byte ptr al, [edx]    { Move byte 1 into AL. EAX is a DWORD,
                                a 4 byte register, but we only want
                                to copy 1 byte. That is why we copy
                                [EDX] to AL (the first byte of EAX)
                                instead of EAX. If we would copy
                                [EDX] to EAX, then 4 bytes would
                                be copied. }

    { |   Extra 16 bits   | High (AH) | Low  (AL) |
      +---------+---------+-----------+-----------+
      |         |         |           |           |
      |    4    |    3    |     2     |     1     |
      |         |         |           |           |
      +---------+---------+-----------+-----------+

       4 * 8 bits = 32 bits register EAX
    }


    add byte ptr al, [ebx]    { And add byte 2... }

    { Now because we have put another byte in AL, AL could overflow.
      Remember, a byte value can be 255 max! What happens if AL
      overflows 255? Then the so-called 'carry bit' is set. We check
      for that. If the carry bit is set, then we need to add 1 to
      the byte next to AL, called AH. (AL and AH stand for
      Accumulator Low and High.) In fact, we check if the carry bit
      is NOT set. If that is the case, then we skip the code
      for adding 1 to that byte, by jumping over it! }

    jnc @cont1                { Jump Not Carry, to label @cont1. }
    inc ah                    { Otherwise increase AH by 1.. }
    clc                       { ..and clear the carry bit again. }

  @cont1:                     { (cont as in continue) }

    add byte ptr al, [ebx+4]  { Now add byte 3. That's 4 bytes
                                offset from EBX. }
    jnc @cont2                { Same carry checks again... }
    inc ah
    clc

  @cont2:

    add byte ptr al, [ebx+8]  { Add byte 4... }
    jnc @cont3                { bla bla }
    inc ah
    clc

  @cont3:

    shr eax, 2                { Alright, we have all 4 bytes summed
                                up in EAX! Now we divide EAX by 4,
                                simply by shifting the whole
                                register 2 bits to the right. }

    mov byte ptr [edx], al    { And put the result back in byte 1! }

    inc edx                   { Time for the next color of the 3.. }
    inc ebx                   { ..by increasing the pointers of
                                both rows by 1 byte. }

    loop @innerLoop           { Ok, next color! This loops back to the
                                label @innerLoop until ECX is 0.
                                This loop function automatically
                                decreases ECX by 1 everytime. }

  { Ok, at this point the loop seems to be done because 'loop' hasn't
    jumped back to @innerLoop. So all 3 colors are averaged in this
    pixel. Next would be the alpha channel, but we skip that because
    it doesn't do anything. Move both pointers another byte forward.. }

    inc edx                   { row 1, increase pointer by 1 byte }
    inc ebx                   { row 2, increase pointer by 1 byte }

  { Retrieve the pixel counter, that we had put on the stack,
    just before the inner loop started. }

    pop ecx

    loop @outerLoop           { Alright, next pixel! That completes
                                the outer loop. }

  { And remember that we put EBX on the stack, at the start of the
    procedure? Now we pop EBX back from the stack. }

    pop ebx                   { That's all! }
end;

end.

