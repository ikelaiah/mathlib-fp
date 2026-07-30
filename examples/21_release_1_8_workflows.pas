program Release18Workflows;

{$mode objfpc}{$H+}{$J-}

uses
  Classes, SysUtils,
  MathBase.SharedTypes, MathBase.Random, MathBase.Expressions,
  AlgebraLib.DenseMatrices,
  EngineeringLib.DSP, StatsLib.Inference, MLLib.Analysis,
  TimeSeriesLib.StateSpace, InterchangeLib.Models;

var
  Convolver:TOverlapAddConvolver;
  BlockA,BlockB,Tail:TDoubleArray;
  Random:TLocalRandom;
  Distribution:TNormalDistribution;
  Data,Standardized,Identity,Noise,ForecastMean:IDenseDoubleMatrix;
  Labels,Predictions:TIntegerArray;
  Standardizer,RestoredStandardizer:TStandardizationModel;
  Forest:TDecisionForest;
  Configuration:TMultivariateKalmanConfiguration;
  Filter:TMultivariateKalmanFilter;
  Step:TMultivariateKalmanStep;
  Forecast:TMultivariateKalmanForecast;
  Stream:TMemoryStream;
  Symbols:TExpressionSymbols;
  Limits:TExpressionLimits;
  Value:TExpressionValue;
begin
  Convolver:=TOverlapAddConvolver.Create(
    TDoubleArray.Create(0.25,0.5,0.25));
  BlockA:=Convolver.ProcessBlock(TDoubleArray.Create(1,2,3));
  BlockB:=Convolver.ProcessBlock(TDoubleArray.Create(4,5));
  Tail:=Convolver.Flush;
  WriteLn('overlap-add blocks/tail: ',Length(BlockA),' ',
    Length(BlockB),' ',Length(Tail));

  Random:=TLocalRandom.Seeded(180);
  Distribution:=TNormalDistribution.Create(10,2);
  WriteLn('normal q95=',Distribution.Quantile(0.95):0:5,
    ', reproducible sample=',Distribution.Sample(Random):0:5);

  Data:=TDenseDoubleMatrix.FromValues(6,2,
    [0,0, 0.2,0.1, 0.1,0.3, 3,3, 3.2,2.9, 2.8,3.1]);
  Labels:=TIntegerArray.Create(0,0,0,1,1,1);
  Standardizer:=TAnalysisKit.FitStandardization(Data);
  Standardized:=TAnalysisKit.TransformStandardized(Standardizer,Data);
  Forest:=TAnalysisKit.FitClassificationForest(
    Standardized,Labels,24,4,1,180);
  Predictions:=TAnalysisKit.PredictForestClasses(Forest,Standardized);
  WriteLn('forest predictions=',Length(Predictions),
    ', OOB accuracy=',Forest.OOBScore:0:4);

  Identity:=TDenseDoubleMatrix.FromValues(2,2,[1,0,0,1]);
  Noise:=TDenseDoubleMatrix.FromValues(2,2,[0.01,0,0,0.01]);
  Configuration:=TMultivariateKalmanConfiguration.Create(
    Identity,Identity,Noise,Noise);
  Filter:=TMultivariateKalmanFilter.Create(Configuration,
    TDoubleArray.Create(0,0),Identity);
  Step:=Filter.Update(TDoubleArray.Create(1,-1));
  Forecast:=Filter.Forecast(2);
  ForecastMean:=Forecast.ObservationMeans;
  WriteLn('Kalman state=',Step.StateMean[0]:0:4,',',
    Step.StateMean[1]:0:4,', forecast rows=',ForecastMean.Rows);

  Stream:=TMemoryStream.Create;
  try
    SaveStandardization(Stream,Standardizer);
    Stream.Position:=0;
    RestoredStandardizer:=LoadStandardization(Stream,16);
    WriteLn(SummarizeStandardization(RestoredStandardizer));
  finally
    Stream.Free;
  end;

  SetLength(Symbols,2);
  Symbols[0].Name:='x';
  Symbols[0].Value:=TExpressionValue.FromScalar(2);
  Symbols[1].Name:='v';
  Symbols[1].Value:=TExpressionValue.FromVector(
    TDoubleArray.Create(1,2,3));
  Limits:=TExpressionLimits.Defaults;
  Value:=TExpressionEvaluator.Evaluate('dot(v,v)+x',Symbols,Limits);
  WriteLn('bounded expression result=',Value.Scalar:0:1);
end.
