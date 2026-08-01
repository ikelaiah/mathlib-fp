program sparse_end_to_end;

{$mode objfpc}{$H+}{$J-}

uses
  Classes, SysUtils,
  MathBase.Interchange, MathBase.Iteration,
  AlgebraLib.DenseMatrices,
  AlgebraLib.SparseMatrices,
  AlgebraLib.LinearOperators,
  AlgebraLib.IterativeSolvers;

var
  Builder: TSparseDoubleTripletBuilder;
  MatrixValue, Reloaded: ISparseDoubleMatrix;
  OperatorValue: ILinearDoubleOperator;
  Preconditioner: IDoublePreconditioner;
  RightHandSide: IDenseDoubleMatrix;
  Options: TLinearSolveOptions;
  SolveResult: TDoubleLinearSolveResult;
  OpenFormat: TMemoryStream;
  I: SizeInt;
begin
  { Assemble the five-point one-dimensional Poisson stencil as unordered
    contributions. The builder canonicalises and combines coordinates. }
  Builder := TSparseDoubleTripletBuilder.Create(5, 5);
  try
    for I := 0 to 4 do
    begin
      Builder.Add(I, I, 2.0);
      if I > 0 then Builder.Add(I, I - 1, -1.0);
      if I < 4 then Builder.Add(I, I + 1, -1.0);
    end;
    MatrixValue := Builder.ToCSR;
  finally
    Builder.Free;
  end;

  { Matrix Market coordinate form is open, one-based on disk, and validated
    back into zero-based canonical compressed storage. }
  OpenFormat := TMemoryStream.Create;
  try
    WriteSparseMatrixMarket(OpenFormat, MatrixValue);
    OpenFormat.Position := 0;
    Reloaded := ReadSparseMatrixMarketDouble(OpenFormat, sfCSR);
  finally
    OpenFormat.Free;
  end;

  OperatorValue := TDoubleLinearOperator.FromSparse(Reloaded);
  Preconditioner := TDoublePreconditioner.IncompleteCholesky0(Reloaded);
  RightHandSide := TDenseDoubleMatrix.FromValues(5, 1,
    [1.0, 0.0, 0.0, 0.0, 1.0]);
  Options := TLinearSolveOptions.Default;
  Options.RelativeTolerance := 1.0e-12;
  SolveResult := TDoubleIterativeSolver.ConjugateGradient(
    OperatorValue, RightHandSide, Options, Preconditioner);

  Writeln('stored nonzeros: ', Reloaded.NonZeroCount);
  Writeln('termination: ', IterationStatusName(
    SolveResult.Diagnostics.Status));
  Writeln('iterations/products: ', SolveResult.Diagnostics.Iterations, '/',
    SolveResult.Diagnostics.ProductCount);
  Writeln('initial/final residual: ',
    SolveResult.Diagnostics.InitialResidualNorm:0:6, '/',
    SolveResult.Diagnostics.FinalResidualNorm:0:12);
  Writeln('true residual confirmed: ',
    SolveResult.Diagnostics.ResidualConfirmed);
  Writeln('solution endpoints: ', SolveResult.Solution[0, 0]:0:6, ', ',
    SolveResult.Solution[4, 0]:0:6);

  if SolveResult.Diagnostics.Status <> isConverged then Halt(1);
end.
