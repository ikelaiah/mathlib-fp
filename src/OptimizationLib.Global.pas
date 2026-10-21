unit OptimizationLib.Global;

{ Bounded DE/rand/1/bin with deferred updates and optional coordinate polish.
  Storn and Price (1997), DOI 10.1023/A:1008202821328. Native implementation
  from the algorithm description; no external numerical runtime. }

{$mode objfpc}{$H+}{$J-}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, Math, MathBase.SharedTypes, MathBase.Random,
  OptimizationLib.Optimization;

type
  TGlobalSearchStatus = (gssPopulationTolerance, gssEvaluationLimit,
    gssGenerationLimit, gssFixedBounds, gssNoFiniteValue);
  TGlobalPolishStatus = (gpsNotRun, gpsStepTolerance, gpsEvaluationLimit);

  TGlobalOptimizationOptions = record
    PopulationSize: Integer;
    MaxGenerations: Integer;
    MaxEvaluations: Integer;
    DifferentialWeight: Double;
    CrossoverProbability: Double;
    PositionTolerance: Double;
    AbsoluteTolerance: Double;
    RelativeTolerance: Double;
    Seed: QWord;
    MaxPolishEvaluations: Integer;
    InitialPolishStep: Double;
    class function Defaults: TGlobalOptimizationOptions; static;
  end;

  { X and GlobalX own independent arrays. Copying this record follows normal
    Pascal dynamic-array aliasing. Status describes only the global phase;
    neither tolerance status certifies global optimality. FinalRandomState
    replays the random stream, not a population checkpoint. }
  TGlobalOptimizationResult = record
    X: TDoubleArray;
    FVal: Double;
    HasFiniteValue: Boolean;
    GlobalX: TDoubleArray;
    GlobalFVal: Double;
    GlobalEvaluations: Integer;
    PolishEvaluations: Integer;
    Evaluations: Integer;
    Generations: Integer;
    Status: TGlobalSearchStatus;
    PolishStatus: TGlobalPolishStatus;
    FinalRandomState: TRandomState;
  end;

  TGlobalOptimizationKit = class
  public
    { All bounds must be finite, nonempty, matching and ordered. Fixed
      coordinates are permitted. NaN/infinite callback values are rejected
      and counted; callback exceptions propagate. Budgets are strict call
      counts, with a separate optional polish budget. Inputs are not mutated
      or retained; each callback receives an isolated physical-coordinate
      array. A deterministic callback is required for reproducibility. }
    class function DifferentialEvolution(F: TMultivarFunc;
      const Lower, Upper: TDoubleArray): TGlobalOptimizationResult; static; overload;
    class function DifferentialEvolution(F: TMultivarFunc;
      const Lower, Upper: TDoubleArray;
      const Options: TGlobalOptimizationOptions): TGlobalOptimizationResult;
      static; overload;
    class function DifferentialEvolution(F: TMultivarFunc;
      const Lower, Upper: TDoubleArray;
      const Options: TGlobalOptimizationOptions;
      var Random: TLocalRandom): TGlobalOptimizationResult; static; overload;
  end;

implementation

type
  TPopulation = array of TDoubleArray;

function Finite(const Value: Double): Boolean; inline;
begin
  Result := not (IsNan(Value) or IsInfinite(Value));
end;

procedure Require(Condition: Boolean; const MessageText: String);
begin
  if not Condition then
    raise EOptimizationError.Create('DifferentialEvolution: ' + MessageText);
end;

procedure Validate(F: TMultivarFunc; const Lower, Upper: TDoubleArray;
  const O: TGlobalOptimizationOptions);
var J: Integer;
begin
  Require(Assigned(F), 'objective must be assigned');
  Require((Length(Lower) > 0) and (Length(Lower) = Length(Upper)),
    'bounds must have matching nonzero lengths');
  for J := 0 to High(Lower) do
    Require(Finite(Lower[J]) and Finite(Upper[J]) and (Lower[J] <= Upper[J]),
      'bounds must be finite and ordered');
  Require(O.PopulationSize >= 4, 'population must be at least four');
  Require((O.MaxEvaluations >= 1) and (O.MaxGenerations >= 0) and
    (O.MaxPolishEvaluations >= 0), 'invalid resource budget');
  Require(Int64(O.MaxEvaluations) + O.MaxPolishEvaluations <= High(Integer),
    'combined evaluation budgets exceed Integer range');
  Require(Finite(O.DifferentialWeight) and (O.DifferentialWeight > 0) and
    (O.DifferentialWeight <= 2), 'weight must be in (0,2]');
  Require(Finite(O.CrossoverProbability) and (O.CrossoverProbability >= 0) and
    (O.CrossoverProbability <= 1), 'crossover must be in [0,1]');
  Require(Finite(O.PositionTolerance) and (O.PositionTolerance > 0) and
    (O.PositionTolerance <= 1), 'position tolerance must be in (0,1]');
  Require(Finite(O.AbsoluteTolerance) and (O.AbsoluteTolerance >= 0) and
    Finite(O.RelativeTolerance) and (O.RelativeTolerance >= 0),
    'objective tolerances must be finite and nonnegative');
  Require(Finite(O.InitialPolishStep) and (O.InitialPolishStep > 0) and
    (O.InitialPolishStep <= 1), 'polish step must be in (0,1]');
end;

class function TGlobalOptimizationOptions.Defaults: TGlobalOptimizationOptions;
begin
  Result.PopulationSize := 32;
  Result.MaxGenerations := 1000;
  Result.MaxEvaluations := 20000;
  Result.DifferentialWeight := 0.8;
  Result.CrossoverProbability := 0.9;
  Result.PositionTolerance := 1e-8;
  Result.AbsoluteTolerance := 1e-10;
  Result.RelativeTolerance := 1e-8;
  Result.Seed := 1729;
  Result.MaxPolishEvaluations := 0;
  Result.InitialPolishStep := 0.1;
end;

function ClampUnit(Value: Double): Double; inline;
begin
  if Value < 0 then Result := 0
  else if Value > 1 then Result := 1
  else Result := Value;
end;

function PhysicalCoordinate(Lower, Upper, U: Double): Double;
begin
  { Same-sign endpoints have a representable difference. Opposite-sign
    endpoints use a convex combination to avoid overflowing Upper-Lower. }
  if (Lower < 0) and (Upper > 0) then
    Result := (1 - U) * Lower + U * Upper
  else
    Result := Lower + U * (Upper - Lower);
  Result := Max(Lower, Min(Upper, Result));
end;

function PopulationSmall(const P: TPopulation; const Values: TDoubleArray;
  const O: TGlobalOptimizationOptions): Boolean;
var I, J: Integer; Lo, Hi, FLo, FHi, Scale, Spread: Double;
begin
  Result := False;
  FLo := Values[0];
  FHi := Values[0];
  for I := 0 to High(Values) do
  begin
    if not Finite(Values[I]) then Exit;
    FLo := Min(FLo, Values[I]);
    FHi := Max(FHi, Values[I]);
  end;
  Scale := Max(1, Max(Abs(FLo), Abs(FHi)));
  Spread := FHi / Scale - FLo / Scale;
  if (Spread > O.RelativeTolerance) and
    (Spread - O.RelativeTolerance > O.AbsoluteTolerance / Scale) then Exit;
  for J := 0 to High(P[0]) do
  begin
    Lo := P[0][J];
    Hi := Lo;
    for I := 1 to High(P) do
    begin
      Lo := Min(Lo, P[I][J]);
      Hi := Max(Hi, P[I][J]);
    end;
    if Hi - Lo > O.PositionTolerance then Exit;
  end;
  Result := True;
end;

class function TGlobalOptimizationKit.DifferentialEvolution(F: TMultivarFunc;
  const Lower, Upper: TDoubleArray): TGlobalOptimizationResult;
begin
  Result := DifferentialEvolution(F, Lower, Upper,
    TGlobalOptimizationOptions.Defaults);
end;

class function TGlobalOptimizationKit.DifferentialEvolution(F: TMultivarFunc;
  const Lower, Upper: TDoubleArray;
  const Options: TGlobalOptimizationOptions): TGlobalOptimizationResult;
var Random: TLocalRandom;
begin
  Random := TLocalRandom.Seeded(Options.Seed);
  Result := DifferentialEvolution(F, Lower, Upper, Options, Random);
end;

class function TGlobalOptimizationKit.DifferentialEvolution(F: TMultivarFunc;
  const Lower, Upper: TDoubleArray; const Options: TGlobalOptimizationOptions;
  var Random: TLocalRandom): TGlobalOptimizationResult;
var
  Population, NextPopulation: TPopulation;
  Values, NextValues, Trial, BestU, Physical, CallbackX: TDoubleArray;
  FreeCoordinates, Donors: array of Integer;
  N, NP, I, J, K, A, B, C, Forced, Pick, SwapIndex, FreeCount: Integer;
  Value, Step, PreviousBest: Double;
  Complete, Improved: Boolean;

  function Evaluate(const U: TDoubleArray): Double;
  var Coordinate: Integer;
  begin
    SetLength(Physical, N);
    for Coordinate := 0 to N - 1 do
      Physical[Coordinate] := PhysicalCoordinate(Lower[Coordinate],
        Upper[Coordinate], U[Coordinate]);
    CallbackX := Copy(Physical);
    Result := F(CallbackX);
  end;

  procedure Observe(const U: TDoubleArray; Objective: Double);
  begin
    if Finite(Objective) and
      ((not Result.HasFiniteValue) or (Objective < Result.FVal)) then
    begin
      Result.HasFiniteValue := True;
      Result.FVal := Objective;
      Result.X := Copy(Physical);
      BestU := Copy(U);
    end;
  end;

begin
  Validate(F, Lower, Upper, Options);
  Result := Default(TGlobalOptimizationResult);
  Result.FVal := Infinity;
  Result.GlobalFVal := Infinity;
  Result.Status := gssEvaluationLimit;
  Result.PolishStatus := gpsNotRun;
  N := Length(Lower);
  NP := Options.PopulationSize;
  SetLength(FreeCoordinates, N);
  FreeCount := 0;
  for J := 0 to N - 1 do
    if Lower[J] < Upper[J] then
    begin
      FreeCoordinates[FreeCount] := J;
      Inc(FreeCount);
    end;
  SetLength(Trial, N);
  if FreeCount = 0 then
  begin
    Value := Evaluate(Trial);
    Inc(Result.GlobalEvaluations);
    Observe(Trial, Value);
    Result.Status := gssFixedBounds;
  end
  else
  begin
    SetLength(Population, NP);
    SetLength(Values, NP);
    SetLength(Donors, NP - 1);
    I := 0;
    while (I < NP) and (Result.GlobalEvaluations < Options.MaxEvaluations) do
    begin
      SetLength(Population[I], N);
      for K := 0 to FreeCount - 1 do
        Population[I][FreeCoordinates[K]] := Random.NextDouble;
      Value := Evaluate(Population[I]);
      Inc(Result.GlobalEvaluations);
      if not Finite(Value) then Value := Infinity;
      Values[I] := Value;
      Observe(Population[I], Value);
      Inc(I);
    end;
    Complete := I = NP;
    while Complete do
    begin
      if PopulationSmall(Population, Values, Options) then
      begin
        Result.Status := gssPopulationTolerance;
        Break;
      end;
      if Result.GlobalEvaluations >= Options.MaxEvaluations then Break;
      if Result.Generations >= Options.MaxGenerations then
      begin
        Result.Status := gssGenerationLimit;
        Break;
      end;
      SetLength(NextPopulation, NP);
      NextValues := Copy(Values);
      for I := 0 to NP - 1 do NextPopulation[I] := Copy(Population[I]);
      I := 0;
      while (I < NP) and (Result.GlobalEvaluations < Options.MaxEvaluations) do
      begin
        K := 0;
        for J := 0 to NP - 1 do
          if J <> I then
          begin
            Donors[K] := J;
            Inc(K);
          end;
        { Partial Fisher-Yates: exactly three draws, no rejection loop. }
        for K := 0 to 2 do
        begin
          Pick := K + Integer(Random.NextInteger(NP - 1 - K));
          SwapIndex := Donors[K];
          Donors[K] := Donors[Pick];
          Donors[Pick] := SwapIndex;
        end;
        A := Donors[0]; B := Donors[1]; C := Donors[2];
        Forced := FreeCoordinates[Random.NextInteger(FreeCount)];
        Trial := Copy(Population[I]);
        for K := 0 to FreeCount - 1 do
        begin
          J := FreeCoordinates[K];
          if (Random.NextDouble < Options.CrossoverProbability) or (J = Forced) then
            Trial[J] := ClampUnit(Population[A][J] + Options.DifferentialWeight *
              (Population[B][J] - Population[C][J]));
        end;
        Value := Evaluate(Trial);
        Inc(Result.GlobalEvaluations);
        if not Finite(Value) then Value := Infinity;
        Observe(Trial, Value);
        if Value <= Values[I] then
        begin
          NextPopulation[I] := Copy(Trial);
          NextValues[I] := Value;
        end;
        Inc(I);
      end;
      Complete := I = NP;
      Population := NextPopulation;
      Values := NextValues;
      if Complete then Inc(Result.Generations);
    end;
  end;
  if not Result.HasFiniteValue then Result.Status := gssNoFiniteValue;
  Result.GlobalX := Copy(Result.X);
  Result.GlobalFVal := Result.FVal;
  if Result.HasFiniteValue and (FreeCount > 0) and
    (Options.MaxPolishEvaluations > 0) then
  begin
    Step := Options.InitialPolishStep;
    Result.PolishStatus := gpsEvaluationLimit;
    while True do
    begin
      if Step <= Options.PositionTolerance then
      begin
        Result.PolishStatus := gpsStepTolerance;
        Break;
      end;
      if Result.PolishEvaluations >= Options.MaxPolishEvaluations then Break;
      Improved := False;
      for K := 0 to FreeCount - 1 do
      begin
        J := FreeCoordinates[K];
        for Pick := 0 to 1 do
        begin
          if Result.PolishEvaluations >= Options.MaxPolishEvaluations then Break;
          Trial := Copy(BestU);
          if Pick = 0 then Trial[J] := ClampUnit(Trial[J] + Step)
          else Trial[J] := ClampUnit(Trial[J] - Step);
          if Trial[J] = BestU[J] then Continue;
          PreviousBest := Result.FVal;
          Value := Evaluate(Trial);
          Inc(Result.PolishEvaluations);
          Observe(Trial, Value);
          if Result.FVal < PreviousBest then Improved := True;
        end;
      end;
      if not Improved then Step := Step * 0.5;
    end;
  end;
  Result.FinalRandomState := Random.GetState;
  Result.Evaluations := Result.GlobalEvaluations + Result.PolishEvaluations;
end;

end.
