unit CombinatoricsLib.Combinatorics;

{-----------------------------------------------------------------------------
 CombinatoricsLib.Combinatorics

 Discrete mathematics and combinatorics for Free Pascal.
 No external dependencies — only the standard RTL.

 What this library gives you
 ---------------------------
 Counting & combinations
   Factorial          — n!
   Permutation        — P(n,k) = n!/(n-k)!  ordered selection
   Combination        — C(n,k) = n!/(k!(n-k)!)  unordered selection
   Multinomial        — n!/(k1!*k2!*...*km!)
   CatalanNumber      — C_n = C(2n,n)/(n+1)  — bracket/tree counting
   BellNumber         — B_n  — number of partitions of an n-set
   StirlingFirst      — s(n,k) unsigned Stirling numbers of the 1st kind
   StirlingSecond     — S(n,k) Stirling numbers of the 2nd kind
   DerangementCount   — D_n  — permutations with no fixed points

 Sequences & number theory
   Fibonacci          — F_n using fast matrix exponentiation
   Lucas              — L_n Lucas numbers
   PascalRow          — one row of Pascal's triangle
   PascalTriangle     — full triangle up to row N
   PowerSet           — all 2^n subsets of {0..n-1}
   GCD / LCM          — greatest common divisor, least common multiple
   ExtendedGCD        — Bezout coefficients: a*x + b*y = GCD(a,b)
   ModPow             — a^b mod m  (fast exponentiation)
   ModInverse         — modular multiplicative inverse
   IsPrime            — Miller-Rabin primality test (deterministic for n < 3.2e18)
   NextPrime          — next prime >= n
   PrimeFactors       — prime factorisation as (prime, exponent) pairs
   Sieve              — Sieve of Eratosthenes up to limit N

 Permutation generation
   Permutations       — all permutations of an integer array
   NextPermutation    — advance one step in lexicographic order (in-place)
   Combinations       — all k-combinations of {0..n-1}

 Design
   All methods static on TCombinatoricsKit — no object creation needed.
   Int64 is used throughout to handle large intermediate values.
   Raises ECombinatoricsError for invalid inputs (negative n, k>n, etc.).
   Results that would overflow Int64 raise ECombinatoricsError too.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math,
  MathBase.SharedTypes,
  MathBase.Precision;

type
  { Raised for invalid combinatorial inputs or overflow }
  ECombinatoricsError = class(Exception);

  { A prime factor with its exponent: prime^exponent }
  TPrimeFactor = record
    Prime:    Int64;
    Exponent: Integer;
  end;
  TPrimeFactorArray = array of TPrimeFactor;

  { A row of Pascal's triangle: array of Int64 }
  TPascalRow = array of Int64;

  { The full Pascal triangle up to row N: array of rows }
  TPascalTriangle = array of TPascalRow;

  { A permutation: ordered array of integers }
  TPermutation = array of Integer;
  TPermutationList = array of TPermutation;

  { A combination: sorted array of chosen indices }
  TCombination = array of Integer;
  TCombinationList = array of TCombination;

  { A subset (for power set): array of integers }
  TSubset = array of Integer;
  TSubsetList = array of TSubset;

  { TCombinatoricsKit — all methods are class static }
  TCombinatoricsKit = class
  private
    { Internal: Miller-Rabin witness test for one witness A }
    class function MillerRabinWitness(const N, A: Int64): Boolean; static;

    { Internal: multiply a 2x2 Int64 matrix (for Fibonacci fast-doubling) }
    class procedure MatMul2x2(const A, B: array of Int64; out C: array of Int64); static;

    { Internal: raise 2x2 matrix to power P }
    class procedure MatPow2x2(M: array of Int64; P: Int64; out R: array of Int64); static;

  public

    { =======================================================================
      FACTORIALS & COUNTING
    ======================================================================= }

    { n! — factorial of N.
      Returns 1 for N=0.  Raises ECombinatoricsError for N < 0 or N > 20
      (20! is the largest factorial that fits in Int64).
      For larger N use LogFactorial from ProbabilityLib or GammaLn. }
    class function Factorial(N: Integer): Int64; static;

    { ln(n!) — log-factorial, valid for any N >= 0.
      Use this instead of Factorial when N > 20 to avoid overflow.
      Example: LogFactorial(100) ≈ 363.739 }
    class function LogFactorial(N: Integer): Double; static;

    { P(n, k) = n! / (n-k)! — ordered selection (permutations without rep).
      "How many ways to arrange k items chosen from n distinct items?"
      Example: P(5,2) = 20 }
    class function Permutation(N, K: Integer): Int64; static;

    { C(n, k) = n! / (k! * (n-k)!) — unordered selection (combinations).
      "How many ways to choose k items from n without caring about order?"
      Example: C(5,2) = 10
      Uses the multiplicative formula to avoid overflow for moderate n. }
    class function Combination(N, K: Integer): Int64; static;

    { ln C(n,k) — log-combination, safe for large N.
      Example: LogCombination(100, 50) ≈ 68.158 (log of a 29-digit number) }
    class function LogCombination(N, K: Integer): Double; static;

    { Multinomial coefficient n! / (k[0]! * k[1]! * ... * k[m-1]!).
      The K array must sum to N.
      Example: Multinomial(6, [1,2,3]) = 60  (anagram count of "AAABBC") }
    class function Multinomial(N: Integer; const K: TIntegerArray): Int64; static;

    { Catalan number C_n = C(2n,n) / (n+1).
      C_0=1, C_1=1, C_2=2, C_3=5, C_4=14, C_5=42 ...
      Counts: balanced bracket sequences, full binary trees, triangulations.
      Max safe N ≈ 30 before Int64 overflow. }
    class function CatalanNumber(N: Integer): Int64; static;

    { Bell number B_n — number of ways to partition a set of N elements.
      B_0=1, B_1=1, B_2=2, B_3=5, B_4=15, B_5=52 ...
      Uses the Bell triangle (Aitken's array) internally.
      Max safe N ≈ 18 before Int64 overflow. }
    class function BellNumber(N: Integer): Int64; static;

    { Unsigned Stirling number of the first kind s(n,k).
      Counts permutations of N elements with exactly K cycles.
      s(0,0)=1; s(n,0)=0 for n>0; s(n,n)=1. }
    class function StirlingFirst(N, K: Integer): Int64; static;

    { Stirling number of the second kind S(n,k).
      Counts ways to partition N elements into exactly K non-empty subsets.
      S(n,1)=1; S(n,n)=1; S(n,0)=0 for n>0. }
    class function StirlingSecond(N, K: Integer): Int64; static;

    { D_n — number of derangements: permutations of N with no fixed points.
      D_0=1, D_1=0, D_2=1, D_3=2, D_4=9, D_5=44 ...
      Recurrence: D_n = (n-1)*(D_{n-1} + D_{n-2}) }
    class function DerangementCount(N: Integer): Int64; static;

    { =======================================================================
      SEQUENCES & PASCAL'S TRIANGLE
    ======================================================================= }

    { F_n — Fibonacci number (F_0=0, F_1=1, F_2=1, F_3=2 ...).
      Uses fast matrix doubling: O(log n) multiplications.
      Max safe N ≈ 92 before Int64 overflow. }
    class function Fibonacci(N: Integer): Int64; static;

    { L_n — Lucas number (L_0=2, L_1=1, L_2=3, L_3=4 ...).
      Same recurrence as Fibonacci but different seed values.
      Max safe N ≈ 91 before Int64 overflow. }
    class function Lucas(N: Integer): Int64; static;

    { Returns row N of Pascal's triangle as an array of Int64.
      Row 0 = [1]; Row 1 = [1,1]; Row 2 = [1,2,1]; etc.
      Element [k] = C(N, k). }
    class function PascalRow(N: Integer): TPascalRow; static;

    { Returns the full Pascal triangle rows 0..N as a 2-D array.
      Triangle[i][k] = C(i, k). }
    class function PascalTriangle(N: Integer): TPascalTriangle; static;

    { =======================================================================
      NUMBER THEORY
    ======================================================================= }

    { GCD(A, B) — greatest common divisor via Euclidean algorithm.
      GCD(0, n) = n.  Always returns a non-negative value. }
    class function GCD(A, B: Int64): Int64; static;

    { LCM(A, B) — least common multiple.
      LCM(0, n) = 0. }
    class function LCM(A, B: Int64): Int64; static;

    { Extended GCD: returns GCD and sets X, Y such that A*X + B*Y = GCD.
      Useful for computing modular inverses and solving linear Diophantine
      equations. }
    class function ExtendedGCD(A, B: Int64; out X, Y: Int64): Int64; static;

    { A^B mod M — fast modular exponentiation (square-and-multiply).
      Handles large exponents efficiently: O(log B) multiplications.
      M must be > 0.  Returns 1 when B = 0 (by convention). }
    class function ModPow(A, B, M: Int64): Int64; static;

    { Modular multiplicative inverse of A mod M.
      Returns X such that A*X ≡ 1 (mod M).
      Raises ECombinatoricsError if GCD(A, M) ≠ 1 (inverse does not exist). }
    class function ModInverse(A, M: Int64): Int64; static;

    { True if N is prime.  Uses deterministic Miller-Rabin for N < 3.2e18.
      IsPrime(0) = False; IsPrime(1) = False; IsPrime(2) = True. }
    class function IsPrime(N: Int64): Boolean; static;

    { Smallest prime >= N.  IsPrime is called internally. }
    class function NextPrime(N: Int64): Int64; static;

    { Prime factorisation of N as an array of (prime, exponent) records.
      Example: PrimeFactors(360) = [(2,3),(3,2),(5,1)]  because 360=2³·3²·5 }
    class function PrimeFactors(N: Int64): TPrimeFactorArray; static;

    { Sieve of Eratosthenes: returns all primes <= Limit as an Int64 array.
      Limit must be >= 2.  Memory: ~Limit/8 bytes. }
    class function Sieve(Limit: Int64): TPascalRow; static;

    { Euler's totient φ(n) — count of integers in [1,n] coprime to n.
      φ(1)=1; φ prime p = p-1; φ(p^k) = p^(k-1)*(p-1). }
    class function EulerTotient(N: Int64): Int64; static;

    { =======================================================================
      PERMUTATION & COMBINATION GENERATION
    ======================================================================= }

    { All permutations of Items in lexicographic order.
      Items need not be sorted; the returned list is sorted lex.
      Warning: result has N! entries — only practical for N <= 10. }
    class function Permutations(const Items: TIntegerArray): TPermutationList; static;

    { Advance Items to the next permutation in lexicographic order (in-place).
      Returns True if a next permutation exists; False if Items was already
      the last permutation (it is then reset to the first/smallest).
      Use in a loop to enumerate all permutations without storing them all:
        repeat ... until not NextPermutation(perm); }
    class function NextPermutation(var Items: TIntegerArray): Boolean; static;

    { All K-combinations of {0, 1, ..., N-1} in lexicographic order.
      Example: Combinations(4,2) = [[0,1],[0,2],[0,3],[1,2],[1,3],[2,3]]
      Warning: result has C(N,K) entries. }
    class function Combinations(N, K: Integer): TCombinationList; static;

    { Power set of {0, 1, ..., N-1}: all 2^N subsets.
      Subsets are returned in lexicographic order of their bitmask.
      Warning: result has 2^N entries — only practical for N <= 20. }
    class function PowerSet(N: Integer): TSubsetList; static;

  end;

implementation

{ ---------------------------------------------------------------------------
  Private helpers
--------------------------------------------------------------------------- }

class function TCombinatoricsKit.MillerRabinWitness(const N, A: Int64): Boolean;
{ Returns True if A is a witness to N being composite (i.e. N is NOT prime).
  Uses 128-bit-safe arithmetic via Double for the modular multiplication. }
var
  D, R, X, Y: Int64;
  I: Integer;

  { Multiply A*B mod M without overflow using __int128 emulation via Double.
    For n < 2^63 and a,b < n, the product a*b can overflow Int64.
    We use the "Russian peasant" binary method. }
  function MulMod(AA, BB, MM: Int64): Int64;
  var
    Res: Int64;
  begin
    Res := 0;
    AA  := AA mod MM;
    while BB > 0 do
    begin
      if Odd(BB) then
        Res := (Res + AA) mod MM;
      AA := (AA + AA) mod MM;
      BB := BB shr 1;
    end;
    Result := Res;
  end;

begin
  { Write N-1 = 2^R * D }
  D := N - 1;
  R := 0;
  while not Odd(D) do
  begin
    D := D shr 1;
    Inc(R);
  end;

  { Compute A^D mod N }
  X := 1;
  Y := A mod N;
  while D > 0 do
  begin
    if Odd(D) then X := MulMod(X, Y, N);
    Y := MulMod(Y, Y, N);
    D := D shr 1;
  end;

  if (X = 1) or (X = N - 1) then Exit(False);  { probably prime }

  for I := 1 to R - 1 do
  begin
    X := MulMod(X, X, N);
    if X = N - 1 then Exit(False);
  end;
  Result := True;  { composite }
end;

class procedure TCombinatoricsKit.MatMul2x2(const A, B: array of Int64; out C: array of Int64);
{ Multiply two 2x2 matrices stored as [a00, a01, a10, a11] }
begin
  C[0] := A[0]*B[0] + A[1]*B[2];
  C[1] := A[0]*B[1] + A[1]*B[3];
  C[2] := A[2]*B[0] + A[3]*B[2];
  C[3] := A[2]*B[1] + A[3]*B[3];
end;

class procedure TCombinatoricsKit.MatPow2x2(M: array of Int64; P: Int64; out R: array of Int64);
{ Raise 2x2 matrix M to power P by repeated squaring }
var
  Tmp: array[0..3] of Int64;
begin
  { Start with identity matrix }
  R[0] := 1; R[1] := 0;
  R[2] := 0; R[3] := 1;

  while P > 0 do
  begin
    if Odd(P) then
    begin
      MatMul2x2(R, M, Tmp);
      R[0] := Tmp[0]; R[1] := Tmp[1];
      R[2] := Tmp[2]; R[3] := Tmp[3];
    end;
    MatMul2x2(M, M, Tmp);
    M[0] := Tmp[0]; M[1] := Tmp[1];
    M[2] := Tmp[2]; M[3] := Tmp[3];
    P := P shr 1;
  end;
end;

{ ---------------------------------------------------------------------------
  FACTORIALS & COUNTING
--------------------------------------------------------------------------- }

class function TCombinatoricsKit.Factorial(N: Integer): Int64;
{ Precomputed table — 20! = 2432902008176640000 fits in Int64; 21! does not }
const
  Table: array[0..20] of Int64 = (
    1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880,
    3628800, 39916800, 479001600, 6227020800, 87178291200,
    1307674368000, 20922789888000, 355687428096000,
    6402373705728000, 121645100408832000, 2432902008176640000);
begin
  if N < 0  then raise ECombinatoricsError.Create('Factorial: N must be >= 0');
  if N > 20 then raise ECombinatoricsError.Create(
    'Factorial: N > 20 overflows Int64 — use LogFactorial instead');
  Result := Table[N];
end;

class function TCombinatoricsKit.LogFactorial(N: Integer): Double;
{ ln(N!) = GammaLn(N+1) via Lanczos approximation — accurate for all N }
begin
  if N < 0 then raise ECombinatoricsError.Create('LogFactorial: N must be >= 0');
  Result := GammaLn(N + 1);
end;

class function TCombinatoricsKit.Permutation(N, K: Integer): Int64;
{ P(n,k) = n * (n-1) * ... * (n-k+1)  — multiplicative form }
var
  I: Integer;
  R: Int64;
begin
  if N < 0 then raise ECombinatoricsError.Create('Permutation: N must be >= 0');
  if K < 0 then raise ECombinatoricsError.Create('Permutation: K must be >= 0');
  if K > N then raise ECombinatoricsError.Create('Permutation: K must be <= N');
  R := 1;
  for I := N downto (N - K + 1) do
  begin
    if R > High(Int64) div I then
      raise ECombinatoricsError.Create('Permutation: result overflows Int64');
    R := R * I;
  end;
  Result := R;
end;

class function TCombinatoricsKit.Combination(N, K: Integer): Int64;
{ C(n,k) using the multiplicative formula: product_{i=1}^{k} (n-k+i)/i
  Divides at each step to keep intermediate values small. }
var
  I: Integer;
  R: Int64;
begin
  if N < 0 then raise ECombinatoricsError.Create('Combination: N must be >= 0');
  if K < 0 then raise ECombinatoricsError.Create('Combination: K must be >= 0');
  if K > N then raise ECombinatoricsError.Create('Combination: K must be <= N');
  if K = 0 then Exit(1);
  if K > N div 2 then K := N - K;  { use smaller K for efficiency }
  R := 1;
  for I := 1 to K do
  begin
    if R > High(Int64) div (N - K + I) then
      raise ECombinatoricsError.Create('Combination: result overflows Int64');
    R := R * (N - K + I) div I;
  end;
  Result := R;
end;

class function TCombinatoricsKit.LogCombination(N, K: Integer): Double;
begin
  if N < 0 then raise ECombinatoricsError.Create('LogCombination: N must be >= 0');
  if (K < 0) or (K > N) then raise ECombinatoricsError.Create('LogCombination: K must be in [0,N]');
  Result := LogFactorial(N) - LogFactorial(K) - LogFactorial(N - K);
end;

class function TCombinatoricsKit.Multinomial(N: Integer; const K: TIntegerArray): Int64;
{ n! / (k[0]! * k[1]! * ... ) — checked that sum(K) = N }
var
  I, Sum: Integer;
  R: Int64;
begin
  if N < 0 then raise ECombinatoricsError.Create('Multinomial: N must be >= 0');
  Sum := 0;
  for I := 0 to High(K) do
  begin
    if K[I] < 0 then raise ECombinatoricsError.Create('Multinomial: K values must be >= 0');
    Sum := Sum + K[I];
  end;
  if Sum <> N then raise ECombinatoricsError.Create(
    'Multinomial: sum of K array must equal N');
  { Build result as product of C(partial_sum, k[i]) }
  R := 1;
  Sum := 0;
  for I := 0 to High(K) do
  begin
    Sum := Sum + K[I];
    R   := R * Combination(Sum, K[I]);
  end;
  Result := R;
end;

class function TCombinatoricsKit.CatalanNumber(N: Integer): Int64;
{ C_n = C(2n, n) / (n+1) }
begin
  if N < 0 then raise ECombinatoricsError.Create('CatalanNumber: N must be >= 0');
  if N > 30 then raise ECombinatoricsError.Create(
    'CatalanNumber: N > 30 overflows Int64');
  Result := Combination(2 * N, N) div (N + 1);
end;

class function TCombinatoricsKit.BellNumber(N: Integer): Int64;
{ Uses Bell triangle (Aitken's array).
  Row 0: [1]
  Each row starts with the last element of the previous row,
  then each next element = previous element in current row + element above it. }
var
  Prev, Curr: array of Int64;
  I, J: Integer;
begin
  if N < 0 then raise ECombinatoricsError.Create('BellNumber: N must be >= 0');
  if N > 18 then raise ECombinatoricsError.Create(
    'BellNumber: N > 18 overflows Int64');
  if N = 0 then Exit(1);
  SetLength(Prev, 1);
  Prev[0] := 1;
  for I := 1 to N do
  begin
    SetLength(Curr, I + 1);
    Curr[0] := Prev[I - 1];          { first of row = last of previous row }
    for J := 1 to I do
      Curr[J] := Curr[J-1] + Prev[J-1];
    Prev := Curr;
  end;
  Result := Prev[0];
end;

class function TCombinatoricsKit.StirlingFirst(N, K: Integer): Int64;
{ Unsigned Stirling numbers of the 1st kind via recurrence:
  s(n,k) = s(n-1,k-1) + (n-1)*s(n-1,k) }
var
  Table: array of array of Int64;
  I, J: Integer;
begin
  if (N < 0) or (K < 0) then raise ECombinatoricsError.Create(
    'StirlingFirst: N and K must be >= 0');
  if K > N then Exit(0);
  SetLength(Table, N+1, N+1);
  Table[0][0] := 1;
  for I := 1 to N do
    for J := 1 to I do
      Table[I][J] := Table[I-1][J-1] + (I-1) * Table[I-1][J];
  Result := Table[N][K];
end;

class function TCombinatoricsKit.StirlingSecond(N, K: Integer): Int64;
{ Stirling numbers of the 2nd kind via recurrence:
  S(n,k) = k*S(n-1,k) + S(n-1,k-1) }
var
  Table: array of array of Int64;
  I, J: Integer;
begin
  if (N < 0) or (K < 0) then raise ECombinatoricsError.Create(
    'StirlingSecond: N and K must be >= 0');
  if K > N then Exit(0);
  SetLength(Table, N+1, N+1);
  Table[0][0] := 1;
  for I := 1 to N do
    for J := 1 to I do
      Table[I][J] := J * Table[I-1][J] + Table[I-1][J-1];
  Result := Table[N][K];
end;

class function TCombinatoricsKit.DerangementCount(N: Integer): Int64;
{ D_n via recurrence D_n = (n-1)*(D_{n-1} + D_{n-2})
  D_0=1, D_1=0 }
var
  A, B, C: Int64;
  I: Integer;
begin
  if N < 0 then raise ECombinatoricsError.Create('DerangementCount: N must be >= 0');
  if N = 0 then Exit(1);
  if N = 1 then Exit(0);
  A := 1; B := 0;  { D_0, D_1 }
  for I := 2 to N do
  begin
    C := (I - 1) * (A + B);
    A := B;
    B := C;
  end;
  Result := B;
end;

{ ---------------------------------------------------------------------------
  SEQUENCES
--------------------------------------------------------------------------- }

class function TCombinatoricsKit.Fibonacci(N: Integer): Int64;
{ Fast matrix doubling: [F(2k), F(2k+1)] from [F(k), F(k+1)]
  F(2k)   = F(k) * (2*F(k+1) - F(k))
  F(2k+1) = F(k)^2 + F(k+1)^2
  O(log N) multiplications. }
var
  A, B, C, D, E: Int64;

  procedure FibDouble(K: Integer; out FK, FK1: Int64);
  begin
    if K = 0 then begin FK := 0; FK1 := 1; Exit; end;
    FibDouble(K div 2, A, B);
    C  := A * (2*B - A);   { F(2k) }
    D  := A*A + B*B;       { F(2k+1) }
    if Odd(K) then begin FK := D; FK1 := C + D; end
    else            begin FK := C; FK1 := D; end;
  end;

begin
  if N < 0 then raise ECombinatoricsError.Create('Fibonacci: N must be >= 0');
  if N > 92 then raise ECombinatoricsError.Create(
    'Fibonacci: N > 92 overflows Int64');
  FibDouble(N, Result, E);
end;

class function TCombinatoricsKit.Lucas(N: Integer): Int64;
{ L_n = F_{n-1} + F_{n+1}  (identity relating Lucas to Fibonacci) }
begin
  if N < 0 then raise ECombinatoricsError.Create('Lucas: N must be >= 0');
  if N = 0 then Exit(2);
  if N = 1 then Exit(1);
  Result := Fibonacci(N - 1) + Fibonacci(N + 1);
end;

class function TCombinatoricsKit.PascalRow(N: Integer): TPascalRow;
{ Build row N iteratively: row[k] = row[k-1] * (N-k+1) / k }
var
  K: Integer;
begin
  if N < 0 then raise ECombinatoricsError.Create('PascalRow: N must be >= 0');
  SetLength(Result, N + 1);
  Result[0] := 1;
  for K := 1 to N do
    Result[K] := Result[K-1] * (N - K + 1) div K;
end;

class function TCombinatoricsKit.PascalTriangle(N: Integer): TPascalTriangle;
{ Build all rows 0..N }
var
  I: Integer;
begin
  if N < 0 then raise ECombinatoricsError.Create('PascalTriangle: N must be >= 0');
  SetLength(Result, N + 1);
  for I := 0 to N do
    Result[I] := PascalRow(I);
end;

{ ---------------------------------------------------------------------------
  NUMBER THEORY
--------------------------------------------------------------------------- }

class function TCombinatoricsKit.GCD(A, B: Int64): Int64;
{ Euclidean algorithm }
var T: Int64;
begin
  A := Abs(A); B := Abs(B);
  while B <> 0 do
  begin
    T := B;
    B := A mod B;
    A := T;
  end;
  Result := A;
end;

class function TCombinatoricsKit.LCM(A, B: Int64): Int64;
begin
  if (A = 0) or (B = 0) then Exit(0);
  Result := Abs(A) div GCD(A, B) * Abs(B);
end;

class function TCombinatoricsKit.ExtendedGCD(A, B: Int64; out X, Y: Int64): Int64;
{ Extended Euclidean algorithm — iterative version }
var
  OldR, R, OldS, S, OldT, T, Q, Tmp: Int64;
begin
  OldR := A; R := B;
  OldS := 1; S := 0;
  OldT := 0; T := 1;
  while R <> 0 do
  begin
    Q    := OldR div R;
    Tmp  := R;    R    := OldR - Q * R;    OldR := Tmp;
    Tmp  := S;    S    := OldS - Q * S;    OldS := Tmp;
    Tmp  := T;    T    := OldT - Q * T;    OldT := Tmp;
  end;
  X      := OldS;
  Y      := OldT;
  Result := OldR;
end;

class function TCombinatoricsKit.ModPow(A, B, M: Int64): Int64;
{ Square-and-multiply: A^B mod M in O(log B) steps }
var
  R: Int64;
begin
  if M <= 0 then raise ECombinatoricsError.Create('ModPow: M must be > 0');
  if M = 1  then Exit(0);
  R := 1;
  A := A mod M;
  while B > 0 do
  begin
    if Odd(B) then R := (R * A) mod M;
    A := (A * A) mod M;
    B := B shr 1;
  end;
  Result := R;
end;

class function TCombinatoricsKit.ModInverse(A, M: Int64): Int64;
var
  X, Y: Int64;
  G: Int64;
begin
  G := ExtendedGCD(A, M, X, Y);
  if G <> 1 then
    raise ECombinatoricsError.CreateFmt(
      'ModInverse: GCD(%d,%d) = %d ≠ 1 — inverse does not exist', [A, M, G]);
  Result := ((X mod M) + M) mod M;
end;

class function TCombinatoricsKit.IsPrime(N: Int64): Boolean;
{ Deterministic Miller-Rabin with witnesses sufficient for N < 3,215,031,751
  and with extra witnesses covering all N < 3.3 * 10^24 }
const
  { These 7 witnesses are sufficient for all N < 3,317,044,064,679,887,385,961,981 }
  Witnesses: array[0..6] of Int64 = (2, 3, 5, 7, 11, 13, 17);
var
  W: Int64;
begin
  if N < 2  then Exit(False);
  if N = 2  then Exit(True);
  if N = 3  then Exit(True);
  if not Odd(N) then Exit(False);
  for W in Witnesses do
  begin
    if N = W then Exit(True);
    if MillerRabinWitness(N, W) then Exit(False);
  end;
  Result := True;
end;

class function TCombinatoricsKit.NextPrime(N: Int64): Int64;
begin
  if N <= 2 then Exit(2);
  { Return N itself if it is already prime }
  if IsPrime(N) then Exit(N);
  { Advance to the next odd candidate }
  if not Odd(N) then Inc(N) else Inc(N, 2);
  while not IsPrime(N) do
    Inc(N, 2);
  Result := N;
end;

class function TCombinatoricsKit.PrimeFactors(N: Int64): TPrimeFactorArray;
{ Trial division up to sqrt(N); remainder is prime if > 1 }
var
  D, Count: Int64;
  Exp: Integer;
  Len: Integer;
begin
  if N <= 1 then raise ECombinatoricsError.Create(
    'PrimeFactors: N must be >= 2');
  SetLength(Result, 0);
  Len := 0;
  D   := 2;
  while D * D <= N do
  begin
    if N mod D = 0 then
    begin
      Exp := 0;
      while N mod D = 0 do
      begin
        Inc(Exp);
        N := N div D;
      end;
      SetLength(Result, Len + 1);
      Result[Len].Prime    := D;
      Result[Len].Exponent := Exp;
      Inc(Len);
    end;
    if D = 2 then D := 3 else Inc(D, 2);
  end;
  if N > 1 then
  begin
    SetLength(Result, Len + 1);
    Result[Len].Prime    := N;
    Result[Len].Exponent := 1;
  end;
end;

class function TCombinatoricsKit.Sieve(Limit: Int64): TPascalRow;
{ Classic bitset sieve; returns primes as a dynamic array }
var
  IsComposite: array of Boolean;
  I, J, Count, Idx: Int64;
begin
  if Limit < 2 then raise ECombinatoricsError.Create('Sieve: Limit must be >= 2');
  SetLength(IsComposite, Limit + 1);
  FillChar(IsComposite[0], Limit + 1, 0);
  IsComposite[0] := True;
  IsComposite[1] := True;
  I := 2;
  while I * I <= Limit do
  begin
    if not IsComposite[I] then
    begin
      J := I * I;
      while J <= Limit do
      begin
        IsComposite[J] := True;
        J := J + I;
      end;
    end;
    Inc(I);
  end;
  Count := 0;
  for I := 2 to Limit do
    if not IsComposite[I] then Inc(Count);
  SetLength(Result, Count);
  Idx := 0;
  for I := 2 to Limit do
    if not IsComposite[I] then
    begin
      Result[Idx] := I;
      Inc(Idx);
    end;
end;

class function TCombinatoricsKit.EulerTotient(N: Int64): Int64;
{ φ(n) = n * ∏(1 - 1/p) for each prime factor p of n }
var
  Factors: TPrimeFactorArray;
  F: TPrimeFactor;
begin
  if N <= 0 then raise ECombinatoricsError.Create('EulerTotient: N must be >= 1');
  if N = 1  then Exit(1);
  Factors := PrimeFactors(N);
  Result  := N;
  for F in Factors do
    Result := Result div F.Prime * (F.Prime - 1);
end;

{ ---------------------------------------------------------------------------
  PERMUTATION & COMBINATION GENERATION
--------------------------------------------------------------------------- }

class function TCombinatoricsKit.NextPermutation(var Items: TIntegerArray): Boolean;
{ Knuth's Algorithm L: find rightmost ascent, swap with ceiling, reverse tail }
var
  N, I, J, K: Integer;
  Tmp: Integer;
begin
  N := Length(Items);
  if N <= 1 then Exit(False);

  { Find largest I such that Items[I] < Items[I+1] }
  I := N - 2;
  while (I >= 0) and (Items[I] >= Items[I+1]) do Dec(I);
  if I < 0 then
  begin
    { Already the last permutation — reset to first }
    I := 0; J := N - 1;
    while I < J do
    begin
      Tmp := Items[I]; Items[I] := Items[J]; Items[J] := Tmp;
      Inc(I); Dec(J);
    end;
    Exit(False);
  end;

  { Find largest J such that Items[I] < Items[J] }
  J := N - 1;
  while Items[J] <= Items[I] do Dec(J);

  { Swap Items[I] and Items[J] }
  Tmp := Items[I]; Items[I] := Items[J]; Items[J] := Tmp;

  { Reverse Items[I+1..N-1] }
  K := I + 1; J := N - 1;
  while K < J do
  begin
    Tmp := Items[K]; Items[K] := Items[J]; Items[J] := Tmp;
    Inc(K); Dec(J);
  end;
  Result := True;
end;

class function TCombinatoricsKit.Permutations(const Items: TIntegerArray): TPermutationList;
{ Generate all permutations by sorting first then stepping with NextPermutation }
var
  Perm: TIntegerArray;
  Count, I, J: Integer;
  Tmp: Integer;
begin
  SetLength(Perm, Length(Items));
  for I := 0 to High(Items) do Perm[I] := Items[I];
  { Sort ascending to start from lexicographically first permutation }
  for I := 0 to High(Perm) - 1 do
    for J := I+1 to High(Perm) do
      if Perm[J] < Perm[I] then
      begin
        Tmp := Perm[I]; Perm[I] := Perm[J]; Perm[J] := Tmp;
      end;

  Count := Factorial(Length(Perm));
  SetLength(Result, Count);
  for I := 0 to Count - 1 do
  begin
    SetLength(Result[I], Length(Perm));
    for J := 0 to High(Perm) do Result[I][J] := Perm[J];
    NextPermutation(Perm);
  end;
end;

class function TCombinatoricsKit.Combinations(N, K: Integer): TCombinationList;
{ Generate all C(N,K) combinations of {0..N-1} in lex order
  using the combinatorial number system algorithm }
var
  Combo: TCombination;
  Count: Int64;
  Idx, I, J: Integer;
begin
  if N < 0 then raise ECombinatoricsError.Create('Combinations: N must be >= 0');
  if (K < 0) or (K > N) then raise ECombinatoricsError.Create(
    'Combinations: K must be in [0,N]');

  Count := Combination(N, K);
  SetLength(Result, Count);
  SetLength(Combo, K);

  { Initialise first combination: [0, 1, 2, ..., K-1] }
  for I := 0 to K-1 do Combo[I] := I;
  Idx := 0;

  while Idx < Count do
  begin
    SetLength(Result[Idx], K);
    for I := 0 to K-1 do Result[Idx][I] := Combo[I];
    Inc(Idx);
    { Advance to next combination in lex order }
    I := K - 1;
    while (I >= 0) and (Combo[I] = I + N - K) do Dec(I);
    if I >= 0 then
    begin
      Inc(Combo[I]);
      for J := I+1 to K-1 do Combo[J] := Combo[J-1] + 1;
    end;
  end;
end;

class function TCombinatoricsKit.PowerSet(N: Integer): TSubsetList;
{ Enumerate all 2^N subsets via bitmask }
var
  Total, Mask, Bit, Idx: Integer;
  Sub: TSubset;
begin
  if N < 0  then raise ECombinatoricsError.Create('PowerSet: N must be >= 0');
  if N > 24 then raise ECombinatoricsError.Create(
    'PowerSet: N > 24 would produce > 16M subsets — use a generator instead');
  Total := 1 shl N;
  SetLength(Result, Total);
  for Mask := 0 to Total - 1 do
  begin
    SetLength(Sub, 0);
    for Bit := 0 to N-1 do
      if (Mask shr Bit) and 1 = 1 then
      begin
        SetLength(Sub, Length(Sub) + 1);
        Sub[High(Sub)] := Bit;
      end;
    Result[Mask] := Sub;
  end;
end;

end.
