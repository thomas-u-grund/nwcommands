suppressMessages({library(ergm); library(network)})
set.seed(99)
for (nm in c("und_a","dir_a")) {
  isd <- nm=="dir_a"
  A <- as.matrix(read.csv(paste0(nm,"_adj.csv"), header=FALSE)); n <- nrow(A)
  X <- matrix(rbinom(n*n,1,.85),n,n); X <- X*t(X); diag(X) <- 0   # symmetric 0/1
  write.table(X, paste0(nm,"_x.csv"), sep=",", row.names=FALSE, col.names=FALSE)
  net <- network(A, directed=isd); x <- X
  s <- summary(net ~ localtriangle(x)); cat(nm, names(s), s, "\n")
}
