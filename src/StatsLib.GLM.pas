unit StatsLib.GLM;

{ Canonical-link Bernoulli and Poisson GLMs. IRLS corrections use the shared
  pivoted QR; input storage is never mutated or retained. Result arrays own
  their storage, with normal Pascal array aliasing on record assignment. }

{$mode objfpc}{$H+}{$J-}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, Math, MathBase.SharedTypes,
  AlgebraLib.DenseMatrices, AlgebraLib.DenseDecompositions;

const
  GLM_MAX_FREQUENCY_COUNT = 2147483647;

type
  EGLMError = class(Exception);
  TGLMFamily = (gfBernoulliLogit, gfPoissonLog);
  TGLMStatus = (glsConverged, glsIterationLimit, glsRankDeficient,
    glsIllConditioned, glsCompleteSeparation, glsBoundary,
    glsNumericalFailure, glsStalled);

  TGLMOptions = record
    MaxIterations: Integer;
    Tolerance, RankTolerance, MinimumConditionIndicator: Double;
    class function Default: TGLMOptions; static;
  end;

  TGLMFrequencyWeights = array of QWord;

  TGLMInputs = record
    Offsets, Exposures: TDoubleArray;
    FrequencyWeights: TGLMFrequencyWeights;
    class function Default: TGLMInputs; static;
  end;

  TGLMFitResult = record
    Family: TGLMFamily;
    Status: TGLMStatus;
    Message: String;
    Iterations, Rank, DegreesOfFreedom: SizeInt;
    Identifiable, HasFiniteIterate: Boolean;
    UsesOffsets, UsesExposure: Boolean;
    FrequencyCount: SizeInt;
    DiagnosticRows: TIntegerArray;
    ConditionIndicator, Deviance, NullDeviance, PearsonChiSquare: Double;
    Coefficients, StandardErrors, FittedMeans, ResponseResiduals,
      DevianceResiduals, DevianceHistory: TDoubleArray;
  end;

  TGLMKit = class
  public
    class function FitLogistic(const Design: IDenseDoubleMatrix;
      const Response: TDoubleArray): TGLMFitResult; overload; static;
    class function FitLogistic(const Design: IDenseDoubleMatrix;
      const Response: TDoubleArray; const Options: TGLMOptions):
      TGLMFitResult; overload; static;
    class function FitPoisson(const Design: IDenseDoubleMatrix;
      const Response: TDoubleArray): TGLMFitResult; overload; static;
    class function FitPoisson(const Design: IDenseDoubleMatrix;
      const Response: TDoubleArray; const Options: TGLMOptions):
      TGLMFitResult; overload; static;
    class function FitLogistic(const Design: IDenseDoubleMatrix;
      const Response: TDoubleArray; const Inputs: TGLMInputs):
      TGLMFitResult; overload; static;
    class function FitLogistic(const Design: IDenseDoubleMatrix;
      const Response: TDoubleArray; const Inputs: TGLMInputs;
      const Options: TGLMOptions): TGLMFitResult; overload; static;
    class function FitPoisson(const Design: IDenseDoubleMatrix;
      const Response: TDoubleArray; const Inputs: TGLMInputs):
      TGLMFitResult; overload; static;
    class function FitPoisson(const Design: IDenseDoubleMatrix;
      const Response: TDoubleArray; const Inputs: TGLMInputs;
      const Options: TGLMOptions): TGLMFitResult; overload; static;
    class function PredictMean(const Fit: TGLMFitResult;
      const Design: IDenseDoubleMatrix): TDoubleArray; overload; static;
    class function PredictMean(const Fit: TGLMFitResult;
      const Design: IDenseDoubleMatrix; const Inputs: TGLMInputs):
      TDoubleArray; overload; static;
  end;

implementation

class function TGLMInputs.Default: TGLMInputs;
begin
  Result.Offsets := nil; Result.Exposures := nil;
  Result.FrequencyWeights := nil;
end;

class function TGLMOptions.Default: TGLMOptions;
begin
  Result.MaxIterations := 100;
  Result.Tolerance := 1E-8;
  Result.RankTolerance := 1E-12;
  Result.MinimumConditionIndicator := 1E-10;
end;

function Finite(const Value: Double): Boolean; inline;
begin
  Result := not IsNan(Value) and not IsInfinite(Value);
end;

function BuildOffsets(const Inputs: TGLMInputs; const Rows: SizeInt;
  const Family: TGLMFamily): TDoubleArray;
var I: SizeInt;
begin
  Result := nil;
  if ((Length(Inputs.Offsets) <> 0) and (Length(Inputs.Offsets) <> Rows)) or
     ((Length(Inputs.Exposures) <> 0) and (Length(Inputs.Exposures) <> Rows)) then
    raise EGLMError.Create('GLM inputs: offset/exposure lengths must match rows.');
  if (Family <> gfPoissonLog) and (Length(Inputs.Exposures) <> 0) then
    raise EGLMError.Create('GLM inputs: exposure requires the Poisson log link.');
  SetLength(Result, Rows);
  for I := 0 to Rows - 1 do
  begin
    if Length(Inputs.Offsets) <> 0 then
    begin
      if not Finite(Inputs.Offsets[I]) then
        raise EGLMError.Create('GLM inputs: offsets must be finite.');
      Result[I] := Inputs.Offsets[I];
    end;
    if Length(Inputs.Exposures) <> 0 then
    begin
      if not Finite(Inputs.Exposures[I]) or (Inputs.Exposures[I] <= 0) then
        raise EGLMError.Create('GLM inputs: exposures must be positive and finite.');
      Result[I] := Result[I] + Ln(Inputs.Exposures[I]);
    end;
    if not Finite(Result[I]) then
      raise EGLMError.Create('GLM inputs: combined offset is not representable.');
  end;
end;

function BuildFrequencies(const Inputs: TGLMInputs; const Rows: SizeInt;
  out Total: SizeInt; out DiagnosticRows: TIntegerArray): TDoubleArray;
var I, ActiveCount: SizeInt; Value: QWord;
begin
  Result := nil; DiagnosticRows := nil; Total := 0;
  if Length(Inputs.FrequencyWeights) = 0 then
  begin
    Total := Rows; SetLength(Result, Rows);
    for I := 0 to Rows - 1 do Result[I] := 1;
    Exit;
  end;
  if (Length(Inputs.FrequencyWeights) <> Rows) or
    (Rows > High(Integer)) then
    raise EGLMError.Create('GLM frequencies: weights must match representable rows.');
  ActiveCount := 0;
  for I := 0 to Rows - 1 do
  begin
    Value := Inputs.FrequencyWeights[I];
    if Value > QWord(GLM_MAX_FREQUENCY_COUNT) - QWord(Total) then
      raise EGLMError.Create('GLM frequencies: total exceeds the supported count.');
    Inc(Total, SizeInt(Value));
    if Value <> 0 then Inc(ActiveCount);
  end;
  if Total = 0 then raise EGLMError.Create('GLM frequencies: positive total required.');
  SetLength(Result, Rows); SetLength(DiagnosticRows, ActiveCount);
  ActiveCount := 0;
  for I := 0 to Rows - 1 do
  begin
    Result[I] := Inputs.FrequencyWeights[I];
    if Result[I] <> 0 then
    begin DiagnosticRows[ActiveCount] := I; Inc(ActiveCount); end;
  end;
end;

function ResponseAverage(const Y, Frequencies: TDoubleArray;
  const Total: SizeInt): Double;
var I: SizeInt;
begin
  Result := 0;
  for I := 0 to High(Y) do
    if Frequencies[I] <> 0 then
      Result := Result + (Y[I] / Total) * Frequencies[I];
  if not Finite(Result) then raise EGLMError.Create('GLM response average overflow.');
end;

function SelectDiagnosticRows(const Values: TDoubleArray;
  const Rows: TIntegerArray): TDoubleArray;
var I: SizeInt;
begin
  Result := nil;
  if Length(Values) = 0 then Exit;
  SetLength(Result, Length(Rows));
  for I := 0 to High(Rows) do Result[I] := Values[Rows[I]];
end;

procedure ValidateDesign(const Design: IDenseDoubleMatrix;
  const Operation: String);
var I, J: SizeInt;
begin
  if Design = nil then raise EGLMError.Create(Operation + ': design is nil.');
  if Design.Cols < 1 then
    raise EGLMError.Create(Operation + ': design needs at least one column.');
  for I := 0 to Design.Rows - 1 do
    for J := 0 to Design.Cols - 1 do
      if not Finite(Design[I, J]) then
        raise EGLMError.CreateFmt('%s: design[%d,%d] must be finite.',
          [Operation, I, J]);
end;

procedure ValidateFit(const Design: IDenseDoubleMatrix;
  const Response: TDoubleArray; const Options: TGLMOptions;
  const Family: TGLMFamily);
var I: SizeInt;
begin
  ValidateDesign(Design, 'GLM fit');
  if (Design.Rows < Design.Cols) or (Design.Rows < 1) or
     (Design.Rows <> Length(Response)) then
    raise EGLMError.Create('GLM fit: response length must equal rows, with rows >= columns.');
  if (Options.MaxIterations < 1) or (Options.MaxIterations > 10000) or
     not Finite(Options.Tolerance) or (Options.Tolerance <= 0) or
     (Options.Tolerance > Double(0.01)) or not Finite(Options.RankTolerance) or
     (Options.RankTolerance <= 0) or (Options.RankTolerance >= 1) or
     not Finite(Options.MinimumConditionIndicator) or
     (Options.MinimumConditionIndicator <= 0) or
     (Options.MinimumConditionIndicator > 1) then
    raise EGLMError.Create('GLM fit: invalid iteration, tolerance or condition options.');
  for I := 0 to High(Response) do
  begin
    if not Finite(Response[I]) then
      raise EGLMError.CreateFmt('GLM fit: response[%d] must be finite.', [I]);
    if Family = gfBernoulliLogit then
    begin
      if (Response[I] <> 0) and (Response[I] <> 1) then
        raise EGLMError.Create('FitLogistic: responses must be exactly zero or one.');
    end
    else if (Response[I] < 0) or (Frac(Response[I]) <> 0) then
      raise EGLMError.Create('FitPoisson: responses must be nonnegative integer counts.');
  end;
end;

function InverseLink(const Family: TGLMFamily; const Eta: Double;
  out Mean, Weight: Double): Boolean;
var E: Double;
begin
  Result := False;
  if not Finite(Eta) then Exit;
  if Family = gfBernoulliLogit then
  begin
    E := Exp(-Abs(Eta));
    if Eta >= 0 then Mean := 1 / (1 + E) else Mean := E / (1 + E);
    Weight := E / Sqr(1 + E);
  end
  else
  begin
    if Abs(Eta) > 700 then Exit;
    Mean := Exp(Eta); Weight := Mean;
  end;
  Result := Finite(Mean) and Finite(Weight);
end;

function Softplus(const Value: Double): Double;
begin
  { Explicit double operands avoid FPC selecting the Single Max overload. }
  Result := Max(Value, Double(0)) + LnXP1(Exp(-Abs(Value)));
end;

function UnitDeviance(const Family: TGLMFamily;
  const Y, Eta, Mean: Double): Double;
var R, Term, Total: Double; K: Integer;
begin
  if Family = gfBernoulliLogit then
  begin
    if Y = 1 then Result := 2 * Softplus(-Eta)
    else Result := 2 * Softplus(Eta);
  end
  else if Y = 0 then Result := 2 * Mean
  else
  begin
    R := (Mean - Y) / Y;
    if Abs(R) < 0.01 then
    begin
      { r-log(1+r) without cancellation at a nearly perfect count mean. }
      Term := Sqr(R); Total := Term / 2;
      for K := 3 to 20 do
      begin
        Term := -Term * R;
        Total := Total + Term / K;
      end;
      Result := 2 * Y * Total;
    end
    else Result := 2 * (Y * (Ln(Y) - Eta) - Y + Mean);
    Result := Max(Double(0), Result);
  end;
end;

function OffsetNullIntercept(const Y, Offsets, Frequencies: TDoubleArray;
  const Total: SizeInt; const Family: TGLMFamily): Double;
var I, Iteration: SizeInt; Average, Peak, LowOffset, Sum, Lower, Upper,
  Middle, Mean, Weight: Double;
begin
  Average := ResponseAverage(Y, Frequencies, Total);
  Peak := -Infinity; LowOffset := Infinity;
  for I := 0 to High(Y) do
    if Frequencies[I] <> 0 then
  begin
    Peak := Max(Peak, Offsets[I]); LowOffset := Min(LowOffset, Offsets[I]);
  end;
  if not Finite(Average) then raise EGLMError.Create('GLM null mean overflow.');
  if (Average = 0) or ((Family = gfBernoulliLogit) and (Average = 1)) then Exit(0);
  if Family = gfPoissonLog then
  begin
    Sum := 0;
    for I := 0 to High(Y) do
      if Frequencies[I] <> 0 then
        Sum := Sum + (Exp(Offsets[I] - Peak) / Total) * Frequencies[I];
    Result := (Ln(Average) - Peak) - Ln(Sum);
  end
  else
  begin
    Lower := -Peak - 40; Upper := -LowOffset + 40;
    Middle := 0;
    for Iteration := 1 to 200 do
    begin
      Middle := Lower / 2 + Upper / 2;
      if (Middle = Lower) or (Middle = Upper) then Break;
      Sum := 0;
      for I := 0 to High(Y) do
        if Frequencies[I] <> 0 then
      begin
        if not InverseLink(Family, Middle + Offsets[I], Mean, Weight) then
          raise EGLMError.Create('GLM null inverse link is not representable.');
        Sum := Sum + (Mean / Total) * Frequencies[I];
      end;
      if Sum < Average then Lower := Middle else Upper := Middle;
    end;
    Result := Middle;
  end;
  if not Finite(Result) then raise EGLMError.Create('GLM null intercept overflow.');
  Sum := 0;
  for I := 0 to High(Y) do
    if Frequencies[I] <> 0 then
  begin
    if not InverseLink(Family, Result + Offsets[I], Mean, Weight) then
      raise EGLMError.Create('GLM null inverse link is not representable.');
    Sum := Sum + (Mean / Total) * Frequencies[I];
  end;
  if Abs(Sum - Average) > 1E-10 * Max(Double(1), Average) then
    raise EGLMError.Create('GLM null intercept score is not representable.');
end;

function OffsetNullDeviance(const Y, Offsets, Frequencies: TDoubleArray;
  const Total: SizeInt; const Family: TGLMFamily): Double;
var I: SizeInt; Intercept, Eta, Mean, Weight, Average: Double;
begin
  Result := 0; Average := ResponseAverage(Y, Frequencies, Total);
  if (Average = 0) or ((Family = gfBernoulliLogit) and (Average = 1)) then Exit;
  Intercept := OffsetNullIntercept(Y, Offsets, Frequencies, Total, Family);
  for I := 0 to High(Y) do
    if Frequencies[I] <> 0 then
  begin
    Eta := Intercept + Offsets[I];
    if not InverseLink(Family, Eta, Mean, Weight) then
      raise EGLMError.Create('GLM null inverse link is not representable.');
    Result := Result + UnitDeviance(Family, Y[I], Eta, Mean) * Frequencies[I];
  end;
end;

function Evaluate(const X: IDenseDoubleMatrix;
  const Y, Beta, Offsets, Frequencies: TDoubleArray;
  const Family: TGLMFamily; out Means, Weights, Etas: TDoubleArray;
  out Deviance: Double): Boolean;
var I, J: SizeInt; Eta, Contribution: Double;
begin
  Result := False; Deviance := 0;
  Means := nil; Weights := nil; Etas := nil;
  SetLength(Means, X.Rows); SetLength(Weights, X.Rows); SetLength(Etas, X.Rows);
  for I := 0 to X.Rows - 1 do
  begin
    if Frequencies[I] = 0 then Continue;
    Eta := Offsets[I];
    for J := 0 to X.Cols - 1 do Eta := Eta + X[I,J] * Beta[J];
    Etas[I] := Eta;
    if not InverseLink(Family, Eta, Means[I], Weights[I]) or (Weights[I] <= 0) then Exit;
    Weights[I] := Weights[I] * Frequencies[I];
    if not Finite(Weights[I]) then Exit;
    Contribution := UnitDeviance(Family, Y[I], Eta, Means[I]) * Frequencies[I];
    if not Finite(Contribution) then Exit;
    Deviance := Deviance + Contribution;
    if not Finite(Deviance) then Exit;
  end;
  Result := True;
end;

function WeightedFactor(const X: IDenseDoubleMatrix; const Y, Means,
  Weights, Frequencies: TDoubleArray; const Total: SizeInt;
  const Options: TGLMOptions;
  out Target: IDenseDoubleMatrix; out MaximumRootWeight: Double): IDenseDoubleQR;
var A: IDenseDoubleMatrix; I, J: SizeInt; Root, MaximumVarianceRoot: Double;
begin
  MaximumRootWeight := 0; MaximumVarianceRoot := 0;
  for I := 0 to High(Weights) do
    if Frequencies[I] <> 0 then
  begin
    MaximumRootWeight := Max(MaximumRootWeight, Sqrt(Weights[I]));
    MaximumVarianceRoot := Max(MaximumVarianceRoot,
      Sqrt(Weights[I] / Frequencies[I]));
  end;
  A := TDenseDoubleMatrix.Zeros(X.Rows, X.Cols);
  Target := TDenseDoubleMatrix.Zeros(X.Rows, 1);
  for I := 0 to X.Rows - 1 do
  begin
    if Frequencies[I] = 0 then Continue;
    Root := Sqrt(Weights[I]);
    for J := 0 to X.Cols - 1 do A[I,J] := (Root / MaximumRootWeight) * X[I,J];
    Target[I,0] := ((Y[I] - Means[I]) / Root) *
      (Frequencies[I] / MaximumRootWeight);
    if not Finite(Target[I,0]) then
      raise EGLMError.Create('GLM IRLS: nonrepresentable weighted correction.');
  end;
  { Compact weighted rows and expanded repeated rows differ only by the
    maximum-root normalization. Preserve the expanded-design rank cutoff. }
  Result := FactorPivotedQR(A, (Options.RankTolerance * Sqrt(Total)) *
    (MaximumVarianceRoot / MaximumRootWeight));
end;

function CheckFactor(const Factor: IDenseDoubleQR; const Columns: SizeInt;
  const Options: TGLMOptions; var Fit: TGLMFitResult): Boolean;
begin
  Fit.Rank := Factor.NumericalRank;
  Fit.ConditionIndicator := Factor.ConditionIndicator;
  Result := False;
  if Fit.Rank < Columns then Fit.Status := glsRankDeficient
  else if Fit.ConditionIndicator < Options.MinimumConditionIndicator then
    Fit.Status := glsIllConditioned
  else Result := True;
end;

function BoundaryStatus(const Y, Etas, Frequencies: TDoubleArray;
  const Family: TGLMFamily; const X: IDenseDoubleMatrix;
  const Beta: TDoubleArray; out Status: TGLMStatus): Boolean;
var I, J: SizeInt; MaxEta, MinMargin, MaxEtaValue, DirectionEta: Double;
  AllZero: Boolean;
begin
  MaxEta := 0; MinMargin := Infinity; MaxEtaValue := -Infinity; AllZero := True;
  for I := 0 to High(Etas) do
    if Frequencies[I] <> 0 then
  begin
    DirectionEta := 0;
    for J := 0 to X.Cols - 1 do
      DirectionEta := DirectionEta + X[I,J] * Beta[J];
    MaxEta := Max(MaxEta, Abs(Etas[I]));
    MaxEtaValue := Max(MaxEtaValue, DirectionEta);
    MinMargin := Min(MinMargin, (2 * Y[I] - 1) * DirectionEta);
    AllZero := AllZero and (Y[I] = 0);
  end;
  Result := True;
  if (Family = gfBernoulliLogit) and
     (MinMargin > 1E-10 * Max(Double(1), MaxEta)) then Status := glsCompleteSeparation
  else if (Family = gfPoissonLog) and AllZero and
     (MaxEtaValue < -1E-10 * Max(Double(1), MaxEta)) then Status := glsBoundary
  else if ((Family = gfBernoulliLogit) and (MaxEta >= 36)) or
          ((Family = gfPoissonLog) and (MaxEta >= 700)) then Status := glsBoundary
  else Result := False;
end;

procedure StandardErrors(const Factor: IDenseDoubleQR;
  const Scales: TDoubleArray; const RootWeight: Double;
  out Errors: TDoubleArray);
var R: IDenseDoubleMatrix; Permutation: TSizeIntArray;
  Column, SumSquares: TDoubleArray; I, J, K, P: SizeInt; Value: Double;
begin
  P := Length(Scales); R := Factor.R; Permutation := Factor.Permutation;
  SetLength(SumSquares, P); SetLength(Column, P); SetLength(Errors, P);
  for K := 0 to P - 1 do
  begin
    for I := P - 1 downto 0 do
    begin
      if I = K then Value := 1 else Value := 0;
      for J := I + 1 to P - 1 do Value := Value - R[I,J] * Column[J];
      Column[I] := Value / R[I,I];
      SumSquares[I] := SumSquares[I] + Sqr(Column[I]);
    end;
  end;
  for I := 0 to P - 1 do
  begin
    J := Permutation[I];
    Errors[J] := (Sqrt(SumSquares[I]) / RootWeight) / Scales[J];
    if not Finite(Errors[J]) then
      raise EGLMError.Create('GLM information: nonrepresentable standard error.');
  end;
end;

procedure FinishDiagnostics(const Y, Etas, Means, Weights,
  Frequencies: TDoubleArray; const Total: SizeInt;
  var Fit: TGLMFitResult);
var I: SizeInt; Average, NullEta, NullMean, D, Residual: Double;
begin
  Fit.DegreesOfFreedom := Total - Fit.Rank;
  Fit.FittedMeans := Copy(Means);
  SetLength(Fit.ResponseResiduals, Length(Y));
  SetLength(Fit.DevianceResiduals, Length(Y));
  Average := ResponseAverage(Y, Frequencies, Total);
  if not Finite(Average) then raise EGLMError.Create('GLM null mean is not representable.');
  Fit.NullDeviance := 0; Fit.PearsonChiSquare := 0;
  if Fit.Family = gfBernoulliLogit then
  begin
    if (Average > 0) and (Average < 1) then NullEta := Ln(Average) - Ln(1-Average)
    else NullEta := 0;
  end
  else if Average > 0 then NullEta := Ln(Average) else NullEta := 0;
  NullMean := Average;
  for I := 0 to High(Y) do
    if Frequencies[I] <> 0 then
  begin
    Residual := Y[I] - Means[I]; Fit.ResponseResiduals[I] := Residual;
    D := UnitDeviance(Fit.Family, Y[I], Etas[I], Means[I]) * Frequencies[I];
    Fit.DevianceResiduals[I] := Sqrt(D);
    if Residual < 0 then Fit.DevianceResiduals[I] := -Fit.DevianceResiduals[I];
    Fit.PearsonChiSquare := Fit.PearsonChiSquare +
      Sqr((Residual / Sqrt(Weights[I])) * Frequencies[I]);
    if ((Fit.Family = gfBernoulliLogit) and (Average > 0) and (Average < 1)) or
       ((Fit.Family = gfPoissonLog) and (Average > 0)) then
      Fit.NullDeviance := Fit.NullDeviance +
        UnitDeviance(Fit.Family, Y[I], NullEta, NullMean) * Frequencies[I];
  end;
end;

function FitModel(const Design: IDenseDoubleMatrix; const Y: TDoubleArray;
  const Inputs: TGLMInputs; const Options: TGLMOptions;
  const Family: TGLMFamily): TGLMFitResult;
const Messages: array[TGLMStatus] of String = (
  'Converged with full-rank finite information.', 'IRLS iteration limit reached.',
  'Design or weighted information is rank deficient.',
  'QR condition indicator is below the requested minimum.',
  'Strict signed margins certify complete separation; no finite logistic MLE.',
  'Boundary estimate or inverse-link information limit; no reliable finite MLE.',
  'A numerical result is not representable; last finite iterate retained.',
  'No finite non-increasing deviance step was found.');
var X, Target, Solution: IDenseDoubleMatrix; Factor: IDenseDoubleQR;
  Scales, Beta, Candidate, Means, Weights, Etas, NewMeans, NewWeights,
    NewEtas, Offsets, Frequencies: TDoubleArray;
  DiagnosticRows: TIntegerArray;
  I, J, Iteration, Halving, FrequencyCount: SizeInt;
  RootWeight, NewDeviance, OldDeviance, Step, Change, BetaNorm, FullChange,
    Average, LinearChange, EtaNorm, Correction, InitialIntercept: Double;
  Accepted, Representable, ConstantColumn: Boolean;
begin
  ValidateFit(Design, Y, Options, Family);
  Frequencies := BuildFrequencies(Inputs, Design.Rows, FrequencyCount, DiagnosticRows);
  Offsets := BuildOffsets(Inputs, Design.Rows, Family);
  Result := Default(TGLMFitResult); Result.Family := Family;
  Result.UsesOffsets := Length(Inputs.Offsets) <> 0;
  Result.UsesExposure := Length(Inputs.Exposures) <> 0;
  Result.FrequencyCount := FrequencyCount;
  Result.Status := glsIterationLimit;
  SetLength(Scales, Design.Cols); SetLength(Beta, Design.Cols);
  SetLength(Candidate, Design.Cols); SetLength(Result.Coefficients, Design.Cols);
  X := TDenseDoubleMatrix.Zeros(Design.Rows, Design.Cols);
  for J := 0 to Design.Cols - 1 do
  begin
    for I := 0 to Design.Rows - 1 do
      if Frequencies[I] <> 0 then Scales[J] := Max(Scales[J], Abs(Design[I,J]));
    if Scales[J] = 0 then Scales[J] := 1;
    for I := 0 to Design.Rows - 1 do
      if Frequencies[I] <> 0 then X[I,J] := Design[I,J] / Scales[J];
  end;
  try
    if Family = gfPoissonLog then
    begin
      Average := ResponseAverage(Y, Frequencies, FrequencyCount);
      if Finite(Average) and (Average > 0) and (Ln(Average) < 700) then
      begin
        InitialIntercept := Ln(Average);
        for J := 0 to X.Cols - 1 do
        begin
          Correction := 0;
          for I := 0 to X.Rows - 1 do
            if Frequencies[I] <> 0 then begin Correction := X[I,J]; Break; end;
          ConstantColumn := Correction <> 0;
          for I := 0 to X.Rows - 1 do
            if Frequencies[I] <> 0 then
              ConstantColumn := ConstantColumn and (X[I,J] = Correction);
          if ConstantColumn then
          begin
            if Result.UsesOffsets or Result.UsesExposure then
              InitialIntercept := OffsetNullIntercept(Y, Offsets, Frequencies,
                FrequencyCount, Family);
            Beta[J] := InitialIntercept / Correction; Break;
          end;
        end;
      end;
    end;
    if not Evaluate(X, Y, Beta, Offsets, Frequencies, Family,
      Means, Weights, Etas, Result.Deviance) then
      raise EGLMError.Create('GLM initial objective is not representable.');
    Result.HasFiniteIterate := True;
    SetLength(Result.DevianceHistory, 1); Result.DevianceHistory[0] := Result.Deviance;
    for Iteration := 1 to Options.MaxIterations do
    begin
      Factor := WeightedFactor(X, Y, Means, Weights, Frequencies,
        FrequencyCount, Options, Target, RootWeight);
      if not CheckFactor(Factor, X.Cols, Options, Result) then Break;
      Solution := Factor.SolveLeastSquares(Target);
      Change := 0; BetaNorm := 0;
      for J := 0 to X.Cols - 1 do
      begin
        Change := Max(Change, Abs(Solution[J,0]));
        BetaNorm := Max(BetaNorm, Abs(Beta[J]));
      end;
      FullChange := Change;
      LinearChange := 0; EtaNorm := 0;
      for I := 0 to X.Rows - 1 do
      begin
        Correction := 0;
        for J := 0 to X.Cols - 1 do Correction := Correction + X[I,J] * Solution[J,0];
        LinearChange := Max(LinearChange, Abs(Correction));
        EtaNorm := Max(EtaNorm, Abs(Etas[I]));
      end;
      if (LinearChange <= Options.Tolerance * (1 + EtaNorm)) and
         (Change <= Options.Tolerance * (1 + BetaNorm)) and
         ((Length(Result.DevianceHistory) = 1) or
          (Result.DevianceHistory[Length(Result.DevianceHistory)-2] - Result.Deviance
           <= Options.Tolerance * (1 + Result.Deviance))) then
      begin Result.Status := glsConverged; Break; end;
      OldDeviance := Result.Deviance; Step := 1; Accepted := False;
      for Halving := 0 to 40 do
      begin
        Representable := True;
        for J := 0 to X.Cols - 1 do
        begin
          Candidate[J] := Beta[J] + Step * Solution[J,0];
          Representable := Representable and Finite(Candidate[J] / Scales[J]);
        end;
        if Representable and Evaluate(X, Y, Candidate, Offsets, Frequencies, Family,
           NewMeans, NewWeights, NewEtas, NewDeviance)
           and (NewDeviance <= OldDeviance +
             8 * 2.2204460492503131E-16 * (1 + OldDeviance)) then
        begin Accepted := True; Break; end;
        Step := Step / 2;
      end;
      if not Accepted then
      begin
        if not Representable then Result.Status := glsNumericalFailure
        else Result.Status := glsStalled;
        Break;
      end;
      Change := 0; BetaNorm := 0;
      for J := 0 to X.Cols - 1 do
      begin
        Change := Max(Change, Abs(Candidate[J] - Beta[J]));
        BetaNorm := Max(BetaNorm, Abs(Candidate[J]));
      end;
      Beta := Copy(Candidate); Means := NewMeans; Weights := NewWeights; Etas := NewEtas;
      Result.Deviance := NewDeviance; Result.Iterations := Iteration;
      SetLength(Result.DevianceHistory, Length(Result.DevianceHistory) + 1);
      Result.DevianceHistory[High(Result.DevianceHistory)] := NewDeviance;
      if BoundaryStatus(Y, Etas, Frequencies, Family, X, Beta, Result.Status) then Break;
      if (FullChange <= Options.Tolerance * (1 + BetaNorm)) and
         (LinearChange <= Options.Tolerance * (1 + EtaNorm)) and
         (OldDeviance - NewDeviance <= Options.Tolerance * (1 + NewDeviance)) then
      begin
        Result.Status := glsConverged; Break;
      end;
    end;
    { Recompute information at the accepted final iterate, not the preceding
      IRLS point. Inferential diagnostics are withheld on every failed fit. }
    if Result.Status = glsConverged then
    begin
      Factor := WeightedFactor(X, Y, Means, Weights, Frequencies,
        FrequencyCount, Options, Target, RootWeight);
      if CheckFactor(Factor, X.Cols, Options, Result) then
        StandardErrors(Factor, Scales, RootWeight, Result.StandardErrors);
    end;
    for J := 0 to X.Cols - 1 do
    begin
      Result.Coefficients[J] := Beta[J] / Scales[J];
      if not Finite(Result.Coefficients[J]) then
        raise EGLMError.Create('GLM coefficient is not representable.');
    end;
    FinishDiagnostics(Y, Etas, Means, Weights, Frequencies, FrequencyCount, Result);
    if Result.UsesOffsets or Result.UsesExposure then
      Result.NullDeviance := OffsetNullDeviance(Y, Offsets, Frequencies,
        FrequencyCount, Family);
    if not Finite(Result.PearsonChiSquare) or not Finite(Result.NullDeviance) then
      raise EGLMError.Create('GLM diagnostics are not representable.');
  except
    on EGLMError do Result.Status := glsNumericalFailure;
    on EDenseMatrixError do Result.Status := glsNumericalFailure;
    on EMathError do Result.Status := glsNumericalFailure;
  end;
  if not Result.HasFiniteIterate then
  begin
    Result.Deviance := 0; Result.NullDeviance := 0; Result.PearsonChiSquare := 0;
    Result.FittedMeans := nil; Result.ResponseResiduals := nil;
    Result.DevianceResiduals := nil; Result.DevianceHistory := nil;
  end;
  for J := 0 to X.Cols - 1 do Result.Coefficients[J] := Beta[J] / Scales[J];
  if Result.HasFiniteIterate then Result.FittedMeans := Copy(Means);
  if Result.Status = glsNumericalFailure then
  begin
    Result.NullDeviance := 0; Result.PearsonChiSquare := 0;
    Result.ResponseResiduals := nil; Result.DevianceResiduals := nil;
  end;
  Result.Identifiable := Result.Status = glsConverged;
  if not Result.Identifiable then Result.StandardErrors := nil;
  Result.Message := Messages[Result.Status];
  if Length(Inputs.FrequencyWeights) <> 0 then
  begin
    Result.DiagnosticRows := DiagnosticRows;
    Result.FittedMeans := SelectDiagnosticRows(Result.FittedMeans, DiagnosticRows);
    Result.ResponseResiduals := SelectDiagnosticRows(Result.ResponseResiduals, DiagnosticRows);
    Result.DevianceResiduals := SelectDiagnosticRows(Result.DevianceResiduals, DiagnosticRows);
  end;
end;

class function TGLMKit.FitLogistic(const Design: IDenseDoubleMatrix;
  const Response: TDoubleArray): TGLMFitResult;
begin Result := FitLogistic(Design, Response, TGLMOptions.Default); end;

class function TGLMKit.FitLogistic(const Design: IDenseDoubleMatrix;
  const Response: TDoubleArray; const Options: TGLMOptions): TGLMFitResult;
begin Result := FitModel(Design, Response, TGLMInputs.Default, Options, gfBernoulliLogit); end;

class function TGLMKit.FitPoisson(const Design: IDenseDoubleMatrix;
  const Response: TDoubleArray): TGLMFitResult;
begin Result := FitPoisson(Design, Response, TGLMOptions.Default); end;

class function TGLMKit.FitPoisson(const Design: IDenseDoubleMatrix;
  const Response: TDoubleArray; const Options: TGLMOptions): TGLMFitResult;
begin Result := FitModel(Design, Response, TGLMInputs.Default, Options, gfPoissonLog); end;

class function TGLMKit.FitLogistic(const Design: IDenseDoubleMatrix;
  const Response: TDoubleArray; const Inputs: TGLMInputs): TGLMFitResult;
begin Result := FitLogistic(Design, Response, Inputs, TGLMOptions.Default); end;

class function TGLMKit.FitLogistic(const Design: IDenseDoubleMatrix;
  const Response: TDoubleArray; const Inputs: TGLMInputs;
  const Options: TGLMOptions): TGLMFitResult;
begin Result := FitModel(Design, Response, Inputs, Options, gfBernoulliLogit); end;

class function TGLMKit.FitPoisson(const Design: IDenseDoubleMatrix;
  const Response: TDoubleArray; const Inputs: TGLMInputs): TGLMFitResult;
begin Result := FitPoisson(Design, Response, Inputs, TGLMOptions.Default); end;

class function TGLMKit.FitPoisson(const Design: IDenseDoubleMatrix;
  const Response: TDoubleArray; const Inputs: TGLMInputs;
  const Options: TGLMOptions): TGLMFitResult;
begin Result := FitModel(Design, Response, Inputs, Options, gfPoissonLog); end;

class function TGLMKit.PredictMean(const Fit: TGLMFitResult;
  const Design: IDenseDoubleMatrix): TDoubleArray;
begin Result := PredictMean(Fit, Design, TGLMInputs.Default); end;

class function TGLMKit.PredictMean(const Fit: TGLMFitResult;
  const Design: IDenseDoubleMatrix; const Inputs: TGLMInputs): TDoubleArray;
var I, J: SizeInt; Eta, Weight: Double; Offsets: TDoubleArray;
begin
  Result := nil;
  if (Fit.Status <> glsConverged) or not Fit.Identifiable or
     not (Fit.Family in [gfBernoulliLogit, gfPoissonLog]) then
    raise EGLMError.Create('PredictMean: a converged identifiable GLM fit is required.');
  ValidateDesign(Design, 'PredictMean');
  if Length(Inputs.FrequencyWeights) <> 0 then
    raise EGLMError.Create('PredictMean: frequency weights are training inputs only.');
  if (Design.Rows > 0) and
    ((Fit.UsesOffsets <> (Length(Inputs.Offsets) <> 0)) or
     (Fit.UsesExposure <> (Length(Inputs.Exposures) <> 0))) then
    raise EGLMError.Create('PredictMean: new rows require the fitted offset/exposure kinds.');
  Offsets := BuildOffsets(Inputs, Design.Rows, Fit.Family);
  if Design.Cols <> Length(Fit.Coefficients) then
    raise EGLMError.Create('PredictMean: design columns must match coefficient count.');
  for J := 0 to High(Fit.Coefficients) do
    if not Finite(Fit.Coefficients[J]) then
      raise EGLMError.Create('PredictMean: coefficients must be finite.');
  SetLength(Result, Design.Rows);
  try
    for I := 0 to Design.Rows - 1 do
    begin
      Eta := Offsets[I];
      for J := 0 to Design.Cols - 1 do Eta := Eta + Design[I,J] * Fit.Coefficients[J];
      if not InverseLink(Fit.Family, Eta, Result[I], Weight) then
        raise EGLMError.Create('PredictMean: inverse link is not representable.');
    end;
  except
    on E: EMathError do
      raise EGLMError.Create('PredictMean: linear predictor is not representable.');
  end;
end;

end.
