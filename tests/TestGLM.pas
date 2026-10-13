unit TestGLM;

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math, fpcunit, testregistry,
  MathBase.SharedTypes, AlgebraLib.DenseMatrices, StatsLib.GLM;

type
  TGLMTest = class(TTestCase)
  published
    procedure TestIndependentReferenceFits;
    procedure TestAnalyticInterceptModels;
    procedure TestPredictionOwnershipAndDomains;
    procedure TestInvalidRequests;
    procedure TestRankAndConditionFailures;
    procedure TestIterationLimitWithholdsInference;
    procedure TestCompleteSeparationCertificates;
    procedure TestQuasiSeparationNeverConverges;
    procedure TestPoissonBoundaryAndNoIntercept;
    procedure TestScaleAndRowOrderInvariance;
    procedure TestNumericalFailureAndExtremePredictions;
    procedure TestResidualDiagnosticsAndSaturatedCounts;
    procedure TestLargeCountsAndStridedDesign;
  end;

implementation

{$I GLMReference.inc}

procedure TGLMTest.TestIndependentReferenceFits;
var
  C, I, J: Integer;
  X: IDenseDoubleMatrix;
  Y: TDoubleArray;
  Fit: TGLMFitResult;
  Options: TGLMOptions;
begin
  Options := TGLMOptions.Default;
  Options.Tolerance := 1E-11;
  for C := Low(GLMReferences) to High(GLMReferences) do
  begin
    X := TDenseDoubleMatrix.Zeros(GLMReferences[C].N, GLMReferences[C].P);
    SetLength(Y, X.Rows);
    for I := 0 to X.Rows - 1 do
    begin
      Y[I] := GLMReferences[C].Response[I];
      for J := 0 to X.Cols - 1 do
        X[I, J] := GLMReferences[C].Design[I * X.Cols + J];
    end;
    if GLMReferences[C].Family = 0 then
      Fit := TGLMKit.FitLogistic(X, Y, Options)
    else Fit := TGLMKit.FitPoisson(X, Y, Options);
    AssertEquals('independent fit ' + IntToStr(C) + ' converged', Ord(glsConverged), Ord(Fit.Status));
    AssertTrue('converged fit is identifiable', Fit.Identifiable);
    AssertEquals('full numerical rank', X.Cols, Fit.Rank);
    AssertEquals('residual degrees of freedom', X.Rows-X.Cols, Fit.DegreesOfFreedom);
    for J := 0 to X.Cols - 1 do
    begin
      AssertEquals('reference coefficient', GLMReferences[C].Coefficients[J],
        Fit.Coefficients[J], 2E-8 * Max(Double(1), Abs(GLMReferences[C].Coefficients[J])));
      AssertEquals('reference standard error', GLMReferences[C].Errors[J],
        Fit.StandardErrors[J], 2E-8 * Max(Double(1), GLMReferences[C].Errors[J]));
    end;
    for I := 0 to X.Rows - 1 do
      AssertEquals('reference fitted mean', GLMReferences[C].Means[I],
        Fit.FittedMeans[I], 2E-9 * Max(Double(1), GLMReferences[C].Means[I]));
    AssertEquals('reference deviance', GLMReferences[C].Deviance, Fit.Deviance, 2E-8);
    AssertEquals('reference Pearson chi-square', GLMReferences[C].Pearson,
      Fit.PearsonChiSquare, 2E-8);
    AssertEquals('last history is reported deviance', Fit.Deviance,
      Fit.DevianceHistory[High(Fit.DevianceHistory)], 0);
    for I := 1 to High(Fit.DevianceHistory) do
      AssertTrue('accepted deviance is non-increasing',
        Fit.DevianceHistory[I] <= Fit.DevianceHistory[I-1] +
          8 * 2.2204460492503131E-16 * (1 + Fit.DevianceHistory[I-1]));
  end;
end;

procedure TGLMTest.TestAnalyticInterceptModels;
var X: IDenseDoubleMatrix; Y: TDoubleArray; Fit: TGLMFitResult;
begin
  X := TDenseDoubleMatrix.FromValues(4, 1, [1, 1, 1, 1]);
  Y := TDoubleArray.Create(0, 1, 1, 1);
  Fit := TGLMKit.FitLogistic(X, Y);
  AssertEquals('log odds', Ln(3), Fit.Coefficients[0], 1E-8);
  AssertEquals('Bernoulli information', Sqrt(4/3), Fit.StandardErrors[0], 1E-8);
  AssertEquals('null model deviance', Fit.Deviance, Fit.NullDeviance, 1E-10);
  Y := TDoubleArray.Create(0, 1, 2, 5);
  Fit := TGLMKit.FitPoisson(X, Y);
  AssertEquals('log mean count', Ln(2), Fit.Coefficients[0], 1E-8);
  AssertEquals('Poisson information', 1/Sqrt(8), Fit.StandardErrors[0], 1E-8);
  AssertEquals('zero count deviance residual', -2, Fit.DevianceResiduals[0], 1E-8);
  AssertEquals('null model deviance', Fit.Deviance, Fit.NullDeviance, 1E-10);
end;

procedure TGLMTest.TestPredictionOwnershipAndDomains;
var X: IDenseDoubleMatrix; Y, Prediction: TDoubleArray; Fit: TGLMFitResult;
begin
  X := TDenseDoubleMatrix.FromValues(4, 1, [1, 1, 1, 1]);
  Y := TDoubleArray.Create(0, 1, 1, 1);
  Fit := TGLMKit.FitLogistic(X, Y);
  Prediction := TGLMKit.PredictMean(Fit, X);
  AssertEquals('prediction uses fitted logit', 0.75, Prediction[0], 1E-9);
  Prediction[0] := 99;
  Y[0] := 99; X[0,0] := 99;
  AssertEquals('fit owns mean array', 0.75, Fit.FittedMeans[0], 1E-9);
  AssertEquals('fit does not retain input', Ln(3), Fit.Coefficients[0], 1E-8);
  X := TDenseDoubleMatrix.Zeros(2, 2);
  try
    Prediction := TGLMKit.PredictMean(Fit, X);
    Fail('incompatible prediction design must be rejected');
  except on EGLMError do ; end;
end;

procedure ExpectFitError(const X: IDenseDoubleMatrix; const Y: TDoubleArray;
  const Options: TGLMOptions; const Poisson: Boolean = False);
var Fit: TGLMFitResult;
begin
  try
    if Poisson then Fit := TGLMKit.FitPoisson(X, Y, Options)
    else Fit := TGLMKit.FitLogistic(X, Y, Options);
    raise Exception.Create('invalid GLM request was accepted: ' + Fit.Message);
  except on EGLMError do ; end;
end;

procedure TGLMTest.TestInvalidRequests;
var X: IDenseDoubleMatrix; Y: TDoubleArray; O: TGLMOptions;
begin
  O := TGLMOptions.Default;
  Y := TDoubleArray.Create(0, 1);
  ExpectFitError(nil, Y, O);
  X := TDenseDoubleMatrix.Zeros(1, 2); ExpectFitError(X, Y, O);
  X := TDenseDoubleMatrix.Zeros(2, 1);
  ExpectFitError(X, TDoubleArray.Create(0), O);
  X[0,0] := NaN; ExpectFitError(X, Y, O);
  X[0,0] := Infinity; ExpectFitError(X, Y, O);
  X[0,0] := 1; X[1,0] := 1;
  ExpectFitError(X, TDoubleArray.Create(0, 0.5), O);
  ExpectFitError(X, TDoubleArray.Create(0, 2), O);
  ExpectFitError(X, TDoubleArray.Create(0, NaN), O);
  ExpectFitError(X, TDoubleArray.Create(0, Infinity), O, True);
  ExpectFitError(X, TDoubleArray.Create(0, -1), O, True);
  ExpectFitError(X, TDoubleArray.Create(0, 0.5), O, True);
  O.MaxIterations := 0; ExpectFitError(X, Y, O);
  O := TGLMOptions.Default; O.Tolerance := NaN; ExpectFitError(X, Y, O);
  O := TGLMOptions.Default; O.Tolerance := 0.1; ExpectFitError(X, Y, O);
  O := TGLMOptions.Default; O.RankTolerance := 0; ExpectFitError(X, Y, O);
  O := TGLMOptions.Default; O.MinimumConditionIndicator := 1.1;
  ExpectFitError(X, Y, O);
  AssertEquals('rejection preserves input', 1.0, X[0,0], 0);
end;

procedure TGLMTest.TestRankAndConditionFailures;
var X: IDenseDoubleMatrix; Y: TDoubleArray; Fit: TGLMFitResult; O: TGLMOptions;
begin
  X := TDenseDoubleMatrix.FromValues(4, 2, [1,2, 1,2, 1,2, 1,2]);
  Y := TDoubleArray.Create(0,1,0,1);
  Fit := TGLMKit.FitLogistic(X, Y);
  AssertEquals('duplicate columns are rank deficient', Ord(glsRankDeficient), Ord(Fit.Status));
  AssertEquals('rank is one', 1, Fit.Rank);
  AssertEquals('no inference on rank failure', 0, Length(Fit.StandardErrors));
  AssertTrue('rank failure retains initial objective', Fit.HasFiniteIterate);
  X := TDenseDoubleMatrix.FromValues(4, 2, [1,1, 1,1.00000001, 1,1.00000002, 1,1.00000003]);
  O := TGLMOptions.Default; O.RankTolerance := 1E-14;
  O.MinimumConditionIndicator := 1E-5;
  Fit := TGLMKit.FitLogistic(X, Y, O);
  AssertEquals('ill conditioning is distinguished from rank', Ord(glsIllConditioned), Ord(Fit.Status));
  AssertEquals('ill-conditioned matrix has full rank', 2, Fit.Rank);
  AssertTrue('condition indicator explains failure', Fit.ConditionIndicator < 1E-5);
  X := TDenseDoubleMatrix.Zeros(4,1);
  Fit := TGLMKit.FitPoisson(X, TDoubleArray.Create(0,1,2,3));
  AssertEquals('zero column is rank deficient', Ord(glsRankDeficient), Ord(Fit.Status));
end;

procedure TGLMTest.TestIterationLimitWithholdsInference;
var X: IDenseDoubleMatrix; Y, P: TDoubleArray; Fit: TGLMFitResult; O: TGLMOptions;
begin
  X := TDenseDoubleMatrix.FromValues(4,1,[1,1,1,1]);
  Y := TDoubleArray.Create(0,1,1,1);
  O := TGLMOptions.Default; O.MaxIterations := 1;
  Fit := TGLMKit.FitLogistic(X,Y,O);
  AssertEquals('iteration limit is explicit', Ord(glsIterationLimit), Ord(Fit.Status));
  AssertEquals('one accepted step', 1, Fit.Iterations);
  AssertFalse('failed fit is not identifiable', Fit.Identifiable);
  AssertEquals('failed fit has no standard errors', 0, Length(Fit.StandardErrors));
  AssertTrue('last means are finite', not IsNan(Fit.FittedMeans[0]));
  try P := TGLMKit.PredictMean(Fit,X); Fail('failed fit prediction must be rejected');
  except on EGLMError do ; end;
end;

procedure TGLMTest.TestCompleteSeparationCertificates;
var X: IDenseDoubleMatrix; Fit: TGLMFitResult;
begin
  X := TDenseDoubleMatrix.FromValues(4,2,[1,-2, 1,-1, 1,1, 1,2]);
  Fit := TGLMKit.FitLogistic(X,TDoubleArray.Create(0,0,1,1));
  AssertEquals('strict margins certify complete separation',
    Ord(glsCompleteSeparation), Ord(Fit.Status));
  AssertFalse('separated MLE is not finite', Fit.Identifiable);
  AssertEquals('separated fit has no standard errors', 0, Length(Fit.StandardErrors));
  X := TDenseDoubleMatrix.FromValues(4,1,[1,1,1,1]);
  Fit := TGLMKit.FitLogistic(X,TDoubleArray.Create(1,1,1,1));
  AssertEquals('single class intercept is separated', Ord(glsCompleteSeparation), Ord(Fit.Status));
  Fit := TGLMKit.FitLogistic(X,TDoubleArray.Create(0,0,0,0));
  AssertEquals('zero class intercept is separated', Ord(glsCompleteSeparation), Ord(Fit.Status));
end;

procedure TGLMTest.TestQuasiSeparationNeverConverges;
var X: IDenseDoubleMatrix; Fit: TGLMFitResult; O: TGLMOptions;
begin
  X := TDenseDoubleMatrix.FromValues(4,2,[1,-1, 1,0, 1,0, 1,1]);
  Fit := TGLMKit.FitLogistic(X,TDoubleArray.Create(0,0,1,1));
  AssertTrue('quasi-separation is not a converged finite estimate', Fit.Status <> glsConverged);
  AssertFalse('quasi-separated information is not reported as identifiable', Fit.Identifiable);
  AssertEquals('quasi-separated standard errors withheld', 0, Length(Fit.StandardErrors));
  O := TGLMOptions.Default; O.Tolerance := 0.01;
  Fit := TGLMKit.FitLogistic(X,TDoubleArray.Create(0,0,1,1),O);
  AssertTrue('loose supported tolerance does not invent a finite MLE', Fit.Status <> glsConverged);
end;

procedure TGLMTest.TestPoissonBoundaryAndNoIntercept;
var X: IDenseDoubleMatrix; Fit: TGLMFitResult;
begin
  X := TDenseDoubleMatrix.FromValues(4,1,[1,1,1,1]);
  Fit := TGLMKit.FitPoisson(X,TDoubleArray.Create(0,0,0,0));
  AssertEquals('zero-count intercept MLE is on boundary', Ord(glsBoundary), Ord(Fit.Status));
  AssertEquals('zero-count null deviance', 0.0, Fit.NullDeviance, 0);
  X := TDenseDoubleMatrix.FromValues(2,1,[-1,1]);
  Fit := TGLMKit.FitPoisson(X,TDoubleArray.Create(0,0));
  AssertEquals('zero counts without intercept may have finite MLE', Ord(glsConverged), Ord(Fit.Status));
  AssertEquals('symmetric no-intercept solution', 0.0, Fit.Coefficients[0], 0);
  AssertEquals('symmetric no-intercept deviance', 4.0, Fit.Deviance, 1E-14);
  Fit := TGLMKit.FitLogistic(X,TDoubleArray.Create(0,0));
  AssertEquals('single class without intercept need not separate', Ord(glsConverged), Ord(Fit.Status));
end;

procedure TGLMTest.TestScaleAndRowOrderInvariance;
var X, Scaled, Reversed: IDenseDoubleMatrix; Y, ReverseY: TDoubleArray;
  A,B,C: TGLMFitResult; I,J: Integer;
begin
  X := TDenseDoubleMatrix.FromValues(6,2,[1,-2, 1,-1, 1,0, 1,1, 1,2, 1,3]);
  Y := TDoubleArray.Create(0,1,0,1,0,1);
  Scaled := X.Clone; Reversed := X.Clone; SetLength(ReverseY,6);
  for I:=0 to 5 do
  begin
    Scaled[I,1] := X[I,1] * 1E150;
    ReverseY[I] := Y[5-I];
    for J:=0 to 1 do Reversed[I,J] := X[5-I,J];
  end;
  A := TGLMKit.FitLogistic(X,Y); B := TGLMKit.FitLogistic(Scaled,Y);
  C := TGLMKit.FitLogistic(Reversed,ReverseY);
  AssertEquals('extreme predictor units converge', Ord(glsConverged), Ord(B.Status));
  AssertEquals('coefficient unit mapping', A.Coefficients[1], B.Coefficients[1]*1E150, 1E-8);
  AssertEquals('standard error unit mapping', A.StandardErrors[1], B.StandardErrors[1]*1E150, 1E-8);
  for I:=0 to 5 do
  begin
    AssertEquals('scale invariant fitted means', A.FittedMeans[I], B.FittedMeans[I], 1E-9);
    AssertEquals('row permutation invariant means', A.FittedMeans[I], C.FittedMeans[5-I], 1E-9);
  end;
  AssertEquals('fit preserves predictor values', -2.0, X[0,1], 0);
end;

procedure TGLMTest.TestNumericalFailureAndExtremePredictions;
var X: IDenseDoubleMatrix; Fit: TGLMFitResult; P: TDoubleArray;
begin
  X := TDenseDoubleMatrix.FromValues(2,1,[1,1]);
  Fit := TGLMKit.FitPoisson(X,TDoubleArray.Create(1E308,1E308));
  AssertEquals('nonrepresentable initial objective', Ord(glsNumericalFailure), Ord(Fit.Status));
  AssertFalse('no finite objective is distinguished', Fit.HasFiniteIterate);
  AssertEquals('unavailable initial means are empty', 0, Length(Fit.FittedMeans));
  Fit := TGLMKit.FitLogistic(X,TDoubleArray.Create(0,1));
  Fit.Coefficients[0] := 1000;
  P := TGLMKit.PredictMean(Fit,X);
  AssertEquals('large positive logit safely saturates', 1.0, P[0], 0);
  Fit.Coefficients[0] := -1000; P := TGLMKit.PredictMean(Fit,X);
  AssertEquals('large negative logit safely saturates', 0.0, P[0], 0);
  Fit := TGLMKit.FitPoisson(X,TDoubleArray.Create(1,2));
  Fit.Coefficients[0] := 1000;
  try P:=TGLMKit.PredictMean(Fit,X); Fail('nonrepresentable Poisson prediction');
  except on EGLMError do ; end;
end;

procedure TGLMTest.TestResidualDiagnosticsAndSaturatedCounts;
var X: IDenseDoubleMatrix; Fit: TGLMFitResult; I: Integer; SumD: Double;
begin
  X := TDenseDoubleMatrix.FromValues(3,3,[1,0,0, 0,1,0, 0,0,1]);
  Fit := TGLMKit.FitPoisson(X,TDoubleArray.Create(1,2,3));
  AssertEquals('positive saturated Poisson converges', Ord(glsConverged), Ord(Fit.Status));
  AssertEquals('saturated residual degrees of freedom', 0, Fit.DegreesOfFreedom);
  AssertEquals('perfect-count deviance is stable near zero', 0.0, Fit.Deviance, 1E-14);
  X := TDenseDoubleMatrix.FromValues(4,1,[1,1,1,1]);
  Fit := TGLMKit.FitPoisson(X,TDoubleArray.Create(0,1,2,5)); SumD:=0;
  for I:=0 to 3 do SumD:=SumD+Sqr(Fit.DevianceResiduals[I]);
  AssertEquals('signed deviance residual squares sum to deviance', Fit.Deviance, SumD, 1E-12);
  AssertEquals('residual preserves observed-minus-mean', -2.0, Fit.ResponseResiduals[0], 1E-9);
end;

procedure TGLMTest.TestLargeCountsAndStridedDesign;
var Storage, X: IDenseDoubleMatrix; Fit: TGLMFitResult;
begin
  Storage := TDenseDoubleMatrix.FromValues(4,2,[99,1, 99,1, 99,1, 99,1]);
  X := Storage.ColumnView(1);
  Fit := TGLMKit.FitPoisson(X,TDoubleArray.Create(1E12,1E12,1E12,1E12));
  AssertEquals('large count intercept converges', Ord(glsConverged), Ord(Fit.Status));
  AssertEquals('large count log mean', Ln(1E12), Fit.Coefficients[0], 1E-10);
  AssertEquals('large count information', 5E-7, Fit.StandardErrors[0], 1E-15);
  AssertEquals('strided design source remains unchanged', 99.0, Storage[0,0], 0);
end;

initialization
  RegisterTest(TGLMTest);
end.
