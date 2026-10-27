# Generates the event logs for the nwdynam vs goldfish benchmark (deterministic: set.seed per size).
# Usage: Rscript gen_dynam.R   (env BENCH)  -> data/dynam/<id>_events.csv (sender, receiver, eventtime), <id>_actors.csv (actor, group, x)
B <- Sys.getenv("BENCH"); dir.create(file.path(B, "data", "dynam"), showWarnings = FALSE, recursive = TRUE)
sizes <- data.frame(id = c("e200_n20", "e1000_n30", "e5000_n20", "e5000_n50", "e5000_n100", "e20000_n100"),
                    nev = c(200, 1000, 5000, 5000, 5000, 20000), n = c(20, 30, 20, 50, 100, 100), seed = 20261026 + 1:6)
gen <- function(nev, n, seed) {
  set.seed(seed)
  group <- sample(1:3, n, replace = TRUE); x <- round(rnorm(n), 4)
  A <- matrix(0, n, n); outd <- numeric(n); ind <- numeric(n)
  el <- matrix(0, nev, 3); tt <- 0
  for (i in seq_len(nev)) {
    ws <- exp(0.4 * x + 0.3 * log1p(outd)); s <- sample.int(n, 1, prob = ws)
    tp <- as.numeric(A[s, ] %*% A)                       # two-paths s -> k -> j
    lp <- 1.2 * A[s, ] + 0.8 * A[, s] + 0.15 * (ind > 0) + 0.4 * (group == group[s]) + 0.3 * pmin(tp, 3)
    lp[s] <- -Inf; pr <- exp(lp - max(lp[is.finite(lp)])); pr[s] <- 0
    r <- sample.int(n, 1, prob = pr)
    if (A[s, r] == 0) { outd[s] <- outd[s] + 1; ind[r] <- ind[r] + 1 }
    A[s, r] <- 1
    tt <- tt + rexp(1, rate = 5)
    el[i, ] <- c(s, r, tt)
  }
  # every actor must appear (as sender or receiver) so that actor numbers equal node numbers in both programs
  for (m in setdiff(seq_len(n), unique(c(el[, 1], el[, 2])))) { k <- sample.int(nev, 1); el[k, 1] <- m; if (el[k, 2] == m) el[k, 2] <- m %% n + 1 }
  list(el = el, group = group, x = x)
}
for (k in seq_len(nrow(sizes))) {
  z <- sizes[k, ]; d <- gen(z$nev, z$n, z$seed)
  write.csv(data.frame(sender = d$el[, 1], receiver = d$el[, 2], eventtime = sprintf("%.6f", d$el[, 3])),
            file.path(B, "data", "dynam", paste0(z$id, "_events.csv")), row.names = FALSE, quote = FALSE)
  write.csv(data.frame(actor = seq_len(z$n), group = d$group, x = d$x),
            file.path(B, "data", "dynam", paste0(z$id, "_actors.csv")), row.names = FALSE, quote = FALSE)
  cat(z$id, "events", z$nev, "actors", z$n, "repeat share", round(mean(duplicated(paste(d$el[, 1], d$el[, 2]))), 3), "\n")
}
