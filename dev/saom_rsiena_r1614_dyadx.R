# RSiena 1.6.13/1.6.14: WXX for two-mode networks (dyadFirstBipartiteObjective), XWX/XWX1/XWX2 (dyadSecondBipartiteObjective) and the new WXZX (one-mode and two-mode).
# Two-mode data: the 40 x 20 waves of saom_rsiena_twomode_sim.R (dev/saom_twomode_w*.csv), W among the 40 actors, Z among the 20 events; one-mode: s50 with W = dev/saom_rsiena_dyadx_w.csv and Z below.
# Prints "RTGT <spec> <targets>" (observed statistics) and "RSIENA <spec> seed <s> : est ..." (two seeds).
suppressMessages(library(RSiena))
set.seed(2026)
mk <- function(n, p) { M <- matrix(sample(0:2, n * n, replace = TRUE, prob = c(1 - p, p * 0.6, p * 0.4)), n, n); diag(M) <- 0; M }
W40 <- mk(40, 0.12); Z20 <- mk(20, 0.2); Z50 <- mk(50, 0.1)
write.csv(W40, "dev/saom_r1614_w40.csv", row.names = FALSE); write.csv(Z20, "dev/saom_r1614_z20.csv", row.names = FALSE); write.csv(Z50, "dev/saom_r1614_z50.csv", row.names = FALSE)
for (w in 1:3) write.csv(get(paste0("s50", w)), sprintf("dev/saom_r1614_s50_w%d.csv", w), row.names = FALSE)
W50 <- as.matrix(read.csv("dev/saom_rsiena_dyadx_w.csv"))
A <- sienaNodeSet(40, nodeSetName = "A"); B <- sienaNodeSet(20, nodeSetName = "B")
tw <- lapply(1:3, function(w) as.matrix(read.csv(sprintf("dev/saom_twomode_w%d.csv", w))))
dep <- sienaDependent(array(unlist(tw), dim = c(40, 20, 3)), type = "bipartite", nodeSet = c("A", "B"))
cW <- coDyadCovar(W40, nodeSets = c("A", "A")); cZ <- coDyadCovar(Z20, nodeSets = c("B", "B"))
dat2 <- sienaDataCreate(dep, cW, cZ, nodeSets = list(A, B))
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
dW <- coDyadCovar(W50); dZ <- coDyadCovar(Z50)
dat1 <- sienaDataCreate(net, dW, dZ)
run <- function(tag, dat, base, ef, args) {
	e <- eval(parse(text = sprintf("includeEffects(base, %s, %s)", ef, args)))
	fx <- e; xx <- unclass(fx); fx$fix[xx$include & xx$type == "eval"] <- TRUE
	tg <- try(siena07(sienaAlgorithmCreate(projname = NULL, seed = 1, n3 = 20, nsub = 0, cond = FALSE), data = dat, effects = fx, batch = TRUE, silent = TRUE), silent = TRUE)
	if (inherits(tg, "try-error")) { cat("RTGT", tag, "ERROR", gsub("\n", " ", tg), "\n"); return(invisible()) }
	cat("RTGT", tag, round(tg$targets, 4), "\n")
	for (sd in 1:2) {
		r <- try({ ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4, cond = FALSE), data = dat, effects = e, batch = TRUE, silent = TRUE)
			sprintf("est %s se %s", paste(round(c(ans$rate, ans$theta), 3), collapse = " "), paste(round(ans$se, 3), collapse = " ")) }, silent = TRUE)
		cat("RSIENA", tag, "seed", sd, ":", gsub("\n", " ", r), "\n")
	}
}
b2 <- getEffects(dat2)
run("TM_WXX", dat2, b2, "WXX", "interaction1 = 'cW'")
run("TM_XWX", dat2, b2, "XWX", "interaction1 = 'cZ'")
run("TM_XWX1", dat2, b2, "XWX1", "interaction1 = 'cZ'")
run("TM_XWX2", dat2, b2, "XWX2", "interaction1 = 'cZ'")
run("TM_WXZX", dat2, b2, "WXZX", "interaction1 = 'cW', interaction2 = 'cZ'")
b1 <- includeEffects(getEffects(dat1), recip)
run("OM_WXX", dat1, b1, "WXX", "interaction1 = 'dW'")
run("OM_WXZX", dat1, b1, "WXZX", "interaction1 = 'dW', interaction2 = 'dZ'")
run("OM_WXZX_swap", dat1, b1, "WXZX", "interaction1 = 'dZ', interaction2 = 'dW'")
# a non-directed network (the symmetric waves of dev/saom_rsiena_symmulti_w*.csv, 50 actors): WXZX and WXX
sw <- lapply(1:3, function(k) as.matrix(read.csv(sprintf("dev/saom_rsiena_symmulti_w%d.csv", k))))
snet <- sienaDependent(array(unlist(sw), dim = c(50, 50, 3)))
dat3 <- sienaDataCreate(snet, dW, dZ)
b3 <- getEffects(dat3)
run("SYM_WXZX", dat3, b3, "WXZX", "interaction1 = 'dW', interaction2 = 'dZ'")
run("SYM_WXX", dat3, b3, "WXX", "interaction1 = 'dW'")
