program ParallelMultiply;

{ Opt-in parallel dense multiplication (v2.15.0).

  A large product is the bottleneck of many dense workflows. MultiplyParallelInto
  splits the output rows across a caller-chosen number of workers and returns
  exactly the same bits as the serial blocked kernel. Ordinary Multiply calls
  never start threads, small products stay serial, and a Unix program needs
  cthreads first in its uses clause before any worker can start. }

{$mode objfpc}{$H+}{$J-}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Math, AlgebraLib.DenseMatrices, AlgebraLib.DenseKernels;

const
  Rows = 240;
  Inner = 200;
  Cols = 180;

var
  A, B, Serial, Parallel: IDenseDoubleMatrix;
  I, J, Workers: SizeInt;
  X, Y: Double;
  Identical: Boolean;
begin
  A := TDenseDoubleMatrix.Zeros(Rows, Inner);
  B := TDenseDoubleMatrix.Zeros(Inner, Cols);
  for I := 0 to Rows - 1 do
    for J := 0 to Inner - 1 do
      A[I, J] := Sin(0.01 * (I + 1) + 0.03 * (J + 1));
  for I := 0 to Inner - 1 do
    for J := 0 to Cols - 1 do
      B[I, J] := Cos(0.02 * (I + 1) - 0.01 * (J + 1));
  Serial := TDenseDoubleMatrix.Zeros(Rows, Cols);
  Parallel := TDenseDoubleMatrix.Zeros(Rows, Cols);

  // The caller owns the worker count; use the processors, capped at eight.
  Workers := Max(1, Min(8, Integer(GetCPUCount)));
  MultiplyBlockedInto(A, B, Serial);
  MultiplyParallelInto(A, B, Parallel, Workers);

  Identical := True;
  for I := 0 to Rows - 1 do
    for J := 0 to Cols - 1 do
    begin
      X := Serial[I, J];
      Y := Parallel[I, J];
      if not CompareMem(@X, @Y, SizeOf(Double)) then
        Identical := False;
    end;
  if not Identical then
    raise Exception.Create('parallel product differs from the serial kernel');
  Writeln(Format('product %dx%dx%d: parallel and serial results are bitwise identical',
    [Rows, Inner, Cols]));

  // Work below DENSE_PARALLEL_MIN_WORK_PER_WORKER per extra worker stays serial.
  if EffectiveMultiplyWorkers(16, 16, 16, 8) <> 1 then
    raise Exception.Create('small product should stay serial');
  Writeln('small 16x16x16 product: 1 worker (no thread start-up)');

  try
    MultiplyParallelInto(A, B, Parallel, DENSE_PARALLEL_MAX_WORKERS + 1);
    raise Exception.Create('oversized worker count was accepted');
  except
    on E: EDenseMatrixError do
      Writeln('worker counts outside 1..', DENSE_PARALLEL_MAX_WORKERS,
        ' are rejected before any write');
  end;
  Writeln('parallel multiply: success');
end.
