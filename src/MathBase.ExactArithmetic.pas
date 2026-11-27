unit MathBase.ExactArithmetic;

{ Exact integers and rationals. All published limb arrays are immutable.
  Assignment may share a buffer, but operations write only owned scratch. }

{$mode objfpc}{$H+}{$J-}
{$modeswitch advancedrecords}

interface

uses
  SysUtils;

const
  MaxExactIntegerBits = 131072;

type
  EExactArithmeticError = class(Exception);
  TExactRadix = (erDecimal, erHexadecimal);

  TBigInteger = record
  private type
    TLimbArray = array of LongWord;
  private
    FLimbs: TLimbArray;
    FNegative: Boolean;
  public
    class function FromInt64(Value: Int64): TBigInteger; static;
    class function FromDouble(Value: Double): TBigInteger; static;
    class function Parse(const Text: String; Radix: TExactRadix = erDecimal): TBigInteger; static;
    function ToText(Radix: TExactRadix = erDecimal): String;
    function TryToInt64(out Value: Int64): Boolean;
    function TryToDouble(out Value: Double): Boolean;
    function IsZero: Boolean;
    function CompareTo(const Other: TBigInteger): Integer;
    function Power(Exponent: QWord): TBigInteger;
    class function GCD(const Left, Right: TBigInteger): TBigInteger; static;
    class operator +(const Left, Right: TBigInteger): TBigInteger;
    class operator -(const Left, Right: TBigInteger): TBigInteger;
    class operator -(const Value: TBigInteger): TBigInteger;
    class operator *(const Left, Right: TBigInteger): TBigInteger;
  end;

  TBigIntegerDivision = record
    Quotient, Remainder: TBigInteger;
  end;

  { Default values represent zero. Numerator and Denominator return
    independent immutable values in lowest terms, with Denominator > 0. }
  TBigRational = record
  private
    FNumerator, FDenominator: TBigInteger;
    function GetDenominator: TBigInteger;
  public
    class function FromRatio(const Numerator, Denominator: TBigInteger): TBigRational; static;
    class function FromInt64(Value: Int64): TBigRational; static;
    class function FromDouble(Value: Double): TBigRational; static;
    class function Parse(const Text: String; Radix: TExactRadix = erDecimal): TBigRational; static;
    function ToText(Radix: TExactRadix = erDecimal): String;
    function TryToInt64(out Value: Int64): Boolean;
    function TryToDouble(out Value: Double): Boolean;
    function CompareTo(const Other: TBigRational): Integer;
    property Numerator: TBigInteger read FNumerator;
    property Denominator: TBigInteger read GetDenominator;
    class operator +(const Left, Right: TBigRational): TBigRational;
    class operator -(const Left, Right: TBigRational): TBigRational;
    class operator -(const Value: TBigRational): TBigRational;
    class operator *(const Left, Right: TBigRational): TBigRational;
    class operator /(const Left, Right: TBigRational): TBigRational;
  end;

{ Truncate toward zero. A nonzero remainder has the sign of the dividend. }
function DivideWithRemainder(const Dividend, Divisor: TBigInteger): TBigIntegerDivision;

implementation

type
  TLimbArray = TBigInteger.TLimbArray;

const
  LimbBits = 32;
  LimbBase: QWord = QWord(1) shl LimbBits;
  LimbMask: QWord = High(LongWord);
  MaxLimbs = MaxExactIntegerBits div LimbBits;
  MaxScratchLimbs = 2 * MaxLimbs + 1;
  MaxDecimalDigits = 39457;
  MaxHexDigits = MaxExactIntegerBits div 4;
  DecimalChunkBase = 1000000000;
  DecimalChunkDigits = 9;
  HexSymbols = '0123456789ABCDEF';
  Binary64FractionBits = 52;
  Binary64ExponentBias = 1023;
  Binary64MinExponent = -1022;
  Binary64MinSubnormalExponent = -1074;
  Binary64Sign: QWord = QWord(1) shl 63;
  Binary64HiddenBit: QWord = QWord(1) shl Binary64FractionBits;
  Binary64FractionMask: QWord = (QWord(1) shl Binary64FractionBits) - 1;
  Binary64ExponentMask = 2047;

procedure CheckLength(Count, Limit: SizeInt);
begin
  if Count > Limit then
    raise EExactArithmeticError.Create('Exact integer magnitude exceeds the supported size');
end;

procedure Trim(var Limbs: TLimbArray);
var
  Count: SizeInt;
begin
  Count := Length(Limbs);
  while (Count > 0) and (Limbs[Count - 1] = 0) do
    Dec(Count);
  if Count <> Length(Limbs) then
    SetLength(Limbs, Count);
end;

function MakeInteger(const Limbs: TLimbArray; Negative: Boolean): TBigInteger;
begin
  Result.FLimbs := Limbs;
  Result.FNegative := Negative and (Length(Limbs) <> 0);
end;

function UnsignedLimbs(Value: QWord): TLimbArray;
begin
  Result := nil;
  if Value = 0 then
    Exit;
  if Value > LimbMask then
    SetLength(Result, 2)
  else
    SetLength(Result, 1);
  Result[0] := LongWord(Value and LimbMask);
  if Length(Result) = 2 then
    Result[1] := LongWord(Value shr LimbBits);
end;

function ToUnsignedWordPair(const Limbs: TLimbArray): QWord;
begin
  Result := 0;
  if Length(Limbs) > 0 then
    Result := Limbs[0];
  if Length(Limbs) = 2 then
    Result := Result or (QWord(Limbs[1]) shl LimbBits);
end;

function CompareMagnitude(const Left, Right: TLimbArray): Integer;
var
  I: SizeInt;
begin
  if Length(Left) < Length(Right) then
    Exit(-1);
  if Length(Left) > Length(Right) then
    Exit(1);
  for I := High(Left) downto 0 do
  begin
    if Left[I] < Right[I] then
      Exit(-1);
    if Left[I] > Right[I] then
      Exit(1);
  end;
  Result := 0;
end;

function DecodeDigit(Symbol: Char; Base: LongWord): LongWord;
begin
  case Symbol of
    '0'..'9': Result := Ord(Symbol) - Ord('0');
    'A'..'F': Result := Ord(Symbol) - Ord('A') + 10;
    'a'..'f': Result := Ord(Symbol) - Ord('a') + 10;
  else
    raise EExactArithmeticError.Create('Invalid exact integer digit');
  end;
  if Result >= Base then
    raise EExactArithmeticError.Create('Digit is outside the selected radix');
end;

function DigitLimit(Radix: TExactRadix): SizeInt;
begin
  case Radix of
    erDecimal: Result := MaxDecimalDigits;
    erHexadecimal: Result := MaxHexDigits;
  else
    raise EExactArithmeticError.Create('Unsupported exact integer radix');
  end;
end;

procedure MultiplyAddWord(var Limbs: TLimbArray; var Used: SizeInt;
  Multiplier, Digit: LongWord);
var
  I: SizeInt;
  Value, Carry: QWord;
begin
  Carry := Digit;
  for I := 0 to Used - 1 do
  begin
    Value := QWord(Limbs[I]) * Multiplier + Carry;
    Limbs[I] := LongWord(Value and LimbMask);
    Carry := Value shr LimbBits;
  end;
  if Carry <> 0 then
  begin
    CheckLength(Used + 1, Length(Limbs));
    Limbs[Used] := LongWord(Carry);
    Inc(Used);
  end;
end;

function DivideWordInPlace(var Limbs: TLimbArray; Used: SizeInt; Divisor: LongWord): LongWord;
var
  I: SizeInt;
  Current, Remainder: QWord;
begin
  Remainder := 0;
  for I := Used - 1 downto 0 do
  begin
    Current := (Remainder shl LimbBits) or Limbs[I];
    Limbs[I] := LongWord(Current div Divisor);
    Remainder := Current mod Divisor;
  end;
  Result := LongWord(Remainder);
end;

function ParseHex(const Text: String; First: SizeInt): TLimbArray;
var
  I, Offset: SizeInt;
  Digit: LongWord;
begin
  Result := nil;
  SetLength(Result, (Length(Text) - First + 8) div 8);
  for I := Length(Text) downto First do
  begin
    Offset := Length(Text) - I;
    Digit := DecodeDigit(Text[I], 16);
    Result[Offset div 8] := Result[Offset div 8] or (Digit shl (4 * (Offset mod 8)));
  end;
  Trim(Result);
end;

function ParseDecimal(const Text: String; First: SizeInt): TLimbArray;
var
  I, Capacity, Used, ChunkLength: SizeInt;
  Digit, Multiplier: LongWord;
begin
  Result := nil;
  Capacity := (Length(Text) - First + DecimalChunkDigits) div DecimalChunkDigits;
  if Capacity > MaxLimbs then
    Capacity := MaxLimbs;
  SetLength(Result, Capacity);
  Used := 0;
  I := First;
  while I <= Length(Text) do
  begin
    Digit := 0;
    Multiplier := 1;
    ChunkLength := 0;
    while (I <= Length(Text)) and (ChunkLength < DecimalChunkDigits) do
    begin
      Digit := 10 * Digit + DecodeDigit(Text[I], 10);
      Multiplier := 10 * Multiplier;
      Inc(I);
      Inc(ChunkLength);
    end;
    MultiplyAddWord(Result, Used, Multiplier, Digit);
  end;
  SetLength(Result, Used);
end;

function WriteHex(const Limbs: TLimbArray; Negative: Boolean): String;
var
  Offset, First: SizeInt;
  Digit: LongWord;
begin
  SetLength(Result, Length(Limbs) * 8 + 1);
  for Offset := 0 to Length(Limbs) * 8 - 1 do
  begin
    Digit := (Limbs[Offset div 8] shr (4 * (Offset mod 8))) and 15;
    Result[Length(Result) - Offset] := HexSymbols[Digit + 1];
  end;
  First := 2;
  while Result[First] = '0' do
    Inc(First);
  if Negative then
  begin
    Dec(First);
    Result[First] := '-';
  end;
  Result := Copy(Result, First, Length(Result) - First + 1);
end;

function WriteDecimal(const Limbs: TLimbArray; Negative: Boolean): String;
var
  Scratch: TLimbArray;
  Cursor, Used, DigitCount: SizeInt;
  Chunk: LongWord;
begin
  Scratch := Copy(Limbs);
  Used := Length(Scratch);
  SetLength(Result, Used * 10 + 1);
  Cursor := Length(Result);
  while Used > 0 do
  begin
    Chunk := DivideWordInPlace(Scratch, Used, DecimalChunkBase);
    while (Used > 0) and (Scratch[Used - 1] = 0) do
      Dec(Used);
    DigitCount := 0;
    repeat
      Result[Cursor] := Chr(Ord('0') + Chunk mod 10);
      Dec(Cursor);
      Chunk := Chunk div 10;
      Inc(DigitCount);
    until (Chunk = 0) and ((Used = 0) or (DigitCount = DecimalChunkDigits));
  end;
  if Negative then
  begin
    Result[Cursor] := '-';
    Dec(Cursor);
  end;
  Result := Copy(Result, Cursor + 1, Length(Result) - Cursor);
end;

class function TBigInteger.FromInt64(Value: Int64): TBigInteger;
var
  Magnitude: QWord;
begin
  if Value < 0 then
    Magnitude := QWord(-(Value + 1)) + 1
  else
    Magnitude := QWord(Value);
  Result := MakeInteger(UnsignedLimbs(Magnitude), Value < 0);
end;

class function TBigInteger.Parse(const Text: String; Radix: TExactRadix): TBigInteger;
var
  First, DigitCount: SizeInt;
  Negative: Boolean;
begin
  if Text = '' then
    raise EExactArithmeticError.Create('Missing exact integer digits');
  First := 1;
  Negative := Text[1] = '-';
  if Text[1] in ['+', '-'] then
    Inc(First);
  DigitCount := Length(Text) - First + 1;
  if DigitCount = 0 then
    raise EExactArithmeticError.Create('Missing exact integer digits');
  if DigitCount > DigitLimit(Radix) then
    raise EExactArithmeticError.Create('Exact integer text exceeds the supported digit count');
  if Radix = erDecimal then
    Result := MakeInteger(ParseDecimal(Text, First), Negative)
  else
    Result := MakeInteger(ParseHex(Text, First), Negative);
end;

function TBigInteger.ToText(Radix: TExactRadix): String;
begin
  if IsZero then
    Exit('0');
  case Radix of
    erDecimal: Result := WriteDecimal(FLimbs, FNegative);
    erHexadecimal: Result := WriteHex(FLimbs, FNegative);
  else
    raise EExactArithmeticError.Create('Unsupported exact integer radix');
  end;
end;

function TBigInteger.TryToInt64(out Value: Int64): Boolean;
const
  MinInt64Magnitude: QWord = QWord(High(Int64)) + 1;
var
  Magnitude: QWord;
begin
  Value := 0;
  if Length(FLimbs) > 2 then
    Exit(False);
  Magnitude := ToUnsignedWordPair(FLimbs);
  if FNegative and (Magnitude = MinInt64Magnitude) then
  begin
    Value := Low(Int64);
    Exit(True);
  end;
  if Magnitude > QWord(High(Int64)) then
    Exit(False);
  Value := Int64(Magnitude);
  if FNegative then
    Value := -Value;
  Result := True;
end;

function TBigInteger.IsZero: Boolean;
begin
  Result := Length(FLimbs) = 0;
end;

function TBigInteger.CompareTo(const Other: TBigInteger): Integer;
begin
  if FNegative <> Other.FNegative then
  begin
    if FNegative then
      Exit(-1);
    Exit(1);
  end;
  Result := CompareMagnitude(FLimbs, Other.FLimbs);
  if FNegative then
    Result := -Result;
end;

function AddMagnitude(const Left, Right: TLimbArray): TLimbArray;
var
  I, Count: SizeInt;
  Carry, Value: QWord;
begin
  Result := nil;
  Count := Length(Left);
  if Length(Right) > Count then
    Count := Length(Right);
  CheckLength(Count + 1, MaxScratchLimbs);
  SetLength(Result, Count + 1);
  Carry := 0;
  for I := 0 to Count - 1 do
  begin
    Value := Carry;
    if I < Length(Left) then
      Value := Value + Left[I];
    if I < Length(Right) then
      Value := Value + Right[I];
    Result[I] := LongWord(Value and LimbMask);
    Carry := Value shr LimbBits;
  end;
  Result[Count] := LongWord(Carry);
  Trim(Result);
end;

{ Left has magnitude at least Right. }
function SubtractMagnitude(const Left, Right: TLimbArray): TLimbArray;
var
  I: SizeInt;
  Value, Borrow: QWord;
begin
  Result := nil;
  SetLength(Result, Length(Left));
  Borrow := 0;
  for I := 0 to High(Left) do
  begin
    Value := LimbBase + Left[I] - Borrow;
    if I < Length(Right) then
      Value := Value - Right[I];
    Result[I] := LongWord(Value and LimbMask);
    Borrow := Ord(Value < LimbBase);
  end;
  Trim(Result);
end;

function MultiplyMagnitude(const Left, Right: TLimbArray): TLimbArray;
var
  I, J: SizeInt;
  Carry, Value: QWord;
begin
  Result := nil;
  if (Length(Left) = 0) or (Length(Right) = 0) then
    Exit;
  CheckLength(Length(Left) + Length(Right), MaxScratchLimbs);
  SetLength(Result, Length(Left) + Length(Right));
  for I := 0 to High(Left) do
  begin
    if Left[I] = 0 then
      Continue;
    Carry := 0;
    for J := 0 to High(Right) do
    begin
      Value := QWord(Left[I]) * Right[J] + Result[I + J] + Carry;
      Result[I + J] := LongWord(Value and LimbMask);
      Carry := Value shr LimbBits;
    end;
    Result[I + Length(Right)] := LongWord(Carry);
  end;
  Trim(Result);
end;

function AddSigned(const Left, Right: TBigInteger): TBigInteger;
begin
  if Left.FNegative = Right.FNegative then
    Exit(MakeInteger(AddMagnitude(Left.FLimbs, Right.FLimbs), Left.FNegative));
  if CompareMagnitude(Left.FLimbs, Right.FLimbs) >= 0 then
    Result := MakeInteger(SubtractMagnitude(Left.FLimbs, Right.FLimbs), Left.FNegative)
  else
    Result := MakeInteger(SubtractMagnitude(Right.FLimbs, Left.FLimbs), Right.FNegative);
end;

class operator TBigInteger.+(const Left, Right: TBigInteger): TBigInteger;
begin
  Result := AddSigned(Left, Right);
  CheckLength(Length(Result.FLimbs), MaxLimbs);
end;

class operator TBigInteger.-(const Value: TBigInteger): TBigInteger;
begin
  Result := MakeInteger(Value.FLimbs, not Value.FNegative);
end;

class operator TBigInteger.-(const Left, Right: TBigInteger): TBigInteger;
begin
  Result := Left + (-Right);
end;

function MultiplySigned(const Left, Right: TBigInteger): TBigInteger;
begin
  Result := MakeInteger(MultiplyMagnitude(Left.FLimbs, Right.FLimbs),
    Left.FNegative xor Right.FNegative);
end;

class operator TBigInteger.*(const Left, Right: TBigInteger): TBigInteger;
begin
  Result := MultiplySigned(Left, Right);
  CheckLength(Length(Result.FLimbs), MaxLimbs);
end;

function ShiftLeft(const Limbs: TLimbArray; Count: Integer): TLimbArray;
var
  I, WordShift, BitShift: SizeInt;
  Carry, WordValue: QWord;
begin
  Result := nil;
  if Length(Limbs) = 0 then
    Exit;
  WordShift := Count div LimbBits;
  BitShift := Count mod LimbBits;
  SetLength(Result, Length(Limbs) + WordShift + 1);
  Carry := 0;
  for I := 0 to High(Limbs) do
  begin
    WordValue := (QWord(Limbs[I]) shl BitShift) or Carry;
    Result[I + WordShift] := LongWord(WordValue and LimbMask);
    Carry := WordValue shr LimbBits;
  end;
  Result[Length(Limbs) + WordShift] := LongWord(Carry);
  Trim(Result);
end;

procedure UndoNormalization(var Limbs: TLimbArray; Shift: Integer);
var
  I: SizeInt;
  WordValue, Carry, Mask: QWord;
begin
  if Shift = 0 then
    Exit;
  Carry := 0;
  Mask := (QWord(1) shl Shift) - 1;
  for I := High(Limbs) downto 0 do
  begin
    WordValue := (Carry shl LimbBits) or Limbs[I];
    Carry := WordValue and Mask;
    Limbs[I] := LongWord((WordValue shr Shift) and LimbMask);
  end;
end;

function LeadingZeroBits(Value: LongWord): Integer;
var
  TopBit: LongWord;
begin
  Result := 0;
  TopBit := LongWord(1) shl (LimbBits - 1);
  while (Value and TopBit) = 0 do
  begin
    Inc(Result);
    TopBit := TopBit shr 1;
  end;
end;

{ Knuth Algorithm D. The normalized dividend has one extra guard limb.
  The high two limbs estimate each quotient digit, then the next divisor
  limb corrects it. An underflow in the subtraction needs one add-back. }
procedure DivideMultipleLimbs(const Dividend, Divisor: TLimbArray;
  out Quotient, Remainder: TLimbArray);
var
  U, V: TLimbArray;
  Shift: Integer;
  I, J, N, M: SizeInt;
  TopDivisor, Numerator, Guess, Residue, Product, Borrow, WordValue, Carry: QWord;
begin
  N := Length(Dividend);
  M := Length(Divisor);
  Shift := LeadingZeroBits(Divisor[M - 1]);
  U := ShiftLeft(Dividend, Shift);
  V := ShiftLeft(Divisor, Shift);
  SetLength(U, N + 1);
  SetLength(Quotient, N - M + 1);
  TopDivisor := V[M - 1];
  for J := N - M downto 0 do
  begin
    if U[J + M] = TopDivisor then
    begin
      Guess := LimbMask;
      Residue := TopDivisor + U[J + M - 1];
    end
    else
    begin
      Numerator := (QWord(U[J + M]) shl LimbBits) or U[J + M - 1];
      Guess := Numerator div TopDivisor;
      Residue := Numerator mod TopDivisor;
    end;
    while (Residue < LimbBase) and
      (Guess * V[M - 2] > ((Residue shl LimbBits) or U[J + M - 2])) do
    begin
      Dec(Guess);
      Residue := Residue + TopDivisor;
    end;

    Borrow := 0;
    for I := 0 to M - 1 do
    begin
      Product := Guess * V[I] + Borrow;
      WordValue := LimbBase + U[J + I] - (Product and LimbMask);
      U[J + I] := LongWord(WordValue and LimbMask);
      Borrow := (Product shr LimbBits) + Ord(WordValue < LimbBase);
    end;
    WordValue := LimbBase + U[J + M] - Borrow;
    U[J + M] := LongWord(WordValue and LimbMask);
    if WordValue < LimbBase then
    begin
      Dec(Guess);
      Carry := 0;
      for I := 0 to M - 1 do
      begin
        WordValue := QWord(U[J + I]) + V[I] + Carry;
        U[J + I] := LongWord(WordValue and LimbMask);
        Carry := WordValue shr LimbBits;
      end;
      U[J + M] := LongWord((QWord(U[J + M]) + Carry) and LimbMask);
    end;
    Quotient[J] := LongWord(Guess);
  end;
  Remainder := Copy(U, 0, M);
  UndoNormalization(Remainder, Shift);
  Trim(Remainder);
  Trim(Quotient);
end;

procedure DivideMagnitude(const Dividend, Divisor: TLimbArray;
  out Quotient, Remainder: TLimbArray);
var
  Order: Integer;
begin
  if Length(Divisor) = 0 then
    raise EExactArithmeticError.Create('Exact division by zero');
  Order := CompareMagnitude(Dividend, Divisor);
  if Order < 0 then
  begin
    Quotient := nil;
    Remainder := Dividend;
  end
  else if Order = 0 then
  begin
    Quotient := UnsignedLimbs(1);
    Remainder := nil;
  end
  else if Length(Divisor) = 1 then
  begin
    Quotient := Copy(Dividend);
    Remainder := UnsignedLimbs(DivideWordInPlace(Quotient, Length(Quotient), Divisor[0]));
    Trim(Quotient);
  end
  else
    DivideMultipleLimbs(Dividend, Divisor, Quotient, Remainder);
end;

function DivideWithRemainder(const Dividend, Divisor: TBigInteger): TBigIntegerDivision;
var
  Quotient, Remainder: TLimbArray;
begin
  DivideMagnitude(Dividend.FLimbs, Divisor.FLimbs, Quotient, Remainder);
  Result.Quotient := MakeInteger(Quotient, Dividend.FNegative xor Divisor.FNegative);
  Result.Remainder := MakeInteger(Remainder, Dividend.FNegative);
end;

function MagnitudeGCD(const Left, Right: TLimbArray): TLimbArray;
var
  A, B, Quotient, Remainder: TLimbArray;
begin
  A := Left;
  B := Right;
  while Length(B) <> 0 do
  begin
    DivideMagnitude(A, B, Quotient, Remainder);
    A := B;
    B := Remainder;
  end;
  Result := A;
end;

class function TBigInteger.GCD(const Left, Right: TBigInteger): TBigInteger;
begin
  Result := MakeInteger(MagnitudeGCD(Left.FLimbs, Right.FLimbs), False);
end;

function TBigInteger.Power(Exponent: QWord): TBigInteger;
var
  Factor: TBigInteger;
begin
  Result := FromInt64(1);
  Factor := Self;
  while Exponent <> 0 do
  begin
    if Odd(Exponent) then
      Result := Result * Factor;
    Exponent := Exponent shr 1;
    if Exponent <> 0 then
      Factor := Factor * Factor;
  end;
end;

function IsUnitMagnitude(const Limbs: TLimbArray): Boolean;
begin
  Result := (Length(Limbs) = 1) and (Limbs[0] = 1);
end;

function ExactQuotient(const Dividend, Divisor: TLimbArray): TLimbArray;
var
  Remainder: TLimbArray;
begin
  if IsUnitMagnitude(Divisor) then
    Exit(Dividend);
  DivideMagnitude(Dividend, Divisor, Result, Remainder);
  if Length(Remainder) <> 0 then
    raise EExactArithmeticError.Create('Internal exact division produced a remainder');
end;

function CheckedRatio(const Numerator, Denominator: TLimbArray; Negative: Boolean): TBigRational;
begin
  CheckLength(Length(Numerator), MaxLimbs);
  CheckLength(Length(Denominator), MaxLimbs);
  Result.FNumerator := MakeInteger(Numerator, Negative);
  Result.FDenominator := MakeInteger(Denominator, False);
end;

function ReduceRatio(const Numerator, Denominator: TBigInteger): TBigRational;
var
  Common: TLimbArray;
begin
  if Denominator.IsZero then
    raise EExactArithmeticError.Create('Exact rational denominator must be nonzero');
  if Numerator.IsZero then
    Exit(Default(TBigRational));
  Common := MagnitudeGCD(Numerator.FLimbs, Denominator.FLimbs);
  Result := CheckedRatio(ExactQuotient(Numerator.FLimbs, Common),
    ExactQuotient(Denominator.FLimbs, Common), Numerator.FNegative xor Denominator.FNegative);
end;

function TBigRational.GetDenominator: TBigInteger;
begin
  if FDenominator.IsZero then
    Result := TBigInteger.FromInt64(1)
  else
    Result := FDenominator;
end;

class function TBigRational.FromRatio(const Numerator, Denominator: TBigInteger): TBigRational;
begin
  Result := ReduceRatio(Numerator, Denominator);
end;

class function TBigRational.FromInt64(Value: Int64): TBigRational;
var
  Integral: TBigInteger;
begin
  Integral := TBigInteger.FromInt64(Value);
  Result := CheckedRatio(Integral.FLimbs, UnsignedLimbs(1), Integral.FNegative);
end;

class function TBigRational.Parse(const Text: String; Radix: TExactRadix): TBigRational;
var
  Slash, ComponentLimit: SizeInt;
  N, D: TBigInteger;
begin
  ComponentLimit := DigitLimit(Radix) + 1;
  if Length(Text) > 2 * ComponentLimit + 1 then
    raise EExactArithmeticError.Create('Exact rational text exceeds the supported length');
  Slash := Pos('/', Text);
  if Slash = 0 then
    Exit(FromRatio(TBigInteger.Parse(Text, Radix), TBigInteger.FromInt64(1)));
  if (Slash - 1 > ComponentLimit) or (Length(Text) - Slash > ComponentLimit) then
    raise EExactArithmeticError.Create('Exact rational component text exceeds the supported length');
  N := TBigInteger.Parse(Copy(Text, 1, Slash - 1), Radix);
  D := TBigInteger.Parse(Copy(Text, Slash + 1, Length(Text) - Slash), Radix);
  Result := FromRatio(N, D);
end;

function TBigRational.ToText(Radix: TExactRadix): String;
begin
  Result := FNumerator.ToText(Radix) + '/' + GetDenominator.ToText(Radix);
end;

function TBigRational.TryToInt64(out Value: Int64): Boolean;
begin
  Value := 0;
  if FNumerator.IsZero then
    Exit(True);
  Result := IsUnitMagnitude(FDenominator.FLimbs) and FNumerator.TryToInt64(Value);
end;

function TBigRational.CompareTo(const Other: TBigRational): Integer;
var
  Left, Right: TBigInteger;
begin
  Left := MultiplySigned(FNumerator, Other.Denominator);
  Right := MultiplySigned(Other.FNumerator, Denominator);
  Result := Left.CompareTo(Right);
end;

class operator TBigRational.+(const Left, Right: TBigRational): TBigRational;
var
  D1, D2, Sum: TBigInteger;
begin
  if Left.FNumerator.IsZero then
    Exit(Right);
  if Right.FNumerator.IsZero then
    Exit(Left);
  D1 := Left.FDenominator;
  D2 := Right.FDenominator;
  Sum := AddSigned(MultiplySigned(Left.FNumerator, D2), MultiplySigned(Right.FNumerator, D1));
  Result := ReduceRatio(Sum, MultiplySigned(D1, D2));
end;

class operator TBigRational.-(const Value: TBigRational): TBigRational;
begin
  Result.FNumerator := -Value.FNumerator;
  Result.FDenominator := Value.FDenominator;
end;

class operator TBigRational.-(const Left, Right: TBigRational): TBigRational;
begin
  Result := Left + (-Right);
end;

function MultiplyRatios(const N1, D1, N2, D2: TBigInteger): TBigRational;
var
  Common1, Common2, Numerator, Denominator: TLimbArray;
begin
  if D2.IsZero then
    raise EExactArithmeticError.Create('Exact rational division by zero');
  if N1.IsZero or N2.IsZero then
    Exit(Default(TBigRational));
  { Each input ratio is already reduced. Only the crossed pairs can
    share factors, so cancel them before allocating the products. }
  Common1 := MagnitudeGCD(N1.FLimbs, D2.FLimbs);
  Common2 := MagnitudeGCD(N2.FLimbs, D1.FLimbs);
  Numerator := MultiplyMagnitude(ExactQuotient(N1.FLimbs, Common1),
    ExactQuotient(N2.FLimbs, Common2));
  Denominator := MultiplyMagnitude(ExactQuotient(D1.FLimbs, Common2),
    ExactQuotient(D2.FLimbs, Common1));
  Result := CheckedRatio(Numerator, Denominator,
    N1.FNegative xor D1.FNegative xor N2.FNegative xor D2.FNegative);
end;

class operator TBigRational.*(const Left, Right: TBigRational): TBigRational;
begin
  Result := MultiplyRatios(Left.FNumerator, Left.Denominator, Right.FNumerator, Right.Denominator);
end;

class operator TBigRational./(const Left, Right: TBigRational): TBigRational;
begin
  Result := MultiplyRatios(Left.FNumerator, Left.Denominator, Right.Denominator, Right.FNumerator);
end;

{ Decode the IEEE-754 representation using integers. A finite value is
  Significand * 2^Exponent, with all removable factors of two stripped. }
procedure DecodeBinary64(Value: Double; out Significand: QWord;
  out Exponent: Integer; out Negative: Boolean);
var
  Bits: QWord;
  ExponentField: Integer;
begin
  Move(Value, Bits, SizeOf(Bits));
  Negative := (Bits and Binary64Sign) <> 0;
  ExponentField := Integer((Bits shr Binary64FractionBits) and Binary64ExponentMask);
  Significand := Bits and Binary64FractionMask;
  if ExponentField = Binary64ExponentMask then
    raise EExactArithmeticError.Create('Exact conversion requires finite Double input');
  if ExponentField = 0 then
    Exponent := Binary64MinSubnormalExponent
  else
  begin
    Significand := Significand or Binary64HiddenBit;
    Exponent := ExponentField - Binary64ExponentBias - Binary64FractionBits;
  end;
  if Significand = 0 then
  begin
    Exponent := 0;
    Negative := False;
    Exit;
  end;
  while (Exponent < 0) and (not Odd(Significand)) do
  begin
    Significand := Significand shr 1;
    Inc(Exponent);
  end;
end;

class function TBigInteger.FromDouble(Value: Double): TBigInteger;
var
  Significand: QWord;
  Exponent: Integer;
  Negative: Boolean;
begin
  DecodeBinary64(Value, Significand, Exponent, Negative);
  if Exponent < 0 then
    raise EExactArithmeticError.Create('Exact integer conversion requires integral Double input');
  Result := MakeInteger(ShiftLeft(UnsignedLimbs(Significand), Exponent), Negative);
end;

class function TBigRational.FromDouble(Value: Double): TBigRational;
var
  Significand: QWord;
  Exponent: Integer;
  Negative: Boolean;
begin
  DecodeBinary64(Value, Significand, Exponent, Negative);
  if Exponent < 0 then
    Result := CheckedRatio(UnsignedLimbs(Significand), ShiftLeft(UnsignedLimbs(1), -Exponent), Negative)
  else
    Result := CheckedRatio(ShiftLeft(UnsignedLimbs(Significand), Exponent), UnsignedLimbs(1), Negative);
end;

function BitLength(const Limbs: TLimbArray): Integer;
begin
  Result := Length(Limbs) * LimbBits - LeadingZeroBits(Limbs[High(Limbs)]);
end;

function RatioExponent(const Numerator, Denominator: TLimbArray): Integer;
var
  Order: Integer;
begin
  Result := BitLength(Numerator) - BitLength(Denominator);
  if Result >= 0 then
    Order := CompareMagnitude(Numerator, ShiftLeft(Denominator, Result))
  else
    Order := CompareMagnitude(ShiftLeft(Numerator, -Result), Denominator);
  if Order < 0 then
    Dec(Result);
end;

function RoundedSignificand(const Numerator, Denominator: TLimbArray; Scale: Integer): QWord;
var
  Dividend, Divisor, Quotient, Remainder: TLimbArray;
  Order: Integer;
begin
  if Scale >= 0 then
  begin
    Dividend := ShiftLeft(Numerator, Scale);
    Divisor := Denominator;
  end
  else
  begin
    Dividend := Numerator;
    Divisor := ShiftLeft(Denominator, -Scale);
  end;
  DivideMagnitude(Dividend, Divisor, Quotient, Remainder);
  Result := ToUnsignedWordPair(Quotient);
  Order := CompareMagnitude(ShiftLeft(Remainder, 1), Divisor);
  if (Order > 0) or ((Order = 0) and Odd(Result)) then
    Inc(Result);
end;

{ Construct the rounded binary64 bits directly, including subnormals and
  signed underflow. Overflow reports failure and leaves the output at zero. }
function TryEncodeBinary64(const Numerator, Denominator: TLimbArray;
  Negative: Boolean; out Value: Double): Boolean;
var
  Bits, Significand: QWord;
  Exponent: Integer;
begin
  Value := 0.0;
  if Length(Numerator) = 0 then
    Exit(True);
  Exponent := RatioExponent(Numerator, Denominator);
  if Exponent > Binary64ExponentBias then
    Exit(False);
  Bits := 0;
  if Exponent >= Binary64MinExponent then
  begin
    Significand := RoundedSignificand(Numerator, Denominator, Binary64FractionBits - Exponent);
    if Significand = Binary64HiddenBit shl 1 then
    begin
      Inc(Exponent);
      if Exponent > Binary64ExponentBias then
        Exit(False);
      Significand := Binary64HiddenBit;
    end;
    Bits := (QWord(Exponent + Binary64ExponentBias) shl Binary64FractionBits) or
      (Significand and Binary64FractionMask);
  end
  else if Exponent >= Binary64MinSubnormalExponent - 1 then
    Bits := RoundedSignificand(Numerator, Denominator, -Binary64MinSubnormalExponent);
  if Negative then
    Bits := Bits or Binary64Sign;
  Move(Bits, Value, SizeOf(Bits));
  Result := True;
end;

function TBigInteger.TryToDouble(out Value: Double): Boolean;
begin
  Result := TryEncodeBinary64(FLimbs, UnsignedLimbs(1), FNegative, Value);
end;

function TBigRational.TryToDouble(out Value: Double): Boolean;
var
  D: TBigInteger;
begin
  D := Denominator;
  Result := TryEncodeBinary64(FNumerator.FLimbs, D.FLimbs, FNumerator.FNegative, Value);
end;

end.
