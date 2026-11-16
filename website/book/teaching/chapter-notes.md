---
title: "Chapter notes"
grand_parent: "Book companion"
parent: "Teaching with the book"
nav_order: 3
description: "One entry per chapter of Network Analysis with Stata: time needed, data sets, prerequisites, commands taught, where students get stuck, and the exercises by level."
permalink: /book/teaching/chapter-notes/
---

# Chapter notes
{: .no_toc }

One entry for each chapter. The entries use these headings:

- **Time:** a rough estimate in class sessions of about 90 minutes, including a lab. It depends on how much of the
  chapter's code is run in class.
- **Data:** the data sets the chapter loads with `nwwebuse`, and any small networks it types in.
- **Builds on:** the earlier chapters it draws on. Part I and Chapters 4 to 6 are common ground for all chapters
  after them.
- **Commands:** the commands of the package that the chapter teaches.
- **Where students get stuck:** taken from the chapter's box of common mistakes and from its hints.
- **Exercises:** the number of exercises at each level, with their numbers. Exercises are numbered in the order in
  which they appear in the chapter, as in the book.

1. TOC
{:toc}

## Part I. Foundations

### Chapter 1. Why networks?
- **Time:** 1 session. There is no code.
- **Data:** none; the examples are described in words.
- **Builds on:** nothing.
- **Commands:** none.
- **Where students get stuck:**
  - Equating exposure with adoption. The network supplies only the exposure, and the bridges that speed an
    infection can slow a behavior that needs reinforcement.
  - Inferring influence from a cross-sectional similarity, or from a group mean of an outcome, which the reflection
    problem leaves ambiguous.
  - Calling any data set with several units a network, although it has nothing on who is connected to whom.
  - Telling attributes from relations: the hints ask whether a quantity can be written down for one unit without
    mentioning any other unit.
  - Keeping a score apart from the idea it stands for: what betweenness counts is not yet brokerage (Ex. 11).
- **Exercises:** 12. Basic 6 (1–6); applied 4 (7–10); open 2 (11, 12).

### Chapter 2. What is a network?
- **Time:** 1 session.
- **Data:** `lazega`; a four-person network `mini`, typed in.
- **Builds on:** 1.
- **Commands:** `nwset`, `nwsummarize`, `nwdegree`, `nwplot`, `nwsym`, `nwsubset`, `nwtoedge`.
- **Where students get stuck:**
  - Converting one type of network into another without saying so. Symmetrizing the advice network turns 892 arcs
    into 700 edges and erases who asked whom.
  - Comparing the directed and the undirected density of the same network as if they measured the same thing; they
    divide by different numbers of possible ties.
  - Treating a subset as the network: the eight lawyers that can be checked by hand have a density of 0.161 and
    two look isolated; in the whole firm the density is 0.179 and nobody is isolated.
  - Reading the adjacency matrix the wrong way round. Rows are senders and columns receivers here; a source with
    the opposite convention flips every arrow without an error message.
  - Counting mutual pairs: a mutual pair holds two arcs but becomes one edge (Ex. 7).
- **Exercises:** 8. Basic 4 (1–4); applied 3 (5–7); open 1 (8).

### Chapter 3. From a research question to a network and a method
- **Time:** 1 session.
- **Data:** `lazega`.
- **Builds on:** 1, 2.
- **Commands:** `nwdyads`, `nwsym` with `mode(max)` (the OR rule) and `mode(min)` (the AND rule).
- **Where students get stuck:**
  - Comparing networks collected with different ceilings on the number of names. Measures built from degree are
    not comparable, although both files have a column called degree.
  - Reporting a whole-network analysis without its response rate. The edge list looks complete whoever is missing.
  - Asking an ego-network design to answer a whole-network question. Closeness, betweenness and communities cannot
    be recovered from ego data.
  - The reconciliation rules: the AND rule keeps the mutual pairs, the OR rule the mutual and the one-sided pairs
    (Ex. 2, 3, 8). For the lawyers' friendship reports they give 74 and 501 edges.
- **Exercises:** 10. Basic 3 (1–3); applied 6 (4–9); open 1 (10).

## Part II. Describing and positioning networks

### Chapter 4. Working with networks in Stata
- **Time:** 1–2 sessions, most of it in the lab.
- **Data:** `lazega`, `florentine`, `glasgow`; a toy network declared from a matrix, a small survey export, and an
  example edge list read with `nwimport`.
- **Builds on:** 2, 3.
- **Commands:** `nwset` (edge list and `mat()`), `nwimport`, `nwfromedge`, `nwsummarize`, `nwclear`, `nwsave`,
  `nwuse`, `nwload`, `nwname`, `nwgenerate`, `nwreplace`, `nwsubset`, `nwkeepnodes`, `nwduplicate`,
  `nwsymmetrize`, `nwdegree`.
- **Where students get stuck:**
  - Treating a nomination as a tie. The `undirected` option applies the union rule silently (five ties from eight
    nominations in the chapter's example).
  - Losing isolates. An edge list holds only people who appear in a tie; the others drop out of *n* and inflate
    density and every average. Give each a row with an empty receiver, or declare the network from a matrix.
  - Trusting the type that `nwimport` infers. Check the `Directed:` and `Valued:` lines of `nwsummarize` against
    the design.
  - Expecting `clear` to remove networks. It removes the data in memory, not the declared networks; use `nwclear`.
  - Typing a matrix for `nwset, mat()`: row *i*, column *j* holds the arc from *i* to *j*, and rows are separated by
    a backslash (Ex. 1).
- **Exercises:** 8. Basic 3 (1–3); applied 4 (4–7); open 1 (8).

### Chapter 5. Seeing networks
- **Time:** 1–2 sessions, most of it in the lab.
- **Data:** `florentine`, `lazega`, `usair` (drawn on the base map `usmap`), `chesapeake`.
- **Builds on:** 4.
- **Commands:** `nwplot` (layouts, `color()`, `symbol()`, `size()`, `edgesize()`, `generate()` and `nodexy()`,
  `basemap()`, `interactive`), `nwplotmatrix`, `nwpath` to highlight a path, `nwsubset`, `nwgenerate`.
- **Where students get stuck:**
  - Reading node position as a finding. The same network can look centered on one actor in one layout and
    undifferentiated in another.
  - Comparing pictures of one network at different times without fixed coordinates; `generate()` and `nodexy()`
    keep the positions.
  - Mapping a rank as a size. The lawyers' `seniority` is 1 for the most senior, so as a size it draws the picture
    upside down.
  - Moving nodes on a page with real coordinates. Recolor and resize, but leave the nodes.
  - Reproducing an interactive page: the saved do-file needs the same data and the same node order as when the page
    was written (Ex. 8).
- **Exercises:** 11. Basic 3 (1–3); applied 7 (4–10); open 1 (11).

### Chapter 6. Describing networks
- **Time:** 1–2 sessions.
- **Data:** `lazega`, `gang`, `glasgow`.
- **Builds on:** 2, 4, 5.
- **Commands:** `nwsummarize`, `nwdyads`, `nwtriads`, `nwmixing`, `nwassortativity`, `nwdegree`.
- **Where students get stuck:**
  - Comparing density across networks of different size. The lawyers' 0.179 and the Glasgow girls' 0.046 are not a
    comparison of cohesion.
  - Reading the E-I index against zero. The chance value is about +0.41 for the gang's birthplace groups and
    -0.05 for the lawyers' offices.
  - Reading the smallest permutation p-value as a precise value. With 100 permutations it is 0.02, so the honest
    report is p ≤ 0.02.
  - Mixing relations in one comparison: transitivity is 0.33, 0.36 or 0.19 depending on the relation of the firm.
  - Reciprocity of pairs and of arcs count different things (Ex. 2).
- **Exercises:** 12. Basic 4 (1–4); applied 6 (5–10); open 2 (11, 12).

### Chapter 7. Paths, distance, and reachability
- **Time:** 1 session.
- **Data:** `lazega`, `florentine`, `glasgow`; `usair` in Ex. 8.
- **Builds on:** 4, 6.
- **Commands:** `nwgeodesic` (with `unconnected()`), `nwpath`, `nwreach`, `nwneighbor`, `nwrandom`, `nwtriads`.
- **Where students get stuck:**
  - Treating distance as defined for disconnected pairs without a stated rule. The diameter and radius of 16 for the
    Florentine marriage network are the penalty, not path lengths, and the average of 4.175 is 2.49 among the
    connected pairs.
  - Treating distance as symmetric in a directed network. From `n59` to `n23` the advice distance is four; back it
    is three.
  - Comparing averages taken over different sets of pairs: for a network with unreachable pairs, `nwgeodesic`
    reports the share of connected pairs and the average over those pairs (Ex. 3).
  - Reading a short average distance as a small world. That needs clustering and a random baseline as well (Ex. 8).
- **Exercises:** 10. Basic 4 (1–4); applied 4 (5–8); open 2 (9, 10).

### Chapter 8. Centrality, brokerage, and structural holes
- **Time:** 2 sessions.
- **Data:** `florentine`, `lazega`.
- **Builds on:** 6, 7.
- **Commands:** `nwdegree`, `nwcloseness`, `nwbetween`, `nwevcent`, `nwkatz`, `nwburt`, `nwbrokerage`,
  `nwbridges`, `nwsimmelian`, `nwsym`.
- **Where students get stuck:**
  - Ignoring direction without saying so. On the symmetrized network, closeness, betweenness, eigenvector and Katz
    centrality answer a question about the structure, not about who asks whom. Directed closeness correlates .96
    with out-degree. Use in-degree for "who is sought".
  - Leaving unreachable pairs to a hidden rule. Changing the rule changes the closeness of every node not fully
    connected to the rest (Ex. 4).
  - Assuming `nwkatz` is the walk-counting Katz measure of textbooks. By default it sums over shortest-path
    distances; the option `walks` gives the textbook version.
  - Reading a high score as power or influence. What a position is worth needs outcome data.
  - Reading brokerage role counts without the grouping variable in mind. A binary grouping cannot produce a
    liaison, and counts grow with the number of two-paths, so compare shares as well.
- **Exercises:** 12. Basic 4 (1, 2, 3, 8); applied 6 (4–7, 9, 10); open 2 (11, 12).

### Chapter 9. Cohesion, subgroups, and communities
- **Time:** 2 sessions.
- **Data:** `lazega`, `gang`, `macaque`; `florentine` in Ex. 2.
- **Builds on:** 6, 7.
- **Commands:** `nwsym`, `nwcomponents`, `nwclique`, `nwkplex`, `nwnclique`, `nwkcore`, `nwkcomponents`,
  `nwcohesion`, `nwcommunity`, `nwmodularity`, `nwplot`.
- **Where students get stuck:**
  - Forgetting that n-clique paths can leave the group, so two members may be connected only through outsiders.
  - Reporting a community result without the algorithm, its settings and the partition sizes. Louvain and label
    propagation return four communities against one on the advice network, and a bare count hides singletons.
  - Comparing the modularity of a detected partition with that of a known one as if both had been chosen the same
    way. The detected partition was selected for its high modularity.
  - Not stating the version of a directed relation. Reciprocated ties (`mode(min)`) give a much smaller network
    than ties in either direction (`mode(max)`).
  - Taking a k-core for a group that is hard to pull apart. A k-core is a minimum-degree condition; only
    k-components and the cohesion hierarchy test connectivity (Ex. 1).
- **Exercises:** 8. Basic 2 (1, 2); applied 4 (3–6); open 2 (7, 8).

### Chapter 10. Positions, roles, and structural equivalence
- **Time:** 2 sessions.
- **Data:** a small office typed in; `lazega`; `florentine`.
- **Builds on:** 8, 9.
- **Commands:** `nwsimindex`, `nwregular`, `nwconcor`, `nwcollapse`, `nwhierarchy`, `nwdendrogram`,
  `nwcoreperiphery`, `nwtoedge`; `nwdissimilar` for directed profiles.
- **Where students get stuck:**
  - Running `nwconcor` or `nwhierarchy` on two-mode data, which stops with error 6088. Project first, or cluster
    the profiles of one mode.
  - Forgetting that CONCOR rejects isolates, which can appear after symmetrizing or subsetting.
  - Trusting the default linkage. Single linkage put 68 lawyers in one cluster and three in singletons.
  - Reading within-block density from `nwcollapse`, whose image network has no diagonal.
  - Reading pooled Jaccard similarity as a directed comparison; use `nwdissimilar` when direction matters.
  - Expecting exact regular equivalence to find roles in dense data: one class for all 71 lawyers in the advice
    network, one class per lawyer in the friendship network.
  - Structural equivalence by hand: a tie between the two actors compared does not count (Ex. 1, 3).
- **Exercises:** 10. Basic 3 (1–3); applied 6 (4–9); open 1 (10).

### Chapter 11. Ego networks
- **Time:** 1 session.
- **Data:** `lazega`, `glasgow`; a small personal-network survey typed in.
- **Builds on:** 4, 7, 8.
- **Commands:** `nwego`, `nwegoplot`, `nwaltergen` (`proportion()`, `diversity()`, `hop()`, `net()`), `nwdegree`;
  `collapse` for survey data.
- **Where students get stuck:**
  - Letting a missing ego measure shrink a sample. Four of the 50 Glasgow girls name no friend, so their exposure
    is missing and a regression drops them; density is missing for every ego with fewer than two alters.
  - Entering size, density, effective size and constraint in one model, where the coefficients are unstable.
  - Reading composition as preference without a baseline of what the setting makes available.
  - Forgetting which network a command uses. `nwaltergen` without `net()` takes the most recently created network.
  - Applying `diversity()` to a continuous variable such as tenure or age.
- **Exercises:** 10. Basic 3 (1–3); applied 5 (4–8); open 2 (9, 10).

### Chapter 12. Two-mode networks
- **Time:** 1–2 sessions.
- **Data:** `davis`.
- **Builds on:** 6, 8, 9.
- **Commands:** `nw2toedge`, `nwdegree` and `nwclustering` for two-mode networks, `nw2project` (`stat(count)`,
  `stat(binary)`, `stat(jaccard)`), `nwcommunity`, `nwplot`.
- **Where students get stuck:**
  - Applying one-mode measures to raw two-mode data. Some commands stop with error 6088; others return a number for
    the bipartite graph read as one-mode, without normalization by mode. The command reference (Appendix C) lists
    how every command treats a two-mode network.
  - Reading a dense binary projection as informative: 91% of all pairs of the Southern women are tied in it.
  - Letting large groups dominate a projection. A group of *m* members produces *m*(*m*−1)/2 projected ties.
  - Density and degree in two modes: they divide by the size of the other mode (Ex. 2, 3).
- **Exercises:** 9. Basic 4 (1–4); applied 4 (5–8); open 1 (9).

### Chapter 13. Valued, signed, and multiplex networks
- **Time:** 2 sessions.
- **Data:** `lazega`, `gang` (valued), `chesapeake`, `gahuku`, `senate114`, `senate93`.
- **Builds on:** 6, 8.
- **Commands:** `nwtabulate`, `nwrecode`, `nwcorrelate`, `nwbalance`, `nwdegree` (strength), `nwbetween`
  (weighted and `binary`), `nwgen`.
- **Where students get stuck:**
  - Dichotomizing without reporting it. The recode in the chapter changes 133 of 315 ties. Commands differ in
    whether they use the values; `binary` switches them off, and each command prints which it used.
  - Taking the "changes made" line of `nwrecode` for a count of ties. It counts matrix cells, two per undirected tie.
  - Treating a negative tie as a missing one, or a missing tie as neutral.
  - Quoting a balance percentage without a baseline. With 39% positive ties, random signs already give 49%
    balanced triads; say whether the strong or the weak version is meant.
  - Reading inferred signs as likes and dislikes. The Senate signs compare co-sponsorship with what chance would
    give (Ex. 11).
- **Exercises:** 14. Basic 5 (1, 2, 5, 6, 7); applied 8 (3, 4, 8–13); open 1 (14).

### Chapter 14. Networks over time
- **Time:** 1 session.
- **Data:** `glasgow`; a small timestamped edge list typed in.
- **Builds on:** 3, 5, 6.
- **Commands:** `nwturnover` (with `formation`), `nwgen`, `nwplot` with `generate()` and `nodexy()`, `nwmovie`,
  `nwset ..., time()`, `nwattime`.
- **Where students get stuck:**
  - Comparing waves collected under different name-generator ceilings or boundary rules, which produces turnover
    that reflects measurement.
  - Comparing turnover across studies with different intervals between waves.
  - Using a movie in place of turnover statistics. An animation shows where change happened, not how much.
  - Reading turnover as the speed of the process: ties formed and dissolved within an interval are never seen.
  - Jaccard index and persistence have different denominators: all ties present in either wave, or the ties of the
    first wave (Ex. 2).
- **Exercises:** 8. Basic 3 (1–3); applied 4 (4–7); open 1 (8).

## Part III. Simulating networks

### Chapter 15. Random and structured network generators
- **Time:** 1–2 sessions.
- **Data:** `lazega` for comparison; generated networks.
- **Builds on:** 6, 7.
- **Commands:** `nwrandom`, `nwring`, `nwlattice`, `nwsmall`, `nwpref`, `nwgen`, `nwgeodesic`, `nwdegree`,
  `nwsummarize`, `nwplot`.
- **Where students get stuck:**
  - Reading a single draw as the model's typical outcome. Five draws of the same random graph gave transitivities
    from 0.175 to 0.181; ten graphs with 16 nodes ranged from 0 to 0.364.
  - Forgetting `set seed`, so that nothing downstream is reproducible.
  - Overlooking defaults: `nwlattice` and `nwsmall` produce directed networks unless `undirected` is specified.
  - Predicting chance levels: in a random graph every possible tie is present with the same probability, so the
    expected transitivity is about the density (Ex. 2, 3).
- **Exercises:** 9. Basic 4 (1–4); applied 4 (5–8); open 1 (9).

### Chapter 16. Generating networks from attributes and tie probabilities
- **Time:** 1–2 sessions.
- **Data:** `lazega`.
- **Builds on:** 6, 9, 15.
- **Commands:** `nwexpand`, `nwgen`, `nwdyadprob`, `nwhomophily`, `nwmixing`, `nwtoedge`, `nwfromedge`; `logit`
  and `predict` on the edge list.
- **Where students get stuck:**
  - Getting the direction wrong. `nwdyadprob` produces a directed network by default, even from a symmetric
    probability network.
  - Passing values that are not probabilities. Values outside 0 to 1 are treated as log-odds, without a warning.
  - Reading a homophily coefficient as a probability. It is a log-odds ratio: `homophily(3)` multiplies the odds of
    a within-group tie by about 20.
  - Judging an estimated generator by what it was fitted to. Only features outside the model, such as reciprocity
    and transitivity, test it.
  - Expected E-I values: they follow from the group sizes, as one minus twice the share of within-group pairs
    (Ex. 3).
- **Exercises:** 10. Basic 3 (1–3); applied 6 (4–9); open 1 (10).

### Chapter 17. Network structure and diffusion
- **Time:** 2 sessions. Students write and modify small Stata programs.
- **Data:** generated networks only (small world, ring, random graph, preferential attachment).
- **Builds on:** 7, 15.
- **Commands:** `nwsmall`, `nwpref`, `nwcontext`, `nwdegree`; the programs `diffuse`, `seedgroup` and
  `experiment`, written in the chapter; frames to collect results.
- **Where students get stuck:**
  - Starting complex contagion with a single adopter. With a threshold of two, nobody ever has two adopting
    neighbors (Ex. 4).
  - Letting the starting group change with the network. Fix its size and the rule that picks it, as `seedgroup`
    does.
  - Comparing networks with different numbers of ties. Hold size and mean degree fixed.
  - Reporting one run, or only a mean. Report the share of runs that succeed and the spread over many networks and
    starting groups.
  - Using the wrong direction of ties. `nwcontext` counts the neighbors a node sends ties to unless `mode()` says
    otherwise; use `mode(incoming)` for a process that travels from sender to receiver.
- **Exercises:** 6. Basic 2 (1, 2); applied 3 (3–5); open 1 (6).

## Part IV. Statistical inference for networks

### Chapter 18. Random networks and null models
- **Time:** 1 session.
- **Data:** `lazega`; `glasgow` in Ex. 4.
- **Builds on:** 6, 15.
- **Commands:** `nwcug` with `condition(density)`, `condition(census)` and `condition(degrees)`, and `plot`;
  `nwrandom`.
- **Where students get stuck:**
  - Calling a statistic high or low without a reference distribution. A transitivity of 0.33 means little until it
    is set against the 0.179 that chance gives at that density.
  - Reading a significant result as evidence for a mechanism. Rejecting the density null leaves closure, office
    sorting and a few very busy lawyers all in play.
  - Comparing tests with different conditioning without noticing. The calls differ by one word.
  - Choosing the p-value column: a claim that a statistic is larger than chance concerns one tail (Ex. 1).
- **Exercises:** 6. Basic 3 (1–3); applied 2 (4, 5); open 1 (6).

### Chapter 19. Permutation inference and comparing networks
- **Time:** 1 session.
- **Data:** `lazega`.
- **Builds on:** 6, 18.
- **Commands:** `nwpermute`, `nwcorrelate`, `nwmixing` with `permutations()`.
- **Where students get stuck:**
  - Running an ordinary correlation or regression on dyadic data. The rows share nodes and are not independent.
  - Confusing permutation with random-graph generation. The CUG test draws new networks; permutation relabels the
    observed one.
  - Using too few permutations. The two-sided p-value cannot be smaller than 2/(*R*+1); a value at that floor means
    more permutations are needed if a finer value matters (Ex. 2).
- **Exercises:** 6. Basic 3 (1–3); applied 2 (4, 5); open 1 (6).

### Chapter 20. QAP regression
- **Time:** 1 session.
- **Data:** `lazega`, `glasgow`.
- **Builds on:** 18, 19.
- **Commands:** `nwqap` (`qapspp`, `plot`, `mode()`, `type(regress)`, `predict()`), `nwgen`, `nwtoedge`.
- **Where students get stuck:**
  - Reporting QAP p-values as if they came from an ordinary regression. They come from refitting the model on
    permuted networks.
  - Forgetting that a coefficient controls only for what is in the model. The friendship coefficient is 2.47 in one
    model and 2.20 in another.
  - Using too few permutations for the precision claimed: 500 permutations cannot tell 0.003 from 0.004.
  - Not reporting the routine and the number of permutations when predictors are correlated.
  - Turning a logit coefficient into a probability: add the coefficients that apply to the constant, then apply
    1/(1+e<sup>−x</sup>) (Ex. 1).
- **Exercises:** 9. Basic 3 (1–3); applied 5 (4–8); open 1 (9).

### Chapter 21. Exponential random graph models
- **Time:** 2–3 sessions.
- **Data:** `lazega`.
- **Builds on:** 6, 7, 18, 19, 20.
- **Commands:** `nwergm` (`edges`, `mutual`, `nodematch()`, `nodeofactor()`, `nodeifactor()`, `gwesp()`,
  `edgecov()`), `estat mcmcdiag`, `estat gof`, `estimates store`, `lrtest`, `predict`.
- **Where students get stuck:**
  - Reporting a coefficient because MCMLE converged. The message records only that the algorithm stopped; read
    `estat mcmcdiag` after every fit, since effective sample sizes can be a few dozen among thousands of draws.
  - Treating good fit on the model's own statistics as proof. That agreement is guaranteed; the final advice model
    still misses the spread of the out-degrees and the number of pairs at distance 2.
  - Reading a coefficient: it compares the conditional log-odds of one tie for two pairs that differ only in that
    term, with every other tie held fixed (Ex. 1).
- **Exercises:** 10. Basic 2 (1, 2); applied 7 (3–9); open 1 (10).

### Chapter 22. Advanced exponential random graph models
- **Time:** 2 sessions.
- **Data:** `lazega`, `mesa`.
- **Builds on:** 18, 21.
- **Commands:** `nwergm simulate`, `nwergm` on an undirected network and with missing dyads, `nwtomata`; a small
  program `simsummary` written in the chapter.
- **Where students get stuck:**
  - Treating a coefficient as if it controlled only its own statistic. Setting the `mutual` coefficient to zero also
    lowered the density; setting the gwesp coefficient to zero cut it to a third. Adjust `edges` and report the
    density with every comparison.
  - Using raw triad counts (`triangle`, `ctriple`) on a clustered network. On Faux Mesa High estimation stops;
    use `gwesp`.
  - Losing the node attributes. `nwergm simulate` with a number of nodes replaces the data in memory; run it
    between `preserve` and `restore`.
  - Coding a missing dyad as a non-tie. Leave it missing; `nwergm` then leaves it out of the likelihood, which
    assumes the dyads are missing at random.
- **Exercises:** 6. Basic 2 (1, 2); applied 4 (3–6); open 0.

### Chapter 23. Stochastic actor-oriented models
- **Time:** 2 sessions.
- **Data:** `glasgow`.
- **Builds on:** 14, 21 (the first sections, on effect statistics and change statistics); 20 for the contrast with
  a model of one wave.
- **Commands:** `nwsaom` (`wave1()`, `wave2()`, `waves()`, `outdegree`, `reciprocity`, `transtrip`,
  `nodematch()`, `behavior()`, `behsim`, `avalt`), `nwsaom describe`, `nwsaom refit`, `estat gof`.
- **Where students get stuck:**
  - Reading the convergence t-ratios as significance tests, or the table's z as a convergence check.
  - Expecting any behavior to identify a co-evolution model. Alcohol use (five levels) supports one in the Glasgow
    data; smoking (three levels, rarely changing) gives very imprecise behavior estimates.
  - Fitting an SAOM to data that is not a panel. `nwsaom` needs two or more waves on the same actors, with joiners
    and leavers declared through `present()`.
  - Comparing coefficients of `avsim` and `avalt`, which measure influence on different scales; compare signs and
    p-values (Ex. 5).
- **Exercises:** 9. Basic 3 (1, 4, 7); applied 4 (2, 3, 5, 6); open 2 (8, 9).

### Chapter 24. Advanced stochastic actor-oriented models
- **Time:** 2–3 sessions.
- **Data:** `glasgow`; `baerveldt19` (19 Dutch schools, two waves).
- **Builds on:** 23.
- **Commands:** `estat score`, `estat timetest`, `estat importance`, `estat simulate`, `estat mems`,
  `nwsaom simulate`, `nwsaom` with `ml`, `nwsaom bayes`, `nwsaom multinet` (described), `nwstack`, `nwsaom` with
  `groups()`, `nwsaom meta`.
- **Where students get stuck:**
  - Freeing every effect that the score test flags in one step. Each test is conditional on the effects in the
    model at that moment.
  - Reading a short Bayesian run to the last digit. The effective sample size says how many independent draws the
    chain is worth; the ends of a credible interval need hundreds.
  - Interpreting the cross-network coefficient of `nwsaom multinet` when one network is nearly a subset of the
    other. It then records the overlap.
  - Reporting the standard errors of a joint model without a heterogeneity check. They are too small when the
    groups do not share their effects.
- **Exercises:** 5. Basic 1 (1); applied 2 (2, 3); open 2 (4, 5).

### Chapter 25. Relational event models
- **Time:** 1–2 sessions.
- **Data:** `manufacturing` (the first two weeks, `keep if t < 14`); a ten-event toy log typed in.
- **Builds on:** 14 and the first sections of 21; 23 for the comparisons the chapter draws.
- **Commands:** `nwset ..., eventtime()`, `nwrem` (`nodsnd`, `nidrec`, `frpsndsnd`, `rsndsnd`, `covevent()`),
  `nwload ..., xvars`, `nwexpand`.
- **Where students get stuck:**
  - Looking for an intercept. The likelihood compares pairs at the same instant, so none can be estimated.
  - Quoting a single `nodsnd` or `nidrec` coefficient as stable; both shift with the other effects in the model.
  - Building a `covevent()` network from the event rows. It needs one row per actor, from `nwload` with `xvars`.
  - The risk set: at each event every ordered pair of actors is at risk, 129 × 128 for the email log (Ex. 2).
- **Exercises:** 8. Basic 3 (1–3); applied 3 (4–6); open 2 (7, 8).

### Chapter 26. The Dynamic Network Actor Model
- **Time:** 1–2 sessions.
- **Data:** `manufacturing`; the toy log of Chapter 25 in Ex. 2.
- **Builds on:** 25.
- **Commands:** `nwset ..., eventtime() directed`, `nwdynam` (`submodel(rate)`, the choice sub-model, `intercept`,
  `inertia`, `recip`, `indeg`, `outdeg`, `same()`), `nwload ..., xvars`.
- **Where students get stuck:**
  - Reading `indeg` and `outdeg` the same way in both sub-models. In the rate sub-model they describe the acting
    actor, in the choice sub-model the candidate receiver.
  - Taking an order-only fit for one that uses waiting times. Without `intercept` the rate sub-model is order-only,
    and the choice sub-model never has an intercept.
  - Declaring the event network without `directed`. `nwdynam` then stops; only `choice_coordination` needs an
    undirected network.
- **Exercises:** 8. Basic 3 (1–3); applied 3 (4–6); open 2 (7, 8).

## Part V. Doing network research

### Chapter 27. A complete network analysis
- **Time:** 2 sessions.
- **Data:** `lazega`; `gang` in Ex. 7.
- **Builds on:** 6, 8, 9, 18, 20, 21; 22 helps.
- **Commands:** no new commands; the chapter combines `nwdegree`, `nwkcore`, `nwsym`, `nwqap`, `nwergm`,
  `nwergm simulate`, `estat`, `nwdrop` and frames.
- **Where students get stuck:**
  - Reading a receiver effect of status as deference. It shows only that partners are sought more.
  - Counting the same finding three times. The density table, the QAP model and the ERGM use the same 892 arcs.
  - Judging the all-partner core against random labels alone. Activity alone puts lawyers into a k-core, so the
    baseline has to hold it fixed, and for cores of reciprocated ties the reciprocity as well.
  - Choosing the sensitivity runs after seeing the results. State them with the expectations.
- **Exercises:** 8. Basic 3 (1–3); applied 3 (4–6); open 2 (7, 8).

### Chapter 28. Reproducible and responsible network research
- **Time:** 1 session.
- **Data:** `lazega`; `glasgow` in Ex. 5.
- **Builds on:** 3, 5, 18, 27.
- **Commands:** stored results of `nwcug` and `nwqap` (`return list`, `ereturn list`); in Ex. 5, `postfile` to
  collect results.
- **Where students get stuck:**
  - Treating the removal of names as anonymization. Structural re-identifiability has no analogue in ordinary data
    sets and must be assessed on its own terms.
  - Expecting rerun plotting code to reproduce a figure. Unless the coordinates were saved, it will not.
  - Citing a moving development version of the software instead of a specific, tagged one.
  - Reading tail p-values: with the plus-one correction a tail p-value is (count + 1)/(*R* + 1) (Ex. 3).
- **Exercises:** 7. Basic 3 (1–3); applied 2 (4, 5); open 2 (6, 7).

## Appendices

The appendices have no exercises. For teaching, the most useful are Appendix B (*When things go wrong*, on
reading error codes) for the first labs, Appendix C (*Command reference*, with R and Python equivalents and the
network types each command supports) for students who come from other software, Appendix D (*Datasets used in
this book*) for planning, and Appendix A (*Performance and network size*) before students analyze large networks
of their own. Appendix E is a mathematical reference, Appendix F covers programming with networks in Mata, and
Appendix G collects the notation and a glossary.
