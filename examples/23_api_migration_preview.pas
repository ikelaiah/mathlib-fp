program api_migration_preview;

{$mode objfpc}{$H+}{$J-}

uses
  SysUtils, Math,
  MathBase.SharedTypes, MathBase.Complex,
  MathBase.Iteration,
  AlgebraLib.Matrices,
  AlgebraLib.DenseMatrices,
  AlgebraLib.DenseDecompositions,
  AlgebraLib.DenseSolvers,
  AlgebraLib.SparseMatrices,
  AlgebraLib.LinearOperators,
  AlgebraLib.IterativeSolvers,
  NumericsLib.Interpolation,
  NumericsLib.Modelling,
  OptimizationLib.Optimization,
  EngineeringLib.DSP,
  StatsLib.Streaming;

function MigrationObjective(const X: TDoubleArray): Double;
begin
  Result := Sqr(X[0] - 2.0) + Sqr(X[1] + 1.0);
end;

function MigrationGradient(const X: TDoubleArray): TDoubleArray;
begin
  Result := TDoubleArray.Create(
    2.0 * (X[0] - 2.0), 2.0 * (X[1] + 1.0));
end;

procedure Require(const Condition: Boolean; const MessageText: string);
begin
  if not Condition then
    raise Exception.Create('migration preview: ' + MessageText);
end;

var
  LegacySparse: TMatrixKitSparse;
  Builder: TSparseDoubleTripletBuilder;
  Sparse: ISparseDoubleMatrix;
  Dense, DenseRightHandSide, DenseSolution: IDenseDoubleMatrix;
  DenseDiagnostics: TDenseSolveDiagnostics;
  SparseOperator: ILinearDoubleOperator;
  SparsePreconditioner: IDoublePreconditioner;
  SparseOptions: TLinearSolveOptions;
  SparseResult: TDoubleLinearSolveResult;
  Spline: TCubicSplineInterpolator;
  Fit: TFitResult;
  OptimizationOptions: TOptimizationOptions;
  OptimizationResult: TOptResult;
  SpectrumInput, Spectrum: TComplexArray;
  Summary: TOnlineStatistics;
begin
  { Compatibility storage remains mutable and each lookup/insertion is linear
    in its stored count. Conversion is explicit rather than representation-
    changing behind an existing handle. }
  LegacySparse := TMatrixKitSparse.Create(2, 2);
  try
    LegacySparse.SetValue(0, 0, 2.0);
    LegacySparse.SetValue(1, 1, 3.0);
    Builder := TSparseDoubleTripletBuilder.Create(2, 2);
    try
      Builder.Add(0, 0, LegacySparse.GetValue(0, 0));
      Builder.Add(1, 1, LegacySparse.GetValue(1, 1));
      Sparse := Builder.ToCSR;
    finally
      Builder.Free;
    end;
  finally
    LegacySparse.Free;
  end;

  { Candidate primary conventions: typed reference-counted handles, zero-based
    indexing, explicit options/statuses, and no silent scalar conversion. }
  Dense := TDenseDoubleMatrix.FromValues(2, 2, [2.0, 0.0, 0.0, 3.0]);
  DenseRightHandSide := TDenseDoubleMatrix.FromValues(2, 1, [4.0, 9.0]);
  DenseSolution := SolveWithInfo(
    Dense, DenseRightHandSide, DenseDiagnostics);
  Require(
    (Abs(DenseSolution[0, 0] - 2.0) <= 1.0e-12) and
    (Abs(DenseSolution[1, 0] - 3.0) <= 1.0e-12),
    'typed dense solve produced the wrong solution');

  Spline := TCubicSplineInterpolator.Build(
    [0.0, 1.0, 2.0], [0.0, 1.0, 4.0], sbNatural);
  Fit := TModellingKit.FitPolynomial(
    TDoubleArray.Create(0.0, 1.0, 2.0, 3.0),
    TDoubleArray.Create(1.0, 3.0, 5.0, 7.0),
    1, nil);
  Require(
    (Fit.Status = isConverged) and
    (Abs(Fit.Parameters[0] - 1.0) <= 1.0e-10) and
    (Abs(Fit.Parameters[1] - 2.0) <= 1.0e-10),
    'typed fitting workflow did not recover y = 1 + 2x');

  OptimizationOptions := TOptimizationOptions.Defaults;
  OptimizationOptions.MaxIterations := 50;
  OptimizationResult := TOptimizationKit.NonlinearConjugateGradient(
    @MigrationObjective, @MigrationGradient,
    TDoubleArray.Create(5.0, -4.0), OptimizationOptions);
  Require(
    (OptimizationResult.Status = isConverged) and
    (Abs(OptimizationResult.X[0] - 2.0) <= 1.0e-6) and
    (Abs(OptimizationResult.X[1] + 1.0) <= 1.0e-6),
    'optimizer did not report and return the expected minimum');

  SparseOperator := TDoubleLinearOperator.FromSparse(Sparse);
  SparsePreconditioner := TDoublePreconditioner.SparseDiagonal(Sparse);
  SparseOptions := TLinearSolveOptions.Default;
  SparseOptions.RelativeTolerance := 1.0e-12;
  SparseResult := TDoubleIterativeSolver.ConjugateGradient(
    SparseOperator, DenseRightHandSide, SparseOptions,
    SparsePreconditioner);
  Require(
    (SparseResult.Diagnostics.Status = isConverged) and
    SparseResult.Diagnostics.ConvergenceConfirmed and
    (Abs(SparseResult.Solution[0, 0] - 2.0) <= 1.0e-10) and
    (Abs(SparseResult.Solution[1, 0] - 3.0) <= 1.0e-10),
    'typed sparse operator solve failed');

  SpectrumInput := TComplexArray.Create(
    TComplex.Create(1.0, 0.0), TComplex.Zero,
    TComplex.Zero, TComplex.Zero);
  Spectrum := TDSPKit.Transform(SpectrumInput);
  Summary := TOnlineStatistics.Create;
  Summary.Add(Dense[0, 0]);
  Summary.Add(Sparse[1, 1]);

  Writeln('dense solve: ', DenseSolution[0, 0]:0:1, ', ',
    DenseSolution[1, 0]:0:1, '; residual=',
    DenseDiagnostics.ResidualNorm:0:12);
  Writeln('sparse solve: ',
    IterationStatusName(SparseResult.Diagnostics.Status), '; residual=',
    SparseResult.Diagnostics.FinalResidualNorm:0:12);
  Writeln('spline(1.5): ', Spline.Evaluate(1.5):0:6);
  Writeln('linear fit: intercept=', Fit.Parameters[0]:0:6,
    ', slope=', Fit.Parameters[1]:0:6,
    ', status=', IterationStatusName(Fit.Status));
  Writeln('optimization: x=', OptimizationResult.X[0]:0:6, ', ',
    OptimizationResult.X[1]:0:6, '; status=',
    IterationStatusName(OptimizationResult.Status));
  Writeln('DSP DC bin: ', Spectrum[0].Re:0:1);
  Writeln('streaming mean: ', Summary.Mean:0:1);
end.
