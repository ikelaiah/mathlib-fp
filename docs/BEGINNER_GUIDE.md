# A beginner's guide to mathlib-fp

Start with `Double`, `TDoubleArray`, and the simple calls that return a new
result. You do not need generics, complex arithmetic, matrix views,
destination buffers, or reusable workspaces to complete the recipes in this
guide. Those controls remain available through each domain's advanced route.

Run the [README quick start](../README.md#quick-start) first, then choose a
task from the [beginner recipes](RECIPES.md). Every linked program is compiled,
run, and checked against its claimed output in release qualification.

## The beginner data path

| Need | Begin with | Go deeper when |
| --- | --- | --- |
| Real scalar | `Double` | Use `Single` only for a measured storage or interoperability need |
| Real vector | `TDoubleArray` | Use a destination overload for repeated work after the simple form is correct |
| Dense matrix | `IDenseDoubleMatrix` | Use views, reusable factors, or another scalar type when the contract calls for them |
| Sparse matrix | `ISparseDoubleMatrix` | Add a reusable preconditioner/workspace for repeated large solves |
| Iterative outcome | the result record and `TIterationStatus` | Add progress, cancellation, and tighter options only when required |

The names above are concrete public aliases. A beginner should not need to
understand the generic specialization scaffolding used to implement them.

## Dynamic arrays and zero-based indexing

Free Pascal dynamic arrays are managed values. Their first element is at index
zero, `Length(A)` is the element count, and `High(A)` is the final valid index
or `-1` for an empty array.

```pascal
uses MathBase.SharedTypes, StatsLib.Stats;

var
  Samples: TDoubleArray;
begin
  Samples := TDoubleArray.Create(2.0, 4.0, 6.0, 8.0);
  WriteLn('first=', Samples[0]:0:1, ' last=', Samples[High(Samples)]:0:1);
  WriteLn('mean=', TStatsKit.Mean(Samples):0:1);
end.
```

Expected output:

```text
first=2.0 last=8.0
mean=5.0
```

`SetLength(A, N)` allocates or resizes an array. Assignment shares managed
array storage until one side is resized; it is not a promise of an independent
deep copy. Treat an input declared `const` as read-only. APIs that promise an
independent copy say so in their contract.

## Managed interface lifetimes

Dense and sparse matrix interfaces such as `IDenseDoubleMatrix` and
`ISparseDoubleMatrix` are reference counted. Assign them normally and do not
call `Free`. The final reference releases the object automatically.

An interface can still expose mutable matrix data. A view retains its source
storage and aliases that region; a clone owns an independent copy. Read the
[typed dense ownership contract](TypedDenseMatrices.md#complete-storage-contract) or the
[sparse storage contract](SparseLinearAlgebra.md#compressed-storage-contract)
before sharing mutable storage between routines or threads.

## Callbacks

Root finders, fitting routines, and optimisers accept Pascal function
callbacks. Declare a function with the exact documented signature before the
program's main `begin` block, then pass it with `@`:

```pascal
function Objective(X: Double): Double;
begin
  Result := Sqr(X - 3.0);
end;
```

The callback must remain valid for the duration of the call. A callback that
raises propagates its exception; long-running APIs document whether a progress
callback may request cancellation. Do not add hidden global state merely to
feed a callback—use the documented context, record, or object form when one is
provided.

## Options records

Start from the record's documented default constructor, then change only the
field you understand:

```pascal
Options := TLinearSolveOptions.Default;
Options.MaxIterations := 500;
```

Defaults select scale-aware tolerances where the API supports them. A zeroed
record is not necessarily the default configuration. Invalid limits,
tolerances, shapes, or callback combinations raise the exception named by the
contract before a result is returned.

## Result statuses and exceptions

These two outcomes mean different things:

- A result status such as `isIterationLimit`, `isCancelled`, or
  `isNumericalBreakdown` says the input contract was valid but the requested
  convergence outcome was not reached. Inspect the status and diagnostics
  before using the best iterate.
- An exception such as `EDenseMatrixError`, `EOptimizationError`, or
  `EProbabilityError` says the call violated its public contract—for example a
  wrong shape, invalid probability parameter, nil callback, or non-finite
  value where finite input is required.

`isAcceptableLimit` is an algorithm-specific successful-enough outcome only
where that algorithm documents it. Do not turn every non-converged status into
success, and do not catch an invalid-contract exception merely to continue
with an uninitialised result. The [iteration status reference](NumericalModelling.md#termination-results)
names the shared statuses; each recipe links its exact failure guidance.

## Copies, allocation, and precision

The beginner recipes intentionally use allocating calls. A returned dynamic
array or matrix result normally owns new storage; a factorisation may also
retain a private snapshot. This keeps ownership obvious and prevents partial
mutation when validation fails.

After the program is correct:

1. keep `Double` unless storage, input format, or measured throughput justifies
   `Single`;
2. use complex types only for genuinely complex data or transforms;
3. use a documented view when aliasing is intentional;
4. use an `Into`/destination overload to reuse caller-owned output; and
5. use a reusable factor or workspace when repeated calls dominate cost.

Single precision reduces storage and precision. Complex values store two real
components. Conversion between scalar kinds is explicit and may allocate;
complex-to-real conversion rejects a nonzero imaginary component. See the
[typed conversion rules](TypedDenseMatrices.md#compatibility-and-copy-costs) before moving
off the double-real path.

## Continue to the advanced routes

The [documentation index](index.md#domains) links every stable domain landing
page. Each landing page identifies a tested beginner program, common tasks,
the exact contract and failure section, and a tested advanced example. The
transition uses documented shared containers or an explicit documented
conversion—never private glue.
