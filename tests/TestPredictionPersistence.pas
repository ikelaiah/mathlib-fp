unit TestPredictionPersistence;
{$mode objfpc}{$H+}{$J-}
interface
uses Classes, SysUtils, Math, fpcunit, testregistry, MathBase.SharedTypes,
  AlgebraLib.DenseMatrices, MLLib.MachineLearning, MLLib.Analysis, MLLib.PLS,
  StatsLib.GLM, InterchangeLib.Models, NumericsLib.Interpolation,
  EngineeringLib.DSP, TimeSeriesLib.StateSpace;
type TPredictionPersistenceTest = class(TTestCase)
  private
    procedure ExpectInvalidGLM(const Stream:TMemoryStream);
    procedure ExpectInvalidPLS(const Stream:TMemoryStream);
  published
    procedure TestGLMProjection;
    procedure TestPLSOriginalScaleProjection;
    procedure TestProjectionFailures;
    procedure TestLogisticRoundTrip;
    procedure TestMalformedGLMAndLimits;
    procedure TestMalformedPLSAndInvalidSave;
    procedure TestLegacyFixedEnvelopes;
  end;
implementation
{$I PredictionLegacyFixtures.inc}

function StreamBytes(const Stream:TMemoryStream):TBytes;
begin
  Result:=nil; SetLength(Result,Stream.Size); Stream.Position:=0;
  if Length(Result)>0 then Stream.ReadBuffer(Result[0],Length(Result));
  Stream.Position:=0;
end;

procedure SetStreamBytes(const Stream:TMemoryStream; const Bytes:TBytes);
begin
  Stream.Clear;
  if Length(Bytes)>0 then Stream.WriteBuffer(Bytes[0],Length(Bytes));
  Stream.Position:=0;
end;

procedure RepairChecksum(var Bytes:TBytes);
var I,J:Integer; CRC:LongWord;
begin
  CRC:=$FFFFFFFF;
  for I:=24 to High(Bytes) do begin
    CRC:=CRC xor Bytes[I];
    for J:=0 to 7 do
      if (CRC and 1)<>0 then CRC:=(CRC shr 1) xor $EDB88320
      else CRC:=CRC shr 1;
  end;
  CRC:=not CRC;
  for I:=0 to 3 do Bytes[20+I]:=(CRC shr (8*I)) and $FF;
end;

procedure PatchPayload(const Stream:TMemoryStream; Index:Integer; Value:Byte);
var Bytes:TBytes;
begin
  Bytes:=StreamBytes(Stream); Bytes[24+Index]:=Value;
  RepairChecksum(Bytes); SetStreamBytes(Stream,Bytes);
end;

procedure LoadHex(const Stream:TMemoryStream; const Hex:String);
var Bytes:TBytes; I:Integer;
begin
  SetLength(Bytes,Length(Hex) div 2);
  for I:=0 to High(Bytes) do Bytes[I]:=StrToInt('$'+Copy(Hex,2*I+1,2));
  SetStreamBytes(Stream,Bytes);
end;

function StreamHex(const Stream:TMemoryStream):String;
var Bytes:TBytes; I:Integer;
begin
  Bytes:=StreamBytes(Stream); Result:='';
  for I:=0 to High(Bytes) do Result:=Result+IntToHex(Bytes[I],2);
end;

procedure TPredictionPersistenceTest.ExpectInvalidGLM(const Stream:TMemoryStream);
var Model:TGLMPredictionModel;
begin
  Stream.Position:=0;
  try Model:=LoadGLMPrediction(Stream); Fail('invalid GLM artifact accepted');
  except on E:EModelInterchangeError do ; end;
end;

procedure TPredictionPersistenceTest.ExpectInvalidPLS(const Stream:TMemoryStream);
var Model:TPLSPredictionModel;
begin
  Stream.Position:=0;
  try Model:=LoadPLSPrediction(Stream); Fail('invalid PLS artifact accepted');
  except on E:EModelInterchangeError do ; end;
end;

procedure TPredictionPersistenceTest.TestGLMProjection;
var X:IDenseDoubleMatrix; Inputs,NewInputs:TGLMInputs; Fit:TGLMFitResult;
  Model:TGLMPredictionModel; P:TDoubleArray; Stream:TMemoryStream;
begin
  X:=TDenseDoubleMatrix.FromValues(3,1,[1,1,1]); Inputs:=TGLMInputs.Default;
  Inputs.Offsets:=TDoubleArray.Create(Ln(2.0),Ln(2.0),Ln(2.0));
  Inputs.Exposures:=TDoubleArray.Create(0.5,1,1.5);
  Inputs.FrequencyWeights:=TGLMFrequencyWeights.Create(2,1,3);
  Fit:=TGLMKit.FitPoisson(X,[2,4,6],Inputs);
  AssertEquals(Fit.Message,Ord(glsConverged),Ord(Fit.Status));
  Model:=TGLMKit.ToPredictionModel(Fit);
  Fit.Coefficients[0]:=99;
  AssertEquals(Ln(2.0),Model.Coefficients[0],2E-9);
  AssertTrue(Model.UsesOffsets); AssertTrue(Model.UsesExposure);
  NewInputs:=TGLMInputs.Default; NewInputs.Offsets:=TDoubleArray.Create(Ln(2.0));
  NewInputs.Exposures:=TDoubleArray.Create(4);
  X:=TDenseDoubleMatrix.FromValues(1,1,[1]);
  P:=TGLMKit.PredictMean(Model,X,NewInputs);
  AssertEquals(16.0,P[0],2E-8);
  Stream:=TMemoryStream.Create;
  try
    SaveGLMPrediction(Stream,Model); AssertEquals(Int64(48),Stream.Size);
    Stream.Position:=0; Model:=LoadGLMPrediction(Stream); Stream.Clear;
    P:=TGLMKit.PredictMean(Model,X,NewInputs); AssertEquals(16.0,P[0],2E-8);
  finally Stream.Free; end;
end;

procedure TPredictionPersistenceTest.TestPLSOriginalScaleProjection;
var X:TDoubleMatrix; Y,P:TDoubleArray; Fit:TPLSModel;
  Model:TPLSPredictionModel; I:Integer; Stream:TMemoryStream;
begin
  SetLength(X,6); SetLength(Y,6);
  for I:=0 to 5 do begin
    X[I]:=TDoubleArray.Create(100+I,200+2*I); Y[I]:=203+2*I;
  end;
  Fit:=TPLSKit.Fit(X,Y); Model:=TPLSKit.ToPredictionModel(Fit);
  Fit.Coefficients[0]:=999; Fit.PredictorMeans:=nil; Fit.PredictorScales:=nil;
  SetLength(X,1); X[0]:=TDoubleArray.Create(110,220);
  P:=TPLSKit.Predict(Model,X); AssertEquals(223.0,P[0],2E-8);
  Stream:=TMemoryStream.Create;
  try
    SavePLSPrediction(Stream,Model); AssertEquals(Int64(64),Stream.Size);
    Stream.Position:=0; Model:=LoadPLSPrediction(Stream); Stream.Clear;
    P:=TPLSKit.Predict(Model,X); AssertEquals(223.0,P[0],2E-8);
  finally Stream.Free; end;
  Model.Coefficients:=TDoubleArray.Create(0,0); Model.Intercept:=7;
  Stream:=TMemoryStream.Create;
  try
    SavePLSPrediction(Stream,Model); Stream.Position:=0;
    Model:=LoadPLSPrediction(Stream,2);
    P:=TPLSKit.Predict(Model,X); AssertEquals(7.0,P[0],0);
  finally Stream.Free; end;
end;

procedure TPredictionPersistenceTest.TestLogisticRoundTrip;
var X:IDenseDoubleMatrix; Inputs:TGLMInputs; Fit:TGLMFitResult;
  Model:TGLMPredictionModel; Stream:TMemoryStream; P:TDoubleArray;
begin
  X:=TDenseDoubleMatrix.FromValues(4,1,[1,1,1,1]); Inputs:=TGLMInputs.Default;
  Inputs.Offsets:=TDoubleArray.Create(Ln(2.0)-Ln(3.0),Ln(2.0)-Ln(3.0),
    Ln(2.0)+Ln(3.0),Ln(2.0)+Ln(3.0));
  Fit:=TGLMKit.FitLogistic(X,[0,0,1,1],Inputs);
  Model:=TGLMKit.ToPredictionModel(Fit); Stream:=TMemoryStream.Create;
  try
    SaveGLMPrediction(Stream,Model); Stream.Position:=0;
    Model:=LoadGLMPrediction(Stream); P:=TGLMKit.PredictMean(Model,X,Inputs);
    AssertEquals(0.25,P[0],2E-9); AssertEquals(0.75,P[3],2E-9);
  finally Stream.Free; end;
end;

procedure TPredictionPersistenceTest.TestMalformedGLMAndLimits;
const Bad:array[0..7] of Byte=(2,2,0,1,1,1,128,1);
var Stream:TMemoryStream; Model:TGLMPredictionModel; Bytes:TBytes; I,J:Integer;
begin
  Stream:=TMemoryStream.Create;
  Model:=Default(TGLMPredictionModel); Model.Family:=gfPoissonLog;
  Model.Coefficients:=TDoubleArray.Create(2,0);
  try
    for I in [0,8,10,11,20] do begin
      Stream.Clear; SaveGLMPrediction(Stream,Model); Bytes:=StreamBytes(Stream);
      Bytes[I]:=Bytes[I] xor 1; SetStreamBytes(Stream,Bytes); ExpectInvalidGLM(Stream);
    end;
    for I:=0 to 7 do begin
      Stream.Clear; SaveGLMPrediction(Stream,Model);
      PatchPayload(Stream,I,Bad[I]); ExpectInvalidGLM(Stream);
    end;
    Stream.Clear; SaveGLMPrediction(Stream,Model);
    PatchPayload(Stream,22,$F8); PatchPayload(Stream,23,$7F); ExpectInvalidGLM(Stream);
    Stream.Clear; SaveGLMPrediction(Stream,Model);
    for J:=8 to 15 do PatchPayload(Stream,J,0);
    ExpectInvalidGLM(Stream);
    Stream.Clear; SaveGLMPrediction(Stream,Model); Bytes:=StreamBytes(Stream);
    SetLength(Bytes,Length(Bytes)+1); Bytes[High(Bytes)]:=0; Bytes[12]:=33;
    RepairChecksum(Bytes); SetStreamBytes(Stream,Bytes); ExpectInvalidGLM(Stream);
    Stream.Clear; SaveGLMPrediction(Stream,Model); Stream.Size:=23; ExpectInvalidGLM(Stream);
    Stream.Clear; SaveGLMPrediction(Stream,Model); Stream.Position:=0;
    try Model:=LoadGLMPrediction(Stream,1); Fail('element cap ignored');
    except on E:EModelInterchangeError do ; end;
    Stream.Position:=0;
    try Model:=LoadGLMPrediction(Stream,0); Fail('zero cap accepted');
    except on E:EModelInterchangeError do ; end;
    AssertEquals(Int64(0),Stream.Position);
    try Model:=LoadGLMPrediction(Stream,High(QWord)); Fail('byte overflow cap');
    except on E:EModelInterchangeError do ; end;
    AssertEquals(Int64(0),Stream.Position);
    Stream.Clear; Model.Coefficients:=TDoubleArray.Create(2);
    SaveGLMPrediction(Stream,Model); Stream.Position:=0;
    Model:=LoadGLMPrediction(Stream,1);
    AssertEquals(2.0,Model.Coefficients[0],0);
  finally Stream.Free; end;
end;

procedure TPredictionPersistenceTest.TestMalformedPLSAndInvalidSave;
const Bad:array[0..7] of Byte=(2,0,1,1,1,1,1,1);
var Stream:TMemoryStream; Model:TPLSPredictionModel; GLM:TGLMPredictionModel; I:Integer;
begin
  Stream:=TMemoryStream.Create; Model.Intercept:=3;
  Model.Coefficients:=TDoubleArray.Create(2);
  try
    for I:=0 to 7 do begin
      Stream.Clear; SavePLSPrediction(Stream,Model);
      PatchPayload(Stream,I,Bad[I]); ExpectInvalidPLS(Stream);
    end;
    Stream.Clear; SavePLSPrediction(Stream,Model);
    PatchPayload(Stream,14,$F8); PatchPayload(Stream,15,$7F); ExpectInvalidPLS(Stream);
    Stream.Clear; SavePLSPrediction(Stream,Model);
    PatchPayload(Stream,30,$F8); PatchPayload(Stream,31,$7F); ExpectInvalidPLS(Stream);
    Stream.Position:=0;
    try Model:=LoadPLSPrediction(Stream,0); Fail('zero PLS cap');
    except on E:EModelInterchangeError do ; end;
    AssertEquals(Int64(0),Stream.Position);
    try Model:=LoadPLSPrediction(Stream,High(QWord)); Fail('PLS byte overflow cap');
    except on E:EModelInterchangeError do ; end;
    AssertEquals(Int64(0),Stream.Position);
    Stream.Clear; Model.Intercept:=NaN;
    try SavePLSPrediction(Stream,Model); Fail('nonfinite save intercept');
    except on E:EModelInterchangeError do ; end;
    AssertEquals(Int64(0),Stream.Size);
    Model.Intercept:=3; Model.Coefficients:=nil;
    try SavePLSPrediction(Stream,Model); Fail('empty save vector');
    except on E:EModelInterchangeError do ; end;
    GLM:=Default(TGLMPredictionModel); GLM.Coefficients:=TDoubleArray.Create(0);
    GLM.UsesExposure:=True;
    try SaveGLMPrediction(Stream,GLM); Fail('logistic exposure artifact');
    except on E:EModelInterchangeError do ; end;
    GLM.UsesExposure:=False; GLM.Coefficients[0]:=NaN;
    try SaveGLMPrediction(Stream,GLM); Fail('nonfinite GLM save');
    except on E:EModelInterchangeError do ; end;
  finally Stream.Free; end;
end;

procedure TPredictionPersistenceTest.TestLegacyFixedEnvelopes;
var Stream:TMemoryStream; Spline:TCubicSplineInterpolator; FIR:TStreamingFIR;
  Standard:TStandardizationModel; Kalman:TScalarKalmanFilter;
begin
  Stream:=TMemoryStream.Create;
  try
    LoadHex(Stream,LegacySplineHex); Spline:=LoadCubicSpline(Stream);
    AssertEquals(0.5,Spline.Evaluate(0.5),0);
    Stream.Clear; SaveCubicSpline(Stream,Spline); AssertEquals(LegacySplineHex,StreamHex(Stream));
    LoadHex(Stream,LegacyFIRHex); FIR:=LoadStreamingFIR(Stream);
    AssertEquals(2.0,FIR.History[0],0); AssertEquals(1.0,FIR.History[1],0);
    Stream.Clear; SaveStreamingFIR(Stream,FIR); AssertEquals(LegacyFIRHex,StreamHex(Stream));
    LoadHex(Stream,LegacyStandardizationHex); Standard:=LoadStandardization(Stream);
    AssertEquals(3.0,Standard.Means[0],0); AssertEquals(2.0,Standard.Scales[0],0);
    Stream.Clear; SaveStandardization(Stream,Standard);
    AssertEquals(LegacyStandardizationHex,StreamHex(Stream));
    LoadHex(Stream,LegacyKalmanHex); Kalman:=LoadScalarKalman(Stream);
    AssertEquals(3.0,Kalman.Estimate,0); AssertEquals(0.4,Kalman.Variance,0);
    Stream.Clear; SaveScalarKalman(Stream,Kalman); AssertEquals(LegacyKalmanHex,StreamHex(Stream));
  finally Stream.Free; end;
end;

procedure TPredictionPersistenceTest.TestProjectionFailures;
var X:IDenseDoubleMatrix; Fit:TGLMFitResult; Model:TGLMPredictionModel;
  PLSFit:TPLSModel; PLSModel:TPLSPredictionModel; P:TDoubleArray;
  Rows:TDoubleMatrix;
begin
  Fit:=Default(TGLMFitResult); Fit.Status:=glsIterationLimit;
  try Model:=TGLMKit.ToPredictionModel(Fit); Fail('failed fit projected');
  except on E:EGLMError do ; end;
  PLSFit:=Default(TPLSModel); PLSFit.Coefficients:=TDoubleArray.Create(1);
  PLSFit.PredictorMeans:=TDoubleArray.Create(0);
  PLSFit.PredictorScales:=TDoubleArray.Create(0);
  try PLSModel:=TPLSKit.ToPredictionModel(PLSFit); Fail('invalid scales projected');
  except on E:EPLSError do ; end;
  Model:=Default(TGLMPredictionModel); X:=TDenseDoubleMatrix.FromValues(1,1,[1]);
  try P:=TGLMKit.PredictMean(Model,X); Fail('empty inference coefficients');
  except on E:EGLMError do ; end;
  PLSModel.Coefficients:=TDoubleArray.Create(0); PLSModel.Intercept:=NaN;
  SetLength(Rows,1); Rows[0]:=TDoubleArray.Create(1);
  try P:=TPLSKit.Predict(PLSModel,Rows); Fail('nonfinite inference intercept');
  except on E:EPLSError do ; end;
end;
initialization
  RegisterTest(TPredictionPersistenceTest);
end.
