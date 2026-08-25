# nwergm vs. R ergm() head-to-head benchmark suite

Development-only benchmark suite (not shipped, not in any `_pkg_*.txt` manifest,
matching `dev/ergm_reference/`'s own convention). Compares `nwergm`'s wall-clock
time and coefficient/SE agreement against Statnet's own `ergm()` (R) on an
**identical** exported network, fit with each tool's own default settings — the
most realistic "how long does this actually take a real user" comparison.

## Files

Five canonical benchmarks, each following the same pattern: generate once (fixed
seed) and export identically for both tools, fit via `nwergm` with default
control settings (Stata script), fit via `ergm()` with default control
settings (R script). Numbered by benchmark: `0x` = 30-node original, `1x` =
100-node directed, `2x` = 100-node undirected GWESP, `3x` = 500-node sparse,
`4x` = 1000-node control.

- `01_generate_network.do` / `02_bench_stata.do` / `03_bench_r.R` — **benchmark
  1**: 30-node directed, `edges + mutual`. `bench_net.csv` (30×30, 105 ties).
- `04_profile_breakdown.do` — coarse time-breakdown of a real MCMLE run on
  benchmark 1's own network: one MCMC simulation call vs. the full outer loop,
  isolating controller/variance overhead by subtraction (no shipped function
  modified). Result: ~94% of wall time is genuine MCMC simulation, ~6%
  everything else.
- `05_iteration_variability.do` — refits benchmark 1's network 20 times at
  different seeds to characterize how much the MCMLE iteration count (and
  hence wall time) varies from pure Monte Carlo noise alone.
- `10_bench_100dir.do` / `11_bench_100dir_r.R` — **benchmark 2**: 100-node
  directed, `edges + mutual + nodematch`. `net100dir.csv` + `attr100dir.csv`.
- `20_bench_100undir_gwesp.do` / `21_bench_100undir_gwesp_r.R` — **benchmark
  3**: 100-node undirected, `edges + gwesp(0.5, fixed)`. `net100undir.csv`.
- `30_bench_500sparse.do` / `31_bench_500sparse_r.R` — **benchmark 4**:
  500-node sparse undirected, `edges + nodematch + gwesp`. `net500.csv` +
  `attr500.csv`.
- `40_bench_1000dir_control.do` / `41_bench_1000dir_control_r.R` — **benchmark
  5** (dyad-dependent control, no GWESP): 1000-node directed,
  `edges + mutual + nodematch`. `net1000.csv` + `attr1000.csv`. Loads via a
  direct Mata-to-`st_store()` edgelist construction rather than the
  import/reshape path the smaller benchmarks use — Stata BE's own
  `c(maxvar)=2048` hard cap breaks the wide-CSV/`reshape long` approach at
  1000+ columns (see the script's own header comment).
- `50_microbench_primitives.do` — isolates nwergm's own Mata primitives
  (`has_edge`/`toggle`/`ergm_propose_tnt`/each `change_*` term/
  `common_neighbors`/`neighbors_out`) at realistic sparse degree, used to
  pin the harmonisation-unit-83 GWESP gap on Mata's own per-call overhead
  before writing any native code.
- `60_verbose_500sparse_r.R` — runs Statnet's own `ergm()` with
  `verbose=TRUE` on benchmark 4's exact network, capturing its real
  per-iteration MCMLE trace (theta, gradient, T²/degrees of freedom) - the
  basis for harmonisation unit 84's direct iteration-by-iteration
  comparison against `nwergm`'s own `verbose` output that root-caused the
  convergence-at-scale problem.

`nwset`'s own `mat()` option has a real, documented bug with bare Stata matrix
names (`docs/CERTIFICATION.md`'s own Pending list) that a literal-expression
workaround doesn't scale past ~30 nodes either — every Stata-side script here
loads via `nwset`'s edgelist input path instead, either via `import
delimited`/`reshape long` (benchmarks 1-4) or direct Mata `st_store()`
(benchmark 5, for the `maxvar` reason above).

## Running it

```
cd nwcommands_2016
/Applications/Stata/StataBE.app/Contents/MacOS/StataBE -e do "dev/ergm_benchmark_r_vs_stata/02_bench_stata.do"
Rscript dev/ergm_benchmark_r_vs_stata/03_bench_r.R
```

(substitute any of the numbered pairs above for a different benchmark). Both
print wall time, coefficients, and convergence status. Stata's log goes to
`<scriptname>.log` in the working directory (delete it before re-running, or
Stata will refuse to overwrite) — the CSV/attribute files also need deleting
before a Stata re-run, since `fopen(...,"w")` errors if the file already
exists (each generation script's own `capture erase` line handles this).

## Results

**Benchmark 1** (harmonisation unit 80): the original 30-node case, tracked
across the two fixes that unit made:

| | R `ergm` 4.12.0 | `nwergm` before unit 80 | `nwergm` after unit 80 |
|---|---|---|---|
| Wall time | 0.29s | 163.18s | 6.6–7.0s (typical), as low as 1.8s on some seeds |
| MCMLE iterations | 1 | 10–20 (sometimes hit the cap without converging) | 1–7 |
| edges coef | −1.945 | −1.955 to −1.944 | −1.955 to −1.948 |
| mutual coef | −0.290 | −0.295 to −0.321 | −0.300 to −0.302 |

Unit 80 replaced `ErgmGraph`'s `all_ties()` with an incrementally-maintained
live edge array (fixing TNT's own O(n+nties)-per-proposal cost, ~129x faster
per `dev/ergm_benchmark.do`) and replaced the MCMLE convergence test's
per-coordinate rule with a genuine joint Hotelling's T² test (matching
Statnet's own actual "confidence" method) — a batch-means variance estimator
was also tried and directly rejected based on evidence. See
`docs/CERTIFICATION.md`'s unit-80 entry for the full account.

**All five benchmarks** (harmonisation unit 81, current code):

| Benchmark | R `ergm` | `nwergm` | Ratio | nwergm converged? |
|---|---|---|---|---|
| 1: 30-node directed, edges+mutual | 0.29s | 6.6-7.0s | ~23-25x | yes |
| 2: 100-node directed, edges+mutual+nodematch | 0.484s | 13.746s | ~28.4x | yes (12 iter) |
| 3: 100-node undirected, edges+gwesp | 0.326s | 22.065s | ~67.7x | yes (5 iter) |
| 4: 500-node sparse, edges+nodematch+gwesp | 2.293s | 93.174s | ~40.6x | no (hit cap) |
| 5: 1000-node directed CONTROL (no gwesp) | 9.177s | 27.762s | **~3.0x** | no (hit cap) |

Coefficients agreed closely with R on every benchmark, including the two that
did not converge within the default 20-iteration cap. **The pattern is
clear**: GWESP-involving models (3, 4) sit at 40-68x; the GWESP-free control
(5), even at 10x the node count of benchmark 1, sits at ~3x. The remaining
gap concentrates specifically in the shared-partner machinery
(`common_neighbors()`/`change_gwesp()`), not in raw node count or the MCMLE
controller generally — `04_profile_breakdown.do` separately confirmed ~94%
of a real MCMLE run's wall time is genuine MCMC simulation, leaving no large
hidden inefficiency in the outer loop to chase. See `docs/ERGM_ROADMAP.md`'s
own Performance section for the full decision-framework writeup.

**A genuine large-N scaling bug was found and fixed while building benchmark
5**: `nwergm.ado`'s own MPLE design-matrix construction routed through an
intermediate Stata MATRIX (`st_matrix()`), which does not complete in any
reasonable time once row count reaches the hundreds of thousands (confirmed
via an isolated test: a bare `st_matrix()` call on a 999,000-row matrix did
not finish within 2 minutes, where the equivalent `st_store()` call on
identical data took 0.008 seconds) — this was blocking ANY directed model at
a few hundred nodes or more, regardless of which ERGM terms were used. Fixed
by routing the design matrix directly through `st_store()`; benchmark 5 went
from not completing after 35+ minutes to 27.8 seconds. See
`docs/CERTIFICATION.md`'s unit-81 entry and `docs/ERGM_ARCHITECTURE.md`'s
integration-layer section for the full account and the general principle
(`st_store()` for anything scaling with the network, `st_matrix()` only for
small model-sized structures).

**Incremental shared-partner cache tried and rejected for these networks
(harmonisation unit 82)**: the obvious next lever after unit 81 — an O(1)
incrementally-maintained shared-partner cache for `common_neighbors()`,
replacing the O(min(deg_i,deg_j)) on-demand scan `change_gwesp()` calls on
every proposal — was built, certified fully correct (brute-force
cross-checks plus end-to-end change-statistic equivalence, both cache-on and
cache-off), wired into `nwergm.ado`, and re-benchmarked directly. It made
things **worse**, not better: benchmark 3 went from 22.065s to ~39.3s in a
controlled A/B test. Root cause, fully diagnosed rather than guessed at: TNT's
own Metropolis-Hastings acceptance rate on a converged, well-fitted sparse
model is very high (measured 92.9% on the real benchmark-3 model), so
`toggle()`'s own O(deg_i+deg_j) cache-maintenance cost (two `neighbors_out()`
calls, each allocating a fresh array, plus the cache-adjustment loops) fires
on nearly every single proposal — and at these networks' actual degree
(~4-6), that maintenance cost exceeds the O(1) lookup's own savings. A
systematic degree sweep (n=200, matched acceptance rate) found the crossover
to a net win sits around degree ~30-40+, well above what any of these five
benchmark networks have. **The cache was reverted (not wired by default)**;
the fully-correct machinery remains in `unw_ergm.do`, certified via
`cscripts/test_nwergm_spcache.do`, available for a future degree-aware
auto-enable heuristic or explicit opt-in on genuinely dense networks. See
`docs/CERTIFICATION.md`'s unit-82 entry for the full root-cause chain and
`docs/ERGM_ROADMAP.md`'s Performance section for the updated decision
framework this finding produces for the C++ question.

**Native (C) MCMC backend (harmonisation unit 83)**: per the user's own
explicit relaxation of this project's earlier Mata-first default (unit 82's
own finding that the shared-partner cache did not close the GWESP gap
satisfied the user's own stated conditional for reaching for C/C++), a
genuine Stata C plugin (`native/ergm_mcmc.c`) now implements the entire
MCMC sampling loop for the four terms this suite exercises
(edges/mutual/nodematch/gwesp), auto-selected whenever a model is eligible
and the compiled plugin is present, with the full Mata implementation kept
as the always-available reference/fallback. Re-running all five benchmarks
with the native backend engaged, same default settings, only the backend
changed:

| Benchmark | R `ergm` | nwergm (unit 81, Mata) | nwergm (unit 83, native) | Ratio now | Was |
|---|---|---|---|---|---|
| 1: 30-node directed, edges+mutual | 0.29s | 6.6-7.0s | **0.311s** | ~1.07x | ~23-25x |
| 2: 100-node directed, edges+mutual+nodematch | 0.484s | 13.746s | **0.495s** | ~1.02x | ~28.4x |
| 3: 100-node undirected, edges+gwesp | 0.326s | 22.065s | **0.419s** | ~1.29x | ~67.7x |
| 4: 500-node sparse, edges+nodematch+gwesp | 2.293s | 93.174s | **3.932s** | ~1.72x (still hits the iteration cap) | ~40.6x |
| 5: 1000-node directed CONTROL (no gwesp) | 9.177s | 27.762s | **4.883s** | ~0.53x (faster than R) | ~3.0x |

Coefficients/standard errors are unchanged in character from the Mata
backend (the native backend changes execution speed, not the statistical
model) and were cross-certified against the Mata reference via
`cscripts/test_nwergm_native.do` (statistical equivalence of sampled
distributions from an identical starting network/theta, plus a
self-consistency check that the network the plugin hands back genuinely
matches the statistics it reports). Benchmarks 4 and 5 still hit the
default 20-iteration MCMLE cap without converging - unchanged from unit 81,
since the native backend accelerates each iteration, not the number of
iterations MCMLE needs; investigating that is a separate, not-yet-started
item (see `docs/ERGM_ROADMAP.md`'s Performance section). See
`docs/CERTIFICATION.md`'s unit-83 entry for the full design, the fresh
verification against Statnet's own current C source, and the Mata
microbenchmark (`50_microbench_primitives.do`) that pinned the GWESP gap on
interpreter overhead rather than an algorithmic difference before any C
code was written.

**MCMLE convergence-at-scale root-caused and fixed (harmonisation unit
84)**: benchmarks 4 and 5 hitting the 20-iteration cap (still true after
unit 83's native backend - that unit made each iteration faster, not the
iteration count itself lower) turned out to be an invalid statistical test,
not a stuck optimizer or a slow sampler. A real, verbose Statnet trace on
the identical benchmark-4 network (`60_verbose_500sparse_r.R`) showed
Statnet's own "confidence" convergence test uses an autocorrelation-
discounted EFFECTIVE sample size as its own F-test degrees of freedom
(non-integer, far below its raw recorded draw count, growing across
iterations) - `nwergm`'s own equivalent test used the RAW `mcmcsamplesize`
directly, which - given the same MCMC chain is thinned, not fully
decorrelated - made its own implied confidence region far too tight to ever
contain a genuinely converged estimate. `nwergm`'s own `verbose` output on
the same network confirmed theta was already tracking Statnet's converged
value from iteration 1; only the pass/fail TEST was broken. Fixed by
applying the same lag-1-autocorrelation correction the final variance step
already used one iteration earlier - inside the per-iteration test itself.
Result, same five benchmarks, only this fix added on top of the native
backend:

| Benchmark | R `ergm` | nwergm (unit 83, native) | nwergm (unit 84, +convergence fix) | Iterations |
|---|---|---|---|---|
| 1: 30-node directed, edges+mutual | 0.29s | 0.311s | **0.278s** | 1 (was ~1-7) |
| 2: 100-node directed, edges+mutual+nodematch | 0.484s | 0.495s | **0.306s** | 1 |
| 3: 100-node undirected, edges+gwesp | 0.326s | 0.419s | **0.405s** | 1 |
| 4: 500-node sparse, edges+nodematch+gwesp | 2.293s | 3.932s (capped, unconverged) | **2.785s** | 1 (was 20, unconverged) |
| 5: 1000-node directed CONTROL (no gwesp) | 9.177s | 4.883s (capped, unconverged) | **3.267s** | 1 (was 20, unconverged) |

All five benchmarks now converge properly (none hit the iteration cap) and
run faster still, since a converged 1-2 iteration fit is less total MCMC
work than a full, unconverged 20-iteration run. See `dev/ergm_benchmark_r_vs_stata/60_verbose_500sparse_r.R`
for the real Statnet trace this diagnosis was based on and
`docs/CERTIFICATION.md`'s unit-84 entry for the full account.

**Adaptive interval closes the mixing-quality open question (harmonisation
unit 85)**: unit 84's own fix could correctly report "converged" from a
genuinely tiny effective MCMC sample size (35.7 out of 3000 raw draws on
benchmark 4 at the then-fixed default `mcmcinterval`) - statistically
valid, but leaving real precision on the table, exactly mirroring Statnet's
own directly-observed behavior of growing its own interval ("New interval =
512" then "1024") when its test isn't yet trustworthy. `ErgmMCMLE()` now
grows `interval` (never shrinks it) whenever the achieved effective sample
size falls short of a target floor (`max(200, 64*nparam)`, mirroring
Statnet's own documented `MCMLE.effectiveSize=64`-per-parameter target),
and only declares convergence once both the Hotelling test passes AND that
floor is met. Small/well-mixing models (benchmarks 1 and 3) never trigger
it at all - confirmed via a dedicated regression test
(`cscripts/test_nwergm_adaptive_interval.do`) that growth does NOT fire
under nwergm's own actual production defaults. Re-running the full suite
with this fix added on top of unit 84:

| Benchmark | R `ergm` | nwergm (unit 84) | nwergm (unit 85, +adaptive interval) | Iterations | Final interval |
|---|---|---|---|---|---|
| 1: 30-node directed, edges+mutual | 0.29s | 0.278s | 0.365s | 1 | 50 (unchanged) |
| 2: 100-node directed, edges+mutual+nodematch | 0.484s | 0.306s | 0.352s | 2 | grown |
| 3: 100-node undirected, edges+gwesp | 0.326s | 0.405s | 0.416s | 1 | 50 (unchanged) |
| 4: 500-node sparse, edges+nodematch+gwesp | 2.293s | 2.785s | **3.744s** | 3 | 50→300→600 |
| 5: 1000-node directed CONTROL (no gwesp) | 9.177s | 3.267s | **3.989s** | 3 | grown |

All five still converge in 1-3 iterations at well under 4 seconds even for
the largest networks, but benchmark 4's own fitted `gwesp` coefficient
moved from 0.0179 (unit 84, single iteration, low effective sample size)
to 0.0363 - much closer to Statnet's own 0.0371 - confirming the extra
iterations bought real precision, not just a slower path to the same
answer. See `docs/CERTIFICATION.md`'s unit-85 entry for the full account.

**Native backend scope relaxation - term-expansion benchmarks (harmonisation
unit 92)**: per the user's own explicit instruction ("run various models
with benchmarks to R code... just an example of effects... do not benchmark
beyond 10000 nodes"), three new benchmarks (6-8) each exercise one of the
three native-backend waves unit 92 added - NOT an exhaustive combinatorial
sweep, one representative example per wave, all comfortably under the
stated 10,000-node ceiling:

- **Benchmark 6** (`80_bench_mixed_stata.do`/`81_bench_mixed_r.R`): 1000-node
  sparse undirected, `edges + gwesp + nodefactor + nodecov` - exactly the
  "gwesp mixed with other terms" case that used to force nwergm's own native
  backend to fall back to Mata entirely (wave 1: the attribute/factor
  family).
- **Benchmark 7** (`83_bench_degreefam_stata.do`/`84_bench_degreefam_r.R`):
  2000-node sparse directed, `edges + mutual + nodematch + odegree(2) +
  idegree(2) + gwodegree + gwidegree` - several degree-count-family terms at
  once (wave 2).
- **Benchmark 8**
  (`85_bench_sharedpartner_stata.do`/`86_bench_sharedpartner_r.R`):
  1000-node sparse undirected, `edges + gwesp + gwnsp` - the shared-partner
  family beyond gwesp itself (wave 3). NOT `edges+gwesp+gwdsp+triangle` (tried
  first): those three are near-duplicate measures of the same clustering
  structure, and on a sparse, near-triangle-free random network they are
  collinear enough that the MPLE design matrix (always built first, as
  MCMLE's own starting value) fails to converge - a genuine statistical
  degeneracy from that specific term COMBINATION on this specific network,
  not a code bug (each term is independently certified via
  `cscripts/test_nwergm_native.do`). `gwnsp` is a natural complement to
  `gwesp` (untied- vs tied-dyad shared partners) rather than a near-duplicate,
  avoiding the pitfall while still exercising the exact same wave-3
  composition dispatch (`gwnsp = gwdsp - gwesp`) in `native/ergm_mcmc.c`.

| Benchmark | Terms | n | R `ergm` | `nwergm` (native) | Ratio | Coefficients (nwergm vs. R, selected) |
|---|---|---|---|---|---|---|
| 6 | edges+gwesp+nodefactor+nodecov | 1000 | 9.10s | 13.65s | ~1.5x | edges: −5.097 / −5.097; gwesp: 0.0296 / 0.0271 |
| 7 | edges+mutual+nodematch+odegree(2)+idegree(2)+gwodegree+gwidegree | 2000 | 18.63s | 33.76s | ~1.8x | edges: −5.797 / −5.800; mutual: 0.294 / 0.303; gwodegree: −0.293 / −0.289 |
| 8 | edges+gwesp+gwnsp | 1000 | 6.13s | 107.80s | ~17.6x | edges: −5.045 / −5.047; gwesp: −0.0219 / −0.0276; gwnsp: −0.0056 / −0.0056 |

All three converged (MCMLE iterations: 4, 8, 6 respectively) and every
coefficient agrees closely with R's own fit - the native relaxation changes
execution speed and eligibility, never the statistical model. Timing ratios
for benchmarks 6-7 (~1.5-1.8x) are in the same "near parity" range the
original four native terms achieved back in unit 83 - direct evidence the
relaxation genuinely delivered what the user asked for on the everyday case
of mixing gwesp with covariate/degree terms. **Benchmark 8's own much larger
gap (~17.6x) is disclosed honestly, not glossed over**: the native backend
(unit 92, all three waves) accelerates ONLY the MCMC simulation loop itself
- the one-time MPLE design-matrix construction and the observed-network
statistic computation still run entirely in Mata regardless of native
eligibility (see `docs/ERGM_ARCHITECTURE.md`'s own "native boundary crossed
once per `ErgmMCMCSample()` call" design), and `gwdsp`/`gwnsp`'s own
`stat_gwdsp()` genuinely needs an O(n²) full-dyad Mata enumeration
(`docs/ERGM_ROADMAP.md`'s own unit-88 finding, unrelated to this unit) - at
n=1000 that is 499,500 dyads, each needing a `common_neighbors()` call, paid
in interpreted Mata every time the design matrix or the observed baseline is
(re)built. This is a genuine, disclosed remaining gap - not something this
unit's own native work claims to have closed - and a natural candidate for
a FUTURE wave (porting the design-matrix/observed-statistic construction
itself, not just the MCMC change-statistic, for the O(n²) term family).

## Extending this suite

Further ideas: force convergence on benchmarks 4/5 (e.g. raise
`mcmleiterations()`) to get an apples-to-apples ratio uninflated by hitting
the iteration cap; a directed GWESP-equivalent benchmark once directed
shared-partner terms exist (roadmap item); a benchmark exercising `edgecov()`
at scale; investigate accelerating `build_mple_data()`/the observed-statistic
computation for the O(n²) `gwdsp`/`gwnsp`/`esp`/`dsp` term family specifically
(benchmark 8's own disclosed remaining gap, above) now that their MCMC
change-statistics are native. Follow the same generate/fit-Stata/fit-R
three-file pattern.
