# v2.10.0 review notes

Repeated subjects could cross a random fold boundary in the default PLS
workflow. Callers can now supply explicit grouped training/validation rows,
inspect per-split errors, and test on a group held entirely outside component
selection. The old seeded PLS path is preserved.

Validation: focused split/PLS tests, full normal/optimized/checked suites,
all examples, clean-archive qualification and a fresh consumer before release.
