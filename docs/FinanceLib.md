# FinanceLib

Financial mathematics domain covering time value of money, bonds, NPV/IRR,
depreciation, option pricing, ratio analysis, and risk metrics.

Depends on: **MathBase**

## Units

| Unit | File | Purpose |
|------|------|---------|
| `FinanceLib.Interest` | [FinanceLib.Interest.pas](../src/FinanceLib.Interest.pas) | Core implementation — all logic lives here (`TFinanceKit`) |
| `FinanceLib.Bonds` | [FinanceLib.Bonds.pas](../src/FinanceLib.Bonds.pas) | Focused bond entry unit; exports `TBondKit`, `EBondError`, `TBondPayment`, and `TBondSchedule` aliases |
| `FinanceLib.NPV` | [FinanceLib.NPV.pas](../src/FinanceLib.NPV.pas) | Focused NPV/IRR entry unit; exports `TNPVKit`, `ENPVError`, and `TNPVCashFlows` aliases |

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
| `TFinanceKit.TAmortizationPayment` | `PaymentNumber`, `Payment`, `Principal`, `Interest`, `RemainingBalance` |

The amortization types are nested in `TFinanceKit` and are named by qualifying
them with the class:

```pascal
var
  Payment: TFinanceKit.TAmortizationPayment;
  Schedule: TFinanceKit.TAmortizationArray;
```

Callers using `FinanceLib.Bonds` can name the same types as `TBondPayment` and
`TBondSchedule`.

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
PMT := TFinanceKit.Payment(200000, 0.045/12, 360); // ≈ 1013.3706
```

### Net Present Value & IRR

| Method | Description |
|--------|-------------|
| `NetPresentValue(InitialInvestment, CashFlows, Rate [, Decimals])` | NPV = −I + Σ CFt / (1+r)ᵗ |
| `InternalRateOfReturn(InitialInvestment, CashFlows [, Decimals])` | Rate where NPV = 0; bracketed bisection supports positive and negative IRRs greater than −100% |

```pascal
CashFlows := TDoubleArray.Create(20000, 25000, 30000, 35000, 40000);
NPV := TFinanceKit.NetPresentValue(100000, CashFlows, 0.10);
// NPV ≈ 10124.7431; IRR ≈ 13.4531%
IRR := TFinanceKit.InternalRateOfReturn(100000, CashFlows);
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
| `AmortizationSchedule(LoanAmount, Rate, NumberOfPayments [, Decimals])` | Full `TFinanceKit.TAmortizationArray` table |

```pascal
// $1,000 bond, 6% coupon (semi-annual), 4.5% YTM, 10 years
Price := TFinanceKit.BondPrice(1000, 0.06, 0.045, 2, 10); // ≈ 1119.7278
```

### Option Pricing (Black-Scholes)

| Method | Description |
|--------|-------------|
| `BlackScholes(SpotPrice, StrikePrice, RiskFreeRate, Volatility, TimeToMaturity, OptionType [, Decimals])` | European call or put price |

### Investment & Return Metrics

| Method | Formula | Description |
|--------|---------|-------------|
| `ReturnOnInvestment(Gain, Cost [, Decimals])` | (Gain − Cost) / Cost | ROI as decimal |
| `ReturnOnEquity(NetIncome, ShareholdersEquity [, Decimals])` | Net Income / Equity | ROE as decimal |
| `WACC(EquityValue, DebtValue, CostOfEquity, CostOfDebt, TaxRate [, Decimals])` | (E/V × Re) + (D/V × Rd × (1−T)) | Weighted-average cost of capital |
| `CAPM(RiskFreeRate, Beta, ExpectedMarketReturn [, Decimals])` | r = rf + β(rm − rf) | Expected return |
| `GordonGrowthModel(CurrentDividend, GrowthRate, RequiredReturn [, Decimals])` | P = D₀(1+g) / (r − g) | Stock intrinsic value |

### Financial Ratio Analysis

| Method | Returns |
|--------|---------|
| `WorkingCapitalRatios(CurrentAssets, CurrentLiabilities, Inventory, Cash, Sales [, Decimals])` | `TWorkingCapitalRatios` |
| `LeverageRatios(TotalDebt, TotalAssets, TotalEquity, EBIT, InterestExpense [, Decimals])` | `TLeverageRatios` |
| `ProfitabilityRatios(Revenue, COGS, EBIT, NetIncome, TotalAssets, CurrentLiabilities [, Decimals])` | `TProfitabilityRatios` |
| `DuPontAnalysis(NetIncome, Sales, TotalAssets, TotalEquity [, Decimals])` | `TDuPontAnalysis` |
| `OperatingLeverage(Quantity, PricePerUnit, VariableCostPerUnit, FixedCosts [, Decimals])` | `TOperatingLeverage` |
| `BreakEvenUnits(FixedCosts, UnitPrice, UnitVariableCost [, Decimals])` | Break-even sales volume |
| `BreakEvenRevenue(FixedCosts, PricePerUnit, VariableCostPerUnit [, Decimals])` | Break-even revenue |

### Risk-Adjusted Performance

| Method | Returns |
|--------|---------|
| `RiskMetrics(PortfolioReturn, RiskFreeRate, MarketReturn, Beta, PortfolioStdDev, BenchmarkReturn, TrackingError [, Decimals])` | `TRiskMetrics` |

---

## Unit Aliases

`FinanceLib.Bonds` and `FinanceLib.NPV` are intentionally small focused entry
units. The formulas remain in `FinanceLib.Interest`; the focused units export
aliases and do not maintain duplicate implementations:

```pascal
// In FinanceLib.Bonds:
TBondKit      = TFinanceKit;
EBondError    = EFinanceError;
TBondPayment  = TFinanceKit.TAmortizationPayment;
TBondSchedule = TFinanceKit.TAmortizationArray;

// In FinanceLib.NPV:
TNPVKit       = TFinanceKit;
ENPVError     = EFinanceError;
TNPVCashFlows = TDoubleArray;
```

Because `TBondKit` and `TNPVKit` are aliases of the complete `TFinanceKit`
class, all its methods remain technically accessible. The intended domain APIs
are `BondPrice`, `BondYieldToMaturity`, `ModifiedDuration`, and
`AmortizationSchedule` through `TBondKit`, and `NetPresentValue` and
`InternalRateOfReturn` through `TNPVKit`.

These examples need only the focused unit in their `uses` clause:

```pascal
uses FinanceLib.Bonds;

var
  Schedule: TBondSchedule;
begin
  Schedule := TBondKit.AmortizationSchedule(1000, 0.01, 3, 2);
end;
```

```pascal
uses FinanceLib.NPV;

var
  CashFlows: TNPVCashFlows;
  Rate: Double;
begin
  CashFlows := TNPVCashFlows.Create(120);
  Rate := TNPVKit.InternalRateOfReturn(100, CashFlows); // 0.2000
end;
```

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
- The optional `ADecimals` parameter (default `4`) uses `SimpleRoundTo`, which
  rounds halfway values away from zero. Structured result fields and
  amortization schedule amounts use the same requested precision. NPV sums
  unrounded discounted cash flows and rounds the final result.
- Undefined ratios raise `EFinanceError` instead of returning a fabricated
  zero. This includes zero divisors such as current liabilities, working
  capital, interest expense, portfolio standard deviation, beta, tracking
  error, EBIT, revenue, assets, equity, or capital employed, as applicable.
- `InternalRateOfReturn` requires a positive initial investment and at least
  one positive future cash flow. It raises `EFinanceError` when it cannot
  bracket or converge on a rate. Cash-flow patterns with multiple mathematical
  IRRs are inherently ambiguous; the method returns the root within the
  sign-changing bracket it establishes.
- Other invalid inputs—including negative periods, an empty cash-flow array,
  or non-convergence of an iterative method—also raise `EFinanceError`.
