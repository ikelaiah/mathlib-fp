unit AlgebraLib.DenseDecompositions;

{-----------------------------------------------------------------------------
 AlgebraLib.DenseDecompositions

 Portable typed triangular, QR/CPQR, SVD, and symmetric/Hermitian eigen
 decompositions for mathlib-fp 1.6. Factors own immutable private snapshots;
 all accessors and solves return fresh storage.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  SysUtils, Math, MathBase.SharedTypes, MathBase.Complex,
  AlgebraLib.DenseMatrices;

type
  TDenseTriangle = (dtLower, dtUpper);
  TDenseDiagonal = (ddNonUnit, ddUnit);
  TDenseTranspose = (dtNoTranspose, dtTranspose, dtConjugateTranspose);

  TDenseSolveDiagnostics = record
    Method: string;
    NumericalRank: SizeInt;
    IsRankDeficient: Boolean;
    Tolerance: Double;
    ConditionIndicator: Double;
    ResidualNorm: Double;
    BackwardError: Double;
  end;

  generic IDenseQRFactorization<T> = interface
    function GetRows: SizeInt;
    function GetCols: SizeInt;
    function GetQ: specialize IDenseMatrix<T>;
    function GetR: specialize IDenseMatrix<T>;
    function GetPermutation: TSizeIntArray;
    function GetNumericalRank: SizeInt;
    function GetTolerance: Double;
    function GetConditionIndicator: Double;
    function GetIsColumnPivoted: Boolean;
    function SolveLeastSquares(const B: specialize IDenseMatrix<T>):
      specialize IDenseMatrix<T>;
    function SolveLeastSquaresWithInfo(const B: specialize IDenseMatrix<T>;
      out Diagnostics: TDenseSolveDiagnostics): specialize IDenseMatrix<T>;
    property Rows: SizeInt read GetRows;
    property Cols: SizeInt read GetCols;
    property Q: specialize IDenseMatrix<T> read GetQ;
    property R: specialize IDenseMatrix<T> read GetR;
    { A*P = Q*R; Permutation[j] is the source column at factor column j. }
    property Permutation: TSizeIntArray read GetPermutation;
    property NumericalRank: SizeInt read GetNumericalRank;
    property Tolerance: Double read GetTolerance;
    property ConditionIndicator: Double read GetConditionIndicator;
    property IsColumnPivoted: Boolean read GetIsColumnPivoted;
  end;

  generic IDenseSVDFactorization<T> = interface
    function GetRows: SizeInt;
    function GetCols: SizeInt;
    function GetU: specialize IDenseMatrix<T>;
    function GetSingularValues: TDoubleArray;
    function GetV: specialize IDenseMatrix<T>;
    function GetNumericalRank: SizeInt;
    function GetTolerance: Double;
    function GetConditionIndicator: Double;
    function GetSweeps: SizeInt;
    function SolveMinimumNorm(const B: specialize IDenseMatrix<T>):
      specialize IDenseMatrix<T>;
    function SolveMinimumNormWithInfo(const B: specialize IDenseMatrix<T>;
      out Diagnostics: TDenseSolveDiagnostics): specialize IDenseMatrix<T>;
    property Rows: SizeInt read GetRows;
    property Cols: SizeInt read GetCols;
    { Compact convention: A = U*diag(SingularValues)*V^H. }
    property U: specialize IDenseMatrix<T> read GetU;
    property SingularValues: TDoubleArray read GetSingularValues;
    property V: specialize IDenseMatrix<T> read GetV;
    property NumericalRank: SizeInt read GetNumericalRank;
    property Tolerance: Double read GetTolerance;
    property ConditionIndicator: Double read GetConditionIndicator;
    property Sweeps: SizeInt read GetSweeps;
  end;

  generic IDenseHermitianEigenFactorization<T> = interface
    function GetSize: SizeInt;
    function GetEigenvalues: TDoubleArray;
    function GetEigenvectors: specialize IDenseMatrix<T>;
    function GetSweeps: SizeInt;
    function GetConverged: Boolean;
    property Size: SizeInt read GetSize;
    property Eigenvalues: TDoubleArray read GetEigenvalues;
    { Columns are normalized eigenvectors; eigenvalues are ascending. }
    property Eigenvectors: specialize IDenseMatrix<T> read GetEigenvectors;
    property Sweeps: SizeInt read GetSweeps;
    property Converged: Boolean read GetConverged;
  end;

  IDenseSingleQR = specialize IDenseQRFactorization<Single>;
  IDenseDoubleQR = specialize IDenseQRFactorization<Double>;
  IDenseSingleComplexQR =
    specialize IDenseQRFactorization<TSingleComplex>;
  IDenseComplexQR = specialize IDenseQRFactorization<TComplex>;

  IDenseSingleSVD = specialize IDenseSVDFactorization<Single>;
  IDenseDoubleSVD = specialize IDenseSVDFactorization<Double>;
  IDenseSingleComplexSVD =
    specialize IDenseSVDFactorization<TSingleComplex>;
  IDenseComplexSVD = specialize IDenseSVDFactorization<TComplex>;

  IDenseSingleSymmetricEigen =
    specialize IDenseHermitianEigenFactorization<Single>;
  IDenseDoubleSymmetricEigen =
    specialize IDenseHermitianEigenFactorization<Double>;
  IDenseSingleComplexHermitianEigen =
    specialize IDenseHermitianEigenFactorization<TSingleComplex>;
  IDenseComplexHermitianEigen =
    specialize IDenseHermitianEigenFactorization<TComplex>;

function SolveTriangular(const A, B: IDenseSingleMatrix;
  const Triangle: TDenseTriangle; const Transpose: TDenseTranspose = dtNoTranspose;
  const Diagonal: TDenseDiagonal = ddNonUnit): IDenseSingleMatrix; overload;
function SolveTriangular(const A, B: IDenseDoubleMatrix;
  const Triangle: TDenseTriangle; const Transpose: TDenseTranspose = dtNoTranspose;
  const Diagonal: TDenseDiagonal = ddNonUnit): IDenseDoubleMatrix; overload;
function SolveTriangular(const A, B: IDenseSingleComplexMatrix;
  const Triangle: TDenseTriangle; const Transpose: TDenseTranspose = dtNoTranspose;
  const Diagonal: TDenseDiagonal = ddNonUnit):
  IDenseSingleComplexMatrix; overload;
function SolveTriangular(const A, B: IDenseComplexMatrix;
  const Triangle: TDenseTriangle; const Transpose: TDenseTranspose = dtNoTranspose;
  const Diagonal: TDenseDiagonal = ddNonUnit): IDenseComplexMatrix; overload;

function FactorQR(const A: IDenseSingleMatrix;
  const Tolerance: Double = -1.0): IDenseSingleQR; overload;
function FactorQR(const A: IDenseDoubleMatrix;
  const Tolerance: Double = -1.0): IDenseDoubleQR; overload;
function FactorQR(const A: IDenseSingleComplexMatrix;
  const Tolerance: Double = -1.0): IDenseSingleComplexQR; overload;
function FactorQR(const A: IDenseComplexMatrix;
  const Tolerance: Double = -1.0): IDenseComplexQR; overload;

function FactorPivotedQR(const A: IDenseSingleMatrix;
  const Tolerance: Double = -1.0): IDenseSingleQR; overload;
function FactorPivotedQR(const A: IDenseDoubleMatrix;
  const Tolerance: Double = -1.0): IDenseDoubleQR; overload;
function FactorPivotedQR(const A: IDenseSingleComplexMatrix;
  const Tolerance: Double = -1.0): IDenseSingleComplexQR; overload;
function FactorPivotedQR(const A: IDenseComplexMatrix;
  const Tolerance: Double = -1.0): IDenseComplexQR; overload;

function LeastSquares(const A, B: IDenseSingleMatrix;
  out Diagnostics: TDenseSolveDiagnostics): IDenseSingleMatrix; overload;
function LeastSquares(const A, B: IDenseDoubleMatrix;
  out Diagnostics: TDenseSolveDiagnostics): IDenseDoubleMatrix; overload;
function LeastSquares(const A, B: IDenseSingleComplexMatrix;
  out Diagnostics: TDenseSolveDiagnostics):
  IDenseSingleComplexMatrix; overload;
function LeastSquares(const A, B: IDenseComplexMatrix;
  out Diagnostics: TDenseSolveDiagnostics): IDenseComplexMatrix; overload;

function RankRevealingLeastSquares(const A, B: IDenseSingleMatrix;
  out Diagnostics: TDenseSolveDiagnostics;
  const Tolerance: Double = -1.0): IDenseSingleMatrix; overload;
function RankRevealingLeastSquares(const A, B: IDenseDoubleMatrix;
  out Diagnostics: TDenseSolveDiagnostics;
  const Tolerance: Double = -1.0): IDenseDoubleMatrix; overload;
function RankRevealingLeastSquares(const A, B: IDenseSingleComplexMatrix;
  out Diagnostics: TDenseSolveDiagnostics;
  const Tolerance: Double = -1.0): IDenseSingleComplexMatrix; overload;
function RankRevealingLeastSquares(const A, B: IDenseComplexMatrix;
  out Diagnostics: TDenseSolveDiagnostics;
  const Tolerance: Double = -1.0): IDenseComplexMatrix; overload;

function FactorSVD(const A: IDenseSingleMatrix;
  const Tolerance: Double = -1.0): IDenseSingleSVD; overload;
function FactorSVD(const A: IDenseDoubleMatrix;
  const Tolerance: Double = -1.0): IDenseDoubleSVD; overload;
function FactorSVD(const A: IDenseSingleComplexMatrix;
  const Tolerance: Double = -1.0): IDenseSingleComplexSVD; overload;
function FactorSVD(const A: IDenseComplexMatrix;
  const Tolerance: Double = -1.0): IDenseComplexSVD; overload;

function MinimumNormSolve(const A, B: IDenseSingleMatrix;
  out Diagnostics: TDenseSolveDiagnostics;
  const Tolerance: Double = -1.0): IDenseSingleMatrix; overload;
function MinimumNormSolve(const A, B: IDenseDoubleMatrix;
  out Diagnostics: TDenseSolveDiagnostics;
  const Tolerance: Double = -1.0): IDenseDoubleMatrix; overload;
function MinimumNormSolve(const A, B: IDenseSingleComplexMatrix;
  out Diagnostics: TDenseSolveDiagnostics;
  const Tolerance: Double = -1.0): IDenseSingleComplexMatrix; overload;
function MinimumNormSolve(const A, B: IDenseComplexMatrix;
  out Diagnostics: TDenseSolveDiagnostics;
  const Tolerance: Double = -1.0): IDenseComplexMatrix; overload;

function FactorSymmetricEigen(const A: IDenseSingleMatrix):
  IDenseSingleSymmetricEigen; overload;
function FactorSymmetricEigen(const A: IDenseDoubleMatrix):
  IDenseDoubleSymmetricEigen; overload;
function FactorHermitianEigen(const A: IDenseSingleComplexMatrix):
  IDenseSingleComplexHermitianEigen; overload;
function FactorHermitianEigen(const A: IDenseComplexMatrix):
  IDenseComplexHermitianEigen; overload;

implementation

type
  generic TScalarArray<T> = array of T;

  generic IDecompositionScalar<T> = interface
    function Zero: T;
    function One: T;
    function FromReal(const Value: Double): T;
    function Magnitude(const Value: T): Double;
    function RealPart(const Value: T): Double;
    function ImaginaryMagnitude(const Value: T): Double;
    function Conjugate(const Value: T): T;
    function IsFinite(const Value: T): Boolean;
    function Epsilon: Double;
  end;

  generic IDecompositionFactory<T> = interface
    function Zeros(const Rows, Cols: SizeInt): specialize IDenseMatrix<T>;
  end;

  TSingleDecompositionScalar = class(TInterfacedObject,
    specialize IDecompositionScalar<Single>)
    function Zero: Single;
    function One: Single;
    function FromReal(const Value: Double): Single;
    function Magnitude(const Value: Single): Double;
    function RealPart(const Value: Single): Double;
    function ImaginaryMagnitude(const Value: Single): Double;
    function Conjugate(const Value: Single): Single;
    function IsFinite(const Value: Single): Boolean;
    function Epsilon: Double;
  end;

  TDoubleDecompositionScalar = class(TInterfacedObject,
    specialize IDecompositionScalar<Double>)
    function Zero: Double;
    function One: Double;
    function FromReal(const Value: Double): Double;
    function Magnitude(const Value: Double): Double;
    function RealPart(const Value: Double): Double;
    function ImaginaryMagnitude(const Value: Double): Double;
    function Conjugate(const Value: Double): Double;
    function IsFinite(const Value: Double): Boolean;
    function Epsilon: Double;
  end;

  TSingleComplexDecompositionScalar = class(TInterfacedObject,
    specialize IDecompositionScalar<TSingleComplex>)
    function Zero: TSingleComplex;
    function One: TSingleComplex;
    function FromReal(const Value: Double): TSingleComplex;
    function Magnitude(const Value: TSingleComplex): Double;
    function RealPart(const Value: TSingleComplex): Double;
    function ImaginaryMagnitude(const Value: TSingleComplex): Double;
    function Conjugate(const Value: TSingleComplex): TSingleComplex;
    function IsFinite(const Value: TSingleComplex): Boolean;
    function Epsilon: Double;
  end;

  TComplexDecompositionScalar = class(TInterfacedObject,
    specialize IDecompositionScalar<TComplex>)
    function Zero: TComplex;
    function One: TComplex;
    function FromReal(const Value: Double): TComplex;
    function Magnitude(const Value: TComplex): Double;
    function RealPart(const Value: TComplex): Double;
    function ImaginaryMagnitude(const Value: TComplex): Double;
    function Conjugate(const Value: TComplex): TComplex;
    function IsFinite(const Value: TComplex): Boolean;
    function Epsilon: Double;
  end;

  TSingleDecompositionFactory = class(TInterfacedObject,
    specialize IDecompositionFactory<Single>)
    function Zeros(const Rows, Cols: SizeInt): IDenseSingleMatrix;
  end;
  TDoubleDecompositionFactory = class(TInterfacedObject,
    specialize IDecompositionFactory<Double>)
    function Zeros(const Rows, Cols: SizeInt): IDenseDoubleMatrix;
  end;
  TSingleComplexDecompositionFactory = class(TInterfacedObject,
    specialize IDecompositionFactory<TSingleComplex>)
    function Zeros(const Rows, Cols: SizeInt): IDenseSingleComplexMatrix;
  end;
  TComplexDecompositionFactory = class(TInterfacedObject,
    specialize IDecompositionFactory<TComplex>)
    function Zeros(const Rows, Cols: SizeInt): IDenseComplexMatrix;
  end;

  generic TDenseQRImpl<T> = class(TInterfacedObject,
    specialize IDenseQRFactorization<T>)
  private
    type TMatrix = specialize IDenseMatrix<T>;
  private
    FPolicy: specialize IDecompositionScalar<T>;
    FFactory: specialize IDecompositionFactory<T>;
    FSource, FQ, FR: specialize IDenseMatrix<T>;
    FPermutation: TSizeIntArray;
    FRows, FCols, FRank: SizeInt;
    FTolerance, FConditionIndicator: Double;
    FPivoted: Boolean;
    procedure Factor(const A: specialize IDenseMatrix<T>;
      const RequestedTolerance: Double);
    procedure FillDiagnostics(const B, X: specialize IDenseMatrix<T>;
      out Diagnostics: TDenseSolveDiagnostics);
  public
    constructor Create(const A: specialize IDenseMatrix<T>;
      const RequestedTolerance: Double; const Pivoted: Boolean;
      const Policy: specialize IDecompositionScalar<T>;
      const FactoryValue: specialize IDecompositionFactory<T>);
    function GetRows: SizeInt;
    function GetCols: SizeInt;
    function GetQ: specialize IDenseMatrix<T>;
    function GetR: specialize IDenseMatrix<T>;
    function GetPermutation: TSizeIntArray;
    function GetNumericalRank: SizeInt;
    function GetTolerance: Double;
    function GetConditionIndicator: Double;
    function GetIsColumnPivoted: Boolean;
    function SolveLeastSquares(const B: specialize IDenseMatrix<T>):
      specialize IDenseMatrix<T>;
    function SolveLeastSquaresWithInfo(const B: specialize IDenseMatrix<T>;
      out Diagnostics: TDenseSolveDiagnostics): specialize IDenseMatrix<T>;
  end;

  generic TDenseSVDImpl<T> = class(TInterfacedObject,
    specialize IDenseSVDFactorization<T>)
  private
    type TMatrix = specialize IDenseMatrix<T>;
  private
    FPolicy: specialize IDecompositionScalar<T>;
    FFactory: specialize IDecompositionFactory<T>;
    FSource, FU, FV: specialize IDenseMatrix<T>;
    FSingularValues: TDoubleArray;
    FRows, FCols, FRank, FSweeps: SizeInt;
    FTolerance, FConditionIndicator: Double;
    procedure Factor(const A: specialize IDenseMatrix<T>;
      const RequestedTolerance: Double);
    procedure FillDiagnostics(const B, X: specialize IDenseMatrix<T>;
      out Diagnostics: TDenseSolveDiagnostics);
  public
    constructor Create(const A: specialize IDenseMatrix<T>;
      const RequestedTolerance: Double;
      const Policy: specialize IDecompositionScalar<T>;
      const FactoryValue: specialize IDecompositionFactory<T>);
    function GetRows: SizeInt;
    function GetCols: SizeInt;
    function GetU: specialize IDenseMatrix<T>;
    function GetSingularValues: TDoubleArray;
    function GetV: specialize IDenseMatrix<T>;
    function GetNumericalRank: SizeInt;
    function GetTolerance: Double;
    function GetConditionIndicator: Double;
    function GetSweeps: SizeInt;
    function SolveMinimumNorm(const B: specialize IDenseMatrix<T>):
      specialize IDenseMatrix<T>;
    function SolveMinimumNormWithInfo(const B: specialize IDenseMatrix<T>;
      out Diagnostics: TDenseSolveDiagnostics): specialize IDenseMatrix<T>;
  end;

  generic TDenseHermitianEigenImpl<T> = class(TInterfacedObject,
    specialize IDenseHermitianEigenFactorization<T>)
  private
    type TMatrix = specialize IDenseMatrix<T>;
  private
    FPolicy: specialize IDecompositionScalar<T>;
    FFactory: specialize IDecompositionFactory<T>;
    FEigenvectors: specialize IDenseMatrix<T>;
    FEigenvalues: TDoubleArray;
    FSize, FSweeps: SizeInt;
    procedure Factor(const A: specialize IDenseMatrix<T>);
  public
    constructor Create(const A: specialize IDenseMatrix<T>;
      const Policy: specialize IDecompositionScalar<T>;
      const FactoryValue: specialize IDecompositionFactory<T>);
    function GetSize: SizeInt;
    function GetEigenvalues: TDoubleArray;
    function GetEigenvectors: specialize IDenseMatrix<T>;
    function GetSweeps: SizeInt;
    function GetConverged: Boolean;
  end;

function TSingleDecompositionScalar.Zero: Single;
begin Result := 0.0; end;
function TSingleDecompositionScalar.One: Single;
begin Result := 1.0; end;
function TSingleDecompositionScalar.FromReal(const Value: Double): Single;
begin Result := Value; end;
function TSingleDecompositionScalar.Magnitude(const Value: Single): Double;
begin Result := Abs(Value); end;
function TSingleDecompositionScalar.RealPart(const Value: Single): Double;
begin Result := Value; end;
function TSingleDecompositionScalar.ImaginaryMagnitude(
  const Value: Single): Double;
begin Result := 0.0; end;
function TSingleDecompositionScalar.Conjugate(const Value: Single): Single;
begin Result := Value; end;
function TSingleDecompositionScalar.IsFinite(const Value: Single): Boolean;
begin Result := not IsNan(Value) and not IsInfinite(Value); end;
function TSingleDecompositionScalar.Epsilon: Double;
begin Result := 1.1920928955078125E-7; end;

function TDoubleDecompositionScalar.Zero: Double;
begin Result := 0.0; end;
function TDoubleDecompositionScalar.One: Double;
begin Result := 1.0; end;
function TDoubleDecompositionScalar.FromReal(const Value: Double): Double;
begin Result := Value; end;
function TDoubleDecompositionScalar.Magnitude(const Value: Double): Double;
begin Result := Abs(Value); end;
function TDoubleDecompositionScalar.RealPart(const Value: Double): Double;
begin Result := Value; end;
function TDoubleDecompositionScalar.ImaginaryMagnitude(
  const Value: Double): Double;
begin Result := 0.0; end;
function TDoubleDecompositionScalar.Conjugate(const Value: Double): Double;
begin Result := Value; end;
function TDoubleDecompositionScalar.IsFinite(const Value: Double): Boolean;
begin Result := not IsNan(Value) and not IsInfinite(Value); end;
function TDoubleDecompositionScalar.Epsilon: Double;
begin Result := 2.2204460492503131E-16; end;

function TSingleComplexDecompositionScalar.Zero: TSingleComplex;
begin Result := TSingleComplex.Zero; end;
function TSingleComplexDecompositionScalar.One: TSingleComplex;
begin Result := TSingleComplex.One; end;
function TSingleComplexDecompositionScalar.FromReal(
  const Value: Double): TSingleComplex;
begin Result := TSingleComplex.Create(Value, 0.0); end;
function TSingleComplexDecompositionScalar.Magnitude(
  const Value: TSingleComplex): Double;
begin Result := Value.Magnitude; end;
function TSingleComplexDecompositionScalar.RealPart(
  const Value: TSingleComplex): Double;
begin Result := Value.Re; end;
function TSingleComplexDecompositionScalar.ImaginaryMagnitude(
  const Value: TSingleComplex): Double;
begin Result := Abs(Value.Im); end;
function TSingleComplexDecompositionScalar.Conjugate(
  const Value: TSingleComplex): TSingleComplex;
begin Result := Value.Conjugate; end;
function TSingleComplexDecompositionScalar.IsFinite(
  const Value: TSingleComplex): Boolean;
begin Result := Value.IsFinite; end;
function TSingleComplexDecompositionScalar.Epsilon: Double;
begin Result := 1.1920928955078125E-7; end;

function TComplexDecompositionScalar.Zero: TComplex;
begin Result := TComplex.Zero; end;
function TComplexDecompositionScalar.One: TComplex;
begin Result := TComplex.One; end;
function TComplexDecompositionScalar.FromReal(
  const Value: Double): TComplex;
begin Result := TComplex.Create(Value, 0.0); end;
function TComplexDecompositionScalar.Magnitude(
  const Value: TComplex): Double;
begin Result := Value.Magnitude; end;
function TComplexDecompositionScalar.RealPart(
  const Value: TComplex): Double;
begin Result := Value.Re; end;
function TComplexDecompositionScalar.ImaginaryMagnitude(
  const Value: TComplex): Double;
begin Result := Abs(Value.Im); end;
function TComplexDecompositionScalar.Conjugate(
  const Value: TComplex): TComplex;
begin Result := Value.Conjugate; end;
function TComplexDecompositionScalar.IsFinite(
  const Value: TComplex): Boolean;
begin Result := Value.IsFinite; end;
function TComplexDecompositionScalar.Epsilon: Double;
begin Result := 2.2204460492503131E-16; end;

function TSingleDecompositionFactory.Zeros(const Rows, Cols: SizeInt):
  IDenseSingleMatrix;
begin Result := TDenseSingleMatrix.Zeros(Rows, Cols); end;
function TDoubleDecompositionFactory.Zeros(const Rows, Cols: SizeInt):
  IDenseDoubleMatrix;
begin Result := TDenseDoubleMatrix.Zeros(Rows, Cols); end;
function TSingleComplexDecompositionFactory.Zeros(const Rows, Cols: SizeInt):
  IDenseSingleComplexMatrix;
begin Result := TDenseSingleComplexMatrix.Zeros(Rows, Cols); end;
function TComplexDecompositionFactory.Zeros(const Rows, Cols: SizeInt):
  IDenseComplexMatrix;
begin Result := TDenseComplexMatrix.Zeros(Rows, Cols); end;

procedure UpdateScaledNorm(const Value: Double; var Scale, SumSquares: Double);
var
  Ratio: Double;
begin
  if Value = 0.0 then
    Exit;
  if Scale < Value then
  begin
    if Scale = 0.0 then
      SumSquares := 1.0
    else
    begin
      Ratio := Scale / Value;
      SumSquares := 1.0 + SumSquares * Ratio * Ratio;
    end;
    Scale := Value;
  end
  else
  begin
    Ratio := Value / Scale;
    SumSquares := SumSquares + Ratio * Ratio;
  end;
end;

function FinishScaledNorm(const Scale, SumSquares: Double): Double;
var
  RootSum: Double;
begin
  if Scale = 0.0 then
    Exit(0.0);
  RootSum := Sqrt(SumSquares);
  if Scale > MaxDouble / RootSum then
    Result := Infinity
  else
    Result := Scale * RootSum;
end;

function SafeNormProductSum(const A, B, C: Double): Double;
var
  ProductValue: Double;
begin
  if (A = 0.0) or (B = 0.0) then
    ProductValue := 0.0
  else if IsInfinite(A) or IsInfinite(B) then
    ProductValue := Infinity
  else if B >= 1.0 then
  begin
    if A > MaxDouble / B then ProductValue := Infinity
    else ProductValue := A * B;
  end
  else
    ProductValue := A * B;
  if IsInfinite(ProductValue) or IsInfinite(C) or
    (ProductValue > MaxDouble - C) then
    Result := Infinity
  else
    Result := ProductValue + C;
end;

function StableJacobiTangent(const HalfDifference,
  CrossMagnitude: Double): Double;
var
  ScaleValue, ScaledDifference, ScaledCross, Denominator: Double;
begin
  { The textbook Tau=(aqq-app)/(2*|apq|) expression can overflow before its
    bounded tangent is formed. Scale the equivalent quadratic directly. }
  if CrossMagnitude = 0.0 then
    Exit(0.0);
  if HalfDifference = 0.0 then
    Exit(1.0);
  ScaleValue := Max(Abs(HalfDifference), CrossMagnitude);
  ScaledDifference := Abs(HalfDifference) / ScaleValue;
  ScaledCross := CrossMagnitude / ScaleValue;
  Denominator := ScaledDifference +
    Sqrt(ScaledDifference * ScaledDifference +
      ScaledCross * ScaledCross);
  Result := ScaledCross / Denominator;
  if HalfDifference < 0.0 then Result := -Result;
end;

generic function MatrixNorm<T>(const A: specialize IDenseMatrix<T>;
  const Policy: specialize IDecompositionScalar<T>): Double;
var
  I, J: SizeInt;
  Scale, SumSquares: Double;
begin
  Scale := 0.0;
  SumSquares := 1.0;
  for I := 0 to A.Rows - 1 do
    for J := 0 to A.Cols - 1 do
      UpdateScaledNorm(Policy.Magnitude(A[I, J]), Scale, SumSquares);
  Result := FinishScaledNorm(Scale, SumSquares);
end;

generic function ResidualNorm<T>(const A, X, B: specialize IDenseMatrix<T>;
  const Policy: specialize IDecompositionScalar<T>): Double;
var
  I, J, K: SizeInt;
  Sum: T;
  Scale, SumSquares: Double;
begin
  Scale := 0.0;
  SumSquares := 1.0;
  for I := 0 to A.Rows - 1 do
    for J := 0 to B.Cols - 1 do
    begin
      Sum := Policy.Zero;
      for K := 0 to A.Cols - 1 do
        Sum := Sum + A[I, K] * X[K, J];
      UpdateScaledNorm(Policy.Magnitude(B[I, J] - Sum),
        Scale, SumSquares);
    end;
  Result := FinishScaledNorm(Scale, SumSquares);
end;

generic procedure CompleteDiagnostics<T>(
  const MethodName: string; const A, X, B: specialize IDenseMatrix<T>;
  const Rank: SizeInt; const Tolerance, ConditionIndicator: Double;
  const Policy: specialize IDecompositionScalar<T>;
  out Diagnostics: TDenseSolveDiagnostics);
var
  Denominator: Double;
begin
  Diagnostics.Method := MethodName;
  Diagnostics.NumericalRank := Rank;
  Diagnostics.IsRankDeficient := Rank < Min(A.Rows, A.Cols);
  Diagnostics.Tolerance := Tolerance;
  Diagnostics.ConditionIndicator := ConditionIndicator;
  Diagnostics.ResidualNorm := specialize ResidualNorm<T>(A, X, B, Policy);
  Denominator := SafeNormProductSum(
    specialize MatrixNorm<T>(A, Policy),
    specialize MatrixNorm<T>(X, Policy),
    specialize MatrixNorm<T>(B, Policy));
  if Diagnostics.ResidualNorm = 0.0 then
    Diagnostics.BackwardError := 0.0
  else if IsInfinite(Denominator) then
    Diagnostics.BackwardError := 0.0
  else if Denominator = 0.0 then
    Diagnostics.BackwardError := Infinity
  else
    Diagnostics.BackwardError := Diagnostics.ResidualNorm / Denominator;
end;

generic procedure ValidateMatrix<T>(const A: specialize IDenseMatrix<T>;
  const OperationName, ArgumentName: string;
  const Policy: specialize IDecompositionScalar<T>);
var
  I, J: SizeInt;
begin
  if A = nil then
    raise EDenseMatrixError.CreateFmt('%s: %s must not be nil.',
      [OperationName, ArgumentName]);
  for I := 0 to A.Rows - 1 do
    for J := 0 to A.Cols - 1 do
      if not Policy.IsFinite(A[I, J]) then
        raise EDenseMatrixError.CreateFmt(
          '%s: %s element [%d,%d] must be finite.',
          [OperationName, ArgumentName, I, J]);
end;

generic function GetOpValue<T>(const A: specialize IDenseMatrix<T>;
  const Row, Col: SizeInt; const Transpose: TDenseTranspose;
  const Policy: specialize IDecompositionScalar<T>): T;
begin
  Result := Policy.Zero;
  case Transpose of
    dtNoTranspose: Result := A[Row, Col];
    dtTranspose: Result := A[Col, Row];
    dtConjugateTranspose: Result := Policy.Conjugate(A[Col, Row]);
  end;
end;

generic function SolveTriangularImpl<T>(const A, B:
  specialize IDenseMatrix<T>; const Triangle: TDenseTriangle;
  const Transpose: TDenseTranspose; const Diagonal: TDenseDiagonal;
  const Policy: specialize IDecompositionScalar<T>):
  specialize IDenseMatrix<T>;
var
  I, J, K, N: SizeInt;
  EffectiveLower: Boolean;
  Sum, DiagonalValue: T;
  Scale, Threshold: Double;
begin
  specialize ValidateMatrix<T>(A, 'SolveTriangular', 'coefficient matrix',
    Policy);
  specialize ValidateMatrix<T>(B, 'SolveTriangular', 'right-hand side',
    Policy);
  if A.Rows <> A.Cols then
    raise EDenseMatrixError.CreateFmt(
      'SolveTriangular: coefficient matrix must be square; got %d x %d.',
      [A.Rows, A.Cols]);
  if B.Rows <> A.Rows then
    raise EDenseMatrixError.CreateFmt(
      'SolveTriangular: right-hand side must have %d rows; got %d x %d.',
      [A.Rows, B.Rows, B.Cols]);
  N := A.Rows;
  Scale := 0.0;
  for I := 0 to N - 1 do
    for J := 0 to N - 1 do
      Scale := Max(Scale, Policy.Magnitude(A[I, J]));
  Threshold := Policy.Epsilon * Max(1, N) * Scale;
  if Diagonal = ddNonUnit then
    for I := 0 to N - 1 do
      if Policy.Magnitude(A[I, I]) <= Threshold then
        raise EDenseMatrixError.CreateFmt(
          'SolveTriangular: diagonal element [%d,%d] is singular at tolerance %g.',
          [I, I, Threshold]);
  Result := B.Clone;
  EffectiveLower := Triangle = dtLower;
  if Transpose <> dtNoTranspose then
    EffectiveLower := not EffectiveLower;
  if EffectiveLower then
    for I := 0 to N - 1 do
      for J := 0 to B.Cols - 1 do
      begin
        Sum := Result[I, J];
        for K := 0 to I - 1 do
          Sum := Sum - specialize GetOpValue<T>(A, I, K, Transpose,
            Policy) * Result[K, J];
        if Diagonal = ddNonUnit then
        begin
          DiagonalValue := specialize GetOpValue<T>(A, I, I, Transpose,
            Policy);
          Sum := Sum / DiagonalValue;
        end;
        Result[I, J] := Sum;
      end
  else
    for I := N - 1 downto 0 do
      for J := 0 to B.Cols - 1 do
      begin
        Sum := Result[I, J];
        for K := I + 1 to N - 1 do
          Sum := Sum - specialize GetOpValue<T>(A, I, K, Transpose,
            Policy) * Result[K, J];
        if Diagonal = ddNonUnit then
        begin
          DiagonalValue := specialize GetOpValue<T>(A, I, I, Transpose,
            Policy);
          Sum := Sum / DiagonalValue;
        end;
        Result[I, J] := Sum;
      end;
end;

constructor TDenseQRImpl.Create(const A: specialize IDenseMatrix<T>;
  const RequestedTolerance: Double; const Pivoted: Boolean;
  const Policy: specialize IDecompositionScalar<T>;
  const FactoryValue: specialize IDecompositionFactory<T>);
begin
  inherited Create;
  FPolicy := Policy;
  FFactory := FactoryValue;
  FPivoted := Pivoted;
  Factor(A, RequestedTolerance);
end;

procedure TDenseQRImpl.Factor(const A: specialize IDenseMatrix<T>;
  const RequestedTolerance: Double);
var
  QFull: TMatrix;
  V: specialize TScalarArray<T>;
  I, J, K, L, PivotCol, TempIndex: SizeInt;
  Scale, SumSquares, NormX, AlphaMagnitude, Tau, MaxNorm, CandidateNorm,
    MaxDiagonal, MinDiagonal: Double;
  Alpha, Phase, Beta, Denominator, DotValue, Temp: T;
begin
  { Golub & Van Loan 4e, 5.2/5.4. Reflectors are applied to the trailing
    matrix and accumulated into an explicit Q. The optional pivot chooses the
    largest remaining trailing column norm; deterministic ties keep the
    earliest column. }
  specialize ValidateMatrix<T>(A, 'FactorQR', 'source matrix', FPolicy);
  if IsNan(RequestedTolerance) or IsInfinite(RequestedTolerance) then
    raise EDenseMatrixError.Create('FactorQR: tolerance must be finite.');
  if A.Rows < A.Cols then
    raise EDenseMatrixError.CreateFmt(
      'FactorQR: source must be tall or square; got %d x %d.',
      [A.Rows, A.Cols]);
  FRows := A.Rows;
  FCols := A.Cols;
  FSource := A.Clone;
  FR := A.Clone;
  QFull := FFactory.Zeros(FRows, FRows);
  for I := 0 to FRows - 1 do
    QFull[I, I] := FPolicy.One;
  SetLength(FPermutation, FCols);
  for J := 0 to FCols - 1 do
    FPermutation[J] := J;

  for K := 0 to FCols - 1 do
  begin
    if FPivoted then
    begin
      PivotCol := K;
      MaxNorm := -1.0;
      for J := K to FCols - 1 do
      begin
        Scale := 0.0;
        SumSquares := 1.0;
        for I := K to FRows - 1 do
          UpdateScaledNorm(FPolicy.Magnitude(FR[I, J]), Scale, SumSquares);
        if Scale = 0.0 then
          CandidateNorm := 0.0
        else
          CandidateNorm := Scale * Sqrt(SumSquares);
        if CandidateNorm > MaxNorm then
        begin
          MaxNorm := CandidateNorm;
          PivotCol := J;
        end;
      end;
      if PivotCol <> K then
      begin
        for I := 0 to FRows - 1 do
        begin
          Temp := FR[I, K];
          FR[I, K] := FR[I, PivotCol];
          FR[I, PivotCol] := Temp;
        end;
        TempIndex := FPermutation[K];
        FPermutation[K] := FPermutation[PivotCol];
        FPermutation[PivotCol] := TempIndex;
      end;
    end;

    SetLength(V, FRows - K);
    Scale := 0.0;
    SumSquares := 1.0;
    for I := K to FRows - 1 do
      UpdateScaledNorm(FPolicy.Magnitude(FR[I, K]), Scale, SumSquares);
    if Scale = 0.0 then
      NormX := 0.0
    else
      NormX := Scale * Sqrt(SumSquares);
    if NormX = 0.0 then
      Continue;
    Alpha := FR[K, K];
    AlphaMagnitude := FPolicy.Magnitude(Alpha);
    if AlphaMagnitude = 0.0 then
      Phase := FPolicy.One
    else
      Phase := Alpha / FPolicy.FromReal(AlphaMagnitude);
    Beta := -(Phase * FPolicy.FromReal(NormX));
    Denominator := Alpha - Beta;
    V[0] := FPolicy.One;
    for I := K + 1 to FRows - 1 do
      V[I - K] := FR[I, K] / Denominator;
    Tau := (NormX + AlphaMagnitude) / NormX;
    FR[K, K] := Beta;
    for I := K + 1 to FRows - 1 do
      FR[I, K] := FPolicy.Zero;

    for J := K + 1 to FCols - 1 do
    begin
      DotValue := FPolicy.Zero;
      for I := K to FRows - 1 do
        DotValue := DotValue +
          FPolicy.Conjugate(V[I - K]) * FR[I, J];
      DotValue := FPolicy.FromReal(Tau) * DotValue;
      for I := K to FRows - 1 do
        FR[I, J] := FR[I, J] - V[I - K] * DotValue;
    end;

    for I := 0 to FRows - 1 do
    begin
      DotValue := FPolicy.Zero;
      for L := K to FRows - 1 do
        DotValue := DotValue + QFull[I, L] * V[L - K];
      DotValue := FPolicy.FromReal(Tau) * DotValue;
      for L := K to FRows - 1 do
        QFull[I, L] := QFull[I, L] -
          DotValue * FPolicy.Conjugate(V[L - K]);
    end;
  end;

  FQ := FFactory.Zeros(FRows, FCols);
  for I := 0 to FRows - 1 do
    for J := 0 to FCols - 1 do
      FQ[I, J] := QFull[I, J];
  { Retain only the compact square R. }
  QFull := FFactory.Zeros(FCols, FCols);
  for I := 0 to FCols - 1 do
    for J := I to FCols - 1 do
      QFull[I, J] := FR[I, J];
  FR := QFull;

  MaxDiagonal := 0.0;
  for I := 0 to FCols - 1 do
    MaxDiagonal := Max(MaxDiagonal, FPolicy.Magnitude(FR[I, I]));
  if RequestedTolerance < 0.0 then
    FTolerance := FPolicy.Epsilon * Max(1, Max(FRows, FCols)) *
      MaxDiagonal
  else
    FTolerance := RequestedTolerance;
  FRank := 0;
  MinDiagonal := Infinity;
  for I := 0 to FCols - 1 do
    if FPolicy.Magnitude(FR[I, I]) > FTolerance then
    begin
      Inc(FRank);
      MinDiagonal := Min(MinDiagonal, FPolicy.Magnitude(FR[I, I]));
    end;
  if MaxDiagonal = 0.0 then
    FConditionIndicator := 0.0
  else if FRank = 0 then
    FConditionIndicator := 0.0
  else
    FConditionIndicator := MinDiagonal / MaxDiagonal;
end;

function TDenseQRImpl.GetRows: SizeInt;
begin Result := FRows; end;
function TDenseQRImpl.GetCols: SizeInt;
begin Result := FCols; end;
function TDenseQRImpl.GetQ: specialize IDenseMatrix<T>;
begin Result := FQ.Clone; end;
function TDenseQRImpl.GetR: specialize IDenseMatrix<T>;
begin Result := FR.Clone; end;
function TDenseQRImpl.GetPermutation: TSizeIntArray;
var I: SizeInt;
begin
  Result := nil;
  SetLength(Result, Length(FPermutation));
  for I := 0 to High(FPermutation) do Result[I] := FPermutation[I];
end;
function TDenseQRImpl.GetNumericalRank: SizeInt;
begin Result := FRank; end;
function TDenseQRImpl.GetTolerance: Double;
begin Result := FTolerance; end;
function TDenseQRImpl.GetConditionIndicator: Double;
begin Result := FConditionIndicator; end;
function TDenseQRImpl.GetIsColumnPivoted: Boolean;
begin Result := FPivoted; end;

function TDenseQRImpl.SolveLeastSquares(
  const B: specialize IDenseMatrix<T>): specialize IDenseMatrix<T>;
var
  I, J, K: SizeInt;
  Y, Z: TMatrix;
  Sum: T;
begin
  specialize ValidateMatrix<T>(B, 'QR SolveLeastSquares',
    'right-hand side', FPolicy);
  if B.Rows <> FRows then
    raise EDenseMatrixError.CreateFmt(
      'QR SolveLeastSquares: right-hand side must have %d rows; got %d x %d.',
      [FRows, B.Rows, B.Cols]);
  if (not FPivoted) and (FRank < FCols) then
    raise EDenseMatrixError.CreateFmt(
      'QR SolveLeastSquares: factor is rank deficient (%d of %d); use column-pivoted QR or SVD.',
      [FRank, FCols]);
  Y := FFactory.Zeros(FCols, B.Cols);
  for I := 0 to FCols - 1 do
    for J := 0 to B.Cols - 1 do
    begin
      Sum := FPolicy.Zero;
      for K := 0 to FRows - 1 do
        Sum := Sum + FPolicy.Conjugate(FQ[K, I]) * B[K, J];
      Y[I, J] := Sum;
    end;
  Z := FFactory.Zeros(FCols, B.Cols);
  for I := FRank - 1 downto 0 do
    for J := 0 to B.Cols - 1 do
    begin
      Sum := Y[I, J];
      for K := I + 1 to FRank - 1 do
        Sum := Sum - FR[I, K] * Z[K, J];
      Z[I, J] := Sum / FR[I, I];
    end;
  Result := FFactory.Zeros(FCols, B.Cols);
  for I := 0 to FCols - 1 do
    for J := 0 to B.Cols - 1 do
      Result[FPermutation[I], J] := Z[I, J];
end;

procedure TDenseQRImpl.FillDiagnostics(const B, X:
  specialize IDenseMatrix<T>; out Diagnostics: TDenseSolveDiagnostics);
var
  SelectedMethod: string;
begin
  if FPivoted then
    SelectedMethod := 'column-pivoted Householder QR'
  else
    SelectedMethod := 'Householder QR';
  specialize CompleteDiagnostics<T>(SelectedMethod, FSource, X, B, FRank,
    FTolerance, FConditionIndicator, FPolicy, Diagnostics);
end;

function TDenseQRImpl.SolveLeastSquaresWithInfo(
  const B: specialize IDenseMatrix<T>;
  out Diagnostics: TDenseSolveDiagnostics): specialize IDenseMatrix<T>;
begin
  Result := SolveLeastSquares(B);
  FillDiagnostics(B, Result, Diagnostics);
end;

constructor TDenseSVDImpl.Create(const A: specialize IDenseMatrix<T>;
  const RequestedTolerance: Double;
  const Policy: specialize IDecompositionScalar<T>;
  const FactoryValue: specialize IDecompositionFactory<T>);
begin
  inherited Create;
  FPolicy := Policy;
  FFactory := FactoryValue;
  Factor(A, RequestedTolerance);
end;

procedure TDenseSVDImpl.Factor(const A: specialize IDenseMatrix<T>;
  const RequestedTolerance: Double);
const
  MAX_SWEEPS = 100;
var
  Work, VFull: TMatrix;
  Norms: TDoubleArray;
  I, J, P, Q, Sweep, CompactSize, Best: SizeInt;
  NP, NQ, ScaleValue, App, Aqq, CrossMagnitude, HalfDifference, Rotation, C,
    MaxSingular, MinSingular, TempReal, CorrelationTolerance, GlobalScale,
    ColumnZeroTolerance: Double;
  Cross, Phase, S, OldP, OldQ, TempScalar, DotValue: T;
  Changed: Boolean;
begin
  { One-sided Jacobi: right rotations orthogonalize Work's columns while the
    same rotations accumulate V. Column norms then become singular values and
    normalized Work columns become U. Direct scalar-typed arithmetic avoids a
    compatibility or precision-conversion path. }
  specialize ValidateMatrix<T>(A, 'FactorSVD', 'source matrix', FPolicy);
  if IsNan(RequestedTolerance) or IsInfinite(RequestedTolerance) then
    raise EDenseMatrixError.Create('FactorSVD: tolerance must be finite.');
  FRows := A.Rows;
  FCols := A.Cols;
  CompactSize := Min(FRows, FCols);
  FSource := A.Clone;
  Work := A.Clone;
  GlobalScale := 0.0;
  for I := 0 to FRows - 1 do
    for J := 0 to FCols - 1 do
      GlobalScale := Max(GlobalScale, FPolicy.Magnitude(Work[I, J]));
  ColumnZeroTolerance := FPolicy.Epsilon *
    Max(1, Max(FRows, FCols)) * GlobalScale;
  VFull := FFactory.Zeros(FCols, FCols);
  for I := 0 to FCols - 1 do
    VFull[I, I] := FPolicy.One;
  CorrelationTolerance := FPolicy.Epsilon *
    Max(1, Max(FRows, FCols));
  FSweeps := 0;
  Changed := False;
  for Sweep := 1 to MAX_SWEEPS do
  begin
    Changed := False;
    for P := 0 to FCols - 2 do
      for Q := P + 1 to FCols - 1 do
      begin
        NP := 0.0;
        NQ := 0.0;
        for I := 0 to FRows - 1 do
        begin
          NP := Max(NP, FPolicy.Magnitude(Work[I, P]));
          NQ := Max(NQ, FPolicy.Magnitude(Work[I, Q]));
        end;
        { In a wide or rank-deficient problem, roundoff leaves nominally null
          columns with tiny values. Re-orthogonalising those columns forever
          can cycle on Win32/x87; they are already below the rank threshold. }
        if (NP <= ColumnZeroTolerance) or (NQ <= ColumnZeroTolerance) then
          Continue;
        ScaleValue := Max(NP, NQ);
        App := 0.0;
        Aqq := 0.0;
        Cross := FPolicy.Zero;
        for I := 0 to FRows - 1 do
        begin
          OldP := Work[I, P] / FPolicy.FromReal(ScaleValue);
          OldQ := Work[I, Q] / FPolicy.FromReal(ScaleValue);
          App := App + Sqr(FPolicy.Magnitude(OldP));
          Aqq := Aqq + Sqr(FPolicy.Magnitude(OldQ));
          Cross := Cross + FPolicy.Conjugate(OldP) * OldQ;
        end;
        CrossMagnitude := FPolicy.Magnitude(Cross);
        if CrossMagnitude <= CorrelationTolerance * Sqrt(App * Aqq) then
          Continue;
        Changed := True;
        Phase := Cross / FPolicy.FromReal(CrossMagnitude);
        HalfDifference := 0.5 * (Aqq - App);
        Rotation := StableJacobiTangent(HalfDifference, CrossMagnitude);
        C := 1.0 / Sqrt(1.0 + Rotation * Rotation);
        S := FPolicy.FromReal(C * Rotation) * Phase;
        for I := 0 to FRows - 1 do
        begin
          OldP := Work[I, P];
          OldQ := Work[I, Q];
          Work[I, P] := FPolicy.FromReal(C) * OldP -
            FPolicy.Conjugate(S) * OldQ;
          Work[I, Q] := S * OldP + FPolicy.FromReal(C) * OldQ;
        end;
        for I := 0 to FCols - 1 do
        begin
          OldP := VFull[I, P];
          OldQ := VFull[I, Q];
          VFull[I, P] := FPolicy.FromReal(C) * OldP -
            FPolicy.Conjugate(S) * OldQ;
          VFull[I, Q] := S * OldP + FPolicy.FromReal(C) * OldQ;
        end;
      end;
    FSweeps := Sweep;
    if not Changed then
      Break;
  end;
  if Changed then
    raise EDenseMatrixError.CreateFmt(
      'FactorSVD: one-sided Jacobi iteration did not converge in %d sweeps.',
      [MAX_SWEEPS]);

  SetLength(Norms, FCols);
  for J := 0 to FCols - 1 do
  begin
    NP := 0.0;
    Aqq := 1.0;
    for I := 0 to FRows - 1 do
      UpdateScaledNorm(FPolicy.Magnitude(Work[I, J]), NP, Aqq);
    if NP = 0.0 then Norms[J] := 0.0
    else Norms[J] := NP * Sqrt(Aqq);
  end;
  for P := 0 to FCols - 1 do
  begin
    Best := P;
    for Q := P + 1 to FCols - 1 do
      if Norms[Q] > Norms[Best] then Best := Q;
    if Best <> P then
    begin
      TempReal := Norms[P]; Norms[P] := Norms[Best]; Norms[Best] := TempReal;
      for I := 0 to FRows - 1 do
      begin
        TempScalar := Work[I, P]; Work[I, P] := Work[I, Best];
        Work[I, Best] := TempScalar;
      end;
      for I := 0 to FCols - 1 do
      begin
        TempScalar := VFull[I, P]; VFull[I, P] := VFull[I, Best];
        VFull[I, Best] := TempScalar;
      end;
    end;
  end;
  SetLength(FSingularValues, CompactSize);
  FU := FFactory.Zeros(FRows, CompactSize);
  FV := FFactory.Zeros(FCols, CompactSize);
  for J := 0 to CompactSize - 1 do
  begin
    FSingularValues[J] := Norms[J];
    for I := 0 to FCols - 1 do
      FV[I, J] := VFull[I, J];
    if Norms[J] > 0.0 then
      for I := 0 to FRows - 1 do
        FU[I, J] := Work[I, J] / FPolicy.FromReal(Norms[J]);
  end;
  { Deterministic orthonormal completion for zero left singular vectors. }
  for J := 0 to CompactSize - 1 do
    if FSingularValues[J] = 0.0 then
    begin
      for P := 0 to FRows - 1 do
      begin
        for I := 0 to FRows - 1 do FU[I, J] := FPolicy.Zero;
        FU[P, J] := FPolicy.One;
        for Q := 0 to J - 1 do
        begin
          DotValue := FPolicy.Zero;
          for I := 0 to FRows - 1 do
            DotValue := DotValue +
              FPolicy.Conjugate(FU[I, Q]) * FU[I, J];
          for I := 0 to FRows - 1 do
            FU[I, J] := FU[I, J] - FU[I, Q] * DotValue;
        end;
        NP := 0.0; Aqq := 1.0;
        for I := 0 to FRows - 1 do
          UpdateScaledNorm(FPolicy.Magnitude(FU[I, J]), NP, Aqq);
        if NP > 0.0 then
        begin
          NP := NP * Sqrt(Aqq);
          for I := 0 to FRows - 1 do
            FU[I, J] := FU[I, J] / FPolicy.FromReal(NP);
          Break;
        end;
      end;
    end;
  if CompactSize = 0 then MaxSingular := 0.0
  else MaxSingular := FSingularValues[0];
  if RequestedTolerance < 0.0 then
    FTolerance := FPolicy.Epsilon * Max(1, Max(FRows, FCols)) * MaxSingular
  else
    FTolerance := RequestedTolerance;
  FRank := 0;
  MinSingular := Infinity;
  for I := 0 to CompactSize - 1 do
    if FSingularValues[I] > FTolerance then
    begin
      Inc(FRank);
      MinSingular := Min(MinSingular, FSingularValues[I]);
    end;
  if (MaxSingular = 0.0) or (FRank = 0) then
    FConditionIndicator := 0.0
  else
    FConditionIndicator := MinSingular / MaxSingular;
end;

function TDenseSVDImpl.GetRows: SizeInt;
begin Result := FRows; end;
function TDenseSVDImpl.GetCols: SizeInt;
begin Result := FCols; end;
function TDenseSVDImpl.GetU: specialize IDenseMatrix<T>;
begin Result := FU.Clone; end;
function TDenseSVDImpl.GetSingularValues: TDoubleArray;
var I: SizeInt;
begin
  Result := nil;
  SetLength(Result, Length(FSingularValues));
  for I := 0 to High(FSingularValues) do Result[I] := FSingularValues[I];
end;
function TDenseSVDImpl.GetV: specialize IDenseMatrix<T>;
begin Result := FV.Clone; end;
function TDenseSVDImpl.GetNumericalRank: SizeInt;
begin Result := FRank; end;
function TDenseSVDImpl.GetTolerance: Double;
begin Result := FTolerance; end;
function TDenseSVDImpl.GetConditionIndicator: Double;
begin Result := FConditionIndicator; end;
function TDenseSVDImpl.GetSweeps: SizeInt;
begin Result := FSweeps; end;

function TDenseSVDImpl.SolveMinimumNorm(
  const B: specialize IDenseMatrix<T>): specialize IDenseMatrix<T>;
var
  I, J, K: SizeInt;
  Coefficients: TMatrix;
  Sum: T;
begin
  specialize ValidateMatrix<T>(B, 'SVD SolveMinimumNorm',
    'right-hand side', FPolicy);
  if B.Rows <> FRows then
    raise EDenseMatrixError.CreateFmt(
      'SVD SolveMinimumNorm: right-hand side must have %d rows; got %d x %d.',
      [FRows, B.Rows, B.Cols]);
  Coefficients := FFactory.Zeros(FRank, B.Cols);
  for I := 0 to FRank - 1 do
    for J := 0 to B.Cols - 1 do
    begin
      Sum := FPolicy.Zero;
      for K := 0 to FRows - 1 do
        Sum := Sum + FPolicy.Conjugate(FU[K, I]) * B[K, J];
      Coefficients[I, J] := Sum / FPolicy.FromReal(FSingularValues[I]);
    end;
  Result := FFactory.Zeros(FCols, B.Cols);
  for I := 0 to FCols - 1 do
    for J := 0 to B.Cols - 1 do
    begin
      Sum := FPolicy.Zero;
      for K := 0 to FRank - 1 do
        Sum := Sum + FV[I, K] * Coefficients[K, J];
      Result[I, J] := Sum;
    end;
end;

procedure TDenseSVDImpl.FillDiagnostics(const B, X:
  specialize IDenseMatrix<T>; out Diagnostics: TDenseSolveDiagnostics);
begin
  specialize CompleteDiagnostics<T>('compact one-sided Jacobi SVD',
    FSource, X, B, FRank, FTolerance, FConditionIndicator, FPolicy,
    Diagnostics);
end;

function TDenseSVDImpl.SolveMinimumNormWithInfo(
  const B: specialize IDenseMatrix<T>;
  out Diagnostics: TDenseSolveDiagnostics): specialize IDenseMatrix<T>;
begin
  Result := SolveMinimumNorm(B);
  FillDiagnostics(B, Result, Diagnostics);
end;

constructor TDenseHermitianEigenImpl.Create(
  const A: specialize IDenseMatrix<T>;
  const Policy: specialize IDecompositionScalar<T>;
  const FactoryValue: specialize IDecompositionFactory<T>);
begin
  inherited Create;
  FPolicy := Policy;
  FFactory := FactoryValue;
  Factor(A);
end;

procedure TDenseHermitianEigenImpl.Factor(
  const A: specialize IDenseMatrix<T>);
const
  MAX_SWEEPS = 100;
var
  Work: TMatrix;
  I, J, P, Q, Sweep, Best: SizeInt;
  MatrixScale, SymmetryTolerance, MaxOff, MaxDiagonal, Threshold,
    App, Aqq, R, HalfDifference, Rotation, C, TempReal: Double;
  APQ, Phase, S, OldP, OldQ, NewP, NewQ, TempScalar: T;
  Converged: Boolean;
begin
  { Deterministic cyclic two-sided Jacobi similarity rotations. Updating both
    mirrored entries preserves Hermitian structure; applying the same right
    rotations to FEigenvectors preserves A*V = V*D. }
  specialize ValidateMatrix<T>(A, 'FactorHermitianEigen', 'source matrix',
    FPolicy);
  if A.Rows <> A.Cols then
    raise EDenseMatrixError.CreateFmt(
      'FactorHermitianEigen: source must be square; got %d x %d.',
      [A.Rows, A.Cols]);
  FSize := A.Rows;
  MatrixScale := 0.0;
  for I := 0 to FSize - 1 do
    for J := 0 to FSize - 1 do
      MatrixScale := Max(MatrixScale, FPolicy.Magnitude(A[I, J]));
  SymmetryTolerance := FPolicy.Epsilon * Max(1, FSize) * MatrixScale;
  for I := 0 to FSize - 1 do
  begin
    if FPolicy.ImaginaryMagnitude(A[I, I]) > SymmetryTolerance then
      raise EDenseMatrixError.CreateFmt(
        'FactorHermitianEigen: diagonal element [%d,%d] must be real.', [I, I]);
    for J := 0 to I - 1 do
      if FPolicy.Magnitude(A[I, J] - FPolicy.Conjugate(A[J, I])) >
        SymmetryTolerance then
        raise EDenseMatrixError.CreateFmt(
          'FactorHermitianEigen: source must be symmetric/Hermitian; mismatch at [%d,%d].',
          [I, J]);
  end;
  Work := A.Clone;
  FEigenvectors := FFactory.Zeros(FSize, FSize);
  for I := 0 to FSize - 1 do
    FEigenvectors[I, I] := FPolicy.One;
  FSweeps := 0;
  Converged := FSize <= 1;
  for Sweep := 1 to MAX_SWEEPS do
  begin
    MaxOff := 0.0;
    MaxDiagonal := 0.0;
    for I := 0 to FSize - 1 do
    begin
      MaxDiagonal := Max(MaxDiagonal, Abs(FPolicy.RealPart(Work[I, I])));
      for J := I + 1 to FSize - 1 do
        MaxOff := Max(MaxOff, FPolicy.Magnitude(Work[I, J]));
    end;
    Threshold := FPolicy.Epsilon * Max(1, FSize) * MaxDiagonal;
    if MaxOff <= Threshold then
    begin
      Converged := True;
      Break;
    end;
    for P := 0 to FSize - 2 do
      for Q := P + 1 to FSize - 1 do
      begin
        APQ := Work[P, Q];
        R := FPolicy.Magnitude(APQ);
        if R <= Threshold then Continue;
        App := FPolicy.RealPart(Work[P, P]);
        Aqq := FPolicy.RealPart(Work[Q, Q]);
        Phase := APQ / FPolicy.FromReal(R);
        HalfDifference := 0.5 * Aqq - 0.5 * App;
        Rotation := StableJacobiTangent(HalfDifference, R);
        C := 1.0 / Sqrt(1.0 + Rotation * Rotation);
        S := FPolicy.FromReal(C * Rotation) * Phase;
        for I := 0 to FSize - 1 do
          if (I <> P) and (I <> Q) then
          begin
            OldP := Work[I, P];
            OldQ := Work[I, Q];
            NewP := FPolicy.FromReal(C) * OldP -
              FPolicy.Conjugate(S) * OldQ;
            NewQ := S * OldP + FPolicy.FromReal(C) * OldQ;
            Work[I, P] := NewP;
            Work[P, I] := FPolicy.Conjugate(NewP);
            Work[I, Q] := NewQ;
            Work[Q, I] := FPolicy.Conjugate(NewQ);
          end;
        Work[P, P] := FPolicy.FromReal(App - Rotation * R);
        Work[Q, Q] := FPolicy.FromReal(Aqq + Rotation * R);
        Work[P, Q] := FPolicy.Zero;
        Work[Q, P] := FPolicy.Zero;
        for I := 0 to FSize - 1 do
        begin
          OldP := FEigenvectors[I, P];
          OldQ := FEigenvectors[I, Q];
          FEigenvectors[I, P] := FPolicy.FromReal(C) * OldP -
            FPolicy.Conjugate(S) * OldQ;
          FEigenvectors[I, Q] := S * OldP +
            FPolicy.FromReal(C) * OldQ;
        end;
      end;
    FSweeps := Sweep;
  end;
  if not Converged then
    raise EDenseMatrixError.CreateFmt(
      'FactorHermitianEigen: cyclic Jacobi iteration did not converge in %d sweeps.',
      [MAX_SWEEPS]);
  SetLength(FEigenvalues, FSize);
  for I := 0 to FSize - 1 do
    FEigenvalues[I] := FPolicy.RealPart(Work[I, I]);
  for I := 0 to FSize - 1 do
  begin
    Best := I;
    for J := I + 1 to FSize - 1 do
      if FEigenvalues[J] < FEigenvalues[Best] then Best := J;
    if Best <> I then
    begin
      TempReal := FEigenvalues[I];
      FEigenvalues[I] := FEigenvalues[Best];
      FEigenvalues[Best] := TempReal;
      for J := 0 to FSize - 1 do
      begin
        TempScalar := FEigenvectors[J, I];
        FEigenvectors[J, I] := FEigenvectors[J, Best];
        FEigenvectors[J, Best] := TempScalar;
      end;
    end;
  end;
end;

function TDenseHermitianEigenImpl.GetSize: SizeInt;
begin Result := FSize; end;
function TDenseHermitianEigenImpl.GetEigenvalues: TDoubleArray;
var I: SizeInt;
begin
  Result := nil;
  SetLength(Result, Length(FEigenvalues));
  for I := 0 to High(FEigenvalues) do Result[I] := FEigenvalues[I];
end;
function TDenseHermitianEigenImpl.GetEigenvectors:
  specialize IDenseMatrix<T>;
begin Result := FEigenvectors.Clone; end;
function TDenseHermitianEigenImpl.GetSweeps: SizeInt;
begin Result := FSweeps; end;
function TDenseHermitianEigenImpl.GetConverged: Boolean;
begin Result := True; end;

function SolveTriangular(const A, B: IDenseSingleMatrix;
  const Triangle: TDenseTriangle; const Transpose: TDenseTranspose;
  const Diagonal: TDenseDiagonal): IDenseSingleMatrix;
var
  Policy: specialize IDecompositionScalar<Single>;
begin
  Policy := TSingleDecompositionScalar.Create;
  Result := specialize SolveTriangularImpl<Single>(A, B, Triangle, Transpose,
    Diagonal, Policy);
end;

function SolveTriangular(const A, B: IDenseDoubleMatrix;
  const Triangle: TDenseTriangle; const Transpose: TDenseTranspose;
  const Diagonal: TDenseDiagonal): IDenseDoubleMatrix;
var
  Policy: specialize IDecompositionScalar<Double>;
begin
  Policy := TDoubleDecompositionScalar.Create;
  Result := specialize SolveTriangularImpl<Double>(A, B, Triangle, Transpose,
    Diagonal, Policy);
end;

function SolveTriangular(const A, B: IDenseSingleComplexMatrix;
  const Triangle: TDenseTriangle; const Transpose: TDenseTranspose;
  const Diagonal: TDenseDiagonal): IDenseSingleComplexMatrix;
var
  Policy: specialize IDecompositionScalar<TSingleComplex>;
begin
  Policy := TSingleComplexDecompositionScalar.Create;
  Result := specialize SolveTriangularImpl<TSingleComplex>(A, B, Triangle,
    Transpose, Diagonal, Policy);
end;

function SolveTriangular(const A, B: IDenseComplexMatrix;
  const Triangle: TDenseTriangle; const Transpose: TDenseTranspose;
  const Diagonal: TDenseDiagonal): IDenseComplexMatrix;
var
  Policy: specialize IDecompositionScalar<TComplex>;
begin
  Policy := TComplexDecompositionScalar.Create;
  Result := specialize SolveTriangularImpl<TComplex>(A, B, Triangle,
    Transpose, Diagonal, Policy);
end;

function FactorQR(const A: IDenseSingleMatrix;
  const Tolerance: Double): IDenseSingleQR;
begin
  Result := specialize TDenseQRImpl<Single>.Create(A, Tolerance, False,
    TSingleDecompositionScalar.Create, TSingleDecompositionFactory.Create);
end;
function FactorQR(const A: IDenseDoubleMatrix;
  const Tolerance: Double): IDenseDoubleQR;
begin
  Result := specialize TDenseQRImpl<Double>.Create(A, Tolerance, False,
    TDoubleDecompositionScalar.Create, TDoubleDecompositionFactory.Create);
end;
function FactorQR(const A: IDenseSingleComplexMatrix;
  const Tolerance: Double): IDenseSingleComplexQR;
begin
  Result := specialize TDenseQRImpl<TSingleComplex>.Create(A, Tolerance,
    False, TSingleComplexDecompositionScalar.Create,
    TSingleComplexDecompositionFactory.Create);
end;
function FactorQR(const A: IDenseComplexMatrix;
  const Tolerance: Double): IDenseComplexQR;
begin
  Result := specialize TDenseQRImpl<TComplex>.Create(A, Tolerance, False,
    TComplexDecompositionScalar.Create, TComplexDecompositionFactory.Create);
end;

function FactorPivotedQR(const A: IDenseSingleMatrix;
  const Tolerance: Double): IDenseSingleQR;
begin
  Result := specialize TDenseQRImpl<Single>.Create(A, Tolerance, True,
    TSingleDecompositionScalar.Create, TSingleDecompositionFactory.Create);
end;
function FactorPivotedQR(const A: IDenseDoubleMatrix;
  const Tolerance: Double): IDenseDoubleQR;
begin
  Result := specialize TDenseQRImpl<Double>.Create(A, Tolerance, True,
    TDoubleDecompositionScalar.Create, TDoubleDecompositionFactory.Create);
end;
function FactorPivotedQR(const A: IDenseSingleComplexMatrix;
  const Tolerance: Double): IDenseSingleComplexQR;
begin
  Result := specialize TDenseQRImpl<TSingleComplex>.Create(A, Tolerance, True,
    TSingleComplexDecompositionScalar.Create,
    TSingleComplexDecompositionFactory.Create);
end;
function FactorPivotedQR(const A: IDenseComplexMatrix;
  const Tolerance: Double): IDenseComplexQR;
begin
  Result := specialize TDenseQRImpl<TComplex>.Create(A, Tolerance, True,
    TComplexDecompositionScalar.Create, TComplexDecompositionFactory.Create);
end;

function LeastSquares(const A, B: IDenseSingleMatrix;
  out Diagnostics: TDenseSolveDiagnostics): IDenseSingleMatrix;
begin Result := FactorQR(A).SolveLeastSquaresWithInfo(B, Diagnostics); end;
function LeastSquares(const A, B: IDenseDoubleMatrix;
  out Diagnostics: TDenseSolveDiagnostics): IDenseDoubleMatrix;
begin Result := FactorQR(A).SolveLeastSquaresWithInfo(B, Diagnostics); end;
function LeastSquares(const A, B: IDenseSingleComplexMatrix;
  out Diagnostics: TDenseSolveDiagnostics): IDenseSingleComplexMatrix;
begin Result := FactorQR(A).SolveLeastSquaresWithInfo(B, Diagnostics); end;
function LeastSquares(const A, B: IDenseComplexMatrix;
  out Diagnostics: TDenseSolveDiagnostics): IDenseComplexMatrix;
begin Result := FactorQR(A).SolveLeastSquaresWithInfo(B, Diagnostics); end;

function RankRevealingLeastSquares(const A, B: IDenseSingleMatrix;
  out Diagnostics: TDenseSolveDiagnostics;
  const Tolerance: Double): IDenseSingleMatrix;
begin
  Result := FactorPivotedQR(A, Tolerance).SolveLeastSquaresWithInfo(B,
    Diagnostics);
end;
function RankRevealingLeastSquares(const A, B: IDenseDoubleMatrix;
  out Diagnostics: TDenseSolveDiagnostics;
  const Tolerance: Double): IDenseDoubleMatrix;
begin
  Result := FactorPivotedQR(A, Tolerance).SolveLeastSquaresWithInfo(B,
    Diagnostics);
end;
function RankRevealingLeastSquares(const A, B: IDenseSingleComplexMatrix;
  out Diagnostics: TDenseSolveDiagnostics;
  const Tolerance: Double): IDenseSingleComplexMatrix;
begin
  Result := FactorPivotedQR(A, Tolerance).SolveLeastSquaresWithInfo(B,
    Diagnostics);
end;
function RankRevealingLeastSquares(const A, B: IDenseComplexMatrix;
  out Diagnostics: TDenseSolveDiagnostics;
  const Tolerance: Double): IDenseComplexMatrix;
begin
  Result := FactorPivotedQR(A, Tolerance).SolveLeastSquaresWithInfo(B,
    Diagnostics);
end;

function FactorSVD(const A: IDenseSingleMatrix;
  const Tolerance: Double): IDenseSingleSVD;
begin
  Result := specialize TDenseSVDImpl<Single>.Create(A, Tolerance,
    TSingleDecompositionScalar.Create, TSingleDecompositionFactory.Create);
end;
function FactorSVD(const A: IDenseDoubleMatrix;
  const Tolerance: Double): IDenseDoubleSVD;
begin
  Result := specialize TDenseSVDImpl<Double>.Create(A, Tolerance,
    TDoubleDecompositionScalar.Create, TDoubleDecompositionFactory.Create);
end;
function FactorSVD(const A: IDenseSingleComplexMatrix;
  const Tolerance: Double): IDenseSingleComplexSVD;
begin
  Result := specialize TDenseSVDImpl<TSingleComplex>.Create(A, Tolerance,
    TSingleComplexDecompositionScalar.Create,
    TSingleComplexDecompositionFactory.Create);
end;
function FactorSVD(const A: IDenseComplexMatrix;
  const Tolerance: Double): IDenseComplexSVD;
begin
  Result := specialize TDenseSVDImpl<TComplex>.Create(A, Tolerance,
    TComplexDecompositionScalar.Create, TComplexDecompositionFactory.Create);
end;

function MinimumNormSolve(const A, B: IDenseSingleMatrix;
  out Diagnostics: TDenseSolveDiagnostics;
  const Tolerance: Double): IDenseSingleMatrix;
begin
  Result := FactorSVD(A, Tolerance).SolveMinimumNormWithInfo(B, Diagnostics);
end;
function MinimumNormSolve(const A, B: IDenseDoubleMatrix;
  out Diagnostics: TDenseSolveDiagnostics;
  const Tolerance: Double): IDenseDoubleMatrix;
begin
  Result := FactorSVD(A, Tolerance).SolveMinimumNormWithInfo(B, Diagnostics);
end;
function MinimumNormSolve(const A, B: IDenseSingleComplexMatrix;
  out Diagnostics: TDenseSolveDiagnostics;
  const Tolerance: Double): IDenseSingleComplexMatrix;
begin
  Result := FactorSVD(A, Tolerance).SolveMinimumNormWithInfo(B, Diagnostics);
end;
function MinimumNormSolve(const A, B: IDenseComplexMatrix;
  out Diagnostics: TDenseSolveDiagnostics;
  const Tolerance: Double): IDenseComplexMatrix;
begin
  Result := FactorSVD(A, Tolerance).SolveMinimumNormWithInfo(B, Diagnostics);
end;

function FactorSymmetricEigen(const A: IDenseSingleMatrix):
  IDenseSingleSymmetricEigen;
begin
  Result := specialize TDenseHermitianEigenImpl<Single>.Create(A,
    TSingleDecompositionScalar.Create, TSingleDecompositionFactory.Create);
end;
function FactorSymmetricEigen(const A: IDenseDoubleMatrix):
  IDenseDoubleSymmetricEigen;
begin
  Result := specialize TDenseHermitianEigenImpl<Double>.Create(A,
    TDoubleDecompositionScalar.Create, TDoubleDecompositionFactory.Create);
end;
function FactorHermitianEigen(const A: IDenseSingleComplexMatrix):
  IDenseSingleComplexHermitianEigen;
begin
  Result := specialize TDenseHermitianEigenImpl<TSingleComplex>.Create(A,
    TSingleComplexDecompositionScalar.Create,
    TSingleComplexDecompositionFactory.Create);
end;
function FactorHermitianEigen(const A: IDenseComplexMatrix):
  IDenseComplexHermitianEigen;
begin
  Result := specialize TDenseHermitianEigenImpl<TComplex>.Create(A,
    TComplexDecompositionScalar.Create, TComplexDecompositionFactory.Create);
end;

end.
