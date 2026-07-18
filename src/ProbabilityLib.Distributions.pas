unit ProbabilityLib.Distributions;

{-----------------------------------------------------------------------------
 ProbabilityLib.Distributions

 A beginner-friendly probability distributions unit for Free Pascal.

 What this domain unit gives you
 ---------------------------
 For each supported distribution you get five things:
   PDF  — probability density (continuous) or mass (discrete) at a point
   CDF  — cumulative probability P(X <= x)
   Survival — upper tail P(X > x)  = 1 - CDF
   Mean     — expected value
   Variance — spread measure

 Supported distributions
 -----------------------
  Continuous
    Normal        — bell curve, the most common distribution
    LogNormal     — Normal on the log scale; always positive
    Exponential   — time between random events
    Gamma         — generalised Exponential; shape+rate parametrisation
    Beta          — probabilities and proportions, lives on [0,1]
    ChiSquared    — sum of squared standard Normals; used in hypothesis tests
    StudentT      — like Normal but heavier tails; used with small samples
    FDist         — ratio of Chi-Squared variables; used in ANOVA
    Weibull       — lifetime/reliability modelling; shape+scale parametrisation
    Uniform       — every value in [a,b] equally likely

  Discrete
    Binomial      — number of successes in N independent yes/no trials
    Poisson       — number of events in a fixed time interval
    Geometric     — number of trials until the first success
    NegBinomial   — number of trials until R successes
    Hypergeometric — sampling without replacement (e.g. quality control)

 How to use — quick start
 ------------------------
   uses ProbabilityLib.Distributions;

   // What is P(X <= 1.96) for a standard Normal?
   p := TProbabilityKit.NormalCDF(1.96, 0, 1);   // ~0.975

   // What is the probability of exactly 3 heads in 10 fair coin flips?
   p := TProbabilityKit.BinomialPMF(3, 10, 0.5); // ~0.117

   // All methods are static — no object creation needed.

 Design notes
 ------------
 - All methods are class static: call TProbabilityKit.XXX directly.
 - Parameters follow the convention (x, distribution params...).
 - Optional ADecimals rounds the result (default = -1 means no rounding).
 - Every public entry point validates finite real parameters and the documented
   distribution domain, raising EProbabilityError on invalid input.
 - Depends only on MathBase.Precision and MathBase.SharedTypes.
-----------------------------------------------------------------------------}

{$mode objfpc}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Math,
  MathBase.SharedTypes,
  MathBase.Precision;

type
  { Raised when you pass invalid parameters to a distribution function }
  EProbabilityError = class(Exception);

  { -------------------------------------------------------------------------
    TProbabilityKit
    All methods are class static — just call TProbabilityKit.XXX(...)
    No object creation or Free() needed.
  ------------------------------------------------------------------------- }
  TProbabilityKit = class
  private
    { Round to ADecimals places; pass -1 to skip rounding }
    class function RoundResult(const V: Double; ADecimals: Integer): Double; static;

    { Internal: ln(n!) using Stirling / GammaLn for large n }
    class function LogFactorial(N: Integer): Double; static;

    { Internal: ln of binomial coefficient C(n,k) }
    class function LogBinomCoeff(N, K: Integer): Double; static;

    class procedure RequireFinite(const V: Double; const Name: string); static;
    class procedure RequirePositive(const V: Double; const Name: string); static;
    class procedure RequireProbability(const P: Double; AllowZero: Boolean;
      const Name: string); static;
    class procedure ValidateHypergeometric(PopSize, SuccPop,
      SampleN: Integer; const Name: string); static;

  public

    { =======================================================================
      NORMAL DISTRIBUTION  (bell curve)

      Parameters
        Mu    — mean (centre of the bell); any real number
        Sigma — standard deviation (width); must be > 0

      Use when: modelling heights, measurement errors, test scores,
                or any quantity that is the sum of many small effects.
    ======================================================================= }

    { PDF: height of the bell curve at X.
      Result is the probability density, NOT a probability itself.
      Example: NormalPDF(0, 0, 1) = 0.3989  (peak of the standard Normal) }
    class function NormalPDF(const X, Mu, Sigma: Double; ADecimals: Integer = -1): Double; static;

    { CDF: P(X <= x) — area under the bell curve to the left of x.
      Example: NormalCDF(1.96, 0, 1) ≈ 0.975  (classic 95% one-tail) }
    class function NormalCDF(const X, Mu, Sigma: Double; ADecimals: Integer = -1): Double; static;

    { Survival: P(X > x) = 1 - CDF.  Upper tail probability.
      Example: NormalSurvival(1.96, 0, 1) ≈ 0.025 }
    class function NormalSurvival(const X, Mu, Sigma: Double; ADecimals: Integer = -1): Double; static;

    { Mean of the Normal distribution = Mu }
    class function NormalMean(const Mu, Sigma: Double): Double; static;

    { Variance of the Normal distribution = Sigma^2 }
    class function NormalVariance(const Mu, Sigma: Double): Double; static;


    { =======================================================================
      LOGNORMAL DISTRIBUTION

      Parameters
        Mu    — mean of the underlying Normal (log-scale)
        Sigma — std dev of the underlying Normal (log-scale); must be > 0

      Use when: modelling stock prices, incomes, or any quantity that is
                always positive and right-skewed.
      Note: if Y ~ Normal(Mu, Sigma) then X = exp(Y) ~ LogNormal(Mu, Sigma).
    ======================================================================= }

    { PDF: probability density of the LogNormal at X (X must be > 0). }
    class function LogNormalPDF(const X, Mu, Sigma: Double; ADecimals: Integer = -1): Double; static;

    { CDF: P(X <= x). }
    class function LogNormalCDF(const X, Mu, Sigma: Double; ADecimals: Integer = -1): Double; static;

    { Survival: P(X > x) = 1 - CDF. }
    class function LogNormalSurvival(const X, Mu, Sigma: Double; ADecimals: Integer = -1): Double; static;

    { Mean = exp(Mu + Sigma^2 / 2) }
    class function LogNormalMean(const Mu, Sigma: Double): Double; static;

    { Variance = (exp(Sigma^2) - 1) * exp(2*Mu + Sigma^2) }
    class function LogNormalVariance(const Mu, Sigma: Double): Double; static;


    { =======================================================================
      EXPONENTIAL DISTRIBUTION

      Parameter
        Lambda — rate (events per unit time); must be > 0
        (Scale = 1/Lambda is the average waiting time)

      Use when: modelling the time between random independent events,
                e.g. time between bus arrivals, radioactive decay.
    ======================================================================= }

    { PDF: probability density at X (X must be >= 0). }
    class function ExponentialPDF(const X, Lambda: Double; ADecimals: Integer = -1): Double; static;

    { CDF: P(X <= x) = 1 - exp(-Lambda * x). }
    class function ExponentialCDF(const X, Lambda: Double; ADecimals: Integer = -1): Double; static;

    { Survival: P(X > x) = exp(-Lambda * x).
      This is the "reliability function" — probability of surviving past x. }
    class function ExponentialSurvival(const X, Lambda: Double; ADecimals: Integer = -1): Double; static;

    { Mean = 1 / Lambda }
    class function ExponentialMean(const Lambda: Double): Double; static;

    { Variance = 1 / Lambda^2 }
    class function ExponentialVariance(const Lambda: Double): Double; static;


    { =======================================================================
      GAMMA DISTRIBUTION

      Parameters
        Alpha — shape (must be > 0); controls the "hump" shape
        Beta  — rate  (must be > 0); scale = 1/Beta

      Relationship to other distributions
        Gamma(1, Lambda) = Exponential(Lambda)
        Gamma(k/2, 1/2)  = ChiSquared(k)

      Use when: modelling waiting times for multiple events, rainfall totals,
                or as a prior distribution for rates/precisions in Bayesian stats.
    ======================================================================= }

    { PDF: probability density at X (X must be > 0). }
    class function GammaPDF(const X, Alpha, Beta: Double; ADecimals: Integer = -1): Double; static;

    { CDF: P(X <= x), computed via regularised incomplete gamma function. }
    class function GammaCDF(const X, Alpha, Beta: Double; ADecimals: Integer = -1): Double; static;

    { Survival: P(X > x) = 1 - CDF. }
    class function GammaSurvival(const X, Alpha, Beta: Double; ADecimals: Integer = -1): Double; static;

    { Mean = Alpha / Beta }
    class function GammaMean(const Alpha, Beta: Double): Double; static;

    { Variance = Alpha / Beta^2 }
    class function GammaVariance(const Alpha, Beta: Double): Double; static;


    { =======================================================================
      BETA DISTRIBUTION

      Parameters
        Alpha — shape parameter (must be > 0)
        Beta  — shape parameter (must be > 0)

      Domain: X in [0, 1]  (probabilities or proportions)

      Special cases
        Beta(1,1) = Uniform(0,1)
        Alpha < 1 and Beta < 1 → U-shaped (bimodal)
        Alpha > 1 and Beta > 1 → single peak

      Use when: modelling probabilities, click-through rates, conversion rates,
                or Bayesian posteriors for a probability parameter.
    ======================================================================= }

    { PDF: probability density at X (X must be in (0,1)). }
    class function BetaPDF(const X, Alpha, Beta: Double; ADecimals: Integer = -1): Double; static;

    { CDF: P(X <= x), computed via regularised incomplete beta function. }
    class function BetaCDF(const X, Alpha, Beta: Double; ADecimals: Integer = -1): Double; static;

    { Survival: P(X > x) = 1 - CDF. }
    class function BetaSurvival(const X, Alpha, Beta: Double; ADecimals: Integer = -1): Double; static;

    { Mean = Alpha / (Alpha + Beta) }
    class function BetaMean(const Alpha, Beta: Double): Double; static;

    { Variance = Alpha*Beta / ((Alpha+Beta)^2 * (Alpha+Beta+1)) }
    class function BetaVariance(const Alpha, Beta: Double): Double; static;


    { =======================================================================
      CHI-SQUARED DISTRIBUTION  (χ²)

      Parameter
        DF — degrees of freedom (positive integer)

      Relationship: ChiSquared(k) = Gamma(k/2, 1/2)
        i.e. the sum of k squared standard Normal variables.

      Use when: goodness-of-fit tests (χ² test), testing independence in
                contingency tables, or computing confidence intervals for variance.
    ======================================================================= }

    { PDF: probability density at X (X must be >= 0). }
    class function ChiSquaredPDF(const X: Double; DF: Integer; ADecimals: Integer = -1): Double; static;

    { CDF: P(X <= x). }
    class function ChiSquaredCDF(const X: Double; DF: Integer; ADecimals: Integer = -1): Double; static;

    { Survival: P(X > x).  This is the p-value from a chi-squared test. }
    class function ChiSquaredSurvival(const X: Double; DF: Integer; ADecimals: Integer = -1): Double; static;

    { Mean = DF }
    class function ChiSquaredMean(DF: Integer): Double; static;

    { Variance = 2 * DF }
    class function ChiSquaredVariance(DF: Integer): Double; static;


    { =======================================================================
      STUDENT'S T DISTRIBUTION

      Parameter
        DF — degrees of freedom (must be >= 1)

      As DF → ∞ the t-distribution approaches Normal(0,1).
      Small DF → heavier tails → more probability in the extremes.

      Use when: computing p-values for t-tests, or building confidence
                intervals for a mean when the sample is small (n < 30).
    ======================================================================= }

    { PDF: probability density at X. }
    class function StudentTPDF(const X: Double; DF: Integer; ADecimals: Integer = -1): Double; static;

    { CDF: P(X <= x). }
    class function StudentTCDF(const X: Double; DF: Integer; ADecimals: Integer = -1): Double; static;

    { Survival: P(X > x). }
    class function StudentTSurvival(const X: Double; DF: Integer; ADecimals: Integer = -1): Double; static;

    { Two-tailed p-value: P(|X| > |x|) = 2 * Survival(|x|).
      Use this when your hypothesis test is two-sided. }
    class function StudentTTwoTail(const X: Double; DF: Integer; ADecimals: Integer = -1): Double; static;

    { Mean = 0 (only defined for DF > 1) }
    class function StudentTMean(DF: Integer): Double; static;

    { Variance = DF / (DF - 2)  (only defined for DF > 2) }
    class function StudentTVariance(DF: Integer): Double; static;


    { =======================================================================
      F DISTRIBUTION

      Parameters
        DF1 — numerator degrees of freedom   (must be >= 1)
        DF2 — denominator degrees of freedom (must be >= 1)

      The F-statistic = (χ²_1/DF1) / (χ²_2/DF2) where χ²_1, χ²_2 are
      independent chi-squared variables.

      Use when: comparing variances (Levene test), ANOVA, or regression
                model fit (F-test for overall significance).
    ======================================================================= }

    { PDF: probability density at X (X must be >= 0). }
    class function FPDF(const X: Double; DF1, DF2: Integer; ADecimals: Integer = -1): Double; static;

    { CDF: P(X <= x). }
    class function FCDF(const X: Double; DF1, DF2: Integer; ADecimals: Integer = -1): Double; static;

    { Survival: P(X > x).  This is the p-value from an F-test. }
    class function FSurvival(const X: Double; DF1, DF2: Integer; ADecimals: Integer = -1): Double; static;

    { Mean = DF2 / (DF2 - 2)  (defined for DF2 > 2) }
    class function FMean(DF1, DF2: Integer): Double; static;

    { Variance (defined for DF2 > 4) }
    class function FVariance(DF1, DF2: Integer): Double; static;


    { =======================================================================
      WEIBULL DISTRIBUTION

      Parameters
        K     — shape (must be > 0)
        Lambda — scale (must be > 0)

      Special cases
        Weibull(1, Lambda) = Exponential(1/Lambda)
        Weibull(2, Lambda) = Rayleigh distribution

      Use when: reliability engineering (time-to-failure), survival analysis,
                modelling wind speeds.  K < 1 → decreasing failure rate;
                K = 1 → constant; K > 1 → increasing failure rate.
    ======================================================================= }

    { PDF: probability density at X (X must be >= 0). }
    class function WeibullPDF(const X, K, Lambda: Double; ADecimals: Integer = -1): Double; static;

    { CDF: P(X <= x) = 1 - exp(-(x/Lambda)^K). }
    class function WeibullCDF(const X, K, Lambda: Double; ADecimals: Integer = -1): Double; static;

    { Survival: P(X > x) = exp(-(x/Lambda)^K).
      This is the "reliability function" used in survival analysis. }
    class function WeibullSurvival(const X, K, Lambda: Double; ADecimals: Integer = -1): Double; static;

    { Mean = Lambda * Gamma(1 + 1/K) }
    class function WeibullMean(const K, Lambda: Double): Double; static;

    { Variance = Lambda^2 * [Gamma(1+2/K) - Gamma(1+1/K)^2] }
    class function WeibullVariance(const K, Lambda: Double): Double; static;


    { =======================================================================
      UNIFORM DISTRIBUTION (continuous)

      Parameters
        A — lower bound
        B — upper bound (must be > A)

      Every value in [A, B] is equally likely.

      Use when: modelling random numbers, rounding errors, or as a
                non-informative prior in Bayesian analysis.
    ======================================================================= }

    { PDF: 1/(B-A) inside [A,B], zero outside. }
    class function UniformPDF(const X, A, B: Double; ADecimals: Integer = -1): Double; static;

    { CDF: (x-A)/(B-A) for x in [A,B]; 0 below A; 1 above B. }
    class function UniformCDF(const X, A, B: Double; ADecimals: Integer = -1): Double; static;

    { Survival: P(X > x) = 1 - CDF. }
    class function UniformSurvival(const X, A, B: Double; ADecimals: Integer = -1): Double; static;

    { Mean = (A + B) / 2 }
    class function UniformMean(const A, B: Double): Double; static;

    { Variance = (B - A)^2 / 12 }
    class function UniformVariance(const A, B: Double): Double; static;


    { =======================================================================
      BINOMIAL DISTRIBUTION (discrete)

      Parameters
        N — number of independent trials (must be >= 1)
        P — probability of success on each trial (must be in [0,1])

      Use when: counting heads in N coin flips, defects in N items,
                correct answers in N quiz questions, etc.
    ======================================================================= }

    { PMF: P(X = k) — probability of exactly K successes in N trials.
      Example: BinomialPMF(3, 10, 0.5) = P(3 heads in 10 flips) ≈ 0.117 }
    class function BinomialPMF(const K, N: Integer; const P: Double; ADecimals: Integer = -1): Double; static;

    { CDF: P(X <= k) — probability of at most K successes. }
    class function BinomialCDF(const K, N: Integer; const P: Double; ADecimals: Integer = -1): Double; static;

    { Survival: P(X > k) = 1 - P(X <= k). }
    class function BinomialSurvival(const K, N: Integer; const P: Double; ADecimals: Integer = -1): Double; static;

    { Mean = N * P }
    class function BinomialMean(const N: Integer; const P: Double): Double; static;

    { Variance = N * P * (1 - P) }
    class function BinomialVariance(const N: Integer; const P: Double): Double; static;


    { =======================================================================
      POISSON DISTRIBUTION (discrete)

      Parameter
        Lambda — average number of events in the interval (must be > 0)

      Use when: counting the number of events in a fixed time or space:
                calls per hour, typos per page, cars per minute at a junction.
    ======================================================================= }

    { PMF: P(X = k) — probability of exactly K events.
      Example: PoissonPMF(2, 3.0) = P(2 events when average is 3) ≈ 0.224 }
    class function PoissonPMF(const K: Integer; const Lambda: Double; ADecimals: Integer = -1): Double; static;

    { CDF: P(X <= k). }
    class function PoissonCDF(const K: Integer; const Lambda: Double; ADecimals: Integer = -1): Double; static;

    { Survival: P(X > k) = 1 - CDF. }
    class function PoissonSurvival(const K: Integer; const Lambda: Double; ADecimals: Integer = -1): Double; static;

    { Mean = Lambda }
    class function PoissonMean(const Lambda: Double): Double; static;

    { Variance = Lambda }
    class function PoissonVariance(const Lambda: Double): Double; static;


    { =======================================================================
      GEOMETRIC DISTRIBUTION (discrete)

      Parameter
        P — probability of success on each trial (must be in (0,1])

      Models the number of trials needed to get the FIRST success.
      (This is the "number of trials" convention, so X >= 1.)

      Use when: rolling a die until you get a six, retrying a network
                request until it succeeds, etc.
    ======================================================================= }

    { PMF: P(X = k) = (1-P)^(k-1) * P  for k = 1, 2, 3, ...
      Example: GeometricPMF(3, 0.5) = P(first success on 3rd flip) = 0.125 }
    class function GeometricPMF(const K: Integer; const P: Double; ADecimals: Integer = -1): Double; static;

    { CDF: P(X <= k) = 1 - (1-P)^k. }
    class function GeometricCDF(const K: Integer; const P: Double; ADecimals: Integer = -1): Double; static;

    { Survival: P(X > k) = (1-P)^k. }
    class function GeometricSurvival(const K: Integer; const P: Double; ADecimals: Integer = -1): Double; static;

    { Mean = 1 / P }
    class function GeometricMean(const P: Double): Double; static;

    { Variance = (1 - P) / P^2 }
    class function GeometricVariance(const P: Double): Double; static;


    { =======================================================================
      NEGATIVE BINOMIAL DISTRIBUTION (discrete)

      Parameters
        R — target number of successes (must be >= 1)
        P — probability of success (must be in (0,1])

      Models the number of trials needed to achieve R successes.
      (Generalises the Geometric distribution where R = 1.)

      Use when: modelling count data with overdispersion, number of
                failures before the R-th success.
    ======================================================================= }

    { PMF: P(X = k) where k is the total number of trials to get R successes.
      k must be >= R. }
    class function NegBinomialPMF(const K, R: Integer; const P: Double; ADecimals: Integer = -1): Double; static;

    { CDF: P(X <= k). }
    class function NegBinomialCDF(const K, R: Integer; const P: Double; ADecimals: Integer = -1): Double; static;

    { Mean = R / P }
    class function NegBinomialMean(const R: Integer; const P: Double): Double; static;

    { Variance = R * (1 - P) / P^2 }
    class function NegBinomialVariance(const R: Integer; const P: Double): Double; static;


    { =======================================================================
      HYPERGEOMETRIC DISTRIBUTION (discrete)

      Parameters
        PopSize  — total population size N
        SuccPop  — number of successes in the population K
        SampleN  — sample size drawn n (without replacement)

      Models sampling WITHOUT replacement — contrast with Binomial which
      assumes sampling WITH replacement (or an infinite population).

      Use when: quality control (drawing defective items from a batch),
                card games (hand dealt from a deck), acceptance sampling.
    ======================================================================= }

    { PMF: P(X = k) — probability of exactly K successes in the sample. }
    class function HypergeometricPMF(
      const K, PopSize, SuccPop, SampleN: Integer;
      ADecimals: Integer = -1): Double; static;

    { CDF: P(X <= k). }
    class function HypergeometricCDF(
      const K, PopSize, SuccPop, SampleN: Integer;
      ADecimals: Integer = -1): Double; static;

    { Mean = n * K / N }
    class function HypergeometricMean(PopSize, SuccPop, SampleN: Integer): Double; static;

    { Variance = n * K/N * (N-K)/N * (N-n)/(N-1) }
    class function HypergeometricVariance(PopSize, SuccPop, SampleN: Integer): Double; static;

  end;

implementation

{ ---------------------------------------------------------------------------
  Private helpers
--------------------------------------------------------------------------- }

class function TProbabilityKit.RoundResult(const V: Double; ADecimals: Integer): Double;
begin
  if ADecimals < 0 then
    Result := V
  else
    Result := RoundTo(V, -ADecimals);
end;

class function TProbabilityKit.LogFactorial(N: Integer): Double;
begin
  { GammaLn(n+1) = ln(n!) exactly via the Gamma function identity Γ(n+1)=n! }
  if N <= 1 then
    Result := 0
  else
    Result := GammaLn(N + 1);
end;

class function TProbabilityKit.LogBinomCoeff(N, K: Integer): Double;
begin
  { ln C(n,k) = ln(n!) - ln(k!) - ln((n-k)!) }
  Result := LogFactorial(N) - LogFactorial(K) - LogFactorial(N - K);
end;

class procedure TProbabilityKit.RequireFinite(const V: Double;
  const Name: string);
begin
  if IsNan(V) or IsInfinite(V) then
    raise EProbabilityError.Create(Name + ' must be finite');
end;

class procedure TProbabilityKit.RequirePositive(const V: Double;
  const Name: string);
begin
  RequireFinite(V, Name);
  if V <= 0 then
    raise EProbabilityError.Create(Name + ' must be > 0');
end;

class procedure TProbabilityKit.RequireProbability(const P: Double;
  AllowZero: Boolean; const Name: string);
begin
  RequireFinite(P, Name);
  if AllowZero then
  begin
    if (P < 0) or (P > 1) then
      raise EProbabilityError.Create(Name + ' must be in [0,1]');
  end
  else if (P <= 0) or (P > 1) then
    raise EProbabilityError.Create(Name + ' must be in (0,1]');
end;

class procedure TProbabilityKit.ValidateHypergeometric(PopSize, SuccPop,
  SampleN: Integer; const Name: string);
begin
  if PopSize < 1 then
    raise EProbabilityError.Create(Name + ': PopSize must be >= 1');
  if (SuccPop < 0) or (SuccPop > PopSize) then
    raise EProbabilityError.Create(Name + ': SuccPop must be in [0, PopSize]');
  if (SampleN < 0) or (SampleN > PopSize) then
    raise EProbabilityError.Create(Name + ': SampleN must be in [0, PopSize]');
end;

{ ---------------------------------------------------------------------------
  NORMAL
--------------------------------------------------------------------------- }

class function TProbabilityKit.NormalPDF(const X, Mu, Sigma: Double; ADecimals: Integer): Double;
var
  Z: Double;
begin
  RequireFinite(X, 'NormalPDF: X');
  RequireFinite(Mu, 'NormalPDF: Mu');
  RequirePositive(Sigma, 'NormalPDF: Sigma');
  Z      := (X - Mu) / Sigma;
  Result := RoundResult(Exp(-0.5 * Z * Z) / (Sigma * Sqrt(2 * Pi)), ADecimals);
end;

class function TProbabilityKit.NormalCDF(const X, Mu, Sigma: Double; ADecimals: Integer): Double;
begin
  RequireFinite(X, 'NormalCDF: X');
  RequireFinite(Mu, 'NormalCDF: Mu');
  RequirePositive(Sigma, 'NormalCDF: Sigma');
  { Reuse MathBase.Precision.NormalCDF which computes Φ((x-mu)/sigma) }
  Result := RoundResult(MathBase.Precision.NormalCDF((X - Mu) / Sigma), ADecimals);
end;

class function TProbabilityKit.NormalSurvival(const X, Mu, Sigma: Double; ADecimals: Integer): Double;
begin
  Result := RoundResult(1.0 - NormalCDF(X, Mu, Sigma), ADecimals);
end;

class function TProbabilityKit.NormalMean(const Mu, Sigma: Double): Double;
begin
  RequireFinite(Mu, 'NormalMean: Mu');
  RequirePositive(Sigma, 'NormalMean: Sigma');
  Result := Mu;
end;

class function TProbabilityKit.NormalVariance(const Mu, Sigma: Double): Double;
begin
  RequireFinite(Mu, 'NormalVariance: Mu');
  RequirePositive(Sigma, 'NormalVariance: Sigma');
  Result := Sigma * Sigma;
end;

{ ---------------------------------------------------------------------------
  LOGNORMAL
--------------------------------------------------------------------------- }

class function TProbabilityKit.LogNormalPDF(const X, Mu, Sigma: Double; ADecimals: Integer): Double;
var
  LnX, Z: Double;
begin
  RequireFinite(X, 'LogNormalPDF: X');
  RequireFinite(Mu, 'LogNormalPDF: Mu');
  RequirePositive(Sigma, 'LogNormalPDF: Sigma');
  if X <= 0 then
    Exit(RoundResult(0, ADecimals));
  LnX    := Ln(X);
  Z      := (LnX - Mu) / Sigma;
  Result := RoundResult(Exp(-0.5 * Z * Z) / (X * Sigma * Sqrt(2 * Pi)), ADecimals);
end;

class function TProbabilityKit.LogNormalCDF(const X, Mu, Sigma: Double; ADecimals: Integer): Double;
begin
  RequireFinite(X, 'LogNormalCDF: X');
  RequireFinite(Mu, 'LogNormalCDF: Mu');
  RequirePositive(Sigma, 'LogNormalCDF: Sigma');
  if X <= 0 then
    Exit(RoundResult(0, ADecimals));
  { CDF(x) = Φ((ln(x) - mu) / sigma) }
  Result := RoundResult(MathBase.Precision.NormalCDF((Ln(X) - Mu) / Sigma), ADecimals);
end;

class function TProbabilityKit.LogNormalSurvival(const X, Mu, Sigma: Double; ADecimals: Integer): Double;
begin
  Result := RoundResult(1.0 - LogNormalCDF(X, Mu, Sigma), ADecimals);
end;

class function TProbabilityKit.LogNormalMean(const Mu, Sigma: Double): Double;
begin
  RequireFinite(Mu, 'LogNormalMean: Mu');
  RequirePositive(Sigma, 'LogNormalMean: Sigma');
  Result := Exp(Mu + 0.5 * Sigma * Sigma);
  if IsInfinite(Result) or IsNan(Result) then
    raise EProbabilityError.Create('LogNormalMean: result is not representable');
end;

class function TProbabilityKit.LogNormalVariance(const Mu, Sigma: Double): Double;
var
  S2: Double;
begin
  RequireFinite(Mu, 'LogNormalVariance: Mu');
  RequirePositive(Sigma, 'LogNormalVariance: Sigma');
  S2     := Sigma * Sigma;
  Result := (Exp(S2) - 1) * Exp(2 * Mu + S2);
  if IsInfinite(Result) or IsNan(Result) then
    raise EProbabilityError.Create('LogNormalVariance: result is not representable');
end;

{ ---------------------------------------------------------------------------
  EXPONENTIAL
--------------------------------------------------------------------------- }

class function TProbabilityKit.ExponentialPDF(const X, Lambda: Double; ADecimals: Integer): Double;
begin
  RequireFinite(X, 'ExponentialPDF: X');
  RequirePositive(Lambda, 'ExponentialPDF: Lambda');
  if X < 0 then
    Exit(RoundResult(0, ADecimals));
  Result := RoundResult(Lambda * Exp(-Lambda * X), ADecimals);
end;

class function TProbabilityKit.ExponentialCDF(const X, Lambda: Double; ADecimals: Integer): Double;
begin
  RequireFinite(X, 'ExponentialCDF: X');
  RequirePositive(Lambda, 'ExponentialCDF: Lambda');
  if X < 0 then
    Exit(RoundResult(0, ADecimals));
  Result := RoundResult(1.0 - Exp(-Lambda * X), ADecimals);
end;

class function TProbabilityKit.ExponentialSurvival(const X, Lambda: Double; ADecimals: Integer): Double;
begin
  RequireFinite(X, 'ExponentialSurvival: X');
  RequirePositive(Lambda, 'ExponentialSurvival: Lambda');
  if X < 0 then
    Exit(RoundResult(1, ADecimals));
  Result := RoundResult(Exp(-Lambda * X), ADecimals);
end;

class function TProbabilityKit.ExponentialMean(const Lambda: Double): Double;
begin
  RequirePositive(Lambda, 'ExponentialMean: Lambda');
  Result := 1.0 / Lambda;
end;

class function TProbabilityKit.ExponentialVariance(const Lambda: Double): Double;
begin
  RequirePositive(Lambda, 'ExponentialVariance: Lambda');
  Result := 1.0 / (Lambda * Lambda);
end;

{ ---------------------------------------------------------------------------
  GAMMA
  Uses the regularised incomplete gamma function via BetaInc identity:
    GammaRegInc(a, x) = 1 - BetaInc(a, large, x/(x+large))  — not ideal.
  We implement a dedicated series + continued-fraction evaluator here.
--------------------------------------------------------------------------- }

{ Internal: regularised incomplete gamma P(a, x) = γ(a,x)/Γ(a).
  Uses series for x < a+1, continued fraction otherwise. }
function RegIncGamma(const A, X: Double): Double;
const
  MaxIter = 10000;
  Eps     = 1e-14;
  FPMin   = 1e-300;
var
  LnGamA, AP, Sum, Del, B, C, D, H, An, Del2: Double;
  N: Integer;
  Converged: Boolean;
begin
  if X < 0 then raise EProbabilityError.Create('RegIncGamma: X must be >= 0');
  if X = 0 then Exit(0);

  LnGamA := GammaLn(A);

  if X < A + 1 then
  begin
    { Series expansion }
    AP  := A;
    Del := 1.0 / A;
    Sum := Del;
    Converged := False;
    for N := 1 to MaxIter do
    begin
      AP  := AP + 1;
      Del := Del * X / AP;
      Sum := Sum + Del;
      if Abs(Del) < Abs(Sum) * Eps then
      begin
        Converged := True;
        Break;
      end;
    end;
    if not Converged then
      raise EProbabilityError.Create('RegIncGamma: series did not converge');
    Result := Sum * Exp(-X + A * Ln(X) - LnGamA);
  end
  else
  begin
    { Continued fraction (Lentz method) }
    B := X + 1 - A;
    C := 1.0 / FPMin;
    D := 1.0 / B;
    H := D;
    Converged := False;
    for N := 1 to MaxIter do
    begin
      An   := -N * (N - A);
      B    := B + 2;
      D    := An * D + B;
      if Abs(D) < FPMin then D := FPMin;
      C    := B + An / C;
      if Abs(C) < FPMin then C := FPMin;
      D    := 1.0 / D;
      Del2 := D * C;
      H    := H * Del2;
      if Abs(Del2 - 1) < Eps then
      begin
        Converged := True;
        Break;
      end;
    end;
    if not Converged then
      raise EProbabilityError.Create('RegIncGamma: continued fraction did not converge');
    Result := 1.0 - Exp(-X + A * Ln(X) - LnGamA) * H;
  end;
end;

class function TProbabilityKit.GammaPDF(const X, Alpha, Beta: Double; ADecimals: Integer): Double;
begin
  RequireFinite(X, 'GammaPDF: X');
  RequirePositive(Alpha, 'GammaPDF: Alpha');
  RequirePositive(Beta, 'GammaPDF: Beta');
  if X <= 0 then Exit(RoundResult(0, ADecimals));
  { f(x) = Beta^Alpha * x^(Alpha-1) * exp(-Beta*x) / Gamma(Alpha) }
  Result := RoundResult(
    Exp(Alpha * Ln(Beta) + (Alpha - 1) * Ln(X) - Beta * X - GammaLn(Alpha)),
    ADecimals);
end;

class function TProbabilityKit.GammaCDF(const X, Alpha, Beta: Double; ADecimals: Integer): Double;
begin
  RequireFinite(X, 'GammaCDF: X');
  RequirePositive(Alpha, 'GammaCDF: Alpha');
  RequirePositive(Beta, 'GammaCDF: Beta');
  if X <= 0 then Exit(RoundResult(0, ADecimals));
  { CDF = P(Alpha, Beta*x) — regularised incomplete gamma }
  Result := RoundResult(RegIncGamma(Alpha, Beta * X), ADecimals);
end;

class function TProbabilityKit.GammaSurvival(const X, Alpha, Beta: Double; ADecimals: Integer): Double;
begin
  Result := RoundResult(1.0 - GammaCDF(X, Alpha, Beta), ADecimals);
end;

class function TProbabilityKit.GammaMean(const Alpha, Beta: Double): Double;
begin
  RequirePositive(Alpha, 'GammaMean: Alpha');
  RequirePositive(Beta, 'GammaMean: Beta');
  Result := Alpha / Beta;
end;

class function TProbabilityKit.GammaVariance(const Alpha, Beta: Double): Double;
begin
  RequirePositive(Alpha, 'GammaVariance: Alpha');
  RequirePositive(Beta, 'GammaVariance: Beta');
  Result := Alpha / (Beta * Beta);
end;

{ ---------------------------------------------------------------------------
  BETA
--------------------------------------------------------------------------- }

class function TProbabilityKit.BetaPDF(const X, Alpha, Beta: Double; ADecimals: Integer): Double;
begin
  RequireFinite(X, 'BetaPDF: X');
  RequirePositive(Alpha, 'BetaPDF: Alpha');
  RequirePositive(Beta, 'BetaPDF: Beta');
  if (X <= 0) or (X >= 1) then Exit(RoundResult(0, ADecimals));
  { f(x) = x^(Alpha-1) * (1-x)^(Beta-1) / B(Alpha, Beta) }
  Result := RoundResult(
    Exp((Alpha - 1) * Ln(X) + (Beta - 1) * Ln(1 - X) -
        (GammaLn(Alpha) + GammaLn(Beta) - GammaLn(Alpha + Beta))),
    ADecimals);
end;

class function TProbabilityKit.BetaCDF(const X, Alpha, Beta: Double; ADecimals: Integer): Double;
begin
  RequireFinite(X, 'BetaCDF: X');
  RequirePositive(Alpha, 'BetaCDF: Alpha');
  RequirePositive(Beta, 'BetaCDF: Beta');
  if X <= 0 then Exit(RoundResult(0, ADecimals));
  if X >= 1 then Exit(RoundResult(1, ADecimals));
  { Uses MathBase.Precision.BetaInc — the regularised incomplete beta I_x(a,b) }
  Result := RoundResult(BetaInc(Alpha, Beta, X), ADecimals);
end;

class function TProbabilityKit.BetaSurvival(const X, Alpha, Beta: Double; ADecimals: Integer): Double;
begin
  Result := RoundResult(1.0 - BetaCDF(X, Alpha, Beta), ADecimals);
end;

class function TProbabilityKit.BetaMean(const Alpha, Beta: Double): Double;
begin
  RequirePositive(Alpha, 'BetaMean: Alpha');
  RequirePositive(Beta, 'BetaMean: Beta');
  Result := Alpha / (Alpha + Beta);
end;

class function TProbabilityKit.BetaVariance(const Alpha, Beta: Double): Double;
var
  S: Double;
begin
  RequirePositive(Alpha, 'BetaVariance: Alpha');
  RequirePositive(Beta, 'BetaVariance: Beta');
  S      := Alpha + Beta;
  Result := (Alpha * Beta) / (S * S * (S + 1));
end;

{ ---------------------------------------------------------------------------
  CHI-SQUARED  — special case of Gamma(DF/2, 1/2)
--------------------------------------------------------------------------- }

class function TProbabilityKit.ChiSquaredPDF(const X: Double; DF: Integer; ADecimals: Integer): Double;
begin
  if DF < 1 then raise EProbabilityError.Create('ChiSquaredPDF: DF must be >= 1');
  RequireFinite(X, 'ChiSquaredPDF: X');
  Result := GammaPDF(X, DF / 2.0, 0.5, ADecimals);
end;

class function TProbabilityKit.ChiSquaredCDF(const X: Double; DF: Integer; ADecimals: Integer): Double;
begin
  if DF < 1 then raise EProbabilityError.Create('ChiSquaredCDF: DF must be >= 1');
  RequireFinite(X, 'ChiSquaredCDF: X');
  if X <= 0 then Exit(RoundResult(0, ADecimals));
  Result := RoundResult(RegIncGamma(DF / 2.0, X / 2.0), ADecimals);
end;

class function TProbabilityKit.ChiSquaredSurvival(const X: Double; DF: Integer; ADecimals: Integer): Double;
begin
  Result := RoundResult(1.0 - ChiSquaredCDF(X, DF), ADecimals);
end;

class function TProbabilityKit.ChiSquaredMean(DF: Integer): Double;
begin
  if DF < 1 then raise EProbabilityError.Create('ChiSquaredMean: DF must be >= 1');
  Result := DF;
end;

class function TProbabilityKit.ChiSquaredVariance(DF: Integer): Double;
begin
  if DF < 1 then raise EProbabilityError.Create('ChiSquaredVariance: DF must be >= 1');
  Result := 2.0 * DF;
end;

{ ---------------------------------------------------------------------------
  STUDENT'S T
--------------------------------------------------------------------------- }

class function TProbabilityKit.StudentTPDF(const X: Double; DF: Integer; ADecimals: Integer): Double;
var
  Nu, LogC: Double;
begin
  if DF < 1 then raise EProbabilityError.Create('StudentTPDF: DF must be >= 1');
  RequireFinite(X, 'StudentTPDF: X');
  Nu    := DF;
  { f(x) = Γ((ν+1)/2) / (√(νπ) Γ(ν/2)) * (1 + x²/ν)^(-(ν+1)/2) }
  LogC  := GammaLn((Nu + 1) / 2) - GammaLn(Nu / 2) - 0.5 * Ln(Nu * Pi);
  Result := RoundResult(Exp(LogC - ((Nu + 1) / 2) * Ln(1 + X * X / Nu)), ADecimals);
end;

class function TProbabilityKit.StudentTCDF(const X: Double; DF: Integer; ADecimals: Integer): Double;
var
  Nu, BetaX: Double;
begin
  if DF < 1 then raise EProbabilityError.Create('StudentTCDF: DF must be >= 1');
  RequireFinite(X, 'StudentTCDF: X');
  Nu    := DF;
  { Use the incomplete beta relationship:
    CDF(x) = I_t(DF/2, 1/2)/2 where t = DF/(DF+x²), adjusted for sign }
  BetaX := Nu / (Nu + X * X);
  if X >= 0 then
    Result := RoundResult(1.0 - 0.5 * BetaInc(Nu / 2, 0.5, BetaX), ADecimals)
  else
    Result := RoundResult(0.5 * BetaInc(Nu / 2, 0.5, BetaX), ADecimals);
end;

class function TProbabilityKit.StudentTSurvival(const X: Double; DF: Integer; ADecimals: Integer): Double;
begin
  Result := RoundResult(1.0 - StudentTCDF(X, DF), ADecimals);
end;

class function TProbabilityKit.StudentTTwoTail(const X: Double; DF: Integer; ADecimals: Integer): Double;
begin
  { Two-tailed p = 2 * P(T > |x|) }
  Result := RoundResult(2.0 * StudentTSurvival(Abs(X), DF), ADecimals);
end;

class function TProbabilityKit.StudentTMean(DF: Integer): Double;
begin
  if DF <= 1 then
    raise EProbabilityError.Create('StudentTMean: Mean undefined for DF <= 1');
  Result := 0;
end;

class function TProbabilityKit.StudentTVariance(DF: Integer): Double;
begin
  if DF <= 2 then
    raise EProbabilityError.Create('StudentTVariance: Variance undefined for DF <= 2');
  Result := DF / (DF - 2);
end;

{ ---------------------------------------------------------------------------
  F DISTRIBUTION
--------------------------------------------------------------------------- }

class function TProbabilityKit.FPDF(const X: Double; DF1, DF2: Integer; ADecimals: Integer): Double;
var
  D1, D2, LogNum: Double;
begin
  if DF1 < 1 then raise EProbabilityError.Create('FPDF: DF1 must be >= 1');
  if DF2 < 1 then raise EProbabilityError.Create('FPDF: DF2 must be >= 1');
  RequireFinite(X, 'FPDF: X');
  if X <= 0 then Exit(RoundResult(0, ADecimals));
  D1 := DF1;
  D2 := DF2;
  { Using log form for numerical stability:
    ln f(x) = (d1/2)*ln(d1) + (d2/2)*ln(d2) + (d1/2-1)*ln(x)
              - ((d1+d2)/2)*ln(d1*x + d2)
              - lnB(d1/2, d2/2) }
  LogNum := (D1 / 2) * Ln(D1) + (D2 / 2) * Ln(D2) +
            (D1 / 2 - 1) * Ln(X) -
            ((D1 + D2) / 2) * Ln(D1 * X + D2) -
            (GammaLn(D1 / 2) + GammaLn(D2 / 2) - GammaLn((D1 + D2) / 2));
  Result := RoundResult(Exp(LogNum), ADecimals);
end;

class function TProbabilityKit.FCDF(const X: Double; DF1, DF2: Integer; ADecimals: Integer): Double;
var
  D1, D2, T: Double;
begin
  if DF1 < 1 then raise EProbabilityError.Create('FCDF: DF1 must be >= 1');
  if DF2 < 1 then raise EProbabilityError.Create('FCDF: DF2 must be >= 1');
  RequireFinite(X, 'FCDF: X');
  if X <= 0 then Exit(RoundResult(0, ADecimals));
  D1 := DF1;
  D2 := DF2;
  { CDF = I_t(d1/2, d2/2) where t = d1*x / (d1*x + d2) }
  T      := D1 * X / (D1 * X + D2);
  Result := RoundResult(BetaInc(D1 / 2, D2 / 2, T), ADecimals);
end;

class function TProbabilityKit.FSurvival(const X: Double; DF1, DF2: Integer; ADecimals: Integer): Double;
begin
  Result := RoundResult(1.0 - FCDF(X, DF1, DF2), ADecimals);
end;

class function TProbabilityKit.FMean(DF1, DF2: Integer): Double;
begin
  if DF1 < 1 then
    raise EProbabilityError.Create('FMean: DF1 must be >= 1');
  if DF2 <= 2 then
    raise EProbabilityError.Create('FMean: Mean undefined for DF2 <= 2');
  Result := DF2 / (DF2 - 2);
end;

class function TProbabilityKit.FVariance(DF1, DF2: Integer): Double;
var
  D1, D2: Double;
begin
  if DF1 < 1 then
    raise EProbabilityError.Create('FVariance: DF1 must be >= 1');
  if DF2 <= 4 then
    raise EProbabilityError.Create('FVariance: Variance undefined for DF2 <= 4');
  D1 := DF1;
  D2 := DF2;
  Result := 2 * D2 * D2 * (D1 + D2 - 2) /
            (D1 * (D2 - 2) * (D2 - 2) * (D2 - 4));
end;

{ ---------------------------------------------------------------------------
  WEIBULL
--------------------------------------------------------------------------- }

class function TProbabilityKit.WeibullPDF(const X, K, Lambda: Double; ADecimals: Integer): Double;
begin
  RequireFinite(X, 'WeibullPDF: X');
  RequirePositive(K, 'WeibullPDF: K');
  RequirePositive(Lambda, 'WeibullPDF: Lambda');
  if X < 0 then Exit(RoundResult(0, ADecimals));
  if X = 0 then
  begin
    { PDF at 0: only non-zero when K < 1 (→ +∞), return 0 otherwise }
    if K < 1 then Exit(RoundResult(Infinity, ADecimals))
    else if K = 1 then Exit(RoundResult(1.0 / Lambda, ADecimals))
    else Exit(RoundResult(0, ADecimals));
  end;
  { f(x) = (K/Lambda) * (x/Lambda)^(K-1) * exp(-(x/Lambda)^K) }
  Result := RoundResult(
    (K / Lambda) * Power(X / Lambda, K - 1) * Exp(-Power(X / Lambda, K)),
    ADecimals);
end;

class function TProbabilityKit.WeibullCDF(const X, K, Lambda: Double; ADecimals: Integer): Double;
begin
  RequireFinite(X, 'WeibullCDF: X');
  RequirePositive(K, 'WeibullCDF: K');
  RequirePositive(Lambda, 'WeibullCDF: Lambda');
  if X <= 0 then Exit(RoundResult(0, ADecimals));
  Result := RoundResult(1.0 - Exp(-Power(X / Lambda, K)), ADecimals);
end;

class function TProbabilityKit.WeibullSurvival(const X, K, Lambda: Double; ADecimals: Integer): Double;
begin
  RequireFinite(X, 'WeibullSurvival: X');
  RequirePositive(K, 'WeibullSurvival: K');
  RequirePositive(Lambda, 'WeibullSurvival: Lambda');
  if X <= 0 then Exit(RoundResult(1, ADecimals));
  Result := RoundResult(Exp(-Power(X / Lambda, K)), ADecimals);
end;

class function TProbabilityKit.WeibullMean(const K, Lambda: Double): Double;
begin
  RequirePositive(K, 'WeibullMean: K');
  RequirePositive(Lambda, 'WeibullMean: Lambda');
  Result := Lambda * Exp(GammaLn(1.0 + 1.0 / K));
end;

class function TProbabilityKit.WeibullVariance(const K, Lambda: Double): Double;
var
  G1, G2: Double;
begin
  RequirePositive(K, 'WeibullVariance: K');
  RequirePositive(Lambda, 'WeibullVariance: Lambda');
  G1 := Exp(GammaLn(1.0 + 1.0 / K));
  G2 := Exp(GammaLn(1.0 + 2.0 / K));
  Result := Lambda * Lambda * (G2 - G1 * G1);
end;

{ ---------------------------------------------------------------------------
  UNIFORM (continuous)
--------------------------------------------------------------------------- }

class function TProbabilityKit.UniformPDF(const X, A, B: Double; ADecimals: Integer): Double;
begin
  RequireFinite(X, 'UniformPDF: X');
  RequireFinite(A, 'UniformPDF: A');
  RequireFinite(B, 'UniformPDF: B');
  if B <= A then raise EProbabilityError.Create('UniformPDF: B must be > A');
  if (X < A) or (X > B) then
    Result := RoundResult(0, ADecimals)
  else
    Result := RoundResult(1.0 / (B - A), ADecimals);
end;

class function TProbabilityKit.UniformCDF(const X, A, B: Double; ADecimals: Integer): Double;
begin
  RequireFinite(X, 'UniformCDF: X');
  RequireFinite(A, 'UniformCDF: A');
  RequireFinite(B, 'UniformCDF: B');
  if B <= A then raise EProbabilityError.Create('UniformCDF: B must be > A');
  if X <= A then Result := RoundResult(0, ADecimals)
  else if X >= B then Result := RoundResult(1, ADecimals)
  else Result := RoundResult((X - A) / (B - A), ADecimals);
end;

class function TProbabilityKit.UniformSurvival(const X, A, B: Double; ADecimals: Integer): Double;
begin
  Result := RoundResult(1.0 - UniformCDF(X, A, B), ADecimals);
end;

class function TProbabilityKit.UniformMean(const A, B: Double): Double;
begin
  RequireFinite(A, 'UniformMean: A');
  RequireFinite(B, 'UniformMean: B');
  if B <= A then raise EProbabilityError.Create('UniformMean: B must be > A');
  Result := (A + B) / 2;
end;

class function TProbabilityKit.UniformVariance(const A, B: Double): Double;
begin
  RequireFinite(A, 'UniformVariance: A');
  RequireFinite(B, 'UniformVariance: B');
  if B <= A then raise EProbabilityError.Create('UniformVariance: B must be > A');
  Result := (B - A) * (B - A) / 12.0;
end;

{ ---------------------------------------------------------------------------
  BINOMIAL (discrete)
--------------------------------------------------------------------------- }

class function TProbabilityKit.BinomialPMF(const K, N: Integer; const P: Double; ADecimals: Integer): Double;
begin
  if N < 1  then raise EProbabilityError.Create('BinomialPMF: N must be >= 1');
  RequireProbability(P, True, 'BinomialPMF: P');
  if (K < 0) or (K > N) then Exit(RoundResult(0, ADecimals));
  if P = 0 then Exit(RoundResult(IfThen(K = 0, 1.0, 0.0), ADecimals));
  if P = 1 then Exit(RoundResult(IfThen(K = N, 1.0, 0.0), ADecimals));
  { P(X=k) = C(n,k) * p^k * (1-p)^(n-k); use log form for stability }
  Result := RoundResult(
    Exp(LogBinomCoeff(N, K) + K * Ln(P) + (N - K) * Ln(1 - P)),
    ADecimals);
end;

class function TProbabilityKit.BinomialCDF(const K, N: Integer; const P: Double; ADecimals: Integer): Double;
var
  I: Integer;
  Sum: Double;
begin
  if N < 1  then raise EProbabilityError.Create('BinomialCDF: N must be >= 1');
  RequireProbability(P, True, 'BinomialCDF: P');
  if K < 0 then Exit(RoundResult(0, ADecimals));
  if K >= N then Exit(RoundResult(1, ADecimals));
  { CDF = I_(1-p)(n-k, k+1) via incomplete beta; or sum for small N }
  if N <= 1000 then
  begin
    Sum := 0;
    for I := 0 to K do
      Sum := Sum + BinomialPMF(I, N, P);
    Result := RoundResult(Sum, ADecimals);
  end
  else
    { For large N use the incomplete beta relationship:
      CDF(k; n, p) = I_(1-p)(n-k, k+1) }
    Result := RoundResult(BetaInc(N - K, K + 1, 1 - P), ADecimals);
end;

class function TProbabilityKit.BinomialSurvival(const K, N: Integer; const P: Double; ADecimals: Integer): Double;
begin
  Result := RoundResult(1.0 - BinomialCDF(K, N, P), ADecimals);
end;

class function TProbabilityKit.BinomialMean(const N: Integer; const P: Double): Double;
begin
  if N < 1 then raise EProbabilityError.Create('BinomialMean: N must be >= 1');
  RequireProbability(P, True, 'BinomialMean: P');
  Result := N * P;
end;

class function TProbabilityKit.BinomialVariance(const N: Integer; const P: Double): Double;
begin
  if N < 1 then raise EProbabilityError.Create('BinomialVariance: N must be >= 1');
  RequireProbability(P, True, 'BinomialVariance: P');
  Result := N * P * (1 - P);
end;

{ ---------------------------------------------------------------------------
  POISSON (discrete)
--------------------------------------------------------------------------- }

class function TProbabilityKit.PoissonPMF(const K: Integer; const Lambda: Double; ADecimals: Integer): Double;
begin
  RequirePositive(Lambda, 'PoissonPMF: Lambda');
  if K < 0 then Exit(RoundResult(0, ADecimals));
  { P(X=k) = exp(-lambda) * lambda^k / k!  — use log form }
  Result := RoundResult(
    Exp(-Lambda + K * Ln(Lambda) - LogFactorial(K)),
    ADecimals);
end;

class function TProbabilityKit.PoissonCDF(const K: Integer; const Lambda: Double; ADecimals: Integer): Double;
var
  I: Integer;
  Sum: Double;
begin
  RequirePositive(Lambda, 'PoissonCDF: Lambda');
  if K < 0 then Exit(RoundResult(0, ADecimals));
  Sum := 0;
  for I := 0 to K do
    Sum := Sum + PoissonPMF(I, Lambda);
  Result := RoundResult(Sum, ADecimals);
end;

class function TProbabilityKit.PoissonSurvival(const K: Integer; const Lambda: Double; ADecimals: Integer): Double;
begin
  Result := RoundResult(1.0 - PoissonCDF(K, Lambda), ADecimals);
end;

class function TProbabilityKit.PoissonMean(const Lambda: Double): Double;
begin
  RequirePositive(Lambda, 'PoissonMean: Lambda');
  Result := Lambda;
end;

class function TProbabilityKit.PoissonVariance(const Lambda: Double): Double;
begin
  RequirePositive(Lambda, 'PoissonVariance: Lambda');
  Result := Lambda;
end;

{ ---------------------------------------------------------------------------
  GEOMETRIC (discrete) — number-of-trials convention (X >= 1)
--------------------------------------------------------------------------- }

class function TProbabilityKit.GeometricPMF(const K: Integer; const P: Double; ADecimals: Integer): Double;
begin
  RequireProbability(P, False, 'GeometricPMF: P');
  if K < 1 then Exit(RoundResult(0, ADecimals));
  { P(X=k) = (1-p)^(k-1) * p }
  Result := RoundResult(Power(1 - P, K - 1) * P, ADecimals);
end;

class function TProbabilityKit.GeometricCDF(const K: Integer; const P: Double; ADecimals: Integer): Double;
begin
  RequireProbability(P, False, 'GeometricCDF: P');
  if K < 1 then Exit(RoundResult(0, ADecimals));
  { CDF = 1 - (1-p)^k }
  Result := RoundResult(1.0 - Power(1 - P, K), ADecimals);
end;

class function TProbabilityKit.GeometricSurvival(const K: Integer; const P: Double; ADecimals: Integer): Double;
begin
  RequireProbability(P, False, 'GeometricSurvival: P');
  if K < 1 then Exit(RoundResult(1, ADecimals));
  Result := RoundResult(Power(1 - P, K), ADecimals);
end;

class function TProbabilityKit.GeometricMean(const P: Double): Double;
begin
  RequireProbability(P, False, 'GeometricMean: P');
  Result := 1.0 / P;
end;

class function TProbabilityKit.GeometricVariance(const P: Double): Double;
begin
  RequireProbability(P, False, 'GeometricVariance: P');
  Result := (1 - P) / (P * P);
end;

{ ---------------------------------------------------------------------------
  NEGATIVE BINOMIAL (discrete) — total trials to get R successes
--------------------------------------------------------------------------- }

class function TProbabilityKit.NegBinomialPMF(const K, R: Integer; const P: Double; ADecimals: Integer): Double;
begin
  if R < 1 then raise EProbabilityError.Create('NegBinomialPMF: R must be >= 1');
  RequireProbability(P, False, 'NegBinomialPMF: P');
  if K < R then Exit(RoundResult(0, ADecimals));
  if P = 1 then Exit(RoundResult(IfThen(K = R, 1.0, 0.0), ADecimals));
  { P(X=k) = C(k-1, r-1) * p^r * (1-p)^(k-r) }
  Result := RoundResult(
    Exp(LogBinomCoeff(K - 1, R - 1) + R * Ln(P) + (K - R) * Ln(1 - P)),
    ADecimals);
end;

class function TProbabilityKit.NegBinomialCDF(const K, R: Integer; const P: Double; ADecimals: Integer): Double;
var
  I: Integer;
  Sum: Double;
begin
  if R < 1 then raise EProbabilityError.Create('NegBinomialCDF: R must be >= 1');
  RequireProbability(P, False, 'NegBinomialCDF: P');
  if K < R then Exit(RoundResult(0, ADecimals));
  if P = 1 then Exit(RoundResult(1, ADecimals));
  Sum := 0;
  for I := R to K do
    Sum := Sum + NegBinomialPMF(I, R, P);
  Result := RoundResult(Sum, ADecimals);
end;

class function TProbabilityKit.NegBinomialMean(const R: Integer; const P: Double): Double;
begin
  if R < 1 then raise EProbabilityError.Create('NegBinomialMean: R must be >= 1');
  RequireProbability(P, False, 'NegBinomialMean: P');
  Result := R / P;
end;

class function TProbabilityKit.NegBinomialVariance(const R: Integer; const P: Double): Double;
begin
  if R < 1 then raise EProbabilityError.Create('NegBinomialVariance: R must be >= 1');
  RequireProbability(P, False, 'NegBinomialVariance: P');
  Result := R * (1 - P) / (P * P);
end;

{ ---------------------------------------------------------------------------
  HYPERGEOMETRIC (discrete) — sampling without replacement
--------------------------------------------------------------------------- }

class function TProbabilityKit.HypergeometricPMF(
  const K, PopSize, SuccPop, SampleN: Integer;
  ADecimals: Integer): Double;
begin
  ValidateHypergeometric(PopSize, SuccPop, SampleN, 'HypergeometricPMF');
  { k must be in [max(0, n+K-N), min(n, K)] }
  if (K < 0) or (K > Min(SampleN, SuccPop)) or (K < Max(0, SampleN + SuccPop - PopSize)) then
    Exit(RoundResult(0, ADecimals));
  { P(X=k) = C(K,k)*C(N-K,n-k) / C(N,n) }
  Result := RoundResult(
    Exp(LogBinomCoeff(SuccPop, K) +
        LogBinomCoeff(PopSize - SuccPop, SampleN - K) -
        LogBinomCoeff(PopSize, SampleN)),
    ADecimals);
end;

class function TProbabilityKit.HypergeometricCDF(
  const K, PopSize, SuccPop, SampleN: Integer;
  ADecimals: Integer): Double;
var
  I, MinK, MaxK: Integer;
  Sum: Double;
begin
  ValidateHypergeometric(PopSize, SuccPop, SampleN, 'HypergeometricCDF');
  MinK := Max(0, SampleN + SuccPop - PopSize);
  MaxK := Min(SampleN, SuccPop);
  if K < MinK then Exit(RoundResult(0, ADecimals));
  if K >= MaxK then Exit(RoundResult(1, ADecimals));
  Sum := 0;
  for I := MinK to K do
    Sum := Sum + HypergeometricPMF(I, PopSize, SuccPop, SampleN);
  Result := RoundResult(Sum, ADecimals);
end;

class function TProbabilityKit.HypergeometricMean(PopSize, SuccPop, SampleN: Integer): Double;
begin
  ValidateHypergeometric(PopSize, SuccPop, SampleN, 'HypergeometricMean');
  Result := SampleN * SuccPop / PopSize;
end;

class function TProbabilityKit.HypergeometricVariance(PopSize, SuccPop, SampleN: Integer): Double;
var
  N, K, N_: Double;
begin
  ValidateHypergeometric(PopSize, SuccPop, SampleN, 'HypergeometricVariance');
  if PopSize = 1 then Exit(0.0);
  N  := PopSize;
  K  := SuccPop;
  N_ := SampleN;
  Result := N_ * (K / N) * ((N - K) / N) * ((N - N_) / (N - 1));
end;

end.
