---
title: "nwexpand"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Expand variable to network"
---

# `nwexpand`

Expand variable to network

## Syntax

```stata
nwexpand 
varname [if]
,
[mode(mode)
network(netname)
nodes(int)
name(newnetname)
xvars
labs(lab1 lab2 ...)
replace]
```

| | |
|---|---|
| `mode`(*[mode](nwexpand)*) | mode used to expand variable; default = *same* |
| `network`(*[netname](netname)*) | apply node labels of *netname* |
| `nodes(int)` | size of new network; default = `_N` - an explicit `nodes(1)` for a genuine 1-node network is honored, distinct from leaving `nodes()` unspecified |
| `name`(*[newnetname](newnetname)*) | name of the new random network; default = *[mode](nwexpand)_varname* |
| `xvars` | generate Stata variables for the network |
| `labs`(*lab1 lab2 ...*) | overwrite node labels |
| `replace` | if a network named *newnetname* already exists, drop it and use this name anyway (see [nwset](nwset) for the same convention) |

## Description

This command generates a new network by expanding an existing variable. When option **nodes()** is unspecified, the command generates a network with `_N` nodes.

The value *M_ij* of the adjacency matrix *M* of the new network is calculated from the values `varname`**[i]**, `varname`**[j]** and some function *expfcn* defined by *[mode](nwexpand)*. By default, *mode = same*.

Valid modes are: **same, dist, distinv, absdist, absdistinv, sender, receiver**

The option **network(**[netname](netname)**)** applies the node labels of *netname* when expanding the variable. Often specifying this option is needed.

An example demonstrates how this works. First, we generate a small dataset with 6 observations and the new variable * gender*. This new variable takes the value 0 for observations 1-3 and the value 1 for observations 4-6.

```stata
. nwclear
. set obs 6
. gen gender = (_n > 3)
. list gender
```
- hline 8
- c | gender c |
- hline 8
- 1. c | 0 c |
- 2. c | 0 c |
- 3. c | 0 c |
- 4. c | 1 c |
- 5. c | 1 c |
- hline 8
- 6. c | 1 c |
- hline 8

Next, we use *nwexpand* to generate a new network from this variable. This generate a new network called *same_gender*.

```stata
. nwexpand gender
```
By looking closer at the adjacency matrix *M* of this new network we see how the default *exp_fcn = same* generated the entries *M_ij* as:

*M_ij = (varname[i] == varname[j])*.

- . nwsummarize same_gender, matonly

- 1 2 3 4 5 6
- hline 25
- 1 c | 0 c |
- 2 c | 1 0 c |
- 3 c | 1 1 0 c |
- 4 c | 0 0 0 0 c |
- 5 c | 0 0 0 1 0 c |
- 6 c | 0 0 0 1 1 0 c |
- hline 25

Alternatively, let us select another mode to illustrate the difference. This command generates a new network called *dist_gender* with the following adjacency matrix:

*M_ij = (varname[i] - varname[j])*.

```stata
. nwexpand gender, mode(dist)
. nwsummarize dist_gender, matonly
```
- 1 2 3 4 5 6
- hline 31
- 1 c | 0 0 0 -1 -1 -1 c |
- 2 c | 0 0 0 -1 -1 -1 c |
- 3 c | 0 0 0 -1 -1 -1 c |
- 4 c | 1 1 1 0 0 0 c |
- 5 c | 1 1 1 0 0 0 c |
- 6 c | 1 1 1 0 0 0 c |
- hline 31

Generally, creating networks like this can be extremely useful for many purposes. For example, one can use it to plot the edgecolors of ties differently when two nodes have the same value on some attribute. This example loads the *gang* network and plots the color of ties in such a way that it shows if two gang members (who co-offend with each other) were either 1) both in prison before or 2) both not in prison before.

```stata
. nwwebuse gang, nwclear
. nwexpand Prison, network(gang)
. nwplot gang, edgecolor(same_Prison)
```
Notice how here the we need to specify the option **network(gang)**. Otherwise, **nwepxand** does not know that the labels of the gang network should be applied and it would consequently treat it is a completeley different network.

The next example loads the *glasgow* dataset and colors ties differently depending on whether the sender of a friendship tie did sport at wave1.

```stata
. nwwebuse glasgow, nwclear
. nwexpand sport1, mode(sender) network(glasgow1)
. nwplot glasgow1, edgecolor(sender_sport1)
```

## Supported network types

Binary: source attribute values can be binary or continuous - `mode()` selects the transform. Directed: not applicable - produces a new derived network from a node attribute, not from an existing network's own directed status. Weighted: yes, natively - every `mode()` choice (same/dist/absdist/distinv/absdistinv/sender/receiver) produces continuous-valued ties by construction. Signed: yes, `mode(dist)` in particular can produce negative values. Two-mode: not applicable - produces a one-mode network from node-level attribute comparisons.

## See also

- [nwcorrelate](nwcorrelate)

- last certified : 24 Aug 2026
