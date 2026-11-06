---
title: "The Chesapeake Bay food web"
grand_parent: "Book companion"
parent: "Interactive pages from the book"
nav_order: 4
description: "Interactive view of the Chesapeake Bay food web with tie widths from the log of the carbon flow, for the exercise of Chapter 5."
permalink: /book/interactive/chesapeake/
---

# The Chesapeake Bay food web

*Chapter 5, exercise.*

<iframe src="../chesapeake_interactive.html" width="100%" height="650" style="border:1px solid #d0d7de; border-radius:6px;" loading="lazy" title="Interactive view of the Chesapeake Bay food web"></iframe>

The side panel needs about 900 pixels of width. On a phone or in a narrow window, open the [page on its own](../chesapeake_interactive.html).

## What to try

Tie width is the log of the carbon flow plus one. Move the edge-width slider to its smallest and to its largest value and describe what changes. The slider multiplies every width by the same number, so the ratio of the widest to the narrowest tie stays as it is: it cannot do the work of the log transformation.

## The Stata commands

```stata
. nwwebuse chesapeake, nwclear
. nwgenerate chesapeake_log = ln(chesapeake + 1)
. set seed 42
. nwplot chesapeake, arcstyle(straight) edgesize(chesapeake_log, legendoff) ///
>     edgefactor(0.5) arrowfactor(0.3) layout(mds) label(_nwnode)       ///
>     generate(x y) interactive noopen fname(chesapeake_interactive.html)
```

## Source

Data: Baird, D. and Ulanowicz, R. E. (1989), *Ecological Monographs* 59, 329-364. See the [data sets](../../../datasets/) page.
