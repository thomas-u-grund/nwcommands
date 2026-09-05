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

[Degree centrality](nwdegree.md)

[Betweenness centrality](nwbetween.md)

[Eigenvector centrality](nwevcent.md)

[Closeness centrality](nwcloseness.md)

[Katz centrality](nwkatz.md)
