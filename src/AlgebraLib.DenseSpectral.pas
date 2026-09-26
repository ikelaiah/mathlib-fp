unit AlgebraLib.DenseSpectral;

{-----------------------------------------------------------------------------
 AlgebraLib.DenseSpectral

 Dense nonsymmetric spectral reductions for mathlib-fp.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  MathBase.Complex, AlgebraLib.DenseMatrices;

type
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

function ReduceHessenberg(const A: IDenseDoubleMatrix):
  IDenseDoubleHessenberg; overload;
function ReduceHessenberg(const A: IDenseComplexMatrix):
  IDenseComplexHessenberg; overload;

implementation

uses
  Math, SysUtils;

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

end.
