---
title: "The Glasgow friendship movie"
grand_parent: "Book companion"
parent: "Interactive pages from the book"
nav_order: 5
description: "The three waves of the Glasgow friendship network as a movie made with nwmovie, as a page to step through and as a video, with the commands of Chapter 14."
permalink: /book/interactive/glasgow-movie/
---

# The Glasgow friendship movie

*Chapter 14, Animating change.*

The three waves of the Glasgow friendship network, played one after another. Each wave gets its own layout, started
from the positions of the wave before, so the girls drift as the network changes.

<iframe src="../glasgow_movie.html" width="100%" height="650" style="border:1px solid #d0d7de; border-radius:6px;" loading="lazy" title="Movie of the Glasgow friendship network, waves 1 to 3"></iframe>

On a phone or in a narrow window, open the [movie page on its own](../glasgow_movie.html).

```stata
. nwwebuse glasgow, nwclear
. nwmovie glasgow1 glasgow2 glasgow3, fname(glasgow_movie) noopen
```

## The movie as a video

`export()` writes the same movie as a video or an animated GIF, with the format set by the file's extension
(`.mp4`, `.webm` or `.gif`); `duration()` sets the milliseconds for each change from one wave to the next.

<video src="../glasgow.mp4" controls width="100%" style="border:1px solid #d0d7de; border-radius:6px;"></video>

```stata
. nwmovie glasgow1 glasgow2 glasgow3, duration(2000) export(glasgow.mp4) replace
```

`export()` needs nwcommands 3.16.0 or later.

## Source

Data: an excerpt of the Teenage Friends and Lifestyle Study. See the [data sets](../../../datasets/) page.
