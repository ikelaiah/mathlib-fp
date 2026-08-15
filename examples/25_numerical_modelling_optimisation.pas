program numerical_modelling_optimisation;

{ ----------------------------------------------------------------------------
  mathlib-fp 1.9.8 representative workflow 2 — numerical modelling and
  optimisation

  A realistic modelling flow: bundle local data, validate it, fit and
  interpolate it, solve a scalar equation, optimise a smooth objective with and
  without bounds, exercise convergence-failure and invalid-input diagnostics,
  and export a deterministic report.

  Domains exercised: MathBase (shared arrays, iteration status, binary
  interchange), NumericsLib (interpolation, fitting, root solving),
  OptimizationLib (conjugate-gradient and bounded L-BFGS optimisation).

  Run from the repository root (or the extracted release archive root). The
  export is written to workflow-exports/model_report.txt relative to the
  working directory.

  Compile:  fpc -Fusrc -FUlib examples/25_numerical_modelling_optimisation.pas
  Run:      ./25_numerical_modelling_optimisation
--------------------------------------------------------------------------- }

{$mode objfpc}{$H+}{$J-}

uses
  Classes, SysUtils,
  MathBase.SharedTypes, MathBase.Iteration, MathBase.Interchange,
  NumericsLib.Interpolation, NumericsLib.Modelling, NumericsLib.Numerics,
  OptimizationLib.Optimization;

const
  ExportPath = 'workflow-exports/model_report.txt';

function F6(const Value: Double): string;
begin
  Str(Value:0:6, Result);
end;

procedure SaveText(const FileName, Content: string);
var
  Output: Text;
begin
  ForceDirectories(ExtractFilePath(FileName));
  Assign(Output, FileName);
  Rewrite(Output);
  Write(Output, Content);
  Close(Output);
end;

{ Smooth bowl with a unique minimum at (2, -1). }
function Bowl(const X: TDoubleArray): Double;
begin
  Result := Sqr(X[0] - 2.0) + Sqr(X[1] + 1.0);
end;

function BowlGrad(const X: TDoubleArray): TDoubleArray;
begin
  Result := TDoubleArray.Create(2.0 * (X[0] - 2.0), 2.0 * (X[1] + 1.0));
end;

{ Bounded objective with a unique minimum at (3, 2). }
function Bounded(const X: TDoubleArray): Double;
begin
  Result := Sqr(X[0] - 3.0) + Sqr(X[1] - 2.0);
end;

function BoundedGrad(const X: TDoubleArray): TDoubleArray;
begin
  Result := TDoubleArray.Create(2.0 * (X[0] - 3.0), 2.0 * (X[1] - 2.0));
end;

{ f(x) = x^2 - 2, root at sqrt(2). }
function SqrtTwo(X: Double): Double;
begin
  Result := X * X - 2.0;
end;

var
  X, Y, Parameters, ExportVector: TDoubleArray;
  Fit: TFitResult;
  Curve: TCubicInterpolator;
  Root: TRootResult;
  FailedRoot: TRootResult;
  OptOptions: TOptimizationOptions;
  UnboundedResult, BoundedResult: TOptResult;
  Stream: TMemoryStream;
  Report: string;
  Rejected: string;
begin
  { 1. Local modelling data + validation -----------------------------------
    y = 3 + 2x exactly; the fitting path recovers the closed-form coefficients. }
  X := TDoubleArray.Create(0.0, 1.0, 2.0, 3.0, 4.0);
  Y := TDoubleArray.Create(3.0, 5.0, 7.0, 9.0, 11.0);
  if Length(X) <> Length(Y) then
  begin
    Writeln('diagnostic: mismatched modelling data rejected');
    Halt(1);
  end;

  { 2. Fitting and interpolation -------------------------------------------
    Linear least-squares fit and a monotone PCHIP interpolant. }
  Fit := TModellingKit.FitPolynomial(X, Y, 1, nil);
  Writeln('fit status: ', IterationStatusName(Fit.Status));
  Writeln('fit intercept: ', F6(Fit.Parameters[0]));
  Writeln('fit slope: ', F6(Fit.Parameters[1]));
  Writeln('fit R^2: ', F6(Fit.RSquared));

  Curve := TCubicInterpolator.BuildPchip(
    TDoubleArray.Create(0.0, 1.0, 2.0, 3.0),
    TDoubleArray.Create(0.0, 1.0, 4.0, 9.0));
  Writeln('pchip(1.5): ', F6(Curve.Evaluate(1.5)));

  { 3. Numerical solve ------------------------------------------------------
    A bracketed scalar root: sqrt(2). }
  Root := TNumericsKit.BrentResult(@SqrtTwo, 1.0, 2.0);
  Writeln('root value: ', F6(Root.Root));
  Writeln('root converged: ', Root.Converged);

  { 4. Optimisation ---------------------------------------------------------
    Unconstrained conjugate gradient, then a bounded L-BFGS solve. }
  OptOptions := TOptimizationOptions.Defaults;
  OptOptions.MaxIterations := 200;
  UnboundedResult := TOptimizationKit.NonlinearConjugateGradient(
    @Bowl, @BowlGrad, TDoubleArray.Create(0.0, 0.0), OptOptions);
  Writeln('optimizer status: ', IterationStatusName(UnboundedResult.Status));
  Writeln('optimizer x0: ', F6(UnboundedResult.X[0]));
  Writeln('optimizer x1: ', F6(UnboundedResult.X[1]));

  OptOptions := TOptimizationOptions.Defaults;
  OptOptions.MaxIterations := 200;
  OptOptions.LowerBounds := TDoubleArray.Create(0.0, 0.0);
  OptOptions.UpperBounds := TDoubleArray.Create(10.0, 10.0);
  BoundedResult := TOptimizationKit.BoundedLBFGS(
    @Bounded, @BoundedGrad, TDoubleArray.Create(5.0, 5.0), OptOptions);
  Writeln('bounded optimizer status: ', IterationStatusName(BoundedResult.Status));
  Writeln('bounded optimizer x0: ', F6(BoundedResult.X[0]));
  Writeln('bounded optimizer x1: ', F6(BoundedResult.X[1]));

  { 5. Diagnostics ----------------------------------------------------------
    (a) A root solve starved of iterations reports non-convergence instead of a
        fabricated answer.
    (b) An invalid fit request raises a typed exception that is caught. }
  FailedRoot := TNumericsKit.BisectionResult(@SqrtTwo, 1.0, 2.0, 1E-12, 2);
  Writeln('root diagnostic converged: ', FailedRoot.Converged);
  Writeln('root diagnostic status: ', IterationStatusName(FailedRoot.Status));

  Rejected := '';
  try
    TModellingKit.FitPolynomial(X, Y, -1, nil);
  except
    on E: Exception do
      Rejected := E.ClassName;
  end;
  Writeln('diagnostic: invalid fit rejected by ', Rejected);

  { 6. Persistence / export -------------------------------------------------
    Round-trip the fitted parameters through versioned binary interchange and
    write a deterministic report. }
  Parameters := Fit.Parameters;
  Stream := TMemoryStream.Create;
  try
    SaveBinary(Stream, Parameters);
    Stream.Position := 0;
    ExportVector := LoadDoubleVectorBinary(Stream, 1000);
  finally
    Stream.Free;
  end;

  Report :=
    'mathlib-fp modelling report' + sLineBreak +
    'fit intercept: ' + F6(Fit.Parameters[0]) + sLineBreak +
    'fit slope: ' + F6(Fit.Parameters[1]) + sLineBreak +
    'root value: ' + F6(Root.Root) + sLineBreak +
    'optimizer x0: ' + F6(UnboundedResult.X[0]) + sLineBreak +
    'optimizer x1: ' + F6(UnboundedResult.X[1]) + sLineBreak +
    'round-trip parameters: ' + IntToStr(Length(ExportVector)) + sLineBreak;
  SaveText(ExportPath, Report);
  Writeln('exported: ', ExportPath, ' (', Length(Report), ' bytes)');

  Writeln('modelling workflow: success');
end.
