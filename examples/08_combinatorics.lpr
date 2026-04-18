program example08_combinatorics;

{-----------------------------------------------------------------------------
 Example 08 — CombinatoricsLib Walkthrough

 Written for someone new to combinatorics and number theory.
 Each section introduces one concept with a plain-English explanation
 and shows the corresponding function call.

 Compile:  fpc example08_combinatorics.lpr
 Run:      ./example08_combinatorics   (Linux/Mac)
           example08_combinatorics.exe (Windows)
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

uses
  SysUtils, Math,
  MathBase.SharedTypes,
  CombinatoricsLib.Combinatorics;

procedure Show(const Lbl: String; V: Int64); overload;
begin WriteLn(Format('  %-42s %d', [Lbl, V])); end;

procedure ShowF(const Lbl: String; V: Double); overload;
begin WriteLn(Format('  %-42s %.6f', [Lbl, V])); end;

procedure Sep; begin WriteLn(StringOfChar('-', 52)); end;

{ ============================================================
  SECTION 1 — Factorial & Permutations
  "How many ordered arrangements?"
============================================================ }
procedure DemoFactorialAndPermutation;
begin
  WriteLn;
  WriteLn('=== FACTORIAL & PERMUTATION ===');
  WriteLn('How many ways to arrange 5 books on a shelf?');
  Sep;
  Show('5! (all 5 books)',            TCombinatoricsKit.Factorial(5));
  Show('P(5,2) — first 2 positions',  TCombinatoricsKit.Permutation(5, 2));
  ShowF('ln(100!) — log-scale safe',  TCombinatoricsKit.LogFactorial(100));
end;

{ ============================================================
  SECTION 2 — Combinations
  "How many unordered selections?"
============================================================ }
procedure DemoCombination;
begin
  WriteLn;
  WriteLn('=== COMBINATIONS ===');
  WriteLn('How many 3-person committees from 10 people?');
  Sep;
  Show('C(10, 3)',                TCombinatoricsKit.Combination(10, 3));
  Show('C(20, 10)',               TCombinatoricsKit.Combination(20, 10));
  ShowF('ln C(100,50) — large',  TCombinatoricsKit.LogCombination(100, 50));
  WriteLn;
  WriteLn('  Multinomial: How many ways to arrange MISSISSIPPI?');
  WriteLn('  (11 letters: M×1, I×4, S×4, P×2)');
  Show('11!/(1!4!4!2!)',
    TCombinatoricsKit.Multinomial(11, TIntegerArray.Create(1,4,4,2)));
end;

{ ============================================================
  SECTION 3 — Special counting sequences
============================================================ }
procedure DemoSpecialSequences;
var I: Integer;
begin
  WriteLn;
  WriteLn('=== SPECIAL COUNTING SEQUENCES ===');
  Sep;

  WriteLn('  Catalan numbers C_0..C_8');
  WriteLn('  (counts balanced bracket sequences, binary trees, ...)');
  Write('  ');
  for I := 0 to 8 do Write(Format('%d ', [TCombinatoricsKit.CatalanNumber(I)]));
  WriteLn;

  WriteLn;
  WriteLn('  Bell numbers B_0..B_7');
  WriteLn('  (number of ways to partition a set)');
  Write('  ');
  for I := 0 to 7 do Write(Format('%d ', [TCombinatoricsKit.BellNumber(I)]));
  WriteLn;

  WriteLn;
  WriteLn('  Derangements D_0..D_7');
  WriteLn('  (permutations with NO fixed points — e.g. Secret Santa)');
  Write('  ');
  for I := 0 to 7 do Write(Format('%d ', [TCombinatoricsKit.DerangementCount(I)]));
  WriteLn;

  WriteLn;
  WriteLn('  Stirling 2nd kind S(5, k) for k=1..5');
  WriteLn('  (ways to split 5 elements into k non-empty groups)');
  Write('  ');
  for I := 1 to 5 do Write(Format('%d ', [TCombinatoricsKit.StirlingSecond(5, I)]));
  WriteLn;
end;

{ ============================================================
  SECTION 4 — Fibonacci & Lucas (fast matrix exponentiation)
============================================================ }
procedure DemoFibonacci;
var I: Integer;
begin
  WriteLn;
  WriteLn('=== FIBONACCI & LUCAS ===');
  Sep;
  Write('  F(0..12): ');
  for I := 0 to 12 do Write(Format('%d ', [TCombinatoricsKit.Fibonacci(I)]));
  WriteLn;
  Write('  L(0..10): ');
  for I := 0 to 10 do Write(Format('%d ', [TCombinatoricsKit.Lucas(I)]));
  WriteLn;
  Show('F(50) — fast doubling', TCombinatoricsKit.Fibonacci(50));
end;

{ ============================================================
  SECTION 5 — Pascal's Triangle
============================================================ }
procedure DemoPascalTriangle;
var
  T: TPascalTriangle;
  Row: TPascalRow;
  I, J: Integer;
begin
  WriteLn;
  WriteLn('=== PASCAL''S TRIANGLE (rows 0..6) ===');
  Sep;
  T := TCombinatoricsKit.PascalTriangle(6);
  for I := 0 to 6 do
  begin
    Write(StringOfChar(' ', (6-I)*2));
    for J := 0 to I do Write(Format('%4d', [T[I][J]]));
    WriteLn;
  end;
  WriteLn;
  WriteLn('  Row 8 (C(8,k) for k=0..8):');
  Row := TCombinatoricsKit.PascalRow(8);
  Write('  ');
  for I := 0 to 8 do Write(Format('%d ', [Row[I]]));
  WriteLn;
end;

{ ============================================================
  SECTION 6 — Number Theory
============================================================ }
procedure DemoNumberTheory;
var
  X, Y, G: Int64;
  Factors: TPrimeFactorArray;
  Primes: array of Int64;
  I: Integer;
  F: TPrimeFactor;
begin
  WriteLn;
  WriteLn('=== NUMBER THEORY ===');
  Sep;

  Show('GCD(252, 105)',     TCombinatoricsKit.GCD(252, 105));
  Show('LCM(4, 6)',         TCombinatoricsKit.LCM(4, 6));

  G := TCombinatoricsKit.ExtendedGCD(35, 15, X, Y);
  WriteLn(Format('  ExtendedGCD(35,15): GCD=%d, X=%d, Y=%d  (35*%d + 15*%d = %d)',
    [G, X, Y, X, Y, 35*X + 15*Y]));

  WriteLn;
  Show('2^10 mod 1000  (ModPow)', TCombinatoricsKit.ModPow(2, 10, 1000));
  Show('ModInverse(3, 11)',       TCombinatoricsKit.ModInverse(3, 11));

  WriteLn;
  WriteLn('  Prime factorisation of 360 = 2^3 * 3^2 * 5^1:');
  Factors := TCombinatoricsKit.PrimeFactors(360);
  for F in Factors do
    WriteLn(Format('    %d ^ %d', [F.Prime, F.Exponent]));

  WriteLn;
  WriteLn('  Primes up to 50 (Sieve of Eratosthenes):');
  Primes := TCombinatoricsKit.Sieve(50);
  Write('  ');
  for I := 0 to High(Primes) do Write(Format('%d ', [Primes[I]]));
  WriteLn;

  WriteLn;
  WriteLn('  IsPrime checks:');
  WriteLn(Format('  IsPrime(17)         = %s', [BoolToStr(TCombinatoricsKit.IsPrime(17), True)]));
  WriteLn(Format('  IsPrime(999999937)  = %s', [BoolToStr(TCombinatoricsKit.IsPrime(999999937), True)]));
  WriteLn(Format('  IsPrime(100)        = %s', [BoolToStr(TCombinatoricsKit.IsPrime(100), True)]));
  Show('NextPrime(100)', TCombinatoricsKit.NextPrime(100));

  WriteLn;
  Show('EulerTotient(12) — φ(12)=4', TCombinatoricsKit.EulerTotient(12));
  WriteLn('  (integers 1..12 coprime to 12: 1, 5, 7, 11)');
end;

{ ============================================================
  SECTION 7 — Generating Permutations
============================================================ }
procedure DemoPermutations;
var
  Perms: TPermutationList;
  Perm: TIntegerArray;
  I, J, Count: Integer;
begin
  WriteLn;
  WriteLn('=== PERMUTATION GENERATION ===');
  Sep;

  { All permutations of [1,2,3] }
  Perms := TCombinatoricsKit.Permutations(TIntegerArray.Create(1,2,3));
  WriteLn('  All permutations of [1,2,3]:');
  for I := 0 to High(Perms) do
  begin
    Write('  ');
    for J := 0 to High(Perms[I]) do Write(Format('%d ', [Perms[I][J]]));
    WriteLn;
  end;

  WriteLn;
  WriteLn('  Stepping through permutations of [1,2,3,4] one at a time:');
  Perm  := TIntegerArray.Create(1, 2, 3, 4);
  Count := 1;
  while TCombinatoricsKit.NextPermutation(Perm) do Inc(Count);
  WriteLn(Format('  Total permutations visited: %d  (= 4! = 24)', [Count]));
end;

{ ============================================================
  SECTION 8 — Generating Combinations
============================================================ }
procedure DemoCombinations;
var
  Combos: TCombinationList;
  I, J: Integer;
begin
  WriteLn;
  WriteLn('=== COMBINATION GENERATION ===');
  Sep;
  WriteLn('  All 2-subsets of {0,1,2,3} — C(4,2) = 6 combinations:');
  Combos := TCombinatoricsKit.Combinations(4, 2);
  for I := 0 to High(Combos) do
  begin
    Write('  {');
    for J := 0 to High(Combos[I]) do
    begin
      if J > 0 then Write(',');
      Write(Combos[I][J]);
    end;
    WriteLn('}');
  end;
end;

{ ============================================================
  SECTION 9 — Power Set
============================================================ }
procedure DemoPowerSet;
var
  Subsets: TSubsetList;
  I, J: Integer;
begin
  WriteLn;
  WriteLn('=== POWER SET of {0,1,2} ===');
  Sep;
  WriteLn('  All 2^3 = 8 subsets:');
  Subsets := TCombinatoricsKit.PowerSet(3);
  for I := 0 to High(Subsets) do
  begin
    if Length(Subsets[I]) = 0 then Write('  {}')
    else
    begin
      Write('  {');
      for J := 0 to High(Subsets[I]) do
      begin
        if J > 0 then Write(',');
        Write(Subsets[I][J]);
      end;
      Write('}');
    end;
    WriteLn;
  end;
end;

{ ============================================================
  MAIN
============================================================ }
begin
  WriteLn('mathlib-fp — CombinatoricsLib Example');
  WriteLn('=====================================');

  DemoFactorialAndPermutation;
  DemoCombination;
  DemoSpecialSequences;
  DemoFibonacci;
  DemoPascalTriangle;
  DemoNumberTheory;
  DemoPermutations;
  DemoCombinations;
  DemoPowerSet;

  WriteLn;
  WriteLn('Done.');
end.
