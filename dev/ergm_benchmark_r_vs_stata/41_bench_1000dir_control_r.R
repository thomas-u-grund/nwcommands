# Canonical benchmark 5 (control): 1000-node directed sparse, edges +
# mutual + nodematch - NO gwesp - fit via Statnet's ergm() on the SAME
# exported network/attribute 40_bench_1000dir_control.do generated.

suppressMessages(library(ergm))

d <- "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/dev/ergm_benchmark_r_vs_stata"
mat <- as.matrix(read.csv(file.path(d, "net1000.csv"), header = FALSE))
grp <- read.csv(file.path(d, "attr1000.csv"), header = FALSE)[[1]]
stopifnot(dim(mat) == c(1000, 1000), length(grp) == 1000)

net <- network(mat, directed = TRUE, matrix.type = "adjacency")
net %v% "grp" <- grp

set.seed(999)
t0 <- Sys.time()
fit <- ergm(net ~ edges + mutual + nodematch("grp"))
t1 <- Sys.time()
elapsed <- as.numeric(difftime(t1, t0, units = "secs"))

cat("\n======================================\n")
cat("R ergm: 1000-node directed CONTROL (no gwesp), edges + mutual + nodematch\n")
cat("======================================\n")
cat(sprintf("Wall time: %.3f seconds\n", elapsed))
print(coef(fit))
print(summary(fit))
