# RSiena: two dependent one-mode networks on the same 30 actors (3 waves), cross-network effects. Networks (CSV, written once): F directed (dev/saom_mn2m_F1..3.csv, the one-mode
# network of saom_rsiena_mn2m.R), H directed and S NON-DIRECTED (dev/saom_mn1m_H1..3.csv, saom_mn1m_S1..3.csv).
# Environment: DEP, OTH in {Fd, Hd, Sd} (the dependent network that gets the cross effect, the other network); EFFS = shortNames (space separated); I1/I2 = interaction1 (default the
# other network) / interaction2 (a covariate cv, a dyadic covariate dy, or a network for from.w.ind); PARM = internal parameter; TARGETS=1 only prints the observed statistics;
# SEEDS = number of seeds (default 2).
suppressMessages(library(RSiena))
nA <- 30
if (!file.exists("dev/saom_mn1m_H1.csv")) {
	set.seed(5252)
	H <- matrix(rbinom(nA * nA, 1, 0.10), nA, nA); diag(H) <- 0
	S <- matrix(0, nA, nA); S[upper.tri(S)] <- rbinom(nA * (nA - 1) / 2, 1, 0.12); S <- S + t(S)
	Fm0 <- as.matrix(read.csv("dev/saom_mn2m_F1.csv", header = FALSE))
	for (w in 1:3) {
		write.table(H, sprintf("dev/saom_mn1m_H%d.csv", w), sep = ",", row.names = FALSE, col.names = FALSE)
		write.table(S, sprintf("dev/saom_mn1m_S%d.csv", w), sep = ",", row.names = FALSE, col.names = FALSE)
		fl <- matrix(rbinom(nA * nA, 1, 0.05), nA, nA) | (Fm0 > 0 & matrix(rbinom(nA * nA, 1, 0.04), nA, nA))
		H <- (H + fl) %% 2; diag(H) <- 0
		fs <- matrix(0, nA, nA); fs[upper.tri(fs)] <- rbinom(nA * (nA - 1) / 2, 1, 0.05); fs <- fs + t(fs)
		S <- (S + fs) %% 2; diag(S) <- 0
	}
}
rd <- function(f) as.matrix(read.csv(f, header = FALSE))
mk <- function(nm) array(unlist(lapply(1:3, function(w) rd(sprintf(nm, w)))), dim = c(nA, nA, 3))
Fd <- sienaDependent(mk("dev/saom_mn2m_F%d.csv"))
Hd <- sienaDependent(mk("dev/saom_mn1m_H%d.csv"))
Sd <- sienaDependent(mk("dev/saom_mn1m_S%d.csv"))
if (!file.exists("dev/saom_mn2m_cov.csv")) stop("run dev/saom_rsiena_mn2m.R first (it writes the covariates)")
cv <- coCovar(as.numeric(read.csv("dev/saom_mn2m_cov.csv", header = FALSE)[, 1]))
dyv <- rd("dev/saom_mn2m_dy.csv"); diag(dyv) <- 0
dy <- coDyadCovar(dyv)
d <- sienaDataCreate(Fd = Fd, Hd = Hd, Sd = Sd, cv = cv, dy = dy)
dep <- Sys.getenv("DEP", "Fd"); oth <- Sys.getenv("OTH", "Hd")
nseed <- as.integer(Sys.getenv("SEEDS", "2"))
# only the two networks of the model: drop the third from the data
d <- eval(parse(text = sprintf("sienaDataCreate(%s = %s, %s = %s, cv = cv, dy = dy)", dep, dep, oth, oth)))
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
		cat("RSIENA", dep, oth, ef, ":", gsub("\n", " ", r), "\n")
		next
	}
	for (sd in 1:nseed) {
		r <- try({ ans <- siena07(sienaAlgorithmCreate(projname = NULL, seed = sd, n3 = 1000, nsub = 4, cond = FALSE), data = d, effects = e, batch = TRUE, silent = TRUE)
			sprintf("targets %s est %s se %s", paste(round(ans$targets, 3), collapse = " "), paste(round(c(ans$rate, ans$theta), 3), collapse = " "), paste(round(sqrt(diag(ans$covtheta)), 3), collapse = " ")) }, silent = TRUE)
		cat("RSIENA", dep, oth, ef, "seed", sd, ":", gsub("\n", " ", r), "\n")
	}
}
