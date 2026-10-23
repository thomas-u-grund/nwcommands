# Generates the test networks used by test_nwergm_structural.do (E3): adjacency + node attributes
suppressMessages({library(ergm); library(network)})
set.seed(20261101)
out <- "."
wm <- function(m, f) write.table(m, f, sep=",", row.names=FALSE, col.names=FALSE)
mk_und <- function(n, p) { U <- matrix(0,n,n); U[upper.tri(U)] <- rbinom(n*(n-1)/2,1,p); U+t(U) }
mk_dir <- function(n, p) { D <- matrix(rbinom(n*n,1,p),n,n); diag(D) <- 0; D }
nets <- list()
nets$und_a <- mk_und(30, .14)
data(florentine); nets$und_b <- as.matrix(network::as.sociomatrix(flomarriage))
nets$dir_a <- mk_dir(25, .10)
data(samplk); nets$dir_b <- as.matrix(network::as.sociomatrix(samplk1))
for (nm in names(nets)) {
  m <- nets[[nm]]; n <- nrow(m)
  wm(m, paste0(nm, "_adj.csv"))
  write.csv(data.frame(a=sample(1:3, n, TRUE), b=sample(0:1, n, TRUE), x=round(rnorm(n),3)), paste0(nm, "_nodes.csv"), row.names=FALSE)
}
