# R ergm 4.12.0 reference distributions of statistics under constraints (simulate), for test_nwergm_constr.do
suppressMessages(library(ergm))
set.seed(20261023)
nsim <- 20000; burn <- 20000; intv <- 200
bstat <- function(x, nb=20){ b <- floor(length(x)/nb); bm <- sapply(1:nb, function(i) mean(x[((i-1)*b+1):(i*b)])); c(mean(x), sd(bm)/sqrt(nb)) }
out <- character(0)
runcase <- function(tag, nw, form, coef, cons, lab, extra=NULL){ message(tag, " ", lab)
  s <- suppressMessages(simulate(form, basis=nw, coef=coef, constraints=cons, nsim=nsim, output="stats",
        control=control.simulate.formula(MCMC.burnin=burn, MCMC.interval=intv)))
  for(j in seq_len(ncol(s))){ r <- bstat(s[,j]); out <<- c(out, sprintf("%s|%s|%s|%.6f|%.6f", tag, lab, colnames(s)[j], r[1], r[2])) }
}
mkU <- function(){ n <- 12; A <- matrix(0,n,n); A[upper.tri(A)] <- rbinom(n*(n-1)/2,1,0.3); A <- A+t(A); network(A, directed=FALSE) }
mkD <- function(){ n <- 10; A <- matrix(rbinom(n*n,1,0.25),n,n); diag(A) <- 0; network(A, directed=TRUE) }
U <- mkU(); D <- mkD()
set.vertex.attribute(U,"g",c(1,1,1,1,2,2,2,2,3,3,3,3)); set.vertex.attribute(D,"g",c(1,1,1,1,1,2,2,2,2,2))
# fixedas networks
Ue <- as.matrix(U, matrix.type="edgelist"); Pn <- network.initialize(12, directed=FALSE); add.edges(Pn, Ue[1:2,1], Ue[1:2,2])
Um <- as.matrix(U); ne <- which(upper.tri(Um) & Um==0, arr.ind=TRUE)[c(1,5),]; Ua <- network.initialize(12, directed=FALSE); add.edges(Ua, ne[,1], ne[,2])
writeLines(c(paste("U", paste(as.vector(t(as.matrix(U))), collapse="")), paste("D", paste(as.vector(t(as.matrix(D))), collapse="")),
             paste("UP", paste(as.vector(t(as.matrix(Pn))), collapse="")), paste("UA", paste(as.vector(t(as.matrix(Ua))), collapse=""))), "e6_basis.txt")
fU <- U ~ edges + triangle + kstar(2); cU <- c(-0.2, 0.15, 0.03)
runcase("U", U, fU, cU, ~edges, "edges")
runcase("U", U, fU, cU, ~degrees, "degrees")
runcase("U", U, fU, cU, ~degreedist, "degreedist")
runcase("U", U, fU, cU, ~bd(maxout=4), "bd4")
runcase("U", U, fU, cU, ~blockdiag("g"), "blockdiag")
runcase("U", U, fU, cU, ~blocks("g", levels2=-(1:3))+edges, "blocksedges")
runcase("U", U, fU, cU, ~fixedas(present=Pn, absent=Ua), "fixedas")
runcase("U", U, fU, cU, ~fixedas(present=Pn, absent=Ua)+bd(maxout=5), "fixedasbd")
fD <- D ~ edges + mutual + istar(2); cD <- c(-0.8, 0.5, 0.05)
runcase("D", D, fD, cD, ~edges, "edges")
runcase("D", D, fD, cD, ~odegrees, "odegrees")
runcase("D", D, fD, cD, ~idegrees, "idegrees")
runcase("D", D, fD, cD, ~idegreedist, "idegreedist")
runcase("D", D, fD, cD, ~degreedist, "degreedist")
runcase("D", D, fD, cD, ~bd(maxout=5,maxin=5), "bd44")
runcase("D", D, fD, cD, ~blockdiag("g"), "blockdiag")
writeLines(out, "e6_sim_ref.txt")
cat(length(out), "rows\n")
