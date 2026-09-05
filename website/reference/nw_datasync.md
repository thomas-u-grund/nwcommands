---
title: "nw_datasync"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Utility to sync current network with dataset"
---

# `nw_datasync`

Utility to sync current network with dataset

## Syntax

```stata
nw_datasync 
[netname]
[,
generate(varname)
off
on
overwrite
```

| | |
|---|---|
| `generate`(*`varname`*) | Generate variable that indicates which observations are nodes in current network |
| `off` | Switch datasync off |
| `on` | Switch datasync on; default |
| `overwrite` | Only used for advanced programming |

## Description

Node attributes are saved in the normal Stata dataset. The observations in the dataset correspond to the nodes in a network. Beginning with version 2.0.0 both are automatically matched by the name of the nodes. In the dataset this match is performed on the variable **_nwnode**. In case this variable does not exist, it is automatically created.

Normally, there is no need to explicitly call **nw_datasync**. All other nwcommands that make use of variables in the Stata dataset (e.g. node attributes) sync automatically.

Syncing is relatively fast, hence, there should be no need to switch it off. Furthermore, a sync is only performed when it is actually needed and the sorting of the observations on the variable **_nwnode** does not correspond to the sorting of the nodes in the network. For larger networks it can make sense to switch syncing off. But keep in mind that then it is up to you to make sure that observations correspond to nodes in the network. In this case, the first observation in the dataset is matched with the first node in the network and so on.

## Examples

Generate a variable indicating which dataset observations correspond to nodes in the current network:

```stata
. nwclear
. nwrandom 5, prob(.4) name(mynet)
. nw_datasync mynet, generate(innet)
. list innet
```
- last certified : 22 Aug 2026
