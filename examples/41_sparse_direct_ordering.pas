program sparse_direct_ordering;

{$mode objfpc}{$H+}

uses
  SysUtils,
  AlgebraLib.DenseMatrices,
  AlgebraLib.SparseMatrices,
  AlgebraLib.StructuredSolvers;

var
  Matrix: ISparseDoubleMatrix;
  Analysis: ISparseDoubleLUAnalysis;
  Factor: ISparseDoubleLUFactor;
  RightHandSide, Solution: IDenseDoubleMatrix;
  I: SizeInt;
begin
  Matrix := TSparseDoubleMatrix.FromCSR(5, 5,
    [0, 2, 5, 7, 10, 13],
    [0, 3, 1, 3, 4, 2, 4, 0, 1, 3, 1, 2, 4],
    [5.0, -1.0, 5.0, -1.0, -1.0, 5.0, -1.0,
     -1.0, -1.0, 5.0, -1.0, -1.0, 5.0]);
  Analysis := TDoubleStructuredSolver.AnalyzeSparseLU(
    Matrix, soMinimumDegree);
  Factor := Analysis.Factorize(Matrix);
  RightHandSide := TDenseDoubleMatrix.FromValues(
    5, 1, [4.0, 3.0, 4.0, 3.0, 3.0]);
  Solution := TDenseDoubleMatrix.Zeros(5, 1);
  Factor.SolveInto(RightHandSide, Solution);
  for I := 0 to Solution.Rows - 1 do
    if Abs(Solution[I, 0] - 1.0) > 1.0e-12 then
    begin
      Writeln('sparse direct: failed');
      Halt(1);
    end;
  Writeln('ordering: ', Ord(Factor.Ordering));
  Writeln('fill entries: ', Factor.FillNonZeroCount);
  Writeln('sparse direct: success');
end.
