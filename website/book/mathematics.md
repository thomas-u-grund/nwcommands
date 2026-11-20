---
title: "Mathematical reference: derivations and details"
parent: "Book companion"
nav_order: 5
description: "Definitions, derivations, option-by-option rules, secondary variants and worked examples behind Appendix E of the book, Mathematical and graph-theoretical reference."
permalink: /book/mathematics/
---

# Mathematical reference: derivations and details
{: .no_toc }

This page goes with Appendix E of the book *Network Analysis with Stata*, "Mathematical and graph-theoretical reference." The printed appendix keeps the definitions and formulas that a reader of the chapters needs, with pointers to the chapters where each idea is introduced. Here every topic is treated in full and in the same order, with the sections numbered as in print (E.1 to E.13): the derivations and algorithmic details, the rules for directed, valued and two-mode networks, the options of each command, error conditions, secondary variants and extended examples. Where a definition differs from that of another program (igraph, UCINET, the R package `sna`), the difference is stated.

The symbol $$\sum_j$$ means "add up the quantity that follows for every node $$j$$." A *path* is a sequence of ties that leads from one node to another, and its *length* is the number of ties it uses. Unless a section says otherwise, a "tie" in a valued network is a non-zero value, and a missing value is not a tie. Chapter numbers are those of the printed book.

<script>
window.MathJax = { tex: { inlineMath: [['\\(', '\\)']], displayMath: [['\\[', '\\]']] } };
</script>
<script async src="https://cdn.jsdelivr.net/npm/mathjax@3.2.2/es5/tex-chtml.js"></script>

{% raw %}
## E.1 Notation, size and density

### Basic notation

A network is $$G = (V, E)$$: a set of nodes $$V$$, $$\vert V\vert  = n$$, and a set of ties $$E$$ connecting pairs
of them (Chapter 2). The adjacency matrix $$A$$ is $$n \times n$$, with $$A_{ij} = 1$$ if a tie runs from $$i$$
to $$j$$ (or connects them, if undirected), 0 otherwise; for a valued network, $$A_{ij}$$ holds the
tie's value directly.

### Valued networks

A network is *valued* when it was created with tie values: a value variable in `nwfromedge`, an import of a file that carries values (a third field on Pajek edge lines, the GML key `value` or `weight`, a matrix with entries other than 0 and 1), `nwset` from a matrix with an entry other than 0 and 1, or `nwset, valued`; it is binary if it was created without tie values or with `unvalued`. The flag is set at creation and is not worked out again from the values: a network of probabilities or shares made with a value variable is valued, and so is one whose values all happen to be 1. Transformations keep the flag of their source, `nwdichotomize` gives a binary network, and a saved network keeps the flag it was saved with (`nwname` with `newvalued(true)` corrects an old file). A measure that has a weighted form in R uses the tie values of a valued network by default and ignores them with the option `binary`; a measure with no weighted form in R is binary by definition and prints the note “(note: tie values are ignored; this measure is binary)”. Tie values are stored in double precision by `nwfromedge`, `nwtoedge`, `nwsave` and `nwexport`, so values such as 623,594.4 or 16,777,217 keep every digit.

### Size and density

Number of possible ties: $$n(n-1)/2$$ (undirected), $$n(n-1)$$ (directed). The undirected count
is smaller because the tie from $$i$$ to $$j$$ is the same tie as the one from $$j$$ to $$i$$.
Density: the number of ties present divided by the number of possible ties (Chapter 6).
`nwsummarize` reports it as `r(density)`, together with the numbers of nodes, of
edges (undirected) or arcs (directed), the smallest and the largest tie value, and, with the option
`detail`, reciprocity, transitivity and the degree centralizations. Three rules decide what
counts. Self-loops are not possible ties (unless the network has them), and cells with a missing value are
removed from the denominator. In a valued network every non-zero value counts as one tie, so
density does not depend on the values (their sum is reported separately as `r(edges_sum)` or
`r(arcs_value)`). In a two-mode network the possible ties are the $$n_1 n_2$$ pairs across the
two modes, so density is the number of ties divided by $$n_1 n_2$$.

### Symmetrization

`nwsym` turns a directed network into an undirected one by combining $$A_{ij}$$ and $$A_{ji}$$ with `mode()`: `max` (default; a tie exists if either direction has one), `min` (only if both do), `sum`, or `mean` $$=(A_{ij}+A_{ji})/2$$; a missing direction counts as 0,
so that in a signed network $$-1$$ against no tie becomes 0 under `max` (Chapter 13). `nwissymmetric` (and `nwsym, check`) tests whether $$A=A^{\top}$$. Commands that say “symmetrized by default” use `max`.

### Dichotomizing and collapsing

`nwdichotomize` turns a valued network into a binary one: a dyad with value $$A_{ij}\ge c$$ (the cutoff) becomes 1 and every other dyad, including a missing one, becomes 0; negative values below the cutoff are treated like any other low value (it is `nwrecode` with one rule). `nwcollapse` merges the nodes that share a value of a grouping variable (`by()`) into one node: the value of the tie from group $$g$$ to group $$h$$ is a summary statistic of the values $$A_{ij}$$ over all dyads with $$i$$ in $$g$$ and $$j$$ in $$h$$, zero cells included; the statistic is any statistic of Stata's `collapse` and the default is the maximum, so by default two groups are tied if any member of one is tied to any member of the other. The result has the directedness of the original network and is flagged valued when its values are not all 0 and 1 (a mean of 0/1 ties is a density between 0 and 1). Ties within a group are dropped: the collapsed network has no self-loops, so its diagonal is empty and a tie between two members of the same group leaves no trace (to count them, collapse the edge list from `nwtoedge` with Stata's `collapse`). Two-mode networks stop with error 6088.

## E.2 Dyads, triads and clustering

### Reciprocity and the dyad census

A *dyad* is a pair of nodes. Every directed dyad $$(i,j)$$, $$i \neq j$$, falls into exactly one of three categories: *mutual*
($$A_{ij}=1$$ and $$A_{ji}=1$$), *asymmetric* (exactly one of the two is 1), or *null* (neither is).
Reciprocity is the proportion of dyads with at least one tie that are mutual:

$$
\text{Reciprocity} = \frac{\text{Mutual}}{\text{Mutual} + \text{Asymmetric}}
$$

(Chapter 6).
`nwdyads` returns the three counts as `r(_100)` (mutual), `r(_010)` (asymmetric) and
`r(_001)` (null) and the ratio above as `r(reciprocity)`. In a valued network any non-zero value is a tie, so
only presence matters. In an undirected network every tie is mutual and the asymmetric count is 0, so the
reciprocity is 1 (or undefined without ties); in a two-mode network the number of
null dyads is $$n_1 n_2$$ minus the ties (163 for the Southern women, $$252-89$$), and the reciprocity is shown as n/a and stored as missing, because a reciprocity of 1 would have no meaning there. This is the *dyadic* reciprocity; the share of arcs that are
reciprocated, $$2\,\text{Mutual}/(\text{number of arcs})$$, is a different number and is not reported.

### The triad census

A *triad* is a set of three nodes, and the census counts how often each possible
pattern of ties among three nodes occurs. Every unordered triple of nodes in a directed network falls into one of sixteen isomorphism
classes, labeled by the MAN scheme: **M**utual, **A**symmetric, and **N**ull dyad
counts within the triple. `030T` means zero mutual, three asymmetric, zero null, forming
a directed transitive path; `300` means all three dyads mutual. Each label is three digits, the numbers of mutual, asymmetric and null dyads, followed
where needed by a letter that separates patterns with the same three digits. `nwtriads` tabulates all sixteen counts at once in the order 003, 012, 021D, 021U, 021C, 030T,
030C, 102, 111D, 111U, 120D, 120U, 120C, 201, 210, 300, with the labels of the R package `sna`, and
returns them as `r(_003)` to `r(_300)`. The counts follow the algorithm of
Batagelj and Mrvar (2001): triads with at least two connected dyads are enumerated from the neighbors of each node, and the empty triads (003) are
obtained by subtraction from $$\binom{n}{3}$$. The counts are integers and sum to $$\binom{n}{3}$$. A tie is a non-zero value, so
valued networks are dichotomized; a missing value is not prorated. In an undirected network only
003, 102, 201 and 300 (no, one, two or three ties) can occur. The census originates with
Holland and Leinhardt (1970). `nwtriads` also returns the transitivity defined under Clustering coefficient and transitivity below as `r(transitivity)`.

### Four-node motifs

`nwmotifs` on a one-mode network (and on a two-mode network with the option `onemode`) classifies every set of four nodes of the (symmetrized, dichotomized) network by its induced subgraph into: *path* (3 ties, degrees 1,2,2,1), *star* (3 ties, 3,1,1,1), *cycle* (4 ties, 2,2,2,2), *paw* (a triangle plus a pendant tie: 4 ties, 3,2,2,1), *diamond* (5 ties), *$$K_4$$* (6 ties) and *disconnected* (everything else); the seven counts sum to $$\binom{n}{4}$$. The number of ties together with the sorted degrees identifies the graph (cf. Milo et al. 2002).

### Clustering coefficient and transitivity

`nwclustering` computes a local coefficient $$T_i$$ for every node, a *global* coefficient and the *average* of the local ones
(Chapter 6). For an undirected, binary network let $$\mathcal{N}_i$$ be the set of $$i$$'s neighbors and $$k_i=\vert \mathcal{N}_i\vert $$:

$$
T_i = \frac{\#\{\{j,h\}\subseteq\mathcal{N}_i : A_{jh}=1\}}{k_i(k_i-1)/2},
$$

$$
T_{\text{global}} = \frac{\sum_i \#\{\text{closed neighbor pairs of } i\}}{\sum_i k_i(k_i-1)/2}
= \frac{3\times(\text{number of triangles})}{\text{number of connected triples}}.
$$

For a *directed* binary network the pairs are two-paths: $$T_i$$ is the share of ordered pairs $$(a,b)$$, $$a\neq b$$, with a tie $$a\to i$$ and a tie $$i\to b$$ that
are closed by a tie $$a\to b$$, and the global coefficient is the sum of the closed pairs over the sum of all such pairs over all nodes. This is the
transitivity of Wasserman and Faust (1994) (the `weak` measure of `gtrans` in the R package `sna`); it is not computed from the triad census.
For a *valued*, undirected network Opsahl and Panzarasa (2009) weight each pair of neighbors $$j,h$$ by a combination $$w_{ijh}$$ of the two tie values at $$i$$ and count a pair as closed if
&#8203;$$j$$ and $$h$$ are tied at all:

$$
T_i = \frac{\sum_{j<h} w_{ijh}\,\mathbb{1}[A_{jh}\neq 0]}{\sum_{j<h} w_{ijh}},\qquad
w_{ijh} = \begin{cases} (A_{ij}+A_{ih})/2 & \texttt{arithmetic}\\ \sqrt{A_{ij}A_{ih}} & \texttt{geometric}\\ \max(A_{ij},A_{ih}) & \texttt{maximum}\\ \min(A_{ij},A_{ih}) & \texttt{minimum}\\ 1 & \texttt{binary,}\end{cases}
$$

selected with `measure()`. The default is `arithmetic` for a valued undirected network (a network counts as valued when it was created with tie values, so shares and probabilities are valued) and `binary` otherwise. A weighted
*and* directed network is refused (error 198); `symmetrize` first symmetrizes by the maximum. A node with fewer than two neighbors has no pair and a missing $$T_i$$,
so the average is taken over the nodes with a defined coefficient only (a path has average 0 and global 0, and its end nodes are missing);
the global coefficient is always the ratio of the two sums. On a two-mode network `nwclustering` uses the two-mode coefficients below by default (the option `onemode` gives the coefficient of the bipartite graph, which is 0).
The factor 3 appears because each triangle contains three connected triples, one centered on each of its nodes.

## E.3 Distance, flow and connectivity

### Distance and reachability

Geodesic distance $$d(i,j)$$: the length of the shortest path connecting $$i$$ and $$j$$ (Chapter 7).
(A geodesic is a shortest path.) `nwgeodesic` counts steps on a binary network; on a valued network the length of a path is the sum of the costs $$A_{ij}^{-a}$$ of its ties (a stronger tie is a shorter step, Opsahl et al. 2010), with $$a=1$$ by default. The option `binary`, or `alpha(0)`, counts steps, and `alpha(-1)` reads the values as lengths, as igraph does. The weighted form runs at any size with the compiled plugin (Appendix A); without a current plugin, a valued network of more than 100 nodes stops with an error unless `force` (the slow Mata computation) or `binary` is given. If $$j$$ cannot be reached from $$i$$ the distance is missing. Of the distance matrix `nwgeodesic` also returns the average path length (mean over the ordered pairs of
nodes in a directed network, over the unordered pairs in an undirected one), the diameter (the largest distance) and the radius (the smallest eccentricity, where the eccentricity of a node is its largest distance);
all three are $$-1$$ if some pair is unconnected, unless `unconnected(`$$c$$`)` replaces the missing distances by a number $$c$$ or by `max`, the largest finite distance plus one.
`nwreach` returns the 0/1 reachability matrix (1 if some path leads from $$i$$ to $$j$$; directed paths unless `sym`); `nwpath` lists the shortest paths between two nodes
and `nwneighbor` the nodes that receive a tie from (default), send a tie to, or are tied either way to a node.

*Farness, nearness and closeness.* `nwcloseness` computes, for every node,

$$
F_i = \sum_{j\neq i} d(i,j),\qquad \text{nearness}_i = \frac{1}{F_i},\qquad C_C(i) = \frac{n-1}{F_i},
$$

the three variables named in `generate()` (Sabidussi 1966) (Chapter 8). A directed network is symmetrized first (by the maximum) unless `nosym` is given,
in which case $$d(i,j)$$ follows the direction of the ties. On a valued network the distances are the weighted distances above (with `binary` they are steps). In a connected network $$C_C$$ lies between 0 and 1 and equals 1 for a node tied to everybody.
If some nodes cannot be reached, `nwcloseness` prints a warning and, as igraph does, defines $$C_C(i)=R_i/F_i$$, where $$R_i$$ is the number of other nodes that $$i$$ can reach, so that closeness stays at most 1; a node in a small component is then compared only with the few nodes it reaches and can score high. Use `unconnected(`$$c$$`)` (for example $$c=n$$, or `max`) to give unreachable pairs a distance and obtain $$(n-1)/F_i$$ over all nodes; the option `legacy` returns $$(n-1)/F_i$$ with the finite distances only, which can exceed 1. An isolate, or a node that reaches nobody, has $$F_i=0$$ and missing nearness and closeness.

### Flow, connectivity and random walks

`nwmaxflow` computes the maximum flow between a source and a sink with the augmenting-path algorithm of Edmonds and Karp (1972); every tie has capacity 1 (so the flow is the number of tie-disjoint paths) unless `weighted` uses the tie values, and the number of ties in a minimum cut is returned. A directed network keeps its directions.
`nwlambda` returns for every pair of nodes the edge connectivity $$\lambda(i,j)$$, the largest number of tie-disjoint paths, i.e. the smallest number of ties whose removal separates them (computed on the symmetrized, dichotomized network). `nwbridges` lists the *global bridges*, ties whose removal disconnects $$i$$ from $$j$$, or the *local bridges*, ties whose removal raises the distance between its ends to more than 2.
`nwrandomwalk` returns the mean hitting time $$h_i$$ to a target $$t$$ of the simple random walk on the symmetrized network, the solution of $$h_t=0$$ and $$h_i = 1 + \frac{1}{k_i}\sum_{j\sim i}h_j$$ for $$i\neq t$$; every node must have at least one tie. On a valued network the walk follows a tie in proportion to its value, $$h_i = 1 + \sum_j (A_{ij}/s_i) h_j$$ with $$s_i$$ the strength (`binary` gives the simple walk). On a two-mode network the command stops with error 6088 unless `onemode` reads the bipartite graph as a one-mode graph.

## E.4 Centrality

### Degree and degree centralization

&#8203;$$k_i = \sum_j A_{ij}$$ (undirected); indegree $$\sum_j A_{ji}$$ (ties received), outdegree $$\sum_j A_{ij}$$ (ties sent). Degree
centrality $$C_D(i) = k_i$$; the option `standardize` of `nwdegree` divides by $$n-1$$, the largest degree possible (Chapter 8).
Freeman's degree centralization, returned as `r(dg_central)` (undirected) or `r(indg_central)` and `r(outdg_central)` (directed), is

$$
\frac{\sum_i\bigl(k_{\max}-k_i\bigr)}{(n-1)(n-2)}\ \text{(undirected)},\qquad
\frac{\sum_i\bigl(k^{\text{in}}_{\max}-k^{\text{in}}_i\bigr)}{(n-1)^2}\ \text{(directed, likewise for outdegree)},
$$

computed from the raw degrees, so that a star has centralization 1 and a regular network 0. On a two-mode network `nwdegree` uses the two-mode degree below by default (the option `onemode` gives the number of ties).

### Generalized degree for valued networks

Following Opsahl et al. (2010), `nwdegree`'s tuning parameter $$\alpha$$ interpolates between
counting ties and summing their values:

$$
C_D^{\alpha}(i) = k_i \left(\frac{s_i}{k_i}\right)^{\alpha},
$$

where $$k_i$$ is $$i$$'s ordinary (binary) degree and $$s_i = \sum_j A_{ij}$$ is $$i$$'s *strength*, the sum of its
tie values. $$\alpha = 0$$ recovers ordinary degree (the $$s_i/k_i$$ term is ignored; it is also what the option `binary` gives); $$\alpha = 1$$, the default on a valued network, recovers
strength exactly, $$k_i \cdot (s_i/k_i) = s_i$$; a value in between weights the two multiplicatively
(Chapters 13 and 7). In words: a node with ten ties of value 1 and a node with two
ties of value 5 have the same strength, 10, but different degrees, 10 and 2; $$\alpha$$ sets how much
the analyst cares about the number of ties compared with their values.

### Betweenness

$$
C_B(i) = \sum_{j<k} \frac{g_{jk}(i)}{g_{jk}} \quad (i\neq j,k),
$$

where $$g_{jk}$$ is the number of shortest paths between $$j$$ and $$k$$, and $$g_{jk}(i)$$ the number of
those passing through $$i$$ (Chapter 8); the sum is computed by the algorithm of Brandes (2001). In a directed network the sum runs over all ordered pairs $$(j,k)$$, so a path from $$j$$ to $$k$$ and one from $$k$$ to $$j$$ both count. By default
`nwbetween` symmetrizes first (it then works with unordered pairs); with `nosym` directions are respected. The option `standardize` divides by the largest value a node can reach, $$(n-1)(n-2)/2$$ for unordered and
&#8203;$$(n-1)(n-2)$$ for ordered pairs (after the default symmetrization an originally directed network is therefore divided by $$(n-1)(n-2)/2$$). On a valued network the shortest paths minimize the sum of $$A_{ij}^{-a}$$
along the path (Opsahl et al. 2010; $$a$$ is `alpha()`, default 1; for $$a=1$$ this is igraph with `weights = 1/w`) and ties with a value of 0 or below are ignored; with `binary` the network is dichotomized. Path lengths are compared with a relative tolerance of $$10^{-10}$$ (as in igraph), so that paths of equal length are counted as tied even when floating-point sums differ in the last digits. (The option `weighted` is accepted and redundant.) A node scores high when many pairs depend on it to connect.
Freeman's betweenness centralization, returned in `r(bw_central)`, is $$\sum_i(\max_k C_B(k)-C_B(i))$$ divided by its maximum, $$(n-1)^2(n-2)/2$$ for the raw scores of an undirected network and $$(n-1)^2(n-2)$$ for the raw scores of a directed network analysed with `nosym`; a star has the value 1.

### Eigenvector centrality

&#8203;$$x_i = \frac{1}{\lambda}\sum_j A_{ij} x_j$$; $$x$$ is the eigenvector of $$A$$ associated with its largest eigenvalue $$\lambda$$
(Chapter 8). `nwevcent` returns $$x$$ scaled to *unit Euclidean length*, $$\sum_i x_i^2=1$$, so that a score is not comparable with programs that scale the maximum to 1 (igraph's default: divide by $$\max_i x_i$$).
For a star on $$n$$ nodes the centre has score $$1/\sqrt2$$. By default a directed network is symmetrized by the maximum (`nosym` prevents this) and a valued network uses the tie values (`binary` dichotomizes it);
the eigenvector is found by power iteration. With `nosym` on a directed network the formula above is used as written: a node is central when the nodes *it sends ties to* are central, which is the transpose of the convention of igraph. In a network that is not connected the score is that of the component with the largest eigenvalue, and the nodes in the other components are
(numerically) 0. In words: a node is central when it is tied to nodes that are themselves central.

### Distance-decay (Katz-family) centrality

`nwkatz`: $$\text{nwkatz}(i) = \sum_{j\neq i} \alpha^{d(i,j)}$$, summed over the nodes $$j\neq i$$ reachable from $$i$$; the default is $$\alpha=1$$, for which the score is the number of nodes reachable from $$i$$.
A directed network is symmetrized first unless `nosym` is given; then two variables are returned, `_out` (distances along ties sent by $$i$$) and `_in` (distances along ties received by $$i$$).
This is a shortest-path-distance measure, distinct from the walk-counting Katz measure (Katz 1953; Bonacich 1972),
which the option `walks` computes:

$$
\text{Katz}_{\text{out}} = (I - \alpha A)^{-1}\mathbf{1},\qquad \text{Katz}_{\text{in}} = (I - \alpha A^{\top})^{-1}\mathbf{1},
$$

with the default $$\alpha = 0.9/\rho(A)$$, where $$\rho(A)$$ is the largest absolute eigenvalue of $$A$$, and an error if $$\vert \alpha\vert \rho(A)\ge1$$ (the walk sum would diverge). The walk version uses the tie values as given, does not symmetrize and counts the walk of length 0, so every score is at least 1 (Chapter 8).
With $$0<\alpha<1$$, near nodes count more than far ones; in the walk version every walk of length $$\ell$$ from $$i$$ counts $$\alpha^\ell$$.

### PageRank

`nwpagerank` returns the stationary distribution of a surfer who follows an outgoing tie, chosen uniformly (on a valued network with probability $$A_{ij}/s_i$$, where $$s_i$$ is the out-strength; `binary` chooses uniformly), with probability $$\delta$$ (option `damping()`, default 0.85) and otherwise jumps to a uniformly chosen node:

$$
r_j = \frac{1-\delta}{n} + \delta\left(\sum_{i:\,A_{ij}\neq0}\frac{r_i}{k^{\text{out}}_i} + \frac{1}{n}\sum_{i:\,k^{\text{out}}_i=0} r_i\right),
$$

so that the scores sum to 1; a node without outgoing ties spreads its score evenly over all nodes. An undirected tie works in both directions (R: `igraph::page_rank` with weights), and the
iteration stops when no score changes by more than `tol()` ($$10^{-10}$$) or after `maxiter()` (1000) sweeps (Brin and Page 1998). In words: a node is important when important nodes point to it, and each node shares its importance
equally among the nodes it points to.

### Induced, endogenous and exogenous centrality

For a centrality measure $$c$$ (`nwinduced` supports `degree`, `betweenness`, `closeness` and `evcent`, undirected degree only) Everett and Borgatti (2010) split the contribution of node $$v$$ into three parts:

$$
\begin{gathered}
\text{endogenous}_v = c_v,\qquad \text{exogenous}_v = \text{induced}_v - \text{endogenous}_v,\\
\text{induced}_v = \sum_{i} c_i(G) - \sum_{i\neq v} c_i(G-v),
\end{gathered}
$$

where $$G-v$$ is the network without node $$v$$ and its ties and $$c_i(G-v)$$ the score recomputed on it (the command writes the three variables with the suffixes `_endog`, `_induced`, `_exog`).
For degree the induced centrality is $$2k_v$$ and the exogenous centrality $$k_v$$, the drop in the centrality of the *others*.

## E.5 Brokerage and structural holes

### Structural holes: effective size, efficiency, constraint and hierarchy

Let $$z_{ij}$$ be the value of the tie from $$i$$ to $$j$$ (1 for a binary tie), $$z_{i+}=\sum_j z_{ij}$$, $$N_i$$ the set of nodes $$j$$ with $$z_{ij}>0$$ and $$p_{ij}=z_{ij}/z_{i+}$$ the proportion of $$i$$'s investment in $$j$$ (Burt 1992). `nwburt` reports for each node $$i$$ (closed form for a binary, undirected network)

$$
\text{effective size}=k_i-\frac{2t_i}{k_i}, \qquad \text{efficiency}=\frac{\text{effective size}}{k_i},
$$

$$
C_i=\sum_{j\in N_i}\Bigl(p_{ij}+\sum_{q\in N_i,\,q\neq j}p_{iq}p_{qj}\Bigr)^2 ,
$$

where $$k_i=\vert N_i\vert $$ and $$t_i$$ is the number of ties among $$i$$'s contacts. Hierarchy is $$H_i=\sum_j \frac{c_{ij}}{C_i/k_i}\ln\frac{c_{ij}}{C_i/k_i}\big/(k_i\ln k_i)$$ with $$c_{ij}$$ the term of $$j$$ in $$C_i$$; the command returns 1 for a node with exactly one contact (where the formula is 0/0) and missing for a node without contacts. For a directed network whose ties are all 1, only the outgoing ties are used (no symmetrization, so $$p_{ij}$$ is the share of $$i$$'s outgoing investment and $$p_{qj}$$ uses $$q$$'s outgoing ties).

For a *valued* network (some tie value other than 0 and 1) `nwburt` computes Burt's weighted measures, as `igraph::constraint` with weights and `networkx.effective_size` and `networkx.constraint` do (the three agree to $$10^{-10}$$ on the test networks). The strength of the relation between $$i$$ and $$j$$ is $$a_{ij}=z_{ij}+z_{ji}$$, so a directed valued network is symmetrized, $$N_i$$ is the set of nodes with $$a_{ij}>0$$, the proportional strength is $$p_{ij}=a_{ij}/\sum_k a_{ik}$$ and the marginal strength is $$m_{jq}=a_{jq}/\max_k a_{jk}$$. Then

$$
\text{effective size}_i=\sum_{j\in N_i}\Bigl(1-\sum_{q\in N_i,\,q\neq j}p_{iq}m_{jq}\Bigr),\qquad
C_i=\sum_{j\in N_i}\Bigl(p_{ij}+\sum_{q\neq i,j}p_{iq}p_{qj}\Bigr)^2,
$$

efficiency is the effective size divided by $$k_i=\vert N_i\vert $$, and hierarchy is as above. With all ties equal to 1 and an undirected network these reduce to the closed form $$k_i-2t_i/k_i$$, which holds for binary ties only. The option `binary` counts every positive value as a tie (outgoing ties for a directed network). A negative or missing tie value stops the command. `nwconstraint` returns the dyadic matrix of the squared terms $$(p_{ij}+\sum_q p_{iq}p_{qj})^2$$, which is also defined for pairs without a tie but with a two-step path, so its row sums are not $$C_i$$; it uses the tie values as given. (Chapter 8.)
In words: constraint is high when $$i$$ puts most of its effort into contacts who are also tied to each other, so that $$i$$ has no one to bridge between, and low when $$i$$'s contacts do not know each other; effective size counts the contacts that are not redundant.

### Brokerage roles

Gould and Fernandez (1989) classify every two-path $$a \to b \to c$$ with $$a \neq c$$ for which $$a$$ has no tie to $$c$$, by the groups of the three nodes; the node $$b$$ in the middle plays the role of: *coordinator* if all three are in one group; *gatekeeper* if $$a$$ is outside the group of $$b$$ and $$c$$; *representative* if $$a$$ and $$b$$ share a group and $$c$$ is outside; *consultant* (itinerant broker) if $$a$$ and $$c$$ share a group and $$b$$ is outside; *liaison* if all three groups differ. `nwbrokerage` stores for each node $$b$$ the number of two-paths in each role in five variables, `generate()“_coordinator` and so on; these are raw counts without normalization. In an undirected network each two-path is counted once for each direction, so each counts twice. Tie values are ignored (Chapter 8).

## E.6 Cohesive subgroups and communities

### Cohesive subgroups

All commands in this section work on the undirected, unvalued view of the network: a tie counts if it is present in either direction, and tie values and signs are ignored.
A *clique* is a maximal subset of nodes, every pair of which is tied (`nwclique`; subsets with fewer than `minsize()`, default 3, members are not reported).
A *$$k$$-plex* relaxes this by degree (Seidman and Foster 1978): a subset $$S$$ with $$m=\vert S\vert $$ members in which every member is tied to at least $$m-k$$ of the other $$m-1$$ members, so that each member may lack at most $$k-1$$ ties to the others; a $$1$$-plex is a clique (`nwkplex`, option `k()`, default 2, `minsize()` default $$k+1$$).
An *$$n$$-clique* (Luce 1950) relaxes distance: a maximal subset in which every pair is at geodesic distance at most $$n$$ in the whole network, so that connecting paths may run through nodes outside the subset (`nwnclique`, `n()` default 2). An *$$n$$-clan* is an $$n$$-clique whose members are also within distance $$n$$ of each other inside the subset itself, that is, whose induced subnetwork has diameter at most $$n$$ (`nwnclan`). Clans are the maximal $$n$$-cliques that pass this test; an $$n$$-clique that fails it is not replaced by a smaller clan.
The *coreness* of a node is the largest $$k$$ such that it belongs to a subset in which every member has degree at least $$k$$ inside the subset (Seidman 1983); it is found by repeatedly removing the node of smallest remaining degree (`nwkcore`). For directed networks a node's neighbors are its in- and out-neighbors together.
A *component* is a maximal set of nodes connected by paths that ignore tie direction (weak components; `nwcomponents`, option `lgc` keeps the largest).
A *$$k$$-component* is a maximal subset whose members cannot be disconnected by removing fewer than $$k$$ nodes, that is, whose vertex connectivity is at least $$k$$ (`nwkcomponents`, `k()` default 2). `nwcohesion` reports the nested hierarchy of such blocks together with the connectivity level of each (Moody and White 2003).
A *Simmelian tie* (Krackhardt 1999) is, as implemented in `nwsimmelian`, a mutual tie $$i \leftrightarrow j$$ for which some third node $$k$$ is mutually tied to both; the result is a new binary network, and tie strength plays no role.
(“Maximal” means that no further node can be added without breaking the rule.) (Chapter 9).

### Community detection and modularity

A *partition* divides the nodes into groups so that each node belongs to exactly one group. Community detection is defined here for undirected networks: a directed network is accepted only with option `symmetrize`, which keeps the larger of the two directed values for each pair (a tie in either direction for a binary network). With total weight $$m=\tfrac12\sum_{ij}A_{ij}$$ and strengths $$k_i=\sum_j A_{ij}$$ (self-ties ignored), modularity with resolution $$\gamma$$ is

$$
Q = \frac{1}{2m}\sum_{i,j}\Bigl(A_{ij}-\gamma\frac{k_ik_j}{2m}\Bigr)\delta(c_i,c_j) ,
$$

(Newman 2006; Reichardt and Bornholdt 2006); $$\gamma=1$$ is the default (`resolution()`), larger values favor smaller communities. $$A_{ij}$$ are tie values for a valued network (`measure(valued)`, the default when the network is valued) and 0/1 otherwise (`measure(binary)`). On a two-mode network both commands use Barber's bipartite modularity, $$Q_B=\frac1m\sum_C\bigl(e_C-K^{(1)}_CK^{(2)}_C/m\bigr)$$, where $$m$$ is the number of ties, $$e_C$$ the number of ties inside community $$C$$ and $$K^{(1)}_C$$, $$K^{(2)}_C$$ the sums of the degrees of its mode-1 and mode-2 nodes; the null model has only cross-mode pairs. The option `onemode` gives the modularity above for the bipartite graph read as a one-mode graph (`r(modularity_type)` says which one was computed). The search is a Louvain-type search in Mata that starts from several node orders (`starts()`, default 30) and keeps the best partition (R: `bipartite::computeModules`). `nwcommunity` searches for a partition with the Louvain algorithm (Blondel et al. 2008): nodes are visited in the fixed order $$1,\dots,n$$ and moved to the neighboring community with the largest gain in $$Q$$, communities are then collapsed into single nodes, and the two steps are repeated until nothing moves. Option `algorithm(labelprop)` uses label propagation (Raghavan et al. 2007) instead, which does not optimize $$Q$$ and breaks ties at random. `nwcommunity` stores $$Q$$ of the partition it found; `nwmodularity` evaluates $$Q$$ for a partition given in a variable (`group()`) (Chapter 9). The term $$k_ik_j/2m$$ is the number of ties expected between $$i$$ and $$j$$ if ties were placed at random but each node kept its degree; values of $$Q$$ near 0 mean no more within-group ties than chance.

### Graph Laplacian

On a two-mode network `nwspectral` stops with error 6088; the option `onemode` gives the spectrum of the bipartite graph read as a one-mode graph. For the undirected (symmetrized, optionally valued) network with self-ties removed, `nwspectral` forms $$L = D - W$$, where $$W$$ holds the tie values and $$D$$ is diagonal with the strengths $$k_i$$. The number of zero eigenvalues of $$L$$ equals the number of components; the second-smallest eigenvalue is the algebraic connectivity, and with option `bipartition` the sign of the corresponding eigenvector splits the nodes in two groups.

## E.7 Positions

### Similarity and dissimilarity of nodes

Let $$a_i$$ be the vector of $$i$$'s outgoing ties and $$a^{\mathrm{in}}_i$$ of its incoming ties. For a pair $$(i,j)$$ the commands compare the vectors with the positions $$i$$ and $$j$$ left out ($$k\neq i,j$$, $$n-2$$ positions per direction). `context(outgoing)` or `(incoming)` uses one direction, `context(both)` (default) both together. `nwdissimilar` offers: `euclidean` (default) $$\sqrt{\sum_k(a_{ik}-a_{jk})^2+\sum_k(a_{ki}-a_{kj})^2}$$ on the raw values; `manhatten` (sic) the sum of absolute differences; `hamming` the number of positions where the binarized ties differ; `nonmatches` that number divided by $$n-2$$ per direction; `jaccard` one minus the number of shared ties divided by the number of distinct ties. For binary networks Manhattan and Hamming coincide and Euclidean is the square root of Hamming. `nwsimilar` offers `pearson` (default; correlation of the two stacked vectors, with a fallback value in $$[-1,1]$$ when a vector has no variance), `matches` (share of agreeing positions, $$1-$$`nonmatches`), `hamming` (number of agreeing positions out of $$2n$$, the two left-out positions counting as agreements), `jaccard` and `crossproduct` (on a binary network the number of shared ties; on a valued network $$\sum_k w_{ik}w_{jk}$$ over the outgoing ties, $$\sum_k w_{ki}w_{kj}$$ over the incoming ones, and the sum of both for `context(both)`). `nwhierarchy` clusters these dissimilarities with Stata's `clustermat` (linkage default `singlelinkage`) and cuts the tree at `groups()`; `nwconcor` (Breiger et al. 1975) correlates the stacked profile vectors, correlates the resulting matrix with itself until it contains only $$\pm1$$ (at most `maxiter()`, default 25 times) and splits into two blocks by sign, repeated `splits()` times to give $$2^{\text{splits}}$$ blocks (Chapter 10). With `context(both)` the union in the denominator of the Jaccard measure pools the out- and in-neighbours of both nodes, positions $$i$$ and $$j$$ left out.
`nwsimindex` compares neighbor sets $$N(i)$$ (in- and out-neighbors together) by `common` $$\vert N(i)\cap N(j)\vert $$, `jaccard` $$\vert N(i)\cap N(j)\vert /\vert N(i)\cup N(j)\vert $$, `dice` $$2\vert N(i)\cap N(j)\vert /(k_i+k_j)$$, `cosine` $$\vert N(i)\cap N(j)\vert /\sqrt{k_ik_j}$$ and `adamicadar` $$\sum_{h\in N(i)\cap N(j)}1/\ln k_h$$ (Adamic and Adar 2003), the sum running over common neighbors with $$k_h\ge2$$. `nwshared` writes, for every existing tie $$\{i,j\}$$, the number of common neighbors; pairs without a tie get 0. On a directed network the option `undirected` is required (the network is symmetrized first); without it the command stops with error 198.

### Regular equivalence

Two nodes are regularly equivalent when, for every class, either both send a tie to some member of that class or neither does, and the same for the ties they receive (White and Reitz 1983). `nwregular` finds the maximal regular equivalence of the binary network (tie values and self-ties ignored) by refinement, as CATREGE does for binary data (Borgatti and Everett 1993): it starts with all nodes in one class and, in each round, gives every node the signature (its class, the set of classes it sends ties to, the set of classes it receives ties from); nodes with different signatures are put into different classes. The rounds stop when no class splits. The result is the coarsest partition in which every pair of classes $$(r,s)$$ forms a regular block: either no tie runs from $$r$$ to $$s$$, or every member of $$r$$ sends a tie to some member of $$s$$ and every member of $$s$$ receives one from some member of $$r$$. The image matrix `r(image)` has a 1 for every pair of classes joined by a regular block (Chapter 10).

### Core-periphery and factions

Both operate on the symmetrized network (values optional through `measure(valued)`) and fit an ideal block pattern by the Pearson correlation between the observed ties and the pattern over all ordered pairs $$i\neq j$$. `nwcoreperiphery` (Borgatti and Everett 2000) uses the pattern “tie expected if at least one of $$i,j$$ is in the core”; it starts from the nodes with above-average degree as core and flips single nodes while the fitness rises (at most `maxiter()`, default 100 sweeps), so the result is a local optimum. `nwfactions` takes the number of groups $$K$$ (`groups()`, default 2) and the pattern “tie expected if $$i$$ and $$j$$ are in the same group”; it starts by dealing nodes to groups in order of degree and moves single nodes to the group that raises the fitness most.

## E.8 Ego networks

### Ego networks and alter statistics

`nwego` reports, for every node $$i$$, the size $$\vert \mathcal{A}_i\vert $$ of its ego network, where $$\mathcal{A}_i$$ are all nodes tied to $$i$$ in either direction (the union of receivers and senders), and the density among the alters, excluding $$i$$:

$$
\text{density}_i = \frac{\#\{(a,b)\in\mathcal{A}_i^2: a\neq b, A_{ab}\neq0\}}{\vert \mathcal{A}_i\vert (\vert \mathcal{A}_i\vert -1)}\ \text{(directed)},
$$

$$
\text{density}_i = \frac{\#\{\{a,b\}\subseteq\mathcal{A}_i: A_{ab}\neq0\}}{\vert \mathcal{A}_i\vert (\vert \mathcal{A}_i\vert -1)/2}\ \text{(undirected)};
$$

it is missing for fewer than two alters, and tie values are ignored (Chapter 11). `nwaltergen` computes a statistic of a node variable $$z$$ over the alters of $$i$$ (for a directed network the nodes $$i$$ sends ties to; with `hop(`$$h$$`)` the nodes at geodesic distance exactly $$h$$), ignoring missing values:
mean, `wmean` (mean weighted by the tie values), sum (0 without alters), min, max, `sd` (with divisor $$m-1$$, $$m$$ the number of alters with a value), count, `diversity` (Blau's index $$1-\sum_k p_k^2$$, with $$p_k$$ the share of alters with value $$k$$) and `proportion` (share of alters whose value equals a given value);
the result is missing without alters, except for sum and count.

## E.9 Two-mode networks

### Two-mode networks: density, degree, clustering, projection

For a two-mode network with $$n_1$$ nodes in mode 1 and $$n_2$$ in mode 2, the number of
possible ties is $$n_1 \times n_2$$ (only cross-mode pairs are structurally possible), so density
is the number of ties divided by $$n_1 n_2$$, not $$\binom{n_1+n_2}{2}$$. `nwdegree` on a two-mode network (`nw2degree` is the older name) divides the degree of a mode-1 node $$i$$
by the size of the *opposite* mode, $$k_i/n_2$$ (Borgatti and Everett 1997), so that it stays interpretable as a
proportion regardless of how the two mode sizes compare (Chapter 12); a mode-2 node is normalized by $$n_1$$. With `alpha(`$$a$$`)` on a valued network the numerator is $$k_i(s_i/k_i)^a$$ as in the generalized degree above.

`nwclustering` on a two-mode network (`nw2clustering` is the older name) measures closure with four-paths, because a triangle cannot exist when ties only run between the modes (Opsahl 2013; Robins and Alexander 2004). For a node $$c$$ of the chosen mode (`level(1|2)`) a four-path is $$e_0 - a_0 - c - a_1 - e_2$$ with
&#8203;$$a_0\neq a_1$$ in the other mode and $$e_0\neq e_2$$ in the mode of $$c$$, both different from $$c$$; it is *closed* if a further node $$a_2\notin\{a_0,a_1\}$$ is tied to both $$e_0$$ and $$e_2$$ (a six-cycle):

$$
T_c = \frac{\sum_{\text{four-paths at } c} m\cdot\mathbb{1}[\text{closed}]}{\sum_{\text{four-paths at } c} m},
$$

with $$m=1$$ for `binary` and the arithmetic, geometric, maximum or minimum of the four tie values for the weighted measures (default `arithmetic` if the network is valued). The global coefficient is the ratio of the two sums over all nodes of the level, the average is taken over nodes with at least one four-path. Four-cycles do not count as closure. This is the coefficient of Opsahl (the default; R: `tnet::clustering_tm`). The option `ra` reports instead the global coefficient of Robins and Alexander, $$4\,C_4/L_3$$, where $$C_4$$ is the number of four-cycles and $$L_3$$ the number of paths with three ties; the two answer different questions and have different values (Southern women: .772 for Opsahl, .468 for Robins and Alexander).

`nw2project` (`nwproject`) projects onto one mode (`project(1|2)`). Two nodes of that mode are tied if they have a common neighbor in the other mode; the value is chosen with `stat()`. For a binary network the default is `count`, the number of common neighbors. For a valued network the tie values $$(u_h,v_h)$$ of the two nodes
to each common neighbor $$h$$ are combined: `min` or `max` (over all these values), `sum` or `mean` (over all of them; the mean divides by twice the number of common neighbors), or `minmax` (default): $$\max_h\min(u_h,v_h)$$, the strongest shared bond. Independent of the values, `count`, `binary` (1 if any common neighbor),
`jaccard` $$= \vert N_u\cap N_v\vert /\vert N_u\cup N_v\vert $$ and `cosine` $$=\vert N_u\cap N_v\vert /\sqrt{\vert N_u\vert \vert N_v\vert }$$ score the neighbor sets $$N_u,N_v$$. With `stat(newman)` the weight of a pair is Newman's collaboration weight, the sum over the common neighbors $$h$$ of $$1/(k_h-1)$$ (R: `tnet::projecting_tm` with method `Newman`).

*Further two-mode measures.* `nwdegree` with `raw` returns the count of ties instead of the division by the other mode (R: `tnet::degree_tm`). `nw2nested` reports the nestedness measure NODF of Almeida-Neto and others (equal to `vegan::nestednodf` with ordered rows and columns) and the C-score of Stone and Roberts, in a normalized form (`bipartite::C.score`). `nwcloseness` and `nwbetween` on a two-mode network use the normalizations of Borgatti and Everett (1997) by default (`twomode` is a synonym, and `onemode` gives the unnormalized numbers of the bipartite graph): closeness is the smallest possible farness divided by the farness, and betweenness is divided by the largest value possible for the mode. `nwsimilar` and `nwdissimilar` compare a node with the other nodes of its own mode over the nodes of the other mode; pairs from different modes are missing. Commands that would read the empty blocks between nodes of the same mode stop with error 6088 (Appendix C).

*Bipartite motifs and node positions.* On a two-mode network `nwmotifs` (alias `nw2motifs`) counts the motifs of Simmons et al. (2019). Let $$B$$ be the $$n_1\times n_2$$ incidence matrix of the ties above zero (rows are the nodes of mode 1). An *occurrence* of a motif is a set of $$r$$ nodes of mode 1 and $$c$$ nodes of mode 2 whose induced subgraph (all ties between them, and no others) is connected and has the shape of the motif; it is counted once, whatever the number of ways of reading it. There are 17 motifs with two to five nodes and 27 more with six nodes (option `sixnode`), 44 in all. A motif has *positions*, the classes of its nodes that are exchangeable by a relabelling that keeps the ties (the end of a path, the middle of a path, …); there are 46 positions for the motifs up to five nodes and 148 up to six. The frequency $$F_m$$ of motif $$m$$ is the number of its occurrences, and the position count $$N_{ip}$$ of node $$i$$ is the number of occurrences of the motif of position $$p$$ in which $$i$$ holds $$p$$. Two identities fix the meaning: the sum of $$N_{ip}$$ over all nodes equals $$F_m$$ times the number of nodes that the motif has in position $$p$$, and the counts of a node that is in no occurrence are zero. Examples (the numbering is that of `bmotif`, not derived from a rule): motif 1 is a single tie, with position 1 for the node of mode 2 and position 2 for the node of mode 1, so that $$N_{i,2}=k_i$$ is the degree of a node of mode 1; motif 2 is a node of mode 1 with two neighbors, so that the middle node has $$N_{i,4}=\binom{k_i}{2}$$; and motif 6 is the four-cycle, $$F_6=\sum_{i<j}\binom{\vert N_i\cap N_j\vert }{2}$$ over the pairs of nodes of mode 1 with common neighbors $$N_i\cap N_j$$, which is the count $$C_4$$ of the Robins–Alexander coefficient above. With the option `onemode`, `nwmotifs` gives instead the seven counts of four nodes of the bipartite graph read as a one-mode graph (see Four-node motifs in Section E.2).

### Matching

`nwmatching` finds a set of pairs of mode-1 and mode-2 nodes, tied to each other, in which no node occurs twice. On a binary network, or with `binary`, the set is of maximum cardinality; on a valued network it is the set of largest total tie value (the Hungarian method), stored in `r(weight)`, and it can contain fewer pairs. Example: with ties of value 1, 5 and 1 for p1–g1, p1–g2 and p2–g2, the valued matching is the single pair p1–g2 of value 5, and the matching with `binary` has two pairs. It stores for each mode-1 node the id of its partner (0 if unmatched).

## E.10 Mixing by attributes

### Assortativity

`nwassortativity` computes the Pearson correlation, over all ordered pairs $$(i,j)$$ of tied nodes, between the attribute $$x_i$$ of one end and $$x_j$$ of the other (Newman 2002): every tie contributes both $$(x_i,x_j)$$ and $$(x_j,x_i)$$, so the result does not depend on the order of the ends. The attribute is a numeric variable (`attribute()`); without it the node's degree is used on a binary network (the number of distinct neighbors, in or out) and its strength, the sum of the tie values, on a valued network (`binary` gives the degree). Directed networks are treated as undirected for this purpose. On a binary network, or with `binary`, each tie counts once; on a valued network each pair is weighted by the tie value (Leung and Chau 2007), with $$r_w=\sum_{ij}w_{ij}(x_i-\bar x)(x_j-\bar y)/\sqrt{\cdot}$$ and weighted means and variances. A coefficient of $$+1$$ means ties join equal values, $$-1$$ opposite values (Chapter 6).

### E-I index and mixing table

$$
\text{E-I} = \frac{E - I}{E + I},
$$

In the notation of the index, $$E$$ is the number of ties running between categories of a grouping variable and $$I$$ the number running within; the index runs from $$-1$$ (all ties stay inside the groups) to $$+1$$ (all ties cross between groups) (Chapter 6). `nwmixing` cross-tabulates the attribute value of the sender against that of the receiver over all present ties (value 0 means no tie), prints the table, and computes $$\text{E-I}=(E-I)/(E+I)$$ with $$I$$ the sum of the diagonal and $$E$$ the rest (Krackhardt and Stern 1988). In an undirected network each tie appears twice in the table; the index is unaffected. The $$p$$-value (option `permutations()`, default 100) permutes the attribute over the nodes and uses the two-sided rule of the section on permutation and conditional uniform graph $$p$$-values (E.12); self-ties are excluded from the permutation reference but not from the table.

## E.11 Signed networks and change over time

### Structural balance

A triad is *closed* if all three pairs are tied in either direction; only closed triads are counted. Its signs are those of the ties (for a pair tied in both directions the tie from the lower-numbered to the higher-numbered node is used; magnitudes are ignored). It is *balanced* if the product of the three signs is positive: three positive ties, or one positive and two negative (Cartwright and Harary 1956). `nwbalance` stores per node the number of closed triads and of balanced closed triads containing it, and their ratio (`r(balance)`: balanced over closed triads) (Chapter 13). With `reps(`$$R$$`)` the share of balanced triads is compared with random signs on the same ties: with $$p$$ the share of tied pairs whose sign is positive, each of the $$R$$ draws gives every tied pair the sign $$+1$$ with probability $$p$$ and $$-1$$ otherwise, independently, and counts the balanced closed triads. Under this model a closed triad is balanced with probability $$\frac12\{1+(2p-1)^3\}$$ (`r(null_expected)`); the command reports the mean and standard deviation of the share over the draws and the number of draws whose share is at least the observed one.

### Network turnover

Between two waves of the same relation, every possible tie is stable (present both times),
formed (absent then present), or dissolved (present then absent). The Jaccard index
summarizes overall turnover as the proportion of ties present in *either* wave that were
present in *both*:

$$
\text{Jaccard} = \frac{\text{Stable}}{\text{Stable} + \text{Formed} + \text{Dissolved}}
$$

(Chapter 14).

With stable, formed and dissolved ties as above, `nwturnover` also returns the persistence $$\text{Stable}/(\text{Stable}+\text{Dissolved})$$, the share of the ties of the first wave that survive. Only presence is compared (a value or sign other than zero counts as a tie); both networks need the same nodes and the same directedness. For each node the variable `generate()` holds the node's own $$\text{Stable}/(\text{Stable}+\text{Formed}+\text{Dissolved})$$ over its ties. In an undirected network each tie is counted once in the totals.

## E.12 Generators, simulation and tests

### Structured generators

A *generator* is a rule that produces a network by a random or fixed procedure (Chapters 15 and 16). In all generators, `undirected` makes the network undirected (the default is directed), `selfloop` (`nwrandom` only) allows ties from a node to itself, and `weights()` gives the ties random values (see below). Wherever a count of ties is stated, it is exact.

*Random networks* (`nwrandom`). With `prob(`$$p$$`)` every possible tie, each ordered pair in a directed network and each unordered pair in an undirected one, is present independently with probability $$p$$, the random graph of Erdős and Rényi (1959) in the form with a fixed probability; the number of ties varies from network to network and its expected density is $$p$$. With `density(`$$d$$`)` the number of ties is fixed: $$M=\lfloor n(n-1)d\rfloor$$ arcs placed uniformly at random among the $$n(n-1)$$ ordered pairs in a directed network, and $$\lfloor M/2\rfloor$$ edges among the $$n(n-1)/2$$ unordered pairs in an undirected one (for $$n=20$$ and $$d=0.3$$: 114 arcs, or 57 edges). With `census(`$$m$$ $$a$$`)` (directed networks) exactly $$m$$ randomly chosen pairs of nodes are mutual, $$a$$ further pairs carry one tie in a randomly chosen direction, and all other pairs are null, which fixes the dyad census (see Reciprocity and the dyad census in Section E.2). `weights(`$$p_1,\dots,p_K$$`)` is a vector of probabilities: each tie that exists gets the integer value $$k$$ with probability $$p_k$$ (the vector must sum to 1). The conditional uniform graph test uses `density` and `census` draws (see the next subsection).

*Ring lattice* (`nwring`, `k(`$$k$$`)`). The $$n$$ nodes are placed on a circle and each node is tied to its $$k$$ nearest nodes on either side, $$i\pm1,\dots,i\pm k$$ (modulo $$n$$), so that every node has degree $$2k$$ (for $$n>2k$$). `nwlattice` instead lays the nodes on a grid with the given number of columns and rows and ties each node to its (up to four) horizontal and vertical neighbors; `xwrap` and `ywrap` join the opposite edges, which gives a torus on which every node has degree 4.

*Small-world networks* (`nwsmall`). The Watts-Strogatz model (Watts and Strogatz 1998) starts from the ring lattice with $$k$$ neighbors on either side. With `prob(`$$p$$`)` every lattice tie is, independently with probability $$p$$, detached from its second end and reattached from the same first end to a node chosen uniformly among the nodes that are *not within distance $$k$$ on the ring* of the first end and not yet tied to it; in a directed network each of the $$2k$$ outgoing lattice ties of a node is treated in this way, in an undirected one each of the $$nk$$ ties once. With `shortcuts(`$$s$$`)` exactly $$s$$ distinct lattice ties are rewired in the same way. Either way the number of ties stays that of the lattice, and a rewired tie always leaves the lattice band; so $$p=0$$ returns the ring lattice, but $$p=1$$ does *not* give a random graph of the same density: it gives a network with no tie inside the band (for $$n=20$$, $$k=2$$ and $$p=1$$ all 40 ties lie outside it), unlike the original model, where the new end is chosen among all nodes.

*Preferential attachment* (`nwpref`; Barabási and Albert 1999). The first $$m_0$$ nodes (`m0()`, default 2) form a complete network. Every further node, in the order of its number, creates ties to $$\min(m,m_0)$$ distinct earlier nodes (`m()`, default 2; a value of $$m$$ larger than $$m_0$$ is cut back to $$m_0$$: with $$n=30$$ and $$m_0=3$$ the option $$m=5$$ gives $$3+27\cdot3=84$$ edges). The probability of choosing an earlier node is proportional to its current degree (in an undirected network) or to the number of ties it has received (in a directed one, where the new node sends the ties); the starting complete network counts a self-tie for each of its nodes in these weights, which is removed from the final network. With `prob(`$$q$$`)` a new node chooses its targets, with probability $$q$$ (one draw per new node), uniformly among the earlier nodes instead.

*Networks from tie probabilities* (`nwdyadprob`). `mat()` gives a matrix of probabilities $$P_{ij}$$ and every tie $$(i,j)$$, $$i\neq j$$, is present independently with probability $$P_{ij}$$ (for an undirected network the lower triangle is used). If `nwdyadprob` is given a network of weights instead of a probability matrix, values outside the unit interval are first transformed by the inverse logit. With `density(`$$d$$`)` the matrix is read as relative weights $$w_{ij}$$ and exactly $$M=n(n-1)d$$ ties (halved for undirected networks, which use the pairs $$i<j$$) are drawn without replacement with fixed-size probability-proportional-to-weight sampling: the probability that the pair $$ij$$ is among the ties is

$$
\Pr(ij\text{ is a tie}) = M\,\frac{w_{ij}}{\sum_{kl} w_{kl}},
$$

the sum running over all possible pairs, and the command stops with an error if this exceeds 1 for some pair.
`nwhomophily` chooses $$w_{ij}=\exp\bigl(\sum_v h_v\,e^{v}_{ij}\bigr)$$ for the attributes $$v$$ in its variable list, where $$h_v$$ is the coefficient given in `homophily()` and $$e^v_{ij}$$ the dyadic expansion of the attribute set by `mode()` (`nwexpand`; default `same`, $$e^v_{ij}=1$$ if $$i$$ and $$j$$ have the same value and 0 otherwise). So a pair with $$e_{ij}=1$$ is $$e^{h}$$ times as likely to be a tie as a pair with $$e_{ij}=0$$ in the sense of the ratio of tie probabilities; this equals the odds ratio only when the network is sparse, because the probabilities are scaled to fix the number of ties.

The `mode()` expansions of `nwexpand` for a numeric variable $$z$$ are, for the pair $$(i,j)$$: `same` $$\mathbb 1[z_i=z_j]$$; `sender` $$z_i$$; `receiver` $$z_j$$; `dist` $$z_i-z_j$$; `distinv` $$z_j-z_i$$; `absdist` $$\vert z_i-z_j\vert $$; `absdistinv` $$\max_{kl}\vert z_k-z_l\vert -\vert z_i-z_j\vert $$ (a bounded measure of closeness, not a reciprocal). `weights()` in the ring, small-world and preferential generators is the same vector of probabilities as in `nwrandom`.

### Connections model utility

In the connections model of Jackson and Wolinsky (1996) node $$i$$ receives the benefit $$b^{d(i,j)}$$ from each other node $$j$$ at geodesic distance $$d(i,j)$$ and pays the cost $$c$$ for each of its direct ties: $$U_i=\sum_{j\ne i}b^{d(i,j)}-c\,k_i$$. `nwutility` stores benefit, cost and utility in `_benefit`, `_cost`, `_util`; unreachable nodes contribute nothing; $$0\le b\le1$$ (`benefit()`, default 1) and `cost()` (default 1). 

### Permutation, correlation and conditional uniform graph $$p$$-values

*Node-label permutation* (`nwpermute`, used by `nwcorrelate`, `nwqap` and `nwmixing`). A permutation $$\pi$$ of the nodes is drawn uniformly among all $$n!$$ orderings and the network $$A'$$ with $$A'_{ij}=A_{\pi(i)\pi(j)}$$ is formed: rows and columns are reordered together, so the number of ties, the dyad census and the degree distribution are unchanged and only the assignment of nodes to positions is randomized. For a two-mode network the permutation is drawn within each mode, so no tie ever falls inside a mode; with the option `swap` the ties themselves are rewired by exchanging the partners of two ties, which keeps both degree sequences (the null model of `bipartite::swap.web`).

*Correlation of two networks* (`nwcorrelate`). The statistic is the Pearson correlation between the tie values $$A_{ij}$$ and $$B_{ij}$$ of two networks over all ordered pairs $$i\neq j$$ (the diagonal is left out); an attribute $$z$$ is first expanded into a network by `nwexpand` (`mode()`, default `same`). This is the quantity of Hubert and Schultz (1976). With `permutations(`$$R$$`)`, $$R>1$$, the first network's nodes are permuted $$R$$ times and the correlation recomputed; the reported $$p$$-value is *two-sided*, twice the smaller tail, with the observed correlation $$r$$ counted as one more draw of the null:

$$
p = \min\Bigl(1,\ \frac{2\,\bigl(1+\min(\#\{r_s \ge r\},\ \#\{r_s \le r\})\bigr)}{R+1}\Bigr),
$$

with permuted correlations equal to $$r$$ counted, so that $$p$$ is never 0 and its smallest value is $$2/(R+1)$$ (Phipson and Smyth 2010); `r(lb)` and `r(ub)` are the 2.5th and 97.5th percentiles of the $$R$$ permuted values.
Called with one network, `nwcorrelate` correlates the *nodes*: for every pair $$i\neq j$$ the Pearson correlation between the two nodes' tie vectors over the $$n-2$$ other nodes $$k\neq i,j$$, using the ties sent (`context(outgoing)`, default), received (`incoming`), or the sent and the received ties stacked in one vector of length $$2(n-2)$$ (`both`); it reports the mean of these correlations as `r(avg_corr)`. Where one of the two vectors is constant the correlation is undefined, and the command substitutes a value computed from the totals $$S_i,S_j$$ of the two vectors: $$\min(S_i,S_j)/\max(S_i,S_j)$$ if both are positive, $$-1$$ if exactly one is 0 and $$+1$$ if both are 0.

*Conditional uniform graph test* (`nwcug`). The observed statistic $$T_{\text{obs}}$$ (any `r()` result of a command given in `stat()`) is compared with $$R$$ values $$T_1,\dots,T_R$$ (`reps()`, default 1000) computed on independently generated random networks with the same nodes that share one feature of the observed network: `condition(density)` (default), the number of ties (the networks of `nwrandom, density()`), or `condition(census)`, the numbers of mutual and of asymmetric dyads (directed networks only). The command returns the upper and lower one-sided proportions $$p_{\ge}=(1+\#\{T_r\ge T_{\text{obs}}\})/(R+1)$$ and $$p_{\le}=(1+\#\{T_r\le T_{\text{obs}}\})/(R+1)$$, in which the observed value counts as one more draw, the null mean and standard deviation, and the two-sided $$p$$-value

$$
p = \min\bigl(1,\ 2\min(p_{\ge},p_{\le})\bigr).
$$

The same two-sided rule, $$p=\min\bigl(1,\ 2(1+\min(\#\{T_r\ge T_{\text{obs}}\},\#\{T_r\le T_{\text{obs}}\}))/(R+1)\bigr)$$, is used for the $$p$$-value of the E-I index in `nwmixing`, whose reference values come from node-label permutations of the attribute. `nwcug`, `nwmixing` and `nwcorrelate` thus use the same doubled one-sided proportion, and `nwqap` the distance from the permutation mean (see QAP regression below); all four add 1 to numerator and denominator, so none reports $$p=0$$.

### QAP regression

`nwqap` regresses a dependent network on one or more predictor networks, or on node variables turned into dyadic predictors by `nwexpand` (`mode()`, default `same`, so a variable `office` enters as the indicator `same_office`). Every ordered pair $$i\neq j$$ is one observation, in undirected networks as well (both triangles are used), so there are $$n(n-1)$$ observations:

$$
g\bigl(E[Y_{ij}]\bigr) = \beta_0 + \beta_1 X_{1,ij} + \cdots + \beta_P X_{P,ij},
$$

where the regression and its link $$g$$ are chosen by `type()`: the default is `logit` (any non-zero tie value is a tie, with a note for valued networks), and `type(regress)` gives ordinary least squares for tie values (Chapter 20). The reported coefficients are those of this fit; their standard errors are not used. The $$p$$-values come from the *permutation* of the dependent network. Each of the $$R$$ permutations (`permutations()`, default 500) reorders the rows and columns of $$Y$$ together by a random permutation of the nodes (see the node-label permutation in Section E.12), leaves the predictors unchanged and refits the model, which gives a reference distribution of each coefficient $$b_k$$ with mean $$\bar b_k$$ and variance $$v_k$$ (stored in `e(V)`, a diagonal matrix, so Stata's standard errors are the permutation standard deviations). The reported $$p$$-value is the share of permuted coefficients that lie farther from the permutation mean than the observed one,

$$
p_k = \frac{1 + \#\{b_k^{(r)} > \bar b_k + \vert b_k-\bar b_k\vert \} + \#\{b_k^{(r)} < \bar b_k - \vert b_k-\bar b_k\vert \}}{R+1},
$$

with strict inequalities and with the observed coefficient counted as one more draw, so that the smallest possible value is $$1/(R+1)$$ (0.002 for 500 permutations, as in Chapter 20). With the option `qapspp` the $$p$$-values use *double semi-partialling* (Dekker et al. 2007) instead: for the predictor $$k$$, both $$Y$$ and $$X_k$$ are regressed by ordinary least squares on all other predictors (with a constant), the residuals of $$X_k$$ are arranged as a network and permuted as above, and the slope of the residuals of $$Y$$ on the permuted residuals is recomputed $$R$$ times; the same rule gives $$p_k$$. The partialling is by least squares even when `type(logit)` is used, and the coefficients reported remain those of the model fit. Because one node appears in many pairs, the pairs are not independent and the usual $$p$$-values do not apply; reshuffling the node labels of $$Y$$ shows what coefficients arise when $$Y$$ is unrelated to the predictors.

## E.13 Statistical models for networks

### Statistical models for networks: one frame, four families

The four families of models in Chapters 21 to 28 answer different questions but share one notation. Each explains the network by *statistics*: numbers computed from the network (or from the history of events) that stand for a mechanism, such as the number of mutual ties for reciprocity or of closed triangles for triadic closure. A statistic is written $$s$$, with arguments that say what it is computed from, and each has one *coefficient* $$\theta$$ with the same subscript: positive if the mechanism makes the outcome more likely, negative if less likely, zero if it plays no role, given the other statistics. The families differ in the outcome.

| Family | Outcome that is modeled | Statistics | Coefficients |
|---|---|---|---|
| ERGM | a whole network $$y$$ observed once | $$s(y)$$ | $$\theta$$ |
| SAOM | the choice of one actor $$i$$ who may change one tie, between panel waves | $$s_{ik}(x)$$ | $$\theta_k$$ (objective function), $$\rho_m$$ (rate) |
| REM | which ordered pair $$ij$$ produces the next event | $$s_{ij}(t)$$ | $$\theta$$ |
| DyNAM | which actor $$i$$ acts next (rate), and whom $$j$$ they choose (choice) | $$s_i(t)$$, $$s_{ij}(t)$$ | $$\theta_R$$, $$\theta_C$$ |

Here $$y$$ is a network seen once (the ERGM) and $$x$$ a network that changes between panel waves (the SAOM); $$Y$$ and $$X$$ are the corresponding random networks. $$y_{ij}$$ or $$x_{ij}$$ is 1 if there is a tie from $$i$$ to $$j$$ and 0 otherwise, as $$A_{ij}$$ above, and $$s_{ij}(t)$$ always means “the statistics of the pair $$ij$$, computed from everything that happened strictly before time $$t$$.”

All four models use the *multinomial logit* (or conditional logit): when something has to be chosen from a list of alternatives, the alternative $$a$$ is chosen with probability

$$
P(a) = \frac{\exp\{\theta^\top s(a)\}}{\sum_{a'} \exp\{\theta^\top s(a')\}},
$$

the sum running over all alternatives $$a'$$ on the list. The families differ in what they put on the list: two states of one tie (ERGM, conditional form), the options of one actor (SAOM), all ordered pairs (REM), or all actors and then all receivers (DyNAM). The commands, their terms and the assumptions of each model are described in the chapters.

### Exponential random graph models (ERGM)

An ERGM treats the whole network as one random outcome and gives every possible network $$y$$ on the same nodes a probability that grows with a weighted count of its features:

$$
P(Y = y) = \frac{\exp\{\theta^\top s(y)\}}{\kappa(\theta)}, \qquad \kappa(\theta) = \sum_{y'} \exp\{\theta^\top s(y')\},
$$

(Frank and Strauss 1986; Wasserman and Pattison 1996; Robins et al. 2007; Hunter et al. 2008) (Chapter 21). Here $$s(y)$$ is the list of counted features of $$y$$, with one entry $$s_k(y)$$ for each term in the model (the number of ties, of mutual pairs, of pairs of equal attribute joined by a tie, a weighted count of closed triangles), $$\theta$$ the list of coefficients, and $$\kappa(\theta)$$ the *normalizing constant*, the sum over every network $$y'$$ on the same nodes, which makes the probabilities add to 1. For 16 nodes and undirected ties there are $$2^{120}$$ such networks, which is why $$\kappa$$ cannot be computed directly. The conditional form, which is how coefficients are read, fixes every tie except $$(i,j)$$ at its current value $$y_{-ij}$$:

$$
\text{logit}\bigl(P(Y_{ij} = 1 \mid y_{-ij})\bigr) = \theta^\top \delta(y)_{ij}, \qquad \delta(y)_{ij} = s(y_{ij}^+) - s(y_{ij}^-),
$$

where $$y_{ij}^+$$ and $$y_{ij}^-$$ are $$y$$ with the tie $$(i,j)$$ set to present and to absent, all else unchanged, so that the *change statistic* $$\delta(y)_{ij}$$ is how much each counted feature changes when that one tie is switched on: $$\theta_k$$ is the change in the log-odds of a tie for each unit of the $$k$$th change statistic, given all other ties.

Because $$\kappa(\theta)$$ is out of reach, two strategies are used. *Maximum pseudolikelihood* (MPLE) (Strauss and Ikeda 1990) multiplies the conditional probabilities above as if the dyads were independent, which amounts to a logistic regression of every tie indicator on its change statistics; it is exact when no statistic involves more than one dyad and otherwise approximate, with standard errors that tend to be too small. *Monte Carlo maximum likelihood* (MCMLE) (Hunter and Handcock 2006) works with the true likelihood. The log-likelihood relative to a reference value $$\theta_0$$ is $$(\theta - \theta_0)^\top s(y_{\text{obs}}) - \log E_{\theta_0}\bigl[\exp\{(\theta - \theta_0)^\top s(Y)\}\bigr]$$, and the expectation is estimated from networks simulated at $$\theta_0$$ by a Markov chain that toggles one tie at a time; the simulation is repeated at the updated estimate until the estimating equations are close enough to the observed statistics, and, as in R's `ergm`, each sample is extended until its effective sample size reaches a target (64 by default). The maximum is reached where the expected statistics equal the observed ones, $$E_{\hat\theta}[s(Y)] = s(y_{\text{obs}})$$. This holds for terms with a fixed decay parameter; a term whose decay is estimated as well (such as `gwespfree()`) makes the model a curved exponential family, in which the equation holds in a weighted form (Hunter and Handcock 2006). With triangle-type counts the model can become *degenerate*, with almost all probability on nearly empty or nearly complete networks (Schweinberger 2011); weighted terms such as `gwesp` avoid it (Snijders et al. 2006; Hunter 2007).

### Stochastic actor-oriented models (SAOM)

A SAOM explains how a network changes between panel waves, as a series of small unobserved steps, each taken by one actor. At a random moment an actor $$i$$ gets the opportunity to change one of its outgoing ties, or to change nothing; it picks the option with the highest value to itself, up to random variation:

$$
f_i(\theta, x) = \sum_k \theta_k\, s_{ik}(x), \qquad p_i(x, x') = \frac{\exp\{f_i(\theta, x')\}}{\sum_{x'' \in \mathcal{C}(x,i)} \exp\{f_i(\theta, x'')\}},
$$

and opportunities come to actor $$i$$ at rate $$\rho_m$$ in observation period $$m$$ (Snijders 1996; Snijders 2001; Snijders et al. 2010) (Chapter 25). The network $$x$$ moves to $$x'$$ by a step of actor $$i$$ at rate $$\rho_m\, p_i(x,x')$$. Here $$x'$$ differs from the current network $$x$$ by at most one outgoing tie of $$i$$, and $$\mathcal{C}(x,i)$$ is the *choice set*: $$x$$ itself and the $$n-1$$ networks obtained by toggling one of $$i$$'s outgoing ties. The statistic $$s_{ik}(x)$$ is the $$k$$th effect seen from actor $$i$$'s position (its outdegree, the number of its reciprocated ties, the number of transitive triplets it takes part in), so that $$f_i$$ is the *objective function*: how attractive the network $$x$$ is to $$i$$. The *rate* $$\rho_m$$ is the expected number of opportunities per actor in period $$m$$. A step in which an actor makes a change is a *ministep*. When a behavior changes along with the network, actors also take ministeps on their own behavior with a second objective function of the same form, which is what separates selection from influence. As in RSiena, an effect can be split into a *creation* part (applying only when a tie is added) and an *endowment* part (applying only when a tie is removed).

The likelihood of two observed waves would require summing over every sequence of ministeps that could connect them, which cannot be done. The default is therefore the *method of moments* (Snijders 2001): with $$u_k(x) = \sum_i s_{ik}(x)$$ the total of the $$k$$th statistic over all actors, the estimates solve

$$
E_{\rho,\theta}\bigl[u(X(t_{m+1})) \mid X(t_m) = x_{\text{obs}}(t_m)\bigr] = u\bigl(x_{\text{obs}}(t_{m+1})\bigr),
$$

summed over periods $$m$$: the model, started at the first wave, must on average reproduce the observed statistics of the next wave (and an amount of change that matches the observed one, which determines $$\rho_m$$). The left-hand side can only be evaluated by simulation, so the equations are solved by the *Robbins-Monro* stochastic approximation (Robbins and Monro 1951): repeatedly simulate at the current estimate, compare simulated and observed statistics, and move the estimate by a small step that reduces the difference, with steps that shrink over time. Convergence is judged by $$t$$-ratios of the deviation, which should be small. For a single group of actors `nwsaom` also offers *maximum likelihood* (option `ml`), which treats the unobserved sequence of ministeps as missing data (Snijders et al. 2010), and *Bayesian estimation* (`nwsaom bayes`) (Koskinen and Snijders 2007). The process is a Markov process and actors are *myopic*: they weigh the immediate result of each option and do not plan ahead.

### Relational event models (REM)

A REM works on a list of timed events, each with a sender, a receiver and a time. At every moment each ordered pair of actors $$ij$$ has a *hazard* $$\lambda_{ij}(t)$$, the instantaneous rate at which $$i$$ would next act toward $$j$$:

$$
\lambda_{ij}(t) = \lambda_0(t)\,\exp\{\theta^\top s_{ij}(t)\}
$$

(Butts 2008). The statistics $$s_{ij}(t)$$ are computed from the earlier events only (how often $$i$$ has contacted $$j$$, whether $$j$$ contacted $$i$$ last, how active $$i$$ has been); $$\exp(\theta_k)$$ is the factor by which the hazard is multiplied for one unit of the statistic, and $$\lambda_0(t)$$ is the *baseline hazard*, the rate at which events happen at all, the same for every pair. Given that the next event occurs, the probability that it is the pair $$ij$$ is the pair's share of all hazards. If the order of events is all that is used, the baseline cancels, because it appears in the numerator and in every term of the denominator, and the estimates maximize the *ordinal partial likelihood*, the device of Cox's survival model (Cox 1972):

$$
L(\theta) = \prod_{k=1}^{E} \frac{\exp\{\theta^\top s_{a_k}(t_k)\}}{\sum_{(i,j) \in \mathcal{R}_k} \exp\{\theta^\top s_{ij}(t_k)\}},
$$

where $$a_k = (i_k, j_k)$$ is the pair that produced event $$k$$ at time $$t_k$$, $$E$$ is the number of events and $$\mathcal{R}_k$$ is the *risk set* at event $$k$$, the pairs that could have produced it, ordinarily all $$n(n-1)$$ ordered pairs of different actors. At each event, how probable was the pair that fired among all pairs that could have; multiply over events. This is also why the model has no intercept: a constant added to every score cancels. A *timed* likelihood also uses the waiting times and therefore needs a model for $$\lambda_0(t)$$ (Butts 2008); `nwrem` fits the ordinal one only, as `relevent::rem.dyad()` does with `ordinal=TRUE`. Events with identical time stamps are read in the order of the list, one after another, each seeing the earlier ones, as `relevent` does, so the order of the rows in such a group matters.

### Dynamic network actor models (DyNAM)

A DyNAM splits the question of the REM in two. First, *who acts*: each actor $$i$$ has a hazard $$\lambda_i(t)$$ to be the next to send an event. Second, *whom they choose*: given that $$i$$ acts, a multinomial logit over all possible receivers:

$$
\lambda_i(t) = \exp\{\theta_R^\top s_i(t)\}, \qquad P(j \mid i, t) = \frac{\exp\{\theta_C^\top s_{ij}(t)\}}{\sum_{h \neq i} \exp\{\theta_C^\top s_{ih}(t)\}}
$$

(Stadtfeld and Block 2017) (Chapter 28). The first part is the *rate* sub-model, the second the *choice* sub-model, with separate coefficients $$\theta_R$$ and $$\theta_C$$, separate statistics and separate estimation. The statistics $$s_i(t)$$ describe the single actor (by default, to how many different actors $$i$$ has sent events so far and from how many it has received them), $$s_{ij}(t)$$ the pair (past contacts from $$i$$ to $$j$$, whether $$j$$ contacted $$i$$, shared attribute). In the rate sub-model only the order of events is used by default: the probability that actor $$i$$ is the next to act is $$\lambda_i(t)/\sum_h \lambda_h(t)$$, the sum running over all $$n$$ actors. With the option `intercept`, a constant $$\theta_0$$ enters the exponent, $$\lambda_i(t) = \exp\{\theta_0 + \theta_R^\top s_i(t)\}$$, and the waiting times are used as well: each actor is a clock with that rate, so the expected waiting time of actor $$i$$ is $$1/\lambda_i(t)$$.

Both sub-models are estimated by maximum likelihood, each from its own conditional probabilities: the rate sub-model from the probability that the actor who did act was the one to act, the choice sub-model from the probability that the receiver who was chosen was chosen. In the order-only default both are partial likelihoods of the form of the REM's, with $$n$$ alternatives for the rate and $$n-1$$ for the choice. For events that two actors form together, with no sender (a treaty, a co-authored paper), the *coordination* model (Stadtfeld et al. 2017) (`submodel(choice_coordination)`) multiplies each actor's choice probability for the other and normalizes over all unordered pairs:

$$
P(\{i,j\} \mid t) = \frac{P(j \mid i, t)\, P(i \mid j, t)}{\sum_{k<l} P(l \mid k, t)\, P(k \mid l, t)}.
$$

It is a product of two multinomial logits and, unlike the choice and rate sub-models, need not be concave in $$\theta_C$$, so `nwdynam` fits it from several starting values and keeps the best converged one. Events with identical time stamps are treated as *simultaneous*, as the R package `goldfish` does: the statistics of all events at one time stamp are computed from the network as it stood before that time, so the order of the rows in the group does not matter (the option `sequential` restores the older row-by-row treatment). `nwrem` and `nwdynam` thus differ on this point on purpose, because each follows its reference program.

When ties are observed only at a few moments, the SAOM is the model of change; when every event is recorded with its time, the REM and the DyNAM use that information directly. For a single snapshot, the ERGM is the standard model of tie dependence.

{% endraw %}
