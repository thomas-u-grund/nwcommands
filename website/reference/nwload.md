---
title: "nwload"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Load a network as Stata variables"
---

# `nwload`

Load a network as Stata variables

## Syntax

```stata
nwload
[netname]
[,
xvars
nocurrent
labelonly
generate(varname)
viewon
viewoff
overwrite
force]
```

| | |
|---|---|
| `xvars` | Run only a lightweight [nw_datasync](nw_datasync.md) sync and exit immediately - does NOT itself
materialize the adjacency-matrix Stata variables the way a bare `nwload` call does; despite the
similar name, this is a different operation from the `xvars` option other nwcommands (network
generators) offer |
| `nocurrent` | Only load network as Stata variables, but do not make it the *current network* |
| `labelonly` | Only load the node labels as Stata variable |
| `generate(varname)` | Generate flag for nodes of the loaded network; default = *_nwinclude* |
| `viewoff` | Unconnect view from network to dataset; default |
| `viewon` | Establish view of network to dataset |
| `overwrite` | Forwarded to [nw_datasync](nw_datasync.md)'s own `overwrite` option; only used for advanced programming |
| `force` | By default, matrix is not loaded for networks with more than 1000 nodes unless **force** is specified |

## Description

Networks exist as objects in Mata. Once a networks have been imported, generated or set, one can interact with them by referring to their [netname](netname.md), just as if one would interact with variables using their `varname`.

Networks have various meta-information, such as node labels (see [nwname](nwname.md)). Each network also has information about a set of Stata variables that should be created to represent the network as Stata variables. **nwset, detail** shows this information for all networks.

The meta-data of a network (including the variables that should be used to load the network) can be changed with [nwname](nwname.md).

The command **nwload** loads a network as Stata variables. By doing so, the command generates a set of Stata variables (the names of these variables are stored in the meta-information for a network) and populates these variables with the adjaceny matrix of the network.

An adjacency matrix is a simple representation of a network. The adjaceny matrix *M* of a network has the dimensions *nodes x nodes*. The matrix cell *M_ij* = 0 when there is no tie between nodes *i* and *j*. In binary networks, *M_ij* = 1 when there is a network relationship between nodes *i* and *j*. However, networks can also be valued, i.e. *M_ij* > 1. Some nwcommands support valued networks.

Loading a network as Stata variables can be useful if one wants to interact with (or look at) the network through the dataset. But notice that changing one of the Stata variables does not change the underlying network, unless a view of the network to the dataset is established with the option **viewon**. But be careful, establishing such a view can also lead to unintended changes of an underlying network. The option **viewoff** reverts back and unconnects a network from a view on the dataset. To change values of the underlying network directly use [nwreplace](nwreplace.md) instead.

For example, if one were to import/use a network with 16 nodes and drop all Stata variables, **nwload** would create exactly 16 variables and 16 cases.

```stata
. nwwebuse florentine, nwclear
. drop _all
. nwload flomarriage
```
All Stata variables can be deleted without deleting the underlying networks (except when a network is established as a view on the dataset with option **viewon**; see above). With **nwload** a network can always be brought back as Stata variables. In case the variables already exist, they are overwritten. If one wants to permanently drop a network one needs to use [nwdrop](nwdrop.md) or [nwclear](nwclear.md) (very similar to how one would drop or clear normal variables).

**nwload** not only loads the adjacency matrix as variables, but also generates (or overwrites) the variable *_nwnode*. This variable identifies nodes. When the network is two-mode (see [introduction to two-mode networks](nw2set.md)), the command also creates the variable *_nwmode*. Lastly, the command generates (or overwrites) the variable *_nwinclude* (unless option opt:generate() specifies another variable name. This variable indicates which nodes are part of the network that has been loaded.

Nodes and node attributes are represented as observations in the dataset and are matched with the variable *_nwnode*. Whenever a nwcommand uses or produces node-level attributes it matches the nodes with the observations.

One can only load the node labels of a network as a Stata variable with the option **labelsonly** (this does neither load the adjacency matrix of a network as Stata variables nor other information, but just creates the variable *_nwnode*).

For example, one can plot the Florentine marriage network and label the nodes accordingly with:

```stata
. nwwebuse florentine, nwclear
. nwplot flomarriage, label(_nwnode)
```
Furthermore, **nwload** makes [netname](netname.md) the current network, unless option **nocurrent** is specified. Many nwcommands (although they do something with a network) do not require a network name. In the cases where no [netname](netname.md) is specified, a nwcommand automatically runs with the [current network](nwcurrent.md). For programming your own network commands with this feature see `nw_syntax`.

By default, commands that generate a network (see [network generator](nw_topical.md)) do NOT also load the network as Stata variables - creating a network never silently spends Stata's own variable budget. Most network generators have the option **xvars**, which DOES invoke **nwload** after creating the new network, generating its Stata variables immediately. This is convenient for a single network at a time, but can exhaust Stata's variable limit if used while generating many networks at once.

For example this code generates 1000 random networks with 100 nodes each without ever loading any of them as Stata variables (the default - **xvars** is NOT specified). Afterwards, **nwload** is used to load just one (the current network, here, the last random network that has been generated) as Stata variables.

```stata
. nwrandom 100, prob(.1) ntimes(1000)
. nwload
```
Notice that `nwload` does not import or create a network, it simply creates Stata variables to represent a network. Only networks that already do exist in Stata, i.e. have been set by [nwset](nwset.md) or imported by [nwimport](nwimport.md) or [nwuse](nwuse.md) or [nwwebuse](nwwebuse.md) or created by a [network generator](nw_topical.md), can be loaded as Stata variables. If two different networks use the same variable names, the Stata variables are overwritten.

## Supported network types

Binary: yes. Directed: yes. Weighted: yes. Signed: yes. Two-mode: yes - loads the network's own stored data into Stata variables exactly as stored, independent of any of these properties.

## See also

- [nwcurrent](nwcurrent.md), [nwsync](nwsync.md), [nwuse](nwuse.md), [nwimport](nwimport.md), [feasible network sizes](nw_intro.md)

- last certified : 25 Aug 2026
