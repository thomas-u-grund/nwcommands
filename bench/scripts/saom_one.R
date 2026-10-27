# One timed RSiena fit in its own process.  Usage: Rscript saom_one.R MODEL SEED OUTFILE [NODES]
# env BENCH = folder speed_all.  A cheap untimed warm-up fit (N1, seed 100) loads RSiena and its compiled
# code first; the timer covers siena07() only (data and effects are built before the timer).
# NODES > 1: useCluster = TRUE with that many local worker processes (the multi-core comparison).
a <- commandArgs(TRUE); model <- a[1]; seed <- as.integer(a[2]); out <- a[3]
nodes <- if (length(a) > 3) as.integer(a[4]) else 1L
source(file.path(Sys.getenv("BENCH"), "scripts", "saom_specs.R"))
fit <- function(m, s, nodes = 1L) {
  isx <- m %in% names(specx)
  if (isx) { d <- specx[[m]]$data(); e <- specx[[m]]$eff(d); cond <- specx[[m]]$cond; mt <- NULL
  } else { x <- spec[[m]](); d <- x[[1]]; e <- x[[2]]; cond <- if (!is.null(x$cond)) x$cond else NA; mt <- x$mt
           if (!is.null(mt)) e$initialValue[e$shortName == "Rate" & e$type == "rate"] <- 0.5 }
  alg <- if (isx) sienaAlgorithmCreate(projname = NULL, seed = s, cond = cond)
         else sienaAlgorithmCreate(projname = NULL, seed = s, cond = cond,
                modelType = if (is.null(mt)) NULL else c(friendship = mt))
  cl <- if (nodes > 1) list(useCluster = TRUE, nbrNodes = nodes, initC = TRUE) else list()
  t <- system.time(ans <- do.call(siena07, c(list(alg, data = d, effects = e, batch = TRUE, silent = TRUE), cl)))[["elapsed"]]
  list(t = t, a = ans, isx = isx)
}
invisible(fit("N1", 100L))
drop <- Sys.getenv("DROP")
if (nzchar(drop)) { .e0 <- specx[[model]]$eff; specx[[model]]$eff <- function(d) { e <- .e0(d); e$include[e$shortName == drop & e$type == "eval"] <- FALSE; e } }
r <- fit(model, seed, nodes); ans <- r$a; eff <- ans$effects
if (r$isx) {
  nm <- paste(eff$name, eff$shortName, eff$interaction1, eff$interaction2, eff$type, ifelse(eff$shortName == "Rate", eff$period, ""), sep = "|")
  est <- ans$theta; se <- ans$se
  if (!is.null(ans$rate) && length(ans$rate) > 0 && !any(eff$shortName == "Rate" & eff$include)) {
    dn <- unique(eff$name)[1]
    nm <- c(paste0(dn, "|Rate|||rate|", seq_along(ans$rate)), nm); est <- c(ans$rate, est); se <- c(ans$vrate[seq_along(ans$rate)], se)
  }
} else {
  isbeh <- eff$name != "friendship"
  beh_simx <- eff$shortName == "simX" & eff$interaction1 %in% c("drinking", "smoking")
  nm <- character(nrow(eff)); per <- ave(seq_len(nrow(eff)), eff$name, eff$shortName, FUN = seq_along)
  for (i in seq_len(nrow(eff))) {
    if (eff$shortName[i] == "Rate") nm[i] <- paste0(if (isbeh[i]) "brate" else "rate", per[i])
    else if (beh_simx[i]) nm[i] <- "behsim" else nm[i] <- canon(eff$name[i], eff$shortName[i], isbeh[i])
  }
  est <- ans$theta; se <- ans$se
  if (!is.null(ans$rate) && length(ans$rate) > 0 && !any(nm == "rate1")) {
    nm <- c(paste0("rate", seq_along(ans$rate)), nm); est <- c(ans$rate, est); se <- c(ans$vrate[seq_along(ans$rate)], se)
  }
}
wr <- function(k, v) cat(k, "\t", paste(v, collapse = "\t"), "\n", sep = "", file = out, append = TRUE)
unlink(out)
wr("secs", sprintf("%.4f", r$t)); wr("tconv_max", sprintf("%.5f", ans$tconv.max))
wr("converged", as.integer(ans$tconv.max < 0.25)); wr("iters", NA); wr("ll", NA)
wr("names", nm); wr("ests", sprintf("%.8g", est)); wr("ses", sprintf("%.8g", se))
wr("version", as.character(packageVersion("RSiena")))
