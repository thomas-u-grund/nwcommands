# nwergm vs. R ergm() head-to-head benchmark

Development-only benchmark suite (not shipped, not in any `_pkg_*.txt` manifest,
matching `dev/ergm_reference/`'s own convention). Compares `nwergm`'s wall-clock
time and coefficient/SE agreement against Statnet's own `ergm()` (R) on an
**identical** exported network, fit with each tool's own default settings — the
most realistic "how long does this actually take a real user" comparison.

## Files

- `01_generate_network.do` — generates one reproducible 30-node directed random
  network (`nwrandom`, `prob(0.12)`, fixed seed) and exports its adjacency
  matrix to `bench_net.csv` (plain 0/1 CSV, no header) so both tools fit the
  exact same data. Re-run this only if you want a different benchmark network —
  the current `bench_net.csv` is checked in so the comparison is reproducible
  without needing to regenerate it.
- `02_bench_stata.do` — loads `bench_net.csv` via `nwset`'s edgelist input path
  (see the script's own comment on why: `nwset`'s `mat()` option has a real,
  documented bug with bare Stata matrix names — `docs/CERTIFICATION.md`'s own
  Pending list — that a literal-expression workaround doesn't scale past small
  networks either), fits `edges + mutual` via `nwergm` with default control
  settings, and times the whole call with Stata's own `timer`.
- `03_bench_r.R` — loads the same `bench_net.csv` into a `network` object, fits
  `edges + mutual` via `ergm()` with default control settings, and times the
  whole call with `Sys.time()`.
- `bench_net.csv` — the shared network (30×30, 105 directed ties).

## Running it

```
cd nwcommands_2016
/Applications/Stata/StataBE.app/Contents/MacOS/StataBE -e do "dev/ergm_benchmark_r_vs_stata/02_bench_stata.do"
Rscript dev/ergm_benchmark_r_vs_stata/03_bench_r.R
```

Both print wall time, coefficients, and convergence status. Stata's log goes to
`02_bench_stata.log` in the working directory (delete it before re-running, or
Stata will refuse to overwrite).

## Results (harmonisation unit 80)

| | R `ergm` 4.12.0 | `nwergm` before unit 80 | `nwergm` after unit 80 |
|---|---|---|---|
| Wall time | 0.29s | 163.18s | 6.6–7.0s (typical), as low as 1.8s on some seeds |
| MCMLE iterations | 1 | 10–20 (sometimes hit the cap without converging) | 1–7 |
| edges coef | −1.945 | −1.955 to −1.944 | −1.955 to −1.948 |
| mutual coef | −0.290 | −0.295 to −0.321 | −0.300 to −0.302 |

Coefficients agree closely across every run — good cross-validation that the
estimator lands in the right place regardless of the performance work. The
"before" and "after" columns are the same code path fit at different points in
harmonisation unit 80's own work: unit 80 replaced `ErgmGraph`'s `all_ties()`
with an incrementally-maintained live edge array (fixing TNT's own O(n+nties)-
per-proposal cost, benchmarked separately in `dev/ergm_benchmark.do` at ~129x
faster) and replaced the MCMLE convergence test's per-coordinate rule with a
genuine joint Hotelling's T² test (matching Statnet's own actual "confidence"
method) — see `docs/ERGM_ROADMAP.md`'s own Performance section and
`docs/CERTIFICATION.md`'s unit-80 entry for the full account, including one
change (a batch-means variance estimator) that was tried and directly
rejected based on evidence rather than adopted.

## Extending this suite

The user-suggested next canonical benchmarks (not yet built): a 100-node
directed `edges + mutual + nodematch`, a 100-node undirected `edges + gwesp`,
and a 500-node sparse `edges + nodematch + gwesp` — the last pair would
exercise `common_neighbors()`/`change_gwesp()` at a scale where they might
start to matter (see the per-operation benchmark in `dev/ergm_benchmark.do`).
Follow the same three-script pattern: generate-and-export, fit-and-time in
Stata, fit-and-time in R on the identical data.
