# Architecture

Technical overview for anyone reading or extending the codebase, not just using it. See
`README.md` for installation and the user-facing command surface.

## Layering

- **`.ado`/`.sthlp` files** (repo root) — the Stata-facing command layer: syntax parsing,
  option validation, dispatch into Mata, and `ereturn`/`return` result posting. This is also
  literally the installable package — the repository root *is* the flat directory a plain
  `net install` lays out, so there is no separate `src/`-vs-`build/` split to reason about.
- **Mata core** (`unw_core.do`) — compiled into `lib/lnwcommands.mlib`. `NWdef` is the central
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

- `nwgraph.c` — betweenness centrality (Brandes' algorithm) and unweighted distances, structured to
  host further general graph kernels behind the same plugin binary over time. `nwcomb.h` and
  `nwcomb2.h` (included by `nwgraph.c`, so still one binary) add the combinatorial kernels: cohesive
  blocking, factions, line connectivity (equivalent-flow tree), the 4-node motif census, two-mode
  clustering, and the exhaustive subgroup searches (n-cliques, n-clans, k-plexes) with result and
  work limits. The Mata side (`nwg_comb()` in `unw_core.do`) probes the plugin once per session and
  keeps the older Mata code as the fallback.

The boundary is always crossed once per outer loop, never once per inner step. Reproducibility across the Mata/native boundary is
handled by seeding each plugin's own self-contained RNG from a value the Mata caller draws, so a
given `set seed` reproducibly drives the same native run (the two backends do not share a
bit-identical RNG stream, only statistically equivalent output, which is what the test suite
certifies). `.github/workflows/build-plugins.yml` builds and commits all three platforms'
binaries on push, so a compiled plugin is normally available regardless of what platform a given
commit was authored on.

## Statistical model packages

The statistical models for networks are separate packages in separate repositories, each
GPL-3 and each depending only on this core (never on one another, and the core never depends on
them): `nwergm` (ERGM), `nwsaom` (stochastic actor-oriented models), `nwrem` (relational event
models) and `nwdynam` (Dynamic Network Actor Models). They use the core's `NWdef` network
objects, `nwset`, `_nwsyntax` and the Mata library `lnwcommands.mlib`, and ship their own Mata
library and native plugins. The core ships nothing with these four command names, so installing or updating the core never
overwrites an installed model package. See each repository for its own architecture notes.

## Testing and certification

Every command family has a corresponding `cscripts/test_*.do` regression test, run in both dev
mode (sourcing the Mata files directly) and production mode (against the compiled library and
plugins), so a change is checked against both the source of truth and what actually ships.
Native/Mata backend pairs are certified either
for exact agreement (deterministic algorithms like betweenness) or statistical equivalence of
sampled distributions (stochastic algorithms like MCMC), whichever matches what the two backends
actually guarantee.

## Extending the package

`nwprogramming.sthlp` (`help nwprogramming` once installed) documents the internal
`NWdef`/network-registry API for anyone writing a new command against it, including a pitfalls
list drawn from real bugs found during development. Adding an ordinary new structural command follows the same shape as any existing `nw*` command — parse
options, resolve the network via the registry, call or add an `NWdef` method, return results the
usual Stata way.
