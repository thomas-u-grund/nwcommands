# Reference observed sufficient statistics from Statnet ergm, for
# nwergm's change-statistic / statistic() certification suite.
suppressMessages(library(ergm))
source("dev/ergm_reference/ref_networks.R")

options(digits=17)
nwU <- make_undirected()
nwD <- make_directed()
ecovU <- make_edgecov_undirected()

cat("=== UNDIRECTED ===\n")
cat("edges: "); print(summary(nwU ~ edges))
cat("nodematch(sex): "); print(summary(nwU ~ nodematch("sex")))
cat("nodecov(age): "); print(summary(nwU ~ nodecov("age")))
cat("edgecov(ecovU): "); print(summary(nwU ~ edgecov(ecovU)))
cat("gwesp(0.5,fixed=TRUE): "); print(summary(nwU ~ gwesp(0.5, fixed=TRUE)))
cat("gwdegree(0.5,fixed=TRUE): "); print(summary(nwU ~ gwdegree(0.5, fixed=TRUE)))

cat("\n=== DIRECTED ===\n")
cat("edges: "); print(summary(nwD ~ edges))
cat("mutual: "); print(summary(nwD ~ mutual))
cat("nodematch(sex): "); print(summary(nwD ~ nodematch("sex")))
cat("nodecov(age): "); print(summary(nwD ~ nodecov("age")))
cat("gwesp(0.5,fixed=TRUE) [uses OTP by default for directed]: "); print(summary(nwD ~ gwesp(0.5, fixed=TRUE)))
cat("gwidegree(0.5,fixed=TRUE): "); print(summary(nwD ~ gwidegree(0.5, fixed=TRUE)))
cat("gwodegree(0.5,fixed=TRUE): "); print(summary(nwD ~ gwodegree(0.5, fixed=TRUE)))
