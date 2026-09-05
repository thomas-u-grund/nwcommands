---
title: "Importing & Exporting"
parent: Tutorials
nav_order: 3
description: "Edgelists, UCINET/Pajek formats, and moving networks in and out of nwcommands."
---

# Importing & Exporting

Real network data rarely arrives as an nwcommands-native object — it's a text file, a UCINET
matrix, or something a collaborator built in Pajek. This tutorial covers moving data across that
boundary in both directions.

## Importing a plain edgelist

`nwimport` reads a range of common formats, and `filename` can be a URL — no local download
step needed:

```stata
. nwimport "https://raw.githubusercontent.com/thomas-u-grund/nwcommands/master/data/edgelist_example.txt", type(edgelist)
------------------------------
Importing successful

. nwsummarize
--------------------------------------------------
   Network name:  edgelist_example
   Network id:  1
   Directed: true
   Valued: false
   Two-mode: false
   Nodes: 4
   Selfloop: false
   Arcs: 5
   Minimum value:  0
   Maximum value:  1
   Density:  .417
   Temporal: false
```

The imported network is named after the file by default (`edgelist_example`) — use `name()` to
pick something else.

## Exporting to UCINET and Pajek

`nwexport` writes one network at a time, in either UCINET (`.dl`) or Pajek (`.net`) format:

```stata
. nwwebuse florentine, nwclear

. nwexport flomarriage, type(ucinet) replace
Exporting network: flomarriage
Saved as file: flomarriage.dl

. nwexport flobusiness, type(pajek) replace
Exporting network: flobusiness
Saved as file: flobusiness.net
```

By default the file lands in Stata's current working directory, named after the network; `fname()`
overrides that.

## Round-tripping through a plain edgelist

Sometimes the format you need isn't a file format at all — you just want the network as an
ordinary Stata dataset to reshape, filter, or merge with something else, then turn back into a
network. `nwtoedge` does the first half:

```stata
. nwwebuse glasgow, nwclear

. nwtoedge glasgow1
(50 real changes made)

. describe

Contains data from /var/folders/hx/2zp2k5ps2y7d_6hx015fcr1h0000gn/T//S_50827.000001
 Observations:         2,500                  
    Variables:             3                  5 Sep 2026 14:21
------------------------------------------------------------------------------------------------------------------
Variable      Storage   Display    Value
    name         type    format    label      Variable label
------------------------------------------------------------------------------------------------------------------
_ego            str3    %9s                   
_alter          str3    %9s                   
glasgow1        byte    %10.0g                
------------------------------------------------------------------------------------------------------------------
Sorted by: _ego  _alter

. list in 1/5

     +--------------------------+
     | _ego   _alter   glasgow1 |
     |--------------------------|
  1. |   n1       n1          . |
  2. |   n1      n10          0 |
  3. |   n1      n11          1 |
  4. |   n1      n12          0 |
  5. |   n1      n13          0 |
     +--------------------------+
```

Note that this is every possible pair of the 50 nodes (2,500 rows = 50×50), not just the pairs
that are actually tied — the tie value itself is the column named after the network
(`glasgow1`, here `0`/`1`/missing for the diagonal). Keep only the real ties and rebuild:

```stata
. keep if glasgow1 == 1
(2,387 observations deleted)

. nwfromedge _ego _alter, name(rebuilt)

. nwsummarize rebuilt
--------------------------------------------------
   Network name:  rebuilt
   Network id:  4
   Directed: true
   Valued: false
   Two-mode: false
   Nodes: 50
   Selfloop: false
   Arcs: 113
   Minimum value:  0
   Maximum value:  1
   Density:  .046
   Temporal: false
```

`rebuilt` comes back with all 50 of `glasgow1`'s original nodes, isolates included, even though an
edgelist itself has no way to represent a zero-tie node as a row of its own — three of Glasgow's 50
students have no friendship ties at all. [nwtoedge](../../reference/nwtoedge) attaches its source
network's own full node list to the edgelist dataset behind the scenes (no extra rows or variables
to see), and [nwfromedge](../../reference/nwfromedge) automatically adds back anything on that list
that the edgelist's own ties did not reproduce - no manual bookkeeping needed. This only works
because `nwtoedge` produced this particular edgelist; an edgelist typed in by hand or brought in
from another source carries no such list, so genuinely use [nwaddnodes](../../reference/nwaddnodes)
for that case, same as always.
