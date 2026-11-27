program ExactArithmeticEvidence;

{$mode objfpc}{$H+}{$J-}

uses
  {$IFDEF WINDOWS}Windows,{$ELSE}Unix,{$ENDIF}
  SysUtils, MathBase.ExactArithmetic;

function ReadCounter: Int64;
{$IFDEF WINDOWS}
begin
  QueryPerformanceCounter(Result);
end;
{$ELSE}
var
  Now: TTimeVal;
begin
  fpgettimeofday(@Now, nil);
  Result := Int64(Now.tv_sec) * 1000000 + Now.tv_usec;
end;
{$ENDIF}

function MillisecondsSince(Started: Int64): Double;
{$IFDEF WINDOWS}
var
  Frequency: Int64;
begin
  QueryPerformanceFrequency(Frequency);
  Result := 1000.0 * (ReadCounter - Started) / Frequency;
end;
{$ELSE}
begin
  Result := (ReadCounter - Started) / 1000.0;
end;
{$ENDIF}

var
  Operation: String;
  Limbs, Repeats, I: Integer;
  Left, Right, One, Dividend, Product: TBigInteger;
  L, R, Sum: TBigRational;
  Division: TBigIntegerDivision;
  Before, After: TFPCHeapStatus;
  Start: Int64;
  Elapsed: Double;
begin
  Operation := ParamStr(1);
  Limbs := StrToIntDef(ParamStr(2), 0);
  Repeats := StrToIntDef(ParamStr(3), 0);
  if (Limbs < 2) or (Limbs > MaxExactIntegerBits div 32) or
    (Repeats < 1) or (Repeats > 10000) then
    Halt(1);
  if (Operation <> 'rational') and (Limbs > MaxExactIntegerBits div 64) then
    Halt(1);

  One := TBigInteger.FromInt64(1);
  Left := TBigInteger.Parse(StringOfChar('A', 8 * Limbs), erHexadecimal);
  Right := TBigInteger.Parse(StringOfChar('F', 8 * Limbs), erHexadecimal);
  if Operation = 'divide' then
    Dividend := Left * Right + One;
  if Operation = 'rational' then
  begin
    L := TBigRational.FromRatio(Right - One, Right);
    R := TBigRational.FromRatio(One, Right);
  end;

  Before := GetFPCHeapStatus;
  Start := ReadCounter;
  if Operation = 'multiply' then
    for I := 1 to Repeats do
      Product := Left * Right
  else if Operation = 'divide' then
    for I := 1 to Repeats do
      Division := DivideWithRemainder(Dividend, Left)
  else if Operation = 'rational' then
    for I := 1 to Repeats do
      Sum := L + R
  else
    Halt(1);
  Elapsed := MillisecondsSince(Start);
  After := GetFPCHeapStatus;

  if Operation = 'multiply' then
  begin
    Division := DivideWithRemainder(Product, Left);
    if not Division.Remainder.IsZero or (Division.Quotient.CompareTo(Right) <> 0) then
      Halt(2);
  end
  else if Operation = 'divide' then
  begin
    if (Division.Remainder.CompareTo(One) <> 0) or (Division.Quotient.CompareTo(Right) <> 0) then
      Halt(2);
  end
  else if Sum.ToText <> '1/1' then
    Halt(2);

  Writeln('EXACT|operation=', Operation, '|limbs=', Limbs, '|iterations=', Repeats,
    '|elapsed_ms=', Elapsed:0:6, '|heap_start_bytes=', Before.CurrHeapUsed,
    '|heap_peak_before_bytes=', Before.MaxHeapUsed, '|heap_peak_after_bytes=', After.MaxHeapUsed);
end.
