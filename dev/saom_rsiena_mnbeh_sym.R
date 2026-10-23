# RSiena: directed network 'net' (s50 friendship), a NON-DIRECTED second network 'sym' (sym_w1..3.csv) and the behavior 'beh' (s50a). Behavior effects of both networks (first = net, second = sym).
# BEHEFF = "shortName:first:second" ... SEEDS. Prints targets and estimates.
suppressMessages(library(RSiena))
W <- lapply(1:3, function(w) as.matrix(read.csv(sprintf("sym_w%d.csv", w))))
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
sym <- sienaDependent(array(unlist(W), dim = c(50, 50, 3)))
beh <- sienaDependent(s50a, type = "behavior")
d <- sienaDataCreate(net, sym, beh)
e <- getEffects(d)
e <- includeEffects(e, recip, name = "net")
e <- includeEffects(e, avAlt, name = "beh", interaction1 = "net")
for (x in strsplit(Sys.getenv("BEHEFF", ""), " ")[[1]]) {
	if (x == "") next
	p <- strsplit(x, ":")[[1]]
	e <- eval(parse(text = sprintf("includeEffects(e, %s, name = 'beh', interaction1 = '%s', interaction2 = '%s')", p[1], p[2], p[3])))
}
# the density of the non-directed network is held at 0.045 (a free fit of it is not identified well enough in nwsaom multinet)
if (Sys.getenv("FIXSYM", "") == "1") e <- setEffect(e, density, name = "sym", fix = TRUE, test = FALSE, initialValue = 0.045)
for (sd in 1:as.numeric(Sys.getenv("SEEDS", "2"))) {
	ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE)
	if (sd == 1) cat("RSIENA names:", paste(ans$effects$effectName, collapse = " | "), "\n")
	cat("RSIENA seed", sd, "targets:", paste(round(ans$targets, 3), collapse = " "), "\n")
	cat("RSIENA seed", sd, "est:", paste(round(ans$theta, 3), collapse = " "), "\n")
	cat("RSIENA seed", sd, "se:", paste(round(sqrt(diag(ans$covtheta)), 3), collapse = " "), "\n")
}
