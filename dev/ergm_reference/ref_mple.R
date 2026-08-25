suppressMessages(library(ergm))
source("dev/ergm_reference/ref_networks.R")
options(digits=17)

nwU <- make_undirected()
nwD <- make_directed()

cat("=== MPLE: undirected edges only ===\n")
f1 <- ergmMPLE(nwU ~ edges)
fit1 <- glm(f1$response ~ f1$predictor - 1, weights=f1$weights, family="binomial")
print(coef(fit1))

cat("\n=== MPLE: undirected edges + nodematch(sex) ===\n")
f2 <- ergmMPLE(nwU ~ edges + nodematch("sex"))
fit2 <- glm(f2$response ~ f2$predictor - 1, weights=f2$weights, family="binomial")
print(coef(fit2))

cat("\n=== MPLE: directed edges + mutual ===\n")
f3 <- ergmMPLE(nwD ~ edges + mutual)
fit3 <- glm(f3$response ~ f3$predictor - 1, weights=f3$weights, family="binomial")
print(coef(fit3))

cat("\n=== MPLE via ergm() directly (should match), undirected edges+nodematch(sex) ===\n")
fit2b <- ergm(nwU ~ edges + nodematch("sex"), estimate="MPLE")
print(coef(fit2b))
