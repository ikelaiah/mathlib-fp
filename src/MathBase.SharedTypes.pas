unit MathBase.SharedTypes;

{-----------------------------------------------------------------------------
 MathBase.SharedTypes

 Common numeric array types and helper records shared across all math libs.

 Provides:
   - TIntegerArray, TDoubleArray, TSingleArray, TExtendedArray
   - TDoublePair  (lower/upper interval record)
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}
{$modeswitch advancedrecords}

interface

uses
  Classes, SysUtils;

type
  { Standardized numeric array types }
  TIntegerArray  = array of Integer;
  TDoubleArray   = array of Double;
  TSingleArray   = array of Single;
  TExtendedArray = array of Extended;

  { A record representing a numeric range or interval }
  TDoublePair = record
    Lower: Double;
    Upper: Double;
  end;

{ Convert integer array to double array }
function ToDoubleArray(const Data: TIntegerArray): TDoubleArray; overload;
{ Convert single array to double array }
function ToDoubleArray(const Data: TSingleArray): TDoubleArray; overload;
{ Convert extended array to double array }
function ToDoubleArray(const Data: TExtendedArray): TDoubleArray; overload;

implementation

function ToDoubleArray(const Data: TIntegerArray): TDoubleArray;
var
  I: Integer;
begin
  Result := nil;
  SetLength(Result, Length(Data));
  for I := 0 to High(Data) do
    Result[I] := Data[I];
end;

function ToDoubleArray(const Data: TSingleArray): TDoubleArray;
var
  I: Integer;
begin
  Result := nil;
  SetLength(Result, Length(Data));
  for I := 0 to High(Data) do
    Result[I] := Data[I];
end;

function ToDoubleArray(const Data: TExtendedArray): TDoubleArray;
var
  I: Integer;
begin
  Result := nil;
  SetLength(Result, Length(Data));
  for I := 0 to High(Data) do
    Result[I] := Data[I];
end;

end.
