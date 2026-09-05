---
title: "nwdendrogram"
parent: "Command reference"
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

Displays results from hierarchical clustering (see [nwhierarchy](nwhierarchy.md) or `cluster`) as wheel dendrogram.

## Supported network types

Not applicable - visualizes an existing hierarchical-clustering result (from [nwhierarchy](nwhierarchy.md)), not a network directly; whatever directed/valued/two-mode support [nwhierarchy](nwhierarchy.md) itself has already determined the clustering this command displays.
