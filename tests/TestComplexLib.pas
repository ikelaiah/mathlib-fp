unit TestComplexLib;

{$mode objfpc}{$H+}{$J-}

interface

uses
  fpcunit, testutils, testregistry, Math,
  MathBase.Complex, AlgebraLib.VectorKernels;

type
  TTestComplexFoundation = class(TTestCase)
  private
    procedure DoAddMismatchedRealVectors;
    procedure DoNormalizeZeroComplexVector;
    procedure DoElementWiseDivideByZero;
    procedure DoMeanOfEmptyVector;
    procedure AssertComplexNear(const Expected, Actual: TComplex;
      const Tolerance: Double; const MessageText: string);
  published
    procedure Test01_ArithmeticAndConjugate;
    procedure Test02_StableMagnitudeAndPolarForm;
    procedure Test03_PrincipalFunctions;
    procedure Test04_ComplexTrigonometry;
    procedure Test05_ComplexDivisionExtremeScales;
    procedure Test06_SignedZeroBranchCuts;
    procedure Test07_NonFiniteComplexArithmetic;
    procedure Test08_InverseComplexFunctions;
    procedure Test09_RealVectorKernels;
    procedure Test10_ComplexVectorKernels;
    procedure Test11_VectorValidation;
    procedure Test12_RealVectorReductions;
    procedure Test13_RealVectorElementWiseOperations;
    procedure Test14_RealVectorIntoAliasingAndResize;
    procedure Test15_ComplexVectorDestinationBuffers;
    procedure Test16_EmptyVectorContracts;
  end;

implementation

function NegativeZero: Double;
var
  Bits: QWord;
begin
  Bits := QWord($8000000000000000);
  Move(Bits, Result, SizeOf(Result));
end;

procedure TTestComplexFoundation.DoAddMismatchedRealVectors;
var
  A, B: TRealVector;
begin
  A := TRealVector.Create(1.0);
  B := TRealVector.Create(1.0, 2.0);
  TVectorKit.Add(A, B);
end;

procedure TTestComplexFoundation.DoNormalizeZeroComplexVector;
var
  A: TComplexVector;
begin
  A := TComplexVector.Create(TComplex.Zero);
  TVectorKit.Normalize(A);
end;

procedure TTestComplexFoundation.DoElementWiseDivideByZero;
begin
  TVectorKit.ElementWiseDivide(TRealVector.Create(1.0),
    TRealVector.Create(0.0));
end;

procedure TTestComplexFoundation.DoMeanOfEmptyVector;
begin
  TVectorKit.Mean(nil);
end;

procedure TTestComplexFoundation.AssertComplexNear(const Expected,
  Actual: TComplex; const Tolerance: Double; const MessageText: string);
begin
  AssertEquals(MessageText + ' real', Expected.Re, Actual.Re, Tolerance);
  AssertEquals(MessageText + ' imaginary', Expected.Im, Actual.Im, Tolerance);
end;

procedure TTestComplexFoundation.Test01_ArithmeticAndConjugate;
var
  A, B: TComplex;
begin
  A := TComplex.Create(3.0, 4.0);
  B := TComplex.Create(1.0, -2.0);
  AssertComplexNear(TComplex.Create(4.0, 2.0), A + B, 1E-15, 'addition');
  AssertComplexNear(TComplex.Create(11.0, -2.0), A * B, 1E-15, 'multiplication');
  AssertComplexNear(TComplex.Create(1.0, 2.0), B.Conjugate, 1E-15, 'conjugate');
  AssertComplexNear(A, A / TComplex.One, 1E-15, 'division by one');
end;

procedure TTestComplexFoundation.Test02_StableMagnitudeAndPolarForm;
var
  Z: TComplex;
begin
  Z := TComplex.Create(1.0E308, 1.0E308);
  AssertTrue('large magnitude remains finite', not IsInfinite(Z.Magnitude));
  AssertEquals('large magnitude reference', Sqrt(2.0), Z.Magnitude / 1.0E308, 1E-15);
  AssertTrue('infinite real magnitude',
    IsInfinite(TComplex.Create(Infinity, 1.0).Magnitude));
  AssertTrue('infinity dominates NaN in magnitude',
    IsInfinite(TComplex.Create(Infinity, NaN).Magnitude));
  AssertTrue('NaN magnitude', IsNan(TComplex.Create(NaN, 1.0).Magnitude));
  Z := TComplex.FromPolar(2.0, Pi / 6.0);
  AssertEquals('polar real', Sqrt(3.0), Z.Re, 1E-15);
  AssertEquals('polar imaginary', 1.0, Z.Im, 1E-15);
end;

procedure TTestComplexFoundation.Test03_PrincipalFunctions;
var
  Z, Root: TComplex;
begin
  Z := TComplex.Create(-4.0, 0.0);
  Root := CSqrt(Z);
  AssertComplexNear(TComplex.Create(0.0, 2.0), Root, 1E-15, 'principal square root');
  AssertComplexNear(TComplex.Create(1.0, 0.0), CExp(CLog(TComplex.One)), 1E-15,
    'exp log one');
  AssertComplexNear(TComplex.Create(0.0, -8.0), CPow(Z, 1.5), 1E-14,
    'principal complex power');
end;

procedure TTestComplexFoundation.Test04_ComplexTrigonometry;
var
  IUnit: TComplex;
begin
  IUnit := TComplex.ImaginaryUnit;
  AssertComplexNear(TComplex.Create(0.0, Sinh(1.0)), CSin(IUnit), 1E-15,
    'sin(i)');
  AssertComplexNear(TComplex.Create(Cosh(1.0), 0.0), CCos(IUnit), 1E-15,
    'cos(i)');
  AssertComplexNear(TComplex.Create(0.0, Tanh(1.0)), CTan(IUnit), 1E-15,
    'tan(i)');
end;

procedure TTestComplexFoundation.Test05_ComplexDivisionExtremeScales;
var
  Z: TComplex;
begin
  Z := TComplex.Create(1.0E308, 1.0E308) /
    TComplex.Create(1.0E308, -1.0E308);
  AssertComplexNear(TComplex.ImaginaryUnit, Z, 1E-15, 'large division');
  Z := TComplex.Create(1.0E-308, 1.0E-308) /
    TComplex.Create(1.0E-308, -1.0E-308);
  AssertComplexNear(TComplex.ImaginaryUnit, Z, 1E-15, 'small division');
end;

procedure TTestComplexFoundation.Test06_SignedZeroBranchCuts;
var
  NegativeZero, PositiveZero: Double;
  Z: TComplex;
begin
  PositiveZero := 0.0;
  NegativeZero := TestComplexLib.NegativeZero;
  AssertEquals('log upper branch', Pi, CLog(TComplex.Create(-1.0, PositiveZero)).Im,
    1E-15);
  AssertEquals('log lower branch', -Pi, CLog(TComplex.Create(-1.0, NegativeZero)).Im,
    1E-15);
  Z := CSqrt(TComplex.Create(-4.0, NegativeZero));
  AssertEquals('sqrt lower branch magnitude', 2.0, Abs(Z.Im), 1E-15);
  AssertTrue('sqrt lower branch sign', Z.Im < 0.0);
  Z := CAsinh(TComplex.Create(PositiveZero, -2.0));
  AssertEquals('asinh lower cut right side real', Ln(2.0 + Sqrt(3.0)),
    Z.Re, 1E-15);
  AssertEquals('asinh lower cut right side imaginary', -Pi / 2.0,
    Z.Im, 1E-15);
  Z := CAsinh(TComplex.Create(NegativeZero, -2.0));
  AssertEquals('asinh lower cut left side real', -Ln(2.0 + Sqrt(3.0)),
    Z.Re, 1E-15);
  AssertEquals('asinh lower cut left side imaginary', -Pi / 2.0,
    Z.Im, 1E-15);
end;

procedure TTestComplexFoundation.Test07_NonFiniteComplexArithmetic;
var
  Z: TComplex;
begin
  Z := TComplex.One / TComplex.Create(Infinity, Infinity);
  AssertEquals('finite divided by infinity real', 0.0, Z.Re, 0.0);
  AssertEquals('finite divided by infinity imaginary', 0.0, Z.Im, 0.0);
  Z := TComplex.Create(NaN, 0.0) / TComplex.One;
  AssertTrue('NaN division real', IsNan(Z.Re));
  AssertTrue('NaN division imaginary', IsNan(Z.Im));

  Z := CExp(TComplex.Create(Infinity, 0.0));
  AssertTrue('exp positive infinity real', IsInfinite(Z.Re));
  AssertEquals('exp positive infinity imaginary', 0.0, Z.Im, 0.0);
  Z := CSqrt(TComplex.Create(-Infinity, NegativeZero));
  AssertEquals('sqrt negative infinity real', 0.0, Z.Re, 0.0);
  AssertTrue('sqrt negative infinity imaginary magnitude', IsInfinite(Z.Im));
  AssertTrue('sqrt negative infinity lower side', Z.Im < 0.0);
  Z := CSqrt(TComplex.Create(1.0, Infinity));
  AssertTrue('sqrt infinite imaginary real', IsInfinite(Z.Re));
  AssertTrue('sqrt infinite imaginary imaginary', IsInfinite(Z.Im));
end;

procedure TTestComplexFoundation.Test08_InverseComplexFunctions;
const
  Tiny = 1.0E-20;
  Huge = 1.0E308;
var
  Z: TComplex;
begin
  AssertComplexNear(TComplex.Create(Pi / 6.0, 0.0),
    CAsin(TComplex.Create(0.5, 0.0)), 1E-15, 'asin');
  AssertComplexNear(TComplex.Create(Pi / 3.0, 0.0),
    CAcos(TComplex.Create(0.5, 0.0)), 1E-15, 'acos');
  AssertComplexNear(TComplex.Create(Pi / 4.0, 0.0),
    CAtan(TComplex.One), 1E-15, 'atan');
  AssertComplexNear(TComplex.Create(Ln(1.0 + Sqrt(2.0)), 0.0),
    CAsinh(TComplex.One), 1E-15, 'asinh');
  AssertComplexNear(TComplex.Create(Ln(2.0 + Sqrt(3.0)), 0.0),
    CAcosh(TComplex.Create(2.0, 0.0)), 1E-15, 'acosh');
  AssertComplexNear(TComplex.Create(0.5 * Ln(3.0), 0.0),
    CAtanh(TComplex.Create(0.5, 0.0)), 1E-15, 'atanh');

  Z := TComplex.Create(-2.0, 3.0);
  AssertComplexNear(TComplex.Create(-0.5706527843210994,
    1.9833870299165355), CAsin(Z), 5E-14, 'complex asin reference');
  AssertComplexNear(TComplex.Create(2.1414491111159960,
    -1.9833870299165355), CAcos(Z), 5E-14, 'complex acos reference');
  AssertComplexNear(TComplex.Create(-1.4099210495965755,
    0.2290726829685388), CAtan(Z), 5E-14, 'complex atan reference');
  AssertComplexNear(TComplex.Create(-1.9686379257930964,
    0.9646585044076028), CAsinh(Z), 5E-14, 'complex asinh reference');
  AssertComplexNear(TComplex.Create(1.9833870299165355,
    2.1414491111159960), CAcosh(Z), 5E-14, 'complex acosh reference');
  AssertComplexNear(TComplex.Create(-0.1469466662255298,
    1.3389725222944935), CAtanh(Z), 5E-14, 'complex atanh reference');

  AssertComplexNear(TComplex.Create(Tiny, -Tiny),
    CAsinh(TComplex.Create(Tiny, -Tiny)), 1E-35,
    'asinh preserves tiny components');
  AssertComplexNear(TComplex.Create(Tiny, -Tiny),
    CAtanh(TComplex.Create(Tiny, -Tiny)), 1E-35,
    'atanh preserves tiny components');

  Z := CAsinh(TComplex.Create(Huge, 0.0));
  AssertEquals('large asinh real', Ln(Huge) + Ln(2.0), Z.Re, 1E-12);
  AssertEquals('large asinh imaginary', 0.0, Z.Im, 0.0);
  Z := CAcosh(TComplex.Create(Huge, 0.0));
  AssertEquals('large acosh real', Ln(Huge) + Ln(2.0), Z.Re, 1E-12);
  AssertEquals('large acosh imaginary', 0.0, Z.Im, 0.0);
  Z := CAtanh(TComplex.Create(Huge, 0.0));
  AssertEquals('large atanh real asymptote', 1.0E-308, Z.Re, 1.0E-322);
  AssertEquals('large atanh upper branch', Pi / 2.0, Z.Im, 1E-15);

  Z := CAsin(TComplex.Create(1.0E150, 1.0E150));
  AssertEquals('large complex asin real', Pi / 4.0, Z.Re, 1E-15);
  AssertEquals('large complex asin imaginary',
    Ln(1.0E150) + 1.5 * Ln(2.0), Z.Im, 1E-12);
  Z := CAtan(TComplex.Create(1.0E150, 1.0E150));
  AssertEquals('large complex atan real', Pi / 2.0, Z.Re, 1E-15);
  AssertEquals('large complex atan imaginary', 5.0E-151, Z.Im, 1E-164);
end;

procedure TTestComplexFoundation.Test09_RealVectorKernels;
var
  A, B, ResultVector: TRealVector;
begin
  A := TRealVector.Create(3.0, 4.0);
  B := TRealVector.Create(1.0, -2.0);
  AssertEquals('dot product', -5.0, TVectorKit.Dot(A, B), 1E-15);
  AssertEquals('stable norm', 5.0, TVectorKit.Norm2(A), 1E-15);
  ResultVector := TVectorKit.Axpy(2.0, A, B);
  AssertEquals('axpy first', 7.0, ResultVector[0], 1E-15);
  AssertEquals('axpy second', 6.0, ResultVector[1], 1E-15);
  ResultVector := TVectorKit.Normalize(A);
  AssertEquals('normalise first', 0.6, ResultVector[0], 1E-15);
  AssertEquals('normalise second', 0.8, ResultVector[1], 1E-15);
end;

procedure TTestComplexFoundation.Test10_ComplexVectorKernels;
var
  A, B, ResultVector: TComplexVector;
begin
  A := TComplexVector.Create(TComplex.Create(1.0, 1.0), TComplex.Create(2.0, 0.0));
  B := TComplexVector.Create(TComplex.Create(1.0, -1.0), TComplex.Create(0.0, 1.0));
  AssertComplexNear(TComplex.Create(2.0, 2.0), TVectorKit.Dot(A, B), 1E-15,
    'nonconjugating dot');
  AssertComplexNear(TComplex.Create(6.0, 0.0), TVectorKit.DotConjugate(A, A),
    1E-15, 'Hermitian dot');
  AssertEquals('complex norm', Sqrt(6.0), TVectorKit.Norm2(A), 1E-15);
  ResultVector := TVectorKit.Scale(A, TComplex.ImaginaryUnit);
  AssertComplexNear(TComplex.Create(-1.0, 1.0), ResultVector[0], 1E-15,
    'complex scaling');
end;

procedure TTestComplexFoundation.Test11_VectorValidation;
begin
  AssertException('mismatched real vectors', EVectorError, @DoAddMismatchedRealVectors);
  AssertException('normalise zero complex vector', EVectorError,
    @DoNormalizeZeroComplexVector);
  AssertException('elementwise division by zero', EVectorError,
    @DoElementWiseDivideByZero);
end;

procedure TTestComplexFoundation.Test12_RealVectorReductions;
var
  A, B: TRealVector;
begin
  A := TRealVector.Create(1.0E16, 1.0, -1.0E16);
  AssertEquals('compensated sum', 1.0, TVectorKit.Sum(A), 0.0);
  AssertEquals('compensated dot', 1.0,
    TVectorKit.Dot(A, TRealVector.Create(1.0, 1.0, 1.0)), 0.0);
  B := TRealVector.Create(2.0, 4.0, -8.0);
  AssertEquals('mean', Double(-2.0) / Double(3.0), TVectorKit.Mean(B), 1E-15);
  AssertEquals('min', -8.0, TVectorKit.Min(B), 0.0);
  AssertEquals('max', 4.0, TVectorKit.Max(B), 0.0);
end;

procedure TTestComplexFoundation.Test13_RealVectorElementWiseOperations;
var
  B, Destination: TRealVector;
begin
  B := TRealVector.Create(2.0, 4.0, -8.0);
  Destination := TRealVector.Create(0.0, 0.0, 0.0);
  TVectorKit.ElementWiseMultiplyInto(B, TRealVector.Create(3.0, 2.0, -1.0),
    Destination);
  AssertEquals('multiply into first', 6.0, Destination[0], 0.0);
  AssertEquals('multiply into second', 8.0, Destination[1], 0.0);
  AssertEquals('multiply into third', 8.0, Destination[2], 0.0);
  Destination := TVectorKit.ElementWiseDivide(Destination,
    TRealVector.Create(2.0, 2.0, 4.0));
  AssertEquals('divide first', 3.0, Destination[0], 0.0);
  AssertEquals('divide second', 4.0, Destination[1], 0.0);
  AssertEquals('divide third', 2.0, Destination[2], 0.0);
end;

procedure TTestComplexFoundation.Test14_RealVectorIntoAliasingAndResize;
var
  A, B, Destination: TRealVector;
begin
  A := TRealVector.Create(1.0, 2.0, 3.0);
  B := TRealVector.Create(10.0, 20.0, 30.0);
  Destination := nil;
  TVectorKit.AddInto(A, B, Destination);
  AssertEquals('AddInto resizes destination', 3, Length(Destination));
  AssertEquals('AddInto first', 11.0, Destination[0], 0.0);
  TVectorKit.SubtractInto(B, A, B);
  AssertEquals('SubtractInto aliases source', 9.0, B[0], 0.0);
  AssertEquals('SubtractInto aliases source last', 27.0, B[2], 0.0);
  TVectorKit.ScaleInto(A, 2.0, A);
  AssertEquals('ScaleInto aliases source', 2.0, A[0], 0.0);
  AssertEquals('ScaleInto aliases source last', 6.0, A[2], 0.0);
  TVectorKit.ElementWiseDivideInto(A, TRealVector.Create(2.0, 2.0, 2.0), A);
  AssertEquals('DivideInto aliases numerator', 1.0, A[0], 0.0);
  AssertEquals('DivideInto aliases numerator last', 3.0, A[2], 0.0);
  B := TRealVector.Create(2.0, 4.0, -8.0);
  Destination := TRealVector.Create(6.0, 8.0, 8.0);
  TVectorKit.AxpyInto(0.5, B, Destination, Destination);
  AssertEquals('alias-safe axpy into first', 7.0, Destination[0], 0.0);
  AssertEquals('alias-safe axpy into second', 10.0, Destination[1], 0.0);
  AssertEquals('alias-safe axpy into third', 4.0, Destination[2], 0.0);
end;

procedure TTestComplexFoundation.Test15_ComplexVectorDestinationBuffers;
var
  ComplexA, ComplexB, ComplexDestination: TComplexVector;
begin
  ComplexA := TComplexVector.Create(TComplex.Create(3.0, 4.0));
  ComplexDestination := TComplexVector.Create(TComplex.Zero);
  TVectorKit.NormalizeInto(ComplexA, ComplexDestination);
  AssertComplexNear(TComplex.Create(0.6, 0.8), ComplexDestination[0], 1E-15,
    'complex normalize into');
  ComplexDestination := nil;
  ComplexA := TComplexVector.Create(TComplex.Create(1.0, 2.0));
  ComplexB := TComplexVector.Create(TComplex.Create(3.0, -1.0));
  TVectorKit.AddInto(ComplexA, ComplexB, ComplexDestination);
  AssertComplexNear(TComplex.Create(4.0, 1.0), ComplexDestination[0], 1E-15,
    'complex AddInto resizes destination');
  TVectorKit.AxpyInto(TComplex.ImaginaryUnit, ComplexA, ComplexB, ComplexB);
  AssertComplexNear(TComplex.Create(1.0, 0.0), ComplexB[0], 1E-15,
    'complex AxpyInto aliases source');
end;

procedure TTestComplexFoundation.Test16_EmptyVectorContracts;
var
  Empty, Destination: TRealVector;
begin
  Empty := nil;
  Destination := TRealVector.Create(1.0);
  TVectorKit.AddInto(Empty, Empty, Destination);
  AssertEquals('AddInto empty result', 0, Length(Destination));
  AssertEquals('empty sum', 0.0, TVectorKit.Sum(Empty), 0.0);
  AssertEquals('empty norm', 0.0, TVectorKit.Norm2(Empty), 0.0);
  AssertException('mean empty vector', EVectorError, @DoMeanOfEmptyVector);
end;

initialization
  RegisterTest(TTestComplexFoundation);

end.
