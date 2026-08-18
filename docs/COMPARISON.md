# Choosing a Pascal numerical library

This page is an informational map of Pascal numerical libraries for someone
choosing a foundation for Free Pascal work. It uses only facts verified from
upstream projects and this repository; see the comparison policy below.

| Library | Status/licence | Native Pascal? | Scope | Notes |
| ------- | -------------- | -------------- | ----- | ----- |
| FPC NumLib | Bundled with FPC; FPC RTL licence; essentially unchanged since 2000 | Yes — Pascal source | Units for determinants, eigenvalues, integration, ODEs, roots, linear systems, special functions, and splines | Port of the 1986–2000 NUMLIB library (Eindhoven); `ArbFloat` configurable types; flat-array pointer-overlay API |
| DMath | Jean Debord; v0.90 (Dec 2012); LGPL v2 | Yes — Delphi/FPC Pascal | Special functions, distributions, linear algebra, optimisation, integration/ODEs, FFT, RNG, regression/PCA, and expression parsing | Broad scope; last release v0.90 (Dec 2012); continued by LMath |
| LMath | FPC/Lazarus continuation of DMath; LGPL v3; last update 2025-10 | Yes — FPC/Lazarus Pascal | Same procedural core as DMath | SourceForge `lmath-library`; Lazarus packages and GUI demos |
| MtxVec | Dew Research; commercial | Core Edition is full-source Pascal; Delphi/C++ Builder/.NET | Dense vector and matrix numerics | Performance paths include MKL and assembly; add-ons include Stats, DSP, and Data Miner |
| ALGLIB for Delphi | Free edition licensed for personal/academic use; commercial use paid | Pascal wrapper around a C core; FPC-compatible | LP/QP/SOCP/QCQP/NLP/MINLP, global and derivative-free optimisation, 1–3D interpolation, dense/sparse EVD/SVD, FFT, statistics, and decision forests | Broad numerical and optimisation coverage |
| AMath/DAMath + MPArith | Wolfgang Ehrhardt; zlib licence | Yes — Delphi + FPC Pascal | Elementary and special functions (Bessel, elliptic, hypergeometric, zeta/polylog, distributions), quadrature, multiprecision | Quadpack and double-exponential quadrature; reference manual includes implementation notes and cited sources |
| mrMath | Apache-2.0; active in 2026 | Yes — Delphi + FPC Pascal | Dense LU/QR/Cholesky/SVD, PCA/t-SNE/ICA/NNMF, wavelets | ASM/AVX/FMA kernels; multithreading |
| numerik | MIT; last updated 2021 | Yes — FPC/Lazarus Pascal | NumPy-like `TMultiArray` with broadcasting and slicing | Requires external OpenBLAS/LAPACK libraries |
| FastMath | BSD; Delphi-only | Yes — Delphi Pascal (SIMD assembly) | 2-D/3-D/4-D vectors and matrices for games/graphics; single precision | Designed for graphics workloads |
| mathlib-fp | MIT; native Free Pascal | Yes — complete portable Object Pascal | 13 focused domains covering algebra, probability, statistics, engineering/DSP, numerics, optimisation, time series, machine learning, finance, geometry, and interchange | No mandatory third-party numerical runtime; versioned web/offline documentation; beginner recipes; machine-readable capability inventory; qualification programme |

## Position

mathlib-fp is intended as a general-purpose numerical library for Free Pascal
with four deliberate characteristics: an MIT licence with no paid tier, a
complete implementation in Object Pascal source within this repository, no
mandatory third-party numerical runtime, and documentation and qualification
material organised as a learning path. These characteristics are described for
mathlib-fp itself; this page makes no claim that they are unique or that any
other library lacks them.

## Known current gaps

The [capability inventory](CAPABILITIES.md) is the authority for what
mathlib-fp does not yet support. The main gaps and their roadmap destinations
are:

- **Special-function families** — Bessel, elliptic, and exponential-integral
  families are unsupported; the destination is the
  [2.1 Special Functions II gate](ROADMAP.md#21-special-functions-ii).
- **Advanced spectral families** — nonsymmetric, generalised, polynomial,
  Schur, shift-invert, and interior-target eigensystems are deferred; the
  destination is the
  [2.2 spectral algebra gate](ROADMAP.md#22-nonsymmetric-and-generalised-spectral-algebra).
- **Stiff and implicit ODEs** — the current ODE path is explicit and non-stiff;
  the destination is the
  [2.3 stiff and implicit ODEs gate](ROADMAP.md#23-stiff-and-implicit-odes).
- **Advanced sparse direct algorithms** — no fill-reducing symbolic ordering,
  multifrontal/supernodal, distributed, out-of-core, or GPU path exists; the
  destination is the [2.4 Sparse Direct II gate](ROADMAP.md#24-sparse-direct-ii).
- **Parallel/SIMD dispatch and advanced iterative variants** — no stable
  thread-pool or vector-intrinsic API and no block/flexible Krylov or
  multigrid; the destination is the
  [performance acceleration track](ROADMAP.md#performance-acceleration-track).
- **Advanced DSP design and wavelets** — equiripple, advanced IIR families,
  and broader wavelets are conditional; the destination is the
  [Signal Processing II lane](ROADMAP.md#signal-processing-ii).
- **Conditional statistics and data science** — survival/factor analysis,
  robust covariance, GLMs, boosting, and broader forecasting are not
  activated; the destination is the
  [Statistics II](ROADMAP.md#statistics-ii) and
  [Data Analysis II](ROADMAP.md#data-analysis-ii) lanes.
- **General model/decomposition persistence** — only selected model adapters
  are stable; the destination is the
  [Persistence and interchange II lane](ROADMAP.md#persistence-and-interchange-ii).
- **Global and discrete optimisation** — no reproducible global-optimisation
  baseline and no committed MILP/MINLP capability; the destination is the
  [Global and discrete optimisation lane](ROADMAP.md#global-and-discrete-optimisation).

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
major release. Claims are linked to evidence where practical, unknown facts
are distinguished from unsupported capabilities, and no library is declared
superior on the basis of raw function counts.

## Sources

- FPC NumLib — [FPC NumLib unit reference](https://www.freepascal.org/daily/packages/numlib/numlib/index.html).
- DMath — [DMath/TPMath page](https://www.unilim.fr/pages_perso/jean.debord/tpmath/tpmath.htm).
- LMath — [SourceForge LMath project](https://sourceforge.net/projects/lmath-library/files/LMath/).
- MtxVec — Dew Research.
- ALGLIB for Delphi — ALGLIB Project.
- AMath/DAMath + MPArith — Wolfgang Ehrhardt.
- mrMath — [github.com/mikerabat/mrmath](https://github.com/mikerabat/mrmath).
- numerik — [github.com/ariaghora/numerik](https://github.com/ariaghora/numerik).
- FastMath — [github.com/neslib/FastMath](https://github.com/neslib/FastMath).
- mathlib-fp — [github.com/ikelaiah/mathlib-fp](https://github.com/ikelaiah/mathlib-fp).

URLs that are not already present in this repository's documentation or the
verified fact set are deliberately omitted rather than invented.
