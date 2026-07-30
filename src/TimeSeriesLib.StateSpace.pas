unit TimeSeriesLib.StateSpace;

{-----------------------------------------------------------------------------
 TimeSeriesLib.StateSpace

 Scalar linear-Gaussian Kalman filtering with explicit, bounded state.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, Math, MathBase.SharedTypes,
  AlgebraLib.DenseMatrices, AlgebraLib.DenseSolvers,
  AlgebraLib.DenseDecompositions;

type
  EStateSpaceError = class(Exception);

  TScalarKalmanConfiguration = record
    Transition: Double;
    Observation: Double;
    ProcessVariance: Double;
    MeasurementVariance: Double;
    class function Create(const ATransition, AObservation,
      AProcessVariance, AMeasurementVariance: Double):
      TScalarKalmanConfiguration; static;
  end;

  TKalmanSeriesResult = record
    Estimates: TDoubleArray;
    Variances: TDoubleArray;
    Innovations: TDoubleArray;
    InnovationVariances: TDoubleArray;
    LogLikelihood: Double;
  end;

  TKalmanForecast = record
    Means: TDoubleArray;
    Variances: TDoubleArray;
  end;

  TScalarKalmanFilter = record
  private
    FConfiguration: TScalarKalmanConfiguration;
    FEstimate: Double;
    FCovariance: Double;
    procedure PredictInPlace;
    procedure UpdateInPlace(const Measurement: Double;
      out Innovation, InnovationVariance: Double);
  public
    class function Create(const Configuration: TScalarKalmanConfiguration;
      const InitialEstimate, InitialVariance: Double):
      TScalarKalmanFilter; static;
    procedure Reset(const InitialEstimate, InitialVariance: Double);
    procedure Predict;
    procedure Update(const Measurement: Double);
    function Process(const Measurements: TDoubleArray):
      TKalmanSeriesResult;
    function Forecast(const StepCount: SizeInt): TKalmanForecast;
    property Estimate: Double read FEstimate;
    property Variance: Double read FCovariance;
    property Configuration: TScalarKalmanConfiguration read FConfiguration;
  end;

  TDenseDoubleMatrixArray = array of IDenseDoubleMatrix;

  TMultivariateKalmanConfiguration = record
    Transition:IDenseDoubleMatrix;
    Observation:IDenseDoubleMatrix;
    ProcessCovariance:IDenseDoubleMatrix;
    MeasurementCovariance:IDenseDoubleMatrix;
    class function Create(const ATransition,AObservation,
      AProcessCovariance,AMeasurementCovariance:IDenseDoubleMatrix):
      TMultivariateKalmanConfiguration; static;
  end;

  TMultivariateKalmanStep = record
    StateMean:TDoubleArray;
    StateCovariance:IDenseDoubleMatrix;
    Innovation:TDoubleArray;
    InnovationCovariance:IDenseDoubleMatrix;
    LogLikelihood:Double;
  end;

  TMultivariateKalmanSeriesResult = record
    StateMeans:IDenseDoubleMatrix;
    StateCovariances:TDenseDoubleMatrixArray;
    Innovations:IDenseDoubleMatrix;
    InnovationCovariances:TDenseDoubleMatrixArray;
    LogLikelihood:Double;
  end;

  TMultivariateKalmanForecast = record
    ObservationMeans:IDenseDoubleMatrix;
    ObservationCovariances:TDenseDoubleMatrixArray;
  end;

  TMultivariateKalmanFilter = record
  private
    FConfiguration:TMultivariateKalmanConfiguration;
    FStateMean:TDoubleArray;
    FStateCovariance:IDenseDoubleMatrix;
    procedure PredictInPlace;
    function UpdateInPlace(const Measurement:TDoubleArray):
      TMultivariateKalmanStep;
  public
    class function Create(const Configuration:TMultivariateKalmanConfiguration;
      const InitialMean:TDoubleArray;
      const InitialCovariance:IDenseDoubleMatrix):TMultivariateKalmanFilter;
      static;
    procedure Reset(const InitialMean:TDoubleArray;
      const InitialCovariance:IDenseDoubleMatrix);
    procedure Predict;
    function Update(const Measurement:TDoubleArray):TMultivariateKalmanStep;
    function Process(const Measurements:IDenseDoubleMatrix):
      TMultivariateKalmanSeriesResult;
    function Forecast(const StepCount:SizeInt):TMultivariateKalmanForecast;
    function StateMean:TDoubleArray;
    function StateCovariance:IDenseDoubleMatrix;
    function StateSize:SizeInt;
  end;

implementation

const
  STATE_SPACE_PI: Double = 3.141592653589793238462643383279502884;

procedure RequireFinite(const Value: Double; const Name, Operation: string);
begin
  if IsNan(Value) or IsInfinite(Value) then
    raise EStateSpaceError.CreateFmt('%s: %s must be finite.',
      [Operation, Name]);
end;

procedure ValidateConfiguration(
  const Configuration: TScalarKalmanConfiguration);
begin
  RequireFinite(Configuration.Transition, 'Transition',
    'TScalarKalmanConfiguration');
  RequireFinite(Configuration.Observation, 'Observation',
    'TScalarKalmanConfiguration');
  RequireFinite(Configuration.ProcessVariance, 'ProcessVariance',
    'TScalarKalmanConfiguration');
  RequireFinite(Configuration.MeasurementVariance, 'MeasurementVariance',
    'TScalarKalmanConfiguration');
  if Configuration.Observation = 0.0 then
    raise EStateSpaceError.Create(
      'TScalarKalmanConfiguration: Observation must be non-zero.');
  if Configuration.ProcessVariance < 0.0 then
    raise EStateSpaceError.Create(
      'TScalarKalmanConfiguration: ProcessVariance must be non-negative.');
  if Configuration.MeasurementVariance <= 0.0 then
    raise EStateSpaceError.Create(
      'TScalarKalmanConfiguration: MeasurementVariance must be positive.');
end;

class function TScalarKalmanConfiguration.Create(const ATransition,
  AObservation, AProcessVariance, AMeasurementVariance: Double):
  TScalarKalmanConfiguration;
begin
  Result.Transition := ATransition;
  Result.Observation := AObservation;
  Result.ProcessVariance := AProcessVariance;
  Result.MeasurementVariance := AMeasurementVariance;
  ValidateConfiguration(Result);
end;

class function TScalarKalmanFilter.Create(
  const Configuration: TScalarKalmanConfiguration;
  const InitialEstimate, InitialVariance: Double): TScalarKalmanFilter;
begin
  ValidateConfiguration(Configuration);
  Result.FConfiguration := Configuration;
  Result.Reset(InitialEstimate, InitialVariance);
end;

procedure TScalarKalmanFilter.Reset(const InitialEstimate,
  InitialVariance: Double);
begin
  ValidateConfiguration(FConfiguration);
  RequireFinite(InitialEstimate, 'InitialEstimate',
    'TScalarKalmanFilter.Reset');
  RequireFinite(InitialVariance, 'InitialVariance',
    'TScalarKalmanFilter.Reset');
  if InitialVariance < 0.0 then
    raise EStateSpaceError.Create(
      'TScalarKalmanFilter.Reset: InitialVariance must be non-negative.');
  FEstimate := InitialEstimate;
  FCovariance := InitialVariance;
end;

procedure TScalarKalmanFilter.PredictInPlace;
begin
  FEstimate := FConfiguration.Transition * FEstimate;
  FCovariance := Sqr(FConfiguration.Transition) * FCovariance +
    FConfiguration.ProcessVariance;
  if IsNan(FEstimate) or IsInfinite(FEstimate) or
     IsNan(FCovariance) or IsInfinite(FCovariance) then
    raise EStateSpaceError.Create(
      'TScalarKalmanFilter.Predict: numerical overflow.');
end;

procedure TScalarKalmanFilter.UpdateInPlace(const Measurement: Double;
  out Innovation, InnovationVariance: Double);
var
  Gain, OneMinusGainObservation: Double;
begin
  Innovation := Measurement - FConfiguration.Observation * FEstimate;
  InnovationVariance := Sqr(FConfiguration.Observation) * FCovariance +
    FConfiguration.MeasurementVariance;
  if IsNan(InnovationVariance) or IsInfinite(InnovationVariance) or
     (InnovationVariance <= 0.0) then
    raise EStateSpaceError.Create(
      'TScalarKalmanFilter.Update: innovation variance must remain finite and positive.');
  Gain := FCovariance * FConfiguration.Observation / InnovationVariance;
  FEstimate := FEstimate + Gain * Innovation;
  { Joseph scalar form preserves non-negative covariance under rounding. }
  OneMinusGainObservation := 1.0 - Gain * FConfiguration.Observation;
  FCovariance := Sqr(OneMinusGainObservation) * FCovariance +
    Sqr(Gain) * FConfiguration.MeasurementVariance;
  if IsNan(FEstimate) or IsInfinite(FEstimate) or
     IsNan(FCovariance) or IsInfinite(FCovariance) then
    raise EStateSpaceError.Create(
      'TScalarKalmanFilter.Update: numerical overflow.');
end;

procedure TScalarKalmanFilter.Predict;
var
  Work: TScalarKalmanFilter;
begin
  Work := Self;
  Work.PredictInPlace;
  Self := Work;
end;

procedure TScalarKalmanFilter.Update(const Measurement: Double);
var
  Work: TScalarKalmanFilter;
  Innovation, InnovationVariance: Double;
begin
  RequireFinite(Measurement, 'Measurement', 'TScalarKalmanFilter.Update');
  Work := Self;
  Work.UpdateInPlace(Measurement, Innovation, InnovationVariance);
  Self := Work;
end;

function TScalarKalmanFilter.Process(const Measurements: TDoubleArray):
  TKalmanSeriesResult;
var
  Work: TScalarKalmanFilter;
  I: SizeInt;
  Innovation, InnovationVariance, Contribution, NewLogLikelihood: Double;
begin
  Result.Estimates := nil;
  Result.Variances := nil;
  Result.Innovations := nil;
  Result.InnovationVariances := nil;
  Result.LogLikelihood := 0.0;
  for I := 0 to High(Measurements) do
    RequireFinite(Measurements[I], Format('Measurements[%d]', [I]),
      'TScalarKalmanFilter.Process');
  SetLength(Result.Estimates, Length(Measurements));
  SetLength(Result.Variances, Length(Measurements));
  SetLength(Result.Innovations, Length(Measurements));
  SetLength(Result.InnovationVariances, Length(Measurements));
  Work := Self;
  for I := 0 to High(Measurements) do
  begin
    Work.PredictInPlace;
    Work.UpdateInPlace(Measurements[I], Innovation, InnovationVariance);
    Result.Estimates[I] := Work.FEstimate;
    Result.Variances[I] := Work.FCovariance;
    Result.Innovations[I] := Innovation;
    Result.InnovationVariances[I] := InnovationVariance;
    Contribution := -0.5 *
      (Ln(2.0 * STATE_SPACE_PI * InnovationVariance) +
       Sqr(Innovation) / InnovationVariance);
    NewLogLikelihood := Result.LogLikelihood + Contribution;
    if IsNan(NewLogLikelihood) or IsInfinite(NewLogLikelihood) then
      raise EStateSpaceError.CreateFmt(
        'TScalarKalmanFilter.Process: log-likelihood overflow at sample %d.',
        [I]);
    Result.LogLikelihood := NewLogLikelihood;
  end;
  Self := Work;
end;

function TScalarKalmanFilter.Forecast(const StepCount: SizeInt):
  TKalmanForecast;
var
  Work: TScalarKalmanFilter;
  I: SizeInt;
begin
  Result.Means := nil;
  Result.Variances := nil;
  if StepCount < 0 then
    raise EStateSpaceError.Create(
      'TScalarKalmanFilter.Forecast: StepCount must be non-negative.');
  SetLength(Result.Means, StepCount);
  SetLength(Result.Variances, StepCount);
  Work := Self;
  for I := 0 to StepCount - 1 do
  begin
    Work.PredictInPlace;
    Result.Means[I] := FConfiguration.Observation * Work.FEstimate;
    Result.Variances[I] := Sqr(FConfiguration.Observation) *
      Work.FCovariance + FConfiguration.MeasurementVariance;
    if IsNan(Result.Means[I]) or IsInfinite(Result.Means[I]) or
       IsNan(Result.Variances[I]) or IsInfinite(Result.Variances[I]) then
      raise EStateSpaceError.CreateFmt(
        'TScalarKalmanFilter.Forecast: numerical overflow at step %d.', [I]);
  end;
end;

procedure RequireFiniteMatrix(const Value:IDenseDoubleMatrix;
  const Name,Operation:String);
var I,J:Integer;
begin
  if Value=nil then
    raise EStateSpaceError.CreateFmt('%s: %s must not be nil.',
      [Operation,Name]);
  for I:=0 to Value.Rows-1 do for J:=0 to Value.Cols-1 do
    RequireFinite(Value[I,J],Format('%s[%d,%d]',[Name,I,J]),Operation);
end;

procedure ValidateCovariance(const Value:IDenseDoubleMatrix;
  Dimension:Integer; PositiveDefinite:Boolean; const Name:String);
var
  I,J:Integer;
  Eigen:IDenseDoubleSymmetricEigen;
  Eigenvalues:TDoubleArray;
  Scale,Tolerance:Double;
begin
  RequireFiniteMatrix(Value,Name,'TMultivariateKalmanConfiguration');
  if (Value.Rows<>Dimension) or (Value.Cols<>Dimension) then
    raise EStateSpaceError.CreateFmt(
      'TMultivariateKalmanConfiguration: %s must be %dx%d.',
      [Name,Dimension,Dimension]);
  for I:=0 to Dimension-1 do for J:=I+1 to Dimension-1 do
    if Abs(Value[I,J]-Value[J,I])>
       1E-12*Max(1,Max(Abs(Value[I,J]),Abs(Value[J,I]))) then
      raise EStateSpaceError.CreateFmt(
        'TMultivariateKalmanConfiguration: %s must be symmetric.',[Name]);
  try
    Eigen:=FactorSymmetricEigen(Value);
  except
    on E:Exception do raise EStateSpaceError.CreateFmt(
      'TMultivariateKalmanConfiguration: %s eigensystem failed: %s',
      [Name,E.Message]);
  end;
  Eigenvalues:=Eigen.Eigenvalues; Scale:=1;
  if Length(Eigenvalues)>0 then
    Scale:=Max(Scale,Abs(Eigenvalues[High(Eigenvalues)]));
  Tolerance:=1E-11*Scale;
  if PositiveDefinite then
  begin
    if (Length(Eigenvalues)=0) or (Eigenvalues[0]<=Tolerance) then
      raise EStateSpaceError.CreateFmt(
        'TMultivariateKalmanConfiguration: %s must be positive definite.',
        [Name]);
  end
  else if (Length(Eigenvalues)>0) and (Eigenvalues[0]<-Tolerance) then
    raise EStateSpaceError.CreateFmt(
      'TMultivariateKalmanConfiguration: %s must be positive semidefinite.',
      [Name]);
end;

procedure ValidateConfiguration(
  const Configuration:TMultivariateKalmanConfiguration);
var N,M:Integer;
begin
  RequireFiniteMatrix(Configuration.Transition,'Transition',
    'TMultivariateKalmanConfiguration');
  if (Configuration.Transition.Rows<1) or
     (Configuration.Transition.Rows<>Configuration.Transition.Cols) then
    raise EStateSpaceError.Create(
      'TMultivariateKalmanConfiguration: Transition must be non-empty and square.');
  N:=Configuration.Transition.Rows;
  RequireFiniteMatrix(Configuration.Observation,'Observation',
    'TMultivariateKalmanConfiguration');
  if (Configuration.Observation.Rows<1) or
     (Configuration.Observation.Cols<>N) then
    raise EStateSpaceError.Create(
      'TMultivariateKalmanConfiguration: Observation columns must match the state dimension.');
  M:=Configuration.Observation.Rows;
  ValidateCovariance(Configuration.ProcessCovariance,N,False,
    'ProcessCovariance');
  ValidateCovariance(Configuration.MeasurementCovariance,M,True,
    'MeasurementCovariance');
end;

function MatrixTranspose(const A:IDenseDoubleMatrix):IDenseDoubleMatrix;
var I,J:Integer;
begin
  Result:=TDenseDoubleMatrix.Zeros(A.Cols,A.Rows);
  for I:=0 to A.Rows-1 do for J:=0 to A.Cols-1 do
    Result[J,I]:=A[I,J];
end;

function MatrixMultiply(const A,B:IDenseDoubleMatrix):IDenseDoubleMatrix;
var I,J,K:Integer; Sum:Double;
begin
  if A.Cols<>B.Rows then
    raise EStateSpaceError.Create('Kalman matrix multiply: shape mismatch.');
  Result:=TDenseDoubleMatrix.Zeros(A.Rows,B.Cols);
  for I:=0 to A.Rows-1 do for J:=0 to B.Cols-1 do
  begin
    Sum:=0;
    for K:=0 to A.Cols-1 do Sum:=Sum+A[I,K]*B[K,J];
    if IsNan(Sum) or IsInfinite(Sum) then
      raise EStateSpaceError.Create('Kalman matrix multiply: numerical overflow.');
    Result[I,J]:=Sum;
  end;
end;

function MatrixAdd(const A,B:IDenseDoubleMatrix;
  FactorB:Double=1):IDenseDoubleMatrix;
var I,J:Integer;
begin
  if (A.Rows<>B.Rows) or (A.Cols<>B.Cols) then
    raise EStateSpaceError.Create('Kalman matrix add: shape mismatch.');
  Result:=TDenseDoubleMatrix.Zeros(A.Rows,A.Cols);
  for I:=0 to A.Rows-1 do for J:=0 to A.Cols-1 do
  begin
    Result[I,J]:=A[I,J]+FactorB*B[I,J];
    if IsNan(Result[I,J]) or IsInfinite(Result[I,J]) then
      raise EStateSpaceError.Create('Kalman matrix add: numerical overflow.');
  end;
end;

function MatrixVector(const A:IDenseDoubleMatrix;
  const X:TDoubleArray):TDoubleArray;
var I,J:Integer;
begin
  Result:=nil;
  if A.Cols<>Length(X) then
    raise EStateSpaceError.Create('Kalman matrix-vector product: shape mismatch.');
  SetLength(Result,A.Rows);
  for I:=0 to A.Rows-1 do
  begin
    for J:=0 to A.Cols-1 do Result[I]:=Result[I]+A[I,J]*X[J];
    if IsNan(Result[I]) or IsInfinite(Result[I]) then
      raise EStateSpaceError.Create(
        'Kalman matrix-vector product: numerical overflow.');
  end;
end;

function IdentityMatrix(N:Integer):IDenseDoubleMatrix;
var I:Integer;
begin
  Result:=TDenseDoubleMatrix.Zeros(N,N);
  for I:=0 to N-1 do Result[I,I]:=1;
end;

class function TMultivariateKalmanConfiguration.Create(
  const ATransition,AObservation,AProcessCovariance,
  AMeasurementCovariance:IDenseDoubleMatrix):
  TMultivariateKalmanConfiguration;
begin
  Result:=Default(TMultivariateKalmanConfiguration);
  if ATransition<>nil then Result.Transition:=ATransition.Clone;
  if AObservation<>nil then Result.Observation:=AObservation.Clone;
  if AProcessCovariance<>nil then
    Result.ProcessCovariance:=AProcessCovariance.Clone;
  if AMeasurementCovariance<>nil then
    Result.MeasurementCovariance:=AMeasurementCovariance.Clone;
  ValidateConfiguration(Result);
end;

class function TMultivariateKalmanFilter.Create(
  const Configuration:TMultivariateKalmanConfiguration;
  const InitialMean:TDoubleArray;
  const InitialCovariance:IDenseDoubleMatrix):TMultivariateKalmanFilter;
begin
  Result:=Default(TMultivariateKalmanFilter);
  ValidateConfiguration(Configuration);
  Result.FConfiguration:=TMultivariateKalmanConfiguration.Create(
    Configuration.Transition,Configuration.Observation,
    Configuration.ProcessCovariance,Configuration.MeasurementCovariance);
  Result.Reset(InitialMean,InitialCovariance);
end;

procedure TMultivariateKalmanFilter.Reset(const InitialMean:TDoubleArray;
  const InitialCovariance:IDenseDoubleMatrix);
var I,N:Integer;
begin
  ValidateConfiguration(FConfiguration);
  N:=FConfiguration.Transition.Rows;
  if Length(InitialMean)<>N then
    raise EStateSpaceError.CreateFmt(
      'TMultivariateKalmanFilter.Reset: InitialMean has length %d; expected %d.',
      [Length(InitialMean),N]);
  for I:=0 to High(InitialMean) do
    RequireFinite(InitialMean[I],Format('InitialMean[%d]',[I]),
      'TMultivariateKalmanFilter.Reset');
  ValidateCovariance(InitialCovariance,N,False,'InitialCovariance');
  FStateMean:=Copy(InitialMean);
  FStateCovariance:=InitialCovariance.Clone;
end;

procedure TMultivariateKalmanFilter.PredictInPlace;
var A,AT:IDenseDoubleMatrix;
begin
  A:=FConfiguration.Transition;
  AT:=MatrixTranspose(A);
  FStateMean:=MatrixVector(A,FStateMean);
  FStateCovariance:=MatrixAdd(
    MatrixMultiply(MatrixMultiply(A,FStateCovariance),AT),
    FConfiguration.ProcessCovariance);
end;

function TMultivariateKalmanFilter.UpdateInPlace(
  const Measurement:TDoubleArray):TMultivariateKalmanStep;
var
  H,HT,S,HP,Solution,K,KH,IminusKH,JosephLeft,JosephRight,
    RHS,Solved,L:IDenseDoubleMatrix;
  Factor:IDenseDoubleCholesky;
  PredictedObservation,Correction:TDoubleArray;
  I,J,N,M:Integer;
  Quadratic,LogDet:Double;
begin
  Result:=Default(TMultivariateKalmanStep);
  H:=FConfiguration.Observation;
  N:=Length(FStateMean); M:=H.Rows;
  if Length(Measurement)<>M then
    raise EStateSpaceError.CreateFmt(
      'TMultivariateKalmanFilter.Update: measurement has length %d; expected %d.',
      [Length(Measurement),M]);
  for I:=0 to M-1 do
    RequireFinite(Measurement[I],Format('Measurement[%d]',[I]),
      'TMultivariateKalmanFilter.Update');
  PredictedObservation:=MatrixVector(H,FStateMean);
  SetLength(Result.Innovation,M);
  for I:=0 to M-1 do Result.Innovation[I]:=
    Measurement[I]-PredictedObservation[I];
  HT:=MatrixTranspose(H);
  S:=MatrixAdd(MatrixMultiply(MatrixMultiply(H,FStateCovariance),HT),
    FConfiguration.MeasurementCovariance);
  try
    Factor:=FactorCholesky(S);
    HP:=MatrixMultiply(H,FStateCovariance);
    Solution:=Factor.Solve(HP);
  except
    on E:Exception do raise EStateSpaceError.Create(
      'TMultivariateKalmanFilter.Update: innovation covariance solve failed: '+
      E.Message);
  end;
  K:=MatrixTranspose(Solution);
  Correction:=MatrixVector(K,Result.Innovation);
  for I:=0 to N-1 do FStateMean[I]:=FStateMean[I]+Correction[I];
  KH:=MatrixMultiply(K,H);
  IminusKH:=MatrixAdd(IdentityMatrix(N),KH,-1);
  JosephLeft:=MatrixMultiply(
    MatrixMultiply(IminusKH,FStateCovariance),MatrixTranspose(IminusKH));
  JosephRight:=MatrixMultiply(
    MatrixMultiply(K,FConfiguration.MeasurementCovariance),
    MatrixTranspose(K));
  FStateCovariance:=MatrixAdd(JosephLeft,JosephRight);
  { Restore exact symmetry within the rounding error of the Joseph products. }
  for I:=0 to N-1 do for J:=I+1 to N-1 do
  begin
    FStateCovariance[I,J]:=
      0.5*(FStateCovariance[I,J]+FStateCovariance[J,I]);
    FStateCovariance[J,I]:=FStateCovariance[I,J];
  end;
  RHS:=TDenseDoubleMatrix.FromVector(Result.Innovation,True);
  Solved:=Factor.Solve(RHS);
  Quadratic:=0;
  for I:=0 to M-1 do Quadratic:=Quadratic+
    Result.Innovation[I]*Solved[I,0];
  L:=Factor.L; LogDet:=0;
  for I:=0 to M-1 do LogDet:=LogDet+2*Ln(L[I,I]);
  Result.LogLikelihood:=-0.5*(M*Ln(2*STATE_SPACE_PI)+LogDet+Quadratic);
  Result.StateMean:=Copy(FStateMean);
  Result.StateCovariance:=FStateCovariance.Clone;
  Result.InnovationCovariance:=S.Clone;
end;

procedure TMultivariateKalmanFilter.Predict;
var Work:TMultivariateKalmanFilter;
begin
  Work:=Self;
  Work.FStateMean:=Copy(FStateMean);
  Work.FStateCovariance:=FStateCovariance.Clone;
  Work.PredictInPlace;
  Self:=Work;
end;

function TMultivariateKalmanFilter.Update(
  const Measurement:TDoubleArray):TMultivariateKalmanStep;
var Work:TMultivariateKalmanFilter;
begin
  Work:=Self;
  Work.FStateMean:=Copy(FStateMean);
  Work.FStateCovariance:=FStateCovariance.Clone;
  Result:=Work.UpdateInPlace(Measurement);
  Self:=Work;
end;

function TMultivariateKalmanFilter.Process(
  const Measurements:IDenseDoubleMatrix):TMultivariateKalmanSeriesResult;
var
  Work:TMultivariateKalmanFilter;
  Step:TMultivariateKalmanStep;
  Measurement:TDoubleArray;
  I,J,M,N:Integer;
begin
  Result:=Default(TMultivariateKalmanSeriesResult);
  RequireFiniteMatrix(Measurements,'Measurements',
    'TMultivariateKalmanFilter.Process');
  M:=FConfiguration.Observation.Rows;
  N:=Length(FStateMean);
  if Measurements.Cols<>M then
    raise EStateSpaceError.CreateFmt(
      'TMultivariateKalmanFilter.Process: Measurements has %d columns; expected %d.',
      [Measurements.Cols,M]);
  Result.StateMeans:=TDenseDoubleMatrix.Zeros(Measurements.Rows,N);
  Result.Innovations:=TDenseDoubleMatrix.Zeros(Measurements.Rows,M);
  SetLength(Result.StateCovariances,Measurements.Rows);
  SetLength(Result.InnovationCovariances,Measurements.Rows);
  Work:=Self;
  Work.FStateMean:=Copy(FStateMean);
  Work.FStateCovariance:=FStateCovariance.Clone;
  SetLength(Measurement,M);
  for I:=0 to Measurements.Rows-1 do
  begin
    for J:=0 to M-1 do Measurement[J]:=Measurements[I,J];
    Work.PredictInPlace;
    Step:=Work.UpdateInPlace(Measurement);
    for J:=0 to N-1 do Result.StateMeans[I,J]:=Step.StateMean[J];
    for J:=0 to M-1 do Result.Innovations[I,J]:=Step.Innovation[J];
    Result.StateCovariances[I]:=Step.StateCovariance;
    Result.InnovationCovariances[I]:=Step.InnovationCovariance;
    Result.LogLikelihood:=Result.LogLikelihood+Step.LogLikelihood;
    if IsNan(Result.LogLikelihood) or IsInfinite(Result.LogLikelihood) then
      raise EStateSpaceError.CreateFmt(
        'TMultivariateKalmanFilter.Process: log-likelihood overflow at row %d.',
        [I]);
  end;
  Self:=Work;
end;

function TMultivariateKalmanFilter.Forecast(
  const StepCount:SizeInt):TMultivariateKalmanForecast;
var
  Work:TMultivariateKalmanFilter;
  Mean:TDoubleArray;
  Covariance,H,HT:IDenseDoubleMatrix;
  I,J,M:Integer;
begin
  Result:=Default(TMultivariateKalmanForecast);
  if StepCount<0 then
    raise EStateSpaceError.Create(
      'TMultivariateKalmanFilter.Forecast: StepCount must be non-negative.');
  M:=FConfiguration.Observation.Rows;
  Result.ObservationMeans:=TDenseDoubleMatrix.Zeros(StepCount,M);
  SetLength(Result.ObservationCovariances,StepCount);
  Work:=Self;
  Work.FStateMean:=Copy(FStateMean);
  Work.FStateCovariance:=FStateCovariance.Clone;
  H:=FConfiguration.Observation; HT:=MatrixTranspose(H);
  for I:=0 to StepCount-1 do
  begin
    Work.PredictInPlace;
    Mean:=MatrixVector(H,Work.FStateMean);
    Covariance:=MatrixAdd(
      MatrixMultiply(MatrixMultiply(H,Work.FStateCovariance),HT),
      FConfiguration.MeasurementCovariance);
    for J:=0 to M-1 do Result.ObservationMeans[I,J]:=Mean[J];
    Result.ObservationCovariances[I]:=Covariance;
  end;
end;

function TMultivariateKalmanFilter.StateMean:TDoubleArray;
begin Result:=Copy(FStateMean); end;

function TMultivariateKalmanFilter.StateCovariance:IDenseDoubleMatrix;
begin Result:=FStateCovariance.Clone; end;

function TMultivariateKalmanFilter.StateSize:SizeInt;
begin Result:=Length(FStateMean)+Sqr(Length(FStateMean)); end;

end.
