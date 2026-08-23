# Benchmark 8 (harmonisation unit 92, native wave 3): 1000-node sparse
# undirected, edges + gwesp + gwnsp, fit via Statnet's ergm() on the
# SAME exported network 85_bench_sharedpartner_stata.do generated. See
# that script's own header comment for why gwnsp (not gwdsp/triangle)
# was chosen as gwesp's companion term.

suppressMessages(library(ergm))

d <- "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/dev/ergm_benchmark_r_vs_stata"
mat <- as.matrix(read.csv(file.path(d, "net_sp.csv"), header = FALSE))
stopifnot(dim(mat) == c(1000, 1000))

net <- network(mat, directed = FALSE, matrix.type = "adjacency")

set.seed(999)
t0 <- Sys.time()
fit <- ergm(net ~ edges + gwesp(0.5, fixed = TRUE) + gwnsp(0.5, fixed = TRUE))
t1 <- Sys.time()
elapsed <- as.numeric(difftime(t1, t0, units = "secs"))

cat("\n======================================\n")
cat("R ergm: 1000-node undirected, edges + gwesp + gwnsp\n")
cat("======================================\n")
cat(sprintf("Wall time: %.3f seconds\n", elapsed))
print(coef(fit))
print(summary(fit))
