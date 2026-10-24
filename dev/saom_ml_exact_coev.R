# exact observed-data score of a 3-actor network + behavior (levels 0..2) model, for the Fisher-identity test of the chain machinery
n<-3
W<-list(rbind(c(0,1,0),c(0,0,1),c(0,0,0)),rbind(c(0,1,1),c(1,0,0),c(0,0,0)),rbind(c(0,0,1),c(1,0,1),c(0,1,0)))
Z<-list(c(0,1,1),c(1,1,2),c(1,2,2))
m<-mean(unlist(Z))
dyi<-as.matrix(expand.grid(i=1:n,j=1:n)); dyi<-dyi[dyi[,1]!=dyi[,2],]
nd<-nrow(dyi); NS<-2^nd; NZ<-3^n; S<-NS*NZ
kof<-function(i,j) which(dyi[,1]==i & dyi[,2]==j)
toA<-function(s){A<-matrix(0,n,n); A[dyi]<-bitwAnd(bitwShiftR(s,0:(nd-1)),1); A}
toZ<-function(c){z<-numeric(n); for(i in 1:n){z[i]<-c%%3; c<-c%/%3}; z}
idxA<-function(A) sum(A[dyi]*2^(0:(nd-1)))
idxZ<-function(z) sum(z*3^(0:(n-1)))
state<-function(A,z) idxA(A)+NS*idxZ(z)+1
Pmat<-function(th,rho){ # rho = c(rhoN, rhoB) for the period
 Pm<-matrix(0,S,S); srho<-sum(rho)
 for(c in 0:(NZ-1)){z<-toZ(c)
  for(s in 0:(NS-1)){A<-toA(s); from<-s+NS*c+1
   for(i in 1:n){
    u<-numeric(n)
    for(j in 1:n) if(j!=i){sg<-if(A[i,j]==1) -1 else 1; u[j]<-th[1]*sg+th[2]*sg*A[j,i]+th[3]*sg*(z[i]-3.1133333)}
    p<-exp(u)/sum(exp(u))
    for(j in 1:n){to<-if(j==i) from else bitwXor(s,2^(kof(i,j)-1))+NS*c+1; Pm[from,to]<-Pm[from,to]+(rho[1]/srho)*p[j]/n}
    # behavior
    od<-sum(A[i,]); avg<-if(od>0) sum(A[i,]*z)/od-m else 0
    cand<-c(); ub<-c()
    for(d in c(-1,0,1)){ if(z[i]+d<0||z[i]+d>2) next
      ch<-if(d==0) 0 else th[4]*d+th[5]*(2*(z[i]-m)+d)*d+th[6]*d*avg
      cand<-c(cand,d); ub<-c(ub,ch)}
    pb<-exp(ub)/sum(exp(ub))
    for(q in seq_along(cand)){z2<-z; z2[i]<-z[i]+cand[q]; to<-s+NS*idxZ(z2)+1; Pm[from,to]<-Pm[from,to]+(rho[2]/srho)*pb[q]/n}
   }}}
 Pm}
logL<-function(th,rhoN,rhoB){tot<-0
 for(p in 1:2){Pm<-Pmat(th,c(rhoN[p],rhoB[p])); v<-numeric(S); v[state(W[[p]],Z[[p]])]<-1; e0<-state(W[[p+1]],Z[[p+1]]); lam<-n*(rhoN[p]+rhoB[p]); L<-0
  for(R in 0:150){w<-exp(-lam+R*log(lam)-lgamma(R+1))*v[e0]; L<-L+w; v<-as.vector(v%*%Pm)}
  tot<-tot+log(L)}
 tot}
th0<-c(-0.8,0.5,0.3,0.4,-0.3,0.6); rN<-c(3,3); rB<-c(2,2); h<-1e-4
g<-numeric(10)
for(k in 1:6){a<-th0;b<-th0;a[k]<-a[k]+h;b[k]<-b[k]-h; g[k]<-(logL(a,rN,rB)-logL(b,rN,rB))/(2*h)}
for(k in 1:2){a<-rN;b<-rN;a[k]<-a[k]+h;b[k]<-b[k]-h; g[6+k]<-(logL(th0,a,rB)-logL(th0,b,rB))/(2*h)}
for(k in 1:2){a<-rB;b<-rB;a[k]<-a[k]+h;b[k]<-b[k]-h; g[8+k]<-(logL(th0,rN,a)-logL(th0,rN,b))/(2*h)}
cat("EXACTSCORE",g,"\n")
cat("MEAN",m,"\n")
