---
title: "Tutorial 4: Reproducible Workflow"
parent: "nwcommands (core)"
nav_order: 4
description: "A complete analysis in one do-file: ties and people from CSV files, a network with node attributes, results kept as variables, saving the network project, and handing the ties to another program."
---

# Tutorial 4: Reproducible Workflow

Everything in the earlier tutorials was typed command by command. A real project is a **do-file** that anyone can
run from the first line to the last and get the same results. This tutorial shows the shape of such a file: raw data
in, a network with node attributes, results, and the network written out again. It uses a tiny made-up
office of six people (`Ann` to `Fay`) so that every step is visible; the whole script is
[`example.do`](example.do) and its output [`example.log`](example.log).

## Start clean, fix the seed

```stata
version 17
clear all
set seed 20261031
```

`version` makes the script behave the same in later Stata releases, `clear all` removes anything left over from
an earlier session (including the networks held in memory) and `set seed` makes every random step repeatable,
for example `nwrandom` or the permutation tests of [Tutorial 18](../18-testing/). Without the seed the same
file gives a different p-value on every run.

## Two files, as the data usually come

Ties and people are most often separate files: a list of who is tied to whom, and a table of characteristics.
The script first writes two small CSV files with `export delimited` so that it is self-contained (in your
project they are the files you were given):

* `edges.csv` has two columns, `ego` and `alter`, one row per tie.
* `people.csv` has one row per person: `name`, `dept` and `age`.

## Read the ties and build the network

```stata
. import delimited using "edges.csv", varnames(1) stringcols(_all) clear

. nwfromedge ego alter, name(friends) undirected

. nwsummarize friends
--------------------------------------------------
   Network name:  friends
   Network id:  1
   Directed: false
   Valued: false
   Two-mode: false
   Nodes: 6
   Selfloop: false
   Edges: 7
   Minimum value:  0
   Maximum value:  1
   Density:  .467
   Temporal: false
```

`nwfromedge` takes the names in the two columns as the nodes, so six people appear although there are seven
rows. Give the network a `name()` of your own, because later commands refer to it. A third variable would be the tie
value (see [Tutorial 16](../16-valued-networks/)).

## Attach the people by name

After `nwfromedge` the data set has one row per node, and the variable `_nwnode` holds the node's name. Copy
it into an ordinary variable and merge the table of people on it. Use `merge 1:1`, so that Stata stops if a name appears
twice, and read the result of the merge:

```stata
. generate name = _nwnode

. merge 1:1 name using `people', nogenerate

    Result                      Number of obs
    -----------------------------------------
    Not matched                             0
    Matched                                 6  
    -----------------------------------------
```

(`people` is a temporary file with the contents of `people.csv`; see the script.) All six matched. A name that
is spelled differently in the two files would show up here as "Not matched", which is why the check belongs in
the script. The attributes are now variables next to the network, ready for
`nwplot, color(dept)`, `nwmixing, attribute(...)` ([Tutorial 14](../14-homophily-mixing/)) and the like.

## Analyse and keep the results as variables

Commands with `generate()` write their result into a variable, so results line up with the people and with
the attributes, and can be tabulated, plotted or exported like any other variable:

```stata
. nwdegree friends, generate(deg) silent

. nwbetween friends, generate(btw) silent

. list name dept age deg btw, noobs

  +--------------------------------+
  | name    dept   age   deg   btw |
  |--------------------------------|
  |  Ann   sales    31     2     0 |
  |  Bob   sales    45     2     0 |
  |   Cy    tech    38     3     6 |
  |  Dee    tech    29     3     6 |
  |  Eli    tech    52     2     0 |
  |--------------------------------|
  |  Fay   sales    41     2     0 |
  +--------------------------------+
```

Cy and Dee sit on the only path between the two halves of the office, hence their betweenness of 6.
(`silent` suppresses the printed table, handy in a script that runs many commands. Avoid names for
generated variables that are the beginning of the name of an existing variable.)

## Save the whole project

`nwsave` writes the network and all variables to one file, `nwuse` brings it back:

```stata
. nwsave friends_project, replace

. nwclear

. clear

. nwuse friends_project

. nwsummarize friends
```

(`Nodes: 6`, `Edges: 7`, as before; see the log.) Use this to separate the slow data-preparation script from the
analysis scripts, or to share a network with its attributes in one file. Two Stata users with the core installed
can open it. For other programs, export a standard format (see [Tutorial 3](../03-importing-exporting/)).

## Hand the ties to another program

`nwtoedge` turns a network into a data set of pairs, one row per possible pair; keep the pairs that are ties and write
them out. R, Python and most network programs read this file as an edge list:

```stata
. nwtoedge friends

. keep if friends == 1
(14 observations deleted)

. keep _ego _alter

. export delimited using "friends_edges.csv", replace

. type friends_edges.csv
_ego,_alter
Bob,Ann
Cy,Ann
Cy,Bob
Dee,Cy
Eli,Dee
Fay,Dee
Fay,Eli
```

The pairs come from the adjacency matrix, so each tie of an undirected network is listed once, in the
direction from the later node to the earlier one.

## A checklist for your own do-files

* Begin with `version`, `clear all` and `set seed`; end with `log close` if you open a log at the top.
* Keep raw data untouched and write cleaned data and results to separate files.
* Refer to networks by `name()` and to node attributes by variable, never by row number.
* Check every `merge`; do not leave "Not matched" unexplained.
* Put the packages' versions into the log (`nwversion` shows the core version) so that a later reader knows what
  produced the results.
* Run the file from the top in a fresh Stata session before you trust it.
