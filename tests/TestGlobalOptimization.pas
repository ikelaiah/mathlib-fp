unit TestGlobalOptimization;

{$mode objfpc}{$H+}{$J-}

interface

uses
  SysUtils, Math, fpcunit, testregistry, MathBase.SharedTypes,
  MathBase.Random, OptimizationLib.Optimization, OptimizationLib.Global;

type
  TTestGlobalOptimization = class(TTestCase)
  published
    procedure FindsKnownMultimodalMinimum;
    procedure ReplaysSeedWithoutTouchingGlobalRandom;
    procedure UsesExplicitRandomState;
    procedure HonorsPartialInitializationAndGenerationBudgets;
    procedure ReportsGenerationAndPopulationStops;
    procedure HandlesFixedAndExtremeBounds;
    procedure RejectsNonfiniteValues;
    procedure ValidatesBeforeCallingOrAdvancingRandom;
    procedure ProtectsInputsAndBestFromCallbackMutation;
    procedure PropagatesCallbackExceptions;
    procedure PolishImprovesWithoutExceedingSeparateBudget;
    procedure PolishReportsStepToleranceAndSkipsImpossibleSearch;
    procedure ValidatesAllOptionsAndBounds;
    procedure RecoversFromNonfinitePopulation;
    procedure ChecksIndependentProblemMinima;
  end;

implementation

var
  Calls: Integer;
  SeenLower, SeenUpper: TDoubleArray;

function Bowl(const X: TDoubleArray): Double;
var I: Integer;
begin
  Inc(Calls);
  Result := 0;
  for I := 0 to High(X) do
  begin
    if (Length(SeenLower) > I) and
      ((X[I] < SeenLower[I]) or (X[I] > SeenUpper[I])) then
      raise Exception.Create('Callback outside bounds');
    Result := Result + Sqr(X[I] - 0.25);
  end;
end;

function Rastrigin(const X: TDoubleArray): Double;
var I: Integer;
begin
  Result := 10 * Length(X);
  for I := 0 to High(X) do
    Result := Result + Sqr(X[I]) - 10 * Cos(2 * Pi * X[I]);
end;

function ConstantObjective(const X: TDoubleArray): Double;
begin
  Inc(Calls);
  Result := 7;
end;

function NonfiniteObjective(const X: TDoubleArray): Double;
begin
  Inc(Calls);
  if Calls mod 2 = 0 then Result := NaN else Result := Infinity;
end;

function MutatingObjective(const X: TDoubleArray): Double;
begin
  Result := Sqr(X[0] - 0.25);
  X[0] := 1e100;
end;

function RaisingObjective(const X: TDoubleArray): Double;
begin
  raise EAbort.Create('objective failure');
  Result := 0;
end;

function BoundaryObjective(const X: TDoubleArray): Double;
begin
  Inc(Calls);
  if (X[0] < -1) or (X[0] > 1) then raise Exception.Create('outside box');
  Result := -X[0];
end;

function InitiallyNonfinite(const X: TDoubleArray): Double;
begin
  Inc(Calls);
  if Calls <= 8 then Result := Infinity else Result := Sqr(X[0]);
end;

function RosenbrockObjective(const X: TDoubleArray): Double;
begin
  Result := 100 * Sqr(X[1]-Sqr(X[0])) + Sqr(1-X[0]);
end;

function AckleyObjective(const X: TDoubleArray): Double;
begin
  Result := -20 * Exp(-0.2 * Sqrt((Sqr(X[0])+Sqr(X[1]))/2)) -
    Exp((Cos(2*Pi*X[0])+Cos(2*Pi*X[1]))/2) + 20 + Exp(1);
end;

procedure TTestGlobalOptimization.FindsKnownMultimodalMinimum;
var O: TGlobalOptimizationOptions; R: TGlobalOptimizationResult;
begin
  O := TGlobalOptimizationOptions.Defaults;
  O.MaxEvaluations := 20000;
  R := TGlobalOptimizationKit.DifferentialEvolution(@Rastrigin,
    [-5.12, -5.12], [5.12, 5.12], O);
  AssertTrue(R.HasFiniteValue);
  AssertEquals(0, R.FVal, 1e-7);
  AssertEquals(0, R.X[0], 1e-3);
  AssertEquals(0, R.X[1], 1e-3);
end;

procedure TTestGlobalOptimization.ReplaysSeedWithoutTouchingGlobalRandom;
var O: TGlobalOptimizationOptions; A, B: TGlobalOptimizationResult;
  SavedSeed: LongWord;
begin
  SeenLower := nil;
  O := TGlobalOptimizationOptions.Defaults;
  O.MaxEvaluations := 101;
  SavedSeed := RandSeed;
  A := TGlobalOptimizationKit.DifferentialEvolution(@Bowl, [-2,-2], [2,2], O);
  AssertEquals(SavedSeed, RandSeed);
  B := TGlobalOptimizationKit.DifferentialEvolution(@Bowl, [-2,-2], [2,2], O);
  AssertEquals(A.FVal, B.FVal, 0);
  AssertEquals(A.X[0], B.X[0], 0);
  AssertTrue(CompareByte(A.FinalRandomState, B.FinalRandomState,
    SizeOf(TRandomState)) = 0);
  A.X[0] := 999;
  AssertTrue(A.GlobalX[0] <> 999);
end;

procedure TTestGlobalOptimization.UsesExplicitRandomState;
var O: TGlobalOptimizationOptions; A, B: TGlobalOptimizationResult;
  RA, RB: TLocalRandom; S: TRandomState;
begin
  SeenLower := nil;
  O := TGlobalOptimizationOptions.Defaults;
  O.MaxEvaluations := 80;
  RA := TLocalRandom.Seeded(42);
  RB := RA;
  A := TGlobalOptimizationKit.DifferentialEvolution(@Bowl, [-1], [1], O, RA);
  B := TGlobalOptimizationKit.DifferentialEvolution(@Bowl, [-1], [1], O, RB);
  S := RA.GetState;
  AssertEquals(A.FVal, B.FVal, 0);
  AssertTrue(CompareByte(S, A.FinalRandomState, SizeOf(S)) = 0);
end;

procedure TTestGlobalOptimization.HonorsPartialInitializationAndGenerationBudgets;
var O: TGlobalOptimizationOptions; R: TGlobalOptimizationResult; Budget: Integer;
begin
  SeenLower := nil;
  O := TGlobalOptimizationOptions.Defaults;
  O.PopulationSize := 8;
  for Budget := 1 to 25 do
  begin
    Calls := 0;
    O.MaxEvaluations := Budget;
    R := TGlobalOptimizationKit.DifferentialEvolution(@Bowl, [-2], [2], O);
    AssertEquals(Budget, Calls);
    AssertEquals(Calls, R.GlobalEvaluations);
    AssertEquals(Calls, R.Evaluations);
    AssertEquals(Max(0, Budget div 8 - 1), R.Generations);
    AssertEquals(Ord(gssEvaluationLimit), Ord(R.Status));
  end;
end;

procedure TTestGlobalOptimization.ReportsGenerationAndPopulationStops;
var O: TGlobalOptimizationOptions; R: TGlobalOptimizationResult;
begin
  O := TGlobalOptimizationOptions.Defaults;
  O.MaxGenerations := 0;
  R := TGlobalOptimizationKit.DifferentialEvolution(@ConstantObjective, [-1], [1], O);
  AssertEquals(Ord(gssGenerationLimit), Ord(R.Status));
  AssertEquals(32, R.Evaluations);
  O.PositionTolerance := 1;
  R := TGlobalOptimizationKit.DifferentialEvolution(@ConstantObjective, [-1], [1], O);
  AssertEquals(Ord(gssPopulationTolerance), Ord(R.Status));
end;

procedure TTestGlobalOptimization.HandlesFixedAndExtremeBounds;
var O: TGlobalOptimizationOptions; R: TGlobalOptimizationResult;
begin
  O := TGlobalOptimizationOptions.Defaults;
  SeenLower := nil;
  R := TGlobalOptimizationKit.DifferentialEvolution(@Bowl, [0.25,0.25], [0.25,0.25], O);
  AssertEquals(1, R.Evaluations);
  AssertEquals(0, R.FVal, 0);
  AssertEquals(Ord(gssFixedBounds), Ord(R.Status));
  SeenLower := TDoubleArray.Create(-1.7e308, 2, 1e300);
  SeenUpper := TDoubleArray.Create(1.7e308, 2, 1.000000000000001e300);
  O.MaxEvaluations := 70;
  R := TGlobalOptimizationKit.DifferentialEvolution(@ConstantObjective,
    SeenLower, SeenUpper, O);
  AssertTrue(not IsInfinite(R.X[0]));
  AssertEquals(2, R.X[1], 0);
  AssertTrue(R.X[2] >= SeenLower[2]);
  AssertTrue(R.X[2] <= SeenUpper[2]);
  SeenLower := nil;
  SeenUpper := nil;
end;

procedure TTestGlobalOptimization.RejectsNonfiniteValues;
var O: TGlobalOptimizationOptions; R: TGlobalOptimizationResult;
begin
  O := TGlobalOptimizationOptions.Defaults;
  O.MaxEvaluations := 71;
  Calls := 0;
  R := TGlobalOptimizationKit.DifferentialEvolution(@NonfiniteObjective, [-1], [1], O);
  AssertEquals(71, Calls);
  AssertFalse(R.HasFiniteValue);
  AssertEquals(0, Length(R.X));
  AssertTrue(IsInfinite(R.FVal));
  AssertEquals(Ord(gssNoFiniteValue), Ord(R.Status));
end;

procedure TTestGlobalOptimization.ValidatesBeforeCallingOrAdvancingRandom;
var O: TGlobalOptimizationOptions; R: TGlobalOptimizationResult;
  RNG: TLocalRandom; Before, After: TRandomState;
begin
  O := TGlobalOptimizationOptions.Defaults;
  O.PopulationSize := 3;
  RNG := TLocalRandom.Seeded(10);
  Before := RNG.GetState;
  Calls := 0;
  try
    R := TGlobalOptimizationKit.DifferentialEvolution(@Bowl, [-1], [1], O, RNG);
    Fail('Expected EOptimizationError');
  except on E: EOptimizationError do ; end;
  After := RNG.GetState;
  AssertEquals(0, Calls);
  AssertTrue(CompareByte(Before, After, SizeOf(Before)) = 0);
end;

procedure TTestGlobalOptimization.ProtectsInputsAndBestFromCallbackMutation;
var O: TGlobalOptimizationOptions; R: TGlobalOptimizationResult;
  L, U: TDoubleArray;
begin
  O := TGlobalOptimizationOptions.Defaults;
  L := TDoubleArray.Create(-1);
  U := TDoubleArray.Create(1);
  R := TGlobalOptimizationKit.DifferentialEvolution(@MutatingObjective, L, U, O);
  AssertEquals(-1, L[0], 0);
  AssertEquals(1, U[0], 0);
  AssertTrue(Abs(R.X[0]) <= 1);
  AssertEquals(Sqr(R.X[0]-0.25), R.FVal, 1e-20);
end;

procedure TTestGlobalOptimization.PropagatesCallbackExceptions;
begin
  try
    TGlobalOptimizationKit.DifferentialEvolution(@RaisingObjective, [-1], [1]);
    Fail('Expected callback exception');
  except on E: EAbort do AssertEquals('objective failure', E.Message); end;
end;

procedure TTestGlobalOptimization.PolishImprovesWithoutExceedingSeparateBudget;
var O: TGlobalOptimizationOptions; A, R: TGlobalOptimizationResult;
begin
  SeenLower := nil;
  O := TGlobalOptimizationOptions.Defaults;
  O.MaxEvaluations := 1;
  A := TGlobalOptimizationKit.DifferentialEvolution(@Bowl, [-1], [1], O);
  O.MaxPolishEvaluations := 150;
  Calls := 0;
  R := TGlobalOptimizationKit.DifferentialEvolution(@Bowl, [-1], [1], O);
  AssertEquals(1, R.GlobalEvaluations);
  AssertTrue(R.PolishEvaluations <= 150);
  AssertEquals(Calls, R.Evaluations);
  AssertEquals(R.GlobalEvaluations + R.PolishEvaluations, R.Evaluations);
  AssertEquals(A.FVal, R.GlobalFVal, 0);
  AssertTrue(R.FVal < R.GlobalFVal);
  AssertEquals(0.25, R.X[0], 1e-7);
  AssertEquals(Ord(gpsStepTolerance), Ord(R.PolishStatus));
  O.MaxPolishEvaluations := 1;
  R := TGlobalOptimizationKit.DifferentialEvolution(@BoundaryObjective, [-1], [1], O);
  AssertEquals(1, R.PolishEvaluations);
  AssertEquals(Ord(gpsEvaluationLimit), Ord(R.PolishStatus));
  AssertTrue(R.FVal <= R.GlobalFVal);
end;

procedure TTestGlobalOptimization.PolishReportsStepToleranceAndSkipsImpossibleSearch;
var O: TGlobalOptimizationOptions; R: TGlobalOptimizationResult;
begin
  O := TGlobalOptimizationOptions.Defaults;
  O.MaxEvaluations := 1;
  O.MaxPolishEvaluations := 100;
  O.PositionTolerance := O.InitialPolishStep;
  R := TGlobalOptimizationKit.DifferentialEvolution(@Bowl, [-1], [1], O);
  AssertEquals(0, R.PolishEvaluations);
  AssertEquals(Ord(gpsStepTolerance), Ord(R.PolishStatus));
  R := TGlobalOptimizationKit.DifferentialEvolution(@Bowl, [0.25], [0.25], O);
  AssertEquals(0, R.PolishEvaluations);
  AssertEquals(Ord(gpsNotRun), Ord(R.PolishStatus));
  R := TGlobalOptimizationKit.DifferentialEvolution(@NonfiniteObjective, [-1], [1], O);
  AssertEquals(0, R.PolishEvaluations);
  AssertEquals(Ord(gpsNotRun), Ord(R.PolishStatus));
end;

procedure TTestGlobalOptimization.ValidatesAllOptionsAndBounds;
var O: TGlobalOptimizationOptions; L, U: TDoubleArray;
  F: TMultivarFunc; R: TGlobalOptimizationResult; CaseIndex: Integer;
begin
  for CaseIndex := 0 to 19 do
  begin
    O := TGlobalOptimizationOptions.Defaults;
    L := TDoubleArray.Create(-1); U := TDoubleArray.Create(1); F := @Bowl;
    case CaseIndex of
      0: F := nil;
      1: L := nil;
      2: U := nil;
      3: L[0] := 2;
      4: L[0] := NaN;
      5: U[0] := Infinity;
      6: O.MaxEvaluations := 0;
      7: O.MaxGenerations := -1;
      8: O.MaxPolishEvaluations := -1;
      9: O.DifferentialWeight := 0;
      10: O.DifferentialWeight := 2.1;
      11: O.CrossoverProbability := -0.1;
      12: O.CrossoverProbability := 1.1;
      13: O.PositionTolerance := 0;
      14: O.PositionTolerance := 1.1;
      15: O.AbsoluteTolerance := -1;
      16: O.RelativeTolerance := NaN;
      17: O.InitialPolishStep := 0;
      18: O.InitialPolishStep := Infinity;
      19: begin O.MaxEvaluations := High(Integer); O.MaxPolishEvaluations := 1; end;
    end;
    Calls := 0;
    try
      R := TGlobalOptimizationKit.DifferentialEvolution(F, L, U, O);
      Fail('Invalid case '+IntToStr(CaseIndex));
    except on E: EOptimizationError do ; end;
    AssertEquals(0, Calls);
  end;
end;

procedure TTestGlobalOptimization.RecoversFromNonfinitePopulation;
var O: TGlobalOptimizationOptions; R: TGlobalOptimizationResult;
begin
  O := TGlobalOptimizationOptions.Defaults;
  O.PopulationSize := 8;
  O.MaxEvaluations := 32;
  Calls := 0;
  R := TGlobalOptimizationKit.DifferentialEvolution(@InitiallyNonfinite, [-1], [1], O);
  AssertTrue(R.HasFiniteValue);
  AssertEquals(32, Calls);
end;

procedure TTestGlobalOptimization.ChecksIndependentProblemMinima;
var O: TGlobalOptimizationOptions; R: TGlobalOptimizationResult;
begin
  SeenLower := nil;
  O := TGlobalOptimizationOptions.Defaults;
  R := TGlobalOptimizationKit.DifferentialEvolution(@RosenbrockObjective,
    [-2,-1], [2,3], O);
  AssertEquals(0, R.FVal, 1e-8);
  AssertEquals(1, R.X[0], 1e-3);
  AssertEquals(1, R.X[1], 1e-3);
  R := TGlobalOptimizationKit.DifferentialEvolution(@AckleyObjective,
    [-5,-5], [5,5], O);
  AssertEquals(0, R.FVal, 1e-6);
  O.MaxPolishEvaluations := 200;
  O.MaxEvaluations := 1;
  R := TGlobalOptimizationKit.DifferentialEvolution(@BoundaryObjective, [-1], [1], O);
  AssertEquals(-1, R.FVal, 0);
  AssertEquals(1, R.X[0], 0);
end;

initialization
  RegisterTest(TTestGlobalOptimization);
end.
