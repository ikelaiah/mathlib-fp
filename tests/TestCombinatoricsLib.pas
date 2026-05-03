unit TestCombinatoricsLib;

{-----------------------------------------------------------------------------
 TestCombinatoricsLib

 Comprehensive tests for CombinatoricsLib.Combinatorics.
 All expected values are verified against Wolfram Alpha / OEIS.

 Coverage
   Factorial / LogFactorial
   Permutation / Combination / LogCombination / Multinomial
   CatalanNumber / BellNumber / StirlingFirst / StirlingSecond
   DerangementCount
   Fibonacci / Lucas
   PascalRow / PascalTriangle
   GCD / LCM / ExtendedGCD
   ModPow / ModInverse
   IsPrime / NextPrime / PrimeFactors / Sieve / EulerTotient
   NextPermutation / Permutations / Combinations / PowerSet
   Error handling — ECombinatoricsError
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math,
  fpcunit, testutils, testregistry,
  MathBase.SharedTypes,
  CombinatoricsLib.Combinatorics;

type
  TTestCombinatoricsLib = class(TTestCase)
  private
    const EPS = 1E-9;

    procedure AssertNearD(const Expected, Actual, Tol: Double; const Msg: String = '');

    { Wrappers for ECombinatoricsError exception tests }
    procedure DoFactorial_Negative;
    procedure DoFactorial_TooLarge;
    procedure DoPermutation_KgtN;
    procedure DoCombination_KgtN;
    procedure DoMultinomial_WrongSum;
    procedure DoCatalanNumber_TooLarge;
    procedure DoBellNumber_TooLarge;
    procedure DoModPow_ZeroM;
    procedure DoModInverse_NoInverse;
    procedure DoSieve_TooSmall;
    procedure DoPowerSet_TooLarge;
    procedure DoFibonacci_Negative;
    procedure DoPrimeFactors_One;

  published
    { Factorial }
    procedure Test01_Factorial_Zero;
    procedure Test02_Factorial_Small;
    procedure Test03_Factorial_Max;
    procedure Test04_Factorial_Negative_Raises;
    procedure Test05_Factorial_Overflow_Raises;

    { LogFactorial }
    procedure Test06_LogFactorial_Zero;
    procedure Test07_LogFactorial_Small;
    procedure Test08_LogFactorial_Large;

    { Permutation }
    procedure Test09_Permutation_Basic;
    procedure Test10_Permutation_AllItems;
    procedure Test11_Permutation_Zero;
    procedure Test12_Permutation_KgtN_Raises;

    { Combination }
    procedure Test13_Combination_Basic;
    procedure Test14_Combination_Symmetric;
    procedure Test15_Combination_ZeroK;
    procedure Test16_Combination_KgtN_Raises;
    procedure Test17_LogCombination_Large;

    { Multinomial }
    procedure Test18_Multinomial_Basic;
    procedure Test19_Multinomial_WrongSum_Raises;

    { CatalanNumber }
    procedure Test20_CatalanNumber_Sequence;
    procedure Test21_CatalanNumber_TooLarge_Raises;

    { BellNumber }
    procedure Test22_BellNumber_Sequence;
    procedure Test23_BellNumber_TooLarge_Raises;

    { StirlingFirst / StirlingSecond }
    procedure Test24_StirlingFirst_KnownValues;
    procedure Test25_StirlingFirst_Boundary;
    procedure Test26_StirlingSecond_KnownValues;
    procedure Test27_StirlingSecond_Boundary;

    { DerangementCount }
    procedure Test28_Derangement_Sequence;

    { Fibonacci }
    procedure Test29_Fibonacci_Sequence;
    procedure Test30_Fibonacci_Large;
    procedure Test31_Fibonacci_Negative_Raises;

    { Lucas }
    procedure Test32_Lucas_Sequence;

    { PascalRow / PascalTriangle }
    procedure Test33_PascalRow_Row5;
    procedure Test34_PascalRow_Sum;
    procedure Test35_PascalTriangle_Shape;

    { GCD / LCM }
    procedure Test36_GCD_Basic;
    procedure Test37_GCD_Coprime;
    procedure Test38_GCD_Zero;
    procedure Test39_LCM_Basic;
    procedure Test40_LCM_Zero;

    { ExtendedGCD }
    procedure Test41_ExtendedGCD_Bezout;

    { ModPow }
    procedure Test42_ModPow_Basic;
    procedure Test43_ModPow_ZeroExp;
    procedure Test44_ModPow_ZeroM_Raises;

    { ModInverse }
    procedure Test45_ModInverse_Basic;
    procedure Test46_ModInverse_NoInverse_Raises;

    { IsPrime / NextPrime }
    procedure Test47_IsPrime_SmallPrimes;
    procedure Test48_IsPrime_Composites;
    procedure Test49_IsPrime_EdgeCases;
    procedure Test50_IsPrime_LargePrime;
    procedure Test51_NextPrime_Basic;

    { PrimeFactors }
    procedure Test52_PrimeFactors_360;
    procedure Test53_PrimeFactors_Prime;
    procedure Test54_PrimeFactors_One_Raises;

    { Sieve }
    procedure Test55_Sieve_UpTo30;
    procedure Test56_Sieve_Count100;
    procedure Test57_Sieve_TooSmall_Raises;

    { EulerTotient }
    procedure Test58_EulerTotient_Primes;
    procedure Test59_EulerTotient_Composite;

    { NextPermutation }
    procedure Test60_NextPermutation_Step;
    procedure Test61_NextPermutation_LastResets;
    procedure Test62_NextPermutation_FullCycle;

    { Permutations }
    procedure Test63_Permutations_Count;
    procedure Test64_Permutations_First;
    procedure Test65_Permutations_Last;

    { Combinations }
    procedure Test66_Combinations_Count;
    procedure Test67_Combinations_C42;
    procedure Test68_Combinations_ZeroK;

    { PowerSet }
    procedure Test69_PowerSet_N3;
    procedure Test70_PowerSet_EmptySet;
    procedure Test71_PowerSet_TooLarge_Raises;

  end;

implementation

procedure TTestCombinatoricsLib.AssertNearD(const Expected, Actual, Tol: Double; const Msg: String);
begin
  if Abs(Expected - Actual) > Tol then
    Fail(Format('%s  expected %.12f  got %.12f  (tol %.2e)',
      [Msg, Expected, Actual, Tol]));
end;

{ --- exception wrappers --- }
procedure TTestCombinatoricsLib.DoFactorial_Negative; begin TCombinatoricsKit.Factorial(-1); end;
procedure TTestCombinatoricsLib.DoFactorial_TooLarge; begin TCombinatoricsKit.Factorial(21); end;
procedure TTestCombinatoricsLib.DoPermutation_KgtN; begin TCombinatoricsKit.Permutation(3, 5); end;
procedure TTestCombinatoricsLib.DoCombination_KgtN; begin TCombinatoricsKit.Combination(3, 5); end;
procedure TTestCombinatoricsLib.DoMultinomial_WrongSum;
begin
  TCombinatoricsKit.Multinomial(10, TIntegerArray.Create(2,3));
end;
procedure TTestCombinatoricsLib.DoCatalanNumber_TooLarge;begin TCombinatoricsKit.CatalanNumber(31); end;
procedure TTestCombinatoricsLib.DoBellNumber_TooLarge; begin TCombinatoricsKit.BellNumber(19); end;
procedure TTestCombinatoricsLib.DoModPow_ZeroM; begin TCombinatoricsKit.ModPow(2, 10, 0); end;
procedure TTestCombinatoricsLib.DoModInverse_NoInverse; begin TCombinatoricsKit.ModInverse(4, 6); end;
procedure TTestCombinatoricsLib.DoSieve_TooSmall; begin TCombinatoricsKit.Sieve(1); end;
procedure TTestCombinatoricsLib.DoPowerSet_TooLarge; begin TCombinatoricsKit.PowerSet(25); end;
procedure TTestCombinatoricsLib.DoFibonacci_Negative; begin TCombinatoricsKit.Fibonacci(-1); end;
procedure TTestCombinatoricsLib.DoPrimeFactors_One; begin TCombinatoricsKit.PrimeFactors(1); end;

{ ===========================================================================
  FACTORIAL
=========================================================================== }

procedure TTestCombinatoricsLib.Test01_Factorial_Zero;
begin
  AssertEquals('0! = 1', Int64(1), TCombinatoricsKit.Factorial(0));
end;

procedure TTestCombinatoricsLib.Test02_Factorial_Small;
begin
  AssertEquals('5! = 120',  Int64(120),   TCombinatoricsKit.Factorial(5));
  AssertEquals('10! = 3628800', Int64(3628800), TCombinatoricsKit.Factorial(10));
end;

procedure TTestCombinatoricsLib.Test03_Factorial_Max;
begin
  { 20! = 2432902008176640000 }
  AssertEquals('20!', Int64(2432902008176640000), TCombinatoricsKit.Factorial(20));
end;

procedure TTestCombinatoricsLib.Test04_Factorial_Negative_Raises;
begin
  AssertException('Factorial(-1)', ECombinatoricsError, @DoFactorial_Negative);
end;

procedure TTestCombinatoricsLib.Test05_Factorial_Overflow_Raises;
begin
  AssertException('Factorial(21)', ECombinatoricsError, @DoFactorial_TooLarge);
end;

{ ===========================================================================
  LOG FACTORIAL
=========================================================================== }

procedure TTestCombinatoricsLib.Test06_LogFactorial_Zero;
begin
  AssertNearD(0, TCombinatoricsKit.LogFactorial(0), EPS, 'LogFact(0)=0');
end;

procedure TTestCombinatoricsLib.Test07_LogFactorial_Small;
begin
  { ln(5!) = ln(120) ≈ 4.787492 }
  AssertNearD(Ln(120), TCombinatoricsKit.LogFactorial(5), 1E-9, 'LogFact(5)');
end;

procedure TTestCombinatoricsLib.Test08_LogFactorial_Large;
begin
  { ln(100!) ≈ 363.739375555563 — Stirling approximation, tol 1e-4 }
  AssertNearD(363.739375555563, TCombinatoricsKit.LogFactorial(100), 1E-4,
    'LogFact(100)');
end;

{ ===========================================================================
  PERMUTATION
=========================================================================== }

procedure TTestCombinatoricsLib.Test09_Permutation_Basic;
begin
  { P(5,2) = 20 }
  AssertEquals('P(5,2)', Int64(20), TCombinatoricsKit.Permutation(5, 2));
end;

procedure TTestCombinatoricsLib.Test10_Permutation_AllItems;
begin
  { P(5,5) = 5! = 120 }
  AssertEquals('P(5,5)', Int64(120), TCombinatoricsKit.Permutation(5, 5));
end;

procedure TTestCombinatoricsLib.Test11_Permutation_Zero;
begin
  { P(n,0) = 1 for any n }
  AssertEquals('P(7,0)', Int64(1), TCombinatoricsKit.Permutation(7, 0));
end;

procedure TTestCombinatoricsLib.Test12_Permutation_KgtN_Raises;
begin
  AssertException('P(3,5)', ECombinatoricsError, @DoPermutation_KgtN);
end;

{ ===========================================================================
  COMBINATION
=========================================================================== }

procedure TTestCombinatoricsLib.Test13_Combination_Basic;
begin
  AssertEquals('C(5,2)=10', Int64(10), TCombinatoricsKit.Combination(5, 2));
  AssertEquals('C(10,3)=120', Int64(120), TCombinatoricsKit.Combination(10, 3));
end;

procedure TTestCombinatoricsLib.Test14_Combination_Symmetric;
begin
  { C(n,k) = C(n, n-k) }
  AssertEquals('C(10,3)=C(10,7)', TCombinatoricsKit.Combination(10,3),
               TCombinatoricsKit.Combination(10,7));
end;

procedure TTestCombinatoricsLib.Test15_Combination_ZeroK;
begin
  AssertEquals('C(n,0)=1', Int64(1), TCombinatoricsKit.Combination(100, 0));
end;

procedure TTestCombinatoricsLib.Test16_Combination_KgtN_Raises;
begin
  AssertException('C(3,5)', ECombinatoricsError, @DoCombination_KgtN);
end;

procedure TTestCombinatoricsLib.Test17_LogCombination_Large;
begin
  { ln C(100,50) ≈ 66.7838 }
  AssertNearD(66.7838, TCombinatoricsKit.LogCombination(100, 50), 1E-3,
    'LogC(100,50)');
end;

{ ===========================================================================
  MULTINOMIAL
=========================================================================== }

procedure TTestCombinatoricsLib.Test18_Multinomial_Basic;
begin
  { 6!/(1!2!3!) = 720/12 = 60 }
  AssertEquals('Multinomial(6,[1,2,3])', Int64(60),
    TCombinatoricsKit.Multinomial(6, TIntegerArray.Create(1,2,3)));
  { "MISSISSIPPI": 11!/(1!4!4!2!) = 34650 }
  AssertEquals('MISSISSIPPI', Int64(34650),
    TCombinatoricsKit.Multinomial(11, TIntegerArray.Create(1,4,4,2)));
end;

procedure TTestCombinatoricsLib.Test19_Multinomial_WrongSum_Raises;
begin
  AssertException('Multinomial bad sum', ECombinatoricsError, @DoMultinomial_WrongSum);
end;

{ ===========================================================================
  CATALAN / BELL / STIRLING / DERANGEMENT
=========================================================================== }

procedure TTestCombinatoricsLib.Test20_CatalanNumber_Sequence;
const
  { C_0..C_8 from OEIS A000108 }
  Expected: array[0..8] of Int64 = (1,1,2,5,14,42,132,429,1430);
var I: Integer;
begin
  for I := 0 to 8 do
    AssertEquals(Format('Catalan(%d)', [I]), Expected[I],
      TCombinatoricsKit.CatalanNumber(I));
end;

procedure TTestCombinatoricsLib.Test21_CatalanNumber_TooLarge_Raises;
begin
  AssertException('Catalan>30', ECombinatoricsError, @DoCatalanNumber_TooLarge);
end;

procedure TTestCombinatoricsLib.Test22_BellNumber_Sequence;
const
  { B_0..B_8 from OEIS A000110 }
  Expected: array[0..8] of Int64 = (1,1,2,5,15,52,203,877,4140);
var I: Integer;
begin
  for I := 0 to 8 do
    AssertEquals(Format('Bell(%d)', [I]), Expected[I],
      TCombinatoricsKit.BellNumber(I));
end;

procedure TTestCombinatoricsLib.Test23_BellNumber_TooLarge_Raises;
begin
  AssertException('Bell>18', ECombinatoricsError, @DoBellNumber_TooLarge);
end;

procedure TTestCombinatoricsLib.Test24_StirlingFirst_KnownValues;
begin
  { s(4,2) = 11  (OEIS A132393) }
  AssertEquals('s(4,2)', Int64(11), TCombinatoricsKit.StirlingFirst(4, 2));
  { s(5,3) = 35 }
  AssertEquals('s(5,3)', Int64(35), TCombinatoricsKit.StirlingFirst(5, 3));
end;

procedure TTestCombinatoricsLib.Test25_StirlingFirst_Boundary;
begin
  AssertEquals('s(n,n)=1', Int64(1), TCombinatoricsKit.StirlingFirst(5, 5));
  AssertEquals('s(n,0)=0', Int64(0), TCombinatoricsKit.StirlingFirst(5, 0));
  AssertEquals('s(k>n)=0', Int64(0), TCombinatoricsKit.StirlingFirst(3, 5));
end;

procedure TTestCombinatoricsLib.Test26_StirlingSecond_KnownValues;
begin
  { S(4,2) = 7  (OEIS A008299) }
  AssertEquals('S(4,2)', Int64(7), TCombinatoricsKit.StirlingSecond(4, 2));
  { S(5,3) = 25 }
  AssertEquals('S(5,3)', Int64(25), TCombinatoricsKit.StirlingSecond(5, 3));
end;

procedure TTestCombinatoricsLib.Test27_StirlingSecond_Boundary;
begin
  AssertEquals('S(n,n)=1', Int64(1), TCombinatoricsKit.StirlingSecond(5, 5));
  AssertEquals('S(n,1)=1', Int64(1), TCombinatoricsKit.StirlingSecond(5, 1));
  AssertEquals('S(k>n)=0', Int64(0), TCombinatoricsKit.StirlingSecond(3, 5));
end;

procedure TTestCombinatoricsLib.Test28_Derangement_Sequence;
const
  { D_0..D_7 from OEIS A000166 }
  Expected: array[0..7] of Int64 = (1,0,1,2,9,44,265,1854);
var I: Integer;
begin
  for I := 0 to 7 do
    AssertEquals(Format('D(%d)', [I]), Expected[I],
      TCombinatoricsKit.DerangementCount(I));
end;

{ ===========================================================================
  FIBONACCI / LUCAS
=========================================================================== }

procedure TTestCombinatoricsLib.Test29_Fibonacci_Sequence;
const
  Expected: array[0..9] of Int64 = (0,1,1,2,3,5,8,13,21,34);
var I: Integer;
begin
  for I := 0 to 9 do
    AssertEquals(Format('F(%d)', [I]), Expected[I],
      TCombinatoricsKit.Fibonacci(I));
end;

procedure TTestCombinatoricsLib.Test30_Fibonacci_Large;
begin
  { F(50) = 12586269025 }
  AssertEquals('F(50)', Int64(12586269025), TCombinatoricsKit.Fibonacci(50));
end;

procedure TTestCombinatoricsLib.Test31_Fibonacci_Negative_Raises;
begin
  AssertException('Fib(-1)', ECombinatoricsError, @DoFibonacci_Negative);
end;

procedure TTestCombinatoricsLib.Test32_Lucas_Sequence;
const
  Expected: array[0..7] of Int64 = (2,1,3,4,7,11,18,29);
var I: Integer;
begin
  for I := 0 to 7 do
    AssertEquals(Format('L(%d)', [I]), Expected[I],
      TCombinatoricsKit.Lucas(I));
end;

{ ===========================================================================
  PASCAL'S TRIANGLE
=========================================================================== }

procedure TTestCombinatoricsLib.Test33_PascalRow_Row5;
const
  Expected: array[0..5] of Int64 = (1,5,10,10,5,1);
var
  Row: TPascalRow;
  I: Integer;
begin
  Row := TCombinatoricsKit.PascalRow(5);
  AssertEquals('Row5 length', 6, Length(Row));
  for I := 0 to 5 do
    AssertEquals(Format('Row5[%d]', [I]), Expected[I], Row[I]);
end;

procedure TTestCombinatoricsLib.Test34_PascalRow_Sum;
{ Sum of row N = 2^N }
var
  Row: TPascalRow;
  Sum: Int64;
  I: Integer;
begin
  Row := TCombinatoricsKit.PascalRow(8);
  Sum := 0;
  for I := 0 to High(Row) do Sum := Sum + Row[I];
  AssertEquals('Sum row 8 = 256', Int64(256), Sum);
end;

procedure TTestCombinatoricsLib.Test35_PascalTriangle_Shape;
var
  T: TPascalTriangle;
  I: Integer;
begin
  T := TCombinatoricsKit.PascalTriangle(5);
  AssertEquals('Triangle rows', 6, Length(T));
  for I := 0 to 5 do
    AssertEquals(Format('Row %d length', [I]), I+1, Length(T[I]));
  AssertEquals('T[4][2] = C(4,2) = 6', Int64(6), T[4][2]);
end;

{ ===========================================================================
  GCD / LCM / EXTENDED GCD
=========================================================================== }

procedure TTestCombinatoricsLib.Test36_GCD_Basic;
begin
  AssertEquals('GCD(12,8)=4',   Int64(4), TCombinatoricsKit.GCD(12, 8));
  AssertEquals('GCD(100,75)=25',Int64(25), TCombinatoricsKit.GCD(100, 75));
end;

procedure TTestCombinatoricsLib.Test37_GCD_Coprime;
begin
  AssertEquals('GCD(13,7)=1', Int64(1), TCombinatoricsKit.GCD(13, 7));
end;

procedure TTestCombinatoricsLib.Test38_GCD_Zero;
begin
  AssertEquals('GCD(0,5)=5', Int64(5), TCombinatoricsKit.GCD(0, 5));
  AssertEquals('GCD(5,0)=5', Int64(5), TCombinatoricsKit.GCD(5, 0));
end;

procedure TTestCombinatoricsLib.Test39_LCM_Basic;
begin
  AssertEquals('LCM(4,6)=12',  Int64(12), TCombinatoricsKit.LCM(4, 6));
  AssertEquals('LCM(3,7)=21',  Int64(21), TCombinatoricsKit.LCM(3, 7));
end;

procedure TTestCombinatoricsLib.Test40_LCM_Zero;
begin
  AssertEquals('LCM(0,5)=0', Int64(0), TCombinatoricsKit.LCM(0, 5));
end;

procedure TTestCombinatoricsLib.Test41_ExtendedGCD_Bezout;
var X, Y, G: Int64;
begin
  G := TCombinatoricsKit.ExtendedGCD(35, 15, X, Y);
  AssertEquals('ExtGCD result', Int64(5), G);
  { Verify Bezout: 35*X + 15*Y = 5 }
  AssertEquals('Bezout identity', Int64(5), 35*X + 15*Y);
end;

{ ===========================================================================
  MOD ARITHMETIC
=========================================================================== }

procedure TTestCombinatoricsLib.Test42_ModPow_Basic;
begin
  { 2^10 mod 1000 = 1024 mod 1000 = 24 }
  AssertEquals('2^10 mod 1000', Int64(24), TCombinatoricsKit.ModPow(2, 10, 1000));
  { 3^7 mod 13 = 2187 mod 13 = 3 }
  AssertEquals('3^7 mod 13', Int64(3), TCombinatoricsKit.ModPow(3, 7, 13));
end;

procedure TTestCombinatoricsLib.Test43_ModPow_ZeroExp;
begin
  AssertEquals('a^0 mod m = 1', Int64(1), TCombinatoricsKit.ModPow(99, 0, 7));
end;

procedure TTestCombinatoricsLib.Test44_ModPow_ZeroM_Raises;
begin
  AssertException('ModPow M=0', ECombinatoricsError, @DoModPow_ZeroM);
end;

procedure TTestCombinatoricsLib.Test45_ModInverse_Basic;
begin
  { 3 * 4 = 12 ≡ 1 (mod 11) }
  AssertEquals('ModInv(3,11)=4', Int64(4), TCombinatoricsKit.ModInverse(3, 11));
end;

procedure TTestCombinatoricsLib.Test46_ModInverse_NoInverse_Raises;
begin
  { GCD(4,6)=2 ≠ 1 }
  AssertException('ModInv no inverse', ECombinatoricsError, @DoModInverse_NoInverse);
end;

{ ===========================================================================
  PRIMALITY / SIEVE
=========================================================================== }

procedure TTestCombinatoricsLib.Test47_IsPrime_SmallPrimes;
const
  Primes: array[0..9] of Int64 = (2,3,5,7,11,13,17,19,23,29);
var P: Int64;
begin
  for P in Primes do
    AssertTrue(Format('IsPrime(%d)', [P]), TCombinatoricsKit.IsPrime(P));
end;

procedure TTestCombinatoricsLib.Test48_IsPrime_Composites;
const
  Composites: array[0..5] of Int64 = (4,6,8,9,15,100);
var C: Int64;
begin
  for C in Composites do
    AssertFalse(Format('not IsPrime(%d)', [C]), TCombinatoricsKit.IsPrime(C));
end;

procedure TTestCombinatoricsLib.Test49_IsPrime_EdgeCases;
begin
  AssertFalse('IsPrime(0)=F', TCombinatoricsKit.IsPrime(0));
  AssertFalse('IsPrime(1)=F', TCombinatoricsKit.IsPrime(1));
  AssertTrue( 'IsPrime(2)=T', TCombinatoricsKit.IsPrime(2));
end;

procedure TTestCombinatoricsLib.Test50_IsPrime_LargePrime;
begin
  { 999999937 is prime (OEIS) }
  AssertTrue('IsPrime(999999937)', TCombinatoricsKit.IsPrime(999999937));
  { 999999938 = 2 * 499999969 — composite }
  AssertFalse('IsPrime(999999938)', TCombinatoricsKit.IsPrime(999999938));
end;

procedure TTestCombinatoricsLib.Test51_NextPrime_Basic;
begin
  AssertEquals('NextPrime(1)=2',  Int64(2),  TCombinatoricsKit.NextPrime(1));
  AssertEquals('NextPrime(14)=17',Int64(17), TCombinatoricsKit.NextPrime(14));
  AssertEquals('NextPrime(17)=17',Int64(17), TCombinatoricsKit.NextPrime(17));
end;

procedure TTestCombinatoricsLib.Test52_PrimeFactors_360;
var F: TPrimeFactorArray;
begin
  { 360 = 2^3 * 3^2 * 5^1 }
  F := TCombinatoricsKit.PrimeFactors(360);
  AssertEquals('360: 3 factors', 3, Length(F));
  AssertEquals('factor[0].prime',    Int64(2), F[0].Prime);
  AssertEquals('factor[0].exponent', 3,        F[0].Exponent);
  AssertEquals('factor[1].prime',    Int64(3), F[1].Prime);
  AssertEquals('factor[1].exponent', 2,        F[1].Exponent);
  AssertEquals('factor[2].prime',    Int64(5), F[2].Prime);
  AssertEquals('factor[2].exponent', 1,        F[2].Exponent);
end;

procedure TTestCombinatoricsLib.Test53_PrimeFactors_Prime;
var F: TPrimeFactorArray;
begin
  F := TCombinatoricsKit.PrimeFactors(17);
  AssertEquals('17 is prime: 1 factor', 1, Length(F));
  AssertEquals('factor prime', Int64(17), F[0].Prime);
  AssertEquals('exponent',     1,         F[0].Exponent);
end;

procedure TTestCombinatoricsLib.Test54_PrimeFactors_One_Raises;
begin
  AssertException('PrimeFactors(1)', ECombinatoricsError, @DoPrimeFactors_One);
end;

procedure TTestCombinatoricsLib.Test55_Sieve_UpTo30;
const
  Expected: array[0..9] of Int64 = (2,3,5,7,11,13,17,19,23,29);
var
  Primes: array of Int64;
  I: Integer;
begin
  Primes := TCombinatoricsKit.Sieve(30);
  AssertEquals('Sieve(30) count', 10, Length(Primes));
  for I := 0 to 9 do
    AssertEquals(Format('Sieve[%d]', [I]), Expected[I], Primes[I]);
end;

procedure TTestCombinatoricsLib.Test56_Sieve_Count100;
begin
  { There are 25 primes <= 100 }
  AssertEquals('25 primes <= 100', 25, Length(TCombinatoricsKit.Sieve(100)));
end;

procedure TTestCombinatoricsLib.Test57_Sieve_TooSmall_Raises;
begin
  AssertException('Sieve(1)', ECombinatoricsError, @DoSieve_TooSmall);
end;

{ ===========================================================================
  EULER TOTIENT
=========================================================================== }

procedure TTestCombinatoricsLib.Test58_EulerTotient_Primes;
begin
  { φ(p) = p-1 for prime p }
  AssertEquals('φ(7)=6',  Int64(6),  TCombinatoricsKit.EulerTotient(7));
  AssertEquals('φ(13)=12',Int64(12), TCombinatoricsKit.EulerTotient(13));
end;

procedure TTestCombinatoricsLib.Test59_EulerTotient_Composite;
begin
  { φ(12) = 4 (coprime: 1,5,7,11) }
  AssertEquals('φ(12)=4',  Int64(4),  TCombinatoricsKit.EulerTotient(12));
  { φ(36) = 12 }
  AssertEquals('φ(36)=12', Int64(12), TCombinatoricsKit.EulerTotient(36));
end;

{ ===========================================================================
  PERMUTATION GENERATION
=========================================================================== }

procedure TTestCombinatoricsLib.Test60_NextPermutation_Step;
var P: TIntegerArray;
begin
  P := TIntegerArray.Create(1, 2, 3);
  AssertTrue('next exists', TCombinatoricsKit.NextPermutation(P));
  AssertEquals('P[0]=1', 1, P[0]);
  AssertEquals('P[1]=3', 3, P[1]);
  AssertEquals('P[2]=2', 2, P[2]);
end;

procedure TTestCombinatoricsLib.Test61_NextPermutation_LastResets;
var P: TIntegerArray;
begin
  P := TIntegerArray.Create(3, 2, 1);  { last permutation }
  AssertFalse('no next', TCombinatoricsKit.NextPermutation(P));
  { Should be reset to [1,2,3] }
  AssertEquals('reset[0]', 1, P[0]);
  AssertEquals('reset[1]', 2, P[1]);
  AssertEquals('reset[2]', 3, P[2]);
end;

procedure TTestCombinatoricsLib.Test62_NextPermutation_FullCycle;
var
  P: TIntegerArray;
  Count: Integer;
begin
  P := TIntegerArray.Create(1, 2, 3);
  Count := 1;
  while TCombinatoricsKit.NextPermutation(P) do Inc(Count);
  AssertEquals('3! = 6 permutations', 6, Count);
end;

{ ===========================================================================
  PERMUTATIONS (all at once)
=========================================================================== }

procedure TTestCombinatoricsLib.Test63_Permutations_Count;
var L: TPermutationList;
begin
  L := TCombinatoricsKit.Permutations(TIntegerArray.Create(1,2,3,4));
  AssertEquals('4! = 24', 24, Length(L));
end;

procedure TTestCombinatoricsLib.Test64_Permutations_First;
var L: TPermutationList;
begin
  L := TCombinatoricsKit.Permutations(TIntegerArray.Create(1,2,3));
  { First in lex order = [1,2,3] }
  AssertEquals('First[0]', 1, L[0][0]);
  AssertEquals('First[1]', 2, L[0][1]);
  AssertEquals('First[2]', 3, L[0][2]);
end;

procedure TTestCombinatoricsLib.Test65_Permutations_Last;
var L: TPermutationList;
begin
  L := TCombinatoricsKit.Permutations(TIntegerArray.Create(1,2,3));
  { Last in lex order = [3,2,1] }
  AssertEquals('Last[0]', 3, L[5][0]);
  AssertEquals('Last[1]', 2, L[5][1]);
  AssertEquals('Last[2]', 1, L[5][2]);
end;

{ ===========================================================================
  COMBINATIONS
=========================================================================== }

procedure TTestCombinatoricsLib.Test66_Combinations_Count;
begin
  AssertEquals('C(5,2)=10', 10, Length(TCombinatoricsKit.Combinations(5, 2)));
  AssertEquals('C(6,3)=20', 20, Length(TCombinatoricsKit.Combinations(6, 3)));
end;

procedure TTestCombinatoricsLib.Test67_Combinations_C42;
var L: TCombinationList;
begin
  L := TCombinatoricsKit.Combinations(4, 2);
  AssertEquals('C(4,2) count', 6, Length(L));
  { First = [0,1] }
  AssertEquals('L[0][0]', 0, L[0][0]);
  AssertEquals('L[0][1]', 1, L[0][1]);
  { Last = [2,3] }
  AssertEquals('L[5][0]', 2, L[5][0]);
  AssertEquals('L[5][1]', 3, L[5][1]);
end;

procedure TTestCombinatoricsLib.Test68_Combinations_ZeroK;
var L: TCombinationList;
begin
  L := TCombinatoricsKit.Combinations(5, 0);
  AssertEquals('C(5,0)=1 empty subset', 1, Length(L));
  AssertEquals('empty subset length', 0, Length(L[0]));
end;

{ ===========================================================================
  POWER SET
=========================================================================== }

procedure TTestCombinatoricsLib.Test69_PowerSet_N3;
var S: TSubsetList;
begin
  S := TCombinatoricsKit.PowerSet(3);
  { 2^3 = 8 subsets }
  AssertEquals('2^3 = 8 subsets', 8, Length(S));
  { Mask 0 = empty set }
  AssertEquals('empty subset', 0, Length(S[0]));
  { Mask 7 = {0,1,2} }
  AssertEquals('full subset length', 3, Length(S[7]));
end;

procedure TTestCombinatoricsLib.Test70_PowerSet_EmptySet;
var S: TSubsetList;
begin
  S := TCombinatoricsKit.PowerSet(0);
  AssertEquals('PowerSet(0) = 1 subset', 1, Length(S));
  AssertEquals('only subset is empty', 0, Length(S[0]));
end;

procedure TTestCombinatoricsLib.Test71_PowerSet_TooLarge_Raises;
begin
  AssertException('PowerSet(25)', ECombinatoricsError, @DoPowerSet_TooLarge);
end;

initialization
  RegisterTest(TTestCombinatoricsLib);

end.
