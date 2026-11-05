unit TestParallelMultiply;

{ v2.15.0 opt-in parallel dense multiplication. The serial blocked kernel is
  the oracle: every parallel result must match it bitwise for the same block
  size, including uneven partitions, views, aliasing, non-default rounding and
  concurrent callers. }

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math, fpcunit, testregistry, MathBase.Complex,
  AlgebraLib.DenseMatrices, AlgebraLib.DenseKernels;

type
  TParallelMultiplyTest = class(TTestCase)
  published
    procedure TestRealBitwiseAgreement;
    procedure TestComplexBitwiseAgreement;
    procedure TestEffectiveWorkers;
    procedure TestValidationPrecedesWrites;
    procedure TestAliasedDestinationAndViews;
    procedure TestConcurrentCallers;
    procedure TestWorkerExceptionsPropagate;
    procedure TestWorkersInheritRoundingMode;
  end;

implementation

type
  TShape = record
    Rows, Inner, Cols: SizeInt;
  end;

const
  { Serial-only, two-worker, row-limited and multi-worker shapes. }
  Shapes: array[0..3] of TShape = (
    (Rows: 37; Inner: 29; Cols: 41),
    (Rows: 64; Inner: 64; Cols: 64),
    (Rows: 3; Inner: 400; Cols: 400),
    (Rows: 130; Inner: 70; Cols: 90));
  WorkerCounts: array[0..5] of SizeInt = (1, 2, 3, 4, 7,
    DENSE_PARALLEL_MAX_WORKERS);
  BlockSizes: array[0..5] of SizeInt = (32, 1, 7, 32, High(SizeInt), 5);

function DoubleMatrix(const Rows, Cols: SizeInt;
  const Seed: Double): IDenseDoubleMatrix;
var
  I, J: SizeInt;
begin
  Result := TDenseDoubleMatrix.Zeros(Rows, Cols);
  for I := 0 to Rows - 1 do
    for J := 0 to Cols - 1 do
      Result[I, J] := Sin(Seed + I * 0.37 + J * 0.11) * (1.0 + J mod 3);
end;

function SingleMatrix(const Rows, Cols: SizeInt;
  const Seed: Double): IDenseSingleMatrix;
var
  I, J: SizeInt;
begin
  Result := TDenseSingleMatrix.Zeros(Rows, Cols);
  for I := 0 to Rows - 1 do
    for J := 0 to Cols - 1 do
      Result[I, J] := Single(Cos(Seed + I * 0.23 - J * 0.17));
end;

function ComplexMatrix(const Rows, Cols: SizeInt;
  const Seed: Double): IDenseComplexMatrix;
var
  I, J: SizeInt;
begin
  Result := TDenseComplexMatrix.Zeros(Rows, Cols);
  for I := 0 to Rows - 1 do
    for J := 0 to Cols - 1 do
      Result[I, J] := TComplex.Create(Sin(Seed + I * 0.31 + J * 0.07),
        Cos(Seed - I * 0.13 + J * 0.29));
end;

function SingleComplexMatrix(const Rows, Cols: SizeInt;
  const Seed: Double): IDenseSingleComplexMatrix;
var
  I, J: SizeInt;
begin
  Result := TDenseSingleComplexMatrix.Zeros(Rows, Cols);
  for I := 0 to Rows - 1 do
    for J := 0 to Cols - 1 do
      Result[I, J] := TSingleComplex.Create(
        Single(Sin(Seed + I * 0.19 - J * 0.05)),
        Single(Cos(Seed + I * 0.41 + J * 0.03)));
end;

function SameBits(const A, B: IDenseDoubleMatrix): Boolean; overload;
var
  I, J: SizeInt;
  X, Y: Double;
begin
  Result := (A.Rows = B.Rows) and (A.Cols = B.Cols);
  if Result then
    for I := 0 to A.Rows - 1 do
      for J := 0 to A.Cols - 1 do
      begin
        X := A[I, J];
        Y := B[I, J];
        if not CompareMem(@X, @Y, SizeOf(Double)) then
          Exit(False);
      end;
end;

function SameBits(const A, B: IDenseSingleMatrix): Boolean; overload;
var
  I, J: SizeInt;
  X, Y: Single;
begin
  Result := (A.Rows = B.Rows) and (A.Cols = B.Cols);
  if Result then
    for I := 0 to A.Rows - 1 do
      for J := 0 to A.Cols - 1 do
      begin
        X := A[I, J];
        Y := B[I, J];
        if not CompareMem(@X, @Y, SizeOf(Single)) then
          Exit(False);
      end;
end;

function SameBits(const A, B: IDenseComplexMatrix): Boolean; overload;
var
  I, J: SizeInt;
  X, Y: TComplex;
begin
  Result := (A.Rows = B.Rows) and (A.Cols = B.Cols);
  if Result then
    for I := 0 to A.Rows - 1 do
      for J := 0 to A.Cols - 1 do
      begin
        X := A[I, J];
        Y := B[I, J];
        if not (CompareMem(@X.Re, @Y.Re, SizeOf(Double)) and
          CompareMem(@X.Im, @Y.Im, SizeOf(Double))) then
          Exit(False);
      end;
end;

function SameBits(const A, B: IDenseSingleComplexMatrix): Boolean; overload;
var
  I, J: SizeInt;
  X, Y: TSingleComplex;
begin
  Result := (A.Rows = B.Rows) and (A.Cols = B.Cols);
  if Result then
    for I := 0 to A.Rows - 1 do
      for J := 0 to A.Cols - 1 do
      begin
        X := A[I, J];
        Y := B[I, J];
        if not (CompareMem(@X.Re, @Y.Re, SizeOf(Single)) and
          CompareMem(@X.Im, @Y.Im, SizeOf(Single))) then
          Exit(False);
      end;
end;

function CaseName(const Shape: TShape; const Workers,
  BlockSize: SizeInt): string;
begin
  Result := Format('%dx%dx%d workers=%d block=%d',
    [Shape.Rows, Shape.Inner, Shape.Cols, Workers, BlockSize]);
end;

procedure TParallelMultiplyTest.TestRealBitwiseAgreement;
var
  S, W: Integer;
  Shape: TShape;
  AD, BD, SerialD, ParallelD: IDenseDoubleMatrix;
  AS_, BS, SerialS, ParallelS: IDenseSingleMatrix;
begin
  for S := Low(Shapes) to High(Shapes) do
  begin
    Shape := Shapes[S];
    AD := DoubleMatrix(Shape.Rows, Shape.Inner, S);
    BD := DoubleMatrix(Shape.Inner, Shape.Cols, S + 0.5);
    AS_ := SingleMatrix(Shape.Rows, Shape.Inner, S);
    BS := SingleMatrix(Shape.Inner, Shape.Cols, S + 0.5);
    for W := Low(WorkerCounts) to High(WorkerCounts) do
    begin
      SerialD := TDenseDoubleMatrix.Zeros(Shape.Rows, Shape.Cols);
      ParallelD := TDenseDoubleMatrix.Zeros(Shape.Rows, Shape.Cols);
      MultiplyBlockedInto(AD, BD, SerialD, BlockSizes[W]);
      MultiplyParallelInto(AD, BD, ParallelD, WorkerCounts[W],
        BlockSizes[W]);
      AssertTrue('double ' + CaseName(Shape, WorkerCounts[W],
        BlockSizes[W]), SameBits(SerialD, ParallelD));

      SerialS := TDenseSingleMatrix.Zeros(Shape.Rows, Shape.Cols);
      ParallelS := TDenseSingleMatrix.Zeros(Shape.Rows, Shape.Cols);
      MultiplyBlockedInto(AS_, BS, SerialS, BlockSizes[W]);
      MultiplyParallelInto(AS_, BS, ParallelS, WorkerCounts[W],
        BlockSizes[W]);
      AssertTrue('single ' + CaseName(Shape, WorkerCounts[W],
        BlockSizes[W]), SameBits(SerialS, ParallelS));
    end;
  end;
  // The default block size matches the serial default.
  AD := DoubleMatrix(130, 70, 9.0);
  BD := DoubleMatrix(70, 90, 4.0);
  SerialD := TDenseDoubleMatrix.Zeros(130, 90);
  ParallelD := TDenseDoubleMatrix.Zeros(130, 90);
  MultiplyBlockedInto(AD, BD, SerialD);
  MultiplyParallelInto(AD, BD, ParallelD, 5);
  AssertTrue('default block size', SameBits(SerialD, ParallelD));
end;

procedure TParallelMultiplyTest.TestComplexBitwiseAgreement;
var
  S, W: Integer;
  Shape: TShape;
  AZ, BZ, SerialZ, ParallelZ: IDenseComplexMatrix;
  AC, BC, SerialC, ParallelC: IDenseSingleComplexMatrix;
begin
  for S := Low(Shapes) to High(Shapes) do
  begin
    Shape := Shapes[S];
    AZ := ComplexMatrix(Shape.Rows, Shape.Inner, S);
    BZ := ComplexMatrix(Shape.Inner, Shape.Cols, S + 0.25);
    AC := SingleComplexMatrix(Shape.Rows, Shape.Inner, S);
    BC := SingleComplexMatrix(Shape.Inner, Shape.Cols, S + 0.25);
    for W := Low(WorkerCounts) to High(WorkerCounts) do
    begin
      SerialZ := TDenseComplexMatrix.Zeros(Shape.Rows, Shape.Cols);
      ParallelZ := TDenseComplexMatrix.Zeros(Shape.Rows, Shape.Cols);
      MultiplyBlockedInto(AZ, BZ, SerialZ, BlockSizes[W]);
      MultiplyParallelInto(AZ, BZ, ParallelZ, WorkerCounts[W],
        BlockSizes[W]);
      AssertTrue('complex ' + CaseName(Shape, WorkerCounts[W],
        BlockSizes[W]), SameBits(SerialZ, ParallelZ));

      SerialC := TDenseSingleComplexMatrix.Zeros(Shape.Rows, Shape.Cols);
      ParallelC := TDenseSingleComplexMatrix.Zeros(Shape.Rows, Shape.Cols);
      MultiplyBlockedInto(AC, BC, SerialC, BlockSizes[W]);
      MultiplyParallelInto(AC, BC, ParallelC, WorkerCounts[W],
        BlockSizes[W]);
      AssertTrue('single complex ' + CaseName(Shape, WorkerCounts[W],
        BlockSizes[W]), SameBits(SerialC, ParallelC));
    end;
  end;
end;

procedure TParallelMultiplyTest.TestEffectiveWorkers;

  function Threaded(const Value: SizeInt): SizeInt;
  begin
    if DenseThreadingAvailable then
      Result := Value
    else
      Result := 1;
  end;

  procedure ExpectInvalid(const Rows, Inner, Cols, Requested: SizeInt);
  begin
    try
      EffectiveMultiplyWorkers(Rows, Inner, Cols, Requested);
      Fail(Format('expected rejection of %d,%d,%d requested=%d',
        [Rows, Inner, Cols, Requested]));
    except
      on EDenseMatrixError do ;
    end;
  end;

begin
  // The test runner installs cthreads on Unix; Windows always has threads.
  AssertTrue('test runner has a thread manager', DenseThreadingAvailable);
  AssertEquals('one requested worker', 1,
    EffectiveMultiplyWorkers(1000, 1000, 1000, 1));
  AssertEquals('zero rows', 1, EffectiveMultiplyWorkers(0, 50, 50, 8));
  AssertEquals('zero inner', 1, EffectiveMultiplyWorkers(50, 0, 50, 8));
  AssertEquals('zero columns', 1, EffectiveMultiplyWorkers(50, 50, 0, 8));
  AssertEquals('single row', 1, EffectiveMultiplyWorkers(1, 4000, 4000, 8));
  AssertEquals('below one worker of work', 1,
    EffectiveMultiplyWorkers(128, 32, 31, 8));
  AssertEquals('exactly one worker of work', 1,
    EffectiveMultiplyWorkers(128, 32, 32, 8));
  AssertEquals('two workers of work', Threaded(2),
    EffectiveMultiplyWorkers(64, 64, 64, 8));
  AssertEquals('bounded by rows', Threaded(3),
    EffectiveMultiplyWorkers(3, 400, 400, 8));
  AssertEquals('requested count honoured', Threaded(4),
    EffectiveMultiplyWorkers(512, 512, 512, 4));
  AssertEquals('maximum count', Threaded(DENSE_PARALLEL_MAX_WORKERS),
    EffectiveMultiplyWorkers(1000, 1000, 1000, DENSE_PARALLEL_MAX_WORKERS));
  AssertEquals('saturating operation count', Threaded(8),
    EffectiveMultiplyWorkers(High(SizeInt), High(SizeInt), High(SizeInt), 8));
  ExpectInvalid(10, 10, 10, 0);
  ExpectInvalid(10, 10, 10, -1);
  ExpectInvalid(10, 10, 10, DENSE_PARALLEL_MAX_WORKERS + 1);
  ExpectInvalid(-1, 10, 10, 2);
  ExpectInvalid(10, -1, 10, 2);
  ExpectInvalid(10, 10, -1, 2);
end;

procedure TParallelMultiplyTest.TestValidationPrecedesWrites;
var
  A, B, Destination, Wrong, Expected: IDenseDoubleMatrix;
  Z, ZB, ZDestination: IDenseComplexMatrix;

  procedure Expect(const Name: string; const X, Y, D: IDenseDoubleMatrix;
    const Workers, BlockSize: SizeInt);
  begin
    try
      MultiplyParallelInto(X, Y, D, Workers, BlockSize);
      Fail('expected EDenseMatrixError: ' + Name);
    except
      on EDenseMatrixError do ;
    end;
    AssertTrue('destination unchanged: ' + Name,
      SameBits(Destination, Expected));
  end;

begin
  A := DoubleMatrix(80, 60, 1.0);
  B := DoubleMatrix(60, 70, 2.0);
  Destination := TDenseDoubleMatrix.Zeros(80, 70);
  Destination[0, 0] := 12345.0;
  Destination[79, 69] := -6789.0;
  Expected := Destination.Clone;
  Expect('zero workers', A, B, Destination, 0, 32);
  Expect('negative workers', A, B, Destination, -2, 32);
  Expect('too many workers', A, B, Destination,
    DENSE_PARALLEL_MAX_WORKERS + 1, 32);
  Expect('zero block', A, B, Destination, 4, 0);
  Expect('negative block', A, B, Destination, 4, -8);
  Expect('nil left', nil, B, Destination, 4, 32);
  Expect('nil right', A, nil, Destination, 4, 32);
  Expect('nil destination', A, B, nil, 4, 32);
  Expect('inner mismatch', A, DoubleMatrix(59, 70, 2.0), Destination, 4, 32);
  Wrong := TDenseDoubleMatrix.Zeros(80, 69);
  Expect('destination shape', A, B, Wrong, 4, 32);
  A[40, 30] := NaN;
  Expect('non-finite left', A, B, Destination, 4, 32);
  A[40, 30] := 0.0;
  B[10, 69] := Infinity;
  Expect('non-finite right', A, B, Destination, 4, 32);

  Z := ComplexMatrix(4, 3, 0.0);
  ZB := ComplexMatrix(2, 4, 0.0);
  ZDestination := TDenseComplexMatrix.Zeros(4, 4);
  try
    MultiplyParallelInto(Z, ZB, ZDestination, 2);
    Fail('expected complex inner mismatch');
  except
    on EDenseMatrixError do ;
  end;
end;

procedure TParallelMultiplyTest.TestAliasedDestinationAndViews;
var
  A, B, Expected, BigA, BigB, BigDestination, ViewA, ViewB, ViewDestination,
    SerialDestination: IDenseDoubleMatrix;
begin
  A := DoubleMatrix(90, 90, 3.0);
  B := DoubleMatrix(90, 90, 7.0);
  Expected := TDenseDoubleMatrix.Zeros(90, 90);
  MultiplyBlockedInto(A, B, Expected);
  MultiplyParallelInto(A, B, A, 4);
  AssertTrue('destination aliases left operand', SameBits(A, Expected));

  A := DoubleMatrix(90, 90, 3.0);
  MultiplyParallelInto(A, B, B, 3);
  AssertTrue('destination aliases right operand', SameBits(B, Expected));

  BigA := DoubleMatrix(120, 100, 5.0);
  BigB := DoubleMatrix(100, 120, 6.0);
  BigDestination := TDenseDoubleMatrix.Zeros(130, 130);
  ViewA := BigA.View(7, 3, 101, 60);
  ViewB := BigB.View(11, 9, 60, 77);
  ViewDestination := BigDestination.View(13, 17, 101, 77);
  SerialDestination := TDenseDoubleMatrix.Zeros(101, 77);
  MultiplyBlockedInto(ViewA, ViewB, SerialDestination, 9);
  MultiplyParallelInto(ViewA, ViewB, ViewDestination, 6, 9);
  AssertTrue('strided views', SameBits(SerialDestination, ViewDestination));
  AssertEquals('outside view untouched', 0.0, BigDestination[12, 17]);
  AssertEquals('outside view untouched', 0.0, BigDestination[13, 16]);
end;

type
  TCallerThread = class(TThread)
  private
    FA, FB, FResult: IDenseDoubleMatrix;
    FWorkers, FRepeats: SizeInt;
    FError: string;
  protected
    procedure Execute; override;
  public
    constructor Create(const A, B: IDenseDoubleMatrix;
      const Workers, Repeats: SizeInt);
  end;

constructor TCallerThread.Create(const A, B: IDenseDoubleMatrix;
  const Workers, Repeats: SizeInt);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FA := A;
  FB := B;
  FWorkers := Workers;
  FRepeats := Repeats;
  FResult := TDenseDoubleMatrix.Zeros(A.Rows, B.Cols);
end;

procedure TCallerThread.Execute;
var
  R: SizeInt;
begin
  try
    for R := 1 to FRepeats do
      MultiplyParallelInto(FA, FB, FResult, FWorkers);
  except
    on E: Exception do
      FError := E.ClassName + ': ' + E.Message;
  end;
end;

procedure TParallelMultiplyTest.TestConcurrentCallers;
const
  CallerCount = 4;
var
  A, B, Expected: IDenseDoubleMatrix;
  Callers: array[0..CallerCount - 1] of TCallerThread;
  C: Integer;
begin
  A := DoubleMatrix(96, 80, 8.0);
  B := DoubleMatrix(80, 72, 9.0);
  Expected := TDenseDoubleMatrix.Zeros(96, 72);
  MultiplyBlockedInto(A, B, Expected);
  for C := 0 to CallerCount - 1 do
    Callers[C] := nil;
  try
    // The callers share read-only operands and each owns its destination.
    for C := 0 to CallerCount - 1 do
      Callers[C] := TCallerThread.Create(A, B, 2 + C, 3);
    for C := 0 to CallerCount - 1 do
      Callers[C].Start;
    for C := 0 to CallerCount - 1 do
      Callers[C].WaitFor;
    for C := 0 to CallerCount - 1 do
    begin
      AssertEquals('caller error', '', Callers[C].FError);
      AssertTrue('caller result', SameBits(Expected, Callers[C].FResult));
    end;
  finally
    for C := 0 to CallerCount - 1 do
      Callers[C].Free;
  end;
end;

function RaisedClass(const Proc: TProcedure): string;
begin
  Result := '';
  try
    Proc();
  except
    on E: EMathError do
      Result := 'EMathError:' + E.ClassName;
    on E: Exception do
      Result := E.ClassName;
  end;
end;

{ Windows reports the hardware exception code, so serial and worker classes
  match. FPC's Linux SIGFPE handler instead classifies from sticky status
  flags (x87 first), which earlier x87 work in the calling thread can leave
  set; a fresh worker may therefore report EOverflow where the caller reports
  EInvalidOp. Both are EMathError, which is the portable contract. }
procedure AssertSameMathFailure(const Name, SerialClass,
  ParallelClass: string; const ExpectRaise: Boolean);
begin
  if not ExpectRaise then
  begin
    TAssert.AssertEquals(Name + ' serial', '', SerialClass);
    TAssert.AssertEquals(Name + ' parallel', '', ParallelClass);
    Exit;
  end;
  TAssert.AssertEquals(Name + ' serial is a math error', 'EMathError:',
    Copy(SerialClass, 1, 11));
  TAssert.AssertEquals(Name + ' parallel is a math error', 'EMathError:',
    Copy(ParallelClass, 1, 11));
{$IFDEF MSWINDOWS}
  TAssert.AssertEquals(Name + ' same class', SerialClass, ParallelClass);
{$ENDIF}
end;

var
  OverflowA, OverflowB, OverflowDestination: IDenseDoubleMatrix;
  OverflowSA, OverflowSB, OverflowSDestination: IDenseSingleMatrix;

procedure SerialDoubleOverflow;
begin
  MultiplyBlockedInto(OverflowA, OverflowB, OverflowDestination);
end;

procedure ParallelDoubleOverflow;
begin
  MultiplyParallelInto(OverflowA, OverflowB, OverflowDestination, 4);
end;

procedure SerialSingleOverflow;
begin
  MultiplyBlockedInto(OverflowSA, OverflowSB, OverflowSDestination);
end;

procedure ParallelSingleOverflow;
begin
  MultiplyParallelInto(OverflowSA, OverflowSB, OverflowSDestination, 4);
end;

procedure TParallelMultiplyTest.TestWorkerExceptionsPropagate;
var
  SerialClass, ParallelClass: string;
  ExpectRaise: Boolean;
  J, Round: SizeInt;
  MaskBefore: TFPUExceptionMask;
  Caller: TCallerThread;
begin
  MaskBefore := GetExceptionMask;
  ExpectRaise := not (exOverflow in MaskBefore);
  // A caller thread may run with different FPU masks. Its workers must not
  // change the process-wide FPU defaults that the RTL restores after an
  // exception in this thread.
  Caller := TCallerThread.Create(DoubleMatrix(96, 80, 1.0),
    DoubleMatrix(80, 72, 2.0), 3, 1);
  try
    Caller.Start;
    Caller.WaitFor;
    AssertEquals('caller thread error', '', Caller.FError);
  finally
    Caller.Free;
  end;
  for Round := 1 to 2 do
  begin
  // Finite inputs whose products overflow only in the last rows, which a
  // worker thread (not the calling thread) computes.
  OverflowA := DoubleMatrix(80, 64, 1.0);
  OverflowB := DoubleMatrix(64, 64, 2.0);
  for J := 0 to 63 do
  begin
    OverflowA[79, J] := 1.0E300;
    OverflowB[J, 5] := 1.0E300;
  end;
  OverflowDestination := TDenseDoubleMatrix.Zeros(80, 64);
  SerialClass := RaisedClass(@SerialDoubleOverflow);
  ParallelClass := RaisedClass(@ParallelDoubleOverflow);
  AssertSameMathFailure('double overflow', SerialClass, ParallelClass,
    ExpectRaise);

  OverflowSA := SingleMatrix(80, 64, 1.0);
  OverflowSB := SingleMatrix(64, 64, 2.0);
  for J := 0 to 63 do
  begin
    OverflowSA[78, J] := 1.0E30;
    OverflowSB[J, 3] := 1.0E30;
  end;
  OverflowSDestination := TDenseSingleMatrix.Zeros(80, 64);
  SerialClass := RaisedClass(@SerialSingleOverflow);
  ParallelClass := RaisedClass(@ParallelSingleOverflow);
  AssertSameMathFailure('single overflow', SerialClass, ParallelClass,
    ExpectRaise);
  AssertTrue('caller exception mask unchanged',
    GetExceptionMask = MaskBefore);
  end;
  OverflowA := nil; OverflowB := nil; OverflowDestination := nil;
  OverflowSA := nil; OverflowSB := nil; OverflowSDestination := nil;
end;

procedure TParallelMultiplyTest.TestWorkersInheritRoundingMode;
var
  A, B, Nearest, Serial, Parallel: IDenseDoubleMatrix;
  Previous: TFPURoundingMode;
begin
  A := DoubleMatrix(120, 70, 0.3);
  B := DoubleMatrix(70, 60, 0.9);
  Nearest := TDenseDoubleMatrix.Zeros(120, 60);
  Serial := TDenseDoubleMatrix.Zeros(120, 60);
  Parallel := TDenseDoubleMatrix.Zeros(120, 60);
  MultiplyBlockedInto(A, B, Nearest);
  Previous := SetRoundMode(rmUp);
  try
    MultiplyBlockedInto(A, B, Serial);
    MultiplyParallelInto(A, B, Parallel, 6);
  finally
    SetRoundMode(Previous);
  end;
  AssertFalse('rounding mode changes the serial result',
    SameBits(Nearest, Serial));
  AssertTrue('workers use the caller rounding mode',
    SameBits(Serial, Parallel));
end;

initialization
  RegisterTest(TParallelMultiplyTest);

end.
