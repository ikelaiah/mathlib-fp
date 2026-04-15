# pascal-mathlibs

[![FPC](https://img.shields.io/badge/Free%20Pascal-3.2.2-blue.svg)](https://www.freepascal.org/)
[![Lazarus](https://img.shields.io/badge/Lazarus-3.6+-blue.svg)](https://www.lazarus-ide.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE.md)
[![Tests](https://img.shields.io/badge/Tests-Passing-brightgreen.svg)](tests/)
![Status](https://img.shields.io/badge/Status-Development-yellow.svg)

A monorepo of focused Free Pascal math libraries for scientific and engineering computing. No external dependencies.

> [!NOTE]
> This project was previously part of [tidykit-fp](https://github.com/ikelaiah/tidykit-fp). The math modules were separated into this standalone monorepo on 2026-04-14.
> This library is under active development and APIs may change without notice.

---

## Libraries

| Library | Description | Main Class |
| ------- | ----------- | ---------- |
| [MathBase](MathBase/) | Shared types, constants, special functions, and trigonometry | `TTrigKit` |
| [AlgebraLib](AlgebraLib/) | Dense matrix operations, decompositions, and linear solvers | `TMatrixKit` / `IMatrix` |
| [FinanceLib](FinanceLib/) | Time value of money, bonds, NPV/IRR, option pricing, ratio analysis | `TFinanceKit` |
| [EngineeringLib](EngineeringLib/) | Fluid dynamics, thermodynamics, signal processing, unit conversion | `TFluidDynamicsKit`, `TThermodynamicsKit`, `TSignalKit`, `TUnitConversionKit` |
| [StatsLib](StatsLib/) | Descriptive stats, hypothesis tests, correlation, bootstrap, non-parametric tests | `TStatsKit` |

---

## Repository Layout

```text
pascal-mathlibs/
│
├── README.md
├── CHANGELOG.md
├── LICENSE.md
│
├── src/                    ← all library units (add this single folder to -Fu)
│   ├── MathBase.MathConstants.pas
│   ├── MathBase.SharedTypes.pas
│   ├── MathBase.Precision.pas
│   ├── MathBase.Trigonometry.pas
│   ├── AlgebraLib.Matrices.pas
│   ├── AlgebraLib.Vectors.pas
│   ├── AlgebraLib.Determinants.pas
│   ├── FinanceLib.Interest.pas
│   ├── FinanceLib.Bonds.pas
│   ├── FinanceLib.NPV.pas
│   ├── EngineeringLib.FluidDynamics.pas
│   ├── EngineeringLib.Thermodynamics.pas
│   ├── EngineeringLib.Signal.pas
│   ├── EngineeringLib.UnitConversion.pas
│   ├── EngineeringLib.Velocity.pas
│   └── EngineeringLib.Pressure.pas
│   └── StatsLib.Stats.pas
│
├── MathBase/               ← README for the MathBase group
├── AlgebraLib/             ← README for the AlgebraLib group
├── FinanceLib/             ← README for the FinanceLib group
├── EngineeringLib/         ← README for the EngineeringLib group
├── StatsLib/               ← README for the StatsLib group
│
├── examples/               ← runnable example programs
│
└── tests/
    ├── TestMathBase.pas
    ├── TestAlgebraLib.pas
    ├── TestFinanceLib.pas
    ├── TestEngineeringLib.pas
    ├── TestEngineeringLib_FluidDynamics.pas
    ├── TestEngineeringLib_Thermodynamics.pas
    ├── TestEngineeringLib_Signal.pas
    ├── TestEngineeringLib_UnitConversion.pas
    └── TestStatsLib.pas
```

---

## Getting Started in 5 Minutes

### Step 1 — Clone

```bash
git clone https://github.com/ikelaiah/pascal-mathlibs
cd pascal-mathlibs
```

### Step 2 — Add the source path to your project

All units live in the `src/` folder. You only ever need to add one path.

#### Lazarus IDE

> Project → Project Options → Compiler Options → Paths → Other Unit Files (`-Fu`)

```text
../src
```

#### FPC command line

```bash
fpc -Fu../src my_program.lpr
```

### Step 3 — Use `{$mode objfpc}` in every source file

All units in this project are compiled in `objfpc` mode. Your program file must declare the same mode or the compiler will reject the syntax:

```pascal
{$mode objfpc}{$H+}   // put this at the very top, before the program/unit keyword
```

`{$H+}` enables long (AnsiString) strings, which is the standard FP default in Lazarus.

### Step 4 — Run an example

The [examples/](examples/) folder contains six ready-to-compile programs that cover every library:

| File | What it shows |
|------|---------------|
| [examples/01_stats_basics.lpr](examples/01_stats_basics.lpr) | Descriptive stats, percentiles, correlation, bootstrap CI |
| [examples/02_hypothesis_test.lpr](examples/02_hypothesis_test.lpr) | t-test, Mann-Whitney U, Wilcoxon, effect size |
| [examples/03_matrix_operations.lpr](examples/03_matrix_operations.lpr) | Matrix arithmetic, inverse, LU/QR decomposition |
| [examples/04_finance_npv_irr.lpr](examples/04_finance_npv_irr.lpr) | PV/FV, NPV/IRR, loan payment, amortization schedule |
| [examples/05_unit_conversion.lpr](examples/05_unit_conversion.lpr) | Length, mass, temperature, velocity, pressure, energy |
| [examples/06_fluid_dynamics.lpr](examples/06_fluid_dynamics.lpr) | Reynolds number, Bernoulli, head loss, aerodynamics |

Build and run example 5 (no physics knowledge required):

```bash
cd examples
fpc -Fu../src 05_unit_conversion.lpr
./05_unit_conversion
```

---

## Quick Start

Add `src/` to your project's search path (`-Fu../src`), then use the units directly:

```pascal
uses
  MathBase.SharedTypes,       // TDoubleArray, TDoublePair
  MathBase.MathConstants,     // MathPi, StandardGravity, …
  MathBase.Precision,         // GammaLn, NormalCDF, …
  MathBase.Trigonometry,      // TTrigKit
  AlgebraLib.Matrices,        // TMatrixKit, IMatrix
  FinanceLib.Interest,        // TFinanceKit
  EngineeringLib.FluidDynamics,   // TFluidDynamicsKit
  EngineeringLib.Thermodynamics,  // TThermodynamicsKit
  EngineeringLib.UnitConversion,  // TUnitConversionKit
  EngineeringLib.Signal,          // TSignalKit
  StatsLib.Stats;             // TStatsKit
```

Each library is independent (aside from MathBase, which all others depend on). Include only what you need.

### Example — Statistics

```pascal
uses StatsLib.Stats;

var
  Data: TDoubleArray;
  Stats: TDescriptiveStats;
begin
  Data := TDoubleArray.Create(4.5, 3.0, 5.0, 4.0, 4.8, 3.2, 4.5, 4.9);
  Stats := TStatsKit.Describe(Data);
  Writeln(Stats.ToString);
  Writeln('Pearson r = ', TStatsKit.PearsonCorrelation(Data, Data):0:4);
end.
```

### Example — Matrix Operations

```pascal
uses AlgebraLib.Matrices;

var
  A: IMatrix;
  LU: TLUDecomposition;
begin
  A  := TMatrixKit.FromArray([[3,1],[1,3]]);
  LU := A.LUDecompose;
  Writeln('Det = ', A.Determinant:0:4);
  Writeln('Rank = ', A.Rank);
end.
```

### Example — Finance

```pascal
uses FinanceLib.Interest;

var
  CashFlows: TDoubleArray;
begin
  CashFlows := TDoubleArray.Create(20000, 25000, 30000, 35000, 40000);
  Writeln('NPV  = ', TFinanceKit.NetPresentValue(100000, CashFlows, 0.10):0:2);
  Writeln('IRR  = ', TFinanceKit.InternalRateOfReturn(100000, CashFlows) * 100:0:2, '%');
end.
```

### Example — Engineering

```pascal
uses EngineeringLib.FluidDynamics, EngineeringLib.UnitConversion;

var
  Re, SpeedMph: Double;
begin
  Re       := TFluidDynamicsKit.ReynoldsNumber(997, 2.0, 0.05, 1.0e-3);
  SpeedMph := TUnitConversionKit.ConvertVelocity(2.0, vuMeterPerSecond, vuMilePerHour);
  Writeln('Re = ', Re:0:0, '  (', SpeedMph:0:2, ' mph)');
end.
```

---

## Dependency Graph

```text
MathBase  ←  AlgebraLib
          ←  FinanceLib
          ←  StatsLib
          ←  EngineeringLib  (independent of AlgebraLib, FinanceLib, StatsLib)
```

All libraries depend on **MathBase**. No library depends on another peer library.

---

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/ikelaiah/pascal-mathlibs
   ```

2. Add `src/` to your project's search path:
   - **Lazarus**: Other Unit Files → `../src`
   - **FPC CLI**: `fpc -Fu../src my_program.lpr`

3. No package manager or external dependencies required — only the Free Pascal RTL.

---

## System Requirements

- Free Pascal Compiler (FPC) 3.2.2+
- Lazarus 3.6+ (optional, for IDE support)
- Tested on Windows 11 and Ubuntu 24.04

---

## Testing

```bash
cd tests
./TestRunner.exe -a --format=plain
```

---

## Contributing

Contributions are welcome. Please open an issue before submitting a pull request for significant changes.

1. Fork the project
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes
4. Push and open a pull request

---

## License

MIT — see [LICENSE.md](LICENSE.md).

---

## Acknowledgments

- FPC Team for Free Pascal
- Original tidykit-fp contributors
