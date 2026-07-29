program convex_optimization;

{$mode objfpc}{$H+}

uses
  SysUtils, MathBase.SharedTypes, MathBase.Iteration,
  OptimizationLib.Convex;

var
  Model:TQuadraticProgram;
  Options:TConvexOptions;
  Result:TConvexResult;
  Cones:TSecondOrderCones;
begin
  { Closest point to (2,-1), subject to x+y <= 2. }
  SetLength(Model.Q,2);
  Model.Q[0]:=TDoubleArray.Create(2,0);
  Model.Q[1]:=TDoubleArray.Create(0,2);
  Model.C:=TDoubleArray.Create(-4,2);
  SetLength(Model.InequalityA,1);
  Model.InequalityA[0]:=TDoubleArray.Create(1,1);
  Model.InequalityB:=TDoubleArray.Create(2);
  Model.LowerBounds:=TDoubleArray.Create(-10,-10);
  Model.UpperBounds:=TDoubleArray.Create(10,10);
  Options:=TConvexOptions.Defaults;
  Result:=TConvexOptimizationKit.SolveQuadraticProgram(Model,Options);
  WriteLn('QP ',IterationStatusName(Result.Status),
    ': x=',Result.X[0]:0:6,', y=',Result.X[1]:0:6,
    ', feasibility=',Result.Feasibility:0:3);

  { Minimise -x subject to |x| <= 1, written as a second-order cone. }
  SetLength(Cones,1);
  SetLength(Cones[0].A,1);
  Cones[0].A[0]:=TDoubleArray.Create(1);
  Cones[0].B:=TDoubleArray.Create(0);
  Cones[0].D:=TDoubleArray.Create(0);
  Cones[0].E:=1;
  Options:=TConvexOptions.Defaults;
  Options.InitialX:=TDoubleArray.Create(0); { strictly feasible start }
  Result:=TConvexOptimizationKit.SolveSecondOrderConeProgram(
    TDoubleArray.Create(-1),Cones,Options);
  WriteLn('SOCP ',IterationStatusName(Result.Status),
    ': x=',Result.X[0]:0:6,
    ', feasibility=',Result.Feasibility:0:3);
end.
