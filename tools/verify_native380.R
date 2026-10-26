# Reference values for cscripts/test_nw2motifs.do (kernel 50 of the nwgraph plugin, generation 11): bmotif 2.0.2 (Simmons et al. 2019).
#   Rscript tools/verify_native380.R <outdir> [bmotif library dir] [directory with davis_cells.csv and ftdirectors_se_cells.csv; default cscripts/native380_fixture]
# davis_cells.csv, ftdirectors_se_cells.csv (i,j = row and column of every tie) are the two data sets exported from Stata with
# tools/export_native380_nets.do (mode 1 = rows).  Writes into <outdir>:
#   nets.csv    (net,label,n1,n2,six)     the networks: 1 toy 6 x 4, 2 davis, 3 ftdirectors_se (five-node motifs only), 4 a subsample of the directors
#               (six-node motifs too), 5..34 random bipartite networks (various sizes and densities, isolates), 35..38 four larger ones
#   cells.csv   (net,i,j)                 ties (row i of mode 1, column j of mode 2); not repeated for the two data sets that Stata reads itself (nets 2 and 3)
#   freq.csv    (net,motif,nodes,frequency,normalise_sum,normalise_sizeclass,normalise_levelsize,normalise_nodesets)  bmotif::mcount(normalisation = TRUE)
#   pos.csv     (net,node,np1..np148)     bmotif::node_positions(level = "all"): node = 1..n1 rows, then n1+1..n1+n2 columns; np47.. empty without six
#   posnorm.csv (net,type,node,np1..np148) the twelve normalisations for the nets in `normnets'
args <- commandArgs(TRUE); out <- args[1]
lib <- if (length(args) >= 2 && nzchar(args[2])) args[2] else NULL
dat <- if (length(args) >= 3) args[3] else "cscripts/native380_fixture"
suppressMessages(library(bmotif, lib.loc = lib))
cat("bmotif", as.character(packageVersion("bmotif", lib.loc = lib)), "\n")
dir.create(out, showWarnings = FALSE, recursive = TRUE)
set.seed(380)
fmt <- function(d) { d[] <- lapply(d, function(c) if (is.numeric(c) && !is.integer(c)) ifelse(is.finite(c), sprintf("%.17g", c), "") else c); d }
nets <- list(); cells <- NULL
add <- function(label, B, six, store = TRUE) {
  id <- length(nets) + 1
  nets[[id]] <<- list(label = label, B = B, six = six)
  if (store && any(B > 0)) { w <- which(B > 0, arr.ind = TRUE); cells <<- rbind(cells, data.frame(net = id, i = w[, 1], j = w[, 2])) }
}
toy <- matrix(0, 6, 4); for (e in list(c(1,1),c(1,2),c(2,1),c(2,2),c(2,3),c(3,2),c(3,3),c(4,3),c(4,4),c(5,4),c(6,4),c(6,1))) toy[e[1], e[2]] <- 1
add("toy", toy, TRUE)
fromcells <- function(f) { d <- read.csv(f); B <- matrix(0, max(d$i), max(d$j)); B[cbind(d$i, d$j)] <- 1; B }
dav <- fromcells(file.path(dat, "davis_cells.csv")); add("davis", dav, TRUE, FALSE)
dir <- fromcells(file.path(dat, "ftdirectors_se_cells.csv")); add("ftdirectors_se", dir, FALSE, FALSE)
# subsample of the directors for the six-node motifs: the 10 firms with the most directors, and the directors who sit on at least one of them
keep <- order(colSums(dir), decreasing = TRUE)[1:10]
sub <- dir[rowSums(dir[, keep, drop = FALSE]) > 0, keep]
add("directors_sub", sub, TRUE)
for (b in 1:30) {
  n1 <- sample(3:22, 1); n2 <- sample(3:18, 1)
  if (b %% 6 == 1) { n1 <- sample(3:7, 1); n2 <- sample(12:20, 1) }   # fewer rows than columns
  if (b %% 6 == 2) { n1 <- sample(14:24, 1); n2 <- sample(3:7, 1) }   # fewer columns than rows
  p <- runif(1, 0.06, 0.7)
  B <- matrix(as.numeric(runif(n1 * n2) < p), n1, n2)
  if (b %% 4 == 0) { B[sample(n1, max(1, n1 %/% 5)), ] <- 0; B[, sample(n2, max(1, n2 %/% 5))] <- 0 }   # isolates
  if (b == 30) B[] <- 0                                                                                    # no ties at all
  if (b == 29) B[] <- 1                                                                                    # complete
  add(paste0("random", b), B, TRUE)
}
# four larger networks: moderate density, more rows than columns and the reverse
for (sz in list(c(35, 28, 0.3), c(60, 12, 0.45), c(12, 60, 0.2), c(45, 45, 0.1))) {
  B <- matrix(as.numeric(runif(sz[1] * sz[2]) < sz[3]), sz[1], sz[2]); add(sprintf("random%dx%d", sz[1], sz[2]), B, TRUE)
}
normnets <- c(1, 2, 5, 9, 12)
types <- c("none","sum","sizeclass","sizeclass_plus1","sizeclass_NAzero","position","levelsize","levelsize_plus1","levelsize_NAzero","motif","motif_plus1","motif_NAzero")
fr <- NULL; ps <- NULL; pn <- NULL; nn <- NULL
for (id in seq_along(nets)) {
  x <- nets[[id]]; B <- x$B
  cat(sprintf("%d %s %d x %d ties %d six %s ", id, x$label, nrow(B), ncol(B), sum(B > 0), x$six)); t0 <- proc.time()[3]
  mc <- mcount(B, six_node = x$six, normalisation = TRUE, mean_weight = FALSE, standard_dev = FALSE)
  np <- as.matrix(node_positions(B, six_node = x$six, level = "all", weights_method = "none", weights_combine = "none", normalisation = "none"))
  cat(sprintf("%.1fs\n", proc.time()[3] - t0))
  fr <- rbind(fr, data.frame(net = id, motif = mc$motif, nodes = mc$nodes, frequency = mc$frequency, normalise_sum = mc$normalise_sum,
    normalise_sizeclass = mc$normalise_sizeclass, normalise_levelsize = mc$normalise_levelsize, normalise_nodesets = mc$normalise_nodesets))
  full <- matrix(NA_real_, nrow(np), 148); full[, 1:ncol(np)] <- np
  if (nrow(np) != nrow(B) + ncol(B)) stop("rows of node_positions")
  ps <- rbind(ps, data.frame(net = id, node = 1:nrow(np), setNames(as.data.frame(full), paste0("np", 1:148))))
  if (id %in% normnets) for (ty in types) {
    nq <- as.matrix(node_positions(B, six_node = x$six, level = "all", weights_method = "none", weights_combine = "none", normalisation = ty))
    f2 <- matrix(NA_real_, nrow(nq), 148); f2[, 1:ncol(nq)] <- nq
    pn <- rbind(pn, data.frame(net = id, type = ty, node = 1:nrow(nq), setNames(as.data.frame(f2), paste0("np", 1:148))))
  }
  nn <- rbind(nn, data.frame(net = id, label = x$label, n1 = nrow(B), n2 = ncol(B), six = as.integer(x$six)))
}
write.csv(nn, file.path(out, "nets.csv"), row.names = FALSE, quote = FALSE)
write.csv(cells, file.path(out, "cells.csv"), row.names = FALSE, quote = FALSE)
write.csv(fmt(fr), file.path(out, "freq.csv"), row.names = FALSE, quote = FALSE, na = "")
write.csv(fmt(ps), file.path(out, "pos.csv"), row.names = FALSE, quote = FALSE, na = "")
write.csv(fmt(pn), file.path(out, "posnorm.csv"), row.names = FALSE, quote = FALSE, na = "")
cat("done\n")
