program typed_dense_solve;

{$mode objfpc}{$H+}{$J-}

uses
  AlgebraLib.DenseMatrices,
  AlgebraLib.DenseKernels,
  AlgebraLib.DenseSolvers;

var
  ItemsPerReceipt, ReceiptTotals, UnitPrices: IDenseDoubleMatrix;
  NewOrder, NewOrderTotal: IDenseDoubleMatrix;
begin
  { A cafe has three receipts but no itemised prices. Each row records the
    quantities of coffee, sandwiches, and juice on one receipt. }
  ItemsPerReceipt := TDenseDoubleMatrix.FromValues(3, 3,
    [2.0, 1.0, 1.0,
     1.0, 2.0, 3.0,
     3.0, 2.0, 1.0]);
  ReceiptTotals := TDenseDoubleMatrix.FromValues(3, 1,
    [18.50, 28.00, 30.00]);

  { Solve ItemsPerReceipt * UnitPrices = ReceiptTotals. Solve uses an LU
    factorisation and triangular solves; it does not form an inverse. }
  UnitPrices := Solve(ItemsPerReceipt, ReceiptTotals);

  WriteLn('Prices inferred from the three receipts:');
  WriteLn('  Coffee:  $', UnitPrices[0, 0]:0:2);
  WriteLn('  Sandwich: $', UnitPrices[1, 0]:0:2);
  WriteLn('  Juice:   $', UnitPrices[2, 0]:0:2);

  { Use the solved prices to quote five coffees, four sandwiches, and
    three juices. }
  NewOrder := TDenseDoubleMatrix.FromValues(1, 3, [5.0, 4.0, 3.0]);
  NewOrderTotal := Multiply(NewOrder, UnitPrices);
  WriteLn;
  WriteLn('Total for the new order: $', NewOrderTotal[0, 0]:0:2);
  WriteLn('typed dense solve: success');
end.
