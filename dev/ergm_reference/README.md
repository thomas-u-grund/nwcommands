# ERGM reference-value generator (development-only, not part of the shipped package)

This directory holds R scripts that use Statnet `ergm`/`network` to generate
reference values for `nwergm`'s permanent Stata certification suite
(`cscripts/test_nwergm_*.do`). **Nothing here ships with `nwcommands`** —
`nwergm.ado` has no R dependency at runtime. These scripts exist purely so a
developer with R + `ergm` installed can regenerate/extend the reference
values that are hand-transcribed as literal expected numbers into the Stata
test files.

Workflow: define a small canonical network in R, compute the quantity of
interest (observed sufficient statistics, MPLE coefficients, MCMLE
coefficients/SEs), print it with full precision, then copy the printed value
into the corresponding `cscripts/test_nwergm_*.do` assertion as a literal
constant with a comment noting it came from here and the `ergm` version used.

Not excluded from git (worth keeping for future re-validation), but excluded
from every `_pkg_*.txt`/`.pkg` manifest — never packaged.

Requires: R with `ergm`, `network`, `statnet.common` installed. Run any
script with `Rscript dev/ergm_reference/<script>.R`.
