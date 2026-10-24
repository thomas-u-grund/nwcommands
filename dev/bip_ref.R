# R reference for the nwergm bipartite tests (tag bip): observed statistics and MPLE for every spec row on three networks.
# usage: Rscript bip_ref.R <dir with bip?_edges.csv/bip?_nodes.csv> <spec file> <out csv>
suppressMessages(library(ergm))
args <- commandArgs(TRUE); d <- args[1]; specf <- args[2]; outf <- args[3]
rd <- function(nm) {
  e <- read.csv(file.path(d, paste0("bip", nm, "_edges.csv"))); v <- read.csv(file.path(d, paste0("bip", nm, "_nodes.csv")))
  n1 <- v$n1[1]; n <- nrow(v); n2 <- n - n1
  B <- matrix(0, n1, n2); B[cbind(e$person, e$event)] <- 1
  nw <- network(B, bipartite = n1, directed = FALSE)
  nw %v% "g" <- v$g; nw %v% "x" <- v$x; nw %v% "h" <- v$h
  nw
}
spec <- read.table(specf, sep = "|", quote = "", stringsAsFactors = FALSE, col.names = c("id", "rterm", "sopts"), comment.char = "")
res <- list()
for (nm in c("A", "B", "C")) {
  nw <- rd(nm)
  for (i in seq_len(nrow(spec))) {
    f <- as.formula(paste("nw ~ edges +", spec$rterm[i]))
    st <- tryCatch(suppressWarnings(summary(f)), error = function(e) NULL)
    if (is.null(st)) { res[[length(res) + 1]] <- data.frame(net = nm, id = spec$id[i], idx = 0, rname = "ERROR", rstat = NA, rb = NA, rse = NA); next }
    fit <- tryCatch(suppressWarnings(suppressMessages(ergm(f, estimate = "MPLE"))), error = function(e) NULL)
    b <- if (is.null(fit)) rep(NA, length(st)) else coef(fit)
    se <- if (is.null(fit)) rep(NA, length(st)) else tryCatch(sqrt(diag(vcov(fit, sources = "model"))), error = function(e) rep(NA, length(st)))
    res[[length(res) + 1]] <- data.frame(net = nm, id = spec$id[i], idx = seq_along(st), rname = names(st), rstat = as.numeric(st), rb = as.numeric(b), rse = as.numeric(se))
  }
}
write.csv(do.call(rbind, res), outf, row.names = FALSE)
# design matrices (all dyads): ergmMPLE predictor + response, for comparison with the Stata change statistics
dres <- list()
for (nm in c("A", "B", "C")) {
  nw <- rd(nm)
  for (i in seq_len(nrow(spec))) {
    f <- as.formula(paste("nw ~ edges +", spec$rterm[i]))
    m <- tryCatch(suppressWarnings(ergmMPLE(f, output = "matrix")), error = function(e) NULL)
    if (is.null(m)) next
    D <- cbind(m$predictor, y = m$response, w = m$weights)
    dres[[length(dres) + 1]] <- data.frame(net = nm, id = spec$id[i], D, check.names = FALSE)
  }
}
saveRDS(dres, sub("\\.csv$", "_design.rds", outf))
