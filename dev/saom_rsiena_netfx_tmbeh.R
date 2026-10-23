# two-mode (bipartite) 40 x 20 data of saom_rsiena_twomode_sim.R with a co-evolving behavior of the actors (dev/saom_netfx_tmbeh.csv): the network effects
# crossXOutAct, avGroupEgoX and totGroupEgoX with the dependent behavior as the covariate (interaction1 = "beh"). RSiena's targets and estimates for 2 seeds;
# counterpart dev/saom_rsiena_netfx_tmbeh.do
library(RSiena)
W <- lapply(1:3, function(w) as.matrix(read.csv(sprintf("dev/saom_twomode_w%d.csv", w))))
A <- sienaNodeSet(40, nodeSetName = "A"); B <- sienaNodeSet(20, nodeSetName = "B")
dep <- sienaDependent(array(unlist(W), dim = c(40, 20, 3)), type = "bipartite", nodeSet = c("A", "B"))
beh <- sienaDependent(as.matrix(read.csv("dev/saom_netfx_tmbeh.csv")), type = "behavior", nodeSet = "A")
dat <- sienaDataCreate(dep, beh, nodeSets = list(A, B))
for (ef in strsplit(Sys.getenv("EFFS", "crossXOutAct avGroupEgoX totGroupEgoX"), " ")[[1]]) {
	e <- getEffects(dat)
	e <- eval(parse(text = sprintf("includeEffects(e, %s, interaction1 = 'beh', name = 'dep')", ef)))
	for (sd in 1:2) {
		ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4, cond = FALSE), data = dat, effects = e, batch = TRUE, silent = TRUE)
		if (sd == 1) cat("RTGT", ef, round(ans$targets, 3), "\n")
		cat("RSIENA", ef, "seed", sd, ": theta", round(ans$theta, 3), "se", round(sqrt(diag(ans$covtheta)), 3), "\n")
	}
}
