---
title: "Glasgow friendship, wave 1, by smoking"
grand_parent: "Book companion"
parent: "Interactive pages from the book"
nav_order: 3
description: "Interactive view of the Glasgow friendship network at wave 1, colored by smoking, for the exercise of Chapter 5."
permalink: /book/interactive/glasgow-smoking/
---

# Glasgow friendship, wave 1, by smoking

*Chapter 5, exercise.*

<iframe src="../glasgow1_smoke_interactive.html" width="100%" height="650" style="border:1px solid #d0d7de; border-radius:6px;" loading="lazy" title="Interactive view of the Glasgow friendship network, wave 1"></iframe>

The side panel needs about 900 pixels of width. On a phone or in a narrow window, open the [page on its own](../glasgow1_smoke_interactive.html).

## What to try

Color is smoking at wave 1 (`smoke1`, three levels). Drag the most conspicuous girl to a new place, save the two CSV files and bring the layout back into Stata with `nodexy()`, `importcoords()` and `edgeimport()`. Which impression of the first picture survives the move, and which does not?

## The Stata commands

```stata
. nwwebuse glasgow, nwclear
. set seed 42
. nwplot glasgow1, color(smoke1, colorpalette(gs12 orange cranberry)) ///
>     label(_nwnode) generate(x y) interactive noopen ///
>     fname(glasgow1_smoke_interactive.html)
```

## Source

Data: an excerpt of the Teenage Friends and Lifestyle Study. See the [data sets](../../../datasets/) page.
