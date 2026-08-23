# Benchmark 6 (harmonisation unit 92): 1000-node sparse undirected,
# edges + gwesp + nodefactor + nodecov (MIXED - the case that used to
# force nwergm's own native backend to fall back to Mata), fit via
# Statnet's ergm() on the SAME exported network/attributes
# 80_bench_mixed_stata.do generated.

suppressMessages(library(ergm))

d <- "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/dev/ergm_benchmark_r_vs_stata"
mat <- as.matrix(read.csv(file.path(d, "net_mixed.csv"), header = FALSE))
attr <- read.csv(file.path(d, "attr_mixed.csv"), header = FALSE)
grp <- attr[[1]]
cov <- attr[[2]]
stopifnot(dim(mat) == c(1000, 1000), length(grp) == 1000, length(cov) == 1000)

net <- network(mat, directed = FALSE, matrix.type = "adjacency")
net %v% "grp" <- grp
net %v% "cov" <- cov

set.seed(999)
t0 <- Sys.time()
fit <- ergm(net ~ edges + gwesp(0.5, fixed = TRUE) + nodefactor("grp") + nodecov("cov"))
t1 <- Sys.time()
elapsed <- as.numeric(difftime(t1, t0, units = "secs"))

cat("\n======================================\n")
cat("R ergm: 1000-node sparse undirected, edges + gwesp + nodefactor + nodecov (MIXED)\n")
cat("======================================\n")
cat(sprintf("Wall time: %.3f seconds\n", elapsed))
print(coef(fit))
print(summary(fit))
