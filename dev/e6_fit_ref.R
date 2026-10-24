# R ergm 4.12.0 reference fits with constraints (MPLE exact, MCMLE over several seeds), for test_nwergm_constr.do
suppressMessages(library(ergm))
rd <- function(tag){ l <- readLines("e6_basis.txt"); x <- strsplit(sub(paste0("^",tag," "),"",l[startsWith(l,paste0(tag," "))]),"")[[1]]; matrix(as.integer(x), ncol=sqrt(length(x)), byrow=TRUE) }
U <- network(rd("U"), directed=FALSE); D <- network(rd("D"), directed=TRUE)
Pn <- network(rd("UP"), directed=FALSE); Ua <- network(rd("UA"), directed=FALSE)
set.vertex.attribute(U,"g",c(1,1,1,1,2,2,2,2,3,3,3,3)); set.vertex.attribute(D,"g",c(1,1,1,1,1,2,2,2,2,2))
out <- character(0)
mple <- function(lab, nw, form, cons){
  f <- suppressWarnings(suppressMessages(ergm(form, constraints=cons, estimate="MPLE")))
  co <- coef(f); se <- sqrt(diag(vcov(f)))
  for(j in seq_along(co)) out <<- c(out, sprintf("MPLE|%s|%s|%.8f|%.8f", lab, names(co)[j], co[j], se[j]))
}
fU <- U ~ edges + nodematch("g") + triangle
mple("U_fixedas", U, fU, ~fixedas(present=Pn, absent=Ua))
mple("U_blockdiag", U, fU, ~blockdiag("g"))
mple("U_blocks", U, fU, ~blocks("g", levels2=-(1:3)))
mple("U_bd4", U, fU, ~bd(maxout=4))
mple("U_edges", U, fU, ~edges)
mple("U_degrees", U, fU, ~degrees)
fD <- D ~ edges + mutual + nodematch("g")
mple("D_blockdiag", D, fD, ~blockdiag("g"))
mple("D_odegrees", D, fD, ~odegrees)
mple("D_bd", D, fD, ~bd(maxout=4,maxin=4))
mcmle <- function(lab, nw, form, cons, seeds=1:4){
  for(s in seeds){ set.seed(s)
    f <- suppressWarnings(suppressMessages(ergm(form, constraints=cons, control=control.ergm(MCMC.samplesize=4096, MCMC.burnin=16384, MCMC.interval=1024, seed=s))))
    co <- coef(f); se <- sqrt(diag(vcov(f)))
    for(j in seq_along(co)) out <<- c(out, sprintf("MCMLE|%s|%s|%d|%.6f|%.6f", lab, names(co)[j], s, co[j], se[j])) }
}
mcmle("U_edges", U, U ~ edges + triangle, ~edges)
mcmle("U_degrees", U, U ~ edges + triangle, ~degrees)
mcmle("U_bd4", U, U ~ edges + triangle, ~bd(maxout=4))
mcmle("D_odegrees", D, D ~ edges + mutual, ~odegrees)
mcmle("D_idegrees", D, D ~ edges + mutual, ~idegrees)
writeLines(out, "e6_fit_ref.txt")
cat(length(out), "rows\n")
