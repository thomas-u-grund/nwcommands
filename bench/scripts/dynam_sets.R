# The effect sets of the nwdynam vs goldfish benchmark: goldfish formula right-hand side and sub-model.
dsets <- list(
  C1 = list(sub = "choice", rhs = "inertia + recip + indeg"),
  C2 = list(sub = "choice", rhs = "inertia + recip + indeg + same(actors$group)"),
  C3 = list(sub = "choice", rhs = "inertia + trans"),
  R1 = list(sub = "rate",   rhs = "indeg + outdeg"),
  R2 = list(sub = "rate",   rhs = "indeg + outdeg + ego(actors$x)"))
