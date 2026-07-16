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
- Use a library name such as `algebra`, `stats`, or `engineering` as the scope
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

### Documentation

- Update README.md if needed
- Add/update API documentation
- Include examples for new features
- Update changelog

## 📋 Pull Request Process

1. Update the README.md with details of changes if needed
2. Update the documentation
3. Add tests for new functionality
4. Ensure the test suite passes
5. Update the CHANGELOG.md
6. Submit a pull request

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
