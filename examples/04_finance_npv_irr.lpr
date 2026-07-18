program FinanceNpvIrr;

{-----------------------------------------------------------------------------
  04_finance_npv_irr.lpr

  Demonstrates time-value-of-money calculations, project NPV/IRR, and loan
  amortization. Rates always match the period: annual rates for annual cash
  flows, and annual-rate/12 for monthly payments.

  Build (FPC command line):
    mkdir lib
    fpc -Fu../src -FUlib 04_finance_npv_irr.lpr

  Build (Lazarus):
    Add ../src to:
    Project -> Project Options -> Compiler Options -> Paths -> Other Unit Files
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}

uses
  SysUtils,
  MathBase.SharedTypes,
  FinanceLib.Interest;   // TFinanceKit, TFinanceKit.TAmortizationArray

var
  CashFlows: TDoubleArray;
  NPV, IRR, PV, FV, PMT: Double;
  Schedule: TFinanceKit.TAmortizationArray;
  I: Integer;

begin
  // ── 1. Present Value and Future Value ─────────────────────────────────
  // What is $10 000 received in 5 years worth today at 7% discount rate?
  PV := TFinanceKit.PresentValue(10000, 0.07, 5);

  // What will $5 000 invested today grow to in 10 years at 6%?
  FV := TFinanceKit.FutureValue(5000, 0.06, 10);

  WriteLn('=== Time Value of Money ===');
  WriteLn(Format('  PV of $10,000 in 5 yrs  @ 7%%  : $%.2f', [PV]));
  WriteLn(Format('  FV of $5,000  in 10 yrs @ 6%%  : $%.2f', [FV]));
  WriteLn;

  // ── 2. Loan payment ──────────────────────────────────────────────────
  // Monthly payment on a $250,000 mortgage at 5% annual rate over 25 years.
  // Rate per period = 5% / 12; periods = 25 * 12.
  PMT := TFinanceKit.Payment(250000, 0.05 / 12, 25 * 12);
  WriteLn('=== Loan Payment ===');
  WriteLn(Format('  Monthly payment on $250,000 @ 5%% / 25 yrs : $%.2f', [PMT]));
  WriteLn;

  // ── 3. NPV / IRR ─────────────────────────────────────────────────────
  // A project costs $100,000 upfront and generates cash flows over 5 years.
  // Is it worth investing at a 10% hurdle rate?
  CashFlows := TDoubleArray.Create(20000, 25000, 30000, 35000, 40000);

  NPV := TFinanceKit.NetPresentValue(100000, CashFlows, 0.10);
  IRR := TFinanceKit.InternalRateOfReturn(100000, CashFlows) * 100;

  WriteLn('=== Project Evaluation ===');
  WriteLn('  Initial investment : $100,000');
  WriteLn('  Cash flows         : $20k  $25k  $30k  $35k  $40k');
  WriteLn(Format('  NPV @ 10%%          : $%.2f', [NPV]));
  WriteLn(Format('  IRR                : %.2f%%', [IRR]));
  if NPV > 0 then
    WriteLn('  Decision           : Accept (NPV > 0)')
  else
    WriteLn('  Decision           : Reject (NPV <= 0)');
  WriteLn;

  // ── 4. Amortization schedule (first 6 months of a car loan) ──────────
  // $30,000 car loan at 6% annual rate, 60 monthly payments.
  Schedule := TFinanceKit.AmortizationSchedule(30000, 0.06 / 12, 60);

  WriteLn('=== Amortization Schedule (first 6 of 60 payments) ===');
  WriteLn(Format('  %-4s  %-10s  %-10s  %-10s  %-14s',
    ['#', 'Payment', 'Principal', 'Interest', 'Balance']));
  WriteLn(StringOfChar('-', 56));

  for I := 0 to 5 do
    WriteLn(Format('  %-4d  $%-9.2f  $%-9.2f  $%-9.2f  $%-13.2f', [
      Schedule[I].PaymentNumber,
      Schedule[I].Payment,
      Schedule[I].Principal,
      Schedule[I].Interest,
      Schedule[I].RemainingBalance
    ]));

  WriteLn(Format('  ... (%d more payments)', [Length(Schedule) - 6]));
  WriteLn;

  WriteLn('Done. Press Enter to exit.');
  ReadLn;
end.
