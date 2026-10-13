# v2.7.0 workflow qualification

The runnable [GLM workflow](../../../examples/44_generalized_linear_models.pas)
fits logistic and Poisson slopes on an explicitly constructed design, inspects
standard errors/deviance/Pearson diagnostics, predicts counts for new rows,
and handles a complete-separation certificate without treating it as a fit.

Its checked output includes logistic slope `0.361321`, Poisson slope
`0.476797`, predicted counts `1.058467` and `2.746745`, and the final marker
`GLM workflow: success`. It compiled and ran on Windows x86-64 with FPC 3.2.2.
The complete release qualification also executes all examples and retained
cross-domain workflows from their checked-in sources. Hosted clean-archive
checks will be recorded in the qualification report before tagging.
