# 2.3.0 qualification

**Status:** Pending.

The release requires a checksummed clean-source-archive qualification on Linux
and a checksummed clean-ZIP qualification on Windows. Both profiles include
the full test and example suites, documentation and output checks, numerical,
performance, and portability gates; Windows also builds the Lazarus package
for Win64 and Win32. Linux additionally runs with new outbound connections
blocked.

| Platform | Result | Evidence |
| --- | --- | --- |
| Linux x86-64, FPC 3.2.2 | Pending | Release qualification workflow |
| Windows x86-64, FPC 3.2.2, Lazarus 4.8 | Pending | Release qualification workflow |

The completed workflow record and its checksummed artifacts will be linked
from [workflow qualification](workflow-qualification.md).
