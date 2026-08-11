program PortabilityProbe;

{$mode objfpc}{$H+}{$J-}

uses
  Classes, SysUtils,
  MathBase.SharedTypes, MathBase.Interchange;

const
  RELEASE = '1.9.6';
  COMPILER_VERSION = {$I %FPCVERSION%};

function TargetOS: string;
begin
  {$IFDEF WIN64}Result := 'win64';{$ENDIF}
  {$IFDEF WIN32}Result := 'win32';{$ENDIF}
  {$IFDEF LINUX}Result := 'linux';{$ENDIF}
  {$IFDEF DARWIN}Result := 'darwin';{$ENDIF}
  {$IF not defined(WIN64) and not defined(WIN32) and not defined(LINUX) and not defined(DARWIN)}
  Result := 'unknown';
  {$ENDIF}
end;

function TargetCPU: string;
begin
  {$IFDEF CPUX86_64}Result := 'x86_64';{$ENDIF}
  {$IFDEF CPUI386}Result := 'i386';{$ENDIF}
  {$IFDEF CPUAARCH64}Result := 'aarch64';{$ENDIF}
  {$IF not defined(CPUX86_64) and not defined(CPUI386) and not defined(CPUAARCH64)}
  Result := 'unknown';
  {$ENDIF}
end;

function EndianName: string;
var
  Value: Word;
begin
  Value := 1;
  if PByte(@Value)^ = 1 then Result := 'little' else Result := 'big';
end;

function BytesToHex(const Stream: TMemoryStream): string;
const
  DIGITS: array[0..15] of Char = '0123456789abcdef';
var
  I: SizeInt;
  Value: Byte;
begin
  SetLength(Result, Stream.Size * 2);
  for I := 0 to Stream.Size - 1 do
  begin
    Value := PByte(Stream.Memory)[I];
    Result[I * 2 + 1] := DIGITS[Value shr 4];
    Result[I * 2 + 2] := DIGITS[Value and $0F];
  end;
end;

function BinaryFixture: string;
var
  Stream: TMemoryStream;
begin
  Stream := TMemoryStream.Create;
  try
    SaveBinary(Stream, TDoubleArray.Create(1.0));
    Result := BytesToHex(Stream);
  finally
    Stream.Free;
  end;
end;

function LocaleGuard: string;
var
  Previous: TFormatSettings;
  Text: string;
begin
  Previous := DefaultFormatSettings;
  try
    DefaultFormatSettings.DecimalSeparator := ',';
    Text := DoubleVectorToInvariant(TDoubleArray.Create(1.5));
    if Pos('1.5', Text) > 0 then Result := 'pass' else Result := 'fail';
  finally
    DefaultFormatSettings := Previous;
  end;
end;

function NumericalChecksum: string;
var
  Value: Double;
  Bits: QWord;
begin
  Value := (0.5 + 0.25) + 0.25;
  Move(Value, Bits, SizeOf(Bits));
  Result := LowerCase(IntToHex(Bits, 16));
end;

begin
  Writeln('mathlib-fp portability probe');
  Writeln('PORT|release=', RELEASE,
    '|target_os=', TargetOS,
    '|target_cpu=', TargetCPU,
    '|compiler_version=', COMPILER_VERSION,
    '|pointer_bits=', SizeOf(Pointer) * 8,
    '|sizeint_bits=', SizeOf(SizeInt) * 8,
    '|single_bytes=', SizeOf(Single),
    '|double_bytes=', SizeOf(Double),
    '|extended_bytes=', SizeOf(Extended),
    '|endian=', EndianName,
    '|locale_guard=', LocaleGuard,
    '|numerical_checksum=', NumericalChecksum,
    '|binary_fixture_hex=', BinaryFixture);
end.
