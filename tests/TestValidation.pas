unit TestValidation;

{$mode objfpc}{$H+}{$J-}

interface

uses
  SysUtils, fpcunit, testregistry,
  MathBase.SharedTypes, MLLib.Analysis;

type
  TTestValidation = class(TTestCase)
  published
    procedure TestExplicitRowsAndFailures;
    procedure TestGroupedRowsNeverLeak;
    procedure TestManyDistinctGroups;
    procedure TestStratifiedRowsAndReplay;
  end;

implementation

procedure TTestValidation.TestExplicitRowsAndFailures;
var S: TValidationSplit; LargeCount: Int64;
begin
  S.TrainingRows := TIntegerArray.Create(0, 2);
  S.ValidationRows := TIntegerArray.Create(3);
  TAnalysisKit.ValidateSplit(5, S);
  S.ValidationRows := TIntegerArray.Create(2);
  try
    TAnalysisKit.ValidateSplit(5, S);
    Fail('overlap accepted');
  except on E: EAnalysisError do ; end;
  S.ValidationRows := TIntegerArray.Create(5);
  try
    TAnalysisKit.ValidateSplit(5, S);
    Fail('out-of-range index accepted');
  except on E: EAnalysisError do ; end;
  S.ValidationRows := nil;
  try
    TAnalysisKit.ValidateSplit(5, S);
    Fail('empty validation accepted');
  except on E: EAnalysisError do ; end;
  S.ValidationRows := TIntegerArray.Create(3);
  if SizeOf(SizeInt) > SizeOf(Integer) then
  begin
    LargeCount := Int64(High(Integer)) + 1;
    try
      TAnalysisKit.ValidateSplit(SizeInt(LargeCount), S);
      Fail('unrepresentable row space accepted');
    except on E: EAnalysisError do ; end;
  end;
end;

procedure TTestValidation.TestGroupedRowsNeverLeak;
var
  Groups: TIntegerArray;
  Splits, Replay: TValidationSplits;
  Fold, I, J: Integer;
  Seen: array[0..7] of Integer;
begin
  Groups := TIntegerArray.Create(1, 1, 1, 2, 2, 3, 3, 4);
  Splits := TAnalysisKit.GroupKFoldSplits(Groups, 3, 77);
  Replay := TAnalysisKit.GroupKFoldSplits(Groups, 3, 77);
  AssertEquals(3, Length(Splits));
  FillChar(Seen, SizeOf(Seen), 0);
  for Fold := 0 to High(Splits) do
  begin
    AssertEquals(Length(Splits[Fold].ValidationRows),
      Length(Replay[Fold].ValidationRows));
    for I := 0 to High(Splits[Fold].ValidationRows) do
      AssertEquals(Splits[Fold].ValidationRows[I],
        Replay[Fold].ValidationRows[I]);
    TAnalysisKit.ValidateSplit(Length(Groups), Splits[Fold]);
    for I in Splits[Fold].ValidationRows do
    begin
      Inc(Seen[I]);
      for J in Splits[Fold].TrainingRows do
        AssertTrue('group leakage', Groups[I] <> Groups[J]);
    end;
  end;
  for I := 0 to High(Seen) do AssertEquals(1, Seen[I]);
end;

procedure TTestValidation.TestManyDistinctGroups;
var
  Groups: TIntegerArray;
  Splits: TValidationSplits;
  Seen: array[0..63] of Integer;
  Fold, Row, I: Integer;
begin
  SetLength(Groups, Length(Seen));
  for I := 0 to High(Groups) do Groups[I] := I - 31;
  RandSeed := 321;
  Splits := TAnalysisKit.GroupKFoldSplits(Groups, 8, 77);
  AssertEquals('global RNG unchanged', 321, RandSeed);
  FillChar(Seen, SizeOf(Seen), 0);
  for Fold := 0 to High(Splits) do
  begin
    TAnalysisKit.ValidateSplit(Length(Groups), Splits[Fold]);
    AssertEquals(8, Length(Splits[Fold].ValidationRows));
    for Row in Splits[Fold].ValidationRows do Inc(Seen[Row]);
  end;
  for I := 0 to High(Seen) do AssertEquals(1, Seen[I]);
end;

procedure TTestValidation.TestStratifiedRowsAndReplay;
var
  Labels, A, B: TIntegerArray;
  First, Second: TValidationSplits;
  Fold, I, ZeroCount, OneCount: Integer;
begin
  Labels := TIntegerArray.Create(0, 0, 0, 0, 1, 1, 1, 1);
  RandSeed := 123;
  First := TAnalysisKit.StratifiedKFoldSplits(Labels, 2, 99);
  AssertEquals('global RNG unchanged', 123, RandSeed);
  Second := TAnalysisKit.StratifiedKFoldSplits(Labels, 2, 99);
  for Fold := 0 to 1 do
  begin
    TAnalysisKit.ValidateSplit(Length(Labels), First[Fold]);
    A := First[Fold].ValidationRows;
    B := Second[Fold].ValidationRows;
    AssertEquals(Length(A), Length(B));
    ZeroCount := 0; OneCount := 0;
    for I := 0 to High(A) do
    begin
      AssertEquals(A[I], B[I]);
      if Labels[A[I]] = 0 then Inc(ZeroCount) else Inc(OneCount);
    end;
    AssertEquals(2, ZeroCount);
    AssertEquals(2, OneCount);
  end;
  try
    TAnalysisKit.StratifiedKFoldSplits(Labels, 5, 99);
    Fail('insufficient class size accepted');
  except on E: EAnalysisError do ; end;
end;

initialization
  RegisterTest(TTestValidation);
end.
