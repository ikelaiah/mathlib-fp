program dense_solver_selection;

{$mode objfpc}{$H+}{$J-}

uses
  AlgebraLib.DenseMatrices,
  AlgebraLib.DenseDecompositions;

{ Typed dense matrices are reference-counted interfaces. FromValues receives
  entries in row-major order, and element access is zero based: A[0, 0] is the
  top-left entry.

  The convenience routines used below allocate a result and factor the input
  once. When solving repeatedly with the same coefficient matrix, call
  FactorQR, FactorSVD, or FactorSymmetricEigen once and retain the returned
  factor instead. }

var
  Design, Observed, Coefficients: IDenseDoubleMatrix;
  RedundantDesign, Target, MinimumNorm: IDenseDoubleMatrix;
  Covariance: IDenseDoubleMatrix;
  FitInfo, MinimumNormInfo: TDenseSolveDiagnostics;
  Spectrum: IDenseDoubleSymmetricEigen;
begin
  { Fit the calibration model

        observed = offset + gain * input

    to four noisy measurements. Design has four rows (observations) and two
    columns (unknown coefficients). Because the system is tall and full rank,
    Householder QR is the predictable least-squares choice. It minimizes
    ||Design*Coefficients - Observed|| without forming the less stable normal
    equations Design^T*Design. }
  Design := TDenseDoubleMatrix.FromValues(4, 2,
    [1.0, 0.0,
     1.0, 1.0,
     1.0, 2.0,
     1.0, 3.0]);
  Observed := TDenseDoubleMatrix.FromValues(4, 1,
    [1.1, 2.9, 5.2, 6.8]);
  Coefficients := LeastSquares(Design, Observed, FitInfo);

  { Coefficient row 0 is the fitted offset and row 1 is the fitted gain.
    ResidualNorm measures the remaining mismatch in the units of Observed.
    BackwardError normalizes that mismatch by the scales of the coefficient
    matrix, solution, and right-hand side, so a small value indicates that the
    computed answer solves a nearby problem accurately. }
  WriteLn('Sensor calibration (Householder QR)');
  WriteLn('  offset = ', Coefficients[0, 0]:0:4);
  WriteLn('  gain   = ', Coefficients[1, 0]:0:4);
  WriteLn('  residual norm = ', FitInfo.ResidualNorm:0:6);
  WriteLn('  backward error = ', FitInfo.BackwardError:0:6);

  { This command matrix has two output equations and three actuator settings:

        command[0] + command[2] = 2
        command[1] + command[2] = 2

    The third actuator's response is the sum of the first two response
    columns, so the columns are linearly dependent. Infinitely many commands
    reach the target. SVD exposes the numerical rank and deliberately selects
    the solution with the smallest Euclidean norm. QR alone cannot provide
    that minimum-norm guarantee for this wide, rank-deficient problem. }
  RedundantDesign := TDenseDoubleMatrix.FromValues(2, 3,
    [1.0, 0.0, 1.0,
     0.0, 1.0, 1.0]);
  Target := TDenseDoubleMatrix.FromValues(2, 1, [2.0, 2.0]);
  MinimumNorm := MinimumNormSolve(RedundantDesign, Target, MinimumNormInfo);

  { The expected command is [2/3, 2/3, 4/3]. NumericalRank is two because
    only two independent actuator-response directions exist. }
  WriteLn;
  WriteLn('Redundant actuator command (compact SVD)');
  WriteLn('  command = [', MinimumNorm[0, 0]:0:4, ', ',
    MinimumNorm[1, 0]:0:4, ', ', MinimumNorm[2, 0]:0:4, ']');
  WriteLn('  numerical rank = ', MinimumNormInfo.NumericalRank);

  { A real symmetric covariance matrix has real eigenvalues and an orthonormal
    eigenvector basis. FactorSymmetricEigen returns eigenvalues in ascending
    order, and eigenvector column J belongs to eigenvalue J.

    Therefore column 1 below is the principal direction with the larger
    variance. Its sign is arbitrary: [x,y] and [-x,-y] describe the same
    eigendirection, so either printed sign is mathematically correct. }
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
  WriteLn('dense solver selection: success');
end.
