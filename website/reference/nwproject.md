---
title: "nwproject"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "One-mode projection of a two-mode network (alias for [nw2project](nw2project.md))"
---

# `nwproject`

One-mode projection of a two-mode network (alias for [nw2project](nw2project.md))

## Syntax

```stata
nwproject
[netname]
,
project(1|2)
[name(newnetname)
stat(string)
xvars
replace]
```

## Description

`nwproject` is an exact alias for [nw2project](nw2project.md) - it forwards every argument and option unchanged and returns the identical stored results. It exists purely for discoverability: unlike [nw2set](nw2set.md)/[nw2fromedge](nw2fromedge.md)/[nw2toedge](nw2toedge.md)/[nw2degree](nw2degree.md)/[nw2clustering](nw2clustering.md) (whose `nw2` prefix genuinely disambiguates a one-mode command from a same-purpose two-mode-specific sibling), a one-mode `nwproject` could never exist - projecting only makes sense starting from a two-mode source - so there is no ambiguity for the `nw2` prefix to resolve here, only an unnecessary naming inconsistency with the rest of the "transformation grammar" family ([nwcollapse](nwcollapse.md), [nwexpand](nwexpand.md), [nwfromedge](nwfromedge.md), [nwtoedge](nwtoedge.md)), none of which carry a `nw2` prefix. [nw2project](nw2project.md) itself is unaffected and remains fully supported - see its own help file for the complete option reference, the `stat()` formulas, and worked examples.

## Examples

Build a small two-mode network (3 people x 2 events) and project it onto mode 1 (people):

```stata
. nwclear
. mata: net = (1,0 \ 1,1 \ 0,1)
. nw2set, mat(net) name(attendance)
. nwproject attendance, project(1) name(people_net)
. nwsummarize people_net, matonly
```

## Supported network types

Identical to [nw2project](nw2project.md) - see that command's help file.

## Stored results

See [nw2project](nw2project.md).

- last certified : 28 Aug 2026
