program BenchmarkRunner;

{$mode objfpc}{$H+}{$J-}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Math,
  MathBase.SharedTypes,
  MathBase.Complex,
  StatsLib.Stats,
  GeometryLib.Geometry,
  AlgebraLib.Matrices,
  AlgebraLib.VectorKernels,
  EngineeringLib.Signal;

procedure BenchmarkSort;
const
  N = 250000;
var
  Data: TDoubleArray;
  I: Integer;
  Started: QWord;
begin
  SetLength(Data, N);
  for I := 0 to High(Data) do
    Data[I] := ((Int64(I) * 104729) mod 1000003) - 500001;
  Started := GetTickCount64;
  TStatsKit.Sort(Data);
  Writeln('stats merge sort, n=', N, ': ', GetTickCount64 - Started, ' ms');
  if Data[0] > Data[High(Data)] then Halt(2);
end;

procedure BenchmarkConvexHull;
const
  N = 150000;
var
  Points, Hull: TPolygon2D;
  I: Integer;
  Started: QWord;
begin
  SetLength(Points, N);
  for I := 0 to High(Points) do
    Points[I] := TPoint2D.Create((Int64(I) * 7919) mod 100003,
      (Int64(I) * I + 17 * Int64(I)) mod 100019);
  Started := GetTickCount64;
  Hull := TGeometryKit.ConvexHull(Points);
  Writeln('geometry convex hull, n=', N, ', hull=', Length(Hull), ': ',
    GetTickCount64 - Started, ' ms');
  if Length(Hull) < 3 then Halt(3);
end;

procedure BenchmarkMatrixMultiply;
const
  N = 192;
var
  A, B, C: IMatrix;
  I, J: Integer;
  Started: QWord;
begin
  A := TMatrixKit.Create(N, N);
  B := TMatrixKit.Create(N, N);
  for I := 0 to N - 1 do
    for J := 0 to N - 1 do
    begin
      A.SetValue(I, J, Sin(I * 0.01 + J * 0.03));
      B.SetValue(I, J, Cos(I * 0.02 - J * 0.01));
    end;
  Started := GetTickCount64;
  C := A.Multiply(B);
  Writeln('dense matrix multiply, ', N, 'x', N, ': ',
    GetTickCount64 - Started, ' ms; checksum=', C.GetValue(0, 0):0:6);
end;

procedure BenchmarkComplexArithmetic;
const
  N = 2000000;
var
  I: Integer;
  Z, W, Checksum: TComplex;
  Started: QWord;
begin
  Z := TComplex.Create(0.125, -0.75);
  W := TComplex.Create(0.999, 0.02);
  Checksum := TComplex.Zero;
  Started := GetTickCount64;
  for I := 1 to N do
  begin
    Z := Z * W + TComplex.Create(0.001, -0.002);
    Checksum := Checksum + Z;
  end;
  Writeln('complex arithmetic, n=', N, ': ', GetTickCount64 - Started,
    ' ms; checksum=', Checksum.Re:0:6);
end;

procedure BenchmarkVectorKernels;
const
  N = 1000000;
var
  A, B, Destination: TRealVector;
  I: Integer;
  Started: QWord;
  Checksum: Double;
begin
  SetLength(A, N);
  SetLength(B, N);
  SetLength(Destination, N);
  for I := 0 to N - 1 do
  begin
    A[I] := Sin(I * 0.001);
    B[I] := Cos(I * 0.001);
  end;
  Started := GetTickCount64;
  TVectorKit.AxpyInto(0.75, A, B, Destination);
  Checksum := TVectorKit.Dot(Destination, A);
  Writeln('vector AXPY+dot, n=', N, ': ', GetTickCount64 - Started,
    ' ms; checksum=', Checksum:0:6);
end;

procedure BenchmarkComplexFFT;
const
  N = 262144;
var
  Data: TComplexArray;
  I: Integer;
  Started: QWord;
begin
  SetLength(Data, N);
  for I := 0 to N - 1 do
    Data[I] := TComplex.Create(Sin(I * 0.01), Cos(I * 0.03));
  Started := GetTickCount64;
  TSignalKit.FFT(Data);
  Writeln('complex FFT, n=', N, ': ', GetTickCount64 - Started,
    ' ms; checksum=', Data[1].Magnitude:0:6);
end;

begin
  Writeln('mathlib-fp representative microbenchmarks');
  BenchmarkSort;
  BenchmarkConvexHull;
  BenchmarkMatrixMultiply;
  BenchmarkComplexArithmetic;
  BenchmarkVectorKernels;
  BenchmarkComplexFFT;
end.
