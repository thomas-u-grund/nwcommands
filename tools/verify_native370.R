# Reference values for cscripts/test_native370.do (native kernels 43..46 of the nwgraph plugin, generation 10).
#   Rscript tools/verify_native370.R <outdir>
# Writes into <outdir>:
#   pr_cells.csv  (net,i,j,w)       30 random weighted networks (directed and undirected, dangling nodes, isolates)
#   pr_nets.csv   (net,n,directed)
#   pr_expected.csv (net,node,pr)   the exact solution of the PageRank system (igraph::page_rank(weights = w, damping = 0.85) agrees to 1e-7)
#   mt_cells.csv  (net,i,j,w)       30 random weighted bipartite networks (n1 nodes of mode 1 first, then n2 of mode 2)
#   mt_nets.csv   (net,n1,n2)
#   bt_cells.csv, bt_nets.csv, bt_expected.csv: 24 random valued networks (integer weights 1..4) and igraph::betweenness(weights = 1/w)
#   mt_expected.csv (net,weight,size) total weight and size of igraph::max_bipartite_match(weights = w); the weight is
#                   also the maximum over all matchings (checked by brute force when the network is small)
args <- commandArgs(TRUE); out <- args[1]
# non-integer weights are multiples of 1/64: exact in the single precision in which nwset stores ties
suppressMessages(library(igraph))
set.seed(370)
wr <- function(d, f) { d[] <- lapply(d, function(c) if (is.numeric(c) && !is.integer(c)) ifelse(is.finite(c), sprintf("%.17g", c), "") else c); write.csv(d, f, row.names = FALSE, quote = FALSE) }
dir.create(out, showWarnings = FALSE, recursive = TRUE)
cells <- NULL; nets <- NULL; ex <- NULL
for (b in 1:30) {
  n <- sample(6:45, 1); dirc <- b %% 2 == 1
  A <- matrix(0, n, n)
  p <- runif(1, 0.05, 0.25)
  for (i in 1:n) for (j in 1:n) if (i != j && runif(1) < p) A[i, j] <- if (b %% 3 == 0) sample(1:9, 1) else pmax(1, round(runif(1, 0.1, 5) * 64)) / 64
  if (!dirc) { A[lower.tri(A)] <- t(A)[lower.tri(A)] }
  if (b %% 5 == 0) A[n, ] <- 0                      # a dangling node (and with no ties at all if undirected: isolate)
  if (b %% 5 == 0 && !dirc) A[, n] <- 0
  g <- graph_from_adjacency_matrix(A, mode = if (dirc) "directed" else "undirected", weighted = TRUE)
  pri <- page_rank(g, directed = dirc, damping = 0.85, weights = E(g)$weight)$vector
  # the exact stationary vector from the linear system r = d (P' r + dangling/n) + (1-d)/n  (igraph's PRPACK stops at about 1e-9)
  st <- rowSums(A); P <- A / ifelse(st > 0, st, 1); dang <- as.numeric(st == 0)
  Mx <- 0.85 * (t(P) + matrix(1 / n, n, 1) %*% matrix(dang, 1, n))
  pr <- as.numeric(solve(diag(n) - Mx, rep(0.15 / n, n)))
  if (max(abs(pr - pri)) > 1e-7) stop("igraph and the linear system differ in net ", b)
  w <- which(A != 0, arr.ind = TRUE)
  cells <- rbind(cells, data.frame(net = b, i = w[, 1], j = w[, 2], w = A[w]))
  nets <- rbind(nets, data.frame(net = b, n = n, directed = as.integer(dirc)))
  ex <- rbind(ex, data.frame(net = b, node = 1:n, pr = pr))
}
wr(cells, file.path(out, "pr_cells.csv"))
wr(nets, file.path(out, "pr_nets.csv"))
wr(ex, file.path(out, "pr_expected.csv"))

mc <- NULL; mn <- NULL; me <- NULL
for (b in 1:30) {
  n1 <- sample(3:14, 1); n2 <- sample(3:14, 1)
  intw <- b %% 2 == 0
  B <- matrix(0, n1, n2)
  p <- runif(1, 0.15, 0.5)
  for (i in 1:n1) for (j in 1:n2) if (runif(1) < p) B[i, j] <- if (intw) sample(1:6, 1) else pmax(1, round(runif(1, 0.1, 9) * 64)) / 64
  if (sum(B > 0) == 0) B[1, 1] <- 2
  g <- graph_from_biadjacency_matrix(B, weighted = TRUE)
  m <- max_bipartite_match(g, weights = E(g)$weight)
  # brute force over all matchings by recursion on the rows (exponential, n1 <= 14, n2 <= 14 only for sparse nets)
  best <- function(i, used) {
    if (i > n1) return(0)
    v <- best(i + 1, used)
    for (j in which(B[i, ] > 0)) if (!(j %in% used)) v <- max(v, B[i, j] + best(i + 1, c(used, j)))
    v
  }
  bf <- if (sum(B > 0) <= 40) best(1, integer(0)) else NA
  if (!is.na(bf) && abs(bf - m$matching_weight) > 1e-9) stop("igraph and brute force differ in net ", b)
  w <- which(B > 0, arr.ind = TRUE)
  mc <- rbind(mc, data.frame(net = b, i = w[, 1], j = n1 + w[, 2], w = B[w]))
  mn <- rbind(mn, data.frame(net = b, n1 = n1, n2 = n2))
  me <- rbind(me, data.frame(net = b, weight = m$matching_weight, size = m$matching_size, brute = bf))
}
wr(mc, file.path(out, "mt_cells.csv"))
wr(mn, file.path(out, "mt_nets.csv"))
wr(me, file.path(out, "mt_expected.csv"))

# weighted betweenness (kernel 47): igraph::betweenness with lengths 1/w (alpha = 1), undirected networks with integer
# weights 1..4 (many tied shortest paths) and directed ones
bc <- NULL; bn <- NULL; be <- NULL
for (b in 1:24) {
  n <- sample(8:40, 1); dirc <- b %% 3 == 0
  A <- matrix(0, n, n)
  p <- runif(1, 0.08, 0.3)
  for (i in 1:n) for (j in 1:n) if (i != j && runif(1) < p) A[i, j] <- sample(1:4, 1)
  if (!dirc) { A[lower.tri(A)] <- t(A)[lower.tri(A)] }
  g <- graph_from_adjacency_matrix(A, mode = if (dirc) "directed" else "undirected", weighted = TRUE)
  bt <- if (ecount(g) > 0) betweenness(g, directed = dirc, weights = 1 / E(g)$weight) else rep(0, n)
  w <- which(A != 0, arr.ind = TRUE)
  bc <- rbind(bc, data.frame(net = b, i = w[, 1], j = w[, 2], w = A[w]))
  bn <- rbind(bn, data.frame(net = b, n = n, directed = as.integer(dirc)))
  be <- rbind(be, data.frame(net = b, node = 1:n, bt = bt))
}
wr(bc, file.path(out, "bt_cells.csv")); wr(bn, file.path(out, "bt_nets.csv")); wr(be, file.path(out, "bt_expected.csv"))

# weighted closeness (kernels 48, 49): igraph::closeness(mode = "out", normalized = TRUE) = reachable nodes / farness, lengths
# 1/w (alpha = 1, column c1) and w (alpha = -1, igraph's convention, column cm); disconnected networks, isolates, directed ones
cc <- NULL; cn <- NULL; ce <- NULL
for (b in 1:24) {
  n <- sample(8:45, 1); dirc <- b %% 3 == 0
  A <- matrix(0, n, n)
  p <- runif(1, 0.03, 0.15)
  for (i in 1:n) for (j in 1:n) if (i != j && runif(1) < p) A[i, j] <- sample(1:5, 1)
  if (!dirc) { A[lower.tri(A)] <- t(A)[lower.tri(A)] }
  if (sum(A) == 0) { A[1, 2] <- 1; if (!dirc) A[2, 1] <- 1 }
  g <- graph_from_adjacency_matrix(A, mode = if (dirc) "directed" else "undirected", weighted = TRUE)
  cl <- function(wt) { if (ecount(g) == 0) return(rep(NaN, n)); suppressWarnings(closeness(g, mode = "out", weights = wt, normalized = TRUE)) }
  c1 <- cl(1 / E(g)$weight); cm <- cl(E(g)$weight)
  w <- which(A != 0, arr.ind = TRUE)
  cc <- rbind(cc, data.frame(net = b, i = w[, 1], j = w[, 2], w = A[w]))
  cn <- rbind(cn, data.frame(net = b, n = n, directed = as.integer(dirc)))
  ce <- rbind(ce, data.frame(net = b, node = 1:n, c1 = c1, cm = cm))
}
wr(cc, file.path(out, "cl_cells.csv")); wr(cn, file.path(out, "cl_nets.csv")); wr(ce, file.path(out, "cl_expected.csv"))
