suppressMessages(library(ergm))
wr <- function(A, f) { B <- matrix(ifelse(is.na(A), ".", as.character(A)), nrow(A)); write.table(B, f, sep=",", row.names=FALSE, col.names=FALSE, quote=FALSE) }
set.seed(11); n<-40
g<-sample(1:2,n,TRUE)
P<-matrix(0.06,n,n); P[outer(g,g,"==")]<-0.2
A<-matrix(rbinom(n*n,1,P),n,n); A[lower.tri(A)]<-t(A)[lower.tri(A)]; diag(A)<-0
# add triadic closure
idx<-which(upper.tri(A)&is.na(A)); 
na<-sample(which(upper.tri(A)),70); A[na]<-NA; A[lower.tri(A)]<-t(A)[lower.tri(A)]; diag(A)<-0
wr(A,"u2_adj.csv"); write.csv(data.frame(g=g),"u2_nodes.csv",row.names=FALSE)
nw<-network(A,directed=FALSE); set.vertex.attribute(nw,"g",g)
cat("NA dyads", network.naedgecount(nw), "edges", network.edgecount(nw), "\n")
res<-list()
for (sd in 1:4){ r<-ergm(nw~edges+nodematch("g")+triangle,control=control.ergm(seed=sd)); res[[sd]]<-c(coef(r),sqrt(diag(vcov(r))),as.numeric(logLik(r)))}
print(round(do.call(rbind,res),4))
r<-ergm(nw~edges+nodematch("g"),estimate="MPLE"); print(c(coef(r),sqrt(diag(vcov(r))),as.numeric(logLik(r)),nobs(r)))
# directed with many NA
set.seed(12); m<-30
D<-matrix(rbinom(m*m,1,.1),m,m); diag(D)<-0
rec<-which(D==1,arr.ind=TRUE); for(k in seq_len(nrow(rec))) if(runif(1)<.5) D[rec[k,2],rec[k,1]]<-1
nad<-sample(which(row(D)!=col(D)),60); D[nad]<-NA
wr(D,"d2_adj.csv")
nwd<-network(D,directed=TRUE)
cat("directed NA", network.naedgecount(nwd),"\n")
res<-list()
for (sd in 1:4){ r<-ergm(nwd~edges+mutual,control=control.ergm(seed=sd)); res[[sd]]<-c(coef(r),sqrt(diag(vcov(r))),as.numeric(logLik(r)))}
print(round(do.call(rbind,res),4))
