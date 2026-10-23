# RSiena: two dependent networks (s50 friendship 'net' + the second network 'adv' of dev/saom_rsiena_mn.R) and the behavior alcohol 'beh' (s50a).
# BEHEFF = behavior effects of both networks, "shortName:first:second:parm ..." (e.g. "FFDeg:net:adv:0 indegMixedPop:adv:net:0").
# EXTRA = further effects of the behavior ("shortName:interaction1" ...), e.g. "avAlt:net". SEEDS = number of seeds. Prints targets and estimates.
suppressMessages(library(RSiena))
Bm <- lapply(1:3, function(w) as.matrix(read.csv(sprintf("dev/saom_mn_b%d.csv", w))))
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
adv <- sienaDependent(array(unlist(Bm), dim = c(50, 50, 3)))
# MISS=1: some behavior values missing (dev/saom_rsiena_mnbeh_miss.csv: a1..a3 with NA, m1..m3 the 0/1 missing indicators)
if (Sys.getenv("MISS", "") == "1") {
	if (!file.exists("dev/saom_rsiena_mnbeh_miss.csv")) {
		a <- s50a; a[c(3, 17), 1] <- NA; a[c(8, 30), 2] <- NA; a[c(3, 12, 45), 3] <- NA
		write.csv(data.frame(a1 = a[, 1], a2 = a[, 2], a3 = a[, 3], m1 = is.na(a[, 1]) * 1, m2 = is.na(a[, 2]) * 1, m3 = is.na(a[, 3]) * 1, s1 = s50s[, 1]), "dev/saom_rsiena_mnbeh_miss.csv", row.names = FALSE, na = "")
	}
	dm <- read.csv("dev/saom_rsiena_mnbeh_miss.csv")
	s50a <- as.matrix(dm[, c("a1", "a2", "a3")])
}
beh <- sienaDependent(s50a, type = "behavior")
smoke1 <- coCovar(s50s[, 1])
cov1 <- coCovar(as.numeric(((1:50) * 7) %% 5))
d <- sienaDataCreate(net, adv, beh, smoke1, cov1)
e <- getEffects(d)
e <- includeEffects(e, recip, name = "net"); e <- includeEffects(e, recip, name = "adv")
for (x in strsplit(Sys.getenv("EXTRA", "avAlt:net"), " ")[[1]]) {
	# shortName[@endow|@creation][:interaction1[:interaction2[:parm]]]
	p <- strsplit(x, ":")[[1]]
	ty <- ""; if (grepl("@", p[1])) { ty <- sprintf(", type = '%s'", sub(".*@", "", p[1])); p[1] <- sub("@.*", "", p[1]) }
	i1 <- if (length(p) >= 2) sprintf(", interaction1 = '%s'", p[2]) else ""
	i2 <- if (length(p) >= 3) sprintf(", interaction2 = '%s'", p[3]) else ""
	e <- eval(parse(text = sprintf("includeEffects(e, %s, name = 'beh'%s%s%s)", p[1], i1, i2, ty)))
	if (length(p) >= 4) { u <- unclass(e); k <- which(u$shortName == p[1] & u$include & u$name == "beh" & u$interaction1 == p[2]); e$parm[k] <- as.numeric(p[4]) }
}
# EXCL = behavior effects whose evaluation part is dropped (the endowment / creation split replaces it): "linear quad avAlt:net"
for (x in strsplit(Sys.getenv("EXCL", ""), " ")[[1]]) {
	if (x == "") next
	p <- strsplit(x, ":")[[1]]
	i1 <- if (length(p) >= 2) sprintf(", interaction1 = '%s'", p[2]) else ""
	e <- eval(parse(text = sprintf("includeEffects(e, %s, name = 'beh'%s, include = FALSE)", p[1], i1)))
}
for (x in strsplit(Sys.getenv("BEHEFF", ""), " ")[[1]]) {
	if (x == "") next
	p <- strsplit(x, ":")[[1]]
	e <- eval(parse(text = sprintf("includeEffects(e, %s, name = 'beh', interaction1 = '%s', interaction2 = '%s')", p[1], p[2], p[3])))
	if (as.numeric(p[4]) > 0) { u <- unclass(e); k <- which(u$shortName == p[1] & u$include & u$name == "beh" & u$interaction1 == p[2]); e$parm[k] <- as.numeric(p[4]) }
}
# INTER = "effect1[:i1]+effect2[:i2][+effect3[:i3]]" ... : user-defined interactions of behavior effects of the model (includeInteraction, name 'beh')
for (x in strsplit(Sys.getenv("INTER", ""), " ")[[1]]) {
	if (x == "") next
	cp <- strsplit(x, "+", fixed = TRUE)[[1]]
	nmv <- sapply(cp, function(y) strsplit(y, ":")[[1]][1]); i1 <- sapply(cp, function(y) { q <- strsplit(y, ":")[[1]]; if (length(q) > 1) q[2] else "" })
	e <- eval(parse(text = sprintf("includeInteraction(e, %s, name = 'beh', interaction1 = c(%s))", paste(nmv, collapse = ", "), paste(sprintf("'%s'", i1), collapse = ", "))))
}
# NETEFF = "shortName:network:interaction1" network effects with the behavior as covariate
for (x in strsplit(Sys.getenv("NETEFF", ""), " ")[[1]]) {
	if (x == "") next
	p <- strsplit(x, ":")[[1]]
	e <- eval(parse(text = sprintf("includeEffects(e, %s, name = '%s', interaction1 = '%s')", p[1], p[2], p[3])))
}
print(as.data.frame(e)[e$include, c("name", "shortName", "interaction1", "interaction2", "parm", "type")])
for (sd in 1:as.numeric(Sys.getenv("SEEDS", "2"))) {
	ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE)
	cat("RSIENA seed", sd, "targets:", paste(round(ans$targets, 3), collapse = " "), "\n")
	if (sd == 1) cat("RSIENA names:", paste(ans$effects$effectName, collapse = " | "), "\n")
	cat("RSIENA seed", sd, "est:", paste(round(ans$theta, 3), collapse = " "), "\n")
	cat("RSIENA seed", sd, "se:", paste(round(sqrt(diag(ans$covtheta)), 3), collapse = " "), "\n")
}
