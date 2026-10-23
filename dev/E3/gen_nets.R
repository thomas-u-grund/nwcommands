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
data(samplk); # denser, structured networks (so that MPLE comparisons are not separated)
cl <- function(U, rep) { n <- nrow(U); for (r in 1:rep) { cn <- U %*% U; add <- (cn > 0) & (U == 0) & (matrix(runif(n*n),n) < 0.25); add[lower.tri(add, TRUE)] <- FALSE; U <- U + add + t(add) }; diag(U) <- 0; U }
nets$und_c <- cl(mk_und(60, .05), 2)
D <- mk_dir(40, .06); for (r in 1:2) { D2 <- D %*% D; add <- (D2 > 0) & (D == 0) & (matrix(runif(1600),40) < .2); D <- D + add; rec <- t(D) * (D == 0) * (matrix(runif(1600),40) < .3); D <- D + rec }; D[D > 1] <- 1; diag(D) <- 0
nets$dir_c <- D
nets$dir_b <- as.matrix(network::as.sociomatrix(samplk1))
for (nm in names(nets)) {
  m <- nets[[nm]]; n <- nrow(m)
  wm(m, paste0(nm, "_adj.csv"))
  write.csv(data.frame(a=sample(1:3, n, TRUE), b=sample(0:1, n, TRUE), x=round(rnorm(n),3)), paste0(nm, "_nodes.csv"), row.names=FALSE)
}
