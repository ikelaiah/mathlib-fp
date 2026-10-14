#!/usr/bin/env python3
"""Generate independent high-precision PLS1 fit/CV reference values.

This is a small Decimal implementation written for a fixed, exact fixture. It
uses no project code, NumPy, or external packages. The Pascal implementation
uses binary64 arithmetic; this script evaluates the same documented PLS1
deflation equations at 80 decimal digits.
"""

from __future__ import annotations

import argparse
from decimal import Decimal, localcontext
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / "tests" / "PLSReference.inc"
SEED = 1729
FOLDS = 5
TOLERANCE = Decimal("1e-12")


def fixture():
    x = []
    y = []
    for i in range(10):
        t = Decimal(i) - Decimal("4.5")
        u = Decimal((i * 7) % 11 - 5)
        x.append([t, Decimal(2) * t + u, -t + Decimal(3) * u])
        y.append(Decimal(5) + Decimal("1.5") * t - Decimal("0.8") * u)
    return x, y


def mean(values):
    result = Decimal(0)
    for i, value in enumerate(values, 1):
        result += (value - result) / Decimal(i)
    return result


def sample_scale(values, center):
    if len(values) <= 1:
        return Decimal(0)
    return (sum((value - center) ** 2 for value in values) / Decimal(len(values) - 1)).sqrt()


def prepare(x, y):
    n = len(x)
    p = len(x[0])
    means = [mean([x[i][j] for i in range(n)]) for j in range(p)]
    scales = [sample_scale([x[i][j] for i in range(n)], means[j]) for j in range(p)]
    scales = [scale if scale else Decimal(1) for scale in scales]
    x_scaled = [[(x[i][j] - means[j]) / scales[j] for j in range(p)] for i in range(n)]
    y_mean = mean(y)
    y_scale = sample_scale(y, y_mean) or Decimal(1)
    y_scaled = [(value - y_mean) / y_scale for value in y]
    return x_scaled, y_scaled, means, scales, y_mean, y_scale


def numerical_rank(x, tolerance=TOLERANCE):
    n = len(x)
    p = len(x[0])
    basis = []
    for j in range(p):
        vector = [x[i][j] for i in range(n)]
        initial = sum(value * value for value in vector).sqrt()
        if not initial:
            continue
        for _ in range(2):
            for q in basis:
                projection = sum(a * b for a, b in zip(q, vector))
                vector = [value - projection * direction for value, direction in zip(vector, q)]
        residual = sum(value * value for value in vector).sqrt()
        if residual <= tolerance * initial:
            continue
        basis.append([value / residual for value in vector])
    return len(basis)


def fit_components(x_scaled, y_scaled, max_components):
    n = len(x_scaled)
    p = len(x_scaled[0])
    residual_x = [row[:] for row in x_scaled]
    residual_y = y_scaled[:]
    weights = []
    loadings = []
    rotations = []
    scores = []
    betas = [[Decimal(0) for _ in range(p)]]
    for _ in range(max_components):
        covariance = [
            sum(residual_x[i][j] * residual_y[i] for i in range(n))
            for j in range(p)
        ]
        cross_norm = sum(value * value for value in covariance).sqrt()
        x_norm = sum(value * value for row in residual_x for value in row).sqrt()
        y_norm = sum(value * value for value in residual_y).sqrt()
        if not x_norm or not y_norm or not cross_norm:
            break
        if cross_norm / x_norm / y_norm <= TOLERANCE:
            break
        weight = [value / cross_norm for value in covariance]
        score = [sum(residual_x[i][j] * weight[j] for j in range(p)) for i in range(n)]
        orthogonalization = [Decimal(0) for _ in scores]
        for _pass in range(2):
            for k, previous_score in enumerate(scores):
                projection = sum(a * b for a, b in zip(previous_score, score)) / sum(
                    value * value for value in previous_score
                )
                orthogonalization[k] += projection
                score = [value - projection * direction for value, direction in zip(score, previous_score)]
        score_norm_squared = sum(value * value for value in score)
        if not score_norm_squared:
            break
        loading = [
            sum(residual_x[i][j] * score[i] for i in range(n)) / score_norm_squared
            for j in range(p)
        ]
        loading_y = sum(a * b for a, b in zip(residual_y, score)) / score_norm_squared
        rotation = weight[:]
        for k, previous_rotation in enumerate(rotations):
            adjusted = sum(a * b for a, b in zip(loadings[k], weight)) + orthogonalization[k]
            rotation = [value - adjusted * direction for value, direction in zip(rotation, previous_rotation)]
        weights.append(weight)
        loadings.append(loading)
        rotations.append(rotation)
        scores.append(score)
        betas.append([
            betas[-1][j] + loading_y * rotation[j] for j in range(p)
        ])
        residual_x = [
            [residual_x[i][j] - score[i] * loading[j] for j in range(p)]
            for i in range(n)
        ]
        residual_y = [residual_y[i] - score[i] * loading_y for i in range(n)]
    return betas


def train_model(x, y, maximum):
    x_scaled, y_scaled, means, scales, y_mean, y_scale = prepare(x, y)
    rank = numerical_rank(x_scaled)
    betas = fit_components(x_scaled, y_scaled, min(maximum, rank))
    raw_betas = []
    for beta in betas:
        coefficients = [beta[j] * y_scale / scales[j] for j in range(len(scales))]
        intercept = y_mean - sum(means[j] * coefficients[j] for j in range(len(scales)))
        raw_betas.append((intercept, coefficients))
    return raw_betas


def next_random(state):
    return (state * 1664525 + 1013904223) & 0xFFFFFFFF


def fold_ids(count, folds, seed):
    order = list(range(count))
    state = seed
    for i in range(count - 1, 0, -1):
        state = next_random(state)
        j = state % (i + 1)
        order[i], order[j] = order[j], order[i]
    result = [0] * count
    for i, row in enumerate(order):
        result[row] = i % folds
    return result


def cross_validate(x, y, maximum):
    ids = fold_ids(len(x), FOLDS, SEED)
    errors = [[] for _ in range(maximum + 1)]
    common_maximum = maximum
    for fold in range(FOLDS):
        train_indexes = [i for i, value in enumerate(ids) if value != fold]
        test_indexes = [i for i, value in enumerate(ids) if value == fold]
        train_x = [x[i] for i in train_indexes]
        train_y = [y[i] for i in train_indexes]
        models = train_model(train_x, train_y, maximum)
        common_maximum = min(common_maximum, len(models) - 1)
        for component in range(len(models)):
            intercept, coefficients = models[component]
            for i in test_indexes:
                prediction = intercept + sum(
                    coefficients[j] * x[i][j] for j in range(len(coefficients))
                )
                errors[component].append(y[i] - prediction)
    rmse = [
        (sum(value * value for value in errors[k]) / Decimal(len(x))).sqrt()
        for k in range(common_maximum + 1)
    ]
    return rmse


def pascal(value: Decimal) -> str:
    return f"{value:.24E}"


def render() -> str:
    with localcontext() as context:
        context.prec = 80
        x, y = fixture()
        rank = numerical_rank(prepare(x, y)[0])
        cv = cross_validate(x, y, rank)
        selected = min(range(len(cv)), key=lambda k: (cv[k], k))
        intercept, coefficients = train_model(x, y, selected)[selected]
        coefficient_values = ",\n  ".join(pascal(value) for value in coefficients)
        cv_values = ",\n  ".join(pascal(value) for value in cv)
        return (
            "{ Generated by tools/generate_pls_reference.py; do not edit. }\n"
            f"const\n  PLSReferenceRank = {rank};\n"
            f"  PLSReferenceSelectedComponents = {selected};\n"
            f"  PLSReferenceIntercept: Double = {pascal(intercept)};\n"
            "  PLSReferenceCoefficients: array[0..2] of Double = (\n  "
            f"{coefficient_values});\n"
            "  PLSReferenceRMSECV: array[0..2] of Double = (\n  "
            f"{cv_values});\n"
        )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    expected = render()
    if args.check:
        if not OUTPUT.exists() or OUTPUT.read_text(encoding="utf-8") != expected:
            raise SystemExit("PLS reference is stale; run tools/generate_pls_reference.py")
        print(f"PLS reference verified: {OUTPUT.relative_to(ROOT)}")
        return 0
    OUTPUT.write_text(expected, encoding="utf-8", newline="\n")
    print(f"Wrote {OUTPUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
