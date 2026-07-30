unit NumericsLib.Modelling;

{ Adaptive integration, fitting, vector equations, and adaptive vector ODEs.
  All callback state is caller-owned; this unit has no mutable global state. }

{$mode objfpc}{$H+}{$J-}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, Math, MathBase.SharedTypes, MathBase.Iteration,
  MathBase.Complex, MathBase.Random, NumericsLib.Differentiation,
  AlgebraLib.DenseMatrices,
  AlgebraLib.DenseSolvers, AlgebraLib.DenseDecompositions;

type
  EModellingError = class(Exception);
  TModelMatrix = array of TDoubleArray;
  TVectorSeries = array of TDoubleArray;

  TScalarIntegrand = function(X: Double): Double;
  TMultidimensionalIntegrand = function(const X: TDoubleArray): Double;
  TProgressFunction = function(Iteration, Evaluations: Integer;
    Measure: Double): Boolean;

  TIntegrationResult = record
    Value: Double;
    ErrorEstimate: Double;
    Evaluations: Integer;
    Intervals: Integer;
    Status: TIterationStatus;
  end;

  TLinearBasisFunction = function(X: Double; BasisIndex: Integer): Double;

  TFitResult = record
    Parameters: TDoubleArray;
    Residuals: TDoubleArray;
    Covariance: TModelMatrix;
    Rank: Integer;
    DegreesOfFreedom: Integer;
    ResidualSumSquares: Double;
    RSquared: Double;
    Iterations: Integer;
    Evaluations: Integer;
    GradientNorm: Double;
    Status: TIterationStatus;
  end;

  TSplineFitResult = record
    InteriorKnots: TDoubleArray;
    Fit: TFitResult;
    function Evaluate(const X: Double): Double;
  end;

  TResidualFunction = function(const Parameters: TDoubleArray): TDoubleArray;
  TJacobianFunction = function(const Parameters: TDoubleArray): TModelMatrix;
  TRobustLoss = (rlSquared, rlHuber, rlSoftL1);

  TNonlinearFitOptions = record
    AbsoluteTolerance: Double;
    RelativeTolerance: Double;
    GradientTolerance: Double;
    InitialDamping: Double;
    MaxIterations: Integer;
    LowerBounds: TDoubleArray;
    UpperBounds: TDoubleArray;
    ParameterScales: TDoubleArray;
    Loss: TRobustLoss;
    LossScale: Double;
    CheckDerivative: Boolean;
    Progress: TProgressFunction;
    class function Defaults: TNonlinearFitOptions; static;
  end;

  TVectorEquationFunction = function(const X: TDoubleArray): TDoubleArray;
  TVectorJacobianFunction = function(const X: TDoubleArray): TModelMatrix;

  TVectorRootResult = record
    X: TDoubleArray;
    Residual: TDoubleArray;
    ResidualNorm: Double;
    StepNorm: Double;
    Iterations: Integer;
    Evaluations: Integer;
    Status: TIterationStatus;
  end;

  TPolynomialRootResult = record
    Roots: TComplexArray;
    Residuals: TDoubleArray;
    Iterations: Integer;
    Evaluations: Integer;
    Status: TIterationStatus;
  end;

  TODEVectorFunction = function(T: Double;
    const Y: TDoubleArray): TDoubleArray;
  TODEEventFunction = function(T: Double;
    const Y: TDoubleArray): Double;

  TAdaptiveODEOptions = record
    AbsoluteTolerance: Double;
    AbsoluteTolerances: TDoubleArray;
    RelativeTolerance: Double;
    InitialStep: Double;
    MinimumStep: Double;
    MaximumStep: Double;
    MaxSteps: Integer;
    Event: TODEEventFunction;
    EventDirection: Integer; { -1 falling, 0 either, +1 rising }
    Progress: TProgressFunction;
    class function Defaults: TAdaptiveODEOptions; static;
  end;

  TAdaptiveODESolution = record
    T: TDoubleArray;
    Y: TVectorSeries;
    Derivatives: TVectorSeries;
    AcceptedSteps: Integer;
    RejectedSteps: Integer;
    Evaluations: Integer;
    EventFound: Boolean;
    EventTime: Double;
    EventState: TDoubleArray;
    Status: TIterationStatus;
    function Evaluate(Time: Double): TDoubleArray;
  end;

  TModellingKit = class
  public
    class function IntegrateAdaptive(F: TScalarIntegrand; A, B: Double;
      AbsoluteTolerance: Double = 1E-10;
      RelativeTolerance: Double = 1E-8;
      MaxIntervals: Integer = 1000): TIntegrationResult; static;
    class function IntegrateImproper(F: TScalarIntegrand; A, B: Double;
      AbsoluteTolerance: Double = 1E-9;
      RelativeTolerance: Double = 1E-7;
      MaxIntervals: Integer = 2000): TIntegrationResult; static;
    class function IntegrateQuasiMonteCarlo(F: TMultidimensionalIntegrand;
      const LowerBounds, UpperBounds: TDoubleArray; Samples: Integer;
      Seed: Integer = 0): TIntegrationResult; static;
    class function IntegrateCubature(F: TMultidimensionalIntegrand;
      const LowerBounds, UpperBounds: TDoubleArray; Order: Integer = 5;
      MaxEvaluations: Integer = 1000000): TIntegrationResult; static;
    class function IntegrateMonteCarlo(F: TMultidimensionalIntegrand;
      const LowerBounds, UpperBounds: TDoubleArray; Samples: Integer;
      var Random: TLocalRandom): TIntegrationResult; static;

    class function FitLinearBasis(const X, Y: TDoubleArray;
      BasisCount: Integer; Basis: TLinearBasisFunction;
      const Weights: TDoubleArray): TFitResult; static;
    class function FitPolynomial(const X, Y: TDoubleArray; Degree: Integer;
      const Weights: TDoubleArray): TFitResult; static;
    class function FitSplineBasis(const X, Y, InteriorKnots: TDoubleArray;
      const Weights: TDoubleArray): TSplineFitResult; static;
    class function FitNonlinear(Residual: TResidualFunction;
      Jacobian: TJacobianFunction; const InitialParameters: TDoubleArray;
      const Options: TNonlinearFitOptions): TFitResult; static;
    class function FitNonlinearAuto(Residual: TDualVectorFunction;
      const InitialParameters: TDoubleArray;
      const Options: TNonlinearFitOptions): TFitResult; static;

    class function SolveSystem(F: TVectorEquationFunction;
      Jacobian: TVectorJacobianFunction; const InitialX: TDoubleArray;
      AbsoluteTolerance: Double = 1E-10;
      RelativeTolerance: Double = 1E-8;
      MaxIterations: Integer = 100;
      Progress: TProgressFunction = nil): TVectorRootResult; static;
    class function SolveSystemAuto(F: TDualVectorFunction;
      const InitialX: TDoubleArray;
      AbsoluteTolerance: Double = 1E-10;
      RelativeTolerance: Double = 1E-8;
      MaxIterations: Integer = 100;
      Progress: TProgressFunction = nil): TVectorRootResult; static;

    class function SolvePolynomial(const Coefficients: TDoubleArray;
      AbsoluteTolerance: Double = 1E-12;
      RelativeTolerance: Double = 1E-10;
      MaxIterations: Integer = 2000): TPolynomialRootResult; static;

    class function SolveODE(F: TODEVectorFunction; T0: Double;
      const Y0: TDoubleArray; T1: Double;
      const Options: TAdaptiveODEOptions): TAdaptiveODESolution; static;
  end;

implementation

const
  DoubleEpsilon = 2.2204460492503131E-16;

type
  TGKInterval = record
    A, B, Value, Error: Double;
  end;
  TGKIntervals = array of TGKInterval;

function IsFiniteValue(const X: Double): Boolean; inline;
begin Result := not IsNan(X) and not IsInfinite(X); end;

procedure ValidateVector(const X: TDoubleArray; const Name: String;
  AllowEmpty: Boolean = False);
var I: Integer;
begin
  if (not AllowEmpty) and (Length(X) = 0) then
    raise EModellingError.Create(Name + ': vector must not be empty.');
  for I := 0 to High(X) do
    if not IsFiniteValue(X[I]) then
      raise EModellingError.CreateFmt(
        '%s: value at index %d must be finite.', [Name, I]);
end;

function VectorNorm(const X: TDoubleArray): Double;
var
  I: Integer;
  Scale, SSQ, A: Double;
begin
  Scale := 0; SSQ := 1;
  for I := 0 to High(X) do
  begin
    A := Abs(X[I]);
    if A <> 0 then
      if Scale < A then begin SSQ := 1 + SSQ * Sqr(Scale / A); Scale := A; end
      else SSQ := SSQ + Sqr(A / Scale);
  end;
  if Scale = 0 then Result := 0 else Result := Scale * Sqrt(SSQ);
end;

function CopyMatrix(const A: TModelMatrix): TModelMatrix;
var I: Integer;
begin
  Result := nil;
  SetLength(Result, Length(A));
  for I := 0 to High(A) do Result[I] := Copy(A[I]);
end;

procedure ValidateMatrix(const A: TModelMatrix; Rows, Cols: Integer;
  const Name: String);
var I: Integer;
begin
  if Length(A) <> Rows then raise EModellingError.CreateFmt(
    '%s: row count %d; expected %d.', [Name, Length(A), Rows]);
  for I := 0 to Rows - 1 do
  begin
    if Length(A[I]) <> Cols then raise EModellingError.CreateFmt(
      '%s: row %d has %d columns; expected %d.',
      [Name, I, Length(A[I]), Cols]);
    ValidateVector(A[I], Name + ' row', True);
  end;
end;

function DenseFromMatrix(const A: TModelMatrix): IDenseDoubleMatrix;
var I, J: Integer;
begin
  if Length(A) = 0 then Exit(TDenseDoubleMatrix.Zeros(0, 0));
  Result := TDenseDoubleMatrix.Zeros(Length(A), Length(A[0]));
  for I := 0 to High(A) do for J := 0 to High(A[I]) do Result[I,J] := A[I][J];
end;

function DenseFromVector(const A: TDoubleArray): IDenseDoubleMatrix;
begin Result := TDenseDoubleMatrix.FromVector(A, True); end;

function VectorFromDense(const A: IDenseDoubleMatrix): TDoubleArray;
var I: Integer;
begin
  Result := nil;
  SetLength(Result, A.Rows);
  for I := 0 to A.Rows - 1 do Result[I] := A[I,0];
end;

function EvaluateScalar(F: TScalarIntegrand; X: Double;
  var Evaluations: Integer): Double;
begin
  Result := F(X); Inc(Evaluations);
  if not IsFiniteValue(Result) then raise EModellingError.CreateFmt(
    'Adaptive integration: integrand returned non-finite value at %.17g.', [X]);
end;

procedure GaussKronrod15(F: TScalarIntegrand; A, B: Double;
  var Evaluations: Integer; out Value, Error: Double);
const
  XGK: array[0..7] of Double = (
    0.991455371120812639206854697526329,
    0.949107912342758524526189684047851,
    0.864864423359769072789712788640926,
    0.741531185599394439863864773280788,
    0.586087235467691130294144838258730,
    0.405845151377397166906606412076961,
    0.207784955007898467600689403773245,
    0.0);
  WGK: array[0..7] of Double = (
    0.022935322010529224963732008058970,
    0.063092092629978553290700663189204,
    0.104790010322250183839876322541518,
    0.140653259715525918745189590510238,
    0.169004726639267902826583426598550,
    0.190350578064785409913256402421014,
    0.204432940075298892414161999234649,
    0.209482141084727828012999174891714);
  WG: array[0..3] of Double = (
    0.129484966168869693270611432679082,
    0.279705391489276667901467771423780,
    0.381830050505118944950369775488975,
    0.417959183673469387755102040816327);
var
  Center, Half, FC, F1, F2, KSum, GSum: Double;
  I: Integer;
begin
  Center := A + (B - A) / 2; Half := (B - A) / 2;
  FC := EvaluateScalar(F, Center, Evaluations);
  KSum := WGK[7] * FC; GSum := WG[3] * FC;
  for I := 0 to 6 do
  begin
    F1 := EvaluateScalar(F, Center - Half * XGK[I], Evaluations);
    F2 := EvaluateScalar(F, Center + Half * XGK[I], Evaluations);
    KSum := KSum + WGK[I] * (F1 + F2);
    case I of
      1: GSum := GSum + WG[0] * (F1 + F2);
      3: GSum := GSum + WG[1] * (F1 + F2);
      5: GSum := GSum + WG[2] * (F1 + F2);
    end;
  end;
  Value := KSum * Half;
  Error := Abs((KSum - GSum) * Half);
  Error := Max(Error, 50 * DoubleEpsilon * Abs(Value));
end;

class function TModellingKit.IntegrateAdaptive(F: TScalarIntegrand; A,
  B, AbsoluteTolerance, RelativeTolerance: Double;
  MaxIntervals: Integer): TIntegrationResult;
var
  Items: TGKIntervals;
  I, Worst: Integer;
  Mid, LV, LE, RV, RE, Tol, Sign: Double;
begin
  Result := Default(TIntegrationResult);
  if not Assigned(F) then raise EModellingError.Create(
    'IntegrateAdaptive: integrand must be assigned.');
  if not IsFiniteValue(A) or not IsFiniteValue(B) then
    raise EModellingError.Create(
      'IntegrateAdaptive: finite interval endpoints are required.');
  if (AbsoluteTolerance < 0) or (RelativeTolerance < 0) or
     (AbsoluteTolerance + RelativeTolerance <= 0) or
     not IsFiniteValue(AbsoluteTolerance) or
     not IsFiniteValue(RelativeTolerance) then
    raise EModellingError.Create(
      'IntegrateAdaptive: tolerances must be finite, non-negative, and not both zero.');
  if MaxIntervals <= 0 then raise EModellingError.Create(
    'IntegrateAdaptive: MaxIntervals must be positive.');
  if A = B then begin Result.Status := isConverged; Exit; end;
  Sign := 1;
  if B < A then begin Mid:=A; A:=B; B:=Mid; Sign:=-1; end;
  SetLength(Items, 1); Items[0].A := A; Items[0].B := B;
  GaussKronrod15(F, A, B, Result.Evaluations, Items[0].Value, Items[0].Error);
  Result.Value := Items[0].Value; Result.ErrorEstimate := Items[0].Error;
  while True do
  begin
    Tol := AbsoluteTolerance + RelativeTolerance * Abs(Result.Value);
    if Result.ErrorEstimate <= Tol then
    begin Result.Status := isConverged; Break; end;
    if Length(Items) >= MaxIntervals then
    begin
      if Result.ErrorEstimate <= 10 * Tol then Result.Status := isAcceptableLimit
      else Result.Status := isIterationLimit;
      Break;
    end;
    Worst := 0;
    for I := 1 to High(Items) do
      if Items[I].Error > Items[Worst].Error then Worst := I;
    Mid := Items[Worst].A + (Items[Worst].B - Items[Worst].A) / 2;
    if (Mid = Items[Worst].A) or (Mid = Items[Worst].B) then
    begin Result.Status := isStagnation; Break; end;
    GaussKronrod15(F, Items[Worst].A, Mid, Result.Evaluations, LV, LE);
    GaussKronrod15(F, Mid, Items[Worst].B, Result.Evaluations, RV, RE);
    Result.Value := Result.Value - Items[Worst].Value + LV + RV;
    Result.ErrorEstimate := Max(0, Result.ErrorEstimate -
      Items[Worst].Error + LE + RE);
    SetLength(Items, Length(Items) + 1);
    Items[High(Items)].A := Mid; Items[High(Items)].B := Items[Worst].B;
    Items[High(Items)].Value := RV; Items[High(Items)].Error := RE;
    Items[Worst].B := Mid; Items[Worst].Value := LV; Items[Worst].Error := LE;
  end;
  Result.Value := Sign * Result.Value;
  Result.Intervals := Length(Items);
end;

{ Improper transforms need context without global callback state. Implement the
  same bounded adaptive queue while evaluating the transformed original
  callback directly. }
type
  TImproperMode = (imBothInfinite, imRightInfinite, imLeftInfinite);

function EvaluateImproper(F: TScalarIntegrand; T, Bound: Double;
  Mode: TImproperMode; var Evaluations: Integer): Double;
var
  X, Jacobian, Angle, C, V: Double;
begin
  case Mode of
    imBothInfinite:
      begin
        Angle := Pi * (T - 0.5);
        C := Cos(Angle); X := Tan(Angle); Jacobian := Pi / (C * C);
      end;
    imRightInfinite:
      begin X := Bound + T / (1 - T); Jacobian := 1 / Sqr(1 - T); end;
  else
    begin X := Bound - T / (1 - T); Jacobian := 1 / Sqr(1 - T); end;
  end;
  V := F(X); Inc(Evaluations);
  Result := V * Jacobian;
  if not IsFiniteValue(Result) then raise EModellingError.CreateFmt(
    'IntegrateImproper: transformed integrand is non-finite at %.17g.', [X]);
end;

procedure ImproperGK15(F: TScalarIntegrand; A, B, Bound: Double;
  Mode: TImproperMode; var Evaluations: Integer; out Value, Error: Double);
const
  XGK: array[0..7] of Double = (0.9914553711208126,0.9491079123427585,
    0.8648644233597691,0.7415311855993944,0.5860872354676911,
    0.4058451513773972,0.2077849550078985,0.0);
  WGK: array[0..7] of Double = (0.02293532201052922,0.06309209262997855,
    0.1047900103222502,0.1406532597155259,0.1690047266392679,
    0.1903505780647854,0.2044329400752989,0.2094821410847278);
  WG: array[0..3] of Double = (0.1294849661688697,0.2797053914892767,
    0.3818300505051189,0.4179591836734694);
var C,H,FC,F1,F2,K,G: Double; I: Integer;
begin
  C:=A+(B-A)/2; H:=(B-A)/2;
  FC:=EvaluateImproper(F,C,Bound,Mode,Evaluations);
  K:=WGK[7]*FC; G:=WG[3]*FC;
  for I:=0 to 6 do begin
    F1:=EvaluateImproper(F,C-H*XGK[I],Bound,Mode,Evaluations);
    F2:=EvaluateImproper(F,C+H*XGK[I],Bound,Mode,Evaluations);
    K:=K+WGK[I]*(F1+F2);
    case I of 1:G:=G+WG[0]*(F1+F2);3:G:=G+WG[1]*(F1+F2);
      5:G:=G+WG[2]*(F1+F2); end;
  end;
  Value:=K*H; Error:=Max(Abs((K-G)*H),50*DoubleEpsilon*Abs(Value));
end;

class function TModellingKit.IntegrateImproper(F: TScalarIntegrand; A,
  B, AbsoluteTolerance, RelativeTolerance: Double;
  MaxIntervals: Integer): TIntegrationResult;
var
  Items: TGKIntervals;
  Mode: TImproperMode;
  Bound, Mid, LV, LE, RV, RE, Tol: Double;
  I, Worst: Integer;
begin
  Result := Default(TIntegrationResult);
  if not Assigned(F) then raise EModellingError.Create(
    'IntegrateImproper: integrand must be assigned.');
  if IsNan(A) or IsNan(B) or (A >= B) then raise EModellingError.Create(
    'IntegrateImproper: require A < B; endpoints may be infinite.');
  if IsInfinite(A) and IsInfinite(B) then begin Mode:=imBothInfinite; Bound:=0; end
  else if IsInfinite(B) then begin
    if not IsFiniteValue(A) then raise EModellingError.Create(
      'IntegrateImproper: invalid lower bound.');
    Mode:=imRightInfinite; Bound:=A;
  end
  else if IsInfinite(A) then begin
    if not IsFiniteValue(B) then raise EModellingError.Create(
      'IntegrateImproper: invalid upper bound.');
    Mode:=imLeftInfinite; Bound:=B;
  end
  else Exit(IntegrateAdaptive(F,A,B,AbsoluteTolerance,RelativeTolerance,MaxIntervals));
  if (AbsoluteTolerance < 0) or (RelativeTolerance < 0) or
     (AbsoluteTolerance + RelativeTolerance <= 0) or (MaxIntervals <= 0) then
    raise EModellingError.Create('IntegrateImproper: invalid controls.');
  SetLength(Items,1); Items[0].A:=0; Items[0].B:=1;
  ImproperGK15(F,0,1,Bound,Mode,Result.Evaluations,Items[0].Value,Items[0].Error);
  Result.Value:=Items[0].Value; Result.ErrorEstimate:=Items[0].Error;
  while True do begin
    Tol:=AbsoluteTolerance+RelativeTolerance*Abs(Result.Value);
    if Result.ErrorEstimate<=Tol then begin Result.Status:=isConverged; Break; end;
    if Length(Items)>=MaxIntervals then begin
      if Result.ErrorEstimate<=10*Tol then Result.Status:=isAcceptableLimit
      else Result.Status:=isIterationLimit; Break; end;
    Worst:=0; for I:=1 to High(Items) do
      if Items[I].Error>Items[Worst].Error then Worst:=I;
    Mid:=Items[Worst].A+(Items[Worst].B-Items[Worst].A)/2;
    if (Mid=Items[Worst].A) or (Mid=Items[Worst].B) then begin
      Result.Status:=isStagnation; Break; end;
    ImproperGK15(F,Items[Worst].A,Mid,Bound,Mode,Result.Evaluations,LV,LE);
    ImproperGK15(F,Mid,Items[Worst].B,Bound,Mode,Result.Evaluations,RV,RE);
    Result.Value:=Result.Value-Items[Worst].Value+LV+RV;
    Result.ErrorEstimate:=Max(0,Result.ErrorEstimate-Items[Worst].Error+LE+RE);
    SetLength(Items,Length(Items)+1);
    Items[High(Items)].A:=Mid; Items[High(Items)].B:=Items[Worst].B;
    Items[High(Items)].Value:=RV; Items[High(Items)].Error:=RE;
    Items[Worst].B:=Mid; Items[Worst].Value:=LV; Items[Worst].Error:=LE;
  end;
  Result.Intervals:=Length(Items);
end;

function RadicalInverse(Index, Base: Integer): Double;
var F: Double;
begin
  Result:=0; F:=1/Base;
  while Index>0 do begin Result:=Result+F*(Index mod Base);
    Index:=Index div Base; F:=F/Base; end;
end;

class function TModellingKit.IntegrateQuasiMonteCarlo(
  F: TMultidimensionalIntegrand; const LowerBounds,
  UpperBounds: TDoubleArray; Samples, Seed: Integer): TIntegrationResult;
const Primes: array[0..15] of Integer =
  (2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53);
var
  Point: TDoubleArray;
  I,J,D: Integer;
  V,Mean,M2,Delta,Volume: Double;
begin
  Result:=Default(TIntegrationResult);
  if not Assigned(F) then raise EModellingError.Create(
    'IntegrateQuasiMonteCarlo: integrand must be assigned.');
  D:=Length(LowerBounds);
  if (D=0) or (D<>Length(UpperBounds)) or (D>Length(Primes)) then
    raise EModellingError.Create(
      'IntegrateQuasiMonteCarlo: dimensions must match and be between 1 and 16.');
  if Samples<=1 then raise EModellingError.Create(
    'IntegrateQuasiMonteCarlo: Samples must exceed one.');
  SetLength(Point,D); Volume:=1; Mean:=0; M2:=0;
  for J:=0 to D-1 do begin
    if not IsFiniteValue(LowerBounds[J]) or
       not IsFiniteValue(UpperBounds[J]) or
       (LowerBounds[J]>=UpperBounds[J]) then raise EModellingError.CreateFmt(
      'IntegrateQuasiMonteCarlo: require finite lower < upper at dimension %d.',[J]);
    Volume:=Volume*(UpperBounds[J]-LowerBounds[J]);
  end;
  for I:=1 to Samples do begin
    for J:=0 to D-1 do Point[J]:=LowerBounds[J]+
      (UpperBounds[J]-LowerBounds[J])*RadicalInverse(I+Abs(Seed),Primes[J]);
    V:=F(Point); Inc(Result.Evaluations);
    if not IsFiniteValue(V) then raise EModellingError.CreateFmt(
      'IntegrateQuasiMonteCarlo: non-finite callback result at sample %d.',[I]);
    Delta:=V-Mean; Mean:=Mean+Delta/I; M2:=M2+Delta*(V-Mean);
  end;
  Result.Value:=Volume*Mean;
  Result.ErrorEstimate:=Volume*Sqrt(M2/(Samples-1)/Samples);
  Result.Intervals:=Samples; Result.Status:=isAcceptableLimit;
end;

class function TModellingKit.IntegrateCubature(
  F: TMultidimensionalIntegrand; const LowerBounds,
  UpperBounds: TDoubleArray; Order, MaxEvaluations: Integer):
  TIntegrationResult;
var
  Point,Nodes3,Weights3,Nodes5,Weights5:TDoubleArray;
  D,I,EvaluationCount:Integer;
  Required,Count3,Count5:QWord;
  Primary,Reference:Double;

  function RuleValue(const Nodes,Weights:TDoubleArray):Double;
  var
    WeightedSum:Double;

    procedure Visit(const Dimension:Integer; const Weight:Double);
    var
      NodeIndex:Integer;
      Midpoint,HalfWidth,Value:Double;
    begin
      if Dimension=D then
      begin
        Value:=F(Point);
        Inc(EvaluationCount);
        if not IsFiniteValue(Value) then
          raise EModellingError.CreateFmt(
            'IntegrateCubature: non-finite callback result at evaluation %d.',
            [EvaluationCount]);
        WeightedSum:=WeightedSum+Weight*Value;
        Exit;
      end;
      Midpoint:=0.5*(LowerBounds[Dimension]+UpperBounds[Dimension]);
      HalfWidth:=0.5*(UpperBounds[Dimension]-LowerBounds[Dimension]);
      for NodeIndex:=0 to High(Nodes) do
      begin
        Point[Dimension]:=Midpoint+HalfWidth*Nodes[NodeIndex];
        Visit(Dimension+1,Weight*HalfWidth*Weights[NodeIndex]);
      end;
    end;

  begin
    WeightedSum:=0;
    Visit(0,1);
    Result:=WeightedSum;
  end;

begin
  Result:=Default(TIntegrationResult);
  if not Assigned(F) then
    raise EModellingError.Create(
      'IntegrateCubature: integrand must be assigned.');
  D:=Length(LowerBounds);
  if (D=0) or (D<>Length(UpperBounds)) or (D>16) then
    raise EModellingError.Create(
      'IntegrateCubature: dimensions must match and be between 1 and 16.');
  if not (Order in [3,5]) then
    raise EModellingError.Create(
      'IntegrateCubature: Order must be 3 or 5.');
  if MaxEvaluations<=0 then
    raise EModellingError.Create(
      'IntegrateCubature: MaxEvaluations must be positive.');
  for I:=0 to D-1 do
    if not IsFiniteValue(LowerBounds[I]) or
       not IsFiniteValue(UpperBounds[I]) or
       (LowerBounds[I]>=UpperBounds[I]) then
      raise EModellingError.CreateFmt(
        'IntegrateCubature: require finite lower < upper at dimension %d.',
        [I]);
  Count3:=1; Count5:=1;
  for I:=1 to D do
  begin
    if Count3>QWord(MaxEvaluations) div 3 then
      Count3:=QWord(MaxEvaluations)+1
    else
      Count3:=Count3*3;
    if Count5>QWord(MaxEvaluations) div 5 then
      Count5:=QWord(MaxEvaluations)+1
    else
      Count5:=Count5*5;
  end;
  if Order=5 then Required:=Count3+Count5
  else Required:=Count3+1;
  if (Required>QWord(MaxEvaluations)) or
     (Required>QWord(High(Integer))) then
    raise EModellingError.CreateFmt(
      'IntegrateCubature: requested rules need %s evaluations; cap is %d.',
      [UIntToStr(Required),MaxEvaluations]);
  Nodes3:=TDoubleArray.Create(-Sqrt(3/5),0,Sqrt(3/5));
  Weights3:=TDoubleArray.Create(5/9,8/9,5/9);
  Nodes5:=TDoubleArray.Create(
    -Sqrt(5+2*Sqrt(10/7))/3,
    -Sqrt(5-2*Sqrt(10/7))/3,
    0,
    Sqrt(5-2*Sqrt(10/7))/3,
    Sqrt(5+2*Sqrt(10/7))/3);
  Weights5:=TDoubleArray.Create(
    (322-13*Sqrt(70))/900,
    (322+13*Sqrt(70))/900,
    128/225,
    (322+13*Sqrt(70))/900,
    (322-13*Sqrt(70))/900);
  SetLength(Point,D);
  EvaluationCount:=0;
  if Order=5 then
  begin
    Primary:=RuleValue(Nodes5,Weights5);
    Reference:=RuleValue(Nodes3,Weights3);
  end
  else
  begin
    Primary:=RuleValue(Nodes3,Weights3);
    SetLength(Nodes5,1); Nodes5[0]:=0;
    SetLength(Weights5,1); Weights5[0]:=2;
    Reference:=RuleValue(Nodes5,Weights5);
  end;
  Result.Value:=Primary;
  Result.ErrorEstimate:=Abs(Primary-Reference);
  Result.Evaluations:=EvaluationCount;
  Result.Intervals:=EvaluationCount;
  Result.Status:=isAcceptableLimit;
end;

class function TModellingKit.IntegrateMonteCarlo(
  F: TMultidimensionalIntegrand; const LowerBounds,
  UpperBounds: TDoubleArray; Samples: Integer;
  var Random: TLocalRandom): TIntegrationResult;
var
  Working:TLocalRandom;
  State:TRandomState;
  Point:TDoubleArray;
  I,J,D:Integer;
  Value,Mean,M2,Delta,Volume:Double;
begin
  Result:=Default(TIntegrationResult);
  if not Assigned(F) then
    raise EModellingError.Create(
      'IntegrateMonteCarlo: integrand must be assigned.');
  D:=Length(LowerBounds);
  if (D=0) or (D<>Length(UpperBounds)) or (D>64) then
    raise EModellingError.Create(
      'IntegrateMonteCarlo: dimensions must match and be between 1 and 64.');
  if Samples<=1 then
    raise EModellingError.Create(
      'IntegrateMonteCarlo: Samples must exceed one.');
  Working:=Random;
  State:=Working.GetState;
  if (State.Words[0]=0) and (State.Words[1]=0) and
     (State.Words[2]=0) and (State.Words[3]=0) then
    raise EModellingError.Create(
      'IntegrateMonteCarlo: random state must not be all zero.');
  SetLength(Point,D);
  Volume:=1;
  for J:=0 to D-1 do
  begin
    if not IsFiniteValue(LowerBounds[J]) or
       not IsFiniteValue(UpperBounds[J]) or
       (LowerBounds[J]>=UpperBounds[J]) then
      raise EModellingError.CreateFmt(
        'IntegrateMonteCarlo: require finite lower < upper at dimension %d.',
        [J]);
    Volume:=Volume*(UpperBounds[J]-LowerBounds[J]);
    if not IsFiniteValue(Volume) then
      raise EModellingError.Create(
        'IntegrateMonteCarlo: integration volume overflowed.');
  end;
  Mean:=0; M2:=0;
  for I:=1 to Samples do
  begin
    for J:=0 to D-1 do
      Point[J]:=LowerBounds[J]+
        (UpperBounds[J]-LowerBounds[J])*Working.NextDouble;
    Value:=F(Point);
    Inc(Result.Evaluations);
    if not IsFiniteValue(Value) then
      raise EModellingError.CreateFmt(
        'IntegrateMonteCarlo: non-finite callback result at sample %d.',[I]);
    Delta:=Value-Mean;
    Mean:=Mean+Delta/I;
    M2:=M2+Delta*(Value-Mean);
  end;
  Result.Value:=Volume*Mean;
  Result.ErrorEstimate:=Volume*Sqrt(Max(0,M2)/(Samples-1)/Samples);
  Result.Intervals:=Samples;
  Result.Status:=isAcceptableLimit;
  Random:=Working;
end;

function PolynomialBasis(X: Double; BasisIndex: Integer): Double;
begin Result:=Power(X,BasisIndex); end;

function FitPreparedDesign(const X, Y: TDoubleArray;
  const RawDesign: TModelMatrix; const Weights: TDoubleArray;
  const Operation: String): TFitResult;
var
  Design, Normal: TModelMatrix;
  RHSValues: TDoubleArray;
  A,B,Solution: IDenseDoubleMatrix;
  Diag: TDenseSolveDiagnostics;
  I,J,K,N,BasisCount: Integer;
  W,SqrtW,Pred,MeanY,SST: Double;
begin
  Result:=Default(TFitResult);
  if (Length(X)<>Length(Y)) or (Length(X)=0) then
    raise EModellingError.Create(Operation+
      ': X and Y lengths must match and be non-empty.');
  if Length(RawDesign)<>Length(X) then
    raise EModellingError.Create(Operation+
      ': design row count must match observations.');
  BasisCount:=Length(RawDesign[0]);
  if (BasisCount<=0) or (BasisCount>Length(X)) then
    raise EModellingError.Create(Operation+
      ': basis count must be between 1 and the observation count.');
  if (Length(Weights)<>0) and (Length(Weights)<>Length(X)) then
    raise EModellingError.Create(Operation+
      ': Weights must be empty or match observations.');
  ValidateVector(X,Operation+' X'); ValidateVector(Y,Operation+' Y');
  N:=Length(X); SetLength(Design,N); SetLength(RHSValues,N);
  for I:=0 to N-1 do begin
    if Length(RawDesign[I])<>BasisCount then
      raise EModellingError.CreateFmt(
        '%s: design row %d has %d columns; expected %d.',
        [Operation,I,Length(RawDesign[I]),BasisCount]);
    if Length(Weights)=0 then W:=1 else W:=Weights[I];
    if (W<=0) or not IsFiniteValue(W) then raise EModellingError.CreateFmt(
      '%s: weight %d must be finite and positive.',[Operation,I]);
    SqrtW:=Sqrt(W); SetLength(Design[I],BasisCount);
    for J:=0 to BasisCount-1 do begin
      if not IsFiniteValue(RawDesign[I][J]) then
        raise EModellingError.CreateFmt(
          '%s: basis value [%d,%d] is non-finite.',[Operation,I,J]);
      Design[I][J]:=SqrtW*RawDesign[I][J];
      if not IsFiniteValue(Design[I][J]) then raise EModellingError.CreateFmt(
        '%s: weighted basis value [%d,%d] overflowed.',[Operation,I,J]);
    end;
    RHSValues[I]:=SqrtW*Y[I];
  end;
  A:=DenseFromMatrix(Design); B:=DenseFromVector(RHSValues);
  Solution:=RankRevealingLeastSquares(A,B,Diag);
  Result.Parameters:=VectorFromDense(Solution); Result.Rank:=Diag.NumericalRank;
  Result.DegreesOfFreedom:=N-Result.Rank; SetLength(Result.Residuals,N);
  MeanY:=0; for I:=0 to N-1 do MeanY:=MeanY+Y[I]; MeanY:=MeanY/N;
  Result.ResidualSumSquares:=0; SST:=0;
  for I:=0 to N-1 do begin
    Pred:=0; for J:=0 to BasisCount-1 do Pred:=Pred+
      Result.Parameters[J]*RawDesign[I][J];
    Result.Residuals[I]:=Y[I]-Pred;
    Result.ResidualSumSquares:=Result.ResidualSumSquares+Sqr(Result.Residuals[I]);
    SST:=SST+Sqr(Y[I]-MeanY);
  end;
  if SST>0 then Result.RSquared:=1-Result.ResidualSumSquares/SST
  else if Result.ResidualSumSquares=0 then Result.RSquared:=1 else Result.RSquared:=0;
  Result.Status:=isConverged;
  { Covariance = sigma^2 (X'WX)^-1 only for full rank and positive DOF. }
  if (Result.Rank=BasisCount) and (Result.DegreesOfFreedom>0) then begin
    SetLength(Result.Covariance,BasisCount);
    for I:=0 to BasisCount-1 do SetLength(Result.Covariance[I],BasisCount);
    SetLength(Normal,BasisCount);
    for I:=0 to BasisCount-1 do begin SetLength(Normal[I],BasisCount);
      for J:=0 to BasisCount-1 do begin W:=0;
        for K:=0 to Length(X)-1 do begin
          if Length(Weights)=0 then SqrtW:=1 else SqrtW:=Weights[K];
          W:=W+SqrtW*RawDesign[K][I]*RawDesign[K][J];
        end; Normal[I][J]:=W; end; end;
    A:=DenseFromMatrix(Normal);
    B:=TDenseDoubleMatrix.Zeros(BasisCount,BasisCount);
    for I:=0 to BasisCount-1 do B[I,I]:=1;
    Solution:=Solve(A,B);
    W:=Result.ResidualSumSquares/Result.DegreesOfFreedom;
    for I:=0 to BasisCount-1 do for J:=0 to BasisCount-1 do
      Result.Covariance[I][J]:=W*Solution[I,J];
  end;
end;

class function TModellingKit.FitLinearBasis(const X, Y: TDoubleArray;
  BasisCount: Integer; Basis: TLinearBasisFunction;
  const Weights: TDoubleArray): TFitResult;
var
  Design: TModelMatrix;
  I,J: Integer;
begin
  Result:=Default(TFitResult);
  if not Assigned(Basis) then raise EModellingError.Create(
    'FitLinearBasis: basis callback must be assigned.');
  if (Length(X)<>Length(Y)) or (Length(X)=0) then raise EModellingError.Create(
    'FitLinearBasis: X and Y lengths must match and be non-empty.');
  if (BasisCount<=0) or (BasisCount>Length(X)) then raise EModellingError.Create(
    'FitLinearBasis: BasisCount must be between 1 and the observation count.');
  SetLength(Design,Length(X));
  for I:=0 to High(X) do
  begin
    SetLength(Design[I],BasisCount);
    for J:=0 to BasisCount-1 do
      Design[I][J]:=Basis(X[I],J);
  end;
  Result:=FitPreparedDesign(X,Y,Design,Weights,'FitLinearBasis');
end;

class function TModellingKit.FitPolynomial(const X, Y: TDoubleArray;
  Degree: Integer; const Weights: TDoubleArray): TFitResult;
begin
  if Degree<0 then raise EModellingError.Create(
    'FitPolynomial: Degree must be non-negative.');
  Result:=FitLinearBasis(X,Y,Degree+1,@PolynomialBasis,Weights);
end;

function TSplineFitResult.Evaluate(const X: Double): Double;
var
  I, ParameterIndex: Integer;
  DX: Double;
begin
  if not IsFiniteValue(X) then
    raise EModellingError.Create(
      'SplineFit.Evaluate: X must be finite.');
  if Length(Fit.Parameters)<>4+Length(InteriorKnots) then
    raise EModellingError.Create(
      'SplineFit.Evaluate: model parameter shape is invalid.');
  Result:=Fit.Parameters[0]+Fit.Parameters[1]*X+
    Fit.Parameters[2]*Sqr(X)+Fit.Parameters[3]*X*Sqr(X);
  ParameterIndex:=4;
  for I:=0 to High(InteriorKnots) do
  begin
    DX:=X-InteriorKnots[I];
    if DX>0 then
      Result:=Result+Fit.Parameters[ParameterIndex]*DX*Sqr(DX);
    Inc(ParameterIndex);
  end;
end;

class function TModellingKit.FitSplineBasis(const X, Y,
  InteriorKnots: TDoubleArray; const Weights: TDoubleArray):
  TSplineFitResult;
var
  Design: TModelMatrix;
  I,J,BasisCount: Integer;
  DX,MinX,MaxX: Double;
begin
  Result:=Default(TSplineFitResult);
  if (Length(X)<>Length(Y)) or (Length(X)=0) then
    raise EModellingError.Create(
      'FitSplineBasis: X and Y lengths must match and be non-empty.');
  ValidateVector(X,'FitSplineBasis X');
  ValidateVector(Y,'FitSplineBasis Y');
  ValidateVector(InteriorKnots,'FitSplineBasis interior knots',True);
  MinX:=X[0]; MaxX:=X[0];
  for I:=1 to High(X) do
  begin
    MinX:=Min(MinX,X[I]);
    MaxX:=Max(MaxX,X[I]);
  end;
  for I:=1 to High(InteriorKnots) do
    if InteriorKnots[I]<=InteriorKnots[I-1] then
      raise EModellingError.Create(
        'FitSplineBasis: interior knots must be strictly increasing.');
  for I:=0 to High(InteriorKnots) do
    if (InteriorKnots[I]<=MinX) or
       (InteriorKnots[I]>=MaxX) then
      raise EModellingError.CreateFmt(
        'FitSplineBasis: knot %d must lie strictly inside the X range.',[I]);
  BasisCount:=4+Length(InteriorKnots);
  if BasisCount>Length(X) then
    raise EModellingError.Create(
      'FitSplineBasis: observations must be at least the basis count.');
  SetLength(Design,Length(X));
  for I:=0 to High(X) do
  begin
    SetLength(Design[I],BasisCount);
    Design[I][0]:=1;
    Design[I][1]:=X[I];
    Design[I][2]:=Sqr(X[I]);
    Design[I][3]:=X[I]*Sqr(X[I]);
    for J:=0 to High(InteriorKnots) do
    begin
      DX:=X[I]-InteriorKnots[J];
      if DX>0 then Design[I][4+J]:=DX*Sqr(DX);
    end;
  end;
  Result.InteriorKnots:=Copy(InteriorKnots);
  Result.Fit:=FitPreparedDesign(X,Y,Design,Weights,'FitSplineBasis');
end;

class function TNonlinearFitOptions.Defaults: TNonlinearFitOptions;
begin
  Result:=Default(TNonlinearFitOptions);
  Result.AbsoluteTolerance:=1E-10; Result.RelativeTolerance:=1E-8;
  Result.GradientTolerance:=1E-8; Result.InitialDamping:=1E-3;
  Result.MaxIterations:=200; Result.Loss:=rlSquared; Result.LossScale:=1;
end;

function RobustWeight(R, Scale: Double; Loss: TRobustLoss): Double;
var A: Double;
begin
  A:=Abs(R)/Scale;
  case Loss of
    rlHuber: if A<=1 then Result:=1 else Result:=1/Sqrt(A);
    rlSoftL1: Result:=Power(1+Sqr(A),-0.25);
  else Result:=1; end;
end;

type
  TResidualSource = record
    RealFunction:TResidualFunction;
    AnalyticJacobian:TJacobianFunction;
    DualFunction:TDualVectorFunction;
  end;

function EvaluateDualResidual(F:TDualVectorFunction;
  const P:TDoubleArray):TDoubleArray;
var
  Input:TDualArray;
  Output:TDualArray;
  I:Integer;
begin
  Result:=nil;
  SetLength(Input,Length(P));
  for I:=0 to High(P) do
    Input[I]:=TDual.Create(P[I],0);
  Output:=F(Input);
  SetLength(Result,Length(Output));
  for I:=0 to High(Output) do
  begin
    if not IsFiniteValue(Output[I].Value) or
       not IsFiniteValue(Output[I].Derivative) then
      raise EModellingError.CreateFmt(
        'automatic residual: non-finite value at row %d.',[I]);
    Result[I]:=Output[I].Value;
  end;
end;

function EvaluateResidualSource(const Source:TResidualSource;
  const P:TDoubleArray; var Evaluations:Integer):TDoubleArray;
begin
  if Assigned(Source.DualFunction) then
    Result:=EvaluateDualResidual(Source.DualFunction,P)
  else
    Result:=Source.RealFunction(P);
  Inc(Evaluations);
end;

function AutomaticResidualJacobian(const Source:TResidualSource;
  const P:TDoubleArray; var Evaluations:Integer):TModelMatrix;
begin
  Result:=TModelMatrix(TDifferentiationKit.AutoJacobian(
    Source.DualFunction,P));
  Inc(Evaluations,Length(P));
end;

function NumericalResidualJacobian(const Source:TResidualSource;
  const P, Base: TDoubleArray; var Evaluations: Integer): TModelMatrix;
var PP,PM,RP,RM:TDoubleArray; I,J:Integer; H:Double;
begin
  Result := nil;
  SetLength(Result,Length(Base));
  for J:=0 to High(Base) do SetLength(Result[J],Length(P));
  PP:=Copy(P); PM:=Copy(P);
  for I:=0 to High(P) do begin
    H:=Power(DoubleEpsilon,1/3)*Max(1,Abs(P[I]));
    PP[I]:=P[I]+H; PM[I]:=P[I]-H;
    RP:=EvaluateResidualSource(Source,PP,Evaluations);
    RM:=EvaluateResidualSource(Source,PM,Evaluations);
    PP[I]:=P[I]; PM[I]:=P[I];
    if (Length(RP)<>Length(Base)) or (Length(RM)<>Length(Base)) then
      raise EModellingError.Create('FitNonlinear: residual dimension changed.');
    ValidateVector(RP,'FitNonlinear residual'); ValidateVector(RM,'FitNonlinear residual');
    for J:=0 to High(Base) do Result[J][I]:=(RP[J]-RM[J])/(2*H);
  end;
end;

function ResidualCost(const R:TDoubleArray; Scale:Double; Loss:TRobustLoss):Double;
var I:Integer; A:Double;
begin Result:=0; for I:=0 to High(R) do begin A:=Abs(R[I])/Scale;
  case Loss of rlHuber:if A<=1 then Result:=Result+0.5*Sqr(R[I])
    else Result:=Result+Scale*(Abs(R[I])-0.5*Scale);
    rlSoftL1:Result:=Result+Sqr(Scale)*(Sqrt(1+Sqr(A))-1);
  else Result:=Result+0.5*Sqr(R[I]); end; end; end;

function FitNonlinearCore(const Source:TResidualSource;
  const InitialParameters: TDoubleArray;
  const Options: TNonlinearFitOptions): TFitResult;
var
  P,Trial,R,RTrial,Delta,G,ParameterScales,SingularValues:TDoubleArray;
  J:TModelMatrix;
  JReference:TModelMatrix;
  H:TModelMatrix; A,B,S:IDenseDoubleMatrix;
  FinalFactor:IDenseDoubleSVD;
  V:IDenseDoubleMatrix;
  I,K,L,Q,N,M,Stale:Integer;
  Lambda,Cost,TrialCost,W,Scale,StepNorm,PrevCost,Diff,Limit,
    PSI,PSL,VarianceEstimate:Double;
begin
  Result:=Default(TFitResult);
  if not Assigned(Source.RealFunction) and
     not Assigned(Source.DualFunction) then raise EModellingError.Create(
    'FitNonlinear: residual callback must be assigned.');
  ValidateVector(InitialParameters,'FitNonlinear initial parameters');
  if (Options.AbsoluteTolerance<0) or (Options.RelativeTolerance<0) or
     (Options.GradientTolerance<=0) or (Options.InitialDamping<=0) or
     (Options.MaxIterations<=0) or (Options.LossScale<=0) then
    raise EModellingError.Create('FitNonlinear: invalid options.');
  N:=Length(InitialParameters);
  if (Length(Options.LowerBounds)<>0) and
     (Length(Options.LowerBounds)<>N) then raise EModellingError.Create(
       'FitNonlinear: lower bounds length mismatch.');
  if (Length(Options.UpperBounds)<>0) and
     (Length(Options.UpperBounds)<>N) then raise EModellingError.Create(
       'FitNonlinear: upper bounds length mismatch.');
  if (Length(Options.ParameterScales)<>0) and
     (Length(Options.ParameterScales)<>N) then raise EModellingError.Create(
       'FitNonlinear: parameter scales length mismatch.');
  SetLength(ParameterScales,N);
  for I:=0 to N-1 do
  begin
    ParameterScales[I]:=1;
    if Length(Options.ParameterScales)>0 then
    begin
      if not IsFiniteValue(Options.ParameterScales[I]) or
         (Options.ParameterScales[I]<=0) then
        raise EModellingError.CreateFmt(
          'FitNonlinear: parameter scale %d must be finite and positive.',
          [I]);
      ParameterScales[I]:=Options.ParameterScales[I];
    end;
    if (Length(Options.LowerBounds)>0) and
       (Length(Options.UpperBounds)>0) and
       (Options.LowerBounds[I]>Options.UpperBounds[I]) then
      raise EModellingError.CreateFmt(
        'FitNonlinear: lower bound exceeds upper bound at parameter %d.',
        [I]);
  end;
  P:=Copy(InitialParameters);
  for I:=0 to N-1 do begin
    if Length(Options.LowerBounds)>0 then P[I]:=Max(P[I],Options.LowerBounds[I]);
    if Length(Options.UpperBounds)>0 then P[I]:=Min(P[I],Options.UpperBounds[I]);
  end;
  R:=EvaluateResidualSource(Source,P,Result.Evaluations);
  ValidateVector(R,'FitNonlinear residual');
  M:=Length(R); Lambda:=Options.InitialDamping; Cost:=ResidualCost(R,Options.LossScale,Options.Loss);
  if Options.CheckDerivative and
     (Assigned(Source.AnalyticJacobian) or
      Assigned(Source.DualFunction)) then
  begin
    if Assigned(Source.DualFunction) then
      J:=AutomaticResidualJacobian(Source,P,Result.Evaluations)
    else
    begin
      J:=Source.AnalyticJacobian(P);
      Inc(Result.Evaluations);
    end;
    ValidateMatrix(J,M,N,'FitNonlinear Jacobian');
    JReference:=NumericalResidualJacobian(Source,P,R,Result.Evaluations);
    for I:=0 to M-1 do
      for L:=0 to N-1 do
      begin
        Diff:=Abs(J[I][L]-JReference[I][L]);
        Limit:=1E-7+1E-5*Max(Abs(J[I][L]),Abs(JReference[I][L]));
        if Diff>Limit then
          raise EModellingError.CreateFmt(
            'FitNonlinear derivative check: Jacobian[%d,%d] differs from the numerical reference (%.6g versus %.6g).',
            [I,L,J[I][L],JReference[I][L]]);
      end;
  end;
  PrevCost:=Infinity; Stale:=0;
  for K:=1 to Options.MaxIterations do begin
    if Assigned(Source.DualFunction) then
      J:=AutomaticResidualJacobian(Source,P,Result.Evaluations)
    else if Assigned(Source.AnalyticJacobian) then
    begin
      J:=Source.AnalyticJacobian(P);
      Inc(Result.Evaluations);
    end
    else
      J:=NumericalResidualJacobian(Source,P,R,Result.Evaluations);
    ValidateMatrix(J,M,N,'FitNonlinear Jacobian');
    SetLength(H,N); SetLength(G,N);
    for I:=0 to N-1 do begin
      PSI:=ParameterScales[I];
      SetLength(H[I],N); G[I]:=0;
      for L:=0 to M-1 do begin W:=RobustWeight(R[L],Options.LossScale,Options.Loss);
        G[I]:=G[I]+Sqr(W)*J[L][I]*PSI*R[L]; end;
      for L:=0 to N-1 do begin
        PSL:=ParameterScales[L];
        H[I][L]:=0;
        for Q:=0 to M-1 do begin W:=RobustWeight(R[Q],Options.LossScale,Options.Loss);
          H[I][L]:=H[I][L]+Sqr(W)*J[Q][I]*PSI*J[Q][L]*PSL;
        end;
      end;
      H[I][I]:=H[I][I]+Lambda*Max(1,H[I][I]); G[I]:=-G[I];
    end;
    Result.GradientNorm:=VectorNorm(G);
    if Result.GradientNorm<=Options.GradientTolerance then begin
      Result.Status:=isConverged; Result.Iterations:=K-1; Break; end;
    try A:=DenseFromMatrix(H); B:=DenseFromVector(G); S:=Solve(A,B);
      Delta:=VectorFromDense(S);
    except on E:Exception do begin Result.Status:=isNumericalBreakdown;
      Result.Iterations:=K; Break; end; end;
    for I:=0 to N-1 do Delta[I]:=Delta[I]*ParameterScales[I];
    StepNorm:=VectorNorm(Delta); Trial:=Copy(P);
    for I:=0 to N-1 do begin Trial[I]:=P[I]+Delta[I];
      if Length(Options.LowerBounds)>0 then Trial[I]:=Max(Trial[I],Options.LowerBounds[I]);
      if Length(Options.UpperBounds)>0 then Trial[I]:=Min(Trial[I],Options.UpperBounds[I]); end;
    RTrial:=EvaluateResidualSource(Source,Trial,Result.Evaluations);
    if Length(RTrial)<>Length(R) then raise EModellingError.Create(
      'FitNonlinear: residual dimension changed.');
    ValidateVector(RTrial,'FitNonlinear residual'); TrialCost:=ResidualCost(RTrial,Options.LossScale,Options.Loss);
    if TrialCost<Cost then begin P:=Trial; R:=RTrial; PrevCost:=Cost; Cost:=TrialCost;
      Lambda:=Max(1E-15,Lambda/3);
      Scale:=Options.AbsoluteTolerance+Options.RelativeTolerance*Max(1,VectorNorm(P));
      if StepNorm<=Scale then begin Result.Status:=isConverged; Result.Iterations:=K; Break; end;
      if Abs(PrevCost-Cost)<=Options.AbsoluteTolerance+Options.RelativeTolerance*Max(1,Cost)
        then Inc(Stale) else Stale:=0;
    end else begin Lambda:=Min(1E15,Lambda*10); Inc(Stale); end;
    Result.Iterations:=K;
    if Stale>=8 then begin Result.Status:=isStagnation; Break; end;
    if Assigned(Options.Progress) and
       (not Options.Progress(K,Result.Evaluations,Cost)) then begin
      Result.Status:=isCancelled; Break; end;
  end;
  if Result.Status=isUnknown then Result.Status:=isIterationLimit;
  Result.Parameters:=P; Result.Residuals:=R;
  Result.ResidualSumSquares:=0; for I:=0 to High(R) do
    Result.ResidualSumSquares:=Result.ResidualSumSquares+Sqr(R[I]);
  if Assigned(Source.DualFunction) then
    J:=AutomaticResidualJacobian(Source,P,Result.Evaluations)
  else if Assigned(Source.AnalyticJacobian) then
  begin
    J:=Source.AnalyticJacobian(P);
    Inc(Result.Evaluations);
  end
  else
    J:=NumericalResidualJacobian(Source,P,R,Result.Evaluations);
  ValidateMatrix(J,M,N,'FitNonlinear final Jacobian');
  try
    FinalFactor:=FactorSVD(DenseFromMatrix(J));
    Result.Rank:=FinalFactor.NumericalRank;
    SingularValues:=FinalFactor.SingularValues;
    V:=FinalFactor.V;
  except
    on E:Exception do
    begin
      Result.Rank:=0;
      SingularValues:=nil;
      V:=nil;
    end;
  end;
  Result.DegreesOfFreedom:=Length(R)-Result.Rank;
  if (Options.Loss=rlSquared) and (Result.Rank=N) and
     (Result.DegreesOfFreedom>0) then
  begin
    VarianceEstimate:=Result.ResidualSumSquares/Result.DegreesOfFreedom;
    SetLength(Result.Covariance,N);
    for I:=0 to N-1 do
    begin
      SetLength(Result.Covariance[I],N);
      for L:=0 to N-1 do
        for Q:=0 to N-1 do
          if SingularValues[Q]>FinalFactor.Tolerance then
            Result.Covariance[I][L]:=Result.Covariance[I][L]+
              VarianceEstimate*V[I,Q]*V[L,Q]/Sqr(SingularValues[Q]);
    end;
  end;
end;

class function TModellingKit.FitNonlinear(Residual: TResidualFunction;
  Jacobian: TJacobianFunction; const InitialParameters: TDoubleArray;
  const Options: TNonlinearFitOptions): TFitResult;
var
  Source:TResidualSource;
begin
  Source:=Default(TResidualSource);
  Source.RealFunction:=Residual;
  Source.AnalyticJacobian:=Jacobian;
  Result:=FitNonlinearCore(Source,InitialParameters,Options);
end;

class function TModellingKit.FitNonlinearAuto(
  Residual: TDualVectorFunction; const InitialParameters: TDoubleArray;
  const Options: TNonlinearFitOptions): TFitResult;
var
  Source:TResidualSource;
begin
  Source:=Default(TResidualSource);
  Source.DualFunction:=Residual;
  Result:=FitNonlinearCore(Source,InitialParameters,Options);
end;

function ConvertJacobian(const J:TModelMatrix):NumericsLib.Differentiation.TDoubleMatrix;
var I:Integer; begin Result:=nil; SetLength(Result,Length(J));
  for I:=0 to High(J) do Result[I]:=Copy(J[I]); end;

function SolveSystemCore(const Source:TResidualSource;
  const InitialX: TDoubleArray;
  AbsoluteTolerance, RelativeTolerance: Double; MaxIterations: Integer;
  Progress: TProgressFunction): TVectorRootResult;
var
  X,R,RNew,Step,Trial:TDoubleArray; J:TModelMatrix;
  A,B,S:IDenseDoubleMatrix; I,K,N,Stale:Integer;
  NormR,NewNorm,Alpha,Scale,PrevNorm:Double;
begin
  Result:=Default(TVectorRootResult);
  if not Assigned(Source.RealFunction) and
     not Assigned(Source.DualFunction) then raise EModellingError.Create(
    'SolveSystem: function callback must be assigned.');
  ValidateVector(InitialX,'SolveSystem initial X'); N:=Length(InitialX);
  if (AbsoluteTolerance<0) or (RelativeTolerance<0) or
     (AbsoluteTolerance+RelativeTolerance<=0) or (MaxIterations<=0) then
    raise EModellingError.Create('SolveSystem: invalid controls.');
  X:=Copy(InitialX);
  R:=EvaluateResidualSource(Source,X,Result.Evaluations);
  if Length(R)<>N then raise EModellingError.Create(
    'SolveSystem: residual dimension must equal variable count.');
  ValidateVector(R,'SolveSystem residual'); NormR:=VectorNorm(R); Stale:=0;
  for K:=1 to MaxIterations do begin
    Scale:=AbsoluteTolerance+RelativeTolerance*Max(1,VectorNorm(X));
    if NormR<=Scale then begin Result.Status:=isConverged; Result.Iterations:=K-1; Break; end;
    if Assigned(Source.DualFunction) then
      J:=AutomaticResidualJacobian(Source,X,Result.Evaluations)
    else if Assigned(Source.AnalyticJacobian) then
    begin
      J:=Source.AnalyticJacobian(X);
      Inc(Result.Evaluations);
    end
    else
      J:=NumericalResidualJacobian(Source,X,R,Result.Evaluations);
    ValidateMatrix(J,N,N,'SolveSystem Jacobian');
    for I:=0 to N-1 do R[I]:=-R[I];
    try A:=DenseFromMatrix(J); B:=DenseFromVector(R); S:=Solve(A,B);
      Step:=VectorFromDense(S);
    except on E:Exception do begin Result.Status:=isNumericalBreakdown;
      Result.Iterations:=K; Break; end; end;
    for I:=0 to N-1 do R[I]:=-R[I];
    Result.StepNorm:=VectorNorm(Step); Alpha:=1; PrevNorm:=NormR;
    repeat
      Trial:=Copy(X); for I:=0 to N-1 do Trial[I]:=X[I]+Alpha*Step[I];
      RNew:=EvaluateResidualSource(Source,Trial,Result.Evaluations);
      if Length(RNew)<>N then raise EModellingError.Create(
        'SolveSystem: residual dimension changed.');
      ValidateVector(RNew,'SolveSystem residual'); NewNorm:=VectorNorm(RNew);
      if NewNorm<NormR then Break; Alpha:=Alpha/2;
    until Alpha<1E-8;
    if NewNorm<NormR then begin X:=Trial; R:=RNew; NormR:=NewNorm; end;
    if Abs(PrevNorm-NormR)<=DoubleEpsilon*Max(1,PrevNorm) then Inc(Stale)
    else Stale:=0;
    Result.Iterations:=K;
    if Stale>=5 then begin Result.Status:=isStagnation; Break; end;
    if Assigned(Progress) and not Progress(K,Result.Evaluations,NormR) then begin
      Result.Status:=isCancelled; Break; end;
  end;
  if Result.Status=isUnknown then Result.Status:=isIterationLimit;
  Result.X:=X; Result.Residual:=R; Result.ResidualNorm:=NormR;
end;

class function TModellingKit.SolveSystem(F: TVectorEquationFunction;
  Jacobian: TVectorJacobianFunction; const InitialX: TDoubleArray;
  AbsoluteTolerance, RelativeTolerance: Double; MaxIterations: Integer;
  Progress: TProgressFunction): TVectorRootResult;
var
  Source:TResidualSource;
begin
  Source:=Default(TResidualSource);
  Source.RealFunction:=TResidualFunction(F);
  Source.AnalyticJacobian:=TJacobianFunction(Jacobian);
  Result:=SolveSystemCore(Source,InitialX,AbsoluteTolerance,
    RelativeTolerance,MaxIterations,Progress);
end;

class function TModellingKit.SolveSystemAuto(F: TDualVectorFunction;
  const InitialX: TDoubleArray; AbsoluteTolerance,
  RelativeTolerance: Double; MaxIterations: Integer;
  Progress: TProgressFunction): TVectorRootResult;
var
  Source:TResidualSource;
begin
  Source:=Default(TResidualSource);
  Source.DualFunction:=F;
  Result:=SolveSystemCore(Source,InitialX,AbsoluteTolerance,
    RelativeTolerance,MaxIterations,Progress);
end;

function EvaluatePolynomialComplex(const Coefficients: TDoubleArray;
  const X: TComplex): TComplex;
var
  I: Integer;
begin
  Result:=TComplex.Create(Coefficients[High(Coefficients)],0);
  for I:=High(Coefficients)-1 downto 0 do
    Result:=Result*X+Coefficients[I];
end;

procedure SortPolynomialRoots(var Roots:TComplexArray;
  var Residuals:TDoubleArray);
var
  I,J:Integer;
  Root:TComplex;
  Residual:Double;
begin
  for I:=1 to High(Roots) do
  begin
    Root:=Roots[I]; Residual:=Residuals[I]; J:=I-1;
    while (J>=0) and ((Roots[J].Re>Root.Re) or
      ((Roots[J].Re=Root.Re) and (Roots[J].Im>Root.Im))) do
    begin
      Roots[J+1]:=Roots[J];
      Residuals[J+1]:=Residuals[J];
      Dec(J);
    end;
    Roots[J+1]:=Root;
    Residuals[J+1]:=Residual;
  end;
end;

class function TModellingKit.SolvePolynomial(
  const Coefficients: TDoubleArray; AbsoluteTolerance,
  RelativeTolerance: Double; MaxIterations: Integer):
  TPolynomialRootResult;
var
  Current,Previous,Best:TComplexArray;
  Value,Denominator,Update:TComplex;
  I,J,K,Degree,Stale:Integer;
  Leading,Radius,Angle,MaxUpdate,MaxResidual,BestMaximum,
    Limit,CoefficientScale,DenominatorScale:Double;
begin
  Result:=Default(TPolynomialRootResult);
  if Length(Coefficients)<2 then
    raise EModellingError.Create(
      'SolvePolynomial: at least two coefficients are required.');
  ValidateVector(Coefficients,'SolvePolynomial coefficients');
  if Coefficients[High(Coefficients)]=0 then
    raise EModellingError.Create(
      'SolvePolynomial: highest-order coefficient must be non-zero.');
  if (AbsoluteTolerance<0) or (RelativeTolerance<0) or
     (AbsoluteTolerance+RelativeTolerance<=0) or
     not IsFiniteValue(AbsoluteTolerance) or
     not IsFiniteValue(RelativeTolerance) or (MaxIterations<=0) then
    raise EModellingError.Create('SolvePolynomial: invalid controls.');
  Degree:=High(Coefficients);
  Leading:=Coefficients[Degree];
  CoefficientScale:=0;
  Radius:=1;
  for I:=0 to Degree-1 do
  begin
    CoefficientScale:=Max(CoefficientScale,Abs(Coefficients[I]));
    Radius:=Max(Radius,1+Abs(Coefficients[I]/Leading));
  end;
  CoefficientScale:=Max(CoefficientScale,Abs(Leading));
  if Degree=1 then
  begin
    SetLength(Result.Roots,1);
    SetLength(Result.Residuals,1);
    Result.Roots[0]:=TComplex.Create(-Coefficients[0]/Leading,0);
    Value:=EvaluatePolynomialComplex(Coefficients,Result.Roots[0]);
    Result.Residuals[0]:=Value.Magnitude;
    Result.Evaluations:=1;
    Result.Status:=isConverged;
    Exit;
  end;
  SetLength(Current,Degree);
  SetLength(Previous,Degree);
  SetLength(Best,Degree);
  for I:=0 to Degree-1 do
  begin
    Angle:=2*Pi*(I+0.5)/Degree;
    { Unequal radii deliberately avoid an exactly conjugate-symmetric starting
      set. Such a set cannot separate a conjugate pair onto two distinct real
      roots in exact arithmetic, making convergence platform-rounding
      dependent for real polynomials with several real roots. }
    Current[I]:=TComplex.FromPolar(
      Radius*(0.75+0.25*(I+1)/Degree),Angle);
  end;
  Best:=Copy(Current);
  BestMaximum:=Infinity;
  Stale:=0;
  for K:=1 to MaxIterations do
  begin
    Previous:=Copy(Current);
    MaxUpdate:=0;
    for I:=0 to Degree-1 do
    begin
      Value:=EvaluatePolynomialComplex(Coefficients,Previous[I]);
      Inc(Result.Evaluations);
      Denominator:=TComplex.One;
      for J:=0 to Degree-1 do
        if J<>I then
          Denominator:=Denominator*(Previous[I]-Previous[J]);
      DenominatorScale:=Denominator.Magnitude;
      if (DenominatorScale<=DoubleEpsilon) or
         not IsFiniteValue(DenominatorScale) then
      begin
        Result.Status:=isNumericalBreakdown;
        Break;
      end;
      Update:=Value/(Denominator*Leading);
      Current[I]:=Previous[I]-Update;
      if not Current[I].IsFinite then
      begin
        Result.Status:=isNumericalBreakdown;
        Break;
      end;
      MaxUpdate:=Max(MaxUpdate,Update.Magnitude);
    end;
    Result.Iterations:=K;
    if Result.Status=isNumericalBreakdown then Break;
    MaxResidual:=0;
    for I:=0 to Degree-1 do
    begin
      Value:=EvaluatePolynomialComplex(Coefficients,Current[I]);
      Inc(Result.Evaluations);
      if not Value.IsFinite then
      begin
        Result.Status:=isNumericalBreakdown;
        Break;
      end;
      MaxResidual:=Max(MaxResidual,Value.Magnitude);
    end;
    if Result.Status=isNumericalBreakdown then Break;
    if MaxResidual<BestMaximum then
    begin
      BestMaximum:=MaxResidual;
      Best:=Copy(Current);
      Stale:=0;
    end
    else
      Inc(Stale);
    Limit:=AbsoluteTolerance+RelativeTolerance*
      Max(1.0,CoefficientScale);
    if (MaxResidual<=Limit) and
       (MaxUpdate<=AbsoluteTolerance+RelativeTolerance*Max(1.0,Radius)) then
    begin
      Result.Status:=isConverged;
      Break;
    end;
    if Stale>=50 then
    begin
      Result.Status:=isStagnation;
      Break;
    end;
  end;
  if Result.Status=isUnknown then
    Result.Status:=isIterationLimit;
  Result.Roots:=Copy(Best);
  SetLength(Result.Residuals,Degree);
  for I:=0 to Degree-1 do
  begin
    Value:=EvaluatePolynomialComplex(Coefficients,Result.Roots[I]);
    Inc(Result.Evaluations);
    if Value.IsFinite then
      Result.Residuals[I]:=Value.Magnitude
    else
      Result.Residuals[I]:=Infinity;
  end;
  SortPolynomialRoots(Result.Roots,Result.Residuals);
end;

class function TAdaptiveODEOptions.Defaults: TAdaptiveODEOptions;
begin
  Result:=Default(TAdaptiveODEOptions);
  Result.AbsoluteTolerance:=1E-9; Result.RelativeTolerance:=1E-7;
  Result.InitialStep:=0; Result.MinimumStep:=1E-12;
  Result.MaximumStep:=Infinity; Result.MaxSteps:=100000;
end;

function EvalODE(F:TODEVectorFunction; T:Double; const Y:TDoubleArray;
  N:Integer; var Evaluations:Integer):TDoubleArray;
begin Result:=F(T,Y); Inc(Evaluations);
  if Length(Result)<>N then raise EModellingError.CreateFmt(
    'SolveODE: derivative length %d; expected %d.',[Length(Result),N]);
  ValidateVector(Result,'SolveODE derivative'); end;

function Combine(const Y:TDoubleArray; H:Double; const K:TVectorSeries;
  const Coeff:array of Double):TDoubleArray;
var I,J:Integer; begin Result:=nil; SetLength(Result,Length(Y));
  for I:=0 to High(Y) do begin Result[I]:=Y[I];
    for J:=0 to High(Coeff) do Result[I]:=Result[I]+H*Coeff[J]*K[J][I]; end; end;

function EventCrossed(A,B:Double;Direction:Integer):Boolean;
begin case Direction of -1:Result:=(A>0) and (B<=0);
  1:Result:=(A<0) and (B>=0);
  else Result:=((A<=0) and (B>=0)) or ((A>=0) and (B<=0)); end; end;

class function TModellingKit.SolveODE(F: TODEVectorFunction; T0: Double;
  const Y0: TDoubleArray; T1: Double;
  const Options: TAdaptiveODEOptions): TAdaptiveODESolution;
var
  K:TVectorSeries; Y,YNew,Y4,Temp:TDoubleArray;
  T,H,Direction,Err,Scale,Ratio,Factor,EventPrev,EventNow:Double;
  EventLeft,EventRight,EventMid,EventValue:Double;
  EventY:TDoubleArray;
  I,N,Attempts,RejectStreak:Integer; Accept:Boolean;
begin
  Result:=Default(TAdaptiveODESolution);
  EventPrev:=0;
  if not Assigned(F) then raise EModellingError.Create(
    'SolveODE: derivative callback must be assigned.');
  ValidateVector(Y0,'SolveODE initial state'); N:=Length(Y0);
  if not IsFiniteValue(T0) or not IsFiniteValue(T1) or (T0=T1) then
    raise EModellingError.Create('SolveODE: require finite T0 <> T1.');
  if (Options.AbsoluteTolerance<0) or (Options.RelativeTolerance<0) or
     ((Length(Options.AbsoluteTolerances)=0) and
      (Options.AbsoluteTolerance+Options.RelativeTolerance<=0)) or
     (Options.MinimumStep<=0) or (Options.MaximumStep<=0) or
     (Options.MaxSteps<=0) then raise EModellingError.Create(
       'SolveODE: invalid options.');
  if (Length(Options.AbsoluteTolerances)<>0) and
     (Length(Options.AbsoluteTolerances)<>N) then
    raise EModellingError.Create(
      'SolveODE: per-component absolute tolerance length mismatch.');
  for I:=0 to High(Options.AbsoluteTolerances) do
    if not IsFiniteValue(Options.AbsoluteTolerances[I]) or
       (Options.AbsoluteTolerances[I]<0) or
       (Options.AbsoluteTolerances[I]+Options.RelativeTolerance<=0) then
      raise EModellingError.CreateFmt(
        'SolveODE: absolute tolerance %d is invalid.',[I]);
  Direction:=1; if T1<T0 then Direction:=-1;
  H:=Options.InitialStep;
  if H=0 then H:=Direction*Min(Abs(T1-T0)/100,0.01)
  else H:=Direction*Abs(H);
  H:=Direction*Min(Abs(H),Options.MaximumStep);
  T:=T0; Y:=Copy(Y0); SetLength(Result.T,1); Result.T[0]:=T;
  SetLength(Result.Y,1); Result.Y[0]:=Copy(Y);
  SetLength(Result.Derivatives,1); Result.Derivatives[0]:=EvalODE(F,T,Y,N,Result.Evaluations);
  if Assigned(Options.Event) then begin EventPrev:=Options.Event(T,Y);
    if not IsFiniteValue(EventPrev) then raise EModellingError.Create(
      'SolveODE: event callback returned non-finite value.'); end;
  RejectStreak:=0; Attempts:=0;
  while Direction*(T1-T)>0 do begin
    Inc(Attempts);
    if Attempts>Options.MaxSteps then begin Result.Status:=isIterationLimit; Break; end;
    if Abs(H)>Abs(T1-T) then H:=T1-T;
    SetLength(K,7); K[0]:=Copy(Result.Derivatives[High(Result.Derivatives)]);
    Temp:=Combine(Y,H,K,[1/5]); K[1]:=EvalODE(F,T+H*1/5,Temp,N,Result.Evaluations);
    Temp:=Combine(Y,H,K,[3/40,9/40]); K[2]:=EvalODE(F,T+H*3/10,Temp,N,Result.Evaluations);
    Temp:=Combine(Y,H,K,[44/45,-56/15,32/9]); K[3]:=EvalODE(F,T+H*4/5,Temp,N,Result.Evaluations);
    Temp:=Combine(Y,H,K,[19372/6561,-25360/2187,64448/6561,-212/729]);
    K[4]:=EvalODE(F,T+H*8/9,Temp,N,Result.Evaluations);
    Temp:=Combine(Y,H,K,[9017/3168,-355/33,46732/5247,49/176,-5103/18656]);
    K[5]:=EvalODE(F,T+H,Temp,N,Result.Evaluations);
    YNew:=Combine(Y,H,K,[35/384,0,500/1113,125/192,-2187/6784,11/84]);
    K[6]:=EvalODE(F,T+H,YNew,N,Result.Evaluations);
    Y4:=Combine(Y,H,K,[5179/57600,0,7571/16695,393/640,-92097/339200,187/2100,1/40]);
    Err:=0;
    for I:=0 to N-1 do begin
      if Length(Options.AbsoluteTolerances)>0 then
        Scale:=Options.AbsoluteTolerances[I]
      else
        Scale:=Options.AbsoluteTolerance;
      Scale:=Scale+Options.RelativeTolerance*
        Max(Abs(Y[I]),Abs(YNew[I]));
      Ratio:=Abs(YNew[I]-Y4[I])/Scale; if Ratio>Err then Err:=Ratio; end;
    Accept:=Err<=1;
    if Accept then begin
      T:=T+H; Y:=YNew; Inc(Result.AcceptedSteps); RejectStreak:=0;
      SetLength(Result.T,Length(Result.T)+1); Result.T[High(Result.T)]:=T;
      SetLength(Result.Y,Length(Result.Y)+1); Result.Y[High(Result.Y)]:=Copy(Y);
      SetLength(Result.Derivatives,Length(Result.Derivatives)+1);
      Result.Derivatives[High(Result.Derivatives)]:=Copy(K[6]);
      if Assigned(Options.Event) then begin EventNow:=Options.Event(T,Y);
        if not IsFiniteValue(EventNow) then raise EModellingError.Create(
          'SolveODE: event callback returned non-finite value.');
        if EventCrossed(EventPrev,EventNow,Options.EventDirection) then begin
          Result.EventFound:=True;
          EventLeft:=Result.T[High(Result.T)-1]; EventRight:=T;
          EventValue:=EventPrev;
          for I:=1 to 50 do
          begin
            EventMid:=EventLeft+(EventRight-EventLeft)/2;
            EventY:=Result.Evaluate(EventMid);
            EventNow:=Options.Event(EventMid,EventY);
            Inc(Result.Evaluations);
            if not IsFiniteValue(EventNow) then
              raise EModellingError.Create(
                'SolveODE: event callback returned non-finite value.');
            if ((EventValue<=0) and (EventNow>=0)) or
               ((EventValue>=0) and (EventNow<=0)) then
              EventRight:=EventMid
            else
            begin
              EventLeft:=EventMid;
              EventValue:=EventNow;
            end;
            if Abs(EventRight-EventLeft)<=
               Options.AbsoluteTolerance+
               Options.RelativeTolerance*Max(1,Abs(EventMid)) then Break;
          end;
          Result.EventTime:=EventLeft+(EventRight-EventLeft)/2;
          Result.EventState:=Result.Evaluate(Result.EventTime);
          Result.Status:=isConverged; Break; end;
        EventPrev:=EventNow; end;
      if Assigned(Options.Progress) and
         not Options.Progress(Result.AcceptedSteps,Result.Evaluations,T) then begin
        Result.Status:=isCancelled; Break; end;
    end else begin Inc(Result.RejectedSteps); Inc(RejectStreak); end;
    if Err=0 then Factor:=5 else Factor:=0.9*Power(Err,-0.2);
    Factor:=Min(5,Max(0.1,Factor)); H:=Direction*Min(Options.MaximumStep,Abs(H)*Factor);
    if Abs(H)<Options.MinimumStep then begin
      if Direction*(T1-T)<=Options.MinimumStep then H:=T1-T
      else begin Result.Status:=isStagnation; Break; end; end;
    if RejectStreak>=20 then begin Result.Status:=isStagnation; Break; end;
  end;
  if (Result.Status=isUnknown) and (Direction*(T1-T)<=0) then Result.Status:=isConverged;
end;

function TAdaptiveODESolution.Evaluate(Time: Double): TDoubleArray;
var
  Lo,Hi,Mid,I:Integer; H,S,H00,H10,H01,H11:Double;
begin
  if Length(T)=0 then raise EModellingError.Create(
    'AdaptiveODESolution.Evaluate: solution is empty.');
  if not IsFiniteValue(Time) then raise EModellingError.Create(
    'AdaptiveODESolution.Evaluate: time must be finite.');
  if Time<=T[0] then Exit(Copy(Y[0]));
  if Time>=T[High(T)] then Exit(Copy(Y[High(Y)]));
  Lo:=0; Hi:=High(T); while Hi-Lo>1 do begin Mid:=Lo+(Hi-Lo) div 2;
    if T[Mid]<=Time then Lo:=Mid else Hi:=Mid; end;
  H:=T[Lo+1]-T[Lo]; S:=(Time-T[Lo])/H;
  H00:=2*S*S*S-3*S*S+1; H10:=S*S*S-2*S*S+S;
  H01:=-2*S*S*S+3*S*S; H11:=S*S*S-S*S;
  SetLength(Result,Length(Y[Lo]));
  for I:=0 to High(Result) do Result[I]:=H00*Y[Lo][I]+H10*H*Derivatives[Lo][I]+
    H01*Y[Lo+1][I]+H11*H*Derivatives[Lo+1][I];
end;

end.
