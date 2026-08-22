# Canonical small networks shared across the reference scripts in this
# directory - mirrored exactly (same edges, same attribute values) in the
# Stata cscripts/test_nwergm_*.do certification suite, so results here are
# directly comparable to nwergm's own output.

library(network)

# --- Undirected canonical network: 5 nodes, 5 edges. Triangle {1,2,3} plus
# a path 3-4-5, so nonzero GWESP/GWdegree structure exists without being
# trivial to hand-verify.
make_undirected <- function() {
  el <- matrix(c(1,2, 1,3, 2,3, 3,4, 4,5), ncol=2, byrow=TRUE)
  nw <- network.initialize(5, directed=FALSE)
  nw <- network.edgelist(el, nw)
  nw %v% "sex" <- c(1,1,2,2,1)
  nw %v% "age" <- c(20,25,30,22,28)
  nw
}

# --- Directed canonical network: 5 nodes, one mutual pair (1<->2) plus a
# directed chain 1->3->4->5->1, so both mutual and non-mutual structure
# exists.
make_directed <- function() {
  el <- matrix(c(1,2, 2,1, 1,3, 3,4, 4,5, 5,1), ncol=2, byrow=TRUE)
  nw <- network.initialize(5, directed=TRUE)
  nw <- network.edgelist(el, nw)
  nw %v% "sex" <- c(1,1,2,2,1)
  nw %v% "age" <- c(20,25,30,22,28)
  nw
}

# --- Dyadic covariate (edgecov) matrix for the undirected network - a
# plain 5x5 symmetric matrix of "distance"-like values, diagonal irrelevant.
make_edgecov_undirected <- function() {
  matrix(c(
    0, 3, 1, 4, 2,
    3, 0, 2, 1, 5,
    1, 2, 0, 3, 1,
    4, 1, 3, 0, 2,
    2, 5, 1, 2, 0
  ), nrow=5, byrow=TRUE)
}
