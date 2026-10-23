# R ergm 4.12.0 reference fits with obs.constraints (unobserved dyads = fixallbut), for test_nwergm_constr.do
suppressMessages(library(ergm))
set.seed(4242)
n <- 14
A <- matrix(0,n,n); A[upper.tri(A)] <- rbinom(n*(n-1)/2,1,0.35); A <- A+t(A)
V <- network(A, directed=FALSE)
ut <- which(upper.tri(A), arr.ind=TRUE)
sel <- ut[sample(nrow(ut), 10),]
M <- matrix(0,n,n); M[sel] <- 1; M <- M + t(M)
miss <- network(M, directed=FALSE)
writeLines(c(paste("V", paste(as.vector(t(A)), collapse="")), paste("VM", paste(as.vector(t(M)), collapse=""))), "e6_obs_basis.txt")
out <- character(0)
cat("edges", network.edgecount(V), "\n")
for(s in 1:3){
  set.seed(s)
  t0 <- Sys.time()
  f <- suppressWarnings(suppressMessages(ergm(V ~ edges + triangle, obs.constraints=~fixallbut(miss), control=control.ergm(MCMC.samplesize=4096, MCMC.burnin=16384, MCMC.interval=1024, seed=s))))
  cat("fit", s, format(Sys.time()-t0), "\n")
  co <- coef(f); se <- sqrt(diag(vcov(f)))
  for(j in seq_along(co)) out <- c(out, sprintf("OBS|V_miss|%s|%d|%.6f|%.6f", names(co)[j], s, co[j], se[j]))
}
writeLines(out, "e6_obs_ref.txt")
cat(length(out), "rows\n")
