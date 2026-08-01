unit AlgebraLib.PartialEigensystems;

{-----------------------------------------------------------------------------
 AlgebraLib.PartialEigensystems

 Portable restarted Lanczos and Arnoldi baselines for selected eigenpairs.
 Both methods target largest-magnitude eigenvalues only. There is no shift-
 invert path in 1.9, so interior and nearest-shift targets are explicitly not
 represented by this API.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, Math,
  MathBase.SharedTypes, MathBase.Complex, MathBase.Iteration,
  AlgebraLib.DenseMatrices, AlgebraLib.DenseDecompositions,
  AlgebraLib.SparseMatrices,
  AlgebraLib.LinearOperators;

type
  EPartialEigensystemError = class(Exception);

  TSpectralTarget = (stLargestMagnitude);
  TSpectralMethod = (smRestartedLanczos, smRestartedArnoldi);

  TSpectralOptions = record
    EigenpairCount: SizeInt;
    KrylovDimension: SizeInt;
    MaximumRestarts: SizeInt;
    Tolerance: Double;
    BreakdownTolerance: Double;
    StartingSeed: QWord;
    Target: TSpectralTarget;
    class function Default: TSpectralOptions; static;
  end;

  TSpectralResult = record
    Method: TSpectralMethod;
    Status: TIterationStatus;
    Eigenvalues: TComplexArray;
    Eigenvectors: IDenseComplexMatrix;
    ResidualNorms: TDoubleArray;
    ConvergedCount: SizeInt;
    RestartCount: SizeInt;
    ProductCount: SizeInt;
    StartingSeed: QWord;
  end;

  TComplexRows = array of TComplexArray;

  { Small projected general eigensolver used by Arnoldi. It performs shifted
    complex QR and triangular back-substitution. }
  TSmallComplexEigen = class
  public
    class procedure Solve(const Matrix: TComplexRows;
      out Eigenvalues: TComplexArray;
      out Eigenvectors: TComplexRows;
      const Tolerance: Double = 1.0e-13;
      const MaximumIterations: SizeInt = 4000); static;
  end;

  generic TSpectralVector<T> = array of T;
  generic TSpectralVectors<T> = array of specialize TSpectralVector<T>;

  generic TPartialEigenSolver<T> = class
  private
    type
      TVector = specialize TSpectralVector<T>;
      TVectors = specialize TSpectralVectors<T>;
      TOperator = specialize ILinearOperator<T>;
      TDense = specialize IDenseMatrix<T>;
      PSingleValue = ^Single;
      PDoubleValue = ^Double;
      PSingleComplexValue = ^TSingleComplex;
      PComplexValue = ^TComplex;
    class function CreateDense(const Rows, Cols: SizeInt): TDense; static;
    class function ScalarToComplex(const Value: T): TComplex; static;
    class function ComplexToScalar(const Value: TComplex): T; static;
    class function Dot(const A, B: TVector; const N: SizeInt): T; static;
    class function Norm2(const A: TVector; const N: SizeInt): Double; static;
    class procedure Normalize(var A: TVector; const N: SizeInt;
      const BreakdownTolerance: Double); static;
    class procedure Orthogonalize(var A: TVector;
      const Basis: TVectors; const Count, N: SizeInt); static;
    class procedure Apply(const OperatorValue: TOperator;
      const Input: TVector; var Output: TVector;
      const DenseInput, DenseOutput: TDense;
      var ProductCount: SizeInt); static;
    class function NextRandom(var State: QWord): Double; static;
    class procedure StartingVector(var VectorValue: TVector;
      const N: SizeInt; var State: QWord); static;
    class procedure Validate(const OperatorValue: TOperator;
      const Options: TSpectralOptions; const Hermitian: Boolean); static;
    class function ComplexVectorToTyped(const Values: TComplexArray;
      const N: SizeInt): TVector; static;
    class function TypedVectorToComplex(const Values: TVector;
      const N: SizeInt): TComplexArray; static;
    class function ResidualNorm(const OperatorValue: TOperator;
      const VectorValue: TComplexArray; const Eigenvalue: TComplex;
      const DenseInput, DenseOutput: TDense;
      var ProductCount: SizeInt): Double; static;
  public
    class function Lanczos(const OperatorValue: TOperator;
      const Options: TSpectralOptions): TSpectralResult; static;
    class function Arnoldi(const OperatorValue: TOperator;
      const Options: TSpectralOptions): TSpectralResult; static;
  end;

  TSinglePartialEigenSolver = specialize TPartialEigenSolver<Single>;
  TDoublePartialEigenSolver = specialize TPartialEigenSolver<Double>;
  TSingleComplexPartialEigenSolver =
    specialize TPartialEigenSolver<TSingleComplex>;
  TComplexPartialEigenSolver = specialize TPartialEigenSolver<TComplex>;

implementation

class function TSpectralOptions.Default: TSpectralOptions;
begin
  Result.EigenpairCount := 1;
  Result.KrylovDimension := 20;
  Result.MaximumRestarts := 20;
  Result.Tolerance := 1.0e-8;
  Result.BreakdownTolerance := 1.0e-14;
  Result.StartingSeed := QWord($4D595DF4D0F33173);
  Result.Target := stLargestMagnitude;
end;

class procedure TSmallComplexEigen.Solve(const Matrix: TComplexRows;
  out Eigenvalues: TComplexArray; out Eigenvectors: TComplexRows;
  const Tolerance: Double; const MaximumIterations: SizeInt);
var
  A, Q, R, Z, NewA, NewZ: TComplexRows;
  V, Y: TComplexArray;
  N, I, J, K, Iteration: SizeInt;
  Shift, Value, Sum: TComplex;
  VectorNorm, OffDiagonal: Double;
begin
  N := Length(Matrix);
  SetLength(A, N);
  SetLength(Q, N);
  SetLength(R, N);
  SetLength(Z, N);
  SetLength(NewA, N);
  SetLength(NewZ, N);
  for I := 0 to N - 1 do
  begin
    if Length(Matrix[I]) <> N then
      raise EPartialEigensystemError.Create(
        'Projected Arnoldi matrix must be square.');
    SetLength(A[I], N);
    SetLength(Q[I], N);
    SetLength(R[I], N);
    SetLength(Z[I], N);
    SetLength(NewA[I], N);
    SetLength(NewZ[I], N);
    for J := 0 to N - 1 do
    begin
      A[I][J] := Matrix[I][J];
      if I = J then Z[I][J] := TComplex.One
      else Z[I][J] := TComplex.Zero;
    end;
  end;
  SetLength(V, N);
  for Iteration := 0 to MaximumIterations - 1 do
  begin
    OffDiagonal := 0.0;
    for I := 1 to N - 1 do
      for J := 0 to I - 1 do
        OffDiagonal := OffDiagonal + A[I][J].SqrMagnitude;
    if Sqrt(OffDiagonal) <= Tolerance then Break;
    Shift := A[N - 1][N - 1];
    for I := 0 to N - 1 do
      for J := 0 to N - 1 do
      begin
        Q[I][J] := TComplex.Zero;
        R[I][J] := TComplex.Zero;
      end;
    for J := 0 to N - 1 do
    begin
      for I := 0 to N - 1 do
      begin
        V[I] := A[I][J];
        if I = J then V[I] := V[I] - Shift;
      end;
      for K := 0 to J - 1 do
      begin
        Value := TComplex.Zero;
        for I := 0 to N - 1 do
          Value := Value + Q[I][K].Conjugate * V[I];
        R[K][J] := Value;
        for I := 0 to N - 1 do V[I] := V[I] - Value * Q[I][K];
      end;
      VectorNorm := 0.0;
      for I := 0 to N - 1 do
        VectorNorm := VectorNorm + V[I].SqrMagnitude;
      VectorNorm := Sqrt(VectorNorm);
      if VectorNorm <= Tolerance * 1.0e-3 then
      begin
        for I := 0 to N - 1 do
          if I = J then V[I] := TComplex.One
          else V[I] := TComplex.Zero;
        for K := 0 to J - 1 do
        begin
          Value := TComplex.Zero;
          for I := 0 to N - 1 do
            Value := Value + Q[I][K].Conjugate * V[I];
          for I := 0 to N - 1 do V[I] := V[I] - Value * Q[I][K];
        end;
        VectorNorm := 0.0;
        for I := 0 to N - 1 do
          VectorNorm := VectorNorm + V[I].SqrMagnitude;
        VectorNorm := Sqrt(VectorNorm);
      end;
      R[J][J] := TComplex.Create(VectorNorm, 0.0);
      if VectorNorm > 0.0 then
        for I := 0 to N - 1 do Q[I][J] := V[I] / VectorNorm;
    end;
    for I := 0 to N - 1 do
      for J := 0 to N - 1 do
      begin
        Sum := TComplex.Zero;
        for K := 0 to N - 1 do Sum := Sum + R[I][K] * Q[K][J];
        NewA[I][J] := Sum;
        if I = J then NewA[I][J] := NewA[I][J] + Shift;
        Sum := TComplex.Zero;
        for K := 0 to N - 1 do Sum := Sum + Z[I][K] * Q[K][J];
        NewZ[I][J] := Sum;
      end;
    for I := 0 to N - 1 do
      for J := 0 to N - 1 do
      begin
        A[I][J] := NewA[I][J];
        Z[I][J] := NewZ[I][J];
      end;
  end;
  SetLength(Eigenvalues, N);
  SetLength(Eigenvectors, N);
  SetLength(Y, N);
  for I := 0 to N - 1 do SetLength(Eigenvectors[I], N);
  for K := 0 to N - 1 do
  begin
    Eigenvalues[K] := A[K][K];
    for I := 0 to N - 1 do Y[I] := TComplex.Zero;
    Y[K] := TComplex.One;
    for I := K - 1 downto 0 do
    begin
      Sum := TComplex.Zero;
      for J := I + 1 to K do Sum := Sum + A[I][J] * Y[J];
      Value := A[I][I] - Eigenvalues[K];
      if Value.Magnitude <= Tolerance then
        Value := TComplex.Create(Tolerance, 0.0);
      Y[I] := -Sum / Value;
    end;
    VectorNorm := 0.0;
    for I := 0 to N - 1 do
    begin
      Sum := TComplex.Zero;
      for J := 0 to N - 1 do Sum := Sum + Z[I][J] * Y[J];
      Eigenvectors[I][K] := Sum;
      VectorNorm := VectorNorm + Sum.SqrMagnitude;
    end;
    VectorNorm := Sqrt(VectorNorm);
    if VectorNorm > 0.0 then
      for I := 0 to N - 1 do
        Eigenvectors[I][K] := Eigenvectors[I][K] / VectorNorm;
  end;
end;

class function TPartialEigenSolver.CreateDense(
  const Rows, Cols: SizeInt): TDense;
begin
  case specialize TLinearScalar<T>.Kind of
    sskSingle:
      Result := specialize DenseInterfaceCast<Single, T>(
        TDenseSingleMatrix.Zeros(Rows, Cols));
    sskDouble:
      Result := specialize DenseInterfaceCast<Double, T>(
        TDenseDoubleMatrix.Zeros(Rows, Cols));
    sskSingleComplex:
      Result := specialize DenseInterfaceCast<TSingleComplex, T>(
        TDenseSingleComplexMatrix.Zeros(Rows, Cols));
  else
    Result := specialize DenseInterfaceCast<TComplex, T>(
      TDenseComplexMatrix.Zeros(Rows, Cols));
  end;
end;

class function TPartialEigenSolver.ScalarToComplex(
  const Value: T): TComplex;
begin
  case specialize TLinearScalar<T>.Kind of
    sskSingle:
      Result := TComplex.Create(PSingleValue(@Value)^, 0.0);
    sskDouble:
      Result := TComplex.Create(PDoubleValue(@Value)^, 0.0);
    sskSingleComplex:
      Result := ToComplex(PSingleComplexValue(@Value)^);
  else
    Result := PComplexValue(@Value)^;
  end;
end;

class function TPartialEigenSolver.ComplexToScalar(
  const Value: TComplex): T;
begin
  Result := Default(T);
  case specialize TLinearScalar<T>.Kind of
    sskSingle:
      PSingleValue(@Result)^ := Value.Re;
    sskDouble:
      PDoubleValue(@Result)^ := Value.Re;
    sskSingleComplex:
      PSingleComplexValue(@Result)^ := ToSingleComplex(Value);
  else
    PComplexValue(@Result)^ := Value;
  end;
end;

class function TPartialEigenSolver.Dot(
  const A, B: TVector; const N: SizeInt): T;
var
  I: SizeInt;
begin
  Result := specialize TLinearScalar<T>.Zero;
  for I := 0 to N - 1 do
    Result := Result +
      specialize TLinearScalar<T>.Conjugate(A[I]) * B[I];
end;

class function TPartialEigenSolver.Norm2(
  const A: TVector; const N: SizeInt): Double;
var
  I: SizeInt;
begin
  Result := 0.0;
  for I := 0 to N - 1 do
    Result := Result + specialize TLinearScalar<T>.AbsSquared(A[I]);
  Result := Sqrt(Result);
end;

class procedure TPartialEigenSolver.Normalize(var A: TVector;
  const N: SizeInt; const BreakdownTolerance: Double);
var
  I: SizeInt;
  VectorNorm: Double;
  Scale: T;
begin
  VectorNorm := Norm2(A, N);
  if VectorNorm <= BreakdownTolerance then
    raise EPartialEigensystemError.Create(
      'Partial eigensolver: starting or restart vector has zero norm.');
  Scale := specialize TLinearScalar<T>.FromDouble(1.0 / VectorNorm);
  for I := 0 to N - 1 do A[I] := Scale * A[I];
end;

class procedure TPartialEigenSolver.Orthogonalize(var A: TVector;
  const Basis: TVectors; const Count, N: SizeInt);
var
  I, J: SizeInt;
  Coefficient: T;
begin
  for I := 0 to Count - 1 do
  begin
    Coefficient := Dot(Basis[I], A, N);
    for J := 0 to N - 1 do
      A[J] := A[J] - Coefficient * Basis[I][J];
  end;
end;

class procedure TPartialEigenSolver.Apply(const OperatorValue: TOperator;
  const Input: TVector; var Output: TVector;
  const DenseInput, DenseOutput: TDense; var ProductCount: SizeInt);
var
  I: SizeInt;
begin
  for I := 0 to OperatorValue.Cols - 1 do DenseInput[I, 0] := Input[I];
  OperatorValue.Apply(DenseInput, DenseOutput);
  for I := 0 to OperatorValue.Rows - 1 do Output[I] := DenseOutput[I, 0];
  Inc(ProductCount);
end;

class function TPartialEigenSolver.NextRandom(var State: QWord): Double;
begin
  State := State xor (State shl 13);
  State := State xor (State shr 7);
  State := State xor (State shl 17);
  Result := (Double(State shr 11) / 9007199254740992.0) * 2.0 - 1.0;
end;

class procedure TPartialEigenSolver.StartingVector(var VectorValue: TVector;
  const N: SizeInt; var State: QWord);
var
  I: SizeInt;
  Value: TComplex;
begin
  if State = 0 then State := QWord($9E3779B97F4A7C15);
  for I := 0 to N - 1 do
  begin
    Value := TComplex.Create(NextRandom(State), 0.0);
    if specialize TLinearScalar<T>.Kind in
       [sskSingleComplex, sskComplex] then
      Value.Im := NextRandom(State);
    VectorValue[I] := ComplexToScalar(Value);
  end;
end;

class procedure TPartialEigenSolver.Validate(const OperatorValue: TOperator;
  const Options: TSpectralOptions; const Hermitian: Boolean);
begin
  if OperatorValue = nil then
    raise EPartialEigensystemError.Create(
      'Partial eigensolver: operator must not be nil.');
  if OperatorValue.Rows <> OperatorValue.Cols then
    raise EPartialEigensystemError.Create(
      'Partial eigensolver: operator must be square.');
  if (Options.EigenpairCount <= 0) or
     (Options.EigenpairCount > OperatorValue.Rows) then
    raise EPartialEigensystemError.Create(
      'Partial eigensolver: eigenpair count must be in [1,n].');
  if (Options.KrylovDimension <= Options.EigenpairCount) or
     (Options.KrylovDimension > OperatorValue.Rows) then
    raise EPartialEigensystemError.Create(
      'Partial eigensolver: Krylov dimension must exceed requested count and not exceed n.');
  if Options.MaximumRestarts <= 0 then
    raise EPartialEigensystemError.Create(
      'Partial eigensolver: maximum restarts must be positive.');
  if IsNan(Options.Tolerance) or IsInfinite(Options.Tolerance) or
     (Options.Tolerance <= 0.0) or
     IsNan(Options.BreakdownTolerance) or
     IsInfinite(Options.BreakdownTolerance) or
     (Options.BreakdownTolerance < 0.0) then
    raise EPartialEigensystemError.Create(
      'Partial eigensolver: tolerances must be finite and valid.');
  if Options.Target <> stLargestMagnitude then
    raise EPartialEigensystemError.Create(
      'Partial eigensolver: only largest-magnitude targeting is supported.');
  if Hermitian and (OperatorValue.Rows = 0) then
    raise EPartialEigensystemError.Create(
      'Lanczos: empty operators have no selected eigenpairs.');
end;

class function TPartialEigenSolver.ComplexVectorToTyped(
  const Values: TComplexArray; const N: SizeInt): TVector;
var
  I: SizeInt;
begin
  Result := nil;
  SetLength(Result, N);
  for I := 0 to N - 1 do Result[I] := ComplexToScalar(Values[I]);
end;

class function TPartialEigenSolver.TypedVectorToComplex(
  const Values: TVector; const N: SizeInt): TComplexArray;
var
  I: SizeInt;
begin
  Result := nil;
  SetLength(Result, N);
  for I := 0 to N - 1 do Result[I] := ScalarToComplex(Values[I]);
end;

class function TPartialEigenSolver.ResidualNorm(
  const OperatorValue: TOperator; const VectorValue: TComplexArray;
  const Eigenvalue: TComplex; const DenseInput, DenseOutput: TDense;
  var ProductCount: SizeInt): Double;
var
  TypedInput, TypedOutput: TVector;
  I, N: SizeInt;
  Applied, Difference: TComplex;
begin
  N := OperatorValue.Rows;
  SetLength(TypedInput, N);
  SetLength(TypedOutput, N);
  if specialize TLinearScalar<T>.Kind in
     [sskSingleComplex, sskComplex] then
  begin
    for I := 0 to N - 1 do TypedInput[I] := ComplexToScalar(VectorValue[I]);
    Apply(OperatorValue, TypedInput, TypedOutput,
      DenseInput, DenseOutput, ProductCount);
    Result := 0.0;
    for I := 0 to N - 1 do
    begin
      Difference := ScalarToComplex(TypedOutput[I]) -
        Eigenvalue * VectorValue[I];
      Result := Result + Difference.SqrMagnitude;
    end;
  end
  else
  begin
    for I := 0 to N - 1 do
      TypedInput[I] := specialize TLinearScalar<T>.FromDouble(
        VectorValue[I].Re);
    Apply(OperatorValue, TypedInput, TypedOutput,
      DenseInput, DenseOutput, ProductCount);
    Result := 0.0;
    for I := 0 to N - 1 do
    begin
      Applied := TComplex.Create(
        specialize TLinearScalar<T>.RealPart(TypedOutput[I]), 0.0);
      Difference := Applied - Eigenvalue *
        TComplex.Create(VectorValue[I].Re, 0.0);
      Result := Result + Difference.SqrMagnitude;
    end;
    for I := 0 to N - 1 do
      TypedInput[I] := specialize TLinearScalar<T>.FromDouble(
        VectorValue[I].Im);
    Apply(OperatorValue, TypedInput, TypedOutput,
      DenseInput, DenseOutput, ProductCount);
    for I := 0 to N - 1 do
    begin
      Applied := TComplex.Create(0.0,
        specialize TLinearScalar<T>.RealPart(TypedOutput[I]));
      Difference := Applied - Eigenvalue *
        TComplex.Create(0.0, VectorValue[I].Im);
      Result := Result + Difference.SqrMagnitude;
    end;
  end;
  Result := Sqrt(Result);
end;

class function TPartialEigenSolver.Lanczos(
  const OperatorValue: TOperator;
  const Options: TSpectralOptions): TSpectralResult;
var
  Basis, Locked: TVectors;
  QPrevious, W, Candidate, Start: TVector;
  Alpha, Beta: TDoubleArray;
  Projected: IDenseDoubleMatrix;
  Factor: IDenseDoubleSymmetricEigen;
  ProjectedValues: TDoubleArray;
  ProjectedVectors: IDenseDoubleMatrix;
  DenseInput, DenseOutput: TDense;
  State: QWord;
  PairIndex, RestartIndex, J, I, Dimension, Best: SizeInt;
  AlphaScalar, Coefficient: T;
  BetaPrevious, Residual: Double;
  CandidateComplex: TComplexArray;
  Converged: Boolean;
begin
  Validate(OperatorValue, Options, True);
  Result.Method := smRestartedLanczos;
  Result.Status := isUnknown;
  Result.StartingSeed := Options.StartingSeed;
  Result.ProductCount := 0;
  Result.RestartCount := 0;
  Result.ConvergedCount := 0;
  SetLength(Result.Eigenvalues, Options.EigenpairCount);
  SetLength(Result.ResidualNorms, Options.EigenpairCount);
  Result.Eigenvectors := TDenseComplexMatrix.Zeros(
    OperatorValue.Rows, Options.EigenpairCount);
  DenseInput := CreateDense(OperatorValue.Cols, 1);
  DenseOutput := CreateDense(OperatorValue.Rows, 1);
  SetLength(Locked, Options.EigenpairCount);
  State := Options.StartingSeed;
  for PairIndex := 0 to Options.EigenpairCount - 1 do
  begin
    SetLength(Start, OperatorValue.Rows);
    StartingVector(Start, OperatorValue.Rows, State);
    Orthogonalize(Start, Locked, PairIndex, OperatorValue.Rows);
    Normalize(Start, OperatorValue.Rows, Options.BreakdownTolerance);
    Converged := False;
    Candidate := nil;
    for RestartIndex := 0 to Options.MaximumRestarts - 1 do
    begin
      Inc(Result.RestartCount);
      Dimension := Options.KrylovDimension;
      SetLength(Basis, Dimension);
      for J := 0 to Dimension - 1 do
        SetLength(Basis[J], OperatorValue.Rows);
      SetLength(QPrevious, OperatorValue.Rows);
      SetLength(W, OperatorValue.Rows);
      SetLength(Candidate, OperatorValue.Rows);
      for I := 0 to OperatorValue.Rows - 1 do
      begin
        Basis[0][I] := Start[I];
        QPrevious[I] := specialize TLinearScalar<T>.Zero;
      end;
      SetLength(Alpha, Dimension);
      SetLength(Beta, Max(0, Dimension - 1));
      BetaPrevious := 0.0;
      for J := 0 to Dimension - 1 do
      begin
        Apply(OperatorValue, Basis[J], W,
          DenseInput, DenseOutput, Result.ProductCount);
        AlphaScalar := Dot(Basis[J], W, OperatorValue.Rows);
        Alpha[J] := specialize TLinearScalar<T>.RealPart(AlphaScalar);
        for I := 0 to OperatorValue.Rows - 1 do
          W[I] := W[I] -
            specialize TLinearScalar<T>.FromDouble(Alpha[J]) * Basis[J][I] -
            specialize TLinearScalar<T>.FromDouble(BetaPrevious) * QPrevious[I];
        Orthogonalize(W, Basis, J + 1, OperatorValue.Rows);
        Orthogonalize(W, Locked, PairIndex, OperatorValue.Rows);
        if J < Dimension - 1 then
        begin
          Beta[J] := Norm2(W, OperatorValue.Rows);
          if Beta[J] <= Options.BreakdownTolerance then
          begin
            Dimension := J + 1;
            Break;
          end;
          for I := 0 to OperatorValue.Rows - 1 do
          begin
            QPrevious[I] := Basis[J][I];
            Basis[J + 1][I] :=
              specialize TLinearScalar<T>.FromDouble(1.0 / Beta[J]) * W[I];
          end;
          BetaPrevious := Beta[J];
        end;
      end;
      Projected := TDenseDoubleMatrix.Zeros(Dimension, Dimension);
      for I := 0 to Dimension - 1 do
      begin
        Projected[I, I] := Alpha[I];
        if I < Dimension - 1 then
        begin
          Projected[I, I + 1] := Beta[I];
          Projected[I + 1, I] := Beta[I];
        end;
      end;
      Factor := FactorSymmetricEigen(Projected);
      ProjectedValues := Factor.Eigenvalues;
      ProjectedVectors := Factor.Eigenvectors;
      Best := 0;
      for I := 1 to Dimension - 1 do
        if Abs(ProjectedValues[I]) > Abs(ProjectedValues[Best]) then Best := I;
      for I := 0 to OperatorValue.Rows - 1 do
        Candidate[I] := specialize TLinearScalar<T>.Zero;
      for J := 0 to Dimension - 1 do
      begin
        Coefficient := specialize TLinearScalar<T>.FromDouble(
          ProjectedVectors[J, Best]);
        for I := 0 to OperatorValue.Rows - 1 do
          Candidate[I] := Candidate[I] + Coefficient * Basis[J][I];
      end;
      Normalize(Candidate, OperatorValue.Rows, Options.BreakdownTolerance);
      CandidateComplex := TypedVectorToComplex(
        Candidate, OperatorValue.Rows);
      Residual := ResidualNorm(OperatorValue, CandidateComplex,
        TComplex.Create(ProjectedValues[Best], 0.0),
        DenseInput, DenseOutput, Result.ProductCount);
      Result.Eigenvalues[PairIndex] :=
        TComplex.Create(ProjectedValues[Best], 0.0);
      Result.ResidualNorms[PairIndex] := Residual;
      for I := 0 to OperatorValue.Rows - 1 do
        Result.Eigenvectors[I, PairIndex] := CandidateComplex[I];
      if Residual <= Options.Tolerance *
         Max(1.0, Abs(ProjectedValues[Best])) then
      begin
        Converged := True;
        Break;
      end;
      for I := 0 to OperatorValue.Rows - 1 do Start[I] := Candidate[I];
    end;
    Locked[PairIndex] := Candidate;
    if Converged then Inc(Result.ConvergedCount);
  end;
  if Result.ConvergedCount = Options.EigenpairCount then
    Result.Status := isConverged
  else
    Result.Status := isIterationLimit;
end;

class function TPartialEigenSolver.Arnoldi(
  const OperatorValue: TOperator;
  const Options: TSpectralOptions): TSpectralResult;
var
  Basis, Locked: TVectors;
  H: array of TVector;
  Projected, ProjectedVectors: TComplexRows;
  ProjectedValues: TComplexArray;
  W, Candidate, Start: TVector;
  CandidateComplex: TComplexArray;
  DenseInput, DenseOutput: TDense;
  State: QWord;
  PairIndex, RestartIndex, I, J, K, Dimension, Best: SizeInt;
  WNorm, Residual: Double;
  Converged: Boolean;
begin
  Validate(OperatorValue, Options, False);
  Result.Method := smRestartedArnoldi;
  Result.Status := isUnknown;
  Result.StartingSeed := Options.StartingSeed;
  Result.ProductCount := 0;
  Result.RestartCount := 0;
  Result.ConvergedCount := 0;
  SetLength(Result.Eigenvalues, Options.EigenpairCount);
  SetLength(Result.ResidualNorms, Options.EigenpairCount);
  Result.Eigenvectors := TDenseComplexMatrix.Zeros(
    OperatorValue.Rows, Options.EigenpairCount);
  DenseInput := CreateDense(OperatorValue.Cols, 1);
  DenseOutput := CreateDense(OperatorValue.Rows, 1);
  SetLength(Locked, Options.EigenpairCount);
  State := Options.StartingSeed;
  for PairIndex := 0 to Options.EigenpairCount - 1 do
  begin
    SetLength(Start, OperatorValue.Rows);
    StartingVector(Start, OperatorValue.Rows, State);
    Orthogonalize(Start, Locked, PairIndex, OperatorValue.Rows);
    Normalize(Start, OperatorValue.Rows, Options.BreakdownTolerance);
    Converged := False;
    Candidate := nil;
    for RestartIndex := 0 to Options.MaximumRestarts - 1 do
    begin
      Inc(Result.RestartCount);
      Dimension := Options.KrylovDimension;
      SetLength(Basis, Dimension + 1);
      for I := 0 to Dimension do SetLength(Basis[I], OperatorValue.Rows);
      SetLength(H, Dimension + 1);
      for I := 0 to Dimension do
      begin
        SetLength(H[I], Dimension);
        for J := 0 to Dimension - 1 do
          H[I][J] := specialize TLinearScalar<T>.Zero;
      end;
      SetLength(W, OperatorValue.Rows);
      SetLength(Candidate, OperatorValue.Rows);
      for I := 0 to OperatorValue.Rows - 1 do Basis[0][I] := Start[I];
      for J := 0 to Dimension - 1 do
      begin
        Apply(OperatorValue, Basis[J], W,
          DenseInput, DenseOutput, Result.ProductCount);
        for I := 0 to J do
        begin
          H[I][J] := Dot(Basis[I], W, OperatorValue.Rows);
          for K := 0 to OperatorValue.Rows - 1 do
            W[K] := W[K] - H[I][J] * Basis[I][K];
        end;
        Orthogonalize(W, Locked, PairIndex, OperatorValue.Rows);
        WNorm := Norm2(W, OperatorValue.Rows);
        H[J + 1][J] := specialize TLinearScalar<T>.FromDouble(WNorm);
        if WNorm <= Options.BreakdownTolerance then
        begin
          Dimension := J + 1;
          Break;
        end;
        for I := 0 to OperatorValue.Rows - 1 do
          Basis[J + 1][I] :=
            specialize TLinearScalar<T>.FromDouble(1.0 / WNorm) * W[I];
      end;
      SetLength(Projected, Dimension);
      for I := 0 to Dimension - 1 do
      begin
        SetLength(Projected[I], Dimension);
        for J := 0 to Dimension - 1 do
          Projected[I][J] := ScalarToComplex(H[I][J]);
      end;
      TSmallComplexEigen.Solve(Projected,
        ProjectedValues, ProjectedVectors);
      Best := 0;
      for I := 1 to Dimension - 1 do
        if ProjectedValues[I].Magnitude >
           ProjectedValues[Best].Magnitude then Best := I;
      SetLength(CandidateComplex, OperatorValue.Rows);
      for I := 0 to OperatorValue.Rows - 1 do
      begin
        CandidateComplex[I] := TComplex.Zero;
        for J := 0 to Dimension - 1 do
          CandidateComplex[I] := CandidateComplex[I] +
            ScalarToComplex(Basis[J][I]) * ProjectedVectors[J][Best];
      end;
      WNorm := 0.0;
      for I := 0 to OperatorValue.Rows - 1 do
        WNorm := WNorm + CandidateComplex[I].SqrMagnitude;
      WNorm := Sqrt(WNorm);
      if WNorm <= Options.BreakdownTolerance then
        raise EPartialEigensystemError.Create(
          'Arnoldi: projected eigenvector has zero norm.');
      for I := 0 to OperatorValue.Rows - 1 do
        CandidateComplex[I] := CandidateComplex[I] / WNorm;
      Residual := ResidualNorm(OperatorValue, CandidateComplex,
        ProjectedValues[Best], DenseInput, DenseOutput,
        Result.ProductCount);
      Result.Eigenvalues[PairIndex] := ProjectedValues[Best];
      Result.ResidualNorms[PairIndex] := Residual;
      for I := 0 to OperatorValue.Rows - 1 do
        Result.Eigenvectors[I, PairIndex] := CandidateComplex[I];
      Candidate := ComplexVectorToTyped(
        CandidateComplex, OperatorValue.Rows);
      if Residual <= Options.Tolerance *
         Max(1.0, ProjectedValues[Best].Magnitude) then
      begin
        Converged := True;
        Break;
      end;
      for I := 0 to OperatorValue.Rows - 1 do Start[I] := Candidate[I];
      Orthogonalize(Start, Locked, PairIndex, OperatorValue.Rows);
      Normalize(Start, OperatorValue.Rows, Options.BreakdownTolerance);
    end;
    Locked[PairIndex] := Candidate;
    if Converged then Inc(Result.ConvergedCount);
  end;
  if Result.ConvergedCount = Options.EigenpairCount then
    Result.Status := isConverged
  else
    Result.Status := isIterationLimit;
end;

end.
