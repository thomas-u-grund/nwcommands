# (as saom_rsiena_r1614.R with 8 actors and 14 events: more events than actors, for the effects that read the covariate of the events with an actor index) (effects new or changed in 1.6.12-1.6.14: toU, WXX/WXZX, regrouped covariate x network effects). Based on saom_rsiena_mnnet.R: cross-network effects with a two-mode member and with non-directed networks of
# nwsaom multinet, on deterministic networks (formulas, no random numbers) that the test builds identically. Prints "REF group token value".
suppressMessages(library(RSiena))
nA <- 8; nE <- 14
ii <- function(r, c) matrix(rep(1:r, c), r, c)
jj <- function(r, c) matrix(rep(1:c, each = r), r, c)
x2 <- function(a, b) (a + b) %% 2
Bw <- lapply(1:3, function(w) { I <- ii(nA, nE); J <- jj(nA, nE); x2(((I * 7 + J * 13 + I * J) %% 11 < 3) * 1, ((I * 3 + J * 5 + w * (I + J)) %% 23 == 0) * 1) })
Fw <- lapply(1:3, function(w) { I <- ii(nA, nA); J <- jj(nA, nA); M <- x2(((I * 5 + J * 11 + I * J) %% 17 < 3) * 1, ((I * 2 + J * 3 + w * (I + 2 * J)) %% 29 == 0) * 1); diag(M) <- 0; M })
Hw <- lapply(1:3, function(w) { I <- ii(nA, nA); J <- jj(nA, nA); M <- x2(((I * 3 + J * 7 + 2 * I * J) %% 19 < 3) * 1, ((I * 4 + J * 5 + w * (I + J)) %% 31 == 0) * 1); diag(M) <- 0; M })
Sw <- lapply(1:3, function(w) { I <- ii(nA, nA); J <- jj(nA, nA); M <- x2((((I + J) * 3 + I * J) %% 13 < 2) * 1, (((I + J) * 2 + w * (I * J)) %% 27 == 0) * 1); diag(M) <- 0; M })
cvv <- (((1:nA) * 3) %% 4) + 1
dyv <- ((ii(nA, nA) * 3 + jj(nA, nA) * 5) %% 4) * 1; diag(dyv) <- 0
dyEv <- ((ii(nA, nE) * 2 + jj(nA, nE) * 7) %% 4) * 1
arr <- function(L, r, c) array(unlist(L), dim = c(r, c, 3))
mk <- function(nm) switch(nm,
	Fd = sienaDependent(arr(Fw, nA, nA), nodeSet = "A"), Hd = sienaDependent(arr(Hw, nA, nA), nodeSet = "A"), Sd = sienaDependent(arr(Sw, nA, nA), nodeSet = "A"),
	Bd = sienaDependent(arr(Bw, nA, nE), type = "bipartite", nodeSet = c("A", "E")))
cvEv <- (((1:nE) * 3) %% 4) + 1
cvE <- coCovar(cvEv, nodeSet = "E"); cv <- coCovar(cvv, nodeSet = "A"); dy <- coDyadCovar(dyv, nodeSets = c("A", "A")); dyE <- coDyadCovar(dyEv, nodeSets = c("A", "E"))
ns <- list(A = sienaNodeSet(nA, "A"), E = sienaNodeSet(nE, "E"))
run <- function(group, dep, oth, tokens) {
	# one-mode networks first (RSiena orders the data that way); the dependent network is the one that gets the cross effect
	nets <- list(Fd = NULL, Hd = NULL, Sd = NULL, Bd = NULL)
	nms <- c(dep, oth); nms <- c(nms[nms != "Bd"], nms[nms == "Bd"])
	args <- c(lapply(nms, mk), list(cv, dy, dyE), if ("Bd" %in% nms) list(cvE)); names(args) <- c(nms, "cv", "dy", "dyE", if ("Bd" %in% nms) "cvE")
	args$nodeSets <- ns
	d <- do.call(sienaDataCreate, args)
	for (tk in tokens) {
		p <- strsplit(tk, ":")[[1]]; ef <- p[1]; parm <- if (length(p) >= 2 && p[2] != "") p[2] else NA; i2 <- if (length(p) >= 3) p[3] else ""; i1 <- if (length(p) >= 4) p[4] else oth
		e <- getEffects(d)
		e <- if (i2 == "") eval(parse(text = sprintf("includeEffects(e, `%s`, name = '%s', interaction1 = '%s')", ef, dep, i1)))
			else eval(parse(text = sprintf("includeEffects(e, `%s`, name = '%s', interaction1 = '%s', interaction2 = '%s')", ef, dep, i1, i2)))
		if (!is.na(parm)) { x <- unclass(e); k <- which(x$shortName == ef & x$include & x$name == dep); e$parm[k] <- as.numeric(parm) }
		r <- try(siena07(sienaAlgorithmCreate(projname = NULL, seed = 1, n3 = 50, nsub = 0, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE), silent = TRUE)
		if (inherits(r, "try-error")) { cat("REF", group, tk, "ERROR\n"); next }
		# the cross statistic: the last effect of the dependent network
		pos <- which(unclass(e)$include & unclass(e)$type == "eval" & unclass(e)$name == dep)
		tg <- r$targets
		# targets are in the order of the effects (rates first): find the index of the cross effect among the included non-rate effects
		inc <- unclass(e)$include & unclass(e)$type != "rate"
		allinc <- which(unclass(e)$include)
		idx <- which(allinc == max(which(unclass(e)$include & unclass(e)$name == dep & unclass(e)$type == "eval" & unclass(e)$shortName == ef)))
		cat("REF", group, tk, sprintf("%.6f", tg[idx]), "\n")
	}
}
run("FB", "Fd", "Bd", c("altDist2W:1:cvE", "totDist2W:1:cvE", "simDist2W:1:cvE", "outActIntnX:1:cvE", "outPopIntnX:1:cvE", "covNetNet:0:cv"))
run("BF", "Bd", "Fd", c("diffWXClosure:0:cv", "inActIntnX:1:cv", "outActIntnX:1:cv", "sameXInActIntn:1:cv", "sameXOutActIntn:1:cv", "altDist2W:1:cv", "totDist2W:1:cv", "simDist2W:1:cv", "toU:0:dy"))
run("FB", "Fd", "Bd", c("toU:0:dyE"))
