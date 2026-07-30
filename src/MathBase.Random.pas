unit MathBase.Random;

{-----------------------------------------------------------------------------
 MathBase.Random

 Explicit local random state for reproducible numerical workflows. The
 generator never reads or writes the RTL global RandSeed.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}{$Q-}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, Math;

type
  ERandomStateError = class(Exception);

  TRandomState = record
    Words: array[0..3] of QWord;
  end;

  { xoshiro256** with SplitMix64 seeding. This generator is intended for
    simulation and sampling, not cryptography. Value assignment copies the
    complete state and subsequent mutation is independent. }
  TLocalRandom = record
  private
    FState: TRandomState;
    class function RotateLeft(const Value: QWord; const Shift: Byte): QWord;
      static; inline;
    class function SplitMix64(var State: QWord): QWord; static; inline;
    procedure Jump;
  public
    class function Seeded(const Seed: QWord): TLocalRandom; static;
    procedure Reseed(const Seed: QWord);
    function NextUInt64: QWord;
    function NextUInt32: LongWord;
    function NextDouble: Double;
    function NextSingle: Single;
    function NextInteger(const UpperExclusive: SizeUInt): SizeUInt;
    function NextNormal: Double;
    function Split: TLocalRandom;
    function GetState: TRandomState;
    procedure SetState(const State: TRandomState);
  end;

implementation

class function TLocalRandom.RotateLeft(const Value: QWord;
  const Shift: Byte): QWord;
begin
  Result := (Value shl Shift) or (Value shr (64 - Shift));
end;

class function TLocalRandom.SplitMix64(var State: QWord): QWord;
var
  Z: QWord;
begin
  State := State + QWord($9E3779B97F4A7C15);
  Z := State;
  Z := (Z xor (Z shr 30)) * QWord($BF58476D1CE4E5B9);
  Z := (Z xor (Z shr 27)) * QWord($94D049BB133111EB);
  Result := Z xor (Z shr 31);
end;

class function TLocalRandom.Seeded(const Seed: QWord): TLocalRandom;
begin
  Result.Reseed(Seed);
end;

procedure TLocalRandom.Reseed(const Seed: QWord);
var
  Seeder: QWord;
  I: Integer;
begin
  Seeder := Seed;
  for I := 0 to 3 do
    FState.Words[I] := SplitMix64(Seeder);
end;

function TLocalRandom.NextUInt64: QWord;
var
  Temporary: QWord;
begin
  Result := RotateLeft(FState.Words[1] * 5, 7) * 9;
  Temporary := FState.Words[1] shl 17;

  FState.Words[2] := FState.Words[2] xor FState.Words[0];
  FState.Words[3] := FState.Words[3] xor FState.Words[1];
  FState.Words[1] := FState.Words[1] xor FState.Words[2];
  FState.Words[0] := FState.Words[0] xor FState.Words[3];
  FState.Words[2] := FState.Words[2] xor Temporary;
  FState.Words[3] := RotateLeft(FState.Words[3], 45);
end;

function TLocalRandom.NextUInt32: LongWord;
begin
  Result := LongWord(NextUInt64 shr 32);
end;

function TLocalRandom.NextDouble: Double;
begin
  { The high 53 bits map exactly to [0, 1) in binary64. }
  Result := (NextUInt64 shr 11) * (1.0 / 9007199254740992.0);
end;

function TLocalRandom.NextSingle: Single;
begin
  Result := Single((NextUInt64 shr 40) * (1.0 / 16777216.0));
end;

function TLocalRandom.NextInteger(const UpperExclusive: SizeUInt): SizeUInt;
var
  Candidate, Bound, Limit: QWord;
begin
  if UpperExclusive = 0 then
    raise ERandomStateError.Create(
      'TLocalRandom.NextInteger: UpperExclusive must be positive.');
  Bound := QWord(UpperExclusive);
  Limit := High(QWord) - (High(QWord) mod Bound);
  repeat
    Candidate := NextUInt64;
  until Candidate < Limit;
  Result := SizeUInt(Candidate mod Bound);
end;

function TLocalRandom.NextNormal: Double;
var
  U1, U2: Double;
begin
  repeat
    U1 := NextDouble;
  until U1 > 0.0;
  U2 := NextDouble;
  Result := Sqrt(-2.0 * Ln(U1)) * Cos(2.0 * Pi * U2);
end;

procedure TLocalRandom.Jump;
const
  JumpPolynomial: array[0..3] of QWord = (
    QWord($180EC6D33CFD0ABA), QWord($D5A61266F0C9392C),
    QWord($A9582618E03FC9AA), QWord($39ABDC4529B1661C));
var
  Accumulated: TRandomState;
  I, BitIndex: Integer;
begin
  FillChar(Accumulated, SizeOf(Accumulated), 0);
  for I := 0 to 3 do
    for BitIndex := 0 to 63 do
    begin
      if (JumpPolynomial[I] and (QWord(1) shl BitIndex)) <> 0 then
      begin
        Accumulated.Words[0] := Accumulated.Words[0] xor FState.Words[0];
        Accumulated.Words[1] := Accumulated.Words[1] xor FState.Words[1];
        Accumulated.Words[2] := Accumulated.Words[2] xor FState.Words[2];
        Accumulated.Words[3] := Accumulated.Words[3] xor FState.Words[3];
      end;
      NextUInt64;
    end;
  FState := Accumulated;
end;

function TLocalRandom.Split: TLocalRandom;
begin
  Result.FState := FState;
  Jump;
end;

function TLocalRandom.GetState: TRandomState;
begin
  Result := FState;
end;

procedure TLocalRandom.SetState(const State: TRandomState);
begin
  if (State.Words[0] = 0) and (State.Words[1] = 0) and
     (State.Words[2] = 0) and (State.Words[3] = 0) then
    raise ERandomStateError.Create(
      'TLocalRandom.SetState: the all-zero generator state is invalid.');
  FState := State;
end;

end.
