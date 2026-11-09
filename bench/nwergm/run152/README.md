# nwergm 1.5.2 and 1.5.1 against ergm 4.12.0, 8 and 9 November 2026

The eight benchmark models of the nwergm article, seeds 1 to 7, one fit per process after an untimed warm-up fit;
ergm and nwergm in turn for every model and seed (`run_benchmark.sh`, `03_benchmark_fit.R`, `03_benchmark_fit.do`).
The scripts are those of the article's replication files, which also hold the network data.

- `benchmark_raw_152.txt`: nwergm 1.5.2 installed from its release tag, 9 November 2026. Lines:
  program, `@@B8`, model, seed, seconds, MCMLE iterations. `load_152.txt`: load average before each pair of fits
  (1.8 to 3.4; no other Stata or R job ran).
- `benchmark_raw_151.txt`: nwergm 1.5.1, 8 November 2026, the same machine (load average 2.4 to 4.6; no other Stata or R job ran). `load_151.txt`.
- `fixed_workload_152.txt`: one MCMLE iteration with 4,000 draws, interval 1,024, burn-in 16,384, no adaptive sample
  size, no log-likelihood (`07_fixed_workload.R`, `07_fixed_workload.do`), nwergm 1.5.2. Lines: program, model,
  seconds, proposals, microseconds per proposal.

Machine: Apple M5 Pro, macOS, Stata 18 BE, R 4.6.0, ergm 4.12.0, nwcommands core 3.17.2.
