# R MCMLE reference for the dyad-dependent covariate terms (agent E4).
# usage: Rscript ref_mcmle.R <datadir> <out.csv>   (networks written by ref.R)
suppressMessages({library(ergm); library(network)})
args <- commandArgs(TRUE); d <- args[1]; out <- args[2]
load_net <- function(name, directed) {
  A <- as.matrix(read.csv(file.path(d, paste0("net_", name, "_adj.csv")), header=FALSE))
  at <- read.csv(file.path(d, paste0("net_", name, "_nodes.csv")))
  nw <- network(A, directed=directed)
  for (v in names(at)) nw %v% v <- at[[v]]
  nw
}
nets <- list(U=load_net("U", FALSE), D=load_net("D", TRUE))
mods <- list(
  m1=list(net="U", f=~edges+nodecovrange("x")+nodefactordistinct("a")),
  m2=list(net="D", f=~edges+nodeocovrange("x")+nodeifactordistinct("z")),
  m3=list(net="D", f=~edges+nodecovrange("x")+nodefactordistinct("a")),
  m4=list(net="U", f=~edges+absdiffcat("z")+smalldiff("x",cutoff=5)+sociality(nodes=1:3)),
  m5=list(net="D", f=~edges+nodemix("g")+diff("x")+dyadcov(DEC)))
DEC <- as.matrix(read.csv(file.path(d, "net_D_ec.csv"), header=FALSE))
res <- list()
for (nm in names(mods)) {
  nw <- nets[[mods[[nm]]$net]]
  f <- update(mods[[nm]]$f, nw ~ .)
  for (seed in 1:3) {
    set.seed(seed)
    fit <- try(ergm(f, control=control.ergm(MCMC.samplesize=5000, MCMC.interval=100, MCMC.burnin=20000, seed=seed, MCMLE.maxit=30)), silent=TRUE)
    if (inherits(fit, "try-error")) next
    se <- sqrt(diag(vcov(fit)))
    res[[length(res)+1]] <- data.frame(model=nm, seed=seed, idx=seq_along(coef(fit)), name=names(coef(fit)), coef=as.numeric(coef(fit)), se=as.numeric(se))
  }
}
write.csv(do.call(rbind, res), out, row.names=FALSE)
