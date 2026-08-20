# Certification Status

Living document. Last updated: 2026-08-21.

Per-feature stage tracking. A feature is not "done" until all four stages are checked: **implemented** (code written) → **tested** (cscripts test exists and passes, both dev and production mode) → **certified** (verified against known-correct values / dense-vs-sparse regression / edge cases, per the certification standard below) → **documented** (`.sthlp` exists and is current, including any new options/limitations).

## Certification standard (applied to every row below)

- **Syntax**: valid Stata syntax, documented options work, invalid options fail cleanly, missing required inputs give an informative error.
- **Functional**: verified against a small network with an analytically known correct answer.
- **Regression** (where replacing/extending existing code): compared against the prior implementation on small networks; if results differ, the discrepancy is investigated and documented, not silently accepted.
- **Edge cases**: empty network, isolates, disconnected components, directed/undirected, weighted, self-loops, non-consecutive node IDs — as applicable to the feature.
- **Scalability** (sparse-backend features only): tested on a realistically large sparse network, memory/time checked, absence of accidental dense allocation confirmed.

## Status table

| Feature | Implemented | Tested | Certified | Documented | Notes |
|---|---|---|---|---|---|
| Sparse index (`neighbors`/`degree`/`has_edge`/`edge_weight`/`edgelist`) | ✅ | ✅ | ✅ | ✅ (this doc + inline comments) | `test_sparse_index.do`, both modes |
| `set_edge_from_triplets`/`create_by_name_sparse`/lazy materialization | ✅ | ✅ | ✅ | ✅ | `test_sparse_lazy_dense.do`, both modes; benchmark at 3 tiers |
| `calculate_components()` sparse migration | ✅ | ✅ | ✅ | ✅ | byte-identical to prior dense output |
| `calculate_clustering()` sparse migration + self-inclusion bugfix | ✅ | ✅ | ✅ | ✅ | dead code (zero callers), bugfix documented in-line |
| `calculate_betweenness()` sparse migration + dequeue/brace/nosym/halving fixes | ✅ | ✅ | ✅ | ✅ | `test_nwbetween.do`, both modes; first-ever successful execution of this command |
| `get_outdegree()`/`get_indegree()` sparse migration | ✅ | ✅ | ✅ | ✅ | `test_nwdegree.do` (existing), both modes |
| `nwvalue.ado` bracket-syntax + off-by-one fix | ✅ | ✅ | ✅ | ✅ | `test_nwvalue.do` |
| `nwclustering.ado` rename-quirk fix | ✅ | ✅ | ✅ | — (no doc change needed, internal fix) | `test_nwclustering.do` |
| `nwgeodesic.ado`/`nwdyadprob.ado` `nw_syntax`-clobbering fixes | ✅ | ✅ | ✅ | — | `test_nwgeodesic.do`, `test_nwdyadprob.do` |
| `nwcommunity`/`nwmodularity` (Louvain community detection) | ✅ | ✅ | ✅ | ✅ | 3 hand-computable networks, exact match |
| `build_sparse_index()` rowidx sizing bugfix | ✅ | ✅ | ✅ | ✅ | dedicated regression test added |

## Pending (queued for implementation, not yet started)

| Feature | Priority (see ROADMAP.md) | Est. effort |
|---|---|---|
| `nw2project` | Stage 3, #1 | Small |
| `nwburt` revival | Stage 3, #2 | Small |
| `nwbalance` docs+tests | Stage 1 | Trivial |
| `nwgenvar`/`nwgenerate` dead-code fixes | Stage 1 | Trivial |
| Alter-aggregation (`nwgen ... = mean(alter.x)`) | Stage 5, top | Medium |
| Distance-family sparse migration | Stage 0 remainder | Large |
