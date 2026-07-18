program BenchmarkRunner;

{$mode objfpc}{$H+}{$J-}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Math,
  MathBase.SharedTypes,
  StatsLib.Stats,
  GeometryLib.Geometry,
  AlgebraLib.Matrices;

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

begin
  Writeln('mathlib-fp representative microbenchmarks');
  BenchmarkSort;
  BenchmarkConvexHull;
  BenchmarkMatrixMultiply;
end.
