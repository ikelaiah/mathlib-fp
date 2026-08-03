# mathlib-fp v1.9.3

Version 1.9.3 completes the proposed 2.0 API decision without changing the
frozen 1.9 public surface or numerical behavior.

## What changed

- Every exact public declaration is classified as a recommended common path,
  advanced stable path, compatibility surface, experimental surface, or
  generic implementation support.
- A concise [all-domain common-path map](API_COMMON_PATHS_2.0.md) points to 13
  complete output-checked programs while the generated declaration reference
  remains exhaustive.
- [Complete conventions](API_CONVENTIONS_2.0.md) resolve naming, indexing,
  shape, units, ownership, mutation, aliasing, exceptions, defaults,
  tolerances, outcomes, RNG state, cancellation, progress, and thread safety
  across every domain.
- Every compatibility declaration has a typed replacement and semantic note or
  an explicit retain decision. No compatibility entry is deprecated merely
  because 2.0 is planned.
- All 21 plain compiler aliases have an exact review covering behavior,
  defaults, ownership, exception identity, and numerical results. Pressure and
  velocity facade/error aliases receive prospective canonical paths for 1.9.7
  migration and package-boundary testing; 1.9.3 does not deprecate them.
- The [exact proposed diff](API_DIFF_1.9_TO_2.0.md) records no source,
  behavior, warning, or packaging change. Documentary priorities are listed
  separately.

## Common and advanced paths

The recommended route remains double-real and allocating. Named scalar
variants, advanced containers, diagnostics, factors, destinations, views,
callbacks, and reusable workspaces remain stable and fully documented one step
deeper. Generic base declarations exposed for Free Pascal specialization are
still in the exact reference but are not recommended application API.

## Compatibility

`IMatrix`, `TMatrixKit`, and `TMatrixKitSparse` remain source-compatible;
typed replacements require explicit copying conversions. `FinanceLib.Bonds`
and `FinanceLib.NPV` are explicitly retained because they provide exact focused
aliases without different numerical semantics.

For new pressure and velocity code, the documented common path is
`TFluidDynamicsKit` with `EFluidDynamicsError`. `TPressureKit`,
`EPressureError`, `TVelocityKit`, and `EVelocityError` remain exact supported
aliases. Their possible deprecation is a 1.9.7 decision after tested migration
and packaging evidence, not a 1.9.3 change.

There are no declaration removals, new defaults, storage changes, warnings, or
package changes in 1.9.3.

## Install

Download the tagged source as
[`tar.gz`](https://github.com/ikelaiah/mathlib-fp/archive/refs/tags/v1.9.3.tar.gz)
or [`zip`](https://github.com/ikelaiah/mathlib-fp/archive/refs/tags/v1.9.3.zip),
extract it, and compile the README program with `src/` on the unit search path.
No configure step or generated source is required.

## Separately planned capability

Ergonomic 2-D and 3-D vector rotation is useful but belongs to a focused
1.10.0 design. That review must settle 3-D representation, orientation, angular
units, normalization, non-finite behavior, and names before implementation.
Version 1.9.3 adds no rotation declaration.

## Validation

The release gate reconstructs all declaration classifications from the
reviewed manifest, verifies all domain/unit and convention decisions, proves
one review for every exact compiler alias, checks all compatibility mappings
and exact diff categories, compiles/runs the 13 common programs, and rejects
generic implementation declarations in common examples. See the
[qualification report](QUALIFICATION_1.9.3.md).

The library remains native Free Pascal source with standard RTL/FCL units only.
No DLL, package download, service, account, licence key, or network connection
is required to build or run the stable library.

Capability maturity and known numerical limitations are unchanged; see the
[capability inventory](CAPABILITIES.md). The zero experimental declaration
count is an API classification result, not a claim that every long-term
capability is already implemented.
