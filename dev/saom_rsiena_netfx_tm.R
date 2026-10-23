# two-mode (bipartite) 40 x 20 data of saom_rsiena_twomode_sim.R: a bipartite dyadic covariate X, and interactions (includeInteraction) of network effects.
# Prints RSiena's targets (observed statistics, sum over the 2 periods) and estimates for 2 seeds; counterpart dev/saom_rsiena_netfx_tm.do
library(RSiena)
W <- lapply(1:3, function(w) as.matrix(read.csv(sprintf("dev/saom_twomode_w%d.csv", w))))
A <- sienaNodeSet(40, nodeSetName = "A"); B <- sienaNodeSet(20, nodeSetName = "B")
dep <- sienaDependent(array(unlist(W), dim = c(40, 20, 3)), type = "bipartite", nodeSet = c("A", "B"))
c1 <- coCovar(read.csv("dev/saom_twomode_cvA.csv")$ega, nodeSet = "A"); c2 <- coCovar(read.csv("dev/saom_twomode_cvB.csv")$altb, nodeSet = "B")
d1 <- coDyadCovar(as.matrix(read.csv("dev/saom_netfx_dyad.csv")), nodeSets = c("A", "B"))
dat <- sienaDataCreate(dep, c1, c2, d1, nodeSets = list(A, B))
mk <- function(spec) {
	e <- getEffects(dat)
	if (spec == "dyadX") { e <- includeEffects(e, inPopSqrt); e <- includeEffects(e, X, interaction1 = "d1") }
	if (spec == "intEgoAlt") { e <- includeEffects(e, egoX, interaction1 = "c1"); e <- includeEffects(e, altX, interaction1 = "c2"); e <- includeInteraction(e, egoX, altX, interaction1 = c("c1", "c2")) }
	e
}
for (spec in strsplit(Sys.getenv("SPECS", "dyadX intEgoAlt"), " ")[[1]]) {
	e <- mk(spec)
	fx <- e; xx <- unclass(fx); fx$fix[xx$include & xx$type == "eval"] <- TRUE
	tg <- siena07(sienaAlgorithmCreate(projname = NULL, seed = 1, n3 = 20, nsub = 0, cond = FALSE), data = dat, effects = fx, batch = TRUE, silent = TRUE)
	cat("RTGT", spec, round(tg$targets, 3), "\n")
	for (sd in 1:2) {
		ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4, cond = FALSE), data = dat, effects = e, batch = TRUE, silent = TRUE)
		cat("RSIENA", spec, "seed", sd, ": est", round(c(ans$rate, ans$theta), 3), "se", round(sqrt(diag(ans$covtheta)), 3), "\n")
	}
}
