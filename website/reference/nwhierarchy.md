---
title: "nwhierarchy"
parent: "Command reference"
grand_parent: "nwcommands (core)"
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
equiv:gen(newvarname)
replace]
nwhierarchy
,
dismat(matname)
[linkage(linkage) groups(int) equiv:gen(newvarname) replace]
nwhierarchy
,
disnet(netname)
[linkage(linkage) groups(int) equiv:gen(newvarname) replace]
```

| | |
|---|---|
| `type`(*[type](nwdissimilar)*) | Type of dissimilarity between two nodes; default = euclidean |
| `context`(*[context](nwdissimilar)*) | Context definition for dissimilarity calculation; default = both |
| `linkage`(*`linkage`*) | Clustering linkage method (e.g. `singlelinkage`, `averagelinkage`, `completelinkage`); default = `singlelinkage` |
| `groups(int)` | Cut the resulting dendrogram into this many role/position equivalence classes, generated as an ordinary Stata variable |
| `equiv:gen(newvarname)` | Name of the variable `groups(int)` generates. **Required whenever `groups(int)` is specified** - give exactly one of `generate()` or `equivgen()` (they are the same option; alias `generate()` matches [nwcommunity](nwcommunity) / [nwspectral](nwspectral)'s own naming in this same group), not both. Has no effect, and is not required, without `groups(int)` |
| `replace` | Replace an existing `equiv:gen(newvarname)` variable |
| `force` | Cluster a network with more than 6,000 nodes (without `dismat()`) |
| *clustermat_options* | Any other option (e.g. `add` or `clear`) is passed on to `clustermat`; `add` is used when neither `add` nor `clear` is given |

## Description

`nwhierarchy` performs hierarchical clustering of a network's nodes based on their pairwise structural dissimilarity (by default, computed the same way [nwdissimilar](nwdissimilar) computes it - see that command's own `type()`/`context()` options, which `nwhierarchy` passes straight through) and returns a Stata `cluster analysis` object built via `clustermat`. The default linkage is **single** (`singlelinkage`); single linkage tends to chain nodes into one large cluster, so consider `linkage(averagelinkage)` or `linkage(completelinkage)`.

`dismat()`, `disnet()`, and `type()`/`context()` are three alternative ways to supply the pairwise dissimilarity `nwhierarchy` clusters on, not independent options - the single `syntax` statement accepts all of them together with no validation, so if more than one is given, only one is actually used: `dismat()` wins if specified at all; otherwise `disnet()` wins if specified; otherwise `type()`/`context()` (computed via [nwdissimilar](nwdissimilar)) is used. The others are silently ignored, not combined or warned about - specify only one.

This is the clustering step of a three-stage **role/position analysis** workflow: [nwdissimilar](nwdissimilar) (or [nwsimilar](nwsimilar), inverted) computes how structurally similar every pair of nodes is; `nwhierarchy` builds a dendrogram from those distances; and `groups(int)` (below) cuts that dendrogram into a fixed number of role/position equivalence classes, generated as an ordinary per-node Stata variable - directly analogous to [nwcomponents](nwcomponents)' own single component-id-variable output, except the partition here is by structural role rather than by connectivity.

`groups(int)`, when specified, additionally cuts the dendrogram into exactly that many groups (via Stata's own `cluster generate ..., groups()`) and stores the result in `equiv:gen(newvarname)` (or its `generate()` alias - one of the two is then required) - one call in place of first working out `clustermat`'s own auto-generated cluster-object name (never itself returned in `r()`, so it cannot otherwise be recovered programmatically) and then calling `cluster generate` by hand. Without `groups(int)`, `nwhierarchy` creates only the cluster object itself (usable with `cluster` and `clustermat`'s own full postestimation suite, e.g. [nwdendrogram](nwdendrogram) or `cluster dendrogram` directly), and no *_role*-style variable is generated.

## Network types

As for [nwdissimilar](nwdissimilar) with `context()` / `type()`; a matrix from `dismat()` or `disnet()` is used as given (not checked to be a dissimilarity matrix). **Two-mode:** not supported (error 6088; use [nwproject](nwproject) first). See [nwnetworktypes](nwnetworktypes).

## Limits

The hierarchical clustering is Stata's `clustermat` on the dense dissimilarity matrix. Measured in Stata/BE, random directed network with 10 ties per node: 1,000 nodes 3 seconds, 2,000 nodes 16 seconds, 3,000 nodes 45 seconds, 5,000 nodes 170 seconds (the dissimilarities themselves take 1 second). 10,000 nodes more than 300 seconds. Above 2,000 nodes the command prints a note; above 6,000 nodes it stops with r(484) unless `force` is given (Stata keeps the dissimilarity matrix as a Stata matrix, at most 11,000 rows in Stata/BE). [nwdendrogram](nwdendrogram) of such a clustering adds the time of the plot.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwhierarchy flomarriage
. cluster dendrogram _clus_1
```
The full role/position workflow, cutting directly to a usable per-node role variable:

```stata
. nwwebuse florentine, nwclear
. nwhierarchy flomarriage, groups(3) generate(_role)
. tab _role
. nwdendrogram _nwhierarchy_role, label(_nwnode)
```
Using a specific dissimilarity type/context, and a custom variable name:

```stata
. nwhierarchy flomarriage, type(hamming) context(outgoing) groups(3) equivgen(role3)
```

## Stored results

`nwhierarchy` is `rclass`. The following are only set when `groups(int)` is specified:

- **Scalars**
- **r(groups)** --- number of role/position groups requested

- **Macros**
- **r(rolevar)** --- name of the generated role/position variable

## See also

- [nwdissimilar](nwdissimilar), [nwsimilar](nwsimilar), [nwcomponents](nwcomponents), `cluster`, `clustermat`,
- [nwdendrogram](nwdendrogram)

---

*nwcommands version 3.25.0, 14 November 2026* ([check your installed version](nwversion))
