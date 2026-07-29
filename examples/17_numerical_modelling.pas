program numerical_modelling;

{$mode objfpc}{$H+}

uses
  SysUtils, Math, MathBase.SharedTypes, MathBase.Iteration,
  NumericsLib.Interpolation, NumericsLib.Modelling;

function DecayResidual(const P:TDoubleArray):TDoubleArray;
const
  X:array[0..4] of Double=(0,0.5,1,1.5,2);
  Y:array[0..4] of Double=(3.02,1.83,1.12,0.66,0.43);
var I:Integer;
begin
  Result:=nil;
  SetLength(Result,Length(X));
  for I:=0 to High(X) do Result[I]:=P[0]*Exp(-P[1]*X[I])-Y[I];
end;

function GrowthODE(T:Double;const Y:TDoubleArray):TDoubleArray;
begin Result:=TDoubleArray.Create(Y[0]); end;

function ReachTwo(T:Double;const Y:TDoubleArray):Double;
begin Result:=Y[0]-2; end;

var
  Fit:TFitResult;
  FitOptions:TNonlinearFitOptions;
  ODEOptions:TAdaptiveODEOptions;
  Solution:TAdaptiveODESolution;
  Curve:TCubicInterpolator;
begin
  Curve:=TCubicInterpolator.BuildPchip(
    TDoubleArray.Create(0,1,2,3),
    TDoubleArray.Create(0,1,1.5,2));
  WriteLn('PCHIP(1.5) = ',Curve.Evaluate(1.5):0:6,
    ', derivative = ',Curve.Derivative(1.5):0:6);

  FitOptions:=TNonlinearFitOptions.Defaults;
  FitOptions.LowerBounds:=TDoubleArray.Create(0,0);
  FitOptions.UpperBounds:=TDoubleArray.Create(10,10);
  Fit:=TModellingKit.FitNonlinear(@DecayResidual,nil,
    TDoubleArray.Create(2,0.5),FitOptions);
  WriteLn('fit status: ',IterationStatusName(Fit.Status),
    ', amplitude=',Fit.Parameters[0]:0:5,
    ', rate=',Fit.Parameters[1]:0:5,
    ', RSS=',Fit.ResidualSumSquares:0:6);

  ODEOptions:=TAdaptiveODEOptions.Defaults;
  ODEOptions.Event:=@ReachTwo;
  Solution:=TModellingKit.SolveODE(@GrowthODE,0,
    TDoubleArray.Create(1),2,ODEOptions);
  WriteLn('ODE status: ',IterationStatusName(Solution.Status),
    ', event t=',Solution.EventTime:0:7,
    ' (expected ln(2)=',Ln(2):0:7,')');
end.
