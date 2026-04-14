# Frequently Asked Questions (FAQ)

**Q1: What is the overall design philosophy of pascal-mathlibs' API?**

A1: pascal-mathlibs aims for simplicity and directness. All libraries expose
**static class methods** — no instance creation required. This suits the
stateless nature of mathematical calculations.

**Q2: Is the API stable?**

A2: The library is under active development. APIs may change without notice
before version 1.0. Check the `CHANGELOG.md` and library `README.md` files
for the latest status.

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
pascal-mathlibs is a focused monorepo containing only the math, statistics,
finance, and engineering libraries.

**Q6: What are the future goals?**

A6: Planned additions include more real-world examples, expanded engineering
modules, and DataFrame-like structures for data manipulation.
