# Independent check of the weighted Burt measures of nwburt (kernel 40) against R.
#   Rscript tools/verify_burt.R <outdir> [nnets]
# (non-integer weights are multiples of 1/64: exact in the single precision in which nwset stores ties)
# Writes <outdir>/cells.csv (net,i,j,w: the matrix cells of 60 random valued networks, Stata side input),
# <outdir>/nets.csv (net,n,directed) and <outdir>/expected.csv (net,node,es,eff,con,hier,igraph,ens_infl,con_infl).
# The reference formulas are written out densely here (not the algorithm of the C kernel):
#   a = z + t(z) (self-loops dropped), p_ij = a_ij / sum_k a_ik, m_jq = a_jq / max_k a_jk,
#   ES_i = sum_{j in N(i)} (1 - sum_{q in N(i), q != j} p_iq m_jq)
#   C_i  = sum_{j in N(i)} (p_ij + sum_{q in N(i), q != j} p_iq p_qj)^2
#   eff_i = ES_i / |N(i)|, H_i = sum_j (c_j/(C/N)) ln(c_j/(C/N)) / (N ln N)  (1 for N = 1, NA for N = 0)
# and compared with igraph::constraint(weights=). influenceR::ens()/constraint() take no weights: they are compared on the
# dichotomized undirected networks (binary reference columns bes, beff, bcon, bhier).
args <- commandArgs(TRUE); out <- args[1]; nnets <- if (length(args) > 1) as.integer(args[2]) else 60
suppressMessages(library(igraph))
have_infl <- requireNamespace("influenceR", quietly = TRUE)
burt_ref <- function(z) {
  n <- nrow(z); diag(z) <- 0
  a <- z + t(z); s <- rowSums(a); mx <- apply(a, 1, max)
  es <- eff <- con <- hier <- rep(NA_real_, n)
  for (i in 1:n) {
    nb <- which(a[i, ] > 0)
    if (length(nb) == 0) { es[i] <- 0; eff[i] <- 0; con[i] <- 0; hier[i] <- NA; next }
    p <- a[i, ] / s[i]
    cj <- numeric(length(nb)); rj <- numeric(length(nb))
    for (k in seq_along(nb)) {
      j <- nb[k]; qs <- setdiff(nb, j)
      rj[k] <- sum(p[qs] * a[j, qs] / mx[j])
      cj[k] <- (p[j] + sum(p[qs] * a[qs, j] / s[qs]))^2
    }
    N <- length(nb); es[i] <- sum(1 - rj); eff[i] <- es[i] / N; con[i] <- sum(cj)
    if (N == 1) hier[i] <- 1 else { q <- cj / (con[i] / N); hier[i] <- sum(q * log(q)) / (N * log(N)) }
  }
  list(es = es, eff = eff, con = con, hier = hier)
}
set.seed(20261025)
cells <- list(); nets <- list(); exp <- list(); maxdiff <- c(igraph = 0, igraph_bin = 0, infl_con = 0, infl_ens = 0)
for (b in 1:nnets) {
  n <- sample(5:16, 1); directed <- b %% 2 == 0; integer <- (b %/% 2) %% 2 == 0
  m <- sample(n:(3 * n), 1)
  ei <- sample(1:n, m, TRUE); ej <- sample(1:n, m, TRUE)       # includes self-loops and repeated pairs
  w <- if (integer) sample(1:5, m, TRUE) else sample(3:384, m, TRUE) / 64
  if (b %% 5 == 0) { iso <- n; keep <- ei != iso & ej != iso; ei <- ei[keep]; ej <- ej[keep]; w <- w[keep] }  # isolate
  g <- graph_from_edgelist(cbind(ei, ej), directed = directed)
  if (vcount(g) < n) g <- add_vertices(g, n - vcount(g))
  E(g)$weight <- w
  z <- matrix(0, n, n)                                           # repeated ties add up (igraph does the same)
  for (k in seq_along(ei)) { z[ei[k], ej[k]] <- z[ei[k], ej[k]] + w[k]; if (!directed && ei[k] != ej[k]) z[ej[k], ei[k]] <- z[ej[k], ei[k]] + w[k] }
  r <- burt_ref(z)
  ig <- as.numeric(constraint(g, weights = E(g)$weight))
  ok <- !is.nan(ig)
  maxdiff["igraph"] <- max(maxdiff["igraph"], max(abs(ig[ok] - r$con[ok])))
  # binary (ties present/absent) on undirected networks: our reference, igraph (unweighted), influenceR
  bes <- beff <- bcon <- bhier <- icon <- iens <- rep(NA_real_, n)
  if (!directed) {
    zb <- (z > 0) * 1; diag(zb) <- 0
    rb <- burt_ref(zb); bes <- rb$es; beff <- rb$eff; bcon <- rb$con; bhier <- rb$hier
    gb <- graph_from_adjacency_matrix(zb, mode = "undirected")
    igb <- as.numeric(constraint(gb)); okb <- !is.nan(igb)
    maxdiff["igraph_bin"] <- max(maxdiff["igraph_bin"], max(abs(igb[okb] - bcon[okb])))
    if (have_infl) {
      icon <- as.numeric(influenceR::constraint(gb)); iens <- as.numeric(influenceR::ens(gb))
      okc <- degree(gb) > 0
      maxdiff["infl_con"] <- max(maxdiff["infl_con"], max(abs(icon[okc] - bcon[okc])))
      maxdiff["infl_ens"] <- max(maxdiff["infl_ens"], max(abs(iens[okc] - bes[okc])))
    }
  }
  idx <- which(z != 0, arr.ind = TRUE)
  cells[[b]] <- data.frame(net = b, i = idx[, 1], j = idx[, 2], w = z[idx])
  nets[[b]] <- data.frame(net = b, n = n, directed = as.integer(directed))
  exp[[b]] <- data.frame(net = b, node = 1:n, es = r$es, eff = r$eff, con = r$con, hier = r$hier, igraph = ig, bes = bes, beff = beff, bcon = bcon, bhier = bhier, infl_ens = iens, infl_con = icon)
}
write.csv(do.call(rbind, cells), file.path(out, "cells.csv"), row.names = FALSE)
write.csv(do.call(rbind, nets), file.path(out, "nets.csv"), row.names = FALSE)
write.csv(do.call(rbind, exp), file.path(out, "expected.csv"), row.names = FALSE, na = "")
cat("R reference vs igraph::constraint max abs diff:", format(maxdiff["igraph"]), "\n")
cat("binary, undirected: R reference vs igraph::constraint:", format(maxdiff["igraph_bin"]), "\n")
if (have_infl) cat("binary, undirected: R reference vs influenceR::constraint:", format(maxdiff["infl_con"]), " vs influenceR::ens:", format(maxdiff["infl_ens"]), "\n")
