---
title: "Assignments with other data"
parent: "Teaching and workshops"
nav_order: 5
description: "Nine assignments that apply the methods of Network Analysis with Stata to data sets that nwwebuse loads but the book's chapters do not use as their main example."
permalink: /book/teaching/assignments/
---

# Assignments with other data
{: .no_toc }

Each assignment applies the methods of some chapters to a data set that ships with nwcommands but is not the main
example of those chapters. Students who have worked through the chapters on the lawyers or the Glasgow girls then
have to make the decisions themselves: which version of a relation, which baseline, which rule for unreachable
pairs. All data sets load with `nwwebuse` and are described on the [Data sets](/datasets/) page; `help netexample`
in Stata gives their variable codings.

The questions do not give the results. Every assignment ends with an open question that has no single answer.

1. TOC
{:toc}

## 1. Factions in a monastery
- **Data:** Sampson's monastery, `nwwebuse sampson`. Eighteen novice monks; ranked choices at three times
  (`samplk1` to `samplk3`) and a liking ranking (`samplike`), directed and valued with values 1 to 3. Attributes:
  `faction` (Loyal, Turks, Outcasts) and `cloisterville`.
- **Draws on:** Chapters 6, 9, 10, 13 and 19.
- **Questions:**
  1. Run `nwsummarize` on the four networks and `nwtabulate samplike`. Read the coding of the values in
     `help netexample`. Is a higher value a stronger tie? Decide whether to use the values or to dichotomize, and
     state the rule. A binary version is `nwrecode samplike (1/3 = 1), generate(like01)`.
  2. Report the dyad census and reciprocity of the liking network with `nwdyads`.
  3. Run `nwmixing samplike, attribute(faction) permutations(1000)` after `set seed 12345`. Compute from the
     faction sizes (`tab faction`) the E-I index that random labels would give, and read the observed index against
     it, not against zero.
  4. Find positions with `nwconcor like01, splits(2) generate(block)` and with `nwhierarchy like01, groups(3)
     linkage(wardslinkage) generate(h3)`. Cross-tabulate each with `faction`. Repeat the hierarchical clustering
     with the default single linkage. Which method recovers the factions, and why might a block differ from a
     faction?
  5. Run `nwcommunity like01, algorithm(louvain) seed(12345) symmetrize generate(com)` and cross-tabulate the
     communities with `faction`. Say what a community and a block each claim about the monks.
  6. Open: the factions were revealed after the liking ranking was collected. Does a partition that matches them
     show that the liking ties produced the split? Name a rival account.

## 2. A karate club that split
- **Data:** Zachary's karate club, `nwwebuse zachary`. Thirty-four members, undirected; `zachary_bin` (binary) and
  `zachary_val` (the same 78 ties, valued up to 7 by the number of contexts in which two members interacted).
  Attribute: `group`, the faction each member joined after the split. The instructor is `Mr Hi`; the club's
  president is node 34.
- **Draws on:** Chapters 8, 9 and 13.
- **Questions:**
  1. Run Louvain (`nwcommunity zachary_bin, algorithm(louvain) seed(12345) generate(lv)`) and label propagation
     under four seeds (`algorithm(labelprop)` with `seed(1)` to `seed(4)`). Report the number of communities, the
     modularity and the cross-tabulation with `group` for each run.
  2. Compute the modularity of the observed split with `nwmodularity zachary_bin, group(group)`. Compare it with
     the modularity of the detected partitions. Why is this comparison unfair to the observed split?
  3. Run `nwkcore` and `nwkcomponents` with `k(2)`. Is either faction a cohesive group by these stricter tests?
  4. Compute betweenness on `zachary_bin` and on `zachary_val`, and with the option `binary` on `zachary_val`.
     Which members change rank? The weighted version treats a high value as a short step; say what that assumes
     about the values.
  5. Open: a method that "finds" a split known in advance looks impressive. What would it take to predict the split
     from data collected before it?

## 3. Borders between US states
- **Data:** US state borders, `nwwebuse usstates`. Fifty states, undirected, 107 ties; a tie means a shared land
  border. Node labels are the two-letter abbreviations.
- **Draws on:** Chapters 7, 8, 15 and 18.
- **Questions:**
  1. Run `nwsummarize` and `nwcomponents usstates, generate(comp)`. Which states are not in the main component,
     and why?
  2. Run `nwgeodesic usstates`, then again with `unconnected(50)` (give the second call `name()`, since the
     network `_geodesic` exists already). Which numbers change with the penalty, and which do not? What would you
     report?
  3. Find the shortest paths from Maine to California with `nwpath usstates, ego(ME) alter(CA)`. Report the length
     and the number of shortest paths.
  4. Compute betweenness and closeness (`nwcloseness usstates, unconnected(max) generate(clo far near)`). Which
     states score highest on each? Name the flow for which border betweenness would be a sensible measure, and one
     for which it would not.
  5. Report the transitivity with `nwtriads usstates`. Draw ten undirected random graphs with 50 nodes and the same
     density with `nwrandom` and `set seed 1`, and compare their transitivity and average distance with the
     observed values.
  6. Open: a random graph of the same density is an easy baseline to beat for a map. Which features of geography
     would a fairer baseline have to hold fixed?

## 4. Interlocking boards in Sweden
- **Data:** Swedish company directors, `nwwebuse ftdirectors_se`. A two-mode network of 5,092 directors and 455
  listed companies (5,669 ties); mode 1 `director`, mode 2 `company`. Directors have `gender` and `age`; companies
  have `sector`, `industry` and `employees`. Some values are missing.
- **Draws on:** Chapters 9 and 12, and Appendix A of the book on network size.
- **Questions:**
  1. Run `nwsummarize ftdirectors_se` and `nwdegree ftdirectors_se, generate(deg)`. The two-mode degree is divided
     by the size of the other mode; turn it back into the number of boards per director and the number of
     directors per board. How many directors sit on more than one board?
  2. Project onto the companies: `nw2project ftdirectors_se, project(2) name(boards) stat(count)`. What does a tie
     in `boards` mean, and what does its value count? Why is the projection onto the 5,092 directors a poor first
     step here?
  3. Run `nwcomponents boards, generate(bcomp)`. Report the size of the largest component and the number of
     companies with no shared director.
  4. Run `nwmixing boards, attribute(sector)`. Do interlocks stay within sectors more than the sector sizes alone
     would produce? Say how you treat the companies without a sector.
  5. Run `nwcommunity boards, algorithm(louvain) seed(12345) generate(bcom)` and report the partition sizes,
     singletons included.
  6. Open: an interlock can carry information between companies, or merely record that a few people are in
     demand. Which data would separate the two readings?

## 5. Friendship in a Dutch school class
- **Data:** the Knecht classroom, `nwwebuse klas12b`. Twenty-six pupils in their first year of secondary school,
  friendship at four waves three months apart (`klas12b_wave1` to `klas12b_wave4`), and `klas12b_primary` (same
  primary school). Attributes include `sex`, `age`, `ethnicity`, `religion`, delinquency at four waves
  (`delinq1` to `delinq4`) and alcohol use at waves 2 to 4. In the delinquency and alcohol variables 0 means
  missing. In the loaded networks, a missing answer and a pupil who was not in the class at a wave are both coded
  as no tie (`help netexample`).
- **Draws on:** Chapters 3, 6, 14, 25 and 26.
- **Questions:**
  1. Run `nwsaom describe, waves(klas12b_wave1 klas12b_wave2 klas12b_wave3 klas12b_wave4)` and `nwturnover`
     (with `generate()`, as in Chapter 14) for each pair of consecutive waves. Is there enough change, and not too much, for an SAOM?
  2. Run `nwmixing` with `attribute(sex)` and `permutations(1000)` at each wave. Read each E-I index against its
     chance value.
  3. Fit `nwsaom, waves(klas12b_wave1 klas12b_wave2 klas12b_wave3 klas12b_wave4) outdegree reciprocity transtrip
     nodematch(sex) seed(12345)`. Check both convergence criteria and restart with `nwsaom refit` if needed.
     Interpret `nodematch_sex` as a statement about the pupils' choices.
  4. Run `estat gof, nsim(100) seed(1)`. Where does the model fail?
  5. Hold two candidate effects at 0 with `fix()`, as Chapter 26 does, and run `estat score`. Which effect would
     you free first?
  6. Open: no tie and no answer are coded alike here. Which of your results could that affect, and in which
     direction?

## 6. Support among the characters of the Harry Potter books
- **Data:** Harry Potter support networks, `nwwebuse hpotter`. Sixty-four characters; directed support ties in each
  of six books (`hpbook1` to `hpbook6`). Attributes: `schoolyear`, `gender` and `house` (coded 1 to 4).
- **Draws on:** Chapters 3, 6, 14, 19 and 20.
- **Questions:**
  1. Run `nwsummarize` on all six networks. The number of ties differs a lot between books. Using the reporting
     checklist of Chapter 3, say what a "wave" is in these data and what the book-to-book differences may reflect
     besides change in support.
  2. Run `nwturnover` (with `generate()`, as in Chapter 14) for each pair of consecutive books and report the Jaccard index and persistence.
  3. Report the reciprocity of each book with `nwdyads`.
  4. Look at the mixing table of `hpbook1` by `house` before testing anything. Then run `nwmixing hpbook5,
     attribute(house) permutations(1000)` and the same with `attribute(gender)`. Compute the chance values from the
     group sizes (`tab house`, `tab gender`).
  5. After `set seed 12345`, fit `nwqap hpbook2 hpbook1 house gender, permutations(200)`. Read the coefficients of
     the earlier book and of shared house. Fit the same model for a later pair of books.
  6. Open: the ties were coded from novels by readers. What is a tie here, and which conclusions about real support
     networks could such data support?

## 7. Nineteen Dutch schools compared
- **Data:** the Dutch Social Behavior study, `nwwebuse baerveldt19`. Nineteen schools, two waves; for each school
  *k* the networks `schoolk_w1` and `schoolk_w2` (directed) and `schoolk_ethn` (whether the parents of two pupils
  were born in the same country). Chapter 26 uses these data for a joint SAOM; this assignment compares the
  schools descriptively and with permutation methods.
- **Draws on:** Chapters 6, 14, 18, 19, 20 and 30; Chapter 26 for the last question.
- **Questions:**
  1. In a loop over the schools, collect size, density, mean degree, reciprocity (`nwdyads`) and the Jaccard index
     between the waves (`nwturnover`) into a results data set with `postfile`, using stored results instead of
     retyped numbers (as in Chapter 30, Ex. 4). Which schools are dense? Does the ranking change with mean degree?
  2. Check whether the waves contain missing ties, and how the measures you use treat them.
  3. Test the reciprocity of the first wave in each school with `nwcug, stat(nwdyads) rname(reciprocity)
     condition(density)`, with a modest `reps()`. Then repeat the test for one school with `condition(census)`
     in place of `condition(density)`, and say why that condition cannot test reciprocity.
  4. For three schools, run `nwcorrelate schoolk_w1 schoolk_ethn, permutations(1000)` and `nwqap schoolk_w2
     schoolk_w1 schoolk_ethn, permutations(500)`. Is friendship sorted by ethnic background, once the earlier
     friendships are held fixed?
  5. Open: on the evidence of your table, would you pool the schools in one model or analyze them separately and
     combine the results? Compare your answer with the reasoning of Chapter 26.

## 8. The full US airport network
- **Data:** US airports, `nwwebuse usair_full`. Every US airport with a scheduled non-stop domestic route: 549
  airports, 5,450 directed routes. Attributes: `iata`, `name`, `city`, `lat`, `lon` and the degrees `_outdegree`,
  `_indegree` and `_degree`. Chapters 5 and 7 use `usair`, the 50 busiest airports.
- **Draws on:** Chapters 3, 5, 7 and 8, and Appendix A of the book.
- **Questions:**
  1. Run `nwcomponents usair_full, generate(comp)` and list the airports outside the main component with their
     cities. What are they?
  2. Run `nwgeodesic usair_full`. Report the share of connected pairs and the average distance over them. Compare
     with `usair`, and say what the boundary of the 50 busiest airports hides (Chapter 3).
  3. Compute betweenness and list the five highest airports with their cities. The highest is not the busiest hub;
     explain why, from the routes it connects.
  4. Compute closeness with `unconnected(max)` and once without the option. How do the rankings differ, and which
     would you report?
  5. Optional: draw the network on the map of the states as Chapter 5 draws `usair`, with `nodexy(lon lat)` and
     `basemap(usmap)`, restricted to the contiguous states with an `if` condition.
  6. Open: betweenness counts shortest paths in the number of flights. Which question about air travel does that
     answer, and which does it not?

## 9. A tailor shop before and after a dispute
- **Data:** Kapferer's tailor shop, `nwwebuse kapferer`. Interaction among workers at two times around a labor
  dispute, undirected: `kapferer_t1` (39 nodes, 158 ties) and `kapferer_t2` (43 nodes, 190 ties). The two networks
  do not share a node set, so they are not a panel on the same actors. No attributes.
- **Draws on:** Chapters 6, 9, 14, 21 and 22.
- **Questions:**
  1. Describe both networks: density, mean degree, transitivity (`nwtriads`), components and k-cores (`nwkcore`).
     Which comparisons between the two are fair, given that the node sets differ?
  2. Try `nwturnover kapferer_t1 kapferer_t2, generate(_turnover)`. Why does it not apply here?
  3. Fit `nwergm kapferer_t2, edges gwesp(.5) seed(12345)`. Run `estat mcmcdiag` and `estat gof, gof(model
     distance degree espartners) seed(12345)`. Where does the model fit and where does it fail?
  4. Fit `nwergm kapferer_t2, edges triangle seed(12345)` with `capture noisily`. What happens, and why does
     `gwesp` avoid it?
  5. Fit the gwesp model to `kapferer_t1` as well. What would you need to know before reading a difference between
     the two coefficients as a change caused by the dispute?
  6. Open: design a study of the same shop that could show whether the dispute changed who interacts with whom.
