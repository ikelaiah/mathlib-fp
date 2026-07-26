program dense_solver_selection;

{$mode objfpc}{$H+}{$J-}

uses
  AlgebraLib.DenseMatrices,
  AlgebraLib.DenseDecompositions;

var
  Design, Observed, Coefficients: IDenseDoubleMatrix;
  RedundantDesign, Target, MinimumNorm: IDenseDoubleMatrix;
  Covariance: IDenseDoubleMatrix;
  FitInfo, MinimumNormInfo: TDenseSolveDiagnostics;
  Spectrum: IDenseDoubleSymmetricEigen;
begin
  { Calibrate offset + gain from four noisy measurements. A tall full-rank
    system belongs on the Householder QR path. }
  Design := TDenseDoubleMatrix.FromValues(4, 2,
    [1.0, 0.0,
     1.0, 1.0,
     1.0, 2.0,
     1.0, 3.0]);
  Observed := TDenseDoubleMatrix.FromValues(4, 1,
    [1.1, 2.9, 5.2, 6.8]);
  Coefficients := LeastSquares(Design, Observed, FitInfo);
  WriteLn('Sensor calibration (Householder QR)');
  WriteLn('  offset = ', Coefficients[0, 0]:0:4);
  WriteLn('  gain   = ', Coefficients[1, 0]:0:4);
  WriteLn('  residual norm = ', FitInfo.ResidualNorm:0:6);
  WriteLn('  backward error = ', FitInfo.BackwardError:0:6);

  { Two actuators have the same response. Infinitely many settings hit the
    target; SVD deliberately selects the minimum-norm setting. }
  RedundantDesign := TDenseDoubleMatrix.FromValues(2, 3,
    [1.0, 0.0, 1.0,
     0.0, 1.0, 1.0]);
  Target := TDenseDoubleMatrix.FromValues(2, 1, [2.0, 2.0]);
  MinimumNorm := MinimumNormSolve(RedundantDesign, Target, MinimumNormInfo);
  WriteLn;
  WriteLn('Redundant actuator command (compact SVD)');
  WriteLn('  command = [', MinimumNorm[0, 0]:0:4, ', ',
    MinimumNorm[1, 0]:0:4, ', ', MinimumNorm[2, 0]:0:4, ']');
  WriteLn('  numerical rank = ', MinimumNormInfo.NumericalRank);

  { A symmetric covariance matrix has real ordered eigenvalues. The leading
    eigenvector is the direction with the larger variance. }
  Covariance := TDenseDoubleMatrix.FromValues(2, 2,
    [4.0, 1.5,
     1.5, 2.0]);
  Spectrum := FactorSymmetricEigen(Covariance);
  WriteLn;
  WriteLn('Covariance spectrum (ascending)');
  WriteLn('  eigenvalues = ', Spectrum.Eigenvalues[0]:0:4, ', ',
    Spectrum.Eigenvalues[1]:0:4);
  WriteLn('  leading direction = [', Spectrum.Eigenvectors[0, 1]:0:4,
    ', ', Spectrum.Eigenvectors[1, 1]:0:4, ']');
end.
