program ParallelMultiplyEvidence;

{ v2.15.0 large-product evidence. One process measures one shape, scalar kind
  and requested worker count so that its peak memory is not shared with other
  runs. It times the serial blocked kernel and MultiplyParallelInto (best of
  Repeats), checks the parallel result bitwise against the serial one, and
  measures the largest difference from the portable MultiplyInto oracle.

  Usage: ParallelMultiplyEvidence <double|complex> <rows> <inner> <cols>
           <workers> <repeats>

  Define MFP_NO_THREAD_MANAGER to omit cthreads on Unix and observe the
  explicit serial fallback. }

{$mode objfpc}{$H+}{$J-}

uses
  {$IFDEF UNIX}{$IFNDEF MFP_NO_THREAD_MANAGER}cthreads,{$ENDIF}{$ENDIF}
  {$IFDEF WINDOWS}Windows,{$ELSE}Unix,{$ENDIF}
  SysUtils, Math, MathBase.Complex, AlgebraLib.DenseMatrices,
  AlgebraLib.DenseKernels;

{$IFDEF WINDOWS}
type
  TProcessMemoryCounters = record
    cb: DWORD;
    PageFaultCount: DWORD;
    PeakWorkingSetSize: SizeUInt;
    WorkingSetSize: SizeUInt;
    QuotaPeakPagedPoolUsage: SizeUInt;
    QuotaPagedPoolUsage: SizeUInt;
    QuotaPeakNonPagedPoolUsage: SizeUInt;
    QuotaNonPagedPoolUsage: SizeUInt;
    PagefileUsage: SizeUInt;
    PeakPagefileUsage: SizeUInt;
  end;

function K32GetProcessMemoryInfo(Process: THandle;
  var Counters: TProcessMemoryCounters; Size: DWORD): BOOL; stdcall;
  external 'kernel32.dll';

function PeakResidentBytes: QWord;
var
  Counters: TProcessMemoryCounters;
begin
  FillChar(Counters, SizeOf(Counters), 0);
  Counters.cb := SizeOf(Counters);
  if K32GetProcessMemoryInfo(GetCurrentProcess, Counters, SizeOf(Counters)) then
    Result := Counters.PeakWorkingSetSize
  else
    Result := 0;
end;
{$ELSE}
function PeakResidentBytes: QWord;
var
  Status: TextFile;
  Line: string;
  Value: QWord;
begin
  Result := 0;
  AssignFile(Status, '/proc/self/status');
  {$I-}Reset(Status);{$I+}
  if IOResult <> 0 then
    Exit;
  try
    while not Eof(Status) do
    begin
      ReadLn(Status, Line);
      if Copy(Line, 1, 6) = 'VmHWM:' then
      begin
        Line := Trim(Copy(Line, 7, Length(Line)));
        Line := Trim(Copy(Line, 1, Pos(' ', Line + ' ') - 1));
        if TryStrToQWord(Line, Value) then
          Result := Value * 1024;
      end;
    end;
  finally
    CloseFile(Status);
  end;
end;
{$ENDIF}

function ReadCounter: Int64;
{$IFDEF WINDOWS}
begin
  QueryPerformanceCounter(Result);
end;
{$ELSE}
var
  CurrentTime: TTimeVal;
begin
  fpgettimeofday(@CurrentTime, nil);
  Result := Int64(CurrentTime.tv_sec) * 1000000 + CurrentTime.tv_usec;
end;
{$ENDIF}

function ElapsedMilliseconds(const Started: Int64): Double;
{$IFDEF WINDOWS}
var
  Frequency: Int64;
begin
  QueryPerformanceFrequency(Frequency);
  Result := 1000.0 * (ReadCounter - Started) / Frequency;
end;
{$ELSE}
begin
  Result := (ReadCounter - Started) / 1000.0;
end;
{$ENDIF}

procedure Report(const Scalar: string; const Rows, Inner, Cols, Workers,
  Repeats: SizeInt; const SerialMs, ParallelMs: Double;
  const Bitwise: Boolean; const MaxOracleDifference, OracleScale: Double;
  const LogicalBytes: QWord);
begin
  Writeln('PARALLEL|scalar=', Scalar,
    '|shape=', Rows, 'x', Inner, 'x', Cols,
    '|requested_workers=', Workers,
    '|effective_workers=', EffectiveMultiplyWorkers(Rows, Inner, Cols, Workers),
    '|threading_available=', LowerCase(BoolToStr(DenseThreadingAvailable, True)),
    '|cpu_count=', GetCPUCount,
    '|repeats=', Repeats,
    '|serial_ms=', SerialMs:0:3,
    '|parallel_ms=', ParallelMs:0:3,
    '|bitwise_equal=', LowerCase(BoolToStr(Bitwise, True)),
    '|max_abs_difference_vs_portable=', MaxOracleDifference:0:20,
    '|max_abs_portable_value=', OracleScale:0:6,
    '|logical_bytes=', LogicalBytes,
    '|peak_resident_bytes=', PeakResidentBytes);
end;

procedure RunDouble(const Rows, Inner, Cols, Workers, Repeats: SizeInt);
var
  A, B, Serial, Parallel, Portable: IDenseDoubleMatrix;
  I, J, R: SizeInt;
  Started: Int64;
  SerialMs, ParallelMs, Elapsed, Difference, Scale: Double;
  Bitwise: Boolean;
  X, Y: Double;
begin
  A := TDenseDoubleMatrix.Zeros(Rows, Inner);
  B := TDenseDoubleMatrix.Zeros(Inner, Cols);
  for I := 0 to Rows - 1 do
    for J := 0 to Inner - 1 do
      A[I, J] := Sin((I + 1) * 0.01 + (J + 1) * 0.03);
  for I := 0 to Inner - 1 do
    for J := 0 to Cols - 1 do
      B[I, J] := Cos((I + 1) * 0.02 - (J + 1) * 0.01);
  Serial := TDenseDoubleMatrix.Zeros(Rows, Cols);
  Parallel := TDenseDoubleMatrix.Zeros(Rows, Cols);
  Portable := TDenseDoubleMatrix.Zeros(Rows, Cols);
  SerialMs := Infinity;
  ParallelMs := Infinity;
  for R := 1 to Repeats do
  begin
    Started := ReadCounter;
    MultiplyBlockedInto(A, B, Serial);
    Elapsed := ElapsedMilliseconds(Started);
    if Elapsed < SerialMs then SerialMs := Elapsed;
    Started := ReadCounter;
    MultiplyParallelInto(A, B, Parallel, Workers);
    Elapsed := ElapsedMilliseconds(Started);
    if Elapsed < ParallelMs then ParallelMs := Elapsed;
  end;
  MultiplyInto(A, B, Portable);
  Bitwise := True;
  Difference := 0.0;
  Scale := 0.0;
  for I := 0 to Rows - 1 do
    for J := 0 to Cols - 1 do
    begin
      X := Serial[I, J];
      Y := Parallel[I, J];
      if not CompareMem(@X, @Y, SizeOf(Double)) then
        Bitwise := False;
      Difference := Max(Difference, Abs(Y - Portable[I, J]));
      Scale := Max(Scale, Abs(Portable[I, J]));
    end;
  Report('double', Rows, Inner, Cols, Workers, Repeats, SerialMs, ParallelMs,
    Bitwise, Difference, Scale,
    QWord(Rows * Inner + Inner * Cols + 3 * Rows * Cols) * SizeOf(Double));
end;

procedure RunComplex(const Rows, Inner, Cols, Workers, Repeats: SizeInt);
var
  A, B, Serial, Parallel, Portable: IDenseComplexMatrix;
  I, J, R: SizeInt;
  Started: Int64;
  SerialMs, ParallelMs, Elapsed, Difference, Scale: Double;
  Bitwise: Boolean;
  X, Y: TComplex;
begin
  A := TDenseComplexMatrix.Zeros(Rows, Inner);
  B := TDenseComplexMatrix.Zeros(Inner, Cols);
  for I := 0 to Rows - 1 do
    for J := 0 to Inner - 1 do
      A[I, J] := TComplex.Create(Sin((I + 1) * 0.01 + (J + 1) * 0.03),
        Cos((I + 1) * 0.05 - (J + 1) * 0.02));
  for I := 0 to Inner - 1 do
    for J := 0 to Cols - 1 do
      B[I, J] := TComplex.Create(Cos((I + 1) * 0.02 - (J + 1) * 0.01),
        Sin((I + 1) * 0.04 + (J + 1) * 0.07));
  Serial := TDenseComplexMatrix.Zeros(Rows, Cols);
  Parallel := TDenseComplexMatrix.Zeros(Rows, Cols);
  Portable := TDenseComplexMatrix.Zeros(Rows, Cols);
  SerialMs := Infinity;
  ParallelMs := Infinity;
  for R := 1 to Repeats do
  begin
    Started := ReadCounter;
    MultiplyBlockedInto(A, B, Serial);
    Elapsed := ElapsedMilliseconds(Started);
    if Elapsed < SerialMs then SerialMs := Elapsed;
    Started := ReadCounter;
    MultiplyParallelInto(A, B, Parallel, Workers);
    Elapsed := ElapsedMilliseconds(Started);
    if Elapsed < ParallelMs then ParallelMs := Elapsed;
  end;
  MultiplyInto(A, B, Portable);
  Bitwise := True;
  Difference := 0.0;
  Scale := 0.0;
  for I := 0 to Rows - 1 do
    for J := 0 to Cols - 1 do
    begin
      X := Serial[I, J];
      Y := Parallel[I, J];
      if not (CompareMem(@X.Re, @Y.Re, SizeOf(Double)) and
        CompareMem(@X.Im, @Y.Im, SizeOf(Double))) then
        Bitwise := False;
      Difference := Max(Difference,
        Max(Abs(Y.Re - Portable[I, J].Re), Abs(Y.Im - Portable[I, J].Im)));
      Scale := Max(Scale,
        Max(Abs(Portable[I, J].Re), Abs(Portable[I, J].Im)));
    end;
  Report('complex', Rows, Inner, Cols, Workers, Repeats, SerialMs, ParallelMs,
    Bitwise, Difference, Scale,
    QWord(Rows * Inner + Inner * Cols + 3 * Rows * Cols) * SizeOf(TComplex));
end;

var
  Rows, Inner, Cols, Workers, Repeats: SizeInt;
begin
  if ParamCount <> 6 then
  begin
    Writeln(StdErr, 'usage: ParallelMultiplyEvidence <double|complex> ',
      '<rows> <inner> <cols> <workers> <repeats>');
    Halt(2);
  end;
  Rows := StrToInt(ParamStr(2));
  Inner := StrToInt(ParamStr(3));
  Cols := StrToInt(ParamStr(4));
  Workers := StrToInt(ParamStr(5));
  Repeats := StrToInt(ParamStr(6));
  if Repeats < 1 then
    Halt(2);
  if ParamStr(1) = 'double' then
    RunDouble(Rows, Inner, Cols, Workers, Repeats)
  else if ParamStr(1) = 'complex' then
    RunComplex(Rows, Inner, Cols, Workers, Repeats)
  else
    Halt(2);
end.
