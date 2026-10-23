# R MPLE reference for curved (free-decay) terms at boundary solutions (agent E4).
# usage: Rscript curved_ref.R <xvaldir> <out.csv> ; networks from the earlier cross-validation (dir_adj.csv, und_adj.csv)
suppressMessages({library(ergm); library(network)})
args <- commandArgs(TRUE); d <- args[1]; out <- args[2]
A <- as.matrix(read.csv(file.path(d, "dir_adj.csv"), header=FALSE))
nd <- network(A, directed=TRUE)
nodes <- read.csv(file.path(d, "dir_nodes.csv")); nd %v% "a" <- nodes$a; nd %v% "x" <- nodes$x
U <- as.matrix(read.csv(file.path(d, "und_adj.csv"), header=FALSE))
nu <- network(U, directed=FALSE); un <- read.csv(file.path(d, "und_nodes.csv")); nu %v% "a" <- un$a; nu %v% "x" <- un$x
specs <- list(
 c("cDe","nd","gwesp(fixed=FALSE,type='OTP')"),
 c("cDi","nd","gwidegree(fixed=FALSE)"),
 c("cDo","nd","gwodegree(fixed=FALSE)"),
 c("cDd","nd","gwdsp(fixed=FALSE,type='OTP')"),
 c("cDn","nd","gwnsp(fixed=FALSE,type='OTP')"),
 c("cUe","nu","gwesp(fixed=FALSE)"),
 c("cUd","nu","gwdegree(fixed=FALSE)"),
 c("cUs","nu","gwdsp(fixed=FALSE)"),
 c("cUn","nu","gwnsp(fixed=FALSE)"))
res <- list()
for (sp in specs) {
  f <- as.formula(paste(sp[2], "~ edges +", sp[3]))
  fit <- try(suppressMessages(ergm(f, estimate="MPLE")), silent=TRUE)
  if (inherits(fit, "try-error")) { res[[length(res)+1]] <- data.frame(id=sp[1], idx=0, name="ERROR", coef=NA, se=NA); next }
  res[[length(res)+1]] <- data.frame(id=sp[1], idx=seq_along(coef(fit)), name=names(coef(fit)), coef=as.numeric(coef(fit)), se=sqrt(diag(vcov(fit))))
}
write.csv(do.call(rbind, res), out, row.names=FALSE)
