## Update from 0.3.0 to 0.4.0

This release corrects minibatch weighting in sequential Riesz regression and
centering of influence scores for clustered inference. Both corrections can
affect previously reported results. NEWS documents the argument renames
(`outcome` to `out` and `mediators` to `med`), the new weighted Super Learner
ensemble, the handling of constant outcomes, and the revised fold and training
defaults.

The LightGBM and MARS wrappers are provided by the suggested package
`mlr3extralearners` from the mlr-org R-universe listed in Additional_repositories.
The README gives installation instructions for the default ensemble. The
documented GLM example runs with the strong dependencies alone.

Ang Yu remains the maintainer and is listed as the author of ria.test.
DESCRIPTION credits Nicholas Williams, Richard Liu, and Iván Díaz for crumble
and identifies the copyright holders of the derived code.

## Check results

R 4.6.2 on macOS 27.2.1 (arm64):
`R CMD check --as-cran --run-donttest ria.test_0.4.0.tar.gz`
with `_R_CHECK_CRAN_INCOMING_REMOTE_=false`.

0 errors | 0 warnings | 1 note

The note was “Unable to verify current time.” Remote CRAN incoming checks
could not run because this environment could not resolve the repository hosts.

All 281 test expectations passed, with no skips. Examples (including
`\donttest`) and the PDF and HTML manuals passed. Separate end-to-end fits
exercised the default four-learner ensemble and a GLM in an R library without
`mlr3extralearners`.
