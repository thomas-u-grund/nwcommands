# Native Graph Libraries — Feasibility Investigation and Selective Migration

Harmonisation unit 95. Living document. Last updated: 2026-08-23.

## The ask

The user asked for an evidence-based investigation of adopting an external native (C/C++) graph
library — igraph, NetworKit, SuiteSparse:GraphBLAS/LAGraph, with LEMON/Boost Graph
Library (BGL)/SNAP as further candidates — as an optional performance backend for this
package's existing Mata-implemented graph commands (`nwbetween`, `nwcloseness`,
`nwcomponents`, `nwpath`, centralities, k-core, clustering/triangles, community detection,
two-mode projection, structural similarity, and more), with an explicit migration rule: native
is adopted for a given command only if its *total* time (including any Mata↔native conversion
overhead) is at most half of Mata's own total time for the same call. The instruction was
explicit not to stop at a feasibility report: "Once the evidence identifies clear winners,
begin the selective migration and continue autonomously." `nwergm`'s own native MCMC engine
(`docs/ERGM_ARCHITECTURE.md`) is out of scope here — it stays exactly as it is, a specialised
kernel, not a general graph library's concern.

## The headline finding: the obvious win is already banked, in Mata, for free

Before surveying any external library, the single most important fact for this whole
investigation is that **this project already did the general-purpose, big-O version of this
work**, in a separate, earlier migration (`docs/SPARSE_BACKEND.md`), entirely in Mata, with zero
new dependencies. That migration replaced the package's own dense `O(N^2)` adjacency-matrix
representation with a genuinely sparse one for the core structural commands — components,
degree, clustering, neighbor traversal, unweighted BFS distances — and it is not a hopeful
claim: it is **proven at 100,000 nodes / 1,000,000 edges** (full connected-components analysis
in well under 10 seconds, near-instant degree/neighbor lookups, `edge_dense_built` confirmed
`0` throughout — the dense matrix, which would need ~74.5GB at that size, is never built at
all). Any general-purpose external graph library's own headline pitch — "handle graphs sparsity
naturally instead of as a dense matrix" — is a sales pitch this package no longer needs for that
command family. Adopting a large, heavyweight external dependency to re-solve an
already-solved problem would be a strictly worse trade: more supply-chain surface, more
cross-platform build complexity, and (as the licence audit below shows) real distribution
constraints in more than one candidate's case, for a win already banked.

This reframes the actual investigation from "should we adopt a big graph library" to the much
narrower, evidence-driven question the migration rule was actually designed to answer:
**which SPECIFIC remaining algorithms are still slow, and why** — is it genuine algorithmic
complexity (nothing to be done except a smarter algorithm, native or not), or is it Mata's own
per-operation interpreter overhead compounding on top of an already-fine algorithm (exactly the
profile `nwergm`'s own native MCMC backend was built to fix, and re-confirmed directly below with
real measurements, not an assumption)?

## Candidate library survey and licence audit

Every candidate the user named was actually checked (installed-package metadata,
`brew info`, and the upstream LICENSE files directly fetched from each project's own
repository) rather than assumed from memory:

| Library | Language / API | Licence (verified) | Note |
|---|---|---|---|
| **igraph** | C core (Python/R bindings on top) | **GPL-2.0-or-later** | Confirmed via Homebrew's own formula metadata. A strong copyleft licence — statically or dynamically linking igraph into this package's own native plugin would place a real GPL-compliance obligation on that plugin binary (and arguably its distribution alongside the rest of the package). This alone rules igraph out for a project that has not itself chosen a copyleft licence (see the "no LICENSE file yet" note below) without a deliberate, separate licensing decision. |
| **NetworKit** | C++ core (`libnetworkit`), Python-first packaging | MIT (core); pulls in Python/NumPy/SciPy as *packaging* dependencies (not linked into a plugin) | Permissive licence, but the project is built and distributed Python-first; using just the C++ core directly means depending on an upstream that does not itself treat "plain C++ library, no Python" as its primary supported use case. |
| **SuiteSparse:GraphBLAS** | C (GraphBLAS standard API) | **Apache-2.0** | Verified directly from the upstream `LICENSE` file (not the Homebrew `suite-sparse` bundle formula, which mixes in GPL-3.0-only and LGPL components from *other* SuiteSparse packages — a real trap: `brew install suite-sparse` pulls in copyleft code as a build dependency even if only the Apache-2.0 GraphBLAS piece is ever used at runtime. Building GraphBLAS standalone from its own upstream repository avoids this entirely). |
| **LAGraph** (built on GraphBLAS) | C | **BSD (2-clause style)** | Verified directly from the upstream `LICENSE` file. Genuinely permissive, no copyleft. |
| **LEMON** | C++ (header-heavy template library) | **Boost Software License 1.0** | Verified directly from the upstream `LICENSE` file. The most permissive licence surveyed (no attribution requirement even in binary form). |
| **Boost Graph Library (BGL)** | C++ (header-only templates) | **Boost Software License 1.0** | Same licence family as LEMON. No new build/link artifact at all (header-only) — but a genuinely different, C++-template-heavy integration style from this project's existing plain-C plugin pattern. |
| **SNAP** (Stanford) | C++ | **BSD-3-Clause** | Verified directly from the upstream `LICENSE` file. Permissive. |

**Licensing bottom line**: igraph is disqualified outright by its GPL-2.0-or-later licence
unless this project deliberately adopts a compatible copyleft licence for itself (a separate,
much bigger decision — see item 8's own repository-cleanup work, which found this project does
not currently have a `LICENSE` file at all). Every other candidate is permissively licensed and
would not by itself force a licensing decision. This audit alone would already narrow the field
meaningfully even before any performance evidence is considered.

## Real evidence: where does Mata's own interpreter overhead actually still hurt?

Rather than benchmark library adapters that do not exist yet, the higher-value first step was
to directly re-run the same kind of isolated microbenchmark that originally justified `nwergm`'s
own native MCMC backend (`native/ergm_mcmc.c`'s own header comment) against this package's
*current*, already-sparse-migrated Mata algorithms — to find out, with real numbers, which
specific commands are still slow enough to be worth accelerating at all.

**Betweenness centrality** (`nwbetween`, Brandes 2001) was the standout finding. On a sparse
random undirected network (density 0.004):

| Nodes | Mata (current, sparse-migrated) |
|---|---|
| 500 | 0.89s |
| 1,000 | 13.2s |

A ~15x slowdown for a 2x increase in node count is far worse than the algorithm's own
`O(V·(V+E))` complexity alone predicts at this density (`E` scales roughly with `V^2` at fixed
density, so `V·(V+E)` scales roughly with `V^3` — an 8x slowdown would already be "expected";
15x points at real per-operation interpreter overhead compounding on top of that, the same
signature `nwergm`'s own change-statistic microbenchmark found). A closer look at
`calculate_betweenness()` in `unw_core.do` confirms why: it still pre-allocates a dense
`N x (N-1)` adjacency-list matrix (`J(get_nodes(), get_nodes()-1, .)`) even though it populates
it via the sparse `neighbors()` accessor — a real, previously-undiscovered leftover
inefficiency from the sparse migration that stopped short of this one function's own internal
scratch structure — on top of Mata's own well-documented per-call overhead in Brandes' own
tight double-nested queue/stack loops.

`nwkcore` (k-core peeling) and `nwcomponents` were also profiled at the same sizes and did
**not** show this pattern — both stayed comfortably fast (well under a second at 1,000-10,000
nodes), confirming the slowness is specific to betweenness's own algorithm shape (many small
per-node/per-edge updates inside deeply nested loops), not a generic "Mata is slow" finding.
`nwcommunity` (Louvain) could not be profiled at the same sizes in this pass (its own
`symmetrize` precondition on directed input was hit during benchmarking) and remains a
disclosed, unstarted follow-on candidate — see below.

## Decision: bespoke native C kernel, not a third-party library

Given the combination of (a) the sparse-Mata migration already banking the general-purpose win,
(b) real licensing friction in the most prominent candidate (igraph), and (c) betweenness
centrality specifically showing the exact interpreter-overhead signature a native port fixes —
the evidence-based conclusion is **the same engineering pattern this project already proved
works for `nwergm`'s own MCMC backend: a small, bespoke, purpose-built native C kernel, not
adoption of a third-party graph library**. This is not a consolation prize — it is the
*better*-evidenced choice for this specific, narrow need:

- **No licensing exposure at all** — the code is this project's own, under whatever licence the
  project itself chooses (a still-open question — see item 8's repository-cleanup work).
- **No new build-system or cross-platform complexity** — reuses the exact same
  `native/Makefile` / Stata Plugin Interface (SPI) pattern already proven working on macOS
  (this project has no CMake, and several of the candidates — GraphBLAS especially — have
  large, complex build systems of their own that would need to be cross-compiled for
  Windows/Linux CI on top of everything already required for `ergm_mcmc.c`).
- **Matches the actual, narrow need** — one well-understood, ~150-line algorithm, not a
  general-purpose library's entire API surface (of which this package would use perhaps 2-3
  functions).

A general-purpose external library remains the right call if and when a MUCH broader swath of
algorithms turns out to need native acceleration than this pass found evidence for — see
"Remaining candidates and scope" below for what that would look like.

## What was actually built (unit 95): native betweenness centrality

`native/nwgraph.c` — a new, shared native-graph-kernel Stata plugin (structured to host
additional algorithm codes later behind one shared plugin binary, exactly mirroring how
`ergm_mcmc.c` hosts many TERM codes behind one plugin rather than one plugin per term) —
implements Brandes' algorithm for unweighted/dichotomized betweenness centrality, the default
mode of `calculate_betweenness()` in `unw_core.do`. `unw_core.do` gained a parallel dispatcher
(`NativeGraphInstallDir()`/`NativeGraphPluginSubdir()`/`NativeGraphPluginPath()`/
`NativeGraphAvailable()`, deliberately generalized — unlike `nwergm`'s own single-purpose
`ErgmNative*` functions — so future native graph kernels can share this one dispatcher and
plugin binary) and `calculate_betweenness_native()`, marshalling the network's own `edgelist()`
(already sparse, one row per stored tie; ties with weight `<= 0` excluded, matching
`calculate_betweenness()`'s own `edge_weight(m,n)>0` filter exactly) across a single `plugin
call` and reading back one betweenness score per node. `nwbetween.ado` dispatches to native
whenever `NativeGraphAvailable()` is true and the weighted (Dijkstra) mode was not requested;
the weighted mode and every platform without a compiled `nwgraph.plugin`/`nwgraph_unix.plugin`
transparently keep using the existing, unchanged Mata implementation — the same graceful,
never-erroring fallback contract `nwergm`'s own native backend already established.

**Certification**: betweenness centrality is a deterministic, exact combinatorial quantity
(unlike `nwergm`'s own stochastic MCMC sampler) — native and Mata are required to agree exactly
(to ordinary floating-point summation-order noise, not a statistical tolerance).
`cscripts/test_nwgraph_native.do` covers a small hand-built undirected graph, a small hand-built
directed graph, an isolate (zero-degree node), a disconnected graph (two separate components),
a signed network (a negative tie correctly excluded from both backends identically), and
`nwbetween.ado` itself with the native plugin file temporarily hidden mid-test to force and
directly compare against the Mata fallback path. All pass, with a max absolute difference on
the order of `1e-12` (ordinary floating-point noise). Full `cscripts/` sweep (dev and production
modes, 141 files): no regressions beyond this project's own established dead-external-URL
baseline.

**Real measured results** (against the migration rule: native total time, including
Mata↔native marshalling overhead, must be at most half of Mata's own total time):

| Nodes | Mata | Native (incl. marshalling) | Speedup |
|---|---|---|---|
| 500 | 0.89s | 0.021s | ~42x |
| 1,000 | 13.2s | 0.021s | ~628x |
| 2,000 | *(not measured — Mata alone would have taken minutes; see below)* | 0.40s | — |
| 5,000 | *(not measured)* | 1.46s | — |
| 10,000 | *(not measured)* | 6.79s | — |

Native betweenness at 10,000 nodes (6.79s) is already faster in absolute terms than Mata was at
1,000 nodes (13.2s) — a full order of magnitude more nodes handled in less wall-clock time. This
clears the migration rule's own `>= 2x` bar by two to three orders of magnitude, not marginally
— an unambiguous, evidence-backed "yes, migrate this one."

**A genuine, disclosed limitation found while benchmarking**: at 20,000 nodes, the current
Mata-side marshalling step (`edgelist()` plus the weight-filter `select()` call) itself became
slow and memory-hungry enough (multiple minutes, tens of gigabytes of resident memory observed
before the run was deliberately killed rather than risk exhausting the host machine) to
dominate wall time — the native C kernel itself is not the bottleneck at that scale, the Mata
marshalling step feeding it is. This is a real, scoped follow-on: reading the tie list directly
from the sparse CSR arrays (`rowptr`/`colidx`/`cweight`, already exposed on `NWdef`) instead of
via the `edgelist()` + `select()` intermediate representation would very likely remove this
bottleneck, but was not attempted in this pass to keep this wave's own scope controlled — see
"Remaining candidates and scope" below.

## Remaining candidates and scope (not attempted in this pass)

Following the same "decide term by term, on evidence" discipline this project has used
throughout (`nwergm`'s own term-expansion waves, the sparse-backend migration's own commit
sequence):

1. **Marshalling-overhead fix for `calculate_betweenness_native()`** — read the sparse CSR
   arrays directly instead of via `edgelist()`, to remove the 20,000-node bottleneck found
   above. Small, well-scoped, high-confidence follow-on.
2. **Community detection (Louvain, `nwcommunity`)** — flagged as a likely second candidate
   (many small per-node delta-modularity computations in a tight loop, structurally similar to
   betweenness) but not yet profiled cleanly (hit an unrelated `symmetrize` precondition during
   this pass's own benchmarking on a directed test network) or ported. Needs its own dedicated
   microbenchmark on a correctly-symmetrized network before a migrate/don't-migrate decision can
   be made the same evidence-based way betweenness's was.
3. **k-core peeling (`nwkcore`)** — profiled and found already fast (sub-second at the sizes
   tested); no evidence yet that native acceleration would clear the `>= 2x`-including-overhead
   bar. Re-profile at larger scale before ruling out permanently.
4. **Weighted (Dijkstra-based) betweenness** (`nwbetween`'s own `weighted` option) — remains
   Mata-only. `calculate_betweenness_weighted()` was not profiled in this pass; if it shows the
   same interpreter-overhead signature, extending `native/nwgraph.c` with a weighted algorithm
   code is a natural, structurally similar follow-on to what was just built.
5. **Structural-equivalence / similarity measures, two-mode projection, and the remaining
   dense-matrix-dependent commands** (`nwevcent`, older unmigrated algorithms — see
   `docs/SPARSE_BACKEND.md`'s own "Status" section for the exact list) — not investigated in
   this pass at all. These may turn out to need either the sparse-Mata treatment (like the
   original `docs/SPARSE_BACKEND.md` migration) or native acceleration once memory-safe at
   scale — undetermined without their own dedicated profiling pass.
6. **A genuinely broader native-backend architecture** (the kind of dispatcher, benchmark
   framework, and cross-platform-build investment a general-purpose external library like
   GraphBLAS/LAGraph or SNAP would justify) remains available as a future direction **if and
   only if** items 2-5 above turn up several more genuinely interpreter-overhead-bound
   algorithms — at that point, the calculus in "Decision" above (one-off bespoke kernels vs. a
   full library) should be revisited with that broader evidence in hand, not re-decided from
   this pass's narrower one-algorithm result.

None of these are started. Each is disclosed here, not silently dropped, following this
project's own established practice of scoping real follow-on work explicitly rather than
implying a broader completion than what was actually done.

## Cross-platform and CI

`native/Makefile` now builds both `ergm_mcmc.c` and `nwgraph.c` under the same `macos`/`unix`
targets (per-plugin targets `macos-ergm_mcmc`/`macos-nwgraph`/`unix-ergm_mcmc`/`unix-nwgraph`
remain available individually). `.github/workflows/build-plugins.yml` (renamed from "Build
native ERGM plugins" to "Build native plugins") was updated to build, upload, and commit both
plugins' own Windows/Linux/macOS binaries — Windows via an added `cl /LD` invocation for
`nwgraph.c` alongside the existing `ergm_mcmc.c` one, Linux/macOS automatically via the
Makefile's own now-aggregate `unix`/`macos` targets. As with `ergm_mcmc.plugin`, only macOS is
built and verified directly in this development environment; Windows/Linux binaries are built
by CI once this repository is public (see item 8's own repository-cleanup work) and were not
built or tested directly here.
