# pascal-mathlibs

A collection of Free Pascal mathematics libraries organised as a monorepo.

## Libraries

| Library | Description | Depends on |
|---------|-------------|------------|
| [MathBase](MathBase.md) | Shared types, constants, precision functions, and trigonometry | — |
| [AlgebraLib](AlgebraLib.md) | Dense matrix ops, decompositions, iterative solvers, vectors | MathBase |
| [FinanceLib](FinanceLib.md) | Time value of money, bonds, NPV/IRR, options, ratios, risk metrics | MathBase |
| [StatsLib](StatsLib.md) | Descriptive stats, hypothesis testing, correlation, bootstrap | MathBase |
| [EngineeringLib](EngineeringLib.md) | Fluid dynamics, thermodynamics, signal processing (FFT, FIR), unit conversion | MathBase |
| [NumericsLib](NumericsLib.md) | Root finding, numerical integration, ODE solvers, interpolation | MathBase |

## Dependency Graph

```text
MathBase
├── AlgebraLib
├── FinanceLib
├── StatsLib
├── EngineeringLib
└── NumericsLib
```

## Common Base Types

All libraries share the types defined in `MathBase.SharedTypes`:

```pascal
TIntegerArray  = array of Integer;
TDoubleArray   = array of Double;
TSingleArray   = array of Single;
TExtendedArray = array of Extended;
TDoublePair    = record Lower, Upper: Double; end;
```

## Design Principles

- All kit classes (`TFinanceKit`, `TStatsKit`, `TMatrixKit`, `TNumericsKit`, etc.) use **static class methods** — no instance required.
- Operations on collections take `TDoubleArray` as input.
- An optional `ADecimals` parameter (default `4`) is available on most scalar-returning methods to control rounding.
- Each library raises its own typed exception (`EFinanceError`, `EStatsError`, `EMatrixError`, `EInvalidArgument`) for invalid inputs.
