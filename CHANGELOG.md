# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

...

## [1.0.1] - 2026-04-16

### Fixed

- `AlgebraLib.Matrices` — `TMatrixKit.IsPositiveDefinite` previously used an
  insufficient check (determinant > 0 and positive diagonal elements), which is
  not a sufficient condition for positive definiteness. It now attempts a Cholesky
  factorisation; success is the definitive test for symmetric positive definite matrices.
- `AlgebraLib.Matrices` — `TMatrixKit.IsPositiveSemidefinite` had the same flaw.
  It now computes all eigenvalues via `EigenDecomposition` and checks that none are
  less than −1e-9.
- `AlgebraLib.Matrices` — `TMatrixKit.Cholesky` previously called `IsPositiveDefinite`
  as a pre-check, which created a circular dependency after the above fix. The guard has
  been replaced with an inline check: if the diagonal term under the square root is
  negative, `EMatrixError` is raised immediately.

### Performance

- `AlgebraLib.Matrices` — `TMatrixKit.Determinant` replaced recursive cofactor
  expansion (O(n!)) with an LU-based calculation (O(n³)). The determinant is derived
  from the product of the diagonal of U, with sign determined by counting permutation
  cycles in the LU pivot array. Singular matrices return 0.
- `AlgebraLib.Matrices` — `BLOCK_SIZE` increased from 4 to 64. The previous value
  was too small to provide any L1 cache benefit; 64 doubles (512 bytes) fits
  comfortably within a typical 32 KB L1 cache per block face.
- `AlgebraLib.Matrices` — `TMatrixKit.Multiply` now uses parallel execution for
  matrices with 64 or more rows. A pool of `TThread.ProcessorCount` worker threads
  is spawned, each computing a disjoint range of output rows. Smaller matrices
  continue to use the existing block or standard path. No locks are required as
  output rows are fully independent.

## [1.0.0] - 2026-04-14

### Changed

- The math modules (`TStatsKit`, `TFinanceKit`, `TMatrixKit`, `TTrigKit`, and supporting
  units) have been separated from [tidykit-fp](https://github.com/ikelaiah/tidykit-fp)
  into this standalone monorepo.
- Source reorganised into focused sub-libraries: `MathBase`, `AlgebraLib`, `FinanceLib`,
  `EngineeringLib`, and `StatsLib`, each with its own `README.md`.
- Unit namespaces updated to match the new library structure
  (e.g. `MathBase.SharedTypes`, `AlgebraLib.Matrices`, `StatsLib.Stats`).
- `EngineeringLib` expanded with `uFluidDynamics.pas`, `uThermodynamics.pas`,
  `uSignal.pas`, and `uUnitConversion.pas`.
- `MathBase` expanded with `uTrigonometry.pas` (previously part of the math module in tidykit-fp).

### Removed

- All non-math modules (Strings, FS, DateTime, JSON, Logger, Request, Crypto, Archive)
  are no longer part of this repository; they remain in tidykit-fp.

---

## Release [0.1.7] - 2025-05-dd

### Added

- ...

### Fixes

- ...


## Release [0.1.6] - 2025-04-24

### Added

- More examples to showcase the usage of the FS module.

### Fixes

- Various bugfixes and improvements to the FS module.
- Bugfix Logger unit

## [0.1.5] - 2025-04-21

### Added

- Added Ubuntu 24.04.02 compatibility for DateTime and FS modules
- Added automatic test environment detection for the HTTP request module
- Added HTTP fallback mechanism for testing HTTPS endpoints when OpenSSL is unavailable
- Added detailed OpenSSL installation instructions for Linux distributions
- Added cross-platform SSL/TLS initialization support for HTTP requests

### Fixed

- Fixed file timestamp handling issues on Unix systems
- Fixed path normalization for cross-platform compatibility
- Resolved file path length detection issues on Linux
- Corrected directory sorting behavior on Unix filesystems
- Fixed OpenSSL initialization and error handling on Linux systems
- Fixed HTTP request error handling to work consistently across platforms
- Improved TryGet and TryPost error handling for SSL failures

### Changed

- Reorganized platform-specific code for better readability
- Improved test organization with clearer platform-specific sections 
- Enhanced comments throughout platform-specific code sections
- Refactored Request module to use platform-specific implementations of SSL initialization
- Updated documentation to include Linux OpenSSL dependencies for HTTPS support

### Removed

...

## [0.1.0] - 2025-03-13

### Added

- Comprehensive Math modules:
  - Statistical calculations (`TStatsKit` class)
  - Financial mathematics (`TFinanceKit` class)
  - Matrix operations with decompositions (`TMatrixKit` class)
  - Trigonometric functions (`TTrigKit` class)
- JSON operations with interface-based memory management
- Logging system with multiple output destinations
- Cryptography enhancements:
  - SHA3 implementation
  - SHA2 family (SHA-256, SHA-512, SHA-512/256)
  - AES-256 encryption with CBC and CTR modes
- Archive operations (ZIP/TAR)
- HTTP client with request/response handling
- String representations for all matrix decompositions
- Initial release
- FileSystem operations (`TFileKit`)
- String operations (`TStringKit`)
- DateTime operations (`TDateTimeKit`)
- Core functionality
- Cross-platform support (Windows tested)
- Core mathematical types and operations
- Base file system operations
- String manipulation capabilities
- Basic error handling

### Improved

- Comprehensive documentation:
  - Created dedicated documentation files for each math module
  - Added detailed examples for all operations
  - Improved API references with mathematical explanations
  - Added cheat sheet for quick reference
- Memory-safe interface design for matrices
- Professional README with badges and detailed feature list
- Code organization and naming consistency

### Fixed

- String representation format for matrix decompositions
- Precision handling in financial calculations
- Memory leaks in matrix operations
- Error handling in statistical functions

### Known Issues

- Limited timezone support on Unix-like systems
- Untested on macOS and FreeBSD platforms