---
title: "Course outlines"
grand_parent: "Book companion"
parent: "Teaching with the book"
nav_order: 1
description: "Three course outlines for Network Analysis with Stata: a 12-week course on descriptive and inferential network analysis, a 12-week course on statistical models, and a 5-day workshop."
permalink: /book/teaching/outlines/
---

# Course outlines
{: .no_toc }

Three outlines, each built on the reading paths of *Getting started*. A week assumes one lecture and one
computer lab of about 90 minutes each; a workshop day assumes about six hours. For each week or day the outline
gives the chapters, the core idea, a demonstration with the data set and the commands the chapter uses, and
exercises to assign. Exercises are cited as "Ch. 8, Ex. 3", numbered as in the book. The
[chapter notes](../chapter-notes/) list all exercises of each chapter by level, so you can swap one for another.

The demonstrations are taken from the chapters' own examples. The [do-files of the book](../../dofiles/)
contain every printed command in order and can be run in class as they are.

1. TOC
{:toc}

## A. Descriptive and inferential network analysis (12 weeks)

For students new to network analysis. The course follows the common ground (Chapters 1 to 6), the path
*Describing a network* up to Chapter 11, and the first part of the path *Statistical models for one observed
network* (Chapters 15, 18, 19 and 20). It ends with the parts of the capstone that do not need an ERGM.

### Week 1. Relations and their vocabulary
- **Chapters:** 1 *Why networks?*; 2 *What is a network?*
- **Core idea:** a relational question needs data on pairs. A tie is directed or undirected, binary or valued,
  signed or not, and each choice keeps some information and discards other information. A network can be a cause,
  an outcome or the context of another process.
- **Demonstration:** the four-person network `mini`, typed with `input` and declared with `nwset`; then
  `nwwebuse lazega, nwclear`, `nwsummarize lazega_adv` and `nwsym`, which turns the 892 advice arcs into 700 edges;
  the eight-lawyer subset with `nwsubset` and its edge list with `nwtoedge`.
- **Exercises:** Ch. 1, Ex. 2 (attribute or relation); Ch. 1, Ex. 6 (influence and its rivals for a correlation
  among friends); Ch. 2, Ex. 3 (density of the work network by hand, before and after symmetrizing);
  Ch. 2, Ex. 7 (mutual pairs from the numbers of arcs and edges).

### Week 2. From a question to network data in Stata
- **Chapters:** 3 *From a research question to a network and a method*; 4 *Working with networks in Stata*
- **Core idea:** a network is constructed, not found. Boundary, tie definition, name generator, the rule for
  one-sided reports and missing data each shape what it can answer, and each belongs in the report. In Stata a
  network is declared once and then found by name.
- **Demonstration:** the OR and AND rules on the lawyers' friendship reports (501 against 74 edges) with
  `nwsym lazega_fr, mode(max)` and `mode(min)`, and `nwdyads`; the survey example of Chapter 4, from a wide export
  through `reshape long` to `nwfromedge`; `nwset, mat()`, `nwimport`, wildcards over several networks,
  `nwsave`, `nwuse`, `nwsubset` and `nwsymmetrize`.
- **Exercises:** Ch. 3, Ex. 2 (AND rule, OR rule and arcs by hand); Ch. 3, Ex. 3 (the two rules on the advice
  network); Ch. 4, Ex. 1 (declare a five-person network from a matrix); Ch. 4, Ex. 6 (directed, union and
  intersection versions of the survey network).

### Week 3. Pictures of networks
- **Chapters:** 5 *Seeing networks*
- **Core idea:** in most layouts the ties are data and the node positions are not. A claim about structure needs a
  measure defined on the ties. Fixed coordinates are needed to compare pictures; a matrix plot avoids the
  coordinate question.
- **Demonstration:** `nwplot flomarriage, label(_nwnode)` in the default, `layout(circle)` and `layout(frucht)`
  layouts, and with `size(wealth)`; `nwplot lazega_adv, color(office)`; `nwplotmatrix lazega_adv, group(office)`;
  the busiest US airports on a map with `nodexy()` and `basemap(usmap)`; the Chesapeake Bay food web with
  `edgesize()` on log flows; an interactive page with `generate(x y)`.
- **Exercises:** Ch. 5, Ex. 1 (one network, three layouts); Ch. 5, Ex. 5 (matrix plot by status);
  Ch. 5, Ex. 10 (which display for which question).

### Week 4. Describing a whole network
- **Chapters:** 6 *Describing networks*
- **Core idea:** density is hard to compare across sizes, so report mean degree with it. Reciprocity, transitivity
  and the triad census describe closure; the E-I index and assortativity are read against the value the group sizes
  alone would produce, not against zero.
- **Demonstration:** `nwdyads lazega_adv`, `nwtriads lazega_adv`, `nwmixing lazega_adv, attribute(office)` and
  `attribute(status)`, which print the E-I index with a permutation p-value, and `nwassortativity`; the gang's
  birthplace groups with `nwmixing gang, attribute(Birthplace)`; the Glasgow girls as a contrast in size.
- **Exercises:** Ch. 6, Ex. 2 (reciprocity of pairs and of arcs); Ch. 6, Ex. 5 (the work network beside advice
  and friendship); Ch. 6, Ex. 7 (gender and the expected E-I index); Ch. 6, Ex. 11 (density or mean degree).

### Week 5. Paths and reachability
- **Chapters:** 7 *Paths, distance, and reachability*
- **Core idea:** reachability asks whether anything can flow; distance asks how far. A network that is not
  connected needs a stated convention for unreachable pairs. In a directed network distance need not be
  symmetric. Short distances alone do not make a small world.
- **Demonstration:** `nwpath lazega_adv` between two lawyers, `nwgeodesic lazega_adv`; `nwreach flomarriage` and
  `nwgeodesic flomarriage, unconnected(16)` for the isolated Pucci family; `nwgeodesic glasgow1` on a network with
  unreachable pairs.
- **Exercises:** Ch. 7, Ex. 1 (the reachability matrix and Pucci); Ch. 7, Ex. 3 (distances among the Glasgow
  girls); Ch. 7, Ex. 6 (one pair of lawyers in both directions); Ch. 7, Ex. 10 (what an average distance says about a
  rumor).

### Week 6. Centrality and brokerage
- **Chapters:** 8 *Centrality, brokerage, and structural holes*
- **Core idea:** name the mechanism (activity, access, control, prestige) before choosing the measure. Say whether
  ties are counted in their direction. A score measures position, not power or influence.
- **Demonstration:** the Florentine table of degree, closeness, betweenness, effective size and constraint; on
  the advice network `nwdegree, generate(adv_out adv_in)`, `nwcloseness` with and without `nosym`, `nwbetween`,
  `nwevcent`, `nwburt`, `nwbrokerage, group(officenum)`, `nwbridges` and `nwsimmelian`.
- **Exercises:** Ch. 8, Ex. 3 (a star network by hand); Ch. 8, Ex. 4 (closeness under two penalties);
  Ch. 8, Ex. 7 (tenure as a rival source of a high in-degree); Ch. 8, Ex. 11 (whom to brief first).

### Week 7. Cohesive groups and communities
- **Chapters:** 9 *Cohesion, subgroups, and communities*
- **Core idea:** "hard to separate" has three meanings: local density (cliques, k-plexes, n-cliques, k-cores),
  robustness (k-components, the cohesion hierarchy) and separation (communities). A detected community is not by
  itself evidence of a cohesive social group.
- **Demonstration:** the reciprocated advice network from `nwsym lazega_adv, mode(min)`; `nwclique`, `nwkplex`,
  `nwnclique`, `nwkcore`, `nwkcomponents` and `nwcohesion`; `nwcommunity lazega_adv, algorithm(louvain)
  seed(12345) symmetrize` and `nwmodularity lazega_adv, group(officenum) symmetrize`; the gang and the macaque
  cortex as further cases.
- **Exercises:** Ch. 9, Ex. 1 (k-components against k-cores); Ch. 9, Ex. 4 (communities of the co-work network);
  Ch. 9, Ex. 5 (label propagation under four seeds); Ch. 9, Ex. 7 (what a cohesion result stands for).

### Week 8. Positions and roles
- **Chapters:** 10 *Positions, roles, and structural equivalence*
- **Core idea:** two actors can occupy the same position without being tied. Similar tie profiles, blocks,
  regular equivalence and core and periphery are different answers to "who could replace whom?"
- **Demonstration:** the small office typed with `input` and `nwset`, with `nwsimindex` and `nwregular`; on the
  advice network `nwsimindex lazega_adv, measure(jaccard)`, `nwconcor lazega_adv, splits(2)`, `nwcollapse`,
  `nwhierarchy` with single and Ward linkage, and `nwcoreperiphery`; `nwdendrogram` on the Florentine families.
- **Exercises:** Ch. 10, Ex. 3 (structural equivalence by hand); Ch. 10, Ex. 4 (Ward and CONCOR as two-group
  splits); Ch. 10, Ex. 7 (is the core just the busiest lawyers?); Ch. 10, Ex. 8 (who could replace lawyer n17).

### Week 9. Ego networks
- **Chapters:** 11 *Ego networks*. Chapters 12 (two-mode), 13 (valued, signed, multiplex) or 14 (over time) can
  replace it, or Chapter 10, if the students' own data call for them.
- **Core idea:** an ego network is a unit of analysis in its own right. Size, density, effective size and
  constraint are largely redundant. Composition is read against what the setting makes available, and exposure
  before an outcome is a covariate, not proof of influence.
- **Demonstration:** `nwego lazega_adv, sizevar(egosize) densvar(egodens)`, `nwegoplot`, and `nwaltergen` with
  `proportion()` and `diversity()`; exposure to smoking friends in the Glasgow data with `nwaltergen` and
  `regress`; the same measures from survey data with `collapse`.
- **Exercises:** Ch. 11, Ex. 1 (ego density and effective size by hand); Ch. 11, Ex. 4 (ego density against
  constraint); Ch. 11, Ex. 6 (the exposure regression one wave later); Ch. 11, Ex. 9 (which ego measure for a
  question about promotion).

### Week 10. Baselines
- **Chapters:** 15 *Random and structured network generators* (the sections on density and random graphs);
  18 *Random networks and null models*
- **Core idea:** size and density alone set the chance level of many statistics. A null model holds some features
  fixed, and that choice defines the question a test answers. Dyads share nodes, so ordinary tests do not apply.
- **Demonstration:** the density sweep with `nwrandom`; `nwcug lazega_adv, stat(nwclustering)
  rname(cluster_global) reps(1000) seed(12345) condition(density) plot`, then the same test of reciprocity with
  `stat(nwdyads) rname(reciprocity)` under density, dyad-census and degree conditioning.
- **Exercises:** Ch. 15, Ex. 3 (the transitivity chance leads you to expect); Ch. 15, Ex. 7 (how often a small
  random graph has no closed triads); Ch. 18, Ex. 3 (the friendship network's null mean); Ch. 18, Ex. 5 (clustering
  inside the Boston office).

### Week 11. Permutation tests and QAP regression
- **Chapters:** 19 *Permutation inference and comparing networks*; 20 *QAP regression*
- **Core idea:** relabeling the nodes keeps the structure and breaks the link between identity and position. QAP
  keeps a regression's point estimates and replaces its inference with permutation p-values. Significance and
  predictive accuracy are different claims.
- **Demonstration:** `nwpermute lazega_fr`, `nwcorrelate lazega_adv lazega_fr, permutations(1000)`,
  `nwmixing lazega_adv, attribute(office) permutations(1000)`; `nwqap lazega_adv lazega_fr office practice status,
  permutations(500) plot`, the same with `qapspp`, and `predict()`; `nwqap glasgow2 glasgow1 smoke1 sport1`.
- **Exercises:** Ch. 19, Ex. 2 (the smallest possible p-value); Ch. 19, Ex. 4 (advice and co-work); Ch. 20, Ex. 1
  (fitted tie probabilities by hand); Ch. 20, Ex. 5 (the advice model without friendship).

### Week 12. One complete analysis, and reporting it
- **Chapters:** 27 *A complete network analysis* (theory, data, description and QAP);
  28 *Reproducible and responsible network research*
- **Core idea:** state the expectations, and what would count against them, before any model is fitted. Agreement
  of analyses on the same arcs is one piece of evidence, not three. A report owes its readers the construction
  decisions, and its subjects a judgment about disclosure risk.
- **Demonstration:** advice density by the status of sender and receiver; activity and seniority by status; the QAP
  model of Chapter 27. The ERGMs that follow are easier after Chapter 21, so present their results here (associates
  do not favor partners; being asked follows seniority) and leave the code to course B. From Chapter 28,
  stored results after `nwcug` (`return list`) and `nwqap` (`ereturn list`).
- **Exercises:** Ch. 27, Ex. 1 (density ratios from the status table); Ch. 27, Ex. 7 (could an all-partner core be
  chance?); Ch. 28, Ex. 1 (the construction decisions of Chapter 27); Ch. 28, Ex. 4 (how many
  lawyers their degrees alone identify).

## B. Statistical models for networks (12 weeks)

For students who know the material of Chapters 1 to 8, from course A or from another course. It can be taught as
a second course. The course follows the path *Statistical models for one observed network* to its end
(Chapters 15, 18 to 22) and then the path *Change and events* (Chapters 14, 23 to 26), and closes with the
capstone. Chapter 16 is added because its logit on the edge list leads directly to dyadic models.

### Week 1. Random graphs and generators
- **Chapters:** 15 *Random and structured network generators*
- **Core idea:** a random graph fixes only size and density; other generators add one idea each (geometry,
  shortcuts, growth). A resemblance shows that a mechanism could produce a pattern, not that it did. One draw is
  not the model's typical outcome.
- **Demonstration:** `nwrandom 71, density(.179)` with `set seed`, `nwring`, `nwlattice`, `nwsmall` and `nwpref`;
  the same generators through `nwgen`; a small-world sweep over rewiring probabilities with `nwgeodesic`.
- **Exercises:** Ch. 15, Ex. 2 (predict transitivity and reciprocity, then draw); Ch. 15, Ex. 6 (degree
  distributions of a random and a preferential-attachment network); Ch. 15, Ex. 8 (evidence against preferential
  attachment); Ch. 15, Ex. 9 (what a small-world claim needs).

### Week 2. Networks from attributes
- **Chapters:** 16 *Generating networks from attributes and tie probabilities*
- **Core idea:** tie probabilities can come from group membership or from a homophily coefficient, which is a
  log-odds ratio. Group sizes and opportunity can produce the same sorting as preference. A logit on the edge list
  turns several attributes into a generator; what it fails to reproduce shows what attributes alone cannot explain.
- **Demonstration:** `nwexpand` for same-group networks, `nwgen` for tie probabilities and `nwdyadprob` to draw;
  `nwhomophily` with `nwmixing` to check recovery; `nwtoedge`, `logit`, `predict` and `nwfromedge` for the
  estimated generator.
- **Exercises:** Ch. 16, Ex. 2 (the odds factor of a homophily coefficient); Ch. 16, Ex. 3 (the E-I index that
  ignores status); Ch. 16, Ex. 4 (the homophily sweep for office); Ch. 16, Ex. 9 (preference or opportunity).

### Week 3. Null models
- **Chapters:** 18 *Random networks and null models*
- **Core idea:** the conditional uniform graph test compares an observed statistic with networks that share some of
  its features. Conditioning on density, the dyad census or the degrees answers different questions. Rejecting a
  null leaves every mechanism that could produce the pattern in play.
- **Demonstration:** `nwcug lazega_adv` for transitivity and reciprocity under `condition(density)`,
  `condition(census)` and `condition(degrees)`, with `plot`.
- **Exercises:** Ch. 18, Ex. 1 (distance from the null mean in standard deviations); Ch. 18, Ex. 2 (why the census
  condition is refused for an undirected network); Ch. 18, Ex. 4 (Glasgow and the lawyers under two conditions);
  Ch. 18, Ex. 6 (questions to ask of a "significant" clustering).

### Week 4. Permutation tests and QAP regression
- **Chapters:** 19 *Permutation inference and comparing networks*; 20 *QAP regression*
- **Core idea:** permutation keeps the observed structure and relabels it; the p-value concerns the data in hand.
  QAP regression adds several predictors, and turns logit coefficients into odds ratios and fitted probabilities.
  It does not model dependence between ties.
- **Demonstration:** `nwcorrelate` and `nwmixing` with `permutations()`; `nwqap lazega_adv lazega_fr office
  practice status, permutations(500) plot`, `qapspp`, `mode(receiver absdist)`, `type(regress)` on a valued
  outcome, and `predict()`; the Glasgow model with an earlier wave as predictor.
- **Exercises:** Ch. 19, Ex. 5 (is advice sorted by gender?); Ch. 20, Ex. 3 (odds ratio and the p-value floor);
  Ch. 20, Ex. 4 (the Glasgow model with fewer predictors); Ch. 20, Ex. 9 (what is wrong with ordinary standard
  errors).

### Week 5. ERGM I: dependence and change statistics
- **Chapters:** 21 *Exponential random graph models*, from the start through the reciprocity step and the check of
  the MCMC simulation
- **Core idea:** a model of a whole network lets ties depend on other ties. An ERGM coefficient is a change in the
  conditional log-odds of one tie, given the rest of the network, read through its change statistic. A
  specification is built in stages.
- **Demonstration:** `nwergm lazega_adv, edges seed(12345)`; then `nodematch(office practice)`,
  `nodeofactor(status)` and `nodeifactor(status)`; then `mutual`; `estat mcmcdiag` after the fit.
- **Exercises:** Ch. 21, Ex. 1 (what the office coefficient says about a pair); Ch. 21, Ex. 2 (why the
  normalizing constant cannot be computed); Ch. 21, Ex. 3 (homophily on gender); Ch. 21, Ex. 7 (two MCMC intervals).

### Week 6. ERGM II: closure, comparison and fit
- **Chapters:** 21, from the transitivity step to the end
- **Core idea:** homophily, status, reciprocity and closure compete for the same ties. Convergence of MCMLE is not
  a verdict on the model. Fit is judged on statistics the model does not contain.
- **Demonstration:** the final model with `gwesp(.5)`; `estat mcmcdiag, plot`; `estimates store` and `lrtest`;
  `estat gof, gof(model distance odegree idegree espartners) seed(12345) plot`; `predict, frame(pr) pr`.
- **Exercises:** Ch. 21, Ex. 4 (goodness of fit with 300 draws); Ch. 21, Ex. 6 (other gwesp decays and
  gwodegree); Ch. 21, Ex. 9 (co-work as a rival to closure); Ch. 21, Ex. 10 (a statistic for unreachable pairs).

### Week 7. ERGM III: simulation, degeneracy and missing data
- **Chapters:** 22 *Advanced exponential random graph models*
- **Core idea:** simulating from a model shows what it implies. A coefficient does not move only its own
  statistic. A raw triangle count can make a model degenerate; geometrically weighted terms avoid it. A missing
  dyad is not a non-tie.
- **Demonstration:** `nwergm simulate` from hand-chosen coefficients and from the fitted advice model with one
  coefficient changed; `nwergm mesa, edges nodematch(grade race) gwesp(.25) seed(12345)` and the same model with
  `triangle`, which fails; a version of `mesa` with missing dyads built with `nwtomata`.
- **Exercises:** Ch. 22, Ex. 1 (why `mutual` has no meaning in an undirected network); Ch. 22, Ex. 2 (why a
  triangle count degenerates); Ch. 22, Ex. 4 (simulate with the gwesp coefficient at 0.3); Ch. 22, Ex. 6 (ten
  missing dyads).

### Week 8. Change between waves
- **Chapters:** 14 *Networks over time*; 23 *Stochastic actor-oriented models*, through the ministep process, the
  objective function and the first look at the data
- **Core idea:** a network observed once is a snapshot of a process. Ties between waves are stable, formed or
  dissolved. An SAOM represents the unseen process as small choices by actors, with a rate function (how often an
  actor may change a tie) and an objective function (which change it makes).
- **Demonstration:** `nwturnover glasgow1 glasgow2, generate(_turnover)` with and without `formation`; plots at
  fixed positions with `nodexy()` and `nwmovie`; `nwsaom describe, waves(glasgow1 glasgow2 glasgow3)`;
  `nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity seed(1)`.
- **Exercises:** Ch. 14, Ex. 2 (Jaccard index and persistence by hand); Ch. 14, Ex. 7 (formed ties against all
  pairs without a tie); Ch. 23, Ex. 1 (the counts of `nwsaom describe`); Ch. 23, Ex. 7 (what the rate counts).

### Week 9. Stochastic actor-oriented models
- **Chapters:** 23, from building up a model on Glasgow to the end
- **Core idea:** convergence t-ratios check the estimation; the z statistics test effects. Goodness of fit shows
  where a model fails. A co-evolution model separates selection from influence, given its assumptions and a
  behavior that changes often enough.
- **Demonstration:** `nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity transtrip nodematch(smoke1)
  seed(12345)`; three waves with `waves()`; `nwsaom refit`; `estat gof, nsim(100) seed(1)`; the co-evolution model
  with `behavior(alcohol1 alcohol2 alcohol3)`, `behsim` and `avalt`.
- **Exercises:** Ch. 23, Ex. 2 (the second period and a restart); Ch. 23, Ex. 3 (homophily in sport); Ch. 23,
  Ex. 5 (`avsim` in place of `avalt`); Ch. 23, Ex. 8 (a teacher's seating plan).

### Week 10. SAOM: adequacy, estimators and several groups
- **Chapters:** 24 *Advanced stochastic actor-oriented models*
- **Core idea:** the score test says which effect to try next; the time test whether effects stay constant;
  simulation and the importance table show what a model implies. Method of Moments, maximum likelihood and Bayesian
  estimation have their own diagnostics. Several groups can be pooled in a joint model or combined in a
  meta-analysis.
- **Demonstration:** `estat score`, `estat timetest, fixrates`, `estat importance` and `estat simulate`;
  `nwsaom simulate`; the `ml` option and `nwsaom bayes, nmain(250) seed(1)`; `nwwebuse baerveldt19`,
  `nwstack school*_w1, name(w1) group(school)`, a joint model with `groups(school)`, and `nwsaom meta`.
- **Exercises:** Ch. 24, Ex. 1 (two estimators in standard errors); Ch. 24, Ex. 2 (Bayesian runs with other
  seeds); Ch. 24, Ex. 3 (freeing outdegree activity); Ch. 24, Ex. 4 (40 classes: joint model or meta-analysis).

### Week 11. Event models
- **Chapters:** 25 *Relational event models*; 26 *The Dynamic Network Actor Model*
- **Core idea:** with a time-stamped log the unit is the event. The relational event model compares, at every
  event, the pair that fired with all pairs at risk, so it has no intercept. Frequency and recency of past contact
  are different claims. The DyNAM separates who acts from whom the actor chooses.
- **Demonstration:** the ten-event toy log, `nwset sender receiver, eventtime(t) name(chat)` and
  `nwrem chat, nodsnd nidrec`; the company emails (`keep if t < 14`) with `nwrem mail` and `frpsndsnd`,
  `rsndsnd` and `covevent(samesup)` after `nwload mail, xvars` and `nwexpand supervisor`; `nwdynam mail,
  submodel(rate)`, `nwdynam mail, inertia recip indeg same(branch)` and `submodel(rate) intercept`.
- **Exercises:** Ch. 25, Ex. 2 (the risk set and the log likelihood of equal weights); Ch. 25, Ex. 4 (recency of
  receipt); Ch. 26, Ex. 3 (an expected waiting time); Ch. 26, Ex. 8 (which of five models for which question).

### Week 12. One complete analysis, and reporting it
- **Chapters:** 27 *A complete network analysis*; 28 *Reproducible and responsible network research*
- **Core idea:** one question about the law firm, whether advice runs up the status order, is carried from theory
  and stated expectations through description, QAP regression and a sequence of ERGMs to a synthesis, with
  sensitivity runs chosen in advance.
  The report states the construction decisions and confronts the disclosure risk of relational data.
- **Demonstration:** the QAP model; the ERGM with friendship as `edgecov()`; `nodemix(status)` and `lincom` for
  whose choices carry the status effect; seniority rank next to partnership (`nodeicov()`, `nodeocov()`); the
  sensitivity runs with the AND rule (`nwsym lazega_fr, mode(min)`) and without the two most
  active lawyers (`nwdrop`); stored results from Chapter 28.
- **Exercises:** Ch. 27, Ex. 2 (odds ratios of the ERGM, and why QAP and ERGM are not two confirmations);
  Ch. 27, Ex. 3 (the mixing model and the status-match model are the same model); Ch. 27, Ex. 6 (a sensitivity
  check of your own choice); Ch. 27, Ex. 9 (deference or competence); Ch. 28, Ex. 5
  (a do-file that collects results without retyping them).

## C. Workshop or summer school (5 days)

For participants who know Stata and want to apply network analysis to their own data. The first three days cover
the common ground and the main descriptive tools, the fourth the inference for one network, and the fifth the
first model, with a choice for the afternoon. A morning can take one chapter as a lecture and a lab; an
afternoon the next.

### Day 1. Networks as data
- **Chapters:** 1 *Why networks?*; 2 *What is a network?*; 3 *From a research question to a network and a
  method* (the reporting checklist); 4 *Working with networks in Stata*; 5 *Seeing networks*
- **Core idea:** a relational question needs data on pairs, and every construction decision changes the network.
  A network is declared once in Stata and found by name. Node positions in a picture are not data.
- **Demonstration:** `nwwebuse lazega, nwclear`, `nwsummarize lazega_*`, `nwsym` and `nwdyads`; the survey
  example from `reshape long` to `nwfromedge`; `nwplot flomarriage` in three layouts; `nwplot lazega_adv,
  color(office)`; an interactive page.
- **Exercises:** Ch. 1, Ex. 5 (cause, outcome or context); Ch. 2, Ex. 3 (density by hand before and after
  symmetrizing); Ch. 4, Ex. 4 (wildcards, `nwsave` and `nwuse`); Ch. 5, Ex. 1 (one network, three layouts).

### Day 2. Describing networks and positions in them
- **Chapters:** 6 *Describing networks*; 7 *Paths, distance, and reachability*; 8 *Centrality, brokerage, and
  structural holes*
- **Core idea:** each statistic describes one named relation in one network and is read against what chance and
  group sizes would produce. Reachability comes before distance. A centrality measure follows a mechanism.
- **Demonstration:** `nwdyads`, `nwtriads` and `nwmixing` on `lazega_adv`; `nwgeodesic` and `nwpath`;
  `nwdegree`, `nwcloseness`, `nwbetween`, `nwburt` and `nwbrokerage, group(officenum)`.
- **Exercises:** Ch. 6, Ex. 7 (gender and the expected E-I index); Ch. 7, Ex. 3 (distances among the Glasgow
  girls); Ch. 8, Ex. 4 (closeness under two penalties); Ch. 8, Ex. 6 (sought or broker?).

### Day 3. Groups, positions and ego networks
- **Chapters:** 9 *Cohesion, subgroups, and communities*; 10 *Positions, roles, and structural equivalence*;
  11 *Ego networks*. Participants with affiliation or valued data can take Chapter 12 or 13 in place of 10 or 11.
- **Core idea:** a cohesive group, a community, a position and an ego network answer different questions about
  the same ties. A partition proposed by an algorithm is not by itself a social group.
- **Demonstration:** `nwkcore`, `nwkcomponents` and `nwcommunity, algorithm(louvain)` with `nwmodularity`;
  `nwconcor` and `nwhierarchy` with `tab` against office and status; `nwego`, `nwegoplot` and `nwaltergen`.
- **Exercises:** Ch. 9, Ex. 4 (communities of the co-work network); Ch. 10, Ex. 4 (Ward and CONCOR as two-group
  splits); Ch. 11, Ex. 4 (ego density against constraint).

### Day 4. Inference for one network
- **Chapters:** 15 *Random and structured network generators* (the sections on density and random graphs);
  18 *Random networks and null models*; 19 *Permutation inference and comparing networks*; 20 *QAP regression*
- **Core idea:** dyads are not independent observations. A conditional uniform graph test compares a statistic with
  random networks; permutation relabels the observed one; QAP regression adds several predictors. Each rests on
  its own assumption about what may be exchanged.
- **Demonstration:** `nwrandom`; `nwcug lazega_adv` with `condition(density)` and `condition(census)`;
  `nwcorrelate lazega_adv lazega_fr, permutations(1000)`; `nwqap lazega_adv lazega_fr office practice status,
  permutations(500) plot`.
- **Exercises:** Ch. 18, Ex. 3 (the friendship network's null mean); Ch. 19, Ex. 4 (advice and co-work);
  Ch. 20, Ex. 5 (the advice model without friendship); Ch. 20, Ex. 7 (homophily or shared office).

### Day 5. A first network model
- **Chapters:** morning: 21 *Exponential random graph models*. Afternoon, one of two: 14 *Networks over time* and
  23 *Stochastic actor-oriented models*, for participants with panel data; or 27 *A complete network analysis*,
  which brings the week together on the law firm.
- **Core idea:** an ERGM makes the dependence among ties the object of the model; its coefficients are read as
  conditional log-odds through change statistics, and its fit is checked on statistics it does not contain. An
  SAOM models change between waves as choices of actors.
- **Demonstration:** the staged advice model with `nwergm`, `estat mcmcdiag` and `estat gof`; for the panel
  option, `nwturnover`, `nwsaom describe` and `nwsaom` on the Glasgow waves; for the capstone option, the QAP and
  ERGM models of Chapter 27.
- **Exercises:** Ch. 21, Ex. 1 (what the office coefficient says about a pair); Ch. 21, Ex. 3 (homophily on
  gender); then Ch. 23, Ex. 3 (homophily in sport) for the panel option, or Ch. 27, Ex. 4 (a step or a slope:
  seniority in odds ratios) for the capstone option.

Permutation tests and model fits repeat a computation many times. Appendix A of the book advises setting `reps()`
or `permutations()` deliberately; in a lab with many students, a smaller number of repetitions than the book's
gives the same lesson in less time.
