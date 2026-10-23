# NON-DIRECTED network (sym_w1..3.csv, 50 actors) with the dependent behavior (dev/saom_netfx_symbeh.csv, values 0-9) as the covariate: degAbsDiffX, degPosDiffX, higher;
# prints RSiena's targets and estimates with standard errors for 2 seeds; counterpart dev/saom_rsiena_netfx_sym.do
library(RSiena)
W <- lapply(1:3, function(w) as.matrix(read.csv(sprintf("sym_w%d.csv", w))))
net <- sienaDependent(array(unlist(W), dim = c(50, 50, 3)))
beh <- sienaDependent(as.matrix(read.csv("dev/saom_netfx_symbeh.csv")), type = "behavior")
d <- sienaDataCreate(net, beh)
efs <- strsplit(Sys.getenv("EFFS", "degAbsDiffX degPosDiffX higher"), " ")[[1]]
for (ef in efs) {
	e <- includeEffects(getEffects(d), avAlt, name = "beh", interaction1 = "net")
	e <- eval(parse(text = sprintf("includeEffects(e, %s, interaction1 = 'beh')", ef)))
	for (sd in 1:2) {
		ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE)
		cat("RSIENA", ef, "seed", sd, ": targets", round(ans$targets, 3), "\n")
		cat("RSIENA", ef, "seed", sd, ": theta", round(ans$theta, 3), "se", round(sqrt(diag(ans$covtheta)), 3), "\n")
	}
}
