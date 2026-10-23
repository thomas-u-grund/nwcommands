# RSiena observed statistics of the network effects with the dependent behavior as covariate, one effect per model, for network NET ('net' or 'adv'); prints "RT <effect> <value>"
suppressMessages(library(RSiena))
Bm <- lapply(1:3, function(w) as.matrix(read.csv(sprintf("dev/saom_mn_b%d.csv", w))))
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
adv <- sienaDependent(array(unlist(Bm), dim = c(50, 50, 3)))
beh <- sienaDependent(s50a, type = "behavior")
d <- sienaDataCreate(net, adv, beh)
NET <- Sys.getenv("NET", "net")
for (ef in strsplit(Sys.getenv("EFFS"), " ")[[1]]) {
	e <- getEffects(d)
	e <- eval(parse(text = sprintf("includeEffects(e, %s, name = '%s', interaction1 = 'beh')", ef, NET)))
	if (ef == "outXMore") { u <- unclass(e); e$parm[which(u$shortName == ef & u$include)] <- 1 }
	r <- try(siena07(sienaAlgorithmCreate(projname = NULL, seed = 1, n3 = 10, nsub = 0, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE), silent = TRUE)
	if (inherits(r, "try-error")) { cat("RT", ef, "ERROR\n"); next }
	k <- which(r$effects$shortName == ef & r$effects$name == NET)
	cat("RT", ef, round(r$targets[k], 4), "\n")
}
