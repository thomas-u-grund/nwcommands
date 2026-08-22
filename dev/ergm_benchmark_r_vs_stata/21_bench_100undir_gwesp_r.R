# Canonical benchmark 3: 100-node undirected, edges + gwesp(0.5, fixed),
# fit via Statnet's ergm() on the SAME exported network
# 20_bench_100undir_gwesp.do generated, using ergm()'s own default settings.

suppressMessages(library(ergm))

d <- "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/dev/ergm_benchmark_r_vs_stata"
mat <- as.matrix(read.csv(file.path(d, "net100undir.csv"), header = FALSE))
stopifnot(dim(mat) == c(100, 100))

net <- network(mat, directed = FALSE, matrix.type = "adjacency")

set.seed(999)
t0 <- Sys.time()
fit <- ergm(net ~ edges + gwesp(0.5, fixed = TRUE))
t1 <- Sys.time()
elapsed <- as.numeric(difftime(t1, t0, units = "secs"))

cat("\n======================================\n")
cat("R ergm: 100-node undirected, edges + gwesp(0.5, fixed)\n")
cat("======================================\n")
cat(sprintf("Wall time: %.3f seconds\n", elapsed))
print(coef(fit))
print(summary(fit))
