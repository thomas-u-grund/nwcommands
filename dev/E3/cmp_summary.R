R <- read.csv("ref_summary.csv"); S <- read.csv("stata_summary.csv", stringsAsFactors=FALSE)
S <- S[S$sname != "edges",]
bad <- 0
for (k in unique(paste(R$net, R$id))) {
  nt <- strsplit(k," ")[[1]]; r <- R[R$net==nt[1] & R$id==nt[2],]; s <- S[S$net==nt[1] & S$id==nt[2],]
  if (nrow(s)==0 || any(grepl("ERROR", s$idx))) { cat("MISSING/ERROR", k, "\n"); bad <- bad+1; next }
  if (nrow(r)!=nrow(s)) { cat("COUNT", k, nrow(r), nrow(s), "\n"); bad <- bad+1; next }
  d <- max(abs(r$rval - as.numeric(s$sval)))
  nm <- all(gsub(".","_",r$rname,fixed=TRUE) == gsub(".","_",s$sname,fixed=TRUE))
  if (d > 1e-8 || !nm) { cat(sprintf("DIFF %-28s maxdiff=%g names_equal=%s\n", k, d, nm)); bad <- bad+1 }
}
cat("terms-networks compared:", length(unique(paste(R$net,R$id))), " problems:", bad, "\n")
