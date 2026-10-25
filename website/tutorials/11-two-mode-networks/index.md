---
title: "Tutorial 9: Two-mode networks"
parent: "nwcommands (core)"
nav_order: 10
description: "Two-mode (affiliation) networks: people and the events or companies they attend; degree, projection to one mode, components, community detection and plotting, with the data sets davis and ftdirectors_se."
---

# Two-mode networks

In a **two-mode** (affiliation) network there are two kinds of nodes, and ties run only between the kinds, never
inside one: women and the social events they attend, directors and the companies on whose boards they sit. This
tutorial uses the two two-mode data sets that come with the core, `davis` (a small, classic one) and
`ftdirectors_se` (a large one), and shows how to describe such a network, count what each node is tied to, project it
onto one mode and plot it. The data sets, with their sources and licences, are described on the
[data sets](../../datasets/#two-mode-affiliation-networks) page.

{: .note }
`davis` and `ftdirectors_se` ship with the release that follows 3.3.1. With that release installed,
`nwwebuse davis` and `nwwebuse ftdirectors_se` load them, as shown below. The output on this page was produced from
the copies in the data folder of the repository, loaded with `nwuse`, which is the command `nwwebuse` calls.

## Southern women: 18 women, 14 events

Eighteen women of a Southern US town and the 14 social events they attended in 1936, as reported in the local
newspaper (Davis, Gardner and Gardner 1941). A tie means that the woman attended the event.

```stata
. nwwebuse davis, nwclear

. nwsummarize davis
--------------------------------------------------
   Network name:  davis
   Network id:  1
   Directed: false
   Valued: false
   Two-mode: true
   Nodes: 32
      Level 1: 18 (woman)
      Level 2: 14 (event)
   Selfloop: false
   Edges: 89
   Minimum value:  0
   Maximum value:  1
   Density:  .353
   Temporal: false
```

`Two-mode: true` and the two levels tell you what you have: 18 nodes of the first mode (`woman`) and 14 of the
second (`event`), 32 nodes and 89 ties in all. The density is computed over all pairs of nodes, so it is not
comparable with the density of a one-mode network. The variable `_nwmode` (1 or 2) says which mode a row belongs to,
and the attributes belong to one mode each: `surname` and `title` to the women, `eventdate` to the events.

## Degree in a two-mode network

`nw2degree` counts the ties of each node. In a two-mode network it divides the count by the number of nodes in the
*other* mode, so a woman who attended all 14 events has the value 1. Multiplying back gives plain counts:

```stata
. nw2degree davis, generate(att)
----------------------------------------
  Network name: davis

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
         att |         32    .3531746     .171207   .1428571   .7777778

. generate attended = round(att * 14) if _nwmode == "1"
(14 missing values generated)

. generate guests = round(att * 18) if _nwmode == "2"
(18 missing values generated)

. list _nwnode surname title attended if _nwmode == "1", noobs

  +-------------------------------------------+
  |   _nwnode      surname   title   attended |
  |-------------------------------------------|
  |    Brenda       Rogers    Miss          7 |
  | Charlotte       McDowd    Miss          4 |
  |   Dorothy    Murchison     Mrs          2 |
  |   Eleanor          Nye    Miss          4 |
  |    Evelyn    Jefferson     Mrs          8 |
  |-------------------------------------------|
  |     Flora        Price     Mrs          2 |
  |   Frances     Anderson    Miss          4 |
  |     Helen        Lloyd     Mrs          5 |
  | Katherine       Rogers    Miss          6 |
  |     Laura   Mandeville    Miss          7 |
  |-------------------------------------------|
  |      Myra      Liddell    Miss          4 |
  |      Nora      Fayette     Mrs          8 |
  |    Olivia     Carleton     Mrs          2 |
  |     Pearl   Oglethorpe    Miss          3 |
  |      Ruth       DeSand    Miss          4 |
  |-------------------------------------------|
  |    Sylvia     Avondale     Mrs          7 |
  |   Theresa     Anderson    Miss          8 |
  |     Verne    Sanderson    Miss          4 |
  +-------------------------------------------+
```

Evelyn, Nora and Theresa attended the most events (8 each); Dorothy, Flora and Olivia only 2. The same variable
gives, for the second mode, the number of women who attended each event:

```stata
. gsort -guests

. list _nwnode eventdate guests in 1/3, noobs

  +-------------------------------+
  | _nwnode    eventdate   guests |
  |-------------------------------|
  |      E8   1936-09-16       14 |
  |      E9   1936-04-08       12 |
  |      E7   1936-03-15       10 |
  +-------------------------------+

. sort _nwmode _nwnode
```

The best attended event was `E8` (16 September 1936), with 14 of the 18 women.

## Projecting onto one mode

Two women are linked in the **projection** onto the women if they attended a common event, and the value of the tie
is the number of events they attended together. `nw2project` builds this one-mode network; `project(1)` keeps the
first mode, `project(2)` would keep the events:

```stata
. nw2project davis, project(1) name(women)
----------------------------------------
  Projected network: women
  Level: 1
  Nodes: 18
  Ties: 278

. nwsummarize women
--------------------------------------------------
   Network name:  women
   Network id:  2
   Directed: false
   Valued: true
   Two-mode: false
   Nodes: 18
   Selfloop: false
   Edges: 139
   Minimum value:  0
   Maximum value:  7
   Density:  .908
   Temporal: false
   Provenance:  projected from network davis, mode 1 (woman), stat=minmax
```

The projection is an ordinary network, and all one-mode commands work on it. It has 139 ties (the line `Ties: 278`
of `nw2project` counts each undirected tie in both directions), the tie values go up to 7 shared events, and almost
all pairs of women share at least one event (density .908). That is typical of projections: a few well attended events
link everybody, so the projection is much denser than the two-mode network it came from. Use the tie values, not
just their presence, when you analyze it.

`nwcommunity` finds groups of women in the projection (Louvain, using the tie values):

```stata
. nwcommunity women, generate(group)
----------------------------------------
  Network name: women
  Communities: 2
  Modularity Q: .152

      group |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |          8       44.44       44.44
          2 |         10       55.56      100.00
------------+-----------------------------------
      Total |         18      100.00
```

It finds two communities, of 8 and 10 women. Community detection on a projection is a description of the shared
events, not a test of a theory about the women; how the groups compare with other analyses of these data depends on
the method, and nothing here claims that they reproduce any particular published partition.

## Plotting the two modes

`layout(bipartite)` places the two modes in two rows, ordered to reduce crossings; `vertical` makes them two columns,
which gives the names room:

```stata
. nwplot davis, layout(bipartite, vertical) color(_nwmode) label(_nwnode) scheme(s1network) export("plot_davis.svg") repl
> ace
Calculating node coordinates...
Plotting network...
Exporting graph to plot_davis.svg...
(file plot_davis.svg not found)
file plot_davis.svg saved as SVG format
```

![The Southern women (left) and the events they attended (right)](plot_davis.svg)

## A large two-mode network: company directors in Sweden

`ftdirectors_se` is a subset of a data set of directors and companies compiled from the Financial Times web site
(Evtushenko and Gastner 2019; licence and the changes made are on the [data sets](../../datasets/#ftdirectors_se-company-directors-in-sweden) page):
the 455 Swedish listed companies and all 5,092 directors who sit on their boards.

```stata
. nwwebuse ftdirectors_se, nwclear

. nwsummarize ftdirectors_se
--------------------------------------------------
   Network name:  ftdirectors_se
   Network id:  1
   Directed: false
   Valued: false
   Two-mode: true
   Nodes: 5547
      Level 1: 5092 (director)
      Level 2: 455 (company)
   Selfloop: false
   Edges: 5669
   Minimum value:  0
   Maximum value:  1
   Density:  0
   Temporal: false
```

The commands are the same, only the size differs: 5,547 nodes and 5,669 ties. How many boards does a director sit on?

```stata
. nw2degree ftdirectors_se, generate(deg)
----------------------------------------
  Network name: ftdirectors_se

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
         deg |      5,547    .0024468    .0010275   .0005892   .0153846

. generate boards = round(deg * 455) if _nwmode == "1"
(455 missing values generated)

. tabulate boards

     boards |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |      4,702       92.34       92.34
          2 |        268        5.26       97.60
          3 |         81        1.59       99.19
          4 |         26        0.51       99.71
          5 |          8        0.16       99.86
          6 |          5        0.10       99.96
          7 |          2        0.04      100.00
------------+-----------------------------------
      Total |      5,092      100.00
```

Nine in ten directors (92.3 percent) sit on one board; 390 sit on two to seven. Directors and companies carry
attributes (gender and age; sector, industry and number of employees), so attribute questions are ordinary Stata
questions. Gender is missing for 582 directors:

```stata
. tabulate gender if _nwmode == "1", missing

     gender |      Freq.     Percent        Cum.
------------+-----------------------------------
            |        582       11.43       11.43
     Female |      1,025       20.13       31.56
       Male |      3,485       68.44      100.00
------------+-----------------------------------
      Total |      5,092      100.00

. tabstat boards if _nwmode == "1", by(gender) statistics(mean count)

Summary for variables: boards
Group variable: gender 

gender |      Mean         N
-------+--------------------
Female |  1.190244      1025
  Male |  1.098709      3485
-------+--------------------
 Total |  1.119512      4510
----------------------------
```

Among the directors whose gender is known, the women sit on slightly more boards on average (1.19) than the men
(1.10). This is a description of this subset, which holds only Swedish companies; it says nothing about causes.

The projection onto the companies links two companies when they share a director. Its tie value is the number of
shared directors:

```stata
. nw2project ftdirectors_se, project(2) name(companies)
----------------------------------------
  Projected network: companies
  Level: 2
  Nodes: 455
  Ties: 1518

. nwsummarize companies
--------------------------------------------------
   Network name:  companies
   Network id:  2
   Directed: false
   Valued: true
   Two-mode: false
   Nodes: 455
   Selfloop: false
   Edges: 759
   Minimum value:  0
   Maximum value:  5
   Density:  .007
   Temporal: false
   Provenance:  projected from network ftdirectors_se, mode 2 (company), stat=minmax
```

Only 759 of the 103,285 possible pairs of companies share a director (density .007). The components of the
projection show how the companies fall apart into groups of interlocked boards:

```stata
. quietly nwcomponents companies, generate(comp)

. display r(components)
132

. egen size = count(comp), by(comp)

. summarize size, meanonly

. display r(max)
304

end of do-file
```

The 455 companies form 132 components; the largest holds 304 companies, and many of the others consist of a single
company without a director in common with any other.

{: .note }
For plots, project onto the companies first: a plot of all 5,547 nodes of the two-mode network is unreadable. A
two-mode network is stored as one matrix over both modes, so the size limits count the nodes of both modes together
(see [How large a network can I analyze?](../../nwcommands/size-limits/)).

## What to remember

- `nwsummarize` shows `Two-mode: true` and the sizes of the two modes; `_nwmode` marks the mode of each row.
- `nw2degree` divides the number of ties by the size of the other mode; multiply back for counts.
- `nw2project, project(1)` and `project(2)` give the two one-mode networks, with the number of shared neighbors as
  tie value. The projections are dense when a few nodes of the other mode have many ties.
- After a projection, the whole one-mode toolbox applies: `nwcomponents`, `nwcommunity`, `nwdegree` and the others.
- `nw2clustering` gives clustering coefficients for two-mode networks, and `nwplot` has `layout(bipartite)`.

The commands of this tutorial are in `example.do` in the folder of the tutorial; its log is `example.log`.
