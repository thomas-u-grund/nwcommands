*! R script that converts one networkdata .rda file to csv (runs on the user's computer); text payload of nwnetworkdata, read by nwnetworkdata.ado (file read between /* and */). Not a command.
/*
## nwnetworkdata_convert.R
## Part of nwnetworkdata (Stata, nwcommands). Converts ONE .rda file of the R package networkdata
## (David Schoch, https://github.com/schochastics/networkdata, MIT) that nwnetworkdata has downloaded to the user's
## own cache into csv tables that Stata can read. It is run on the user's computer by nwnetworkdata; it contains no data.
## Needs R and the package igraph.
##
## Usage:  Rscript nwnetworkdata_convert.R <file.rda> <output folder>
## Output: <obj>_edges.csv  <obj>_nodes.csv  <obj>_index.csv  <obj>_attrs.csv   (egor objects: <obj>_ego.csv, _alter.csv, _aatie.csv, _index.csv)

suppressMessages(library(igraph))

.rtype <- function(x) if (is.factor(x)) "character" else if (is.logical(x)) "logical" else if (is.numeric(x)) "numeric" else "character"
.clean <- function(x) {
  x <- as.character(x); na <- is.na(x)
  bad <- which(!na & !validUTF8(x)); if (length(bad)) { Encoding(x[bad]) <- "latin1"; x[bad] <- enc2utf8(x[bad]) }
  u <- which(!na & Encoding(x) == "unknown"); if (length(u)) Encoding(x[u]) <- "UTF-8"
  x <- enc2utf8(x); gsub("[\r\n\t]+", " ", x)
}
.sanit <- function(x, prefix = "v", maxlen = 32, taken = character()) {
  s <- gsub("[^A-Za-z0-9_]", "_", iconv(x, "UTF-8", "ASCII//TRANSLIT", sub = "_"))
  s[is.na(s) | s == ""] <- prefix
  bad <- grepl("^[0-9]", s); s[bad] <- paste0(prefix, s[bad])
  s <- substr(s, 1, maxlen)
  res <- character(length(s)); used <- taken
  for (i in seq_along(s)) { cand <- s[i]; k <- 1
    while (cand %in% used) { k <- k + 1; suf <- paste0("_", k); cand <- paste0(substr(s[i], 1, maxlen - nchar(suf)), suf) }
    res[i] <- cand; used <- c(used, cand) }
  res
}
.numfmt <- function(x) ifelse(is.na(x), "", format(x, digits = 15, trim = TRUE, scientific = FALSE))
.tocol <- function(x, type) {
  if (type == "logical") return(ifelse(is.na(x), "", ifelse(x, "1", "0")))
  if (type == "numeric") return(.numfmt(as.numeric(x)))
  v <- .clean(x); v[is.na(x)] <- ""; v
}

## returns list(idx = per-network summary, att = attribute schema, ref = reference degrees (for the package tests))
nwnd_convert_one <- function(f, outdir) {
  e <- new.env(); nm <- load(f, e); obj <- nm[1]; o <- get(obj, e)
  w <- function(df, suffix) write.csv(df, file.path(outdir, paste0(obj, "_", suffix, ".csv")), row.names = FALSE, na = "", fileEncoding = "UTF-8")
  if (inherits(o, "egor")) {
    for (tb in c("ego", "alter", "aatie")) {
      df <- as.data.frame(o[[tb]]); for (j in seq_along(df)) if (is.factor(df[[j]]) || is.character(df[[j]])) df[[j]] <- .clean(df[[j]])
      w(df, tb)
    }
    idx <- data.frame(net = obj, obj = obj, element = 0L, nelem = 3L, kind = "egor", stringsAsFactors = FALSE)
    w(idx, "index"); return(invisible(list(idx = idx, att = NULL, ref = NULL)))
  }
  if (!inherits(o, "igraph") && !(is.list(o) && all(vapply(o, inherits, TRUE, "igraph"))))
    stop("object ", obj, " is neither an igraph object nor a list of igraph objects")
  units <- if (inherits(o, "igraph")) list(o) else o
  kind <- if (inherits(o, "igraph")) "igraph" else "list_of_igraph"
  va_all <- character(); ea_all <- character(); vt <- list(); et <- list()
  for (g in units) {
    for (a in setdiff(vertex_attr_names(g), "name")) { va_all <- union(va_all, a); t <- .rtype(vertex_attr(g, a)); vt[[a]] <- if (is.null(vt[[a]]) || vt[[a]] == t) t else "character" }
    for (a in edge_attr_names(g)) { ea_all <- union(ea_all, a); t <- .rtype(edge_attr(g, a)); et[[a]] <- if (is.null(et[[a]]) || et[[a]] == t) t else "character" }
  }
  reserved <- c("nd_elem", "nd_id", "nd_order", "nd_label", "nd_name", "nd_from", "nd_to", "nd_mode")
  vs <- if (length(va_all)) .sanit(va_all, "v", 32, reserved) else character(); names(vs) <- va_all
  es <- if (length(ea_all)) .sanit(ea_all, "e", 32, reserved) else character(); names(es) <- ea_all
  ATT <- list()
  for (a in va_all) ATT[[length(ATT)+1]] <- data.frame(obj = obj, scope = "node", attr = a, stata = vs[[a]], rtype = vt[[a]], stringsAsFactors = FALSE)
  for (a in ea_all) ATT[[length(ATT)+1]] <- data.frame(obj = obj, scope = "edge", attr = a, stata = es[[a]], rtype = et[[a]], stringsAsFactors = FALSE)
  EDG <- list(); NOD <- list(); IDX <- list(); REF <- list()
  for (k in seq_along(units)) {
    g <- units[[k]]; g <- tryCatch(upgrade_graph(g), error = function(e) g)
    n <- vcount(g); dir <- is_directed(g); va <- vertex_attr_names(g); ea <- edge_attr_names(g)
    two <- FALSE; ty <- rep(FALSE, n); two_ok <- NA
    if ("type" %in% va && is.logical(vertex_attr(g, "type"))) { ty <- vertex_attr(g, "type"); el0 <- as_edgelist(g, names = FALSE); two_ok <- all(ty[el0[,1]] != ty[el0[,2]]); two <- isTRUE(two_ok) }
    el <- as_edgelist(g, names = FALSE); m <- nrow(el)
    ## Stata node order: one-mode = igraph order; two-mode = mode-1 (type FALSE) nodes first, then mode-2
    ord <- if (two) order(ty, seq_len(n)) else seq_len(n); rank <- integer(n); rank[ord] <- seq_len(n)
    if (two) { sw <- ty[el[,1]]; el[sw, ] <- el[sw, 2:1, drop = FALSE] }
    weighted <- "weight" %in% ea && is.numeric(edge_attr(g, "weight"))
    wt <- if (weighted) as.numeric(edge_attr(g, "weight")) else rep(1, m)
    nmv <- if ("name" %in% va) .clean(vertex_attr(g, "name")) else NA_character_
    lab <- if ("name" %in% va) .sanit(nmv, "n", 28) else paste0("n", seq_len(n))
    if ("name" %in% va) { lab[is.na(vertex_attr(g, "name"))] <- NA; lab <- .sanit(ifelse(is.na(lab), paste0("n", seq_len(n)), lab), "n", 28) }
    ND <- data.frame(nd_elem = rep(k, n), nd_id = seq_len(n), nd_order = rank, nd_label = lab, nd_name = if ("name" %in% va) nmv else rep("", n),
                     nd_mode = if (two) ifelse(ty, 2L, 1L) else rep(0L, n), stringsAsFactors = FALSE)
    for (a in va_all) ND[[vs[[a]]]] <- if (a %in% va) .tocol(vertex_attr(g, a), vt[[a]]) else rep("", n)
    NOD[[k]] <- ND[order(ND$nd_order), ]
    ED <- data.frame(nd_elem = rep(k, m), nd_from = rank[el[,1]], nd_to = rank[el[,2]], stringsAsFactors = FALSE)
    for (a in ea_all) ED[[es[[a]]]] <- if (a %in% ea) .tocol(edge_attr(g, a), et[[a]]) else rep("", m)
    EDG[[k]] <- ED
    ## reference numbers of the aggregated value matrix (parallel edges summed): used by the package tests
    a <- rank[el[,1]]; b <- rank[el[,2]]
    if (!dir) { lo <- pmin(a, b); hi <- pmax(a, b); a <- lo; b <- hi }
    ag <- if (m) rowsum(wt, paste(a, b), reorder = FALSE) else matrix(numeric(), 0, 1)
    pr <- if (m) do.call(rbind, strsplit(rownames(ag), " ")) else matrix(character(), 0, 2)
    pa <- as.integer(pr[,1]); pb <- as.integer(pr[,2]); pv <- as.numeric(ag[,1])
    keep <- pv != 0; offd <- pa != pb; use <- keep & offd
    ids <- as.character(seq_len(n))
    rs <- function(v, grp) { r <- rowsum(c(v, 0), c(grp, 1))[,1]; x <- as.numeric(r[ids]); x[is.na(x)] <- 0; x }
    if (dir) { outdeg <- tabulate(pa[use], n); indeg <- tabulate(pb[use], n); outstr <- rs(pv[use], pa[use]); instr <- rs(pv[use], pb[use]) }
    else { outdeg <- tabulate(c(pa[use], pb[use]), n); indeg <- outdeg
           outstr <- rs(c(pv[use], pv[use]), c(pa[use], pb[use])); instr <- outstr }
    loopval <- numeric(n); ls <- keep & !offd; loopval[pa[ls]] <- pv[ls]
    netname <- if (kind == "igraph") obj else paste0(obj, "_", k)
    REF[[k]] <- data.frame(net = netname, node = seq_len(n), outdeg = outdeg, indeg = indeg, outstr = .numfmt(outstr), instr = .numfmt(instr), loopval = .numfmt(loopval), stringsAsFactors = FALSE)
    IDX[[k]] <- data.frame(net = netname, obj = obj, element = if (kind == "igraph") 0L else k, nelem = length(units), kind = kind,
      n = n, m_igraph = m, directed = as.integer(dir), twomode = as.integer(two), twomode_attr_invalid = as.integer(identical(two_ok, FALSE)),
      n1 = if (two) sum(!ty) else 0L, n2 = if (two) sum(ty) else 0L, weighted = as.integer(weighted), multi = as.integer(any_multiple(g)),
      loops = as.integer(any(which_loop(g))), nloops = sum(which_loop(g)), npairs = sum(use), npairs_incl_loops = sum(keep),
      nisolates = sum(degree(g) == 0), nvattr = length(setdiff(va, "name")), neattr = length(ea), named = as.integer("name" %in% va),
      vattrs = paste(vs[setdiff(va, "name")], collapse = ";"), eattrs = paste(es[ea], collapse = ";"),
      temporal = as.integer(any(c("time", "timestamp") %in% ea)),
      graph_name = if ("name" %in% graph_attr_names(g)) .clean(graph_attr(g, "name"))[1] else "", stringsAsFactors = FALSE)
  }
  idx <- do.call(rbind, IDX); att <- if (length(ATT)) do.call(rbind, ATT) else data.frame(obj = character(), scope = character(), attr = character(), stata = character(), rtype = character())
  w(do.call(rbind, EDG), "edges"); w(do.call(rbind, NOD), "nodes"); w(idx, "index"); w(att, "attrs")
  invisible(list(idx = idx, att = att, ref = do.call(rbind, REF)))
}

if (sys.nframe() == 0L) {
  a <- commandArgs(TRUE)
  if (length(a) < 2) stop("usage: Rscript nwnetworkdata_convert.R <file.rda> <output folder>")
  dir.create(a[2], showWarnings = FALSE, recursive = TRUE)
  nwnd_convert_one(a[1], a[2])
}
*/
