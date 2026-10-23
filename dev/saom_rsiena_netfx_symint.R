# NON-DIRECTED network (sym_w1..3.csv, 50 actors): includeInteraction of egoX and altX of a constant covariate (_tv.csv, column v1); targets and estimates (2 seeds);
# counterpart dev/saom_rsiena_netfx_symint.do
library(RSiena)
W <- lapply(1:3, function(w) as.matrix(read.csv(sprintf("sym_w%d.csv", w))))
net <- sienaDependent(array(unlist(W), dim = c(50, 50, 3)))
cv <- coCovar(read.csv("_tv.csv")$v1)
d <- sienaDataCreate(net, cv)
e <- getEffects(d)
e <- includeEffects(e, egoX, altX, interaction1 = "cv")
e <- includeInteraction(e, egoX, altX, interaction1 = c("cv", "cv"))
for (sd in 1:2) {
	ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE)
	if (sd == 1) cat("RTGT", round(ans$targets, 3), "\n")
	cat("RSIENA seed", sd, ": theta", round(ans$theta, 3), "se", round(sqrt(diag(ans$covtheta)), 3), "\n")
}
