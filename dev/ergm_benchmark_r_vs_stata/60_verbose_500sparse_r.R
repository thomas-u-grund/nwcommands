# Diagnostic script for harmonisation unit 84 (docs/CERTIFICATION.md):
# runs ergm() on the SAME benchmark-4 network (net500.csv/attr500.csv,
# 30_bench_500sparse.do's own output) with verbose=TRUE to capture
# Statnet's real, per-iteration MCMLE trace - used for a direct
# iteration-by-iteration comparison against nwergm's own `verbose` output
# on the identical network, to root-cause why nwergm's MCMLE kept hitting
# its iteration cap on this benchmark while Statnet converged quickly.
#
# The key finding (see docs/CERTIFICATION.md unit 84 for the full account):
# Statnet's own printed "Test statistic: T^2 = ..., with N free parameter(s)
# and D degrees of freedom" lines show D is non-integer and far below the
# raw recorded MCMC sample size, growing across iterations ("increasing
# sample size" is printed explicitly on a failed test) - i.e. Statnet's own
# convergence test already discounts for MCMC autocorrelation via an
# effective sample size, which nwergm's own equivalent test did not do
# before this unit's fix.

suppressMessages(library(ergm))
d <- "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/dev/ergm_benchmark_r_vs_stata"
mat <- as.matrix(read.csv(file.path(d, "net500.csv"), header = FALSE))
grp <- read.csv(file.path(d, "attr500.csv"), header = FALSE)[[1]]
net <- network(mat, directed = FALSE, matrix.type = "adjacency")
net %v% "grp" <- grp

set.seed(999)
fit <- ergm(net ~ edges + nodematch("grp") + gwesp(0.5, fixed = TRUE), verbose = TRUE)

cat("=== FINAL ===\n")
print(coef(fit))
print(summary(fit))
