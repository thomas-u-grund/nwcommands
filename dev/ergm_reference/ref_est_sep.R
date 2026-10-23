.libPaths(c("../rlib413", .libPaths()))
suppressMessages(library(ergm))
set.seed(5); n <- 12; g <- rep(1:2, each=6)
A <- outer(g, g, "==") * 1; diag(A) <- 0
# quasi-separation: drop a few within ties randomly (still separable? keep none between)
A[upper.tri(A) & A==1 & matrix(runif(n*n)<.3,n)] <- 0; A[lower.tri(A)] <- t(A)[lower.tri(A)]
write.table(A, "sep_adj.csv", sep=",", row.names=FALSE, col.names=FALSE)
write.csv(data.frame(g=g), "sep_nodes.csv", row.names=FALSE)
nw <- network(A, directed=FALSE); nw %v% "g" <- g
f <- ergm(nw ~ edges + nodematch("g"), estimate="MPLE")
print(coef(summary(f)))
f2 <- ergm(nw ~ edges + nodematch("g"), estimate="MPLE", control=control.ergm(MPLE.check=FALSE))
print(coef(summary(f2)))
f3 <- ergm(nw ~ edges + nodematch("g"), estimate="MPLE", control=control.ergm(MPLE.type="penalized"))
print(coef(summary(f3)))
