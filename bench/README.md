# Benchmarks: the model packages against R

Scripts, data and raw timings behind the website page
[Speed compared with R](https://nwcommands.org/nwcommands/speed/). Measured on 26 and 27 October 2026 on an
Apple M5 Pro, macOS, Stata 18 BE, R 4.6.0. All timings are with Stata 18; Stata 17 was not timed. The nwergm timings are of version 1.3.0 (1.3.1 was not timed again).

| Comparison | Versions |
|---|---|
| nwergm against ergm | nwergm 1.3.0 (and 1.2.3), ergm 4.12.0 |
| nwsaom against RSiena | nwsaom 1.1.1 (27 October; the run of nwsaom 1.1.0 of 26 October is kept), RSiena 1.6.14 |
| nwrem against relevent | nwrem 1.0.10, relevent 1.2-1 (`hessian = TRUE` and `FALSE`) |
| nwdynam against goldfish | nwdynam 1.2.0, goldfish 1.6.12 (engines `default`, `default_c`, `gather_compute`) |

All with nwcommands core 3.10.0.

## What is in this folder

| Folder | Content |
|---|---|
| `raw/` | One row per timed fit: package, model (cell), implementation, repeat, status, one-minute load average before the fit, number of other R or Stata processes, seconds, convergence flag, estimates and standard errors, versions, start time. |
| `summary/` | Medians, ranges, ratios, convergence counts, agreement of the estimates and load statistics, made from `raw/` by `scripts/aggregate_all.py`. |
| `scripts/` | The drivers (`plan_*.py`, `benchlib.py`), one script per fit (`saom_one.R`, `saom_one.do`, `rem_one.R`, `rem_nw.do`, `dynam_gf.R`, `dynam_nw.do`), the model definitions, the data generators (`gen_rem.R`, `gen_dynam.R`) and the aggregation. |
| `data/` | The networks and event logs of the nwsaom, nwrem and nwdynam comparisons. |
| `raw/saom111/` | The nwsaom 1.1.1 run of 27 October (`saom_main.csv`, `saom_extra.csv`, `saom_cores.csv`), the two calibration series, the fits that were discarded after the laptop went to sleep, and the record of foreign R or Stata processes. `summary/saom111_main.csv` and `summary/saom111_extra.csv` hold the medians. `raw/saom_*.csv` without this folder are the 1.1.0 run. |
| `nwergm/idle/` | The nwergm run (`idle_all.csv`: 168 fits) and its scripts. |
| `nwergm/scripts/`, `nwergm/networks/` | The earlier nwergm benchmark scripts and the eight benchmark networks (three large ones are gzipped). |

## How each fit was timed

Each fit runs in its own process, after an untimed warm-up fit in the same process. The timer covers the
estimation call only. The programs run in turn (R, Stata, R, Stata, ...), one process at a time, 7 repeats
(fewer for fits over 60 seconds), each with a kill switch of 600 seconds. A fit that hits the kill switch is
recorded as a time-out. The load average before each fit is in `raw/`.

## How to repeat a comparison

The scripts take their locations from environment variables, not from fixed paths. Set `BENCH` to this folder
and `SCR` to a scratch folder that holds a clean `PLUS` directory and the installed trees (core, packages), and
`STATA` to the Stata binary if it is not in the default place (the R scripts expect `Rscript` at
`/usr/local/bin/Rscript`; edit `RSCRIPT` at the top of the `plan_*.py` files otherwise). The nwergm scripts need
`SCR` as well. The machine should have no other R or Stata process running.

- nwsaom against RSiena: `BENCH=... SCR=... python3 scripts/plan_saom.py main` (also `extra` and `cores`); the 1.1.1 run used `scripts/plan_111.py` (`small`, `large`, `extra`, `cores`).
- nwrem against relevent: `Rscript scripts/gen_rem.R`, then `python3 scripts/plan_rem.py`.
- nwdynam against goldfish: `Rscript scripts/gen_dynam.R`, then `python3 scripts/plan_dynam.py`.
- nwergm against ergm: `zsh nwergm/idle/drive.sh` (needs the networks of `nwergm/networks/` and both nwergm versions).
- Summaries: `python3 scripts/aggregate_all.py` rewrites `summary/` from `raw/`.

## Licence

GNU General Public License, version 3, like the packages. The Glasgow data are those of RSiena. The simulated
event logs and generated networks come from the generator scripts.
