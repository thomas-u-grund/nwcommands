# R ergm 4.12.0 reference fits with obs.constraints (unobserved dyads = fixallbut), for test_nwergm_constr.do
suppressMessages(library(ergm))
rd <- function(tag){ l <- readLines("e6_basis.txt"); x <- strsplit(sub(paste0("^",tag," "),"",l[startsWith(l,paste0(tag," "))]),"")[[1]]; matrix(as.integer(x), ncol=sqrt(length(x)), byrow=TRUE) }
U <- network(rd("U"), directed=FALSE)
set.seed(99)
Um <- as.matrix(U); ut <- which(upper.tri(Um), arr.ind=TRUE)
sel <- ut[sample(nrow(ut), 24),]
M <- matrix(0,12,12); M[sel] <- 1; M <- M + t(M)
miss <- network(M, directed=FALSE)
writeLines(paste("UM", paste(as.vector(t(M)), collapse="")), "e6_obs_miss.txt")
out <- character(0)
for(s in 1:4){
  set.seed(s)
  f <- suppressWarnings(suppressMessages(ergm(U ~ edges + triangle, obs.constraints=~fixallbut(miss), control=control.ergm(MCMC.samplesize=4096, MCMC.burnin=16384, MCMC.interval=1024, seed=s))))
  co <- coef(f); se <- sqrt(diag(vcov(f)))
  for(j in seq_along(co)) out <- c(out, sprintf("OBS|U_miss|%s|%d|%.6f|%.6f", names(co)[j], s, co[j], se[j]))
  set.seed(s)
  f <- suppressWarnings(suppressMessages(ergm(U ~ edges + triangle, constraints=~bd(maxout=5), obs.constraints=~fixallbut(miss), control=control.ergm(MCMC.samplesize=4096, MCMC.burnin=16384, MCMC.interval=1024, seed=s))))
  co <- coef(f); se <- sqrt(diag(vcov(f)))
  for(j in seq_along(co)) out <- c(out, sprintf("OBS|U_miss_bd|%s|%d|%.6f|%.6f", names(co)[j], s, co[j], se[j]))
}
writeLines(out, "e6_obs_ref.txt")
cat(length(out), "rows\n")
