# MCMLE of R ergm for the models of bip_mcmle_models.txt on network D, 4 seeds each: mean and sd of the coefficients over seeds
suppressMessages(library(ergm))
args <- commandArgs(TRUE); d <- args[1]; specf <- args[2]; outf <- args[3]
e <- read.csv(file.path(d, "bipD_edges.csv")); v <- read.csv(file.path(d, "bipD_nodes.csv"))
n1 <- v$n1[1]; n <- nrow(v); B <- matrix(0, n1, n - n1); B[cbind(e$person, e$event)] <- 1
nw <- network(B, bipartite = n1, directed = FALSE); nw %v% "g" <- v$g; nw %v% "x" <- v$x; nw %v% "h" <- v$h
spec <- read.table(specf, sep = "|", quote = "", stringsAsFactors = FALSE, col.names = c("id", "rterm", "sopts"))
out <- list()
for (i in seq_len(nrow(spec))) {
  f <- as.formula(paste("nw ~ edges +", spec$rterm[i]))
  cf <- NULL
  for (s in 1:4) {
    set.seed(s)
    fit <- tryCatch(suppressWarnings(suppressMessages(ergm(f, control = control.ergm(MCMC.samplesize = 4000, MCMLE.maxit = 30, seed = s)))), error = function(e) NULL)
    if (!is.null(fit)) cf <- rbind(cf, coef(fit))
  }
  if (is.null(cf)) { cat(spec$id[i], "R failed\n"); next }
  out[[i]] <- data.frame(id = spec$id[i], name = colnames(cf), rmean = colMeans(cf), rsd = apply(cf, 2, sd), n = nrow(cf), rse = tryCatch(sqrt(diag(vcov(fit))), error = function(e) NA))
}
write.csv(do.call(rbind, out), outf, row.names = FALSE)
