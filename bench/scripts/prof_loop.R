# Profiling helper (not a timing run): fits MODEL REPS times in one R process for the external sampler.
a <- commandArgs(TRUE); model <- a[1]; reps <- as.integer(a[2])
source(file.path(Sys.getenv("BENCH"), "scripts", "saom_specs.R"))
drop <- Sys.getenv("DROP")
isx <- model %in% names(specx)
cat("start\n", file = "ready.txt")
for (s in seq_len(reps)) {
  if (isx) { d <- specx[[model]]$data(); e <- specx[[model]]$eff(d); cond <- specx[[model]]$cond; mt <- NULL
  } else { x <- spec[[model]](); d <- x[[1]]; e <- x[[2]]; cond <- if (!is.null(x$cond)) x$cond else NA; mt <- x$mt
           if (!is.null(mt)) e$initialValue[e$shortName == "Rate" & e$type == "rate"] <- 0.5 }
  if (nzchar(drop)) e$include[e$shortName == drop & e$type == "eval"] <- FALSE
  alg <- if (isx) sienaAlgorithmCreate(projname = NULL, seed = s, cond = cond)
         else sienaAlgorithmCreate(projname = NULL, seed = s, cond = cond, modelType = if (is.null(mt)) NULL else c(friendship = mt))
  invisible(siena07(alg, data = d, effects = e, batch = TRUE, silent = TRUE))
}
