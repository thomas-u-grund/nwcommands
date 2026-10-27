# Generates the two extra relevent/nwrem event logs (5,000 events at 20 and at 100 actors) with the same generator as
# the four earlier sizes (nwrem/dev/speed/gen_only.R), so events and actors can be varied separately.
# The four ladder sizes e200 (n=20), e1000 (30), e5000 (50), e20000 (100) are copied unchanged from the earlier run.
B <- Sys.getenv("BENCH"); dir.create(file.path(B, "data", "rem"), showWarnings = FALSE, recursive = TRUE)
gen <- function(nev, n, seed) {
  set.seed(seed)
  cs <- rnorm(n); cr <- rnorm(n); ci <- rnorm(n)
  ws <- exp(0.7*rnorm(n) + 0.3*cs); wr <- exp(0.7*rnorm(n) + 0.2*cr)
  el <- matrix(0, nev, 3)
  for (i in seq_len(nev)) {
    u <- runif(1)
    if (i > 1 && u < 0.2) { j <- sample.int(i-1,1); s <- el[j,2]; r <- el[j,3] }
    else if (i > 1 && u < 0.3) { j <- sample.int(i-1,1); s <- el[j,3]; r <- el[j,2] }
    else { s <- sample.int(n,1,prob=ws); r <- sample.int(n,1,prob=wr); while (r==s) r <- sample.int(n,1,prob=wr) }
    el[i,] <- c(i,s,r)
  }
  miss <- setdiff(seq_len(n), unique(c(el[,2],el[,3])))
  for (m in miss) { k <- sample.int(nev,1); if (runif(1)<.5) el[k,2] <- m else el[k,3] <- m
    if (el[k,2]==el[k,3]) el[k,3] <- (el[k,3] %% n) + 1 }
  stopifnot(all(el[,2]!=el[,3]), length(unique(c(el[,2],el[,3])))==n)
  list(el=el, cs=cs, cr=cr, ci=ci)
}
sizes <- data.frame(id=c("e5000_n20","e5000_n100"), nev=c(5000,5000), n=c(20,100), seed=20261026+c(11,12))
for (k in seq_len(nrow(sizes))) { z <- sizes[k,]; d <- gen(z$nev, z$n, z$seed)
  write.csv(data.frame(sender=d$el[,2], receiver=d$el[,3], eventtime=d$el[,1]), file.path(B,"data","rem",paste0(z$id,"_events.csv")), row.names=FALSE)
  write.csv(data.frame(covsnd=d$cs, covrec=d$cr, covint=d$ci), file.path(B,"data","rem",paste0(z$id,"_cov.csv")), row.names=FALSE) }
