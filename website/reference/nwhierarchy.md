---
title: "nwhierarchy"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Hierarchical clustering of nodes (role/position analysis)"
---

# `nwhierarchy`

Hierarchical clustering of nodes (role/position analysis)

## Syntax

```stata
nwhierarchy
[netname]
,
[context(context)
type(type)
linkage(linkage)
groups(int)
equivgen(newvarname)
replace]
nwhierarchy
,
dismat(matname)
[linkage(linkage) groups(int) equivgen(newvarname) replace]
nwhierarchy
,
disnet(netname)
[linkage(linkage) groups(int) equivgen(newvarname) replace]
```

| | |
|---|---|
| `type`(*[type](nwdissimilar.md)*) | Type of dissimilarity between two nodes; default = euclidean |
| `context`(*[context](nwdissimilar.md)*) | Context definition for dissimilarity calculation; default = both |
| `linkage`(*`linkage`*) | Clustering linkage method (e.g. `singlelinkage`, `averagelinkage`, `completelinkage`); default = `singlelinkage` |
| `groups(int)` | Cut the resulting dendrogram into this many role/position equivalence classes, generated as an ordinary Stata variable |
| `equivgen(newvarname)` | Name of the variable `groups(int)` generates; default = *_role*. Ignored unless `groups(int)` is specified (alias: `generate()`, matching [nwcommunity](nwcommunity.md)/[nwspectral](nwspectral.md)'s own naming in this same group) |
| `replace` | Replace an existing `equivgen(newvarname)` variable |

## Description

`nwhierarchy` performs hierarchical clustering of a network's nodes based on their pairwise structural dissimilarity (by default, computed the same way [nwdissimilar](nwdissimilar.md) computes it - see that command's own `type()`/`context()` options, which `nwhierarchy` passes straight through) and returns a Stata `cluster analysis` object built via `clustermat`.

`dismat()`, `disnet()`, and `type()`/`context()` are three alternative ways to supply the pairwise dissimilarity `nwhierarchy` clusters on, not independent options - the single `syntax` statement accepts all of them together with no validation, so if more than one is given, only one is actually used: `dismat()` wins if specified at all; otherwise `disnet()` wins if specified; otherwise `type()`/`context()` (computed via [nwdissimilar](nwdissimilar.md)) is used. The others are silently ignored, not combined or warned about - specify only one.

This is the clustering step of a three-stage **role/position analysis** workflow: [nwdissimilar](nwdissimilar.md) (or [nwsimilar](nwsimilar.md), inverted) computes how structurally similar every pair of nodes is; `nwhierarchy` builds a dendrogram from those distances; and `groups(int)` (below) cuts that dendrogram into a fixed number of role/position equivalence classes, generated as an ordinary per-node Stata variable - directly analogous to [nwcomponents](nwcomponents.md)' own single component-id-variable output, except the partition here is by structural role rather than by connectivity.

`groups(int)`, when specified, additionally cuts the dendrogram into exactly that many groups (via Stata's own `cluster generate ..., groups()`) and stores the result in `equivgen(newvarname)` (default *_role*) - one call in place of first working out `clustermat`'s own auto-generated cluster-object name (never itself returned in `r()`, so it cannot otherwise be recovered programmatically) and then calling `cluster generate` by hand. Without `groups(int)`, `nwhierarchy` behaves exactly as before - only the cluster object itself is created (usable with `cluster` and `clustermat`'s own full postestimation suite, e.g. [nwdendrogram](nwdendrogram.md) or `cluster dendrogram` directly), and no *_role*-style variable is generated.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwhierarchy flomarriage
. cluster dendrogram _clus_1
```
The full role/position workflow, cutting directly to a usable per-node role variable:

```stata
. nwwebuse florentine, nwclear
. nwhierarchy flomarriage, groups(3)
. tab _role
. nwdendrogram _nwhierarchy_role, label(_nwnode)
```
Using a specific dissimilarity type/context, and a custom variable name:

```stata
. nwhierarchy flomarriage, type(hamming) context(outgoing) groups(3) equivgen(role3)
```

## Supported network types

Same network-type support as the underlying dissimilarity computation - see [nwdissimilar](nwdissimilar.md)'s own "Supported network types" section when using the default `context()`/`type()` form. The `dismat()` and `disnet()` forms bypass `nwdissimilar` entirely and use whatever matrix/network you supply directly - `nwhierarchy` does not itself validate that it is a genuine dissimilarity matrix (symmetric, zero diagonal, nonnegative). Stata's own `clustermat` (which does the actual clustering) requires a matrix with no missing values, including on the diagonal.

## Stored results

`nwhierarchy` is `rclass`. The following are only set when `groups(int)` is specified:

**Scalars**

- **r(groups)** number of role/position groups requested

**Macros**

- **r(rolevar)** name of the generated role/position variable

## See also

- [nwdissimilar](nwdissimilar.md), [nwsimilar](nwsimilar.md), [nwcomponents](nwcomponents.md), `cluster`, `clustermat`,
- [nwdendrogram](nwdendrogram.md)

- last certified : 24 Aug 2026
