R <- read.csv("ref_mcmle.csv", stringsAsFactors=FALSE); S <- read.csv("stata_mcmle.csv", stringsAsFactors=FALSE)
for (id in unique(R$id)) {
  r <- R[R$id==id,]; s <- S[S$id==id,]
  if (any(grepl("ERROR", s$sname))) { cat(id, "ERROR\n"); next }
  rm <- tapply(r$rcoef, r$idx, mean); rs <- tapply(r$rcoef, r$idx, sd); sm <- tapply(s$scoef, s$idx, mean); ss <- tapply(s$scoef, s$idx, sd)
  se <- tapply(r$rse, r$idx, mean)
  nm <- r$rname[r$seed==1]
  cat(sprintf("%s\n", id))
  print(data.frame(coef=nm, R_mean=round(rm,3), R_sd=round(rs,3), S_mean=round(sm,3), S_sd=round(ss,3), diff=round(sm-rm,3), diff_in_SE=round((sm-rm)/se,2)), row.names=FALSE)
}
