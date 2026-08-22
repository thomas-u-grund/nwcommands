# Canonical benchmark 2: 100-node directed, edges + mutual + nodematch,
# fit via Statnet's ergm() on the SAME exported network/attribute
# 10_bench_100dir.do generated, using ergm()'s own default settings.

suppressMessages(library(ergm))

d <- "/Users/tgrund/FILES_NEW/RESEARCH/nwcommands_2016/dev/ergm_benchmark_r_vs_stata"
mat <- as.matrix(read.csv(file.path(d, "net100dir.csv"), header = FALSE))
grp <- read.csv(file.path(d, "attr100dir.csv"), header = FALSE)[[1]]
stopifnot(dim(mat) == c(100, 100), length(grp) == 100)

net <- network(mat, directed = TRUE, matrix.type = "adjacency")
net %v% "grp" <- grp

set.seed(999)
t0 <- Sys.time()
fit <- ergm(net ~ edges + mutual + nodematch("grp"))
t1 <- Sys.time()
elapsed <- as.numeric(difftime(t1, t0, units = "secs"))

cat("\n======================================\n")
cat("R ergm: 100-node directed, edges + mutual + nodematch\n")
cat("======================================\n")
cat(sprintf("Wall time: %.3f seconds\n", elapsed))
print(coef(fit))
print(summary(fit))
