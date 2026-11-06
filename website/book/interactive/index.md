---
title: "Interactive pages from the book"
parent: "Book companion"
has_children: true
nav_order: 1
description: "Working copies of the interactive network pages and the network movie that the book Network Analysis with Stata builds with nwplot, interactive and nwmovie, with the commands that wrote them."
permalink: /book/interactive/
---

# Interactive pages from the book
{: .no_toc }

A printed book can show only stills of an interactive page. These are working copies of the pages that the book
*Network Analysis with Stata* (forthcoming, Stata Press) builds, each with the commands that wrote it. Every page
is a single file with its plotting library inside it. It runs in your browser, does not contact any server and does
not need Stata. What you change on a page is not stored on this site; *Save nodes*, *Save edges* and *Export PNG*
write files to your own computer.

**Chapter 5: Seeing networks**

- [The Florentine marriage network](florentine/): move the Medici family and see what a layout can and cannot show.
- [Interactive demo: Lazega advice network](lazega/): the chapter's full workflow, with a guide to what to try and
  how to bring the layout back into Stata.
- [Glasgow friendship, wave 1, by smoking](glasgow-smoking/) (exercise).
- [The Chesapeake Bay food web](chesapeake/) (exercise): why the edge-width slider cannot replace a transformation.

**Chapter 14: Networks over time**

- [The Glasgow friendship movie](glasgow-movie/): the three waves as a page to step through and as a video.

The pages were produced with nwcommands, which is free software under the GNU General Public License, version 3.
Each file contains the drawing library Cytoscape.js and other open-source code under the MIT license (the notices
are in the file).
