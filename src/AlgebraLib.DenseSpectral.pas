unit AlgebraLib.DenseSpectral;

{-----------------------------------------------------------------------------
 AlgebraLib.DenseSpectral

 Dense nonsymmetric spectral reductions for mathlib-fp.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  MathBase.SharedTypes, MathBase.Complex, AlgebraLib.DenseMatrices;

type
  TRealEigenvalueOrdering = (reoSchurOrder, reoRealPart, reoMagnitude);

  IDenseDoubleHessenberg = interface
    function GetSize: SizeInt;
    function GetQ: IDenseDoubleMatrix;
    function GetH: IDenseDoubleMatrix;
    property Size: SizeInt read GetSize;
    { Q is orthogonal and Q^T * A * Q = H. }
    property Q: IDenseDoubleMatrix read GetQ;
    { H is upper Hessenberg. }
    property H: IDenseDoubleMatrix read GetH;
  end;

  IDenseComplexHessenberg = interface
    function GetSize: SizeInt;
    function GetQ: IDenseComplexMatrix;
    function GetH: IDenseComplexMatrix;
    property Size: SizeInt read GetSize;
    { Q is unitary and Q^H * A * Q = H. }
    property Q: IDenseComplexMatrix read GetQ;
    { H is upper Hessenberg. }
    property H: IDenseComplexMatrix read GetH;
  end;

  IDenseDoubleRealSchur = interface
    function GetSize: SizeInt;
    function GetQ: IDenseDoubleMatrix;
    function GetT: IDenseDoubleMatrix;
    function GetIterations: SizeInt;
    property Size: SizeInt read GetSize;
    { A = Q*T*Q^T; Q is orthogonal and T is in real Schur form. }
    property Q: IDenseDoubleMatrix read GetQ;
    { Defensive copy of the upper quasi-triangular Schur form. }
    property T: IDenseDoubleMatrix read GetT;
    { Number of implicit Francis double-shift steps. }
    property Iterations: SizeInt read GetIterations;
  end;

  IDenseComplexSchur = interface
    function GetSize: SizeInt;
    function GetQ: IDenseComplexMatrix;
    function GetT: IDenseComplexMatrix;
    function GetIterations: SizeInt;
    property Size: SizeInt read GetSize;
    { A = Q*T*Q^H; Q is unitary and T is upper triangular. }
    property Q: IDenseComplexMatrix read GetQ;
    { Defensive copy of the upper triangular complex Schur form. }
    property T: IDenseComplexMatrix read GetT;
    { Number of shifted QR iterations. }
    property Iterations: SizeInt read GetIterations;
  end;

  IDenseDoubleRealEigen = interface
    function GetSize: SizeInt;
    function GetEigenvalues: TComplexArray;
    function GetRightEigenvectors: IDenseComplexMatrix;
    function GetResiduals: TDoubleArray;
    function GetIterations: SizeInt;
    function GetConverged: Boolean;
    property Size: SizeInt read GetSize;
    property Eigenvalues: TComplexArray read GetEigenvalues;
    { Normalized right eigenvectors are returned as columns. }
    property RightEigenvectors: IDenseComplexMatrix read GetRightEigenvectors;
    { Normalized backward residual corresponding to each eigenpair. }
    property Residuals: TDoubleArray read GetResiduals;
    property Iterations: SizeInt read GetIterations;
    property Converged: Boolean read GetConverged;
  end;

  IDenseDoubleGeneralizedSchur = interface
    function GetSize: SizeInt;
    function GetQ: IDenseDoubleMatrix;
    function GetS: IDenseDoubleMatrix;
    function GetZ: IDenseDoubleMatrix;
    function GetT: IDenseDoubleMatrix;
    function GetAlpha: TComplexArray;
    function GetBeta: TComplexArray;
    function GetIterations: SizeInt;
    property Size: SizeInt read GetSize;
    property Q: IDenseDoubleMatrix read GetQ;
    property S: IDenseDoubleMatrix read GetS;
    property Z: IDenseDoubleMatrix read GetZ;
    property T: IDenseDoubleMatrix read GetT;
    { Homogeneous generalized eigenvalue numerators, paired by index. }
    property Alpha: TComplexArray read GetAlpha;
    { Denominators; zero denotes an eigenvalue at infinity. }
    property Beta: TComplexArray read GetBeta;
    property Iterations: SizeInt read GetIterations;
  end;

  IDenseDoubleGeneralizedEigen = interface
    function GetSize: SizeInt;
    function GetAlpha: TComplexArray;
    function GetBeta: TComplexArray;
    function GetRightEigenvectors: IDenseComplexMatrix;
    function GetResiduals: TDoubleArray;
    function GetIterations: SizeInt;
    function GetConverged: Boolean;
    property Size: SizeInt read GetSize;
    property Alpha: TComplexArray read GetAlpha;
    property Beta: TComplexArray read GetBeta;
    property RightEigenvectors: IDenseComplexMatrix read GetRightEigenvectors;
    property Residuals: TDoubleArray read GetResiduals;
    property Iterations: SizeInt read GetIterations;
    property Converged: Boolean read GetConverged;
  end;

  IDenseComplexGeneralizedSchur = interface
    function GetSize: SizeInt;
    function GetQ: IDenseComplexMatrix;
    function GetS: IDenseComplexMatrix;
    function GetZ: IDenseComplexMatrix;
    function GetT: IDenseComplexMatrix;
    function GetAlpha: TComplexArray;
    function GetBeta: TComplexArray;
    function GetIterations: SizeInt;
    property Size: SizeInt read GetSize;
    property Q: IDenseComplexMatrix read GetQ;
    property S: IDenseComplexMatrix read GetS;
    property Z: IDenseComplexMatrix read GetZ;
    property T: IDenseComplexMatrix read GetT;
    property Alpha: TComplexArray read GetAlpha;
    property Beta: TComplexArray read GetBeta;
    property Iterations: SizeInt read GetIterations;
  end;

  IDenseComplexGeneralizedEigen = interface
    function GetSize: SizeInt;
    function GetAlpha: TComplexArray;
    function GetBeta: TComplexArray;
    function GetRightEigenvectors: IDenseComplexMatrix;
    function GetResiduals: TDoubleArray;
    function GetIterations: SizeInt;
    function GetConverged: Boolean;
    property Size: SizeInt read GetSize;
    property Alpha: TComplexArray read GetAlpha;
    property Beta: TComplexArray read GetBeta;
    property RightEigenvectors: IDenseComplexMatrix read GetRightEigenvectors;
    property Residuals: TDoubleArray read GetResiduals;
    property Iterations: SizeInt read GetIterations;
    property Converged: Boolean read GetConverged;
  end;

function ReduceHessenberg(const A: IDenseDoubleMatrix):
  IDenseDoubleHessenberg; overload;
function ReduceHessenberg(const A: IDenseComplexMatrix):
  IDenseComplexHessenberg; overload;
function FactorRealSchur(const A: IDenseDoubleMatrix;
  const MaxIterations: SizeInt = 0): IDenseDoubleRealSchur;
function FactorComplexSchur(const A: IDenseComplexMatrix;
  const MaxIterations: SizeInt = 0): IDenseComplexSchur;
function FactorRealEigen(const A: IDenseDoubleMatrix;
  const Ordering: TRealEigenvalueOrdering = reoSchurOrder;
  const MaxIterations: SizeInt = 0): IDenseDoubleRealEigen;
function FactorRealGeneralizedSchur(const A, B: IDenseDoubleMatrix;
  const MaxIterations: SizeInt = 0): IDenseDoubleGeneralizedSchur;
function FactorRealGeneralizedEigen(const A, B: IDenseDoubleMatrix;
  const MaxIterations: SizeInt = 0): IDenseDoubleGeneralizedEigen;
{ Complex-input generalized Schur reduction and right-eigenpair solve. }
function FactorComplexGeneralizedSchur(const A, B: IDenseComplexMatrix;
  const MaxIterations: SizeInt = 0): IDenseComplexGeneralizedSchur;
function FactorComplexGeneralizedEigen(const A, B: IDenseComplexMatrix;
  const MaxIterations: SizeInt = 0): IDenseComplexGeneralizedEigen;

implementation

uses
  Math, SysUtils, AlgebraLib.DenseDecompositions,
  AlgebraLib.DenseSolvers, AlgebraLib.DenseKernels;

type
  TDenseDoubleHessenberg = class(TInterfacedObject,
    IDenseDoubleHessenberg)
  private
    FSize: SizeInt;
    FQ, FH: IDenseDoubleMatrix;
    procedure Factor(const A: IDenseDoubleMatrix);
  public
    constructor Create(const A: IDenseDoubleMatrix);
    function GetSize: SizeInt;
    function GetQ: IDenseDoubleMatrix;
    function GetH: IDenseDoubleMatrix;
  end;

  TDenseComplexHessenberg = class(TInterfacedObject,
    IDenseComplexHessenberg)
  private
    FSize: SizeInt;
    FQ, FH: IDenseComplexMatrix;
    procedure Factor(const A: IDenseComplexMatrix);
  public
    constructor Create(const A: IDenseComplexMatrix);
    function GetSize: SizeInt;
    function GetQ: IDenseComplexMatrix;
    function GetH: IDenseComplexMatrix;
  end;

  TDenseDoubleRealSchur = class(TInterfacedObject, IDenseDoubleRealSchur)
  private
    FSize, FIterations: SizeInt;
    FQ, FT: IDenseDoubleMatrix;
    procedure Factor(const A: IDenseDoubleMatrix;
      const MaxIterations: SizeInt);
  public
    constructor Create(const A: IDenseDoubleMatrix;
      const MaxIterations: SizeInt);
    function GetSize: SizeInt;
    function GetQ: IDenseDoubleMatrix;
    function GetT: IDenseDoubleMatrix;
    function GetIterations: SizeInt;
  end;

  TDenseDoubleRealEigen = class(TInterfacedObject, IDenseDoubleRealEigen)
  private
    FSize, FIterations: SizeInt;
    FValues: TComplexArray;
    FVectors: IDenseComplexMatrix;
    FResiduals: TDoubleArray;
    procedure Factor(const A: IDenseDoubleMatrix;
      const Ordering: TRealEigenvalueOrdering;
      const MaxIterations: SizeInt);
  public
    constructor Create(const A: IDenseDoubleMatrix;
      const Ordering: TRealEigenvalueOrdering; const MaxIterations: SizeInt);
    function GetSize: SizeInt;
    function GetEigenvalues: TComplexArray;
    function GetRightEigenvectors: IDenseComplexMatrix;
    function GetResiduals: TDoubleArray;
    function GetIterations: SizeInt;
    function GetConverged: Boolean;
  end;

  TDenseDoubleGeneralizedSchur = class(TInterfacedObject,
    IDenseDoubleGeneralizedSchur)
  private
    FSize, FIterations: SizeInt;
    FQ, FS, FZ, FT: IDenseDoubleMatrix;
    FAlpha, FBeta: TComplexArray;
    FTransformEigenvectors: IDenseComplexMatrix;
    procedure Factor(const A, B: IDenseDoubleMatrix;
      const MaxIterations: SizeInt);
  public
    constructor Create(const A, B: IDenseDoubleMatrix;
      const MaxIterations: SizeInt);
    function GetSize: SizeInt;
    function GetQ: IDenseDoubleMatrix;
    function GetS: IDenseDoubleMatrix;
    function GetZ: IDenseDoubleMatrix;
    function GetT: IDenseDoubleMatrix;
    function GetAlpha: TComplexArray;
    function GetBeta: TComplexArray;
    function GetIterations: SizeInt;
  end;

  TDenseDoubleGeneralizedEigen = class(TInterfacedObject,
    IDenseDoubleGeneralizedEigen)
  private
    FSchur: IDenseDoubleGeneralizedSchur;
    FVectors: IDenseComplexMatrix;
    FResiduals: TDoubleArray;
    procedure Factor(const A, B: IDenseDoubleMatrix;
      const MaxIterations: SizeInt);
  public
    constructor Create(const A, B: IDenseDoubleMatrix;
      const MaxIterations: SizeInt);
    function GetSize: SizeInt;
    function GetAlpha: TComplexArray;
    function GetBeta: TComplexArray;
    function GetRightEigenvectors: IDenseComplexMatrix;
    function GetResiduals: TDoubleArray;
    function GetIterations: SizeInt;
    function GetConverged: Boolean;
  end;

  TDenseComplexGeneralizedSchur = class(TInterfacedObject,
    IDenseComplexGeneralizedSchur)
  private
    FSize, FIterations: SizeInt;
    FQ, FS, FZ, FT, FTransformEigenvectors: IDenseComplexMatrix;
    FAlpha, FBeta: TComplexArray;
    procedure Factor(const A, B: IDenseComplexMatrix;
      const MaxIterations: SizeInt);
  public
    constructor Create(const A, B: IDenseComplexMatrix;
      const MaxIterations: SizeInt);
    function GetSize: SizeInt;
    function GetQ: IDenseComplexMatrix;
    function GetS: IDenseComplexMatrix;
    function GetZ: IDenseComplexMatrix;
    function GetT: IDenseComplexMatrix;
    function GetAlpha: TComplexArray;
    function GetBeta: TComplexArray;
    function GetIterations: SizeInt;
  end;

  TDenseComplexGeneralizedEigen = class(TInterfacedObject,
    IDenseComplexGeneralizedEigen)
  private
    FSchur: IDenseComplexGeneralizedSchur;
    FVectors: IDenseComplexMatrix;
    FResiduals: TDoubleArray;
    procedure Factor(const A, B: IDenseComplexMatrix;
      const MaxIterations: SizeInt);
  public
    constructor Create(const A, B: IDenseComplexMatrix;
      const MaxIterations: SizeInt);
    function GetSize: SizeInt;
    function GetAlpha: TComplexArray;
    function GetBeta: TComplexArray;
    function GetRightEigenvectors: IDenseComplexMatrix;
    function GetResiduals: TDoubleArray;
    function GetIterations: SizeInt;
    function GetConverged: Boolean;
  end;

  TDenseComplexSchur = class(TInterfacedObject, IDenseComplexSchur)
  private
    FSize, FIterations: SizeInt;
    FQ, FT: IDenseComplexMatrix;
    procedure Factor(const A: IDenseComplexMatrix;
      const MaxIterations: SizeInt);
  public
    constructor Create(const A: IDenseComplexMatrix;
      const MaxIterations: SizeInt);
    function GetSize: SizeInt;
    function GetQ: IDenseComplexMatrix;
    function GetT: IDenseComplexMatrix;
    function GetIterations: SizeInt;
  end;

procedure FactorComplexSchurInternal(const A: IDenseComplexMatrix;
  const MaxIterations: SizeInt; out Q, T: IDenseComplexMatrix;
  out Iterations: SizeInt);
var
  N, Active, I, J, Limit, SinceDeflation: SizeInt;
  H, U, Shifted, StepQ, ScaledA: IDenseComplexMatrix;
  Hessenberg: IDenseComplexHessenberg;
  QR: IDenseComplexQR;
  Shift: TComplex;
  LocalScale, Threshold, Epsilon, GlobalScale: Double;
begin
  if A = nil then
    raise EDenseMatrixError.Create('Complex Schur: matrix must not be nil.');
  if A.Rows <> A.Cols then
    raise EDenseMatrixError.Create('Complex Schur: matrix must be square.');
  N := A.Rows;
  if MaxIterations < 0 then
    raise EDenseMatrixError.Create('Complex Schur: iteration limit is negative.');
  Limit := MaxIterations;
  if Limit = 0 then Limit := 100 * Max(1, N);
  GlobalScale := 0.0;
  for I := 0 to N - 1 do
    for J := 0 to N - 1 do
      GlobalScale := Max(GlobalScale, A[I, J].Magnitude);
  if GlobalScale = 0.0 then
    ScaledA := A.Clone
  else
  begin
    ScaledA := TDenseComplexMatrix.Zeros(N, N);
    for I := 0 to N - 1 do
      for J := 0 to N - 1 do
        ScaledA[I, J] := A[I, J] / GlobalScale;
  end;
  Hessenberg := ReduceHessenberg(ScaledA);
  H := Hessenberg.H;
  Q := Hessenberg.Q;
  Iterations := 0;
  Active := N - 1;
  SinceDeflation := 0;
  Epsilon := 2.2204460492503131E-16;
  while Active > 0 do
  begin
    LocalScale := Max(H[Active, Active].Magnitude,
      H[Active - 1, Active - 1].Magnitude);
    Threshold := Epsilon * Max(1, N) * LocalScale;
    if H[Active, Active - 1].Magnitude <= Threshold then
    begin
      H[Active, Active - 1] := TComplex.Zero;
      Dec(Active);
      SinceDeflation := 0;
      Continue;
    end;
    if Iterations >= Limit then
      raise EDenseMatrixError.CreateFmt(
        'Complex Schur: iteration limit (%d) reached before convergence.',
        [Limit]);

    Shift := H[Active, Active];
    if (SinceDeflation > 0) and (SinceDeflation mod 16 = 0) then
      Shift := Shift + TComplex.Create(0.75, 0.25) *
        H[Active, Active - 1].Magnitude;
    Shifted := TDenseComplexMatrix.Zeros(Active + 1, Active + 1);
    for I := 0 to Active do
      for J := 0 to Active do
      begin
        Shifted[I, J] := H[I, J];
        if I = J then Shifted[I, J] := Shifted[I, J] - Shift;
      end;
    QR := FactorQR(Shifted);
    StepQ := QR.Q;
    U := TDenseComplexMatrix.Zeros(N, N);
    for I := 0 to N - 1 do U[I, I] := TComplex.One;
    for I := 0 to Active do
      for J := 0 to Active do U[I, J] := StepQ[I, J];
    H := Multiply(Multiply(ConjugateTranspose(U), H), U);
    Q := Multiply(Q, U);
    Inc(Iterations);
    Inc(SinceDeflation);
    if (H[Active, Active - 1].Magnitude <= Threshold) then
    begin
      H[Active, Active - 1] := TComplex.Zero;
      Dec(Active);
      SinceDeflation := 0;
    end;
  end;
  if GlobalScale = 0.0 then
    T := H
  else
  begin
    T := TDenseComplexMatrix.Zeros(N, N);
    for I := 0 to N - 1 do
      for J := 0 to N - 1 do T[I, J] := H[I, J] * GlobalScale;
  end;
  for I := 0 to N - 1 do
    for J := 0 to N - 1 do
      if not T[I, J].IsFinite then
        raise EDenseMatrixError.Create(
          'Complex Schur: computed factor is non-finite.');
end;

procedure ValidateFiniteComplexMatrix(const A: IDenseComplexMatrix); forward;

constructor TDenseComplexSchur.Create(const A: IDenseComplexMatrix;
  const MaxIterations: SizeInt);
begin
  inherited Create;
  Factor(A, MaxIterations);
end;

procedure TDenseComplexSchur.Factor(const A: IDenseComplexMatrix;
  const MaxIterations: SizeInt);
var
  I, J: SizeInt;
begin
  ValidateFiniteComplexMatrix(A);
  FactorComplexSchurInternal(A, MaxIterations, FQ, FT, FIterations);
  FSize := A.Rows;
  for I := 0 to FSize - 1 do
    for J := 0 to FSize - 1 do
      if not FQ[I, J].IsFinite or not FT[I, J].IsFinite then
        raise EDenseMatrixError.CreateFmt(
          'FactorComplexSchur: non-finite factor at [%d,%d].', [I, J]);
  for I := 1 to FSize - 1 do
    for J := 0 to I - 1 do
      FT[I, J] := TComplex.Zero;
end;

function TDenseComplexSchur.GetSize: SizeInt;
begin
  Result := FSize;
end;

function TDenseComplexSchur.GetQ: IDenseComplexMatrix;
begin
  Result := FQ.Clone;
end;

function TDenseComplexSchur.GetT: IDenseComplexMatrix;
begin
  Result := FT.Clone;
end;

function TDenseComplexSchur.GetIterations: SizeInt;
begin
  Result := FIterations;
end;

procedure ValidateFiniteMatrix(const A: IDenseDoubleMatrix);
var
  I, J: SizeInt;
begin
  if A = nil then
    raise EDenseMatrixError.Create(
      'ReduceHessenberg: source matrix must not be nil.');
  if A.Rows <> A.Cols then
    raise EDenseMatrixError.CreateFmt(
      'ReduceHessenberg: source must be square; got %d x %d.',
      [A.Rows, A.Cols]);
  for I := 0 to A.Rows - 1 do
    for J := 0 to A.Cols - 1 do
      if IsNan(A[I, J]) or IsInfinite(A[I, J]) then
        raise EDenseMatrixError.CreateFmt(
          'ReduceHessenberg: source element [%d,%d] must be finite.', [I, J]);
end;

function ScaledNorm(const Values: array of Double): Double;
var
  I: SizeInt;
  Scale, SumSquares, Magnitude, RootSum: Double;
begin
  Scale := 0.0;
  SumSquares := 1.0;
  for I := 0 to High(Values) do
  begin
    Magnitude := Abs(Values[I]);
    if Magnitude <> 0.0 then
      if Scale < Magnitude then
      begin
        SumSquares := 1.0 + SumSquares * Sqr(Scale / Magnitude);
        Scale := Magnitude;
      end
      else
        SumSquares := SumSquares + Sqr(Magnitude / Scale);
  end;
  if Scale = 0.0 then
    Exit(0.0);
  RootSum := Sqrt(SumSquares);
  if Scale > MaxDouble / RootSum then
    Result := Infinity
  else
    Result := Scale * RootSum;
end;

constructor TDenseDoubleHessenberg.Create(const A: IDenseDoubleMatrix);
begin
  inherited Create;
  Factor(A);
end;

procedure TDenseDoubleHessenberg.Factor(const A: IDenseDoubleMatrix);
var
  Work: IDenseDoubleMatrix;
  Reflector: array of Double;
  I, J, K, Index, ReflectorSize: SizeInt;
  Norm, Alpha, Denominator, Beta, DotProduct: Double;
  NeedsReduction: Boolean;
begin
  ValidateFiniteMatrix(A);
  FSize := A.Rows;
  Work := A.Clone;
  FQ := TDenseDoubleMatrix.Zeros(FSize, FSize);
  for I := 0 to FSize - 1 do
    FQ[I, I] := 1.0;

  for K := 0 to FSize - 3 do
  begin
    ReflectorSize := FSize - K - 1;
    SetLength(Reflector, ReflectorSize);
    for I := 0 to ReflectorSize - 1 do
      Reflector[I] := Work[K + 1 + I, K];
    NeedsReduction := False;
    for I := 1 to ReflectorSize - 1 do
      if Reflector[I] <> 0.0 then
      begin
        NeedsReduction := True;
        Break;
      end;
    if not NeedsReduction then
      Continue;
    Norm := ScaledNorm(Reflector);
    if Norm = 0.0 then
      Continue;

    if Reflector[0] >= 0.0 then
      Alpha := -Norm
    else
      Alpha := Norm;
    if IsNan(Alpha) or IsInfinite(Alpha) then
      raise EDenseMatrixError.Create(
        'ReduceHessenberg: reflector norm exceeds the finite range.');

    Denominator := 0.0;
    for I := 0 to ReflectorSize - 1 do
    begin
      Reflector[I] := Reflector[I] / Norm;
      if I = 0 then
        Reflector[I] := Reflector[I] - Alpha / Norm;
      Denominator := Denominator + Sqr(Reflector[I]);
    end;
    Beta := 2.0 / Denominator;

    { Apply the symmetric Householder reflector from the left. }
    for J := K to FSize - 1 do
    begin
      DotProduct := 0.0;
      for I := 0 to ReflectorSize - 1 do
        DotProduct := DotProduct + Reflector[I] * Work[K + 1 + I, J];
      for I := 0 to ReflectorSize - 1 do
        Work[K + 1 + I, J] := Work[K + 1 + I, J] -
          Beta * Reflector[I] * DotProduct;
    end;

    { Apply the same reflector from the right to complete the similarity. }
    for I := 0 to FSize - 1 do
    begin
      DotProduct := 0.0;
      for J := 0 to ReflectorSize - 1 do
        DotProduct := DotProduct + Work[I, K + 1 + J] * Reflector[J];
      for J := 0 to ReflectorSize - 1 do
        Work[I, K + 1 + J] := Work[I, K + 1 + J] -
          Beta * DotProduct * Reflector[J];
    end;

    { Accumulate Q on the right, so Q^T * A * Q = H. }
    for I := 0 to FSize - 1 do
    begin
      DotProduct := 0.0;
      for J := 0 to ReflectorSize - 1 do
        DotProduct := DotProduct + FQ[I, K + 1 + J] * Reflector[J];
      for J := 0 to ReflectorSize - 1 do
        FQ[I, K + 1 + J] := FQ[I, K + 1 + J] -
          Beta * DotProduct * Reflector[J];
    end;

    Work[K + 1, K] := Alpha;
    for Index := K + 2 to FSize - 1 do
      Work[Index, K] := 0.0;
  end;

  for I := 0 to FSize - 1 do
    for J := 0 to FSize - 1 do
      if IsNan(Work[I, J]) or IsInfinite(Work[I, J]) or
        IsNan(FQ[I, J]) or IsInfinite(FQ[I, J]) then
        raise EDenseMatrixError.CreateFmt(
          'ReduceHessenberg: non-finite factor at [%d,%d].', [I, J]);
  FH := Work;
end;

function TDenseDoubleHessenberg.GetSize: SizeInt;
begin
  Result := FSize;
end;

function TDenseDoubleHessenberg.GetQ: IDenseDoubleMatrix;
begin
  Result := FQ.Clone;
end;

function TDenseDoubleHessenberg.GetH: IDenseDoubleMatrix;
begin
  Result := FH.Clone;
end;

function ReduceHessenberg(const A: IDenseDoubleMatrix):
  IDenseDoubleHessenberg;
begin
  Result := TDenseDoubleHessenberg.Create(A);
end;

procedure ValidateFiniteComplexMatrix(const A: IDenseComplexMatrix);
var
  I, J: SizeInt;
begin
  if A = nil then
    raise EDenseMatrixError.Create(
      'ReduceHessenberg: source matrix must not be nil.');
  if A.Rows <> A.Cols then
    raise EDenseMatrixError.CreateFmt(
      'ReduceHessenberg: source must be square; got %d x %d.',
      [A.Rows, A.Cols]);
  for I := 0 to A.Rows - 1 do
    for J := 0 to A.Cols - 1 do
      if not A[I, J].IsFinite then
        raise EDenseMatrixError.CreateFmt(
          'ReduceHessenberg: source element [%d,%d] must be finite.', [I, J]);
end;

function ScaledComplexNorm(const Values: array of TComplex): Double;
var
  I: SizeInt;
  Scale, SumSquares, Magnitude, RootSum: Double;
  procedure Accumulate(const Value: Double);
  begin
    Magnitude := Abs(Value);
    if Magnitude <> 0.0 then
      if Scale < Magnitude then
      begin
        SumSquares := 1.0 + SumSquares * Sqr(Scale / Magnitude);
        Scale := Magnitude;
      end
      else
        SumSquares := SumSquares + Sqr(Magnitude / Scale);
  end;
begin
  Scale := 0.0;
  SumSquares := 1.0;
  for I := 0 to High(Values) do
  begin
    Accumulate(Values[I].Re);
    Accumulate(Values[I].Im);
  end;
  if Scale = 0.0 then
    Exit(0.0);
  RootSum := Sqrt(SumSquares);
  if Scale > MaxDouble / RootSum then
    Result := Infinity
  else
    Result := Scale * RootSum;
end;

constructor TDenseComplexHessenberg.Create(const A: IDenseComplexMatrix);
begin
  inherited Create;
  Factor(A);
end;

procedure TDenseComplexHessenberg.Factor(const A: IDenseComplexMatrix);
var
  Work: IDenseComplexMatrix;
  Reflector: array of TComplex;
  I, J, K, Index, ReflectorSize: SizeInt;
  Norm, Beta, Denominator: Double;
  Phase, Alpha, DotProduct, Correction: TComplex;
  NeedsReduction: Boolean;
begin
  ValidateFiniteComplexMatrix(A);
  try
    FSize := A.Rows;
    Work := A.Clone;
    FQ := TDenseComplexMatrix.Zeros(FSize, FSize);
    for I := 0 to FSize - 1 do
      FQ[I, I] := TComplex.One;

    for K := 0 to FSize - 3 do
    begin
      ReflectorSize := FSize - K - 1;
      SetLength(Reflector, ReflectorSize);
      for I := 0 to ReflectorSize - 1 do
        Reflector[I] := Work[K + 1 + I, K];
      NeedsReduction := False;
      for I := 1 to ReflectorSize - 1 do
        if Reflector[I] <> TComplex.Zero then
        begin
          NeedsReduction := True;
          Break;
        end;
      if not NeedsReduction then
        Continue;

      Norm := ScaledComplexNorm(Reflector);
      if IsNan(Norm) or IsInfinite(Norm) then
        raise EDenseMatrixError.Create(
          'ReduceHessenberg: reflector norm exceeds the finite range.');
      if Norm = 0.0 then
        Continue;
      if (Reflector[0].Re = 0.0) and (Reflector[0].Im = 0.0) then
        Phase := TComplex.One
      else
      begin
        Denominator := ScaledComplexNorm([Reflector[0]]);
        Phase := Reflector[0] / Denominator;
      end;
      Alpha := -(Phase * Norm);

      Denominator := 0.0;
      for I := 0 to ReflectorSize - 1 do
      begin
        Reflector[I] := Reflector[I] / Norm;
        if I = 0 then
          Reflector[I] := Reflector[I] + Phase;
        Denominator := Denominator + Sqr(Reflector[I].Re) +
          Sqr(Reflector[I].Im);
      end;
      Beta := 2.0 / Denominator;

      { P = I - beta*v*v^H, with v^H applied from the left. }
      for J := K to FSize - 1 do
      begin
        DotProduct := TComplex.Zero;
        for I := 0 to ReflectorSize - 1 do
          DotProduct := DotProduct + Reflector[I].Conjugate *
            Work[K + 1 + I, J];
        for I := 0 to ReflectorSize - 1 do
        begin
          Correction := (Reflector[I] * DotProduct) * Beta;
          Work[K + 1 + I, J] := Work[K + 1 + I, J] - Correction;
        end;
      end;

      { Apply the same Hermitian reflector from the right. }
      for I := 0 to FSize - 1 do
      begin
        DotProduct := TComplex.Zero;
        for J := 0 to ReflectorSize - 1 do
          DotProduct := DotProduct + Work[I, K + 1 + J] * Reflector[J];
        for J := 0 to ReflectorSize - 1 do
        begin
          Correction := (DotProduct * Reflector[J].Conjugate) * Beta;
          Work[I, K + 1 + J] := Work[I, K + 1 + J] - Correction;
        end;
      end;

      { Accumulate Q on the right, yielding Q^H*A*Q = H. }
      for I := 0 to FSize - 1 do
      begin
        DotProduct := TComplex.Zero;
        for J := 0 to ReflectorSize - 1 do
          DotProduct := DotProduct + FQ[I, K + 1 + J] * Reflector[J];
        for J := 0 to ReflectorSize - 1 do
        begin
          Correction := (DotProduct * Reflector[J].Conjugate) * Beta;
          FQ[I, K + 1 + J] := FQ[I, K + 1 + J] - Correction;
        end;
      end;

      Work[K + 1, K] := Alpha;
      for Index := K + 2 to FSize - 1 do
        Work[Index, K] := TComplex.Zero;
    end;

    for I := 0 to FSize - 1 do
      for J := 0 to FSize - 1 do
        if not Work[I, J].IsFinite or not FQ[I, J].IsFinite then
          raise EDenseMatrixError.CreateFmt(
            'ReduceHessenberg: non-finite factor at [%d,%d].', [I, J]);
    FH := Work;
  except
    on E: EOverflow do
      raise EDenseMatrixError.Create(
        'ReduceHessenberg: complex arithmetic exceeded the finite range.');
  end;
end;

function TDenseComplexHessenberg.GetSize: SizeInt;
begin
  Result := FSize;
end;

function TDenseComplexHessenberg.GetQ: IDenseComplexMatrix;
begin
  Result := FQ.Clone;
end;

function TDenseComplexHessenberg.GetH: IDenseComplexMatrix;
begin
  Result := FH.Clone;
end;

function ReduceHessenberg(const A: IDenseComplexMatrix):
  IDenseComplexHessenberg;
begin
  Result := TDenseComplexHessenberg.Create(A);
end;

function IsNegligibleSubdiagonal(const A: IDenseDoubleMatrix;
  const Row: SizeInt): Boolean;
const
  DOUBLE_EPSILON = 2.2204460492503131E-16;
var
  Scale, DiagonalScale, SubdiagonalScale, Threshold: Double;
begin
  Scale := Max(Abs(A[Row - 1, Row - 1]), Abs(A[Row, Row]));
  Scale := Max(Scale, Abs(A[Row, Row - 1]));
  if Scale = 0.0 then
    Exit(True);
  DiagonalScale := Abs(A[Row - 1, Row - 1]) / Scale +
    Abs(A[Row, Row]) / Scale;
  SubdiagonalScale := Abs(A[Row, Row - 1]) / Scale;
  Threshold := DOUBLE_EPSILON * DiagonalScale;
  Result := SubdiagonalScale <= Threshold;
end;

function BuildRealReflector(var Values: array of Double;
  const Count: SizeInt; out Beta: Double): Boolean;
var
  I: SizeInt;
  Norm, Alpha, Denominator: Double;
begin
  Norm := ScaledNorm(Values);
  if IsNan(Norm) or IsInfinite(Norm) then
    raise EDenseMatrixError.Create(
      'FactorRealSchur: reflector norm exceeds the finite range.');
  if Norm = 0.0 then
    Exit(False);
  if Values[0] >= 0.0 then
    Alpha := -Norm
  else
    Alpha := Norm;
  Denominator := 0.0;
  for I := 0 to Count - 1 do
  begin
    Values[I] := Values[I] / Norm;
    if I = 0 then
      Values[I] := Values[I] - Alpha / Norm;
    Denominator := Denominator + Sqr(Values[I]);
  end;
  Beta := 2.0 / Denominator;
  Result := True;
end;

procedure ApplyRealReflector(const A, Q: IDenseDoubleMatrix;
  const Start, Count: SizeInt; const Reflector: array of Double;
  const Beta: Double);
var
  I, J: SizeInt;
  DotProduct: Double;
begin
  for J := 0 to A.Cols - 1 do
  begin
    DotProduct := 0.0;
    for I := 0 to Count - 1 do
      DotProduct := DotProduct + Reflector[I] * A[Start + I, J];
    for I := 0 to Count - 1 do
      A[Start + I, J] := A[Start + I, J] -
        Beta * Reflector[I] * DotProduct;
  end;
  for I := 0 to A.Rows - 1 do
  begin
    DotProduct := 0.0;
    for J := 0 to Count - 1 do
      DotProduct := DotProduct + A[I, Start + J] * Reflector[J];
    for J := 0 to Count - 1 do
      A[I, Start + J] := A[I, Start + J] -
        Beta * DotProduct * Reflector[J];
  end;
  for I := 0 to Q.Rows - 1 do
  begin
    DotProduct := 0.0;
    for J := 0 to Count - 1 do
      DotProduct := DotProduct + Q[I, Start + J] * Reflector[J];
    for J := 0 to Count - 1 do
      Q[I, Start + J] := Q[I, Start + J] -
        Beta * DotProduct * Reflector[J];
  end;
end;

procedure ApplyPlaneRotation(const A, Q: IDenseDoubleMatrix;
  const Start: SizeInt; const Cosine, Sine: Double);
var
  I, J: SizeInt;
  FirstValue, SecondValue: Double;
begin
  { Apply O^T from the left, O from the right, and accumulate Q*O. }
  for J := 0 to A.Cols - 1 do
  begin
    FirstValue := A[Start, J];
    SecondValue := A[Start + 1, J];
    A[Start, J] := Cosine * FirstValue + Sine * SecondValue;
    A[Start + 1, J] := -Sine * FirstValue + Cosine * SecondValue;
  end;
  for I := 0 to A.Rows - 1 do
  begin
    FirstValue := A[I, Start];
    SecondValue := A[I, Start + 1];
    A[I, Start] := Cosine * FirstValue + Sine * SecondValue;
    A[I, Start + 1] := -Sine * FirstValue + Cosine * SecondValue;
  end;
  for I := 0 to Q.Rows - 1 do
  begin
    FirstValue := Q[I, Start];
    SecondValue := Q[I, Start + 1];
    Q[I, Start] := Cosine * FirstValue + Sine * SecondValue;
    Q[I, Start + 1] := -Sine * FirstValue + Cosine * SecondValue;
  end;
end;

procedure StandardizeRealSchurBlock(const A, Q: IDenseDoubleMatrix;
  const Start: SizeInt);
var
  Scale, A11, A12, A21, A22, HalfDifference, Center, Discriminant,
    Root, Eigenvalue, EigenvectorNorm, FirstNorm, SecondNorm, X, Y, Theta,
    Cosine, Sine, CommonDiagonal: Double;
begin
  Scale := Max(Max(Abs(A[Start, Start]), Abs(A[Start, Start + 1])),
    Max(Abs(A[Start + 1, Start]), Abs(A[Start + 1, Start + 1])));
  if Scale = 0.0 then
  begin
    A[Start + 1, Start] := 0.0;
    Exit;
  end;
  A11 := A[Start, Start] / Scale;
  A12 := A[Start, Start + 1] / Scale;
  A21 := A[Start + 1, Start] / Scale;
  A22 := A[Start + 1, Start + 1] / Scale;
  HalfDifference := 0.5 * (A11 - A22);
  Center := 0.5 * A11 + 0.5 * A22;
  Discriminant := HalfDifference * HalfDifference + A12 * A21;

  if Discriminant >= 0.0 then
  begin
    Root := Sqrt(Discriminant);
    if Center >= 0.0 then
      Eigenvalue := Center + Root
    else
      Eigenvalue := Center - Root;
    FirstNorm := ScaledNorm([A12, Eigenvalue - A11]);
    SecondNorm := ScaledNorm([Eigenvalue - A22, A21]);
    if FirstNorm >= SecondNorm then
    begin
      X := A12;
      Y := Eigenvalue - A11;
      EigenvectorNorm := FirstNorm;
    end
    else
    begin
      X := Eigenvalue - A22;
      Y := A21;
      EigenvectorNorm := SecondNorm;
    end;
    if EigenvectorNorm = 0.0 then
      raise EDenseMatrixError.Create(
        'FactorRealSchur: could not form a real 2x2 Schur vector.');
    ApplyPlaneRotation(A, Q, Start,
      X / EigenvectorNorm, Y / EigenvectorNorm);
    A[Start + 1, Start] := 0.0;
    Exit;
  end;

  Theta := 0.5 * ArcTan2(-(A11 - A22), A12 + A21);
  Cosine := Cos(Theta);
  Sine := Sin(Theta);
  ApplyPlaneRotation(A, Q, Start, Cosine, Sine);
  CommonDiagonal := 0.5 * A[Start, Start] +
    0.5 * A[Start + 1, Start + 1];
  A[Start, Start] := CommonDiagonal;
  A[Start + 1, Start + 1] := CommonDiagonal;
  if (A[Start, Start + 1] = 0.0) or
    (A[Start + 1, Start] = 0.0) or
    ((A[Start, Start + 1] > 0.0) = (A[Start + 1, Start] > 0.0)) then
    raise EDenseMatrixError.Create(
      'FactorRealSchur: failed to standardize a complex 2x2 block.');
end;

procedure FrancisDoubleShiftStep(const A, Q: IDenseDoubleMatrix;
  const Low, High: SizeInt);
var
  Reflector: array[0..2] of Double;
  I, J, K, Count: SizeInt;
  Scale, A11, A12, A21, A22, A32, ShiftSum, ShiftProduct,
    Beta: Double;
  ActiveReflector: array of Double;
begin
  Scale := 0.0;
  for I := Low to High do
    for J := Low to High do
      Scale := Max(Scale, Abs(A[I, J]));
  if Scale = 0.0 then
    Exit;

  A11 := A[High - 1, High - 1] / Scale;
  A12 := A[High - 1, High] / Scale;
  A21 := A[High, High - 1] / Scale;
  A22 := A[High, High] / Scale;
  ShiftSum := A11 + A22;
  ShiftProduct := A11 * A22 - A12 * A21;

  A11 := A[Low, Low] / Scale;
  A12 := A[Low, Low + 1] / Scale;
  A21 := A[Low + 1, Low] / Scale;
  A22 := A[Low + 1, Low + 1] / Scale;
  A32 := A[Low + 2, Low + 1] / Scale;
  Reflector[0] := A11 * A11 + A12 * A21 - ShiftSum * A11 + ShiftProduct;
  Reflector[1] := A21 * (A11 + A22 - ShiftSum);
  Reflector[2] := A21 * A32;

  for K := Low to High - 1 do
  begin
    Count := Min(3, High - K + 1);
    SetLength(ActiveReflector, Count);
    if K = Low then
      for I := 0 to Count - 1 do
        ActiveReflector[I] := Reflector[I]
    else
      for I := 0 to Count - 1 do
        ActiveReflector[I] := A[K + I, K - 1];
    if not BuildRealReflector(ActiveReflector, Count, Beta) then
      Continue;
    ApplyRealReflector(A, Q, K, Count, ActiveReflector, Beta);
    if K > Low then
      for I := K + 1 to Min(K + Count - 1, High) do
        A[I, K - 1] := 0.0;
  end;

  for I := 2 to A.Rows - 1 do
    for J := 0 to I - 2 do
      A[I, J] := 0.0;
end;

constructor TDenseDoubleRealSchur.Create(const A: IDenseDoubleMatrix;
  const MaxIterations: SizeInt);
begin
  inherited Create;
  Factor(A, MaxIterations);
end;

procedure TDenseDoubleRealSchur.Factor(const A: IDenseDoubleMatrix;
  const MaxIterations: SizeInt);
var
  Hessenberg: IDenseDoubleHessenberg;
  RequestedIterations, ActiveHigh, BlockStart, BlockSize, I, J: SizeInt;
begin
  ValidateFiniteMatrix(A);
  if MaxIterations < 0 then
    raise EDenseMatrixError.Create(
      'FactorRealSchur: iteration limit must be non-negative.');
  try
    FSize := A.Rows;
    Hessenberg := ReduceHessenberg(A);
    FT := Hessenberg.H;
    FQ := Hessenberg.Q;
    FIterations := 0;
    if MaxIterations = 0 then
      RequestedIterations := 100 * Max(1, FSize)
    else
      RequestedIterations := MaxIterations;
    ActiveHigh := FSize - 1;

    while ActiveHigh > 0 do
    begin
      for I := 1 to ActiveHigh do
        if IsNegligibleSubdiagonal(FT, I) then
          FT[I, I - 1] := 0.0;
      BlockStart := ActiveHigh;
      while (BlockStart > 0) and (FT[BlockStart, BlockStart - 1] <> 0.0) do
        Dec(BlockStart);
      BlockSize := ActiveHigh - BlockStart + 1;
      if BlockSize <= 2 then
      begin
        if BlockSize = 2 then
          StandardizeRealSchurBlock(FT, FQ, BlockStart);
        ActiveHigh := BlockStart - 1;
        Continue;
      end;
      if FIterations >= RequestedIterations then
        raise EDenseMatrixError.CreateFmt(
          'FactorRealSchur: iteration limit (%d) reached before convergence.',
          [RequestedIterations]);
      FrancisDoubleShiftStep(FT, FQ, BlockStart, ActiveHigh);
      Inc(FIterations);
    end;

    for I := 0 to FSize - 1 do
      for J := 0 to FSize - 1 do
        if IsNan(FT[I, J]) or IsInfinite(FT[I, J]) or
          IsNan(FQ[I, J]) or IsInfinite(FQ[I, J]) then
          raise EDenseMatrixError.CreateFmt(
            'FactorRealSchur: non-finite factor at [%d,%d].', [I, J]);
  except
    on E: EOverflow do
      raise EDenseMatrixError.Create(
        'FactorRealSchur: arithmetic exceeded the finite range.');
  end;
end;

function TDenseDoubleRealSchur.GetSize: SizeInt;
begin
  Result := FSize;
end;

function TDenseDoubleRealSchur.GetQ: IDenseDoubleMatrix;
begin
  Result := FQ.Clone;
end;

function TDenseDoubleRealSchur.GetT: IDenseDoubleMatrix;
begin
  Result := FT.Clone;
end;

function TDenseDoubleRealSchur.GetIterations: SizeInt;
begin
  Result := FIterations;
end;

function FactorRealSchur(const A: IDenseDoubleMatrix;
  const MaxIterations: SizeInt): IDenseDoubleRealSchur;
begin
  Result := TDenseDoubleRealSchur.Create(A, MaxIterations);
end;

function EigenOrderingKey(const Value: TComplex;
  const Ordering: TRealEigenvalueOrdering): Double;
var
  Scale, Ratio: Double;
begin
  if Ordering = reoRealPart then
    Exit(Value.Re);
  if Ordering = reoMagnitude then
  begin
    Scale := Max(Abs(Value.Re), Abs(Value.Im));
    if Scale = 0.0 then
      Exit(0.0);
    Ratio := Min(Abs(Value.Re), Abs(Value.Im)) / Scale;
    { Log-hypot remains ordered when the true magnitude exceeds MaxDouble. }
    Exit(Ln(Scale) + 0.5 * Ln(1.0 + Sqr(Ratio)));
  end;
  Result := 0.0;
end;

procedure RescaleEigenvectorTail(var Vector: TComplexArray;
  const LastIndex: SizeInt);
var
  I: SizeInt;
  Largest: Double;
begin
  Largest := 0.0;
  for I := 0 to LastIndex do
    Largest := Max(Largest, Max(Abs(Vector[I].Re), Abs(Vector[I].Im)));
  if Largest > 1.0E100 then
    for I := 0 to LastIndex do
      Vector[I] := Vector[I] / Largest
  else if (Largest > 0.0) and (Largest < 1.0E-100) then
    for I := 0 to LastIndex do
      Vector[I] := Vector[I] / Largest;
end;

function SolveSchurBlock(const T: IDenseDoubleMatrix;
  const BlockStart, BlockSize, EigenBlockEnd: SizeInt;
  const Eigenvalue: TComplex; const SchurScale: Double;
  var Vector: TComplexArray): Boolean;
const
  DOUBLE_EPSILON = 2.2204460492503131E-16;
var
  J: SizeInt;
  A11, A12, A21, A22, Determinant, Delta: Double;
  RHS1, RHS2, Denominator, X1, X2: TComplex;
begin
  RHS1 := TComplex.Zero;
  RHS2 := TComplex.Zero;
  for J := BlockStart + BlockSize to EigenBlockEnd do
  begin
    RHS1 := RHS1 - (T[BlockStart, J] / SchurScale) * Vector[J];
    if BlockSize = 2 then
      RHS2 := RHS2 - (T[BlockStart + 1, J] / SchurScale) * Vector[J];
  end;
  Delta := 32.0 * DOUBLE_EPSILON *
    Max(1.0, Max(Abs(Eigenvalue.Re), Abs(Eigenvalue.Im)));
  A11 := T[BlockStart, BlockStart] / SchurScale;
  Denominator := TComplex.Create(A11 - Eigenvalue.Re, -Eigenvalue.Im);
  if BlockSize = 1 then
  begin
    if Denominator.Magnitude < Delta then
      Denominator := Denominator + Delta;
    Vector[BlockStart] := RHS1 / Denominator;
    Exit(Vector[BlockStart].IsFinite);
  end;

  A12 := T[BlockStart, BlockStart + 1] / SchurScale;
  A21 := T[BlockStart + 1, BlockStart] / SchurScale;
  A22 := T[BlockStart + 1, BlockStart + 1] / SchurScale;
  A11 := A11 - Eigenvalue.Re;
  A22 := A22 - Eigenvalue.Re;
  A11 := A11 + Delta;
  A22 := A22 + Delta;
  X1 := TComplex.Create(A11, -Eigenvalue.Im);
  X2 := TComplex.Create(A22, -Eigenvalue.Im);
  Determinant := (X1 * X2 - A12 * A21).Magnitude;
  if Determinant < Delta * Delta then
  begin
    A11 := A11 + Delta;
    A22 := A22 + Delta;
    X1 := TComplex.Create(A11, -Eigenvalue.Im);
    X2 := TComplex.Create(A22, -Eigenvalue.Im);
  end;
  Denominator := X1 * X2 - A12 * A21;
  if Denominator.Magnitude = 0.0 then
    Exit(False);
  X1 := (RHS1 * X2 - A12 * RHS2) / Denominator;
  { Cramer's rule for the second component. }
  X2 := (TComplex.Create(A11, -Eigenvalue.Im) * RHS2 -
    A21 * RHS1) / Denominator;
  Vector[BlockStart] := X1;
  Vector[BlockStart + 1] := X2;
  Result := X1.IsFinite and X2.IsFinite;
end;

function BuildSchurEigenvector(const T, Q: IDenseDoubleMatrix;
  const BlockStart, BlockSize: SizeInt; const Eigenvalue: TComplex;
  const SchurScale: Double): TComplexArray;
var
  I, J, Row, BlockSizeHere, EigenBlockEnd: SizeInt;
  BlockScale, ImaginaryPart, VectorNorm: Double;
  SchurVector: TComplexArray;
begin
  SetLength(SchurVector, T.Rows);
  EigenBlockEnd := BlockStart + BlockSize - 1;
  if BlockSize = 1 then
    SchurVector[BlockStart] := TComplex.One
  else
  begin
    BlockScale := Max(Abs(T[BlockStart, BlockStart + 1]),
      Abs(T[BlockStart + 1, BlockStart]));
    if BlockScale = 0.0 then
      raise EDenseMatrixError.Create(
        'FactorRealEigen: invalid zero off-diagonal in a complex Schur block.');
    ImaginaryPart := BlockScale * Sqrt(
      (Abs(T[BlockStart, BlockStart + 1]) / BlockScale) *
      (Abs(T[BlockStart + 1, BlockStart]) / BlockScale));
    if IsNan(ImaginaryPart) or IsInfinite(ImaginaryPart) then
      raise EDenseMatrixError.Create(
        'FactorRealEigen: complex eigenvalue exceeds the finite range.');
    SchurVector[BlockStart] := TComplex.Create(
      T[BlockStart, BlockStart + 1] / BlockScale, 0.0);
    SchurVector[BlockStart + 1] := TComplex.Create(0.0,
      ImaginaryPart / BlockScale);
  end;

  Row := BlockStart - 1;
  while Row >= 0 do
  begin
    if (Row > 0) and (T[Row, Row - 1] <> 0.0) then
    begin
      BlockSizeHere := 2;
      Dec(Row);
    end
    else
      BlockSizeHere := 1;
    if not SolveSchurBlock(T, Row, BlockSizeHere, EigenBlockEnd,
      TComplex.Create(Eigenvalue.Re / SchurScale,
        Eigenvalue.Im / SchurScale), SchurScale, SchurVector) then
      raise EDenseMatrixError.Create(
        'FactorRealEigen: failed during Schur back substitution.');
    RescaleEigenvectorTail(SchurVector, EigenBlockEnd);
    Dec(Row);
  end;

  Result := nil;
  SetLength(Result, T.Rows);
  for I := 0 to T.Rows - 1 do
  begin
    Result[I] := TComplex.Zero;
    for J := 0 to T.Rows - 1 do
      Result[I] := Result[I] + Q[I, J] * SchurVector[J];
  end;
  VectorNorm := ScaledComplexNorm(Result);
  if (VectorNorm = 0.0) or IsNan(VectorNorm) or IsInfinite(VectorNorm) then
    raise EDenseMatrixError.Create(
      'FactorRealEigen: could not normalize a computed eigenvector.');
  for I := 0 to High(Result) do
  begin
    Result[I] := Result[I] / VectorNorm;
    if not Result[I].IsFinite then
      raise EDenseMatrixError.Create(
        'FactorRealEigen: eigenvector contains a non-finite value.');
  end;
end;

function ComputeEigenResidual(const A: IDenseDoubleMatrix;
  const Eigenvalue: TComplex; const Vector: IDenseComplexMatrix;
  const Column: SizeInt; const MatrixScale, MatrixNorm: Double): Double;
var
  I, J: SizeInt;
  ProductValue, ResidualValue, ScaledLambda: TComplex;
  Values: TComplexArray;
  Denominator: Double;
begin
  if MatrixScale = 0.0 then
    Exit(0.0);
  ScaledLambda := TComplex.Create(Eigenvalue.Re / MatrixScale,
    Eigenvalue.Im / MatrixScale);
  SetLength(Values, A.Rows);
  for I := 0 to A.Rows - 1 do
  begin
    ProductValue := TComplex.Zero;
    for J := 0 to A.Cols - 1 do
      ProductValue := ProductValue + (A[I, J] / MatrixScale) * Vector[J, Column];
    ResidualValue := ProductValue - ScaledLambda * Vector[I, Column];
    Values[I] := ResidualValue;
  end;
  Denominator := MatrixNorm + ScaledLambda.Magnitude;
  if Denominator = 0.0 then
    Exit(0.0);
  Result := ScaledComplexNorm(Values) / Denominator;
  if IsNan(Result) or IsInfinite(Result) then
    raise EDenseMatrixError.Create(
      'FactorRealEigen: eigenpair residual is non-finite.');
end;

constructor TDenseDoubleRealEigen.Create(const A: IDenseDoubleMatrix;
  const Ordering: TRealEigenvalueOrdering; const MaxIterations: SizeInt);
begin
  inherited Create;
  Factor(A, Ordering, MaxIterations);
end;

procedure TDenseDoubleRealEigen.Factor(const A: IDenseDoubleMatrix;
  const Ordering: TRealEigenvalueOrdering; const MaxIterations: SizeInt);
var
  Schur: IDenseDoubleRealSchur;
  T, Q: IDenseDoubleMatrix;
  I, J, K, BlockStart, BlockSize, Column: SizeInt;
  MatrixScale, SchurScale, MatrixNorm, BlockScale, ImaginaryPart: Double;
  TempValue: TComplex;
  TempResidual: Double;
  TempColumn: array of TComplex;
  ResidualValues: TComplexArray;
  Eigenvector: TComplexArray;
begin
  ValidateFiniteMatrix(A);
  if not (Ordering in [reoSchurOrder, reoRealPart, reoMagnitude]) then
    raise EDenseMatrixError.Create(
      'FactorRealEigen: unsupported eigenvalue ordering.');
  Schur := FactorRealSchur(A, MaxIterations);
  FSize := Schur.Size;
  FIterations := Schur.Iterations;
  T := Schur.T;
  Q := Schur.Q;
  SchurScale := 0.0;
  for I := 0 to FSize - 1 do
    for J := 0 to FSize - 1 do
      SchurScale := Max(SchurScale, Abs(T[I, J]));
  if SchurScale = 0.0 then
    SchurScale := 1.0;
  SetLength(FValues, FSize);
  SetLength(FResiduals, FSize);
  FVectors := TDenseComplexMatrix.Zeros(FSize, FSize);

  BlockStart := 0;
  Column := 0;
  while BlockStart < FSize do
  begin
    if (BlockStart + 1 < FSize) and (T[BlockStart + 1, BlockStart] <> 0.0) then
      BlockSize := 2
    else
      BlockSize := 1;
    if BlockSize = 1 then
      FValues[Column] := TComplex.Create(T[BlockStart, BlockStart], 0.0)
    else
    begin
      BlockScale := Max(Max(Abs(T[BlockStart, BlockStart]),
        Abs(T[BlockStart, BlockStart + 1])),
        Max(Abs(T[BlockStart + 1, BlockStart]),
          Abs(T[BlockStart + 1, BlockStart + 1])));
      if BlockScale = 0.0 then
        raise EDenseMatrixError.Create(
          'FactorRealEigen: invalid zero complex Schur block.');
      ImaginaryPart := BlockScale * Sqrt(
        (Abs(T[BlockStart, BlockStart + 1]) / BlockScale) *
        (Abs(T[BlockStart + 1, BlockStart]) / BlockScale));
      if IsNan(ImaginaryPart) or IsInfinite(ImaginaryPart) then
        raise EDenseMatrixError.Create(
          'FactorRealEigen: eigenvalue exceeds the finite range.');
      FValues[Column] := TComplex.Create(T[BlockStart, BlockStart],
        ImaginaryPart);
      FValues[Column + 1] := FValues[Column].Conjugate;
    end;
    Eigenvector := BuildSchurEigenvector(T, Q, BlockStart, BlockSize,
      FValues[Column], SchurScale);
    for I := 0 to FSize - 1 do
    begin
      FVectors[I, Column] := Eigenvector[I];
      if BlockSize = 2 then
        FVectors[I, Column + 1] := Eigenvector[I].Conjugate;
    end;
    Inc(Column, BlockSize);
    Inc(BlockStart, BlockSize);
  end;

  MatrixScale := 0.0;
  for I := 0 to FSize - 1 do
    for J := 0 to FSize - 1 do
      MatrixScale := Max(MatrixScale, Abs(A[I, J]));
  MatrixNorm := 0.0;
  if MatrixScale > 0.0 then
  begin
    SetLength(ResidualValues, FSize * FSize);
    K := 0;
    for I := 0 to FSize - 1 do
      for J := 0 to FSize - 1 do
      begin
        ResidualValues[K] := TComplex.Create(A[I, J] / MatrixScale, 0.0);
        Inc(K);
      end;
    MatrixNorm := ScaledComplexNorm(ResidualValues);
  end;
  for J := 0 to FSize - 1 do
    FResiduals[J] := ComputeEigenResidual(A, FValues[J], FVectors, J,
      MatrixScale, MatrixNorm);

  if Ordering <> reoSchurOrder then
    for I := 1 to FSize - 1 do
    begin
      TempValue := FValues[I];
      TempResidual := FResiduals[I];
      SetLength(TempColumn, FSize);
      for K := 0 to FSize - 1 do
        TempColumn[K] := FVectors[K, I];
      J := I;
      while (J > 0) and
        (EigenOrderingKey(TempValue, Ordering) <
        EigenOrderingKey(FValues[J - 1], Ordering)) do
      begin
        FValues[J] := FValues[J - 1];
        FResiduals[J] := FResiduals[J - 1];
        for K := 0 to FSize - 1 do
          FVectors[K, J] := FVectors[K, J - 1];
        Dec(J);
      end;
      FValues[J] := TempValue;
      FResiduals[J] := TempResidual;
      for K := 0 to FSize - 1 do
        FVectors[K, J] := TempColumn[K];
    end;

  for I := 0 to FSize - 1 do
    if not FValues[I].IsFinite or IsNan(FResiduals[I]) or
      IsInfinite(FResiduals[I]) then
      raise EDenseMatrixError.CreateFmt(
        'FactorRealEigen: non-finite result at eigenpair %d.', [I]);
end;

function TDenseDoubleRealEigen.GetSize: SizeInt;
begin
  Result := FSize;
end;

function TDenseDoubleRealEigen.GetEigenvalues: TComplexArray;
var
  I: SizeInt;
begin
  Result := nil;
  SetLength(Result, Length(FValues));
  for I := 0 to High(FValues) do
    Result[I] := FValues[I];
end;

function TDenseDoubleRealEigen.GetRightEigenvectors: IDenseComplexMatrix;
begin
  Result := FVectors.Clone;
end;

function TDenseDoubleRealEigen.GetResiduals: TDoubleArray;
var
  I: SizeInt;
begin
  Result := nil;
  SetLength(Result, Length(FResiduals));
  for I := 0 to High(FResiduals) do
    Result[I] := FResiduals[I];
end;

function TDenseDoubleRealEigen.GetIterations: SizeInt;
begin
  Result := FIterations;
end;

function TDenseDoubleRealEigen.GetConverged: Boolean;
begin
  Result := True;
end;

procedure TDenseDoubleGeneralizedSchur.Factor(const A, B: IDenseDoubleMatrix;
  const MaxIterations: SizeInt);
var
  I, J, Candidate: SizeInt;
  Scale, Gamma, NormBeta: Double;
  IsIdentityB: Boolean;
  C, BScaled, M, CZ, R, ShiftedT, Identity:
    IDenseDoubleMatrix;
  LU: IDenseDoubleLU;
  QR: IDenseDoubleQR;
  Schur: IDenseDoubleRealSchur;
  Eigen: IDenseDoubleRealEigen;
  Mu, AlphaValue, BetaValue: TComplex;
  TempComplex: TComplex;
  FoundShift: Boolean;
begin
  if (A = nil) or (B = nil) then
    raise EDenseMatrixError.Create(
      'FactorRealGeneralizedSchur: matrices must not be nil.');
  if (A.Rows <> A.Cols) or (B.Rows <> B.Cols) or (A.Rows <> B.Rows) then
    raise EDenseMatrixError.Create(
      'FactorRealGeneralizedSchur: matrices must be square and have matching sizes.');
  if MaxIterations < 0 then
    raise EDenseMatrixError.Create(
      'FactorRealGeneralizedSchur: iteration limit must be non-negative.');
  FSize := A.Rows;
  IsIdentityB := True;
  Scale := 0.0;
  for I := 0 to FSize - 1 do
    for J := 0 to FSize - 1 do
    begin
      if IsNan(A[I, J]) or IsInfinite(A[I, J]) or
         IsNan(B[I, J]) or IsInfinite(B[I, J]) then
        raise EDenseMatrixError.CreateFmt(
          'FactorRealGeneralizedSchur: non-finite input at [%d,%d].', [I, J]);
      if B[I, J] <> Ord(I = J) then IsIdentityB := False;
      Scale := Max(Scale, Max(Abs(A[I, J]), Abs(B[I, J])));
    end;

  if IsIdentityB then
  begin
    Schur := FactorRealSchur(A, MaxIterations);
    Eigen := FactorRealEigen(A, reoSchurOrder, MaxIterations);
    FQ := Schur.Q;
    FZ := Schur.Q;
    FS := Schur.T;
    FT := TDenseDoubleMatrix.Zeros(FSize, FSize);
    for I := 0 to FSize - 1 do FT[I, I] := 1.0;
    FAlpha := Eigen.Eigenvalues;
    FBeta := nil;
    SetLength(FBeta, FSize);
    for I := 0 to FSize - 1 do
    begin
      Scale := Max(1.0, FAlpha[I].Magnitude);
      FAlpha[I] := FAlpha[I] / Scale;
      FBeta[I] := TComplex.Create(1.0 / Scale, 0.0);
    end;
    FTransformEigenvectors := Eigen.RightEigenvectors;
    FIterations := Schur.Iterations;
    Exit;
  end;

  if FSize = 0 then
  begin
    FQ := TDenseDoubleMatrix.Zeros(0, 0);
    FZ := TDenseDoubleMatrix.Zeros(0, 0);
    FS := A.Clone;
    FT := B.Clone;
    FAlpha := nil;
    FBeta := nil;
    FTransformEigenvectors := TDenseComplexMatrix.Zeros(0, 0);
    FIterations := 0;
    Exit;
  end;
  if Scale = 0.0 then
    raise EDenseMatrixError.Create(
      'FactorRealGeneralizedSchur: zero pencil is indeterminate.');

  { A nonsingular shift C=A+gamma*B maps finite and infinite eigenvalues to
    the ordinary spectrum of C^-1*B. A regular n-by-n pencil has at most n
    singular shifts, so testing n+1 distinct values finds a usable C. }
  BScaled := TDenseDoubleMatrix.Zeros(FSize, FSize);
  for I := 0 to FSize - 1 do
    for J := 0 to FSize - 1 do
    begin
      if ((A[I, J] <> 0.0) and (A[I, J] / Scale = 0.0)) or
         ((B[I, J] <> 0.0) and (B[I, J] / Scale = 0.0)) then
        raise EDenseMatrixError.Create(
          'FactorRealGeneralizedSchur: input dynamic range is not representable after scaling.');
      BScaled[I, J] := B[I, J] / Scale;
    end;
  FoundShift := False;
  for Candidate := 0 to FSize do
  begin
    Gamma := Candidate;
    C := TDenseDoubleMatrix.Zeros(FSize, FSize);
    for I := 0 to FSize - 1 do
      for J := 0 to FSize - 1 do
        C[I, J] := A[I, J] / Scale + Gamma * BScaled[I, J];
    try
      LU := FactorLU(C);
      M := LU.Solve(BScaled);
      FoundShift := True;
      Break;
    except
      on EDenseMatrixError do ;
    end;
  end;
  if not FoundShift then
    raise EDenseMatrixError.Create(
      'FactorRealGeneralizedSchur: no numerically nonsingular pencil shift was found.');

  Schur := FactorRealSchur(M, MaxIterations);
  Eigen := FactorRealEigen(M, reoSchurOrder, MaxIterations);
  FTransformEigenvectors := Eigen.RightEigenvectors;
  FZ := Schur.Q;
  CZ := Multiply(C, FZ);
  QR := FactorQR(CZ);
  if QR.NumericalRank <> FSize then
    raise EDenseMatrixError.Create(
      'FactorRealGeneralizedSchur: shifted right-vector factor is rank deficient.');
  FQ := QR.Q;
  R := QR.R;
  Identity := TDenseDoubleMatrix.Zeros(FSize, FSize);
  for I := 0 to FSize - 1 do Identity[I, I] := 1.0;
  ShiftedT := Multiply(R, Schur.T);
  FS := Multiply(R, Identity);
  for I := 0 to FSize - 1 do
    for J := 0 to FSize - 1 do
      FS[I, J] := (FS[I, J] - Gamma * ShiftedT[I, J]) * Scale;
  FT := ShiftedT;
  for I := 0 to FSize - 1 do
    for J := 0 to FSize - 1 do
      FT[I, J] := FT[I, J] * Scale;
  for I := 0 to FSize - 1 do
    for J := 0 to FSize - 1 do
      if IsNan(FS[I, J]) or IsInfinite(FS[I, J]) or
         IsNan(FT[I, J]) or IsInfinite(FT[I, J]) then
        raise EDenseMatrixError.CreateFmt(
          'FactorRealGeneralizedSchur: non-finite factor at [%d,%d].', [I, J]);

  { Triangularize each 2x2 diagonal block of T with a right plane rotation.
    The same rotation is accumulated into Z and applied to S. }
  I := 0;
  while I < FSize do
  begin
    if (I + 1 < FSize) and (Abs(FT[I + 1, I]) > 0.0) then
    begin
      Scale := Max(Abs(FT[I + 1, I]), Abs(FT[I + 1, I + 1]));
      if Scale = 0.0 then
        raise EDenseMatrixError.Create(
          'FactorRealGeneralizedSchur: invalid zero QZ block.');
      NormBeta := Scale * Sqrt(Sqr(FT[I + 1, I] / Scale) +
        Sqr(FT[I + 1, I + 1] / Scale));
      if (NormBeta = 0.0) or IsInfinite(NormBeta) then
        raise EDenseMatrixError.Create(
          'FactorRealGeneralizedSchur: QZ block scaling failed.');
      AlphaValue := TComplex.Create(FT[I + 1, I + 1] / NormBeta,
        -FT[I + 1, I] / NormBeta);
      BetaValue := TComplex.Create(FT[I + 1, I] / NormBeta,
        FT[I + 1, I + 1] / NormBeta);
      for J := 0 to FSize - 1 do
      begin
        Mu := TComplex.Create(FZ[J, I], 0.0);
        FZ[J, I] := FZ[J, I] * (FT[I + 1, I + 1] / NormBeta) +
          FZ[J, I + 1] * (-FT[I + 1, I] / NormBeta);
        FZ[J, I + 1] := Mu.Re * (FT[I + 1, I] / NormBeta) +
          FZ[J, I + 1] * (FT[I + 1, I + 1] / NormBeta);
      end;
      for J := 0 to FSize - 1 do
      begin
        NormBeta := FT[J, I];
        FT[J, I] := NormBeta * AlphaValue.Re +
          FT[J, I + 1] * AlphaValue.Im;
        FT[J, I + 1] := NormBeta * BetaValue.Re +
          FT[J, I + 1] * BetaValue.Im;
        NormBeta := FS[J, I];
        FS[J, I] := NormBeta * AlphaValue.Re +
          FS[J, I + 1] * AlphaValue.Im;
        FS[J, I + 1] := NormBeta * BetaValue.Re +
          FS[J, I + 1] * BetaValue.Im;
      end;
      FT[I + 1, I] := 0.0;
      Inc(I, 2);
    end
    else
      Inc(I);
  end;
  for J := 0 to FSize - 1 do
    if FT[J, J] < 0.0 then
    begin
      for I := 0 to FSize - 1 do
      begin
        FS[I, J] := -FS[I, J];
        FT[I, J] := -FT[I, J];
        FZ[I, J] := -FZ[I, J];
      end;
    end;

  SetLength(FAlpha, FSize);
  SetLength(FBeta, FSize);
  for I := 0 to FSize - 1 do
  begin
    Mu := Eigen.Eigenvalues[I];
    AlphaValue := TComplex.One - Mu * Gamma;
    BetaValue := Mu;
    NormBeta := BetaValue.Magnitude;
    if NormBeta <> 0.0 then
    begin
      BetaValue := BetaValue * (BetaValue.Conjugate / NormBeta);
      AlphaValue := AlphaValue * (Mu.Conjugate / NormBeta);
    end
    else
      AlphaValue := TComplex.One;
    Scale := Max(AlphaValue.Magnitude, BetaValue.Magnitude);
    if (Scale = 0.0) or IsNan(Scale) or IsInfinite(Scale) then
      raise EDenseMatrixError.Create(
        'FactorRealGeneralizedSchur: indeterminate or non-finite generalized eigenvalue.');
    FAlpha[I] := AlphaValue / Scale;
    FBeta[I] := BetaValue / Scale;
  end;
  I := 0;
  while I < FSize do
  begin
    if (Eigen.Eigenvalues[I].Im > 0.0) and (I + 1 < FSize) then
    begin
      if FAlpha[I].Im < 0.0 then
      begin
        TempComplex := FAlpha[I];
        FAlpha[I] := FAlpha[I + 1];
        FAlpha[I + 1] := TempComplex;
        TempComplex := FBeta[I];
        FBeta[I] := FBeta[I + 1];
        FBeta[I + 1] := TempComplex;
        for J := 0 to FSize - 1 do
        begin
          TempComplex := FTransformEigenvectors[J, I];
          FTransformEigenvectors[J, I] := FTransformEigenvectors[J, I + 1];
          FTransformEigenvectors[J, I + 1] := TempComplex;
        end;
      end;
      Inc(I, 2);
    end
    else
      Inc(I);
  end;
  FIterations := Schur.Iterations;
end;

constructor TDenseDoubleGeneralizedSchur.Create(const A, B: IDenseDoubleMatrix;
  const MaxIterations: SizeInt);
begin
  inherited Create;
  Factor(A, B, MaxIterations);
end;

function TDenseDoubleGeneralizedSchur.GetSize: SizeInt;
begin
  Result := FSize;
end;

function TDenseDoubleGeneralizedSchur.GetQ: IDenseDoubleMatrix;
begin
  Result := FQ.Clone;
end;

function TDenseDoubleGeneralizedSchur.GetS: IDenseDoubleMatrix;
begin
  Result := FS.Clone;
end;

function TDenseDoubleGeneralizedSchur.GetZ: IDenseDoubleMatrix;
begin
  Result := FZ.Clone;
end;

function TDenseDoubleGeneralizedSchur.GetT: IDenseDoubleMatrix;
begin
  Result := FT.Clone;
end;

function TDenseDoubleGeneralizedSchur.GetAlpha: TComplexArray;
var
  I: SizeInt;
begin
  Result := nil;
  SetLength(Result, Length(FAlpha));
  for I := 0 to High(FAlpha) do Result[I] := FAlpha[I];
end;

function TDenseDoubleGeneralizedSchur.GetBeta: TComplexArray;
var
  I: SizeInt;
begin
  Result := nil;
  SetLength(Result, Length(FBeta));
  for I := 0 to High(FBeta) do Result[I] := FBeta[I];
end;

function TDenseDoubleGeneralizedSchur.GetIterations: SizeInt;
begin
  Result := FIterations;
end;

procedure TDenseDoubleGeneralizedEigen.Factor(const A, B: IDenseDoubleMatrix;
  const MaxIterations: SizeInt);
var
  I, J, K, N: SizeInt;
  IsIdentityB: Boolean;
  Eigen: IDenseDoubleRealEigen;
  SchurImpl: TDenseDoubleGeneralizedSchur;
  Scale, NormA, NormB, VectorNorm, ResidualNorm, Denominator: Double;
  AV, BV, Residual: TComplex;
  Components: array of Double;
begin
  SchurImpl := TDenseDoubleGeneralizedSchur.Create(A, B, MaxIterations);
  FSchur := SchurImpl;
  IsIdentityB := True;
  for I := 0 to A.Rows - 1 do
    for J := 0 to A.Rows - 1 do
      if B[I, J] <> Ord(I = J) then IsIdentityB := False;
  if IsIdentityB then
  begin
    Eigen := FactorRealEigen(A, reoSchurOrder, MaxIterations);
    FVectors := Eigen.RightEigenvectors;
    FResiduals := Eigen.Residuals;
    Exit;
  end;
  FVectors := SchurImpl.FTransformEigenvectors.Clone;
  N := FSchur.Size;
  Scale := 0.0;
  for I := 0 to N - 1 do
    for J := 0 to N - 1 do
      Scale := Max(Scale, Max(Abs(A[I, J]), Abs(B[I, J])));
  NormA := 0.0;
  NormB := 0.0;
  for I := 0 to N - 1 do
    for J := 0 to N - 1 do
    begin
      NormA := NormA + Sqr(A[I, J] / Scale);
      NormB := NormB + Sqr(B[I, J] / Scale);
    end;
  NormA := Sqrt(NormA);
  NormB := Sqrt(NormB);
  SetLength(FResiduals, N);
  SetLength(Components, 2 * N);
  for K := 0 to N - 1 do
  begin
    VectorNorm := 0.0;
    for J := 0 to N - 1 do
      VectorNorm := VectorNorm + FVectors[J, K].SqrMagnitude;
    VectorNorm := Sqrt(VectorNorm);
    for I := 0 to N - 1 do
    begin
      AV := TComplex.Zero;
      BV := TComplex.Zero;
      for J := 0 to N - 1 do
      begin
        AV := AV + FVectors[J, K] * (A[I, J] / Scale);
        BV := BV + FVectors[J, K] * (B[I, J] / Scale);
      end;
      Residual := FSchur.Beta[K] * AV - FSchur.Alpha[K] * BV;
      Components[2 * I] := Residual.Re;
      Components[2 * I + 1] := Residual.Im;
    end;
    ResidualNorm := ScaledNorm(Components);
    Denominator := (FSchur.Beta[K].Magnitude * NormA +
      FSchur.Alpha[K].Magnitude * NormB) * VectorNorm;
    if Denominator = 0.0 then
    begin
      if ResidualNorm <> 0.0 then
        raise EDenseMatrixError.CreateFmt(
          'FactorRealGeneralizedEigen: zero residual denominator at eigenpair %d.',
          [K]);
      FResiduals[K] := 0.0;
    end
    else
      FResiduals[K] := ResidualNorm / Denominator;
  end;
end;

constructor TDenseDoubleGeneralizedEigen.Create(const A, B: IDenseDoubleMatrix;
  const MaxIterations: SizeInt);
begin
  inherited Create;
  Factor(A, B, MaxIterations);
end;

function TDenseDoubleGeneralizedEigen.GetSize: SizeInt;
begin
  Result := FSchur.Size;
end;

function TDenseDoubleGeneralizedEigen.GetAlpha: TComplexArray;
begin
  Result := FSchur.Alpha;
end;

function TDenseDoubleGeneralizedEigen.GetBeta: TComplexArray;
begin
  Result := FSchur.Beta;
end;

function TDenseDoubleGeneralizedEigen.GetRightEigenvectors: IDenseComplexMatrix;
begin
  Result := FVectors.Clone;
end;

function TDenseDoubleGeneralizedEigen.GetResiduals: TDoubleArray;
var
  I: SizeInt;
begin
  Result := nil;
  SetLength(Result, Length(FResiduals));
  for I := 0 to High(FResiduals) do Result[I] := FResiduals[I];
end;

function TDenseDoubleGeneralizedEigen.GetIterations: SizeInt;
begin
  Result := FSchur.Iterations;
end;

function TDenseDoubleGeneralizedEigen.GetConverged: Boolean;
begin
  Result := True;
end;

function FactorRealEigen(const A: IDenseDoubleMatrix;
  const Ordering: TRealEigenvalueOrdering;
  const MaxIterations: SizeInt): IDenseDoubleRealEigen;
begin
  Result := TDenseDoubleRealEigen.Create(A, Ordering, MaxIterations);
end;

function FactorRealGeneralizedSchur(const A, B: IDenseDoubleMatrix;
  const MaxIterations: SizeInt): IDenseDoubleGeneralizedSchur;
begin
  Result := TDenseDoubleGeneralizedSchur.Create(A, B, MaxIterations);
end;

function FactorComplexSchur(const A: IDenseComplexMatrix;
  const MaxIterations: SizeInt): IDenseComplexSchur;
begin
  Result := TDenseComplexSchur.Create(A, MaxIterations);
end;

function FactorRealGeneralizedEigen(const A, B: IDenseDoubleMatrix;
  const MaxIterations: SizeInt): IDenseDoubleGeneralizedEigen;
begin
  Result := TDenseDoubleGeneralizedEigen.Create(A, B, MaxIterations);
end;

procedure TDenseComplexGeneralizedSchur.Factor(const A, B: IDenseComplexMatrix;
  const MaxIterations: SizeInt);
var
  I, J, Candidate: SizeInt;
  Scale, Gamma, Magnitude, PairScale, VectorNorm, SchurScale,
    ColumnScale, SumScale: Double;
  C, BScaled, M, SchurQ, SchurT, CZ, R, Product: IDenseComplexMatrix;
  LU: IDenseComplexLU;
  QR: IDenseComplexQR;
  Mu, AlphaValue, BetaValue, Phase, Temp: TComplex;
  FoundShift: Boolean;
begin
  if (A = nil) or (B = nil) then
    raise EDenseMatrixError.Create(
      'FactorComplexGeneralizedSchur: matrices must not be nil.');
  if (A.Rows <> A.Cols) or (B.Rows <> B.Cols) or (A.Rows <> B.Rows) then
    raise EDenseMatrixError.Create(
      'FactorComplexGeneralizedSchur: matrices must be square and have matching sizes.');
  if MaxIterations < 0 then
    raise EDenseMatrixError.Create(
      'FactorComplexGeneralizedSchur: iteration limit must be non-negative.');
  FSize := A.Rows;
  Scale := 0.0;
  for I := 0 to FSize - 1 do
    for J := 0 to FSize - 1 do
    begin
      if not A[I, J].IsFinite or not B[I, J].IsFinite then
        raise EDenseMatrixError.CreateFmt(
          'FactorComplexGeneralizedSchur: non-finite input at [%d,%d].',
          [I, J]);
      Scale := Max(Scale, Max(A[I, J].Magnitude, B[I, J].Magnitude));
    end;
  if FSize = 0 then
  begin
    FQ := TDenseComplexMatrix.Zeros(0, 0);
    FZ := TDenseComplexMatrix.Zeros(0, 0);
    FS := A.Clone;
    FT := B.Clone;
    FAlpha := nil;
    FBeta := nil;
    FTransformEigenvectors := TDenseComplexMatrix.Zeros(0, 0);
    FIterations := 0;
    Exit;
  end;
  if Scale = 0.0 then
    raise EDenseMatrixError.Create(
      'FactorComplexGeneralizedSchur: zero pencil is indeterminate.');

  BScaled := TDenseComplexMatrix.Zeros(FSize, FSize);
  for I := 0 to FSize - 1 do
    for J := 0 to FSize - 1 do
    begin
      if ((A[I, J] <> TComplex.Zero) and
          ((A[I, J] / Scale) = TComplex.Zero)) or
         ((B[I, J] <> TComplex.Zero) and
          ((B[I, J] / Scale) = TComplex.Zero)) then
        raise EDenseMatrixError.Create(
          'FactorComplexGeneralizedSchur: input dynamic range is not representable after scaling.');
      BScaled[I, J] := B[I, J] / Scale;
    end;
  FoundShift := False;
  for Candidate := 0 to FSize do
  begin
    Gamma := Candidate;
    C := TDenseComplexMatrix.Zeros(FSize, FSize);
    for I := 0 to FSize - 1 do
      for J := 0 to FSize - 1 do
        C[I, J] := A[I, J] / Scale + Gamma * BScaled[I, J];
    try
      LU := FactorLU(C);
      M := LU.Solve(BScaled);
      FoundShift := True;
      Break;
    except
      on EDenseMatrixError do ;
    end;
  end;
  if not FoundShift then
    raise EDenseMatrixError.Create(
      'FactorComplexGeneralizedSchur: no numerically nonsingular pencil shift was found.');

  FactorComplexSchurInternal(M, MaxIterations, SchurQ, SchurT, FIterations);
  FTransformEigenvectors := TDenseComplexMatrix.Zeros(FSize, FSize);
  SchurScale := 0.0;
  for I := 0 to FSize - 1 do
    for J := 0 to FSize - 1 do
      SchurScale := Max(SchurScale, SchurT[I, J].Magnitude);
  if SchurScale = 0.0 then
    for I := 0 to FSize - 1 do FTransformEigenvectors[I, I] := TComplex.One
  else
  for I := 0 to FSize - 1 do
  begin
    FTransformEigenvectors[I, I] := TComplex.One;
    for J := I - 1 downto 0 do
    begin
      Temp := TComplex.Zero;
      for Candidate := J + 1 to I do
        Temp := Temp + (SchurT[J, Candidate] / SchurScale) *
          FTransformEigenvectors[Candidate, I];
      Mu := SchurT[I, I] / SchurScale;
      Magnitude := (SchurT[J, J] / SchurScale - Mu).Magnitude;
      SumScale := 2.2204460492503131E-16 * Max(1, FSize);
      if Magnitude <= SumScale then
      begin
        if Temp.Magnitude > SumScale * Max(1, I - J) then
          raise EDenseMatrixError.CreateFmt(
            'FactorComplexGeneralizedSchur: eigenvector recovery failed at %d.',
            [I]);
        FTransformEigenvectors[J, I] := TComplex.Zero;
      end
      else
        FTransformEigenvectors[J, I] := -Temp /
          (SchurT[J, J] / SchurScale - Mu);
      ColumnScale := 0.0;
      for Candidate := 0 to I do
        ColumnScale := Max(ColumnScale,
          FTransformEigenvectors[Candidate, I].Magnitude);
      if ColumnScale > 1E100 then
        for Candidate := 0 to I do
          FTransformEigenvectors[Candidate, I] :=
            FTransformEigenvectors[Candidate, I] / ColumnScale;
    end;
  end;
  FTransformEigenvectors := Multiply(SchurQ, FTransformEigenvectors);
  for J := 0 to FSize - 1 do
  begin
    ColumnScale := 0.0;
    for I := 0 to FSize - 1 do
      ColumnScale := Max(ColumnScale,
        FTransformEigenvectors[I, J].Magnitude);
    if (ColumnScale = 0.0) or IsNan(ColumnScale) or IsInfinite(ColumnScale) then
      raise EDenseMatrixError.CreateFmt(
        'FactorComplexGeneralizedSchur: could not normalize eigenvector %d.',
        [J]);
    VectorNorm := 0.0;
    for I := 0 to FSize - 1 do
      VectorNorm := VectorNorm +
        (FTransformEigenvectors[I, J] / ColumnScale).SqrMagnitude;
    VectorNorm := Sqrt(VectorNorm);
    if (VectorNorm = 0.0) or IsNan(VectorNorm) or IsInfinite(VectorNorm) then
      raise EDenseMatrixError.CreateFmt(
        'FactorComplexGeneralizedSchur: could not normalize eigenvector %d.',
        [J]);
    for I := 0 to FSize - 1 do
      FTransformEigenvectors[I, J] :=
        (FTransformEigenvectors[I, J] / ColumnScale) / VectorNorm;
  end;
  FZ := SchurQ;
  CZ := Multiply(C, FZ);
  QR := FactorQR(CZ);
  if QR.NumericalRank <> FSize then
    raise EDenseMatrixError.Create(
      'FactorComplexGeneralizedSchur: shifted right-vector factor is rank deficient.');
  FQ := QR.Q;
  R := QR.R;
  Product := Multiply(R, SchurT);
  FS := TDenseComplexMatrix.Zeros(FSize, FSize);
  FT := TDenseComplexMatrix.Zeros(FSize, FSize);
  for I := 0 to FSize - 1 do
    for J := 0 to FSize - 1 do
    begin
      FS[I, J] := (R[I, J] - Gamma * Product[I, J]) * Scale;
      FT[I, J] := Product[I, J] * Scale;
    end;

  { Make each diagonal of T nonnegative real by a unit-modulus column phase. }
  for J := 0 to FSize - 1 do
  begin
    Magnitude := FT[J, J].Magnitude;
    if Magnitude > 0.0 then
    begin
      Phase := FT[J, J].Conjugate / Magnitude;
      for I := 0 to FSize - 1 do
      begin
        FS[I, J] := FS[I, J] * Phase;
        FT[I, J] := FT[I, J] * Phase;
        FZ[I, J] := FZ[I, J] * Phase;
      end;
      FT[J, J] := TComplex.Create(Magnitude, 0.0);
    end;
  end;
  for I := 0 to FSize - 1 do
    for J := 0 to FSize - 1 do
      if not FS[I, J].IsFinite or not FT[I, J].IsFinite or
         not FQ[I, J].IsFinite or not FZ[I, J].IsFinite then
        raise EDenseMatrixError.CreateFmt(
          'FactorComplexGeneralizedSchur: non-finite factor at [%d,%d].',
          [I, J]);

  SetLength(FAlpha, FSize);
  SetLength(FBeta, FSize);
  for I := 0 to FSize - 1 do
  begin
    Mu := SchurT[I, I];
    AlphaValue := TComplex.One - Gamma * Mu;
    BetaValue := Mu;
    Magnitude := BetaValue.Magnitude;
    if Magnitude > 0.0 then
    begin
      Phase := BetaValue.Conjugate / Magnitude;
      AlphaValue := AlphaValue * Phase;
      BetaValue := BetaValue * Phase;
    end
    else
      AlphaValue := TComplex.One;
    PairScale := Max(AlphaValue.Magnitude, BetaValue.Magnitude);
    if (PairScale = 0.0) or IsNan(PairScale) or IsInfinite(PairScale) then
      raise EDenseMatrixError.Create(
        'FactorComplexGeneralizedSchur: indeterminate or non-finite generalized eigenvalue.');
    FAlpha[I] := AlphaValue / PairScale;
    FBeta[I] := BetaValue / PairScale;
  end;
end;

constructor TDenseComplexGeneralizedSchur.Create(const A, B: IDenseComplexMatrix;
  const MaxIterations: SizeInt);
begin
  inherited Create;
  Factor(A, B, MaxIterations);
end;

function TDenseComplexGeneralizedSchur.GetSize: SizeInt;
begin
  Result := FSize;
end;

function TDenseComplexGeneralizedSchur.GetQ: IDenseComplexMatrix;
begin
  Result := FQ.Clone;
end;

function TDenseComplexGeneralizedSchur.GetS: IDenseComplexMatrix;
begin
  Result := FS.Clone;
end;

function TDenseComplexGeneralizedSchur.GetZ: IDenseComplexMatrix;
begin
  Result := FZ.Clone;
end;

function TDenseComplexGeneralizedSchur.GetT: IDenseComplexMatrix;
begin
  Result := FT.Clone;
end;

function TDenseComplexGeneralizedSchur.GetAlpha: TComplexArray;
var
  I: SizeInt;
begin
  Result := nil;
  SetLength(Result, Length(FAlpha));
  for I := 0 to High(FAlpha) do Result[I] := FAlpha[I];
end;

function TDenseComplexGeneralizedSchur.GetBeta: TComplexArray;
var
  I: SizeInt;
begin
  Result := nil;
  SetLength(Result, Length(FBeta));
  for I := 0 to High(FBeta) do Result[I] := FBeta[I];
end;

function TDenseComplexGeneralizedSchur.GetIterations: SizeInt;
begin
  Result := FIterations;
end;

procedure TDenseComplexGeneralizedEigen.Factor(const A, B: IDenseComplexMatrix;
  const MaxIterations: SizeInt);
var
  SchurImpl: TDenseComplexGeneralizedSchur;
  N, I, J, K: SizeInt;
  Scale, NormA, NormB, VectorNorm, ResidualNorm, Denominator: Double;
  AV, BV, Residual: TComplex;
  Components: array of Double;
begin
  SchurImpl := TDenseComplexGeneralizedSchur.Create(A, B, MaxIterations);
  FSchur := SchurImpl;
  FVectors := SchurImpl.FTransformEigenvectors.Clone;
  N := FSchur.Size;
  Scale := 0.0;
  for I := 0 to N - 1 do
    for J := 0 to N - 1 do
      Scale := Max(Scale, Max(A[I, J].Magnitude, B[I, J].Magnitude));
  NormA := 0.0;
  NormB := 0.0;
  for I := 0 to N - 1 do
    for J := 0 to N - 1 do
    begin
      NormA := NormA + Sqr(A[I, J].Magnitude / Scale);
      NormB := NormB + Sqr(B[I, J].Magnitude / Scale);
    end;
  NormA := Sqrt(NormA);
  NormB := Sqrt(NormB);
  SetLength(FResiduals, N);
  SetLength(Components, 2 * N);
  for K := 0 to N - 1 do
  begin
    VectorNorm := 0.0;
    for J := 0 to N - 1 do
      VectorNorm := VectorNorm + FVectors[J, K].SqrMagnitude;
    VectorNorm := Sqrt(VectorNorm);
    for I := 0 to N - 1 do
    begin
      AV := TComplex.Zero;
      BV := TComplex.Zero;
      for J := 0 to N - 1 do
      begin
        AV := AV + A[I, J] / Scale * FVectors[J, K];
        BV := BV + B[I, J] / Scale * FVectors[J, K];
      end;
      Residual := FSchur.Beta[K] * AV - FSchur.Alpha[K] * BV;
      Components[2 * I] := Residual.Re;
      Components[2 * I + 1] := Residual.Im;
    end;
    ResidualNorm := ScaledNorm(Components);
    Denominator := (FSchur.Beta[K].Magnitude * NormA +
      FSchur.Alpha[K].Magnitude * NormB) * VectorNorm;
    if Denominator = 0.0 then
    begin
      if ResidualNorm <> 0.0 then
        raise EDenseMatrixError.CreateFmt(
          'FactorComplexGeneralizedEigen: zero residual denominator at %d.',
          [K]);
      FResiduals[K] := 0.0;
    end
    else
      FResiduals[K] := ResidualNorm / Denominator;
  end;
end;

constructor TDenseComplexGeneralizedEigen.Create(const A, B: IDenseComplexMatrix;
  const MaxIterations: SizeInt);
begin
  inherited Create;
  Factor(A, B, MaxIterations);
end;

function TDenseComplexGeneralizedEigen.GetSize: SizeInt;
begin
  Result := FSchur.Size;
end;

function TDenseComplexGeneralizedEigen.GetAlpha: TComplexArray;
begin
  Result := FSchur.Alpha;
end;

function TDenseComplexGeneralizedEigen.GetBeta: TComplexArray;
begin
  Result := FSchur.Beta;
end;

function TDenseComplexGeneralizedEigen.GetRightEigenvectors: IDenseComplexMatrix;
begin
  Result := FVectors.Clone;
end;

function TDenseComplexGeneralizedEigen.GetResiduals: TDoubleArray;
var
  I: SizeInt;
begin
  Result := nil;
  SetLength(Result, Length(FResiduals));
  for I := 0 to High(FResiduals) do Result[I] := FResiduals[I];
end;

function TDenseComplexGeneralizedEigen.GetIterations: SizeInt;
begin
  Result := FSchur.Iterations;
end;

function TDenseComplexGeneralizedEigen.GetConverged: Boolean;
begin
  Result := True;
end;

function FactorComplexGeneralizedSchur(const A, B: IDenseComplexMatrix;
  const MaxIterations: SizeInt): IDenseComplexGeneralizedSchur;
begin
  Result := TDenseComplexGeneralizedSchur.Create(A, B, MaxIterations);
end;

function FactorComplexGeneralizedEigen(const A, B: IDenseComplexMatrix;
  const MaxIterations: SizeInt): IDenseComplexGeneralizedEigen;
begin
  Result := TDenseComplexGeneralizedEigen.Create(A, B, MaxIterations);
end;

end.
