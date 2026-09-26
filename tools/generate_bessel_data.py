#!/usr/bin/env python3
"""Generate independent decimal Bessel references and [8, 16] Chebyshev data.

The reference calculation uses the DLMF 10.2.2 and 10.8.1 power series with
120-digit Decimal arithmetic. The Pascal implementation uses Double series
only at small arguments, Chebyshev approximations in the middle, and the DLMF
10.17 asymptotic expansion above 16. This generator is development-only.
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
KINDS = ("J0", "J1", "Y0", "Y1")
ARGUMENTS = (
    "1e-308", "1e-100", "0.000000000001", "0.0001", "0.01", "0.1", "0.5",
    "0.8935769662791675", "1", "2", "2.197141326031017",
    "2.404825557695773", "3", "3.831705970207512", "4",
    "7.999", "8", "8.001", "8.653727912911013", "9.4", "10",
    "10.173468135062722", "11.5", "11.791534439014281", "12",
    "13.323691936314223", "14.5", "14.930917708487786", "15.999", "16",
    "16.001", "20", "30", "40", "50", "75", "100",
)


def bessel_values(x: Decimal) -> dict[str, Decimal]:
    """Evaluate the integer-order series independently of the Pascal paths."""
    if x <= 0:
        raise ValueError("reference input must be positive")
    with localcontext() as context:
        context.prec = PRECISION
        q = x * x / 4
        j0_term = Decimal(1)
        j1_term = x / 2
        j0 = j0_term
        j1 = j1_term
        y0_series = Decimal(0)
        y1_series = j1_term  # H_0 + H_1 = 1
        harmonic = Decimal(0)
        cutoff = Decimal("1e-105")
        for k in range(1, 1000):
            harmonic += Decimal(1) / k
            j0_term *= -q / (k * k)
            j1_term *= -q / (k * (k + 1))
            j0 += j0_term
            j1 += j1_term
            y0_series -= harmonic * j0_term
            y1_series += (2 * harmonic + Decimal(1) / (k + 1)) * j1_term
            if abs(j0_term) < cutoff and abs(j1_term) < cutoff:
                break
        else:
            raise RuntimeError("reference series did not converge")
        log_term = (x / 2).ln() + EULER_GAMMA
        two_over_pi = 2 / PI
        return {
            "J0": +j0,
            "J1": +j1,
            "Y0": +(two_over_pi * (log_term * j0 + y0_series)),
            "Y1": +(-two_over_pi / x + two_over_pi * log_term * j1 - y1_series / PI),
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


def coefficients(kind: str, count: int = 40, nodes: int = 48) -> list[Decimal]:
    with localcontext() as context:
        context.prec = PRECISION
        angles = [PI * (Decimal(j) + Decimal("0.5")) / nodes for j in range(nodes)]
        values = [bessel_values(12 + 4 * decimal_cos(angle))[kind] for angle in angles]
        return [
            +(2 * sum((value * decimal_cos(k * angle) for value, angle in zip(values, angles)), Decimal(0)) / nodes)
            for k in range(count)
        ]


def save_or_check(path: Path, lines: list[str], check: bool) -> None:
    content = "\n".join(lines) + "\n"
    if check:
        if path.read_text(encoding="utf-8") != content:
            raise SystemExit(f"{path}: generated Bessel data differs")
    else:
        path.write_text(content, encoding="utf-8")


def update_source_coefficients(lines: list[str], check: bool) -> None:
    path = ROOT / "src" / "MathBase.SpecialFunctions.pas"
    source = path.read_text(encoding="utf-8")
    start_marker = "{ BEGIN GENERATED BESSEL COEFFICIENTS }"
    end_marker = "{ END GENERATED BESSEL COEFFICIENTS }"
    start = source.index(start_marker) + len(start_marker)
    end = source.index(end_marker, start)
    generated = "\n" + "\n".join(lines) + "\n"
    if check:
        if source[start:end] != generated:
            raise SystemExit(f"{path}: generated Bessel coefficients differ")
    else:
        path.write_text(source[:start] + generated + source[end:], encoding="utf-8")


def generate(check: bool = False) -> None:
    with localcontext() as context:
        context.prec = PRECISION
        expected = {argument: bessel_values(Decimal(argument)) for argument in ARGUMENTS}
        # Sanity values from standard Bessel tables; these checks catch a
        # mistaken sign or normalization in the independent series formulas.
        assert abs(expected["1"]["J0"] - Decimal("0.7651976865579666")) < Decimal("1e-16")
        assert abs(expected["1"]["J1"] - Decimal("0.4400505857449335")) < Decimal("1e-16")
        assert abs(expected["1"]["Y0"] - Decimal("0.08825696421567696")) < Decimal("1e-16")
        assert abs(expected["1"]["Y1"] + Decimal("0.7812128213002887")) < Decimal("1e-16")

        reference_lines = [
            f"{{ Generated by tools/generate_bessel_data.py v{GENERATOR_VERSION}, Decimal precision {PRECISION}. }}",
            "{ References: https://dlmf.nist.gov/10.2 and https://dlmf.nist.gov/10.8. }",
            "const",
            f"  BesselReferenceCount = {len(ARGUMENTS)};",
            "  BesselReferences: array[0..BesselReferenceCount - 1] of TBesselReference = (",
        ]
        for index, argument in enumerate(ARGUMENTS):
            values = expected[argument]
            suffix = "," if index + 1 < len(ARGUMENTS) else ""
            reference_lines.append(
                "    (X: %s; J0: %s; J1: %s; Y0: %s; Y1: %s)%s"
                % (argument, *(format(values[kind], ".17E") for kind in KINDS), suffix)
            )
        reference_lines.append("  );")
        save_or_check(ROOT / "tests" / "BesselReference.inc", reference_lines, check)

        coefficient_lines = [
            f"{{ Generated by tools/generate_bessel_data.py v{GENERATOR_VERSION}, Decimal precision {PRECISION}. }}",
            "{ Chebyshev interpolation on [8, 16], 48 nodes, 40 coefficients. }",
            "{ Formula source: https://dlmf.nist.gov/10.2 and https://dlmf.nist.gov/10.8. }",
            "const",
        ]
        for kind in KINDS:
            terms = coefficients(kind)
            coefficient_lines.append(f"  {kind}Chebyshev: array[0..{len(terms) - 1}] of Double = (")
            for index, term in enumerate(terms):
                suffix = "," if index + 1 < len(terms) else ""
                coefficient_lines.append(f"    {format(term, '.17E')}{suffix}")
            coefficient_lines.append("  );")
        update_source_coefficients(coefficient_lines, check)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="verify committed data")
    generate(check=parser.parse_args().check)
