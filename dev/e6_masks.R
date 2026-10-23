# Free-dyad masks of R ergm 4.12.0 constraints, for test_nwergm_constr.do
suppressMessages(library(ergm))
g <- c(1,1,2,2,3,3); h <- c(1,2,1,2,1,2); e <- c(0,0,1,0,0,0)
fx <- matrix(0,6,6); fx[1,2] <- 1; fx[2,1] <- 1; fx[3,5] <- 1; fx[5,3] <- 1
specs <- list(
 u_blocks_all  = ~blocks("g", levels2=TRUE),
 u_blocks_neg  = ~blocks("g", levels2=-(1:3)),
 u_blockdiag   = ~blockdiag("g"),
 u_blockdiag_split = ~blockdiag("h", noncontig="split"),
 u_ego         = ~egocentric("e"),
 u_mix         = ~blocks("g", levels2=TRUE) - blockdiag("g"),
 u_and         = ~blockdiag("g") + egocentric("e")
)
for (d in c(FALSE, TRUE)) {
  nw <- network.initialize(6, directed=d)
  set.vertex.attribute(nw,"g",g); set.vertex.attribute(nw,"h",h); set.vertex.attribute(nw,"e",e)
  for (nm in names(specs)) {
    if (d) nm2 <- sub("^u_","d_",nm) else nm2 <- nm
    m <- ergm:::as.rlebdm(ergm:::ergm_conlist.formula(specs[[nm]], nw)) |> as.matrix()
    m <- m*1
    if (!d) m <- m + t(m)
    cat(nm2, ":", paste(as.vector(t(m)), collapse=""), "\n")
  }
}
