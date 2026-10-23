# ML (maxlike) and MoM reference for the co-evolving behavior: Glasgow s501-s503 + drinking s50a. args: seed
library(RSiena)
data(s501); data(s502); data(s503); data(s50a)
friendship <- sienaDependent(array(c(s501, s502, s503), dim = c(50, 50, 3)))
drinking <- sienaDependent(s50a, type = "behavior")
dat <- sienaDataCreate(friendship, drinking)
seed <- as.integer(commandArgs(TRUE)[1])
eff <- getEffects(dat)
eff <- includeEffects(eff, transTrip, name = "friendship")
eff <- includeEffects(eff, simX, interaction1 = "drinking", name = "friendship")
eff <- includeEffects(eff, avAlt, name = "drinking", interaction1 = "friendship")
for (ml in c(FALSE, TRUE)) {
  a <- sienaAlgorithmCreate(projname = NULL, seed = seed, maxlike = ml, n3 = 1000, cond = FALSE, nsub = 4)
  ans <- siena07(a, data = dat, effects = eff, batch = TRUE, silent = TRUE)
  cat("RESULT coev", seed, if (ml) "ML" else "MoM", "\n")
  print(round(rbind(est = ans$theta, se = ans$se), 4)); print(ans$effects$effectName)
}
