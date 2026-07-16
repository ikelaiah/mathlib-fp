unit FinanceLib.Interest;

{-----------------------------------------------------------------------------
 FinanceLib.Interest

 A library for financial mathematics and analysis in Free Pascal
 
 This unit provides:
 - Time Value of Money (PV, FV, Payment, NPV, IRR, Compound Interest, Effective Annual Rate)
 - Loan Amortization Schedule generation
 - Depreciation methods (Straight-Line, Declining Balance)
 - Investment appraisal (ROI, ROE, Break-Even Analysis)
 - Bond calculations (Price, Yield to Maturity, Modified Duration)
 - Option pricing (Black-Scholes model for European options)
 - Financial ratio analysis (Working Capital, Leverage, Profitability, DuPont, Operating Leverage)
 - Risk-adjusted performance metrics (Sharpe Ratio, Treynor Ratio, Jensen's Alpha, Information Ratio)
 - Capital budgeting and cost of capital (WACC, CAPM)
 - Stock valuation (Gordon Growth Model)
 
 Design principles:
 - Static class methods for calculations
 - Uses TDoubleArray from MathBase.SharedTypes for cash flows and relevant data inputs
 - Time is handled via periods/years (Integer/Double), not TDateTime directly
 - Provides specific record types for structured analysis results (TWorkingCapitalRatios, TLeverageRatios, etc.)
 - Includes error handling using EFinanceError for common calculation issues
 - Relies on standard financial formulas and models
 - Most calculations use discrete period compounding; Black-Scholes uses continuous compounding
 - Provides comprehensive documentation for each function
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math, MathBase.SharedTypes, MathBase.Precision;

type
  { Exception class for financial operations }
  EFinanceError = class(Exception);

  { Option type for Black-Scholes model }
  TOptionType = (otCall, otPut);

  { Working Capital Ratios }
  TWorkingCapitalRatios = record
    CurrentRatio: Double;           // Current Assets / Current Liabilities
    QuickRatio: Double;             // (Current Assets - Inventory) / Current Liabilities
    CashRatio: Double;              // Cash / Current Liabilities
    WorkingCapitalTurnover: Double; // Sales / Working Capital
  end;

  { Financial Leverage Ratios }
  TLeverageRatios = record
    DebtRatio: Double;              // Total Debt / Total Assets
    DebtToEquityRatio: Double;      // Total Debt / Total Equity
    EquityMultiplier: Double;       // Total Assets / Total Equity
    TimesInterestEarned: Double;    // EBIT / Interest Expense
  end;

  { Risk Metrics }
  TRiskMetrics = record
    SharpeRatio: Double;      // (Portfolio Return - Risk Free Rate) / Portfolio Standard Deviation
    TreynorRatio: Double;     // (Portfolio Return - Risk Free Rate) / Portfolio Beta
    JensenAlpha: Double;      // Actual Return - CAPM Expected Return
    InformationRatio: Double; // (Portfolio Return - Benchmark Return) / Tracking Error
  end;

  { DuPont Analysis }
  TDuPontAnalysis = record
    ProfitMargin: Double;     // Net Income / Sales
    AssetTurnover: Double;    // Sales / Total Assets
    EquityMultiplier: Double; // Total Assets / Total Equity
    ROE: Double;              // Final ROE from DuPont Analysis
  end;

  { Operating Leverage Analysis }
  TOperatingLeverage = record
    DOL: Double;              // Degree of Operating Leverage
    BreakEvenPoint: Double;   // Break-even point in units
    OperatingLeverage: Double; // % Change in EBIT / % Change in Sales
  end;

  { Profitability Ratios }
  TProfitabilityRatios = record
    GrossMargin: Double;           // (Revenue - COGS) / Revenue
    OperatingMargin: Double;       // EBIT / Revenue
    NetProfitMargin: Double;       // Net Income / Revenue
    ROA: Double;                   // Net Income / Total Assets
    ROCE: Double;                  // EBIT / (Total Assets - Current Liabilities)
  end;

  { Financial calculations class }
  TFinanceKit = class
  private
    {
      @description Helper function for Black-Scholes calculations
      
      @usage Used internally by the Black-Scholes option pricing model to calculate
             the cumulative normal distribution function
      
      @param X The value at which to evaluate the standard normal CDF
      
      @returns The probability that a standard normal random variable is less than X
      
      @warning Uses polynomial approximation, so values in extreme tails 
               (beyond ±8) may have reduced accuracy
      
      @example
        var
          Probability: Double;
        begin
          Probability := CumulativeNormal(1.96);
          // Returns approximately 0.975
        end;
    }
    class function CumulativeNormal(const X: Double): Double; static;
  public
    {
      @description Present Value (PV) represents the current worth of a future sum of money.
                   Formula: PV = FV / (1 + r)^n
                   where:
                   - FV = Future Value
                   - r = Interest rate per period
                   - n = Number of periods
      
      @usage Use to calculate the present value of a single future cash flow
      
      @param AFutureValue The future cash flow amount
      @param ARate The interest/discount rate per period (e.g., 0.05 for 5%)
      @param APeriods The number of periods until the future cash flow
      @param ADecimals Number of decimal places to round to (default: 4)
      
      @returns The present value of the future cash flow, rounded to ADecimals places
      
      @references CFA Institute's Financial Mathematics
      
      @warning Raises EFinanceError if APeriods is negative.
               For very small rates (near zero), returns AFutureValue directly.
      
      @example
        var
          PV: Double;
        begin
          // Calculate the present value of $1000 received in 5 years at 8% annual interest
          PV := TFinanceKit.PresentValue(1000, 0.08, 5);
          // Returns approximately 680.5832
        end;
    }
    class function PresentValue(
      const AFutureValue, ARate: Double;
      const APeriods: Integer;
      const ADecimals: Integer = 4): Double; static;
    
    {
      @description Future Value represents the value of a present sum at a future date.
                   Formula: FV = PV * (1 + r)^n
                   where:
                   - PV = Present Value
                   - r = Interest rate per period
                   - n = Number of periods
      
      @usage Use to calculate how much a current investment will be worth in the future
      
      @param APresentValue The initial investment amount
      @param ARate The interest rate per period (e.g., 0.05 for 5%)
      @param APeriods The number of periods to project into the future
      @param ADecimals Number of decimal places to round to (default: 4)
      
      @returns The future value of the investment, rounded to ADecimals places
      
      @references CFA Institute's Financial Mathematics
      
      @example
        var
          FV: Double;
        begin
          // Calculate the future value of $1000 invested for 5 years at 8% annual interest
          FV := TFinanceKit.FutureValue(1000, 0.08, 5);
          // Returns approximately 1469.3282
        end;
    }
    class function FutureValue(
      const APresentValue, ARate: Double;
      const APeriods: Integer;
      const ADecimals: Integer = 4): Double; static;
    
    {
      @description Compound Interest is the interest earned on both initial principal and accumulated interest.
                   Formula: CI = P * ((1 + r)^n - 1)
                   where:
                   - P = Principal amount
                   - r = Interest rate per period
                   - n = Number of periods
      
      @usage Use to calculate the total interest earned on an investment over time
      
      @param APrincipal The initial principal amount
      @param ARate The interest rate per period (e.g., 0.05 for 5%)
      @param APeriods The number of compounding periods
      @param ADecimals Number of decimal places to round to (default: 4)
      
      @returns The compound interest earned (not including the principal),
               rounded to ADecimals places
      
      @references Financial Mathematics for Actuaries
      
      @example
        var
          Interest: Double;
        begin
          // Calculate the compound interest earned on $1000 invested for 5 years at 8% annual interest
          Interest := TFinanceKit.CompoundInterest(1000, 0.08, 5);
          // Returns approximately 469.3282 (the difference between future value and principal)
        end;
    }
    class function CompoundInterest(
      const APrincipal, ARate: Double;
      const APeriods: Integer;
      const ADecimals: Integer = 4): Double; static;
    
    {
      @description Calculates the periodic payment required to amortize a loan.
                   Formula: PMT = PV * r * (1 + r)^n / ((1 + r)^n - 1)
                   where:
                   - PV = Present Value (loan amount)
                   - r = Interest rate per period
                   - n = Total number of payments
                   
                   This formula assumes:
                   - Payments are made at the end of each period
                   - Interest rate remains constant
                   - All payments are equal
      
      @usage Use to calculate payment amounts for loans, mortgages, or annuities
      
      @param APresentValue The loan amount or present value of the annuity
      @param ARate The interest rate per period (e.g., 0.05 for 5%)
      @param APeriods The total number of payments
      @param ADecimals Number of decimal places to round to (default: 4)
      
      @returns The periodic payment amount, rounded to ADecimals places
      
      @references Financial Mathematics for Actuaries
      
      @warning Raises EFinanceError if APeriods is not positive.
               For very small rates (near zero), calculates as simple division of principal by periods.
      
      @example
        var
          Payment: Double;
        begin
          // Calculate the monthly payment for a $200,000 30-year mortgage at 4.5% annual interest
          // (note: convert annual rate to monthly by dividing by 12)
          Payment := TFinanceKit.Payment(200000, 0.045/12, 30*12);
          // Returns approximately 1013.3721 per month
        end;
    }
    class function Payment(
      const APresentValue, ARate: Double;
      const APeriods: Integer;
      const ADecimals: Integer = 4): Double; static;
    
    {
      @description NPV is the difference between the present value of cash inflows and outflows.
                   Formula: NPV = -I + Σ(CFt / (1+r)^t)
                   where:
                   - I = Initial investment
                   - CFt = Cash flow at time t
                   - r = Discount rate
                   - t = Time period
                   
                   A positive NPV indicates a profitable investment.
      
      @usage Use to evaluate the profitability of an investment or project
      
      @param AInitialInvestment The initial cash outflow (positive value)
      @param ACashFlows Array of future cash flows (positive for inflows, negative for outflows)
      @param Rate The discount rate per period (e.g., 0.10 for 10%)
      @param ADecimals Number of decimal places to round to (default: 4)
      
      @returns The net present value of the investment, rounded to ADecimals places
      
      @references Corporate Finance Institute
      
      @warning Raises EFinanceError if the cash flows array is empty.
               The initial investment is treated as a cash outflow at time 0.
               The first element of ACashFlows is considered to occur one period after the initial investment.
      
      @example
        var
          CashFlows: TDoubleArray;
          NPV: Double;
        begin
          SetLength(CashFlows, 5);
          CashFlows[0] := 20000;  // Year 1
          CashFlows[1] := 25000;  // Year 2
          CashFlows[2] := 30000;  // Year 3
          CashFlows[3] := 35000;  // Year 4
          CashFlows[4] := 40000;  // Year 5
          
          // Calculate NPV of a $100,000 investment with the above cash flows at 10% discount rate
          NPV := TFinanceKit.NetPresentValue(100000, CashFlows, 0.10);
          // Returns positive value if project is profitable at 10% discount rate
        end;
    }
    class function NetPresentValue(
      const AInitialInvestment: Double;
      const ACashFlows: TDoubleArray;
      const Rate: Double;
      const ADecimals: Integer = 4): Double; static;
    
    {
      @description IRR is the discount rate that makes NPV = 0.
                   Found by solving: 0 = -I + Σ(CFt / (1+IRR)^t)
                   
                   Implementation uses the Secant Method with dampening:
                   1. Start with initial guess
                   2. Use secant method: r_new = r - NPV * (r - r_last)/(NPV - NPV_last)
                   3. Apply dampening to improve convergence
                   4. Repeat until |NPV| < tolerance
      
      @usage Use to find the rate of return of an investment based on its cash flows
      
      @param AInitialInvestment The initial cash outflow (positive value)
      @param ACashFlows Array of future cash flows (typically positive values)
      @param ADecimals Number of decimal places to round to (default: 4)
      
      @returns The internal rate of return, rounded to ADecimals places
      
      @references Financial Mathematics for Actuaries
      
      @warning Returns NaN if no convergence is achieved or if the problem has no solution.
               No IRR exists if the cash flow series does not change sign at least once.
               Multiple IRRs can exist mathematically if there are multiple sign changes in the cash flows.
      
      @example
        var
          CashFlows: TDoubleArray;
          IRR: Double;
        begin
          SetLength(CashFlows, 5);
          CashFlows[0] := 20000;  // Year 1
          CashFlows[1] := 25000;  // Year 2
          CashFlows[2] := 30000;  // Year 3
          CashFlows[3] := 35000;  // Year 4
          CashFlows[4] := 40000;  // Year 5
          
          // Calculate IRR of a $100,000 investment with the above cash flows
          IRR := TFinanceKit.InternalRateOfReturn(100000, CashFlows);
          // Returns approximately 0.1797 (17.97%) if convergence is reached
        end;
    }
    class function InternalRateOfReturn(
      const AInitialInvestment: Double;
      const ACashFlows: TDoubleArray;
      const ADecimals: Integer = 4): Double; static;
    
    {
      @description Straight-Line Depreciation:
                   Annual depreciation = (Cost - Salvage) / Life
      
      @usage Use to calculate the constant annual depreciation expense for an asset
      
      @param ACost The initial cost of the asset
      @param ASalvage The salvage (residual) value at the end of the asset's useful life
      @param ALife The useful life of the asset in years
      @param ADecimals Number of decimal places to round to (default: 4)
      
      @returns The annual depreciation expense, rounded to ADecimals places
      
      @references IFRS IAS 16
      
      @example
        var
          AnnualDepreciation: Double;
        begin
          // Calculate the annual depreciation for a $50,000 machine with $5,000 salvage value over 10 years
          AnnualDepreciation := TFinanceKit.StraightLineDepreciation(50000, 5000, 10);
          // Returns 4500.0000 per year
        end;
    }
    class function StraightLineDepreciation(
      const ACost, ASalvage: Double;
      const ALife: Integer;
      const ADecimals: Integer = 4): Double; static;
    
    {
      @description A form of accelerated depreciation using twice the straight-line rate.
                   Formula: Dep = Cost * Rate * (1-Rate)^(period-1)
                   where:
                   - Rate = 2/Life (twice straight-line rate)
                   - Cost = Initial asset cost
                   - Period = Current period
      
      @usage Use to calculate the depreciation expense for a specific period using
             an accelerated depreciation method that front-loads expenses
      
      @param ACost The initial cost of the asset
      @param ASalvage The salvage (residual) value (used for validation only)
      @param ALife The useful life of the asset in years
      @param APeriod The period for which to calculate depreciation (1-based)
      @param ADecimals Number of decimal places to round to (default: 4)
      
      @returns The depreciation expense for the specified period, rounded to ADecimals places
      
      @references IFRS IAS 16
      
      @warning Raises EFinanceError if ALife or APeriod is invalid, or if ACost is not greater than ASalvage.
               APeriod must be within the range 1 to ALife.
      
      @example
        var
          Depreciation: Double;
        begin
          // Calculate year 1 depreciation for a $50,000 machine with $5,000 salvage value over 10 years
          Depreciation := TFinanceKit.DecliningBalanceDepreciation(50000, 5000, 10, 1);
          // Returns approximately 10000 for year 1 (rate = 2/10 = 0.2)
          
          // Calculate year 2 depreciation for the same machine
          Depreciation := TFinanceKit.DecliningBalanceDepreciation(50000, 5000, 10, 2);
          // Returns approximately 8000 for year 2 (less than year 1)
        end;
    }
    class function DecliningBalanceDepreciation(
      const ACost, ASalvage: Double;
      const ALife: Integer;
      const APeriod: Integer;
      const ADecimals: Integer = 4): Double; static;
    
    {
      @description ROI = (Gain - Cost) / Cost
                   Measures the profitability of an investment.
      
      @usage Use to evaluate the return on an investment as a percentage of its cost
      
      @param AGain The total return or value received from the investment
      @param ACost The initial cost of the investment
      @param ADecimals Number of decimal places to round to (default: 4)
      
      @returns The return on investment as a decimal (multiply by 100 for percentage)
      
      @references Corporate Finance Institute
      
      @example
        var
          ROI: Double;
        begin
          // Calculate ROI for an investment that cost $10,000 and returned $12,500
          ROI := TFinanceKit.ReturnOnInvestment(12500, 10000);
          // Returns 0.25 (25% return)
        end;
    }
    class function ReturnOnInvestment(const AGain, ACost: Double; const ADecimals: Integer = 4): Double; static;
    
    {
      @description ROE = Net Income / Shareholders' Equity
                   Measures a company's profitability in relation to shareholders' equity.
      
      @usage Use to evaluate how efficiently a company uses equity to generate profits
      
      @param ANetIncome The company's net income for the period
      @param AShareholdersEquity The average shareholders' equity for the period
      @param ADecimals Number of decimal places to round to (default: 4)
      
      @returns The return on equity as a decimal (multiply by 100 for percentage)
      
      @references Corporate Finance Institute
      
      @example
        var
          ROE: Double;
        begin
          // Calculate ROE for a company with $2 million net income and $15 million in shareholders' equity
          ROE := TFinanceKit.ReturnOnEquity(2000000, 15000000);
          // Returns approximately 0.1333 (13.33% return on equity)
        end;
    }
    class function ReturnOnEquity(
      const ANetIncome, AShareholdersEquity: Double;
      const ADecimals: Integer = 4): Double; static;
    
    {
      @description Calculates the present value of a bond's cash flows.
                   Formula: Price = C * [1 - (1+r)^-n]/r + F/(1+r)^n
                   where:
                   - C = Coupon payment
                   - r = Yield rate per period
                   - n = Number of periods
                   - F = Face value
      
      @usage Use to calculate the fair price of a bond based on its cash flows
      
      @param AFaceValue The par value or face value of the bond
      @param ACouponRate The annual coupon rate as a decimal (e.g., 0.05 for 5%)
      @param AYieldRate The annual yield to maturity as a decimal
      @param APeriodsPerYear The number of coupon payments per year (e.g., 2 for semi-annual)
      @param AYearsToMaturity The number of years until the bond matures
      @param ADecimals Number of decimal places to round to (default: 4)
      
      @returns The fair price of the bond, rounded to ADecimals places
      
      @references CFA Institute's Fixed Income Analysis
      
      @warning Raises EFinanceError if APeriodsPerYear or AYearsToMaturity is invalid.
               The calculation assumes regular coupon payments at equal intervals.
      
      @example
        var
          Price: Double;
        begin
          // Calculate the price of a $1000 face value bond with 6% annual coupon (paid semi-annually)
          // with 4.5% yield to maturity and 10 years to maturity
          Price := TFinanceKit.BondPrice(1000, 0.06, 0.045, 2, 10);
          // Returns approximately 1123.2526
        end;
    }
    class function BondPrice(
      const AFaceValue, ACouponRate, AYieldRate: Double;
      const APeriodsPerYear, AYearsToMaturity: Integer;
      const ADecimals: Integer = 4): Double; static;
    
    {
      @description Calculates the yield that makes present value equal to bond price.
                   Uses iterative Newton-Raphson method to find the yield.
      
      @usage Use to calculate the yield to maturity for a bond with a known market price
      
      @param ABondPrice The current market price of the bond
      @param AFaceValue The par value or face value of the bond
      @param ACouponRate The annual coupon rate as a decimal (e.g., 0.05 for 5%)
      @param APeriodsPerYear The number of coupon payments per year (e.g., 2 for semi-annual)
      @param AYearsToMaturity The number of years until the bond matures
      @param ADecimals Number of decimal places to round to (default: 4)
      
      @returns The annual yield to maturity as a decimal, rounded to ADecimals places
      
      @references CFA Institute's Fixed Income Analysis
      
      @warning Raises EFinanceError if calculation does not converge after maximum iterations.
               The implementation uses Newton-Raphson method with dampening for better convergence.
      
      @example
        var
          YTM: Double;
        begin
          // Calculate yield to maturity for a bond trading at $950 with $1000 face value,
          // 5% annual coupon (paid semi-annually), and 5 years to maturity
          YTM := TFinanceKit.BondYieldToMaturity(950, 1000, 0.05, 2, 5);
          // Returns the yield that would make the present value of this bond equal to $950
        end;
    }
    class function BondYieldToMaturity(
      const ABondPrice, AFaceValue, ACouponRate: Double;
      const APeriodsPerYear, AYearsToMaturity: Integer;
      const ADecimals: Integer = 4): Double; static;

    { ArmotizationPayment type for calculating amortization schedule}
    type
      TAmortizationPayment = record
        PaymentNumber: Integer;
        Payment: Double;
        Principal: Double;
        Interest: Double;
        RemainingBalance: Double;
      end;
      TAmortizationArray = array of TAmortizationPayment;

    {
      @description Calculates the principal and interest portions of a loan payment.
                   Returns array of records containing payment details.
      
      @usage Use to create an amortization schedule for a loan or mortgage
      
      @param ALoanAmount The initial loan amount
      @param ARate The interest rate per period (e.g., 0.05 for 5%)
      @param ANumberOfPayments The total number of payment periods
      @param ADecimals Number of decimal places to round to (default: 4)
      
      @returns TAmortizationArray - Array of payment records containing:
               - PaymentNumber: The payment number (1-based)
               - Payment: The total payment amount (principal + interest)
               - Principal: The portion applied to principal
               - Interest: The portion applied to interest
               - RemainingBalance: The loan balance after this payment
      
      @references Financial Mathematics for Actuaries
      
      @warning Raises EFinanceError if ANumberOfPayments is not positive.
               All amounts are rounded to ADecimals places.
      
      @example
        var
          Schedule: TFinanceKit.TAmortizationArray;
          I: Integer;
        begin
          // Create amortization schedule for a $200,000 loan at 4.5% annual interest
          // paid monthly over 30 years (360 payments)
          Schedule := TFinanceKit.AmortizationSchedule(200000, 0.045/12, 360);
          
          // Display first few payments
          for I := 0 to 2 do
          begin
            // Access payment details
            WriteLn('Payment #', Schedule[I].PaymentNumber);
            WriteLn('  Total Payment: $', Schedule[I].Payment:0:2);
            WriteLn('  Principal: $', Schedule[I].Principal:0:2);
            WriteLn('  Interest: $', Schedule[I].Interest:0:2);
            WriteLn('  Remaining Balance: $', Schedule[I].RemainingBalance:0:2);
          end;
        end;
    }
    class function AmortizationSchedule(
      const ALoanAmount, ARate: Double;
      const ANumberOfPayments: Integer;
      const ADecimals: Integer = 4): TAmortizationArray; static;
      
    {
      @description Converts nominal rates to effective annual rates considering compounding frequency.
                   Formula: EAR = (1 + r/m)^m - 1
                   where:
                   - r = Nominal annual rate
                   - m = Number of compounding periods per year
      
      @usage Use to compare interest rates with different compounding frequencies
      
      @param ANominalRate The nominal annual interest rate as a decimal (e.g., 0.06 for 6%)
      @param ACompoundingsPerYear The number of compounding periods per year
      @param ADecimals Number of decimal places to round to (default: 4)
      
      @returns The effective annual rate as a decimal, rounded to ADecimals places
      
      @references CFA Institute's Financial Mathematics
      
      @warning Raises EFinanceError if ACompoundingsPerYear is not positive.
               For very small nominal rates, returns 0.
      
      @example
        var
          EAR: Double;
        begin
          // Calculate the effective annual rate for a 6% nominal rate compounded monthly
          EAR := TFinanceKit.EffectiveAnnualRate(0.06, 12);
          // Returns approximately 0.0617 (6.17%)
          
          // Calculate the effective annual rate for a 6% nominal rate compounded quarterly
          EAR := TFinanceKit.EffectiveAnnualRate(0.06, 4);
          // Returns approximately 0.0614 (6.14%)
        end;
    }
    class function EffectiveAnnualRate(
      const ANominalRate: Double;
      const ACompoundingsPerYear: Integer;
      const ADecimals: Integer = 4): Double; static;
      
    {
      @description Measures bond price sensitivity to interest rate changes.
                   Formula: ModDur = MacDur / (1 + y/n)
                   where:
                   - MacDur = Macaulay Duration
                   - y = Yield to maturity
                   - n = Number of payments per year
      
      @usage Use to estimate the percentage change in bond price for a given change in yield
    
      @param AFaceValue The par value or face value of the bond
      @param ACouponRate The annual coupon rate as a decimal (e.g., 0.05 for 5%)
      @param AYieldRate The annual yield to maturity as a decimal
      @param APeriodsPerYear The number of coupon payments per year (e.g., 2 for semi-annual)
      @param AYearsToMaturity The number of years until the bond matures
      @param ADecimals Number of decimal places to round to (default: 4)
    
      @returns The modified duration in years, rounded to ADecimals places
    
      @references CFA Institute's Fixed Income Analysis
    
      @warning Higher duration indicates greater sensitivity to interest rate changes.
               For a small change in yield (Δy), the percentage price change ≈ -ModDur × Δy
      
      @example
        var
          Duration: Double;
        begin
          // Calculate modified duration for a $1000 face value bond with 4% annual coupon (paid semi-annually),
          // 5% yield to maturity, and 10 years to maturity
          Duration := TFinanceKit.ModifiedDuration(1000, 0.04, 0.05, 2, 10);
          // If Duration = 7.5, a 1% increase in yield would cause approximately a 7.5% decrease in price
        end;
    }
    class function ModifiedDuration(
      const AFaceValue, ACouponRate, AYieldRate: Double;
      const APeriodsPerYear, AYearsToMaturity: Integer;
      const ADecimals: Integer = 4): Double; static;
      
    {
      @description Calculates break-even point in units.
                   Formula: BE = FC / (P - VC)
                   where:
                   - FC = Fixed costs
                   - P = Price per unit
                   - VC = Variable cost per unit
      
      @usage Use to determine the number of units a business must sell to cover all costs
      
      @param AFixedCosts The total fixed costs
      @param APricePerUnit The selling price per unit
      @param AVariableCostPerUnit The variable cost per unit
      @param ADecimals Number of decimal places to round to (default: 4)
      
      @returns The break-even quantity in units, rounded to ADecimals places
      
      @references Corporate Finance Institute
      
      @warning Raises EFinanceError if APricePerUnit <= AVariableCostPerUnit,
               as break-even is impossible in this case (each sale increases losses).
      
      @example
        var
          BreakEvenUnits: Double;
        begin
          // Calculate break-even quantity for a product with:
          // - Fixed costs: $50,000
          // - Selling price: $25 per unit
          // - Variable cost: $15 per unit
          BreakEvenUnits := TFinanceKit.BreakEvenUnits(50000, 25, 15);
          // Returns 5000 units (at this quantity, total revenue equals total costs)
        end;
    }
    class function BreakEvenUnits(
      const AFixedCosts, APricePerUnit, AVariableCostPerUnit: Double;
      const ADecimals: Integer = 4): Double; static;
    
    {
      @description Working Capital Analysis
      
      Calculates key working capital ratios for liquidity analysis.
      
      @usage Use to analyze a company's liquidity
      
      @param ACurrentAssets The total current assets
      @param ACurrentLiabilities The total current liabilities
      @param AInventory The total inventory
      @param ACash The total cash
      @param ASales The total sales
      @param ADecimals Number of decimal places to round to (default: 4)
      
      @returns TWorkingCapitalRatios - Record containing working capital ratios
      
      @references Corporate Finance Institute
      
      @example
        var
          Ratios: TFinanceKit.TWorkingCapitalRatios;
        begin
          // Calculate working capital ratios for a company with:
          // - Current assets: $1,000,000
          // - Current liabilities: $500,000
          // - Inventory: $200,000
          // - Cash: $100,000
          // - Sales: $1,000,000
          Ratios := TFinanceKit.WorkingCapitalRatios(1000000, 500000, 200000, 100000, 1000000);
          // Ratios.CurrentRatio = 2.00
          // Ratios.QuickRatio = 1.60
          // Ratios.CashRatio = 0.20
          // Ratios.WorkingCapitalTurnover = 2.00
        end;
    }
    class function WorkingCapitalRatios(
      const ACurrentAssets, ACurrentLiabilities, AInventory, ACash, ASales: Double;
      const ADecimals: Integer = 4): TWorkingCapitalRatios; static;
      
    {
      @description Financial Leverage Analysis
      
      Calculates key financial leverage ratios for solvency analysis.
      
      @usage Use to analyze a company's financial leverage
      
      @param ATotalDebt The total debt
      @param ATotalAssets The total assets
      @param ATotalEquity The total equity
      @param AEBIT Earnings Before Interest and Taxes
      @param AInterestExpense Interest Expense
      @param ADecimals Number of decimal places to round to (default: 4)
      
      @returns TLeverageRatios - Record containing financial leverage ratios
      
      @references Corporate Finance Institute
      
      @example
        var
          Ratios: TFinanceKit.TLeverageRatios;
        begin
          // Calculate financial leverage ratios for a company with:
          // - Total debt: $500,000
          // - Total assets: $1,000,000
          // - Total equity: $500,000
          // - Earnings Before Interest and Taxes: $200,000
          // - Interest Expense: $50,000
          Ratios := TFinanceKit.LeverageRatios(500000, 1000000, 500000, 200000, 50000);
          // Ratios.DebtRatio = 0.50
          // Ratios.DebtToEquityRatio = 1.00
          // Ratios.EquityMultiplier = 2.00
          // Ratios.TimesInterestEarned = 4.00
        end;
    }
    class function LeverageRatios(
      const ATotalDebt, ATotalAssets, ATotalEquity, AEBIT, AInterestExpense: Double;
      const ADecimals: Integer = 4): TLeverageRatios; static;
      
    {
      @description Black-Scholes Option Pricing Model
      
      Calculates theoretical price of European call/put options.
      Formula for Call: C = S*N(d1) - K*e^(-rT)*N(d2)
      Formula for Put: P = K*e^(-rT)*N(-d2) - S*N(-d1)
      where:
      d1 = (ln(S/K) + (r + σ²/2)T) / (σ√T)
      d2 = d1 - σ√T
      
      @usage Use to calculate the theoretical price of a European call or put option
      
      @param ASpotPrice The current stock price
      @param AStrikePrice The option's strike price
      @param ARiskFreeRate The risk-free interest rate
      @param AVolatility The annual volatility of the stock
      @param ATimeToMaturity The time until the option expires
      @param AOptionType The type of option (otCall or otPut)
      @param ADecimals Number of decimal places to round to (default: 4)
      
      @returns The theoretical price of the option, rounded to ADecimals places
      
      @references Options, Futures, and Other Derivatives by John C. Hull
      
      @warning Raises EFinanceError if ATimeToMaturity is not positive,
               AVolatility is not positive, or ASpotPrice or AStrikePrice is not positive.
      
      @example
        var
          Price: Double;
        begin
          // Calculate the price of a European call option with:
          // - Spot price: $50
          // - Strike price: $50
          // - Risk-free rate: 5%
          // - Volatility: 20%
          // - Time to maturity: 1 year
          Price := TFinanceKit.BlackScholes(50, 50, 0.05, 0.20, 1, otCall);
          // Returns approximately 7.94
        end;
    }
    class function BlackScholes(
      const ASpotPrice, AStrikePrice, ARiskFreeRate, AVolatility, ATimeToMaturity: Double;
      const AOptionType: TOptionType;
      const ADecimals: Integer = 4): Double; static;
      
    {
      @description Risk-Adjusted Performance Metrics
      
      Calculates various risk-adjusted return measures.
      
      @usage Use to analyze a portfolio's risk-adjusted performance
      
      @param APortfolioReturn The return of the portfolio
      @param ARiskFreeRate The risk-free interest rate
      @param AMarketReturn The return of the market
      @param ABeta The beta of the portfolio
      @param APortfolioStdDev The standard deviation of the portfolio
      @param ABenchmarkReturn The return of the benchmark
      @param ATrackingError The tracking error of the portfolio
      @param ADecimals Number of decimal places to round to (default: 4)
      
      @returns TRiskMetrics - Record containing risk-adjusted return measures
      
      @references CFA Institute's Portfolio Management
      
      @example
        var
          Metrics: TFinanceKit.TRiskMetrics;
        begin
          // Calculate risk-adjusted return metrics for a portfolio with:
          // - Portfolio return: 10%
          // - Risk-free rate: 2%
          // - Market return: 8%
          // - Beta: 1.2
          // - Portfolio standard deviation: 15%
          // - Benchmark return: 7%
          // - Tracking error: 5%
          Metrics := TFinanceKit.RiskMetrics(0.10, 0.02, 0.08, 1.2, 0.15, 0.07, 0.05);
          // Metrics.SharpeRatio = 0.53
          // Metrics.TreynorRatio = 0.05
          // Metrics.JensenAlpha = 0.01
          // Metrics.InformationRatio = 0.20
        end;
    }
    class function RiskMetrics(
      const APortfolioReturn, ARiskFreeRate, AMarketReturn, ABeta, APortfolioStdDev, ABenchmarkReturn, ATrackingError: Double;
      const ADecimals: Integer = 4): TRiskMetrics; static;
      
    {
      @description DuPont Analysis
      
      Breaks down ROE into its component ratios.
      ROE = (Net Income/Sales) * (Sales/Total Assets) * (Total Assets/Total Equity)
      
      @usage Use to analyze a company's return on equity
      
      @param ANetIncome The company's net income for the period
      @param ASales The company's sales for the period
      @param ATotalAssets The company's total assets
      @param ATotalEquity The company's total equity
      @param ADecimals Number of decimal places to round to (default: 4)
      
      @returns TDuPontAnalysis - Record containing DuPont Analysis components
      
      @references Corporate Finance Institute
      
      @example
        var
          Analysis: TFinanceKit.TDuPontAnalysis;
        begin
          // Calculate DuPont Analysis for a company with:
          // - Net income: $100,000
          // - Sales: $1,000,000
          // - Total assets: $2,000,000
          // - Total equity: $1,000,000
          Analysis := TFinanceKit.DuPontAnalysis(100000, 1000000, 2000000, 1000000);
          // Analysis.ProfitMargin = 0.10
          // Analysis.AssetTurnover = 0.50
          // Analysis.EquityMultiplier = 2.00
          // Analysis.ROE = 0.10
        end;
    }
    class function DuPontAnalysis(
      const ANetIncome, ASales, ATotalAssets, ATotalEquity: Double;
      const ADecimals: Integer = 4): TDuPontAnalysis; static;
      
    {
      @description Operating Leverage Analysis
      
      Measures business risk and operating efficiency.
      DOL = (Q * (P-V)) / (Q * (P-V) - F)
      where:
      Q = Quantity
      P = Price per unit
      V = Variable cost per unit
      F = Fixed costs
      
      @usage Use to analyze a company's operating leverage
      
      @param AQuantity The total quantity of products sold
      @param APricePerUnit The selling price per unit
      @param AVariableCostPerUnit The variable cost per unit
      @param AFixedCosts The total fixed costs
      @param ADecimals Number of decimal places to round to (default: 4)
      
      @returns TOperatingLeverage - Record containing operating leverage measures
      
      @references Financial Management: Theory and Practice
      
      @example
        var
          Leverage: TFinanceKit.TOperatingLeverage;
        begin
          // Calculate operating leverage for a company with:
          // - Quantity: 10,000 units
          // - Selling price: $10 per unit
          // - Variable cost: $5 per unit
          // - Fixed costs: $20,000
          Leverage := TFinanceKit.OperatingLeverage(10000, 10, 5, 20000);
          // Leverage.DOL = 2.00
          // Leverage.BreakEvenPoint = 4000 units
          // Leverage.OperatingLeverage = 2.00
        end;
    }
    class function OperatingLeverage(
      const AQuantity, APricePerUnit, AVariableCostPerUnit, AFixedCosts: Double;
      const ADecimals: Integer = 4): TOperatingLeverage; static;
      
    {
      @description Profitability Analysis
      
      Calculates comprehensive set of profitability ratios.
      
      @usage Use to analyze a company's profitability
      
      @param ARevenue The company's total revenue for the period
      @param ACOGS The company's cost of goods sold for the period
      @param AEBIT Earnings Before Interest and Taxes
      @param ANetIncome The company's net income for the period
      @param ATotalAssets The company's total assets
      @param ACurrentLiabilities The company's total current liabilities
      @param ADecimals Number of decimal places to round to (default: 4)
      
      @returns TProfitabilityRatios - Record containing profitability ratios
      
      @references Corporate Finance Institute
      
      @example
        var
          Ratios: TFinanceKit.TProfitabilityRatios;
        begin
          // Calculate profitability ratios for a company with:
          // - Revenue: $1,000,000
          // - Cost of goods sold: $500,000
          // - Earnings Before Interest and Taxes: $200,000
          // - Net income: $100,000
          // - Total assets: $2,000,000
          // - Current liabilities: $500,000
          Ratios := TFinanceKit.ProfitabilityRatios(1000000, 500000, 200000, 100000, 2000000, 500000);
          // Ratios.GrossMargin = 0.50
          // Ratios.OperatingMargin = 0.20
          // Ratios.NetProfitMargin = 0.10
          // Ratios.ROA = 0.05
          // Ratios.ROCE = 0.10
        end;
    }
    class function ProfitabilityRatios(
      const ARevenue, ACOGS, AEBIT, ANetIncome, ATotalAssets, ACurrentLiabilities: Double;
      const ADecimals: Integer = 4): TProfitabilityRatios; static;

    {
      @description Calculates break-even point in currency terms.
                   Formula: BE = FC / (1 - VC/P)
                   where:
                   - FC = Fixed costs
                   - VC = Variable cost per unit
                   - P = Price per unit
    
      @usage Use to determine the revenue a business must generate to cover all costs
    
      @param AFixedCosts The total fixed costs
      @param APricePerUnit The selling price per unit
      @param AVariableCostPerUnit The variable cost per unit
      @param ADecimals Number of decimal places to round to (default: 4)
    
      @returns The break-even revenue in currency units, rounded to ADecimals places
    
      @references Corporate Finance Institute
    
      @warning Raises EFinanceError if APricePerUnit is zero or if APricePerUnit <= AVariableCostPerUnit,
               as break-even is impossible in these cases.
    
      @example
        var
          BreakEvenRev: Double;
        begin
          // Calculate break-even revenue for a product with:
          // - Fixed costs: $50,000
          // - Selling price: $25 per unit
          // - Variable cost: $15 per unit
          BreakEvenRev := TFinanceKit.BreakEvenRevenue(50000, 25, 15);
          // Returns $125,000 (at this revenue, total revenue equals total costs)
        end;
    }
    class function BreakEvenRevenue(
      const AFixedCosts, APricePerUnit, AVariableCostPerUnit: Double;
      const ADecimals: Integer = 4): Double; static;

    {
      @description Calculates company's weighted cost of capital.
                   Formula: WACC = (E/V * Re) + (D/V * Rd * (1-T))
                   where:
                   - E = Market value of equity
                   - D = Market value of debt
                   - V = Total market value (E + D)
                   - Re = Cost of equity
                   - Rd = Cost of debt
                   - T = Tax rate
    
      @usage Use to determine a company's overall cost of capital based on its capital structure
    
      @param AEquityValue The market value of the company's equity
      @param ADebtValue The market value of the company's debt
      @param ACostOfEquity The required return on equity (e.g., 0.12 for 12%)
      @param ACostOfDebt The cost of debt (e.g., 0.05 for 5%)
      @param ATaxRate The corporate tax rate (e.g., 0.21 for 21%)
      @param ADecimals Number of decimal places to round to (default: 4)
    
      @returns The weighted average cost of capital as a decimal, rounded to ADecimals places
    
      @references Corporate Finance Institute
    
      @warning Raises EFinanceError if tax rate is not between 0 and 1,
               or if total firm value (equity + debt) is zero.
    
      @example
        var
          Cost: Double;
        begin
          // Calculate WACC for a company with:
          // - Equity value: $1,000,000
          // - Debt value: $500,000
          // - Cost of equity: 12%
          // - Cost of debt: 5%
          // - Tax rate: 21%
          Cost := TFinanceKit.WACC(1000000, 500000, 0.12, 0.05, 0.21);
          // Returns approximately 0.093 (9.3%)
        end;
    }
    class function WACC(
      const AEquityValue, ADebtValue, ACostOfEquity, ACostOfDebt, ATaxRate: Double;
      const ADecimals: Integer = 4): Double; static;

    {
      @description Calculates expected return of an asset using the Capital Asset Pricing Model.
                   Formula: E(Ri) = Rf + βi(E(Rm) - Rf)
                   where:
                   - Rf = Risk-free rate
                   - βi = Beta of the asset
                   - E(Rm) = Expected market return
    
      @usage Use to determine the expected return of an investment based on its risk
    
      @param ARiskFreeRate The risk-free interest rate (e.g., 0.02 for 2%)
      @param ABeta The beta of the asset (measure of systematic risk)
      @param AExpectedMarketReturn The expected return of the market (e.g., 0.08 for 8%)
      @param ADecimals Number of decimal places to round to (default: 4)
    
      @returns The expected return of the asset as a decimal, rounded to ADecimals places
    
      @references CFA Institute's Portfolio Management
    
      @warning Raises EFinanceError if beta value is unreasonably high (>10) or low (<-10).
               A beta of 1 indicates the asset moves with the market.
               A beta > 1 indicates higher volatility than the market.
               A beta < 1 indicates lower volatility than the market.
    
      @example
        var
          ExpectedReturn: Double;
        begin
          // Calculate the expected return for an asset with:
          // - Risk-free rate: 2%
          // - Beta: 1.2 (more volatile than the market)
          // - Expected market return: 8%
          ExpectedReturn := TFinanceKit.CAPM(0.02, 1.2, 0.08);
          // Returns 0.092 (9.2%) = 2% + 1.2 * (8% - 2%)
        end;
    }
    class function CAPM(
      const ARiskFreeRate, ABeta, AExpectedMarketReturn: Double;
      const ADecimals: Integer = 4): Double; static;

    {
      @description Calculates intrinsic value of a stock using constant dividend growth model.
                   Formula: P = D0(1+g)/(r-g)
                   where:
                   - D0 = Current dividend
                   - g = Growth rate
                   - r = Required rate of return
    
      @usage Use to estimate the fair value of a dividend-paying stock with stable growth
    
      @param ACurrentDividend The most recent annual dividend paid
      @param AGrowthRate The expected annual dividend growth rate (e.g., 0.03 for 3%)
      @param ARequiredReturn The required rate of return (e.g., 0.09 for 9%)
      @param ADecimals Number of decimal places to round to (default: 4)
    
      @returns The theoretical stock price, rounded to ADecimals places
    
      @references CFA Institute's Equity Analysis
    
      @warning Raises EFinanceError if growth rate is greater than or equal to required return rate,
               as the model is only valid when r > g. For high-growth companies, a multi-stage
               dividend discount model would be more appropriate.
    
      @example
        var
          StockPrice: Double;
        begin
          // Calculate the fair value of a stock with:
          // - Current annual dividend: $2.00
          // - Expected growth rate: 3%
          // - Required return: 8%
          StockPrice := TFinanceKit.GordonGrowthModel(2.00, 0.03, 0.08);
          // Returns $41.20 = $2.00 * (1 + 0.03) / (0.08 - 0.03)
        end;
    }
    class function GordonGrowthModel(
      const ACurrentDividend, AGrowthRate, ARequiredReturn: Double;
      const ADecimals: Integer = 4): Double; static;
    end;

implementation

{ TFinanceKit - Financial Mathematics Implementation

  This unit implements standard financial mathematics formulas based on authoritative sources:
  - CFA Institute's Financial Mathematics
  - Financial Mathematics for Actuaries (2nd Edition)
  - Corporate Finance Institute's Financial Modeling
  - IFRS IAS 16 Standard for Asset Depreciation
  
  All calculations use Double precision and include appropriate rounding for financial reporting.
  Time value of money calculations assume:
  - End of period payments
  - Constant interest rate
  - No transaction costs
}

{ TFinanceKit }

class function TFinanceKit.CumulativeNormal(const X: Double): Double;
const
  A1 = 0.31938153;
  A2 = -0.356563782;
  A3 = 1.781477937;
  A4 = -1.821255978;
  A5 = 1.330274429;
  P = 0.2316419;
var
  K, L: Double;
begin
  if X < 0 then
    Result := 1 - CumulativeNormal(-X)
  else
  begin
    K := 1 / (1 + P * X);
    L := ((((A5 * K + A4) * K + A3) * K + A2) * K + A1) * K;
    Result := 1 - L * Exp(-Sqr(X) / 2) / Sqrt(2 * Pi);
  end;
end;

class function TFinanceKit.PresentValue(
  const AFutureValue, ARate: Double;
  const APeriods: Integer;
  const ADecimals: Integer = 4): Double;
begin
  if APeriods < 0 then
    raise EFinanceError.Create('Number of periods must be non-negative');
  if Abs(ARate) < 1E-10 then
    Result := AFutureValue
  else
    Result := SimpleRoundTo(AFutureValue / Power(1 + ARate, APeriods), -ADecimals);
end;

class function TFinanceKit.FutureValue(
  const APresentValue, ARate: Double;
  const APeriods: Integer;
  const ADecimals: Integer = 4): Double;
begin
  Result := SimpleRoundTo(APresentValue * Power(1 + ARate, APeriods), -ADecimals);  // Use ADecimals decimals with bankers' rounding
end;

class function TFinanceKit.CompoundInterest(
  const APrincipal, ARate: Double;
  const APeriods: Integer;
  const ADecimals: Integer = 4): Double;
begin
  Result := SimpleRoundTo(APrincipal * (Power(1 + ARate, APeriods) - 1), -ADecimals);  // Use ADecimals decimals with bankers' rounding
end;

class function TFinanceKit.Payment(
  const APresentValue, ARate: Double;
  const APeriods: Integer;
  const ADecimals: Integer = 4): Double;
var
  Numerator, Denominator, PowerTerm: Double;
begin
  if APeriods <= 0 then
    raise EFinanceError.Create('Number of periods must be positive');
    
  if Abs(ARate) < 1E-10 then
    Result := SimpleRoundTo(APresentValue / APeriods, -ADecimals)
  else
  begin
    PowerTerm := Math.Power(1 + ARate, APeriods);
    Numerator := APresentValue * ARate * PowerTerm;
    Denominator := PowerTerm - 1;
    Result := SimpleRoundTo(Numerator / Denominator, -ADecimals);
  end;
end;

class function TFinanceKit.NetPresentValue(
  const AInitialInvestment: Double;
  const ACashFlows: TDoubleArray;
  const Rate: Double;
  const ADecimals: Integer = 4): Double;
var
  I: Integer;
  NPV, Divisor: Double;
begin
  if Length(ACashFlows) = 0 then
    raise EFinanceError.Create('Cash flows array cannot be empty');
    
  // NPV = -Initial + Σ(CFt / (1+r)^t)
  NPV := -AInitialInvestment;
  
  // Calculate each cash flow's present value
  for I := 0 to High(ACashFlows) do
  begin
    Divisor := Power(1 + Rate, I + 1);
    NPV := NPV + SimpleRoundTo(ACashFlows[I] / Divisor, -ADecimals);
  end;
  
  Result := SimpleRoundTo(NPV, -ADecimals);
end;

class function TFinanceKit.InternalRateOfReturn(
  const AInitialInvestment: Double;
  const ACashFlows: TDoubleArray;
  const ADecimals: Integer = 4): Double;
const
  TOLERANCE = 1E-6;
  MAX_ITERATIONS = 100;
  MIN_RATE = -0.999999;
  MAX_RATE = 1.0;  // Reduced maximum rate
var
  Rate, NPV, LastRate, LastNPV, NewRate: Double;
  I, Iteration: Integer;
  HasPositive, HasNegative: Boolean;
begin
  if Length(ACashFlows) = 0 then
    raise EFinanceError.Create('Cash flows array cannot be empty');
    
  // Check if IRR calculation is possible
  HasPositive := False;
  HasNegative := AInitialInvestment > 0;
  for I := 0 to High(ACashFlows) do
  begin
    if ACashFlows[I] > 0 then
      HasPositive := True
    else if ACashFlows[I] < 0 then
      HasNegative := True;
  end;
  
  if not (HasPositive and HasNegative) then
    raise EFinanceError.Create('Cash flows must have both positive and negative values for IRR calculation');
    
  Rate := 0.1; // Initial guess
  LastRate := 0.05; // Start with a different rate
  LastNPV := 0;
  Iteration := 0;
  
  repeat
    NPV := -AInitialInvestment;
    for I := 0 to High(ACashFlows) do
      NPV := NPV + ACashFlows[I] / Power(1 + Rate, I + 1);
      
    if Iteration > 0 then
    begin
      // Use secant method with dampening
      if Abs(NPV) < TOLERANCE then
        Break;
        
      if Abs(NPV - LastNPV) < 1E-10 then
        Break;
        
      NewRate := Rate - NPV * (Rate - LastRate) / (NPV - LastNPV);
      
      // Stronger dampening for better stability
      if Abs(NewRate - Rate) > 0.001 then
        NewRate := Rate + 0.001 * Sign(NewRate - Rate);
        
      LastRate := Rate;
      Rate := NewRate;
    end;
    
    LastNPV := NPV;
    Inc(Iteration);
    
    // Keep rate within reasonable bounds
    if Rate < MIN_RATE then
      Rate := MIN_RATE
    else if Rate > MAX_RATE then
      Rate := MAX_RATE;
      
  until (Abs(NPV) < TOLERANCE) or (Iteration >= MAX_ITERATIONS);
  
  if Iteration >= MAX_ITERATIONS then
    raise EFinanceError.Create('IRR calculation did not converge');
    
  Result := SimpleRoundTo(Rate, -ADecimals);  // Round to ADecimals decimals
end;

class function TFinanceKit.StraightLineDepreciation(
  const ACost, ASalvage: Double;
  const ALife: Integer;
  const ADecimals: Integer = 4): Double;
begin
  if ALife <= 0 then
    raise EFinanceError.Create('Asset life must be positive');
  if ACost < ASalvage then
    raise EFinanceError.Create('Cost must be greater than or equal to salvage value');
  Result := SimpleRoundTo((ACost - ASalvage) / ALife, -ADecimals);
end;

class function TFinanceKit.DecliningBalanceDepreciation(
  const ACost, ASalvage: Double;
  const ALife: Integer;
  const APeriod: Integer;
  const ADecimals: Integer = 4): Double;
var
  Rate: Double;
begin
  if (ALife <= 0) or (APeriod <= 0) or (APeriod > ALife) then
    raise EFinanceError.Create('Invalid life or period parameters');
  if ACost <= ASalvage then
    raise EFinanceError.Create('Cost must be greater than salvage value');
    
  Rate := 2.0 / ALife;  // Double declining balance rate
  Result := SimpleRoundTo(ACost * Rate * Power(1 - Rate, APeriod - 1), -ADecimals);  // Round to ADecimals decimals
end;

class function TFinanceKit.ReturnOnInvestment(const AGain, ACost: Double; const ADecimals: Integer = 4): Double;
begin
  if Abs(ACost) < 1E-15 then
    raise EFinanceError.Create('Investment cost must be non-zero');
  Result := SimpleRoundTo((AGain - ACost) / ACost, -ADecimals);
end;

class function TFinanceKit.ReturnOnEquity(
  const ANetIncome, AShareholdersEquity: Double;
  const ADecimals: Integer = 4): Double;
begin
  if Abs(AShareholdersEquity) < 1E-15 then
    raise EFinanceError.Create('Shareholders'' equity must be non-zero');
  Result := SimpleRoundTo(ANetIncome / AShareholdersEquity, -ADecimals);
end;

class function TFinanceKit.BondPrice(
  const AFaceValue, ACouponRate, AYieldRate: Double;
  const APeriodsPerYear, AYearsToMaturity: Integer;
  const ADecimals: Integer = 4): Double;
var
  TotalPeriods: Integer;
  CouponPayment, PVCoupons, PVPrincipal: Double;
  YieldPerPeriod: Double;
  I: Integer;
begin
  if (APeriodsPerYear <= 0) or (AYearsToMaturity < 0) then
    raise EFinanceError.Create('Invalid periods or maturity parameters');
    
  TotalPeriods := APeriodsPerYear * AYearsToMaturity;
  CouponPayment := (AFaceValue * ACouponRate) / APeriodsPerYear;
  YieldPerPeriod := AYieldRate / APeriodsPerYear;
  
  // Present value of coupon payments
  PVCoupons := 0;
  for I := 1 to TotalPeriods do
    PVCoupons := PVCoupons + CouponPayment / Power(1 + YieldPerPeriod, I);
  
  // Present value of principal
  PVPrincipal := AFaceValue / Power(1 + YieldPerPeriod, TotalPeriods);
  
  Result := SimpleRoundTo(PVCoupons + PVPrincipal, -ADecimals);
end;

class function TFinanceKit.BondYieldToMaturity(
  const ABondPrice, AFaceValue, ACouponRate: Double;
  const APeriodsPerYear, AYearsToMaturity: Integer;
  const ADecimals: Integer = 4): Double;
const
  MAX_ITERATIONS = 100;
  TOLERANCE = 1E-10;
var
  Yield, LastYield, Price, Derivative: Double;
  Iteration: Integer;
  TotalPeriods: Integer;
  CouponPayment: Double;
  YieldPerPeriod: Double;
  PriceDiff: Double;
  InitialGuess: Double;
begin
  if (APeriodsPerYear <= 0) or (AYearsToMaturity < 0) then
    raise EFinanceError.Create('Invalid periods or maturity parameters');
    
  TotalPeriods := APeriodsPerYear * AYearsToMaturity;
  CouponPayment := (AFaceValue * ACouponRate) / APeriodsPerYear;
  
  // Better initial guess using current yield
  InitialGuess := (CouponPayment * APeriodsPerYear) / ABondPrice;
  if ABondPrice < AFaceValue then
    InitialGuess := InitialGuess + (AFaceValue - ABondPrice) / (ABondPrice * AYearsToMaturity)
  else if ABondPrice > AFaceValue then
    InitialGuess := InitialGuess - (ABondPrice - AFaceValue) / (ABondPrice * AYearsToMaturity);
    
  Yield := InitialGuess;
  Iteration := 0;
  
  repeat
    LastYield := Yield;
    YieldPerPeriod := Yield / APeriodsPerYear;
    
    // Calculate price at current yield
    Price := BondPrice(AFaceValue, ACouponRate, Yield, APeriodsPerYear, AYearsToMaturity);
    PriceDiff := Price - ABondPrice;
    
    // Calculate derivative (price sensitivity)
    Derivative := -TotalPeriods * Price / (1 + YieldPerPeriod);
    
    // Newton-Raphson iteration with dampening
    if Abs(Derivative) > 1E-10 then
    begin
      Yield := LastYield - PriceDiff / Derivative;
      // Apply dampening
      if Abs(Yield - LastYield) > 0.01 then
        Yield := LastYield + 0.01 * Sign(Yield - LastYield);
    end
    else
      Break;
    
    // Ensure yield stays reasonable
    if Yield < -0.99 then Yield := -0.99
    else if Yield > 1.0 then Yield := 1.0;
    
    Inc(Iteration);
  until (Abs(PriceDiff) < TOLERANCE) or (Iteration >= MAX_ITERATIONS);
  
  if Iteration >= MAX_ITERATIONS then
    raise EFinanceError.Create('Yield calculation did not converge');
    
  Result := SimpleRoundTo(Yield, -ADecimals);
end;

class function TFinanceKit.AmortizationSchedule(
  const ALoanAmount, ARate: Double;
  const ANumberOfPayments: Integer;
  const ADecimals: Integer = 4): TAmortizationArray;
var
  I: Integer;
  Balance, PaymentAmount, InterestPayment, PrincipalPayment: Double;
begin
  Result := nil;
  if ANumberOfPayments <= 0 then
    raise EFinanceError.Create('Number of payments must be positive');
    
  SetLength(Result, ANumberOfPayments);
  Balance := ALoanAmount;
  PaymentAmount := TFinanceKit.Payment(ALoanAmount, ARate, ANumberOfPayments);
  
  for I := 0 to ANumberOfPayments - 1 do
  begin
    InterestPayment := SimpleRoundTo(Balance * ARate, -ADecimals);
    PrincipalPayment := SimpleRoundTo(PaymentAmount - InterestPayment, -ADecimals);
    Balance := SimpleRoundTo(Balance - PrincipalPayment, -ADecimals);
    
    Result[I].PaymentNumber := I + 1;
    Result[I].Payment := PaymentAmount;
    Result[I].Principal := PrincipalPayment;
    Result[I].Interest := InterestPayment;
    Result[I].RemainingBalance := Balance;
  end;
end;

class function TFinanceKit.EffectiveAnnualRate(
  const ANominalRate: Double;
  const ACompoundingsPerYear: Integer;
  const ADecimals: Integer = 4): Double;
var
  CompoundFactor: Double;
begin
  if ACompoundingsPerYear <= 0 then
    raise EFinanceError.Create('Number of compounding periods must be positive');
    
  if Abs(ANominalRate) < 1E-10 then
    Result := 0
  else
  begin
    CompoundFactor := 1 + (ANominalRate / ACompoundingsPerYear);
    Result := SimpleRoundTo(Power(CompoundFactor, ACompoundingsPerYear) - 1, -ADecimals);
  end;
end;

class function TFinanceKit.ModifiedDuration(
  const AFaceValue, ACouponRate, AYieldRate: Double;
  const APeriodsPerYear, AYearsToMaturity: Integer;
  const ADecimals: Integer = 4): Double;
var
  TotalPeriods, T: Integer;
  CouponPayment, BondPV, WeightedTime, MacDur: Double;
  YieldPerPeriod: Double;
  PVCashFlow: Double;
begin
  if (APeriodsPerYear <= 0) or (AYearsToMaturity < 0) then
    raise EFinanceError.Create('Invalid periods or maturity parameters');
    
  TotalPeriods := APeriodsPerYear * AYearsToMaturity;
  CouponPayment := (AFaceValue * ACouponRate) / APeriodsPerYear;
  YieldPerPeriod := AYieldRate / APeriodsPerYear;
  
  // Calculate present value and weighted time sum for Macaulay Duration
  BondPV := 0;
  WeightedTime := 0;
  
  // Calculate weighted time for coupon payments
  for T := 1 to TotalPeriods do
  begin
    PVCashFlow := CouponPayment / Power(1 + YieldPerPeriod, T);
    BondPV := BondPV + PVCashFlow;
    WeightedTime := WeightedTime + (T * PVCashFlow);
  end;
  
  // Add final principal payment
  PVCashFlow := AFaceValue / Power(1 + YieldPerPeriod, TotalPeriods);
  BondPV := BondPV + PVCashFlow;
  WeightedTime := WeightedTime + (TotalPeriods * PVCashFlow);
  
  // Calculate Macaulay Duration (in periods)
  MacDur := WeightedTime / BondPV;
  
  // Convert Macaulay Duration to years and then to Modified Duration
  Result := SimpleRoundTo((MacDur / APeriodsPerYear) / (1 + YieldPerPeriod), -ADecimals);
end;

class function TFinanceKit.BreakEvenUnits(
  const AFixedCosts, APricePerUnit, AVariableCostPerUnit: Double;
  const ADecimals: Integer = 4): Double;
begin
  if Abs(APricePerUnit - AVariableCostPerUnit) < 1E-10 then
    raise EFinanceError.Create('Price per unit must be different from variable cost per unit');
    
  if APricePerUnit <= AVariableCostPerUnit then
    raise EFinanceError.Create('Price per unit must be greater than variable cost per unit for break-even to exist');
    
  Result := SimpleRoundTo(AFixedCosts / (APricePerUnit - AVariableCostPerUnit), -ADecimals);
end;

class function TFinanceKit.WorkingCapitalRatios(
  const ACurrentAssets, ACurrentLiabilities, AInventory, ACash, ASales: Double;
  const ADecimals: Integer = 4): TWorkingCapitalRatios;
var
  WorkingCapital: Double;
begin
  if Abs(ACurrentLiabilities) < 1E-10 then
    raise EFinanceError.Create('Current liabilities must be non-zero');
    
  // Current Ratio
  Result.CurrentRatio := SimpleRoundTo(ACurrentAssets / ACurrentLiabilities, -ADecimals);
  
  // Quick Ratio (Acid-Test Ratio)
  Result.QuickRatio := SimpleRoundTo((ACurrentAssets - AInventory) / ACurrentLiabilities, -ADecimals);
  
  // Cash Ratio
  Result.CashRatio := SimpleRoundTo(ACash / ACurrentLiabilities, -ADecimals);
  
  // Working Capital Turnover
  WorkingCapital := ACurrentAssets - ACurrentLiabilities;
  if Abs(WorkingCapital) < 1E-10 then
    Result.WorkingCapitalTurnover := 0  // Undefined case
  else
    Result.WorkingCapitalTurnover := SimpleRoundTo(ASales / WorkingCapital, -ADecimals);
end;

class function TFinanceKit.LeverageRatios(
  const ATotalDebt, ATotalAssets, ATotalEquity, AEBIT, AInterestExpense: Double;
  const ADecimals: Integer = 4): TLeverageRatios;
begin
  if Abs(ATotalAssets) < 1E-10 then
    raise EFinanceError.Create('Total assets must be non-zero');
  if Abs(ATotalEquity) < 1E-10 then
    raise EFinanceError.Create('Total equity must be non-zero');
    
  // Debt Ratio
  Result.DebtRatio := SimpleRoundTo(ATotalDebt / ATotalAssets, -ADecimals);
  
  // Debt to Equity Ratio
  Result.DebtToEquityRatio := SimpleRoundTo(ATotalDebt / ATotalEquity, -ADecimals);
  
  // Equity Multiplier
  Result.EquityMultiplier := SimpleRoundTo(ATotalAssets / ATotalEquity, -ADecimals);
  
  // Times Interest Earned
  if Abs(AInterestExpense) < 1E-10 then
    Result.TimesInterestEarned := 0  // Undefined case
  else
    Result.TimesInterestEarned := SimpleRoundTo(AEBIT / AInterestExpense, -ADecimals);
end;

class function TFinanceKit.BlackScholes(
  const ASpotPrice, AStrikePrice, ARiskFreeRate, AVolatility, ATimeToMaturity: Double;
  const AOptionType: TOptionType;
  const ADecimals: Integer = 4): Double;
var
  D1, D2: Double;
  DiscountFactor: Double;
  VolSqrtT: Double;
  ND1, ND2: Double;
begin
  if ATimeToMaturity <= 0 then
    raise EFinanceError.Create('Time to maturity must be positive');
  if AVolatility <= 0 then
    raise EFinanceError.Create('Volatility must be positive');
  if (ASpotPrice <= 0) or (AStrikePrice <= 0) then
    raise EFinanceError.Create('Prices must be positive');
    
  // Precalculate common terms
  VolSqrtT := AVolatility * Sqrt(ATimeToMaturity);
  
  // Calculate d1 and d2
  D1 := (Ln(ASpotPrice/AStrikePrice) + (ARiskFreeRate + Sqr(AVolatility)/2) * ATimeToMaturity) / VolSqrtT;
  D2 := D1 - VolSqrtT;
  
  // Calculate discount factor once
  DiscountFactor := Exp(-ARiskFreeRate * ATimeToMaturity);
  
  // Calculate cumulative normal probabilities
  ND1 := CumulativeNormal(D1);
  ND2 := CumulativeNormal(D2);
  
  case AOptionType of
    otCall:
      Result := SimpleRoundTo(
        ASpotPrice * ND1 - 
        AStrikePrice * DiscountFactor * ND2,
        -ADecimals
      );
    otPut:
      Result := SimpleRoundTo(
        AStrikePrice * DiscountFactor * (1 - ND2) - 
        ASpotPrice * (1 - ND1),
        -ADecimals
      );
  end;
end;

class function TFinanceKit.RiskMetrics(
  const APortfolioReturn, ARiskFreeRate, AMarketReturn, ABeta, APortfolioStdDev, ABenchmarkReturn, ATrackingError: Double;
  const ADecimals: Integer = 4): TRiskMetrics;
begin
  // Sharpe Ratio
  if Abs(APortfolioStdDev) < 1E-10 then
    Result.SharpeRatio := 0
  else
    Result.SharpeRatio := SimpleRoundTo((APortfolioReturn - ARiskFreeRate) / APortfolioStdDev, -ADecimals);
  
  // Treynor Ratio
  if Abs(ABeta) < 1E-10 then
    Result.TreynorRatio := 0
  else
    Result.TreynorRatio := SimpleRoundTo((APortfolioReturn - ARiskFreeRate) / ABeta, -ADecimals);
  
  // Jensen's Alpha
  Result.JensenAlpha := SimpleRoundTo(
    APortfolioReturn - (ARiskFreeRate + ABeta * (AMarketReturn - ARiskFreeRate)),
    -ADecimals
  );
  
  // Information Ratio
  if Abs(ATrackingError) < 1E-10 then
    Result.InformationRatio := 0
  else
    Result.InformationRatio := SimpleRoundTo(
      (APortfolioReturn - ABenchmarkReturn) / ATrackingError,
      -ADecimals
    );
end;

class function TFinanceKit.DuPontAnalysis(
  const ANetIncome, ASales, ATotalAssets, ATotalEquity: Double;
  const ADecimals: Integer = 4): TDuPontAnalysis;
begin
  if Abs(ASales) < 1E-10 then
    raise EFinanceError.Create('Sales must be non-zero');
  if Abs(ATotalAssets) < 1E-10 then
    raise EFinanceError.Create('Total assets must be non-zero');
  if Abs(ATotalEquity) < 1E-10 then
    raise EFinanceError.Create('Total equity must be non-zero');
    
  // Calculate components
  Result.ProfitMargin := SimpleRoundTo(ANetIncome / ASales, -ADecimals);
  Result.AssetTurnover := SimpleRoundTo(ASales / ATotalAssets, -ADecimals);
  Result.EquityMultiplier := SimpleRoundTo(ATotalAssets / ATotalEquity, -ADecimals);
  
  // Calculate final ROE using DuPont formula
  Result.ROE := SimpleRoundTo(
    Result.ProfitMargin * Result.AssetTurnover * Result.EquityMultiplier,
    -ADecimals
  );
end;

class function TFinanceKit.OperatingLeverage(
  const AQuantity, APricePerUnit, AVariableCostPerUnit, AFixedCosts: Double;
  const ADecimals: Integer = 4): TOperatingLeverage;
var
  ContributionMargin, EBIT, TotalRevenue, TotalVariableCosts: Double;
begin
  if APricePerUnit <= AVariableCostPerUnit then
    raise EFinanceError.Create('Price must be greater than variable cost');
    
  ContributionMargin := APricePerUnit - AVariableCostPerUnit;
  TotalRevenue := AQuantity * APricePerUnit;
  TotalVariableCosts := AQuantity * AVariableCostPerUnit;
  EBIT := TotalRevenue - TotalVariableCosts - AFixedCosts;
  
  // Degree of Operating Leverage (DOL)
  if Abs(EBIT) < 1E-10 then
    Result.DOL := 0
  else
    Result.DOL := SimpleRoundTo((AQuantity * ContributionMargin) / EBIT, -ADecimals);
  
  // Break-even point in units
  Result.BreakEvenPoint := SimpleRoundTo(AFixedCosts / ContributionMargin, -ADecimals);
  
  // Operating Leverage (same as DOL)
  Result.OperatingLeverage := Result.DOL;
end;

class function TFinanceKit.ProfitabilityRatios(
  const ARevenue, ACOGS, AEBIT, ANetIncome, ATotalAssets, ACurrentLiabilities: Double;
  const ADecimals: Integer = 4): TProfitabilityRatios;
begin
  if Abs(ARevenue) < 1E-10 then
    raise EFinanceError.Create('Revenue must be non-zero');
  if Abs(ATotalAssets) < 1E-10 then
    raise EFinanceError.Create('Total assets must be non-zero');
    
  // Gross Margin
  Result.GrossMargin := SimpleRoundTo((ARevenue - ACOGS) / ARevenue, -ADecimals);
  
  // Operating Margin
  Result.OperatingMargin := SimpleRoundTo(AEBIT / ARevenue, -ADecimals);
  
  // Net Profit Margin
  Result.NetProfitMargin := SimpleRoundTo(ANetIncome / ARevenue, -ADecimals);
  
  // Return on Assets (ROA)
  Result.ROA := SimpleRoundTo(ANetIncome / ATotalAssets, -ADecimals);
  
  // Return on Capital Employed (ROCE)
  if Abs(ATotalAssets - ACurrentLiabilities) < 1E-10 then
    Result.ROCE := 0
  else
    Result.ROCE := SimpleRoundTo(AEBIT / (ATotalAssets - ACurrentLiabilities), -ADecimals);
end;

class function TFinanceKit.BreakEvenRevenue(
  const AFixedCosts, APricePerUnit, AVariableCostPerUnit: Double;
  const ADecimals: Integer = 4): Double;
begin
  if APricePerUnit <= AVariableCostPerUnit then
    raise EFinanceError.Create('Price must be greater than variable cost');
    
  Result := SimpleRoundTo(
    AFixedCosts / (1 - AVariableCostPerUnit / APricePerUnit), -ADecimals);
end;

class function TFinanceKit.WACC(
  const AEquityValue, ADebtValue, ACostOfEquity, ACostOfDebt, ATaxRate: Double;
  const ADecimals: Integer = 4): Double;
var
  TotalValue, EquityWeight: Double;
begin
  if (ATaxRate < 0) or (ATaxRate > 1) then
    raise EFinanceError.Create('Tax rate must be between 0 and 1');

  TotalValue := AEquityValue + ADebtValue;
  if Abs(TotalValue) < 1E-10 then
    raise EFinanceError.Create('Total firm value must be non-zero');

  // Calculate weights ensuring they sum to exactly 1
  EquityWeight := AEquityValue / TotalValue;

  Result := SimpleRoundTo(
    (EquityWeight * ACostOfEquity) +
    ((1 - EquityWeight) * ACostOfDebt * (1 - ATaxRate)),
    -ADecimals
  );
end;

class function TFinanceKit.CAPM(
  const ARiskFreeRate, ABeta, AExpectedMarketReturn: Double;
  const ADecimals: Integer = 4): Double;
begin
  if (ARiskFreeRate < 0) or (ARiskFreeRate > 1) or (ABeta < -10) or (ABeta > 10) then
    raise EFinanceError.Create('Invalid input parameters');
    
  Result := SimpleRoundTo(
    ARiskFreeRate + ABeta * (AExpectedMarketReturn - ARiskFreeRate), -ADecimals);
end;

class function TFinanceKit.GordonGrowthModel(
  const ACurrentDividend, AGrowthRate, ARequiredReturn: Double;
  const ADecimals: Integer = 4): Double;
begin
  if (ACurrentDividend < 0) or (AGrowthRate < 0) or (ARequiredReturn < 0) or (AGrowthRate >= ARequiredReturn) then
    raise EFinanceError.Create('Invalid input parameters');
    
  Result := SimpleRoundTo(
    ACurrentDividend * (1 + AGrowthRate) /
      (ARequiredReturn - AGrowthRate), -ADecimals);
end;


end. 
