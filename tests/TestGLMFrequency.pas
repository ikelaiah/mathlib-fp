unit TestGLMFrequency;
{$mode objfpc}{$H+}{$J-}
interface
uses SysUtils, Math, fpcunit, testregistry, MathBase.SharedTypes,
  AlgebraLib.DenseMatrices, StatsLib.GLM;
type TGLMFrequencyTest = class(TTestCase)
  private
    procedure CompareFits(const A,B:TGLMFitResult);
  published
    procedure TestPoissonReplicationWithOffsets;
    procedure TestLogisticReplicationAndZeroRows;
    procedure TestUnitWeightCompatibility;
    procedure TestFrequencyDomainAndOverflow;
    procedure TestEffectiveRankAndSeparation;
    procedure TestLargeFrequencyWithoutExpansion;
  end;
implementation

procedure TGLMFrequencyTest.CompareFits(const A,B:TGLMFitResult);
var J:Integer;
begin
  AssertEquals(A.Message,Ord(glsConverged),Ord(A.Status));
  AssertEquals(B.Message,Ord(glsConverged),Ord(B.Status));
  AssertEquals(A.DegreesOfFreedom,B.DegreesOfFreedom);
  AssertEquals(A.Rank,B.Rank);
  for J:=0 to High(A.Coefficients) do begin
    AssertEquals(A.Coefficients[J],B.Coefficients[J],2E-8);
    AssertEquals(A.StandardErrors[J],B.StandardErrors[J],2E-8);
  end;
  AssertEquals(A.Deviance,B.Deviance,2E-8);
  AssertEquals(A.NullDeviance,B.NullDeviance,2E-8);
  AssertEquals(A.PearsonChiSquare,B.PearsonChiSquare,2E-8);
end;

procedure TGLMFrequencyTest.TestPoissonReplicationWithOffsets;
var X,RX:IDenseDoubleMatrix; Y,RY:TDoubleArray; Inputs,Repeated:TGLMInputs;
  A,B:TGLMFitResult; I,J,K,At:Integer;
begin
  X:=TDenseDoubleMatrix.FromValues(3,2,[1,0,1,1,1,2]);
  Y:=TDoubleArray.Create(1,8,7); Inputs:=TGLMInputs.Default;
  Inputs.Offsets:=TDoubleArray.Create(Ln(2.0),Ln(2.0),Ln(2.0));
  Inputs.Exposures:=TDoubleArray.Create(0.5,1,0.5);
  Inputs.FrequencyWeights:=TGLMFrequencyWeights.Create(2,1,3);
  RX:=TDenseDoubleMatrix.Zeros(6,2); SetLength(RY,6);
  Repeated:=TGLMInputs.Default; SetLength(Repeated.Offsets,6);
  SetLength(Repeated.Exposures,6); At:=0;
  for I:=0 to 2 do for K:=1 to Inputs.FrequencyWeights[I] do begin
    for J:=0 to 1 do RX[At,J]:=X[I,J]; RY[At]:=Y[I];
    Repeated.Offsets[At]:=Inputs.Offsets[I];
    Repeated.Exposures[At]:=Inputs.Exposures[I]; Inc(At);
  end;
  A:=TGLMKit.FitPoisson(X,Y,Inputs); B:=TGLMKit.FitPoisson(RX,RY,Repeated);
  CompareFits(A,B); AssertEquals(6,A.FrequencyCount);
  AssertEquals(3,Length(A.DiagnosticRows));
  for I:=0 to 2 do AssertEquals(I,A.DiagnosticRows[I]);
end;

procedure TGLMFrequencyTest.TestLogisticReplicationAndZeroRows;
var X,RX:IDenseDoubleMatrix; Inputs,Repeated:TGLMInputs; A,B:TGLMFitResult;
  Y,RY:TDoubleArray; I,K,At:Integer; Sum:Double;
begin
  X:=TDenseDoubleMatrix.FromValues(5,2,[1,0,1,0,1,1,1,1,1,1E100]);
  Y:=TDoubleArray.Create(0,1,0,1,0); Inputs:=TGLMInputs.Default;
  Inputs.Offsets:=TDoubleArray.Create(0.2,0.2,-0.3,-0.3,800);
  Inputs.FrequencyWeights:=TGLMFrequencyWeights.Create(3,1,1,4,0);
  RX:=TDenseDoubleMatrix.Zeros(9,2); SetLength(RY,9);
  Repeated:=TGLMInputs.Default; SetLength(Repeated.Offsets,9); At:=0;
  for I:=0 to 3 do for K:=1 to Inputs.FrequencyWeights[I] do begin
    RX[At,0]:=1; RX[At,1]:=X[I,1]; RY[At]:=Y[I];
    Repeated.Offsets[At]:=Inputs.Offsets[I]; Inc(At);
  end;
  A:=TGLMKit.FitLogistic(X,Y,Inputs); B:=TGLMKit.FitLogistic(RX,RY,Repeated);
  CompareFits(A,B); AssertEquals(9,A.FrequencyCount);
  AssertEquals(4,Length(A.FittedMeans)); AssertEquals(4,Length(A.DiagnosticRows));
  Sum:=0;
  for I:=0 to 3 do begin
    AssertEquals(I,A.DiagnosticRows[I]); Sum:=Sum+Sqr(A.DevianceResiduals[I]);
  end;
  AssertEquals(A.Deviance,Sum,2E-8);
  AssertEquals(-Ln(3.0)-0.2,A.Coefficients[0],2E-8);
  AssertEquals(Ln(12.0)+0.5,A.Coefficients[1],2E-8);
end;

procedure TGLMFrequencyTest.TestUnitWeightCompatibility;
var X:IDenseDoubleMatrix; Inputs:TGLMInputs; A,B:TGLMFitResult; I:Integer;
begin
  X:=TDenseDoubleMatrix.FromValues(4,2,[1,0,1,1,1,2,1,3]);
  Inputs:=TGLMInputs.Default;
  Inputs.FrequencyWeights:=TGLMFrequencyWeights.Create(1,1,1,1);
  A:=TGLMKit.FitPoisson(X,[1,3,4,7]); B:=TGLMKit.FitPoisson(X,[1,3,4,7],Inputs);
  CompareFits(A,B); AssertEquals(4,B.FrequencyCount);
  for I:=0 to 3 do AssertEquals(A.FittedMeans[I],B.FittedMeans[I],2E-10);
  AssertEquals(0,Length(A.DiagnosticRows));
end;

procedure TGLMFrequencyTest.TestFrequencyDomainAndOverflow;
var X:IDenseDoubleMatrix; Inputs:TGLMInputs; Fit:TGLMFitResult; P:TDoubleArray;
begin
  X:=TDenseDoubleMatrix.FromValues(2,1,[1,1]); Inputs:=TGLMInputs.Default;
  Inputs.FrequencyWeights:=TGLMFrequencyWeights.Create(1);
  try TGLMKit.FitPoisson(X,[1,2],Inputs); Fail('short weights');
  except on E:EGLMError do ; end;
  Inputs.FrequencyWeights:=TGLMFrequencyWeights.Create(0,0);
  try TGLMKit.FitPoisson(X,[1,2],Inputs); Fail('zero total');
  except on E:EGLMError do ; end;
  Inputs.FrequencyWeights:=TGLMFrequencyWeights.Create(GLM_MAX_FREQUENCY_COUNT,1);
  try TGLMKit.FitPoisson(X,[1,2],Inputs); Fail('total overflow');
  except on E:EGLMError do ; end;
  Inputs.FrequencyWeights:=TGLMFrequencyWeights.Create(High(QWord),0);
  try TGLMKit.FitPoisson(X,[1,2],Inputs); Fail('single count overflow');
  except on E:EGLMError do ; end;
  Inputs.FrequencyWeights:=TGLMFrequencyWeights.Create(1,0);
  try TGLMKit.FitPoisson(X,[1,NaN],Inputs); Fail('invalid ignored row');
  except on E:EGLMError do ; end;
  Inputs.FrequencyWeights:=TGLMFrequencyWeights.Create(1,1);
  Fit:=TGLMKit.FitPoisson(X,[1,2],Inputs);
  try P:=TGLMKit.PredictMean(Fit,X,Inputs); Fail('prediction training weights');
  except on E:EGLMError do ; end;
  P:=TGLMKit.PredictMean(Fit,X); AssertEquals(1.5,P[0],2E-9);
end;

procedure TGLMFrequencyTest.TestEffectiveRankAndSeparation;
var X:IDenseDoubleMatrix; Inputs:TGLMInputs; Fit:TGLMFitResult;
begin
  X:=TDenseDoubleMatrix.FromValues(3,2,[1,0,1,1,1,2]); Inputs:=TGLMInputs.Default;
  Inputs.FrequencyWeights:=TGLMFrequencyWeights.Create(1,0,0);
  Fit:=TGLMKit.FitPoisson(X,[1,2,3],Inputs);
  AssertEquals(Ord(glsRankDeficient),Ord(Fit.Status));
  AssertFalse(Fit.Identifiable); AssertEquals(0,Length(Fit.StandardErrors));
  X:=TDenseDoubleMatrix.FromValues(3,2,[1,-1,1,1,1,1]);
  Inputs.FrequencyWeights:=TGLMFrequencyWeights.Create(1,1,0);
  Fit:=TGLMKit.FitLogistic(X,[0,1,0],Inputs);
  AssertEquals(Ord(glsCompleteSeparation),Ord(Fit.Status));
end;

procedure TGLMFrequencyTest.TestLargeFrequencyWithoutExpansion;
var X:IDenseDoubleMatrix; Inputs:TGLMInputs; Fit:TGLMFitResult;
begin
  X:=TDenseDoubleMatrix.FromValues(1,1,[1]); Inputs:=TGLMInputs.Default;
  Inputs.FrequencyWeights:=TGLMFrequencyWeights.Create(GLM_MAX_FREQUENCY_COUNT);
  Fit:=TGLMKit.FitPoisson(X,[2],Inputs);
  AssertEquals(Fit.Message,Ord(glsConverged),Ord(Fit.Status));
  AssertEquals(GLM_MAX_FREQUENCY_COUNT,Fit.FrequencyCount);
  AssertEquals(GLM_MAX_FREQUENCY_COUNT-1,Fit.DegreesOfFreedom);
  AssertEquals(1,Length(Fit.FittedMeans));
  AssertEquals(Ln(2.0),Fit.Coefficients[0],2E-10);
  AssertEquals(1/Sqrt(Double(2)*GLM_MAX_FREQUENCY_COUNT),Fit.StandardErrors[0],1E-12);
end;
initialization
  RegisterTest(TGLMFrequencyTest);
end.
