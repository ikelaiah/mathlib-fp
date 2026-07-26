unit AlgebraLib.DenseSolvers;

{-----------------------------------------------------------------------------
 AlgebraLib.DenseSolvers

 Reusable pivoted-LU and Cholesky factors for the typed contiguous matrices.
 Solve(A, B) always factors A and performs triangular solves; it never forms an
 inverse. FactorLU/FactorCholesky expose factor reuse for repeated right-hand
 sides. A solve either validates and completes or leaves all caller matrices
 unchanged.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  SysUtils, Math, MathBase.Complex,
  AlgebraLib.DenseMatrices, AlgebraLib.DenseDecompositions;

type
  generic IDenseLUFactorization<T> = interface
    function GetSize: SizeInt;
    function GetPivotRatio: Double;
    function GetConditionIndicator: Double;
    function GetIsIllConditioned: Boolean;
    function GetL: specialize IDenseMatrix<T>;
    function GetU: specialize IDenseMatrix<T>;
    function GetPermutation: TSizeIntArray;
    function Solve(const B: specialize IDenseMatrix<T>):
      specialize IDenseMatrix<T>;
    function SolveWithInfo(const B: specialize IDenseMatrix<T>;
      out Diagnostics: TDenseSolveDiagnostics): specialize IDenseMatrix<T>;
    property Size: SizeInt read GetSize;
    { Smallest accepted pivot divided by the largest input magnitude. }
    property PivotRatio: Double read GetPivotRatio;
    property ConditionIndicator: Double read GetConditionIndicator;
    property IsIllConditioned: Boolean read GetIsIllConditioned;
    property L: specialize IDenseMatrix<T> read GetL;
    property U: specialize IDenseMatrix<T> read GetU;
    property Permutation: TSizeIntArray read GetPermutation;
  end;

  generic IDenseCholeskyFactorization<T> = interface
    function GetSize: SizeInt;
    function GetConditionIndicator: Double;
    function GetL: specialize IDenseMatrix<T>;
    function Solve(const B: specialize IDenseMatrix<T>):
      specialize IDenseMatrix<T>;
    function SolveWithInfo(const B: specialize IDenseMatrix<T>;
      out Diagnostics: TDenseSolveDiagnostics): specialize IDenseMatrix<T>;
    property Size: SizeInt read GetSize;
    property ConditionIndicator: Double read GetConditionIndicator;
    property L: specialize IDenseMatrix<T> read GetL;
  end;

  IDenseSingleLU = specialize IDenseLUFactorization<Single>;
  IDenseDoubleLU = specialize IDenseLUFactorization<Double>;
  IDenseSingleComplexLU =
    specialize IDenseLUFactorization<TSingleComplex>;
  IDenseComplexLU = specialize IDenseLUFactorization<TComplex>;

  IDenseSingleCholesky = specialize IDenseCholeskyFactorization<Single>;
  IDenseDoubleCholesky = specialize IDenseCholeskyFactorization<Double>;
  IDenseSingleComplexCholesky =
    specialize IDenseCholeskyFactorization<TSingleComplex>;
  IDenseComplexCholesky =
    specialize IDenseCholeskyFactorization<TComplex>;

function FactorLU(const A: IDenseSingleMatrix): IDenseSingleLU; overload;
function FactorLU(const A: IDenseDoubleMatrix): IDenseDoubleLU; overload;
function FactorLU(const A: IDenseSingleComplexMatrix):
  IDenseSingleComplexLU; overload;
function FactorLU(const A: IDenseComplexMatrix): IDenseComplexLU; overload;

function FactorCholesky(const A: IDenseSingleMatrix):
  IDenseSingleCholesky; overload;
function FactorCholesky(const A: IDenseDoubleMatrix):
  IDenseDoubleCholesky; overload;
function FactorCholesky(const A: IDenseSingleComplexMatrix):
  IDenseSingleComplexCholesky; overload;
function FactorCholesky(const A: IDenseComplexMatrix):
  IDenseComplexCholesky; overload;

function Solve(const A, B: IDenseSingleMatrix): IDenseSingleMatrix; overload;
function Solve(const A, B: IDenseDoubleMatrix): IDenseDoubleMatrix; overload;
function Solve(const A, B: IDenseSingleComplexMatrix):
  IDenseSingleComplexMatrix; overload;
function Solve(const A, B: IDenseComplexMatrix): IDenseComplexMatrix; overload;

function SolveWithInfo(const A, B: IDenseSingleMatrix;
  out Diagnostics: TDenseSolveDiagnostics): IDenseSingleMatrix; overload;
function SolveWithInfo(const A, B: IDenseDoubleMatrix;
  out Diagnostics: TDenseSolveDiagnostics): IDenseDoubleMatrix; overload;
function SolveWithInfo(const A, B: IDenseSingleComplexMatrix;
  out Diagnostics: TDenseSolveDiagnostics):
  IDenseSingleComplexMatrix; overload;
function SolveWithInfo(const A, B: IDenseComplexMatrix;
  out Diagnostics: TDenseSolveDiagnostics): IDenseComplexMatrix; overload;

function SolvePositiveDefinite(const A, B: IDenseSingleMatrix;
  out Diagnostics: TDenseSolveDiagnostics): IDenseSingleMatrix; overload;
function SolvePositiveDefinite(const A, B: IDenseDoubleMatrix;
  out Diagnostics: TDenseSolveDiagnostics): IDenseDoubleMatrix; overload;
function SolvePositiveDefinite(const A, B: IDenseSingleComplexMatrix;
  out Diagnostics: TDenseSolveDiagnostics):
  IDenseSingleComplexMatrix; overload;
function SolvePositiveDefinite(const A, B: IDenseComplexMatrix;
  out Diagnostics: TDenseSolveDiagnostics): IDenseComplexMatrix; overload;

implementation

type
  generic IScalarPolicy<T> = interface
    function Zero: T;
    function One: T;
    function FromReal(const Value: Double): T;
    function Magnitude(const Value: T): Double;
    function IsFinite(const Value: T): Boolean;
    function Conjugate(const Value: T): T;
    function RealPart(const Value: T): Double;
    function ImaginaryMagnitude(const Value: T): Double;
    function Epsilon: Double;
  end;

  generic IMatrixFactory<T> = interface
    function Zeros(const Rows, Cols: SizeInt): specialize IDenseMatrix<T>;
  end;

  TSinglePolicy = class(TInterfacedObject,
    specialize IScalarPolicy<Single>)
    function Zero: Single;
    function One: Single;
    function FromReal(const Value: Double): Single;
    function Magnitude(const Value: Single): Double;
    function IsFinite(const Value: Single): Boolean;
    function Conjugate(const Value: Single): Single;
    function RealPart(const Value: Single): Double;
    function ImaginaryMagnitude(const Value: Single): Double;
    function Epsilon: Double;
  end;

  TDoublePolicy = class(TInterfacedObject,
    specialize IScalarPolicy<Double>)
    function Zero: Double;
    function One: Double;
    function FromReal(const Value: Double): Double;
    function Magnitude(const Value: Double): Double;
    function IsFinite(const Value: Double): Boolean;
    function Conjugate(const Value: Double): Double;
    function RealPart(const Value: Double): Double;
    function ImaginaryMagnitude(const Value: Double): Double;
    function Epsilon: Double;
  end;

  TSingleComplexPolicy = class(TInterfacedObject,
    specialize IScalarPolicy<TSingleComplex>)
    function Zero: TSingleComplex;
    function One: TSingleComplex;
    function FromReal(const Value: Double): TSingleComplex;
    function Magnitude(const Value: TSingleComplex): Double;
    function IsFinite(const Value: TSingleComplex): Boolean;
    function Conjugate(const Value: TSingleComplex): TSingleComplex;
    function RealPart(const Value: TSingleComplex): Double;
    function ImaginaryMagnitude(const Value: TSingleComplex): Double;
    function Epsilon: Double;
  end;

  TComplexPolicy = class(TInterfacedObject,
    specialize IScalarPolicy<TComplex>)
    function Zero: TComplex;
    function One: TComplex;
    function FromReal(const Value: Double): TComplex;
    function Magnitude(const Value: TComplex): Double;
    function IsFinite(const Value: TComplex): Boolean;
    function Conjugate(const Value: TComplex): TComplex;
    function RealPart(const Value: TComplex): Double;
    function ImaginaryMagnitude(const Value: TComplex): Double;
    function Epsilon: Double;
  end;

  TSingleMatrixFactory = class(TInterfacedObject,
    specialize IMatrixFactory<Single>)
    function Zeros(const Rows, Cols: SizeInt): IDenseSingleMatrix;
  end;

  TDoubleMatrixFactory = class(TInterfacedObject,
    specialize IMatrixFactory<Double>)
    function Zeros(const Rows, Cols: SizeInt): IDenseDoubleMatrix;
  end;

  TSingleComplexMatrixFactory = class(TInterfacedObject,
    specialize IMatrixFactory<TSingleComplex>)
    function Zeros(const Rows, Cols: SizeInt): IDenseSingleComplexMatrix;
  end;

  TComplexMatrixFactory = class(TInterfacedObject,
    specialize IMatrixFactory<TComplex>)
    function Zeros(const Rows, Cols: SizeInt): IDenseComplexMatrix;
  end;

  generic TDenseLUImpl<T> = class(TInterfacedObject,
    specialize IDenseLUFactorization<T>)
  private
    FPolicy: specialize IScalarPolicy<T>;
    FFactory: specialize IMatrixFactory<T>;
    FSource, FCombined: specialize IDenseMatrix<T>;
    FPivots, FPermutation: TSizeIntArray;
    FSize: SizeInt;
    FPivotRatio, FPivotTolerance: Double;
    FIsIllConditioned: Boolean;
    procedure Factor(const A: specialize IDenseMatrix<T>);
  public
    constructor Create(const A: specialize IDenseMatrix<T>;
      const Policy: specialize IScalarPolicy<T>;
      const FactoryValue: specialize IMatrixFactory<T>);
    function GetSize: SizeInt;
    function GetPivotRatio: Double;
    function GetConditionIndicator: Double;
    function GetIsIllConditioned: Boolean;
    function GetL: specialize IDenseMatrix<T>;
    function GetU: specialize IDenseMatrix<T>;
    function GetPermutation: TSizeIntArray;
    function Solve(const B: specialize IDenseMatrix<T>):
      specialize IDenseMatrix<T>;
    function SolveWithInfo(const B: specialize IDenseMatrix<T>;
      out Diagnostics: TDenseSolveDiagnostics): specialize IDenseMatrix<T>;
  end;

  generic TDenseCholeskyImpl<T> = class(TInterfacedObject,
    specialize IDenseCholeskyFactorization<T>)
  private
    FPolicy: specialize IScalarPolicy<T>;
    FFactory: specialize IMatrixFactory<T>;
    FSource, FFactor: specialize IDenseMatrix<T>;
    FSize: SizeInt;
    FConditionIndicator, FDefinitenessTolerance: Double;
    procedure Factor(const A: specialize IDenseMatrix<T>);
  public
    constructor Create(const A: specialize IDenseMatrix<T>;
      const Policy: specialize IScalarPolicy<T>;
      const FactoryValue: specialize IMatrixFactory<T>);
    function GetSize: SizeInt;
    function GetConditionIndicator: Double;
    function GetL: specialize IDenseMatrix<T>;
    function Solve(const B: specialize IDenseMatrix<T>):
      specialize IDenseMatrix<T>;
    function SolveWithInfo(const B: specialize IDenseMatrix<T>;
      out Diagnostics: TDenseSolveDiagnostics): specialize IDenseMatrix<T>;
  end;

function TSinglePolicy.Zero: Single;
begin Result := 0.0; end;
function TSinglePolicy.One: Single;
begin Result := 1.0; end;
function TSinglePolicy.FromReal(const Value: Double): Single;
begin Result := Value; end;
function TSinglePolicy.Magnitude(const Value: Single): Double;
begin Result := Abs(Value); end;
function TSinglePolicy.IsFinite(const Value: Single): Boolean;
begin Result := not IsNan(Value) and not IsInfinite(Value); end;
function TSinglePolicy.Conjugate(const Value: Single): Single;
begin Result := Value; end;
function TSinglePolicy.RealPart(const Value: Single): Double;
begin Result := Value; end;
function TSinglePolicy.ImaginaryMagnitude(const Value: Single): Double;
begin Result := 0.0; end;
function TSinglePolicy.Epsilon: Double;
begin Result := 1.1920928955078125E-7; end;

function TDoublePolicy.Zero: Double;
begin Result := 0.0; end;
function TDoublePolicy.One: Double;
begin Result := 1.0; end;
function TDoublePolicy.FromReal(const Value: Double): Double;
begin Result := Value; end;
function TDoublePolicy.Magnitude(const Value: Double): Double;
begin Result := Abs(Value); end;
function TDoublePolicy.IsFinite(const Value: Double): Boolean;
begin Result := not IsNan(Value) and not IsInfinite(Value); end;
function TDoublePolicy.Conjugate(const Value: Double): Double;
begin Result := Value; end;
function TDoublePolicy.RealPart(const Value: Double): Double;
begin Result := Value; end;
function TDoublePolicy.ImaginaryMagnitude(const Value: Double): Double;
begin Result := 0.0; end;
function TDoublePolicy.Epsilon: Double;
begin Result := 2.2204460492503131E-16; end;

function TSingleComplexPolicy.Zero: TSingleComplex;
begin Result := TSingleComplex.Zero; end;
function TSingleComplexPolicy.One: TSingleComplex;
begin Result := TSingleComplex.One; end;
function TSingleComplexPolicy.FromReal(const Value: Double): TSingleComplex;
begin Result := TSingleComplex.Create(Value, 0.0); end;
function TSingleComplexPolicy.Magnitude(const Value: TSingleComplex): Double;
begin Result := Value.Magnitude; end;
function TSingleComplexPolicy.IsFinite(
  const Value: TSingleComplex): Boolean;
begin Result := Value.IsFinite; end;
function TSingleComplexPolicy.Conjugate(
  const Value: TSingleComplex): TSingleComplex;
begin Result := Value.Conjugate; end;
function TSingleComplexPolicy.RealPart(const Value: TSingleComplex): Double;
begin Result := Value.Re; end;
function TSingleComplexPolicy.ImaginaryMagnitude(
  const Value: TSingleComplex): Double;
begin Result := Abs(Value.Im); end;
function TSingleComplexPolicy.Epsilon: Double;
begin Result := 1.1920928955078125E-7; end;

function TComplexPolicy.Zero: TComplex;
begin Result := TComplex.Zero; end;
function TComplexPolicy.One: TComplex;
begin Result := TComplex.One; end;
function TComplexPolicy.FromReal(const Value: Double): TComplex;
begin Result := TComplex.Create(Value, 0.0); end;
function TComplexPolicy.Magnitude(const Value: TComplex): Double;
begin Result := Value.Magnitude; end;
function TComplexPolicy.IsFinite(const Value: TComplex): Boolean;
begin Result := Value.IsFinite; end;
function TComplexPolicy.Conjugate(const Value: TComplex): TComplex;
begin Result := Value.Conjugate; end;
function TComplexPolicy.RealPart(const Value: TComplex): Double;
begin Result := Value.Re; end;
function TComplexPolicy.ImaginaryMagnitude(const Value: TComplex): Double;
begin Result := Abs(Value.Im); end;
function TComplexPolicy.Epsilon: Double;
begin Result := 2.2204460492503131E-16; end;

function TSingleMatrixFactory.Zeros(const Rows, Cols: SizeInt):
  IDenseSingleMatrix;
begin Result := TDenseSingleMatrix.Zeros(Rows, Cols); end;
function TDoubleMatrixFactory.Zeros(const Rows, Cols: SizeInt):
  IDenseDoubleMatrix;
begin Result := TDenseDoubleMatrix.Zeros(Rows, Cols); end;
function TSingleComplexMatrixFactory.Zeros(const Rows, Cols: SizeInt):
  IDenseSingleComplexMatrix;
begin Result := TDenseSingleComplexMatrix.Zeros(Rows, Cols); end;
function TComplexMatrixFactory.Zeros(const Rows, Cols: SizeInt):
  IDenseComplexMatrix;
begin Result := TDenseComplexMatrix.Zeros(Rows, Cols); end;

procedure UpdateSolverNorm(const Value: Double;
  var Scale, SumSquares: Double);
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

function FinishSolverNorm(const Scale, SumSquares: Double): Double;
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

function SafeSolverNormProductSum(const A, B, C: Double): Double;
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

generic function SolverMatrixNorm<T>(const A: specialize IDenseMatrix<T>;
  const Policy: specialize IScalarPolicy<T>): Double;
var
  I, J: SizeInt;
  Scale, SumSquares: Double;
begin
  Scale := 0.0;
  SumSquares := 1.0;
  for I := 0 to A.Rows - 1 do
    for J := 0 to A.Cols - 1 do
      UpdateSolverNorm(Policy.Magnitude(A[I, J]), Scale, SumSquares);
  Result := FinishSolverNorm(Scale, SumSquares);
end;

generic procedure FillSolverDiagnostics<T>(const MethodName: string;
  const A, X, B: specialize IDenseMatrix<T>; const Rank: SizeInt;
  const Tolerance, ConditionIndicator: Double;
  const Policy: specialize IScalarPolicy<T>;
  out Diagnostics: TDenseSolveDiagnostics);
var
  I, J, K: SizeInt;
  Sum: T;
  Scale, SumSquares, Denominator: Double;
begin
  Diagnostics.Method := MethodName;
  Diagnostics.NumericalRank := Rank;
  Diagnostics.IsRankDeficient := Rank < A.Cols;
  Diagnostics.Tolerance := Tolerance;
  Diagnostics.ConditionIndicator := ConditionIndicator;
  Scale := 0.0;
  SumSquares := 1.0;
  for I := 0 to A.Rows - 1 do
    for J := 0 to B.Cols - 1 do
    begin
      Sum := Policy.Zero;
      for K := 0 to A.Cols - 1 do
        Sum := Sum + A[I, K] * X[K, J];
      UpdateSolverNorm(Policy.Magnitude(B[I, J] - Sum),
        Scale, SumSquares);
    end;
  Diagnostics.ResidualNorm := FinishSolverNorm(Scale, SumSquares);
  Denominator := SafeSolverNormProductSum(
    specialize SolverMatrixNorm<T>(A, Policy),
    specialize SolverMatrixNorm<T>(X, Policy),
    specialize SolverMatrixNorm<T>(B, Policy));
  if Diagnostics.ResidualNorm = 0.0 then
    Diagnostics.BackwardError := 0.0
  else if IsInfinite(Denominator) then
    Diagnostics.BackwardError := 0.0
  else if Denominator = 0.0 then
    Diagnostics.BackwardError := Infinity
  else
    Diagnostics.BackwardError := Diagnostics.ResidualNorm / Denominator;
end;

constructor TDenseLUImpl.Create(const A: specialize IDenseMatrix<T>;
  const Policy: specialize IScalarPolicy<T>;
  const FactoryValue: specialize IMatrixFactory<T>);
begin
  inherited Create;
  FPolicy := Policy;
  FFactory := FactoryValue;
  Factor(A);
end;

procedure TDenseLUImpl.Factor(const A: specialize IDenseMatrix<T>);
var
  I, J, K, PivotRow, TempIndex: SizeInt;
  Scale, PivotMagnitude, CandidateMagnitude, MinPivot: Double;
  Temp, Multiplier: T;
begin
  if A = nil then
    raise EDenseMatrixError.Create('FactorLU: coefficient matrix must not be nil.');
  if A.Rows <> A.Cols then
    raise EDenseMatrixError.CreateFmt(
      'FactorLU: coefficient matrix must be square; got %d x %d.',
      [A.Rows, A.Cols]);
  FSize := A.Rows;
  FSource := A.Clone;
  FCombined := A.Clone;
  SetLength(FPivots, FSize);
  SetLength(FPermutation, FSize);
  Scale := 0.0;
  for I := 0 to FSize - 1 do
  begin
    FPermutation[I] := I;
    for J := 0 to FSize - 1 do
    begin
      if not FPolicy.IsFinite(FCombined[I, J]) then
        raise EDenseMatrixError.CreateFmt(
          'FactorLU: coefficient element [%d,%d] must be finite.', [I, J]);
      Scale := Max(Scale, FPolicy.Magnitude(FCombined[I, J]));
    end;
  end;
  if (FSize > 0) and (Scale = 0.0) then
    raise EDenseMatrixError.Create('FactorLU: coefficient matrix is singular (all zeros).');
  MinPivot := Scale;
  FPivotTolerance := FPolicy.Epsilon * Max(1, FSize) * Scale;
  for K := 0 to FSize - 1 do
  begin
    PivotRow := K;
    PivotMagnitude := FPolicy.Magnitude(FCombined[K, K]);
    for I := K + 1 to FSize - 1 do
    begin
      CandidateMagnitude := FPolicy.Magnitude(FCombined[I, K]);
      if CandidateMagnitude > PivotMagnitude then
      begin
        PivotMagnitude := CandidateMagnitude;
        PivotRow := I;
      end;
    end;
    if PivotMagnitude <= FPivotTolerance then
      raise EDenseMatrixError.CreateFmt(
        'FactorLU: singular or numerically singular pivot at column %d (|pivot|=%g, scale=%g).',
        [K, PivotMagnitude, Scale]);
    FPivots[K] := PivotRow;
    if PivotMagnitude < MinPivot then
      MinPivot := PivotMagnitude;
    if PivotRow <> K then
    begin
      for J := 0 to FSize - 1 do
      begin
        Temp := FCombined[K, J];
        FCombined[K, J] := FCombined[PivotRow, J];
        FCombined[PivotRow, J] := Temp;
      end;
      TempIndex := FPermutation[K];
      FPermutation[K] := FPermutation[PivotRow];
      FPermutation[PivotRow] := TempIndex;
    end;
    for I := K + 1 to FSize - 1 do
    begin
      Multiplier := FCombined[I, K] / FCombined[K, K];
      FCombined[I, K] := Multiplier;
      for J := K + 1 to FSize - 1 do
        FCombined[I, J] := FCombined[I, J] -
          Multiplier * FCombined[K, J];
    end;
  end;
  if FSize = 0 then
    FPivotRatio := 1.0
  else
    FPivotRatio := MinPivot / Scale;
  FIsIllConditioned := FPivotRatio < Sqrt(FPolicy.Epsilon);
end;

function TDenseLUImpl.GetSize: SizeInt;
begin Result := FSize; end;
function TDenseLUImpl.GetPivotRatio: Double;
begin Result := FPivotRatio; end;
function TDenseLUImpl.GetConditionIndicator: Double;
begin Result := FPivotRatio; end;
function TDenseLUImpl.GetIsIllConditioned: Boolean;
begin Result := FIsIllConditioned; end;

function TDenseLUImpl.GetL: specialize IDenseMatrix<T>;
var
  I, J: SizeInt;
begin
  Result := FFactory.Zeros(FSize, FSize);
  for I := 0 to FSize - 1 do
    for J := 0 to FSize - 1 do
      if I = J then
        Result[I, J] := FPolicy.One
      else if I > J then
        Result[I, J] := FCombined[I, J];
end;

function TDenseLUImpl.GetU: specialize IDenseMatrix<T>;
var
  I, J: SizeInt;
begin
  Result := FFactory.Zeros(FSize, FSize);
  for I := 0 to FSize - 1 do
    for J := I to FSize - 1 do
      Result[I, J] := FCombined[I, J];
end;

function TDenseLUImpl.GetPermutation: TSizeIntArray;
var
  I: SizeInt;
begin
  Result := nil;
  SetLength(Result, Length(FPermutation));
  for I := 0 to High(FPermutation) do
    Result[I] := FPermutation[I];
end;

function TDenseLUImpl.Solve(const B: specialize IDenseMatrix<T>):
  specialize IDenseMatrix<T>;
var
  I, J, K, PivotRow: SizeInt;
  Temp, Sum: T;
begin
  if B = nil then
    raise EDenseMatrixError.Create('LU Solve: right-hand side must not be nil.');
  if B.Rows <> FSize then
    raise EDenseMatrixError.CreateFmt(
      'LU Solve: right-hand side must have %d rows; got %d x %d.',
      [FSize, B.Rows, B.Cols]);
  for I := 0 to B.Rows - 1 do
    for J := 0 to B.Cols - 1 do
      if not FPolicy.IsFinite(B[I, J]) then
        raise EDenseMatrixError.CreateFmt(
          'LU Solve: right-hand-side element [%d,%d] must be finite.', [I, J]);
  Result := B.Clone;
  for K := 0 to FSize - 1 do
  begin
    PivotRow := FPivots[K];
    if PivotRow <> K then
      for J := 0 to B.Cols - 1 do
      begin
        Temp := Result[K, J];
        Result[K, J] := Result[PivotRow, J];
        Result[PivotRow, J] := Temp;
      end;
  end;
  for I := 1 to FSize - 1 do
    for J := 0 to B.Cols - 1 do
    begin
      Sum := Result[I, J];
      for K := 0 to I - 1 do
        Sum := Sum - FCombined[I, K] * Result[K, J];
      Result[I, J] := Sum;
    end;
  for I := FSize - 1 downto 0 do
    for J := 0 to B.Cols - 1 do
    begin
      Sum := Result[I, J];
      for K := I + 1 to FSize - 1 do
        Sum := Sum - FCombined[I, K] * Result[K, J];
      Result[I, J] := Sum / FCombined[I, I];
    end;
end;

function TDenseLUImpl.SolveWithInfo(
  const B: specialize IDenseMatrix<T>;
  out Diagnostics: TDenseSolveDiagnostics): specialize IDenseMatrix<T>;
begin
  Result := Solve(B);
  specialize FillSolverDiagnostics<T>('pivoted LU', FSource, Result, B,
    FSize, FPivotTolerance, FPivotRatio, FPolicy, Diagnostics);
end;

constructor TDenseCholeskyImpl.Create(const A: specialize IDenseMatrix<T>;
  const Policy: specialize IScalarPolicy<T>;
  const FactoryValue: specialize IMatrixFactory<T>);
begin
  inherited Create;
  FPolicy := Policy;
  FFactory := FactoryValue;
  Factor(A);
end;

procedure TDenseCholeskyImpl.Factor(const A: specialize IDenseMatrix<T>);
var
  I, J, K: SizeInt;
  Scale, Tolerance, Diagonal: Double;
  Sum, Difference: T;
begin
  if A = nil then
    raise EDenseMatrixError.Create(
      'FactorCholesky: coefficient matrix must not be nil.');
  if A.Rows <> A.Cols then
    raise EDenseMatrixError.CreateFmt(
      'FactorCholesky: coefficient matrix must be square; got %d x %d.',
      [A.Rows, A.Cols]);
  FSize := A.Rows;
  FSource := A.Clone;
  Scale := 0.0;
  for I := 0 to FSize - 1 do
    for J := 0 to FSize - 1 do
    begin
      if not FPolicy.IsFinite(A[I, J]) then
        raise EDenseMatrixError.CreateFmt(
          'FactorCholesky: coefficient element [%d,%d] must be finite.', [I, J]);
      Scale := Max(Scale, FPolicy.Magnitude(A[I, J]));
    end;
  if (FSize > 0) and (Scale = 0.0) then
    raise EDenseMatrixError.Create(
      'FactorCholesky: coefficient matrix is not positive definite (all zeros).');
  Tolerance := FPolicy.Epsilon * Max(1, FSize) * Scale;
  FDefinitenessTolerance := Tolerance;
  for I := 0 to FSize - 1 do
    for J := 0 to I - 1 do
    begin
      Difference := A[I, J] - FPolicy.Conjugate(A[J, I]);
      if FPolicy.Magnitude(Difference) > Tolerance then
        raise EDenseMatrixError.CreateFmt(
          'FactorCholesky: coefficient matrix must be Hermitian; mismatch at [%d,%d].',
          [I, J]);
    end;
  FFactor := FFactory.Zeros(FSize, FSize);
  for I := 0 to FSize - 1 do
    for J := 0 to I do
    begin
      Sum := A[I, J];
      for K := 0 to J - 1 do
        Sum := Sum - FFactor[I, K] * FPolicy.Conjugate(FFactor[J, K]);
      if I = J then
      begin
        Diagonal := FPolicy.RealPart(Sum);
        if (FPolicy.ImaginaryMagnitude(Sum) > Tolerance) or
           (Diagonal <= Tolerance) then
          raise EDenseMatrixError.CreateFmt(
            'FactorCholesky: matrix is not positive definite at diagonal %d.',
            [I]);
        FFactor[I, J] := FPolicy.FromReal(Sqrt(Diagonal));
      end
      else
        FFactor[I, J] := Sum / FFactor[J, J];
    end;
  Scale := 0.0;
  Diagonal := Infinity;
  for I := 0 to FSize - 1 do
  begin
    Scale := Max(Scale, FPolicy.Magnitude(FFactor[I, I]));
    Diagonal := Min(Diagonal, FPolicy.Magnitude(FFactor[I, I]));
  end;
  if FSize = 0 then
    FConditionIndicator := 1.0
  else if Scale = 0.0 then
    FConditionIndicator := 0.0
  else
    FConditionIndicator := Diagonal / Scale;
end;

function TDenseCholeskyImpl.GetSize: SizeInt;
begin Result := FSize; end;

function TDenseCholeskyImpl.GetConditionIndicator: Double;
begin Result := FConditionIndicator; end;

function TDenseCholeskyImpl.GetL: specialize IDenseMatrix<T>;
begin Result := FFactor.Clone; end;

function TDenseCholeskyImpl.Solve(const B: specialize IDenseMatrix<T>):
  specialize IDenseMatrix<T>;
var
  I, J, K: SizeInt;
  Sum: T;
begin
  if B = nil then
    raise EDenseMatrixError.Create(
      'Cholesky Solve: right-hand side must not be nil.');
  if B.Rows <> FSize then
    raise EDenseMatrixError.CreateFmt(
      'Cholesky Solve: right-hand side must have %d rows; got %d x %d.',
      [FSize, B.Rows, B.Cols]);
  for I := 0 to B.Rows - 1 do
    for J := 0 to B.Cols - 1 do
      if not FPolicy.IsFinite(B[I, J]) then
        raise EDenseMatrixError.CreateFmt(
          'Cholesky Solve: right-hand-side element [%d,%d] must be finite.',
          [I, J]);
  Result := B.Clone;
  for I := 0 to FSize - 1 do
    for J := 0 to B.Cols - 1 do
    begin
      Sum := Result[I, J];
      for K := 0 to I - 1 do
        Sum := Sum - FFactor[I, K] * Result[K, J];
      Result[I, J] := Sum / FFactor[I, I];
    end;
  for I := FSize - 1 downto 0 do
    for J := 0 to B.Cols - 1 do
    begin
      Sum := Result[I, J];
      for K := I + 1 to FSize - 1 do
        Sum := Sum - FPolicy.Conjugate(FFactor[K, I]) * Result[K, J];
      Result[I, J] := Sum / FPolicy.Conjugate(FFactor[I, I]);
    end;
end;

function TDenseCholeskyImpl.SolveWithInfo(
  const B: specialize IDenseMatrix<T>;
  out Diagnostics: TDenseSolveDiagnostics): specialize IDenseMatrix<T>;
begin
  Result := Solve(B);
  specialize FillSolverDiagnostics<T>('Cholesky', FSource, Result, B,
    FSize, FDefinitenessTolerance, FConditionIndicator, FPolicy,
    Diagnostics);
end;

function FactorLU(const A: IDenseSingleMatrix): IDenseSingleLU;
begin
  Result := specialize TDenseLUImpl<Single>.Create(A, TSinglePolicy.Create,
    TSingleMatrixFactory.Create);
end;

function FactorLU(const A: IDenseDoubleMatrix): IDenseDoubleLU;
begin
  Result := specialize TDenseLUImpl<Double>.Create(A, TDoublePolicy.Create,
    TDoubleMatrixFactory.Create);
end;

function FactorLU(const A: IDenseSingleComplexMatrix):
  IDenseSingleComplexLU;
begin
  Result := specialize TDenseLUImpl<TSingleComplex>.Create(A,
    TSingleComplexPolicy.Create, TSingleComplexMatrixFactory.Create);
end;

function FactorLU(const A: IDenseComplexMatrix): IDenseComplexLU;
begin
  Result := specialize TDenseLUImpl<TComplex>.Create(A, TComplexPolicy.Create,
    TComplexMatrixFactory.Create);
end;

function FactorCholesky(const A: IDenseSingleMatrix):
  IDenseSingleCholesky;
begin
  Result := specialize TDenseCholeskyImpl<Single>.Create(A,
    TSinglePolicy.Create, TSingleMatrixFactory.Create);
end;

function FactorCholesky(const A: IDenseDoubleMatrix):
  IDenseDoubleCholesky;
begin
  Result := specialize TDenseCholeskyImpl<Double>.Create(A,
    TDoublePolicy.Create, TDoubleMatrixFactory.Create);
end;

function FactorCholesky(const A: IDenseSingleComplexMatrix):
  IDenseSingleComplexCholesky;
begin
  Result := specialize TDenseCholeskyImpl<TSingleComplex>.Create(A,
    TSingleComplexPolicy.Create, TSingleComplexMatrixFactory.Create);
end;

function FactorCholesky(const A: IDenseComplexMatrix):
  IDenseComplexCholesky;
begin
  Result := specialize TDenseCholeskyImpl<TComplex>.Create(A,
    TComplexPolicy.Create, TComplexMatrixFactory.Create);
end;

function Solve(const A, B: IDenseSingleMatrix): IDenseSingleMatrix;
var
  Factor: IDenseSingleLU;
begin
  Factor := FactorLU(A);
  if Factor.IsIllConditioned then
    raise EDenseMatrixError.CreateFmt(
      'Solve(single): coefficient matrix is ill-conditioned (pivot ratio %g); use FactorLU to inspect and solve explicitly.',
      [Factor.PivotRatio]);
  Result := Factor.Solve(B);
end;
function Solve(const A, B: IDenseDoubleMatrix): IDenseDoubleMatrix;
var
  Factor: IDenseDoubleLU;
begin
  Factor := FactorLU(A);
  if Factor.IsIllConditioned then
    raise EDenseMatrixError.CreateFmt(
      'Solve(double): coefficient matrix is ill-conditioned (pivot ratio %g); use FactorLU to inspect and solve explicitly.',
      [Factor.PivotRatio]);
  Result := Factor.Solve(B);
end;
function Solve(const A, B: IDenseSingleComplexMatrix):
  IDenseSingleComplexMatrix;
var
  Factor: IDenseSingleComplexLU;
begin
  Factor := FactorLU(A);
  if Factor.IsIllConditioned then
    raise EDenseMatrixError.CreateFmt(
      'Solve(single complex): coefficient matrix is ill-conditioned (pivot ratio %g); use FactorLU to inspect and solve explicitly.',
      [Factor.PivotRatio]);
  Result := Factor.Solve(B);
end;
function Solve(const A, B: IDenseComplexMatrix): IDenseComplexMatrix;
var
  Factor: IDenseComplexLU;
begin
  Factor := FactorLU(A);
  if Factor.IsIllConditioned then
    raise EDenseMatrixError.CreateFmt(
      'Solve(complex): coefficient matrix is ill-conditioned (pivot ratio %g); use FactorLU to inspect and solve explicitly.',
      [Factor.PivotRatio]);
  Result := Factor.Solve(B);
end;

function SolveWithInfo(const A, B: IDenseSingleMatrix;
  out Diagnostics: TDenseSolveDiagnostics): IDenseSingleMatrix;
begin
  Result := FactorLU(A).SolveWithInfo(B, Diagnostics);
end;

function SolveWithInfo(const A, B: IDenseDoubleMatrix;
  out Diagnostics: TDenseSolveDiagnostics): IDenseDoubleMatrix;
begin
  Result := FactorLU(A).SolveWithInfo(B, Diagnostics);
end;

function SolveWithInfo(const A, B: IDenseSingleComplexMatrix;
  out Diagnostics: TDenseSolveDiagnostics): IDenseSingleComplexMatrix;
begin
  Result := FactorLU(A).SolveWithInfo(B, Diagnostics);
end;

function SolveWithInfo(const A, B: IDenseComplexMatrix;
  out Diagnostics: TDenseSolveDiagnostics): IDenseComplexMatrix;
begin
  Result := FactorLU(A).SolveWithInfo(B, Diagnostics);
end;

function SolvePositiveDefinite(const A, B: IDenseSingleMatrix;
  out Diagnostics: TDenseSolveDiagnostics): IDenseSingleMatrix;
begin
  Result := FactorCholesky(A).SolveWithInfo(B, Diagnostics);
end;

function SolvePositiveDefinite(const A, B: IDenseDoubleMatrix;
  out Diagnostics: TDenseSolveDiagnostics): IDenseDoubleMatrix;
begin
  Result := FactorCholesky(A).SolveWithInfo(B, Diagnostics);
end;

function SolvePositiveDefinite(const A, B: IDenseSingleComplexMatrix;
  out Diagnostics: TDenseSolveDiagnostics): IDenseSingleComplexMatrix;
begin
  Result := FactorCholesky(A).SolveWithInfo(B, Diagnostics);
end;

function SolvePositiveDefinite(const A, B: IDenseComplexMatrix;
  out Diagnostics: TDenseSolveDiagnostics): IDenseComplexMatrix;
begin
  Result := FactorCholesky(A).SolveWithInfo(B, Diagnostics);
end;

end.
