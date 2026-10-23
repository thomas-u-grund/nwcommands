# RSiena: a TWO-MODE dependent network B (30 actors x 12 events) and a one-mode network F on the same actors (3 waves), cross-network effects.
# Data (written once): dev/saom_mn2m_B1..3.csv (30 x 12), dev/saom_mn2m_F1..3.csv (30 x 30).
# Environment: DEP = B (the two-mode network is the dependent one that gets the cross effect, default) or F; EFFS = shortNames of the cross effects (space separated);
# PARM = optional internal parameter; I1/I2 = interaction1 (default: the other network) / interaction2 (a covariate cv, a dyadic covariate dy, or a network for from.w.ind); TARGETS=1 only prints the observed statistics (targets), else estimates for seeds 1:SEEDS (default 2).
suppressMessages(library(RSiena))
nA <- 30; nE <- 12
if (!file.exists("dev/saom_mn2m_B1.csv")) {
	set.seed(4242)
	B <- matrix(rbinom(nA * nE, 1, 0.18), nA, nE)
	F <- matrix(rbinom(nA * nA, 1, 0.07), nA, nA); diag(F) <- 0
	for (w in 1:3) {
		write.table(B, sprintf("dev/saom_mn2m_B%d.csv", w), sep = ",", row.names = FALSE, col.names = FALSE)
		write.table(F, sprintf("dev/saom_mn2m_F%d.csv", w), sep = ",", row.names = FALSE, col.names = FALSE)
		flip <- matrix(rbinom(nA * nE, 1, 0.10), nA, nE); B <- abs(B - flip)
		# the one-mode network follows the shared events a little: actors with a common event tie more often
		co <- (B %*% t(B)) > 1; diag(co) <- FALSE
		flipF <- matrix(rbinom(nA * nA, 1, 0.04), nA, nA) | (co & matrix(rbinom(nA * nA, 1, 0.06), nA, nA))
		F <- (F + flipF) %% 2 * 1; F[F > 1] <- 1; diag(F) <- 0
	}
}
if (!file.exists("dev/saom_mn2m_cov.csv")) {
	set.seed(777)
	write.table(sample(1:4, nA, replace = TRUE), "dev/saom_mn2m_cov.csv", row.names = FALSE, col.names = FALSE)
	write.table(matrix(sample(0:3, nA * nA, replace = TRUE), nA, nA), "dev/saom_mn2m_dy.csv", sep = ",", row.names = FALSE, col.names = FALSE)
	write.table(matrix(sample(0:3, nA * nE, replace = TRUE), nA, nE), "dev/saom_mn2m_dyE.csv", sep = ",", row.names = FALSE, col.names = FALSE)
}
Bm <- lapply(1:3, function(w) as.matrix(read.csv(sprintf("dev/saom_mn2m_B%d.csv", w), header = FALSE)))
Fm <- lapply(1:3, function(w) as.matrix(read.csv(sprintf("dev/saom_mn2m_F%d.csv", w), header = FALSE)))
Fd <- sienaDependent(array(unlist(Fm), dim = c(nA, nA, 3)), nodeSet = "A")
Bd <- sienaDependent(array(unlist(Bm), dim = c(nA, nE, 3)), type = "bipartite", nodeSet = c("A", "E"))
cv <- coCovar(as.numeric(read.csv("dev/saom_mn2m_cov.csv", header = FALSE)[, 1]), nodeSet = "A")
dyv <- as.matrix(read.csv("dev/saom_mn2m_dy.csv", header = FALSE)); diag(dyv) <- 0
dy <- coDyadCovar(dyv, nodeSets = c("A", "A"))
dyE <- coDyadCovar(as.matrix(read.csv("dev/saom_mn2m_dyE.csv", header = FALSE)), nodeSets = c("A", "E"))
d <- sienaDataCreate(Fd = Fd, Bd = Bd, cv = cv, dy = dy, dyE = dyE, nodeSets = list(A = sienaNodeSet(nA, "A"), E = sienaNodeSet(nE, "E")))
dep <- Sys.getenv("DEP", "Bd")
oth <- ifelse(dep == "Bd", "Fd", "Bd")
nseed <- as.integer(Sys.getenv("SEEDS", "2"))
for (ef in strsplit(Sys.getenv("EFFS", "to"), " ")[[1]]) {
	e <- getEffects(d)
	i2 <- Sys.getenv("I2", "")
	i1 <- Sys.getenv("I1", oth)
	if (i2 == "") e <- eval(parse(text = sprintf("includeEffects(e, `%s`, name = '%s', interaction1 = '%s')", ef, dep, i1)))
	else e <- eval(parse(text = sprintf("includeEffects(e, `%s`, name = '%s', interaction1 = '%s', interaction2 = '%s')", ef, dep, i1, i2)))
	pm <- Sys.getenv("PARM", "")
	if (pm != "") { x <- unclass(e); k <- which(x$shortName == ef & x$include & x$name == dep); e$parm[k] <- as.numeric(pm) }
	if (Sys.getenv("TARGETS", "0") == "1") {
		r <- try({ ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = 1, n3 = 50, nsub = 0, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE)
			sprintf("targets %s", paste(round(ans$targets, 4), collapse = " ")) }, silent = TRUE)
		cat("RSIENA", dep, ef, ":", gsub("\n", " ", r), "\n")
		next
	}
	for (sd in 1:nseed) {
		r <- try({ ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE)
			sprintf("targets %s est %s se %s", paste(round(ans$targets, 3), collapse = " "), paste(round(c(ans$rate, ans$theta), 3), collapse = " "), paste(round(sqrt(diag(ans$covtheta)), 3), collapse = " ")) }, silent = TRUE)
		cat("RSIENA", dep, ef, "seed", sd, ":", gsub("\n", " ", r), "\n")
	}
}
