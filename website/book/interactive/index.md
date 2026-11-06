---
title: "Interactive pages from the book"
parent: "Book companion"
nav_order: 1
description: "Working copies of the interactive network pages and the network movie that the book Network Analysis with Stata builds with nwplot, interactive and nwmovie, with the commands that wrote them."
permalink: /book/interactive/
---

# Interactive pages from the book
{: .no_toc }

A printed book can show only stills of an interactive page. These are working copies of the pages that the book
*Network Analysis with Stata* (forthcoming, Stata Press) builds, written by the commands printed next to each one.
Every page is a single file with its plotting library inside it. It runs in your browser, does not contact any
server and does not need Stata. What you change on a page is not stored on this site; *Save nodes*, *Save edges*
and *Export PNG* write files to your own computer.

The side panel of a page needs about 900 pixels of width. On a phone, turn it sideways or use a larger screen.

1. TOC
{:toc}

## Chapter 5: Seeing networks

### The Florentine marriage network

The page of the worked example on layouts: pick up the Medici family, put it at the edge of the picture and watch
its six marriage ties stretch across the page. Its betweenness does not change; only the picture does.

[Open the page](florentine_explore.html)

```stata
. nwwebuse florentine, nwclear
. set seed 42
. nwplot flomarriage, label(_nwnode) generate(x y) ///
>     interactive noopen fname(florentine_explore.html)
```

### The advice network of the law firm

The page of the chapter's full workflow: explore in the browser, save the layout, draw the figure in Stata. Color is
the office, shape the practice and size the number of colleagues who ask the lawyer for advice.

[Open the page](lazega_advice_interactive.html) · [the page with a guide to what to try and how to bring the
layout back into Stata](lazega/)

```stata
. nwwebuse lazega, nwclear
. nwdegree lazega_adv, generate(outdeg indeg) silent
. set seed 42
. nwplot lazega_adv, color(office, colorpalette(navy dkorange gs12))  ///
>     symbol(practice) size(indeg) label(_nwnode) edgefactor(0.4)     ///
>     generate(x y) interactive noopen fname(lazega_advice_interactive.html)
```

### Glasgow friendship, wave 1, by smoking (exercise)

The page for the exercise on the Glasgow friendship network: drag the most conspicuous girl to a new place and ask
which impression of the first picture survives the move.

[Open the page](glasgow1_smoke_interactive.html)

```stata
. nwwebuse glasgow, nwclear
. set seed 42
. nwplot glasgow1, color(smoke1, colorpalette(gs12 orange cranberry)) ///
>     label(_nwnode) generate(x y) interactive noopen ///
>     fname(glasgow1_smoke_interactive.html)
```

### The Chesapeake Bay food web (exercise)

The page for the exercise on tie values: move the edge-width slider to its smallest and its largest value. The slider
multiplies every width by the same number, so it cannot do the work of the log transformation.

[Open the page](chesapeake_interactive.html)

```stata
. nwwebuse chesapeake, nwclear
. nwgenerate chesapeake_log = ln(chesapeake + 1)
. set seed 42
. nwplot chesapeake, arcstyle(straight) edgesize(chesapeake_log, legendoff) ///
>     edgefactor(0.5) arrowfactor(0.3) layout(mds) label(_nwnode)       ///
>     generate(x y) interactive noopen fname(chesapeake_interactive.html)
```

## Chapter 14: Networks over time

### The Glasgow friendship movie

The three waves of the Glasgow friendship network, played one after another. On the page, each wave gets its own
layout, started from the positions of the wave before, so the girls drift as the network changes.

[Open the movie page](glasgow_movie.html)

```stata
. nwwebuse glasgow, nwclear
. nwmovie glasgow1 glasgow2 glasgow3, fname(glasgow_movie) noopen
```

The video below is the export of the same movie with one layout for all three waves (`fixedlayout`), so every
visible change is a friendship nomination that was formed or dropped:

<video src="glasgow.mp4" controls width="100%" style="border:1px solid #d0d7de; border-radius:6px;"></video>

```stata
. nwmovie glasgow1 glasgow2 glasgow3, duration(2000) fixedlayout ///
>         export(glasgow.mp4) replace
```

`export()` needs nwcommands 3.16.0 or later.

## Source and licence

- Data: Padgett (1994) and Breiger and Pattison (1986) for the Florentine families; Lazega (2001) and Lazega and van Duijn (1997) for the
  law firm; the Teenage Friends and Lifestyle Study (Glasgow) for the friendship waves; Baird and Ulanowicz (1989)
  for the Chesapeake Bay food web. See the [data sets](../../datasets/) page.
- The pages were produced with nwcommands, which is free software under the GNU General Public License, version 3.
  Each file contains the drawing library Cytoscape.js and other open-source code under the MIT license (the
  notices are in the file).
