# R reference: MPLE coefficients/SE for edges + term (term only for density/meandeg) -> ref_mple.csv
suppressMessages({library(ergm); library(network)})
sp <- read.csv("spec.csv", stringsAsFactors=FALSE)
nets <- list(und_a=FALSE, und_b=FALSE, und_c=FALSE, dir_a=TRUE, dir_b=TRUE, dir_c=TRUE)
res <- list()
for (nm in names(nets)) {
  A <- as.matrix(read.csv(paste0(nm,"_adj.csv"), header=FALSE)); nd <- read.csv(paste0(nm,"_nodes.csv"))
  net <- network(A, directed=nets[[nm]]); net %v% "a" <- nd$a; net %v% "x" <- nd$x
  for (i in seq_len(nrow(sp))) {
    k <- sp$kind[i]; isd <- nets[[nm]]
    if (k=="und" && isd) next; if (k=="dir" && !isd) next
    rhs <- if (sp$id[i] %in% c("density","meandeg")) sp$r[i] else paste("edges +", sp$r[i])
    f <- as.formula(paste("net ~", rhs))
    fit <- tryCatch(suppressWarnings(suppressMessages(ergm(f, estimate="MPLE"))), error=function(e) NULL)
    if (is.null(fit)) { cat("R error:", nm, sp$id[i], "\n"); next }
    co <- coef(fit); se <- sqrt(diag(vcov(fit)))
    res[[length(res)+1]] <- data.frame(net=nm, id=sp$id[i], idx=seq_along(co), rname=names(co), rcoef=as.numeric(co), rse=as.numeric(se))
  }
}
write.csv(do.call(rbind,res), "ref_mple.csv", row.names=FALSE)
