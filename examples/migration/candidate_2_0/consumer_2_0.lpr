program ConsumerCandidate20;

{$mode objfpc}{$H+}{$J-}

uses
  Classes, SysUtils, Math,
  MathBase.SharedTypes, MathBase.Precision, MathBase.Random,
  MathBase.Interchange,
  AlgebraLib.DenseMatrices,
  FinanceLib.Interest,
  EngineeringLib.Common, EngineeringLib.FluidDynamics,
  StatsLib.Stats,
  ProbabilityLib.Distributions,
  CombinatoricsLib.Combinatorics,
  NumericsLib.Numerics,
  OptimizationLib.Optimization,
  TimeSeriesLib.TimeSeries,
  MLLib.MachineLearning,
  GeometryLib.Geometry;

procedure Require(const Condition: Boolean; const MessageText: string);
begin
  if not Condition then
    raise Exception.Create('candidate 2.0 consumer: ' + MessageText);
end;

procedure Passed(const Domain: string);
begin
  WriteLn(Domain, ': success');
end;

function SquareMinusTwo(X: Double): Double;
begin
  Result := X * X - 2.0;
end;

function Parabola(X: Double): Double;
begin
  Result := Sqr(X - 3.0);
end;

var
  MatrixValue, MatrixCopy: IDenseDoubleMatrix;
  Stream: TMemoryStream;
  Restored: IDenseDoubleMatrix;
  GeneratorA, GeneratorB: TLocalRandom;
  Features, Normalised: TDoubleMatrix;
  Smoothed: TDoubleArray;
  Root: TRootResult;
  FailureRaised: Boolean;
begin
  Require(Abs(GammaLn(5.0) - Ln(24.0)) <= 1.0E-12,
    'MathBase double-precision result changed');
  Passed('MathBase');

  MatrixValue := TDenseDoubleMatrix.FromValues(2, 2,
    [2.0, 0.0, 0.0, 3.0]);
  MatrixCopy := MatrixValue.Clone;
  MatrixCopy[0, 0] := 7.0;
  Require((MatrixValue[0, 0] = 2.0) and (MatrixCopy[0, 0] = 7.0),
    'AlgebraLib typed zero-based clone contract changed');
  Passed('AlgebraLib');

  Require(Abs(TFinanceKit.PresentValue(100.0, 0.1, 1) - 90.9091) <= 1.0E-4,
    'FinanceLib default rounding changed');
  Passed('FinanceLib');

  Require(Abs(TFluidDynamicsKit.DynamicPressure(1.0, 2.0) - 2.0) <= 1.0E-12,
    'EngineeringLib canonical pressure path changed');
  Require(Abs(TFluidDynamicsKit.MachNumber(170.0, 340.0) - 0.5) <= 1.0E-12,
    'EngineeringLib canonical velocity path changed');
  FailureRaised := False;
  try
    TFluidDynamicsKit.DynamicPressure(-1.0, 2.0);
  except
    on EFluidDynamicsError do
      FailureRaised := True;
  end;
  Require(FailureRaised, 'EngineeringLib canonical exception changed');
  Passed('EngineeringLib');

  Require(Abs(TStatsKit.Mean(TDoubleArray.Create(1.0, 2.0, 3.0)) - 2.0)
    <= 1.0E-12, 'StatsLib mean changed');
  Passed('StatsLib');

  Require(Abs(TProbabilityKit.NormalCDF(0.0, 0.0, 1.0) - 0.5) <= 1.0E-12,
    'ProbabilityLib normal CDF changed');
  Passed('ProbabilityLib');

  Require(TCombinatoricsKit.Factorial(5) = 120,
    'CombinatoricsLib factorial changed');
  Passed('CombinatoricsLib');

  Root := TNumericsKit.BrentResult(@SquareMinusTwo, 1.0, 2.0);
  Require(Root.Converged and (Abs(Root.Root - Sqrt(2.0)) <= 1.0E-10),
    'NumericsLib explicit root result changed');
  Passed('NumericsLib');

  Require(Abs(TOptimizationKit.GoldenSection(@Parabola, 0.0, 6.0) - 3.0)
    <= 1.0E-6, 'OptimizationLib default solver changed');
  Passed('OptimizationLib');

  Smoothed := TTimeSeriesKit.SimpleMovingAverage(
    TDoubleArray.Create(1.0, 3.0, 5.0), 3);
  Require((Length(Smoothed) = 3) and (Abs(Smoothed[1] - 3.0) <= 1.0E-12),
    'TimeSeriesLib explicit array result changed');
  Passed('TimeSeriesLib');

  SetLength(Features, 2);
  Features[0] := TDoubleArray.Create(10.0, 100.0);
  Features[1] := TDoubleArray.Create(20.0, 200.0);
  Normalised := TMLKit.Normalise(Features);
  Require((Normalised[0][0] = 0.0) and (Normalised[1][1] = 1.0),
    'MLLib row-major normalization changed');
  Passed('MLLib');

  Stream := TMemoryStream.Create;
  try
    SaveBinary(Stream, MatrixValue);
    Stream.Position := 0;
    Restored := LoadDoubleMatrixBinary(Stream, 10);
    Require((Restored.Rows = 2) and (Restored.Cols = 2) and
      (Restored[1, 1] = 3.0), 'InterchangeLib typed round trip changed');
    GeneratorA := TLocalRandom.Seeded(197);
    GeneratorA.NextUInt64;
    Stream.Clear;
    SaveRandomStateBinary(Stream, GeneratorA.GetState);
    Stream.Position := 0;
    GeneratorB.SetState(LoadRandomStateBinary(Stream));
    Require(GeneratorA.NextUInt64 = GeneratorB.NextUInt64,
      'InterchangeLib explicit random-state replay changed');
  finally
    Stream.Free;
  end;
  Passed('InterchangeLib');

  Require(Abs(TPoint2D.Create(0.0, 0.0).DistanceTo(
    TPoint2D.Create(3.0, 4.0)) - 5.0) <= 1.0E-12,
    'GeometryLib value-type distance changed');
  Passed('GeometryLib');

  WriteLn('candidate 2.0 migration consumer: success');
end.
