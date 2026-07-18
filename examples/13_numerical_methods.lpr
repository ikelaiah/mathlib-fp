program NumericalMethods;

{-----------------------------------------------------------------------------
  13_numerical_methods.lpr

  A guided tour of NumericsLib for newcomers. It demonstrates the four main
  numerical workflows:

    1. finding a root of f(x) = 0;
    2. approximating a definite integral;
    3. solving an ordinary differential equation (ODE); and
    4. interpolating between measured data points.

  From this directory, compile with:

    mkdir lib
    fpc -Fu../src -FUlib 13_numerical_methods.lpr

  Then run ./13_numerical_methods (or 13_numerical_methods.exe on Windows).
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}

uses
  SysUtils,                  // Format and EInvalidArgument
  Math,                      // Exp and Pi
  MathBase.SharedTypes,      // TDoubleArray
  NumericsLib.Numerics;      // TNumericsKit and its result records

{ NumericsLib accepts ordinary unit-level functions as callbacks. The @ symbol
  below passes a function itself, rather than calling it immediately. }

function SquareMinusTwo(X: Double): Double;
begin
  Result := X * X - 2.0;
end;

function SineWave(X: Double): Double;
begin
  Result := Sin(X);
end;

function ExponentialGrowth(T, Y: Double): Double;
begin
  { This is dy/dt = y. T is unused for this autonomous equation, but remains
    part of the callback signature because other ODEs depend on time. }
  Result := Y;
end;

procedure DemoRootFinding;
var
  Root: TRootResult;
begin
  WriteLn('=== 1. Root finding ===');
  WriteLn('Solve x^2 - 2 = 0 on [1, 2], whose positive root is sqrt(2).');

  { Brent is a strong general default: like bisection it requires a bracket
    whose endpoint values have opposite signs, but it is usually faster.

    Use BrentResult when the convergence details matter. The simpler Brent
    wrapper returns only the root and raises if its iteration limit is hit. }
  Root := TNumericsKit.BrentResult(@SquareMinusTwo, 1.0, 2.0);
  WriteLn(Format('Root        : %.12f', [Root.Root]));
  WriteLn(Format('Residual    : %.3e', [Root.Residual]));
  WriteLn(Format('Iterations  : %d', [Root.Iterations]));
  WriteLn(Format('Converged   : %s', [BoolToStr(Root.Converged, True)]));
  WriteLn;

  { Invalid input is reported with an exception. This deliberately bad
    bracket has f(2) > 0 and f(3) > 0, so it cannot establish a root. }
  WriteLn('Trying an invalid bracket [2, 3]...');
  try
    TNumericsKit.Brent(@SquareMinusTwo, 2.0, 3.0);
  except
    on E: EInvalidArgument do
      WriteLn('Caught the expected input error: ', E.Message);
  end;
  WriteLn;
end;

procedure DemoIntegration;
var
  Trapezoid, Simpson, Gauss: Double;
begin
  WriteLn('=== 2. Numerical integration ===');
  WriteLn('Approximate integral(sin(x), x=0..Pi); the exact answer is 2.');

  { N is the number of subintervals for the composite rules. More intervals
    usually improve accuracy but require more function evaluations. }
  Trapezoid := TNumericsKit.TrapezoidalRule(@SineWave, 0.0, Pi, 100);
  Simpson := TNumericsKit.SimpsonRule(@SineWave, 0.0, Pi, 100);

  { Five-point Gauss-Legendre uses only five function evaluations and performs
    especially well for smooth functions on a finite interval. }
  Gauss := TNumericsKit.GaussLegendre5(@SineWave, 0.0, Pi);

  WriteLn(Format('Trapezoidal (N=100): %.10f', [Trapezoid]));
  WriteLn(Format('Simpson     (N=100): %.10f', [Simpson]));
  WriteLn(Format('Gauss-Legendre (5):  %.10f', [Gauss]));
  WriteLn;
end;

procedure DemoODE;
var
  EulerSolution, RK4Solution: TODESolution;
  ExactValue: Double;
  Last: Integer;
begin
  WriteLn('=== 3. Ordinary differential equations ===');
  WriteLn('Solve dy/dt = y with y(0)=1 over [0,1]; exact y(1) is e.');

  { Both solvers return N+1 samples, including the initial value at index 0
    and the final value at index N. RK4 normally gives much better accuracy
    than Euler for the same step count. }
  EulerSolution := TNumericsKit.EulerSolve(
    @ExponentialGrowth, 0.0, 1.0, 1.0, 10);
  RK4Solution := TNumericsKit.RK4Solve(
    @ExponentialGrowth, 0.0, 1.0, 1.0, 10);

  Last := High(RK4Solution.Y);
  ExactValue := Exp(1.0);
  WriteLn(Format('Euler y(1), 10 steps: %.10f (error %.3e)',
    [EulerSolution.Y[High(EulerSolution.Y)],
     Abs(EulerSolution.Y[High(EulerSolution.Y)] - ExactValue)]));
  WriteLn(Format('RK4   y(1), 10 steps: %.10f (error %.3e)',
    [RK4Solution.Y[Last], Abs(RK4Solution.Y[Last] - ExactValue)]));

  { The matching T array makes it easy to iterate over every (t, y) sample. }
  WriteLn(Format('Final sample is (t=%.1f, y=%.10f)',
    [RK4Solution.T[Last], RK4Solution.Y[Last]]));
  WriteLn;
end;

procedure DemoInterpolation;
var
  XKnots, YKnots: TDoubleArray;
  Spline: TCubicSpline;
  QueryX: Double;
begin
  WriteLn('=== 4. Interpolation ===');
  WriteLn('Estimate a value between a few measured samples.');

  { X knots must be finite and strictly increasing. X and Y must have the same
    length. These samples happen to follow y=x^2, but real input could be lab
    measurements or points read from a file. }
  XKnots := TDoubleArray.Create(0.0, 1.0, 2.0, 3.0, 4.0);
  YKnots := TDoubleArray.Create(0.0, 1.0, 4.0, 9.0, 16.0);
  QueryX := 1.5;

  WriteLn(Format('Linear at x=1.5 : %.6f',
    [TNumericsKit.LinearInterp(XKnots, YKnots, QueryX)]));
  WriteLn(Format('Lagrange at x=1.5: %.6f',
    [TNumericsKit.LagrangeInterp(XKnots, YKnots, QueryX)]));

  { Build a spline once, then reuse it for as many query points as needed. A
    natural cubic spline is smooth between knots and scales better than a
    high-degree Lagrange polynomial for larger datasets. }
  Spline := TNumericsKit.CubicSplineBuild(XKnots, YKnots);
  WriteLn(Format('Cubic spline at x=1.5: %.6f',
    [TNumericsKit.CubicSplineEval(Spline, QueryX)]));
  WriteLn;
end;

begin
  WriteLn('mathlib-fp - NumericsLib Walkthrough');
  WriteLn('====================================');
  WriteLn;

  DemoRootFinding;
  DemoIntegration;
  DemoODE;
  DemoInterpolation;

  WriteLn('Done. See docs/NumericsLib.md for method-selection guidance.');
end.
