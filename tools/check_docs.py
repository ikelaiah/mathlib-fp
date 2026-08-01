#!/usr/bin/env python3
"""Check local links, fences, inventory data, and the public-symbol contract."""

from __future__ import annotations

import json
import hashlib
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"


def normalized_interface(source: str) -> str:
    match = re.search(r"(?mi)^implementation\s*$", source)
    if not match:
        raise ValueError("unit has no implementation delimiter")
    text = source[: match.start()].replace("\r\n", "\n").replace("\r", "\n")
    return "\n".join(line.rstrip() for line in text.splitlines()) + "\n"


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
        assert inventory["release"] == "1.9.0"
        assert inventory["schema_version"] == 1
        assert inventory["capabilities"]
    except (ValueError, KeyError, AssertionError) as exc:
        errors.append(f"docs/capabilities.json: invalid inventory: {exc}")

    snapshot_path = DOCS / "public-api-1.9.json"
    snapshot_symbols: set[str] = set()
    snapshot_declarations: list[tuple[str, dict[str, object]]] = []
    try:
        snapshot = json.loads(snapshot_path.read_text(encoding="utf-8"))
        assert snapshot["release"] == "1.9.0"
        assert snapshot["schema_version"] == 2
        assert snapshot["identity"] == [
            "unit",
            "owner",
            "kind",
            "name",
            "signature",
        ]
        snapshot_units = {unit["source"]: unit for unit in snapshot["units"]}
        source_paths = sorted((ROOT / "src").glob("*.pas"))
        expected_sources = {path.relative_to(ROOT).as_posix() for path in source_paths}
        if set(snapshot_units) != expected_sources:
            errors.append(
                "docs/public-api-1.9.json: source-unit set differs from src/*.pas"
            )
        for source_path in source_paths:
            relative = source_path.relative_to(ROOT).as_posix()
            source = source_path.read_text(encoding="utf-8-sig")
            digest = hashlib.sha256(
                normalized_interface(source).encode("utf-8")
            ).hexdigest()
            unit = snapshot_units.get(relative)
            if unit is not None and unit["interface_sha256"] != digest:
                errors.append(
                    f"{relative}: public interface differs from 1.9 snapshot; "
                    "document the reason and regenerate with "
                    "tools/update_api_snapshot.py"
                )
            if unit is not None:
                identities: set[tuple[object, ...]] = set()
                owner_classes = {
                    declaration["name"]: declaration["classification"]
                    for declaration in unit["declarations"]
                    if declaration["owner"] is None
                }
                for declaration in unit["declarations"]:
                    snapshot_declarations.append((unit["unit"], declaration))
                    snapshot_symbols.add(declaration["name"])
                    identity = (
                        unit["unit"],
                        declaration["owner"],
                        declaration["kind"],
                        declaration["name"].casefold(),
                        declaration["signature"].casefold(),
                    )
                    if identity in identities:
                        errors.append(
                            f"{relative}: duplicate API declaration identity "
                            f"{declaration['owner']}.{declaration['name']}"
                        )
                    identities.add(identity)
                    if declaration["classification"] not in {
                        "primary",
                        "compatibility",
                        "deprecated",
                        "experimental",
                        "internal",
                    }:
                        errors.append(
                            f"{relative}: invalid API classification for "
                            f"{declaration['owner']}.{declaration['name']}"
                        )
                    owner = declaration["owner"]
                    if (
                        owner is not None
                        and owner_classes.get(owner) in {"compatibility", "internal"}
                        and declaration["classification"] != owner_classes[owner]
                    ):
                        errors.append(
                            f"{relative}: {owner}.{declaration['name']} does not "
                            "inherit its owner's API classification"
                        )
                    replacement = declaration.get("preferred_replacement")
                    if replacement and replacement not in snapshot_symbols:
                        # Check globally after all units have been collected.
                        pass
        assert isinstance(snapshot["deprecations"], list)
        for deprecated in snapshot["deprecations"]:
            declaration_key = deprecated["declaration"]
            replacement_key = deprecated["replacement"]
            assert isinstance(declaration_key, dict)
            assert isinstance(replacement_key, dict)
            for selector in (declaration_key, replacement_key):
                matches = [
                    item
                    for unit_name, item in snapshot_declarations
                    if unit_name == selector["unit"]
                    and item["owner"] == selector["owner"]
                    and item["kind"] == selector["kind"]
                    and item["name"] == selector["name"]
                    and item["signature"] == selector["signature"]
                ]
                assert len(matches) == 1
        for unit_name, declaration in snapshot_declarations:
            replacement = declaration.get("preferred_replacement")
            if replacement and replacement not in snapshot_symbols:
                errors.append(
                    f"{unit_name}: preferred replacement {replacement} for "
                    f"{declaration['owner']}.{declaration['name']} is absent"
                )
    except (ValueError, KeyError, AssertionError) as exc:
        errors.append(f"docs/public-api-1.9.json: invalid snapshot: {exc}")

    reference_path = DOCS / "API_REFERENCE_1.9.md"
    reference_text = reference_path.read_text(encoding="utf-8")
    reference_rows = set(reference_text.splitlines())
    for unit_name, declaration in snapshot_declarations:
        owner = declaration["owner"] or "(unit)"
        replacement = declaration.get("preferred_replacement", "—")

        def code(value: object) -> str:
            return (
                "`"
                + str(value).replace("|", r"\|").replace("`", r"\`")
                + "`"
            )

        expected_row = (
            "| "
            + " | ".join(
                [
                    code(owner),
                    code(declaration["kind"]),
                    code(declaration["name"]),
                    code(declaration["signature"]),
                    code(declaration["classification"]),
                    code(replacement),
                ]
            )
            + " |"
        )
        if expected_row not in reference_rows:
            errors.append(
                "docs/API_REFERENCE_1.9.md: missing exact declaration row for "
                f"{unit_name}.{owner}.{declaration['name']}"
            )

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
        "TIterationStatus",
        "IterationStatusName",
        "TDifferentiationKit",
        "TDual",
        "dmComplexStep",
        "TComplexScalarVectorFunction",
        "TDualVectorFunction",
        "TJacobianMatrixFunction",
        "DualTan",
        "DualSinh",
        "DualCosh",
        "DualTanh",
        "AutoGradient",
        "AutoJacobian",
        "ComplexStepGradient",
        "CheckGradient",
        "TJacobianCheckResult",
        "CheckJacobian",
        "TBarycentricInterpolator",
        "TCubicInterpolator",
        "TSplineBoundaryKind",
        "TCubicSplineInterpolator",
        "TGridSurface",
        "TScatteredInterpolator",
        "TInterpolationKit",
        "TModellingKit",
        "TIntegrationResult",
        "TFitResult",
        "TSplineFitResult",
        "FitSplineBasis",
        "TNonlinearFitOptions",
        "ParameterScales",
        "TVectorRootResult",
        "TPolynomialRootResult",
        "IntegrateCubature",
        "IntegrateMonteCarlo",
        "FitNonlinearAuto",
        "SolveSystemAuto",
        "SolvePolynomial",
        "TAdaptiveODEOptions",
        "AbsoluteTolerances",
        "TAdaptiveODESolution",
        "TOptimizationOptions",
        "TOptimizationWorkspace",
        "TOptimizationProgress",
        "TConstraintKind",
        "TSmoothConstraints",
        "TMultivarFunctions",
        "TOptResults",
        "TObjectiveMatrix",
        "NonlinearConjugateGradient",
        "BoundedLBFGS",
        "BoundedLBFGSWithWorkspace",
        "TrustRegion",
        "LBFGSAuto",
        "MultiStart",
        "TSmoothConstraint",
        "SolveConstrained",
        "TMultiObjectiveResult",
        "ExplorePareto",
        "lpsInfeasible",
        "TConvexOptimizationKit",
        "TQuadraticProgram",
        "TSecondOrderCone",
        "TConvexOptions",
        "TConvexResult",
        "TRandomState",
        "TLocalRandom",
        "TOnlineStatistics",
        "TNonFinitePolicy",
        "TDSPKit",
        "TFFTNormalization",
        "TComplexBatch",
        "TSingleComplexBatch",
        "TOverlapAddConvolver",
        "TOverlapSaveConvolver",
        "TransformBatch",
        "HaarTransform",
        "TStreamingFIR",
        "TStreamingBiquad",
        "TSpectralEstimate",
        "TNormalDistribution",
        "TExponentialDistribution",
        "TBinomialDistribution",
        "EInferenceError",
        "TCountMatrix",
        "TDistributionEstimate",
        "TInferenceTestResult",
        "TANOVAResult",
        "TContingencyResult",
        "TRegressionDiagnostics",
        "TLogisticRegressionResult",
        "TInferenceKit",
        "EstimateNormal",
        "EstimateExponential",
        "EstimateGamma",
        "EstimateBinomial",
        "OneSampleT",
        "PairedT",
        "WelchT",
        "OneWayANOVA",
        "ChiSquareContingency",
        "AdjustBonferroni",
        "AdjustBenjaminiHochberg",
        "FitOLS",
        "FitLogistic",
        "TAnalysisKit",
        "TPCAResult",
        "TKMeansPlusPlusResult",
        "THierarchicalLinkage",
        "THierarchicalClustering",
        "TStandardizationModel",
        "TForestTask",
        "TDecisionTreeNode",
        "TDecisionTreeNodes",
        "TDecisionTreeModel",
        "TDecisionTrees",
        "TDecisionForest",
        "FitStandardization",
        "TransformStandardized",
        "HierarchicalCluster",
        "CutHierarchy",
        "FitClassificationForest",
        "FitRegressionForest",
        "PredictForestClasses",
        "PredictForestValues",
        "TKDTree",
        "TScalarKalmanConfiguration",
        "TScalarKalmanFilter",
        "TMultivariateKalmanConfiguration",
        "TDenseDoubleMatrixArray",
        "TMultivariateKalmanFilter",
        "TMultivariateKalmanStep",
        "TMultivariateKalmanSeriesResult",
        "TMultivariateKalmanForecast",
        "SaveBinary",
        "LoadDoubleMatrixBinary",
        "WriteMatrixMarket",
        "TValueMetadata",
        "TInterchangeScalarType",
        "TInterchangeValueKind",
        "Describe",
        "SaveCubicSpline",
        "LoadCubicSpline",
        "SaveStreamingFIR",
        "LoadStreamingFIR",
        "SaveStandardization",
        "LoadStandardization",
        "SaveScalarKalman",
        "LoadScalarKalman",
        "DEFAULT_MAX_MODEL_ELEMENTS",
        "EModelInterchangeError",
        "SummarizeCubicSpline",
        "SummarizeStreamingFIR",
        "SummarizeStandardization",
        "SummarizeScalarKalman",
        "EExpressionError",
        "TExpressionValueKind",
        "TExpressionValue",
        "TExpressionSymbol",
        "TExpressionSymbols",
        "TExpressionLimits",
        "TExpressionEvaluator",
        "TDenseMultiplyPath",
        "MultiplyBlockedInto",
        "MultiplyAutoInto",
        "SelectedMultiplyPath",
        "ISparseSingleMatrix",
        "ISparseDoubleMatrix",
        "ISparseSingleComplexMatrix",
        "ISparseComplexMatrix",
        "TSparseDoubleTripletBuilder",
        "TSparseStoredZeroPolicy",
        "IStructuredDoubleMatrix",
        "ILinearDoubleOperator",
        "IMatrixFreeDoubleAction",
        "IPreconditioner",
        "TDoublePreconditioner",
        "TLinearSolveOptions",
        "TLinearSolveDiagnostics",
        "InitialNormalResidualNorm",
        "FinalNormalResidualNorm",
        "ResidualRefreshCount",
        "ConvergenceConfirmed",
        "TDoubleIterativeWorkspace",
        "TDoubleIterativeSolver",
        "ConjugateGradient",
        "MINRES",
        "GMRES",
        "BiCGSTAB",
        "LSQR",
        "TDoubleStructuredSolver",
        "ISparseDoubleLUFactor",
        "TSpectralOptions",
        "TSpectralResult",
        "TDoublePartialEigenSolver",
        "WriteSparseMatrixMarket",
        "SaveSparseBinary",
        "LoadSparseDoubleBinary",
        "DEFAULT_MAX_SPARSE_DIMENSION",
    ]
    for symbol in required_symbols:
        if snapshot_symbols and symbol not in snapshot_symbols:
            errors.append(f"required symbol is absent from API snapshot: {symbol}")
        if symbol not in public_docs:
            errors.append(f"public symbol has no documentation mention: {symbol}")

    defaults_to_check = {
        "TLinearSolveOptions": {
            "MaxIterations": "1000",
            "RelativeTolerance": "1.0e-8",
            "AbsoluteTolerance": "0.0",
            "RestartSize": "30",
            "ResidualRefresh": "50",
            "BreakdownTolerance": "1.0e-30",
            "ConfirmConvergence": "True",
            "Monitor": "nil",
        },
        "TSpectralOptions": {
            "EigenpairCount": "1",
            "KrylovDimension": "20",
            "MaximumRestarts": "20",
            "Tolerance": "1.0e-8",
            "BreakdownTolerance": "1.0e-14",
            "StartingSeed": "QWord($4D595DF4D0F33173)",
            "Target": "stLargestMagnitude",
        },
    }
    default_sources = {
        "TLinearSolveOptions": (
            ROOT / "src" / "AlgebraLib.IterativeSolvers.pas"
        ).read_text(encoding="utf-8-sig"),
        "TSpectralOptions": (
            ROOT / "src" / "AlgebraLib.PartialEigensystems.pas"
        ).read_text(encoding="utf-8-sig"),
    }
    sparse_guide = (DOCS / "SparseLinearAlgebra.md").read_text(encoding="utf-8")
    for record_name, fields in defaults_to_check.items():
        for field, value in fields.items():
            contract_fields = [
                declaration
                for _, declaration in snapshot_declarations
                if declaration["owner"] == record_name
                and declaration["name"] == field
                and declaration["kind"] == "field"
            ]
            if len(contract_fields) != 1:
                errors.append(
                    f"{record_name}.{field}: expected one owner-aware field "
                    f"declaration in API snapshot, found {len(contract_fields)}"
                )
            source_pattern = rf"Result\.{re.escape(field)}\s*:=\s*{re.escape(value)}\s*;"
            if not re.search(source_pattern, default_sources[record_name], re.I):
                errors.append(
                    f"{record_name}.{field}: implementation default is not {value}"
                )
            documented_value = value.replace("QWord(", "").rstrip(")")
            if field not in sparse_guide or documented_value not in sparse_guide:
                errors.append(
                    f"{record_name}.{field}: default {value} is not documented"
                )

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
        f"{len(examples)} indexed examples, {len(required_symbols)} public symbols, "
        f"{len(snapshot_declarations)} owner/signature-aware declarations"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
