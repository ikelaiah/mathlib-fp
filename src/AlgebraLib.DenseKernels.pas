unit AlgebraLib.DenseKernels;

{-----------------------------------------------------------------------------
 AlgebraLib.DenseKernels

 Allocation-conscious Level-1/2/3-style operations for the typed dense matrix
 handles. Allocating functions have matching ...Into procedures. Into
 destinations must already have the exact result shape. Every procedure
 validates all operands before the first destination write. Non-overlapping
 operations write directly into the caller destination; shared backing storage
 is detected conservatively and uses a temporary so overlapping views remain
 deterministic.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  SysUtils, Math, MathBase.Complex, AlgebraLib.DenseMatrices;

type
  TDenseMultiplyPath = (dmpPortable, dmpBlocked);

const
  DENSE_MULTIPLY_BLOCK_SIZE = 32;
  DENSE_MULTIPLY_AUTO_THRESHOLD = 131072;

type
  TSingleUnaryKernel = function(const Value: Single): Single;
  TDoubleUnaryKernel = function(const Value: Double): Double;
  TSingleComplexUnaryKernel = function(
    const Value: TSingleComplex): TSingleComplex;
  TComplexUnaryKernel = function(const Value: TComplex): TComplex;

procedure CopyInto(const A, Destination: IDenseSingleMatrix); overload;
procedure CopyInto(const A, Destination: IDenseDoubleMatrix); overload;
procedure CopyInto(const A, Destination:
  IDenseSingleComplexMatrix); overload;
procedure CopyInto(const A, Destination: IDenseComplexMatrix); overload;

function Add(const A, B: IDenseSingleMatrix): IDenseSingleMatrix; overload;
function Add(const A, B: IDenseDoubleMatrix): IDenseDoubleMatrix; overload;
function Add(const A, B: IDenseSingleComplexMatrix):
  IDenseSingleComplexMatrix; overload;
function Add(const A, B: IDenseComplexMatrix): IDenseComplexMatrix; overload;
procedure AddInto(const A, B, Destination: IDenseSingleMatrix); overload;
procedure AddInto(const A, B, Destination: IDenseDoubleMatrix); overload;
procedure AddInto(const A, B, Destination: IDenseSingleComplexMatrix); overload;
procedure AddInto(const A, B, Destination: IDenseComplexMatrix); overload;

function Subtract(const A, B: IDenseSingleMatrix): IDenseSingleMatrix; overload;
function Subtract(const A, B: IDenseDoubleMatrix): IDenseDoubleMatrix; overload;
function Subtract(const A, B: IDenseSingleComplexMatrix):
  IDenseSingleComplexMatrix; overload;
function Subtract(const A, B: IDenseComplexMatrix):
  IDenseComplexMatrix; overload;
procedure SubtractInto(const A, B, Destination: IDenseSingleMatrix); overload;
procedure SubtractInto(const A, B, Destination: IDenseDoubleMatrix); overload;
procedure SubtractInto(const A, B, Destination:
  IDenseSingleComplexMatrix); overload;
procedure SubtractInto(const A, B, Destination: IDenseComplexMatrix); overload;

function ElementWiseMultiply(const A, B: IDenseSingleMatrix):
  IDenseSingleMatrix; overload;
function ElementWiseMultiply(const A, B: IDenseDoubleMatrix):
  IDenseDoubleMatrix; overload;
function ElementWiseMultiply(const A, B: IDenseSingleComplexMatrix):
  IDenseSingleComplexMatrix; overload;
function ElementWiseMultiply(const A, B: IDenseComplexMatrix):
  IDenseComplexMatrix; overload;
procedure ElementWiseMultiplyInto(const A, B, Destination:
  IDenseSingleMatrix); overload;
procedure ElementWiseMultiplyInto(const A, B, Destination:
  IDenseDoubleMatrix); overload;
procedure ElementWiseMultiplyInto(const A, B, Destination:
  IDenseSingleComplexMatrix); overload;
procedure ElementWiseMultiplyInto(const A, B, Destination:
  IDenseComplexMatrix); overload;

function Scale(const A: IDenseSingleMatrix; const Scalar: Single):
  IDenseSingleMatrix; overload;
function Scale(const A: IDenseDoubleMatrix; const Scalar: Double):
  IDenseDoubleMatrix; overload;
function Scale(const A: IDenseSingleComplexMatrix;
  const Scalar: TSingleComplex): IDenseSingleComplexMatrix; overload;
function Scale(const A: IDenseComplexMatrix; const Scalar: TComplex):
  IDenseComplexMatrix; overload;
procedure ScaleInto(const A, Destination: IDenseSingleMatrix;
  const Scalar: Single); overload;
procedure ScaleInto(const A, Destination: IDenseDoubleMatrix;
  const Scalar: Double); overload;
procedure ScaleInto(const A, Destination: IDenseSingleComplexMatrix;
  const Scalar: TSingleComplex); overload;
procedure ScaleInto(const A, Destination: IDenseComplexMatrix;
  const Scalar: TComplex); overload;

function Axpy(const Alpha: Single; const X, Y: IDenseSingleMatrix):
  IDenseSingleMatrix; overload;
function Axpy(const Alpha: Double; const X, Y: IDenseDoubleMatrix):
  IDenseDoubleMatrix; overload;
function Axpy(const Alpha: TSingleComplex;
  const X, Y: IDenseSingleComplexMatrix):
  IDenseSingleComplexMatrix; overload;
function Axpy(const Alpha: TComplex; const X, Y: IDenseComplexMatrix):
  IDenseComplexMatrix; overload;
procedure AxpyInto(const Alpha: Single;
  const X, Y, Destination: IDenseSingleMatrix); overload;
procedure AxpyInto(const Alpha: Double;
  const X, Y, Destination: IDenseDoubleMatrix); overload;
procedure AxpyInto(const Alpha: TSingleComplex;
  const X, Y, Destination: IDenseSingleComplexMatrix); overload;
procedure AxpyInto(const Alpha: TComplex;
  const X, Y, Destination: IDenseComplexMatrix); overload;

function Apply(const A: IDenseSingleMatrix;
  const Operation: TSingleUnaryKernel): IDenseSingleMatrix; overload;
function Apply(const A: IDenseDoubleMatrix;
  const Operation: TDoubleUnaryKernel): IDenseDoubleMatrix; overload;
function Apply(const A: IDenseSingleComplexMatrix;
  const Operation: TSingleComplexUnaryKernel):
  IDenseSingleComplexMatrix; overload;
function Apply(const A: IDenseComplexMatrix;
  const Operation: TComplexUnaryKernel): IDenseComplexMatrix; overload;
procedure ApplyInto(const A, Destination: IDenseSingleMatrix;
  const Operation: TSingleUnaryKernel); overload;
procedure ApplyInto(const A, Destination: IDenseDoubleMatrix;
  const Operation: TDoubleUnaryKernel); overload;
procedure ApplyInto(const A, Destination: IDenseSingleComplexMatrix;
  const Operation: TSingleComplexUnaryKernel); overload;
procedure ApplyInto(const A, Destination: IDenseComplexMatrix;
  const Operation: TComplexUnaryKernel); overload;

function Transpose(const A: IDenseSingleMatrix): IDenseSingleMatrix; overload;
function Transpose(const A: IDenseDoubleMatrix): IDenseDoubleMatrix; overload;
function Transpose(const A: IDenseSingleComplexMatrix):
  IDenseSingleComplexMatrix; overload;
function Transpose(const A: IDenseComplexMatrix): IDenseComplexMatrix; overload;
procedure TransposeInto(const A, Destination: IDenseSingleMatrix); overload;
procedure TransposeInto(const A, Destination: IDenseDoubleMatrix); overload;
procedure TransposeInto(const A, Destination:
  IDenseSingleComplexMatrix); overload;
procedure TransposeInto(const A, Destination: IDenseComplexMatrix); overload;

function Conjugate(const A: IDenseSingleComplexMatrix):
  IDenseSingleComplexMatrix; overload;
function Conjugate(const A: IDenseComplexMatrix): IDenseComplexMatrix; overload;
procedure ConjugateInto(const A, Destination:
  IDenseSingleComplexMatrix); overload;
procedure ConjugateInto(const A, Destination: IDenseComplexMatrix); overload;
function ConjugateTranspose(const A: IDenseSingleComplexMatrix):
  IDenseSingleComplexMatrix; overload;
function ConjugateTranspose(const A: IDenseComplexMatrix):
  IDenseComplexMatrix; overload;
procedure ConjugateTransposeInto(const A, Destination:
  IDenseSingleComplexMatrix); overload;
procedure ConjugateTransposeInto(const A, Destination:
  IDenseComplexMatrix); overload;

function Multiply(const A, B: IDenseSingleMatrix): IDenseSingleMatrix; overload;
function Multiply(const A, B: IDenseDoubleMatrix): IDenseDoubleMatrix; overload;
function Multiply(const A, B: IDenseSingleComplexMatrix):
  IDenseSingleComplexMatrix; overload;
function Multiply(const A, B: IDenseComplexMatrix):
  IDenseComplexMatrix; overload;
procedure MultiplyInto(const A, B, Destination: IDenseSingleMatrix); overload;
procedure MultiplyInto(const A, B, Destination: IDenseDoubleMatrix); overload;
procedure MultiplyInto(const A, B, Destination:
  IDenseSingleComplexMatrix); overload;
procedure MultiplyInto(const A, B, Destination: IDenseComplexMatrix); overload;
procedure MultiplyBlockedInto(const A, B, Destination:
  IDenseSingleMatrix; const BlockSize: SizeInt =
  DENSE_MULTIPLY_BLOCK_SIZE); overload;
procedure MultiplyBlockedInto(const A, B, Destination:
  IDenseDoubleMatrix; const BlockSize: SizeInt =
  DENSE_MULTIPLY_BLOCK_SIZE); overload;
procedure MultiplyBlockedInto(const A, B, Destination:
  IDenseSingleComplexMatrix; const BlockSize: SizeInt =
  DENSE_MULTIPLY_BLOCK_SIZE); overload;
procedure MultiplyBlockedInto(const A, B, Destination:
  IDenseComplexMatrix; const BlockSize: SizeInt =
  DENSE_MULTIPLY_BLOCK_SIZE); overload;
procedure MultiplyAutoInto(const A, B, Destination:
  IDenseSingleMatrix); overload;
procedure MultiplyAutoInto(const A, B, Destination:
  IDenseDoubleMatrix); overload;
procedure MultiplyAutoInto(const A, B, Destination:
  IDenseSingleComplexMatrix); overload;
procedure MultiplyAutoInto(const A, B, Destination:
  IDenseComplexMatrix); overload;
function SelectedMultiplyPath(const Rows, InnerDimension,
  Columns: SizeInt): TDenseMultiplyPath;

function Dot(const A, B: IDenseSingleMatrix): Single; overload;
function Dot(const A, B: IDenseDoubleMatrix): Double; overload;
function Dot(const A, B: IDenseSingleComplexMatrix): TSingleComplex; overload;
function Dot(const A, B: IDenseComplexMatrix): TComplex; overload;
function DotConjugate(const A, B: IDenseSingleComplexMatrix):
  TSingleComplex; overload;
function DotConjugate(const A, B: IDenseComplexMatrix): TComplex; overload;
function Sum(const A: IDenseSingleMatrix): Single; overload;
function Sum(const A: IDenseDoubleMatrix): Double; overload;
function Sum(const A: IDenseSingleComplexMatrix): TSingleComplex; overload;
function Sum(const A: IDenseComplexMatrix): TComplex; overload;
function Norm2(const A: IDenseSingleMatrix): Single; overload;
function Norm2(const A: IDenseDoubleMatrix): Double; overload;
function Norm2(const A: IDenseSingleComplexMatrix): Single; overload;
function Norm2(const A: IDenseComplexMatrix): Double; overload;

implementation

procedure RequireAssigned(const AssignedValue: Boolean; const Operation: string);
begin
  if not AssignedValue then
    raise EDenseMatrixError.Create(Operation + ': matrix handle must not be nil.');
end;

generic procedure RequireSameShape<T>(const A, B: specialize IDenseMatrix<T>;
  const Operation: string);
begin
  RequireAssigned((A <> nil) and (B <> nil), Operation);
  if (A.Rows <> B.Rows) or (A.Cols <> B.Cols) then
    raise EDenseMatrixError.CreateFmt(
      '%s: matrix shapes must match; got %d x %d and %d x %d.',
      [Operation, A.Rows, A.Cols, B.Rows, B.Cols]);
end;

generic procedure RequireDestinationShape<T>(
  const Destination: specialize IDenseMatrix<T>; const Rows, Cols: SizeInt;
  const Operation: string);
begin
  RequireAssigned(Destination <> nil, Operation);
  if (Destination.Rows <> Rows) or (Destination.Cols <> Cols) then
    raise EDenseMatrixError.CreateFmt(
      '%s: destination shape must be %d x %d; got %d x %d.',
      [Operation, Rows, Cols, Destination.Rows, Destination.Cols]);
end;

procedure RequireFinite(const A: IDenseSingleMatrix; const Operation: string);
var
  R, C: SizeInt;
begin
  RequireAssigned(A <> nil, Operation);
  for R := 0 to A.Rows - 1 do
    for C := 0 to A.Cols - 1 do
      if IsNan(A[R, C]) or IsInfinite(A[R, C]) then
        raise EDenseMatrixError.CreateFmt(
          '%s: element [%d,%d] must be finite.', [Operation, R, C]);
end;

procedure RequireFinite(const A: IDenseDoubleMatrix;
  const Operation: string);
var
  R, C: SizeInt;
begin
  RequireAssigned(A <> nil, Operation);
  for R := 0 to A.Rows - 1 do
    for C := 0 to A.Cols - 1 do
      if IsNan(A[R, C]) or IsInfinite(A[R, C]) then
        raise EDenseMatrixError.CreateFmt(
          '%s: element [%d,%d] must be finite.', [Operation, R, C]);
end;

procedure RequireFinite(const A: IDenseSingleComplexMatrix;
  const Operation: string);
var
  R, C: SizeInt;
begin
  RequireAssigned(A <> nil, Operation);
  for R := 0 to A.Rows - 1 do
    for C := 0 to A.Cols - 1 do
      if not A[R, C].IsFinite then
        raise EDenseMatrixError.CreateFmt(
          '%s: element [%d,%d] must be finite.', [Operation, R, C]);
end;

procedure RequireFinite(const A: IDenseComplexMatrix;
  const Operation: string);
var
  R, C: SizeInt;
begin
  RequireAssigned(A <> nil, Operation);
  for R := 0 to A.Rows - 1 do
    for C := 0 to A.Cols - 1 do
      if not A[R, C].IsFinite then
        raise EDenseMatrixError.CreateFmt(
          '%s: element [%d,%d] must be finite.', [Operation, R, C]);
end;

generic procedure CopyMatrix<T>(const Source, Destination:
  specialize IDenseMatrix<T>);
var
  R, C: SizeInt;
begin
  for R := 0 to Source.Rows - 1 do
    for C := 0 to Source.Cols - 1 do
      Destination[R, C] := Source[R, C];
end;

generic procedure CopyIntoImpl<T>(const A, Destination:
  specialize IDenseMatrix<T>);
var
  Source: specialize IDenseMatrix<T>;
begin
  if A = Destination then
    Exit;
  if Destination.StorageIdentity = A.StorageIdentity then
    Source := A.Clone
  else
    Source := A;
  specialize CopyMatrix<T>(Source, Destination);
end;

procedure CopyInto(const A, Destination: IDenseSingleMatrix);
begin
  RequireFinite(A, 'CopyInto(single)');
  specialize RequireDestinationShape<Single>(Destination, A.Rows, A.Cols,
    'CopyInto(single)');
  specialize CopyIntoImpl<Single>(A, Destination);
end;

procedure CopyInto(const A, Destination: IDenseDoubleMatrix);
begin
  RequireFinite(A, 'CopyInto(double)');
  specialize RequireDestinationShape<Double>(Destination, A.Rows, A.Cols,
    'CopyInto(double)');
  specialize CopyIntoImpl<Double>(A, Destination);
end;

procedure CopyInto(const A, Destination: IDenseSingleComplexMatrix);
begin
  RequireFinite(A, 'CopyInto(single complex)');
  specialize RequireDestinationShape<TSingleComplex>(Destination, A.Rows,
    A.Cols, 'CopyInto(single complex)');
  specialize CopyIntoImpl<TSingleComplex>(A, Destination);
end;

procedure CopyInto(const A, Destination: IDenseComplexMatrix);
begin
  RequireFinite(A, 'CopyInto(complex)');
  specialize RequireDestinationShape<TComplex>(Destination, A.Rows, A.Cols,
    'CopyInto(complex)');
  specialize CopyIntoImpl<TComplex>(A, Destination);
end;

generic procedure AddIntoImpl<T>(const A, B, Destination:
  specialize IDenseMatrix<T>);
var
  R, C: SizeInt;
  Work: specialize IDenseMatrix<T>;
begin
  if (Destination.StorageIdentity = A.StorageIdentity) or
     (Destination.StorageIdentity = B.StorageIdentity) then
    Work := Destination.Clone
  else
    Work := Destination;
  for R := 0 to A.Rows - 1 do
    for C := 0 to A.Cols - 1 do
      Work[R, C] := A[R, C] + B[R, C];
  if Work <> Destination then
    specialize CopyMatrix<T>(Work, Destination);
end;

generic procedure SubtractIntoImpl<T>(const A, B, Destination:
  specialize IDenseMatrix<T>);
var
  R, C: SizeInt;
  Work: specialize IDenseMatrix<T>;
begin
  if (Destination.StorageIdentity = A.StorageIdentity) or
     (Destination.StorageIdentity = B.StorageIdentity) then
    Work := Destination.Clone
  else
    Work := Destination;
  for R := 0 to A.Rows - 1 do
    for C := 0 to A.Cols - 1 do
      Work[R, C] := A[R, C] - B[R, C];
  if Work <> Destination then
    specialize CopyMatrix<T>(Work, Destination);
end;

generic procedure ElementWiseMultiplyIntoImpl<T>(const A, B, Destination:
  specialize IDenseMatrix<T>);
var
  R, C: SizeInt;
  Work: specialize IDenseMatrix<T>;
begin
  if (Destination.StorageIdentity = A.StorageIdentity) or
     (Destination.StorageIdentity = B.StorageIdentity) then
    Work := Destination.Clone
  else
    Work := Destination;
  for R := 0 to A.Rows - 1 do
    for C := 0 to A.Cols - 1 do
      Work[R, C] := A[R, C] * B[R, C];
  if Work <> Destination then
    specialize CopyMatrix<T>(Work, Destination);
end;

procedure AddInto(const A, B, Destination: IDenseSingleMatrix);
begin
  specialize RequireSameShape<Single>(A, B, 'AddInto(single)');
  specialize RequireDestinationShape<Single>(Destination, A.Rows, A.Cols,
    'AddInto(single)');
  RequireFinite(A, 'AddInto(single)');
  RequireFinite(B, 'AddInto(single)');
  specialize AddIntoImpl<Single>(A, B, Destination);
end;

procedure AddInto(const A, B, Destination: IDenseDoubleMatrix);
begin
  specialize RequireSameShape<Double>(A, B, 'AddInto(double)');
  specialize RequireDestinationShape<Double>(Destination, A.Rows, A.Cols,
    'AddInto(double)');
  RequireFinite(A, 'AddInto(double)');
  RequireFinite(B, 'AddInto(double)');
  specialize AddIntoImpl<Double>(A, B, Destination);
end;

procedure AddInto(const A, B, Destination: IDenseSingleComplexMatrix);
begin
  specialize RequireSameShape<TSingleComplex>(A, B,
    'AddInto(single complex)');
  specialize RequireDestinationShape<TSingleComplex>(Destination, A.Rows,
    A.Cols, 'AddInto(single complex)');
  RequireFinite(A, 'AddInto(single complex)');
  RequireFinite(B, 'AddInto(single complex)');
  specialize AddIntoImpl<TSingleComplex>(A, B, Destination);
end;

procedure AddInto(const A, B, Destination: IDenseComplexMatrix);
begin
  specialize RequireSameShape<TComplex>(A, B, 'AddInto(complex)');
  specialize RequireDestinationShape<TComplex>(Destination, A.Rows, A.Cols,
    'AddInto(complex)');
  RequireFinite(A, 'AddInto(complex)');
  RequireFinite(B, 'AddInto(complex)');
  specialize AddIntoImpl<TComplex>(A, B, Destination);
end;

function Add(const A, B: IDenseSingleMatrix): IDenseSingleMatrix;
begin
  specialize RequireSameShape<Single>(A, B, 'Add(single)');
  Result := TDenseSingleMatrix.Zeros(A.Rows, A.Cols);
  AddInto(A, B, Result);
end;

function Add(const A, B: IDenseDoubleMatrix): IDenseDoubleMatrix;
begin
  specialize RequireSameShape<Double>(A, B, 'Add(double)');
  Result := TDenseDoubleMatrix.Zeros(A.Rows, A.Cols);
  AddInto(A, B, Result);
end;

function Add(const A, B: IDenseSingleComplexMatrix):
  IDenseSingleComplexMatrix;
begin
  specialize RequireSameShape<TSingleComplex>(A, B, 'Add(single complex)');
  Result := TDenseSingleComplexMatrix.Zeros(A.Rows, A.Cols);
  AddInto(A, B, Result);
end;

function Add(const A, B: IDenseComplexMatrix): IDenseComplexMatrix;
begin
  specialize RequireSameShape<TComplex>(A, B, 'Add(complex)');
  Result := TDenseComplexMatrix.Zeros(A.Rows, A.Cols);
  AddInto(A, B, Result);
end;

procedure SubtractInto(const A, B, Destination: IDenseSingleMatrix);
begin
  specialize RequireSameShape<Single>(A, B, 'SubtractInto(single)');
  specialize RequireDestinationShape<Single>(Destination, A.Rows, A.Cols,
    'SubtractInto(single)');
  RequireFinite(A, 'SubtractInto(single)');
  RequireFinite(B, 'SubtractInto(single)');
  specialize SubtractIntoImpl<Single>(A, B, Destination);
end;

procedure SubtractInto(const A, B, Destination: IDenseDoubleMatrix);
begin
  specialize RequireSameShape<Double>(A, B, 'SubtractInto(double)');
  specialize RequireDestinationShape<Double>(Destination, A.Rows, A.Cols,
    'SubtractInto(double)');
  RequireFinite(A, 'SubtractInto(double)');
  RequireFinite(B, 'SubtractInto(double)');
  specialize SubtractIntoImpl<Double>(A, B, Destination);
end;

procedure SubtractInto(const A, B, Destination: IDenseSingleComplexMatrix);
begin
  specialize RequireSameShape<TSingleComplex>(A, B,
    'SubtractInto(single complex)');
  specialize RequireDestinationShape<TSingleComplex>(Destination, A.Rows,
    A.Cols, 'SubtractInto(single complex)');
  RequireFinite(A, 'SubtractInto(single complex)');
  RequireFinite(B, 'SubtractInto(single complex)');
  specialize SubtractIntoImpl<TSingleComplex>(A, B, Destination);
end;

procedure SubtractInto(const A, B, Destination: IDenseComplexMatrix);
begin
  specialize RequireSameShape<TComplex>(A, B, 'SubtractInto(complex)');
  specialize RequireDestinationShape<TComplex>(Destination, A.Rows, A.Cols,
    'SubtractInto(complex)');
  RequireFinite(A, 'SubtractInto(complex)');
  RequireFinite(B, 'SubtractInto(complex)');
  specialize SubtractIntoImpl<TComplex>(A, B, Destination);
end;

function Subtract(const A, B: IDenseSingleMatrix): IDenseSingleMatrix;
begin
  specialize RequireSameShape<Single>(A, B, 'Subtract(single)');
  Result := TDenseSingleMatrix.Zeros(A.Rows, A.Cols);
  SubtractInto(A, B, Result);
end;

function Subtract(const A, B: IDenseDoubleMatrix): IDenseDoubleMatrix;
begin
  specialize RequireSameShape<Double>(A, B, 'Subtract(double)');
  Result := TDenseDoubleMatrix.Zeros(A.Rows, A.Cols);
  SubtractInto(A, B, Result);
end;

function Subtract(const A, B: IDenseSingleComplexMatrix):
  IDenseSingleComplexMatrix;
begin
  specialize RequireSameShape<TSingleComplex>(A, B,
    'Subtract(single complex)');
  Result := TDenseSingleComplexMatrix.Zeros(A.Rows, A.Cols);
  SubtractInto(A, B, Result);
end;

function Subtract(const A, B: IDenseComplexMatrix): IDenseComplexMatrix;
begin
  specialize RequireSameShape<TComplex>(A, B, 'Subtract(complex)');
  Result := TDenseComplexMatrix.Zeros(A.Rows, A.Cols);
  SubtractInto(A, B, Result);
end;

procedure ElementWiseMultiplyInto(const A, B, Destination:
  IDenseSingleMatrix);
begin
  specialize RequireSameShape<Single>(A, B,
    'ElementWiseMultiplyInto(single)');
  specialize RequireDestinationShape<Single>(Destination, A.Rows, A.Cols,
    'ElementWiseMultiplyInto(single)');
  RequireFinite(A, 'ElementWiseMultiplyInto(single)');
  RequireFinite(B, 'ElementWiseMultiplyInto(single)');
  specialize ElementWiseMultiplyIntoImpl<Single>(A, B, Destination);
end;

procedure ElementWiseMultiplyInto(const A, B, Destination:
  IDenseDoubleMatrix);
begin
  specialize RequireSameShape<Double>(A, B,
    'ElementWiseMultiplyInto(double)');
  specialize RequireDestinationShape<Double>(Destination, A.Rows, A.Cols,
    'ElementWiseMultiplyInto(double)');
  RequireFinite(A, 'ElementWiseMultiplyInto(double)');
  RequireFinite(B, 'ElementWiseMultiplyInto(double)');
  specialize ElementWiseMultiplyIntoImpl<Double>(A, B, Destination);
end;

procedure ElementWiseMultiplyInto(const A, B, Destination:
  IDenseSingleComplexMatrix);
begin
  specialize RequireSameShape<TSingleComplex>(A, B,
    'ElementWiseMultiplyInto(single complex)');
  specialize RequireDestinationShape<TSingleComplex>(Destination, A.Rows,
    A.Cols, 'ElementWiseMultiplyInto(single complex)');
  RequireFinite(A, 'ElementWiseMultiplyInto(single complex)');
  RequireFinite(B, 'ElementWiseMultiplyInto(single complex)');
  specialize ElementWiseMultiplyIntoImpl<TSingleComplex>(A, B, Destination);
end;

procedure ElementWiseMultiplyInto(const A, B, Destination:
  IDenseComplexMatrix);
begin
  specialize RequireSameShape<TComplex>(A, B,
    'ElementWiseMultiplyInto(complex)');
  specialize RequireDestinationShape<TComplex>(Destination, A.Rows, A.Cols,
    'ElementWiseMultiplyInto(complex)');
  RequireFinite(A, 'ElementWiseMultiplyInto(complex)');
  RequireFinite(B, 'ElementWiseMultiplyInto(complex)');
  specialize ElementWiseMultiplyIntoImpl<TComplex>(A, B, Destination);
end;

function ElementWiseMultiply(const A, B: IDenseSingleMatrix):
  IDenseSingleMatrix;
begin
  specialize RequireSameShape<Single>(A, B, 'ElementWiseMultiply(single)');
  Result := TDenseSingleMatrix.Zeros(A.Rows, A.Cols);
  ElementWiseMultiplyInto(A, B, Result);
end;

function ElementWiseMultiply(const A, B: IDenseDoubleMatrix):
  IDenseDoubleMatrix;
begin
  specialize RequireSameShape<Double>(A, B, 'ElementWiseMultiply(double)');
  Result := TDenseDoubleMatrix.Zeros(A.Rows, A.Cols);
  ElementWiseMultiplyInto(A, B, Result);
end;

function ElementWiseMultiply(const A, B: IDenseSingleComplexMatrix):
  IDenseSingleComplexMatrix;
begin
  specialize RequireSameShape<TSingleComplex>(A, B,
    'ElementWiseMultiply(single complex)');
  Result := TDenseSingleComplexMatrix.Zeros(A.Rows, A.Cols);
  ElementWiseMultiplyInto(A, B, Result);
end;

function ElementWiseMultiply(const A, B: IDenseComplexMatrix):
  IDenseComplexMatrix;
begin
  specialize RequireSameShape<TComplex>(A, B,
    'ElementWiseMultiply(complex)');
  Result := TDenseComplexMatrix.Zeros(A.Rows, A.Cols);
  ElementWiseMultiplyInto(A, B, Result);
end;

procedure ScaleInto(const A, Destination: IDenseSingleMatrix;
  const Scalar: Single);
var
  R, C: SizeInt;
  Work: IDenseSingleMatrix;
begin
  RequireFinite(A, 'ScaleInto(single)');
  if IsNan(Scalar) or IsInfinite(Scalar) then
    raise EDenseMatrixError.Create('ScaleInto(single): scalar must be finite.');
  specialize RequireDestinationShape<Single>(Destination, A.Rows, A.Cols,
    'ScaleInto(single)');
  if Destination.StorageIdentity = A.StorageIdentity then
    Work := Destination.Clone
  else
    Work := Destination;
  for R := 0 to A.Rows - 1 do
    for C := 0 to A.Cols - 1 do
      Work[R, C] := A[R, C] * Scalar;
  if Work <> Destination then
    specialize CopyMatrix<Single>(Work, Destination);
end;

procedure ScaleInto(const A, Destination: IDenseDoubleMatrix;
  const Scalar: Double);
var
  R, C: SizeInt;
  Work: IDenseDoubleMatrix;
begin
  RequireFinite(A, 'ScaleInto(double)');
  if IsNan(Scalar) or IsInfinite(Scalar) then
    raise EDenseMatrixError.Create('ScaleInto(double): scalar must be finite.');
  specialize RequireDestinationShape<Double>(Destination, A.Rows, A.Cols,
    'ScaleInto(double)');
  if Destination.StorageIdentity = A.StorageIdentity then
    Work := Destination.Clone
  else
    Work := Destination;
  for R := 0 to A.Rows - 1 do
    for C := 0 to A.Cols - 1 do
      Work[R, C] := A[R, C] * Scalar;
  if Work <> Destination then
    specialize CopyMatrix<Double>(Work, Destination);
end;

procedure ScaleInto(const A, Destination: IDenseSingleComplexMatrix;
  const Scalar: TSingleComplex);
var
  R, C: SizeInt;
  Work: IDenseSingleComplexMatrix;
begin
  RequireFinite(A, 'ScaleInto(single complex)');
  if not Scalar.IsFinite then
    raise EDenseMatrixError.Create(
      'ScaleInto(single complex): scalar must be finite.');
  specialize RequireDestinationShape<TSingleComplex>(Destination, A.Rows,
    A.Cols, 'ScaleInto(single complex)');
  if Destination.StorageIdentity = A.StorageIdentity then
    Work := Destination.Clone
  else
    Work := Destination;
  for R := 0 to A.Rows - 1 do
    for C := 0 to A.Cols - 1 do
      Work[R, C] := A[R, C] * Scalar;
  if Work <> Destination then
    specialize CopyMatrix<TSingleComplex>(Work, Destination);
end;

procedure ScaleInto(const A, Destination: IDenseComplexMatrix;
  const Scalar: TComplex);
var
  R, C: SizeInt;
  Work: IDenseComplexMatrix;
begin
  RequireFinite(A, 'ScaleInto(complex)');
  if not Scalar.IsFinite then
    raise EDenseMatrixError.Create('ScaleInto(complex): scalar must be finite.');
  specialize RequireDestinationShape<TComplex>(Destination, A.Rows, A.Cols,
    'ScaleInto(complex)');
  if Destination.StorageIdentity = A.StorageIdentity then
    Work := Destination.Clone
  else
    Work := Destination;
  for R := 0 to A.Rows - 1 do
    for C := 0 to A.Cols - 1 do
      Work[R, C] := A[R, C] * Scalar;
  if Work <> Destination then
    specialize CopyMatrix<TComplex>(Work, Destination);
end;

function Scale(const A: IDenseSingleMatrix; const Scalar: Single):
  IDenseSingleMatrix;
begin
  RequireFinite(A, 'Scale(single)');
  Result := TDenseSingleMatrix.Zeros(A.Rows, A.Cols);
  ScaleInto(A, Result, Scalar);
end;

function Scale(const A: IDenseDoubleMatrix; const Scalar: Double):
  IDenseDoubleMatrix;
begin
  RequireFinite(A, 'Scale(double)');
  Result := TDenseDoubleMatrix.Zeros(A.Rows, A.Cols);
  ScaleInto(A, Result, Scalar);
end;

function Scale(const A: IDenseSingleComplexMatrix;
  const Scalar: TSingleComplex): IDenseSingleComplexMatrix;
begin
  RequireFinite(A, 'Scale(single complex)');
  Result := TDenseSingleComplexMatrix.Zeros(A.Rows, A.Cols);
  ScaleInto(A, Result, Scalar);
end;

function Scale(const A: IDenseComplexMatrix; const Scalar: TComplex):
  IDenseComplexMatrix;
begin
  RequireFinite(A, 'Scale(complex)');
  Result := TDenseComplexMatrix.Zeros(A.Rows, A.Cols);
  ScaleInto(A, Result, Scalar);
end;

generic procedure AxpyIntoImpl<T>(const Alpha: T; const X, Y, Destination:
  specialize IDenseMatrix<T>);
var
  R, C: SizeInt;
  Work: specialize IDenseMatrix<T>;
begin
  if (Destination.StorageIdentity = X.StorageIdentity) or
     (Destination.StorageIdentity = Y.StorageIdentity) then
    Work := Destination.Clone
  else
    Work := Destination;
  for R := 0 to X.Rows - 1 do
    for C := 0 to X.Cols - 1 do
      Work[R, C] := Alpha * X[R, C] + Y[R, C];
  if Work <> Destination then
    specialize CopyMatrix<T>(Work, Destination);
end;

procedure AxpyInto(const Alpha: Single;
  const X, Y, Destination: IDenseSingleMatrix);
begin
  specialize RequireSameShape<Single>(X, Y, 'AxpyInto(single)');
  specialize RequireDestinationShape<Single>(Destination, X.Rows, X.Cols,
    'AxpyInto(single)');
  RequireFinite(X, 'AxpyInto(single)');
  RequireFinite(Y, 'AxpyInto(single)');
  if IsNan(Alpha) or IsInfinite(Alpha) then
    raise EDenseMatrixError.Create('AxpyInto(single): alpha must be finite.');
  specialize AxpyIntoImpl<Single>(Alpha, X, Y, Destination);
end;

procedure AxpyInto(const Alpha: Double;
  const X, Y, Destination: IDenseDoubleMatrix);
begin
  specialize RequireSameShape<Double>(X, Y, 'AxpyInto(double)');
  specialize RequireDestinationShape<Double>(Destination, X.Rows, X.Cols,
    'AxpyInto(double)');
  RequireFinite(X, 'AxpyInto(double)');
  RequireFinite(Y, 'AxpyInto(double)');
  if IsNan(Alpha) or IsInfinite(Alpha) then
    raise EDenseMatrixError.Create('AxpyInto(double): alpha must be finite.');
  specialize AxpyIntoImpl<Double>(Alpha, X, Y, Destination);
end;

procedure AxpyInto(const Alpha: TSingleComplex;
  const X, Y, Destination: IDenseSingleComplexMatrix);
begin
  specialize RequireSameShape<TSingleComplex>(X, Y,
    'AxpyInto(single complex)');
  specialize RequireDestinationShape<TSingleComplex>(Destination, X.Rows,
    X.Cols, 'AxpyInto(single complex)');
  RequireFinite(X, 'AxpyInto(single complex)');
  RequireFinite(Y, 'AxpyInto(single complex)');
  if not Alpha.IsFinite then
    raise EDenseMatrixError.Create(
      'AxpyInto(single complex): alpha must be finite.');
  specialize AxpyIntoImpl<TSingleComplex>(Alpha, X, Y, Destination);
end;

procedure AxpyInto(const Alpha: TComplex;
  const X, Y, Destination: IDenseComplexMatrix);
begin
  specialize RequireSameShape<TComplex>(X, Y, 'AxpyInto(complex)');
  specialize RequireDestinationShape<TComplex>(Destination, X.Rows, X.Cols,
    'AxpyInto(complex)');
  RequireFinite(X, 'AxpyInto(complex)');
  RequireFinite(Y, 'AxpyInto(complex)');
  if not Alpha.IsFinite then
    raise EDenseMatrixError.Create('AxpyInto(complex): alpha must be finite.');
  specialize AxpyIntoImpl<TComplex>(Alpha, X, Y, Destination);
end;

function Axpy(const Alpha: Single; const X, Y: IDenseSingleMatrix):
  IDenseSingleMatrix;
begin
  specialize RequireSameShape<Single>(X, Y, 'Axpy(single)');
  Result := TDenseSingleMatrix.Zeros(X.Rows, X.Cols);
  AxpyInto(Alpha, X, Y, Result);
end;

function Axpy(const Alpha: Double; const X, Y: IDenseDoubleMatrix):
  IDenseDoubleMatrix;
begin
  specialize RequireSameShape<Double>(X, Y, 'Axpy(double)');
  Result := TDenseDoubleMatrix.Zeros(X.Rows, X.Cols);
  AxpyInto(Alpha, X, Y, Result);
end;

function Axpy(const Alpha: TSingleComplex;
  const X, Y: IDenseSingleComplexMatrix): IDenseSingleComplexMatrix;
begin
  specialize RequireSameShape<TSingleComplex>(X, Y,
    'Axpy(single complex)');
  Result := TDenseSingleComplexMatrix.Zeros(X.Rows, X.Cols);
  AxpyInto(Alpha, X, Y, Result);
end;

function Axpy(const Alpha: TComplex;
  const X, Y: IDenseComplexMatrix): IDenseComplexMatrix;
begin
  specialize RequireSameShape<TComplex>(X, Y, 'Axpy(complex)');
  Result := TDenseComplexMatrix.Zeros(X.Rows, X.Cols);
  AxpyInto(Alpha, X, Y, Result);
end;

procedure ApplyInto(const A, Destination: IDenseSingleMatrix;
  const Operation: TSingleUnaryKernel);
var
  R, C: SizeInt;
  Temp: IDenseSingleMatrix;
begin
  RequireFinite(A, 'ApplyInto(single)');
  specialize RequireDestinationShape<Single>(Destination, A.Rows, A.Cols,
    'ApplyInto(single)');
  if not Assigned(Operation) then
    raise EDenseMatrixError.Create(
      'ApplyInto(single): operation callback must be assigned.');
  Temp := TDenseSingleMatrix.Zeros(A.Rows, A.Cols);
  for R := 0 to A.Rows - 1 do
    for C := 0 to A.Cols - 1 do
      Temp[R, C] := Operation(A[R, C]);
  specialize CopyMatrix<Single>(Temp, Destination);
end;

procedure ApplyInto(const A, Destination: IDenseDoubleMatrix;
  const Operation: TDoubleUnaryKernel);
var
  R, C: SizeInt;
  Temp: IDenseDoubleMatrix;
begin
  RequireFinite(A, 'ApplyInto(double)');
  specialize RequireDestinationShape<Double>(Destination, A.Rows, A.Cols,
    'ApplyInto(double)');
  if not Assigned(Operation) then
    raise EDenseMatrixError.Create(
      'ApplyInto(double): operation callback must be assigned.');
  Temp := TDenseDoubleMatrix.Zeros(A.Rows, A.Cols);
  for R := 0 to A.Rows - 1 do
    for C := 0 to A.Cols - 1 do
      Temp[R, C] := Operation(A[R, C]);
  specialize CopyMatrix<Double>(Temp, Destination);
end;

procedure ApplyInto(const A, Destination: IDenseSingleComplexMatrix;
  const Operation: TSingleComplexUnaryKernel);
var
  R, C: SizeInt;
  Temp: IDenseSingleComplexMatrix;
begin
  RequireFinite(A, 'ApplyInto(single complex)');
  specialize RequireDestinationShape<TSingleComplex>(Destination, A.Rows,
    A.Cols, 'ApplyInto(single complex)');
  if not Assigned(Operation) then
    raise EDenseMatrixError.Create(
      'ApplyInto(single complex): operation callback must be assigned.');
  Temp := TDenseSingleComplexMatrix.Zeros(A.Rows, A.Cols);
  for R := 0 to A.Rows - 1 do
    for C := 0 to A.Cols - 1 do
      Temp[R, C] := Operation(A[R, C]);
  specialize CopyMatrix<TSingleComplex>(Temp, Destination);
end;

procedure ApplyInto(const A, Destination: IDenseComplexMatrix;
  const Operation: TComplexUnaryKernel);
var
  R, C: SizeInt;
  Temp: IDenseComplexMatrix;
begin
  RequireFinite(A, 'ApplyInto(complex)');
  specialize RequireDestinationShape<TComplex>(Destination, A.Rows, A.Cols,
    'ApplyInto(complex)');
  if not Assigned(Operation) then
    raise EDenseMatrixError.Create(
      'ApplyInto(complex): operation callback must be assigned.');
  Temp := TDenseComplexMatrix.Zeros(A.Rows, A.Cols);
  for R := 0 to A.Rows - 1 do
    for C := 0 to A.Cols - 1 do
      Temp[R, C] := Operation(A[R, C]);
  specialize CopyMatrix<TComplex>(Temp, Destination);
end;

function Apply(const A: IDenseSingleMatrix;
  const Operation: TSingleUnaryKernel): IDenseSingleMatrix;
begin
  RequireFinite(A, 'Apply(single)');
  Result := TDenseSingleMatrix.Zeros(A.Rows, A.Cols);
  ApplyInto(A, Result, Operation);
end;

function Apply(const A: IDenseDoubleMatrix;
  const Operation: TDoubleUnaryKernel): IDenseDoubleMatrix;
begin
  RequireFinite(A, 'Apply(double)');
  Result := TDenseDoubleMatrix.Zeros(A.Rows, A.Cols);
  ApplyInto(A, Result, Operation);
end;

function Apply(const A: IDenseSingleComplexMatrix;
  const Operation: TSingleComplexUnaryKernel):
  IDenseSingleComplexMatrix;
begin
  RequireFinite(A, 'Apply(single complex)');
  Result := TDenseSingleComplexMatrix.Zeros(A.Rows, A.Cols);
  ApplyInto(A, Result, Operation);
end;

function Apply(const A: IDenseComplexMatrix;
  const Operation: TComplexUnaryKernel): IDenseComplexMatrix;
begin
  RequireFinite(A, 'Apply(complex)');
  Result := TDenseComplexMatrix.Zeros(A.Rows, A.Cols);
  ApplyInto(A, Result, Operation);
end;

generic procedure TransposeIntoImpl<T>(const A, Destination:
  specialize IDenseMatrix<T>);
var
  Source: specialize IDenseMatrix<T>;
  R, C: SizeInt;
begin
  if Destination.StorageIdentity = A.StorageIdentity then
    Source := A.Clone
  else
    Source := A;
  for R := 0 to Source.Rows - 1 do
    for C := 0 to Source.Cols - 1 do
      Destination[C, R] := Source[R, C];
end;

procedure TransposeInto(const A, Destination: IDenseSingleMatrix);
begin
  RequireFinite(A, 'TransposeInto(single)');
  specialize RequireDestinationShape<Single>(Destination, A.Cols, A.Rows,
    'TransposeInto(single)');
  specialize TransposeIntoImpl<Single>(A, Destination);
end;

procedure TransposeInto(const A, Destination: IDenseDoubleMatrix);
begin
  RequireFinite(A, 'TransposeInto(double)');
  specialize RequireDestinationShape<Double>(Destination, A.Cols, A.Rows,
    'TransposeInto(double)');
  specialize TransposeIntoImpl<Double>(A, Destination);
end;

procedure TransposeInto(const A, Destination: IDenseSingleComplexMatrix);
begin
  RequireFinite(A, 'TransposeInto(single complex)');
  specialize RequireDestinationShape<TSingleComplex>(Destination, A.Cols,
    A.Rows, 'TransposeInto(single complex)');
  specialize TransposeIntoImpl<TSingleComplex>(A, Destination);
end;

procedure TransposeInto(const A, Destination: IDenseComplexMatrix);
begin
  RequireFinite(A, 'TransposeInto(complex)');
  specialize RequireDestinationShape<TComplex>(Destination, A.Cols, A.Rows,
    'TransposeInto(complex)');
  specialize TransposeIntoImpl<TComplex>(A, Destination);
end;

function Transpose(const A: IDenseSingleMatrix): IDenseSingleMatrix;
begin
  RequireFinite(A, 'Transpose(single)');
  Result := TDenseSingleMatrix.Zeros(A.Cols, A.Rows);
  TransposeInto(A, Result);
end;

function Transpose(const A: IDenseDoubleMatrix): IDenseDoubleMatrix;
begin
  RequireFinite(A, 'Transpose(double)');
  Result := TDenseDoubleMatrix.Zeros(A.Cols, A.Rows);
  TransposeInto(A, Result);
end;

function Transpose(const A: IDenseSingleComplexMatrix):
  IDenseSingleComplexMatrix;
begin
  RequireFinite(A, 'Transpose(single complex)');
  Result := TDenseSingleComplexMatrix.Zeros(A.Cols, A.Rows);
  TransposeInto(A, Result);
end;

function Transpose(const A: IDenseComplexMatrix): IDenseComplexMatrix;
begin
  RequireFinite(A, 'Transpose(complex)');
  Result := TDenseComplexMatrix.Zeros(A.Cols, A.Rows);
  TransposeInto(A, Result);
end;

function Conjugate(const A: IDenseSingleComplexMatrix):
  IDenseSingleComplexMatrix;
begin
  RequireFinite(A, 'Conjugate(single complex)');
  Result := TDenseSingleComplexMatrix.Zeros(A.Rows, A.Cols);
  ConjugateInto(A, Result);
end;

function Conjugate(const A: IDenseComplexMatrix): IDenseComplexMatrix;
begin
  RequireFinite(A, 'Conjugate(complex)');
  Result := TDenseComplexMatrix.Zeros(A.Rows, A.Cols);
  ConjugateInto(A, Result);
end;

procedure ConjugateInto(const A, Destination:
  IDenseSingleComplexMatrix);
var
  Work: IDenseSingleComplexMatrix;
  R, C: SizeInt;
begin
  RequireFinite(A, 'ConjugateInto(single complex)');
  specialize RequireDestinationShape<TSingleComplex>(Destination, A.Rows,
    A.Cols, 'ConjugateInto(single complex)');
  if Destination.StorageIdentity = A.StorageIdentity then
    Work := Destination.Clone
  else
    Work := Destination;
  for R := 0 to A.Rows - 1 do
    for C := 0 to A.Cols - 1 do
      Work[R, C] := A[R, C].Conjugate;
  if Work <> Destination then
    specialize CopyMatrix<TSingleComplex>(Work, Destination);
end;

procedure ConjugateInto(const A, Destination: IDenseComplexMatrix);
var
  Work: IDenseComplexMatrix;
  R, C: SizeInt;
begin
  RequireFinite(A, 'ConjugateInto(complex)');
  specialize RequireDestinationShape<TComplex>(Destination, A.Rows, A.Cols,
    'ConjugateInto(complex)');
  if Destination.StorageIdentity = A.StorageIdentity then
    Work := Destination.Clone
  else
    Work := Destination;
  for R := 0 to A.Rows - 1 do
    for C := 0 to A.Cols - 1 do
      Work[R, C] := A[R, C].Conjugate;
  if Work <> Destination then
    specialize CopyMatrix<TComplex>(Work, Destination);
end;

procedure ConjugateTransposeInto(const A, Destination:
  IDenseSingleComplexMatrix);
var
  Source: IDenseSingleComplexMatrix;
  R, C: SizeInt;
begin
  RequireFinite(A, 'ConjugateTransposeInto(single complex)');
  specialize RequireDestinationShape<TSingleComplex>(Destination, A.Cols,
    A.Rows, 'ConjugateTransposeInto(single complex)');
  if Destination.StorageIdentity = A.StorageIdentity then
    Source := A.Clone
  else
    Source := A;
  for R := 0 to Source.Rows - 1 do
    for C := 0 to Source.Cols - 1 do
      Destination[C, R] := Source[R, C].Conjugate;
end;

procedure ConjugateTransposeInto(const A, Destination:
  IDenseComplexMatrix);
var
  Source: IDenseComplexMatrix;
  R, C: SizeInt;
begin
  RequireFinite(A, 'ConjugateTransposeInto(complex)');
  specialize RequireDestinationShape<TComplex>(Destination, A.Cols, A.Rows,
    'ConjugateTransposeInto(complex)');
  if Destination.StorageIdentity = A.StorageIdentity then
    Source := A.Clone
  else
    Source := A;
  for R := 0 to Source.Rows - 1 do
    for C := 0 to Source.Cols - 1 do
      Destination[C, R] := Source[R, C].Conjugate;
end;

function ConjugateTranspose(const A: IDenseSingleComplexMatrix):
  IDenseSingleComplexMatrix;
begin
  RequireFinite(A, 'ConjugateTranspose(single complex)');
  Result := TDenseSingleComplexMatrix.Zeros(A.Cols, A.Rows);
  ConjugateTransposeInto(A, Result);
end;

function ConjugateTranspose(const A: IDenseComplexMatrix):
  IDenseComplexMatrix;
begin
  RequireFinite(A, 'ConjugateTranspose(complex)');
  Result := TDenseComplexMatrix.Zeros(A.Cols, A.Rows);
  ConjugateTransposeInto(A, Result);
end;

procedure AddCompensated(const Value: Double; var Sum, Correction: Double);
var
  Updated: Double;
begin
  Updated := Sum + Value;
  if Abs(Sum) >= Abs(Value) then
    Correction := Correction + ((Sum - Updated) + Value)
  else
    Correction := Correction + ((Value - Updated) + Sum);
  Sum := Updated;
end;

generic function VectorLength<T>(const A: specialize IDenseMatrix<T>;
  const Operation: string): SizeInt;
begin
  RequireAssigned(A <> nil, Operation);
  if (A.Rows <> 1) and (A.Cols <> 1) then
    raise EDenseMatrixError.Create(Operation + ': operand must be a vector.');
  if A.Rows = 1 then
    Result := A.Cols
  else
    Result := A.Rows;
end;

generic function VectorValue<T>(const A: specialize IDenseMatrix<T>;
  const Index: SizeInt): T;
begin
  if A.Rows = 1 then
    Result := A[0, Index]
  else
    Result := A[Index, 0];
end;

function SelectedMultiplyPath(const Rows, InnerDimension,
  Columns: SizeInt): TDenseMultiplyPath;
var
  Operations: QWord;
begin
  if (Rows < 0) or (InnerDimension < 0) or (Columns < 0) then
    raise EDenseMatrixError.Create(
      'SelectedMultiplyPath: dimensions must be non-negative.');
  if (Rows = 0) or (InnerDimension = 0) or (Columns = 0) then
    Exit(dmpPortable);
  if QWord(Rows) > High(QWord) div QWord(InnerDimension) then
    Exit(dmpBlocked);
  Operations := QWord(Rows) * QWord(InnerDimension);
  if Operations > High(QWord) div QWord(Columns) then
    Exit(dmpBlocked);
  Operations := Operations * QWord(Columns);
  if Operations >= DENSE_MULTIPLY_AUTO_THRESHOLD then
    Result := dmpBlocked
  else
    Result := dmpPortable;
end;

procedure RequirePositiveBlockSize(const BlockSize: SizeInt;
  const Operation: string);
begin
  if BlockSize <= 0 then
    raise EDenseMatrixError.Create(Operation +
      ': BlockSize must be positive.');
end;

procedure MultiplyBlockedInto(const A, B, Destination: IDenseDoubleMatrix;
  const BlockSize: SizeInt);
var
  Work: IDenseDoubleMatrix;
  IBlock, JBlock, KBlock, IEnd, JEnd, KEnd, I, J, K: SizeInt;
  Sum, Correction: Double;
begin
  RequirePositiveBlockSize(BlockSize, 'MultiplyBlockedInto(double)');
  RequireFinite(A, 'MultiplyBlockedInto(double)');
  RequireFinite(B, 'MultiplyBlockedInto(double)');
  if A.Cols <> B.Rows then
    raise EDenseMatrixError.CreateFmt(
      'MultiplyBlockedInto(double): inner dimensions must match; got %d x %d and %d x %d.',
      [A.Rows, A.Cols, B.Rows, B.Cols]);
  specialize RequireDestinationShape<Double>(Destination, A.Rows, B.Cols,
    'MultiplyBlockedInto(double)');
  if (Destination.StorageIdentity = A.StorageIdentity) or
     (Destination.StorageIdentity = B.StorageIdentity) then
    Work := TDenseDoubleMatrix.Zeros(A.Rows, B.Cols)
  else
    Work := Destination;

  IBlock := 0;
  while IBlock < A.Rows do
  begin
    IEnd := IBlock + BlockSize;
    if IEnd > A.Rows then IEnd := A.Rows;
    JBlock := 0;
    while JBlock < B.Cols do
    begin
      JEnd := JBlock + BlockSize;
      if JEnd > B.Cols then JEnd := B.Cols;
      for I := IBlock to IEnd - 1 do
        for J := JBlock to JEnd - 1 do
        begin
          Sum := 0.0;
          Correction := 0.0;
          KBlock := 0;
          while KBlock < A.Cols do
          begin
            KEnd := KBlock + BlockSize;
            if KEnd > A.Cols then KEnd := A.Cols;
            for K := KBlock to KEnd - 1 do
              AddCompensated(A[I, K] * B[K, J], Sum, Correction);
            KBlock := KEnd;
          end;
          Work[I, J] := Sum + Correction;
        end;
      JBlock := JEnd;
    end;
    IBlock := IEnd;
  end;
  if Work <> Destination then
    specialize CopyMatrix<Double>(Work, Destination);
end;

procedure MultiplyBlockedInto(const A, B, Destination: IDenseSingleMatrix;
  const BlockSize: SizeInt);
var
  Work: IDenseSingleMatrix;
  IBlock, JBlock, KBlock, IEnd, JEnd, KEnd, I, J, K: SizeInt;
  Sum, Correction: Double;
begin
  RequirePositiveBlockSize(BlockSize, 'MultiplyBlockedInto(single)');
  RequireFinite(A, 'MultiplyBlockedInto(single)');
  RequireFinite(B, 'MultiplyBlockedInto(single)');
  if A.Cols <> B.Rows then
    raise EDenseMatrixError.CreateFmt(
      'MultiplyBlockedInto(single): inner dimensions must match; got %d x %d and %d x %d.',
      [A.Rows, A.Cols, B.Rows, B.Cols]);
  specialize RequireDestinationShape<Single>(Destination, A.Rows, B.Cols,
    'MultiplyBlockedInto(single)');
  if (Destination.StorageIdentity = A.StorageIdentity) or
     (Destination.StorageIdentity = B.StorageIdentity) then
    Work := TDenseSingleMatrix.Zeros(A.Rows, B.Cols)
  else
    Work := Destination;

  IBlock := 0;
  while IBlock < A.Rows do
  begin
    IEnd := IBlock + BlockSize;
    if IEnd > A.Rows then IEnd := A.Rows;
    JBlock := 0;
    while JBlock < B.Cols do
    begin
      JEnd := JBlock + BlockSize;
      if JEnd > B.Cols then JEnd := B.Cols;
      for I := IBlock to IEnd - 1 do
        for J := JBlock to JEnd - 1 do
        begin
          Sum := 0.0;
          Correction := 0.0;
          KBlock := 0;
          while KBlock < A.Cols do
          begin
            KEnd := KBlock + BlockSize;
            if KEnd > A.Cols then KEnd := A.Cols;
            for K := KBlock to KEnd - 1 do
              AddCompensated(Double(A[I, K]) * Double(B[K, J]),
                Sum, Correction);
            KBlock := KEnd;
          end;
          Work[I, J] := Single(Sum + Correction);
        end;
      JBlock := JEnd;
    end;
    IBlock := IEnd;
  end;
  if Work <> Destination then
    specialize CopyMatrix<Single>(Work, Destination);
end;

procedure MultiplyBlockedInto(const A, B, Destination:
  IDenseSingleComplexMatrix; const BlockSize: SizeInt);
var
  Work: IDenseSingleComplexMatrix;
  IBlock, JBlock, KBlock, IEnd, JEnd, KEnd, I, J, K: SizeInt;
  Product: TSingleComplex;
  SumRe, SumIm, CorrectionRe, CorrectionIm: Double;
begin
  RequirePositiveBlockSize(BlockSize,
    'MultiplyBlockedInto(single complex)');
  RequireFinite(A, 'MultiplyBlockedInto(single complex)');
  RequireFinite(B, 'MultiplyBlockedInto(single complex)');
  if A.Cols <> B.Rows then
    raise EDenseMatrixError.CreateFmt(
      'MultiplyBlockedInto(single complex): inner dimensions must match; got %d x %d and %d x %d.',
      [A.Rows, A.Cols, B.Rows, B.Cols]);
  specialize RequireDestinationShape<TSingleComplex>(Destination,
    A.Rows, B.Cols, 'MultiplyBlockedInto(single complex)');
  if (Destination.StorageIdentity = A.StorageIdentity) or
     (Destination.StorageIdentity = B.StorageIdentity) then
    Work := TDenseSingleComplexMatrix.Zeros(A.Rows, B.Cols)
  else
    Work := Destination;

  IBlock := 0;
  while IBlock < A.Rows do
  begin
    IEnd := IBlock + BlockSize;
    if IEnd > A.Rows then IEnd := A.Rows;
    JBlock := 0;
    while JBlock < B.Cols do
    begin
      JEnd := JBlock + BlockSize;
      if JEnd > B.Cols then JEnd := B.Cols;
      for I := IBlock to IEnd - 1 do
        for J := JBlock to JEnd - 1 do
        begin
          SumRe := 0.0; SumIm := 0.0;
          CorrectionRe := 0.0; CorrectionIm := 0.0;
          KBlock := 0;
          while KBlock < A.Cols do
          begin
            KEnd := KBlock + BlockSize;
            if KEnd > A.Cols then KEnd := A.Cols;
            for K := KBlock to KEnd - 1 do
            begin
              Product := A[I, K] * B[K, J];
              AddCompensated(Product.Re, SumRe, CorrectionRe);
              AddCompensated(Product.Im, SumIm, CorrectionIm);
            end;
            KBlock := KEnd;
          end;
          Work[I, J] := TSingleComplex.Create(
            SumRe + CorrectionRe, SumIm + CorrectionIm);
        end;
      JBlock := JEnd;
    end;
    IBlock := IEnd;
  end;
  if Work <> Destination then
    specialize CopyMatrix<TSingleComplex>(Work, Destination);
end;

procedure MultiplyBlockedInto(const A, B, Destination:
  IDenseComplexMatrix; const BlockSize: SizeInt);
var
  Work: IDenseComplexMatrix;
  IBlock, JBlock, KBlock, IEnd, JEnd, KEnd, I, J, K: SizeInt;
  Product: TComplex;
  SumRe, SumIm, CorrectionRe, CorrectionIm: Double;
begin
  RequirePositiveBlockSize(BlockSize, 'MultiplyBlockedInto(complex)');
  RequireFinite(A, 'MultiplyBlockedInto(complex)');
  RequireFinite(B, 'MultiplyBlockedInto(complex)');
  if A.Cols <> B.Rows then
    raise EDenseMatrixError.CreateFmt(
      'MultiplyBlockedInto(complex): inner dimensions must match; got %d x %d and %d x %d.',
      [A.Rows, A.Cols, B.Rows, B.Cols]);
  specialize RequireDestinationShape<TComplex>(Destination, A.Rows, B.Cols,
    'MultiplyBlockedInto(complex)');
  if (Destination.StorageIdentity = A.StorageIdentity) or
     (Destination.StorageIdentity = B.StorageIdentity) then
    Work := TDenseComplexMatrix.Zeros(A.Rows, B.Cols)
  else
    Work := Destination;

  IBlock := 0;
  while IBlock < A.Rows do
  begin
    IEnd := IBlock + BlockSize;
    if IEnd > A.Rows then IEnd := A.Rows;
    JBlock := 0;
    while JBlock < B.Cols do
    begin
      JEnd := JBlock + BlockSize;
      if JEnd > B.Cols then JEnd := B.Cols;
      for I := IBlock to IEnd - 1 do
        for J := JBlock to JEnd - 1 do
        begin
          SumRe := 0.0; SumIm := 0.0;
          CorrectionRe := 0.0; CorrectionIm := 0.0;
          KBlock := 0;
          while KBlock < A.Cols do
          begin
            KEnd := KBlock + BlockSize;
            if KEnd > A.Cols then KEnd := A.Cols;
            for K := KBlock to KEnd - 1 do
            begin
              Product := A[I, K] * B[K, J];
              AddCompensated(Product.Re, SumRe, CorrectionRe);
              AddCompensated(Product.Im, SumIm, CorrectionIm);
            end;
            KBlock := KEnd;
          end;
          Work[I, J] := TComplex.Create(
            SumRe + CorrectionRe, SumIm + CorrectionIm);
        end;
      JBlock := JEnd;
    end;
    IBlock := IEnd;
  end;
  if Work <> Destination then
    specialize CopyMatrix<TComplex>(Work, Destination);
end;

procedure MultiplyAutoInto(const A, B, Destination: IDenseDoubleMatrix);
begin
  RequireAssigned((A <> nil) and (B <> nil), 'MultiplyAutoInto(double)');
  if SelectedMultiplyPath(A.Rows, A.Cols, B.Cols) = dmpBlocked then
    MultiplyBlockedInto(A, B, Destination)
  else
    MultiplyInto(A, B, Destination);
end;

procedure MultiplyAutoInto(const A, B, Destination: IDenseSingleMatrix);
begin
  RequireAssigned((A <> nil) and (B <> nil), 'MultiplyAutoInto(single)');
  if SelectedMultiplyPath(A.Rows, A.Cols, B.Cols) = dmpBlocked then
    MultiplyBlockedInto(A, B, Destination)
  else
    MultiplyInto(A, B, Destination);
end;

procedure MultiplyAutoInto(const A, B, Destination:
  IDenseSingleComplexMatrix);
begin
  RequireAssigned((A <> nil) and (B <> nil),
    'MultiplyAutoInto(single complex)');
  if SelectedMultiplyPath(A.Rows, A.Cols, B.Cols) = dmpBlocked then
    MultiplyBlockedInto(A, B, Destination)
  else
    MultiplyInto(A, B, Destination);
end;

procedure MultiplyAutoInto(const A, B, Destination: IDenseComplexMatrix);
begin
  RequireAssigned((A <> nil) and (B <> nil), 'MultiplyAutoInto(complex)');
  if SelectedMultiplyPath(A.Rows, A.Cols, B.Cols) = dmpBlocked then
    MultiplyBlockedInto(A, B, Destination)
  else
    MultiplyInto(A, B, Destination);
end;

procedure MultiplyInto(const A, B, Destination: IDenseDoubleMatrix);
var
  Work: IDenseDoubleMatrix;
  I, J, K: SizeInt;
  Sum, Correction: Double;
begin
  RequireFinite(A, 'MultiplyInto(double)');
  RequireFinite(B, 'MultiplyInto(double)');
  if A.Cols <> B.Rows then
    raise EDenseMatrixError.CreateFmt(
      'MultiplyInto(double): inner dimensions must match; got %d x %d and %d x %d.',
      [A.Rows, A.Cols, B.Rows, B.Cols]);
  specialize RequireDestinationShape<Double>(Destination, A.Rows, B.Cols,
    'MultiplyInto(double)');
  if (Destination.StorageIdentity = A.StorageIdentity) or
     (Destination.StorageIdentity = B.StorageIdentity) then
    Work := TDenseDoubleMatrix.Zeros(A.Rows, B.Cols)
  else
    Work := Destination;
  for I := 0 to A.Rows - 1 do
    for J := 0 to B.Cols - 1 do
    begin
      Sum := 0.0;
      Correction := 0.0;
      for K := 0 to A.Cols - 1 do
        AddCompensated(A[I, K] * B[K, J], Sum, Correction);
      Work[I, J] := Sum + Correction;
    end;
  if Work <> Destination then
    specialize CopyMatrix<Double>(Work, Destination);
end;

procedure MultiplyInto(const A, B, Destination: IDenseSingleMatrix);
var
  Work: IDenseSingleMatrix;
  I, J, K: SizeInt;
  Sum, Correction: Double;
begin
  RequireFinite(A, 'MultiplyInto(single)');
  RequireFinite(B, 'MultiplyInto(single)');
  if A.Cols <> B.Rows then
    raise EDenseMatrixError.CreateFmt(
      'MultiplyInto(single): inner dimensions must match; got %d x %d and %d x %d.',
      [A.Rows, A.Cols, B.Rows, B.Cols]);
  specialize RequireDestinationShape<Single>(Destination, A.Rows, B.Cols,
    'MultiplyInto(single)');
  if (Destination.StorageIdentity = A.StorageIdentity) or
     (Destination.StorageIdentity = B.StorageIdentity) then
    Work := TDenseSingleMatrix.Zeros(A.Rows, B.Cols)
  else
    Work := Destination;
  for I := 0 to A.Rows - 1 do
    for J := 0 to B.Cols - 1 do
    begin
      Sum := 0.0;
      Correction := 0.0;
      for K := 0 to A.Cols - 1 do
        AddCompensated(Double(A[I, K]) * Double(B[K, J]), Sum, Correction);
      Work[I, J] := Single(Sum + Correction);
    end;
  if Work <> Destination then
    specialize CopyMatrix<Single>(Work, Destination);
end;

procedure MultiplyInto(const A, B, Destination:
  IDenseSingleComplexMatrix);
var
  Work: IDenseSingleComplexMatrix;
  I, J, K: SizeInt;
  Product: TSingleComplex;
  SumRe, SumIm, CorrectionRe, CorrectionIm: Double;
begin
  RequireFinite(A, 'MultiplyInto(single complex)');
  RequireFinite(B, 'MultiplyInto(single complex)');
  if A.Cols <> B.Rows then
    raise EDenseMatrixError.CreateFmt(
      'MultiplyInto(single complex): inner dimensions must match; got %d x %d and %d x %d.',
      [A.Rows, A.Cols, B.Rows, B.Cols]);
  specialize RequireDestinationShape<TSingleComplex>(Destination, A.Rows,
    B.Cols, 'MultiplyInto(single complex)');
  if (Destination.StorageIdentity = A.StorageIdentity) or
     (Destination.StorageIdentity = B.StorageIdentity) then
    Work := TDenseSingleComplexMatrix.Zeros(A.Rows, B.Cols)
  else
    Work := Destination;
  for I := 0 to A.Rows - 1 do
    for J := 0 to B.Cols - 1 do
    begin
      SumRe := 0.0; SumIm := 0.0;
      CorrectionRe := 0.0; CorrectionIm := 0.0;
      for K := 0 to A.Cols - 1 do
      begin
        Product := A[I, K] * B[K, J];
        AddCompensated(Product.Re, SumRe, CorrectionRe);
        AddCompensated(Product.Im, SumIm, CorrectionIm);
      end;
      Work[I, J] := TSingleComplex.Create(SumRe + CorrectionRe,
        SumIm + CorrectionIm);
    end;
  if Work <> Destination then
    specialize CopyMatrix<TSingleComplex>(Work, Destination);
end;

procedure MultiplyInto(const A, B, Destination: IDenseComplexMatrix);
var
  Work: IDenseComplexMatrix;
  I, J, K: SizeInt;
  Product: TComplex;
  SumRe, SumIm, CorrectionRe, CorrectionIm: Double;
begin
  RequireFinite(A, 'MultiplyInto(complex)');
  RequireFinite(B, 'MultiplyInto(complex)');
  if A.Cols <> B.Rows then
    raise EDenseMatrixError.CreateFmt(
      'MultiplyInto(complex): inner dimensions must match; got %d x %d and %d x %d.',
      [A.Rows, A.Cols, B.Rows, B.Cols]);
  specialize RequireDestinationShape<TComplex>(Destination, A.Rows, B.Cols,
    'MultiplyInto(complex)');
  if (Destination.StorageIdentity = A.StorageIdentity) or
     (Destination.StorageIdentity = B.StorageIdentity) then
    Work := TDenseComplexMatrix.Zeros(A.Rows, B.Cols)
  else
    Work := Destination;
  for I := 0 to A.Rows - 1 do
    for J := 0 to B.Cols - 1 do
    begin
      SumRe := 0.0; SumIm := 0.0;
      CorrectionRe := 0.0; CorrectionIm := 0.0;
      for K := 0 to A.Cols - 1 do
      begin
        Product := A[I, K] * B[K, J];
        AddCompensated(Product.Re, SumRe, CorrectionRe);
        AddCompensated(Product.Im, SumIm, CorrectionIm);
      end;
      Work[I, J] := TComplex.Create(SumRe + CorrectionRe,
        SumIm + CorrectionIm);
    end;
  if Work <> Destination then
    specialize CopyMatrix<TComplex>(Work, Destination);
end;

function Multiply(const A, B: IDenseSingleMatrix): IDenseSingleMatrix;
begin
  RequireAssigned((A <> nil) and (B <> nil), 'Multiply(single)');
  if A.Cols <> B.Rows then
    raise EDenseMatrixError.CreateFmt(
      'Multiply(single): inner dimensions must match; got %d x %d and %d x %d.',
      [A.Rows, A.Cols, B.Rows, B.Cols]);
  Result := TDenseSingleMatrix.Zeros(A.Rows, B.Cols);
  MultiplyInto(A, B, Result);
end;

function Multiply(const A, B: IDenseDoubleMatrix): IDenseDoubleMatrix;
begin
  RequireAssigned((A <> nil) and (B <> nil), 'Multiply(double)');
  if A.Cols <> B.Rows then
    raise EDenseMatrixError.CreateFmt(
      'Multiply(double): inner dimensions must match; got %d x %d and %d x %d.',
      [A.Rows, A.Cols, B.Rows, B.Cols]);
  Result := TDenseDoubleMatrix.Zeros(A.Rows, B.Cols);
  MultiplyInto(A, B, Result);
end;

function Multiply(const A, B: IDenseSingleComplexMatrix):
  IDenseSingleComplexMatrix;
begin
  RequireAssigned((A <> nil) and (B <> nil), 'Multiply(single complex)');
  if A.Cols <> B.Rows then
    raise EDenseMatrixError.CreateFmt(
      'Multiply(single complex): inner dimensions must match; got %d x %d and %d x %d.',
      [A.Rows, A.Cols, B.Rows, B.Cols]);
  Result := TDenseSingleComplexMatrix.Zeros(A.Rows, B.Cols);
  MultiplyInto(A, B, Result);
end;

function Multiply(const A, B: IDenseComplexMatrix): IDenseComplexMatrix;
begin
  RequireAssigned((A <> nil) and (B <> nil), 'Multiply(complex)');
  if A.Cols <> B.Rows then
    raise EDenseMatrixError.CreateFmt(
      'Multiply(complex): inner dimensions must match; got %d x %d and %d x %d.',
      [A.Rows, A.Cols, B.Rows, B.Cols]);
  Result := TDenseComplexMatrix.Zeros(A.Rows, B.Cols);
  MultiplyInto(A, B, Result);
end;

function Dot(const A, B: IDenseDoubleMatrix): Double;
var
  I, LengthA, LengthB: SizeInt;
  Sum, Correction: Double;
begin
  LengthA := specialize VectorLength<Double>(A, 'Dot(double)');
  LengthB := specialize VectorLength<Double>(B, 'Dot(double)');
  if LengthA <> LengthB then
    raise EDenseMatrixError.CreateFmt(
      'Dot(double): vector lengths must match; got %d and %d.',
      [LengthA, LengthB]);
  RequireFinite(A, 'Dot(double)');
  RequireFinite(B, 'Dot(double)');
  Sum := 0.0; Correction := 0.0;
  for I := 0 to LengthA - 1 do
    AddCompensated(specialize VectorValue<Double>(A, I) *
      specialize VectorValue<Double>(B, I), Sum, Correction);
  Result := Sum + Correction;
end;

function Dot(const A, B: IDenseSingleMatrix): Single;
var
  I, LengthA, LengthB: SizeInt;
  Sum, Correction: Double;
begin
  LengthA := specialize VectorLength<Single>(A, 'Dot(single)');
  LengthB := specialize VectorLength<Single>(B, 'Dot(single)');
  if LengthA <> LengthB then
    raise EDenseMatrixError.CreateFmt(
      'Dot(single): vector lengths must match; got %d and %d.',
      [LengthA, LengthB]);
  RequireFinite(A, 'Dot(single)');
  RequireFinite(B, 'Dot(single)');
  Sum := 0.0; Correction := 0.0;
  for I := 0 to LengthA - 1 do
    AddCompensated(Double(specialize VectorValue<Single>(A, I)) *
      Double(specialize VectorValue<Single>(B, I)), Sum, Correction);
  Result := Single(Sum + Correction);
end;

function Dot(const A, B: IDenseComplexMatrix): TComplex;
var
  I, LengthA, LengthB: SizeInt;
  Product: TComplex;
  SumRe, SumIm, CorrectionRe, CorrectionIm: Double;
begin
  LengthA := specialize VectorLength<TComplex>(A, 'Dot(complex)');
  LengthB := specialize VectorLength<TComplex>(B, 'Dot(complex)');
  if LengthA <> LengthB then
    raise EDenseMatrixError.CreateFmt(
      'Dot(complex): vector lengths must match; got %d and %d.',
      [LengthA, LengthB]);
  RequireFinite(A, 'Dot(complex)');
  RequireFinite(B, 'Dot(complex)');
  SumRe := 0.0; SumIm := 0.0;
  CorrectionRe := 0.0; CorrectionIm := 0.0;
  for I := 0 to LengthA - 1 do
  begin
    Product := specialize VectorValue<TComplex>(A, I) *
      specialize VectorValue<TComplex>(B, I);
    AddCompensated(Product.Re, SumRe, CorrectionRe);
    AddCompensated(Product.Im, SumIm, CorrectionIm);
  end;
  Result := TComplex.Create(SumRe + CorrectionRe, SumIm + CorrectionIm);
end;

function Dot(const A, B: IDenseSingleComplexMatrix): TSingleComplex;
var
  I, LengthA, LengthB: SizeInt;
  Product: TSingleComplex;
  SumRe, SumIm, CorrectionRe, CorrectionIm: Double;
begin
  LengthA := specialize VectorLength<TSingleComplex>(A,
    'Dot(single complex)');
  LengthB := specialize VectorLength<TSingleComplex>(B,
    'Dot(single complex)');
  if LengthA <> LengthB then
    raise EDenseMatrixError.CreateFmt(
      'Dot(single complex): vector lengths must match; got %d and %d.',
      [LengthA, LengthB]);
  RequireFinite(A, 'Dot(single complex)');
  RequireFinite(B, 'Dot(single complex)');
  SumRe := 0.0; SumIm := 0.0;
  CorrectionRe := 0.0; CorrectionIm := 0.0;
  for I := 0 to LengthA - 1 do
  begin
    Product := specialize VectorValue<TSingleComplex>(A, I) *
      specialize VectorValue<TSingleComplex>(B, I);
    AddCompensated(Product.Re, SumRe, CorrectionRe);
    AddCompensated(Product.Im, SumIm, CorrectionIm);
  end;
  Result := TSingleComplex.Create(SumRe + CorrectionRe,
    SumIm + CorrectionIm);
end;

function DotConjugate(const A, B: IDenseComplexMatrix): TComplex;
begin
  Result := Dot(Conjugate(A), B);
end;

function DotConjugate(const A, B: IDenseSingleComplexMatrix):
  TSingleComplex;
begin
  Result := Dot(Conjugate(A), B);
end;

function Sum(const A: IDenseDoubleMatrix): Double;
var
  R, C: SizeInt;
  Total, Correction: Double;
begin
  RequireFinite(A, 'Sum(double)');
  Total := 0.0;
  Correction := 0.0;
  for R := 0 to A.Rows - 1 do
    for C := 0 to A.Cols - 1 do
      AddCompensated(A[R, C], Total, Correction);
  Result := Total + Correction;
end;

function Sum(const A: IDenseSingleMatrix): Single;
var
  R, C: SizeInt;
  Total, Correction: Double;
begin
  RequireFinite(A, 'Sum(single)');
  Total := 0.0;
  Correction := 0.0;
  for R := 0 to A.Rows - 1 do
    for C := 0 to A.Cols - 1 do
      AddCompensated(A[R, C], Total, Correction);
  Result := Single(Total + Correction);
end;

function Sum(const A: IDenseComplexMatrix): TComplex;
var
  R, C: SizeInt;
  Value: TComplex;
  TotalRe, TotalIm, CorrectionRe, CorrectionIm: Double;
begin
  RequireFinite(A, 'Sum(complex)');
  TotalRe := 0.0; TotalIm := 0.0;
  CorrectionRe := 0.0; CorrectionIm := 0.0;
  for R := 0 to A.Rows - 1 do
    for C := 0 to A.Cols - 1 do
    begin
      Value := A[R, C];
      AddCompensated(Value.Re, TotalRe, CorrectionRe);
      AddCompensated(Value.Im, TotalIm, CorrectionIm);
    end;
  Result := TComplex.Create(TotalRe + CorrectionRe, TotalIm + CorrectionIm);
end;

function Sum(const A: IDenseSingleComplexMatrix): TSingleComplex;
var
  R, C: SizeInt;
  Value: TSingleComplex;
  TotalRe, TotalIm, CorrectionRe, CorrectionIm: Double;
begin
  RequireFinite(A, 'Sum(single complex)');
  TotalRe := 0.0; TotalIm := 0.0;
  CorrectionRe := 0.0; CorrectionIm := 0.0;
  for R := 0 to A.Rows - 1 do
    for C := 0 to A.Cols - 1 do
    begin
      Value := A[R, C];
      AddCompensated(Value.Re, TotalRe, CorrectionRe);
      AddCompensated(Value.Im, TotalIm, CorrectionIm);
    end;
  Result := TSingleComplex.Create(TotalRe + CorrectionRe,
    TotalIm + CorrectionIm);
end;

procedure UpdateScaledSum(const Value: Double;
  var ScaleValue, SumSquares: Double);
var
  AbsoluteValue, Ratio: Double;
begin
  AbsoluteValue := Abs(Value);
  if AbsoluteValue = 0.0 then
    Exit;
  if ScaleValue < AbsoluteValue then
  begin
    if ScaleValue = 0.0 then
      SumSquares := 1.0
    else
    begin
      Ratio := ScaleValue / AbsoluteValue;
      SumSquares := 1.0 + SumSquares * Ratio * Ratio;
    end;
    ScaleValue := AbsoluteValue;
  end
  else
  begin
    Ratio := AbsoluteValue / ScaleValue;
    SumSquares := SumSquares + Ratio * Ratio;
  end;
end;

function Norm2(const A: IDenseDoubleMatrix): Double;
var
  R, C: SizeInt;
  ScaleValue, SumSquares: Double;
begin
  RequireFinite(A, 'Norm2(double)');
  ScaleValue := 0.0;
  SumSquares := 0.0;
  for R := 0 to A.Rows - 1 do
    for C := 0 to A.Cols - 1 do
      UpdateScaledSum(A[R, C], ScaleValue, SumSquares);
  if ScaleValue = 0.0 then
    Result := 0.0
  else
    Result := ScaleValue * Sqrt(SumSquares);
end;

function Norm2(const A: IDenseSingleMatrix): Single;
var
  R, C: SizeInt;
  ScaleValue, SumSquares: Double;
begin
  RequireFinite(A, 'Norm2(single)');
  ScaleValue := 0.0;
  SumSquares := 0.0;
  for R := 0 to A.Rows - 1 do
    for C := 0 to A.Cols - 1 do
      UpdateScaledSum(A[R, C], ScaleValue, SumSquares);
  if ScaleValue = 0.0 then
    Result := 0.0
  else
    Result := Single(ScaleValue * Sqrt(SumSquares));
end;

function Norm2(const A: IDenseComplexMatrix): Double;
var
  R, C: SizeInt;
  Value: TComplex;
  ScaleValue, SumSquares: Double;
begin
  RequireFinite(A, 'Norm2(complex)');
  ScaleValue := 0.0;
  SumSquares := 0.0;
  for R := 0 to A.Rows - 1 do
    for C := 0 to A.Cols - 1 do
    begin
      Value := A[R, C];
      UpdateScaledSum(Value.Re, ScaleValue, SumSquares);
      UpdateScaledSum(Value.Im, ScaleValue, SumSquares);
    end;
  if ScaleValue = 0.0 then
    Result := 0.0
  else
    Result := ScaleValue * Sqrt(SumSquares);
end;

function Norm2(const A: IDenseSingleComplexMatrix): Single;
var
  R, C: SizeInt;
  Value: TSingleComplex;
  ScaleValue, SumSquares: Double;
begin
  RequireFinite(A, 'Norm2(single complex)');
  ScaleValue := 0.0;
  SumSquares := 0.0;
  for R := 0 to A.Rows - 1 do
    for C := 0 to A.Cols - 1 do
    begin
      Value := A[R, C];
      UpdateScaledSum(Value.Re, ScaleValue, SumSquares);
      UpdateScaledSum(Value.Im, ScaleValue, SumSquares);
    end;
  if ScaleValue = 0.0 then
    Result := 0.0
  else
    Result := Single(ScaleValue * Sqrt(SumSquares));
end;

end.
