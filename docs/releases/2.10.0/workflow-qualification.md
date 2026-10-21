# v2.10.0 workflow qualification

The [grouped model validation example](../../../examples/47_grouped_model_validation.pas)
keeps one subject outside fitting and component selection, then compares PLS
and ordinary least squares on exactly those three test rows. The training
groups are held out whole during PLS component selection. The example asserts
the analytic response and its printed output has an explicit contract.

Final supported-platform results are recorded in
[qualification.md](qualification.md).
