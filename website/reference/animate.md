---
title: "animate"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Animate graphs"
---

# `animate`

Animate graphs

## Syntax

```stata
animate 
filename
,
graphs(_all | g1 g2 g3...)
[imagickpath(path) delay(#) noloop showcommand keepeps mag(#)]
```

**Required**

| | |
|---|---|
| `graphs(_all \| g1 g2 g3...)` | graphs to be added to the movie |

**Optional**

| | |
|---|---|
| `imagickpath(path)` | path of ImageMagick |
| `delay(#)` | delay between frames in hundredths of a second; default is `delay(50)` |
| `noloop` | no loop of movie |
| `showcommand` | display ImageMagick command |
| `keepeps` | keep .eps files |
| `mag(#)` | magnification of the .eps files, in percent (`graph export`'s `mag()`); default is `mag(100)` |

## Description

`animate` produces .eps files for each graph and adds them together to an animated-gif `filename`. Command requires [ImageMagick](http://www.imagemagick.org/) to be installed on the computer.

## Examples

```stata
. webuse uslifeexp
. graph drop _all
. forvalues i = 1900(10)2000 {
      scatter le year if year <= `i', xscale(range(1900 2000)) name(le`i')
}
. animate lifemovie, graphs(_all)
```

---

*nwcommands version 3.23.0, 13 November 2026* ([check your installed version](nwversion))
