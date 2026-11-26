---
title: "Exercise bank"
parent: "Book companion"
nav_order: 2.5
description: "More exercises for Network Analysis with Stata, with hints: the exercises that are not printed in the book, by chapter, for instructors and for readers who want more practice."
permalink: /book/teaching/exercises/
---

# Exercise bank
{: .no_toc }

The book prints about six exercises at the end of each chapter. The exercises below go with the same chapters and are
not printed in the book. They use the same data sets, commands and notation as the chapter they belong to, and each has a
hint. The levels are the book's: basic (a hand calculation or a short check), applied (rerunning or extending the
chapter's code) and open (a question to argue). The labels, such as 15.a, number the exercises of this page within each
chapter. Section, chapter and figure numbers refer to the book.

1. TOC
{:toc}


## Chapter 1: Why networks?

**1.a** (basic) For each of the following, say whether it is an attribute or a relation, and give a one-line reason: (a) a student's grade; (b) whether two students sit next to each other; (c) the number of countries a firm exports to; (d) whether country A has a treaty with country B; (e) a person's age.

*Hint.* Ask whether the quantity can be written down for one unit without mentioning any other unit. For (c), ask what is being counted and whom the count describes (Section 1.1.1).

**1.b** (basic) A survey of 2,000 employees of one firm records salary, education, tenure and department, one row per employee. List two questions from this chapter that this dataset can answer and two that it cannot. What single piece of information would have to be added to answer the second pair?

*Hint.* Go through the four mechanisms of Section 1.2 (access, brokerage, closure, diffusion) and ask, for each, whether it can be studied with one row per employee and nothing about who deals with whom.

**1.c** (basic) Section 1.5 names three uses of a network in an argument: the network as a cause (network properties explain an outcome), as an outcome (the ties themselves are explained), or as a context (the network is the medium through which some other process runs). Assign each study to one use: (a) a study asking whether central employees are promoted faster; (b) a study asking why some pairs of countries form trade agreements and others do not; (c) a study asking how quickly a rumor spreads through a company depending on its organizational chart.

*Hint.* For each study, name what is being explained. Then ask where the network sits: among the explanations, in the thing explained, or as the route along which the explained process travels.

**1.d** (applied) A researcher observes that scientists who collaborate tend to work in the same subfield, and concludes that scientists prefer to collaborate with people who study similar topics. Using the three accounts of Section 1.3.1 (preference, opportunity structure, institutional sorting), describe one alternative explanation of the same pattern that requires no preference for similarity, and name one piece of additional information that would help to separate it from preference.

*Hint.* Start from the opportunity-structure account of Section 1.3.1, the foci of Feld (1981), and list the settings where scientists meet the people they could collaborate with. Would the pattern still arise if each scientist chose partners at random among the people met there?

**1.e** (applied) Take an example from your own life or from a field you know, such as friendships in a class, collaboration between researchers, or trade between countries. Describe one step in each direction of the cycle of Figure 1.1: how an existing tie led to a later tie, and how the position a person ended up in shaped what the person could do.

*Hint.* For the first step, name a tie that exists because of an earlier one (an introduction by a friend, a shared class). For the second, name an opportunity, such as a job offer or early news, that came through a position.

**1.f** (open) A high betweenness score, a node lying on many shortest paths between others, is often read as brokerage (Section 1.4). In four short answers, say what the brokerage idea claims, what the score measures, what other situation could make the same score high, and what evidence would count against the brokerage reading.

*Hint.* Keep apart what the score counts (positions on shortest paths) and what brokerage needs (something worth passing on, and some control over it). Then ask what a node would look like that has the first without the second.


## Chapter 2: What is a network?

**2.a** (basic) Anna and Sophie wrote three papers together, Sophie and Gwen one, and Anna and Gwen none. Write the valued edge list and the adjacency matrix. Which ties remain if the network is dichotomized so that two authors are tied only when they have written at least two papers together, and what information is lost?

*Hint.* The relation is undirected, so the matrix is symmetric, with the 3 and the 1 appearing above and below the diagonal. A threshold of 2 keeps a tie only where the cell is 2 or more.

**2.b** (applied) Do for the lawyers' friendship network what Section 2.8 did for advice: run `nwsummarize lazega_fr`, then `nwsym lazega_fr, generate(fr_und)` and `nwsummarize fr_und`. From the number of arcs and the number of edges alone, work out how many pairs of lawyers name each other as friends and in how many pairs only one names the other. Do the same for advice (892 arcs, 700 edges). In which relation is a larger share of the tied pairs mutual?

*Hint.* A mutual pair holds two arcs but becomes one edge; a one-sided pair holds one arc and becomes one edge. So arcs minus edges gives the number of mutual pairs, and edges minus mutual pairs the number of one-sided pairs.


## Chapter 3: From a research question to a network and a method

**3.a** (applied) The Teenage Friends and Lifestyle Study asked pupils to name up to six friends; in the full study, 129 of 160 original pupils were present at all three waves. Suppose a later analysis reports the network's density at each wave using only those 129 pupils. What boundary decision has this analysis made, and what would you want to know before trusting a claim that density changed between waves?

*Hint.* Ask who was dropped and why: pupils who changed schools or missed a wave may have had more or fewer friends than those who stayed (Section 3.8).

**3.b** (applied) A study wants to know whether employees whose friends smoke are more likely to start smoking themselves. Say what an ego-network survey of a large national sample can and cannot offer for this question, and what a whole-network panel of a single workplace would add. Name, for each design, what it lets you observe about the friends and about change over time.

*Hint.* For each design, ask who reports the friends' smoking (the respondent or the friends themselves), whether the ties among the friends are observed, and whether the same people are measured again later. Section 3.7 compares the two designs.

**3.c** (applied) The lawyers' advice network is bounded by the firm. Name two research questions about advice among lawyers for which this boundary is adequate and two for which it is not, and say for each of the latter what would have to be collected.

*Hint.* Section 3.3 explains why measures stop at the boundary, and its paragraph on named actors who are not surveyed gives two ways to reach beyond it. For each candidate question, ask whether everyone it needs works inside the firm.

**3.d** (applied) Two researchers use the lawyers' friendship nominations. One asks which pairs of lawyers can be counted on to keep each other's confidences; the other asks how widely a rumor could spread through the firm. Choose between the OR rule (501 ties) and the AND rule (74 ties) for each question, defend the choice by saying what a tie must stand for in each, and say what you would report about the network you did not use.

*Hint.* The section on whose report counts says what a one-sided report may stand for. For each question, ask whether the tie must be acknowledged by both lawyers, or whether one lawyer's report is enough for something to pass along it.


## Chapter 4: Working with networks in Stata

**4.a** (basic) Explain in your own words why `nwload` turns a network into Stata variables only when asked, rather than automatically. Then describe one situation in which having the adjacency matrix as Stata variables is necessary rather than merely convenient.

*Hint.* Count how many variables a network of $n$ nodes adds to the dataset, and compare that with the variable limit of your Stata edition. For the second part, ask what an ordinary Stata command, one that knows nothing about networks, needs as input; the end of the section on `nwload` names the uses.

**4.b** (applied) Return to the survey example of Section 4.4 (with Gwen naming Leh, as in the chapter). Build the network as directed, `nwfromedge id friend, name(fdir) directed`, and report its number of arcs and its density. Then derive the two undirected versions with `nwsymmetrize` (Section 4.9): `mode(max)` for the union rule and `mode(min)` for the intersection rule. Report the number of edges and the density of each, and say which version the chapter's `undirected` option produced.

*Hint.* Start from the long data of the chapter again, up to and including its `drop`: `nwfromedge` replaces the data in memory by the network, so the edge list is gone after the first call. Type `nwsymmetrize fdir, mode(min) generate(f_and)` and the same with `mode(max)` and `generate(f_or)`, then `nwsummarize fdir f_and f_or`. A directed network of five people has $5 \cdot 4 = 20$ possible arcs, an undirected one $10$ possible edges.


## Chapter 5: Seeing networks

**5.a** (basic) Write the interactive page of the Florentine marriage network as in Section 5.8, with `fname(flo_drag.html)` and `generate(x y)`, open it in a browser and drag the Medici family to three different places. For each of the following, say whether it changed: the number of Medici's ties, the lengths of its lines, its betweenness of 47.5, and the answer a reader of the picture would give to "is Medici central?". Then say in one sentence what this shows about reading layouts.

*Hint.* The page moves positions only and computes nothing. Ask which of the four items could be computed from the ties without ever drawing the network.

**5.b** (applied) After `nwwebuse usair, nwclear`, draw the airports twice: once with the default layout, `set seed 42` and `nwplot usair, label(_nwnode)`, and once on the map with the command of Section 5.9, adding `label(_nwnode)`. Name two airports that sit on the rim of the default picture, and find their numbers of routes with `nwdegree usair, generate(routes routes_in)`. Compare those numbers with the mean number of routes (`summarize routes`), and say what places an airport on the rim of each of the two pictures. (The map leaves out Anchorage and Honolulu.)

*Hint.* `list _nwnode City routes, clean noobs` lists the number of routes of every airport. For the last part, ask what each picture uses to place a node: Table 5.2 for the default layout, the coordinate variables for the map.

**5.c** (applied) After `nwwebuse chesapeake, nwclear`, draw Figure 5.9 again with the commands of Section 5.10, adding `generate(cx cy)` to keep the positions. Draw the same picture twice more at the same positions (`nodexy(cx cy)` instead of `layout(mds)`): once with the raw flows as widths, `edgesize(chesapeake)`, and once with their square root, created by `nwgenerate chesapeake_sqrt = sqrt(chesapeake)`. Say how many ties you can still tell apart in each picture, and explain why a transformation is the right choice here on substantive grounds, not only because the picture looks better.

*Hint.* The flows run from 0.21 to 623,594, and `edgesize()` scales the widths in proportion to the values between a narrowest and a widest line. Work out where a flow of 1,000 would fall between the two. For the substantive part, ask whether a flow of 1,000 matters so little to the food web that it should look the same as a flow of 1.

**5.d** (applied) Build the Hartford subnetwork as in Section 5.2 (`nwsubset lazega_adv if office == "Hartford", name(hartford)`) and write its interactive page with `set seed 42` and `nwplot hartford, label(_nwnode) color(status) interactive noopen fname(hartford.html)`. On the page, drag `n46`, the lawyer at the bottom of Figure 5.3, into the middle of the picture, save the do-file and run it. Say what a reader of the new figure would conclude about `n46`, and which facts about `n46` (how many colleagues it names, how many name it) stayed the same.

*Hint.* The saved do-file must run with the same data in memory as when the page was written: load the lawyers and run the same `nwsubset` command first, so that the nodes are in the same order.

**5.e** (applied) Create the log-flow network with `nwgenerate chesapeake_log = ln(chesapeake + 1)` and write the page of the Chesapeake Bay food web with `nwplot chesapeake, interactive noopen fname(chesapeake.html)`. On the page, move the edge-width slider to its smallest and to its largest value and describe what changes. Then follow the routine of Section 5.8: save the do-file, add `edgesize(chesapeake_log)` to its `nwplot` call and run it. Explain why the slider cannot do the work of the log transformation, and what the caption of the figure must say about the positions.

*Hint.* Compare what the slider and the log each do to the ratio of the widest to the narrowest tie. For the caption, look at the columns the do-file writes into `nwedit_nodes.csv` and `nwedit_edges.csv`, and ask where the positions they hold came from.


## Chapter 6: Describing networks

**6.a** (basic) From the friendship census (74 mutual, 427 asymmetric, 1,984 null), recompute by hand the reciprocity of 0.148 that `nwdyads` prints. Then compute the share of friendship *arcs* that are returned. Say why the two numbers differ, and which one answers the question "when a lawyer names a colleague as a friend, how often does the colleague name the lawyer back?"

*Hint.* Dyad-based: mutual over mutual plus asymmetric. Arc-based: the arcs that sit in mutual dyads, $2 \times 74$, over all 575 arcs. The two count different things: pairs and nominations.

**6.b** (basic) The advice triad census has 22,352 empty triads (003) and 99 fully mutual ones (300) among 57,155. Suppose instead that each of the six possible arcs in a triple were present independently with probability 0.179, the density. What share of triples would then be empty, and how many of the 57,155 would be fully mutual? Compare both with the census and say what the differences suggest about how advice ties are arranged.

*Hint.* A triple is empty when all six arcs are absent, with probability $(1 - 0.179)^6$, and fully mutual when all six are present, with probability $0.179^6$; multiply the latter by 57,155.

**6.c** (applied) Rerun `nwassortativity` on the advice network with `attribute(yrs_frm)`, the number of years with the firm. Is the coefficient larger or smaller than the 0.101 found for age? Say what comparison you would need before calling either value "small".

*Hint.* `describe` lists the lawyers' variables. For the second question, ask what values the coefficient takes when the same attribute values are shuffled at random over the lawyers; Chapters 19 and 20 build that comparison.

**6.d** (applied) The gang's birthplace groups have 12, 6, 24 and 12 members (`tab Birthplace`; not the tie-endpoint totals of the mixing table). Compute the expected share of within-group ties under random labels, and from it the expected E-I index. Explain why the observed index of 0.053 is a poor guide on its own.

*Hint.* The share is $\sum_k n_k(n_k-1)$ divided by $n(n-1)$, with $n = 54$; the expected E-I index is one minus twice the share.

**6.e** (applied) Take one measure of this chapter (reciprocity, transitivity, the E-I index or degree assortativity). Name the idea it stands for, as discussed in its section. Then say, for the lawyers', the Glasgow or the gang data, what pattern would count as evidence *against* that idea, and what other process could produce the value you observed.

*Hint.* A good answer names a different source of the same number, for example a nomination cap for reciprocity or a shared office for transitivity, and says what data would tell the two apart.

**6.f** (open) A researcher compares the density of a 30-person start-up's advice network with that of a 700-person firm. Argue whether density or mean degree should be reported for the comparison, and say in one sentence each what density hides and what mean degree hides.

*Hint.* Work through one example: if everyone in both organizations named 5 colleagues, what would the two densities be? Then ask whether the same mean degree could come from a few people naming everyone.


## Chapter 7: Paths, distance, and reachability

**7.a** (basic) Recover the average distance of 2.49 among the 105 connected Florentine pairs from the penalized summary of Section 7.7 alone, using the average shortest path length (4.175), the penalty (16), the number of pairs (120) and the number of unconnected pairs (15).

*Hint.* The total distance over all pairs is $4.175 \times 120$. Subtract what the unconnected pairs contribute and divide by the number of connected pairs.

**7.b** (basic) After `nwwebuse glasgow, nwclear`, run `nwgeodesic` on `glasgow1`. Report the share of ordered pairs that are connected, the average distance over the connected pairs and the longest chain of nominations. Compare the average with the lawyers' 2.025, and say why the two averages are not a fair comparison of how close the two groups are.

*Hint.* Because some pairs have no path, `nwgeodesic` prints `Share of pairs connected`, `Average over connected pairs` and `Longest over connected pairs`. Before comparing, ask which pairs each of the two averages is taken over.

**7.c** (applied) Find the shortest advice paths from the partner `n3` to the associate `n40`, the reverse of the pair in the chapter's worked example. Compare the length and the number of shortest chains with the path from `n40` to `n3` shown in the chapter. Is the distance the same in both directions for this pair, and is the number of routes?

*Hint.* Run `nwpath lazega_adv, ego(n3) alter(n40)`. A path follows the arrows, so the chains from `n3` start with the lawyers whom `n3` asks for advice.

**7.d** (applied) After `nwwebuse usair, nwclear`, run `nwsummarize` and `nwgeodesic` on `usair`, the direct routes among the 50 busiest US airports. Using the density, work out roughly what average distance a random network of the same size and density would have, and compare it with the observed average. Then compare the transitivity from `nwtriads` with the density, and say whether the airports form a small world in the sense of Section 7.6.

*Hint.* At such a high density, nearly every pair that is not tied directly shares a common neighbor, so a random network averages about $\text{density} \times 1 + (1 - \text{density}) \times 2$. A small world needs clustering well above the density as well as short distances.


## Chapter 8: Centrality, brokerage, and structural holes

**8.a** (basic) Check the betweenness of 19 for C in Table 8.1 by hand. List the pairs among the other seven nodes whose shortest path does not pass through C, and say why every other pair contributes exactly 1.

*Hint.* There are $\binom{7}{2} = 21$ pairs among the other seven nodes, so 19 means that two pairs do not need C. A pair contributes 1 when its only shortest path runs through C, and the toy network has no pair with two shortest paths.

**8.b** (applied) Load the law firm (`nwwebuse lazega, nwclear`) and run `nwbrokerage` on `lazega_adv` twice: once with the practice as the group (`group(practicenum)`), once with a four-category group that combines practice and status. For each run, report which roles occur and the share of the 8,448 two-paths that cross a group boundary (all roles except coordinator). Which role appears only in the second run, and why?

*Hint.* Create the four categories with `egen ps = group(practicenum partner)`. The share crossing a boundary is one minus the coordinator count divided by 8,448. Look back at the definition of the liaison role: how many different groups does it need?

**8.c** (applied) The section on degree centrality names a rival source of a high degree: a longer tenure. Check it for being sought in the law firm. Regress the advice in-degree `adv_in` on `i.partner` and `yrs_frm`, as the chapter regressed betweenness. Report the coefficient of the years with the firm and its $p$-value, and say whether tenure accounts for the partners being asked more often.

*Hint.* Generate `adv_out` and `adv_in` with `nwdegree lazega_adv, generate(adv_out adv_in) silent` and compare the partner coefficient with the raw difference in means (15.6 against 9.4) printed in the chapter. The partner coefficient falls but stays clearly positive, while the coefficient of years with the firm is not significant: tenure accounts for part of the difference, not all of it.

**8.d** (basic) Load the Florentine data and run `nwbridges` on the marriage network `flomarriage`, then reload the data and run it on the business network `flobusiness`. List the bridges of each network with `nwtoedge`. Which bridges are the single tie of a pendant family (a family with exactly one tie), and which bridge, if any, cuts off more than one family when it is removed?

*Hint.* Store the bridges as a network, for example `nwbridges flomarriage, name(mb)`, then `nwtoedge mb` and `list if mb == 1`. `nwtoedge` replaces the data in memory, which is why the data are reloaded before the second network. The marriage degrees of the families are in the Florentine table at the start of the chapter; the business degrees have to be computed with `nwdegree`. The marriage network has 5 bridges, 4 of them the single tie of a pendant family; the fifth, Medici–Salviati, cuts off two families. The business network has 3 bridges, all to pendant families.

**8.e** (applied) Load the law firm and build the reciprocated friendship network, `nwsym lazega_fr, mode(min) generate(frm)`, as Section 8.9 built `advm`. Report its number of ties, its number of local bridges and its number of Simmelian ties, and check that local bridges and Simmelian ties again add up to all ties. Then compare the share of Simmelian ties among the reciprocated friendship ties with the 126 of 192 for reciprocated advice, and say which relation is the more closed.

*Hint.* Use `nwsummarize frm` for the ties, `nwbridges frm, type(local) name(frlocal)` for the local bridges and `nwsimmelian frm, name(frsimm)` followed by `nwsummarize frsimm` for the Simmelian ties; read the `Bridges:` and `Edges:` lines.

**8.f** (applied) Partners have lower constraint than associates (.101 against .137), but they also send more advice ties. Does the status difference survive when the number of ties sent is about the same? Compare the mean constraint of partners and associates among the lawyers who send between 10 and 16 advice ties, and then regress constraint on `i.partner` and out-degree for all 71 lawyers. Report both comparisons and say what remains of the status difference.

*Hint.* Run `nwdegree lazega_adv, generate(adv_out adv_in) silent` and `nwburt lazega_adv`, then `tabstat _constraint if inrange(adv_out, 10, 16), by(status) statistics(mean n)` and `regress _constraint i.partner adv_out`. The out-degree range 10 to 16 is where both groups have members; report how many associates fall in it (few, so the comparison is thin).


## Chapter 9: Cohesion, subgroups, and communities

**9.a** (applied) Rerun the community detection of Section 9.6 on `lazega_cow`, the lawyers' co-work network, with the same settings (`algorithm(louvain) seed(12345) symmetrize`). Report the number of communities and the modularity, cross-tabulate the communities with `office`, `practice` and `status`, and compute the modularity of the partitions by office, by practice and by status. Do the co-work groups follow office and practice, as the advice and friendship groups do, or rank?

*Hint.* Use `nwcommunity lazega_cow, algorithm(louvain) seed(12345) symmetrize generate(cow_com)`, then `tab cow_com office` and so on, and `nwmodularity lazega_cow, group(officenum) symmetrize` with `practicenum` and `partner` in turn. Compare with the advice values (.165, .169, .024).

**9.b** (applied) Run label propagation on the friendship network `lazega_fr` under four seeds (`algorithm(labelprop) symmetrize` with `seed(1)` to `seed(4)`). Report the number of communities and the modularity of each run, and cross-tabulate one run that finds more than one community with the Louvain partition `fr_com` of the chapter. Which result would you report, and why?

*Hint.* Generate one variable per seed: `generate(lp1)` with `seed(1)`, `generate(lp2)` with `seed(2)`, and so on. Recreate the Louvain partition with `nwcommunity lazega_fr, algorithm(louvain) seed(12345) symmetrize generate(fr_com)`, then type `tab lp`*k*` fr_com`, with *k* a seed whose run finds more than one community: a Louvain community that falls entirely into one label-propagation community is a group that both methods find.


## Chapter 10: Positions, roles, and structural equivalence

**10.a** (basic) Rerun the CONCOR blocks of Section 10.5 and the core–periphery model of Section 10.9 on `lazega_adv`. Report the block of lawyer n24 (the most active asker of Chapter 8) and whether n24 is in the core. How many of the 18 core lawyers, n24 included, are in n24's block, and are the other core lawyers concentrated in one block or spread over all four?

*Hint.* `nwconcor lazega_adv, splits(2) generate(block)` and `nwcoreperiphery lazega_adv, generate(core)`; then `list _nwnode block core if _nwnode == "n24"` and `tab block core`.

**10.b** (applied) Cut the Florentine marriage network (`nwwebuse florentine, nwclear`) into two and into three groups with the default single linkage, `nwhierarchy flomarriage, groups(2) generate(s2)` and again with `groups(3) generate(s3)`, and into three groups with Ward linkage (`generate(w3)`). List the families of each group. Which families does single linkage split off, and how does its three-group cut differ from Ward's? What does that show about chaining on a network of sixteen families?

*Hint.* Add `linkage(wardslinkage)` for the Ward cut and list all three variables with `list _nwnode s2 s3 w3, clean`. Compare the families that single linkage separates with the degrees in the Florentine table of Chapter 8. With single linkage, a cut into four groups is refused because of tied distances.

**10.c** (applied) Rerun CONCOR with `splits(2)` on `lazega_fr`, the lawyers' friendship network, and cross-tabulate the four friendship blocks with the four advice blocks of Section 10.5. For each advice block, report the friendship block that holds most of its members, and say which friendship block corresponds to an office. Then compute the image matrix of the friendship blocks as in Section 10.6. Is the block that corresponds to an office also the most densely tied inside?

*Hint.* `nwconcor lazega_fr, splits(2) generate(frblock)`, then `tab block frblock` and `tab frblock office`. CONCOR needs every lawyer to have at least one tie; in the friendship network two lawyers name no friend, but both are named by others, so no lawyer has to be dropped. For the image matrix, use `lazega_fr` and `frblock` in place of `lazega_adv` and `block`.

**10.d** (applied) Add a third team to the small office of Section 10.3: a team leader `lead3` who asks Antonia, and two juniors, `junior5` and `junior6`, who ask `lead3`. Predict the classes of `nwregular` before you run it, then check. Next let `junior5` also ask Antonia directly, run `nwregular` again, and report the number of classes. Explain why `junior6` and `lead3` no longer share a class with anyone, although their own ties did not change.

*Hint.* Rebuild the edge list with `input str8 ego str8 alter` and `nwset ego alter, edgelist directed name(firm3)`, and compare `r(image)` before and after. Follow the splits step by step: first `junior5`, who now asks someone other than a team leader; then the leader that `junior5` asks; then the other junior of that leader.


## Chapter 11: Ego networks

**11.a** (basic) An ego has five alters and three ties among them in an undirected network. Compute the ego density and the effective size. Is the effective size nearer to the number of alters (5) or to 1, and what does that say about how redundant the alters are?

*Hint.* Five alters form 10 pairs. Use $n - d(n-1)$ with $n = 5$: an effective size equal to $n$ means no redundancy, and an effective size of 1 means that the alters are all tied to one another.

**11.b** (applied) The law firm records each lawyer's law school in the string variable `school` (Harvard/Yale, UConnecticut, other). Encode it (`encode school, generate(schoolnum)`) and build the share of each lawyer's advisers in `lazega_adv` who went to the lawyer's own school, as Section 11.4 built the own-office share. Report the mean share for each of the three schools and compare it with the share of the 70 colleagues from the same school. Which group turns to its own school more often than the firm's composition would predict?

*Hint.* `tab schoolnum` gives the codes (1 Harvard/Yale, 2 UConnecticut, 3 other) and the counts; a lawyer's baseline is the number of the other 70 lawyers from the same school, divided by 70. Build `ss1`, `ss2` and `ss3` with `proportion(alter.schoolnum==1)` and so on, pick ego's own share with `cond()`, and use `tabstat ..., by(school)`. Keep in mind that "other" is a mix of schools.

**11.c** (applied) Does exposure two steps away tell the same story as exposure among direct friends? In the Glasgow data, call a girl a drinker if she drinks at least once a month at the first wave (`alcohol1 >= 3`). Compute each girl's one-hop and two-hop exposure to drinkers in `glasgow1`, report their correlation and the number of girls for whom the two differ by 0.5 or more, and list the girls with the largest differences in each direction. What does the result say about treating two-hop exposure as a stronger version of one-hop exposure?

*Hint.* Make the indicator with `generate byte drink1 = (alcohol1 >= 3)`, then `nwaltergen dr1 = proportion(alter.drink1==1), net(glasgow1)` and the same with `hop(2)` for `dr2`. Generate `ddiff = dr2 - dr1` and sort by it. Only girls with friends and with someone exactly two steps out have both values.

**11.d** (open) A study asks respondents to name up to three people with whom they discuss important matters and computes ego-network size. Say what a size distribution with most respondents at three would tell you about the respondents and what it would tell you about the question. Then design a comparison of two countries whose surveys used different caps (three names and five names): which measures can be compared and how would you make them comparable?

*Hint.* Ask whether a respondent who names three people has exactly three confidants, or more that the question did not let them name. For the comparison, ask which measures depend on the number of names, and what the five-name survey would look like had it stopped at three.


## Chapter 12: Two-mode networks

**12.a** (basic) Verify the two-mode degree of Evelyn (0.571) and of event `E8` (0.778) from the attendance counts. Why can these two numbers not be compared with each other?

*Hint.* Count Evelyn's events and the attendees of `E8` in the attendance list, and divide each count by the number of nodes in the *other* mode. Then compare the two denominators.

**12.b** (basic) Flora and Olivia attended two events each. Which events? Using the attendance list, name the women who are *not* their neighbors in the projection of the women, and check that the number of neighbors agrees with the 12 given in the text.

*Hint.* A woman is a neighbor of Flora in the projection if she attended at least one of Flora's events. Go through the list and mark every woman who attended neither.

**12.c** (applied) How much of the women's projection rests on one large event? Event `E8` was attended by 14 of the 18 women. Compute how many pairs of women `E8` alone brings together. Then remove `E8` from the two-mode network, project again, and report how many of the 139 ties remain. What does the difference between the two numbers say about reading a projected tie as a sign that two women knew each other?

*Hint.* Fourteen attendees form $14\cdot 13/2$ pairs. To remove the event, keep every other node with `nwsubset davis if _nwnode != "E8", name(davis13)` (Section 4.9), then `nw2project davis13, project(1) name(w13) stat(count)` and read the `Ties:` line.


## Chapter 13: Multiplex, valued, and signed networks

**13.a** (basic) The recode of the gang network into two intensity bands (`intensity`) put the 315 ties into a low band and a high band. From the two `nwtabulate` tables of Section 13.3, compute the share of the 315 ties in each band, and compare them with the shares of the two extreme levels of the original coding (level 1 and level 4). Which distinctions of the original coding does the two-band coding erase, and which does it keep?

*Hint.* Divide the frequencies 274 and 41 of the recoded table, and 182 and 16 of the original table, by 315.

**13.b** (applied) Among the 1,574 ordered pairs of lawyers with at least one relation, 247 have all three and 824 exactly one (Section 13.2). Compute what these two shares would be if advice, co-work and friendship were independent, with the densities 0.179, 0.222 and 0.116, and compare them with the observed 15.7 and 52.4 percent.

*Hint.* Under independence, a pair has all three relations with probability $p_1p_2p_3$, exactly one with probability $p_1(1-p_2)(1-p_3) + (1-p_1)p_2(1-p_3) + (1-p_1)(1-p_2)p_3$, and none with probability $(1-p_1)(1-p_2)(1-p_3)$. Divide the first two by one minus the third.

**13.c** (basic) In the 114th Senate 39% of the ties are positive. Use the formula $\frac{1}{2}\{1 + (2p - 1)^3\}$ of the section on balance percentages to compute the share of balanced triads that random signs give, and do the same for $p = 0.1$ and $p = 0.9$. What do the three values show about a statement such as "80% of the triads are balanced"?

*Hint.* For $p = 0.1$ the term $(2p - 1)^3$ is $(-0.8)^3 = -0.512$.

**13.d** (applied) Run `nwbalance senate114` with `reps(100)` and `seed(2)`, and again with `reps(2000)` and `seed(3)`. Which lines of the output change and which do not? Why is the standard deviation over the draws so much smaller for the Senate (0.002) than for the tribes (0.060)?

*Hint.* The share balanced in one draw is an average over all closed triads of the network. How does the spread of an average depend on the number of items averaged, here 74,140 triads against 68?

**13.e** (applied) A triad violates weak balance only when it has exactly one negative tie. Under random signs with share $p$ of positive ties, that happens with probability $3p^2(1-p)$. Compute the share of weakly balanced triads that random signs give for the tribes ($p = 0.5$), the 114th Senate ($p = 0.388$) and the 93rd Senate ($p = 0.238$), and compare each with the observed share in the text (97.1, 99.4 and 98.9 percent). In which network is the observed weak balance least impressive, and why?

*Hint.* The random share is $1 - 3p^2(1-p)$. For each network, ask how much room the random share leaves below 100 percent, and how much of that room the observed share fills.

**13.f** (applied) Weighted betweenness treats the gang's ordinal codes 1 to 4 as quantities. Check how much the result depends on that. Recode the valued network to a steeper scale, `nwrecode gang_valued (4 = 8) (3 = 4), generate(steep)`, so that the codes become 1, 2, 4 and 8, and compute weighted betweenness on `steep`. Report its correlation with the default weighted betweenness and with the binary version, and say whether g23, the leader by weighted betweenness, keeps first place.

*Hint.* Generate `btw_wgt` and `btw_bin` as before and `nwbetween steep, generate(btw_steep)`; then `correlate btw_wgt btw_steep btw_bin`, `gsort -btw_steep` and list the first six.

**13.g** (applied) A managing partner asks whether friendship among the lawyers matters for how work gets done. You can show (a) the cross-tabulation of advice and friendship, (b) `nwcorrelate` of the two relations, or (c) the count of relations per pair from `nwgen`. Choose one for the managing partner, and for each of the three say in one sentence what it hides. Then name the analysis of Part IV you would need before calling the overlap more than descriptive.

*Hint.* For each display, ask what it reduces the overlap to: counts of pairs, a single number, or a count for each pair. For the analysis of Part IV, ask what, other than a link between the two relations, could put advice and friendship on the same pairs (Section 13.2).


## Chapter 14: Networks over time

**14.a** (basic) Check by hand the Jaccard index (0.384) and the persistence rate (0.569) for waves 2 to 3 from the counts of 66 stable, 56 formed and 50 dissolved ties.

*Hint.* The Jaccard index is stable divided by stable + formed + dissolved, the ties present in either wave. Persistence is stable divided by stable + dissolved, the ties of wave 2.

**14.b** (basic) The three Glasgow waves have 113, 116 and 122 ties among 50 girls. Compute the density of each wave by hand and check the first against the 0.046 of Chapter 6. Why does the near-constant density hide that about half of the ties changed between waves?

*Hint.* A directed network of 50 nodes has $50\cdot 49 = 2{,}450$ possible arcs. A density is computed from the number of ties alone; compare what it would be if every tie of wave 2 were a different one.


## Chapter 15: Random and structured network generators

**15.a** (basic) A directed random graph with 71 nodes has density 0.179. What transitivity does chance alone lead you to expect? The five draws printed in Section 15.2 gave 0.173 to 0.181. Why are these not exactly 0.179?

*Hint.* In the random graph of Section 15.2, every possible tie is present with the same probability, whatever else is tied; apply that to two neighbors of a node. For the second question, ask what changes from one draw to the next when the density stays the same.

**15.b** (basic) An undirected random graph has 20 nodes and a density of 0.2. How many pairs of nodes does it have, how many ties do you expect, and what is the expected degree of a node?

*Hint.* An undirected network of $n$ nodes has $n(n-1)/2$ pairs, and each pair is tied with probability 0.2. A node can be tied to each of the other $n-1$ nodes.

**15.c** (applied) Take the preferential-attachment generator. Say in one sentence which idea of the chapter it stands for. Then name one pattern in an observed network that would count as evidence *against* that idea, and one other process that could produce a similarly skewed degree distribution.

*Hint.* Section 15.6 states the growth rule and why a skewed degree distribution alone does not show that it operated. For evidence against the idea, ask when the hubs of an observed network joined it. For a rival, look for something other than the ties a person already has that could draw many ties to a few people.


## Chapter 16: Generating networks from attributes

**16.a** (basic) By what factor does `homophily(3)` in `nwhomophily` multiply the probability of a tie between two lawyers of the same practice, relative to two lawyers of different practices? What factor does `homophily(-3)` give, and what does a factor below 1 mean?

*Hint.* The coefficient is the log of the probability ratio, so the factor is $e$ raised to the coefficient: $e^{3}$ and $e^{-3}$.

**16.b** (applied) Draw a second block network with the same within-practice probability (0.08) but a between-practice probability of 0.05 instead of 0.01. Run `nwcommunity` (Chapter 9) on the printed block network `blocks` and on the new one, and cross-tabulate the communities with `practice`. In how many communities does one practice make up at least 80 percent of the members, in each network? What does this say about when community detection can find groups that are really there?

*Hint.* Make the probabilities with `nwgen blockprob2 = .05 + .03 * samepractice` and draw with `nwdyadprob`. The block networks are directed, so use `nwcommunity blocks, symmetrize generate(comm)`, then `tabulate comm practice`.

**16.c** (applied) `nwhomophily` accepts several attributes with one coefficient each. Build a network of density 0.179 with homophily on office (coefficient 1) and practice (coefficient 2): `nwhomophily office practice, density(.179) homophily(1 2)`. Measure the E-I index by office and by practice with `nwmixing`. Which attribute's homophily is more visible in the E-I index, and does that agree with the coefficients you set?

*Hint.* Compare each E-I index with its chance value ($-0.05$ for office, $-0.01$ for practice), not with zero. The coefficient for practice is the larger one.

**16.d** (applied) Build a block model on office instead of practice. Compute the share of advice ties among the pairs within an office and among the pairs in different offices, use them as the two probabilities of a block model as in Section 16.2, draw 20 networks from them, and measure in each the E-I index by practice and by status. Do the draws show homophily on practice or status, although the model gives these attributes no role? Compare with the observed E-I indices ($-0.368$ by practice, this chapter, and $-0.152$ by status, Chapter 6).

*Hint.* Make the network of shared offices with `nwexpand office, name(sameoffice)`. Then `preserve`, `nwtoedge lazega_adv sameoffice, full`, `drop if _ego == _alter` and `tabulate sameoffice, summarize(lazega_adv) means` give the two probabilities, and `restore` brings the nodes back. Turn them into a probability network with `nwgen` as in Section 16.2. For the 20 draws, adapt the loop of Section 16.5. Before running it, tabulate `office` against `practice` and `status`, and ask how a model that knows only the office could still produce sorting on another attribute.


## Chapter 20: QAP regression

**20.a** (applied) The five highest fitted probabilities in the `predict()` example of Section 20.8 are all 0.767. (a) Without running anything: why must they be tied, and how many different fitted probabilities can this model give at most? (b) Rerun the example with `nwtoedge adv_fitted lazega_adv lazega_fr, egovars(office practice status) altervars(office practice status)` and check your count with `codebook adv_fitted, compact`: is the maximum reached? (c) Show with `summarize adv_fitted lazega_adv` that the mean fitted probability equals the density of the advice network, and explain why a logit with a constant must reproduce it exactly. What does this say, and what does it not say, about the top group of 161 dyads, of which only 66% are advice ties? (d) Generate one indicator for each attribute that is 1 when ego and alter agree (for example `generate same_office = office_ego == office_alter`) and collapse the edge list with `collapse (mean) fitted=adv_fitted observed=lazega_adv (count) dyads=lazega_adv, by(lazega_fr same_office same_practice same_status)`. Among the cells with at least 50 dyads, which has the largest gap between fitted and observed share (in absolute value), and which assumption of an additive logit does that gap point to?

*Hint.* (a) Each of the four predictors takes two values, and the fitted log-odds is the constant plus the coefficients of those that equal 1. (c) The likelihood equations of a logit with a constant force the fitted probabilities to add up to the observed number of ties; a total says nothing about how well single cells are fitted. (d) Compare the friendship cells with the same attribute pattern without friendship, and ask whether friendship adds the same log-odds in every row of the table; a cell with fewer than about 50 dyads is too thin to read.

**20.b** (applied) Run the `predict()` example of Section 20.8, then sort the edge list in ascending order (`sort adv_fitted _ego _alter`) and tabulate `lazega_adv` among the dyads that share the lowest fitted probability. How many dyads share it, what probability does the model give them, and what share of them are advice ties? Compare with the top group (161 dyads, 0.767 predicted, 66% ties): is the model better at ruling ties out than at ruling them in?

*Hint.* After sorting, the lowest value is in the first row, so `tabulate lazega_adv if adv_fitted == adv_fitted[1]` works as in the example. The lowest value belongs to dyads with no friendship tie and a different office, practice and status.

**20.c** (applied) A researcher asks whether lawyers who share an office and a practice ask each other for advice more often once friendship is taken into account. Fit `nwqap lazega_adv lazega_fr office practice, permutations(500)` twice, each time after `set seed 12345`, once as it is and once with `qapspp`. Report the coefficients and $p$-values of `same_office` and `same_practice` under both schemes and say which you would report. Then name one way in which advice ties depend on one another that neither model contains.

*Hint.* The coefficients cannot differ between the two runs (Section 20.3); compare the $p$-values. For the last part, see Section 20.10.


## Chapter 21: Exponential random graph models

**21.a** (applied) Rerun `estat gof` after the final advice model with 300 simulated networks instead of the default 100: `estat gof, gof(distance odegree espartners) nsim(300) seed(12345)`. For the rows that were clearly off with 100 draws (distance 2 and 3, out-degrees 33 and 37, 10 and 12 shared partners), report the simulated mean and the MC $p$-value. Does the misfit hold up with more draws?

*Hint.* Compare each row with the listing of Section 21.19. A misfit holds up when the observed value stays outside or at the edge of the simulated range and its $p$-value stays small; the minimum and maximum can widen with more draws.

**21.b** (applied) A researcher asks whether lawyers seek advice from colleagues in their own practice. Compare three tools: the E-I index of practice with its permutation $p$-value (`nwmixing`, Chapter 19), a QAP regression with `same_practice` and friendship (Chapter 20), and the final ERGM with `nodematch(practice)`. For each, say what it holds fixed or controls for, and what it cannot represent. Which would you report as the main result, and why?

*Hint.* Section 20.10 names the dependence between ties that a dyadic model leaves out. Ask of each tool which other predictors are in the same model, and whether a lawyer's request may depend on another advice tie, such as the reverse request or one that closes a triangle.

**21.c** (applied) Refit the step 3 model (with `mutual`, without `gwesp`) with `mcmcinterval(50) mcmcburnin(3000) mcmleeffectivesize(0) seed(12345)`, and again with the interval raised to 1024 and the other options unchanged. After each fit, run `estat mcmcdiag` and report the autocorrelations and the smallest effective sample size. Which of the two fits would you report, and why could the coefficients alone not have told you?

*Hint.* The effective sample sizes are in the matrix `r(ess)`; `mata: min(st_matrix("r(ess)"))` prints the smallest. Compare the convergence messages of the two fits as well.

**21.d** (applied) After the final advice model, run `predict, frame(pr) pr` and list the five dyads with the highest conditional probability of a tie (`frame pr: gsort -p`, then `frame pr: list in 1/5`). Which of them are arcs of the observed network? Explain why these probabilities cannot be read as a test of how well the model predicts arcs that were never observed.

*Hint.* `tail` and `head` are node numbers; `nwvalue lazega_adv, egoid(1) alterid(2)` returns the observed value of that arc in `r(value)`. Then recall what each conditional probability holds fixed.


## Chapter 22: Advanced exponential random graph models

**22.a** (applied) Simulate 100 networks from the final advice model with the gwesp coefficient set to 0.3, between the fitted 0.56 and the 0 of Table 22.1. Use a copy of `b` as in Section 22.2, raise the edges coefficient until the mean density of the draws is near 0.18, and report the edges coefficient you chose and the mean reciprocity, density and transitivity of the draws (`simsummary`). Put the result next to the rows of Table 22.1: how does transitivity change as the gwesp coefficient falls from 0.56 to 0.3 and to 0 at about the same density?

*Hint.* `matrix b2 = b`, then `matrix b2[1, colnumb(b2, "gwesp_.5")] = .3` and the same for `"edges"`. Between $-4.66$ (fitted, gwesp 0.56) and $-3.52$ (gwesp 0), try a value about halfway, near $-4.1$, and adjust it; use `nsim(30)` while searching to save time.

**22.b** (applied) Set ten dyads of Faux Mesa High to missing, those between student 1 and students 2 to 11, as in Section 22.5: after `nwtomata mesa, mat(A)`, type `mata: A[1,2..11] = J(1,10,.)` and `mata: A[2..11,1] = J(10,1,.)`, then build `mesa_na` as in that section. Fit `edges nodematch(grade race) gwesp(.25)` with `seed(12345)` to `mesa` and to `mesa_na`. How many informative dyads does the second fit use, and how much do the four coefficients change compared with the complete network?

*Hint.* `e(N)` and `e(nmissing)` give the counts; the complete network has $205\times 204/2=20{,}910$ dyads. Store both fits and compare their coefficients with `estimates table`.


## Chapter 25: Stochastic actor-oriented models

**25.a** (applied) Refit the two-wave model of the section on building up a model on Glasgow (`wave1(glasgow1) wave2(glasgow2) outdegree reciprocity transtrip nodematch(smoke1) seed(12345)`) with `nodematch(sport1)` in place of `nodematch(smoke1)`. `sport1` records whether a pupil did sport regularly at wave 1. Report the coefficient and $p$-value of `nodematch_sport1` next to those of smoking (0.29, $p=0.16$), and say whether either kind of homophily is distinguishable from zero once reciprocity and transitivity are in the model. Then run `estat gof, nsim(100) seed(1)` on the sport model, and again with `seed(2)`. Does the geodesic distribution fail as clearly as it did for the three-wave model in the section on goodness of fit, and what do the two runs together tell you?

*Hint.* Only the variable in `nodematch()` changes. `tabulate sport1` shows the two groups (37 of the 50 pupils do sport regularly); check the two convergence lines before reading the table. The two `estat gof` runs differ only in the seed, so any difference between them is simulation noise; ask whether it is large enough to change your reading.

**25.b** (basic) The three-wave model with outdegree, reciprocity and transitive triplets in the section on goodness of fit estimates two rates, 6.38 (standard error 1.09) and 5.23 (0.90), but one set of coefficients for both periods. (a) Is the drop in the rate larger than twice its standard error? (b) Suppose pupils reciprocated friendship less in the second year than in the first. What would the pooled model report for reciprocity?

*Hint.* For (a), treat the two rates as approximately independent estimates; the standard error of their difference is then $\sqrt{1.09^2+0.90^2}$. For (b), the pooled model fits one reciprocity coefficient to both periods together.

**25.c** (applied) `nwsaom describe` reports for the two Glasgow periods Jaccard indices of 0.33 and 0.38 and Hamming distances of 115 and 106. Describe wave 1 against wave 3 directly, with `nwsaom describe, waves(glasgow1 glasgow3)`. Report the Jaccard index and the Hamming distance, and explain why the Hamming distance from wave 1 to wave 3 is smaller than $115+106=221$. What does the difference say about comparing only the end points of a panel?

*Hint.* Take a tie that was created between waves 1 and 2 and dissolved between waves 2 and 3. Count how often it enters $115+106$, and how often it enters the comparison of wave 1 with wave 3.


## Chapter 27: Relational event models

**27.a** (basic) For the ten-event toy log of three actors, compute the log likelihood with all coefficients at zero, so that each of the six ordered pairs is equally likely at every event. Compare it with the log likelihood of the fitted model `nwrem chat, nodsnd nidrec` ($-15.90$), and explain why a fitted model can never have a lower log likelihood than this value.

*Hint.* Each event then has probability $1/6$, and there are ten events. For the last part, ask whether setting both coefficients to zero is one of the choices open to the maximum likelihood estimator.

**27.b** (applied) The file `manufacturing_nodes` also holds `level`, the employee's level in the hierarchy. Build a same-level network as the chapter built `samesup`, and fit `nwrem mail, nodsnd nidrec covevent(samelevel)`, then the same model with `rsndsnd` added. Report the `covevent_samelevel` coefficient and $p$-value in both fits. By how much does the level coefficient fall when recency enters, and how does that compare with supervisor (1.46, then 1.01 with recency)?

*Hint.* After the chapter's `merge`, `level` is already in the actor-level data, so `nwexpand level, name(samelevel) network(mail)` builds the network; `nwsummarize samelevel` should show 2,352 edges. Before comparing the two drops, note how many pairs each covariate marks: 29 percent share a level, 4 percent a supervisor.


## Chapter 28: The Dynamic Network Actor Model

**28.a** (basic) In the ten-event toy log of Chapter 27, count how many of the ten calls each of the three actors placed. If every actor were equally likely to be the next sender, how many calls would you expect each to place? Which actor places more than that, and which of the two sub-models would describe the difference?

*Hint.* Enter the log as in Chapter 27 and type `tabulate sender` before the `nwset` line, while the events are still the data in memory. The rate sub-model asks who acts next, the choice sub-model whom the actor calls.

**28.b** (applied) The same-branch effect of the choice sub-model was clearly positive (0.49, $z=10.6$) in a model with `inertia`, `recip` and `indeg`. Build it up in steps: fit `nwdynam mail, indeg same(branch)`, then add `recip`, then `inertia`. Report the `same` coefficient at each step, say which added effect lowers it most, and compare the sequence with what `covevent(samesup)` did in Chapter 27.

*Hint.* The data must be the actor-level data set with `branch` created by `encode`, as in the section on the same branch. `recip` asks whether the candidate has written to the sender before, `inertia` whether the sender has written to the candidate before.


## Chapter 29: A complete network analysis

**29.a** (basic) For the ERGM with friendship (`firm`), convert the coefficients of `mutual`, the office and practice `nodematch` terms and the two status terms into odds ratios, and check them against the values quoted below the output. Write one sentence for each saying which two advice arcs it compares. Then say why the friendship odds ratios of the QAP regression (9.9) and of the ERGM (9.3) are not two confirmations of one effect.

*Hint.* After the model, `display exp(_b[mutual])`, or $e^{\beta}$ by hand from the printed coefficient. Each odds ratio compares two arcs that differ only in that term, with all other terms of the model held fixed. For the last part, ask which data the two models are fitted to.

**29.b** (applied) Seniority is a rank. Refit the seniority model with years in the firm (`yrs_frm`) in place of the rank, in `nodeicov()` and `nodeocov()`, and compare it with `senior` using `estimates table`. Report the two `yrs_frm` coefficients with their $p$-values and the partner receiver effect, and say whether the answer to the fourth expectation changes.

*Hint.* Start from all 71 lawyers, as in Exercise 2 of Chapter 29 in the book. `yrs_frm` runs from 1 to 32 and grows with tenure, so the sign of a seniority effect is reversed relative to the rank. Check convergence and the smallest effective sample size as in the chapter.

**29.c** (applied) Chapter 9 found that the 5-core of reciprocated advice consists of eleven partners. Compute the probability that eleven lawyers drawn at random from the 71, with 36 partners among them, are all partners. Then explain, using the chapter's table of in- and out-degrees by status, why this baseline is too weak for a k-core, and describe a baseline that would hold the lawyers' activity fixed.

*Hint.* `display comb(36,11)/comb(71,11)`. A lawyer can only be in a k-core with at least k reciprocated ties, and partners have more ties of every kind. `nwergm simulate 71, edges directed theta(0) basis(lazega_adv) constraints(degrees) nsim(200)` (Chapter 22) draws networks in which every lawyer keeps his or her in- and out-degree; ask how deep their cores go and how often the innermost core would consist of partners only.


## Chapter 30: Reproducible and responsible network research

**30.a** (basic) In the `nwcug` example of this chapter, `r(p_greater)` is 0.000999 and `r(p_less)` is 1, from 1,000 repetitions. How many of the 1,000 null values were at least as large as the observed reciprocity, and how many at most as large? Show how `r(p)`, 0.001998, follows from the two tails.

*Hint.* With the plus-one correction, a tail $p$-value is (count $+ 1$)/1,001. The two-sided value doubles the smaller tail (Chapter 18).
