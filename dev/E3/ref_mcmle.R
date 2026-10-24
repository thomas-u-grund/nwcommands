# R MCMLE reference: networks simulated from known models, then fitted with 3 seeds -> mcmle_M*_adj.csv, ref_mcmle.csv
suppressMessages({library(ergm); library(network)})
sp <- read.csv("mcmle_specs.csv", stringsAsFactors=FALSE)
res <- list()
for (i in seq_len(nrow(sp))) {
  set.seed(100 + i)
  net0 <- network.initialize(sp$n[i], directed=(sp$kind[i]=="dir"))
  f0 <- as.formula(paste("net0 ~ edges +", sp$r[i]))
  tc <- as.numeric(strsplit(sp$truecoef[i], ",")[[1]])
  net <- simulate(f0, coef=tc, nsim=1, control=control.simulate.formula(MCMC.burnin=200000))
  write.table(as.matrix(net), paste0("mcmle_", sp$id[i], "_adj.csv"), sep=",", row.names=FALSE, col.names=FALSE)
  f <- as.formula(paste("net ~ edges +", sp$r[i]))
  for (sd in 1:3) {
    fit <- tryCatch(suppressWarnings(suppressMessages(ergm(f, control=control.ergm(seed=sd)))), error=function(e) NULL)
    if (is.null(fit)) { cat("R failed:", sp$id[i], sd, "\n"); next }
    co <- coef(fit)
    res[[length(res)+1]] <- data.frame(id=sp$id[i], seed=sd, idx=seq_along(co), rname=names(co), rcoef=as.numeric(co), rse=sqrt(diag(vcov(fit))))
  }
}
write.csv(do.call(rbind,res), "ref_mcmle.csv", row.names=FALSE)
