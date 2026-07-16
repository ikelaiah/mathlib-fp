# Frequently Asked Questions (FAQ)

**Q1: What is the overall design philosophy of mathlib-fp' API?**

A1: mathlib-fp aims for simplicity and directness. All libraries expose
**static class methods** — no instance creation required. This suits the
stateless nature of mathematical calculations.

**Q2: Is the API stable?**

A2: The library follows semantic versioning. Within the 1.x series, existing
public signatures are preserved where practical and new behavior is normally
introduced through overloads. Correctness fixes may tighten validation or
replace mathematically invalid output with a typed exception. Check
`CHANGELOG.md` before upgrading.

**Q3: Why static methods instead of Factory/Interface?**

A3: Mathematical and engineering functions are stateless by nature — a call to
`TStatsKit.Mean(Data)` has no side effects and requires no external state.
Static methods are simpler, more direct, and avoid unnecessary overhead for
purely computational work. The exception is `AlgebraLib`, which uses an
interface (`IMatrix`) to support value semantics and automatic reference
counting for matrix objects.

**Q4: What changes are planned for `AlgebraLib.Matrices`?**

A4: `AlgebraLib.Matrices` already uses a class/interface pattern
(`TMatrixKit`/`IMatrix`). This provides automatic reference counting and
value semantics for matrix operations, and is considered stable.

**Q5: Where did the non-math modules go (Strings, FS, DateTime, etc.)?**

A5: Those modules remain in the original
[tidykit-fp](https://github.com/ikelaiah/tidykit-fp) repository.
mathlib-fp is a focused monorepo containing only the math, statistics,
finance, and engineering libraries.

**Q6: What are the future goals?**

A6: Near-term work focuses on numerical correctness, cross-platform validation,
reference datasets, performance benchmarks, and clearer API documentation.
Data-frame functionality remains outside this focused mathematics library.
