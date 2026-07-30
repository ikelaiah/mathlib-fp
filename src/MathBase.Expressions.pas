unit MathBase.Expressions;

{ Opt-in bounded mathematical expression evaluator. It deliberately contains
  no assignment, loops, recursion, I/O, environment, process, or network
  primitives. }

{$mode objfpc}{$H+}{$J-}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, Math, MathBase.SharedTypes, AlgebraLib.DenseMatrices;

type
  EExpressionError=class(Exception);
  TExpressionValueKind=(evScalar,evVector,evMatrix);

  TExpressionValue=record
    Kind:TExpressionValueKind;
    Scalar:Double;
    Vector:TDoubleArray;
    Matrix:IDenseDoubleMatrix;
    class function FromScalar(const Value:Double):TExpressionValue; static;
    class function FromVector(const Value:TDoubleArray):TExpressionValue;
      static;
    class function FromMatrix(const Value:IDenseDoubleMatrix):
      TExpressionValue; static;
  end;

  TExpressionSymbol=record
    Name:String;
    Value:TExpressionValue;
  end;
  TExpressionSymbols=array of TExpressionSymbol;

  TExpressionLimits=record
    MaxTextLength:Integer;
    MaxDepth:Integer;
    MaxOperations:Int64;
    MaxElements:Int64;
    class function Defaults:TExpressionLimits; static;
  end;

  TExpressionEvaluator=class
  public
    class function Evaluate(const Text:String;
      const Symbols:array of TExpressionSymbol;
      const Limits:TExpressionLimits):TExpressionValue; static;
  end;

implementation

function Finite(const X:Double):Boolean; inline;
begin Result:=not IsNan(X) and not IsInfinite(X); end;

procedure ValidateValue(const Value:TExpressionValue;
  const Operation:String);
var I,J:Integer;
begin
  case Value.Kind of
    evScalar:
      if not Finite(Value.Scalar) then
        raise EExpressionError.Create(Operation+': scalar must be finite.');
    evVector:
      for I:=0 to High(Value.Vector) do if not Finite(Value.Vector[I]) then
        raise EExpressionError.CreateFmt(
          '%s: vector element %d must be finite.',[Operation,I]);
    evMatrix:
      begin
        if Value.Matrix=nil then
          raise EExpressionError.Create(Operation+': matrix must not be nil.');
        for I:=0 to Value.Matrix.Rows-1 do
          for J:=0 to Value.Matrix.Cols-1 do
            if not Finite(Value.Matrix[I,J]) then
              raise EExpressionError.CreateFmt(
                '%s: matrix element [%d,%d] must be finite.',
                [Operation,I,J]);
      end;
  else
    raise EExpressionError.Create(Operation+': unknown value kind.');
  end;
end;

function CloneValue(const Value:TExpressionValue):TExpressionValue;
begin
  Result:=Default(TExpressionValue);
  Result.Kind:=Value.Kind;
  case Value.Kind of
    evScalar: Result.Scalar:=Value.Scalar;
    evVector: Result.Vector:=Copy(Value.Vector);
    evMatrix:
      if Value.Matrix<>nil then Result.Matrix:=Value.Matrix.Clone;
  end;
end;

class function TExpressionValue.FromScalar(
  const Value:Double):TExpressionValue;
begin
  Result:=Default(TExpressionValue);
  Result.Kind:=evScalar; Result.Scalar:=Value;
  ValidateValue(Result,'TExpressionValue.FromScalar');
end;

class function TExpressionValue.FromVector(
  const Value:TDoubleArray):TExpressionValue;
begin
  Result:=Default(TExpressionValue);
  Result.Kind:=evVector; Result.Vector:=Copy(Value);
  ValidateValue(Result,'TExpressionValue.FromVector');
end;

class function TExpressionValue.FromMatrix(
  const Value:IDenseDoubleMatrix):TExpressionValue;
begin
  Result:=Default(TExpressionValue);
  Result.Kind:=evMatrix;
  if Value<>nil then Result.Matrix:=Value.Clone;
  ValidateValue(Result,'TExpressionValue.FromMatrix');
end;

class function TExpressionLimits.Defaults:TExpressionLimits;
begin
  Result:=Default(TExpressionLimits);
  Result.MaxTextLength:=16384;
  Result.MaxDepth:=64;
  Result.MaxOperations:=1000000;
  Result.MaxElements:=1000000;
end;

type
  TExpressionParser=class
  private
    FText:String;
    FPosition:Integer;
    FSymbols:TExpressionSymbols;
    FLimits:TExpressionLimits;
    FOperations:Int64;
    FDepth:Integer;
    procedure SkipSpace;
    function Peek:Char;
    function Match(C:Char):Boolean;
    procedure RequireCharacter(C:Char; const Context:String);
    procedure ConsumeOperations(Count:Int64);
    procedure CheckElements(Count:Int64);
    procedure EnterDepth;
    procedure LeaveDepth;
    function ParseExpression:TExpressionValue;
    function ParseTerm:TExpressionValue;
    function ParseUnary:TExpressionValue;
    function ParsePower:TExpressionValue;
    function ParsePrimary:TExpressionValue;
    function ParseNumber:TExpressionValue;
    function ParseIdentifier:String;
    function FindSymbol(const Name:String):TExpressionValue;
    function AddValues(const A,B:TExpressionValue;
      FactorB:Double):TExpressionValue;
    function MultiplyValues(const A,B:TExpressionValue;
      Divide:Boolean):TExpressionValue;
    function NegateValue(const A:TExpressionValue):TExpressionValue;
    function PowerValues(const A,B:TExpressionValue):TExpressionValue;
    function ApplyFunction(const Name:String;
      const A:TExpressionValue; HasB:Boolean;
      const B:TExpressionValue):TExpressionValue;
    function ApplyElementFunction(const Name:String; X:Double):Double;
  public
    constructor Create(const Text:String;
      const Symbols:array of TExpressionSymbol;
      const Limits:TExpressionLimits);
    function Run:TExpressionValue;
  end;

function ValidIdentifier(const Name:String):Boolean;
var I:Integer;
begin
  Result:=Length(Name)>0;
  if not Result then Exit;
  if not (Name[1] in ['A'..'Z','a'..'z','_']) then Exit(False);
  for I:=2 to Length(Name) do
    if not (Name[I] in ['A'..'Z','a'..'z','0'..'9','_']) then Exit(False);
end;

function ValueElementCount(const Value:TExpressionValue):Int64;
begin
  case Value.Kind of
    evScalar: Result:=1;
    evVector: Result:=Length(Value.Vector);
    evMatrix: Result:=Int64(Value.Matrix.Rows)*Value.Matrix.Cols;
  else Result:=0;
  end;
end;

constructor TExpressionParser.Create(const Text:String;
  const Symbols:array of TExpressionSymbol;
  const Limits:TExpressionLimits);
var I,J:Integer; TotalElements:Int64;
begin
  inherited Create;
  if (Limits.MaxTextLength<1) or (Limits.MaxDepth<1) or
     (Limits.MaxOperations<1) or (Limits.MaxElements<1) then
    raise EExpressionError.Create('Expression evaluator: invalid limits.');
  if Length(Text)>Limits.MaxTextLength then
    raise EExpressionError.Create(
      'Expression evaluator: text length limit exceeded.');
  FText:=Text; FPosition:=1; FLimits:=Limits;
  SetLength(FSymbols,Length(Symbols));
  TotalElements:=0;
  for I:=0 to High(Symbols) do
  begin
    if not ValidIdentifier(Symbols[I].Name) then
      raise EExpressionError.CreateFmt(
        'Expression evaluator: invalid symbol name "%s".',[Symbols[I].Name]);
    for J:=0 to I-1 do if Symbols[J].Name=Symbols[I].Name then
      raise EExpressionError.CreateFmt(
        'Expression evaluator: duplicate symbol "%s".',[Symbols[I].Name]);
    ValidateValue(Symbols[I].Value,'Expression symbol '+Symbols[I].Name);
    if TotalElements>Limits.MaxElements-ValueElementCount(Symbols[I].Value) then
      raise EExpressionError.Create(
        'Expression evaluator: symbol element limit exceeded.');
    Inc(TotalElements,ValueElementCount(Symbols[I].Value));
    FSymbols[I].Name:=Symbols[I].Name;
    FSymbols[I].Value:=CloneValue(Symbols[I].Value);
  end;
end;

procedure TExpressionParser.SkipSpace;
begin
  while (FPosition<=Length(FText)) and
        (FText[FPosition] in [' ',#9,#10,#13]) do Inc(FPosition);
end;

function TExpressionParser.Peek:Char;
begin
  SkipSpace;
  if FPosition>Length(FText) then Result:=#0 else Result:=FText[FPosition];
end;

function TExpressionParser.Match(C:Char):Boolean;
begin
  Result:=Peek=C;
  if Result then Inc(FPosition);
end;

procedure TExpressionParser.RequireCharacter(C:Char; const Context:String);
begin
  if not Match(C) then
    raise EExpressionError.CreateFmt(
      'Expression evaluator: expected "%s" %s at character %d.',
      [C,Context,FPosition]);
end;

procedure TExpressionParser.ConsumeOperations(Count:Int64);
begin
  if (Count<0) or (FOperations>FLimits.MaxOperations-Count) then
    raise EExpressionError.Create(
      'Expression evaluator: operation limit exceeded.');
  Inc(FOperations,Count);
end;

procedure TExpressionParser.CheckElements(Count:Int64);
begin
  if (Count<0) or (Count>FLimits.MaxElements) then
    raise EExpressionError.Create(
      'Expression evaluator: element limit exceeded.');
end;

procedure TExpressionParser.EnterDepth;
begin
  Inc(FDepth);
  if FDepth>FLimits.MaxDepth then
    raise EExpressionError.Create(
      'Expression evaluator: parse depth limit exceeded.');
end;

procedure TExpressionParser.LeaveDepth;
begin Dec(FDepth); end;

function TExpressionParser.Run:TExpressionValue;
begin
  if Trim(FText)='' then
    raise EExpressionError.Create('Expression evaluator: expression is empty.');
  Result:=ParseExpression;
  SkipSpace;
  if FPosition<=Length(FText) then
    raise EExpressionError.CreateFmt(
      'Expression evaluator: unexpected character "%s" at %d.',
      [FText[FPosition],FPosition]);
  ValidateValue(Result,'Expression result');
end;

function TExpressionParser.ParseExpression:TExpressionValue;
var Right:TExpressionValue;
begin
  Result:=ParseTerm;
  while True do
    if Match('+') then
    begin Right:=ParseTerm; Result:=AddValues(Result,Right,1); end
    else if Match('-') then
    begin Right:=ParseTerm; Result:=AddValues(Result,Right,-1); end
    else Break;
end;

function TExpressionParser.ParseTerm:TExpressionValue;
var Right:TExpressionValue;
begin
  Result:=ParseUnary;
  while True do
    if Match('*') then
    begin Right:=ParseUnary; Result:=MultiplyValues(Result,Right,False); end
    else if Match('/') then
    begin Right:=ParseUnary; Result:=MultiplyValues(Result,Right,True); end
    else Break;
end;

function TExpressionParser.ParseUnary:TExpressionValue;
var Negative:Boolean;
begin
  Negative:=False;
  while True do
    if Match('+') then
    begin
      { Unary plus changes no value. }
    end
    else if Match('-') then Negative:=not Negative
    else Break;
  Result:=ParsePower;
  if Negative then Result:=NegateValue(Result);
end;

function TExpressionParser.ParsePower:TExpressionValue;
var Right:TExpressionValue;
begin
  Result:=ParsePrimary;
  if Match('^') then
  begin
    EnterDepth;
    try Right:=ParseUnary; finally LeaveDepth; end;
    Result:=PowerValues(Result,Right);
  end;
end;

function TExpressionParser.ParsePrimary:TExpressionValue;
var
  Name:String;
  A,B:TExpressionValue;
  HasB:Boolean;
begin
  if Match('(') then
  begin
    EnterDepth;
    try
      Result:=ParseExpression;
      RequireCharacter(')','to close parenthesized expression');
    finally
      LeaveDepth;
    end;
    Exit;
  end;
  if Peek in ['0'..'9','.'] then Exit(ParseNumber);
  if Peek in ['A'..'Z','a'..'z','_'] then
  begin
    Name:=ParseIdentifier;
    if not Match('(') then Exit(FindSymbol(Name));
    EnterDepth;
    try
      A:=ParseExpression; HasB:=False; B:=Default(TExpressionValue);
      if Match(',') then begin B:=ParseExpression; HasB:=True; end;
      RequireCharacter(')','to close function call');
      Result:=ApplyFunction(LowerCase(Name),A,HasB,B);
    finally
      LeaveDepth;
    end;
    Exit;
  end;
  raise EExpressionError.CreateFmt(
    'Expression evaluator: expected a value at character %d.',[FPosition]);
end;

function TExpressionParser.ParseNumber:TExpressionValue;
var
  Start,Code:Integer;
  SeenDigit:Boolean;
  Value:Double;
begin
  SkipSpace; Start:=FPosition; SeenDigit:=False;
  while (FPosition<=Length(FText)) and (FText[FPosition] in ['0'..'9']) do
  begin SeenDigit:=True; Inc(FPosition); end;
  if (FPosition<=Length(FText)) and (FText[FPosition]='.') then
  begin
    Inc(FPosition);
    while (FPosition<=Length(FText)) and
          (FText[FPosition] in ['0'..'9']) do
    begin SeenDigit:=True; Inc(FPosition); end;
  end;
  if not SeenDigit then
    raise EExpressionError.CreateFmt(
      'Expression evaluator: invalid number at character %d.',[Start]);
  if (FPosition<=Length(FText)) and (FText[FPosition] in ['e','E']) then
  begin
    Inc(FPosition);
    if (FPosition<=Length(FText)) and (FText[FPosition] in ['+','-']) then
      Inc(FPosition);
    if (FPosition>Length(FText)) or
       not (FText[FPosition] in ['0'..'9']) then
      raise EExpressionError.Create(
        'Expression evaluator: exponent requires digits.');
    while (FPosition<=Length(FText)) and
          (FText[FPosition] in ['0'..'9']) do Inc(FPosition);
  end;
  Val(Copy(FText,Start,FPosition-Start),Value,Code);
  if (Code<>0) or not Finite(Value) then
    raise EExpressionError.Create('Expression evaluator: invalid finite number.');
  Result:=TExpressionValue.FromScalar(Value);
end;

function TExpressionParser.ParseIdentifier:String;
var Start:Integer;
begin
  SkipSpace; Start:=FPosition;
  Inc(FPosition);
  while (FPosition<=Length(FText)) and
        (FText[FPosition] in ['A'..'Z','a'..'z','0'..'9','_']) do
    Inc(FPosition);
  Result:=Copy(FText,Start,FPosition-Start);
end;

function TExpressionParser.FindSymbol(const Name:String):TExpressionValue;
var I:Integer;
begin
  for I:=0 to High(FSymbols) do if FSymbols[I].Name=Name then
    Exit(CloneValue(FSymbols[I].Value));
  raise EExpressionError.CreateFmt(
    'Expression evaluator: unknown symbol "%s".',[Name]);
end;

function TExpressionParser.AddValues(const A,B:TExpressionValue;
  FactorB:Double):TExpressionValue;
var I,J:Integer;
begin
  Result:=Default(TExpressionValue);
  if A.Kind<>B.Kind then
    raise EExpressionError.Create(
      'Expression evaluator: addition requires matching value kinds.');
  Result.Kind:=A.Kind;
  case A.Kind of
    evScalar:
      begin ConsumeOperations(1); Result.Scalar:=A.Scalar+FactorB*B.Scalar; end;
    evVector:
      begin
        if Length(A.Vector)<>Length(B.Vector) then
          raise EExpressionError.Create(
            'Expression evaluator: vector addition shape mismatch.');
        CheckElements(Length(A.Vector)); ConsumeOperations(Length(A.Vector));
        SetLength(Result.Vector,Length(A.Vector));
        for I:=0 to High(Result.Vector) do
          Result.Vector[I]:=A.Vector[I]+FactorB*B.Vector[I];
      end;
    evMatrix:
      begin
        if (A.Matrix.Rows<>B.Matrix.Rows) or
           (A.Matrix.Cols<>B.Matrix.Cols) then
          raise EExpressionError.Create(
            'Expression evaluator: matrix addition shape mismatch.');
        CheckElements(Int64(A.Matrix.Rows)*A.Matrix.Cols);
        ConsumeOperations(Int64(A.Matrix.Rows)*A.Matrix.Cols);
        Result.Matrix:=TDenseDoubleMatrix.Zeros(A.Matrix.Rows,A.Matrix.Cols);
        for I:=0 to A.Matrix.Rows-1 do for J:=0 to A.Matrix.Cols-1 do
          Result.Matrix[I,J]:=A.Matrix[I,J]+FactorB*B.Matrix[I,J];
      end;
  end;
  ValidateValue(Result,'Expression addition');
end;

function TExpressionParser.MultiplyValues(const A,B:TExpressionValue;
  Divide:Boolean):TExpressionValue;
var
  I,J:Integer;
  Factor:Double;
begin
  Result:=Default(TExpressionValue);
  if Divide and (B.Kind<>evScalar) then
    raise EExpressionError.Create(
      'Expression evaluator: division requires a scalar denominator.');
  if Divide and (B.Scalar=0) then
    raise EExpressionError.Create('Expression evaluator: division by zero.');
  if (A.Kind=evScalar) and (B.Kind=evScalar) then
  begin
    Result.Kind:=evScalar; ConsumeOperations(1);
    if Divide then Result.Scalar:=A.Scalar/B.Scalar
    else Result.Scalar:=A.Scalar*B.Scalar;
  end
  else if (A.Kind=evScalar) and not Divide then
  begin
    Result:=CloneValue(B); Factor:=A.Scalar;
    CheckElements(ValueElementCount(Result));
    ConsumeOperations(ValueElementCount(Result));
    case Result.Kind of
      evVector: for I:=0 to High(Result.Vector) do
        Result.Vector[I]:=Factor*Result.Vector[I];
      evMatrix: for I:=0 to Result.Matrix.Rows-1 do
        for J:=0 to Result.Matrix.Cols-1 do
          Result.Matrix[I,J]:=Factor*Result.Matrix[I,J];
    end;
  end
  else if B.Kind=evScalar then
  begin
    Result:=CloneValue(A);
    if Divide then Factor:=1/B.Scalar else Factor:=B.Scalar;
    CheckElements(ValueElementCount(Result));
    ConsumeOperations(ValueElementCount(Result));
    case Result.Kind of
      evVector: for I:=0 to High(Result.Vector) do
        Result.Vector[I]:=Result.Vector[I]*Factor;
      evMatrix: for I:=0 to Result.Matrix.Rows-1 do
        for J:=0 to Result.Matrix.Cols-1 do
          Result.Matrix[I,J]:=Result.Matrix[I,J]*Factor;
    end;
  end
  else if (A.Kind=evVector) and (B.Kind=evVector) then
  begin
    if Length(A.Vector)<>Length(B.Vector) then
      raise EExpressionError.Create(
        'Expression evaluator: vector product shape mismatch.');
    Result.Kind:=evVector; SetLength(Result.Vector,Length(A.Vector));
    CheckElements(Length(Result.Vector)); ConsumeOperations(Length(Result.Vector));
    for I:=0 to High(Result.Vector) do
      Result.Vector[I]:=A.Vector[I]*B.Vector[I];
  end
  else if (A.Kind=evMatrix) and (B.Kind=evMatrix) then
  begin
    if (A.Matrix.Rows<>B.Matrix.Rows) or
       (A.Matrix.Cols<>B.Matrix.Cols) then
      raise EExpressionError.Create(
        'Expression evaluator: matrix product shape mismatch; use matmul for matrix multiplication.');
    Result.Kind:=evMatrix;
    Result.Matrix:=TDenseDoubleMatrix.Zeros(A.Matrix.Rows,A.Matrix.Cols);
    CheckElements(Int64(A.Matrix.Rows)*A.Matrix.Cols);
    ConsumeOperations(Int64(A.Matrix.Rows)*A.Matrix.Cols);
    for I:=0 to A.Matrix.Rows-1 do for J:=0 to A.Matrix.Cols-1 do
      Result.Matrix[I,J]:=A.Matrix[I,J]*B.Matrix[I,J];
  end
  else
    raise EExpressionError.Create(
      'Expression evaluator: unsupported product value kinds.');
  ValidateValue(Result,'Expression product');
end;

function TExpressionParser.NegateValue(
  const A:TExpressionValue):TExpressionValue;
var I,J:Integer;
begin
  Result:=CloneValue(A);
  CheckElements(ValueElementCount(Result));
  ConsumeOperations(ValueElementCount(Result));
  case Result.Kind of
    evScalar: Result.Scalar:=-Result.Scalar;
    evVector: for I:=0 to High(Result.Vector) do
      Result.Vector[I]:=-Result.Vector[I];
    evMatrix: for I:=0 to Result.Matrix.Rows-1 do
      for J:=0 to Result.Matrix.Cols-1 do
        Result.Matrix[I,J]:=-Result.Matrix[I,J];
  end;
end;

function TExpressionParser.PowerValues(const A,B:TExpressionValue):
  TExpressionValue;
begin
  if (A.Kind<>evScalar) or (B.Kind<>evScalar) then
    raise EExpressionError.Create(
      'Expression evaluator: exponentiation requires scalars.');
  ConsumeOperations(1);
  Result:=TExpressionValue.FromScalar(Power(A.Scalar,B.Scalar));
end;

function TExpressionParser.ApplyElementFunction(const Name:String;
  X:Double):Double;
begin
  if Name='sin' then Result:=Sin(X)
  else if Name='cos' then Result:=Cos(X)
  else if Name='tan' then Result:=Tan(X)
  else if Name='exp' then Result:=Exp(X)
  else if Name='ln' then
  begin
    if X<=0 then raise EExpressionError.Create(
      'Expression evaluator: ln domain requires a positive value.');
    Result:=Ln(X);
  end
  else if Name='sqrt' then
  begin
    if X<0 then raise EExpressionError.Create(
      'Expression evaluator: sqrt domain requires a non-negative value.');
    Result:=Sqrt(X);
  end
  else if Name='abs' then Result:=Abs(X)
  else raise EExpressionError.CreateFmt(
    'Expression evaluator: unknown function "%s".',[Name]);
  if not Finite(Result) then
    raise EExpressionError.Create(
      'Expression evaluator: function produced a non-finite result.');
end;

function TExpressionParser.ApplyFunction(const Name:String;
  const A:TExpressionValue; HasB:Boolean;
  const B:TExpressionValue):TExpressionValue;
var
  I,J,K:Integer;
  Sum:Double;
begin
  Result:=Default(TExpressionValue);
  if Name='dot' then
  begin
    if not HasB or (A.Kind<>evVector) or (B.Kind<>evVector) or
       (Length(A.Vector)<>Length(B.Vector)) then
      raise EExpressionError.Create(
        'Expression evaluator: dot requires two equal-length vectors.');
    ConsumeOperations(Length(A.Vector)); Sum:=0;
    for I:=0 to High(A.Vector) do Sum:=Sum+A.Vector[I]*B.Vector[I];
    Exit(TExpressionValue.FromScalar(Sum));
  end;
  if Name='matmul' then
  begin
    if not HasB or (A.Kind<>evMatrix) or (B.Kind<>evMatrix) or
       (A.Matrix.Cols<>B.Matrix.Rows) then
      raise EExpressionError.Create(
        'Expression evaluator: matmul requires compatible matrices.');
    CheckElements(Int64(A.Matrix.Rows)*B.Matrix.Cols);
    ConsumeOperations(Int64(A.Matrix.Rows)*A.Matrix.Cols*B.Matrix.Cols);
    Result.Kind:=evMatrix;
    Result.Matrix:=TDenseDoubleMatrix.Zeros(A.Matrix.Rows,B.Matrix.Cols);
    for I:=0 to A.Matrix.Rows-1 do for J:=0 to B.Matrix.Cols-1 do
      for K:=0 to A.Matrix.Cols-1 do
        Result.Matrix[I,J]:=Result.Matrix[I,J]+A.Matrix[I,K]*B.Matrix[K,J];
    ValidateValue(Result,'Expression matmul');
    Exit;
  end;
  if Name='transpose' then
  begin
    if HasB or (A.Kind<>evMatrix) then
      raise EExpressionError.Create(
        'Expression evaluator: transpose requires one matrix.');
    CheckElements(Int64(A.Matrix.Rows)*A.Matrix.Cols);
    ConsumeOperations(Int64(A.Matrix.Rows)*A.Matrix.Cols);
    Result.Kind:=evMatrix;
    Result.Matrix:=TDenseDoubleMatrix.Zeros(A.Matrix.Cols,A.Matrix.Rows);
    for I:=0 to A.Matrix.Rows-1 do for J:=0 to A.Matrix.Cols-1 do
      Result.Matrix[J,I]:=A.Matrix[I,J];
    Exit;
  end;
  if HasB then
    raise EExpressionError.CreateFmt(
      'Expression evaluator: function "%s" takes one argument.',[Name]);
  Result:=CloneValue(A);
  CheckElements(ValueElementCount(Result));
  ConsumeOperations(ValueElementCount(Result));
  case Result.Kind of
    evScalar: Result.Scalar:=ApplyElementFunction(Name,Result.Scalar);
    evVector: for I:=0 to High(Result.Vector) do
      Result.Vector[I]:=ApplyElementFunction(Name,Result.Vector[I]);
    evMatrix: for I:=0 to Result.Matrix.Rows-1 do
      for J:=0 to Result.Matrix.Cols-1 do
        Result.Matrix[I,J]:=ApplyElementFunction(Name,Result.Matrix[I,J]);
  end;
end;

class function TExpressionEvaluator.Evaluate(const Text:String;
  const Symbols:array of TExpressionSymbol;
  const Limits:TExpressionLimits):TExpressionValue;
var Parser:TExpressionParser;
begin
  Parser:=TExpressionParser.Create(Text,Symbols,Limits);
  try Result:=Parser.Run; finally Parser.Free; end;
end;

end.
