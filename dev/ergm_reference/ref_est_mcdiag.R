suppressMessages(library(ergm)); suppressMessages(library(coda))
set.seed(42); n <- 600
Phi <- matrix(c(.6,.2,0, .1,.5,.1, 0,.2,.7),3,byrow=TRUE)
e <- matrix(rnorm(n*3),n); x <- matrix(0,n,3)
for(t in 2:n) x[t,] <- Phi %*% x[t-1,] + e[t,]
x[,3] <- x[,3]*100 + 5; x[,2] <- x[,2]+ 0.3*x[,1]
x <- signif(x[1:250,],6)
write.table(x, "ar1_sample250.csv", sep=",", row.names=FALSE, col.names=FALSE)
xm <- mcmc(x, start=100, thin=100)
cat("MV\n"); mv <- ergm:::spectrum0.mvar(xm); print(mv, digits=12)
cat("spec0ar\n"); print(spectrum0.ar(xm)$spec, digits=12)
h <- ergm:::approx.hotelling.diff.test(xm); cat("HOT\n"); print(unlist(h[c("statistic","parameter","p.value")]), digits=12)
cat("GEW\n"); print(geweke.diag(xm)$z, digits=12)
gm <- ergm:::geweke.diag.mv(xm); print(c(gm$p.value, gm$statistic, gm$parameter), digits=12)
cat("ACF\n"); print(autocorr(xm,0:5)[,2,2], digits=12)
cat("ESS\n"); print(effectiveSize(xm), digits=12)
