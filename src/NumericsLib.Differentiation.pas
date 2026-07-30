unit NumericsLib.Differentiation;

{ Scale-aware finite differences, forward automatic differentiation, and
  derivative checking. Public arrays are borrowed and results own their data. }

{$mode objfpc}{$H+}{$J-}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, Math, MathBase.SharedTypes, MathBase.Complex;

type
  EDifferentiationError = class(Exception);

  TDifferenceMethod = (dmForward, dmCentral, dmComplexStep);
  TVectorFunction = function(const X: TDoubleArray): TDoubleArray;
  TScalarVectorFunction = function(const X: TDoubleArray): Double;
  TComplexScalarVectorFunction = function(
    const X: TComplexArray): TComplex;
  TGradientFunction = function(const X: TDoubleArray): TDoubleArray;
  TDoubleMatrix = array of TDoubleArray;
  TJacobianMatrixFunction = function(
    const X: TDoubleArray): TDoubleMatrix;

  TDual = record
    Value: Double;
    Derivative: Double;
    class function Create(const AValue, ADerivative: Double): TDual; static;
    class operator +(const A, B: TDual): TDual;
    class operator -(const A, B: TDual): TDual;
    class operator -(const A: TDual): TDual;
    class operator *(const A, B: TDual): TDual;
    class operator /(const A, B: TDual): TDual;
    class operator +(const A: TDual; const B: Double): TDual;
    class operator +(const A: Double; const B: TDual): TDual;
    class operator -(const A: TDual; const B: Double): TDual;
    class operator -(const A: Double; const B: TDual): TDual;
    class operator *(const A: TDual; const B: Double): TDual;
    class operator *(const A: Double; const B: TDual): TDual;
    class operator /(const A: TDual; const B: Double): TDual;
  end;

  TDualArray = array of TDual;
  TDualFunction = function(const X: TDualArray): TDual;
  TDualVectorFunction = function(const X: TDualArray): TDualArray;

  TDerivativeCheckResult = record
    Passed: Boolean;
    WorstIndex: Integer;
    AnalyticValue: Double;
    ReferenceValue: Double;
    AbsoluteError: Double;
    RelativeError: Double;
  end;

  TJacobianCheckResult = record
    Passed: Boolean;
    WorstRow: Integer;
    WorstColumn: Integer;
    AnalyticValue: Double;
    ReferenceValue: Double;
    AbsoluteError: Double;
    RelativeError: Double;
  end;

  TDifferentiationKit = class
  public
    class function Gradient(F: TScalarVectorFunction;
      const X: TDoubleArray; Method: TDifferenceMethod = dmCentral;
      RelativeStep: Double = 0.0): TDoubleArray; static;
    class function Jacobian(F: TVectorFunction;
      const X: TDoubleArray; Method: TDifferenceMethod = dmCentral;
      RelativeStep: Double = 0.0): TDoubleMatrix; static;
    class function Hessian(F: TScalarVectorFunction;
      const X: TDoubleArray; RelativeStep: Double = 0.0): TDoubleMatrix; static;
    class function ComplexStepGradient(F: TComplexScalarVectorFunction;
      const X: TDoubleArray; Step: Double = 1E-20): TDoubleArray; static;
    class function AutoGradient(F: TDualFunction;
      const X: TDoubleArray): TDoubleArray; static;
    class function AutoJacobian(F: TDualVectorFunction;
      const X: TDoubleArray): TDoubleMatrix; static;
    class function CheckGradient(F: TScalarVectorFunction;
      Grad: TGradientFunction; const X: TDoubleArray;
      RelativeTolerance: Double = 1E-5;
      AbsoluteTolerance: Double = 1E-7): TDerivativeCheckResult; static;
    class function CheckJacobian(F: TVectorFunction;
      AnalyticJacobian: TJacobianMatrixFunction; const X: TDoubleArray;
      RelativeTolerance: Double = 1E-5;
      AbsoluteTolerance: Double = 1E-7): TJacobianCheckResult; static;
  end;

function DualSin(const X: TDual): TDual;
function DualCos(const X: TDual): TDual;
function DualExp(const X: TDual): TDual;
function DualLn(const X: TDual): TDual;
function DualSqrt(const X: TDual): TDual;
function DualPower(const X: TDual; const P: Double): TDual;
function DualTan(const X: TDual): TDual;
function DualSinh(const X: TDual): TDual;
function DualCosh(const X: TDual): TDual;
function DualTanh(const X: TDual): TDual;

implementation

const
  DoubleEpsilon = 2.2204460492503131E-16;

function IsFiniteValue(const X: Double): Boolean; inline;
begin
  Result := not IsNan(X) and not IsInfinite(X);
end;

procedure ValidateVector(const X: TDoubleArray; const Name: String;
  const AllowEmpty: Boolean = False);
var
  I: Integer;
begin
  if (not AllowEmpty) and (Length(X) = 0) then
    raise EDifferentiationError.Create(Name + ': vector must not be empty.');
  for I := 0 to High(X) do
    if not IsFiniteValue(X[I]) then
      raise EDifferentiationError.CreateFmt(
        '%s: value at index %d must be finite.', [Name, I]);
end;

function DefaultStep(const Method: TDifferenceMethod): Double; inline;
begin
  case Method of
    dmForward: Result := Sqrt(DoubleEpsilon);
    dmCentral: Result := Power(DoubleEpsilon, 1.0 / 3.0);
    dmComplexStep: Result := 1E-20;
  end;
end;

function CoordinateStep(const X, RelativeStep: Double;
  const Method: TDifferenceMethod): Double; inline;
begin
  if RelativeStep > 0 then
    Result := RelativeStep * Max(1.0, Abs(X))
  else
    Result := DefaultStep(Method) * Max(1.0, Abs(X));
end;

class function TDual.Create(const AValue, ADerivative: Double): TDual;
begin
  Result.Value := AValue;
  Result.Derivative := ADerivative;
end;

class operator TDual.+(const A, B: TDual): TDual;
begin Result := Create(A.Value + B.Value, A.Derivative + B.Derivative); end;
class operator TDual.-(const A, B: TDual): TDual;
begin Result := Create(A.Value - B.Value, A.Derivative - B.Derivative); end;
class operator TDual.-(const A: TDual): TDual;
begin Result := Create(-A.Value, -A.Derivative); end;
class operator TDual.*(const A, B: TDual): TDual;
begin Result := Create(A.Value * B.Value,
  A.Derivative * B.Value + A.Value * B.Derivative); end;
class operator TDual./(const A, B: TDual): TDual;
begin
  if B.Value = 0 then
    raise EDifferentiationError.Create('TDual division: denominator is zero.');
  Result := Create(A.Value / B.Value,
    (A.Derivative * B.Value - A.Value * B.Derivative) /
    (B.Value * B.Value));
end;
class operator TDual.+(const A: TDual; const B: Double): TDual;
begin Result := Create(A.Value + B, A.Derivative); end;
class operator TDual.+(const A: Double; const B: TDual): TDual;
begin Result := B + A; end;
class operator TDual.-(const A: TDual; const B: Double): TDual;
begin Result := Create(A.Value - B, A.Derivative); end;
class operator TDual.-(const A: Double; const B: TDual): TDual;
begin Result := Create(A - B.Value, -B.Derivative); end;
class operator TDual.*(const A: TDual; const B: Double): TDual;
begin Result := Create(A.Value * B, A.Derivative * B); end;
class operator TDual.*(const A: Double; const B: TDual): TDual;
begin Result := B * A; end;
class operator TDual./(const A: TDual; const B: Double): TDual;
begin
  if B = 0 then
    raise EDifferentiationError.Create('TDual division: denominator is zero.');
  Result := Create(A.Value / B, A.Derivative / B);
end;

function DualSin(const X: TDual): TDual;
begin Result := TDual.Create(Sin(X.Value), Cos(X.Value) * X.Derivative); end;
function DualCos(const X: TDual): TDual;
begin Result := TDual.Create(Cos(X.Value), -Sin(X.Value) * X.Derivative); end;
function DualExp(const X: TDual): TDual;
begin
  Result.Value := Exp(X.Value);
  Result.Derivative := Result.Value * X.Derivative;
end;
function DualLn(const X: TDual): TDual;
begin
  if X.Value <= 0 then
    raise EDifferentiationError.Create('DualLn: argument must be positive.');
  Result := TDual.Create(Ln(X.Value), X.Derivative / X.Value);
end;
function DualSqrt(const X: TDual): TDual;
begin
  if X.Value < 0 then
    raise EDifferentiationError.Create('DualSqrt: argument must be non-negative.');
  Result.Value := Sqrt(X.Value);
  if Result.Value = 0 then
    if X.Derivative = 0 then Result.Derivative := 0
    else raise EDifferentiationError.Create(
      'DualSqrt: derivative is singular at zero.')
  else
    Result.Derivative := X.Derivative / (2 * Result.Value);
end;
function DualPower(const X: TDual; const P: Double): TDual;
begin
  if (X.Value < 0) and (Frac(P) <> 0) then
    raise EDifferentiationError.Create(
      'DualPower: negative base requires an integer exponent.');
  Result.Value := Power(X.Value, P);
  if P = 0 then Result.Derivative := 0
  else Result.Derivative := P * Power(X.Value, P - 1) * X.Derivative;
end;
function DualTan(const X: TDual): TDual;
var
  C: Double;
begin
  C := Cos(X.Value);
  if C = 0 then
    raise EDifferentiationError.Create(
      'DualTan: derivative is singular where cosine is zero.');
  Result := TDual.Create(Tan(X.Value), X.Derivative / Sqr(C));
end;
function DualSinh(const X: TDual): TDual;
begin
  Result := TDual.Create(Sinh(X.Value), Cosh(X.Value) * X.Derivative);
end;
function DualCosh(const X: TDual): TDual;
begin
  Result := TDual.Create(Cosh(X.Value), Sinh(X.Value) * X.Derivative);
end;
function DualTanh(const X: TDual): TDual;
var
  C: Double;
begin
  C := Cosh(X.Value);
  Result := TDual.Create(Tanh(X.Value), X.Derivative / Sqr(C));
end;

class function TDifferentiationKit.Gradient(F: TScalarVectorFunction;
  const X: TDoubleArray; Method: TDifferenceMethod;
  RelativeStep: Double): TDoubleArray;
var
  XP, XM: TDoubleArray;
  I: Integer;
  H, F0, FP, FM: Double;
begin
  Result := nil;
  F0 := 0;
  if not Assigned(F) then
    raise EDifferentiationError.Create('Gradient: callback must be assigned.');
  ValidateVector(X, 'Gradient');
  if Method = dmComplexStep then
    raise EDifferentiationError.Create(
      'Gradient: dmComplexStep requires ComplexStepGradient and an explicit complex callback.');
  if (RelativeStep < 0) or not IsFiniteValue(RelativeStep) then
    raise EDifferentiationError.Create(
      'Gradient: RelativeStep must be finite and non-negative.');
  XP := Copy(X);
  XM := Copy(X);
  SetLength(Result, Length(X));
  if Method = dmForward then
  begin
    F0 := F(X);
    if not IsFiniteValue(F0) then
      raise EDifferentiationError.Create(
        'Gradient: callback returned a non-finite base value.');
  end;
  for I := 0 to High(X) do
  begin
    H := CoordinateStep(X[I], RelativeStep, Method);
    XP[I] := X[I] + H;
    FP := F(XP);
    XP[I] := X[I];
    if Method = dmCentral then
    begin
      XM[I] := X[I] - H;
      FM := F(XM);
      XM[I] := X[I];
      Result[I] := (FP - FM) / (2 * H);
      if not IsFiniteValue(FM) then
        raise EDifferentiationError.CreateFmt(
          'Gradient: callback returned non-finite value at variable %d.', [I]);
    end
    else
      Result[I] := (FP - F0) / H;
    if not IsFiniteValue(FP) or not IsFiniteValue(Result[I]) then
      raise EDifferentiationError.CreateFmt(
        'Gradient: non-finite result at variable %d.', [I]);
  end;
end;

class function TDifferentiationKit.Jacobian(F: TVectorFunction;
  const X: TDoubleArray; Method: TDifferenceMethod;
  RelativeStep: Double): TDoubleMatrix;
var
  XP, XM, F0, FP, FM: TDoubleArray;
  I, J, M: Integer;
  H: Double;
begin
  Result := nil;
  if not Assigned(F) then
    raise EDifferentiationError.Create('Jacobian: callback must be assigned.');
  ValidateVector(X, 'Jacobian');
  if Method = dmComplexStep then
    raise EDifferentiationError.Create(
      'Jacobian: dmComplexStep requires an explicit complex vector callback.');
  if (RelativeStep < 0) or not IsFiniteValue(RelativeStep) then
    raise EDifferentiationError.Create(
      'Jacobian: RelativeStep must be finite and non-negative.');
  F0 := F(X);
  ValidateVector(F0, 'Jacobian callback', True);
  M := Length(F0);
  SetLength(Result, M);
  for J := 0 to M - 1 do SetLength(Result[J], Length(X));
  XP := Copy(X);
  XM := Copy(X);
  for I := 0 to High(X) do
  begin
    H := CoordinateStep(X[I], RelativeStep, Method);
    XP[I] := X[I] + H;
    FP := F(XP);
    XP[I] := X[I];
    if Length(FP) <> M then
      raise EDifferentiationError.Create(
        'Jacobian: callback result dimension changed.');
    ValidateVector(FP, 'Jacobian callback', True);
    if Method = dmCentral then
    begin
      XM[I] := X[I] - H;
      FM := F(XM);
      XM[I] := X[I];
      if Length(FM) <> M then
        raise EDifferentiationError.Create(
          'Jacobian: callback result dimension changed.');
      ValidateVector(FM, 'Jacobian callback', True);
      for J := 0 to M - 1 do
        Result[J][I] := (FP[J] - FM[J]) / (2 * H);
    end
    else
      for J := 0 to M - 1 do
        Result[J][I] := (FP[J] - F0[J]) / H;
  end;
end;

class function TDifferentiationKit.Hessian(F: TScalarVectorFunction;
  const X: TDoubleArray; RelativeStep: Double): TDoubleMatrix;
var
  XP, XM: TDoubleArray;
  GP, GM: TDoubleArray;
  I, J: Integer;
  H: Double;
begin
  Result := nil;
  if not Assigned(F) then
    raise EDifferentiationError.Create('Hessian: callback must be assigned.');
  ValidateVector(X, 'Hessian');
  SetLength(Result, Length(X));
  for I := 0 to High(Result) do SetLength(Result[I], Length(X));
  XP := Copy(X);
  XM := Copy(X);
  for I := 0 to High(X) do
  begin
    H := CoordinateStep(X[I], RelativeStep, dmCentral);
    XP[I] := X[I] + H;
    XM[I] := X[I] - H;
    GP := Gradient(F, XP, dmCentral, RelativeStep);
    GM := Gradient(F, XM, dmCentral, RelativeStep);
    XP[I] := X[I];
    XM[I] := X[I];
    for J := 0 to High(X) do
      Result[J][I] := (GP[J] - GM[J]) / (2 * H);
  end;
  { Roundoff can make the two paths differ slightly; restore symmetry. }
  for I := 0 to High(X) do
    for J := I + 1 to High(X) do
    begin
      H := 0.5 * (Result[I][J] + Result[J][I]);
      Result[I][J] := H;
      Result[J][I] := H;
    end;
end;

class function TDifferentiationKit.ComplexStepGradient(
  F: TComplexScalarVectorFunction; const X: TDoubleArray;
  Step: Double): TDoubleArray;
var
  CX: TComplexArray;
  BaseValue, Value: TComplex;
  I, J: Integer;
begin
  Result := nil;
  if not Assigned(F) then
    raise EDifferentiationError.Create(
      'ComplexStepGradient: callback must be assigned.');
  ValidateVector(X, 'ComplexStepGradient');
  if (Step <= 0) or not IsFiniteValue(Step) then
    raise EDifferentiationError.Create(
      'ComplexStepGradient: Step must be finite and positive.');
  SetLength(CX, Length(X));
  for I := 0 to High(X) do
    CX[I] := TComplex.Create(X[I], 0);
  BaseValue := F(CX);
  if not BaseValue.IsFinite then
    raise EDifferentiationError.Create(
      'ComplexStepGradient: callback returned a non-finite base value.');
  if Abs(BaseValue.Im) > 64 * DoubleEpsilon *
      Max(1.0, Abs(BaseValue.Re)) then
    raise EDifferentiationError.Create(
      'ComplexStepGradient: callback must be real-valued on real inputs.');
  SetLength(Result, Length(X));
  for I := 0 to High(X) do
  begin
    for J := 0 to High(X) do
      CX[J] := TComplex.Create(X[J], 0);
    CX[I].Im := Step;
    Value := F(CX);
    if not Value.IsFinite then
      raise EDifferentiationError.CreateFmt(
        'ComplexStepGradient: callback returned a non-finite value at variable %d.',
        [I]);
    Result[I] := (Value.Im - BaseValue.Im) / Step;
    if not IsFiniteValue(Result[I]) then
      raise EDifferentiationError.CreateFmt(
        'ComplexStepGradient: non-finite derivative at variable %d.', [I]);
  end;
end;

class function TDifferentiationKit.AutoGradient(F: TDualFunction;
  const X: TDoubleArray): TDoubleArray;
var
  DX: TDualArray;
  Y: TDual;
  I, J: Integer;
begin
  Result := nil;
  if not Assigned(F) then
    raise EDifferentiationError.Create(
      'AutoGradient: callback must be assigned.');
  ValidateVector(X, 'AutoGradient');
  SetLength(DX, Length(X));
  SetLength(Result, Length(X));
  for I := 0 to High(X) do
  begin
    for J := 0 to High(X) do
      DX[J] := TDual.Create(X[J], Ord(I = J));
    Y := F(DX);
    if not IsFiniteValue(Y.Value) or not IsFiniteValue(Y.Derivative) then
      raise EDifferentiationError.CreateFmt(
        'AutoGradient: non-finite result for seed variable %d.', [I]);
    Result[I] := Y.Derivative;
  end;
end;

class function TDifferentiationKit.AutoJacobian(F: TDualVectorFunction;
  const X: TDoubleArray): TDoubleMatrix;
var
  DX: TDualArray;
  Y: TDualArray;
  I, J, M: Integer;
begin
  Result := nil;
  if not Assigned(F) then
    raise EDifferentiationError.Create(
      'AutoJacobian: callback must be assigned.');
  ValidateVector(X, 'AutoJacobian');
  SetLength(DX, Length(X));
  M := -1;
  for I := 0 to High(X) do
  begin
    for J := 0 to High(X) do
      DX[J] := TDual.Create(X[J], Ord(I = J));
    Y := F(DX);
    if M < 0 then
    begin
      M := Length(Y);
      SetLength(Result, M);
      for J := 0 to M - 1 do
        SetLength(Result[J], Length(X));
    end
    else if Length(Y) <> M then
      raise EDifferentiationError.Create(
        'AutoJacobian: callback result dimension changed.');
    for J := 0 to M - 1 do
    begin
      if not IsFiniteValue(Y[J].Value) or
         not IsFiniteValue(Y[J].Derivative) then
        raise EDifferentiationError.CreateFmt(
          'AutoJacobian: non-finite result at row %d, seed variable %d.',
          [J, I]);
      Result[J][I] := Y[J].Derivative;
    end;
  end;
end;

class function TDifferentiationKit.CheckGradient(F: TScalarVectorFunction;
  Grad: TGradientFunction; const X: TDoubleArray;
  RelativeTolerance, AbsoluteTolerance: Double): TDerivativeCheckResult;
var
  A, N: TDoubleArray;
  I: Integer;
  Scale, Limit, RelErr: Double;
begin
  Result := Default(TDerivativeCheckResult);
  Result.WorstIndex := -1;
  if not Assigned(Grad) then
    raise EDifferentiationError.Create(
      'CheckGradient: analytic gradient must be assigned.');
  if (RelativeTolerance < 0) or (AbsoluteTolerance < 0) or
     not IsFiniteValue(RelativeTolerance) or
     not IsFiniteValue(AbsoluteTolerance) then
    raise EDifferentiationError.Create(
      'CheckGradient: tolerances must be finite and non-negative.');
  ValidateVector(X, 'CheckGradient');
  A := Grad(X);
  if Length(A) <> Length(X) then
    raise EDifferentiationError.CreateFmt(
      'CheckGradient: analytic gradient length %d; expected %d.',
      [Length(A), Length(X)]);
  ValidateVector(A, 'CheckGradient analytic gradient');
  N := Gradient(F, X, dmCentral);
  Result.Passed := True;
  for I := 0 to High(X) do
  begin
    Scale := Max(Abs(A[I]), Abs(N[I]));
    Limit := AbsoluteTolerance + RelativeTolerance * Scale;
    if Scale > 0 then RelErr := Abs(A[I] - N[I]) / Scale
    else RelErr := 0;
    if (Result.WorstIndex < 0) or
       (Abs(A[I] - N[I]) > Result.AbsoluteError) then
    begin
      Result.WorstIndex := I;
      Result.AnalyticValue := A[I];
      Result.ReferenceValue := N[I];
      Result.AbsoluteError := Abs(A[I] - N[I]);
      Result.RelativeError := RelErr;
    end;
    if Abs(A[I] - N[I]) > Limit then Result.Passed := False;
  end;
end;

class function TDifferentiationKit.CheckJacobian(F: TVectorFunction;
  AnalyticJacobian: TJacobianMatrixFunction; const X: TDoubleArray;
  RelativeTolerance, AbsoluteTolerance: Double): TJacobianCheckResult;
var
  A, N: TDoubleMatrix;
  I, J, ColumnCount: Integer;
  Scale, Limit, Difference, RelErr: Double;
begin
  Result := Default(TJacobianCheckResult);
  Result.WorstRow := -1;
  Result.WorstColumn := -1;
  if not Assigned(F) or not Assigned(AnalyticJacobian) then
    raise EDifferentiationError.Create(
      'CheckJacobian: function and analytic Jacobian must be assigned.');
  if (RelativeTolerance < 0) or (AbsoluteTolerance < 0) or
     not IsFiniteValue(RelativeTolerance) or
     not IsFiniteValue(AbsoluteTolerance) then
    raise EDifferentiationError.Create(
      'CheckJacobian: tolerances must be finite and non-negative.');
  ValidateVector(X, 'CheckJacobian');
  A := AnalyticJacobian(X);
  N := TDifferentiationKit.Jacobian(F, X, dmCentral);
  if Length(A) <> Length(N) then
    raise EDifferentiationError.CreateFmt(
      'CheckJacobian: analytic row count %d; expected %d.',
      [Length(A), Length(N)]);
  ColumnCount := Length(X);
  Result.Passed := True;
  for I := 0 to High(A) do
  begin
    if Length(A[I]) <> ColumnCount then
      raise EDifferentiationError.CreateFmt(
        'CheckJacobian: analytic row %d has %d columns; expected %d.',
        [I, Length(A[I]), ColumnCount]);
    ValidateVector(A[I], 'CheckJacobian analytic row', True);
    for J := 0 to ColumnCount - 1 do
    begin
      Difference := Abs(A[I][J] - N[I][J]);
      Scale := Max(Abs(A[I][J]), Abs(N[I][J]));
      Limit := AbsoluteTolerance + RelativeTolerance * Scale;
      if Scale > 0 then
        RelErr := Difference / Scale
      else
        RelErr := 0;
      if (Result.WorstRow < 0) or
         (Difference > Result.AbsoluteError) then
      begin
        Result.WorstRow := I;
        Result.WorstColumn := J;
        Result.AnalyticValue := A[I][J];
        Result.ReferenceValue := N[I][J];
        Result.AbsoluteError := Difference;
        Result.RelativeError := RelErr;
      end;
      if Difference > Limit then
        Result.Passed := False;
    end;
  end;
end;

end.
