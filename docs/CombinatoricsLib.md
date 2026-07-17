# CombinatoricsLib Reference

`CombinatoricsLib.Combinatorics` — discrete mathematics and combinatorics for Free Pascal.

---

## Quick Start

```pascal
uses CombinatoricsLib.Combinatorics;

// How many ways to choose 3 items from 10?
n := TCombinatoricsKit.Combination(10, 3);    // 120

// Is 999999937 prime?
b := TCombinatoricsKit.IsPrime(999999937);    // True

// All permutations of [1,2,3]
perms := TCombinatoricsKit.Permutations(TIntegerArray.Create(1,2,3));  // 6 permutations
```

All methods are **class static** — no `Create`/`Free` needed.

---

## Counting & Combinations

| Method | Description | Example |
|--------|-------------|---------|
| `Factorial(N)` | N! — raises if N > 20 (overflow) | `Factorial(5)` = 120 |
| `LogFactorial(N)` | ln(N!) — safe for any N | `LogFactorial(100)` ≈ 363.74 |
| `Permutation(N,K)` | P(n,k) = n!/(n-k)! ordered selection | `Permutation(5,2)` = 20 |
| `Combination(N,K)` | C(n,k) = n!/(k!(n-k)!) unordered | `Combination(5,2)` = 10 |
| `LogCombination(N,K)` | ln C(n,k) — safe for large N | `LogCombination(100,50)` ≈ 68.16 |
| `Multinomial(N, K[])` | n!/(k₁!k₂!…) | `Multinomial(6,[1,2,3])` = 60 |
| `CatalanNumber(N)` | C_n = C(2n,n)/(n+1) | `CatalanNumber(5)` = 42 |
| `BellNumber(N)` | B_n — set partition count | `BellNumber(4)` = 15 |
| `StirlingFirst(N,K)` | s(n,k) unsigned Stirling 1st kind | `StirlingFirst(4,2)` = 11 |
| `StirlingSecond(N,K)` | S(n,k) Stirling 2nd kind | `StirlingSecond(4,2)` = 7 |
| `DerangementCount(N)` | D_n — permutations with no fixed points | `DerangementCount(4)` = 9 |

### Catalan numbers — what they count
The n-th Catalan number counts many equivalent things:
- Valid sequences of n pairs of brackets: `((()))`, `(()())`, …
- Full binary trees with n+1 leaves
- Triangulations of a convex (n+2)-gon
- Monotone lattice paths from (0,0) to (n,n) that don't cross the diagonal

### Stirling numbers — cheat sheet
- `StirlingFirst(n,k)` — number of permutations of n with exactly k cycles
- `StirlingSecond(n,k)` — number of ways to partition n elements into k non-empty subsets
- `BellNumber(n)` = sum of `StirlingSecond(n, k)` for k = 1..n

---

## Sequences & Pascal's Triangle

```pascal
TCombinatoricsKit.Fibonacci(10)       // 55  (F_0=0, F_1=1, F_2=1, ...)
TCombinatoricsKit.Lucas(6)            // 18  (L_0=2, L_1=1, L_2=3, ...)
TCombinatoricsKit.PascalRow(5)        // [1, 5, 10, 10, 5, 1]
TCombinatoricsKit.PascalTriangle(4)   // rows 0..4
```

`PascalTriangle(N)[i][k]` = C(i, k). Row i sums to 2^i.

`Fibonacci` uses **fast doubling** — O(log N) multiplications, safe up to N=92.
The largest safe Lucas index is 90.

---

## Number Theory

### GCD, LCM, Extended GCD

```pascal
TCombinatoricsKit.GCD(12, 8)              // 4
TCombinatoricsKit.LCM(4, 6)              // 12

var X, Y: Int64;
G := TCombinatoricsKit.ExtendedGCD(35, 15, X, Y);
// G=5, and 35*X + 15*Y = 5  (Bezout's identity)
```

### Modular arithmetic

```pascal
TCombinatoricsKit.ModPow(2, 10, 1000)    // 24   (2^10 mod 1000)
TCombinatoricsKit.ModInverse(3, 11)      // 4    (3*4 ≡ 1 mod 11)
```

`ModInverse` raises `ECombinatoricsError` when GCD(A,M) ≠ 1.

### Primality

```pascal
TCombinatoricsKit.IsPrime(999999937)     // True
TCombinatoricsKit.NextPrime(100)         // 101
```

`IsPrime` uses Miller-Rabin with bases 2, 3, 5, 7, 11, 13, and 17. This
witness set is deterministic for `N < 341,550,071,728,321`. Do not extrapolate
the guarantee to the full `Int64` range.

### Factorisation & Sieve

```pascal
// 360 = 2³ × 3² × 5
factors := TCombinatoricsKit.PrimeFactors(360);
// factors[0] = (Prime=2, Exponent=3)
// factors[1] = (Prime=3, Exponent=2)
// factors[2] = (Prime=5, Exponent=1)

primes := TCombinatoricsKit.Sieve(100);  // all 25 primes <= 100
```

`Sieve` stores one Boolean per integer through `Limit`; its memory use is O(Limit),
not a packed one-bit-per-number representation.

### Euler's Totient

```pascal
TCombinatoricsKit.EulerTotient(12)   // 4   (1, 5, 7, 11 are coprime to 12)
TCombinatoricsKit.EulerTotient(7)    // 6   (prime: φ(p) = p-1)
```

---

## Permutation & Combination Generation

### Enumerate all permutations

```pascal
// Option 1 — get all at once (only practical for N <= 10)
perms := TCombinatoricsKit.Permutations(TIntegerArray.Create(1,2,3));
// 6 permutations: [1,2,3], [1,3,2], [2,1,3], [2,3,1], [3,1,2], [3,2,1]

// Option 2 — step one at a time (memory efficient, any N)
perm := TIntegerArray.Create(1, 2, 3, 4);
repeat
  ProcessPermutation(perm);
until not TCombinatoricsKit.NextPermutation(perm);
```

`NextPermutation` uses **Knuth's Algorithm L** and returns `False` (resetting to first) when the last permutation is reached.
`Permutations` allocates `Length(Items)!` rows. Repeated input values therefore
produce repeated rows rather than only the distinct permutations.

### All K-combinations

```pascal
// All 2-element subsets of {0,1,2,3}
combos := TCombinatoricsKit.Combinations(4, 2);
// [[0,1],[0,2],[0,3],[1,2],[1,3],[2,3]]
```

### Power set

```pascal
subsets := TCombinatoricsKit.PowerSet(3);
// 8 subsets of {0,1,2}: [], [0], [1], [0,1], [2], [0,2], [1,2], [0,1,2]
```

Limited to N <= 24 (produces 16M subsets at N=24 — use a generator for larger N).

---

## Error Handling

```pascal
try
  TCombinatoricsKit.Factorial(21);   // overflows Int64
except
  on E: ECombinatoricsError do
    WriteLn(E.Message);
end;
```

`ECombinatoricsError` is raised for:

- negative N or K on counting/generation functions whose domain requires them
- K > N for Permutation, Combination
- Factorial(N > 20) or CatalanNumber(N > 30) or BellNumber(N > 18) — Int64 overflow
- `ModInverse` when GCD(A,M) ≠ 1
- `ModPow` with M <= 0
- `PrimeFactors(N <= 1)`
- `Sieve(Limit < 2)`
- `PowerSet(N > 24)`

`ModPow` also requires a non-negative exponent, although a negative exponent is
not currently rejected. Its `Int64` multiplications can overflow for large
moduli; it is not an arbitrary-precision modular arithmetic routine. Likewise,
`LCM`, Stirling/derangement recurrences, and some sequence builders do not all
perform explicit overflow checks.

---

## Overflow Reference

| Function | Documented safe/accepted maximum | Value at maximum |
|----------|-----------|--------------|
| `Factorial` | 20 | 2.4 × 10¹⁸ |
| `CatalanNumber` | 30 | 3,814,986,502,092,304 |
| `BellNumber` | 18 | 682,076,806,159 |
| `Fibonacci` | 92 | 7.5 × 10¹⁸ |
| `Lucas` | 90 | 6,440,026,026,380,244,498 |

For larger values use `LogFactorial` / `LogCombination` which return `Double`.

---

## Dependencies

- `MathBase.SharedTypes` — `TIntegerArray`
- `MathBase.Precision` — `GammaLn`, used by `LogFactorial`

No other external libraries required.
