suppressMessages(library(ergm))
out <- "."
wr <- function(A, f) { B <- matrix(ifelse(is.na(A), ".", as.character(A)), nrow(A)); write.table(B, f, sep=",", row.names=FALSE, col.names=FALSE, quote=FALSE) }
set.seed(1)
n<-30
A<-matrix(rbinom(n*n,1,.15),n,n); A[lower.tri(A)]<-t(A)[lower.tri(A)]; diag(A)<-0
A[1,2]<-A[2,1]<-NA; A[3,5]<-A[5,3]<-NA; A[10,11]<-A[11,10]<-NA
g<-sample(1:2,n,TRUE); c1<-round(rnorm(n),3)
wr(A,"u_adj.csv"); write.csv(data.frame(g=g,c=c1),"u_nodes.csv",row.names=FALSE)
nw<-network(A,directed=FALSE); set.vertex.attribute(nw,"g",g); set.vertex.attribute(nw,"c",c1)
res <- list()
f <- ergm(nw~edges+nodematch("g")+nodecov("c"))
res$A <- c(coef(f), se=sqrt(diag(vcov(f))), ll=as.numeric(logLik(f)), df=attr(logLik(f),"df"), nobs=nobs(f), aic=AIC(f), bic=BIC(f), nulllik=as.numeric(ergm:::logLikNull(f)))
print(res$A)
# directed
set.seed(2); m<-25
D<-matrix(rbinom(m*m,1,.12),m,m); diag(D)<-0
D[2,3]<-NA; D[4,1]<-NA; D[7,9]<-NA; D[9,7]<-NA; D[12,20]<-NA
wr(D,"d_adj.csv")
nwd<-network(D,directed=TRUE)
fd <- ergm(nwd~edges+mutual, control=control.ergm(seed=1))
cat("directed edges+mutual\n"); print(summary(fd)$coefficients[,1:2]); print(logLik(fd)); print(nobs(fd))
fu <- list()
for (sd in 1:3) { r <- ergm(nw~edges+triangle, control=control.ergm(seed=sd)); fu[[sd]] <- c(coef(r), sqrt(diag(vcov(r))), as.numeric(logLik(r))) }
cat("undirected edges+triangle\n"); print(do.call(rbind,fu))
fdl <- list()
for (sd in 1:3) { r <- ergm(nwd~edges+mutual, control=control.ergm(seed=sd)); fdl[[sd]] <- c(coef(r), sqrt(diag(vcov(r))), as.numeric(logLik(r))) }
print(do.call(rbind,fdl))
# MPLE for dd with NA: dyad-dependent mple (random imputation)
r <- ergm(nw~edges+triangle, estimate="MPLE"); print(coef(r))
