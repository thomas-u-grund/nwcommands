# Network-Type Compatibility Matrix

Living document. Part VII-XIV deliverable of the harmonisation phase. Authoritative reference for
binary/directed/weighted/signed/two-mode support across the public command surface — intended to
drive help-file "Supported network types" sections, dialog control visibility, and validation
logic as those are built out.

**Classification keys** (per the harmonisation brief):

Weighted: **W1** native weighted formulation (correct) · **W2** optional weighted variant (binary
canonical, weighted also available) · **W3** explicitly binary-only (weights intentionally ignored,
documented) · **W4** not applicable (no meaningful weighted formulation exists) · **W5** missing
desirable support (a standard weighted formulation exists but isn't implemented).

Two-mode: **T1** native bipartite implementation · **T2** mode-specific (explicit mode selection)
· **T3** projection-only (never silent) · **T4** not applicable · **T5** missing desirable support.

A row only gets a classification once the underlying code has actually been read and the claim can
be backed by a quoted line — "not yet audited" is used rather than guessing. This table is filled
in incrementally as commands are re-verified; it does not yet cover all ~127 public commands.

## Verified rows

| Command | Binary | Directed | Weighted | Weight meaning | Signed | Two-mode | Mode select | Projection | Notes |
|---|---|---|---|---|---|---|---|---|---|
| `nwdegree` | yes | yes (auto-splits in/out when directed) | **W1** — `get_outdegree(alpha)`/`get_indegree(alpha)`, Opsahl et al. generalized degree `k_i*(s_i/k_i)^alpha` | strength (direct, not distance) | not checked | not checked | n/a | n/a | `.sthlp` claims multi-network output-naming behaviour the code doesn't implement — doc bug, see `docs/COMMAND_AUDIT.md` |
| `nwbetween` | yes | yes (`nosym` skips auto-symmetrize) | **W3** — doc states dichotomized network is used; `alpha(real 0)` is parsed but never referenced anywhere in the body (dead option) | n/a | not checked | not checked | n/a | n/a | Weighted (Dijkstra-based) betweenness is on the roadmap as a genuine W5 gap |
| `nwcloseness` | yes | via `nwgeodesic` passthrough | ambiguous — no `weighted`/`alpha` of its own; entirely inherits whatever `nwgeodesic` options are passed through | distance (inherited) | not checked | not checked | n/a | n/a | Legacy architecture (`_nwsyntax`/`_nwsetobs`), not `nw_syntax` |
| `nwclustering` | yes | requires `symmetrize` for weighted+directed, else **explicit error** | **W1/W2** — `measure()` selects binary/arithmetic/geometric/min/max formulations | tie-value combination (not distance) | not checked | **T1-via-redirect**: checks `is2mode`, auto-redirects to `nw2clustering` with a clear message | n/a (redirect handles it) | n/a | **Model example** — use as the template for correct network-type handling elsewhere |
| `nwconstraint` | implicit only | not distinguished at all | **W1 but undocumented** — always row-normalizes `net/rowsum(net)`, no binary option | strength-like (row-normalized influence) | not checked; negative rowsum would silently corrupt normalization | not checked | n/a | n/a | Highest-priority doc gap: zero network-type documentation despite being weight-driven by construction |
| `nwcorrelate` | yes | `context(incoming/outgoing/both)` for node-correlation mode | uses raw tie values throughout, no dichotomize option | n/a (correlation, not centrality) | not checked | not checked | n/a | n/a | Type-C role-specific command (correctly not netlist-shaped) |
| `nwkatz` | yes | symmetrizes via `nwgeodesic`, no `nosym`-equivalent | **W1 but scientifically questionable** — computes `sum(alpha^dist(i,j))` via `nwgeodesic` distances | **conflates strength/distance**: `alpha` exponentiates a *distance* here, unlike `nwdegree`'s `alpha` which exponentiates a *strength ratio* | not checked | not checked | n/a | n/a | **Not canonical Katz centrality** despite the name/citation — true Katz is `(I-alpha*A)^-1`, an eigenvector-family measure, not a path-distance sum. Needs a documentation correction at minimum. |
| `nwbridges` | yes | output distinguishes arcs vs edges, not the bridge logic itself | implicit dichotomize via distance-without-edge check | n/a | not checked | not checked | n/a | n/a | |
| `nwpath` | yes | `sym` option symmetrizes | no weight semantics — any nonzero treated as traversable | n/a | not checked | not checked | n/a | n/a | `.sthlp` claims `r(paths)`/`r(path_shortest)`/`r(ego)`/`r(alter)`/`r(paths_matrix)` that the code does not actually return — doc/code mismatch |
| `nwreach` | yes | `sym` option | **W3 explicit and correct** — `set_valued(0)` deliberately dichotomizes the output | n/a | not checked | not checked | n/a | n/a | Clean, small, intentional W3 — the *right* way to do W3 (contrast with `nwqap` below) |
| `nwtriads` | yes (only) | **directed-only 16-type MAN census, no guard for undirected input** | **W4** (triad census is inherently dichotomous) | n/a | not checked | not checked | n/a | n/a | Several census categories (e.g. 021D, 030T) are meaningless for undirected data; should reject undirected input or clearly redefine |
| `nwdyads` | yes | yes (M/A/N layout for directed vs M/N for undirected) | **W4** (dyad census, inherently binary) | n/a | not checked | not checked | n/a | n/a | |
| `nwdyadprob` | generator | `undirected` flag | **weighted-aware by design** — values > 1 pushed through `invlogit()` to become probabilities | probability/strength (not distance) | not checked (negative probabilities would misbehave) | not checked | n/a | n/a | Auto-installs `gsample`/`moremata` from the internet at runtime — separate dependency/security flag (Part XXXVII) |
| `nwmixing` | yes | not distinguished | **W4** — E-I index is inherently categorical, cross-tab is dichotomized | n/a | not checked | not checked | n/a | n/a | |
| `nwqap` | yes | not distinguished | **W3, but silent and undocumented** — dichotomizes DV/IV networks via missing-diagonal + long-format transform, no weighted alternative, no warning | n/a | not checked | not checked | n/a | n/a | Uses legacy `_nwsyntax`. Flagship network-regression candidate; the roadmap's `eclass`+QAPSPP item should also add a genuine weighted path, not just wrap the current dichotomized one |
| `nw2clustering` | yes | n/a (two-mode) | not yet fully audited | — | not checked | **T1 native** | implicit both modes | n/a | The `nw2*`-prefix family is the package's dedicated native-bipartite command set |

## Not yet audited against this matrix (127-command surface, ~90 rows remaining)

Includes the full data-management/lifecycle group (`nwset`, `nwaddnodes`, `nwsym`, `nwtranspose`,
etc. — these are largely Type D/structural and may not need weighted/two-mode classification at
all, but should still get an explicit N/A pass rather than silent omission), the generator group
(`nwrandom`, `nwpref`, `nwring`, `nwsmall`, `nwlattice`, `nwhomophily`), the full visualisation
group (`nwplot`, `nwplotjs`, `nwplotmatrix`, `nwmovie`), import/export (`nwimport`, `nwexport`),
and several analysis commands not yet reached (`nwburt`, `nwevcent`, `nwgeodesic`, `nwsimindex`,
`nwkcore`, `nwaltergen`, `nwcug`, `nwcommunity`, `nwmodularity`, `nwbalance`, `nwsummarize`,
`nwtabulate`, `nwcontext`) — several of these were built or extended earlier this session with
explicit, documented network-type conventions already (e.g. `nwkcore`/`nwsimindex`'s
union-of-both-directions convention for directed networks, `nwaltergen`'s deliberately directional
out-neighbor convention) and should be fast to backfill into this table from their own `.sthlp`
"Description" sections rather than re-deriving from scratch.
