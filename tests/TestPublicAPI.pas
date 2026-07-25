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
  MathBase.Trigonometry,
  AlgebraLib.Matrices, AlgebraLib.VectorKernels,
  FinanceLib.Interest, FinanceLib.Bonds, FinanceLib.NPV,
  StatsLib.Stats,
  EngineeringLib.FluidDynamics, EngineeringLib.Thermodynamics,
  EngineeringLib.Signal, EngineeringLib.UnitConversion,
  EngineeringLib.Velocity, EngineeringLib.Pressure,
  NumericsLib.Numerics,
  ProbabilityLib.Distributions,
  CombinatoricsLib.Combinatorics,
  OptimizationLib.Optimization,
  TimeSeriesLib.TimeSeries,
  MLLib.MachineLearning,
  GeometryLib.Geometry;

type
  TTrigKitClass = class of TTrigKit;
  TMatrixKitClass = class of TMatrixKit;
  TVectorKitClass = class of TVectorKit;
  TFinanceKitClass = class of TFinanceKit;
  TBondKitClass = class of TBondKit;
  TNPVKitClass = class of TNPVKit;
  TStatsKitClass = class of TStatsKit;
  TFluidDynamicsKitClass = class of TFluidDynamicsKit;
  TThermodynamicsKitClass = class of TThermodynamicsKit;
  TSignalKitClass = class of TSignalKit;
  TUnitConversionKitClass = class of TUnitConversionKit;
  TVelocityKitClass = class of TVelocityKit;
  TPressureKitClass = class of TPressureKit;
  TNumericsKitClass = class of TNumericsKit;
  TProbabilityKitClass = class of TProbabilityKit;
  TCombinatoricsKitClass = class of TCombinatoricsKit;
  TOptimizationKitClass = class of TOptimizationKit;
  TTimeSeriesKitClass = class of TTimeSeriesKit;
  TMLKitClass = class of TMLKit;
  TGeometryKitClass = class of TGeometryKit;

  TTestPublicAPI = class(TTestCase)
  published
    procedure TestDocumentedKitClassesAreAccessible;
    procedure TestGeometryVectorArithmeticOperatorsAreAccessible;
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
  FluidDynamicsKit: TFluidDynamicsKitClass;
  ThermodynamicsKit: TThermodynamicsKitClass;
  SignalKit: TSignalKitClass;
  UnitConversionKit: TUnitConversionKitClass;
  VelocityKit: TVelocityKitClass;
  PressureKit: TPressureKitClass;
  NumericsKit: TNumericsKitClass;
  ProbabilityKit: TProbabilityKitClass;
  CombinatoricsKit: TCombinatoricsKitClass;
  OptimizationKit: TOptimizationKitClass;
  TimeSeriesKit: TTimeSeriesKitClass;
  MLKit: TMLKitClass;
  GeometryKit: TGeometryKitClass;
begin
  TrigKit := TTrigKit;
  MatrixKit := TMatrixKit;
  VectorKit := TVectorKit;
  ComplexValue := CAsin(TComplex.Create(0.5, 0.0));
  FinanceKit := TFinanceKit;
  BondKit := TBondKit;
  NPVKit := TNPVKit;
  StatsKit := TStatsKit;
  FluidDynamicsKit := TFluidDynamicsKit;
  ThermodynamicsKit := TThermodynamicsKit;
  SignalKit := TSignalKit;
  UnitConversionKit := TUnitConversionKit;
  VelocityKit := TVelocityKit;
  PressureKit := TPressureKit;
  NumericsKit := TNumericsKit;
  ProbabilityKit := TProbabilityKit;
  CombinatoricsKit := TCombinatoricsKit;
  OptimizationKit := TOptimizationKit;
  TimeSeriesKit := TTimeSeriesKit;
  MLKit := TMLKit;
  GeometryKit := TGeometryKit;

  AssertTrue('TTrigKit', TrigKit <> nil);
  AssertTrue('TMatrixKit', MatrixKit <> nil);
  AssertTrue('TVectorKit', VectorKit <> nil);
  AssertEquals('TComplex public API', Pi / 6.0, ComplexValue.Re, 1E-15);
  AssertTrue('TFinanceKit', FinanceKit <> nil);
  AssertTrue('TBondKit', BondKit <> nil);
  AssertTrue('TNPVKit', NPVKit <> nil);
  AssertTrue('TStatsKit', StatsKit <> nil);
  AssertTrue('TFluidDynamicsKit', FluidDynamicsKit <> nil);
  AssertTrue('TThermodynamicsKit', ThermodynamicsKit <> nil);
  AssertTrue('TSignalKit', SignalKit <> nil);
  AssertTrue('TUnitConversionKit', UnitConversionKit <> nil);
  AssertTrue('TVelocityKit', VelocityKit <> nil);
  AssertTrue('TPressureKit', PressureKit <> nil);
  AssertTrue('TNumericsKit', NumericsKit <> nil);
  AssertTrue('TProbabilityKit', ProbabilityKit <> nil);
  AssertTrue('TCombinatoricsKit', CombinatoricsKit <> nil);
  AssertTrue('TOptimizationKit', OptimizationKit <> nil);
  AssertTrue('TTimeSeriesKit', TimeSeriesKit <> nil);
  AssertTrue('TMLKit', MLKit <> nil);
  AssertTrue('TGeometryKit', GeometryKit <> nil);
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

initialization
  RegisterTest(TTestPublicAPI);

end.
