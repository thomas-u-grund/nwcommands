# Architecture

Technical overview for anyone reading or extending the codebase, not just using it. See
`README.md` for installation and the user-facing command surface.

## Layering

- **`.ado`/`.sthlp` files** (repo root) — the Stata-facing command layer: syntax parsing,
  option validation, dispatch into Mata, and `ereturn`/`return` result posting. This is also
  literally the installable package — the repository root *is* the flat directory a plain
  `net install` lays out, so there is no separate `src/`-vs-`build/` split to reason about.
- **Mata core** (`unw_core.do`, plus `unw_ergm.do`/`unw_saom.do`/`unw_rem.do`/`unw_dynam.do` for
  the statistical model families) — compiled into `lib/lnwcommands.mlib`. `NWdef` is the central
  class: every network is an `NWdef` instance, holding node/edge state, metadata (directedness,
  valued-ness, two-mode status, temporal declaration), and the algorithms that operate on it.
- **Native (C) plugins** (`native/`, compiled to `lib/plugins/<platform>/`) — optional,
  per-platform compiled kernels for the small number of operations where Mata's own interpreter
  overhead, not the algorithm, is the actual bottleneck. Every native path has a complete,
  fully-supported Mata fallback; a plugin's absence on a given platform is never an error, only
  a slower default.
- **`cscripts/`** — the regression-test suite, one file per command family, run in both "dev
  mode" (against the Mata source directly) and "production mode" (against the compiled
  `.mlib`/plugins).

## The core network representation

`NWdef` stores each network as a sparse CSR/CSC index (`rowptr`/`colidx`/`cweight` for
out-neighbors, a CSC-style mirror for in-neighbors on directed networks) rather than an N×N
dense matrix. This is what makes networks with 100,000+ nodes and 1,000,000+ edges practical:
construction, degree/neighbor queries, and the core structural algorithms (components,
clustering, betweenness, distances) are all O(degree) or O(V+E), never O(N²).

A dense matrix is still materialized lazily, on first genuine demand, for the handful of
operations that need one (a few commands, and any user code reading the network as a plain Stata
matrix) — guarded by a node-count ceiling that raises a clear error rather than attempting a
silent multi-gigabyte allocation. Two algorithms are dense by necessity rather than migration
debt: spectral analysis (`nwspectral`) needs the full eigenspectrum, not just a dominant
eigenvalue, and a small induced-subgraph helper used only by n-clan diameter checks operates on
graphs small enough that it was never worth converting.

## Native (C) acceleration

Each native kernel is a small, purpose-built Stata plugin, not a general-purpose graph library —
a deliberate choice: the actual need in every case so far has been one well-understood algorithm
where crossing the Mata/native boundary *once per outer loop* (not once per inner operation)
eliminates interpreter overhead, and a bespoke kernel avoids licensing questions and heavyweight
build systems a general library would bring along for a handful of functions actually used.

- `ergm_mcmc.c` — the ERGM MCMC/MPLE sampler.
- `saom_sim.c` — the SAOM ministep sampler.
- `dynam_sim.c` — the DyNAM likelihood/gradient evaluation.
- `nwgraph.c` — betweenness centrality (Brandes' algorithm), structured to host further
  general graph kernels behind the same plugin binary over time.

The boundary is always crossed once per outer loop (once per MCMC sampling call, once per
likelihood evaluation), never once per inner step — a proposal, a ministep, or a single change
statistic never round-trips back into Mata. Reproducibility across the Mata/native boundary is
handled by seeding each plugin's own self-contained RNG from a value the Mata caller draws, so a
given `set seed` reproducibly drives the same native run (the two backends do not share a
bit-identical RNG stream, only statistically equivalent output, which is what the test suite
certifies). `.github/workflows/build-plugins.yml` builds and commits all three platforms'
binaries on push, so a compiled plugin is normally available regardless of what platform a given
commit was authored on.

## Statistical model families

### ERGM (`nwergm`)

MCMC needs to toggle a single edge millions of times over one estimation run; `NWdef`'s sparse
index rebuilds from scratch on every structural change, which is fine for ordinary use but far
too slow for that access pattern. `nwergm` therefore uses its own graph representation,
`ErgmGraph` — an associative-array-backed adjacency set giving O(1)-average toggle and lookup —
read from the network exactly once at the start of estimation and never touching `NWdef` again.

Terms follow a fixed, generic API contract (a per-term-instance data container plus matched
`stat_*`/`change_*` Mata function pairs), so adding a new term means writing that one pair and
registering it — the sampler, MPLE builder, and MCMLE controller never change. The same
contract has a native-C mirror for the terms the compiled backend supports.

Estimation offers both MPLE (exact for dyad-independent models, and the automatic starting value
for MCMLE otherwise) and MCMC-MLE (Geyer & Thompson 1992: simulate at the current parameter,
take a trust-region-capped Newton step on the centered simulated statistics, repeat), with
convergence declared via a joint Hotelling's T² test that the centered sample mean is
statistically indistinguishable from zero.

### SAOM and DyNAM (`nwsaom`, `nwdynam`)

SAOM's ministep sampler has the same repeated-single-toggle access pattern MCMC does, so it
reuses `ErgmGraph`/`ErgmModel`/`ErgmTermData` directly rather than reimplementing a parallel
graph class — a read-only dependency on the ERGM engine's own classes. This reuse is exact, not
approximate: for every effect in the shared family (outdegree, reciprocity, homophily), the
ERGM change statistic *is* the SAOM ego-effect's ministep delta, because both frameworks define
these effects the same way — as a sum of contributions fully local to the one toggled dyad.

The ministep sampler itself is a direct implementation of Snijders' multinomial-logit rule: for
the acting actor, compute the objective-function delta for every possible alternative tie
change, softmax, and draw. Continuous time is handled without a Poisson-count generator, by
exploiting the fact that the pooled waiting time across `n` actors with a constant rate is the
minimum of `n` i.i.d. exponentials. Parameters are estimated via Robbins-Monro stochastic
approximation, matching RSiena's own algorithm.

DyNAM factors the same kind of actor-oriented dynamics into two separate sub-models — which
actor acts next (a continuous-time competing-risks rate model), and which receiver they choose
(a discrete choice model) — plus a third sub-model for undirected, coordinated tie formation.
It shares the relational-event data model with `nwrem` (below) but not its engine, since the
rate/choice factorization needs different machinery.

### REM (`nwrem`)

Relational event models consume the same raw `(sender, receiver, time)` event stream that the
two-mode/temporal architecture already provides via `nwset ..., eventtime()` — no separate
data-ingestion mechanism was needed. Estimation uses the ordinal partial likelihood: given that
some event happened next, the probability it was this specific ordered pair rather than any
other pair that could have happened instead — structurally the same idea as a Cox
proportional-hazards partial likelihood, and for the same reason, no intercept term is
identifiable (a term constant across every candidate pair cancels exactly in the normalizer).

REM is deliberately a standalone engine, sharing no code with the ERGM/SAOM machinery: its
continuous-time, per-event risk-set evaluation (recomputing a value for every possible sender-
receiver pair at every event) is structurally unlike ERGM's dyad-toggle MCMC or SAOM's discrete
ministeps, so forcing a shared engine would have cost more in awkward abstraction than it saved
in reuse.

## Testing and certification

Every command family has a corresponding `cscripts/test_*.do` regression test, run in both dev
mode (sourcing the Mata files directly) and production mode (against the compiled library and
plugins), so a change is checked against both the source of truth and what actually ships.
Statistical model estimates are additionally cross-checked numerically against independent
reference implementations for the same models. Native/Mata backend pairs are certified either
for exact agreement (deterministic algorithms like betweenness) or statistical equivalence of
sampled distributions (stochastic algorithms like MCMC), whichever matches what the two backends
actually guarantee.

## Extending the package

`nw_programming.sthlp` (`help nw_programming` once installed) documents the internal
`NWdef`/network-registry API for anyone writing a new command against it, including a pitfalls
list drawn from real bugs found during development. The ERGM/SAOM/DyNAM term-extension pattern
above is the right model for adding a new effect to any of the three statistical engines; adding
an ordinary new structural command follows the same shape as any existing `nw*` command — parse
options, resolve the network via the registry, call or add an `NWdef` method, return results the
usual Stata way.
