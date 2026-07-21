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
    procedure AssertComplexNear(const Expected, Actual: TComplex;
      const Tolerance: Double; const MessageText: string);
  published
    procedure Test01_ArithmeticAndConjugate;
    procedure Test02_StableMagnitudeAndPolarForm;
    procedure Test03_PrincipalFunctions;
    procedure Test04_ComplexTrigonometry;
    procedure Test05_RealVectorKernels;
    procedure Test06_ComplexVectorKernels;
    procedure Test07_VectorValidation;
  end;

implementation

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

procedure TTestComplexFoundation.Test05_RealVectorKernels;
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

procedure TTestComplexFoundation.Test06_ComplexVectorKernels;
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

procedure TTestComplexFoundation.Test07_VectorValidation;
begin
  AssertException('mismatched real vectors', EVectorError, @DoAddMismatchedRealVectors);
  AssertException('normalise zero complex vector', EVectorError,
    @DoNormalizeZeroComplexVector);
end;

initialization
  RegisterTest(TTestComplexFoundation);

end.
