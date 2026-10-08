# 2.4.0 workflow qualification

**Status:** Local Windows workflow qualification passed; release CI is pending.

The local release qualifier ran three representative workflows on Windows
11 x86-64 with Free Pascal 3.2.2. All three completed successfully and their
output and exported-artifact digests matched the committed qualification
contracts. Machine-readable results are in
[`workflow-qualification-win64.json`](workflow-qualification-win64.json),
with overall release results in [`qualification-win64.json`](qualification-win64.json).

The release qualification workflow must repeat these checks from clean source
archives on Linux x86-64 and Windows x86-64 before publication.
