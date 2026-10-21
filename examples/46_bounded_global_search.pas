program BoundedGlobalSearch;

{$mode objfpc}{$H+}{$J-}

uses
  SysUtils, Math, MathBase.SharedTypes, OptimizationLib.Global;

function Rastrigin(const X: TDoubleArray): Double;
var J: Integer;
begin
  Result := 10 * Length(X);
  for J := 0 to High(X) do
    Result := Result + Sqr(X[J]) - 10 * Cos(2 * Pi * X[J]);
end;

function GlobalStatus(S: TGlobalSearchStatus): String;
begin
  case S of
    gssPopulationTolerance: Result := 'population tolerance';
    gssEvaluationLimit: Result := 'evaluation limit';
    gssGenerationLimit: Result := 'generation limit';
    gssFixedBounds: Result := 'fixed bounds';
    gssNoFiniteValue: Result := 'no finite value';
  end;
end;

var
  Options: TGlobalOptimizationOptions;
  Search, Replay: TGlobalOptimizationResult;
begin
  Options := TGlobalOptimizationOptions.Defaults;
  Options.MaxPolishEvaluations := 200;
  Search := TGlobalOptimizationKit.DifferentialEvolution(@Rastrigin,
    [-5.12, -5.12], [5.12, 5.12], Options);
  Replay := TGlobalOptimizationKit.DifferentialEvolution(@Rastrigin,
    [-5.12, -5.12], [5.12, 5.12], Options);
  if not Search.HasFiniteValue then raise Exception.Create('No finite point');
  if Search.FVal > 1e-7 then raise Exception.Create('Known minimum not recovered');
  if (Search.FVal <> Replay.FVal) or (Search.X[0] <> Replay.X[0]) or
    (Search.X[1] <> Replay.X[1]) then raise Exception.Create('Replay differs');
  if (Search.GlobalEvaluations > Options.MaxEvaluations) or
    (Search.PolishEvaluations > Options.MaxPolishEvaluations) or
    (Search.Evaluations <> Search.GlobalEvaluations + Search.PolishEvaluations) then
    raise Exception.Create('Evaluation budget exceeded');
  if Search.FVal > Search.GlobalFVal then raise Exception.Create('Polish worsened result');
  WriteLn('Rastrigin: best objective = ', Abs(Search.FVal):0:8);
  WriteLn('global stop: ', GlobalStatus(Search.Status));
  WriteLn('evaluations: global=', Search.GlobalEvaluations,
    ', polish=', Search.PolishEvaluations, ', total=', Search.Evaluations);
  WriteLn('replay: identical on this profile');
  WriteLn('A heuristic result is not a global-optimality certificate.');
  WriteLn('bounded global search: success');
end.
