.libPaths(c("../rlib413", .libPaths()))
suppressMessages({library(ergm)}); cat(as.character(packageVersion("ergm")), "\n")
X <- "../ergm_compare/xval/"
rd <- function(f) as.matrix(read.csv(f, header=FALSE))
flo <- network(rd("flo_adj.csv"), directed=FALSE); fn <- read.csv("flo_nodes.csv"); flo %v% "wealth" <- fn$wealth
und <- network(rd(paste0(X,"und_adj.csv")), directed=FALSE); un <- read.csv(paste0(X,"und_nodes.csv")); und %v% "a" <- un$a; und %v% "x" <- un$x
dir <- network(rd(paste0(X,"dir_adj.csv")), directed=TRUE); dn <- read.csv(paste0(X,"dir_nodes.csv")); dir %v% "a" <- dn$a; dir %v% "x" <- dn$x
out <- NULL
add <- function(id, f) { s <- summary(f); co <- coef(s); out <<- rbind(out, data.frame(id=id, term=rownames(co), b=co[,1], se=co[,2])) }
for (ty in c("glm","penalized")) {
  ct <- control.ergm(MPLE.type=ty)
  add(paste0("flo_",ty), ergm(flo ~ edges + triangle + nodecov("wealth"), estimate="MPLE", control=ct))
  add(paste0("und_",ty), ergm(und ~ edges + nodematch("a") + nodecov("x") + gwesp(0.5, fixed=TRUE), estimate="MPLE", control=ct))
  add(paste0("dir_",ty), ergm(dir ~ edges + mutual + nodematch("a") + nodeocov("x"), estimate="MPLE", control=ct))
}
write.csv(out, "ref_mple.csv", row.names=FALSE)
print(out)
