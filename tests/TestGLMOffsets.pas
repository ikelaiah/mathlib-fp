unit TestGLMOffsets;
{$mode objfpc}{$H+}{$J-}
interface
uses SysUtils, Math, fpcunit, testregistry, MathBase.SharedTypes,
  AlgebraLib.DenseMatrices, StatsLib.GLM;
type TGLMOffsetsTest = class(TTestCase)
  published
    procedure TestAnalyticExposureAndNullDeviance;
    procedure TestCombinedInputsAndNewRows;
    procedure TestOffsetsDoNotCertifySeparation;
    procedure TestZeroUnitCompatibility;
    procedure TestInvalidInputsAndPredictionKinds;
    procedure TestAdjustedNumericalFailure;
  end;
implementation
{$I GLMOffsetReference.inc}

procedure TGLMOffsetsTest.TestAnalyticExposureAndNullDeviance;
var X: IDenseDoubleMatrix; Inputs: TGLMInputs; Fit: TGLMFitResult;
  Options: TGLMOptions; I: Integer;
begin
  X:=TDenseDoubleMatrix.FromValues(3,2,[1,0,1,1,1,2]);
  Inputs:=TGLMInputs.Default; Inputs.Exposures:=TDoubleArray.Create(1,2,1);
  Options:=TGLMOptions.Default; Options.Tolerance:=1E-11;
  Fit:=TGLMKit.FitPoisson(X,[2,8,8],Inputs,Options);
  AssertEquals(Fit.Message,Ord(glsConverged),Ord(Fit.Status));
  AssertEquals(Ln(2.0),Fit.Coefficients[0],2E-9);
  AssertEquals(Ln(2.0),Fit.Coefficients[1],2E-9);
  { 80-digit Decimal analytic information inverse: [[18,24],[24,40]]. }
  AssertEquals(GLMExposureInterceptError,Fit.StandardErrors[0],2E-9);
  AssertEquals(GLMExposureSlopeError,Fit.StandardErrors[1],2E-9);
  AssertEquals(GLMExposureNullDeviance,Fit.NullDeviance,2E-9);
  AssertEquals(0.0,Fit.Deviance,2E-12);
  AssertEquals(1,Fit.DegreesOfFreedom);
  AssertTrue(Fit.UsesExposure); AssertFalse(Fit.UsesOffsets);
  for I:=0 to 2 do AssertEquals(0.0,Fit.ResponseResiduals[I],2E-8);
end;

procedure TGLMOffsetsTest.TestCombinedInputsAndNewRows;
var X,NewX: IDenseDoubleMatrix; Inputs,NewInputs: TGLMInputs;
  Fit: TGLMFitResult; P: TDoubleArray;
begin
  X:=TDenseDoubleMatrix.FromValues(3,1,[1,1,1]); Inputs:=TGLMInputs.Default;
  Inputs.Offsets:=TDoubleArray.Create(Ln(2.0),Ln(2.0),Ln(2.0));
  Inputs.Exposures:=TDoubleArray.Create(0.5,1,1.5);
  Fit:=TGLMKit.FitPoisson(X,[2,4,6],Inputs);
  AssertEquals(Fit.Message,Ord(glsConverged),Ord(Fit.Status));
  AssertEquals(Ln(2.0),Fit.Coefficients[0],2E-9);
  AssertEquals(0.0,Fit.NullDeviance,2E-12);
  AssertTrue(Fit.UsesOffsets); AssertTrue(Fit.UsesExposure);
  AssertEquals(Ln(2.0),Inputs.Offsets[0],0);
  AssertEquals(0.5,Inputs.Exposures[0],0);
  Inputs.Offsets[0]:=999; Inputs.Exposures[0]:=999;
  NewX:=TDenseDoubleMatrix.FromValues(1,1,[1]); NewInputs:=TGLMInputs.Default;
  NewInputs.Offsets:=TDoubleArray.Create(Ln(2.0));
  NewInputs.Exposures:=TDoubleArray.Create(4);
  P:=TGLMKit.PredictMean(Fit,NewX,NewInputs);
  AssertEquals('new expected count',16.0,P[0],2E-8);
  AssertEquals('owned fitted values',2.0,Fit.FittedMeans[0],2E-8);
end;

procedure TGLMOffsetsTest.TestOffsetsDoNotCertifySeparation;
var X: IDenseDoubleMatrix; Inputs: TGLMInputs; Fit: TGLMFitResult;
begin
  X:=TDenseDoubleMatrix.FromValues(4,1,[1,1,1,1]); Inputs:=TGLMInputs.Default;
  Inputs.Offsets:=TDoubleArray.Create(Ln(2.0)-Ln(3.0),Ln(2.0)-Ln(3.0),
    Ln(2.0)+Ln(3.0),Ln(2.0)+Ln(3.0));
  Fit:=TGLMKit.FitLogistic(X,[0,0,1,1],Inputs);
  AssertEquals(Fit.Message,Ord(glsConverged),Ord(Fit.Status));
  AssertEquals(-Ln(2.0),Fit.Coefficients[0],2E-8);
  AssertEquals(GLMOffsetLogisticError,Fit.StandardErrors[0],2E-8);
  AssertEquals(GLMOffsetLogisticDeviance,Fit.Deviance,2E-9);
  AssertEquals(Fit.Deviance,Fit.NullDeviance,2E-9);
  AssertEquals(0.25,Fit.FittedMeans[0],2E-9);
  AssertEquals(0.75,Fit.FittedMeans[3],2E-9);
end;

procedure TGLMOffsetsTest.TestZeroUnitCompatibility;
var X: IDenseDoubleMatrix; Inputs: TGLMInputs; A,B: TGLMFitResult; I: Integer;
begin
  X:=TDenseDoubleMatrix.FromValues(4,2,[1,0,1,1,1,2,1,3]);
  Inputs:=TGLMInputs.Default; Inputs.Offsets:=TDoubleArray.Create(0,0,0,0);
  Inputs.Exposures:=TDoubleArray.Create(1,1,1,1);
  A:=TGLMKit.FitPoisson(X,[1,3,4,7]); B:=TGLMKit.FitPoisson(X,[1,3,4,7],Inputs);
  AssertEquals(Ord(A.Status),Ord(B.Status));
  for I:=0 to 1 do begin
    AssertEquals(A.Coefficients[I],B.Coefficients[I],2E-10);
    AssertEquals(A.StandardErrors[I],B.StandardErrors[I],2E-10);
  end;
  AssertEquals(A.NullDeviance,B.NullDeviance,2E-10);
  AssertEquals(A.Deviance,B.Deviance,2E-10);
  Inputs.Exposures:=nil;
  A:=TGLMKit.FitLogistic(X,[0,1,0,1]);
  B:=TGLMKit.FitLogistic(X,[0,1,0,1],Inputs);
  AssertEquals(Ord(glsConverged),Ord(B.Status));
  for I:=0 to 1 do AssertEquals(A.Coefficients[I],B.Coefficients[I],2E-10);
  AssertEquals(A.NullDeviance,B.NullDeviance,2E-10);
end;

procedure TGLMOffsetsTest.TestInvalidInputsAndPredictionKinds;
var X: IDenseDoubleMatrix; Inputs: TGLMInputs; Fit: TGLMFitResult; P: TDoubleArray;
begin
  X:=TDenseDoubleMatrix.FromValues(2,1,[1,1]); Inputs:=TGLMInputs.Default;
  Inputs.Offsets:=TDoubleArray.Create(0);
  try TGLMKit.FitPoisson(X,[1,2],Inputs); Fail('short offset');
  except on E:EGLMError do ; end;
  Inputs.Offsets:=TDoubleArray.Create(0,NaN);
  try TGLMKit.FitPoisson(X,[1,2],Inputs); Fail('nonfinite offset');
  except on E:EGLMError do ; end;
  Inputs.Offsets:=nil; Inputs.Exposures:=TDoubleArray.Create(1);
  try TGLMKit.FitPoisson(X,[1,2],Inputs); Fail('short exposure');
  except on E:EGLMError do ; end;
  Inputs.Exposures:=TDoubleArray.Create(1,0);
  try TGLMKit.FitPoisson(X,[1,2],Inputs); Fail('zero exposure');
  except on E:EGLMError do ; end;
  Inputs.Exposures[1]:=Infinity;
  try TGLMKit.FitPoisson(X,[1,2],Inputs); Fail('nonfinite exposure');
  except on E:EGLMError do ; end;
  Inputs.Exposures[1]:=2;
  try TGLMKit.FitLogistic(X,[0,1],Inputs); Fail('logistic exposure');
  except on E:EGLMError do ; end;
  Fit:=TGLMKit.FitPoisson(X,[1,2],Inputs);
  try P:=TGLMKit.PredictMean(Fit,X); Fail('missing new exposure');
  except on E:EGLMError do ; end;
  Inputs.Offsets:=TDoubleArray.Create(0,0);
  try P:=TGLMKit.PredictMean(Fit,X,Inputs); Fail('unexpected new offset');
  except on E:EGLMError do ; end;
  Inputs.Offsets:=nil; Inputs.Exposures[1]:=-1;
  try P:=TGLMKit.PredictMean(Fit,X,Inputs); Fail('negative new exposure');
  except on E:EGLMError do ; end;
end;

procedure TGLMOffsetsTest.TestAdjustedNumericalFailure;
var X: IDenseDoubleMatrix; Inputs: TGLMInputs; Fit: TGLMFitResult;
  Options: TGLMOptions;
begin
  X:=TDenseDoubleMatrix.FromValues(2,1,[1,1]); Inputs:=TGLMInputs.Default;
  Inputs.Offsets:=TDoubleArray.Create(800,-800);
  Fit:=TGLMKit.FitPoisson(X,[1,1],Inputs);
  AssertEquals(Ord(glsNumericalFailure),Ord(Fit.Status));
  AssertFalse(Fit.Identifiable); AssertEquals(0,Length(Fit.StandardErrors));
  X:=TDenseDoubleMatrix.FromValues(3,2,[1,0,1,1,1,2]);
  Inputs:=TGLMInputs.Default; Inputs.Exposures:=TDoubleArray.Create(1,2,1);
  Options:=TGLMOptions.Default; Options.MaxIterations:=1;
  Fit:=TGLMKit.FitPoisson(X,[2,8,8],Inputs,Options);
  AssertEquals(Ord(glsIterationLimit),Ord(Fit.Status));
  AssertTrue(Fit.HasFiniteIterate); AssertFalse(Fit.Identifiable);
  AssertEquals(0,Length(Fit.StandardErrors));
end;
initialization
  RegisterTest(TGLMOffsetsTest);
end.
