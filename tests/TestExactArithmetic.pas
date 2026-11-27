unit TestExactArithmetic;

{$mode objfpc}{$H+}{$J-}

interface

uses
  SysUtils, Math, fpcunit, testregistry, MathBase.ExactArithmetic,
  CombinatoricsLib.Combinatorics;

type
  TTestExactArithmetic = class(TTestCase)
  published
    procedure TestIntegerTextAndOrdering;
    procedure TestInt64Boundaries;
    procedure TestIntegerTextRejections;
    procedure TestIntegerReferenceCorpus;
    procedure TestPowersAndWidthLimit;
    procedure TestRationalReferenceCorpus;
    procedure TestRationalNormalizationAndLimits;
    procedure TestExactSamplingWorkflow;
    procedure TestBinary64Decoding;
    procedure TestBinary64Rounding;
  end;

implementation

type
  TIntegerReference = record
    A, B, Sum, Difference, Product, Quotient, Remainder, GreatestDivisor: String;
  end;
  TRationalReference = record
    A, B, CanonicalA, CanonicalB, Sum, Difference, Product, Quotient: String;
    Order: Integer;
  end;
  TDecodeReference = record
    Bits: QWord;
    Exact: String;
    Integral: Boolean;
  end;
  TRoundingReference = record
    Exact: String;
    Finite: Boolean;
    Bits: QWord;
  end;

{$I ExactArithmeticReference.inc}

procedure TTestExactArithmetic.TestIntegerTextAndOrdering;
var
  Zero, A, B: TBigInteger;
begin
  Zero := Default(TBigInteger);
  AssertEquals('Default zero', '0', Zero.ToText);
  AssertEquals('Negative zero is canonical', '0', TBigInteger.Parse('-000').ToText);
  A := TBigInteger.Parse('+000100891344545564193334812497256');
  AssertEquals('Independent decimal count', '100891344545564193334812497256', A.ToText);
  AssertEquals('Decimal to hexadecimal', '145FF5D3B1070380DC8085568', A.ToText(erHexadecimal));
  B := TBigInteger.Parse('145ff5d3b1070380dc8085568', erHexadecimal);
  AssertEquals('Hex to same value', 0, A.CompareTo(B));
  A := TBigInteger.Parse('-18446744073709551616');
  B := TBigInteger.Parse('-18446744073709551615');
  AssertEquals('Negative order reverses magnitude', -1, A.CompareTo(B));
  AssertEquals('Independent copy', '-10000000000000000', A.ToText(erHexadecimal));
  AssertEquals('Sign comparison', 1, Zero.CompareTo(A));
end;

procedure TTestExactArithmetic.TestInt64Boundaries;
var
  Value: Int64;
begin
  AssertTrue(TBigInteger.FromInt64(Low(Int64)).TryToInt64(Value));
  AssertEquals(Low(Int64), Value);
  AssertEquals('-9223372036854775808', TBigInteger.FromInt64(Low(Int64)).ToText);
  AssertTrue(TBigInteger.Parse('9223372036854775807').TryToInt64(Value));
  AssertEquals(High(Int64), Value);
  AssertFalse(TBigInteger.Parse('9223372036854775808').TryToInt64(Value));
  AssertEquals(Int64(0), Value);
  AssertFalse(TBigInteger.Parse('-9223372036854775809').TryToInt64(Value));
  AssertEquals(Int64(0), Value);
end;

procedure TTestExactArithmetic.TestIntegerTextRejections;
const
  Invalid: array[0..7] of String = ('', '-', '+', ' 1', '1 ', '1_0', '1.0', '0xFF');
var
  Text: String;
  V: TBigInteger;
begin
  for Text in Invalid do
  begin
    try
      V := TBigInteger.Parse(Text);
      Fail('Accepted invalid input ' + Text + ' as ' + V.ToText);
    except
      on E: EExactArithmeticError do ;
    end;
  end;
  try
    V := TBigInteger.Parse(StringOfChar('0', 32769), erHexadecimal);
    Fail('Accepted a too-long hexadecimal input');
  except
    on E: EExactArithmeticError do ;
  end;
  V := TBigInteger.Parse(StringOfChar('F', 32768), erHexadecimal);
  AssertEquals('Largest allowed hex round trip', StringOfChar('F', 32768),
    V.ToText(erHexadecimal));
  AssertEquals('Largest allowed decimal round trip', 0,
    V.CompareTo(TBigInteger.Parse(V.ToText)));
end;

procedure TTestExactArithmetic.TestIntegerReferenceCorpus;
var
  R: TIntegerReference;
  A, B, CopyOfA: TBigInteger;
  Parts: TBigIntegerDivision;
begin
  for R in IntegerReferences do
  begin
    A := TBigInteger.Parse(R.A, erHexadecimal);
    B := TBigInteger.Parse(R.B, erHexadecimal);
    CopyOfA := A;
    AssertEquals('Addition', R.Sum, (A + B).ToText(erHexadecimal));
    AssertEquals('Subtraction', R.Difference, (A - B).ToText(erHexadecimal));
    AssertEquals('Multiplication', R.Product, (A * B).ToText(erHexadecimal));
    Parts := DivideWithRemainder(A, B);
    AssertEquals('Quotient for ' + R.A + '/' + R.B, R.Quotient,
      Parts.Quotient.ToText(erHexadecimal));
    AssertEquals('Remainder', R.Remainder, Parts.Remainder.ToText(erHexadecimal));
    AssertEquals('Division identity', 0, A.CompareTo(B * Parts.Quotient + Parts.Remainder));
    AssertEquals('Greatest common divisor', R.GreatestDivisor,
      TBigInteger.GCD(A, B).ToText(erHexadecimal));
    A := A + B;
    AssertEquals('Assignment shares immutable values', R.A, CopyOfA.ToText(erHexadecimal));
  end;
  try
    Parts := DivideWithRemainder(TBigInteger.FromInt64(5), Default(TBigInteger));
    Fail('Accepted division by zero with quotient ' + Parts.Quotient.ToText);
  except
    on E: EExactArithmeticError do ;
  end;
end;

procedure TTestExactArithmetic.TestPowersAndWidthLimit;
var
  A, B: TBigInteger;
begin
  AssertEquals('Zero power of zero', '1', TBigInteger.FromInt64(0).Power(0).ToText);
  AssertEquals('Odd power of a negative integer', '-243', TBigInteger.FromInt64(-3).Power(5).ToText);
  AssertEquals('Even power of a negative integer', '81', TBigInteger.FromInt64(-3).Power(4).ToText);
  AssertEquals('Power of two', '10000000000000000', TBigInteger.FromInt64(2).Power(64).ToText(erHexadecimal));
  A := TBigInteger.Parse(StringOfChar('F', 32768), erHexadecimal);
  try
    B := A + TBigInteger.FromInt64(1);
    Fail('Accepted oversized addition with length ' + IntToStr(Length(B.ToText)));
  except
    on E: EExactArithmeticError do ;
  end;
  try
    B := TBigInteger.FromInt64(2).Power(MaxExactIntegerBits);
    Fail('Accepted oversized power with length ' + IntToStr(Length(B.ToText)));
  except
    on E: EExactArithmeticError do ;
  end;
end;

procedure TTestExactArithmetic.TestRationalReferenceCorpus;
var
  R: TRationalReference;
  A, B, CopyOfA: TBigRational;
begin
  for R in RationalReferences do
  begin
    A := TBigRational.Parse(R.A, erHexadecimal);
    B := TBigRational.Parse(R.B, erHexadecimal);
    CopyOfA := A;
    AssertEquals('Normalized A', R.CanonicalA, A.ToText(erHexadecimal));
    AssertEquals('Normalized B', R.CanonicalB, B.ToText(erHexadecimal));
    AssertEquals('Addition', R.Sum, (A + B).ToText(erHexadecimal));
    AssertEquals('Subtraction', R.Difference, (A - B).ToText(erHexadecimal));
    AssertEquals('Multiplication', R.Product, (A * B).ToText(erHexadecimal));
    AssertEquals('Division', R.Quotient, (A / B).ToText(erHexadecimal));
    AssertEquals('Comparison', R.Order, A.CompareTo(B));
    A := A - B;
    AssertEquals('Assignment preserves a copy', R.CanonicalA, CopyOfA.ToText(erHexadecimal));
  end;
end;

procedure TTestExactArithmetic.TestRationalNormalizationAndLimits;
var
  A, B, C: TBigRational;
  M, One: TBigInteger;
  IntValue: Int64;
begin
  A := Default(TBigRational);
  AssertEquals('Default ratio', '0/1', A.ToText);
  AssertEquals('Integer text', '-4/1', TBigRational.Parse('-4').ToText);
  AssertEquals('Negative denominator', '-3/4', TBigRational.Parse('6/-8').ToText);
  AssertTrue(TBigRational.Parse('6/2').TryToInt64(IntValue));
  AssertEquals(Int64(3), IntValue);
  AssertFalse(TBigRational.Parse('7/2').TryToInt64(IntValue));
  AssertEquals(Int64(0), IntValue);
  try
    A := TBigRational.Parse('1/0');
    Fail('Accepted a zero denominator');
  except
    on E: EExactArithmeticError do ;
  end;
  try
    A := TBigRational.Parse('1/2/3');
    Fail('Accepted a second slash');
  except
    on E: EExactArithmeticError do ;
  end;
  try
    A := TBigRational.Parse('1/2') / Default(TBigRational);
    Fail('Accepted rational division by zero');
  except
    on E: EExactArithmeticError do ;
  end;
  M := TBigInteger.Parse(StringOfChar('F', 32768), erHexadecimal);
  One := TBigInteger.FromInt64(1);
  A := TBigRational.FromRatio(M - One, M);
  B := TBigRational.FromRatio(One, M);
  C := A + B;
  AssertEquals('Reduce a double-width result before checking its public width', '1/1', C.ToText);
  C := B * TBigRational.FromRatio(M, One);
  AssertEquals('Cross-cancel wide operands', '1/1', C.ToText);
  try
    C := B / TBigRational.FromRatio(One, M - One) / TBigRational.FromRatio(M, One);
    Fail('Accepted an oversized reduced denominator');
  except
    on E: EExactArithmeticError do ;
  end;
end;

procedure TTestExactArithmetic.TestExactSamplingWorkflow;
var
  Count, Marked: TBigInteger;
  NearLimit: String;
begin
  AssertEquals('Exact 0!', '1', TCombinatoricsKit.FactorialExact(0).ToText);
  AssertEquals('Exact 21!', '51090942171709440000', TCombinatoricsKit.FactorialExact(21).ToText);
  AssertEquals('Fits Int64 but requires exact intermediates', '7219428434016265740',
    TCombinatoricsKit.CombinationExact(66, 33).ToText);
  Count := TCombinatoricsKit.CombinationExact(100, 50);
  Marked := TCombinatoricsKit.CombinationExact(50, 25);
  AssertEquals('100 choose 50', '100891344545564193334812497256', Count.ToText);
  AssertEquals('Reduced sampling probability', '2110031698716658293304/13322197258529868226331',
    TBigRational.FromRatio(Marked * Marked, Count).ToText);
  { Python math.comb gives a 131068-bit result; multiplying before dividing
    on the last step would require 131081 bits. }
  NearLimit := TCombinatoricsKit.CombinationExact(High(Integer), 6638).ToText(erHexadecimal);
  AssertEquals('Near-cap combination hex width', 32767, Length(NearLimit));
  AssertEquals('Near-cap combination high digits', 'A17F2FA75651A31FAF76C9FED0E306583F4309B7DD593874',
    Copy(NearLimit, 1, 48));
  AssertEquals('Near-cap combination low digits', '4E4A26123B7C9F88020213C2C2FCFD088A354F8B32980001',
    Copy(NearLimit, Length(NearLimit) - 47, 48));
end;

function DoubleFromBits(Bits: QWord): Double;
begin
  Move(Bits, Result, SizeOf(Result));
end;

function BitsOfDouble(Value: Double): QWord;
begin
  Move(Value, Result, SizeOf(Result));
end;

procedure TTestExactArithmetic.TestBinary64Decoding;
var
  R: TDecodeReference;
  Value, Rounded: Double;
  ExpectedBits: QWord;
  A: TBigInteger;
  B: TBigRational;
begin
  for R in DecodeReferences do
  begin
    Value := DoubleFromBits(R.Bits);
    B := TBigRational.FromDouble(Value);
    AssertEquals('Exact binary64 value for ' + IntToHex(R.Bits, 16), R.Exact,
      B.ToText(erHexadecimal));
    ExpectedBits := R.Bits;
    if (ExpectedBits shl 1) = 0 then
      ExpectedBits := 0;
    AssertTrue('Finite dyadic round trip succeeds', B.TryToDouble(Rounded));
    AssertTrue('Bitwise dyadic round trip', ExpectedBits = BitsOfDouble(Rounded));
    if R.Integral then
    begin
      A := TBigInteger.FromDouble(Value);
      AssertEquals('Exact integer conversion', R.Exact, A.ToText(erHexadecimal) + '/1');
    end
    else
    begin
      try
        A := TBigInteger.FromDouble(Value);
        Fail('Accepted fractional binary64 input');
      except
        on E: EExactArithmeticError do ;
      end;
    end;
  end;
  try
    B := TBigRational.FromDouble(DoubleFromBits($7FF0000000000000));
    Fail('Accepted infinite binary64 input');
  except
    on E: EExactArithmeticError do ;
  end;
  try
    A := TBigInteger.FromDouble(DoubleFromBits($7FF8000000000001));
    Fail('Accepted NaN as an integer');
  except
    on E: EExactArithmeticError do ;
  end;
end;

procedure TTestExactArithmetic.TestBinary64Rounding;
var
  R: TRoundingReference;
  Value: Double;
  SavedMode, Mode: TFPURoundingMode;
  A: TBigRational;
begin
  SavedMode := GetRoundMode;
  try
    for Mode in [rmNearest, rmDown, rmUp, rmTruncate] do
    begin
      SetRoundMode(Mode);
      for R in RoundingReferences do
      begin
        A := TBigRational.Parse(R.Exact, erHexadecimal);
        AssertTrue('Binary64 range for ' + R.Exact, R.Finite = A.TryToDouble(Value));
        AssertTrue('Rounded bits for ' + R.Exact, R.Bits = BitsOfDouble(Value));
      end;
    end;
  finally
    SetRoundMode(SavedMode);
  end;
  AssertTrue(TBigInteger.Parse('9007199254740993').TryToDouble(Value));
  AssertTrue('Integral halfway tie', BitsOfDouble(Value) = QWord($4340000000000000));
end;

initialization
  RegisterTest(TTestExactArithmetic);

end.
