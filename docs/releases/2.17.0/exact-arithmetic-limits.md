# Exact arithmetic limits and resource measurements

`MaxExactIntegerBits` is 131,072. A public magnitude holds up to 4,096
32-bit limbs, a 16 KiB limb payload. Each reduced rational component is
subject to the same bound. Parsing checks the digit count, including leading
zeroes, before it constructs the magnitude. Operations may use scratch
magnitudes of twice the public limb width plus one carry limb. Normalized
division can use one additional guard limb.

Comparison and addition are linear in the limb count. Schoolbook
multiplication is proportional to the product of the operand limb counts.
Multi-limb division work is proportional to divisor limbs times quotient
limbs, and GCD repeats division. The actual cost of rational operations
depends on the sizes and common factors of their components.

The [benchmark](../../../benchmarks/ExactArithmeticEvidence.lpr) used
FPC 3.2.2 with `-O3` on Windows 11, on an Intel family 6 model 141
processor with 16 logical CPUs. Elapsed milliseconds are for the
entire batch. Peak extra bytes are the Pascal heap high-water mark minus
live heap at the start of the timed batch. They include result and allocator
storage. Any higher peak from setup is also visible in the raw output.

| Operation | Base operand limbs | Calls | Win64 ms | Win64 peak extra bytes | Win32 ms | Win32 peak extra bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Multiply | 8 | 1,024 | 0.262 | 192 | 1.587 | 160 |
| Multiply | 128 | 32 | 1.308 | 2,176 | 8.938 | 2,112 |
| Multiply | 2,048 | 1 | 7.781 | 16,448 | 73.779 | 16,416 |
| Divide | 8 | 1,024 | 1.044 | 416 | 2.885 | 320 |
| Divide | 128 | 32 | 1.604 | 3,808 | 10.346 | 3,696 |
| Divide | 2,048 | 1 | 12.191 | 41,248 | 79.451 | 41,104 |
| Rational add | 8 | 1,024 | 2.177 | 416 | 5.680 | 320 |
| Rational add | 128 | 32 | 2.143 | 3,872 | 19.030 | 3,728 |
| Rational add | 4,096 | 1 | 64.643 | 114,944 | 568.546 | 114,816 |

Compile the benchmark with `-O3` and `-Fusrc`. Run
`ExactArithmeticEvidence multiply 2048 1`,
`ExactArithmeticEvidence divide 2048 1`, or
`ExactArithmeticEvidence rational 4096 1` in separate processes to
reproduce the largest rows. The divide workload divides a prepared wide
product. The rational workload adds `(M−1)/M + 1/M` and reduces the sum to
`1/1`, where `M` is an all-ones magnitude. These are workload measurements.
