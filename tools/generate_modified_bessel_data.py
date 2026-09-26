#!/usr/bin/env python3
"""Generate independent Modified Bessel I/K references and K coefficients.

Reference values use the DLMF integer-order power series with Decimal
arithmetic. The Pascal unit evaluates I by its positive series, K by its
small-argument series, a Chebyshev approximation on [2, 16], and the DLMF
large-argument expansion above 16.
"""

from __future__ import annotations

import argparse
from decimal import Decimal, localcontext
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
PRECISION = 120
GENERATOR_VERSION = 1
PI = Decimal(
    "3.141592653589793238462643383279502884197169399375105820974944592307816406286208998628034825342117067982148086513282306647"
)
EULER_GAMMA = Decimal(
    "0.5772156649015328606065120900824024310421593359399235988057672348848677267776646709369470632917467495146314472498070"
)
ARGUMENTS = (
    "1e-308", "1e-300", "1e-100", "0.000000000001", "0.000001", "0.01",
    "0.1", "0.5", "1", "1.999", "2", "2.001", "2.25", "2.5", "3",
    "3.5", "4", "4.5", "5.5", "6.5", "7.5", "7.999", "8", "8.001",
    "8.5", "9.5", "10", "10.5", "11.5", "12", "12.5", "13.5", "14.5",
    "15.5", "15.999", "16", "16.001", "20", "30", "50", "75", "100",
)
KINDS = ("I0", "I1", "K0", "K1")


def values(x: Decimal) -> dict[str, Decimal]:
    """Evaluate the integer-order power series at positive real *x*."""
    if x <= 0:
        raise ValueError("reference input must be positive")
    with localcontext() as context:
        context.prec = PRECISION
        q = x * x / 4
        term0 = Decimal(1)
        term1 = x / 2
        i0, i1 = term0, term1
        k0_sum = Decimal(0)
        k1_sum = -term1 * (1 - 2 * EULER_GAMMA) / 2
        harmonic = Decimal(0)
        cutoff = Decimal("1e-105")
        for k in range(1, 1000):
            harmonic += Decimal(1) / k
            term0 *= q / (k * k)
            term1 *= q / (k * (k + 1))
            i0 += term0
            i1 += term1
            k0_sum += harmonic * term0
            psi_sum = 2 * harmonic + Decimal(1) / (k + 1) - 2 * EULER_GAMMA
            k1_sum -= term1 * psi_sum / 2
            if abs(term0) < cutoff and abs(term1) < cutoff:
                break
        else:
            raise RuntimeError("modified Bessel reference series did not converge")
        log_term = (x / 2).ln() + EULER_GAMMA
        return {
            "I0": +i0,
            "I1": +i1,
            "K0": +(-log_term * i0 + k0_sum),
            "K1": +(1 / x + (log_term - EULER_GAMMA) * i1 + k1_sum),
        }


def decimal_cos(angle: Decimal) -> Decimal:
    with localcontext() as context:
        context.prec = PRECISION
        angle %= 2 * PI
        if angle > PI:
            angle -= 2 * PI
        term = Decimal(1)
        total = term
        for k in range(1, 160):
            term *= -angle * angle / ((2 * k - 1) * (2 * k))
            total += term
            if abs(term) < Decimal("1e-112"):
                return +total
        raise RuntimeError("cosine series did not converge")


def coefficients(kind: str, count: int = 64, nodes: int = 80) -> list[Decimal]:
    with localcontext() as context:
        context.prec = PRECISION
        angles = [PI * (Decimal(j) + Decimal("0.5")) / nodes for j in range(nodes)]
        sample_x = [9 + 7 * decimal_cos(angle) for angle in angles]
        sample_y = [values(x)[kind] for x in sample_x]
        return [
            +(
                2 * sum(
                    (value * decimal_cos(k * angle) for value, angle in zip(sample_y, angles)),
                    Decimal(0),
                ) / nodes
            )
            for k in range(count)
        ]


def write_or_check(path: Path, lines: list[str], check: bool) -> None:
    content = "\n".join(lines) + "\n"
    if check:
        if path.read_text(encoding="utf-8") != content:
            raise SystemExit(f"{path}: generated modified Bessel data differs")
    else:
        path.write_text(content, encoding="utf-8")


def update_coefficients(lines: list[str], check: bool) -> None:
    path = ROOT / "src" / "MathBase.SpecialFunctions.pas"
    source = path.read_text(encoding="utf-8")
    begin = "{ BEGIN GENERATED MODIFIED BESSEL COEFFICIENTS }"
    end = "{ END GENERATED MODIFIED BESSEL COEFFICIENTS }"
    start = source.index(begin) + len(begin)
    finish = source.index(end, start)
    generated = "\n" + "\n".join(lines) + "\n"
    if check:
        if source[start:finish] != generated:
            raise SystemExit(f"{path}: generated Chebyshev coefficients differ")
    else:
        path.write_text(source[:start] + generated + source[finish:], encoding="utf-8")


def generate(check: bool = False) -> None:
    with localcontext() as context:
        context.prec = PRECISION
        expected = {argument: values(Decimal(argument)) for argument in ARGUMENTS}
        assert abs(expected["1"]["I0"] - Decimal("1.2660658777520083")) < Decimal("1e-16")
        assert abs(expected["1"]["I1"] - Decimal("0.565159103992485")) < Decimal("1e-16")
        assert abs(expected["1"]["K0"] - Decimal("0.4210244382407083")) < Decimal("1e-16")
        assert abs(expected["1"]["K1"] - Decimal("0.6019072301972346")) < Decimal("1e-16")

        reference_lines = [
            f"{{ Generated by tools/generate_modified_bessel_data.py v{GENERATOR_VERSION}, Decimal precision {PRECISION}. }}",
            "{ References: https://dlmf.nist.gov/10.25.E2 and https://dlmf.nist.gov/10.31.E1. }",
            "const",
            f"  ModifiedBesselReferenceCount = {len(ARGUMENTS)};",
            "  ModifiedBesselReferences: array[0..ModifiedBesselReferenceCount - 1] of TModifiedBesselReference = (",
        ]
        for index, argument in enumerate(ARGUMENTS):
            row = expected[argument]
            comma = "," if index + 1 < len(ARGUMENTS) else ""
            rendered = [format(row[kind], ".17E") for kind in KINDS]
            reference_lines.append(
                "    (X: %s; I0: %s; I1: %s; K0: %s; K1: %s)%s"
                % (argument, *rendered, comma)
            )
        reference_lines.append("  );")
        write_or_check(ROOT / "tests" / "ModifiedBesselReference.inc", reference_lines, check)

        coefficient_lines = [
            f"{{ Generated by tools/generate_modified_bessel_data.py v{GENERATOR_VERSION}, Decimal precision {PRECISION}. }}",
            "{ Chebyshev interpolation on [2, 16], 80 nodes, 64 coefficients. }",
            "{ Formula source: https://dlmf.nist.gov/10.31.E1. }",
            "const",
        ]
        for kind in ("K0", "K1"):
            terms = coefficients(kind)
            coefficient_lines.append(f"  {kind}MiddleChebyshev: array[0..{len(terms) - 1}] of Double = (")
            for index, term in enumerate(terms):
                comma = "," if index + 1 < len(terms) else ""
                coefficient_lines.append(f"    {format(term, '.17E')}{comma}")
            coefficient_lines.append("  );")
        update_coefficients(coefficient_lines, check)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="verify committed data")
    generate(check=parser.parse_args().check)
