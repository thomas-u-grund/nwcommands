# Sparse Graph Backend — Architecture & Status

Living document. Last updated: 2026-08-21.

## Why

`nwcommands`' `NWdef` Mata class stored every network as a dense `real matrix edge` (N×N), regardless of actual density. Creating a network allocated O(N²) memory unconditionally (`J(nodes,nodes,0)` in both `nwfromedge.ado`'s `make_matrix()` and `NWdef::init_edge()`), making the package impractical above a few thousand nodes. Full technical audit and design in the original architecture report (superseded by this document as the living status reference).

## What exists now (Commits 1-7, complete)

All in `unw_core.do` on the `NWdef` class, unless noted.

- **Sparse index fields**: `rowptr`/`colidx`/`cweight` (CSR out-neighbors), `rowptr_in`/`colidx_in`/`edgeid_in` (CSC-style in-neighbors, directed networks only — undirected ties are already stored symmetrically in the forward index, so `neighbors_in()` falls back to `neighbors()`). `edgeid_in` points back into `colidx`/`cweight` rather than duplicating weights.
- **Accessors**: `neighbors(i)`, `neighbors_in(i)`, `degree(i)`, `degree_in(i)`, `has_edge(i,j)`, `edge_weight(i,j)`, `edgelist()` — O(1) or O(degree) each, built lazily via `ensure_sparse_built()`/`build_sparse_index()` from whichever representation (dense or sparse) is authoritative, and invalidated by every mutating method (`sparse_built = False`) plus a public `invalidate_sparse()` for the one external raw-pointer-write caller (`nwreplace.ado`).
- **Genuinely sparse-native construction**: `create_by_name_sparse()` + `init_edge_sparse()` (establish node identity without dense allocation) + `set_edge_from_triplets(ego, alter, weight, directed)` (builds the CSR/CSC index directly from an edge list — O(nnz log nnz), never touches `edge`).
- **Lazy dense materialization**: `edge_dense_built` (BOOL field — missing/True means `edge` is already valid, the default/unaffected legacy path; explicit False means "build on demand"). `ensure_dense_built()` is called at the top of all five `get_matrix*()` accessors and materializes `edge` from the sparse triplets on first real demand, **guarded by `nw_max_dense_nodes`** (`unw_defs.ado`, currently 20,000) with an informative error (`errDenseTooLarge`, code 484) instead of a silent multi-gigabyte allocation attempt above that size. `check_valued()` was also made sparse-aware (reads `cweight` directly) to avoid forcing materialization just to answer "is this network valued."
- **Migrated algorithms**: `calculate_components()` (BFS via `neighbors()`/`neighbors_in()`, byte-identical output to the prior dense implementation, verified), `calculate_clustering()` (all 5 modes; also fixed a genuine pre-existing self-inclusion bug, see below), `calculate_betweenness()` (Brandes' algorithm; also fixed a genuine pre-existing total non-functionality, see below), `get_outdegree()`/`get_indegree()`.
- **Proven at scale**: `lib/benchmark_sparse.do` builds and queries networks at 1k/10k/100k nodes (10k/100k/1M edges). At the 100k/1M tier: 1s to build, near-instant degree/neighbor queries, 7s for full connected-components analysis, `edge_dense_built` confirmed `0` throughout (the dense matrix — which would require ~74.5GB — was never constructed). Run: `/Applications/Stata/StataBE.app/Contents/MacOS/StataBE -e do "lib/benchmark_sparse.do"`.

## Bugs found and fixed along the way (all pre-existing, none caused by the migration itself)

- `calculate_clustering()` had a self-inclusion bug (dead code — zero `.ado` callers — from `select()` treating a missing mask value, present whenever self-loops are disabled, as "keep"). Fixed explicitly.
- `calculate_betweenness()`/`nwbetween` had **never once run to completion** in this codebase's history: a call to `dequeue()`, which was never defined anywhere, plus a stray syntax-breaking brace in `nwbetween.ado`. Both fixed; `dequeue()` added as a standalone Mata utility (pop-front on a row vector, verified Mata passes matrix arguments by reference).
- Once `nwbetween` could run, two more bugs surfaced: undirected betweenness was exactly double the standard value (classic unhalved Brandes double-counting — fixed with an explicit `if (!isdirect) Cb = Cb :/ 2`), and the `nosym` option silently did nothing (checked an unpopulated local `` `sym' `` instead of `` `nosym' ``) — fixing that exposed a third bug (the post-symmetrize cleanup path referenced a clobbered `netname` local instead of the already-saved `oldnetname`).
- `build_sparse_index()`'s reverse-index scratch array (`rowidx`) was originally allocated with `n` (node count) rows instead of `nnz` (edge count) rows — silently wrong/erroring on any directed network with average degree > 1. Found via full-suite regression testing (a dense 20-node/380-edge directed network), fixed, and covered by a dedicated permanent regression test.

## What is deliberately NOT done yet

- **`nwfromedge.ado` itself is not rewired** to the sparse-native construction path. Its downstream side effects (`nwsym` symmetrization for undirected input, bipartite embedding, `nw_datasync`) all currently touch the dense matrix at various points and need their own audit before they can be made lazy without risking a silent behavior change on an existing, working, tested command. The sparse-native construction primitives (`set_edge_from_triplets` etc.) are proven and ready for this; the wiring is future work.
- **The distance family remains fully dense**: `calculate_distances()`/`calculate_distance_pair()`/`calculate_distances_without()`/`Brute_dist()`/`Dijkstra_dist()` (the last of these rescans dense matrix rows per iteration rather than using the sparse `neighbors()` accessor even though a `priorityQueue`-based single-source Dijkstra already exists in the codebase and is nearly sparse-ready). This blocks true sparse scalability for `nwcloseness`, `nwgeodesic`, `nwreach`, `nwbridges`, and `nwpath`. This is real algorithmic rework, not a storage-format swap, and is the highest-priority remaining item — see `docs/ROADMAP.md` Stage 0/2.
- `nwneighbor.ado` still reads the dense matrix directly rather than using this session's `neighbors()`/`neighbors_in()` accessors — small, low-risk, not yet done.

## Testing

`cscripts/test_sparse_index.do` (dual-mode BFS-vs-`calculate_components()` proof, self-loop/empty/complete-graph/non-numeric-node-ID coverage, the directed-density regression case for the `rowidx` bug) and `cscripts/test_sparse_lazy_dense.do` (triplet construction, zero-edge networks, the 25,000-node size-guard case) are the permanent regression tests for this work. Both pass in dev mode (`do unw_core.do`) and production mode (against the compiled `lib/lnwcommands.mlib`, via the matching copies in `lib/cscripts_prod/`). Full-suite regression baseline as of this document: 62/70 passing, with the 8 failures being pre-existing dead-external-URL issues (`nwexport`/`nwplot`/`nwplotmatrix`/`nwshared`/`nwsimmelian`/`nwuse`/`nwvalue` all `r(601)`; `nwimport` `r(6750)`) unrelated to any code in this repository.

## Rebuilding

`lib/build.do` recompiles `lib/lnwcommands.mlib` from `unw_core.do` (`do unw_core.do` → `mata mlib create` → `mata mlib add lnwcommands *()` → `mata mlib index`) — required after any `unw_core.do` change before production-mode testing.
