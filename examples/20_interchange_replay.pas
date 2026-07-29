program InterchangeReplay;

{$mode objfpc}{$H+}{$J-}

uses
  Classes, SysUtils,
  MathBase.Random, MathBase.Interchange,
  AlgebraLib.DenseMatrices;

var
  Stream: TMemoryStream;
  Original, Restored: IDenseDoubleMatrix;
  GeneratorA, GeneratorB: TLocalRandom;
  FirstReplay, SecondReplay: QWord;
begin
  Stream := TMemoryStream.Create;
  try
    Original := TDenseDoubleMatrix.FromValues(2, 3,
      [1.0, 2.0, 3.0, 4.5, 5.5, 6.5]);
    SaveBinary(Stream, Original);
    Stream.Position := 0;
    Restored := LoadDoubleMatrixBinary(Stream, 100);
    Writeln(Summarize(Restored, 2, 3));

    GeneratorA := TLocalRandom.Seeded(180);
    GeneratorA.NextUInt64;
    Stream.Clear;
    SaveRandomStateBinary(Stream, GeneratorA.GetState);
    Stream.Position := 0;
    GeneratorB.SetState(LoadRandomStateBinary(Stream));
    FirstReplay := GeneratorA.NextUInt64;
    SecondReplay := GeneratorB.NextUInt64;
    Writeln('RNG replay matches: ', FirstReplay = SecondReplay);
  finally
    Stream.Free;
  end;
end.
