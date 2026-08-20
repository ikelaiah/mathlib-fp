# Contributing to mathlib-fp

Thank you for your interest in contributing to mathlib-fp! We want to make
contributing to this project as easy and transparent as possible.

## 📝 Code of Conduct

- Be respectful and inclusive
- Use welcoming and inclusive language
- Be collaborative
- Focus on what is best for the community
- Show empathy towards other community members

## 🚀 Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/your-username/mathlib-fp.git
   ```
3. Create a new branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## 💻 Development Guidelines

### Code Style

- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions focused and small
- Follow existing code formatting

### Commit Messages

- Use Conventional Commit subjects: `type(scope): concise description`
- Common types are `feat`, `fix`, `docs`, `test`, `refactor`, `perf`, and `build`
- Use a domain name such as `algebra`, `stats`, or `engineering` as the scope
- Reference issues in the body when relevant

Example:
```
fix(algebra): compute fractional powers from symmetric eigenpairs

- reject non-positive-definite matrices
- add reconstruction and residual tests
Fixes #123
```

### Testing

- Add unit tests for new functionality
- Ensure all tests pass before submitting PR
- Rebuild with `-FcUTF8` and resolve compiler warnings
- Test on Windows (minimum requirement)
- If possible, test on Linux/macOS

```bash
cd tests
fpc -B -FcUTF8 -Fu../src -FUlib TestRunner.lpr
./TestRunner -a --format=plain
```

### Continuous integration

The normal `CI` workflow runs on every push and pull request and covers the
Linux and Windows unit tests, example compilation and output contracts,
documentation and API sanity checks, compiler-backed documentation examples,
and the Lazarus package build. Heavyweight release-oriented gates — mutation
testing, full performance and portability evidence, migration and workflow
rehearsal, convergence/2.0 promotion checks, and clean-archive, checksum, and
network-isolated qualification — run only in the scheduled/manual `Release
qualification` workflow and on release publications, not on every PR.

### Documentation

- Update README.md if needed
- Add/update API documentation
- Include examples for new features
- Update changelog

Run the static contract check and compiler-backed documentation examples:

```bash
python tools/test_api_snapshot.py
python tools/test_doc_examples.py
python tools/test_example_output.py
python tools/test_built_docs.py
python tools/check_docs.py
python tools/check_doc_examples.py
python tools/check_example_output.py
release=$(cat VERSION)
python tools/build_docs.py --release "$release" \
  --output "build-temp/docs-site/$release"
python tools/check_built_docs.py \
  --site "build-temp/docs-site/$release" --release "$release"
```

Release-facing Pascal fences must be self-contained: the documentation gate
wraps fragments that begin with `uses`, compiles them against `src/`, and runs
the resulting program. An output-producing runnable fence must be followed by
an `Expected output:` exact text fence or an `Expected output contains:` fence;
the execution gate compares the observed result. This catches stale
signatures, statuses, numerical claims, and success markers as well as syntax
errors.

Use the project terminology defined in the
[documentation index](docs/index.md#terminology):

- **domain** for a functional area such as finance or geometry
- **unit family** for a prefix such as `FinanceLib`
- **unit** for a Pascal unit such as `FinanceLib.Interest`
- **Kit class** only for a public type such as `TFinanceKit`
- **package** for the optional Lazarus package

Do not add empty wrapper units or Kit classes solely to make names look
symmetrical. New public identifiers must describe a useful API boundary.

## 📋 Pull Request Process

1. Update the README.md with details of changes if needed
2. Update the documentation
3. Add tests for new functionality
4. Ensure the test suite passes
5. Update the CHANGELOG.md
6. Submit a pull request

### Contribution gate for new domains

A new domain (a functional area such as finance, geometry, or DSP) or a new
algorithm family inside an existing domain is accepted only when:

1. a documented, demonstrated user need exists (an issue, a completed
   workflow that cannot finish, or a repeated support question);
2. a design record fixes the public types, ownership, mutation, indexing,
   shape, error, tolerance, and compatibility contracts before code lands;
3. at least one independent mathematical reference or published algorithm is
   named, and its licence is compatible with MIT redistribution;
4. tests, API documentation, selection guidance, and a runnable example land
   in the same change as the implementation; and
5. the capability inventory and the closed capability manifest are updated in
   the same change.

Proposals that do not meet the gate are deferred explicitly rather than left
open. The normative policy is
[`docs/GOVERNANCE.md`](docs/GOVERNANCE.md#contribution-gate-for-new-domains).

### Pull Request Title Format

```
type(scope): short description
```

Use the same Conventional Commit types as commit subjects.

## 🐛 Reporting Issues

- Use the issue tracker
- Describe the bug or feature request clearly
- Include code examples if relevant
- Provide system information (OS, FPC version)

## 📚 Documentation Contributions

We especially welcome documentation improvements:
- Fix typos
- Add examples
- Clarify confusing sections
- Add missing documentation
- Translate documentation

## ⭐ Recognition

Contributors may be recognized in release notes and project documentation.

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.
