# Supported platform matrix

Version 1.9.2 uses only Free Pascal source and standard RTL/FCL units.

| Tier | Compiler | OS / CPU | `Single` | `Double` | `Extended` ABI | Qualification |
| --- | --- | --- | --- | --- | --- | --- |
| Primary | FPC 3.2.2 | Windows x86-64 | IEEE binary32 | IEEE binary64 | 64-bit alias on Win64 | Full suite, examples, benchmarks, package |
| Primary | FPC 3.2.2 | Linux x86-64 | IEEE binary32 | IEEE binary64 | 80-bit extended | Full suite, examples, benchmarks |
| Secondary | FPC 3.2.2 | Windows i386 | IEEE binary32 | IEEE binary64 | 80-bit extended | Optimised full suite and package |

Other targets may compile but are not claimed as release-qualified until they
are added to this table with reproducible evidence. `Extended` remains
deliberately outside the typed dense/sparse storage paths in the 1.9 line because its
precision differs by ABI.

Dimensions use `SizeInt`; allocation products are checked before allocation on
32- and 64-bit targets. Practical dimensions remain limited by address space
and available memory.

