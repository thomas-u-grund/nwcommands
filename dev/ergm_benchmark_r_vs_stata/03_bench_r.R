# Fits edges + mutual on the SAME shared benchmark network via Statnet's
# ergm(), using ergm's own DEFAULT control settings (control.ergm()'s own
# defaults - MCMLE.maxit=60, MCMC.burnin/interval/samplesize at their own
# defaults, MCMLE.termination="confidence") - i.e. exactly how a typical
# user would invoke it, with no special tuning for this benchmark. Times
# the whole ergm() call (MPLE starting value + full MCMLE outer loop).

suppressMessages(library(ergm))

mat <- as.matrix(read.csv(
  "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/dev/ergm_benchmark_r_vs_stata/bench_net.csv",
  header = FALSE
))
stopifnot(dim(mat) == c(30, 30))

net <- network(mat, directed = TRUE, matrix.type = "adjacency")

set.seed(999)
t0 <- Sys.time()
fit <- ergm(net ~ edges + mutual)
t1 <- Sys.time()
elapsed <- as.numeric(difftime(t1, t0, units = "secs"))

cat("\n======================================\n")
cat("R ergm: edges + mutual\n")
cat("======================================\n")
cat(sprintf("Wall time: %.3f seconds\n", elapsed))
cat("Coefficients:\n")
print(coef(fit))
cat("Converged: ", !is.null(fit$mle.lik), "\n")
print(summary(fit))
