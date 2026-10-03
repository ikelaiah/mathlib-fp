program stiff_ode_sdirk;

{$mode objfpc}{$H+}{$J-}

uses
  Math, SysUtils,
  MathBase.Iteration,
  MathBase.SharedTypes,
  NumericsLib.Modelling;

function ForcedStiffODE(T:Double; const Y:TDoubleArray):TDoubleArray;
begin
  Result:=TDoubleArray.Create(-1000*(Y[0]-Cos(T))-Sin(T));
end;

function ForcedStiffJacobian(T:Double;
  const Y:TDoubleArray):TModelMatrix;
begin
  Result:=nil;
  SetLength(Result,1);
  Result[0]:=TDoubleArray.Create(-1000);
end;

function FallingHalfState(T:Double; const Y:TDoubleArray):Double;
begin
  Result:=Y[0]-0.5;
end;

var
  Options:TStiffODEOptions;
  Solution:TStiffODESolution;
  DenseState:TDoubleArray;
  ExpectedEndpoint:Double;
begin
  Options:=TStiffODEOptions.Defaults;
  Options.AbsoluteTolerance:=1E-7;
  Options.RelativeTolerance:=1E-6;
  Options.MaximumStep:=0.05;
  Options.JacobianMode:=sjmAnalytic;
  Options.Jacobian:=@ForcedStiffJacobian;

  Solution:=TModellingKit.SolveStiffODE(@ForcedStiffODE,0,
    TDoubleArray.Create(0),1.2,Options);
  if Solution.Status<>isConverged then
    raise Exception.Create('Stiff integration did not converge.');
  ExpectedEndpoint:=Cos(1.2)-Exp(-1200);
  if Abs(Solution.Y[High(Solution.Y)][0]-ExpectedEndpoint)>2E-5 then
    raise Exception.Create('Stiff endpoint exceeded its error budget.');
  DenseState:=Solution.Evaluate(0.4);
  if Abs(DenseState[0]-(Cos(0.4)-Exp(-400)))>2E-5 then
    raise Exception.Create('Dense output exceeded its error budget.');

  WriteLn('method = Alexander two-stage SDIRK');
  WriteLn('endpoint y(1.2) = ',Solution.Y[High(Solution.Y)][0]:0:8);
  WriteLn('dense output y(0.4) = ',DenseState[0]:0:8);
  WriteLn('Jacobian evaluations = ',Solution.JacobianEvaluations);

  Options.Event:=@FallingHalfState;
  Options.EventDirection:=-1;
  Solution:=TModellingKit.SolveStiffODE(@ForcedStiffODE,0,
    TDoubleArray.Create(0),1.2,Options);
  if (Solution.Status<>isConverged) or not Solution.EventFound then
    raise Exception.Create('Falling event was not located.');
  if (Abs(Solution.EventTime-Pi/3)>2E-4) or
     (Abs(Solution.EventState[0]-0.5)>2E-5) then
    raise Exception.Create('Event location exceeded its error budget.');
  WriteLn('falling event state = ',Solution.EventState[0]:0:8);
  WriteLn('stiff ODE example: success');
end.
