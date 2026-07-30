unit TestPublicAPI;

{-----------------------------------------------------------------------------
 TestPublicAPI

 Compile-time smoke coverage for the Kit classes documented in docs/index.md.
 Domain test suites exercise their behaviour; this unit protects the public
 identifiers and their documented import paths from accidental drift.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, Math, fpcunit, testregistry,
  MathBase.Complex,
  MathBase.Random, MathBase.Interchange, MathBase.Expressions,
  MathBase.Trigonometry,
  AlgebraLib.Matrices, AlgebraLib.VectorKernels,
  AlgebraLib.DenseMatrices, AlgebraLib.DenseKernels,
  AlgebraLib.DenseSolvers, AlgebraLib.DenseDecompositions,
  FinanceLib.Interest, FinanceLib.Bonds, FinanceLib.NPV,
  StatsLib.Stats, StatsLib.Streaming, StatsLib.Inference,
  EngineeringLib.FluidDynamics, EngineeringLib.Thermodynamics,
  EngineeringLib.Signal, EngineeringLib.DSP, EngineeringLib.UnitConversion,
  EngineeringLib.Velocity, EngineeringLib.Pressure,
  NumericsLib.Numerics,
  NumericsLib.Differentiation, NumericsLib.Interpolation,
  NumericsLib.Modelling,
  ProbabilityLib.Distributions,
  CombinatoricsLib.Combinatorics,
  OptimizationLib.Optimization,
  OptimizationLib.Convex,
  TimeSeriesLib.TimeSeries, TimeSeriesLib.StateSpace,
  MLLib.MachineLearning, MLLib.Analysis, InterchangeLib.Models,
  GeometryLib.Geometry;

type
  TTrigKitClass = class of TTrigKit;
  TMatrixKitClass = class of TMatrixKit;
  TVectorKitClass = class of TVectorKit;
  TFinanceKitClass = class of TFinanceKit;
  TBondKitClass = class of TBondKit;
  TNPVKitClass = class of TNPVKit;
  TStatsKitClass = class of TStatsKit;
  TInferenceKitClass = class of TInferenceKit;
  TFluidDynamicsKitClass = class of TFluidDynamicsKit;
  TThermodynamicsKitClass = class of TThermodynamicsKit;
  TSignalKitClass = class of TSignalKit;
  TDSPKitClass = class of TDSPKit;
  TUnitConversionKitClass = class of TUnitConversionKit;
  TVelocityKitClass = class of TVelocityKit;
  TPressureKitClass = class of TPressureKit;
  TNumericsKitClass = class of TNumericsKit;
  TDifferentiationKitClass = class of TDifferentiationKit;
  TInterpolationKitClass = class of TInterpolationKit;
  TModellingKitClass = class of TModellingKit;
  TProbabilityKitClass = class of TProbabilityKit;
  TCombinatoricsKitClass = class of TCombinatoricsKit;
  TOptimizationKitClass = class of TOptimizationKit;
  TConvexOptimizationKitClass = class of TConvexOptimizationKit;
  TTimeSeriesKitClass = class of TTimeSeriesKit;
  TMLKitClass = class of TMLKit;
  TAnalysisKitClass = class of TAnalysisKit;
  TGeometryKitClass = class of TGeometryKit;
  TExpressionEvaluatorClass = class of TExpressionEvaluator;

  TTestPublicAPI = class(TTestCase)
  published
    procedure TestDocumentedKitClassesAreAccessible;
    procedure TestGeometryVectorArithmeticOperatorsAreAccessible;
    procedure TestTypedDenseSolveIsAccessible;
    procedure TestTypedDenseDecompositionsAreAccessible;
    procedure TestAppliedNumericsSurfaceIsAccessible;
  end;

implementation

procedure TTestPublicAPI.TestDocumentedKitClassesAreAccessible;
var
  TrigKit: TTrigKitClass;
  MatrixKit: TMatrixKitClass;
  VectorKit: TVectorKitClass;
  ComplexValue: TComplex;
  FinanceKit: TFinanceKitClass;
  BondKit: TBondKitClass;
  NPVKit: TNPVKitClass;
  StatsKit: TStatsKitClass;
  InferenceKit:TInferenceKitClass;
  FluidDynamicsKit: TFluidDynamicsKitClass;
  ThermodynamicsKit: TThermodynamicsKitClass;
  SignalKit: TSignalKitClass;
  DSPKit: TDSPKitClass;
  UnitConversionKit: TUnitConversionKitClass;
  VelocityKit: TVelocityKitClass;
  PressureKit: TPressureKitClass;
  NumericsKit: TNumericsKitClass;
  DifferentiationKit: TDifferentiationKitClass;
  InterpolationKit: TInterpolationKitClass;
  ModellingKit: TModellingKitClass;
  ProbabilityKit: TProbabilityKitClass;
  CombinatoricsKit: TCombinatoricsKitClass;
  OptimizationKit: TOptimizationKitClass;
  ConvexOptimizationKit: TConvexOptimizationKitClass;
  TimeSeriesKit: TTimeSeriesKitClass;
  MLKit: TMLKitClass;
  AnalysisKit: TAnalysisKitClass;
  GeometryKit: TGeometryKitClass;
  ExpressionEvaluator:TExpressionEvaluatorClass;
begin
  TrigKit := TTrigKit;
  MatrixKit := TMatrixKit;
  VectorKit := TVectorKit;
  ComplexValue := CAsin(TComplex.Create(0.5, 0.0));
  FinanceKit := TFinanceKit;
  BondKit := TBondKit;
  NPVKit := TNPVKit;
  StatsKit := TStatsKit;
  InferenceKit:=TInferenceKit;
  FluidDynamicsKit := TFluidDynamicsKit;
  ThermodynamicsKit := TThermodynamicsKit;
  SignalKit := TSignalKit;
  DSPKit := TDSPKit;
  UnitConversionKit := TUnitConversionKit;
  VelocityKit := TVelocityKit;
  PressureKit := TPressureKit;
  NumericsKit := TNumericsKit;
  DifferentiationKit := TDifferentiationKit;
  InterpolationKit := TInterpolationKit;
  ModellingKit := TModellingKit;
  ProbabilityKit := TProbabilityKit;
  CombinatoricsKit := TCombinatoricsKit;
  OptimizationKit := TOptimizationKit;
  ConvexOptimizationKit := TConvexOptimizationKit;
  TimeSeriesKit := TTimeSeriesKit;
  MLKit := TMLKit;
  AnalysisKit := TAnalysisKit;
  GeometryKit := TGeometryKit;
  ExpressionEvaluator:=TExpressionEvaluator;

  AssertTrue('TTrigKit', TrigKit <> nil);
  AssertTrue('TMatrixKit', MatrixKit <> nil);
  AssertTrue('TVectorKit', VectorKit <> nil);
  AssertEquals('TComplex public API', Pi / 6.0, ComplexValue.Re, 1E-15);
  AssertTrue('TFinanceKit', FinanceKit <> nil);
  AssertTrue('TBondKit', BondKit <> nil);
  AssertTrue('TNPVKit', NPVKit <> nil);
  AssertTrue('TStatsKit', StatsKit <> nil);
  AssertTrue('TInferenceKit',InferenceKit<>nil);
  AssertTrue('TFluidDynamicsKit', FluidDynamicsKit <> nil);
  AssertTrue('TThermodynamicsKit', ThermodynamicsKit <> nil);
  AssertTrue('TSignalKit', SignalKit <> nil);
  AssertTrue('TDSPKit', DSPKit <> nil);
  AssertTrue('TUnitConversionKit', UnitConversionKit <> nil);
  AssertTrue('TVelocityKit', VelocityKit <> nil);
  AssertTrue('TPressureKit', PressureKit <> nil);
  AssertTrue('TNumericsKit', NumericsKit <> nil);
  AssertTrue('TDifferentiationKit', DifferentiationKit <> nil);
  AssertTrue('TInterpolationKit', InterpolationKit <> nil);
  AssertTrue('TModellingKit', ModellingKit <> nil);
  AssertTrue('TProbabilityKit', ProbabilityKit <> nil);
  AssertTrue('TCombinatoricsKit', CombinatoricsKit <> nil);
  AssertTrue('TOptimizationKit', OptimizationKit <> nil);
  AssertTrue('TConvexOptimizationKit', ConvexOptimizationKit <> nil);
  AssertTrue('TTimeSeriesKit', TimeSeriesKit <> nil);
  AssertTrue('TMLKit', MLKit <> nil);
  AssertTrue('TAnalysisKit', AnalysisKit <> nil);
  AssertTrue('TGeometryKit', GeometryKit <> nil);
  AssertTrue('TExpressionEvaluator',ExpressionEvaluator<>nil);
end;

procedure TTestPublicAPI.TestAppliedNumericsSurfaceIsAccessible;
var
  Generator: TLocalRandom;
  State: TRandomState;
  Statistics: TOnlineStatistics;
  Configuration: TScalarKalmanConfiguration;
  Filter: TScalarKalmanFilter;
  A, B, Destination: IDenseDoubleMatrix;
  Text: string;
begin
  Generator := TLocalRandom.Seeded(180);
  State := Generator.GetState;
  Generator.SetState(State);
  AssertTrue('explicit local random state', Generator.NextDouble >= 0.0);

  Statistics := TOnlineStatistics.Create(nfpReject);
  Statistics.Add(4.0);
  AssertEquals('streaming statistics', 4.0, Statistics.Mean, 0.0);

  Configuration := TScalarKalmanConfiguration.Create(1.0, 1.0, 0.1, 0.2);
  Filter := TScalarKalmanFilter.Create(Configuration, 0.0, 1.0);
  Filter.Update(1.0);
  AssertTrue('scalar state space', Filter.Variance >= 0.0);

  A := TDenseDoubleMatrix.FromValues(1, 1, [2.0]);
  B := TDenseDoubleMatrix.FromValues(1, 1, [3.0]);
  Destination := TDenseDoubleMatrix.Zeros(1, 1);
  MultiplyAutoInto(A, B, Destination);
  AssertEquals('automatic portable/blocked multiply', 6.0,
    Destination[0, 0], 0.0);

  Text := DenseMatrixToInvariant(A);
  AssertTrue('invariant interchange', Length(Text) > 0);
end;

procedure TTestPublicAPI.TestGeometryVectorArithmeticOperatorsAreAccessible;
var
  V2: TVector2D;
  V3: TVector3D;
begin
  V2 := 2.0 * (TVector2D.Create(3.0, -4.0) + TVector2D.Create(1.0, 2.0));
  V2 := -V2 / 2.0;
  AssertEquals('TVector2D operator X', -4.0, V2.X, 0.0);
  AssertEquals('TVector2D operator Y', 2.0, V2.Y, 0.0);

  V3 := 2.0 * (TVector3D.Create(3.0, -4.0, 5.0) -
    TVector3D.Create(1.0, 2.0, 3.0));
  V3 := -V3 / 2.0;
  AssertEquals('TVector3D operator X', -2.0, V3.X, 0.0);
  AssertEquals('TVector3D operator Y', 6.0, V3.Y, 0.0);
  AssertEquals('TVector3D operator Z', -2.0, V3.Z, 0.0);
end;

procedure TTestPublicAPI.TestTypedDenseSolveIsAccessible;
var
  A, B, X: IDenseDoubleMatrix;
  Z: IDenseComplexMatrix;
begin
  A := TDenseDoubleMatrix.FromValues(2, 2, [2.0, 0.0, 0.0, 4.0]);
  B := TDenseDoubleMatrix.FromValues(2, 1, [6.0, 8.0]);
  X := Solve(A, B);
  AssertEquals('typed Solve', 3.0, X[0, 0], 0.0);
  Z := TDenseComplexMatrix.FromValues(1, 1, [TComplex.Create(1.0, 2.0)]);
  Z := ConjugateTranspose(Z);
  AssertEquals('typed complex kernel', -2.0, Z[0, 0].Im, 0.0);
end;

procedure TTestPublicAPI.TestTypedDenseDecompositionsAreAccessible;
var
  A, B, X: IDenseDoubleMatrix;
  QR: IDenseDoubleQR;
  SVD: IDenseDoubleSVD;
  Eigen: IDenseDoubleSymmetricEigen;
  Info: TDenseSolveDiagnostics;
begin
  A := TDenseDoubleMatrix.FromValues(3, 2,
    [1.0, 0.0, 0.0, 1.0, 1.0, 1.0]);
  B := TDenseDoubleMatrix.FromValues(3, 1, [1.0, 2.0, 3.0]);
  QR := FactorPivotedQR(A);
  X := QR.SolveLeastSquaresWithInfo(B, Info);
  AssertEquals('typed QR rank', 2, Info.NumericalRank);
  AssertEquals('typed QR result shape', 2, X.Rows);
  SVD := FactorSVD(A);
  AssertEquals('typed SVD compact size', 2, Length(SVD.SingularValues));
  Eigen := FactorSymmetricEigen(
    TDenseDoubleMatrix.FromValues(2, 2, [2.0, 1.0, 1.0, 2.0]));
  AssertEquals('typed eigen size', 2, Length(Eigen.Eigenvalues));
end;

initialization
  RegisterTest(TTestPublicAPI);

end.
