# Security Policy

## Supported Versions

| Version | Supported |
| ------- | --------- |
| 2.4.x | :white_check_mark: |
| 2.3.x | :white_check_mark: |
| 2.2.x | :white_check_mark: |
| 2.0.x | :white_check_mark: |
| 1.10.x | :x: |
| 1.9.x | :x: |
| 1.8.x | :x: |
| 1.7.x and older | :x: |

## Security Support Window

Each minor release line is supported for security fixes from its release date
until the earlier of one year or six months after the next minor release line
is published. The 2.0.x line is supported through the 2.2.0 publication plus
six months, and the 2.2.x line through the 2.3.0 publication plus six months.
The 2.3.x line is supported through 2027-04-08, six months after the 2.4.0
publication. The current 2.4.x line is supported for at least one year from
publication.
Security support for the 1.10.x and 1.9.x lines ended on
2026-03-21, six months after 2.0.0 was published. Security fixes are published
as patch releases for every supported affected line with
regression evidence, as defined in the
[governance policies](docs/GOVERNANCE.md#security-support-window).

## Reporting a Vulnerability

We take the security of mathlib-fp seriously. If you believe you have found
a security vulnerability, please report it to us as described below.

**Do not include vulnerability details in a public GitHub issue.**

Submit a [private vulnerability report](https://github.com/ikelaiah/mathlib-fp/security/advisories/new).
If that form is unavailable, open a minimal public issue asking for maintainer
contact without including vulnerability details.

You should receive a response within 48 hours. If for some reason you do not, please follow up to ensure we received your original message.

Please include the following information:

- Type of issue (for example, memory corruption or unsafe numerical behaviour)
- Full paths of source files related to the issue
- Affected tag, branch, commit, or direct source URL
- Any special configuration required to reproduce the issue
- Step-by-step reproduction instructions
- Proof-of-concept code, if available
- The impact and how the issue might be exploited

## Preferred Languages

We prefer all communications to be in English.
