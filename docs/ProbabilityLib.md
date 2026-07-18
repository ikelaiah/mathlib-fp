# ProbabilityLib Reference

`ProbabilityLib.Distributions` — probability distributions for Free Pascal.

---

## Quick Start

```pascal
uses ProbabilityLib.Distributions;

// What is P(X <= 1.96) for a standard Normal?
p := TProbabilityKit.NormalCDF(1.96, 0, 1);       // 0.975002

// P(exactly 3 heads in 10 fair coin flips)?
p := TProbabilityKit.BinomialPMF(3, 10, 0.5);     // 0.117188

// P(waiting time > 2 hours when average rate is 1/hr)?
p := TProbabilityKit.ExponentialSurvival(2, 1);    // 0.135335
```

No object creation needed — all methods are **class static**.

---

## Design Conventions

| Convention | Detail |
|------------|--------|
| All static | `TProbabilityKit.XXX(...)` — no `Create`/`Free` |
| Parameter order | `(x, distribution_params...)` |
| Optional rounding | last param `ADecimals: Integer = -1`; pass e.g. `4` to round to 4 d.p. |
| Out-of-domain X | returns 0 (PDF/PMF) or clamped (CDF) instead of raising |
| Invalid params | All entry points raise `EProbabilityError` for non-finite real inputs or parameters outside the documented distribution domain |

At the support boundary, `GammaPDF` and `BetaPDF` use the library convention of
returning zero rather than representing finite or infinite limiting densities.

---

## Five Functions Per Distribution

For each distribution you get:

| Function | What it returns |
|----------|----------------|
| `PDF` / `PMF` | Probability density (continuous) or mass (discrete) at a single point |
| `CDF` | Cumulative probability P(X ≤ x) |
| `Survival` | Upper-tail probability P(X > x) = 1 − CDF |
| `Mean` | Expected value |
| `Variance` | Spread (σ²) |

---

## Continuous Distributions

### Normal (Bell Curve)

```pascal
TProbabilityKit.NormalPDF(X, Mu, Sigma)
TProbabilityKit.NormalCDF(X, Mu, Sigma)
TProbabilityKit.NormalSurvival(X, Mu, Sigma)
TProbabilityKit.NormalMean(Mu, Sigma)      // = Mu
TProbabilityKit.NormalVariance(Mu, Sigma)  // = Sigma²
```

| Parameter | Meaning | Constraint |
|-----------|---------|-----------|
| `Mu` | Mean (centre) | any real |
| `Sigma` | Standard deviation | > 0 |

Every Normal entry point, including the moment helpers, requires finite `Mu`
and positive finite `Sigma`.

**When to use:** heights, measurement errors, test scores — any quantity that is the sum of many small independent effects.

**Key values:**
- `NormalCDF(1.96, 0, 1)` ≈ 0.975 — the classic 95% one-tailed threshold
- `NormalCDF(1.645, 0, 1)` ≈ 0.95
- `NormalCDF(2.576, 0, 1)` ≈ 0.995

---

### LogNormal

```pascal
TProbabilityKit.LogNormalPDF(X, Mu, Sigma)    // X > 0
TProbabilityKit.LogNormalCDF(X, Mu, Sigma)
TProbabilityKit.LogNormalSurvival(X, Mu, Sigma)
TProbabilityKit.LogNormalMean(Mu, Sigma)      // = exp(Mu + Sigma²/2)
TProbabilityKit.LogNormalVariance(Mu, Sigma)  // = (exp(Sigma²)-1)*exp(2Mu+Sigma²)
```

**When to use:** stock prices, incomes, concentrations — quantities that are always positive and right-skewed.

**Tip:** If `Y ~ Normal(Mu, Sigma)` then `X = exp(Y) ~ LogNormal(Mu, Sigma)`.

---

### Exponential

```pascal
TProbabilityKit.ExponentialPDF(X, Lambda)      // X >= 0
TProbabilityKit.ExponentialCDF(X, Lambda)
TProbabilityKit.ExponentialSurvival(X, Lambda) // = exp(-Lambda*x), the "reliability fn"
TProbabilityKit.ExponentialMean(Lambda)        // = 1/Lambda
TProbabilityKit.ExponentialVariance(Lambda)    // = 1/Lambda²
```

| Parameter | Meaning | Constraint |
|-----------|---------|-----------|
| `Lambda` | Rate (events per unit time) | > 0 |

**When to use:** time between independent random events — bus arrivals, radioactive decay, customer service times.

---

### Gamma

```pascal
TProbabilityKit.GammaPDF(X, Alpha, Beta)      // X > 0
TProbabilityKit.GammaCDF(X, Alpha, Beta)
TProbabilityKit.GammaSurvival(X, Alpha, Beta)
TProbabilityKit.GammaMean(Alpha, Beta)        // = Alpha/Beta
TProbabilityKit.GammaVariance(Alpha, Beta)    // = Alpha/Beta²
```

| Parameter | Meaning | Constraint |
|-----------|---------|-----------|
| `Alpha` | Shape | > 0 |
| `Beta` | Rate (not scale) | > 0 |

**Special cases:**
- `Gamma(1, Lambda)` = `Exponential(Lambda)`
- `Gamma(k/2, 0.5)` = `ChiSquared(k)`

---

### Beta

```pascal
TProbabilityKit.BetaPDF(X, Alpha, Beta)      // X in (0,1)
TProbabilityKit.BetaCDF(X, Alpha, Beta)
TProbabilityKit.BetaSurvival(X, Alpha, Beta)
TProbabilityKit.BetaMean(Alpha, Beta)        // = Alpha/(Alpha+Beta)
TProbabilityKit.BetaVariance(Alpha, Beta)
```

**When to use:** modelling probabilities, conversion rates, click-through rates, or Bayesian posteriors for a probability parameter.

**Special case:** `Beta(1,1)` = `Uniform(0,1)`

Both shape parameters must be positive.

---

### Chi-Squared (χ²)

```pascal
TProbabilityKit.ChiSquaredPDF(X, DF)
TProbabilityKit.ChiSquaredCDF(X, DF)
TProbabilityKit.ChiSquaredSurvival(X, DF)   // this is the p-value from a χ² test
TProbabilityKit.ChiSquaredMean(DF)          // = DF
TProbabilityKit.ChiSquaredVariance(DF)      // = 2*DF
```

**When to use:** χ² goodness-of-fit tests, tests of independence in contingency tables, confidence intervals for variance.

**Example — get the p-value from a χ² test:**
```pascal
pValue := TProbabilityKit.ChiSquaredSurvival(chiStat, degreesOfFreedom);
```

---

### Student's t

```pascal
TProbabilityKit.StudentTPDF(X, DF)
TProbabilityKit.StudentTCDF(X, DF)
TProbabilityKit.StudentTSurvival(X, DF)
TProbabilityKit.StudentTTwoTail(X, DF)    // = 2 * Survival(|X|) — use for two-sided tests
TProbabilityKit.StudentTMean(DF)          // = 0  (DF > 1 only)
TProbabilityKit.StudentTVariance(DF)      // = DF/(DF-2)  (DF > 2 only)
```

**When to use:** t-tests, confidence intervals for a mean when the sample size is small (n < 30).

**Tip:** As DF → ∞ the t-distribution approaches Normal(0,1).

---

### F Distribution

```pascal
TProbabilityKit.FPDF(X, DF1, DF2)
TProbabilityKit.FCDF(X, DF1, DF2)
TProbabilityKit.FSurvival(X, DF1, DF2)   // p-value from an F-test
TProbabilityKit.FMean(DF1, DF2)          // = DF2/(DF2-2)  (DF2 > 2)
TProbabilityKit.FVariance(DF1, DF2)      // (DF2 > 4)
```

**When to use:** ANOVA (comparing group means), regression model significance, Levene's test for equal variances.

`DF1` and `DF2` must both be at least 1. The mean exists only for `DF2 > 2`,
and the variance only for `DF2 > 4`.

---

### Weibull

```pascal
TProbabilityKit.WeibullPDF(X, K, Lambda)
TProbabilityKit.WeibullCDF(X, K, Lambda)
TProbabilityKit.WeibullSurvival(X, K, Lambda)   // reliability function
TProbabilityKit.WeibullMean(K, Lambda)
TProbabilityKit.WeibullVariance(K, Lambda)
```

| Parameter | Meaning | Constraint |
|-----------|---------|-----------|
| `K` | Shape | > 0 |
| `Lambda` | Scale | > 0 |

**Failure rate interpretation:**
- `K < 1` → decreasing failure rate (infant mortality)
- `K = 1` → constant rate (= Exponential)
- `K > 1` → increasing failure rate (wear-out)

---

### Uniform (Continuous)

```pascal
TProbabilityKit.UniformPDF(X, A, B)      // = 1/(B-A) inside [A,B]
TProbabilityKit.UniformCDF(X, A, B)
TProbabilityKit.UniformSurvival(X, A, B)
TProbabilityKit.UniformMean(A, B)        // = (A+B)/2
TProbabilityKit.UniformVariance(A, B)   // = (B-A)²/12
```

---

## Discrete Distributions

### Binomial

```pascal
TProbabilityKit.BinomialPMF(K, N, P)      // P(X = K)
TProbabilityKit.BinomialCDF(K, N, P)      // P(X <= K)
TProbabilityKit.BinomialSurvival(K, N, P) // P(X > K)
TProbabilityKit.BinomialMean(N, P)        // = N*P
TProbabilityKit.BinomialVariance(N, P)    // = N*P*(1-P)
```

| Parameter | Meaning | Constraint |
|-----------|---------|-----------|
| `N` | Number of trials | >= 1 |
| `P` | Success probability per trial | [0, 1] |
| `K` | Number of successes | 0..N |

For PMF/CDF calls, values of K outside `0..N` return a clamped zero/one tail
rather than raising.

**Example:** probability of at most 2 defects in a batch of 20 items, where each item has a 5% defect rate:
```pascal
p := TProbabilityKit.BinomialCDF(2, 20, 0.05);
```

---

### Poisson

```pascal
TProbabilityKit.PoissonPMF(K, Lambda)      // P(X = K)
TProbabilityKit.PoissonCDF(K, Lambda)      // P(X <= K)
TProbabilityKit.PoissonSurvival(K, Lambda) // P(X > K)
TProbabilityKit.PoissonMean(Lambda)        // = Lambda
TProbabilityKit.PoissonVariance(Lambda)    // = Lambda
```

**When to use:** number of events in a fixed time or space — calls per hour, typos per page, cars per minute.

---

### Geometric

```pascal
// X = number of trials until the FIRST success (X >= 1)
TProbabilityKit.GeometricPMF(K, P)        // P(X = K) = (1-P)^(K-1) * P
TProbabilityKit.GeometricCDF(K, P)        // P(X <= K) = 1-(1-P)^K
TProbabilityKit.GeometricSurvival(K, P)   // P(X > K)  = (1-P)^K
TProbabilityKit.GeometricMean(P)          // = 1/P
TProbabilityKit.GeometricVariance(P)      // = (1-P)/P²
```

---

### Negative Binomial

```pascal
// X = total trials to achieve R successes
TProbabilityKit.NegBinomialPMF(K, R, P)   // P(X = K), K >= R
TProbabilityKit.NegBinomialCDF(K, R, P)
TProbabilityKit.NegBinomialMean(R, P)     // = R/P
TProbabilityKit.NegBinomialVariance(R, P) // = R*(1-P)/P²
```

---

### Hypergeometric

```pascal
// Sampling WITHOUT replacement
TProbabilityKit.HypergeometricPMF(K, PopSize, SuccPop, SampleN)
TProbabilityKit.HypergeometricCDF(K, PopSize, SuccPop, SampleN)
TProbabilityKit.HypergeometricMean(PopSize, SuccPop, SampleN)
TProbabilityKit.HypergeometricVariance(PopSize, SuccPop, SampleN)
```

| Parameter | Meaning |
|-----------|---------|
| `PopSize` | Total population size N |
| `SuccPop` | Number of successes in the population K |
| `SampleN` | Sample size drawn n |

Constraints are `PopSize >= 1`, `0 <= SuccPop <= PopSize`, and
`0 <= SampleN <= PopSize`.

**Example:** a box has 20 items, 7 are defective. You draw 5. What is P(exactly 2 are defective)?
```pascal
p := TProbabilityKit.HypergeometricPMF(2, 20, 7, 5);  // ≈ 0.388
```

---

## Error Handling

```pascal
try
  p := TProbabilityKit.NormalCDF(x, mu, 0);  // Sigma = 0 → invalid
except
  on E: EProbabilityError do
    WriteLn('Bad parameters: ', E.Message);
end;
```

`EProbabilityError` is raised by the validating entry points when:

- A scale/rate/shape parameter that must be positive is zero or negative
- `DF < 1` for Chi-Squared, Student's t, or F distributions
- `N < 1` or `P` outside [0,1] for Binomial
- `B <= A` for Uniform
- `R < 1` for Negative Binomial
- `SuccPop > PopSize` or `SampleN > PopSize` for Hypergeometric
- negative population, success, or sample counts for Hypergeometric
- NaN or infinite real inputs and parameters

The same domain validation applies consistently to PDF/PMF, CDF, survival,
mean, and variance helpers. The regularised incomplete-gamma evaluator reports
failure to converge with `EProbabilityError` rather than returning a partial
iterate.

---

## Worked Examples

### Is my data normal? — Chi-squared goodness-of-fit

```pascal
// After computing your test statistic chiStat with (bins-1) df:
pValue := TProbabilityKit.ChiSquaredSurvival(chiStat, bins - 1);
if pValue < 0.05 then
  WriteLn('Reject normality at 5% significance')
else
  WriteLn('Cannot reject normality');
```

### Confidence interval lookup — Student's t

```pascal
// Two-tailed p-value for t = 2.5 with 15 df:
p := TProbabilityKit.StudentTTwoTail(2.5, 15);  // ≈ 0.025
```

### Quality control — Binomial

```pascal
// A production line has a 2% defect rate. Batch of 100 items.
// P(at most 3 defects)?
p := TProbabilityKit.BinomialCDF(3, 100, 0.02);
```

### Reliability — Weibull survival

```pascal
// Component lifetime ~ Weibull(K=2, Lambda=1000 hours)
// P(surviving past 800 hours)?
reliability := TProbabilityKit.WeibullSurvival(800, 2, 1000);
```

---

## Dependencies

- `MathBase.SharedTypes` — `TDoubleArray`, `TDoublePair`
- `MathBase.Precision` — `GammaLn`, `BetaInc`, and `NormalCDF` used internally

No other external libraries required.
