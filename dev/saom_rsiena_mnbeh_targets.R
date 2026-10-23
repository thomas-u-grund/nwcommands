# RSiena observed statistics (targets) of behavior effects in a model with two networks + a behavior; no estimation. Same data as dev/saom_rsiena_mnbeh.R.
# EXTRA = "shortName:interaction1[:interaction2[:parm]] ..." (name = beh). Prints one line "TARGET <effectName> <value>" per effect.
suppressMessages(library(RSiena))
Bm <- lapply(1:3, function(w) as.matrix(read.csv(sprintf("dev/saom_mn_b%d.csv", w))))
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
adv <- sienaDependent(array(unlist(Bm), dim = c(50, 50, 3)))
beh <- sienaDependent(s50a, type = "behavior")
smoke1 <- coCovar(s50s[, 1])
cov1 <- coCovar(as.numeric(((1:50) * 7) %% 5))
d <- sienaDataCreate(net, adv, beh, smoke1, cov1)
e <- getEffects(d)
for (x in strsplit(Sys.getenv("EXTRA", ""), " ")[[1]]) {
	if (x == "") next
	p <- strsplit(x, ":")[[1]]
	ty <- ""; if (grepl("@", p[1])) { ty <- sprintf(", type = '%s'", sub(".*@", "", p[1])); p[1] <- sub("@.*", "", p[1]) }
	i1 <- if (length(p) >= 2) sprintf(", interaction1 = '%s'", p[2]) else ""
	i2 <- if (length(p) >= 3 && p[3] != "") sprintf(", interaction2 = '%s'", p[3]) else ""
	e <- eval(parse(text = sprintf("includeEffects(e, %s, name = 'beh'%s%s%s)", p[1], i1, i2, ty)))
	if (length(p) >= 4) { u <- unclass(e); k <- which(u$shortName == p[1] & u$include & u$name == "beh" & u$interaction1 == p[2]); e$parm[k] <- as.numeric(p[4]) }
}
# NETEXTRA = "shortName:network:interaction1[:parm]" network effects (e.g. the dependent behavior as the covariate)
for (x in strsplit(Sys.getenv("NETEXTRA", ""), " ")[[1]]) {
	if (x == "") next
	p <- strsplit(x, ":")[[1]]
	e <- eval(parse(text = sprintf("includeEffects(e, %s, name = '%s', interaction1 = '%s')", p[1], p[2], p[3])))
	if (length(p) >= 4) { u <- unclass(e); k <- which(u$shortName == p[1] & u$include & u$name == p[2]); e$parm[k] <- as.numeric(p[4]) }
}
ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = 1, n3 = 10, nsub = 0, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE)
nm <- ans$effects$effectName; tg <- ans$targets
for (k in seq_along(nm)) cat("TARGET", gsub(" ", "_", nm[k]), round(tg[k], 4), "\n")
