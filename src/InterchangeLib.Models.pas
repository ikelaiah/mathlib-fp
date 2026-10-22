unit InterchangeLib.Models;

{ Optional persistence adapters for selected stable models. The numerical core
  units remain independent of this unit. }

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math, MathBase.SharedTypes,
  NumericsLib.Interpolation, EngineeringLib.DSP, MLLib.Analysis,
  TimeSeriesLib.StateSpace, StatsLib.GLM, MLLib.PLS;

const
  DEFAULT_MAX_MODEL_ELEMENTS=16000000;

type
  EModelInterchangeError=class(Exception);

procedure SaveCubicSpline(const Stream:TStream;
  const Model:TCubicSplineInterpolator);
function LoadCubicSpline(const Stream:TStream;
  const MaxElements:QWord=DEFAULT_MAX_MODEL_ELEMENTS):
  TCubicSplineInterpolator;
procedure SaveStreamingFIR(const Stream:TStream;
  const Model:TStreamingFIR);
function LoadStreamingFIR(const Stream:TStream;
  const MaxElements:QWord=DEFAULT_MAX_MODEL_ELEMENTS):TStreamingFIR;
procedure SaveStandardization(const Stream:TStream;
  const Model:TStandardizationModel);
function LoadStandardization(const Stream:TStream;
  const MaxElements:QWord=DEFAULT_MAX_MODEL_ELEMENTS):TStandardizationModel;
procedure SaveScalarKalman(const Stream:TStream;
  const Model:TScalarKalmanFilter);
function LoadScalarKalman(const Stream:TStream):TScalarKalmanFilter;
procedure SaveGLMPrediction(const Stream:TStream;
  const Model:TGLMPredictionModel);
function LoadGLMPrediction(const Stream:TStream;
  const MaxElements:QWord=DEFAULT_MAX_MODEL_ELEMENTS):TGLMPredictionModel;
procedure SavePLSPrediction(const Stream:TStream;
  const Model:TPLSPredictionModel);
function LoadPLSPrediction(const Stream:TStream;
  const MaxElements:QWord=DEFAULT_MAX_MODEL_ELEMENTS):TPLSPredictionModel;
function SummarizeCubicSpline(const Model:TCubicSplineInterpolator):String;
function SummarizeStreamingFIR(const Model:TStreamingFIR):String;
function SummarizeStandardization(const Model:TStandardizationModel):String;
function SummarizeScalarKalman(const Model:TScalarKalmanFilter):String;

implementation

type
  TModelKind=(mkCubicSpline=1,mkStreamingFIR=2,
    mkStandardization=3,mkScalarKalman=4,mkGLMPrediction=5,mkPLSPrediction=6);

const
  MODEL_MAGIC:array[0..7] of Byte=(
    Ord('M'),Ord('F'),Ord('P'),Ord('M'),Ord('O'),Ord('D'),Ord('1'),0);
  MODEL_VERSION=1;
  MODEL_HEADER_SIZE=24;

function Finite(const X:Double):Boolean; inline;
begin Result:=not IsNan(X) and not IsInfinite(X); end;

procedure AppendByte(var Bytes:TBytes; Value:Byte);
var N:Integer;
begin N:=Length(Bytes); SetLength(Bytes,N+1); Bytes[N]:=Value; end;

procedure AppendUInt64(var Bytes:TBytes; Value:QWord);
var N,I:Integer;
begin
  N:=Length(Bytes); SetLength(Bytes,N+8);
  for I:=0 to 7 do Bytes[N+I]:=(Value shr (8*I)) and $FF;
end;

procedure AppendDouble(var Bytes:TBytes; Value:Double);
var Bits:QWord;
begin Move(Value,Bits,SizeOf(Bits)); AppendUInt64(Bytes,Bits); end;

procedure PutUInt64(var Bytes:TBytes; Offset:Integer; Value:QWord); forward;

procedure AppendVector(var Bytes:TBytes; const Values:TDoubleArray);
var I,N,Count:Integer; Bits:QWord;
begin
  if Length(Bytes)>High(Integer)-8 then
    raise EModelInterchangeError.Create('Model persistence: vector header exceeds capacity.');
  if Length(Values)>(High(Integer)-8-Length(Bytes)) div 8 then
    raise EModelInterchangeError.Create('Model persistence: vector byte size exceeds capacity.');
  N:=Length(Bytes); Count:=Length(Values);
  SetLength(Bytes,N+8+Count*8); PutUInt64(Bytes,N,Count);
  for I:=0 to High(Values) do
  begin
    if not Finite(Values[I]) then
      raise EModelInterchangeError.CreateFmt(
        'Model persistence: value %d must be finite.',[I]);
    Move(Values[I],Bits,SizeOf(Bits)); PutUInt64(Bytes,N+8+I*8,Bits);
  end;
end;

function CRC32(const Bytes:TBytes):LongWord;
var I,BitIndex:Integer; Value:LongWord;
begin
  Value:=$FFFFFFFF;
  for I:=0 to High(Bytes) do
  begin
    Value:=Value xor Bytes[I];
    for BitIndex:=0 to 7 do
      if (Value and 1)<>0 then
        Value:=(Value shr 1) xor $EDB88320
      else Value:=Value shr 1;
  end;
  Result:=not Value;
end;

procedure PutUInt16(var Bytes:TBytes; Offset:Integer; Value:Word);
begin Bytes[Offset]:=Value and $FF; Bytes[Offset+1]:=Value shr 8; end;

procedure PutUInt32(var Bytes:TBytes; Offset:Integer; Value:LongWord);
var I:Integer;
begin for I:=0 to 3 do Bytes[Offset+I]:=(Value shr (8*I)) and $FF; end;

procedure PutUInt64(var Bytes:TBytes; Offset:Integer; Value:QWord);
var I:Integer;
begin for I:=0 to 7 do Bytes[Offset+I]:=(Value shr (8*I)) and $FF; end;

function GetUInt16(const Bytes:TBytes; Offset:Integer):Word;
begin Result:=Bytes[Offset] or (Word(Bytes[Offset+1]) shl 8); end;

function GetUInt32(const Bytes:TBytes; Offset:Integer):LongWord;
var I:Integer;
begin Result:=0; for I:=0 to 3 do
  Result:=Result or (LongWord(Bytes[Offset+I]) shl (8*I)); end;

function GetUInt64(const Bytes:TBytes; Offset:Integer):QWord;
var I:Integer;
begin Result:=0; for I:=0 to 7 do
  Result:=Result or (QWord(Bytes[Offset+I]) shl (8*I)); end;

procedure WriteEnvelope(const Stream:TStream; Kind:TModelKind;
  const Payload:TBytes);
var Header:TBytes; I:Integer;
begin
  if Stream=nil then
    raise EModelInterchangeError.Create('Model persistence: Stream is nil.');
  SetLength(Header,MODEL_HEADER_SIZE);
  for I:=0 to 7 do Header[I]:=MODEL_MAGIC[I];
  PutUInt16(Header,8,MODEL_VERSION);
  Header[10]:=Ord(Kind);
  Header[11]:=0;
  PutUInt64(Header,12,Length(Payload));
  PutUInt32(Header,20,CRC32(Payload));
  if Length(Header)>0 then Stream.WriteBuffer(Header[0],Length(Header));
  if Length(Payload)>0 then Stream.WriteBuffer(Payload[0],Length(Payload));
end;

procedure ReadExact(const Stream:TStream; var Buffer; Count:SizeInt;
  const Description:String);
var
  Offset,ReadCount:SizeInt;
  Bytes:PByte;
begin
  Offset:=0;
  Bytes:=@Buffer;
  while Offset<Count do
  begin
    ReadCount:=Stream.Read(Bytes[Offset],Count-Offset);
    if ReadCount<=0 then
      raise EModelInterchangeError.Create(
        'Model persistence: truncated '+Description+'.');
    Inc(Offset,ReadCount);
  end;
end;

function ReadEnvelope(const Stream:TStream; ExpectedKind:TModelKind;
  MaxBytes:QWord):TBytes;
var Header:TBytes; I:Integer; PayloadLength:QWord;
begin
  Result:=nil;
  if Stream=nil then
    raise EModelInterchangeError.Create('Model persistence: Stream is nil.');
  SetLength(Header,MODEL_HEADER_SIZE);
  ReadExact(Stream,Header[0],Length(Header),'header');
  for I:=0 to 7 do if Header[I]<>MODEL_MAGIC[I] then
    raise EModelInterchangeError.Create(
      'Model persistence: invalid magic.');
  if GetUInt16(Header,8)<>MODEL_VERSION then
    raise EModelInterchangeError.Create(
      'Model persistence: incompatible version.');
  if Header[10]<>Ord(ExpectedKind) then
    raise EModelInterchangeError.Create(
      'Model persistence: object kind does not match loader.');
  if Header[11]<>0 then
    raise EModelInterchangeError.Create(
      'Model persistence: reserved header byte is nonzero.');
  PayloadLength:=GetUInt64(Header,12);
  if PayloadLength>MaxBytes then
    raise EModelInterchangeError.Create(
      'Model persistence: payload exceeds configured resource limit.');
  if PayloadLength>QWord(High(SizeInt)) then
    raise EModelInterchangeError.Create(
      'Model persistence: payload does not fit address space.');
  SetLength(Result,SizeInt(PayloadLength));
  if Length(Result)>0 then
    ReadExact(Stream,Result[0],Length(Result),'payload');
  if CRC32(Result)<>GetUInt32(Header,20) then
    raise EModelInterchangeError.Create(
      'Model persistence: checksum mismatch.');
end;

function ReadUInt64(const Bytes:TBytes; var Offset:Integer):QWord;
begin
  if Offset>Length(Bytes)-8 then
    raise EModelInterchangeError.Create(
      'Model persistence: truncated integer field.');
  Result:=GetUInt64(Bytes,Offset); Inc(Offset,8);
end;

function ReadDouble(const Bytes:TBytes; var Offset:Integer):Double;
var Bits:QWord;
begin
  Bits:=ReadUInt64(Bytes,Offset);
  Move(Bits,Result,SizeOf(Result));
  if not Finite(Result) then
    raise EModelInterchangeError.Create(
      'Model persistence: non-finite numeric field.');
end;

function ReadVector(const Bytes:TBytes; var Offset:Integer;
  MaxElements:QWord):TDoubleArray;
var Count:QWord; I:Integer;
begin
  Result:=nil; Count:=ReadUInt64(Bytes,Offset);
  if Count>MaxElements then
    raise EModelInterchangeError.Create(
      'Model persistence: vector exceeds configured element limit.');
  if Count>QWord(High(SizeInt)) then
    raise EModelInterchangeError.Create(
      'Model persistence: vector does not fit address space.');
  if Count>QWord((Length(Bytes)-Offset) div 8) then
    raise EModelInterchangeError.Create(
      'Model persistence: truncated vector payload.');
  SetLength(Result,SizeInt(Count));
  for I:=0 to High(Result) do Result[I]:=ReadDouble(Bytes,Offset);
end;

procedure RequireEnd(const Bytes:TBytes; Offset:Integer);
begin
  if Offset<>Length(Bytes) then
    raise EModelInterchangeError.Create(
      'Model persistence: unexpected trailing payload.');
end;

procedure SaveCubicSpline(const Stream:TStream;
  const Model:TCubicSplineInterpolator);
var Payload:TBytes; N:Integer;
begin
  Payload:=nil; N:=Length(Model.X);
  if (N<2) or (Length(Model.Y)<>N) or
     (Length(Model.LinearCoefficients)<>N-1) or
     (Length(Model.QuadraticCoefficients)<>N-1) or
     (Length(Model.CubicCoefficients)<>N-1) then
    raise EModelInterchangeError.Create(
      'SaveCubicSpline: model arrays are inconsistent.');
  AppendByte(Payload,Ord(Model.Boundary));
  AppendVector(Payload,Model.X);
  AppendVector(Payload,Model.Y);
  AppendVector(Payload,Model.LinearCoefficients);
  AppendVector(Payload,Model.QuadraticCoefficients);
  AppendVector(Payload,Model.CubicCoefficients);
  WriteEnvelope(Stream,mkCubicSpline,Payload);
end;

function LoadCubicSpline(const Stream:TStream;
  const MaxElements:QWord):TCubicSplineInterpolator;
var Payload:TBytes; Offset,I,N:Integer;
begin
  Result:=Default(TCubicSplineInterpolator);
  if MaxElements<2 then
    raise EModelInterchangeError.Create(
      'LoadCubicSpline: MaxElements must be at least two.');
  if MaxElements>(High(QWord)-64) div 40 then
    raise EModelInterchangeError.Create(
      'LoadCubicSpline: MaxElements byte calculation overflows.');
  Payload:=ReadEnvelope(Stream,mkCubicSpline,
    64+MaxElements*5*8);
  if Length(Payload)<1 then
    raise EModelInterchangeError.Create(
      'LoadCubicSpline: truncated boundary field.');
  if Payload[0]>Ord(High(TSplineBoundaryKind)) then
    raise EModelInterchangeError.Create(
      'LoadCubicSpline: invalid boundary kind.');
  Result.Boundary:=TSplineBoundaryKind(Payload[0]); Offset:=1;
  Result.X:=ReadVector(Payload,Offset,MaxElements);
  Result.Y:=ReadVector(Payload,Offset,MaxElements);
  Result.LinearCoefficients:=ReadVector(Payload,Offset,MaxElements);
  Result.QuadraticCoefficients:=ReadVector(Payload,Offset,MaxElements);
  Result.CubicCoefficients:=ReadVector(Payload,Offset,MaxElements);
  RequireEnd(Payload,Offset);
  N:=Length(Result.X);
  if (N<2) or (Length(Result.Y)<>N) or
     (Length(Result.LinearCoefficients)<>N-1) or
     (Length(Result.QuadraticCoefficients)<>N-1) or
     (Length(Result.CubicCoefficients)<>N-1) then
    raise EModelInterchangeError.Create(
      'LoadCubicSpline: model array lengths are inconsistent.');
  for I:=1 to N-1 do if Result.X[I]<=Result.X[I-1] then
    raise EModelInterchangeError.Create(
      'LoadCubicSpline: knots must be strictly increasing.');
end;

procedure SaveStreamingFIR(const Stream:TStream; const Model:TStreamingFIR);
var Payload:TBytes;
begin
  Payload:=nil;
  AppendVector(Payload,Model.Coefficients);
  AppendVector(Payload,Model.History);
  WriteEnvelope(Stream,mkStreamingFIR,Payload);
end;

function LoadStreamingFIR(const Stream:TStream;
  const MaxElements:QWord):TStreamingFIR;
var Payload:TBytes; Offset:Integer; Coefficients,History:TDoubleArray;
begin
  if MaxElements<1 then
    raise EModelInterchangeError.Create(
      'LoadStreamingFIR: MaxElements must be positive.');
  if MaxElements>(High(QWord)-32) div 16 then
    raise EModelInterchangeError.Create(
      'LoadStreamingFIR: MaxElements byte calculation overflows.');
  Payload:=ReadEnvelope(Stream,mkStreamingFIR,32+MaxElements*16);
  Offset:=0;
  Coefficients:=ReadVector(Payload,Offset,MaxElements);
  History:=ReadVector(Payload,Offset,MaxElements);
  RequireEnd(Payload,Offset);
  if (Length(Coefficients)<1) or
     (Length(History)<>Length(Coefficients)-1) then
    raise EModelInterchangeError.Create(
      'LoadStreamingFIR: coefficient/history lengths are inconsistent.');
  Result:=TStreamingFIR.Create(Coefficients);
  Result.RestoreHistory(History);
end;

procedure SaveStandardization(const Stream:TStream;
  const Model:TStandardizationModel);
var Payload:TBytes; I:Integer;
begin
  if (Length(Model.Means)<1) or
     (Length(Model.Scales)<>Length(Model.Means)) then
    raise EModelInterchangeError.Create(
      'SaveStandardization: model arrays are inconsistent.');
  for I:=0 to High(Model.Scales) do
    if not Finite(Model.Scales[I]) or (Model.Scales[I]<=0) then
      raise EModelInterchangeError.Create(
        'SaveStandardization: scales must be finite and positive.');
  Payload:=nil;
  AppendVector(Payload,Model.Means);
  AppendVector(Payload,Model.Scales);
  WriteEnvelope(Stream,mkStandardization,Payload);
end;

function LoadStandardization(const Stream:TStream;
  const MaxElements:QWord):TStandardizationModel;
var Payload:TBytes; Offset,I:Integer;
begin
  Result:=Default(TStandardizationModel);
  if MaxElements<1 then
    raise EModelInterchangeError.Create(
      'LoadStandardization: MaxElements must be positive.');
  if MaxElements>(High(QWord)-32) div 16 then
    raise EModelInterchangeError.Create(
      'LoadStandardization: MaxElements byte calculation overflows.');
  Payload:=ReadEnvelope(Stream,mkStandardization,32+MaxElements*16);
  Offset:=0;
  Result.Means:=ReadVector(Payload,Offset,MaxElements);
  Result.Scales:=ReadVector(Payload,Offset,MaxElements);
  RequireEnd(Payload,Offset);
  if (Length(Result.Means)<1) or
     (Length(Result.Scales)<>Length(Result.Means)) then
    raise EModelInterchangeError.Create(
      'LoadStandardization: model arrays are inconsistent.');
  for I:=0 to High(Result.Scales) do if Result.Scales[I]<=0 then
    raise EModelInterchangeError.Create(
      'LoadStandardization: scales must be positive.');
end;

procedure SaveScalarKalman(const Stream:TStream;
  const Model:TScalarKalmanFilter);
var Payload:TBytes; Configuration:TScalarKalmanConfiguration;
begin
  Payload:=nil; Configuration:=Model.Configuration;
  AppendDouble(Payload,Configuration.Transition);
  AppendDouble(Payload,Configuration.Observation);
  AppendDouble(Payload,Configuration.ProcessVariance);
  AppendDouble(Payload,Configuration.MeasurementVariance);
  AppendDouble(Payload,Model.Estimate);
  AppendDouble(Payload,Model.Variance);
  WriteEnvelope(Stream,mkScalarKalman,Payload);
end;

function LoadScalarKalman(const Stream:TStream):TScalarKalmanFilter;
var
  Payload:TBytes;
  Offset:Integer;
  Configuration:TScalarKalmanConfiguration;
  Transition,Observation,ProcessVariance,MeasurementVariance,
    Estimate,Variance:Double;
begin
  Payload:=ReadEnvelope(Stream,mkScalarKalman,48);
  Offset:=0;
  Transition:=ReadDouble(Payload,Offset);
  Observation:=ReadDouble(Payload,Offset);
  ProcessVariance:=ReadDouble(Payload,Offset);
  MeasurementVariance:=ReadDouble(Payload,Offset);
  Estimate:=ReadDouble(Payload,Offset);
  Variance:=ReadDouble(Payload,Offset);
  RequireEnd(Payload,Offset);
  Configuration:=TScalarKalmanConfiguration.Create(
    Transition,Observation,ProcessVariance,MeasurementVariance);
  Result:=TScalarKalmanFilter.Create(Configuration,Estimate,Variance);
end;

function PredictionByteLimit(const MaxElements,Overhead:QWord):QWord;
begin
  if (MaxElements<1) or
    (MaxElements>(QWord(High(Integer))-Overhead) div 8) then
    raise EModelInterchangeError.Create('Prediction model: invalid or excessive element limit.');
  Result:=Overhead+MaxElements*8;
end;

procedure CheckGLMPrediction(const Model:TGLMPredictionModel);
begin
  if not (Model.Family in [gfBernoulliLogit,gfPoissonLog]) or
    (Length(Model.Coefficients)=0) or
    (Model.UsesExposure and (Model.Family<>gfPoissonLog)) then
    raise EModelInterchangeError.Create('GLM prediction model: invalid family, shape or exposure kind.');
end;

procedure SaveGLMPrediction(const Stream:TStream;
  const Model:TGLMPredictionModel);
var Payload:TBytes;
begin
  CheckGLMPrediction(Model);
  Payload:=nil; SetLength(Payload,8);
  Payload[0]:=1; Payload[1]:=Ord(Model.Family); Payload[2]:=Ord(Model.Family);
  if Model.UsesOffsets then Payload[6]:=1;
  if Model.UsesExposure then Payload[6]:=Payload[6] or 2;
  AppendVector(Payload,Model.Coefficients);
  WriteEnvelope(Stream,mkGLMPrediction,Payload);
end;

function LoadGLMPrediction(const Stream:TStream;
  const MaxElements:QWord):TGLMPredictionModel;
var Payload:TBytes; Offset:Integer;
begin
  Result:=Default(TGLMPredictionModel);
  Payload:=ReadEnvelope(Stream,mkGLMPrediction,PredictionByteLimit(MaxElements,16));
  if Length(Payload)<16 then
    raise EModelInterchangeError.Create('GLM prediction model: truncated header/vector.');
  if (Payload[0]<>1) or (Payload[1]>Ord(High(TGLMFamily))) or
    (Payload[2]<>Payload[1]) or (Payload[3]<>0) or (Payload[4]<>0) or
    (Payload[5]<>0) or ((Payload[6] and $FC)<>0) or (Payload[7]<>0) then
    raise EModelInterchangeError.Create('GLM prediction model: unsupported encoding or convention.');
  Result.Family:=TGLMFamily(Payload[1]);
  Result.UsesOffsets:=(Payload[6] and 1)<>0;
  Result.UsesExposure:=(Payload[6] and 2)<>0;
  Offset:=8; Result.Coefficients:=ReadVector(Payload,Offset,MaxElements);
  RequireEnd(Payload,Offset); CheckGLMPrediction(Result);
end;

procedure SavePLSPrediction(const Stream:TStream;
  const Model:TPLSPredictionModel);
var Payload:TBytes;
begin
  if (Length(Model.Coefficients)=0) or not Finite(Model.Intercept) then
    raise EModelInterchangeError.Create('PLS prediction model: nonempty coefficients and finite intercept required.');
  Payload:=nil; SetLength(Payload,8); Payload[0]:=1; Payload[1]:=1;
  AppendDouble(Payload,Model.Intercept); AppendVector(Payload,Model.Coefficients);
  WriteEnvelope(Stream,mkPLSPrediction,Payload);
end;

function LoadPLSPrediction(const Stream:TStream;
  const MaxElements:QWord):TPLSPredictionModel;
var Payload:TBytes; Offset,I:Integer;
begin
  Result:=Default(TPLSPredictionModel);
  Payload:=ReadEnvelope(Stream,mkPLSPrediction,PredictionByteLimit(MaxElements,24));
  if Length(Payload)<24 then
    raise EModelInterchangeError.Create('PLS prediction model: truncated header/vector.');
  if (Payload[0]<>1) or (Payload[1]<>1) or (Payload[2]<>0) or (Payload[3]<>0) then
    raise EModelInterchangeError.Create('PLS prediction model: unsupported encoding or convention.');
  for I:=4 to 7 do if Payload[I]<>0 then
    raise EModelInterchangeError.Create('PLS prediction model: reserved field is nonzero.');
  Offset:=8; Result.Intercept:=ReadDouble(Payload,Offset);
  Result.Coefficients:=ReadVector(Payload,Offset,MaxElements); RequireEnd(Payload,Offset);
  if Length(Result.Coefficients)=0 then
    raise EModelInterchangeError.Create('PLS prediction model: nonempty coefficients required.');
end;

function SummarizeCubicSpline(
  const Model:TCubicSplineInterpolator):String;
begin
  Result:=Format('Cubic spline knots=%d segments=%d boundary=%d',
    [Length(Model.X),Length(Model.LinearCoefficients),Ord(Model.Boundary)]);
end;

function SummarizeStreamingFIR(const Model:TStreamingFIR):String;
begin
  Result:=Format('Streaming FIR taps=%d retained-state=%d',
    [Length(Model.Coefficients),Model.StateSize]);
end;

function SummarizeStandardization(
  const Model:TStandardizationModel):String;
begin
  Result:=Format('Standardization features=%d',
    [Length(Model.Means)]);
end;

function SummarizeScalarKalman(
  const Model:TScalarKalmanFilter):String;
begin
  Result:=Format('Scalar Kalman state=1 retained-values=2 variance=%.6g',
    [Model.Variance]);
end;

end.
