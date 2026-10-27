# One timed goldfish fit in its own process.  Usage: Rscript dynam_gf.R SIZE SET ENGINE SEED OUTFILE   (env BENCH)
# The timer covers estimate() (statistics preprocessing + estimation, as one call); building the network objects
# is before the timer.  An untimed warm-up fit (200 events, same engine) comes first.
suppressMessages(library(goldfish))
a <- commandArgs(TRUE); size <- a[1]; set <- a[2]; engine <- a[3]; out <- a[4]
B <- Sys.getenv("BENCH"); source(file.path(B, "scripts", "dynam_sets.R"))
prep <- function(id) {
  ev <- read.csv(file.path(B, "data", "dynam", paste0(id, "_events.csv")))
  ac <- read.csv(file.path(B, "data", "dynam", paste0(id, "_actors.csv")))
  actors <- data.frame(label = paste0("A", ac$actor), present = TRUE, group = ac$group, x = ac$x)
  events <- data.frame(time = ev$eventtime, sender = paste0("A", ev$sender), receiver = paste0("A", ev$receiver), increment = 1)
  net <- defineNetwork(nodes = actors, directed = TRUE)
  net <- linkEvents(x = net, changeEvent = events, nodes = actors)
  dep <- defineDependentEvents(events = events, nodes = actors, defaultNetwork = net)
  list(actors = actors, dep = dep, net = net, events = events)
}
run <- function(id, set, engine, pre = FALSE) {
  z <- prep(id); env <- new.env(); env$actors <- z$actors; env$dep <- z$dep; env$net <- z$net; env$events <- z$events
  f <- as.formula(paste("dep ~", dsets[[set]]$rhs), env = env)
  init <- list(engine = engine)
  if (pre) return(system.time(estimate(f, model = "DyNAM", subModel = dsets[[set]]$sub, estimationInit = init, preprocessingOnly = TRUE, envir = env))[["elapsed"]])
  t <- system.time(m <- estimate(f, model = "DyNAM", subModel = dsets[[set]]$sub, estimationInit = init, envir = env))[["elapsed"]]
  list(t = t, m = m)
}
invisible(run("e200_n20", set, engine))
r <- run(size, set, engine); m <- r$m
wr <- function(k, v) cat(k, "\t", paste(v, collapse = "\t"), "\n", sep = "", file = out, append = TRUE)
unlink(out)
wr("secs", sprintf("%.4f", r$t)); wr("converged", as.integer(isTRUE(m$convergence$isConverged)))
wr("iters", m$nIterations); wr("ll", sprintf("%.8f", m$logLikelihood))
pn <- sub("\\(.*$", "", trimws(strsplit(dsets[[set]]$rhs, "+", fixed = TRUE)[[1]])); wr("names", pn); wr("ests", sprintf("%.8g", m$parameters)); wr("ses", sprintf("%.8g", m$standardErrors))
pre <- if (r$t < 60) tryCatch(run(size, set, engine, pre = TRUE), error = function(e) NA) else NA
wr("version", paste0("goldfish ", packageVersion("goldfish"), " engine ", engine, " preprocess_only_secs ", if (is.na(pre)) "NA" else sprintf("%.3f", pre)))
