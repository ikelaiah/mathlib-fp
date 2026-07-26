#!/usr/bin/env python3
"""Check local links, fences, inventory data, and the 1.6 public-symbol contract."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"


def heading_slugs(text: str) -> set[str]:
    result = set()
    for heading in re.findall(r"^#{1,6}\s+(.+)$", text, re.M):
        value = re.sub(r"[^\w\s-]", "", heading.lower(), flags=re.UNICODE)
        result.add(re.sub(r"\s", "-", value).strip("-"))
    return result


def main() -> int:
    errors: list[str] = []
    docs = sorted(DOCS.rglob("*.md"))
    for path in docs:
        text = path.read_text(encoding="utf-8")
        if text.count("```") % 2:
            errors.append(f"{path.relative_to(ROOT)}: unbalanced code fence")
        for target in re.findall(r"\[[^\]]+\]\(([^)]+)\)", text):
            if re.match(r"^(?:https?:|mailto:)", target):
                continue
            file_part, _, anchor = target.partition("#")
            linked = (path.parent / file_part).resolve() if file_part else path
            if not linked.exists():
                errors.append(
                    f"{path.relative_to(ROOT)}: missing local link {target}"
                )
            elif anchor and linked.suffix.lower() == ".md":
                linked_text = linked.read_text(encoding="utf-8")
                if anchor not in heading_slugs(linked_text):
                    errors.append(
                        f"{path.relative_to(ROOT)}: missing anchor {target}"
                    )

    inventory_path = DOCS / "capabilities.json"
    try:
        inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
        assert inventory["release"] == "1.6.0"
        assert inventory["schema_version"] == 1
        assert inventory["capabilities"]
    except (ValueError, KeyError, AssertionError) as exc:
        errors.append(f"docs/capabilities.json: invalid inventory: {exc}")

    public_docs = "\n".join(path.read_text(encoding="utf-8") for path in docs)
    required_symbols = [
        "TSingleComplex",
        "IDenseSingleMatrix",
        "IDenseDoubleMatrix",
        "IDenseSingleComplexMatrix",
        "IDenseComplexMatrix",
        "TDenseSingleMatrix",
        "TDenseDoubleMatrix",
        "TDenseSingleComplexMatrix",
        "TDenseComplexMatrix",
        "EDenseMatrixError",
        "DENSE_ALIGNMENT",
        "StorageIdentity",
        "TDenseShape",
        "TSingleMatrixArray",
        "TComplexMatrixArray",
        "TSingleComplexMatrixArray",
        "TSizeIntArray",
        "TSmallSingleMatrix2",
        "TSmallDoubleMatrix2",
        "TSmallSingleComplexMatrix2",
        "TSmallComplexMatrix2",
        "TSmallSingleMatrix2Batch",
        "TSmallDoubleMatrix2Batch",
        "TSmallSingleComplexMatrix2Batch",
        "TSmallComplexMatrix2Batch",
        "ToVector",
        "ConvertToDouble",
        "ConvertToSingle",
        "ConvertToComplex",
        "ConvertToReal",
        "ConvertToDoubleComplex",
        "ConvertToSingleComplex",
        "TSingleUnaryKernel",
        "TDoubleUnaryKernel",
        "TSingleComplexUnaryKernel",
        "TComplexUnaryKernel",
        "AxpyInto",
        "ApplyInto",
        "CopyInto",
        "ConjugateInto",
        "ConjugateTransposeInto",
        "Norm2",
        "MultiplyInto",
        "FactorLU",
        "FactorCholesky",
        "Solve",
        "IDenseSingleLU",
        "IDenseDoubleLU",
        "IDenseSingleComplexLU",
        "IDenseComplexLU",
        "IDenseSingleCholesky",
        "IDenseDoubleCholesky",
        "IDenseSingleComplexCholesky",
        "IDenseComplexCholesky",
        "TDenseSolveDiagnostics",
        "SolveWithInfo",
        "SolvePositiveDefinite",
        "SolveTriangular",
        "TDenseTriangle",
        "TDenseDiagonal",
        "TDenseTranspose",
        "FactorQR",
        "FactorPivotedQR",
        "LeastSquares",
        "RankRevealingLeastSquares",
        "IDenseSingleQR",
        "IDenseDoubleQR",
        "IDenseSingleComplexQR",
        "IDenseComplexQR",
        "FactorSVD",
        "MinimumNormSolve",
        "IDenseSingleSVD",
        "IDenseDoubleSVD",
        "IDenseSingleComplexSVD",
        "IDenseComplexSVD",
        "FactorSymmetricEigen",
        "FactorHermitianEigen",
        "IDenseSingleSymmetricEigen",
        "IDenseDoubleSymmetricEigen",
        "IDenseSingleComplexHermitianEigen",
        "IDenseComplexHermitianEigen",
    ]
    for symbol in required_symbols:
        if symbol not in public_docs:
            errors.append(f"public symbol has no documentation mention: {symbol}")

    examples = sorted((ROOT / "examples").glob("*.pas"))
    index = (ROOT / "examples" / "README.md").read_text(encoding="utf-8")
    for example in examples:
        if example.name not in index:
            errors.append(f"example missing from examples/README.md: {example.name}")

    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(
        f"Documentation checks passed: {len(docs)} pages, "
        f"{len(examples)} indexed examples, {len(required_symbols)} 1.6 symbols"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
