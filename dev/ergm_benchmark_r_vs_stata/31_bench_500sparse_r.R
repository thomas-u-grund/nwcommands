# Canonical benchmark 4: 500-node sparse undirected, edges + nodematch +
# gwesp(0.5, fixed), fit via Statnet's ergm() on the SAME exported
# network/attribute 30_bench_500sparse.do generated.

suppressMessages(library(ergm))

d <- "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/dev/ergm_benchmark_r_vs_stata"
mat <- as.matrix(read.csv(file.path(d, "net500.csv"), header = FALSE))
grp <- read.csv(file.path(d, "attr500.csv"), header = FALSE)[[1]]
stopifnot(dim(mat) == c(500, 500), length(grp) == 500)

net <- network(mat, directed = FALSE, matrix.type = "adjacency")
net %v% "grp" <- grp

set.seed(999)
t0 <- Sys.time()
fit <- ergm(net ~ edges + nodematch("grp") + gwesp(0.5, fixed = TRUE))
t1 <- Sys.time()
elapsed <- as.numeric(difftime(t1, t0, units = "secs"))

cat("\n======================================\n")
cat("R ergm: 500-node sparse undirected, edges + nodematch + gwesp\n")
cat("======================================\n")
cat(sprintf("Wall time: %.3f seconds\n", elapsed))
print(coef(fit))
print(summary(fit))
