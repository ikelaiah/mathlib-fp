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
CURRENT_RELEASE = "1.9.6"
NEXT_RELEASE = "1.9.7"
API_BASELINE_RELEASE = "1.9.0"
API_DECISION_RELEASE = "1.9.3"
HISTORICAL_RELEASES = ["1.9.5", "1.9.4", "1.9.3", "1.9.2", "1.9.1", API_BASELINE_RELEASE]

LEARNING_ROUTE_DOCUMENTS = {
    "MathBase.md": "#quick-start",
    "AlgebraLib.md": "TypedDenseMatrices.md#60-second-solve",
    "FinanceLib.md": "#quick-start",
    "StatsLib.md": "#quick-start",
    "EngineeringLib.md": "#quick-start",
    "NumericsLib.md": "#quick-start",
    "ProbabilityLib.md": "#quick-start",
    "CombinatoricsLib.md": "#quick-start",
    "OptimizationLib.md": "#quick-start",
    "TimeSeriesLib.md": "#quick-start",
    "MLLib.md": "#quick-start",
    "Interchange.md": "#60-second-round-trip",
    "GeometryLib.md": "#quick-start",
}

REQUIRED_PROBLEM_QUERIES = (
    "least squares",
    "normal probability",
    "FFT convolution",
)


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
        result.add(re.sub(r"\s+", "-", value).strip("-"))
    return result


def roadmap_release_state_errors(
    roadmap: str, current_release: str, next_release: str,
) -> list[str]:
    """Return errors when a shipped release is not advanced in the Roadmap."""
    errors = []
    if f"## Previous release: {current_release}" not in roadmap:
        errors.append(
            f"Roadmap does not record {current_release} as the previous release"
        )
    if f"## Next release: {next_release}" not in roadmap:
        errors.append(
            f"Roadmap does not name {next_release} as the next release"
        )
    return errors


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

    for name, beginner_target in LEARNING_ROUTE_DOCUMENTS.items():
        path = DOCS / name
        text = path.read_text(encoding="utf-8")
        headings = (
            "## Learning routes",
            "### Beginner route",
            "### Common tasks and algorithm choice",
            "### Advanced route",
        )
        positions = [text.find(heading) for heading in headings]
        if any(position < 0 for position in positions) or positions != sorted(positions):
            errors.append(
                f"docs/{name}: learning-route headings are missing or out of order"
            )
        if beginner_target not in text:
            errors.append(
                f"docs/{name}: beginner route does not link {beginner_target}"
            )
        advanced_start = text.find("### Advanced route")
        advanced_end = text.find("\n## ", advanced_start + 1)
        advanced = text[
            advanced_start : advanced_end if advanced_end >= 0 else len(text)
        ]
        if "../examples/" not in advanced or ".pas" not in advanced:
            errors.append(
                f"docs/{name}: advanced route has no runnable example link"
            )

    required_learning_pages = (
        "BEGINNER_GUIDE.md",
        "RECIPES.md",
        "AUTOMATED_JOURNEYS_1.9.2.md",
        "PR_NOTES_1.9.2.md",
    )
    for name in required_learning_pages:
        if not (DOCS / name).is_file():
            errors.append(f"missing 1.9.2 learning document: docs/{name}")

    required_decision_pages = (
        "API_COMMON_PATHS_2.0.md",
        "API_CONVENTIONS_2.0.md",
        "API_DIFF_1.9_TO_2.0.md",
        "api-decision-2.0.json",
        "api-diff-1.9-to-2.0.json",
        "PR_NOTES_1.9.3.md",
    )
    for name in required_decision_pages:
        if not (DOCS / name).is_file():
            errors.append(f"missing 1.9.3 API-decision document: docs/{name}")

    recipes = (DOCS / "RECIPES.md").read_text(encoding="utf-8")
    for query in REQUIRED_PROBLEM_QUERIES:
        if query.casefold() not in recipes.casefold():
            errors.append(f"docs/RECIPES.md: missing problem query {query!r}")
    recipe_sections = (
        "Dense square solve",
        "Dense least squares",
        "Sparse solve",
        "Descriptive and streaming statistics",
        "Normal probability",
        "Interpolation and fitting",
        "Optimisation",
        "FFT convolution and filtering",
        "Time series",
        "Finance",
        "Geometry",
        "Unit conversion",
    )
    for heading in recipe_sections:
        if f"## {heading}" not in recipes:
            errors.append(f"docs/RECIPES.md: missing recipe section {heading!r}")

    inventory_path = DOCS / "capabilities.json"
    try:
        inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
        assert inventory["release"] == CURRENT_RELEASE
        assert inventory["schema_version"] == 1
        assert inventory["support_matrix"] == "docs/SUPPORT.md"
        assert inventory["portability_evidence"] == (
            "docs/portability-evidence-1.9.6.json"
        )
        assert inventory["capabilities"]
    except (ValueError, KeyError, AssertionError) as exc:
        errors.append(f"docs/capabilities.json: invalid inventory: {exc}")

    snapshot_path = DOCS / "public-api-1.9.json"
    snapshot_symbols: set[str] = set()
    snapshot_declarations: list[tuple[str, dict[str, object]]] = []
    try:
        snapshot = json.loads(snapshot_path.read_text(encoding="utf-8"))
        assert snapshot["release"] == API_BASELINE_RELEASE
        assert snapshot["schema_version"] == 3
        assert snapshot["decision_release"] == API_DECISION_RELEASE
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
                        "recommended",
                        "advanced",
                        "compatibility",
                        "experimental",
                        "implementation",
                    }:
                        errors.append(
                            f"{relative}: invalid API classification for "
                            f"{declaration['owner']}.{declaration['name']}"
                        )
                    owner = declaration["owner"]
                    if (
                        owner is not None
                        and owner_classes.get(owner) in {
                            "compatibility",
                            "implementation",
                        }
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
        assert snapshot["unresolved_decisions"] == []
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

    def code(value: object) -> str:
        return (
            "`"
            + str(value).replace("|", r"\|").replace("`", r"\`")
            + "`"
        )

    for unit_name, declaration in snapshot_declarations:
        owner = declaration["owner"] or "(unit)"
        replacement = declaration.get("preferred_replacement", "—")
        compatibility_decision = declaration.get("compatibility_decision", "—")
        compatibility_note = declaration.get("compatibility_note", "—")

        expected_row = (
            "| "
            + " | ".join(
                [
                    code(owner),
                    code(declaration["kind"]),
                    code(declaration["name"]),
                    code(declaration["signature"]),
                    code(declaration["classification"]),
                    code(compatibility_decision),
                    code(replacement),
                    code(compatibility_note),
                ]
            )
            + " |"
        )
        if expected_row not in reference_rows:
            errors.append(
                "docs/API_REFERENCE_1.9.md: missing exact declaration row for "
                f"{unit_name}.{owner}.{declaration['name']}"
            )

    try:
        decision = json.loads(
            (DOCS / "api-decision-2.0.json").read_text(encoding="utf-8")
        )
        assert decision["schema_version"] == 2
        assert len(decision["alias_reviews"]) == 21
        for review in decision["alias_reviews"]:
            selector = review["selector"]
            alias_name = f"{selector['unit']}.{selector['name']}"
            status = review["status"]
            if review.get("follow_up_release"):
                status += f"; revisit {review['follow_up_release']}"
            expected_row = (
                "| "
                + " | ".join(
                    [
                        code(alias_name),
                        code(review["target"]),
                        code(review["decision"]),
                        code(review.get("canonical", "—")),
                        code(status),
                        str(review["reason"]).replace("|", r"\|"),
                    ]
                )
                + " |"
            )
            if expected_row not in reference_rows:
                errors.append(
                    "docs/API_REFERENCE_1.9.md: missing exact alias-review row "
                    f"for {alias_name}"
                )
    except (ValueError, KeyError, AssertionError) as exc:
        errors.append(f"docs/api-decision-2.0.json: invalid alias review: {exc}")

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

    try:
        versions = json.loads((DOCS / "versions.json").read_text(encoding="utf-8"))
        assert versions["schema_version"] == 1
        assert versions["current"] == CURRENT_RELEASE
        listed_releases = [item["release"] for item in versions["versions"]]
        assert listed_releases == [CURRENT_RELEASE, *HISTORICAL_RELEASES]
        assert versions["site_url"].startswith("https://")
        assert versions["repository_url"].startswith("https://")
    except (ValueError, KeyError, AssertionError) as exc:
        errors.append(f"docs/versions.json: invalid version manifest: {exc}")

    release_files = [
        DOCS / f"RELEASE_NOTES_{CURRENT_RELEASE}.md",
        DOCS / f"PR_NOTES_{CURRENT_RELEASE}.md",
        DOCS / f"QUALIFICATION_{CURRENT_RELEASE}.md",
        DOCS / f"PORTABILITY_EVIDENCE_{CURRENT_RELEASE}.md",
        DOCS / "FEEDBACK.md",
    ]
    for release_file in release_files:
        if not release_file.is_file():
            errors.append(f"missing release document: {release_file.relative_to(ROOT)}")

    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    roadmap = (DOCS / "ROADMAP.md").read_text(encoding="utf-8")
    support = (DOCS / "SUPPORT.md").read_text(encoding="utf-8")
    changelog = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    package = (ROOT / "packages" / "lazarus" / "mathlib_fp.lpk").read_text(
        encoding="utf-8"
    )
    identity_checks = {
        "README badge": f"version-{CURRENT_RELEASE}-brightgreen" in readme,
        "README release notes": f"RELEASE_NOTES_{CURRENT_RELEASE}.md" in readme,
        "README direct archive": f"tags/v{CURRENT_RELEASE}.tar.gz" in readme,
        "support matrix": f"Version {CURRENT_RELEASE}" in support,
        "changelog": f"## [{CURRENT_RELEASE}]" in changelog,
        "Lazarus package": '<Version Major="1" Minor="9" Release="6"/>' in package,
    }
    for description, valid in identity_checks.items():
        if not valid:
            errors.append(f"release identity mismatch: {description}")
    errors.extend(
        roadmap_release_state_errors(roadmap, CURRENT_RELEASE, NEXT_RELEASE)
    )

    contracts_path = ROOT / "examples" / "output-contracts.json"
    try:
        contract_data = json.loads(contracts_path.read_text(encoding="utf-8"))
        assert contract_data["schema_version"] == 1
        contracts = contract_data["examples"]
        assert len(contracts) == 4
        for contract in contracts:
            source = ROOT / contract["path"]
            assert source.is_file()
            assert contract["contains"]
            final_line = contract["final_line"]
            assert final_line in source.read_text(encoding="utf-8")
    except (ValueError, KeyError, AssertionError) as exc:
        errors.append(f"examples/output-contracts.json: invalid contracts: {exc}")

    feedback_form = (
        ROOT / ".github" / "ISSUE_TEMPLATE" / "release_feedback.yml"
    ).read_text(encoding="utf-8")
    feedback_terms = [
        "Installation time", "Confusing type choice", "Boilerplate conversion",
        "Unexpected error or status", "Missing algorithm-selection guidance",
        "Migration from an earlier API",
    ]
    for term in feedback_terms:
        if term not in feedback_form:
            errors.append(f"release feedback form is missing category: {term}")

    for workflow in ("documentation.yml", "release-qualification.yml"):
        if not (ROOT / ".github" / "workflows" / workflow).is_file():
            errors.append(f"missing release workflow: .github/workflows/{workflow}")
    documentation_workflow = (
        ROOT / ".github" / "workflows" / "documentation.yml"
    ).read_text(encoding="utf-8")
    if "check_built_docs.py --site site" not in documentation_workflow:
        errors.append("documentation workflow does not check built-site links")

    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(
        f"Documentation checks passed: {len(docs)} pages, "
        f"{len(LEARNING_ROUTE_DOCUMENTS)} learning routes, "
        f"{len(examples)} indexed examples, {len(required_symbols)} public symbols, "
        f"{len(snapshot_declarations)} owner/signature-aware declarations"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
