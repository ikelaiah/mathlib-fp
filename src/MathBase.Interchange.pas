unit MathBase.Interchange;

{-----------------------------------------------------------------------------
 MathBase.Interchange

 Optional, dependency-free numerical interchange. Persistence is invariant and
 separate from locale-aware display. Binary loads validate version, shape,
 byte count, element limit, and CRC-32 before constructing a result.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math,
  MathBase.SharedTypes, MathBase.Complex, MathBase.Random,
  AlgebraLib.DenseMatrices, AlgebraLib.SparseMatrices;

const
  DEFAULT_MAX_INTERCHANGE_ELEMENTS = 16000000;
  DEFAULT_MAX_SPARSE_DIMENSION = 16000000;

type
  EInterchangeError = class(Exception);
  TInterchangeScalarType = (istFloat64, istComplex128);
  TInterchangeValueKind = (ivkVector, ivkMatrix);
  TValueMetadata = record
    Kind:TInterchangeValueKind;
    ScalarType:TInterchangeScalarType;
    Rows:SizeInt;
    Columns:SizeInt;
    Elements:QWord;
  end;

function ComplexToInvariant(const Value: TComplex): string;
function ParseComplexInvariant(const Text: string): TComplex;
function DoubleVectorToInvariant(const Values: TDoubleArray): string;
function ParseDoubleVectorInvariant(const Text: string;
  const MaxElements: QWord = DEFAULT_MAX_INTERCHANGE_ELEMENTS): TDoubleArray;
function ComplexVectorToInvariant(const Values: TComplexArray): string;
function ParseComplexVectorInvariant(const Text: string;
  const MaxElements: QWord = DEFAULT_MAX_INTERCHANGE_ELEMENTS): TComplexArray;
function DenseMatrixToInvariant(const Matrix: IDenseDoubleMatrix): string;
function ParseDenseMatrixInvariant(const Text: string;
  const MaxElements: QWord = DEFAULT_MAX_INTERCHANGE_ELEMENTS):
  IDenseDoubleMatrix;

procedure WriteDelimitedMatrix(const Stream: TStream;
  const Matrix: IDenseDoubleMatrix; const Delimiter: Char = ',');
function ReadDelimitedMatrix(const Stream: TStream; const Delimiter: Char = ',';
  const MaxElements: QWord = DEFAULT_MAX_INTERCHANGE_ELEMENTS):
  IDenseDoubleMatrix;

procedure WriteMatrixMarket(const Stream: TStream;
  const Matrix: IDenseDoubleMatrix); overload;
procedure WriteMatrixMarket(const Stream: TStream;
  const Matrix: IDenseComplexMatrix); overload;
function ReadMatrixMarketDouble(const Stream: TStream;
  const MaxElements: QWord = DEFAULT_MAX_INTERCHANGE_ELEMENTS):
  IDenseDoubleMatrix;
function ReadMatrixMarketComplex(const Stream: TStream;
  const MaxElements: QWord = DEFAULT_MAX_INTERCHANGE_ELEMENTS):
  IDenseComplexMatrix;
procedure WriteSparseMatrixMarket(const Stream: TStream;
  const Matrix: ISparseDoubleMatrix); overload;
procedure WriteSparseMatrixMarket(const Stream: TStream;
  const Matrix: ISparseComplexMatrix); overload;
function ReadSparseMatrixMarketDouble(const Stream: TStream;
  const Format: TSparseFormat = sfCSR;
  const MaxNonZeros: QWord = DEFAULT_MAX_INTERCHANGE_ELEMENTS;
  const MaxDimension: QWord = DEFAULT_MAX_SPARSE_DIMENSION):
  ISparseDoubleMatrix;
function ReadSparseMatrixMarketComplex(const Stream: TStream;
  const Format: TSparseFormat = sfCSR;
  const MaxNonZeros: QWord = DEFAULT_MAX_INTERCHANGE_ELEMENTS;
  const MaxDimension: QWord = DEFAULT_MAX_SPARSE_DIMENSION):
  ISparseComplexMatrix;

procedure SaveBinary(const Stream: TStream;
  const Values: TDoubleArray); overload;
procedure SaveBinary(const Stream: TStream;
  const Values: TComplexArray); overload;
procedure SaveBinary(const Stream: TStream;
  const Matrix: IDenseDoubleMatrix); overload;
procedure SaveBinary(const Stream: TStream;
  const Matrix: IDenseComplexMatrix); overload;
function LoadDoubleVectorBinary(const Stream: TStream;
  const MaxElements: QWord = DEFAULT_MAX_INTERCHANGE_ELEMENTS): TDoubleArray;
function LoadComplexVectorBinary(const Stream: TStream;
  const MaxElements: QWord = DEFAULT_MAX_INTERCHANGE_ELEMENTS): TComplexArray;
function LoadDoubleMatrixBinary(const Stream: TStream;
  const MaxElements: QWord = DEFAULT_MAX_INTERCHANGE_ELEMENTS):
  IDenseDoubleMatrix;
function LoadComplexMatrixBinary(const Stream: TStream;
  const MaxElements: QWord = DEFAULT_MAX_INTERCHANGE_ELEMENTS):
  IDenseComplexMatrix;
procedure SaveSparseBinary(const Stream: TStream;
  const Matrix: ISparseSingleMatrix); overload;
procedure SaveSparseBinary(const Stream: TStream;
  const Matrix: ISparseDoubleMatrix); overload;
procedure SaveSparseBinary(const Stream: TStream;
  const Matrix: ISparseSingleComplexMatrix); overload;
procedure SaveSparseBinary(const Stream: TStream;
  const Matrix: ISparseComplexMatrix); overload;
function LoadSparseSingleBinary(const Stream: TStream;
  const MaxNonZeros: QWord = DEFAULT_MAX_INTERCHANGE_ELEMENTS;
  const MaxDimension: QWord = DEFAULT_MAX_SPARSE_DIMENSION):
  ISparseSingleMatrix;
function LoadSparseDoubleBinary(const Stream: TStream;
  const MaxNonZeros: QWord = DEFAULT_MAX_INTERCHANGE_ELEMENTS;
  const MaxDimension: QWord = DEFAULT_MAX_SPARSE_DIMENSION):
  ISparseDoubleMatrix;
function LoadSparseSingleComplexBinary(const Stream: TStream;
  const MaxNonZeros: QWord = DEFAULT_MAX_INTERCHANGE_ELEMENTS;
  const MaxDimension: QWord = DEFAULT_MAX_SPARSE_DIMENSION):
  ISparseSingleComplexMatrix;
function LoadSparseComplexBinary(const Stream: TStream;
  const MaxNonZeros: QWord = DEFAULT_MAX_INTERCHANGE_ELEMENTS;
  const MaxDimension: QWord = DEFAULT_MAX_SPARSE_DIMENSION):
  ISparseComplexMatrix;
procedure SaveRandomStateBinary(const Stream: TStream;
  const State: TRandomState);
function LoadRandomStateBinary(const Stream: TStream): TRandomState;

function Summarize(const Values: TDoubleArray;
  const MaximumValues: SizeInt = 8): string; overload;
function Summarize(const Values:TComplexArray;
  const MaximumValues:SizeInt=8):string; overload;
function Summarize(const Matrix: IDenseDoubleMatrix;
  const MaximumRows: SizeInt = 4;
  const MaximumColumns: SizeInt = 6): string; overload;
function Describe(const Values:TDoubleArray):TValueMetadata; overload;
function Describe(const Values:TComplexArray):TValueMetadata; overload;
function Describe(const Matrix:IDenseDoubleMatrix):TValueMetadata; overload;
function Describe(const Matrix:IDenseComplexMatrix):TValueMetadata; overload;

implementation

type
  TBinaryKind = (bkDoubleVector = 1, bkComplexVector = 2,
    bkDoubleMatrix = 3, bkComplexMatrix = 4, bkRandomState = 5,
    bkSparseSingle = 6, bkSparseDouble = 7,
    bkSparseSingleComplex = 8, bkSparseComplex = 9);

  TBinaryHeader = record
    Kind: TBinaryKind;
    Rows, Columns, PayloadBytes: QWord;
    Checksum: LongWord;
  end;

const
  BINARY_MAGIC: array[0..7] of Byte =
    (Ord('M'), Ord('F'), Ord('P'), Ord('B'), Ord('I'), Ord('N'), Ord('1'), 0);
  BINARY_VERSION = 1;
  MAX_TEXT_BYTES_PER_ELEMENT = 96;
  TEXT_BASE_ALLOWANCE = 1048576;

function InvariantFormatSettings: TFormatSettings;
begin
  Result := DefaultFormatSettings;
  Result.DecimalSeparator := '.';
  Result.ThousandSeparator := #0;
end;

function Summarize(const Values:TComplexArray;
  const MaximumValues:SizeInt):string;
var
  Builder:TStringBuilder;
  I,DisplayCount:SizeInt;
begin
  if MaximumValues<0 then
    raise EInterchangeError.Create(
      'Summarize(complex vector): MaximumValues must be non-negative.');
  Builder:=TStringBuilder.Create;
  try
    Builder.Append('Complex vector length=').Append(IntToStr(Length(Values))).
      Append(' [');
    DisplayCount:=Min(Length(Values),MaximumValues);
    for I:=0 to DisplayCount-1 do
    begin
      if I>0 then Builder.Append(', ');
      Builder.Append(ComplexToInvariant(Values[I]));
    end;
    if DisplayCount<Length(Values) then Builder.Append(', ...');
    Builder.Append(']');
    Result:=Builder.ToString;
  finally
    Builder.Free;
  end;
end;

procedure RequireFinite(const Value: Double; const Operation: string);
begin
  if IsNan(Value) or IsInfinite(Value) then
    raise EInterchangeError.Create(Operation + ': values must be finite.');
end;

procedure RequireMatrix(const Matrix: IDenseDoubleMatrix;
  const Operation: string); overload;
var
  RowIndex, ColumnIndex: SizeInt;
begin
  if Matrix = nil then
    raise EInterchangeError.Create(Operation +
      ': matrix handle must not be nil.');
  for RowIndex := 0 to Matrix.Rows - 1 do
    for ColumnIndex := 0 to Matrix.Cols - 1 do
      RequireFinite(Matrix[RowIndex, ColumnIndex], Operation);
end;

procedure RequireMatrix(const Matrix: IDenseComplexMatrix;
  const Operation: string); overload;
var
  RowIndex, ColumnIndex: SizeInt;
begin
  if Matrix = nil then
    raise EInterchangeError.Create(Operation +
      ': matrix handle must not be nil.');
  for RowIndex := 0 to Matrix.Rows - 1 do
    for ColumnIndex := 0 to Matrix.Cols - 1 do
      if not Matrix[RowIndex, ColumnIndex].IsFinite then
        raise EInterchangeError.Create(Operation +
          ': matrix values must be finite.');
end;

function ParseInvariantFloat(const Text, Operation: string): Double;
var
  Settings: TFormatSettings;
begin
  Settings := InvariantFormatSettings;
  if not TryStrToFloat(Trim(Text), Result, Settings) then
    raise EInterchangeError.CreateFmt('%s: invalid invariant number "%s".',
      [Operation, Text]);
  RequireFinite(Result, Operation);
end;

function FloatInvariant(const Value: Double): string;
var
  Settings: TFormatSettings;
begin
  RequireFinite(Value, 'FloatInvariant');
  Settings := InvariantFormatSettings;
  Result := FloatToStr(Value, Settings);
end;

function ComplexToInvariant(const Value: TComplex): string;
begin
  if not Value.IsFinite then
    raise EInterchangeError.Create(
      'ComplexToInvariant: real and imaginary parts must be finite.');
  Result := '(' + FloatInvariant(Value.Re) + ',' +
    FloatInvariant(Value.Im) + ')';
end;

function ParseComplexInvariant(const Text: string): TComplex;
var
  Value, RealText, ImaginaryText: string;
  Separator: SizeInt;
begin
  Value := Trim(Text);
  if (Length(Value) < 5) or (Value[1] <> '(') or
     (Value[Length(Value)] <> ')') then
    raise EInterchangeError.Create(
      'ParseComplexInvariant: expected "(real,imaginary)".');
  Value := Copy(Value, 2, Length(Value) - 2);
  Separator := Pos(',', Value);
  if (Separator <= 1) or (Separator = Length(Value)) or
     (Pos(',', Copy(Value, Separator + 1, MaxInt)) <> 0) then
    raise EInterchangeError.Create(
      'ParseComplexInvariant: expected exactly two components.');
  RealText := Copy(Value, 1, Separator - 1);
  ImaginaryText := Copy(Value, Separator + 1, MaxInt);
  Result := TComplex.Create(
    ParseInvariantFloat(RealText, 'ParseComplexInvariant'),
    ParseInvariantFloat(ImaginaryText, 'ParseComplexInvariant'));
end;

function StripBrackets(const Text, Operation: string): string;
begin
  Result := Trim(Text);
  if (Length(Result) < 2) or (Result[1] <> '[') or
     (Result[Length(Result)] <> ']') then
    raise EInterchangeError.Create(Operation +
      ': expected surrounding square brackets.');
  Result := Copy(Result, 2, Length(Result) - 2);
end;

function DoubleVectorToInvariant(const Values: TDoubleArray): string;
var
  Builder: TStringBuilder;
  I: SizeInt;
begin
  Builder := TStringBuilder.Create;
  try
    Builder.Append('[');
    for I := 0 to High(Values) do
    begin
      if I > 0 then Builder.Append(',');
      Builder.Append(FloatInvariant(Values[I]));
    end;
    Builder.Append(']');
    Result := Builder.ToString;
  finally
    Builder.Free;
  end;
end;

function SplitStrict(const Text: string; const Delimiter: Char): TStringList;
begin
  Result := TStringList.Create;
  Result.StrictDelimiter := True;
  Result.Delimiter := Delimiter;
  Result.DelimitedText := Text;
end;

function ParseDoubleVectorInvariant(const Text: string;
  const MaxElements: QWord): TDoubleArray;
var
  Inner: string;
  Parts: TStringList;
  I: SizeInt;
begin
  Result := nil;
  Inner := StripBrackets(Text, 'ParseDoubleVectorInvariant');
  if Trim(Inner) = '' then Exit;
  Parts := SplitStrict(Inner, ',');
  try
    if QWord(Parts.Count) > MaxElements then
      raise EInterchangeError.CreateFmt(
        'ParseDoubleVectorInvariant: %d elements exceed limit %d.',
        [Parts.Count, MaxElements]);
    SetLength(Result, Parts.Count);
    for I := 0 to Parts.Count - 1 do
      Result[I] := ParseInvariantFloat(Parts[I],
        'ParseDoubleVectorInvariant');
  finally
    Parts.Free;
  end;
end;

function ComplexVectorToInvariant(const Values: TComplexArray): string;
var
  Builder: TStringBuilder;
  I: SizeInt;
begin
  Builder := TStringBuilder.Create;
  try
    Builder.Append('[');
    for I := 0 to High(Values) do
    begin
      if I > 0 then Builder.Append(';');
      Builder.Append(ComplexToInvariant(Values[I]));
    end;
    Builder.Append(']');
    Result := Builder.ToString;
  finally
    Builder.Free;
  end;
end;

function ParseComplexVectorInvariant(const Text: string;
  const MaxElements: QWord): TComplexArray;
var
  Inner: string;
  Parts: TStringList;
  I: SizeInt;
begin
  Result := nil;
  Inner := StripBrackets(Text, 'ParseComplexVectorInvariant');
  if Trim(Inner) = '' then Exit;
  Parts := SplitStrict(Inner, ';');
  try
    if QWord(Parts.Count) > MaxElements then
      raise EInterchangeError.CreateFmt(
        'ParseComplexVectorInvariant: %d elements exceed limit %d.',
        [Parts.Count, MaxElements]);
    SetLength(Result, Parts.Count);
    for I := 0 to Parts.Count - 1 do
      Result[I] := ParseComplexInvariant(Parts[I]);
  finally
    Parts.Free;
  end;
end;

function DenseMatrixToInvariant(const Matrix: IDenseDoubleMatrix): string;
var
  Builder: TStringBuilder;
  RowIndex, ColumnIndex: SizeInt;
begin
  RequireMatrix(Matrix, 'DenseMatrixToInvariant');
  Builder := TStringBuilder.Create;
  try
    Builder.Append('[');
    for RowIndex := 0 to Matrix.Rows - 1 do
    begin
      if RowIndex > 0 then Builder.Append(';');
      for ColumnIndex := 0 to Matrix.Cols - 1 do
      begin
        if ColumnIndex > 0 then Builder.Append(',');
        Builder.Append(FloatInvariant(Matrix[RowIndex, ColumnIndex]));
      end;
    end;
    Builder.Append(']');
    Result := Builder.ToString;
  finally
    Builder.Free;
  end;
end;

function ParseDenseMatrixInvariant(const Text: string;
  const MaxElements: QWord): IDenseDoubleMatrix;
var
  Inner: string;
  Rows, Fields: TStringList;
  RowIndex, ColumnIndex, ColumnCount: SizeInt;
  ElementCount: QWord;
begin
  Inner := StripBrackets(Text, 'ParseDenseMatrixInvariant');
  if Trim(Inner) = '' then
    Exit(TDenseDoubleMatrix.Zeros(0, 0));
  Rows := SplitStrict(Inner, ';');
  try
    ColumnCount := -1;
    for RowIndex := 0 to Rows.Count - 1 do
    begin
      Fields := SplitStrict(Rows[RowIndex], ',');
      try
        if ColumnCount < 0 then ColumnCount := Fields.Count;
        if (Fields.Count = 0) or (Fields.Count <> ColumnCount) then
          raise EInterchangeError.Create(
            'ParseDenseMatrixInvariant: rows must be non-empty and rectangular.');
      finally
        Fields.Free;
      end;
    end;
    ElementCount := QWord(Rows.Count) * QWord(ColumnCount);
    if ElementCount > MaxElements then
      raise EInterchangeError.CreateFmt(
        'ParseDenseMatrixInvariant: %d elements exceed limit %d.',
        [ElementCount, MaxElements]);
    Result := TDenseDoubleMatrix.Zeros(Rows.Count, ColumnCount);
    for RowIndex := 0 to Rows.Count - 1 do
    begin
      Fields := SplitStrict(Rows[RowIndex], ',');
      try
        for ColumnIndex := 0 to ColumnCount - 1 do
          Result[RowIndex, ColumnIndex] := ParseInvariantFloat(
            Fields[ColumnIndex], 'ParseDenseMatrixInvariant');
      finally
        Fields.Free;
      end;
    end;
  finally
    Rows.Free;
  end;
end;

procedure WriteString(const Stream: TStream; const Text: string);
begin
  if Stream = nil then
    raise EInterchangeError.Create('WriteString: Stream must not be nil.');
  if Length(Text) > 0 then
    Stream.WriteBuffer(Text[1], Length(Text));
end;

function ReadTextLimited(const Stream: TStream; const MaxElements: QWord;
  const Operation: string): string;
var
  Buffer: array[0..8191] of Byte;
  Memory: TMemoryStream;
  Count: LongInt;
  MaximumBytes, CurrentBytes: QWord;
begin
  if Stream = nil then
    raise EInterchangeError.Create(Operation + ': Stream must not be nil.');
  if MaxElements > (High(QWord) - TEXT_BASE_ALLOWANCE) div
     MAX_TEXT_BYTES_PER_ELEMENT then
    MaximumBytes := High(QWord)
  else
    MaximumBytes := MaxElements * MAX_TEXT_BYTES_PER_ELEMENT +
      TEXT_BASE_ALLOWANCE;
  Memory := TMemoryStream.Create;
  try
    CurrentBytes := 0;
    repeat
      Count := Stream.Read(Buffer, SizeOf(Buffer));
      if Count < 0 then
        raise EInterchangeError.Create(Operation + ': stream read failed.');
      if QWord(Count) > MaximumBytes - CurrentBytes then
        raise EInterchangeError.CreateFmt(
          '%s: text input exceeds the configured size limit.', [Operation]);
      if Count > 0 then Memory.WriteBuffer(Buffer, Count);
      Inc(CurrentBytes, Count);
    until Count = 0;
    SetLength(Result, Memory.Size);
    if Memory.Size > 0 then
    begin
      Memory.Position := 0;
      Memory.ReadBuffer(Result[1], Memory.Size);
    end;
  finally
    Memory.Free;
  end;
end;

procedure WriteDelimitedMatrix(const Stream: TStream;
  const Matrix: IDenseDoubleMatrix; const Delimiter: Char);
var
  Builder: TStringBuilder;
  RowIndex, ColumnIndex: SizeInt;
begin
  RequireMatrix(Matrix, 'WriteDelimitedMatrix');
  if Delimiter in [#0, #10, #13, '"', '+', '-', '.', '0'..'9'] then
    raise EInterchangeError.Create(
      'WriteDelimitedMatrix: Delimiter must not conflict with numeric syntax.');
  Builder := TStringBuilder.Create;
  try
    for RowIndex := 0 to Matrix.Rows - 1 do
    begin
      for ColumnIndex := 0 to Matrix.Cols - 1 do
      begin
        if ColumnIndex > 0 then Builder.Append(Delimiter);
        Builder.Append(FloatInvariant(Matrix[RowIndex, ColumnIndex]));
      end;
      Builder.Append(LineEnding);
    end;
    WriteString(Stream, Builder.ToString);
  finally
    Builder.Free;
  end;
end;

function ReadDelimitedMatrix(const Stream: TStream; const Delimiter: Char;
  const MaxElements: QWord): IDenseDoubleMatrix;
var
  Text: string;
  Lines, Fields: TStringList;
  RowIndex, ColumnIndex, ColumnCount, EffectiveRows: SizeInt;
  ElementCount: QWord;
begin
  Text := ReadTextLimited(Stream, MaxElements, 'ReadDelimitedMatrix');
  Lines := TStringList.Create;
  try
    Lines.Text := Text;
    while (Lines.Count > 0) and
      (Trim(Lines[Lines.Count - 1]) = '') do
      Lines.Delete(Lines.Count - 1);
    if Lines.Count = 0 then
      Exit(TDenseDoubleMatrix.Zeros(0, 0));
    EffectiveRows := Lines.Count;
    ColumnCount := -1;
    for RowIndex := 0 to EffectiveRows - 1 do
    begin
      if Trim(Lines[RowIndex]) = '' then
        raise EInterchangeError.Create(
          'ReadDelimitedMatrix: blank rows are not permitted.');
      Fields := SplitStrict(Lines[RowIndex], Delimiter);
      try
        if ColumnCount < 0 then ColumnCount := Fields.Count;
        if (Fields.Count = 0) or (Fields.Count <> ColumnCount) then
          raise EInterchangeError.Create(
            'ReadDelimitedMatrix: rows must be non-empty and rectangular.');
      finally
        Fields.Free;
      end;
    end;
    ElementCount := QWord(EffectiveRows) * QWord(ColumnCount);
    if ElementCount > MaxElements then
      raise EInterchangeError.CreateFmt(
        'ReadDelimitedMatrix: %d elements exceed limit %d.',
        [ElementCount, MaxElements]);
    Result := TDenseDoubleMatrix.Zeros(EffectiveRows, ColumnCount);
    for RowIndex := 0 to EffectiveRows - 1 do
    begin
      Fields := SplitStrict(Lines[RowIndex], Delimiter);
      try
        for ColumnIndex := 0 to ColumnCount - 1 do
          Result[RowIndex, ColumnIndex] := ParseInvariantFloat(
            Fields[ColumnIndex], 'ReadDelimitedMatrix');
      finally
        Fields.Free;
      end;
    end;
  finally
    Lines.Free;
  end;
end;

procedure WriteMatrixMarket(const Stream: TStream;
  const Matrix: IDenseDoubleMatrix);
var
  Builder: TStringBuilder;
  RowIndex, ColumnIndex: SizeInt;
begin
  RequireMatrix(Matrix, 'WriteMatrixMarket(double)');
  Builder := TStringBuilder.Create;
  try
    Builder.Append('%%MatrixMarket matrix array real general').Append(LineEnding);
    Builder.Append(IntToStr(Matrix.Rows)).Append(' ').
      Append(IntToStr(Matrix.Cols)).Append(LineEnding);
    for ColumnIndex := 0 to Matrix.Cols - 1 do
      for RowIndex := 0 to Matrix.Rows - 1 do
        Builder.Append(FloatInvariant(Matrix[RowIndex, ColumnIndex])).
          Append(LineEnding);
    WriteString(Stream, Builder.ToString);
  finally
    Builder.Free;
  end;
end;

procedure WriteMatrixMarket(const Stream: TStream;
  const Matrix: IDenseComplexMatrix);
var
  Builder: TStringBuilder;
  RowIndex, ColumnIndex: SizeInt;
begin
  RequireMatrix(Matrix, 'WriteMatrixMarket(complex)');
  Builder := TStringBuilder.Create;
  try
    Builder.Append('%%MatrixMarket matrix array complex general').
      Append(LineEnding);
    Builder.Append(IntToStr(Matrix.Rows)).Append(' ').
      Append(IntToStr(Matrix.Cols)).Append(LineEnding);
    for ColumnIndex := 0 to Matrix.Cols - 1 do
      for RowIndex := 0 to Matrix.Rows - 1 do
        Builder.Append(FloatInvariant(Matrix[RowIndex, ColumnIndex].Re)).
          Append(' ').
          Append(FloatInvariant(Matrix[RowIndex, ColumnIndex].Im)).
          Append(LineEnding);
    WriteString(Stream, Builder.ToString);
  finally
    Builder.Free;
  end;
end;

function MatrixMarketLines(const Stream: TStream;
  const MaxElements: QWord; const Operation: string): TStringList;
var
  Text: string;
  Index: Integer;
begin
  Text := ReadTextLimited(Stream, MaxElements, Operation);
  Result := TStringList.Create;
  Result.Text := Text;
  Index := 1;
  while Index < Result.Count do
    if (Trim(Result[Index]) <> '') and (Trim(Result[Index])[1] = '%') then
      Result.Delete(Index)
    else
      Inc(Index);
end;

procedure ParseMatrixMarketShape(const Line, Operation: string;
  out Rows, Columns: SizeInt; const MaxElements: QWord);
var
  Fields: TStringList;
  Rows64, Columns64, Elements: QWord;
begin
  Fields := SplitStrict(Trim(Line), ' ');
  try
    while Fields.IndexOf('') >= 0 do Fields.Delete(Fields.IndexOf(''));
    if (Fields.Count <> 2) or
       not TryStrToQWord(Fields[0], Rows64) or
       not TryStrToQWord(Fields[1], Columns64) then
      raise EInterchangeError.Create(Operation +
        ': invalid Matrix Market shape line.');
    if (Rows64 > QWord(High(SizeInt))) or
       (Columns64 > QWord(High(SizeInt))) then
      raise EInterchangeError.Create(Operation +
        ': Matrix Market dimensions exceed platform limits.');
    if (Rows64 <> 0) and (Columns64 > High(QWord) div Rows64) then
      raise EInterchangeError.Create(Operation +
        ': Matrix Market element count overflow.');
    Elements := Rows64 * Columns64;
    if Elements > MaxElements then
      raise EInterchangeError.CreateFmt(
        '%s: %d elements exceed limit %d.',
        [Operation, Elements, MaxElements]);
    Rows := Rows64;
    Columns := Columns64;
  finally
    Fields.Free;
  end;
end;

function ReadMatrixMarketDouble(const Stream: TStream;
  const MaxElements: QWord): IDenseDoubleMatrix;
var
  Lines: TStringList;
  Rows, Columns, RowIndex, ColumnIndex, ValueIndex: SizeInt;
begin
  Lines := MatrixMarketLines(Stream, MaxElements, 'ReadMatrixMarketDouble');
  try
    if (Lines.Count < 2) or
       (LowerCase(Trim(Lines[0])) <>
        '%%matrixmarket matrix array real general') then
      raise EInterchangeError.Create(
        'ReadMatrixMarketDouble: expected dense real Matrix Market array.');
    ParseMatrixMarketShape(Lines[1], 'ReadMatrixMarketDouble',
      Rows, Columns, MaxElements);
    if QWord(Lines.Count - 2) <> QWord(Rows) * QWord(Columns) then
      raise EInterchangeError.Create(
        'ReadMatrixMarketDouble: payload value count does not match shape.');
    Result := TDenseDoubleMatrix.Zeros(Rows, Columns);
    ValueIndex := 2;
    for ColumnIndex := 0 to Columns - 1 do
      for RowIndex := 0 to Rows - 1 do
      begin
        Result[RowIndex, ColumnIndex] := ParseInvariantFloat(
          Lines[ValueIndex], 'ReadMatrixMarketDouble');
        Inc(ValueIndex);
      end;
  finally
    Lines.Free;
  end;
end;

function ReadMatrixMarketComplex(const Stream: TStream;
  const MaxElements: QWord): IDenseComplexMatrix;
var
  Lines, Fields: TStringList;
  Rows, Columns, RowIndex, ColumnIndex, ValueIndex: SizeInt;
begin
  Lines := MatrixMarketLines(Stream, MaxElements, 'ReadMatrixMarketComplex');
  try
    if (Lines.Count < 2) or
       (LowerCase(Trim(Lines[0])) <>
        '%%matrixmarket matrix array complex general') then
      raise EInterchangeError.Create(
        'ReadMatrixMarketComplex: expected dense complex Matrix Market array.');
    ParseMatrixMarketShape(Lines[1], 'ReadMatrixMarketComplex',
      Rows, Columns, MaxElements);
    if QWord(Lines.Count - 2) <> QWord(Rows) * QWord(Columns) then
      raise EInterchangeError.Create(
        'ReadMatrixMarketComplex: payload value count does not match shape.');
    Result := TDenseComplexMatrix.Zeros(Rows, Columns);
    ValueIndex := 2;
    for ColumnIndex := 0 to Columns - 1 do
      for RowIndex := 0 to Rows - 1 do
      begin
        Fields := SplitStrict(Trim(Lines[ValueIndex]), ' ');
        try
          while Fields.IndexOf('') >= 0 do Fields.Delete(Fields.IndexOf(''));
          if Fields.Count <> 2 then
            raise EInterchangeError.Create(
              'ReadMatrixMarketComplex: each value needs real and imaginary fields.');
          Result[RowIndex, ColumnIndex] := TComplex.Create(
            ParseInvariantFloat(Fields[0], 'ReadMatrixMarketComplex'),
            ParseInvariantFloat(Fields[1], 'ReadMatrixMarketComplex'));
        finally
          Fields.Free;
        end;
        Inc(ValueIndex);
      end;
  finally
    Lines.Free;
  end;
end;

procedure WriteSparseMatrixMarket(const Stream: TStream;
  const Matrix: ISparseDoubleMatrix);
var
  Builder: TStringBuilder;
  OuterIndex, K, RowIndex, ColumnIndex: SizeInt;
begin
  if Matrix = nil then
    raise EInterchangeError.Create(
      'WriteSparseMatrixMarket(double): matrix must not be nil.');
  for K := 0 to Matrix.NonZeroCount - 1 do
    if Matrix.GetStoredValue(K) = 0.0 then
      raise EInterchangeError.Create(
        'WriteSparseMatrixMarket(double): explicit stored zeros are outside the canonical coordinate subset.');
  Builder := TStringBuilder.Create;
  try
    Builder.Append('%%MatrixMarket matrix coordinate real general').
      Append(LineEnding);
    Builder.Append(IntToStr(Matrix.Rows)).Append(' ').
      Append(IntToStr(Matrix.Cols)).Append(' ').
      Append(IntToStr(Matrix.NonZeroCount)).Append(LineEnding);
    if Matrix.Format = sfCSR then
      for OuterIndex := 0 to Matrix.Rows - 1 do
        for K := Matrix.GetOuterPointer(OuterIndex) to
          Matrix.GetOuterPointer(OuterIndex + 1) - 1 do
          Builder.Append(IntToStr(OuterIndex + 1)).Append(' ').
            Append(IntToStr(Matrix.GetInnerIndex(K) + 1)).Append(' ').
            Append(FloatInvariant(Matrix.GetStoredValue(K))).Append(LineEnding)
    else
      for OuterIndex := 0 to Matrix.Cols - 1 do
        for K := Matrix.GetOuterPointer(OuterIndex) to
          Matrix.GetOuterPointer(OuterIndex + 1) - 1 do
        begin
          RowIndex := Matrix.GetInnerIndex(K);
          ColumnIndex := OuterIndex;
          Builder.Append(IntToStr(RowIndex + 1)).Append(' ').
            Append(IntToStr(ColumnIndex + 1)).Append(' ').
            Append(FloatInvariant(Matrix.GetStoredValue(K))).Append(LineEnding);
        end;
    WriteString(Stream, Builder.ToString);
  finally
    Builder.Free;
  end;
end;

procedure WriteSparseMatrixMarket(const Stream: TStream;
  const Matrix: ISparseComplexMatrix);
var
  Builder: TStringBuilder;
  OuterIndex, K, RowIndex, ColumnIndex: SizeInt;
  Value: TComplex;
begin
  if Matrix = nil then
    raise EInterchangeError.Create(
      'WriteSparseMatrixMarket(complex): matrix must not be nil.');
  for K := 0 to Matrix.NonZeroCount - 1 do
  begin
    Value := Matrix.GetStoredValue(K);
    if (Value.Re = 0.0) and (Value.Im = 0.0) then
      raise EInterchangeError.Create(
        'WriteSparseMatrixMarket(complex): explicit stored zeros are outside the canonical coordinate subset.');
  end;
  Builder := TStringBuilder.Create;
  try
    Builder.Append('%%MatrixMarket matrix coordinate complex general').
      Append(LineEnding);
    Builder.Append(IntToStr(Matrix.Rows)).Append(' ').
      Append(IntToStr(Matrix.Cols)).Append(' ').
      Append(IntToStr(Matrix.NonZeroCount)).Append(LineEnding);
    if Matrix.Format = sfCSR then
      for OuterIndex := 0 to Matrix.Rows - 1 do
        for K := Matrix.GetOuterPointer(OuterIndex) to
          Matrix.GetOuterPointer(OuterIndex + 1) - 1 do
        begin
          Value := Matrix.GetStoredValue(K);
          Builder.Append(IntToStr(OuterIndex + 1)).Append(' ').
            Append(IntToStr(Matrix.GetInnerIndex(K) + 1)).Append(' ').
            Append(FloatInvariant(Value.Re)).Append(' ').
            Append(FloatInvariant(Value.Im)).Append(LineEnding);
        end
    else
      for OuterIndex := 0 to Matrix.Cols - 1 do
        for K := Matrix.GetOuterPointer(OuterIndex) to
          Matrix.GetOuterPointer(OuterIndex + 1) - 1 do
        begin
          RowIndex := Matrix.GetInnerIndex(K);
          ColumnIndex := OuterIndex;
          Value := Matrix.GetStoredValue(K);
          Builder.Append(IntToStr(RowIndex + 1)).Append(' ').
            Append(IntToStr(ColumnIndex + 1)).Append(' ').
            Append(FloatInvariant(Value.Re)).Append(' ').
            Append(FloatInvariant(Value.Im)).Append(LineEnding);
        end;
    WriteString(Stream, Builder.ToString);
  finally
    Builder.Free;
  end;
end;

procedure ParseSparseMatrixMarketShape(const Line, Operation: string;
  const MaxNonZeros, MaxDimension: QWord;
  out Rows, Columns, NonZeros: SizeInt);
var
  Fields: TStringList;
  Rows64, Columns64, NonZeros64: QWord;
begin
  Fields := SplitStrict(Trim(Line), ' ');
  try
    while Fields.IndexOf('') >= 0 do Fields.Delete(Fields.IndexOf(''));
    if (Fields.Count <> 3) or
       not TryStrToQWord(Fields[0], Rows64) or
       not TryStrToQWord(Fields[1], Columns64) or
       not TryStrToQWord(Fields[2], NonZeros64) then
      raise EInterchangeError.Create(
        Operation + ': invalid coordinate shape line.');
    if (Rows64 > QWord(High(SizeInt))) or
       (Columns64 > QWord(High(SizeInt))) or
       (NonZeros64 > QWord(High(SizeInt))) then
      raise EInterchangeError.Create(
        Operation + ': shape or nonzero count exceeds platform limits.');
    if NonZeros64 > MaxNonZeros then
      raise EInterchangeError.CreateFmt(
        '%s: declared %d nonzeros exceed limit %d.',
        [Operation, NonZeros64, MaxNonZeros]);
    if (Rows64 > MaxDimension) or (Columns64 > MaxDimension) then
      raise EInterchangeError.CreateFmt(
        '%s: declared shape %d x %d exceeds dimension limit %d.',
        [Operation, Rows64, Columns64, MaxDimension]);
    Rows := SizeInt(Rows64);
    Columns := SizeInt(Columns64);
    NonZeros := SizeInt(NonZeros64);
  finally
    Fields.Free;
  end;
end;

function ReadSparseMatrixMarketDouble(const Stream: TStream;
  const Format: TSparseFormat; const MaxNonZeros, MaxDimension: QWord):
  ISparseDoubleMatrix;
var
  Lines, Fields: TStringList;
  Builder: TSparseDoubleTripletBuilder;
  Rows, Columns, NonZeros, I: SizeInt;
  Row64, Column64: QWord;
begin
  Lines := MatrixMarketLines(Stream, MaxNonZeros,
    'ReadSparseMatrixMarketDouble');
  try
    if (Lines.Count < 2) or
       (LowerCase(Trim(Lines[0])) <>
        '%%matrixmarket matrix coordinate real general') then
      raise EInterchangeError.Create(
        'ReadSparseMatrixMarketDouble: expected coordinate real general.');
    ParseSparseMatrixMarketShape(Lines[1],
      'ReadSparseMatrixMarketDouble', MaxNonZeros, MaxDimension,
      Rows, Columns, NonZeros);
    if Lines.Count - 2 <> NonZeros then
      raise EInterchangeError.Create(
        'ReadSparseMatrixMarketDouble: payload count does not match declaration.');
    Builder := TSparseDoubleTripletBuilder.Create(Rows, Columns);
    try
      for I := 0 to NonZeros - 1 do
      begin
        Fields := SplitStrict(Trim(Lines[I + 2]), ' ');
        try
          while Fields.IndexOf('') >= 0 do Fields.Delete(Fields.IndexOf(''));
          if (Fields.Count <> 3) or
             not TryStrToQWord(Fields[0], Row64) or
             not TryStrToQWord(Fields[1], Column64) or
             (Row64 = 0) or (Column64 = 0) or
             (Row64 > QWord(Rows)) or (Column64 > QWord(Columns)) then
            raise EInterchangeError.Create(
              'ReadSparseMatrixMarketDouble: invalid one-based coordinate.');
          Builder.Add(SizeInt(Row64 - 1), SizeInt(Column64 - 1),
            ParseInvariantFloat(Fields[2],
              'ReadSparseMatrixMarketDouble'));
        finally
          Fields.Free;
        end;
      end;
      if Format = sfCSR then Result := Builder.ToCSR(szDrop)
      else Result := Builder.ToCSC(szDrop);
      if Result.NonZeroCount <> NonZeros then
        raise EInterchangeError.Create(
          'ReadSparseMatrixMarketDouble: duplicates or explicit zeros are outside the canonical subset.');
    finally
      Builder.Free;
    end;
  finally
    Lines.Free;
  end;
end;

function ReadSparseMatrixMarketComplex(const Stream: TStream;
  const Format: TSparseFormat; const MaxNonZeros, MaxDimension: QWord):
  ISparseComplexMatrix;
var
  Lines, Fields: TStringList;
  Builder: TSparseComplexTripletBuilder;
  Rows, Columns, NonZeros, I: SizeInt;
  Row64, Column64: QWord;
begin
  Lines := MatrixMarketLines(Stream, MaxNonZeros,
    'ReadSparseMatrixMarketComplex');
  try
    if (Lines.Count < 2) or
       (LowerCase(Trim(Lines[0])) <>
        '%%matrixmarket matrix coordinate complex general') then
      raise EInterchangeError.Create(
        'ReadSparseMatrixMarketComplex: expected coordinate complex general.');
    ParseSparseMatrixMarketShape(Lines[1],
      'ReadSparseMatrixMarketComplex', MaxNonZeros, MaxDimension,
      Rows, Columns, NonZeros);
    if Lines.Count - 2 <> NonZeros then
      raise EInterchangeError.Create(
        'ReadSparseMatrixMarketComplex: payload count does not match declaration.');
    Builder := TSparseComplexTripletBuilder.Create(Rows, Columns);
    try
      for I := 0 to NonZeros - 1 do
      begin
        Fields := SplitStrict(Trim(Lines[I + 2]), ' ');
        try
          while Fields.IndexOf('') >= 0 do Fields.Delete(Fields.IndexOf(''));
          if (Fields.Count <> 4) or
             not TryStrToQWord(Fields[0], Row64) or
             not TryStrToQWord(Fields[1], Column64) or
             (Row64 = 0) or (Column64 = 0) or
             (Row64 > QWord(Rows)) or (Column64 > QWord(Columns)) then
            raise EInterchangeError.Create(
              'ReadSparseMatrixMarketComplex: invalid one-based coordinate.');
          Builder.Add(SizeInt(Row64 - 1), SizeInt(Column64 - 1),
            TComplex.Create(
              ParseInvariantFloat(Fields[2],
                'ReadSparseMatrixMarketComplex'),
              ParseInvariantFloat(Fields[3],
                'ReadSparseMatrixMarketComplex')));
        finally
          Fields.Free;
        end;
      end;
      if Format = sfCSR then Result := Builder.ToCSR(szDrop)
      else Result := Builder.ToCSC(szDrop);
      if Result.NonZeroCount <> NonZeros then
        raise EInterchangeError.Create(
          'ReadSparseMatrixMarketComplex: duplicates or explicit zeros are outside the canonical subset.');
    finally
      Builder.Free;
    end;
  finally
    Lines.Free;
  end;
end;

procedure WriteBytes(const Stream: TStream; const Bytes; const Count: SizeInt);
begin
  if Stream = nil then
    raise EInterchangeError.Create('SaveBinary: Stream must not be nil.');
  if Count > 0 then Stream.WriteBuffer(Bytes, Count);
end;

procedure WriteUInt16LE(const Stream: TStream; const Value: Word);
var
  Bytes: array[0..1] of Byte;
begin
  Bytes[0] := Value and $FF;
  Bytes[1] := Value shr 8;
  WriteBytes(Stream, Bytes, SizeOf(Bytes));
end;

procedure WriteUInt32LE(const Stream: TStream; const Value: LongWord);
var
  Bytes: array[0..3] of Byte;
  I: Integer;
begin
  for I := 0 to 3 do Bytes[I] := (Value shr (8 * I)) and $FF;
  WriteBytes(Stream, Bytes, SizeOf(Bytes));
end;

procedure WriteUInt64LE(const Stream: TStream; const Value: QWord);
var
  Bytes: array[0..7] of Byte;
  I: Integer;
begin
  for I := 0 to 7 do Bytes[I] := (Value shr (8 * I)) and $FF;
  WriteBytes(Stream, Bytes, SizeOf(Bytes));
end;

function CRC32(const Bytes: TBytes): LongWord;
var
  I, BitIndex: SizeInt;
  Value: LongWord;
begin
  Value := $FFFFFFFF;
  for I := 0 to High(Bytes) do
  begin
    Value := Value xor Bytes[I];
    for BitIndex := 0 to 7 do
      if (Value and 1) <> 0 then
        Value := (Value shr 1) xor $EDB88320
      else
        Value := Value shr 1;
  end;
  Result := not Value;
end;

procedure PutUInt64LE(var Bytes: TBytes; const Offset: SizeInt;
  const Value: QWord);
var
  I: Integer;
begin
  for I := 0 to 7 do Bytes[Offset + I] := (Value shr (8 * I)) and $FF;
end;

procedure PutUInt32LE(var Bytes: TBytes; const Offset: SizeInt;
  const Value: LongWord); overload;
var
  I: Integer;
begin
  for I := 0 to 3 do Bytes[Offset + I] := (Value shr (8 * I)) and $FF;
end;

function GetUInt64LE(const Bytes: TBytes; const Offset: SizeInt): QWord;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to 7 do
    Result := Result or (QWord(Bytes[Offset + I]) shl (8 * I));
end;

function GetUInt32LE(const Bytes: TBytes;
  const Offset: SizeInt): LongWord; overload;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to 3 do
    Result := Result or (LongWord(Bytes[Offset + I]) shl (8 * I));
end;

procedure PutDoubleLE(var Bytes: TBytes; const Offset: SizeInt;
  const Value: Double);
var
  Bits: QWord;
begin
  Move(Value, Bits, SizeOf(Bits));
  PutUInt64LE(Bytes, Offset, Bits);
end;

function GetDoubleLE(const Bytes: TBytes; const Offset: SizeInt): Double;
var
  Bits: QWord;
begin
  Bits := GetUInt64LE(Bytes, Offset);
  Move(Bits, Result, SizeOf(Result));
end;

procedure PutSingleLE(var Bytes: TBytes; const Offset: SizeInt;
  const Value: Single);
var
  Bits: LongWord;
begin
  Move(Value, Bits, SizeOf(Bits));
  PutUInt32LE(Bytes, Offset, Bits);
end;

function GetSingleLE(const Bytes: TBytes; const Offset: SizeInt): Single;
var
  Bits: LongWord;
begin
  Bits := GetUInt32LE(Bytes, Offset);
  Move(Bits, Result, SizeOf(Result));
end;

procedure WriteBinaryObject(const Stream: TStream; const Kind: TBinaryKind;
  const Rows, Columns: QWord; const Payload: TBytes);
var
  KindByte, Reserved: Byte;
begin
  WriteBytes(Stream, BINARY_MAGIC, SizeOf(BINARY_MAGIC));
  WriteUInt16LE(Stream, BINARY_VERSION);
  KindByte := Ord(Kind);
  Reserved := 0;
  WriteBytes(Stream, KindByte, 1);
  WriteBytes(Stream, Reserved, 1);
  WriteUInt64LE(Stream, Rows);
  WriteUInt64LE(Stream, Columns);
  WriteUInt64LE(Stream, Length(Payload));
  WriteUInt32LE(Stream, CRC32(Payload));
  if Length(Payload) > 0 then
    WriteBytes(Stream, Payload[0], Length(Payload));
end;

function ReadExact(const Stream: TStream; var Buffer;
  const Count: SizeInt): Boolean;
var
  ReadCount, Total: SizeInt;
  Destination: PByte;
begin
  Result := False;
  if Stream = nil then Exit;
  Destination := @Buffer;
  Total := 0;
  while Total < Count do
  begin
    ReadCount := Stream.Read(Destination[Total], Count - Total);
    if ReadCount <= 0 then Exit;
    Inc(Total, ReadCount);
  end;
  Result := True;
end;

function ReadUInt16LE(const Stream: TStream; const Operation: string): Word;
var
  Bytes: array[0..1] of Byte;
begin
  if not ReadExact(Stream, Bytes, SizeOf(Bytes)) then
    raise EInterchangeError.Create(Operation + ': truncated binary header.');
  Result := Word(Bytes[0]) or (Word(Bytes[1]) shl 8);
end;

function ReadUInt32LE(const Stream: TStream; const Operation: string): LongWord;
var
  Bytes: array[0..3] of Byte;
  I: Integer;
begin
  if not ReadExact(Stream, Bytes, SizeOf(Bytes)) then
    raise EInterchangeError.Create(Operation + ': truncated binary header.');
  Result := 0;
  for I := 0 to 3 do Result := Result or
    (LongWord(Bytes[I]) shl (8 * I));
end;

function ReadUInt64LE(const Stream: TStream; const Operation: string): QWord;
var
  Bytes: array[0..7] of Byte;
  I: Integer;
begin
  if not ReadExact(Stream, Bytes, SizeOf(Bytes)) then
    raise EInterchangeError.Create(Operation + ': truncated binary header.');
  Result := 0;
  for I := 0 to 7 do Result := Result or
    (QWord(Bytes[I]) shl (8 * I));
end;

function ReadBinaryObject(const Stream: TStream; const ExpectedKind: TBinaryKind;
  const MaxElements, ElementBytes: QWord; const Operation: string;
  out Header: TBinaryHeader): TBytes;
var
  Magic: array[0..7] of Byte;
  KindByte, Reserved: Byte;
  Version: Word;
  I: Integer;
  Elements, ExpectedBytes: QWord;
begin
  Result := nil;
  if Stream = nil then
    raise EInterchangeError.Create(Operation + ': Stream must not be nil.');
  if not ReadExact(Stream, Magic, SizeOf(Magic)) then
    raise EInterchangeError.Create(Operation + ': truncated binary magic.');
  for I := 0 to High(Magic) do
    if Magic[I] <> BINARY_MAGIC[I] then
      raise EInterchangeError.Create(Operation + ': incompatible binary magic.');
  Version := ReadUInt16LE(Stream, Operation);
  if Version <> BINARY_VERSION then
    raise EInterchangeError.CreateFmt(
      '%s: unsupported format version %d.', [Operation, Version]);
  if not ReadExact(Stream, KindByte, 1) or
     not ReadExact(Stream, Reserved, 1) then
    raise EInterchangeError.Create(Operation + ': truncated binary kind.');
  if Reserved <> 0 then
    raise EInterchangeError.Create(
      Operation + ': reserved binary header byte must be zero.');
  if KindByte <> Ord(ExpectedKind) then
    raise EInterchangeError.CreateFmt(
      '%s: scalar/storage kind %d is incompatible with expected kind %d.',
      [Operation, KindByte, Ord(ExpectedKind)]);
  Header.Kind := ExpectedKind;
  Header.Rows := ReadUInt64LE(Stream, Operation);
  Header.Columns := ReadUInt64LE(Stream, Operation);
  Header.PayloadBytes := ReadUInt64LE(Stream, Operation);
  Header.Checksum := ReadUInt32LE(Stream, Operation);
  if (Header.Rows <> 0) and
     (Header.Columns > High(QWord) div Header.Rows) then
    raise EInterchangeError.Create(Operation + ': declared shape overflows.');
  Elements := Header.Rows * Header.Columns;
  if Elements > MaxElements then
    raise EInterchangeError.CreateFmt(
      '%s: declared %d elements exceed limit %d.',
      [Operation, Elements, MaxElements]);
  if (Elements <> 0) and (ElementBytes > High(QWord) div Elements) then
    raise EInterchangeError.Create(Operation + ': declared byte count overflows.');
  ExpectedBytes := Elements * ElementBytes;
  if Header.PayloadBytes <> ExpectedBytes then
    raise EInterchangeError.CreateFmt(
      '%s: declared payload length %d does not match shape length %d.',
      [Operation, Header.PayloadBytes, ExpectedBytes]);
  if Header.PayloadBytes > QWord(High(SizeInt)) then
    raise EInterchangeError.Create(
      Operation + ': payload exceeds platform address-space limit.');
  SetLength(Result, SizeInt(Header.PayloadBytes));
  if (Length(Result) > 0) and
     not ReadExact(Stream, Result[0], Length(Result)) then
    raise EInterchangeError.Create(Operation + ': truncated binary payload.');
  if CRC32(Result) <> Header.Checksum then
    raise EInterchangeError.Create(Operation + ': payload checksum mismatch.');
end;

procedure SaveBinary(const Stream: TStream; const Values: TDoubleArray);
var
  Payload: TBytes;
  I: SizeInt;
begin
  if QWord(Length(Values)) > QWord(High(SizeInt)) div SizeOf(Double) then
    raise EInterchangeError.Create('SaveBinary(double vector): byte overflow.');
  SetLength(Payload, Length(Values) * SizeOf(Double));
  for I := 0 to High(Values) do
  begin
    RequireFinite(Values[I], 'SaveBinary(double vector)');
    PutDoubleLE(Payload, I * SizeOf(Double), Values[I]);
  end;
  WriteBinaryObject(Stream, bkDoubleVector, Length(Values), 1, Payload);
end;

procedure SaveBinary(const Stream: TStream; const Values: TComplexArray);
var
  Payload: TBytes;
  I, Offset: SizeInt;
begin
  if QWord(Length(Values)) > QWord(High(SizeInt)) div 16 then
    raise EInterchangeError.Create('SaveBinary(complex vector): byte overflow.');
  SetLength(Payload, Length(Values) * 16);
  for I := 0 to High(Values) do
  begin
    if not Values[I].IsFinite then
      raise EInterchangeError.Create(
        'SaveBinary(complex vector): values must be finite.');
    Offset := I * 16;
    PutDoubleLE(Payload, Offset, Values[I].Re);
    PutDoubleLE(Payload, Offset + 8, Values[I].Im);
  end;
  WriteBinaryObject(Stream, bkComplexVector, Length(Values), 1, Payload);
end;

procedure SaveBinary(const Stream: TStream; const Matrix: IDenseDoubleMatrix);
var
  Payload: TBytes;
  RowIndex, ColumnIndex, Offset: SizeInt;
begin
  RequireMatrix(Matrix, 'SaveBinary(double matrix)');
  if (Matrix.Rows <> 0) and
     (Matrix.Cols > High(SizeInt) div Matrix.Rows) then
    raise EInterchangeError.Create('SaveBinary(double matrix): shape overflow.');
  if Matrix.Rows * Matrix.Cols > High(SizeInt) div 8 then
    raise EInterchangeError.Create('SaveBinary(double matrix): byte overflow.');
  SetLength(Payload, Matrix.Rows * Matrix.Cols * 8);
  Offset := 0;
  for RowIndex := 0 to Matrix.Rows - 1 do
    for ColumnIndex := 0 to Matrix.Cols - 1 do
    begin
      PutDoubleLE(Payload, Offset, Matrix[RowIndex, ColumnIndex]);
      Inc(Offset, 8);
    end;
  WriteBinaryObject(Stream, bkDoubleMatrix, Matrix.Rows, Matrix.Cols, Payload);
end;

procedure SaveBinary(const Stream: TStream; const Matrix: IDenseComplexMatrix);
var
  Payload: TBytes;
  RowIndex, ColumnIndex, Offset, Elements: SizeInt;
begin
  RequireMatrix(Matrix, 'SaveBinary(complex matrix)');
  if (Matrix.Rows <> 0) and
     (Matrix.Cols > High(SizeInt) div Matrix.Rows) then
    raise EInterchangeError.Create('SaveBinary(complex matrix): shape overflow.');
  Elements := Matrix.Rows * Matrix.Cols;
  if Elements > High(SizeInt) div 16 then
    raise EInterchangeError.Create('SaveBinary(complex matrix): byte overflow.');
  SetLength(Payload, Elements * 16);
  Offset := 0;
  for RowIndex := 0 to Matrix.Rows - 1 do
    for ColumnIndex := 0 to Matrix.Cols - 1 do
    begin
      PutDoubleLE(Payload, Offset, Matrix[RowIndex, ColumnIndex].Re);
      PutDoubleLE(Payload, Offset + 8, Matrix[RowIndex, ColumnIndex].Im);
      Inc(Offset, 16);
    end;
  WriteBinaryObject(Stream, bkComplexMatrix, Matrix.Rows, Matrix.Cols, Payload);
end;

function LoadDoubleVectorBinary(const Stream: TStream;
  const MaxElements: QWord): TDoubleArray;
var
  Header: TBinaryHeader;
  Payload: TBytes;
  I: SizeInt;
  Value: Double;
begin
  Result := nil;
  Payload := ReadBinaryObject(Stream, bkDoubleVector, MaxElements, 8,
    'LoadDoubleVectorBinary', Header);
  if Header.Columns <> 1 then
    raise EInterchangeError.Create(
      'LoadDoubleVectorBinary: vector column metadata must equal one.');
  for I := 0 to SizeInt(Header.Rows) - 1 do
  begin
    Value := GetDoubleLE(Payload, I * 8);
    RequireFinite(Value, 'LoadDoubleVectorBinary');
  end;
  SetLength(Result, Header.Rows);
  for I := 0 to High(Result) do
    Result[I] := GetDoubleLE(Payload, I * 8);
end;

function LoadComplexVectorBinary(const Stream: TStream;
  const MaxElements: QWord): TComplexArray;
var
  Header: TBinaryHeader;
  Payload: TBytes;
  I, Offset: SizeInt;
begin
  Result := nil;
  Payload := ReadBinaryObject(Stream, bkComplexVector, MaxElements, 16,
    'LoadComplexVectorBinary', Header);
  if Header.Columns <> 1 then
    raise EInterchangeError.Create(
      'LoadComplexVectorBinary: vector column metadata must equal one.');
  for I := 0 to SizeInt(Header.Rows) - 1 do
  begin
    Offset := I * 16;
    if not TComplex.Create(GetDoubleLE(Payload, Offset),
      GetDoubleLE(Payload, Offset + 8)).IsFinite then
      raise EInterchangeError.Create(
        'LoadComplexVectorBinary: payload values must be finite.');
  end;
  SetLength(Result, Header.Rows);
  for I := 0 to High(Result) do
  begin
    Offset := I * 16;
    Result[I] := TComplex.Create(GetDoubleLE(Payload, Offset),
      GetDoubleLE(Payload, Offset + 8));
  end;
end;

function LoadDoubleMatrixBinary(const Stream: TStream;
  const MaxElements: QWord): IDenseDoubleMatrix;
var
  Header: TBinaryHeader;
  Payload: TBytes;
  RowIndex, ColumnIndex, Offset: SizeInt;
  Value: Double;
begin
  Payload := ReadBinaryObject(Stream, bkDoubleMatrix, MaxElements, 8,
    'LoadDoubleMatrixBinary', Header);
  if (Header.Rows > QWord(High(SizeInt))) or
     (Header.Columns > QWord(High(SizeInt))) then
    raise EInterchangeError.Create(
      'LoadDoubleMatrixBinary: shape exceeds platform limits.');
  Offset := 0;
  for RowIndex := 0 to SizeInt(Header.Rows) - 1 do
    for ColumnIndex := 0 to SizeInt(Header.Columns) - 1 do
    begin
      Value := GetDoubleLE(Payload, Offset);
      RequireFinite(Value, 'LoadDoubleMatrixBinary');
      Inc(Offset, 8);
    end;
  Result := TDenseDoubleMatrix.Zeros(Header.Rows, Header.Columns);
  Offset := 0;
  for RowIndex := 0 to Result.Rows - 1 do
    for ColumnIndex := 0 to Result.Cols - 1 do
    begin
      Result[RowIndex, ColumnIndex] := GetDoubleLE(Payload, Offset);
      Inc(Offset, 8);
    end;
end;

function LoadComplexMatrixBinary(const Stream: TStream;
  const MaxElements: QWord): IDenseComplexMatrix;
var
  Header: TBinaryHeader;
  Payload: TBytes;
  RowIndex, ColumnIndex, Offset: SizeInt;
  Value: TComplex;
begin
  Payload := ReadBinaryObject(Stream, bkComplexMatrix, MaxElements, 16,
    'LoadComplexMatrixBinary', Header);
  if (Header.Rows > QWord(High(SizeInt))) or
     (Header.Columns > QWord(High(SizeInt))) then
    raise EInterchangeError.Create(
      'LoadComplexMatrixBinary: shape exceeds platform limits.');
  Offset := 0;
  for RowIndex := 0 to SizeInt(Header.Rows) - 1 do
    for ColumnIndex := 0 to SizeInt(Header.Columns) - 1 do
    begin
      Value := TComplex.Create(GetDoubleLE(Payload, Offset),
        GetDoubleLE(Payload, Offset + 8));
      if not Value.IsFinite then
        raise EInterchangeError.Create(
          'LoadComplexMatrixBinary: payload values must be finite.');
      Inc(Offset, 16);
    end;
  Result := TDenseComplexMatrix.Zeros(Header.Rows, Header.Columns);
  Offset := 0;
  for RowIndex := 0 to Result.Rows - 1 do
    for ColumnIndex := 0 to Result.Cols - 1 do
    begin
      Result[RowIndex, ColumnIndex] := TComplex.Create(
        GetDoubleLE(Payload, Offset), GetDoubleLE(Payload, Offset + 8));
      Inc(Offset, 16);
  end;
end;

function NewSparsePayload(const Format: TSparseFormat;
  const ZeroPolicy: TSparseStoredZeroPolicy;
  const OuterLength, NonZeros, ValueBytes: SizeInt;
  out OuterOffset, InnerOffset, ValueOffset: SizeInt): TBytes;
var
  PayloadBytes: QWord;
begin
  Result := nil;
  PayloadBytes := 24;
  if QWord(OuterLength) > (High(QWord) - PayloadBytes) div 8 then
    raise EInterchangeError.Create('SaveSparseBinary: outer byte count overflows.');
  Inc(PayloadBytes, QWord(OuterLength) * 8);
  if QWord(NonZeros) >
     (High(QWord) - PayloadBytes) div QWord(8 + ValueBytes) then
    raise EInterchangeError.Create('SaveSparseBinary: payload byte count overflows.');
  Inc(PayloadBytes, QWord(NonZeros) * QWord(8 + ValueBytes));
  if PayloadBytes > QWord(High(SizeInt)) then
    raise EInterchangeError.Create(
      'SaveSparseBinary: payload exceeds platform address-space limit.');
  SetLength(Result, SizeInt(PayloadBytes));
  Result[0] := Ord(Format);
  Result[1] := Ord(ZeroPolicy);
  PutUInt64LE(Result, 8, NonZeros);
  PutUInt64LE(Result, 16, OuterLength);
  OuterOffset := 24;
  InnerOffset := OuterOffset + OuterLength * 8;
  ValueOffset := InnerOffset + NonZeros * 8;
end;

function ReadSparseBinaryEnvelope(const Stream: TStream;
  const ExpectedKind: TBinaryKind;
  const MaxNonZeros, MaxDimension, ValueBytes: QWord;
  const Operation: string; out Header: TBinaryHeader): TBytes;
var
  Magic: array[0..7] of Byte;
  KindByte, Reserved: Byte;
  Version: Word;
  I: Integer;
  MaximumOuter, MaximumPayload, PerNonZero: QWord;
begin
  Result := nil;
  if Stream = nil then
    raise EInterchangeError.Create(Operation + ': Stream must not be nil.');
  if not ReadExact(Stream, Magic, SizeOf(Magic)) then
    raise EInterchangeError.Create(Operation + ': truncated binary magic.');
  for I := 0 to High(Magic) do
    if Magic[I] <> BINARY_MAGIC[I] then
      raise EInterchangeError.Create(Operation + ': incompatible binary magic.');
  Version := ReadUInt16LE(Stream, Operation);
  if Version <> BINARY_VERSION then
    raise EInterchangeError.CreateFmt(
      '%s: unsupported format version %d.', [Operation, Version]);
  if not ReadExact(Stream, KindByte, 1) or
     not ReadExact(Stream, Reserved, 1) then
    raise EInterchangeError.Create(Operation + ': truncated binary kind.');
  if Reserved <> 0 then
    raise EInterchangeError.Create(
      Operation + ': reserved binary header byte must be zero.');
  if KindByte <> Ord(ExpectedKind) then
    raise EInterchangeError.CreateFmt(
      '%s: scalar/storage kind %d is incompatible with expected kind %d.',
      [Operation, KindByte, Ord(ExpectedKind)]);
  Header.Kind := ExpectedKind;
  Header.Rows := ReadUInt64LE(Stream, Operation);
  Header.Columns := ReadUInt64LE(Stream, Operation);
  Header.PayloadBytes := ReadUInt64LE(Stream, Operation);
  Header.Checksum := ReadUInt32LE(Stream, Operation);
  if (Header.Rows > QWord(High(SizeInt))) or
     (Header.Columns > QWord(High(SizeInt))) then
    raise EInterchangeError.Create(
      Operation + ': shape exceeds platform limits.');
  if (Header.Rows > MaxDimension) or
     (Header.Columns > MaxDimension) then
    raise EInterchangeError.CreateFmt(
      '%s: declared shape %d x %d exceeds dimension limit %d.',
      [Operation, Header.Rows, Header.Columns, MaxDimension]);
  MaximumOuter := Max(Header.Rows, Header.Columns);
  if MaximumOuter = High(QWord) then
    raise EInterchangeError.Create(Operation + ': pointer length overflows.');
  Inc(MaximumOuter);
  if MaximumOuter > (High(QWord) - 24) div 8 then
    MaximumPayload := High(QWord)
  else
    MaximumPayload := 24 + MaximumOuter * 8;
  PerNonZero := 8 + ValueBytes;
  if (MaximumPayload <> High(QWord)) and
     (MaxNonZeros <= (High(QWord) - MaximumPayload) div PerNonZero) then
    Inc(MaximumPayload, MaxNonZeros * PerNonZero)
  else
    MaximumPayload := High(QWord);
  if Header.PayloadBytes > MaximumPayload then
    raise EInterchangeError.CreateFmt(
      '%s: payload length exceeds the configured sparse resource limit.',
      [Operation]);
  if Header.PayloadBytes > QWord(High(SizeInt)) then
    raise EInterchangeError.Create(
      Operation + ': payload exceeds platform address-space limit.');
  SetLength(Result, SizeInt(Header.PayloadBytes));
  if (Length(Result) > 0) and
     not ReadExact(Stream, Result[0], Length(Result)) then
    raise EInterchangeError.Create(Operation + ': truncated binary payload.');
  if CRC32(Result) <> Header.Checksum then
    raise EInterchangeError.Create(Operation + ': payload checksum mismatch.');
end;

procedure ParseSparsePayload(const Payload: TBytes;
  const Header: TBinaryHeader; const MaxNonZeros: QWord;
  const ValueBytes: SizeInt; const Operation: string;
  out Format: TSparseFormat; out ZeroPolicy: TSparseStoredZeroPolicy;
  out Outer, Inner: TSparseSizeIntArray; out ValueOffset: SizeInt);
var
  NonZeros64, OuterLength64, ExpectedOuter, ExpectedBytes: QWord;
  I, OuterOffset, InnerOffset: SizeInt;
  Index64: QWord;
begin
  if Length(Payload) < 24 then
    raise EInterchangeError.Create(Operation + ': sparse payload is too short.');
  if (Payload[0] > Ord(High(TSparseFormat))) or
     (Payload[1] > Ord(High(TSparseStoredZeroPolicy))) then
    raise EInterchangeError.Create(
      Operation + ': invalid sparse format or zero policy.');
  for I := 2 to 7 do
    if Payload[I] <> 0 then
      raise EInterchangeError.Create(
        Operation + ': reserved sparse payload bytes must be zero.');
  Format := TSparseFormat(Payload[0]);
  ZeroPolicy := TSparseStoredZeroPolicy(Payload[1]);
  NonZeros64 := GetUInt64LE(Payload, 8);
  OuterLength64 := GetUInt64LE(Payload, 16);
  if NonZeros64 > MaxNonZeros then
    raise EInterchangeError.CreateFmt(
      '%s: declared %d nonzeros exceed limit %d.',
      [Operation, NonZeros64, MaxNonZeros]);
  if (NonZeros64 > QWord(High(SizeInt))) or
     (OuterLength64 > QWord(High(SizeInt))) then
    raise EInterchangeError.Create(
      Operation + ': sparse array length exceeds platform limits.');
  if Format = sfCSR then ExpectedOuter := Header.Rows + 1
  else ExpectedOuter := Header.Columns + 1;
  if OuterLength64 <> ExpectedOuter then
    raise EInterchangeError.Create(
      Operation + ': compressed pointer length does not match format and shape.');
  if OuterLength64 > (High(QWord) - 24) div 8 then
    raise EInterchangeError.Create(Operation + ': pointer bytes overflow.');
  ExpectedBytes := 24 + OuterLength64 * 8;
  if NonZeros64 >
     (High(QWord) - ExpectedBytes) div QWord(8 + ValueBytes) then
    raise EInterchangeError.Create(Operation + ': sparse payload bytes overflow.');
  Inc(ExpectedBytes, NonZeros64 * QWord(8 + ValueBytes));
  if ExpectedBytes <> QWord(Length(Payload)) then
    raise EInterchangeError.Create(
      Operation + ': payload length does not match sparse metadata.');
  SetLength(Outer, SizeInt(OuterLength64));
  SetLength(Inner, SizeInt(NonZeros64));
  OuterOffset := 24;
  InnerOffset := OuterOffset + Length(Outer) * 8;
  ValueOffset := InnerOffset + Length(Inner) * 8;
  for I := 0 to High(Outer) do
  begin
    Index64 := GetUInt64LE(Payload, OuterOffset + I * 8);
    if Index64 > QWord(High(SizeInt)) then
      raise EInterchangeError.Create(
        Operation + ': outer pointer exceeds platform limits.');
    Outer[I] := SizeInt(Index64);
  end;
  for I := 0 to High(Inner) do
  begin
    Index64 := GetUInt64LE(Payload, InnerOffset + I * 8);
    if Index64 > QWord(High(SizeInt)) then
      raise EInterchangeError.Create(
        Operation + ': inner index exceeds platform limits.');
    Inner[I] := SizeInt(Index64);
  end;
end;

procedure SaveSparseBinary(const Stream: TStream;
  const Matrix: ISparseSingleMatrix);
var
  Payload: TBytes;
  OuterOffset, InnerOffset, ValueOffset, I, OuterLength: SizeInt;
begin
  if Matrix = nil then
    raise EInterchangeError.Create('SaveSparseBinary(single): matrix is nil.');
  if Matrix.Format = sfCSR then OuterLength := Matrix.Rows + 1
  else OuterLength := Matrix.Cols + 1;
  Payload := NewSparsePayload(Matrix.Format, Matrix.StoredZeroPolicy,
    OuterLength, Matrix.NonZeroCount, 4,
    OuterOffset, InnerOffset, ValueOffset);
  for I := 0 to OuterLength - 1 do
    PutUInt64LE(Payload, OuterOffset + I * 8, Matrix.GetOuterPointer(I));
  for I := 0 to Matrix.NonZeroCount - 1 do
  begin
    PutUInt64LE(Payload, InnerOffset + I * 8, Matrix.GetInnerIndex(I));
    PutSingleLE(Payload, ValueOffset + I * 4, Matrix.GetStoredValue(I));
  end;
  WriteBinaryObject(Stream, bkSparseSingle,
    Matrix.Rows, Matrix.Cols, Payload);
end;

procedure SaveSparseBinary(const Stream: TStream;
  const Matrix: ISparseDoubleMatrix);
var
  Payload: TBytes;
  OuterOffset, InnerOffset, ValueOffset, I, OuterLength: SizeInt;
begin
  if Matrix = nil then
    raise EInterchangeError.Create('SaveSparseBinary(double): matrix is nil.');
  if Matrix.Format = sfCSR then OuterLength := Matrix.Rows + 1
  else OuterLength := Matrix.Cols + 1;
  Payload := NewSparsePayload(Matrix.Format, Matrix.StoredZeroPolicy,
    OuterLength, Matrix.NonZeroCount, 8,
    OuterOffset, InnerOffset, ValueOffset);
  for I := 0 to OuterLength - 1 do
    PutUInt64LE(Payload, OuterOffset + I * 8, Matrix.GetOuterPointer(I));
  for I := 0 to Matrix.NonZeroCount - 1 do
  begin
    PutUInt64LE(Payload, InnerOffset + I * 8, Matrix.GetInnerIndex(I));
    PutDoubleLE(Payload, ValueOffset + I * 8, Matrix.GetStoredValue(I));
  end;
  WriteBinaryObject(Stream, bkSparseDouble,
    Matrix.Rows, Matrix.Cols, Payload);
end;

procedure SaveSparseBinary(const Stream: TStream;
  const Matrix: ISparseSingleComplexMatrix);
var
  Payload: TBytes;
  OuterOffset, InnerOffset, ValueOffset, I, OuterLength: SizeInt;
  Value: TSingleComplex;
begin
  if Matrix = nil then
    raise EInterchangeError.Create(
      'SaveSparseBinary(single complex): matrix is nil.');
  if Matrix.Format = sfCSR then OuterLength := Matrix.Rows + 1
  else OuterLength := Matrix.Cols + 1;
  Payload := NewSparsePayload(Matrix.Format, Matrix.StoredZeroPolicy,
    OuterLength, Matrix.NonZeroCount, 8,
    OuterOffset, InnerOffset, ValueOffset);
  for I := 0 to OuterLength - 1 do
    PutUInt64LE(Payload, OuterOffset + I * 8, Matrix.GetOuterPointer(I));
  for I := 0 to Matrix.NonZeroCount - 1 do
  begin
    PutUInt64LE(Payload, InnerOffset + I * 8, Matrix.GetInnerIndex(I));
    Value := Matrix.GetStoredValue(I);
    PutSingleLE(Payload, ValueOffset + I * 8, Value.Re);
    PutSingleLE(Payload, ValueOffset + I * 8 + 4, Value.Im);
  end;
  WriteBinaryObject(Stream, bkSparseSingleComplex,
    Matrix.Rows, Matrix.Cols, Payload);
end;

procedure SaveSparseBinary(const Stream: TStream;
  const Matrix: ISparseComplexMatrix);
var
  Payload: TBytes;
  OuterOffset, InnerOffset, ValueOffset, I, OuterLength: SizeInt;
  Value: TComplex;
begin
  if Matrix = nil then
    raise EInterchangeError.Create('SaveSparseBinary(complex): matrix is nil.');
  if Matrix.Format = sfCSR then OuterLength := Matrix.Rows + 1
  else OuterLength := Matrix.Cols + 1;
  Payload := NewSparsePayload(Matrix.Format, Matrix.StoredZeroPolicy,
    OuterLength, Matrix.NonZeroCount, 16,
    OuterOffset, InnerOffset, ValueOffset);
  for I := 0 to OuterLength - 1 do
    PutUInt64LE(Payload, OuterOffset + I * 8, Matrix.GetOuterPointer(I));
  for I := 0 to Matrix.NonZeroCount - 1 do
  begin
    PutUInt64LE(Payload, InnerOffset + I * 8, Matrix.GetInnerIndex(I));
    Value := Matrix.GetStoredValue(I);
    PutDoubleLE(Payload, ValueOffset + I * 16, Value.Re);
    PutDoubleLE(Payload, ValueOffset + I * 16 + 8, Value.Im);
  end;
  WriteBinaryObject(Stream, bkSparseComplex,
    Matrix.Rows, Matrix.Cols, Payload);
end;

function LoadSparseSingleBinary(const Stream: TStream;
  const MaxNonZeros, MaxDimension: QWord): ISparseSingleMatrix;
var
  Header: TBinaryHeader;
  Payload: TBytes;
  Format: TSparseFormat;
  ZeroPolicy: TSparseStoredZeroPolicy;
  Outer, Inner: TSparseSizeIntArray;
  Values: array of Single;
  ValueOffset, I: SizeInt;
begin
  Payload := ReadSparseBinaryEnvelope(Stream, bkSparseSingle,
    MaxNonZeros, MaxDimension, 4, 'LoadSparseSingleBinary', Header);
  ParseSparsePayload(Payload, Header, MaxNonZeros, 4,
    'LoadSparseSingleBinary', Format, ZeroPolicy,
    Outer, Inner, ValueOffset);
  SetLength(Values, Length(Inner));
  for I := 0 to High(Values) do
  begin
    Values[I] := GetSingleLE(Payload, ValueOffset + I * 4);
    RequireFinite(Values[I], 'LoadSparseSingleBinary');
  end;
  if Format = sfCSR then
    Result := TSparseSingleMatrix.FromCSR(Header.Rows, Header.Columns,
      Outer, Inner, Values, ZeroPolicy)
  else
    Result := TSparseSingleMatrix.FromCSC(Header.Rows, Header.Columns,
      Outer, Inner, Values, ZeroPolicy);
end;

function LoadSparseDoubleBinary(const Stream: TStream;
  const MaxNonZeros, MaxDimension: QWord): ISparseDoubleMatrix;
var
  Header: TBinaryHeader;
  Payload: TBytes;
  Format: TSparseFormat;
  ZeroPolicy: TSparseStoredZeroPolicy;
  Outer, Inner: TSparseSizeIntArray;
  Values: array of Double;
  ValueOffset, I: SizeInt;
begin
  Payload := ReadSparseBinaryEnvelope(Stream, bkSparseDouble,
    MaxNonZeros, MaxDimension, 8, 'LoadSparseDoubleBinary', Header);
  ParseSparsePayload(Payload, Header, MaxNonZeros, 8,
    'LoadSparseDoubleBinary', Format, ZeroPolicy,
    Outer, Inner, ValueOffset);
  SetLength(Values, Length(Inner));
  for I := 0 to High(Values) do
  begin
    Values[I] := GetDoubleLE(Payload, ValueOffset + I * 8);
    RequireFinite(Values[I], 'LoadSparseDoubleBinary');
  end;
  if Format = sfCSR then
    Result := TSparseDoubleMatrix.FromCSR(Header.Rows, Header.Columns,
      Outer, Inner, Values, ZeroPolicy)
  else
    Result := TSparseDoubleMatrix.FromCSC(Header.Rows, Header.Columns,
      Outer, Inner, Values, ZeroPolicy);
end;

function LoadSparseSingleComplexBinary(const Stream: TStream;
  const MaxNonZeros, MaxDimension: QWord): ISparseSingleComplexMatrix;
var
  Header: TBinaryHeader;
  Payload: TBytes;
  Format: TSparseFormat;
  ZeroPolicy: TSparseStoredZeroPolicy;
  Outer, Inner: TSparseSizeIntArray;
  Values: array of TSingleComplex;
  ValueOffset, I: SizeInt;
begin
  Payload := ReadSparseBinaryEnvelope(Stream, bkSparseSingleComplex,
    MaxNonZeros, MaxDimension, 8, 'LoadSparseSingleComplexBinary', Header);
  ParseSparsePayload(Payload, Header, MaxNonZeros, 8,
    'LoadSparseSingleComplexBinary', Format, ZeroPolicy,
    Outer, Inner, ValueOffset);
  SetLength(Values, Length(Inner));
  for I := 0 to High(Values) do
  begin
    Values[I] := TSingleComplex.Create(
      GetSingleLE(Payload, ValueOffset + I * 8),
      GetSingleLE(Payload, ValueOffset + I * 8 + 4));
    if not Values[I].IsFinite then
      raise EInterchangeError.Create(
        'LoadSparseSingleComplexBinary: values must be finite.');
  end;
  if Format = sfCSR then
    Result := TSparseSingleComplexMatrix.FromCSR(
      Header.Rows, Header.Columns, Outer, Inner, Values, ZeroPolicy)
  else
    Result := TSparseSingleComplexMatrix.FromCSC(
      Header.Rows, Header.Columns, Outer, Inner, Values, ZeroPolicy);
end;

function LoadSparseComplexBinary(const Stream: TStream;
  const MaxNonZeros, MaxDimension: QWord): ISparseComplexMatrix;
var
  Header: TBinaryHeader;
  Payload: TBytes;
  Format: TSparseFormat;
  ZeroPolicy: TSparseStoredZeroPolicy;
  Outer, Inner: TSparseSizeIntArray;
  Values: array of TComplex;
  ValueOffset, I: SizeInt;
begin
  Payload := ReadSparseBinaryEnvelope(Stream, bkSparseComplex,
    MaxNonZeros, MaxDimension, 16, 'LoadSparseComplexBinary', Header);
  ParseSparsePayload(Payload, Header, MaxNonZeros, 16,
    'LoadSparseComplexBinary', Format, ZeroPolicy,
    Outer, Inner, ValueOffset);
  SetLength(Values, Length(Inner));
  for I := 0 to High(Values) do
  begin
    Values[I] := TComplex.Create(
      GetDoubleLE(Payload, ValueOffset + I * 16),
      GetDoubleLE(Payload, ValueOffset + I * 16 + 8));
    if not Values[I].IsFinite then
      raise EInterchangeError.Create(
        'LoadSparseComplexBinary: values must be finite.');
  end;
  if Format = sfCSR then
    Result := TSparseComplexMatrix.FromCSR(
      Header.Rows, Header.Columns, Outer, Inner, Values, ZeroPolicy)
  else
    Result := TSparseComplexMatrix.FromCSC(
      Header.Rows, Header.Columns, Outer, Inner, Values, ZeroPolicy);
end;

procedure SaveRandomStateBinary(const Stream: TStream;
  const State: TRandomState);
var
  Payload: TBytes;
  Generator: TLocalRandom;
  I: Integer;
begin
  Generator.SetState(State);
  SetLength(Payload, 32);
  for I := 0 to 3 do PutUInt64LE(Payload, I * 8, State.Words[I]);
  WriteBinaryObject(Stream, bkRandomState, 4, 1, Payload);
end;

function LoadRandomStateBinary(const Stream: TStream): TRandomState;
var
  Header: TBinaryHeader;
  Payload: TBytes;
  Generator: TLocalRandom;
  I: Integer;
begin
  Payload := ReadBinaryObject(Stream, bkRandomState, 4, 8,
    'LoadRandomStateBinary', Header);
  if (Header.Rows <> 4) or (Header.Columns <> 1) then
    raise EInterchangeError.Create(
      'LoadRandomStateBinary: state shape must be 4 x 1.');
  for I := 0 to 3 do Result.Words[I] := GetUInt64LE(Payload, I * 8);
  Generator.SetState(Result);
end;

function Summarize(const Values: TDoubleArray;
  const MaximumValues: SizeInt): string;
var
  Builder: TStringBuilder;
  I, DisplayCount: SizeInt;
begin
  if MaximumValues < 0 then
    raise EInterchangeError.Create(
      'Summarize(vector): MaximumValues must be non-negative.');
  Builder := TStringBuilder.Create;
  try
    Builder.Append('Double vector length=').Append(IntToStr(Length(Values))).
      Append(' [');
    DisplayCount := Min(Length(Values), MaximumValues);
    for I := 0 to DisplayCount - 1 do
    begin
      if I > 0 then Builder.Append(', ');
      Builder.Append(FloatInvariant(Values[I]));
    end;
    if DisplayCount < Length(Values) then Builder.Append(', ...');
    Builder.Append(']');
    Result := Builder.ToString;
  finally
    Builder.Free;
  end;
end;

function Summarize(const Matrix: IDenseDoubleMatrix;
  const MaximumRows, MaximumColumns: SizeInt): string;
var
  Builder: TStringBuilder;
  RowIndex, ColumnIndex, RowCount, ColumnCount: SizeInt;
begin
  RequireMatrix(Matrix, 'Summarize(matrix)');
  if (MaximumRows < 0) or (MaximumColumns < 0) then
    raise EInterchangeError.Create(
      'Summarize(matrix): row and column limits must be non-negative.');
  Builder := TStringBuilder.Create;
  try
    Builder.Append('Double matrix shape=').Append(IntToStr(Matrix.Rows)).
      Append('x').Append(IntToStr(Matrix.Cols));
    RowCount := Min(Matrix.Rows, MaximumRows);
    ColumnCount := Min(Matrix.Cols, MaximumColumns);
    for RowIndex := 0 to RowCount - 1 do
    begin
      Builder.Append(LineEnding).Append('[');
      for ColumnIndex := 0 to ColumnCount - 1 do
      begin
        if ColumnIndex > 0 then Builder.Append(', ');
        Builder.Append(FloatInvariant(Matrix[RowIndex, ColumnIndex]));
      end;
      if ColumnCount < Matrix.Cols then Builder.Append(', ...');
      Builder.Append(']');
    end;
    if RowCount < Matrix.Rows then Builder.Append(LineEnding).Append('...');
    Result := Builder.ToString;
  finally
    Builder.Free;
  end;
end;

function Describe(const Values:TDoubleArray):TValueMetadata;
begin
  Result:=Default(TValueMetadata);
  Result.Kind:=ivkVector; Result.ScalarType:=istFloat64;
  Result.Rows:=Length(Values); Result.Columns:=1;
  Result.Elements:=Length(Values);
end;

function Describe(const Values:TComplexArray):TValueMetadata;
begin
  Result:=Default(TValueMetadata);
  Result.Kind:=ivkVector; Result.ScalarType:=istComplex128;
  Result.Rows:=Length(Values); Result.Columns:=1;
  Result.Elements:=Length(Values);
end;

function Describe(const Matrix:IDenseDoubleMatrix):TValueMetadata;
begin
  RequireMatrix(Matrix,'Describe(double matrix)');
  Result:=Default(TValueMetadata);
  Result.Kind:=ivkMatrix; Result.ScalarType:=istFloat64;
  Result.Rows:=Matrix.Rows; Result.Columns:=Matrix.Cols;
  Result.Elements:=QWord(Matrix.Rows)*QWord(Matrix.Cols);
end;

function Describe(const Matrix:IDenseComplexMatrix):TValueMetadata;
begin
  RequireMatrix(Matrix,'Describe(complex matrix)');
  Result:=Default(TValueMetadata);
  Result.Kind:=ivkMatrix; Result.ScalarType:=istComplex128;
  Result.Rows:=Matrix.Rows; Result.Columns:=Matrix.Cols;
  Result.Elements:=QWord(Matrix.Rows)*QWord(Matrix.Cols);
end;

end.
