# Benchmark 7 (harmonisation unit 92, native wave 2): 2000-node sparse
# directed, edges + mutual + nodematch + odegree(2) + idegree(2) +
# gwodegree + gwidegree, fit via Statnet's ergm() on the SAME exported
# network/attributes 83_bench_degreefam_stata.do generated.

suppressMessages(library(ergm))

d <- "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/dev/ergm_benchmark_r_vs_stata"
mat <- as.matrix(read.csv(file.path(d, "net_degfam.csv"), header = FALSE))
grp <- read.csv(file.path(d, "attr_degfam.csv"), header = FALSE)[[1]]
stopifnot(dim(mat) == c(2000, 2000), length(grp) == 2000)

net <- network(mat, directed = TRUE, matrix.type = "adjacency")
net %v% "grp" <- grp

set.seed(999)
t0 <- Sys.time()
fit <- ergm(net ~ edges + mutual + nodematch("grp") + odegree(2) + idegree(2) +
              gwodegree(0.5, fixed = TRUE) + gwidegree(0.5, fixed = TRUE))
t1 <- Sys.time()
elapsed <- as.numeric(difftime(t1, t0, units = "secs"))

cat("\n======================================\n")
cat("R ergm: 2000-node directed, edges+mutual+nodematch+odegree(2)+idegree(2)+gwodegree+gwidegree\n")
cat("======================================\n")
cat(sprintf("Wall time: %.3f seconds\n", elapsed))
print(coef(fit))
print(summary(fit))
