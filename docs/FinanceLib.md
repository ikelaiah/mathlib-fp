# FinanceLib

Financial mathematics library covering time value of money, bonds, NPV/IRR, depreciation, option pricing, ratio analysis, and risk metrics.

Depends on: **MathBase**

## Units

| Unit | File | Purpose |
|------|------|---------|
| `FinanceLib.Interest` | [FinanceLib.Interest.pas](../src/FinanceLib.Interest.pas) | Core implementation — all logic lives here (`TFinanceKit`) |
| `FinanceLib.Bonds` | [FinanceLib.Bonds.pas](../src/FinanceLib.Bonds.pas) | Re-exports bond-oriented aliases (`TBondKit`, `EBondError`) |
| `FinanceLib.NPV` | [FinanceLib.NPV.pas](../src/FinanceLib.NPV.pas) | Re-exports NPV/capital-budgeting aliases (`TNPVKit`, `ENPVError`) |

---

## Core Types

### Exception

```pascal
EFinanceError = class(Exception);
```

### Option Type

```pascal
TOptionType = (otCall, otPut);
```

Used by the Black-Scholes option pricing methods.

### Result Records

| Record | Fields |
|--------|--------|
| `TWorkingCapitalRatios` | `CurrentRatio`, `QuickRatio`, `CashRatio`, `WorkingCapitalTurnover` |
| `TLeverageRatios` | `DebtRatio`, `DebtToEquityRatio`, `EquityMultiplier`, `TimesInterestEarned` |
| `TRiskMetrics` | `SharpeRatio`, `TreynorRatio`, `JensenAlpha`, `InformationRatio` |
| `TDuPontAnalysis` | `ProfitMargin`, `AssetTurnover`, `EquityMultiplier`, `ROE` |
| `TOperatingLeverage` | `DOL`, `BreakEvenPoint`, `OperatingLeverage` |
| `TProfitabilityRatios` | `GrossMargin`, `OperatingMargin`, `NetProfitMargin`, `ROA`, `ROCE` |
| `TAmortizationPayment` | `PaymentNumber`, `Payment`, `Principal`, `Interest`, `RemainingBalance` |

`TAmortizationArray = array of TAmortizationPayment`

---

## TFinanceKit — Static Methods

All methods are `class ... static` — no instance required.

### Time Value of Money

| Method | Formula | Returns |
|--------|---------|---------|
| `PresentValue(FV, Rate, Periods [, Decimals])` | PV = FV / (1 + r)ⁿ | Present value of a future cash flow |
| `FutureValue(PV, Rate, Periods [, Decimals])` | FV = PV × (1 + r)ⁿ | Future value of a present sum |
| `CompoundInterest(Principal, Rate, Periods [, Decimals])` | CI = P × ((1 + r)ⁿ − 1) | Interest earned (excluding principal) |
| `Payment(PV, Rate, Periods [, Decimals])` | PMT = PV × r × (1+r)ⁿ / ((1+r)ⁿ − 1) | Periodic loan/annuity payment |
| `EffectiveAnnualRate(NominalRate, CompoundingsPerYear [, Decimals])` | EAR = (1 + r/m)ᵐ − 1 | Effective annual rate |

```pascal
// $1,000 received in 5 years at 8%
PV := TFinanceKit.PresentValue(1000, 0.08, 5);   // ≈ 680.5832

// Monthly payment on a $200,000 30-year mortgage at 4.5% p.a.
PMT := TFinanceKit.Payment(200000, 0.045/12, 360); // ≈ 1013.3721
```

### Net Present Value & IRR

| Method | Description |
|--------|-------------|
| `NetPresentValue(InitialInvestment, CashFlows, Rate [, Decimals])` | NPV = −I + Σ CFt / (1+r)ᵗ |
| `InternalRateOfReturn(InitialInvestment, CashFlows [, Decimals])` | Rate where NPV = 0; secant method with dampening |

```pascal
CashFlows := TDoubleArray.Create(20000, 25000, 30000, 35000, 40000);
NPV := TFinanceKit.NetPresentValue(100000, CashFlows, 0.10);
IRR := TFinanceKit.InternalRateOfReturn(100000, CashFlows); // ≈ 17.97%
```

### Depreciation

| Method | Formula | Notes |
|--------|---------|-------|
| `StraightLineDepreciation(Cost, Salvage, Life [, Decimals])` | (Cost − Salvage) / Life | Constant annual charge |
| `DecliningBalanceDepreciation(Cost, Salvage, Life, Period [, Decimals])` | Cost × Rate × (1 − Rate)^(period−1) | Rate = 2/Life; accelerated, front-loads expense |

### Bond Calculations

| Method | Description |
|--------|-------------|
| `BondPrice(FaceValue, CouponRate, YieldRate, PeriodsPerYear, YearsToMaturity [, Decimals])` | Fair price from cash flow discounting |
| `BondYieldToMaturity(BondPrice, FaceValue, CouponRate, PeriodsPerYear, YearsToMaturity [, Decimals])` | YTM via Newton-Raphson |
| `ModifiedDuration(FaceValue, CouponRate, YieldRate, PeriodsPerYear, YearsToMaturity [, Decimals])` | Price sensitivity to yield change |
| `AmortizationSchedule(LoanAmount, Rate, NumberOfPayments [, Decimals])` | Full `TAmortizationArray` table |

```pascal
// $1,000 bond, 6% coupon (semi-annual), 4.5% YTM, 10 years
Price := TFinanceKit.BondPrice(1000, 0.06, 0.045, 2, 10); // ≈ 1123.2526
```

### Option Pricing (Black-Scholes)

| Method | Description |
|--------|-------------|
| `BlackScholes(SpotPrice, StrikePrice, RiskFreeRate, Volatility, TimeToExpiry, OptionType [, Decimals])` | European call or put price |

### Investment & Return Metrics

| Method | Formula | Description |
|--------|---------|-------------|
| `ReturnOnInvestment(Gain, Cost [, Decimals])` | (Gain − Cost) / Cost | ROI as decimal |
| `ReturnOnEquity(NetIncome, ShareholdersEquity [, Decimals])` | Net Income / Equity | ROE as decimal |
| `WACC(...)` | Weighted-average cost of capital | |
| `CAPM(RiskFreeRate, Beta, MarketReturn [, Decimals])` | r = rf + β(rm − rf) | Expected return |
| `GordonGrowthModel(Dividend, GrowthRate, DiscountRate [, Decimals])` | P = D / (r − g) | Stock intrinsic value |

### Financial Ratio Analysis

| Method | Returns |
|--------|---------|
| `WorkingCapitalRatios(CurrentAssets, Inventory, Cash, CurrentLiabilities, Sales [, Decimals])` | `TWorkingCapitalRatios` |
| `LeverageRatios(TotalDebt, TotalAssets, TotalEquity, EBIT, InterestExpense [, Decimals])` | `TLeverageRatios` |
| `ProfitabilityRatios(Revenue, COGS, EBIT, NetIncome, TotalAssets, CurrentLiabilities [, Decimals])` | `TProfitabilityRatios` |
| `DuPontAnalysis(NetIncome, Sales, TotalAssets, TotalEquity [, Decimals])` | `TDuPontAnalysis` |
| `OperatingLeverage(SalesVolume, UnitPrice, UnitVariableCost, FixedCosts [, Decimals])` | `TOperatingLeverage` |
| `BreakEvenUnits(FixedCosts, UnitPrice, UnitVariableCost [, Decimals])` | Break-even sales volume |
| `BreakEvenRevenue(FixedCosts, ContributionMarginRatio [, Decimals])` | Break-even revenue |

### Risk-Adjusted Performance

| Method | Returns |
|--------|---------|
| `RiskMetrics(PortfolioReturn, RiskFreeRate, PortfolioStdDev, Beta, MarketReturn, BenchmarkReturn, TrackingError [, Decimals])` | `TRiskMetrics` |

---

## Unit Aliases

`FinanceLib.Bonds` and `FinanceLib.NPV` re-export `TFinanceKit` under domain-specific names:

```pascal
// In FinanceLib.Bonds:
TBondKit   = TFinanceKit;
EBondError = EFinanceError;

// In FinanceLib.NPV:
TNPVKit   = TFinanceKit;
ENPVError = EFinanceError;
```

Add the focused unit to your `uses` clause to signal intent without losing any functionality.

---

## Quick Start

```pascal
uses FinanceLib.Interest;

var
  Schedule: TFinanceKit.TAmortizationArray;
  I: Integer;
begin
  Schedule := TFinanceKit.AmortizationSchedule(200000, 0.045/12, 360);
  for I := 0 to High(Schedule) do
    Writeln(Schedule[I].PaymentNumber, #9,
            Schedule[I].Principal:0:2, #9,
            Schedule[I].Interest:0:2, #9,
            Schedule[I].RemainingBalance:0:2);
end.
```

## Design Notes

- All rates are decimals (e.g. `0.05` for 5 %).
- Time is measured in **periods** or **years** (`Integer`/`Double`) — no `TDateTime`.
- Most calculations use **discrete period compounding**; Black-Scholes uses **continuous compounding**.
- The optional `ADecimals` parameter (default `4`) controls rounding of the returned value.
- `EFinanceError` is raised for invalid inputs (negative periods, empty cash-flow arrays, non-convergence of iterative methods).
