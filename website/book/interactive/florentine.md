---
title: "The Florentine marriage network"
grand_parent: "Book companion"
parent: "Interactive pages from the book"
nav_order: 1
description: "Interactive view of the Florentine marriage network: drag the Medici family to the edge and see what changes in the picture and what does not."
permalink: /book/interactive/florentine/
---

# The Florentine marriage network

*Chapter 5, worked example on layouts.*

<iframe src="../florentine_explore.html" width="100%" height="650" style="border:1px solid #d0d7de; border-radius:6px;" loading="lazy" title="Interactive view of the Florentine marriage network"></iframe>

The side panel needs about 900 pixels of width. On a phone or in a narrow window, open the [page on its own](../florentine_explore.html).

## What to try

Pick up the Medici family and put it at the edge of the picture. Its six marriage ties stretch across the page and the family looks peripheral, yet its betweenness (47.5) is the same number as before. Only the position of one point has changed: a picture can illustrate what a measure has shown, but it cannot show it.

## The Stata commands

```stata
. nwwebuse florentine, nwclear
. set seed 42
. nwplot flomarriage, label(_nwnode) generate(x y) ///
>     interactive noopen fname(florentine_explore.html)
```

## Source

Data: Padgett, J. F. (1994), *Marriage and Elite Structure in Renaissance Florence, 1282-1500*; Breiger, R. and Pattison, P. (1986), *Social Networks* 8, 215-256. See the [data sets](../../../datasets/) page.
