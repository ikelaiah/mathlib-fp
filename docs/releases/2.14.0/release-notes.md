### Added

- Added owned GLM and PLS prediction records and projection from fitted models, keeping prediction independent of persistence.
- Added versioned GLM and PLS save/load adapters with explicit family, link, intercept, preprocessing and column-order conventions, checked sizes, finite values and CRC32 integrity.
- Added an artifact-only consumer, scaled PLS and weighted offset/exposure GLM workflows, malformed-artifact tests and fixed compatibility fixtures for existing model formats.

### Compatibility

- Existing fit-result prediction APIs and model envelope version 1 remain available. Legacy model kind codes and bytes are preserved. Artifacts contain prediction parameters; training diagnostics and general object graphs are outside this format.
