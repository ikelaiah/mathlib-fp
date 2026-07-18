unit TestProbabilityLib;

{-----------------------------------------------------------------------------
 TestProbabilityLib

 Comprehensive tests for ProbabilityLib.Distributions.
 Every test uses analytically known values cross-checked against Python
 scipy.stats and Wolfram Alpha so tolerances are tight.

 Coverage
   Normal        — PDF, CDF, Survival, Mean, Variance
   LogNormal     — PDF, CDF, Survival, Mean, Variance
   Exponential   — PDF, CDF, Survival, Mean, Variance
   Gamma         — PDF, CDF, Survival, Mean, Variance
   Beta          — PDF, CDF, Survival, Mean, Variance
   ChiSquared    — PDF, CDF, Survival, Mean, Variance
   StudentT      — PDF, CDF, Survival, TwoTail, Mean, Variance
   F             — PDF, CDF, Survival, Mean, Variance
   Weibull       — PDF, CDF, Survival, Mean, Variance
   Uniform       — PDF, CDF, Survival, Mean, Variance
   Binomial      — PMF, CDF, Survival, Mean, Variance
   Poisson       — PMF, CDF, Survival, Mean, Variance
   Geometric     — PMF, CDF, Survival, Mean, Variance
   NegBinomial   — PMF, CDF, Mean, Variance
   Hypergeometric— PMF, CDF, Mean, Variance
   Error handling — EProbabilityError raised for invalid params
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math,
  fpcunit, testutils, testregistry,
  ProbabilityLib.Distributions;

type
  TTestProbabilityLib = class(TTestCase)
  private
    const
      EPS  = 1E-6;   { general tolerance }
      EPS2 = 1E-4;   { looser tolerance for series approximations }

    { Asserts two doubles are within Tol of each other }
    procedure AssertNear(const Expected, Actual, Tol: Double; const Msg: String = '');

    { Wrappers that trigger EProbabilityError — used with AssertException }
    procedure DoNormalPDF_BadSigma;
    procedure DoNormalCDF_BadSigma;
    procedure DoExponentialPDF_BadLambda;
    procedure DoGammaPDF_BadAlpha;
    procedure DoGammaPDF_BadBeta;
    procedure DoBetaCDF_BadAlpha;
    procedure DoChiSqCDF_BadDF;
    procedure DoStudentTPDF_BadDF;
    procedure DoStudentTVariance_BadDF;
    procedure DoFPDF_BadDF1;
    procedure DoWeibullPDF_BadK;
    procedure DoUniformPDF_BadBounds;
    procedure DoBinomialPMF_BadN;
    procedure DoBinomialPMF_BadP;
    procedure DoPoissonPMF_BadLambda;
    procedure DoGeometricPMF_BadP;
    procedure DoNegBinomialPMF_BadR;
    procedure DoHypergeometricPMF_BadPop;
    procedure DoNormalMean_BadSigma;
    procedure DoGammaMean_BadAlpha;
    procedure DoUniformMean_BadBounds;
    procedure DoBinomialMean_BadN;
    procedure DoPoissonMean_BadLambda;
    procedure DoNegBinomialMean_BadR;
    procedure DoHypergeometricMean_Negative;
    procedure DoNormalCDF_NonFinite;

  published
    { -----------------------------------------------------------------------
      NORMAL
    ----------------------------------------------------------------------- }
    procedure Test01_Normal_PDF_Standard;
    procedure Test02_Normal_PDF_Shifted;
    procedure Test03_Normal_CDF_196;
    procedure Test04_Normal_CDF_Zero;
    procedure Test05_Normal_Survival;
    procedure Test06_Normal_MeanVariance;
    procedure Test07_Normal_BadSigma_Raises;

    { -----------------------------------------------------------------------
      LOGNORMAL
    ----------------------------------------------------------------------- }
    procedure Test08_LogNormal_PDF;
    procedure Test09_LogNormal_CDF;
    procedure Test10_LogNormal_Survival;
    procedure Test11_LogNormal_MeanVariance;

    { -----------------------------------------------------------------------
      EXPONENTIAL
    ----------------------------------------------------------------------- }
    procedure Test12_Exponential_PDF;
    procedure Test13_Exponential_CDF;
    procedure Test14_Exponential_Survival;
    procedure Test15_Exponential_MeanVariance;
    procedure Test16_Exponential_NegativeX_Zero;
    procedure Test17_Exponential_BadLambda_Raises;

    { -----------------------------------------------------------------------
      GAMMA
    ----------------------------------------------------------------------- }
    procedure Test18_Gamma_PDF;
    procedure Test19_Gamma_CDF;
    procedure Test20_Gamma_Survival;
    procedure Test21_Gamma_MeanVariance;
    procedure Test22_Gamma_BadParams_Raises;

    { -----------------------------------------------------------------------
      BETA
    ----------------------------------------------------------------------- }
    procedure Test23_Beta_PDF;
    procedure Test24_Beta_CDF;
    procedure Test25_Beta_Survival;
    procedure Test26_Beta_MeanVariance;
    procedure Test27_Beta_Uniform_Special_Case;

    { -----------------------------------------------------------------------
      CHI-SQUARED
    ----------------------------------------------------------------------- }
    procedure Test28_ChiSquared_PDF;
    procedure Test29_ChiSquared_CDF;
    procedure Test30_ChiSquared_Survival;
    procedure Test31_ChiSquared_MeanVariance;
    procedure Test32_ChiSquared_BadDF_Raises;

    { -----------------------------------------------------------------------
      STUDENT'S T
    ----------------------------------------------------------------------- }
    procedure Test33_StudentT_PDF;
    procedure Test34_StudentT_CDF;
    procedure Test35_StudentT_Survival;
    procedure Test36_StudentT_TwoTail;
    procedure Test37_StudentT_MeanVariance;
    procedure Test38_StudentT_BadDF_Raises;

    { -----------------------------------------------------------------------
      F DISTRIBUTION
    ----------------------------------------------------------------------- }
    procedure Test39_F_PDF;
    procedure Test40_F_CDF;
    procedure Test41_F_Survival;
    procedure Test42_F_MeanVariance;

    { -----------------------------------------------------------------------
      WEIBULL
    ----------------------------------------------------------------------- }
    procedure Test43_Weibull_PDF;
    procedure Test44_Weibull_CDF;
    procedure Test45_Weibull_Survival;
    procedure Test46_Weibull_MeanVariance;
    procedure Test47_Weibull_Exponential_SpecialCase;

    { -----------------------------------------------------------------------
      UNIFORM
    ----------------------------------------------------------------------- }
    procedure Test48_Uniform_PDF_Inside;
    procedure Test49_Uniform_PDF_Outside;
    procedure Test50_Uniform_CDF;
    procedure Test51_Uniform_Survival;
    procedure Test52_Uniform_MeanVariance;

    { -----------------------------------------------------------------------
      BINOMIAL
    ----------------------------------------------------------------------- }
    procedure Test53_Binomial_PMF_FairCoin;
    procedure Test54_Binomial_PMF_AllHeads;
    procedure Test55_Binomial_CDF;
    procedure Test56_Binomial_Survival;
    procedure Test57_Binomial_MeanVariance;
    procedure Test58_Binomial_OutOfRange_Zero;
    procedure Test59_Binomial_BadParams_Raises;

    { -----------------------------------------------------------------------
      POISSON
    ----------------------------------------------------------------------- }
    procedure Test60_Poisson_PMF;
    procedure Test61_Poisson_CDF;
    procedure Test62_Poisson_Survival;
    procedure Test63_Poisson_MeanVariance;
    procedure Test64_Poisson_BadLambda_Raises;

    { -----------------------------------------------------------------------
      GEOMETRIC
    ----------------------------------------------------------------------- }
    procedure Test65_Geometric_PMF;
    procedure Test66_Geometric_CDF;
    procedure Test67_Geometric_Survival;
    procedure Test68_Geometric_MeanVariance;
    procedure Test69_Geometric_BadP_Raises;

    { -----------------------------------------------------------------------
      NEGATIVE BINOMIAL
    ----------------------------------------------------------------------- }
    procedure Test70_NegBinomial_PMF;
    procedure Test71_NegBinomial_CDF;
    procedure Test72_NegBinomial_MeanVariance;

    { -----------------------------------------------------------------------
      HYPERGEOMETRIC
    ----------------------------------------------------------------------- }
    procedure Test73_Hypergeometric_PMF;
    procedure Test74_Hypergeometric_CDF;
    procedure Test75_Hypergeometric_MeanVariance;

    { -----------------------------------------------------------------------
      ROUNDING (ADecimals parameter)
    ----------------------------------------------------------------------- }
    procedure Test76_NormalCDF_Rounded;
    procedure Test77_BinomialPMF_Rounded;
    procedure Test78_ContinuousCDFSurvivalIdentities;
    procedure Test79_SymmetricDistributionProperties;
    procedure Test80_BinomialPMFSumsToOne;
    procedure Test81_PoissonPMFSumsToOne;
    procedure Test82_HypergeometricPMFSumsToOne;
    procedure Test83_MomentValidationRegression;
    procedure Test84_DiscreteBoundaryRegression;

  end;

implementation

procedure TTestProbabilityLib.AssertNear(const Expected, Actual, Tol: Double; const Msg: String);
begin
  if Abs(Expected - Actual) > Tol then
    Fail(Format('%s  expected %.10f, got %.10f  (tol %.2e)',
      [Msg, Expected, Actual, Tol]));
end;

{ --- wrappers for exception tests --- }
procedure TTestProbabilityLib.DoNormalPDF_BadSigma;
begin TProbabilityKit.NormalPDF(0, 0, -1); end;

procedure TTestProbabilityLib.DoNormalCDF_BadSigma;
begin TProbabilityKit.NormalCDF(0, 0, 0); end;

procedure TTestProbabilityLib.DoExponentialPDF_BadLambda;
begin TProbabilityKit.ExponentialPDF(1, -2); end;

procedure TTestProbabilityLib.DoGammaPDF_BadAlpha;
begin TProbabilityKit.GammaPDF(1, -1, 1); end;

procedure TTestProbabilityLib.DoGammaPDF_BadBeta;
begin TProbabilityKit.GammaPDF(1, 1, 0); end;

procedure TTestProbabilityLib.DoBetaCDF_BadAlpha;
begin TProbabilityKit.BetaCDF(0.5, -1, 2); end;

procedure TTestProbabilityLib.DoChiSqCDF_BadDF;
begin TProbabilityKit.ChiSquaredCDF(1, 0); end;

procedure TTestProbabilityLib.DoStudentTPDF_BadDF;
begin TProbabilityKit.StudentTPDF(0, 0); end;

procedure TTestProbabilityLib.DoStudentTVariance_BadDF;
begin TProbabilityKit.StudentTVariance(2); end;

procedure TTestProbabilityLib.DoFPDF_BadDF1;
begin TProbabilityKit.FPDF(1, 0, 5); end;

procedure TTestProbabilityLib.DoWeibullPDF_BadK;
begin TProbabilityKit.WeibullPDF(1, -1, 1); end;

procedure TTestProbabilityLib.DoUniformPDF_BadBounds;
begin TProbabilityKit.UniformPDF(0.5, 3, 1); end;

procedure TTestProbabilityLib.DoBinomialPMF_BadN;
begin TProbabilityKit.BinomialPMF(1, 0, 0.5); end;

procedure TTestProbabilityLib.DoBinomialPMF_BadP;
begin TProbabilityKit.BinomialPMF(1, 5, 1.5); end;

procedure TTestProbabilityLib.DoPoissonPMF_BadLambda;
begin TProbabilityKit.PoissonPMF(2, -1); end;

procedure TTestProbabilityLib.DoGeometricPMF_BadP;
begin TProbabilityKit.GeometricPMF(1, 0); end;

procedure TTestProbabilityLib.DoNegBinomialPMF_BadR;
begin TProbabilityKit.NegBinomialPMF(3, 0, 0.5); end;

procedure TTestProbabilityLib.DoHypergeometricPMF_BadPop;
begin TProbabilityKit.HypergeometricPMF(1, 0, 0, 0); end;

procedure TTestProbabilityLib.DoNormalMean_BadSigma;
begin TProbabilityKit.NormalMean(0, 0); end;

procedure TTestProbabilityLib.DoGammaMean_BadAlpha;
begin TProbabilityKit.GammaMean(0, 1); end;

procedure TTestProbabilityLib.DoUniformMean_BadBounds;
begin TProbabilityKit.UniformMean(2, 1); end;

procedure TTestProbabilityLib.DoBinomialMean_BadN;
begin TProbabilityKit.BinomialMean(0, 0.5); end;

procedure TTestProbabilityLib.DoPoissonMean_BadLambda;
begin TProbabilityKit.PoissonMean(0); end;

procedure TTestProbabilityLib.DoNegBinomialMean_BadR;
begin TProbabilityKit.NegBinomialMean(0, 0.5); end;

procedure TTestProbabilityLib.DoHypergeometricMean_Negative;
begin TProbabilityKit.HypergeometricMean(10, -1, 2); end;

procedure TTestProbabilityLib.DoNormalCDF_NonFinite;
begin TProbabilityKit.NormalCDF(NaN, 0, 1); end;

{ ===========================================================================
  NORMAL
=========================================================================== }

procedure TTestProbabilityLib.Test01_Normal_PDF_Standard;
begin
  { Standard Normal peak at x=0: 1/sqrt(2*pi) ≈ 0.398942 }
  AssertNear(0.398942, TProbabilityKit.NormalPDF(0, 0, 1), EPS, 'Normal PDF at 0');
end;

procedure TTestProbabilityLib.Test02_Normal_PDF_Shifted;
begin
  { N(2,3) at x=2 (the peak): 1/(3*sqrt(2*pi)) ≈ 0.132981 }
  AssertNear(0.132981, TProbabilityKit.NormalPDF(2, 2, 3), EPS, 'Normal PDF shifted');
end;

procedure TTestProbabilityLib.Test03_Normal_CDF_196;
begin
  { Classic result: Φ(1.96) ≈ 0.975002 }
  AssertNear(0.975002, TProbabilityKit.NormalCDF(1.96, 0, 1), EPS2, 'Normal CDF 1.96');
end;

procedure TTestProbabilityLib.Test04_Normal_CDF_Zero;
begin
  { Φ(0) = 0.5 exactly }
  AssertNear(0.5, TProbabilityKit.NormalCDF(0, 0, 1), EPS, 'Normal CDF at mean');
end;

procedure TTestProbabilityLib.Test05_Normal_Survival;
begin
  { Survival at -1.96 should mirror CDF at 1.96 }
  AssertNear(TProbabilityKit.NormalCDF(1.96, 0, 1),
             TProbabilityKit.NormalSurvival(-1.96, 0, 1), EPS, 'Normal Survival symmetry');
end;

procedure TTestProbabilityLib.Test06_Normal_MeanVariance;
begin
  AssertNear(5.0, TProbabilityKit.NormalMean(5, 2), EPS, 'Normal Mean');
  AssertNear(4.0, TProbabilityKit.NormalVariance(5, 2), EPS, 'Normal Variance');
end;

procedure TTestProbabilityLib.Test07_Normal_BadSigma_Raises;
begin
  AssertException('NormalPDF bad sigma', EProbabilityError, @DoNormalPDF_BadSigma);
  AssertException('NormalCDF zero sigma', EProbabilityError, @DoNormalCDF_BadSigma);
end;

{ ===========================================================================
  LOGNORMAL
=========================================================================== }

procedure TTestProbabilityLib.Test08_LogNormal_PDF;
begin
  { LogNormal(0,1) at x=1: 1/sqrt(2*pi) ≈ 0.398942  (since ln(1)=0) }
  AssertNear(0.398942, TProbabilityKit.LogNormalPDF(1, 0, 1), EPS, 'LogNormal PDF at 1');
end;

procedure TTestProbabilityLib.Test09_LogNormal_CDF;
begin
  { CDF(1; 0, 1) = Φ(0) = 0.5 }
  AssertNear(0.5, TProbabilityKit.LogNormalCDF(1, 0, 1), EPS, 'LogNormal CDF at 1');
end;

procedure TTestProbabilityLib.Test10_LogNormal_Survival;
begin
  { Survival = 1 - CDF }
  AssertNear(0.5, TProbabilityKit.LogNormalSurvival(1, 0, 1), EPS, 'LogNormal Survival at 1');
end;

procedure TTestProbabilityLib.Test11_LogNormal_MeanVariance;
begin
  { LogNormal(0,1): Mean = exp(0.5) ≈ 1.6487, Var = (e-1)*e ≈ 4.6708 }
  AssertNear(1.6487212, TProbabilityKit.LogNormalMean(0, 1), EPS, 'LogNormal Mean');
  AssertNear(4.6707743, TProbabilityKit.LogNormalVariance(0, 1), EPS2, 'LogNormal Variance');
end;

{ ===========================================================================
  EXPONENTIAL
=========================================================================== }

procedure TTestProbabilityLib.Test12_Exponential_PDF;
begin
  { Exp(2) at x=1: 2*exp(-2) ≈ 0.270671 }
  AssertNear(0.270671, TProbabilityKit.ExponentialPDF(1, 2), EPS, 'Exponential PDF');
end;

procedure TTestProbabilityLib.Test13_Exponential_CDF;
begin
  { Exp(1) at x=1: 1 - e^(-1) ≈ 0.632121 }
  AssertNear(0.632121, TProbabilityKit.ExponentialCDF(1, 1), EPS, 'Exponential CDF');
end;

procedure TTestProbabilityLib.Test14_Exponential_Survival;
begin
  { Exp(1) survival at x=1: e^(-1) ≈ 0.367879 }
  AssertNear(0.367879, TProbabilityKit.ExponentialSurvival(1, 1), EPS, 'Exponential Survival');
end;

procedure TTestProbabilityLib.Test15_Exponential_MeanVariance;
begin
  { Exp(2): Mean=0.5, Variance=0.25 }
  AssertNear(0.5,  TProbabilityKit.ExponentialMean(2),     EPS, 'Exponential Mean');
  AssertNear(0.25, TProbabilityKit.ExponentialVariance(2), EPS, 'Exponential Variance');
end;

procedure TTestProbabilityLib.Test16_Exponential_NegativeX_Zero;
begin
  { PDF and CDF are 0 for x < 0 }
  AssertNear(0, TProbabilityKit.ExponentialPDF(-1, 1), EPS, 'Exponential PDF neg x');
  AssertNear(0, TProbabilityKit.ExponentialCDF(-5, 2), EPS, 'Exponential CDF neg x');
end;

procedure TTestProbabilityLib.Test17_Exponential_BadLambda_Raises;
begin
  AssertException('Exp bad lambda', EProbabilityError, @DoExponentialPDF_BadLambda);
end;

{ ===========================================================================
  GAMMA
=========================================================================== }

procedure TTestProbabilityLib.Test18_Gamma_PDF;
begin
  { Gamma(2, 1) at x=2: x*exp(-x) at x=2 = 2*e^-2 ≈ 0.270671 }
  AssertNear(0.270671, TProbabilityKit.GammaPDF(2, 2, 1), EPS, 'Gamma PDF');
end;

procedure TTestProbabilityLib.Test19_Gamma_CDF;
begin
  { Gamma(1,1) = Exponential(1): CDF(1) ≈ 0.632121 }
  AssertNear(0.632121, TProbabilityKit.GammaCDF(1, 1, 1), EPS, 'Gamma CDF (Exp special case)');
end;

procedure TTestProbabilityLib.Test20_Gamma_Survival;
begin
  AssertNear(1.0 - TProbabilityKit.GammaCDF(2, 2, 1),
             TProbabilityKit.GammaSurvival(2, 2, 1), EPS, 'Gamma Survival');
end;

procedure TTestProbabilityLib.Test21_Gamma_MeanVariance;
begin
  { Gamma(3, 2): Mean=1.5, Var=0.75 }
  AssertNear(1.5,  TProbabilityKit.GammaMean(3, 2),     EPS, 'Gamma Mean');
  AssertNear(0.75, TProbabilityKit.GammaVariance(3, 2), EPS, 'Gamma Variance');
end;

procedure TTestProbabilityLib.Test22_Gamma_BadParams_Raises;
begin
  AssertException('Gamma bad alpha', EProbabilityError, @DoGammaPDF_BadAlpha);
  AssertException('Gamma bad beta',  EProbabilityError, @DoGammaPDF_BadBeta);
end;

{ ===========================================================================
  BETA
=========================================================================== }

procedure TTestProbabilityLib.Test23_Beta_PDF;
begin
  { Beta(2,2) at x=0.5: f(0.5) = 6*0.5*0.5 = 1.5 }
  AssertNear(1.5, TProbabilityKit.BetaPDF(0.5, 2, 2), EPS, 'Beta PDF');
end;

procedure TTestProbabilityLib.Test24_Beta_CDF;
begin
  { Beta(1,1) = Uniform(0,1): CDF(0.3) = 0.3 }
  AssertNear(0.3, TProbabilityKit.BetaCDF(0.3, 1, 1), EPS, 'Beta CDF (Uniform)');
end;

procedure TTestProbabilityLib.Test25_Beta_Survival;
begin
  AssertNear(1 - TProbabilityKit.BetaCDF(0.4, 2, 3),
             TProbabilityKit.BetaSurvival(0.4, 2, 3), EPS, 'Beta Survival');
end;

procedure TTestProbabilityLib.Test26_Beta_MeanVariance;
begin
  { Beta(2,5): Mean=2/7≈0.2857, Var=2*5/(7^2*8)≈0.0255 }
  AssertNear(2/7,         TProbabilityKit.BetaMean(2, 5),     EPS, 'Beta Mean');
  AssertNear(10/392,      TProbabilityKit.BetaVariance(2, 5), EPS, 'Beta Variance');
end;

procedure TTestProbabilityLib.Test27_Beta_Uniform_Special_Case;
begin
  { Beta(1,1) PDF = 1 everywhere on (0,1) }
  AssertNear(1.0, TProbabilityKit.BetaPDF(0.5, 1, 1), EPS, 'Beta(1,1) = Uniform PDF');
  AssertNear(1.0, TProbabilityKit.BetaPDF(0.1, 1, 1), EPS, 'Beta(1,1) = Uniform PDF at 0.1');
end;

{ ===========================================================================
  CHI-SQUARED
=========================================================================== }

procedure TTestProbabilityLib.Test28_ChiSquared_PDF;
begin
  { Chi2(2) at x=2: (1/2)*exp(-1) ≈ 0.183940 }
  AssertNear(0.183940, TProbabilityKit.ChiSquaredPDF(2, 2), EPS, 'ChiSq PDF');
end;

procedure TTestProbabilityLib.Test29_ChiSquared_CDF;
begin
  { Chi2(2) CDF at x=2: 1 - exp(-1) ≈ 0.632121 }
  AssertNear(0.632121, TProbabilityKit.ChiSquaredCDF(2, 2), EPS, 'ChiSq CDF');
end;

procedure TTestProbabilityLib.Test30_ChiSquared_Survival;
begin
  { p-value from chi2(1) at x=3.841: classical 95% critical value → p≈0.05 }
  AssertNear(0.05, TProbabilityKit.ChiSquaredSurvival(3.841, 1), 1E-3, 'ChiSq Survival 95%');
end;

procedure TTestProbabilityLib.Test31_ChiSquared_MeanVariance;
begin
  AssertNear(5.0,  TProbabilityKit.ChiSquaredMean(5),     EPS, 'ChiSq Mean');
  AssertNear(10.0, TProbabilityKit.ChiSquaredVariance(5), EPS, 'ChiSq Variance');
end;

procedure TTestProbabilityLib.Test32_ChiSquared_BadDF_Raises;
begin
  AssertException('ChiSq bad DF', EProbabilityError, @DoChiSqCDF_BadDF);
end;

{ ===========================================================================
  STUDENT'S T
=========================================================================== }

procedure TTestProbabilityLib.Test33_StudentT_PDF;
begin
  { t(1) at x=0: 1/(pi) ≈ 0.318310 }
  AssertNear(1/Pi, TProbabilityKit.StudentTPDF(0, 1), EPS, 'StudentT PDF (Cauchy) at 0');
end;

procedure TTestProbabilityLib.Test34_StudentT_CDF;
begin
  { t(∞) → Normal; t(30) at 1.96 ≈ Normal CDF 1.96 within 1e-3 }
  AssertNear(0.5, TProbabilityKit.StudentTCDF(0, 10), EPS, 'StudentT CDF at 0 = 0.5');
end;

procedure TTestProbabilityLib.Test35_StudentT_Survival;
begin
  { Survival(0) = 0.5 by symmetry }
  AssertNear(0.5, TProbabilityKit.StudentTSurvival(0, 5), EPS, 'StudentT Survival at 0');
end;

procedure TTestProbabilityLib.Test36_StudentT_TwoTail;
begin
  { Two-tail at 0: P(|T|>0) = 1 }
  AssertNear(1.0, TProbabilityKit.StudentTTwoTail(0, 5), EPS, 'StudentT TwoTail at 0');
  { t(30) two-tail at 2.042 ≈ 0.05 }
  AssertNear(0.05, TProbabilityKit.StudentTTwoTail(2.042, 30), 5E-3, 'StudentT TwoTail 5%');
end;

procedure TTestProbabilityLib.Test37_StudentT_MeanVariance;
begin
  AssertNear(0.0,              TProbabilityKit.StudentTMean(5),     EPS, 'StudentT Mean');
  AssertNear(5.0/3.0,          TProbabilityKit.StudentTVariance(5), EPS, 'StudentT Variance');
end;

procedure TTestProbabilityLib.Test38_StudentT_BadDF_Raises;
begin
  AssertException('StudentT bad DF', EProbabilityError, @DoStudentTPDF_BadDF);
  AssertException('StudentT Var DF<=2', EProbabilityError, @DoStudentTVariance_BadDF);
end;

{ ===========================================================================
  F DISTRIBUTION
=========================================================================== }

procedure TTestProbabilityLib.Test39_F_PDF;
begin
  { F(1,1) at x=1: computed via Wolfram ≈ 0.159155 }
  AssertNear(0.159155, TProbabilityKit.FPDF(1, 1, 1), EPS2, 'F PDF');
end;

procedure TTestProbabilityLib.Test40_F_CDF;
begin
  { F(5,10) CDF at x=3.326 ≈ 0.95 (5% upper critical) }
  AssertNear(0.95, TProbabilityKit.FCDF(3.326, 5, 10), 1E-3, 'F CDF at 95th pct');
end;

procedure TTestProbabilityLib.Test41_F_Survival;
begin
  { Survival = 1 - CDF }
  AssertNear(1 - TProbabilityKit.FCDF(2.0, 3, 6),
             TProbabilityKit.FSurvival(2.0, 3, 6), EPS, 'F Survival');
end;

procedure TTestProbabilityLib.Test42_F_MeanVariance;
begin
  { F(4,10): Mean=10/8=1.25, Var computed from formula }
  AssertNear(1.25, TProbabilityKit.FMean(4, 10), EPS, 'F Mean');
  AssertNear(2*100*12/(4*64*6), TProbabilityKit.FVariance(4, 10), EPS, 'F Variance');
end;

{ ===========================================================================
  WEIBULL
=========================================================================== }

procedure TTestProbabilityLib.Test43_Weibull_PDF;
begin
  { Weibull(1,1) = Exp(1): PDF(1) = e^(-1) ≈ 0.367879 }
  AssertNear(0.367879, TProbabilityKit.WeibullPDF(1, 1, 1), EPS, 'Weibull PDF (Exp)');
end;

procedure TTestProbabilityLib.Test44_Weibull_CDF;
begin
  { Weibull(1,1) = Exp(1): CDF(1) = 1 - e^(-1) ≈ 0.632121 }
  AssertNear(0.632121, TProbabilityKit.WeibullCDF(1, 1, 1), EPS, 'Weibull CDF (Exp)');
end;

procedure TTestProbabilityLib.Test45_Weibull_Survival;
begin
  AssertNear(Exp(-1), TProbabilityKit.WeibullSurvival(1, 1, 1), EPS, 'Weibull Survival');
end;

procedure TTestProbabilityLib.Test46_Weibull_MeanVariance;
begin
  { Weibull(1,2): same as Exp(0.5). Mean=2, Var=4 }
  AssertNear(2.0, TProbabilityKit.WeibullMean(1, 2),     EPS, 'Weibull Mean (Exp)');
  AssertNear(4.0, TProbabilityKit.WeibullVariance(1, 2), EPS, 'Weibull Variance (Exp)');
end;

procedure TTestProbabilityLib.Test47_Weibull_Exponential_SpecialCase;
begin
  { Weibull(K=1, Lambda) is identical to Exponential(rate=1/Lambda) }
  AssertNear(TProbabilityKit.ExponentialCDF(2, 0.5),
             TProbabilityKit.WeibullCDF(2, 1, 2), EPS, 'Weibull == Exponential');
end;

{ ===========================================================================
  UNIFORM
=========================================================================== }

procedure TTestProbabilityLib.Test48_Uniform_PDF_Inside;
begin
  { Uniform(0,4): PDF = 0.25 everywhere inside }
  AssertNear(0.25, TProbabilityKit.UniformPDF(2, 0, 4), EPS, 'Uniform PDF inside');
end;

procedure TTestProbabilityLib.Test49_Uniform_PDF_Outside;
begin
  { Outside bounds → 0 }
  AssertNear(0, TProbabilityKit.UniformPDF(-1, 0, 4), EPS, 'Uniform PDF outside left');
  AssertNear(0, TProbabilityKit.UniformPDF(5,  0, 4), EPS, 'Uniform PDF outside right');
end;

procedure TTestProbabilityLib.Test50_Uniform_CDF;
begin
  { Uniform(2,6) CDF at x=4: (4-2)/(6-2) = 0.5 }
  AssertNear(0.5, TProbabilityKit.UniformCDF(4, 2, 6), EPS, 'Uniform CDF midpoint');
  AssertNear(0.0, TProbabilityKit.UniformCDF(1, 2, 6), EPS, 'Uniform CDF below A');
  AssertNear(1.0, TProbabilityKit.UniformCDF(7, 2, 6), EPS, 'Uniform CDF above B');
end;

procedure TTestProbabilityLib.Test51_Uniform_Survival;
begin
  AssertNear(0.5, TProbabilityKit.UniformSurvival(4, 2, 6), EPS, 'Uniform Survival');
end;

procedure TTestProbabilityLib.Test52_Uniform_MeanVariance;
begin
  { Uniform(0,1): Mean=0.5, Var=1/12 }
  AssertNear(0.5,       TProbabilityKit.UniformMean(0, 1),     EPS, 'Uniform Mean');
  AssertNear(1.0/12.0,  TProbabilityKit.UniformVariance(0, 1), EPS, 'Uniform Variance');
end;

{ ===========================================================================
  BINOMIAL
=========================================================================== }

procedure TTestProbabilityLib.Test53_Binomial_PMF_FairCoin;
begin
  { P(X=3; n=10, p=0.5) = C(10,3)*0.5^10 ≈ 0.117188 }
  AssertNear(0.117188, TProbabilityKit.BinomialPMF(3, 10, 0.5), EPS2, 'Binomial PMF 3/10');
end;

procedure TTestProbabilityLib.Test54_Binomial_PMF_AllHeads;
begin
  { P(X=5; n=5, p=0.5) = 0.5^5 = 0.03125 }
  AssertNear(0.03125, TProbabilityKit.BinomialPMF(5, 5, 0.5), EPS, 'Binomial all success');
end;

procedure TTestProbabilityLib.Test55_Binomial_CDF;
begin
  { P(X<=3; n=10, p=0.5): sum = 0.171875 }
  AssertNear(0.171875, TProbabilityKit.BinomialCDF(3, 10, 0.5), EPS2, 'Binomial CDF');
end;

procedure TTestProbabilityLib.Test56_Binomial_Survival;
begin
  AssertNear(1 - TProbabilityKit.BinomialCDF(3, 10, 0.5),
             TProbabilityKit.BinomialSurvival(3, 10, 0.5), EPS, 'Binomial Survival');
end;

procedure TTestProbabilityLib.Test57_Binomial_MeanVariance;
begin
  { n=10, p=0.3: Mean=3, Var=2.1 }
  AssertNear(3.0, TProbabilityKit.BinomialMean(10, 0.3),     EPS, 'Binomial Mean');
  AssertNear(2.1, TProbabilityKit.BinomialVariance(10, 0.3), EPS, 'Binomial Variance');
end;

procedure TTestProbabilityLib.Test58_Binomial_OutOfRange_Zero;
begin
  { k > n → 0; k < 0 → 0 }
  AssertNear(0, TProbabilityKit.BinomialPMF(11, 10, 0.5), EPS, 'Binomial k>n → 0');
  AssertNear(0, TProbabilityKit.BinomialPMF(-1, 10, 0.5), EPS, 'Binomial k<0 → 0');
end;

procedure TTestProbabilityLib.Test59_Binomial_BadParams_Raises;
begin
  AssertException('Binomial N=0',    EProbabilityError, @DoBinomialPMF_BadN);
  AssertException('Binomial P=1.5',  EProbabilityError, @DoBinomialPMF_BadP);
end;

{ ===========================================================================
  POISSON
=========================================================================== }

procedure TTestProbabilityLib.Test60_Poisson_PMF;
begin
  { P(X=2; lambda=3) = e^(-3)*9/2 ≈ 0.224042 }
  AssertNear(0.224042, TProbabilityKit.PoissonPMF(2, 3), EPS, 'Poisson PMF');
end;

procedure TTestProbabilityLib.Test61_Poisson_CDF;
begin
  { P(X<=2; lambda=3) = e^(-3)*(1+3+4.5) ≈ 0.423190 }
  AssertNear(0.423190, TProbabilityKit.PoissonCDF(2, 3), EPS2, 'Poisson CDF');
end;

procedure TTestProbabilityLib.Test62_Poisson_Survival;
begin
  AssertNear(1 - TProbabilityKit.PoissonCDF(2, 3),
             TProbabilityKit.PoissonSurvival(2, 3), EPS, 'Poisson Survival');
end;

procedure TTestProbabilityLib.Test63_Poisson_MeanVariance;
begin
  { Both equal lambda }
  AssertNear(4.5, TProbabilityKit.PoissonMean(4.5),     EPS, 'Poisson Mean');
  AssertNear(4.5, TProbabilityKit.PoissonVariance(4.5), EPS, 'Poisson Variance');
end;

procedure TTestProbabilityLib.Test64_Poisson_BadLambda_Raises;
begin
  AssertException('Poisson bad lambda', EProbabilityError, @DoPoissonPMF_BadLambda);
end;

{ ===========================================================================
  GEOMETRIC
=========================================================================== }

procedure TTestProbabilityLib.Test65_Geometric_PMF;
begin
  { P(X=3; p=0.5) = 0.25*0.5 = 0.125 }
  AssertNear(0.125, TProbabilityKit.GeometricPMF(3, 0.5), EPS, 'Geometric PMF');
end;

procedure TTestProbabilityLib.Test66_Geometric_CDF;
begin
  { P(X<=3; p=0.5) = 1 - 0.5^3 = 0.875 }
  AssertNear(0.875, TProbabilityKit.GeometricCDF(3, 0.5), EPS, 'Geometric CDF');
end;

procedure TTestProbabilityLib.Test67_Geometric_Survival;
begin
  { P(X>3; p=0.5) = 0.5^3 = 0.125 }
  AssertNear(0.125, TProbabilityKit.GeometricSurvival(3, 0.5), EPS, 'Geometric Survival');
end;

procedure TTestProbabilityLib.Test68_Geometric_MeanVariance;
begin
  { p=0.25: Mean=4, Var=12 }
  AssertNear(4.0,  TProbabilityKit.GeometricMean(0.25),     EPS, 'Geometric Mean');
  AssertNear(12.0, TProbabilityKit.GeometricVariance(0.25), EPS, 'Geometric Variance');
end;

procedure TTestProbabilityLib.Test69_Geometric_BadP_Raises;
begin
  AssertException('Geometric P=0', EProbabilityError, @DoGeometricPMF_BadP);
end;

{ ===========================================================================
  NEGATIVE BINOMIAL
=========================================================================== }

procedure TTestProbabilityLib.Test70_NegBinomial_PMF;
begin
  { P(X=5; r=3, p=0.5) = C(4,2)*0.5^5 = 6/32 = 0.1875 }
  AssertNear(0.1875, TProbabilityKit.NegBinomialPMF(5, 3, 0.5), EPS, 'NegBinomial PMF');
end;

procedure TTestProbabilityLib.Test71_NegBinomial_CDF;
begin
  { k < r → 0 }
  AssertNear(0, TProbabilityKit.NegBinomialCDF(2, 3, 0.5), EPS, 'NegBinomial CDF k<r');
  { k = r: only way is all successes → p^r = 0.5^3 = 0.125 }
  AssertNear(0.125, TProbabilityKit.NegBinomialCDF(3, 3, 0.5), EPS, 'NegBinomial CDF k=r');
end;

procedure TTestProbabilityLib.Test72_NegBinomial_MeanVariance;
begin
  { r=3, p=0.5: Mean=6, Var=6 }
  AssertNear(6.0, TProbabilityKit.NegBinomialMean(3, 0.5),     EPS, 'NegBinomial Mean');
  AssertNear(6.0, TProbabilityKit.NegBinomialVariance(3, 0.5), EPS, 'NegBinomial Variance');
end;

{ ===========================================================================
  HYPERGEOMETRIC
=========================================================================== }

procedure TTestProbabilityLib.Test73_Hypergeometric_PMF;
begin
  { N=20, K=7 successes, n=5 drawn: P(X=2) via formula
    = C(7,2)*C(13,3)/C(20,5) = 21*286/15504 ≈ 0.38738 }
  AssertNear(0.38738, TProbabilityKit.HypergeometricPMF(2, 20, 7, 5), EPS2,
    'Hypergeometric PMF');
end;

procedure TTestProbabilityLib.Test74_Hypergeometric_CDF;
begin
  { CDF at max possible k = n should be 1 }
  AssertNear(1.0, TProbabilityKit.HypergeometricCDF(5, 20, 7, 5), EPS, 'Hypergeometric CDF full');
end;

procedure TTestProbabilityLib.Test75_Hypergeometric_MeanVariance;
begin
  { N=20, K=7, n=5: Mean = 5*7/20 = 1.75, Var = 5*(7/20)*(13/20)*(15/19) }
  AssertNear(1.75, TProbabilityKit.HypergeometricMean(20, 7, 5), EPS, 'Hypergeometric Mean');
  AssertNear(5*(7/20)*(13/20)*(15/19),
             TProbabilityKit.HypergeometricVariance(20, 7, 5), EPS, 'Hypergeometric Variance');
end;

{ ===========================================================================
  ROUNDING via ADecimals
=========================================================================== }

procedure TTestProbabilityLib.Test76_NormalCDF_Rounded;
var
  Raw, Rounded: Double;
begin
  Raw     := TProbabilityKit.NormalCDF(1.96, 0, 1);         { no rounding }
  Rounded := TProbabilityKit.NormalCDF(1.96, 0, 1, 4);      { 4 dp }
  { Rounded value must differ from raw by less than 0.00005 }
  AssertNear(Raw, Rounded, 0.00005, 'Rounding within 4dp');
  { And must be a multiple of 0.0001 }
  AssertNear(0, Frac(Rounded * 10000), 1E-9, 'Rounded is 4dp');
end;

procedure TTestProbabilityLib.Test77_BinomialPMF_Rounded;
var
  Raw, Rounded: Double;
begin
  Raw     := TProbabilityKit.BinomialPMF(3, 10, 0.5);
  Rounded := TProbabilityKit.BinomialPMF(3, 10, 0.5, 3);
  AssertNear(Raw, Rounded, 0.0005, 'Binomial PMF rounding');
end;

procedure TTestProbabilityLib.Test78_ContinuousCDFSurvivalIdentities;
var
  X, Prev, CDFValue: Double;
  I: Integer;
begin
  Prev := 0.0;
  for I := 0 to 20 do
  begin
    X := -4.0 + 0.4 * I;
    CDFValue := TProbabilityKit.NormalCDF(X, 0, 1);
    AssertNear(1.0, CDFValue + TProbabilityKit.NormalSurvival(X, 0, 1),
      2E-15, 'normal CDF + survival');
    AssertTrue('normal CDF monotone', CDFValue >= Prev);
    Prev := CDFValue;
  end;
  for I := 0 to 20 do
  begin
    X := I * 0.5;
    AssertNear(1.0, TProbabilityKit.GammaCDF(X, 2.5, 1.3) +
      TProbabilityKit.GammaSurvival(X, 2.5, 1.3), 2E-12,
      'gamma CDF + survival');
  end;
  for I := 0 to 20 do
  begin
    X := I / 20.0;
    AssertNear(1.0, TProbabilityKit.BetaCDF(X, 2.0, 5.0) +
      TProbabilityKit.BetaSurvival(X, 2.0, 5.0), 2E-12,
      'beta CDF + survival');
  end;
end;

procedure TTestProbabilityLib.Test79_SymmetricDistributionProperties;
var
  X: Double;
  I: Integer;
begin
  for I := 0 to 10 do
  begin
    X := I / 3.0;
    AssertNear(1.0, TProbabilityKit.NormalCDF(X, 0, 1) +
      TProbabilityKit.NormalCDF(-X, 0, 1), 2E-9, 'normal symmetry');
    AssertNear(1.0, TProbabilityKit.StudentTCDF(X, 9) +
      TProbabilityKit.StudentTCDF(-X, 9), 2E-12, 'Student t symmetry');
  end;
end;

procedure TTestProbabilityLib.Test80_BinomialPMFSumsToOne;
var
  K: Integer;
  Total: Double;
begin
  Total := 0.0;
  for K := 0 to 20 do Total := Total + TProbabilityKit.BinomialPMF(K, 20, 0.37);
  AssertNear(1.0, Total, 1E-10, 'binomial normalization');
end;

procedure TTestProbabilityLib.Test81_PoissonPMFSumsToOne;
var
  K: Integer;
  Total: Double;
begin
  Total := 0.0;
  for K := 0 to 100 do Total := Total + TProbabilityKit.PoissonPMF(K, 7.0);
  AssertNear(1.0, Total, 1E-12, 'Poisson normalization');
end;

procedure TTestProbabilityLib.Test82_HypergeometricPMFSumsToOne;
var
  K: Integer;
  Total: Double;
begin
  Total := 0.0;
  for K := 0 to 12 do
    Total := Total + TProbabilityKit.HypergeometricPMF(K, 40, 12, 15);
  AssertNear(1.0, Total, 5E-12, 'hypergeometric normalization');
end;

procedure TTestProbabilityLib.Test83_MomentValidationRegression;
begin
  AssertException('normal mean validates sigma', EProbabilityError,
    @DoNormalMean_BadSigma);
  AssertException('gamma mean validates alpha', EProbabilityError,
    @DoGammaMean_BadAlpha);
  AssertException('uniform mean validates bounds', EProbabilityError,
    @DoUniformMean_BadBounds);
  AssertException('binomial mean validates N', EProbabilityError,
    @DoBinomialMean_BadN);
  AssertException('Poisson mean validates lambda', EProbabilityError,
    @DoPoissonMean_BadLambda);
  AssertException('negative-binomial mean validates R', EProbabilityError,
    @DoNegBinomialMean_BadR);
  AssertException('hypergeometric mean validates negative counts',
    EProbabilityError, @DoHypergeometricMean_Negative);
  AssertException('distribution inputs must be finite', EProbabilityError,
    @DoNormalCDF_NonFinite);
end;

procedure TTestProbabilityLib.Test84_DiscreteBoundaryRegression;
begin
  AssertNear(1.0, TProbabilityKit.NegBinomialPMF(3, 3, 1.0), EPS,
    'negative binomial P=1 at K=R');
  AssertNear(0.0, TProbabilityKit.NegBinomialPMF(4, 3, 1.0), EPS,
    'negative binomial P=1 after K=R');
  AssertNear(1.0, TProbabilityKit.NegBinomialCDF(3, 3, 1.0), EPS,
    'negative binomial CDF P=1');
  AssertNear(0.0, TProbabilityKit.HypergeometricVariance(1, 1, 1), EPS,
    'single-item hypergeometric variance');
end;

initialization
  RegisterTest(TTestProbabilityLib);

end.
