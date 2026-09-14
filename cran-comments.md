## R CMD check results

0 errors | 0 warnings | 0 notes

Checked with R 4.6.1 on macOS 26.6.2 (arm64) using
`R CMD check --as-cran ria.test_0.3.0.tar.gz`, including examples,
`--run-donttest` examples, tests, and PDF/HTML manuals.

## Changes in 0.3.0

* Add an exact zero-cost permutation fast path for repeated treatment/baseline
  profiles, avoiding the native LP solver for qualifying folds. The general
  LP fallback remains; this does not claim to repair the native solver crash.
* Use permutation indices and handle all-identical profiles without division
  by zero. Validate the general solver's status and permutation output.
* Standardize notation to D, C, and L. Rename `zprime_folds` to `lprime_folds`
  without a compatibility alias, as documented in NEWS.
