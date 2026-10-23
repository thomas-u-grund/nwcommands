# Generates three bipartite test networks for the nwergm bipartite terms (tag bip):
#  A 12 x 10 (random, attribute-driven), B 8 x 15 (random, sparse), C 20 x 6 (hubs + isolates)
# usage: Rscript bip_gen.R <outdir>
suppressMessages({library(ergm); library(network)})
out <- commandArgs(TRUE)[1]
set.seed(20261024)
mk <- function(n1, n2, pbase, hub = FALSE, iso = 0) {
  n <- n1 + n2
  g <- sample(1:3, n, TRUE); x <- round(rnorm(n, 50, 10), 2); h <- sample(0:1, n, TRUE)
  P <- outer(1:n1, 1:n2, function(i, j) plogis(pbase + 0.8*(g[i]==g[n1+j]) + 0.03*(x[i]-50)))
  if (hub) P[1:2, ] <- 0.8
  B <- matrix(rbinom(n1*n2, 1, P), n1, n2)
  if (iso > 0) { B[(n1-iso+1):n1, ] <- 0 }
  list(B=B, n1=n1, n2=n2, g=g, x=x, h=h)
}
nets <- list(A = mk(12, 10, -1.3), B = mk(8, 15, -1.9), C = mk(20, 6, -1.6, hub = TRUE, iso = 2))
for (nm in names(nets)) {
  z <- nets[[nm]]
  e <- which(z$B == 1, arr.ind = TRUE)
  write.csv(data.frame(person = e[,1], event = e[,2]), file.path(out, paste0("bip", nm, "_edges.csv")), row.names = FALSE)
  write.csv(data.frame(g = z$g, x = z$x, h = z$h, n1 = z$n1), file.path(out, paste0("bip", nm, "_nodes.csv")), row.names = FALSE)
}
