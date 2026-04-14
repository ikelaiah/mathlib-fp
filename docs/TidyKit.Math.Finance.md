# 💰 pascal-mathlibs.Finance: Financial Mathematics Library

The `TFinanceKit` class provides comprehensive financial calculations with configurable precision. This module is part of the [pascal-mathlibs.Math](pascal-mathlibs.Math.md) library.

## Table of Contents
- [Precision and Rounding](#precision-and-rounding)
- [Time Value of Money](#time-value-of-money)
- [Investment Analysis](#investment-analysis)
- [Depreciation](#depreciation)
- [Return Metrics](#return-metrics)
- [Modified Duration](#modified-duration)
- [Black-Scholes Option Pricing](#black-scholes-option-pricing)
- [Operating Leverage](#operating-leverage)
- [Best Practices](#best-practices)
- [Error Handling](#error-handling)
- [Examples](#examples)

## Precision and Rounding

All financial functions support an optional `ADecimals` parameter to control the number of decimal places in the result.

```pascal
// Default precision is 4 decimal places
Result := TFinanceKit.SomeFunction(Params);  // Returns result with 4 decimal places

// Custom precision
Result := TFinanceKit.SomeFunction(Params, 6);  // Returns result with 6 decimal places
```

### Default Precision
- All financial calculations default to 4 decimal places for consistency
- This provides sufficient precision for most financial calculations while avoiding floating-point comparison issues

### Custom Precision
- Each financial function accepts an optional `ADecimals` parameter
- Range: typically 0 to 10 decimal places
- Examples:
  - `ADecimals = 2`: For monetary values (e.g., $123.45)
  - `ADecimals = 4`: Default, suitable for most calculations
  - `ADecimals = 6`: For high-precision requirements

### Rounding Behavior
- Uses banker's rounding (symmetric arithmetic rounding)
- Implemented via `SimpleRoundTo` function
- Ensures consistent results across calculations

## Time Value of Money

```pascal
uses pascal-mathlibs.Math.Finance;

// Present Value with default 4 decimals
PV := TFinanceKit.PresentValue(FutureValue, Rate, Periods);

// Present Value with 6 decimal precision
PV := TFinanceKit.PresentValue(FutureValue, Rate, Periods, 6);

// Future Value with custom precision
FV := TFinanceKit.FutureValue(PresentValue, Rate, Periods, 3);

// Payment calculation
PMT := TFinanceKit.Payment(PresentValue, Rate, Periods);
PMT := TFinanceKit.Payment(PresentValue, Rate, Periods, 2);  // 2 decimal places
```

## Investment Analysis

```pascal
var
  CashFlows: TDoubleArray;
begin
  CashFlows := TDoubleArray.Create(100, 200, 300);
  
  // NPV with default precision (4 decimals)
  NPV := TFinanceKit.NetPresentValue(InitialInvestment, CashFlows, Rate);
  
  // NPV with 6 decimal precision
  NPV := TFinanceKit.NetPresentValue(InitialInvestment, CashFlows, Rate, 6);
  
  // IRR with custom precision
  IRR := TFinanceKit.InternalRateOfReturn(InitialInvestment, CashFlows, 3);
end;
```

## Depreciation

```pascal
// Straight-line depreciation with default precision
SLD := TFinanceKit.StraightLineDepreciation(Cost, Salvage, Life);

// Declining balance depreciation with 3 decimal precision
DDB := TFinanceKit.DecliningBalanceDepreciation(Cost, Salvage, Life, Period, 3);

// Sum-of-years-digits depreciation
SOYD := TFinanceKit.SumOfYearsDigitsDepreciation(Cost, Salvage, Life, Period);
```

## Return Metrics

```pascal
// ROI with default precision
ROI := TFinanceKit.ReturnOnInvestment(Gain, Cost);

// ROE with 5 decimal precision
ROE := TFinanceKit.ReturnOnEquity(NetIncome, ShareholdersEquity, 5);

// ROIC (Return on Invested Capital)
ROIC := TFinanceKit.ReturnOnInvestedCapital(NOPAT, InvestedCapital);
```

## Modified Duration

```pascal
// Modified Duration calculation with default precision (4 decimals)
// For a 5-year bond with 6% annual coupon, 5% yield, semi-annual payments
// Expected value: 4.3009
ModDur := TFinanceKit.ModifiedDuration(
  1000.0,  // Face value
  0.06,    // Coupon rate (6%)
  0.05,    // Yield rate (5%)
  2,       // Periods per year (semi-annual)
  5        // Years to maturity
);
```

## Black-Scholes Option Pricing

```pascal
// Black-Scholes calculation with default precision (4 decimals)
// For a stock with:
// - Spot price: 100.0
// - Strike price: 100.0
// - Risk-free rate: 5%
// - Volatility: 20%
// - Time to maturity: 1 year
// Expected values:
// - Call option: 10.4506
// - Put option: 5.5723
CallPrice := TFinanceKit.BlackScholes(
  100.0,   // Spot price
  100.0,   // Strike price
  0.05,    // Risk-free rate (5%)
  0.20,    // Volatility (20%)
  1.0,     // Time to maturity (1 year)
  otCall   // Option type
);

PutPrice := TFinanceKit.BlackScholes(
  100.0,   // Spot price
  100.0,   // Strike price
  0.05,    // Risk-free rate (5%)
  0.20,    // Volatility (20%)
  1.0,     // Time to maturity (1 year)
  otPut    // Option type
);
```

## Operating Leverage

```pascal
// Operating Leverage calculation with default precision (4 decimals)
// For a business with:
// - Quantity: 10,000 units
// - Price per unit: $50
// - Variable cost per unit: $30
// - Fixed costs: $100,000
// Expected values:
// - DOL: 2.0000
// - Break-even point: 5,000 units
Leverage := TFinanceKit.OperatingLeverage(
  10000.0,  // Quantity
  50.0,     // Price per unit
  30.0,     // Variable cost per unit
  100000.0  // Fixed costs
);

// The Degree of Operating Leverage (DOL) is calculated as:
// DOL = (Q × CM) / EBIT
// where:
// Q = Quantity
// CM = Contribution Margin (Price - Variable Cost)
// EBIT = Earnings Before Interest and Taxes
//      = Q × CM - Fixed Costs
```

## Best Practices

1. Use default precision (4 decimals) unless specific requirements exist
2. For monetary display, round to 2 decimals
3. For rate calculations, consider using 4-6 decimals
4. For internal calculations, use higher precision (6+ decimals)
5. Always use the same precision when comparing values

## Error Handling

The `TFinanceKit` class includes comprehensive error checking:

```pascal
try
  IRR := TFinanceKit.InternalRateOfReturn(InitialInvestment, CashFlows);
except
  on E: EFinanceError do
    // Handle finance-specific errors (e.g., convergence failures)
end;
```

Common errors include:
- Negative rates where positive rates are required
- Negative periods
- IRR convergence failures
- Invalid parameters (e.g., negative life for depreciation)
- Division by zero in various calculations

## Examples

### Time Value of Money Calculation

```pascal
var
  PV, FV, Rate: Double;
  Periods: Integer;
begin
  // Calculate present value of $10,000 after 5 years at 8% annual interest
  FV := 10000;
  Rate := 0.08;
  Periods := 5;
  
  PV := TFinanceKit.PresentValue(FV, Rate, Periods);
  WriteLn('Present Value: $', PV:0:2);  // $6805.83
  
  // Calculate payment for a $200,000 mortgage at 4.5% for 30 years
  PV := 200000;
  Rate := 0.045;
  Periods := 30;
  
  PMT := TFinanceKit.Payment(PV, Rate, Periods, 2);
  WriteLn('Monthly Payment: $', (PMT/12):0:2);  // $1013.37
end;
```

### Investment Analysis

```pascal
var
  InitialInvestment: Double;
  CashFlows: TDoubleArray;
  NPV, IRR: Double;
begin
  // Analyze an investment with $5000 initial cost and expected returns
  InitialInvestment := 5000;
  CashFlows := TDoubleArray.Create(1000, 1500, 2000, 2500);
  
  // Calculate NPV at 10% discount rate
  NPV := TFinanceKit.NetPresentValue(InitialInvestment, CashFlows, 0.10);
  WriteLn('NPV: $', NPV:0:2);
  
  // Calculate IRR
  IRR := TFinanceKit.InternalRateOfReturn(InitialInvestment, CashFlows);
  WriteLn('IRR: ', (IRR*100):0:2, '%');
  
  // Interpretation
  if NPV > 0 then
    WriteLn('Investment is profitable at 10% discount rate')
  else
    WriteLn('Investment is not profitable at 10% discount rate');
    
  WriteLn('Break-even discount rate is ', (IRR*100):0:2, '%');
end;
``` 