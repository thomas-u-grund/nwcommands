n<-4; th<-as.numeric(strsplit(Sys.getenv("TH"),",")[[1]])
W<-list(rbind(c(0,1,0,0),c(0,0,1,0),c(1,0,0,0),c(0,0,0,0)),rbind(c(0,1,0,1),c(1,0,1,0),c(1,0,0,0),c(0,0,1,0)),rbind(c(0,0,1,1),c(1,0,0,0),c(0,1,0,1),c(1,0,0,0)))
dy<-which(diag(n)==0 & TRUE, arr.ind=FALSE); dyi<-as.matrix(expand.grid(i=1:n,j=1:n)); dyi<-dyi[dyi[,1]!=dyi[,2],]
nd<-nrow(dyi); S<-2^nd
kof<-function(i,j) which(dyi[,1]==i & dyi[,2]==j)
bits<-function(s) bitwAnd(bitwShiftR(s,0:(nd-1)),1)
toA<-function(s){A<-matrix(0,n,n); b<-bits(s); A[dyi]<-b; A}
idx<-function(A) sum(A[dyi]*2^(0:(nd-1)))
Pm<-matrix(0,S,S)
for(s in 0:(S-1)){A<-toA(s)
 for(i in 1:n){u<-numeric(n)
  for(j in 1:n) if(j!=i){sg<-if(A[i,j]==1) -1 else 1; u[j]<-th[1]*sg+th[2]*sg*A[j,i]}
  p<-exp(u)/sum(exp(u))
  for(j in 1:n){t<-if(j==i) s else bitwXor(s,2^(kof(i,j)-1)); Pm[s+1,t+1]<-Pm[s+1,t+1]+p[j]/n}}}
for(rho in c(1.5,4)){tot<-0
 for(ab in list(c(1,2),c(2,3))){v<-numeric(S); v[idx(W[[ab[1]]])+1]<-1; e0<-idx(W[[ab[2]]])+1; lam<-n*rho; num<-den<-0
  for(R in 0:300){w<-exp(-lam+R*log(lam)-lgamma(R+1))*v[e0]; num<-num+R*w; den<-den+w; v<-as.vector(v%*%Pm)}
  tot<-tot+num/den}
 cat("EXACT rho",rho,"E[R] total",tot,"\n")}
