# v2.7.0 performance provenance

The [manifest](performance-evidence.json) retains the benchmark contracts
from 2.6.0. New GLM fitting makes no speed claim. It uses the shared pivoted
QR implementation, which temporarily materializes an observations-by-
observations Q matrix. For n observations and p coefficients, working storage
is O(n^2 + n*p + p^2), and IRLS work includes O(iterations*n^2*p).
Use this baseline for moderate dense problems; bounded iteration does not
remove the dense memory cost. Existing benchmark correctness, allocation and
storage checks remain release gates, with timing comparisons reported
according to their retained pass/review policy.
