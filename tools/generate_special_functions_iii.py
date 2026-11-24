#!/usr/bin/env python3
"""Generate binary64-facing references and Taylor anchors with mpmath 1.3.0."""

from __future__ import annotations

import argparse
import math
import random
from pathlib import Path

import mpmath as mp


ROOT = Path(__file__).resolve().parent.parent
AIRY = {
    "Ai": mp.airyai,
    "Bi": mp.airybi,
    "AiPrime": lambda x: mp.airyai(x, 1),
    "BiPrime": lambda x: mp.airybi(x, 1),
}
BESSEL = {"J": mp.besselj, "Y": mp.bessely, "I": mp.besseli, "K": mp.besselk}
# Binary64 inputs close to the first J and Y roots for each order.
BESSEL_ROOT_INPUTS = {
    0: (2.404825557695773, 0.8935769662791675),
    1: (3.8317059702075125, 2.197141326031017),
    2: (5.135622301840683, 3.3842417671495935),
    3: (6.380161895923983, 4.527024661149643),
    7: (11.086370019245084, 8.91960573487379),
    16: (21.08514611306472, 18.451433996482454),
    31: (37.15811301753659, 34.00968133821454),
    32: (38.21669118960383, 35.03993249555728),
}


def literal(value: float) -> str:
    return f"{value:.17E}"


def power_of_ten(exponent: float) -> float:
    return float(mp.power(10, mp.mpf(exponent)))


def reference_rows() -> list[str]:
    rng = random.Random(216)
    rows: list[str] = []

    def add(kind: str, order: int, points: list[float], oracle) -> None:
        for x in sorted(set(map(float, points))):
            value = float(oracle(mp.mpf(x)))
            expected = 0.0 if math.isinf(value) else value
            infinity_sign = int(math.copysign(1, value)) if math.isinf(value) else 0
            rows.append(
                f"    (Kind: sf{kind}; Order: {order}; X: {literal(x)};\n"
                f"     Expected: {literal(expected)}; InfinitySign: {infinity_sign})"
            )

    shapes = [0.125, 0.5, 1.0, 1.4616321449683623, 2.0, 15.999, 16.0, 16.001]
    shapes += [power_of_ten(rng.uniform(-7, 8)) for _ in range(18)]
    add("Digamma", 0, shapes + [1e-310, 1e-308, 1e300], mp.digamma)
    for order in (1, 2, 3, 8, 16):
        extreme = [power_of_ten(-310 / (order + 1)), power_of_ten(-307 / (order + 1)),
                   power_of_ten(309 / order), power_of_ten(324 / order - 2)] if order > 1 else [1e-155, 1e-153, 1e308]
        add("Polygamma", order, shapes + [31.999, 32.0, 32.001] + extreme,
            lambda x: mp.polygamma(order, x))

    zeta_points = [math.nextafter(1.0, math.inf), 1.00000001, 1.01, 1.5, 2.0,
                   3.0, 16.0, 32.0, 52.0, 53.0, 54.0, 64.0, 1e6]
    add("Zeta", 0, zeta_points + [1.0 + power_of_ten(rng.uniform(-12, 2)) for _ in range(20)], mp.zeta)

    branch_point = -1.0 / math.e
    neighbours = []
    x = branch_point
    for _ in range(8):
        x = math.nextafter(x, math.inf)
        neighbours.append(x)
    negative = neighbours + [-0.36785, -0.3677, -0.367, -0.36, -0.3, -0.25,
                             -0.1, -0.01, -1e-8, -1e-9, -1e-100, -1e-300, -5e-324]
    negative += [-power_of_ten(rng.uniform(-310, -1)) for _ in range(16)]
    negative += [rng.uniform(branch_point, 0.0) for _ in range(32)]
    transition = branch_point + 0.02 ** 2 / (2.0 * math.e)
    negative += [transition - 1e-11, transition + 1e-11]
    add("LambertW", -1, negative, lambda x: mp.lambertw(x, -1))
    add("LambertW", 0, negative + [0.0, 5e-324, 1e-8, 0.01, 1.0, math.e, 10.0,
                                    1e100, 1e308, float.fromhex("0x1.fffffffffffffp+1023")], mp.lambertw)

    for order, root_inputs in BESSEL_ROOT_INPUTS.items():
        xs = [0.001, 0.1, 1.0, 3.999, 4.0, 4.001, 7.999, 8.0, 8.001, 15.999,
              16.0, 16.001, 32.0, 60.0, 100.0]
        if order:
            xs += [order - 0.001, float(order), order + 0.001,
                   power_of_ten(-311 / order), power_of_ten(-299 / order)]
        xs += [rng.uniform(0.01, 100.0) for _ in range(8)]
        xs.extend(root_inputs)
        for kind, oracle in BESSEL.items():
            if kind in "JI":
                points = xs + [-0.5, -6.0, -100.0, 0.0]
            elif order:
                # The dominant small-x term locates the overflow transition.
                maximum = mp.mpf(float.fromhex("0x1.fffffffffffffp+1023"))
                scale = mp.pi if kind == "Y" else 2
                overflow_x = float(2 * mp.root(mp.factorial(order - 1) / (scale * maximum), order))
                points = xs + [overflow_x * 0.999999, overflow_x * 1.000001]
            else:
                points = xs
            add(kind, order, points, lambda x: oracle(order, x))

    airy_points = [-100.0, -99.75, -25.0, -12.001, -12.0, -11.999, -0.5, 0.0,
                   0.5, 11.499, 11.5, 11.501, 11.999, 12.0, 12.001, 50.0,
                   103.0, 104.0, 104.2, 104.4, 104.6, 105.0, 106.0, 107.0,
                   107.4, 107.6, 107.8, 108.0, 110.0, 120.0]
    airy_points += [rng.uniform(-100.0, 120.0) for _ in range(28)]
    with mp.workdps(20):
        airy_points += [float(mp.airyaizero(k)) for k in (1, 3, 12)]
        airy_points += [float(mp.airybizero(k)) for k in (1, 3, 12)]
    for kind, oracle in AIRY.items():
        add(kind, 0, airy_points, oracle)
    return rows


def write_or_check(path: Path, content: str, check: bool) -> None:
    if check and path.read_text(encoding="utf-8") != content:
        raise SystemExit(f"{path}: generated data differs")
    if not check:
        path.write_text(content, encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    check = parser.parse_args().check
    if mp.__version__ != "1.3.0":
        raise SystemExit("Use mpmath 1.3.0 to reproduce the reference data")
    with mp.workdps(100):
        rows = reference_rows()
        fixtures = (
            "{ Generated by tools/generate_special_functions_iii.py, mpmath 1.3.0. }\n"
            f"const\n  SpecialFunctionReferences: array[0..{len(rows) - 1}] "
            "of TSpecialFunctionReference = (\n" + ",\n".join(rows) + "\n  );\n"
        )
        write_or_check(ROOT / "tests/SpecialFunctionsIIIReference.inc", fixtures, check)

        anchors = []
        for x in range(-12, 13):
            values = [literal(float(oracle(mp.mpf(x)))) for oracle in AIRY.values()]
            anchors.append(f"    ({', '.join(values)}) {{ X = {x} }}")
        content = (
            "{ Generated by tools/generate_special_functions_iii.py, mpmath 1.3.0. }\n"
            "const\n  AiryAnchors: array[-12..12, 0..3] of Double = (\n"
            + ",\n".join(anchors) + "\n  );\n"
        )
        source_path = ROOT / "src/MathBase.SpecialFunctions.pas"
        source = source_path.read_text(encoding="utf-8")
        marker = "{ BEGIN GENERATED AIRY ANCHORS }"
        start = source.index(marker) + len(marker)
        end = source.index("{ END GENERATED AIRY ANCHORS }", start)
        write_or_check(source_path, source[:start] + "\n" + content + source[end:], check)


if __name__ == "__main__":
    main()
