unit TestSparseInterchange;

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  MathBase.Complex, MathBase.Interchange,
  AlgebraLib.SparseMatrices;

type
  TSparseInterchangeTest = class(TTestCase)
  private
    function StreamFromText(const Text: string): TMemoryStream;
  published
    procedure TestMatrixMarketRealAndComplexRoundTrips;
    procedure TestMatrixMarketRejectsMalformedAndDuplicates;
    procedure TestBinaryFourScalarRoundTrips;
    procedure TestBinaryRejectsVersionChecksumTruncationAndLimits;
  end;

implementation

function TSparseInterchangeTest.StreamFromText(
  const Text: string): TMemoryStream;
begin
  Result := TMemoryStream.Create;
  if Length(Text) > 0 then Result.WriteBuffer(Text[1], Length(Text));
  Result.Position := 0;
end;

procedure TSparseInterchangeTest.TestMatrixMarketRealAndComplexRoundTrips;
var
  Stream: TMemoryStream;
  A, B: ISparseDoubleMatrix;
  C, D: ISparseComplexMatrix;
begin
  A := TSparseDoubleMatrix.FromCSR(3, 4, [0, 1, 2, 3],
    [1, 3, 0], [2.0, -1.0, 4.0]);
  Stream := TMemoryStream.Create;
  try
    WriteSparseMatrixMarket(Stream, A);
    Stream.Position := 0;
    B := ReadSparseMatrixMarketDouble(Stream, sfCSC);
    AssertEquals('real shape rows', A.Rows, B.Rows);
    AssertEquals('real shape cols', A.Cols, B.Cols);
    AssertEquals('real coordinate value', -1.0, B[1, 3], 0.0);
    AssertEquals('requested CSC', Ord(sfCSC), Ord(B.Format));
  finally
    Stream.Free;
  end;

  C := TSparseComplexMatrix.FromCSC(2, 2, [0, 1, 2],
    [1, 0], [TComplex.Create(2, -1), TComplex.Create(3, 4)]);
  Stream := TMemoryStream.Create;
  try
    WriteSparseMatrixMarket(Stream, C);
    Stream.Position := 0;
    D := ReadSparseMatrixMarketComplex(Stream);
    AssertEquals('complex real', 3.0, D[0, 1].Re, 0.0);
    AssertEquals('complex imaginary', 4.0, D[0, 1].Im, 0.0);
  finally
    Stream.Free;
  end;
end;

procedure TSparseInterchangeTest.TestMatrixMarketRejectsMalformedAndDuplicates;
var
  Stream: TMemoryStream;
  A: ISparseDoubleMatrix;
  Failed: Boolean;
begin
  Stream := StreamFromText(
    '%%MatrixMarket matrix coordinate real general' + LineEnding +
    '2 2 1' + LineEnding + '0 1 2' + LineEnding);
  try
    Failed := False;
    try
      A := ReadSparseMatrixMarketDouble(Stream);
    except
      on EInterchangeError do Failed := True;
    end;
    AssertTrue('zero one-based index rejected', Failed);
  finally
    Stream.Free;
  end;

  Stream := StreamFromText(
    '%%MatrixMarket matrix coordinate real general' + LineEnding +
    '2 2 2' + LineEnding + '1 1 2' + LineEnding +
    '1 1 3' + LineEnding);
  try
    Failed := False;
    try
      A := ReadSparseMatrixMarketDouble(Stream);
    except
      on EInterchangeError do Failed := True;
    end;
    AssertTrue('duplicate policy violation rejected', Failed);
  finally
    Stream.Free;
  end;

  Stream := StreamFromText(
    '%%MatrixMarket matrix coordinate real general' + LineEnding +
    '1000000 2 0' + LineEnding);
  try
    Failed := False;
    try
      A := ReadSparseMatrixMarketDouble(Stream, sfCSR,
        DEFAULT_MAX_INTERCHANGE_ELEMENTS, 100);
    except
      on EInterchangeError do Failed := True;
    end;
    AssertTrue('Matrix Market dimension resource limit enforced', Failed);
  finally
    Stream.Free;
  end;

  A := TSparseDoubleMatrix.FromCSR(1, 1, [0, 1], [0], [0.0], szKeep);
  Stream := TMemoryStream.Create;
  try
    Failed := False;
    try
      WriteSparseMatrixMarket(Stream, A);
    except
      on EInterchangeError do Failed := True;
    end;
    AssertTrue('writer rejects explicit stored zero', Failed);
    AssertEquals('failed write is atomic', Int64(0), Stream.Size);
  finally
    Stream.Free;
  end;

end;

procedure TSparseInterchangeTest.TestBinaryFourScalarRoundTrips;
var
  Stream: TMemoryStream;
  S: ISparseSingleMatrix;
  D: ISparseDoubleMatrix;
  SC: ISparseSingleComplexMatrix;
  C: ISparseComplexMatrix;
begin
  Stream := TMemoryStream.Create;
  try
    S := TSparseSingleMatrix.FromCSR(2, 2, [0, 1, 2], [0, 1],
      [1.25, -2.5]);
    SaveSparseBinary(Stream, S);
    Stream.Position := 0;
    S := LoadSparseSingleBinary(Stream);
    AssertEquals('single binary', -2.5, S[1, 1], 0.0);
  finally
    Stream.Free;
  end;

  Stream := TMemoryStream.Create;
  try
    D := TSparseDoubleMatrix.FromCSC(2, 3, [0, 1, 1, 2],
      [1, 0], [4.0, 9.0]);
    SaveSparseBinary(Stream, D);
    Stream.Position := 0;
    D := LoadSparseDoubleBinary(Stream);
    AssertEquals('double format retained', Ord(sfCSC), Ord(D.Format));
    AssertEquals('double binary', 9.0, D[0, 2], 0.0);
  finally
    Stream.Free;
  end;

  Stream := TMemoryStream.Create;
  try
    SC := TSparseSingleComplexMatrix.FromCSR(1, 1, [0, 1], [0],
      [TSingleComplex.Create(2, -3)]);
    SaveSparseBinary(Stream, SC);
    Stream.Position := 0;
    SC := LoadSparseSingleComplexBinary(Stream);
    AssertEquals('single complex binary imaginary', -3.0, SC[0, 0].Im, 0.0);
  finally
    Stream.Free;
  end;

  Stream := TMemoryStream.Create;
  try
    C := TSparseComplexMatrix.FromCSR(1, 2, [0, 1], [1],
      [TComplex.Create(5, 7)]);
    SaveSparseBinary(Stream, C);
    Stream.Position := 0;
    C := LoadSparseComplexBinary(Stream);
    AssertEquals('complex binary real', 5.0, C[0, 1].Re, 0.0);
    AssertEquals('complex binary imaginary', 7.0, C[0, 1].Im, 0.0);
  finally
    Stream.Free;
  end;

end;

procedure TSparseInterchangeTest.TestBinaryRejectsVersionChecksumTruncationAndLimits;
var
  Stream: TMemoryStream;
  A, Loaded: ISparseDoubleMatrix;
  Failed: Boolean;
  OriginalSize: Int64;
begin
  A := TSparseDoubleMatrix.FromCSR(2, 2, [0, 1, 2],
    [0, 1], [1.0, 2.0]);

  Stream := TMemoryStream.Create;
  try
    SaveSparseBinary(Stream, A);
    PByte(Stream.Memory)[8] := 2;
    Stream.Position := 0;
    Failed := False;
    try
      Loaded := LoadSparseDoubleBinary(Stream);
    except
      on EInterchangeError do Failed := True;
    end;
    AssertTrue('incompatible version rejected', Failed);
  finally
    Stream.Free;
  end;

  Stream := TMemoryStream.Create;
  try
    SaveSparseBinary(Stream, A);
    PByte(Stream.Memory)[Stream.Size - 1] :=
      PByte(Stream.Memory)[Stream.Size - 1] xor $FF;
    Stream.Position := 0;
    Failed := False;
    try
      Loaded := LoadSparseDoubleBinary(Stream);
    except
      on EInterchangeError do Failed := True;
    end;
    AssertTrue('checksum corruption rejected', Failed);
  finally
    Stream.Free;
  end;

  Stream := TMemoryStream.Create;
  try
    SaveSparseBinary(Stream, A);
    OriginalSize := Stream.Size;
    Stream.Size := OriginalSize - 1;
    Stream.Position := 0;
    Failed := False;
    try
      Loaded := LoadSparseDoubleBinary(Stream);
    except
      on EInterchangeError do Failed := True;
    end;
    AssertTrue('truncation rejected', Failed);
  finally
    Stream.Free;
  end;

  Stream := TMemoryStream.Create;
  try
    SaveSparseBinary(Stream, A);
    Stream.Position := 0;
    Failed := False;
    try
      Loaded := LoadSparseDoubleBinary(Stream, 1);
    except
      on EInterchangeError do Failed := True;
    end;
    AssertTrue('nonzero resource limit enforced before result', Failed);
  finally
    Stream.Free;
  end;

  Stream := TMemoryStream.Create;
  try
    SaveSparseBinary(Stream, A);
    Stream.Position := 0;
    Failed := False;
    try
      Loaded := LoadSparseDoubleBinary(Stream,
        DEFAULT_MAX_INTERCHANGE_ELEMENTS, 1);
    except
      on EInterchangeError do Failed := True;
    end;
    AssertTrue('binary dimension resource limit enforced before result',
      Failed);
  finally
    Stream.Free;
  end;
end;

initialization
  RegisterTest(TSparseInterchangeTest);

end.
