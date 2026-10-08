# 2.4.0 workflow qualification

**Status:** Local Windows and clean-archive Linux/Windows workflow checks passed.
The stable release branch and tag repeat these checks automatically.

The local release qualifier ran three representative workflows on Windows
11 x86-64 with Free Pascal 3.2.2. All three completed successfully and their
output and exported-artifact digests matched the committed qualification
contracts. Machine-readable results are in
[`workflow-qualification-win64.json`](workflow-qualification-win64.json),
with overall release results in [`qualification-win64.json`](qualification-win64.json).

The three representative workflows passed in candidate qualification run
[37772756273](https://github.com/ikelaiah/mathlib-fp/actions/runs/37772756273)
from clean Linux and Windows source archives. The release workflow repeats
these checks on the stable release commit and tag.
