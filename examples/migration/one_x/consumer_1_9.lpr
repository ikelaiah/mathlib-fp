program Consumer19;

{$mode objfpc}{$H+}{$J-}

uses
  Classes, SysUtils, Math,
  MathBase.SharedTypes, MathBase.Precision, MathBase.Random,
  MathBase.Interchange,
  AlgebraLib.Matrices, AlgebraLib.DenseMatrices,
  FinanceLib.Interest,
  EngineeringLib.Pressure, EngineeringLib.Velocity,
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
    raise Exception.Create('1.x consumer: ' + MessageText);
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
  LegacyMatrix, LegacyCopy: IMatrix;
  Stream: TMemoryStream;
  Original, Restored: IDenseDoubleMatrix;
  GeneratorA, GeneratorB: TLocalRandom;
  Features, Normalised: TDoubleMatrix;
  Smoothed: TDoubleArray;
  Root: TRootResult;
  FailureRaised: Boolean;
begin
  Require(Abs(GammaLn(5.0) - Ln(24.0)) <= 1.0E-12,
    'MathBase double-precision result changed');
  Passed('MathBase');

  LegacyMatrix := TMatrixKit.CreateFromArray([[2.0, 0.0], [0.0, 3.0]]);
  LegacyCopy := LegacyMatrix.ScalarMultiply(1.0);
  LegacyCopy[0, 0] := 7.0;
  Require((LegacyMatrix[0, 0] = 2.0) and (LegacyCopy[0, 0] = 7.0),
    'AlgebraLib zero-based explicit copy contract changed');
  Passed('AlgebraLib');

  Require(Abs(TFinanceKit.PresentValue(100.0, 0.1, 1) - 90.9091) <= 1.0E-4,
    'FinanceLib default rounding changed');
  Passed('FinanceLib');

  Require(Abs(TPressureKit.DynamicPressure(1.0, 2.0) - 2.0) <= 1.0E-12,
    'EngineeringLib pressure alias changed');
  Require(Abs(TVelocityKit.MachNumber(170.0, 340.0) - 0.5) <= 1.0E-12,
    'EngineeringLib velocity alias changed');
  FailureRaised := False;
  try
    TPressureKit.DynamicPressure(-1.0, 2.0);
  except
    on EPressureError do
      FailureRaised := True;
  end;
  Require(FailureRaised, 'EngineeringLib focused exception alias changed');
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
    'NumericsLib root diagnostics changed');
  Passed('NumericsLib');

  Require(Abs(TOptimizationKit.GoldenSection(@Parabola, 0.0, 6.0) - 3.0)
    <= 1.0E-6, 'OptimizationLib default solver changed');
  Passed('OptimizationLib');

  Smoothed := TTimeSeriesKit.SimpleMovingAverage(
    TDoubleArray.Create(1.0, 3.0, 5.0), 3);
  Require((Length(Smoothed) = 3) and (Abs(Smoothed[1] - 3.0) <= 1.0E-12),
    'TimeSeriesLib result interpretation changed');
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
    Original := TDenseDoubleMatrix.FromValues(1, 2, [4.0, 5.0]);
    SaveBinary(Stream, Original);
    Stream.Position := 0;
    Restored := LoadDoubleMatrixBinary(Stream, 10);
    Require((Restored.Rows = 1) and (Restored.Cols = 2) and
      (Restored[0, 1] = 5.0), 'InterchangeLib round trip changed');
    GeneratorA := TLocalRandom.Seeded(197);
    GeneratorA.NextUInt64;
    Stream.Clear;
    SaveRandomStateBinary(Stream, GeneratorA.GetState);
    Stream.Position := 0;
    GeneratorB.SetState(LoadRandomStateBinary(Stream));
    Require(GeneratorA.NextUInt64 = GeneratorB.NextUInt64,
      'InterchangeLib random-state ownership changed');
  finally
    Stream.Free;
  end;
  Passed('InterchangeLib');

  Require(Abs(TPoint2D.Create(0.0, 0.0).DistanceTo(
    TPoint2D.Create(3.0, 4.0)) - 5.0) <= 1.0E-12,
    'GeometryLib distance changed');
  Passed('GeometryLib');

  WriteLn('1.x migration consumer: success');
end.
