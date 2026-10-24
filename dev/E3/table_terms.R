# per-term worst deviation from R over all networks (statistic, MPLE coefficient, MPLE SE) -> table_terms.csv
nrm <- function(x) gsub("+","plus",gsub(".","_",x,fixed=TRUE),fixed=TRUE)
RS <- read.csv("ref_summary.csv", stringsAsFactors=FALSE); SS <- read.csv("stata_summary.csv", stringsAsFactors=FALSE)
RM <- read.csv("ref_mple.csv", stringsAsFactors=FALSE); SM <- read.csv("stata_mple.csv", stringsAsFactors=FALSE)
SS <- SS[SS$sname != "edges",]
SM$scoef <- suppressWarnings(as.numeric(SM$scoef)); SM$sse <- suppressWarnings(as.numeric(SM$sse))
ids <- unique(RS$id); out <- list()
for (id in ids) {
  sd <- 0; sn <- 0; md <- NA; me <- NA; mn <- 0; mdeg <- 0
  for (net in unique(RS$net[RS$id==id])) {
    r <- RS[RS$net==net & RS$id==id,]; s <- SS[SS$net==net & SS$id==id,]
    if (nrow(s)==nrow(r) && !any(grepl("ERROR", s$sname))) { sd <- max(sd, max(abs(r$rval - as.numeric(s$sval)))); sn <- sn+1 }
    r <- RM[RM$net==net & RM$id==id,]; s <- SM[SM$net==net & SM$id==id,]
    if (nrow(r)==0 || nrow(s)==0 || any(grepl("ERROR", s$sname))) next
    rk <- !is.na(r$rcoef); scaled <- id %in% c("density","meandeg")
    if (any(!is.finite(r$rcoef[rk])) || any(r$rse[rk] > 20 & !scaled)) { mdeg <- mdeg+1; next }
    k <- match(nrm(r$rname[rk]), nrm(s$sname)); if (any(is.na(k))) next
    sc <- if (scaled) pmax(1, abs(r$rcoef[rk])) else 1
    md <- max(c(md, abs(r$rcoef[rk]-s$scoef[k])/sc), na.rm=TRUE); me <- max(c(me, abs(r$rse[rk]-s$sse[k])/pmax(1,r$rse[rk])), na.rm=TRUE); mn <- mn+1
  }
  out[[id]] <- data.frame(id=id, stat_nets=sn, stat_maxdiff=sd, mple_nets=mn, mple_maxdiff_coef=md, mple_maxdiff_se=me, mple_degenerate_in_R=mdeg)
}
write.csv(do.call(rbind,out), "table_terms.csv", row.names=FALSE)
print(do.call(rbind,out), row.names=FALSE, digits=3)
