# Frequently Asked Questions (FAQ)

**Q1: What is the overall design philosophy of mathlib-fp's API?**

A1: mathlib-fp aims for simplicity and directness. Most calculation APIs are
grouped in **Kit classes** with static class methods, so no instance creation is
required. Supporting units may instead expose types, constants, exceptions, or
low-level functions. `TMatrixKit` also implements `IMatrix` for matrix objects.

**Q2: Is the API stable?**

A2: The project follows semantic versioning. Within the 1.x series, existing
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

**Q5: Where did the non-math units go (Strings, FS, DateTime, etc.)?**

A5: Those units remain in the original
[tidykit-fp](https://github.com/ikelaiah/tidykit-fp) repository.
mathlib-fp contains focused mathematical and engineering domains. See the
[terminology guide](docs/index.md#terminology) for the distinction between a
domain, Pascal unit, unit family, and Kit class.

**Q6: What are the future goals?**

A6: Version 1.3.0 establishes native complex-number, contiguous-array vector,
and complex FFT foundations while preserving the existing matrix-as-vector
API. Future work will grow the native Free Pascal matrix, solver, fitting,
DSP, statistics, and optimization capabilities; it will not depend on wrappers
or required DLLs. See the [roadmap](docs/ROADMAP.md). Data-frame functionality
remains outside this focused mathematics project.
