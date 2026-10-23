R <- read.csv("ref_mple.csv", stringsAsFactors=FALSE); S <- read.csv("stata_mple.csv", stringsAsFactors=FALSE)
bad <- 0; n <- 0
for (k in unique(paste(R$net, R$id))) {
  nt <- strsplit(k," ")[[1]]; r <- R[R$net==nt[1] & R$id==nt[2],]; s <- S[S$net==nt[1] & S$id==nt[2],]
  n <- n+1
  if (nrow(s)==0 || any(grepl("ERROR", s$sname))) { cat("MISSING/ERROR", k, "\n"); bad <- bad+1; next }
  rn <- gsub(".","_",r$rname,fixed=TRUE); sn <- gsub(".","_",s$sname,fixed=TRUE)
  # drop coefficients R reports as NA (collinear) and Stata omitted (0)
  rk <- !is.na(r$rcoef)
  if (any(!is.finite(r$rcoef[rk])) || any(r$rse[rk] > 20)) { cat("degenerate in R (separation/collinear), skipped:", k, "\n"); next }
  sk <- match(rn[rk], sn)
  if (any(is.na(sk))) { cat("NAMES", k, "R:", rn[rk], "S:", sn, "\n"); bad <- bad+1; next }
  dc <- max(abs(r$rcoef[rk] - s$scoef[sk])); ds <- max(abs(r$rse[rk] - s$sse[sk]) / pmax(1, r$rse[rk]))
  flag <- if (dc>1e-4 || ds>1e-4) { bad <- bad+1; "DIFF" } else "ok"
  if (flag=="DIFF") cat(sprintf("%-4s %-26s dcoef=%g dse=%g\n", flag, k, dc, ds))
}
cat("compared", n, "problems", bad, "\n")
