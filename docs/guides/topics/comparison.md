# Choosing a Pascal numerical library

Reviewed 3 October 2026. This is a representative shortlist of Pascal math
libraries and Pascal-facing numerical packages, not a benchmark or a claim of
complete compatibility across every compiler and platform. The GitHub-hosted
projects are listed first; established projects distributed through other
upstream channels follow. Check each upstream project for its current release,
compiler support, and license when evaluating it for a project.

## GitHub-hosted projects

| Project | License and compiler | Areas of strength | Notes |
| ------- | ------------------- | ---------- | ----------------- |
| [mrMath](https://github.com/mikerabat/mrmath) | Apache-2.0; Delphi and Free Pascal source | Dense linear algebra (LU, QR, Cholesky, SVD), statistics, dimensionality reduction, wavelets, and threaded matrix operations | A broad matrix and machine-learning toolkit, with hand-optimized assembly, AVX, and FMA paths. Its documentation describes target-specific builds and setup. |
| [numerik](https://github.com/ariaghora/numerik) | MIT; Object Pascal with a Lazarus package | NumPy-like `TMultiArray`, broadcasting, slicing, array operations, matrix multiplication, and SVD | Brings multidimensional-array semantics to Object Pascal; can use OpenBLAS/LAPACK for BLAS acceleration. |
| [pas-core-math](https://github.com/joaopauloschuler/pas-core-math) | MIT; Free Pascal 3.2.2+ | CORE-MATH scalar functions for binary32 and binary64, with correctly-rounded results as the design goal | A specialist project for high-quality scalar math, with an x86-64 Linux focus. |
| [FastMath](https://github.com/neslib/FastMath) | Simplified BSD; Delphi | Single-precision scalar operations, 2D/3D/4D vectors, small matrices, and quaternions | Designed for graphics and SIMD workloads. Its `Fast*` routines make speed-oriented approximations available as a distinct choice. |
| [CAI Neural API](https://github.com/joaopauloschuler/neural-api) | LGPL-2.1 with a custom linking exception; current master targets Free Pascal/Lazarus, and Delphi users are directed to tag v2.0.0 | Neural-network training and inference, with AVX/AVX2/AVX512 CPU paths and optional OpenCL | A dedicated machine-learning API with CPU and GPU acceleration paths; the project provides a Delphi-compatible release tag alongside its current FPC branch. |
| [MPArith](https://github.com/JulStrat/MPArith) | Free Pascal and Delphi source; terms are in [`copying_we.txt`](https://github.com/JulStrat/MPArith/blob/master/copying_we.txt) | Arbitrary-precision integer, rational, real, and complex arithmetic | A multiprecision collection with test programs, demos, and calculator examples alongside its numeric units. |
| [mathlib-fp 2.4.0](https://github.com/ikelaiah/mathlib-fp) | MIT; native Free Pascal source (FPC 3.2.2+) | 13 focused domains spanning algebra, probability, statistics, engineering/DSP, numerics, optimisation, time series, machine learning, finance, geometry, and interchange | A broad, FPC-first toolkit with no mandatory third-party numerical runtime, versioned web/offline docs, runnable learning examples, a capability inventory, and release qualification. It uses FPC's `objfpc` dialect and does not claim Delphi compatibility. |

## Specialized GitHub projects

These projects focus on precision-specific arithmetic needs.

| Project | License and compiler | Areas of strength | Notes |
| ------- | ------------------- | ---------- | ----------------- |
| [TIntX](https://github.com/Xor-el/IntXLib4Pascal) | MIT; Free Pascal 3.0+ and Delphi 2010+ | Arbitrary-precision integers, including fast multiplication, division, and base conversion | A focused big-integer library with transform-based fast algorithms and support for both major Pascal compiler families. |
| [BigDecimalMath](https://github.com/benibela/bigdecimalmath) | LCL-style LGPL with an explicit linking exception in the source; Free Pascal `objfpc` mode | Arbitrary-precision BCD floating point, arithmetic, rounding, square root, and power | Provides decimal multiprecision operations in an Object Pascal unit. |
| [DelphiBigNumbers](https://github.com/rvelthuis/DelphiBigNumbers) | BSD-2-Clause; Delphi-first | Arbitrary-precision integer, decimal, and rational types | Combines assembly optimizations with pure-Pascal equivalents. The author's notes also describe an FPC build using `PUREPASCAL` and small unit-name adjustments. |

The [DFF Library](https://www.delphiforfun.org/Programs/Library/Default.htm)
is another community-catalogued resource, with material on big floating-point
values, big integers, and astronomical calculations. Its
[community listing](https://github.com/juliomar/awesome-delphi#math) links to
the upstream collection.

## Related projects distributed elsewhere

| Project | License and compiler | Areas of strength | Notes |
| ------- | ------------------- | ---------- | ----------------- |
| [FPC NumLib](https://www.freepascal.org/daily/packages/numlib/numlib/index.html) | Included in the FPC distribution; package notices use the FPC modified-LGPL linking exception | Classic routines for determinants, eigenvalues, integration, ODEs, roots, linear systems, special functions, and splines | A long-standing part of the FPC ecosystem, derived from Eindhoven NUMLIB work. Its configurable `ArbFloat` and flat-array/pointer-overlay interfaces offer low-level control. The upstream source is on GitLab. |
| [DMath](https://www.unilim.fr/pages_perso/jean.debord/tpmath/tpmath.htm) | LGPL-2.0; Delphi, FPC, and Lazarus builds are listed by the project | Scientific routines including special functions, distributions, linear algebra, optimisation, integration/ODEs, FFT, random numbers, and regression | A broad scientific collection with an established history; LMath extends its procedural core for Free Pascal and Lazarus. |
| [JEDI Math](https://sourceforge.net/projects/jedimath/) | MPL-1.1; project lists Delphi, Kylix, FPC, and Lazarus | Matrices/vectors, regression, geometry, physics, equation rendering, and ray tracing | A community project spanning mathematical and graphical areas, including tools for physics and visualization. |
| [LMath](https://sourceforge.net/projects/lmath-library/) | Mostly LGPL-3.0; the `lmDSP` package is identified as GPL; Free Pascal/Lazarus | Numerical analysis, probabilities, matrices, optimisation, equations, integration, FFT, regression, statistics, graphics, and components | Source-only Pascal with Lazarus packages and no external library requirement. SourceForge lists version 0.6.1 and an update in October 2025; package-specific license notices identify the terms for each component. |
| [OptiVec](https://www.optivec.com/) | Commercial; compiler-specific Delphi products and a Lazarus/Free Pascal product for 64-bit Windows; 90-day trial | Vendor describes 4,000+ vector, matrix, and complex functions, plus statistics, FFT, fitting, interpolation, and matrix decompositions | A vendor-supported, performance-oriented engineering and scientific toolkit with hand-optimized routines. The vendor lists version 8.4.3. |
| [AMath and DAMath](https://www.wolfgang-ehrhardt.de/misc_en.html#amath) | Permissive terms stated in the source distribution; Delphi and FPC source | Elementary and special functions, distributions, quadrature, root finding, and complex functions | A specialist collection with function-level reference material and implementation notes. |
| [MtxVec Core Edition](https://www.dewresearch.com/products/mtxvec/core/) | Commercial; full-source Delphi edition, with separate C++/.NET products | Dense vector/matrix numerics, statistics, and signal processing | A supported commercial Delphi option; Core Edition can be built without external DLLs. |
| [ALGLIB for Delphi](https://www.alglib.net/download.php) | Free Delphi/FPC edition is for personal and academic use; commercial edition is available | Broad optimization, interpolation, linear algebra, FFT, statistics, and data-analysis algorithms | A wide algorithm catalog with Pascal interfaces to a C core; the free Delphi edition includes precompiled binaries. |

## Position

mathlib-fp is intended as a general-purpose numerical library for Free Pascal
with four deliberate characteristics: an MIT licence with no paid tier, a
complete implementation in Object Pascal source within this repository, no
mandatory third-party numerical runtime, and documentation and qualification
material organised as a learning path. It is designed as an FPC-first,
Lazarus-focused project. These describe mathlib-fp's approach; other projects
bring strengths in areas such as SIMD performance, multi-precision arithmetic,
array semantics, and Delphi support.

## Current limitations of mathlib-fp

For a balanced comparison, these are boundaries of the released v2.4.0 scope,
as recorded in the [capability inventory](../../reference/capabilities.md).
They describe what a user should not assume is included; they are not a
roadmap or a judgement about other libraries.

- **Compiler focus:** mathlib-fp targets Free Pascal 3.2.2+ in `objfpc` mode;
  Delphi compatibility is not claimed.
- **Execution backends:** the stable paths are portable and serial. There is
  no stable SIMD or thread-pool API, nor a GPU, distributed, or out-of-core
  backend.
- **Precision and algorithms:** typed dense kernels cover single and double
  real and complex values, while many higher-level workflows are double-only.
  The library does not provide arbitrary-precision number types. Some
  algorithms also have specific scope limits, such as full compact rather
  than truncated SVD, largest-magnitude partial eigensolvers, and dense-only
  optimisation.
- **Specialist workflows:** the stable catalogue does not include survival or
  factor analysis, robust covariance, advanced equiripple/IIR design, broader
  wavelet families, or general decomposition and model-graph persistence.
  Other listed projects cover some of these areas as part of their own focus.

## Engineering differentiators

mathlib-fp maintains several documentation and verification practices that are
part of its release process:

- versioned web and offline documentation built from the same reviewed sources
  as the repository Markdown;
- beginner recipes and domain learning routes that lead with the double-real,
  allocating path;
- a machine-readable capability inventory (`capabilities.json`) that drives a
  human-readable status page;
- a qualification programme with accuracy budgets, independent references,
  adversarial fixtures, and release-specific evidence reports;
- runnable documentation examples whose claimed output is checked.

These are described as characteristics of mathlib-fp; this page does not
assert that no other compared library does similar things.

## Comparison policy

This page is informational, not advertising. It is reviewed at least once per
major release and dated. Claims are based on upstream project pages, source
repositories, release archives, and license notices; they summarize what each
project documents and are not independent compiler tests or performance
benchmarks. A missing compatibility claim means it was not verified here, not
that the project cannot work on that compiler. Package-specific license
differences are called out where the upstream project documents them. No
library is declared superior on the basis of raw function counts.

## Sources

- FPC NumLib — [unit reference](https://www.freepascal.org/daily/packages/numlib/numlib/index.html) and [official FPC source tree](https://gitlab.com/freepascal.org/fpc/source/-/tree/main/packages/numlib).
- DMath and LMath — [DMath/TPMath project page](https://www.unilim.fr/pages_perso/jean.debord/tpmath/tpmath.htm), [DMath SourceForge metadata](https://sourceforge.net/projects/dmath/), and [LMath releases and README](https://sourceforge.net/projects/lmath-library/files/LMath/).
- GitHub projects — upstream repositories for [mrMath](https://github.com/mikerabat/mrmath), [numerik](https://github.com/ariaghora/numerik), [pas-core-math](https://github.com/joaopauloschuler/pas-core-math), [FastMath](https://github.com/neslib/FastMath), [CAI Neural API](https://github.com/joaopauloschuler/neural-api), [MPArith](https://github.com/JulStrat/MPArith), [TIntX](https://github.com/Xor-el/IntXLib4Pascal), [BigDecimalMath](https://github.com/benibela/bigdecimalmath), and [DelphiBigNumbers](https://github.com/rvelthuis/DelphiBigNumbers).
- Other upstream sources — [JEDI Math](https://sourceforge.net/projects/jedimath/), [OptiVec](https://www.optivec.com/), [AMath/DAMath](https://www.wolfgang-ehrhardt.de/misc_en.html#amath), [MtxVec Core Edition](https://www.dewresearch.com/products/mtxvec/core/), and [ALGLIB Free Edition](https://www.alglib.net/download.php).
- DFF Library — [community listing](https://github.com/juliomar/awesome-delphi#math) and [upstream collection](https://www.delphiforfun.org/Programs/Library/Default.htm).
- mathlib-fp — [repository](https://github.com/ikelaiah/mathlib-fp), [v2.4.0 release](https://github.com/ikelaiah/mathlib-fp/releases/tag/v2.4.0), and the in-repository [capability inventory](../../reference/capabilities.md).
