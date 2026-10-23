# compares ref_mple.csv (R) with stata_mple.csv; degenerate R fits (separation) are skipped; density/meandeg are compared relative to the coefficient size
R <- read.csv("ref_mple.csv", stringsAsFactors=FALSE); S <- read.csv("stata_mple.csv", stringsAsFactors=FALSE); S$scoef <- suppressWarnings(as.numeric(S$scoef)); S$sse <- suppressWarnings(as.numeric(S$sse))
nrm <- function(x) gsub("+","plus",gsub(".","_",x,fixed=TRUE),fixed=TRUE)
bad <- 0; n <- 0; ok <- character(); degen <- character()
for (k in unique(paste(R$net, R$id))) {
  nt <- strsplit(k," ")[[1]]; r <- R[R$net==nt[1] & R$id==nt[2],]; s <- S[S$net==nt[1] & S$id==nt[2],]
  n <- n+1
  if (nrow(s)==0 || any(grepl("ERROR", s$sname))) { cat("Stata fit failed (R:", paste(round(r$rcoef,2), collapse=" "), ")", k, "\n"); next }
  rn <- nrm(r$rname); sn <- nrm(s$sname)
  rk <- !is.na(r$rcoef)
  scaled <- nt[2] %in% c("density","meandeg")
  if (any(!is.finite(r$rcoef[rk])) || any(r$rse[rk] > 20 & !scaled)) { degen <- c(degen, k); next }
  sk <- match(rn[rk], sn)
  if (any(is.na(sk))) { cat("NAMES", k, "R:", rn[rk], "S:", sn, "\n"); bad <- bad+1; next }
  sc <- if (scaled) pmax(1, abs(r$rcoef[rk])) else 1
  dc <- max(abs(r$rcoef[rk] - s$scoef[sk]) / sc); ds <- max(abs(r$rse[rk] - s$sse[sk]) / pmax(1, r$rse[rk]))
  if (dc>1e-4 || ds>1e-3) { bad <- bad+1; cat(sprintf("DIFF %-26s dcoef=%g dse=%g\n", k, dc, ds)) } else ok <- c(ok, nt[2])
}
cat("compared", n, "problems", bad, "; degenerate in R and skipped:", length(degen), "\n")
alln <- unique(R$id); cat("terms with no usable comparison:", setdiff(alln, ok), "\n")
