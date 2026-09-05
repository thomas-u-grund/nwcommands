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
(`glasgow1`, here `0`/`1`/missing for the diagonal). Before filtering down to real ties, capture
the full set of node labels — this unfiltered pairs list is the only place an isolate's label
still shows up:

```stata
. levelsof _ego, local(alllabels) clean
n1 n10 n11 n12 n13 n14 n15 n16 n17 n18 n19 n2 n20 n21 n22 n23 n24 n25 n26 n27 n28 n29 n3 n30 n31 n32 n33 n34 n35 n
> 36 n37 n38 n39 n4 n40 n41 n42 n43 n44 n45 n46 n47 n48 n49 n5 n50 n6 n7 n8 n9
```

Now keep only the real ties and rebuild:

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
   Nodes: 47
   Selfloop: false
   Arcs: 113
   Minimum value:  0
   Maximum value:  1
   Density:  .052
   Temporal: false
```

`rebuilt` has 47 nodes rather than the original 50 — the same behavior [nwfromedge](../../reference/nwfromedge)
has for any edgelist source: a node with zero ties never appears in an edgelist in the first
place, so three isolates were silently dropped in the round trip.

This is exactly what the label set captured above is for. Any label that no longer appears in
either edgelist column, after filtering, was an isolate:

```stata
. levelsof _ego, local(remaininglabels) clean
n1 n10 n11 n12 n14 n15 n16 n17 n18 n19 n2 n21 n22 n23 n24 n25 n26 n27 n28 n29 n3 n30 n31 n32 n33 n34 n35 n36 n37 n
> 38 n39 n4 n40 n41 n42 n43 n44 n45 n46 n48 n49 n5 n6 n7 n8 n9

. levelsof _alter, local(alterlabels) clean
n1 n10 n11 n14 n15 n16 n17 n18 n19 n2 n21 n22 n23 n24 n25 n26 n27 n28 n29 n3 n30 n31 n32 n33 n34 n35 n36 n37 n38 n
> 39 n4 n40 n41 n42 n43 n44 n45 n46 n47 n48 n49 n5 n6 n7 n8 n9

. local remaininglabels : list remaininglabels | alterlabels

. local isolatelabels : list alllabels - remaininglabels

. display "`isolatelabels'"
n13 n20 n50
```

Use [nwaddnodes](../../reference/nwaddnodes) to add those labels back onto `rebuilt` explicitly:

```stata
. nwaddnodes rebuilt, nodenames(n13, n20, n50)

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

`rebuilt` now has all 50 nodes back, with the same 113 ties as before — only the isolates were
missing, never any real structure. `nwaddnodes` is the only way to represent an isolate coming
from edgelist-based input, since an edgelist itself has no way to record a node with zero ties;
see [this open issue](https://github.com/thomas-u-grund/nwcommands/issues/5) for the case for a
more automatic way to do this in `nwtoedge`/`nwfromedge` directly.
