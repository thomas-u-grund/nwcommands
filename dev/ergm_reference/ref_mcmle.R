suppressMessages(library(ergm))
source("dev/ergm_reference/ref_networks.R")
options(digits=17)

set.seed(1)
nwD <- make_directed()

cat("=== MCMLE: directed edges + mutual ===\n")
fit <- ergm(nwD ~ edges + mutual,
            control = control.ergm(seed = 1, MCMC.samplesize = 20000,
                                    MCMC.burnin = 20000, MCMC.interval = 200,
                                    MCMLE.maxit = 40))
print(summary(fit))
cat("coef:\n"); print(coef(fit))
cat("vcov:\n"); print(vcov(fit))
