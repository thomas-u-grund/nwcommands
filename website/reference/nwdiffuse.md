---
title: "nwdiffuse"
parent: "Core command reference"
grand_parent: "Packages and reference"
nav_exclude: true
search_exclude: false
description: "Diffusion and contagion on a network: exposure, thresholds, adoption curve, hazard data, simulation"
---

# `nwdiffuse`

Diffusion and contagion on a network: exposure, thresholds, adoption curve, hazard data, simulation

## Syntax

```stata
nwdiffuse exposure [netlist], when gen:erate(stub) | cou:nt(stub) [options]
nwdiffuse threshold [netlist], when gen:erate(newvar) | cou:nt(newvar) [options]
nwdiffuse curve [netname], when [graph plot[(cumulative|new|both)] mat:rix(name) silent name(string) saving(filename) export(filename[, options]) twoway_options]
nwdiffuse long [netlist], when clear [keep(varlist) lag(#) options]
nwdiffuse simulate [netlist], model(cascade|threshold|fraction) gen:erate(newvar) [simulation options]
where when says who adopts when, either
toa(varname) the period of adoption of each node, a whole number; missing if the node never adopts, or
adopt(varlist) one 0/1 variable for each period (in the order of the periods): 1 once the node has adopted.
```

| | |
|---|---|
| `t0(#)` | first period; default: the first period in `toa()`, or 1 with `adopt()` |
| `t1(#)` | last period; default: the last period in `toa()` |
| `lag(#)` | use adoption *#* periods earlier; default 0 (`long`: 1) |
| `valued` | weight neighbours by tie values; default: ties count 0/1 |
| `inc:oming` | neighbours are the nodes with a tie *to* the node; default: the nodes the node has a tie *to* |
| `self` | count a node's own adoption as exposure (the network must allow self-loops) |
| `replace` | overwrite existing variables |
| `model(cascade)` | independent cascade; needs `prob(#)` |
| `model(threshold)` | adopt when at least `threshold(#)` neighbours have adopted (or at least the value of `thresholdvar()`) |
| `model(fraction)` | adopt when the share of adopting neighbours is at least `threshold(#)`, a number in (0,1] (or `thresholdvar()`) |
| `prob(#)` | probability that an adopter passes the behaviour on along one tie, per step |
| `thr:eshold(#)` | threshold of all nodes |
| `thresholdv:ar(varname)` | threshold of each node |
| `ns:eeds(#)` | number of initial adopters, drawn at random |
| `seedv:ar(varname)` | 0/1 variable that marks the initial adopters |
| `sp:ont(#)` | probability that a node adopts spontaneously in a step, independent of the network; default 0 |
| `steps(#)` | number of steps; default 20 |
| `seed(#)` | random-number seed |
| `valued`, `incoming`, `self`, `replace` | as above |

## Description

`nwdiffuse` prepares and simulates the diffusion of a behaviour, an innovation or an infection through a network. It follows the definitions of the R package netdiffuseR (Vega Yon and Valente), see below. In `simulate`, by default a node is influenced by the nodes it sends ties to (the nodes it has ties to), which is the reverse of the usual independent-cascade convention that a node passes the behaviour on along its outgoing ties; specify `incoming` for that direction. In `curve`, the *Rate* column is the growth of the cumulative number of adopters from the previous period to this one (new adopters divided by the cumulative number of adopters before them), not a hazard rate; it is missing (`.`) in a period with new adopters when nobody had adopted before. Observation *i* of the data set must hold node *i*, as everywhere in nwcommands. Periods are whole numbers. The network may be the same in all periods (give one network) or change (give one network for each period, in the order of the periods). Directed and undirected, binary and valued networks are allowed; two-mode networks are not. Self-loops are ignored unless `self` is given. Every call of `exposure`, `threshold`, `long` and `simulate` says how the network was read: directed (exposure from the nodes a node sends ties to, or from those it receives ties from with `incoming`) or undirected; for a valued network that the tie values are ignored (or weighted with `valued`); that self-loops were ignored when the network has some; and how many missing ties were treated as 0.

`nwdiffuse exposure` creates, for each period *t* from `t0()` to `t1()`, the variable *stub**t* (for example `expo1990`): with `generate()` the *share* of a node's neighbours that have adopted by period *t*; with `count()` their *number* (with `valued` the sum of the tie values to them). A node without neighbours has exposure 0. The node's own adoption does not count unless `self` is given. With `lag(#)`, period *t* holds the exposure of period *t*-*#* (network and adopters of that period); the first *#* periods are missing.

`nwdiffuse threshold` creates, for each adopter, its threshold: its exposure in the period it adopts (with `generate()` the share of adopting neighbours, with `count()` their number). The exposure of the adoption period includes neighbours that adopt in that same period; use `lag(1)` to count only neighbours that adopted earlier. Non-adopters, and adopters whose period lies before the first period that the lag allows, are missing.

`nwdiffuse curve` shows the adoption curve (cumulative number and proportion of adopters, growth rate and number of new adopters in each period); no network is needed. With `graph` it also draws the cumulative proportion; other `twoway` options may be added. The matrix `r(curve)` has one row per period.

`nwdiffuse long` replaces the data in memory by a person-period (discrete-time event-history) data set for hazard models: for each node one row for each period at risk, from `t0()`+`lag()` to the period of adoption (or `t1()` if the node never adopts). Variables: `node`, `period`, `adopt` (1 in the period of adoption, else 0), `exposure` (share of adopting neighbours, lagged by `lag()`, default 1) and `nexposed` (their number), plus the numeric variables of `keep()`. Nodes that have adopted by the first period at risk have no rows. Fit the hazard model with `logit` or `cloglog` on `adopt`; use `preserve` and `restore` to keep your data. Exposure is lagged by default because exposure in the period of adoption already includes that period's adopters.

`nwdiffuse simulate` runs a simple contagion in discrete steps and stores the period in which each node adopts (missing if it never does). The initial adopters (`nseeds()` random nodes or the nodes marked by `seedvar()`) adopt in period 1. In each step all decisions are taken at the same time from the state of the previous period. A step uses the network given for it (the single network, or the *s*th of the networks for step *s*).

- `cascade`: independent cascade. A node that adopted in the previous period passes the behaviour on to each of its
- (not yet adopted) neighbours with probability `prob()`, once; it never tries again. A node influenced by *c* such
- neighbours adopts with probability 1-(1-`prob()`)^*c*. Tie values are ignored.
- `threshold`: a node adopts when the number of its adopting neighbours (the sum of tie values with `valued`) reaches its threshold.
- `fraction`: a node adopts when the share of its adopting neighbours reaches its threshold. A node without neighbours never adopts this way.

With `spont()`, every node that has not adopted also adopts with that probability in each step, apart from the network. The simulation stops early when nobody can adopt any more (no new adopters and `spont()` = 0 on a single network). The default direction is that a node is influenced by the nodes it has ties to, as in `exposure`; `incoming` reverses it.

## Graph of the curve

`plot(cumulative)`, `plot(new)` and `plot(both)` choose the picture: `cumulative` (the default of `graph` and plain `plot`) is the cumulative proportion of adopters as a line, `new` is a bar chart of the new adopters in each period (whole numbers on the y axis) and `both` draws the two side by side in one graph (the options then go to `graph combine`).

`nwdiffuse curve` `graph` (or its synonym `plot`) draws the cumulative proportion of adopters. `name()` names the graph in memory (it stays unnamed when `name()`, `saving()` and `export()` are all absent), `saving()` writes a `.gph` file and `export()` writes the graph with `graph export`; the file extension sets the format and `width()` and the other `graph export` options follow a comma. A graph or file of the same name is replaced. Other options go to `twoway` and come last. `saving()` and `export()` need `graph` or `plot`.

- `. nwwebuse glasgow, nwclear`
- `. generate toa = cond(smoke1 > 1, 1, cond(smoke2 > 1, 2, cond(smoke3 > 1, 3, .)))`
- `. nwdiffuse curve, toa(toa) plot export(curve.png, width(1200))`

## Remarks

**Agreement with netdiffuseR.** Exposure (share and count, binary and valued, outgoing and incoming, with and without self, static and changing networks, with lags) and thresholds equal the results of `exposure()` and `threshold()` of netdiffuseR 1.25.1 to 9 digits on the test networks. Deviations: netdiffuseR takes the adoption times from a `diffnet` object and can weight exposure by node attributes, use structural-equivalence weights or group-wise exposure; `nwdiffuse` does not. With a lag, netdiffuseR (and so `nwdiffuse`) uses the network of the lagged period as well. The simulations are not a port of `rdiffnet()`; they implement the textbook models stated above.

**Limits.** The network is held as a dense matrix, so the commands are meant for networks up to a few thousand nodes (memory grows with the square of the number of nodes, and with one matrix for each period when the network changes). Exposure variables use one variable for each period. The time of adoption must be known exactly (no interval censoring); adoption cannot be undone (no recovery or forgetting); a node must not adopt before `t0()`.

## Examples

- Exposure and thresholds from adoption times
- `. nwclear`
- `. nwwebuse glasgow, nwclear`
- `. generate toa = cond(smoke1 > 1, 1, cond(smoke2 > 1, 2, cond(smoke3 > 1, 3, .)))`
- `. nwdiffuse exposure glasgow1, toa(toa) generate(expo) count(nexp) lag(1)`
- `. nwdiffuse threshold glasgow1, toa(toa) generate(thresh) lag(1)`
- `. nwdiffuse curve, toa(toa) graph`
- `. nwdiffuse curve, toa(toa) plot(both) export(curve.png, width(1000))`

- Hazard model of adoption with lagged exposure
- `. preserve`
- `. nwdiffuse long glasgow1, toa(toa) clear`
- `. logit adopt exposure i.period`
- `. restore`

- Simulate an independent cascade and a threshold model on a random network
- `. nwrandom 200, prob(0.03) name(rnd) directed`
- `. nwdiffuse simulate rnd, model(cascade) prob(0.2) nseeds(5) seed(1) generate(t_ic) steps(30)`
- `. nwdiffuse simulate rnd, model(fraction) threshold(0.3) nseeds(20) seed(1) generate(t_fr) steps(30)`
- `. nwdiffuse curve rnd, toa(t_ic) graph`

## Stored results

All subcommands store the scalars `r(n)` (nodes) where applicable. `exposure`: `r(t0)`, `r(t1)`, `r(periods)`, `r(lag)`. `threshold`: `r(N)` (adopters with a threshold), `r(mean)`, `r(lag)`. `curve`: `r(t0)`, `r(t1)`, `r(adopters)`, matrix `r(curve)` (columns period, adopters, proportion, rate, new). `long`: `r(rows)`, `r(events)`, `r(lag)`. `simulate`: `r(adopters)`, `r(share)`, `r(lastperiod)`, `r(model)`.

## References

Valente, T. W. 1995. *Network Models of the Diffusion of Innovations*. Cresskill, NJ: Hampton Press.

Vega Yon, G. G., and T. W. Valente. 2021. netdiffuseR: Analysis of diffusion and contagion processes on networks. R package. browse "https://CRAN.R-project.org/package=netdiffuseR"

Granovetter, M. 1978. Threshold models of collective behavior. *American Journal of Sociology* 83: 1420-1443.

Kempe, D., J. Kleinberg, and E. Tardos. 2003. Maximizing the spread of influence through a social network. *Proceedings of the 9th ACM SIGKDD*: 137-146.

## Also see

- psee
- [nwspmatrix](nwspmatrix), [nwrandom](nwrandom), [nwnode](nwnode), [nwturnover](nwturnover)

---

*nwcommands version 3.38.0, 26 November 2026* ([check your installed version](nwversion))
