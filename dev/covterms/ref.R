# Reference generator for test_nwergm_covterms.do (agent E4).
# usage: Rscript ref.R <specfile.csv> <outdir>
# spec columns: id, net, nw (nwergm option string), r (R formula rhs after edges), mcmle (0/1)
# Writes <outdir>/nets_*.csv (networks) and <outdir>/ref.csv (R summary + MPLE per spec).
suppressMessages({library(ergm); library(network)})
args <- commandArgs(TRUE); specf <- args[1]; out <- args[2]
dir.create(out, showWarnings=FALSE, recursive=TRUE)
wm <- function(m, f) write.table(m, f, sep=",", row.names=FALSE, col.names=FALSE)
set.seed(20261101)
mk <- function(name, A, directed, at) {
  wm(A, file.path(out, paste0("net_", name, "_adj.csv")))
  write.csv(as.data.frame(at), file.path(out, paste0("net_", name, "_nodes.csv")), row.names=FALSE)
  nw <- network(A, directed=directed)
  for (v in names(at)) nw %v% v <- at[[v]]
  nw
}
nets <- list()
## random undirected n=30
n <- 30; a <- sample(1:3, n, TRUE); g <- sample(0:1, n, TRUE); x <- round(rnorm(n, 50, 10), 2); z <- sample(1:5, n, TRUE)
P <- outer(1:n, 1:n, function(i,j) plogis(-2.4 + 0.8*(a[i]==a[j]) + 0.02*(x[i]+x[j]-100)))
U <- matrix(0, n, n); U[upper.tri(U)] <- rbinom(sum(upper.tri(U)), 1, P[upper.tri(P)]); U <- U + t(U)
nets$U <- mk("U", U, FALSE, list(a=a, g=g, x=x, z=z))
## random directed n=25
m <- 25; a <- sample(1:3, m, TRUE); g <- sample(0:1, m, TRUE); x <- round(rnorm(m, 50, 10), 2); z <- sample(1:5, m, TRUE)
P <- outer(1:m, 1:m, function(i,j) plogis(-2.2 + 0.8*(a[i]==a[j]) + 0.02*(x[j]-50)))
D <- matrix(rbinom(m*m, 1, P), m, m); diag(D) <- 0
nets$D <- mk("D", D, TRUE, list(a=a, g=g, x=x, z=z))
## real undirected: flomarriage
data(florentine)
A <- as.matrix(flomarriage)
nets$F <- mk("F", A, FALSE, list(w=flomarriage %v% "wealth", pr=flomarriage %v% "priorates", a=as.integer(cut(flomarriage %v% "wealth", c(0, 20, 45, 200)))))
## real undirected: faux.mesa.high
data(faux.mesa.high)
A <- as.matrix(faux.mesa.high)
nets$M <- mk("M", A, FALSE, list(grade=faux.mesa.high %v% "Grade", sex=as.integer(factor(faux.mesa.high %v% "Sex")), race=as.integer(factor(faux.mesa.high %v% "Race"))))
## real directed: samplk1
data(samplk)
A <- as.matrix(samplk1)
nets$S <- mk("S", A, TRUE, list(grp=as.integer(factor(samplk1 %v% "group")), cl=as.integer(factor(samplk1 %v% "cloisterville"))))
## edge covariates (matrices) for dyadic terms, saved per network
for (nm in names(nets)) {
  nn <- network.size(nets[[nm]])
  X <- matrix(round(runif(nn*nn, 0, 4)), nn, nn); diag(X) <- 0
  if (!is.directed(nets[[nm]])) { X[lower.tri(X)] <- t(X)[lower.tri(X)] }
  wm(X, file.path(out, paste0("net_", nm, "_ec.csv")))
}
M3 <- matrix(c(.5,1,2,.3,0,1.5,1,2,.1), 3, byrow=TRUE)
M5 <- matrix(c(.5,1,2,0,1,.3,0,1.5,2,2,1,2,.1,1,0,0,1,1,2,3,2,2,1,0,.5), 5, byrow=TRUE)
FF <- outer(1:16, 1:16, function(i,j) (i*j) %% 4)
spec <- read.csv(specf, stringsAsFactors=FALSE)
res <- list()
for (k in seq_len(nrow(spec))) {
  nw <- nets[[spec$net[k]]]
  nn <- network.size(nw)
  ec <- as.matrix(read.csv(file.path(out, paste0("net_", spec$net[k], "_ec.csv")), header=FALSE))
  f <- as.formula(paste("nw ~ edges +", spec$r[k]))
  environment(f) <- environment()
  r <- try({
    s <- summary(f)
    fit <- ergm(f, estimate="MPLE")
    co <- coef(fit); se <- sqrt(diag(vcov(fit)))
    data.frame(id=spec$id[k], idx=seq_along(s), rname=names(s), stat=as.numeric(s), coef=as.numeric(co), se=as.numeric(se), err="")
  }, silent=TRUE)
  if (inherits(r, "try-error")) r <- data.frame(id=spec$id[k], idx=0, rname="ERROR", stat=NA, coef=NA, se=NA, err=gsub("[\r\n,\"]", " ", as.character(r)))
  res[[k]] <- r
}
write.csv(do.call(rbind, res), file.path(out, "ref.csv"), row.names=FALSE)
