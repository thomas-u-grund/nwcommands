# One timed relevent fit in its own process.  Usage: Rscript rem_one.R SIZE SET HESSIAN(TRUE|FALSE) OUTFILE  (env BENCH)
# Timer = rem.dyad() only.  Untimed warm-up fit (e200, S1) first.
suppressMessages(library(relevent))
a <- commandArgs(TRUE); size <- a[1]; sn <- a[2]; hess <- as.logical(a[3]); out <- a[4]
B <- Sys.getenv("BENCH")
sets <- list(S1_nodsnd_nidrec=c("NODSnd","NIDRec"), S2_degree4=c("NODSnd","NIDRec","NIDSnd","NODRec"),
 S3_degree4_inertia=c("NODSnd","NIDRec","NIDSnd","NODRec","FrPSndSnd","FrRecSnd"), S4_recency=c("NODSnd","NIDRec","RSndSnd","RRecSnd"),
 S5_covariates=c("NODSnd","NIDRec","CovSnd","CovRec","CovInt"))
rd <- function(id, f) { p <- file.path(B, "data", "rem", paste0(id, "_", f, ".csv")); read.csv(p) }
fit <- function(id, sn, hess) {
  ev <- rd(id, "events"); cv <- rd(id, "cov"); el <- cbind(ev$eventtime, ev$sender, ev$receiver); n <- nrow(cv)
  covar <- if (sn == "S5_covariates") list(CovSnd=cv$covsnd, CovRec=cv$covrec, CovInt=cv$covint) else NULL
  t <- system.time(f <- rem.dyad(el, n, effects=sets[[sn]], covar=covar, ordinal=TRUE, fit.method="MLE", hessian=hess, gof=FALSE, verbose=FALSE))[["elapsed"]]
  list(t=t, f=f)
}
invisible(fit("e200", "S1_nodsnd_nidrec", hess))
r <- fit(size, sn, hess); f <- r$f
wr <- function(k, v) cat(k, "\t", paste(v, collapse = "\t"), "\n", sep = "", file = out, append = TRUE)
unlink(out)
se <- if (hess && !is.null(f$cov)) sqrt(diag(f$cov)) else if (!is.null(f$se)) f$se else rep(NA, length(f$coef))
wr("secs", sprintf("%.4f", r$t)); wr("converged", as.integer(identical(as.integer(f$convergence), 0L))); wr("iters", paste(f$counts, collapse = "/"))
wr("ll", sprintf("%.8f", if (!is.null(f$value)) -f$value else NA))
wr("names", names(f$coef)); wr("ests", sprintf("%.8g", f$coef)); wr("ses", sprintf("%.8g", se))
wr("version", paste0("relevent ", packageVersion("relevent"), " hessian ", hess, " fields ", paste(names(f), collapse=",")))
