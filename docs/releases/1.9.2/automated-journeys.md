# 1.9.2 automated beginner journeys

The 1.9.2 first-use gate is deterministic and self-contained. It requires no
external participants, accounts, reports, services, network access, or manual
evidence collection.

## Checked journey

Release qualification performs the following journey from a checksummed clean
source archive:

1. Compare documented public names and exact owner/signature-aware declarations
   with every source `interface` section and the frozen 1.9 API snapshot.
2. Verify that all 13 stable-domain landing pages present the beginner route,
   common-task selection guidance, and advanced route in that order.
3. Confirm that every beginner route links an output-checked runnable program
   and every advanced route links a complete example.
4. Compile and execute every self-contained Pascal documentation program, then
   compare its observed output with the exact or ordered published contract.
5. Build the versioned static site and require problem-oriented search results
   for “least squares”, “normal probability”, and “FFT convolution”.
6. Check every generated local link and anchor, release identity, and offline
   ZIP contents, then emit the deterministic artifact and its SHA-256.

## Commands

The focused checks are:

```text
python tools/check_docs.py
python tools/check_doc_examples.py --compiler fpc
python tools/build_docs.py --release 1.9.2 --output build-temp/docs-site/1.9.2 \
  --offline-archive build-temp/mathlib-fp-docs-1.9.2.zip
python tools/check_built_docs.py --site build-temp/docs-site/1.9.2 --release 1.9.2
```

`tools/qualify_release.py` runs these checks with the library tests, examples,
package build, offline archive, and representative benchmark. CI repeats the
documentation journey from an extracted checksummed source archive on Linux
and Windows.
