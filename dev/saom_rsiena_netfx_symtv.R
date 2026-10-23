# NON-DIRECTED network (sym_w1..3.csv, 50 actors): RSiena's higher with a changing covariate (_tv.csv, varCovar) and XRecip with a changing dyadic covariate
# (dev/saom_netfx_symdy1.csv, ...2.csv; varDyadCovar). Prints the targets (observed statistics) and estimates with standard errors for 2 seeds;
# counterpart dev/saom_rsiena_netfx_symtv.do. Both effects are collinear with other statistics of a non-directed network (higher counts every tie once, as density):
# RSiena's standard errors are missing / huge.
library(RSiena)
W <- lapply(1:3, function(w) as.matrix(read.csv(sprintf("sym_w%d.csv", w))))
net <- sienaDependent(array(unlist(W), dim = c(50, 50, 3)))
tv <- varCovar(as.matrix(read.csv("_tv.csv")[, c("v1", "v2")]))
D <- array(unlist(lapply(1:2, function(p) as.matrix(read.csv(sprintf("dev/saom_netfx_symdy%d.csv", p))))), dim = c(50, 50, 2))
dy <- varDyadCovar(D)
d <- sienaDataCreate(net, tv, dy)
for (ef in c("higher", "XRecip")) {
	e <- getEffects(d)
	if (ef == "higher") e <- includeEffects(e, higher, interaction1 = "tv") else e <- includeEffects(e, XRecip, interaction1 = "dy")
	for (sd in 1:2) {
		ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE)
		if (sd == 1) cat("RTGT", ef, round(ans$targets, 3), "\n")
		cat("RSIENA", ef, "seed", sd, ": theta", round(ans$theta, 3), "se", round(sqrt(diag(ans$covtheta)), 3), "\n")
	}
}
