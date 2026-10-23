n<-4
W<-list(rbind(c(0,1,0,0),c(0,0,1,0),c(1,0,0,0),c(0,0,0,0)),rbind(c(0,1,0,1),c(1,0,1,0),c(1,0,0,0),c(0,0,1,0)),rbind(c(0,0,1,1),c(1,0,0,0),c(0,1,0,1),c(1,0,0,0)))
dyi<-as.matrix(expand.grid(i=1:n,j=1:n)); dyi<-dyi[dyi[,1]!=dyi[,2],]
nd<-nrow(dyi); S<-2^nd
kof<-function(i,j) which(dyi[,1]==i & dyi[,2]==j)
bits<-function(s) bitwAnd(bitwShiftR(s,0:(nd-1)),1)
toA<-function(s){A<-matrix(0,n,n); A[dyi]<-bits(s); A}
idx<-function(A) sum(A[dyi]*2^(0:(nd-1)))
# transition matrix pieces: for each state the move probabilities depend on theta; store neighbours
nb<-array(0L,c(S,n,n)); ch1<-array(0,c(S,n,n)); ch2<-array(0,c(S,n,n)); ch3<-array(0,c(S,n,n))
for(s in 0:(S-1)){A<-toA(s); for(i in 1:n) for(j in 1:n) if(j!=i){sg<-if(A[i,j]==1) -1 else 1; nb[s+1,i,j]<-bitwXor(s,2^(kof(i,j)-1)); ch1[s+1,i,j]<-sg; ch2[s+1,i,j]<-sg*A[j,i]; ch3[s+1,i,j]<-sg*(sum(A[i,]*A[,j])+sum(A[i,]*A[j,]))}}
Pmat<-function(th){Pm<-matrix(0,S,S)
 for(s in 0:(S-1)) for(i in 1:n){u<-numeric(n); for(j in 1:n) if(j!=i) u[j]<-th[1]*ch1[s+1,i,j]+th[2]*ch2[s+1,i,j]+th[3]*ch3[s+1,i,j]
  p<-exp(u)/sum(exp(u)); for(j in 1:n){t<-if(j==i) s else nb[s+1,i,j]; Pm[s+1,t+1]<-Pm[s+1,t+1]+p[j]/n}}
 Pm}
logL<-function(th,rho){Pm<-Pmat(th); tot<-0
 for(ab in list(c(1,2),c(2,3))){v<-numeric(S); v[idx(W[[ab[1]]])+1]<-1; e0<-idx(W[[ab[2]]])+1; lam<-n*rho[ab[1]]; L<-0
  for(R in 0:200){w<-exp(-lam+R*log(lam)-lgamma(R+1))*v[e0]; L<-L+w; v<-as.vector(v%*%Pm)}
  tot<-tot+log(L)}
 tot}
th0<-c(-1,0.7,0.2); rho0<-c(3,3); h<-1e-4
g<-numeric(5)
for(k in 1:3){a<-th0;b<-th0;a[k]<-a[k]+h;b[k]<-b[k]-h; g[k]<-(logL(a,rho0)-logL(b,rho0))/(2*h)}
for(k in 1:2){a<-rho0;b<-rho0;a[k]<-a[k]+h;b[k]<-b[k]-h; g[3+k]<-(logL(th0,a)-logL(th0,b))/(2*h)}
cat("EXACTSCORE",g,"\n")
