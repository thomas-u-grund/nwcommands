# Model definitions for the nwsaom vs RSiena benchmark (RSiena side).
# Copied unchanged from the article's benchmark/rsiena_bench.R (N, U, C, S, T, R models) and
# benchmark_extra/rsiena_extra.R (X models); only the driver loops were removed.
suppressMessages(library(RSiena))
only <- if (length(args) > 1) args[-1] else NULL

clean <- function(x) { x[x > 1] <- 0; x }
sym <- function(x) { x <- clean(x); ((x + t(x)) > 0) * 1 }
tile <- function(m, k) kronecker(diag(k), m)
w <- list(clean(s501), clean(s502), clean(s503))

net3 <- function(k = 1) sienaDependent(array(c(tile(w[[1]], k), tile(w[[2]], k), tile(w[[3]], k)),
                                             dim = c(50 * k, 50 * k, 3)))
net2 <- function() sienaDependent(array(c(w[[1]], w[[2]]), dim = c(50, 50, 2)))

# Each model: data, effects, modelType (NULL = directed), cond, seeds
spec <- list(
  N1 = function() { d <- sienaDataCreate(friendship = net2()); list(d, getEffects(d)) },
  N2 = function() { d <- sienaDataCreate(friendship = net3())
                    list(d, includeEffects(getEffects(d), gwespFF)) },
  N4 = function() { d <- sienaDataCreate(friendship = net3(), smoke1 = coCovar(s50s[, 1]))
                    e <- includeEffects(getEffects(d), gwespFF)
                    list(d, includeEffects(e, sameX, interaction1 = "smoke1")) },
  N5 = function() { d <- sienaDataCreate(friendship = net3())
                    list(d, includeEffects(getEffects(d), gwespFF, inPopSqrt, outAct)) },
  N6 = function() { d <- sienaDataCreate(friendship = net3(), alc1 = coCovar(s50a[, 1]))
                    e <- includeEffects(getEffects(d), gwespFF)
                    list(d, includeEffects(e, egoX, altX, simX, interaction1 = "alc1")) },
  N7 = function() { d <- sienaDataCreate(friendship = net3())
                    list(d, includeEffects(getEffects(d), gwespFF), cond = FALSE) },
  U1 = function() { d <- sienaDataCreate(friendship = sienaDependent(array(c(sym(s501), sym(s502)),
                                          dim = c(50, 50, 2)), allowOnly = FALSE))
                    list(d, getEffects(d)) },
  U2 = function() { d <- sienaDataCreate(friendship = sienaDependent(array(c(sym(s501), sym(s502)),
                                          dim = c(50, 50, 2)), allowOnly = FALSE))
                    e <- getEffects(d)
                    # pairwise types: RSiena's default rate start is on the per-actor
                    # scale and phase 2 does not recover; start on the pairwise scale
                    list(d, e, mt = 6) },
  C1 = function() { d <- sienaDataCreate(friendship = net3(), drinking = sienaDependent(s50a, type = "behavior"))
                    e <- includeEffects(getEffects(d), gwespFF, name = "friendship")
                    e <- includeEffects(e, simX, interaction1 = "drinking", name = "friendship")
                    list(d, includeEffects(e, avAlt, name = "drinking", interaction1 = "friendship")) },
  C2 = function() { d <- sienaDataCreate(friendship = net3(), smoking = sienaDependent(s50s, type = "behavior"))
                    e <- includeEffects(getEffects(d), gwespFF, name = "friendship")
                    e <- includeEffects(e, simX, interaction1 = "smoking", name = "friendship")
                    list(d, includeEffects(e, avSim, name = "smoking", interaction1 = "friendship")) },
  C3 = function() { d <- sienaDataCreate(friendship = net2(), drinking = sienaDependent(s50a[, 1:2], type = "behavior"))
                    e <- includeEffects(getEffects(d), simX, interaction1 = "drinking", name = "friendship")
                    e <- includeEffects(e, quad, name = "drinking", include = FALSE)
                    list(d, includeEffects(e, avAlt, name = "drinking", interaction1 = "friendship")) }
)
for (k in c(2, 4, 10)) local({ kk <- k
  spec[[paste0("S", 50 * kk)]] <<- function() { d <- sienaDataCreate(friendship = net3(kk))
                                                list(d, includeEffects(getEffects(d), gwespFF)) } })
spec[["T200"]] <- function() {
  d <- sienaDataCreate(friendship = net3(4), drinking = sienaDependent(do.call(rbind, rep(list(s50a), 4)), type = "behavior"))
  e <- includeEffects(getEffects(d), gwespFF, name = "friendship")
  e <- includeEffects(e, simX, interaction1 = "drinking", name = "friendship")
  list(d, includeEffects(e, avAlt, name = "drinking", interaction1 = "friendship")) }

realnet <- function(e, cov = TRUE) {
  e <- includeEffects(e, gwespFF, transRecTrip, inPopSqrt, outPopSqrt, name = "friendship")
  e <- includeEffects(e, sameX, interaction1 = "smoke1", name = "friendship")
  if (cov) e <- includeEffects(e, egoX, altX, simX, interaction1 = "alc1", name = "friendship")
  # RSiena 1.6.1 to 1.6.12 give outPopSqrt internal parameter 0, which switches its
  # statistic to start-of-period outdegrees without the square root
  # (stocnet/rsiena#151); parameter 1 is the documented effect, as in nwsaom
  setEffect(e, outPopSqrt, parameter = 1, name = "friendship") }
spec[["R1"]] <- function() { d <- sienaDataCreate(friendship = net3(), smoke1 = coCovar(s50s[, 1]), alc1 = coCovar(s50a[, 1]))
                             list(d, realnet(getEffects(d))) }
spec[["R2"]] <- function() { d <- sienaDataCreate(friendship = net3(), smoke1 = coCovar(s50s[, 1]),
                                                  drinking = sienaDependent(s50a, type = "behavior"))
                             e <- realnet(getEffects(d), cov = FALSE)
                             e <- includeEffects(e, simX, interaction1 = "drinking", name = "friendship")
                             list(d, includeEffects(e, avAlt, name = "drinking", interaction1 = "friendship")) }
spec[["R3"]] <- function() { d <- sienaDataCreate(friendship = sienaDependent(array(c(sym(s501), sym(s502)),
                                                  dim = c(50, 50, 2)), allowOnly = FALSE),
                                                  smoke1 = coCovar(s50s[, 1]), alc1 = coCovar(s50a[, 1]))
                             e <- includeEffects(getEffects(d), gwesp)   # undirected: gwesp, not gwespFF
                             e <- includeEffects(e, sameX, interaction1 = "smoke1")
                             list(d, includeEffects(e, simX, interaction1 = "alc1")) }
spec[["R4"]] <- function() { d <- sienaDataCreate(friendship = net3(4), smoke1 = coCovar(rep(s50s[, 1], 4)), alc1 = coCovar(rep(s50a[, 1], 4)))
                             list(d, realnet(getEffects(d))) }
spec[["R5"]] <- function() { d <- sienaDataCreate(friendship = net3(4), smoke1 = coCovar(rep(s50s[, 1], 4)),
                                                  drinking = sienaDependent(do.call(rbind, rep(list(s50a), 4)), type = "behavior"))
                             e <- realnet(getEffects(d), cov = FALSE)
                             e <- includeEffects(e, simX, interaction1 = "drinking", name = "friendship")
                             list(d, includeEffects(e, avAlt, name = "drinking", interaction1 = "friendship")) }

canon <- function(name, short, isbeh) {
  m <- c(density = "outdegree", recip = "reciprocity", transTrip = "transtrip", gwespFF = "gwesp",
         sameX = "sameX", inPopSqrt = "inpop", outAct = "outact", egoX = "egoX", altX = "altX", transRecTrip = "transrectrip", outPopSqrt = "outpop",
         linear = "linear", quad = "quadratic", avAlt = "avalt", avSim = "avsim")
  if (short == "simX") return(if (isbeh) "simX" else "simX")
  if (!is.na(m[short])) return(unname(m[short]))
  short
}


# ---- X models (benchmark_extra) ----
DX <- file.path(Sys.getenv("BENCH"), "data", "saom", "")
rd <- function(f) { m <- as.matrix(read.csv(f, header = FALSE)); m[is.na(m)] <- 0; diag(m) <- 0; storage.mode(m) <- "numeric"; m }
rdh <- function(f) as.matrix(read.csv(f))
arr3 <- function(l) array(unlist(l), dim = c(dim(l[[1]]), length(l)))

mb_data <- function(beh = FALSE) {
  g <- arr3(lapply(1:3, function(w) rd(sprintf("%ssaom_rsiena_mb_g%d.csv", DX, w))))
  b <- arr3(lapply(1:3, function(w) rd(sprintf("%ssaom_rsiena_mb_b%d.csv", DX, w))))
  friend <- sienaDependent(g); net2 <- sienaDependent(b)
  if (!beh) return(sienaDataCreate(friend, net2))
  smoke <- sienaDependent(as.matrix(read.csv(paste0(DX, "saom_rsiena_mb_smoke.csv"))), type = "behavior")
  sienaDataCreate(friend, net2, smoke)
}
tm_data <- function(pfx, na, ne) {
  w <- lapply(1:3, function(k) as.matrix(read.csv(sprintf("%s%d.csv", pfx, k))))
  A <- sienaNodeSet(na, nodeSetName = "A"); B <- sienaNodeSet(ne, nodeSetName = "B")
  dep <- sienaDependent(array(unlist(w), dim = c(na, ne, 3)), type = "bipartite", nodeSet = c("A", "B"))
  sienaDataCreate(dep, nodeSets = list(A, B))
}
w3 <- function() sienaDependent(array(c(clean(s501), clean(s502), clean(s503)), dim = c(50, 50, 3)))

specx <- list(
  X1 = list(data = function() tm_data(paste0(DX, "saom_twomode_w"), 40, 20),
            eff = function(d) includeEffects(getEffects(d), inPopSqrt, cycle4), cond = FALSE),
  X2 = list(data = function() tm_data(paste0(DX, "saom_rsiena_v21_tm2_w"), 40, 30),
            eff = function(d) includeEffects(getEffects(d), inPopSqrt, outAct, cycle4, outIso, antiInIso2), cond = FALSE),
  X3 = list(data = function() mb_data(FALSE),
            eff = function(d) { e <- includeEffects(getEffects(d), recip, name = "friend")
                                e <- includeEffects(e, recip, name = "net2")
                                includeEffects(e, crprod, name = "friend", interaction1 = "net2") }, cond = FALSE),
  X4 = list(data = function() mb_data(TRUE),
            eff = function(d) { e <- includeEffects(getEffects(d), recip, name = "friend")
                                e <- includeEffects(e, recip, name = "net2")
                                e <- includeEffects(e, linear, quad, name = "smoke")
                                e <- includeEffects(e, avAlt, name = "smoke", interaction1 = "friend")
                                includeEffects(e, avAlt, name = "smoke", interaction1 = "net2") }, cond = FALSE),
  X5 = list(data = function() mb_data(TRUE),
            eff = function(d) { e <- includeEffects(getEffects(d), recip, name = "friend")
                                e <- includeEffects(e, recip, name = "net2")
                                e <- includeEffects(e, linear, quad, name = "smoke")
                                e <- includeEffects(e, avAlt, name = "smoke", interaction1 = "friend")
                                e <- includeEffects(e, egoX, altX, simX, name = "friend", interaction1 = "smoke")
                                includeEffects(e, sameWWClosure, name = "friend", interaction1 = "net2", interaction2 = "smoke") }, cond = FALSE),
  X6 = list(data = function() {
              a <- arr3(lapply(1:3, function(k) rdh(sprintf("%ssaom_rsiena_symmulti_w%d.csv", DX, k))))
              b <- arr3(lapply(1:3, function(k) rdh(sprintf("%ssaom_mn_b%d.csv", DX, k))))
              net <- sienaDependent(a); adv <- sienaDependent(b); sienaDataCreate(net, adv) },
            eff = function(d) includeEffects(getEffects(d), crprod, name = "net", interaction1 = "adv"), cond = FALSE),
  X7 = list(data = function() { net <- w3(); smoke1 <- coCovar(s50s[, 1]); alc1 <- coCovar(s50a[, 1]); sienaDataCreate(net, smoke1, alc1) },
            eff = function(d) { e <- includeEffects(getEffects(d), recip, gwespFF)
                                e <- includeEffects(e, sameXTransTrip, interaction1 = "smoke1")
                                e <- includeEffects(e, altXOutAct, egoPlusAltSqX, interaction1 = "alc1"); e }, cond = NA),
  X8 = list(data = function() { net <- w3(); sienaDataCreate(net) },
            eff = function(d) includeEffects(getEffects(d), recip, transTrip1, transRecTrip2, Jout), cond = NA)
)

