---
title: "nwdendrogram"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Plot a wheel dendrogram"
---

# `nwdendrogram`

Plot a wheel dendrogram

## Syntax

```stata
nwdendrogram
[clname] 
[, options twoway_options]
```

## Description

Displays results from hierarchical clustering (see [nwhierarchy](nwhierarchy) or `cluster`) as wheel dendrogram. The cluster levels must be nested in each other; when they are not, the command stops with error 459. An error of the graph itself (for example an option that `twoway` does not know) is shown and returned.

## Network types

The command works the same for every network type (see [nwnetworktypes](nwnetworktypes)).

## Example

```stata
. nwwebuse florentine, nwclear
. nwhierarchy flomarriage
. nwdendrogram _clus_1
```

---

*nwcommands version 3.25.0, 14 November 2026* ([check your installed version](nwversion))
