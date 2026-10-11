#!/usr/bin/env python3
"""Generate independent 90-digit direct-DFT and overlap-add fixtures."""
from decimal import Decimal, getcontext
from pathlib import Path

getcontext().prec = 90
PI = Decimal(
    "3.141592653589793238462643383279502884197169399375105820974944592307816406286208998628034825342117068"
)
TWO_PI = 2 * PI


def sin_cos(value: Decimal) -> tuple[Decimal, Decimal]:
    value %= TWO_PI
    if value > PI:
        value -= TWO_PI
    x2 = value * value
    sin_term = value
    sin_value = value
    cos_term = Decimal(1)
    cos_value = Decimal(1)
    for k in range(1, 100):
        sin_term *= -x2 / Decimal((2 * k) * (2 * k + 1))
        cos_term *= -x2 / Decimal((2 * k - 1) * (2 * k))
        sin_value += sin_term
        cos_value += cos_term
        if abs(sin_term) < Decimal("1e-88") and abs(cos_term) < Decimal("1e-88"):
            break
    return sin_value, cos_value


def fmt(value: Decimal) -> str:
    if value == 0:
        return "0.0"
    return f"{value:.55E}".replace("E", "e")


n = 7
input_re = [Decimal((i * 7) % 13 - 6) / Decimal(7) for i in range(n)]
input_im = [Decimal((i * 5) % 11 - 5) / Decimal(9) for i in range(n)]
output_re: list[Decimal] = []
output_im: list[Decimal] = []
for k in range(n):
    real = Decimal(0)
    imag = Decimal(0)
    for sample in range(n):
        angle = TWO_PI * Decimal(k * sample) / Decimal(n)
        sine, cosine = sin_cos(angle)
        real += input_re[sample] * cosine + input_im[sample] * sine
        imag += input_im[sample] * cosine - input_re[sample] * sine
    output_re.append(real)
    output_im.append(imag)

lines = [
    "{ Generated with tools/generate_spectral_plan_fixtures.py; Python Decimal, 90-digit context. }",
    "const",
]
for name, values in (
    ("FFTFixture7InputRe", input_re),
    ("FFTFixture7InputIm", input_im),
    ("FFTFixture7ForwardRe", output_re),
    ("FFTFixture7ForwardIm", output_im),
):
    lines.append(f"  {name}: array[0..6] of Double = (")
    lines.append("    " + ",\n    ".join(fmt(value) for value in values) + ");")


def direct_dft(values: list[tuple[Decimal, Decimal]], inverse: bool = False):
    count = len(values)
    result = []
    direction = Decimal(1) if inverse else Decimal(-1)
    for bin_index in range(count):
        real = Decimal(0)
        imag = Decimal(0)
        for sample_index, (sample_re, sample_im) in enumerate(values):
            angle = direction * TWO_PI * Decimal(bin_index * sample_index) / Decimal(count)
            sine, cosine = sin_cos(angle)
            real += sample_re * cosine - sample_im * sine
            imag += sample_re * sine + sample_im * cosine
        if inverse:
            real /= Decimal(count)
            imag /= Decimal(count)
        result.append((real, imag))
    return result


# Small rectangular-window case with explicit padding, direct frame DFTs, and
# a conjugate-bin edit reconstructed by inverse DFT plus weighted overlap-add.
stft_input = [Decimal(value) for value in ("1", "-0.5", "0.25", "1.5", "-1.25")]
sample_count, frame_length, hop_length = 5, 4, 2
left_padding = frame_length - 1
frame_count = 1 + (sample_count + frame_length - 2 + hop_length - 1) // hop_length
padded_length = frame_length + (frame_count - 1) * hop_length
frames = []
for frame_index in range(frame_count):
    start = frame_index * hop_length - left_padding
    frame_values = []
    for local_index in range(frame_length):
        sample_index = start + local_index
        value = stft_input[sample_index] if 0 <= sample_index < sample_count else Decimal(0)
        frame_values.append((value, Decimal(0)))
    frames.append(frame_values)
stft_spectra = [direct_dft(frame) for frame in frames]

edited_spectra = [[value for value in spectrum] for spectrum in stft_spectra]
edited_spectra[2][1] = (edited_spectra[2][1][0] + Decimal("0.25"),
                         edited_spectra[2][1][1] + Decimal("0.125"))
edited_spectra[2][3] = (edited_spectra[2][3][0] + Decimal("0.25"),
                         edited_spectra[2][3][1] - Decimal("0.125"))
accumulator = [Decimal(0) for _ in range(padded_length)]
denominator = [Decimal(0) for _ in range(sample_count)]
for frame_index, spectrum in enumerate(edited_spectra):
    reconstructed = direct_dft(spectrum, inverse=True)
    for local_index, (value, _) in enumerate(reconstructed):
        padded_index = frame_index * hop_length + local_index
        accumulator[padded_index] += value
        sample_index = padded_index - left_padding
        if 0 <= sample_index < sample_count:
            denominator[sample_index] += Decimal(1)
stft_edited_output = [
    accumulator[left_padding + sample_index] / denominator[sample_index]
    for sample_index in range(sample_count)
]

lines.append("  STFTFixture5Input: array[0..4] of Double = (")
lines.append("    " + ",\n    ".join(fmt(value) for value in stft_input) + ");")
for suffix, component_index in (("Re", 0), ("Im", 1)):
    flattened = [spectrum[bin_index][component_index]
                 for spectrum in stft_spectra for bin_index in range(frame_length)]
    lines.append(f"  STFTFixture5Spectrum{suffix}: array[0..19] of Double = (")
    lines.append("    " + ",\n    ".join(fmt(value) for value in flattened) + ");")
lines.append("  STFTFixture5EditedOutput: array[0..4] of Double = (")
lines.append("    " + ",\n    ".join(fmt(value) for value in stft_edited_output) + ");")
Path("tests/SpectralPlanFixtures.inc").write_text(
    "\n".join(lines) + "\n", encoding="utf-8"
)
