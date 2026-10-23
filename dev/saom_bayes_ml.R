# ML (maxlike) and MoM reference for the Bayesian sampler: Glasgow s501-s503
library(RSiena)
data(s501); data(s502); data(s503); data(s50a)
net <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
alc <- coCovar(s50a[, 1])
args <- commandArgs(TRUE); model <- args[1]; seed <- as.integer(args[2])
d <- if (model == "cov") sienaDataCreate(net, alc) else sienaDataCreate(net)
eff <- getEffects(d)
eff <- includeEffects(eff, recip, transTrip)
if (model == "cov") eff <- includeEffects(eff, egoX, altX, simX, interaction1 = "alc")
for (ml in c(FALSE, TRUE)) {
  a <- sienaAlgorithmCreate(projname = NULL, seed = seed, maxlike = ml, n3 = if (ml) 1000 else 1000, cond = FALSE, nsub = 4)
  ans <- siena07(a, data = d, effects = eff, batch = TRUE, silent = TRUE)
  cat("RESULT", model, seed, if (ml) "ML" else "MoM", "\n")
  print(round(rbind(est = ans$theta, se = ans$se), 4)); print(ans$effects$effectName)
}
