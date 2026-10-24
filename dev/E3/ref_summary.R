# R reference: summary() of every term in spec.csv on the 4 test networks -> ref_summary.csv
suppressMessages({library(ergm); library(network)})
sp <- read.csv("spec.csv", stringsAsFactors=FALSE)
nets <- list(und_a=FALSE, und_b=FALSE, und_c=FALSE, und_d=FALSE, dir_a=TRUE, dir_b=TRUE, dir_c=TRUE, dir_d=TRUE)
res <- list()
for (nm in names(nets)) {
  A <- as.matrix(read.csv(paste0(nm,"_adj.csv"), header=FALSE)); nd <- read.csv(paste0(nm,"_nodes.csv"))
  net <- network(A, directed=nets[[nm]]); net %v% "a" <- nd$a; net %v% "x" <- nd$x
  for (i in seq_len(nrow(sp))) {
    k <- sp$kind[i]; isd <- nets[[nm]]
    if (k=="und" && isd) next; if (k=="dir" && !isd) next
    f <- as.formula(paste("net ~", sp$r[i]))
    s <- tryCatch(summary(f), error=function(e) NULL, warning=function(w) suppressWarnings(summary(f)))
    if (is.null(s)) { cat("R error:", nm, sp$id[i], "\n"); next }
    res[[length(res)+1]] <- data.frame(net=nm, id=sp$id[i], idx=seq_along(s), rname=names(s), rval=as.numeric(s))
  }
}
write.csv(do.call(rbind,res), "ref_summary.csv", row.names=FALSE)
