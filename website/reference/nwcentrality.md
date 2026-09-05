---
title: "nwcentrality"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Node centrality measures"
---

# `nwcentrality`

Node centrality measures

## Examples

Each measure below is computed by its own dedicated command - for example, degree centrality:

```stata
. nwwebuse florentine, nwclear
. nwdegree flomarriage, generate(deg)
. list deg in 1/5
```
**See**

[Degree centrality](nwdegree)

[Betweenness centrality](nwbetween)

[Eigenvector centrality](nwevcent)

[Closeness centrality](nwcloseness)

[Katz centrality](nwkatz)
