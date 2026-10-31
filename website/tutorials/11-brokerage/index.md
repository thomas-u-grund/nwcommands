---
title: "Tutorial 11: Brokerage & Structural Holes"
parent: "nwcommands (core)"
nav_order: 12
description: "Who connects otherwise separate parts of a network? Burt's structural hole measures, bridges, Gould-Fernandez brokerage roles and Simmelian ties."
---

# Tutorial 11: Brokerage & Structural Holes

A node that connects parts of the network that would otherwise be disconnected holds an advantageous position: it
controls the flow between them, hears things first and can combine information from different sources. Network
analysis has several ways of making this precise. This tutorial uses four of them, on the Florentine marriage
network (`flomarriage`, 16 families) and on Sampson's monks (`sampson`, 18 monks in three factions). The script is
[`example.do`](example.do), the complete output [`example.log`](example.log).

[Tutorial 8](../08-centrality/) already introduced betweenness, the number of shortest paths that run through a
node. The measures below are related but ask more specific questions.

## Structural holes: Burt's measures

A **structural hole** is a missing tie between two of a node's contacts. If all of your friends know each other,
you add little by being their friend; if they do not, you are the only link between them. `nwburt` computes
Burt's (1992) measures for every node and stores them as variables:

```stata
. nwwebuse florentine, nwclear

. nwburt flomarriage
----------------------------------------
  Network name: flomarriage
----------------------------------------
    Burt structural hole measures

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
    _effsize |         16    2.166667    1.355373          0   5.666667
 _efficiency |         16    .8350694    .2614593          0          1
 _constraint |         16    .5494792    .3071544          0          1
  _hierarchy |         15    .2800012      .44961          0          1
```

* **Effective size** (`_effsize`) is the number of contacts minus the redundancy among them. A node with five
  contacts who all know each other has an effective size close to 1; one whose contacts are strangers has 5.
* **Efficiency** (`_efficiency`) is effective size per contact.
* **Constraint** (`_constraint`) is high when contacts are tied to each other or when the node invests
  much of its network in one contact. Low constraint means many structural holes.
* **Hierarchy** (`_hierarchy`) is how concentrated the constraint is on a single contact (it is missing for the
  isolate).

Put them next to degree, betweenness and clustering for the better connected families:

```stata
. list _nwnode deg btw clu _effsize _constraint if deg>=3, noobs

  +--------------------------------------------------------------+
  |    _nwnode   deg        btw        clu   _effsize   _const~t |
  |--------------------------------------------------------------|
  |    albizzi     3   19.33333          0          3   .3333333 |
  |   bischeri     3        9.5   .3333333   2.333333   .4822531 |
  | castellani     3          5   .3333333   2.333333   .4822531 |
  |   guadagni     4   23.16667          0          4        .25 |
  |     medici     6       47.5   .0666667   5.666667   .2098765 |
  |--------------------------------------------------------------|
  |    peruzzi     3          2   .6666667   1.666667   .6558642 |
  |    ridolfi     3   10.33333   .3333333   2.333333   .4598765 |
  |    strozzi     4   9.333333   .3333333          3   .4583333 |
  | tornabuoni     3   8.333333   .3333333   2.333333   .4598765 |
  +--------------------------------------------------------------+
```

(`deg`, `btw` and `clu` were made with `nwdegree`, `nwbetween` and `nwclustering`, all with `generate()`.)
The Medici stand out: six contacts, an effective size of 5.7 (almost every contact is a separate source), the
lowest constraint (.21) and by far the highest betweenness (47.5), the textbook structural-hole position. The
Peruzzi have three contacts, but two of the three pairs of their contacts are tied (clustering .67), so their effective size is
1.7 and their constraint is the highest in the table. Same degree as the Albizzi, very different brokerage
opportunity.

`nwconstraint` returns the pairwise constraint contributions as a network (`nwconstraint flomarriage,
name(floconstraint)`), for those who need to see which contact constrains whom.

## Bridges

A **bridge** is a tie whose removal would disconnect its two ends: the only path between two parts of the network.
`nwbridges` saves the bridges as a new network:

```stata
. nwbridges flomarriage, name(flobridges)

------------------------------
    Network      : flomarriage
    Directed     : false
    Bridges      : 5
    Type         : global
------------------------------
```

Five of the 20 marriage ties are bridges. With `type(local)` you get **local bridges**, ties whose removal
would push the two ends more than two steps apart, a weaker and more common notion.

## Brokerage roles: Gould and Fernandez

When nodes belong to groups, the brokerage question becomes: *whose* contacts does the broker connect? For every
two-path a → b → c where a cannot reach c directly, Gould and Fernandez (1989) name the role of b by comparing the
groups of a, b and c. `nwbrokerage` counts these roles for every node, using a numeric group variable (here the
monks' faction, encoded as a number):

```stata
. nwwebuse sampson, nwclear

. encode faction, generate(fnum)

. nwbrokerage samplike, group(fnum) generate(brk)
(note: tie values are ignored; this measure is binary)
----------------------------------------
  Network name: samplike
  Two-paths classified: 224
             Role  |    Total
-------------------+---------------
      coordinator  |    56
       gatekeeper  |    80
   representative  |    69
       consultant  |    5
          liaison  |    14
```

| Role | Groups of a, b and c |
|---|---|
| coordinator | all three in the same group |
| gatekeeper | a in another group; b and c in the same group |
| representative | a and b in the same group; c in another group |
| consultant | a and c in the same group; b in another group |
| liaison | all three in different groups |

Gatekeepers (80) and representatives (69) dominate here: most mediation crosses a faction boundary, either
from outside into the broker's own faction (gatekeeper) or from the broker's faction to the outside
(representative). Consultants are rare (5), because they need two ends in a group the broker does not belong to.
The counts for each monk are in the variables `brk_coordinator`, `brk_gatekeeper`, `brk_representative`,
`brk_consultant` and `brk_liaison`:

```stata
. gsort -brk_gatekeeper

. list _nwnode faction brk_gatekeeper brk_representative brk_liaison in 1/5, noobs

  +--------------------------------------------------------+
  |     _nwnode   faction   brk_ga~r   brk_re~e   brk_li~n |
  |--------------------------------------------------------|
  |     Gregory     Turks         16          0          0 |
  |  John Bosco     Turks         12         16          7 |
  | Bonaventure     Loyal          9          8          3 |
  |      Albert     Turks          9          0          0 |
  |      Victor     Loyal          8          6          0 |
  +--------------------------------------------------------+
```

John Bosco is the one monk who brokers in all roles, including seven liaison positions between three factions.

## Simmelian ties

A tie is **Simmelian** if it is reciprocated and the two nodes share at least one reciprocated third contact
(Krackhardt 1998): the tie is embedded in a closed triad of mutual ties. Such ties are more stable and carry
more trust than a tie that stands alone. `nwsimmelian` returns the Simmelian ties as a new network:

```stata
. nwsimmelian samplike, name(strongdir)
(note: tie values are ignored; this measure is binary)

. nwsummarize strongdir
--------------------------------------------------
   Network name:  strongdir
   Network id:  7
   Directed: true
   Valued: true
   Two-mode: false
   Nodes: 18
   Selfloop: false
   Arcs: 32
   Minimum value:  0
   Maximum value:  1
   Density:  .105
```

The monks' "likes" network has 88 arcs, of which 32 are in mutual triads. Tutorial 12 comes back to triads.

## Which command when?

| Question | Command |
|---|---|
| Who spans many structural holes (low constraint, large effective size)? | `nwburt`, `nwconstraint` |
| Which ties are the only connection between two parts? | `nwbridges` |
| Whose contacts does a node connect, given groups? | `nwbrokerage` |
| Which ties are embedded in mutual triads (strong, stable)? | `nwsimmelian` |
| How many shortest paths run through a node? | `nwbetween` ([Tutorial 8](../08-centrality/)) |
