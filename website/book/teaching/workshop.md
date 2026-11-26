---
title: "Six-hour workshop"
parent: "Teaching and workshops"
nav_order: 1
description: "A six-hour workshop in two sessions for network researchers who are new to Stata or to nwcommands: the core workflow, then ERGMs with nwergm and SAOMs with nwsaom, with an optional third session on relational events with nwrem and nwdynam; the book's data and commands."
permalink: /book/teaching/workshop/
---

# Six-hour workshop
{: .no_toc }

A workshop in two sessions of three hours, for researchers who know network
analysis and often work in R (`statnet`/`ergm`, `RSiena`, `igraph`), but may be new to Stata or to nwcommands.
The workshop therefore spends no time on what a network or a centrality measure is. It shows how the work is
done in Stata: networks as objects next to the data, measures as variables, Stata's own commands on them, and the
model packages `nwergm` and `nwsaom`.

- **Session 1 (3 hours):** the nwcommands core.
- **Session 2 (3 hours):** ERGMs with `nwergm` and SAOMs with `nwsaom`.
- **Session 3 (3 hours, optional):** relational events with `nwrem` and `nwdynam`.

**Slides.** PowerPoint decks for all three sessions, with speaker notes. Instructors are free to use, adapt and share
them.

- Session 1, the nwcommands core: [PowerPoint](/book/teaching/slides/session1_nwcommands_core.pptx) ·
  [PDF](/book/teaching/slides/session1_nwcommands_core.pdf)
- Session 2, ERGMs and SAOMs: [PowerPoint](/book/teaching/slides/session2_ergm_saom.pptx) ·
  [PDF](/book/teaching/slides/session2_ergm_saom.pdf)
- Session 3 (optional), relational events: [PowerPoint](/book/teaching/slides/session3_relational_events.pptx) ·
  [PDF](/book/teaching/slides/session3_relational_events.pdf)

Every demonstration uses the data and the commands of the book's chapters. Exercises are cited as
"Ch. 8, Ex. 2", numbered as in the book. The R column of Appendix C of the book (*Commands by task, with R and
Python equivalents*) gives the R functions quoted below.

1. TOC
{:toc}

## Setup

The software needs Stata 17 or later. Stata/BE, the smallest edition, runs every example in the book. Install the
complete collection as described in *Getting started*:

```stata
. net install nwcommands, from(https://nwcommands.org/net/) replace
. nwinstall, everything
```

The first command installs a small starter package; `nwinstall` fetches the rest, including the seven model
packages `nwergm`, `nwsaom`, `nwrem`, `nwdynam`, `nwalaam`, `nwlsm` and `nwsbm`. Appendix B of the book covers installation problems.

All data sets are loaded over the internet with `nwwebuse`, so the room needs a working internet connection. The
[do-files of the book](../../dofiles/) contain every printed command, chapter by chapter, and can be handed out
as the demonstration scripts.

### Before the workshop
{: .no_toc }

Send participants this list:

1. Install Stata 17 or later (any edition).
2. Run the two installation commands above.
3. Check that the model packages are there: `which nwergm` and `which nwsaom`.
4. Check that data can be loaded and drawn: `nwwebuse florentine, nwclear` and then `nwplot flomarriage`.
5. Participants new to Stata: be able to open and run a do-file and to use `use`, `generate`, `tabulate`,
   `summarize` and `regress`. The book assumes that readers know Stata.
6. Optional: download the do-files of Chapters 4, 6, 8, 18 to 21 and 25.

## Session 1: the nwcommands core (3 hours)

| Time | Block |
|---|---|
| 0:00–0:15 | 1. Networks next to the data |
| 0:15–0:50 | 2. Getting networks in and out |
| 0:50–1:25 | 3. Pictures and whole-network description |
| 1:25–1:40 | Break |
| 1:40–2:15 | 4. Measures as variables, and regression |
| 2:15–2:50 | 5. Permutation tests, QAP and CUG |
| 2:50–3:00 | 6. Reproducible scripts, questions |

### 1. Networks next to the data (15 min)
- **Goal:** see the basic design. A network is declared once and kept as an object beside the data set in memory;
  node attributes are ordinary variables, one row per node; every command finds a network by name.
- **Demo:**
  ```stata
  . nwwebuse florentine, nwclear
  . nwplot flomarriage
  . nwwebuse lazega, nwclear
  . nwsummarize lazega_*
  . describe
  ```
- **For R users:** where `igraph` keeps attributes inside the graph object, here they are variables of the data
  set, so `tabulate`, `regress` and the rest of Stata work on them directly.
- **Read afterwards:** *Getting started*; Chapter 4.

### 2. Getting networks in and out (35 min)
- **Goal:** declare a network from an edge list or a matrix, build one from a wide survey export, keep several
  networks of the same actors, save and reload them. Know the two traps: `clear` does not remove networks
  (`nwclear` does), and an edge list loses isolates unless they get a row of their own.
- **Demo (Chapter 4):** `nwset` with an edge list and with `mat()`; the survey example from `reshape long` to
  `nwfromedge ..., undirected`; `nwimport`; wildcards such as `lazega_*` and `*_adv`; `nwsave`, `nwuse`, `nwload`;
  `nwsubset lazega_adv if office == "Hartford", name(hartford)`; `nwsymmetrize` with `mode(min)` and `mode(max)`.
- **R equivalents (Appendix C):** `graph_from_data_frame()`, `graph_from_adjacency_matrix()`, `read_graph()`,
  `write_graph()`.
- **Hands-on:** Ch. 4, Ex. 1 (declare a five-person network from a matrix); Ch. 4, Ex. 3 (wildcards, `nwsave`,
  `nwuse` and `nwname`).
- **Read afterwards:** Chapter 4; Chapter 3 on construction decisions (the OR and AND rules).

### 3. Pictures and whole-network description (35 min)
- **Goal:** draw a network with attributes mapped to color and symbol, fix coordinates to compare pictures, write
  an interactive page; describe a network with the dyad and triad census and mixing tables.
- **Demo (Chapters 5 and 6):**
  ```stata
  . nwplot lazega_adv, color(office)
  . nwplotmatrix lazega_adv, group(office) scheme(s1mono)
  . nwdyads lazega_adv
  . nwtriads lazega_adv
  . nwmixing lazega_adv, attribute(office)
  . nwassortativity lazega_adv, attribute(age)
  ```
  and from Chapter 5 an interactive page with `nwplot ..., interactive` and coordinates kept with `generate(x y)`.
- **R equivalents:** `plot()`, `reciprocity()`, `dyad_census()`, `triad_census()`, `assortativity_nominal()`.
- **Hands-on:** Ch. 5, Ex. 3 (status as color, practice as symbol); Ch. 6, Ex. 3 (the work network beside advice
  and friendship).
- **Read afterwards:** Chapters 5 and 6.

### 4. Measures as variables, and regression (35 min)
- **Goal:** compute node-level measures into variables and use them with Stata's own commands.
- **Demo (Chapters 8 and 11):**
  ```stata
  . nwdegree lazega_adv, generate(adv_out adv_in) silent
  . tabstat adv_in adv_out, by(partner) statistics(mean sd n)
  . nwcloseness lazega_adv, generate(clo far near)
  . nwbetween lazega_adv, generate(_between)
  . nwburt lazega_adv
  . nwbrokerage lazega_adv, generate(brk) group(officenum)
  . nwego lazega_adv, sizevar(egosize) densvar(egodens)
  ```
  then `regress` on the new variables; from Chapter 11, exposure to smoking friends in the Glasgow data with
  `nwaltergen frsmoke = proportion(alter.smoker1==1), net(glasgow1)`, after coding `smoker1` from `smoke1` as the
  chapter does, and a regression of later smoking on it.
- **Points to make:** say whether ties are counted in their direction (`nwcloseness` and `nwbetween` follow the direction
  of the ties of a directed network; the option `sym` symmetrizes); closeness needs a rule for unreachable pairs (`unconnected()`); `nwkatz` sums over shortest-path
  distances unless `walks` is given.
- **R equivalents:** `degree()`, `closeness()`, `betweenness()`, `constraint()`, `sna::brokerage()`,
  `make_ego_graph()`.
- **Hands-on:** Ch. 8, exercise bank 8.c (tenure as a rival source of a high in-degree); Ch. 8, exercise bank 8.f (does the status
  difference in constraint survive?); if time allows, Ch. 11, Ex. 4 (the exposure regression one wave later).
- **Read afterwards:** Chapters 7, 8 and 11.

### 5. Permutation tests, QAP and CUG (35 min)
- **Goal:** test a statistic against random networks of the same size and density, a correlation of two networks
  against relabeling, and a dyadic regression with permutation p-values.
- **Demo (Chapters 18 to 20):**
  ```stata
  . nwcug lazega_adv, stat(nwdyads) rname(reciprocity) reps(1000) seed(12345) condition(density)
  . nwcorrelate lazega_adv lazega_fr, permutations(1000)
  . nwmixing lazega_adv, attribute(office) permutations(1000)
  . set seed 12345
  . nwqap lazega_adv lazega_fr office practice status, permutations(500) plot
  ```
  then `condition(census)` and `condition(degrees)` for the same test, and `qapspp` for the QAP model.
- **Points to make:** the conditioning choice defines the question; the plus-one two-sided p-value cannot be
  smaller than 2/(*R*+1); a QAP table has no z column, because its p-values come from refitting the model on
  permuted networks.
- **R equivalents:** `sna::cug.test()`, `sna::qaptest()`, `sna::netlm()`.
- **Hands-on:** Ch. 19, Ex. 4 (advice and co-work); Ch. 20, Ex. 4 (the advice model without friendship);
  Ch. 18, Ex. 3 (the friendship network's null mean).
- **Read afterwards:** Chapters 18, 19 and 20.

### 6. Reproducible scripts, questions (10 min)
- **Goal:** set seeds, save layout coordinates, and chain commands through stored results (`return list` after
  `nwcug`, `ereturn list` after `nwqap`) instead of retyping numbers.
- **Read afterwards:** Chapter 30; Appendix C for the full table of commands with R and Python equivalents.

## Session 2: ERGMs and SAOMs (3 hours)

| Time | Block |
|---|---|
| 0:00–0:10 | 1. The model packages |
| 0:10–0:55 | 2. Specifying and estimating an ERGM |
| 0:55–1:30 | 3. Diagnosing an ERGM, and simulating from it |
| 1:30–1:45 | Break |
| 1:45–2:25 | 4. Specifying, estimating and checking an SAOM |
| 2:25–2:50 | 5. Score tests and co-evolution |
| 2:50–3:00 | 6. What else the packages do |

### 1. The model packages (10 min)
- **Goal:** place the packages. `nwergm` follows the R package `ergm` of the statnet project and implements 125 of
  its 139 terms, most with R's names, arguments and defaults; the book calls `ergm` the reference and the more
  complete program. `nwsaom` is derived from `RSiena` and `multiSiena` and checks its results against
  `RSiena::siena()`. Both are installed by `nwinstall, everything`.
- **Read afterwards:** the opening sections of Chapters 21 and 25.

### 2. Specifying and estimating an ERGM (45 min)
- **Goal:** build the advice model of the law firm in stages, and read a coefficient as the change in the
  conditional log-odds of one tie, given the rest of the network.
- **Demo (Chapter 21):**
  ```stata
  . nwwebuse lazega, nwclear
  . nwergm lazega_adv, edges seed(12345)
  . nwergm lazega_adv, edges nodematch(office practice) ///
          nodeofactor(status) nodeifactor(status) seed(12345)
  . nwergm lazega_adv, edges mutual nodematch(office practice) ///
          nodeofactor(status) nodeifactor(status) seed(12345)
  . nwergm lazega_adv, edges mutual nodematch(office practice) ///
          nodeofactor(status) nodeifactor(status) gwesp(.5) seed(12345)
  ```
  With `edges` alone the coefficient is the log-odds of the density, ln(0.1795/0.8205) = −1.52. Models without
  dyad-dependent terms are fitted by pseudolikelihood; with `mutual` or `gwesp` the estimates come from MCMLE.
- **R equivalent:** `ergm::ergm()`.
- **Hands-on:** Ch. 21, Ex. 1 (what the office coefficient says about a pair); Ch. 21, Ex. 3 (homophily on
  gender).
- **Read afterwards:** Chapter 21.

### 3. Diagnosing an ERGM, and simulating from it (35 min)
- **Goal:** check the MCMC simulation, compare models, test fit on statistics the model does not contain, and see
  what a model implies by simulating from it.
- **Demo (Chapters 21 and 22):**
  ```stata
  . estat mcmcdiag
  . estat mcmcdiag, plot
  . estimates store closure
  . estat gof, gof(model distance odegree idegree espartners) seed(12345) plot
  . predict, frame(pr) pr
  ```
  `estat mcmcdiag` uses the settings of R's `ergm`, and its option `report` adds the report of R's `summary()` for
  the simulated sample. From Chapter 22: `matrix b = e(b)` after the final model, then
  `nwergm simulate, coef(b) nsim(100) output(network) seed(1)`, and the same with one coefficient changed; and
  `capture noisily nwergm mesa, edges nodematch(grade race) triangle seed(12345)` against the same model with
  `gwesp(.25)`.
- **Points to make:** a converged MCMLE is not a verdict on the model, so read the effective sample sizes; good
  fit on the model's own statistics is guaranteed, so look at the other panels (the final advice model misses the
  spread of the out-degrees and the pairs at distance 2); a coefficient does not move only its own statistic.
- **Hands-on:** Ch. 21, Ex. 5 (co-work as a rival to closure); Ch. 22, exercise bank 22.a (simulate with the gwesp coefficient
  at 0.3).
- **Read afterwards:** Chapter 22.

### 4. Specifying, estimating and checking an SAOM (40 min)
- **Goal:** look at the amount of change, fit a model between waves, tell the convergence check from the
  significance test, restart, and check fit.
- **Demo (Chapter 25):**
  ```stata
  . nwwebuse glasgow, nwclear
  . nwsaom describe, waves(glasgow1 glasgow2 glasgow3)
  . nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity seed(1)
  . nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity transtrip ///
          nodematch(smoke1) seed(12345)
  . nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity ///
          transtrip seed(12345)
  . nwsaom refit, seed(12346)
  . estat gof, nsim(100) seed(1)
  ```
- **Points to make:** the z column tests effects; the convergence t-ratios and the overall maximum convergence
  ratio below the table check the Method-of-Moments search. `nwsaom refit` restarts from the last estimates, as
  RSiena's `prevAns` does. Estimation is conditional by default, as in RSiena. For comparison with R:
  `nwwebuse s50` loads the 50-actor example that RSiena calls `s50` (networks `s50_w1` to `s50_w3`), the same
  pupils as `glasgow`.
- **R equivalent:** `RSiena::siena()`.
- **Hands-on:** Ch. 25, Ex. 2 (the second period and a restart); Ch. 25, exercise bank 25.a (homophily in sport, and
  goodness of fit with two seeds).
- **Read afterwards:** Chapter 25.

### 5. Score tests and co-evolution (25 min)
- **Goal:** decide which effect to add next without fitting every candidate, and separate selection from
  influence in a model where behavior changes too.
- **Demo (Chapters 26 and 25):** the restricted fit of Chapter 26, with three candidate effects held at 0 by
  `fix()`, followed by `estat score`:
  ```stata
  . quietly nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity ///
          transtrip seed(12345)
  . quietly nwsaom refit, seed(12346)
  . matrix b = e(b)
  . quietly nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity ///
          transtrip indegpopularity outactivity cycle3 ///
          theta0(`=b[1,1]' `=b[1,2]' 0 0 `=b[1,3]' 0) ///
          fix(indegpopularity outactivity cycle3) seed(1)
  . estat score
  ```
  then the co-evolution model of Chapter 25:
  ```stata
  . nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip ///
          behsim behavior(alcohol1 alcohol2 alcohol3) linear quadratic avalt ///
          seed(12345)
  ```
- **Points to make:** each score test is conditional on the effects already in the model, so free one effect at a
  time; a behavior must change often enough to identify a co-evolution model (alcohol use works in these data,
  smoking gives very imprecise behavior estimates).
- **Hands-on:** Ch. 26, Ex. 3 (free outdegree activity, then rerun `estat score` and `estat gof`); Ch. 25, Ex. 3
  (`avsim` in place of `avalt`).
- **Read afterwards:** Chapter 26.

### 6. What else the packages do (10 min)
- **Goal:** point to what the session left out. Chapter 26 covers the time test (`estat timetest`), the importance
  of effects (`estat importance`), maximum likelihood and Bayesian estimation, two networks that evolve together
  (`nwsaom multinet`), several groups in a joint model (`groups()`) and meta-analysis (`nwsaom meta`, as
  `RSiena::siena08()`). Chapters 27 and 28 treat time-stamped events with `nwrem` (R: `relevent::rem.dyad()`) and
  `nwdynam` (R: `goldfish`). Chapter 23 fits hidden groups and positions with `nwsbm` and `nwlsm`, and Chapter 24
  an attribute as the outcome with `nwalaam`.
- **Read afterwards:** Chapters 23, 24 and 26 to 29.

## Session 3 (optional): relational events with nwrem and nwdynam (3 hours)

An optional third session for groups that work with time-stamped data (e-mails, calls, messages). It needs
Session 1 and no part of Session 2. It uses the e-mail log of the manufacturing company, the first 14 days
(`keep if t < 14`: 2,738 events among 129 employees), as Chapters 27 and 28 do. The commands were run with
`nwrem` 1.5.0 and `nwdynam` 1.9.0.

| Time | Block |
|---|---|
| 0:00–0:15 | 1. Events and event data |
| 0:15–1:00 | 2. The relational event model: `nwrem` |
| 1:00–1:40 | 3. The DyNAM: who acts, and whom they choose |
| 1:40–1:55 | Break |
| 1:55–2:15 | 4. Comparing the two models |
| 2:15–2:40 | 5. Postestimation: fit, outliers, change points |
| 2:40–3:00 | 6. Limits, pitfalls and where to go |

### 1. Events and event data (15 min)
- **Goal:** an event is a dated act with a sender and a receiver; the question is which event comes next, given
  the history. Declare the log with `nwset sender receiver, eventtime(t)`; a ten-event toy log shows the output.
- **Read afterwards:** Chapter 27.

### 2. The relational event model: `nwrem` (45 min)
- **Goal:** the model compares the observed pair with all 129 × 128 = 16,512 ordered pairs at each event; there
  is no intercept. Fit `nodsnd nidrec`, add inertia (`frpsndsnd`), compare frequency with recency
  (`rsndsnd`) by AIC, add a pair covariate (`covevent()`, same supervisor), and read the display (`ci`).
- **Hands-on:** Ch. 27, Ex. 2 (the risk set and the log likelihood of equal weights); Ch. 27, Ex. 3 (recency of
  receipt).
- **Read afterwards:** Chapter 27.

### 3. The DyNAM: who acts, and whom they choose (40 min)
- **Goal:** two sub-models. The rate model says who acts next (with an intercept: how long it takes), the choice
  model whom the actor chooses. The same effect name means different things in the two. Fit `nwdynam` (choice),
  `submodel(rate)`, `same()` on a branch variable, and the rate with an intercept.
- **Hands-on:** Ch. 28, Ex. 2 (an expected waiting time); Ch. 28, Ex. 5 (`choice_coordination` on the
  undirected log).
- **Read afterwards:** Chapter 28.

### 4. Comparing the two models (20 min)
- **Goal:** the same log in `nwrem` and `nwdynam`; the coefficients are not comparable in size; which model
  answers which question (Ch. 28, Ex. 6).

### 5. Postestimation: fit, outliers, change points (25 min)
- **Goal:** `estat ic`, `estat eventprob` (350,464 rows for 2,738 events and 128 candidates), `estat outliers`
  and `estat changepoints`, as goldfish's `examineOutliers()` and `examineChangepoints()`.
- **Hands-on:** list the five least likely events and compare change-point methods and windows.

### 6. Limits, pitfalls and where to go (20 min)
- **Goal:** no intercept in the REM; `indeg` and `outdeg` mean different things in rate and choice; declare the
  log first; what the packages refuse; the R equivalents.
- **Read afterwards:** Chapters 27 to 29.

## Run times

All the model runs above are short. Appendix A of the book reports that an ERGM of the advice network with seven
terms took about three seconds in Stata/BE on a Mac. On a laptop with Stata/BE, each fit of this session (the
staged ERGMs, `estat gof`, 100 simulated networks, the Glasgow SAOMs, the score test and the co-evolution model; in Session 3 each `nwrem` and `nwdynam` fit takes seconds)
finished within a few seconds, and in Session 1 `nwcug` with `reps(1000)` took about ten seconds. Chapter 26 notes that a Bayesian run takes a few minutes,
and that fitting the 19 Dutch schools one by one took minutes; show those from prepared output rather than run
them live.
