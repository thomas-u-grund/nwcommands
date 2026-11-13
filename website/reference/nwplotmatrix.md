---
title: "nwplotmatrix"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Plot a network as sociomatrix"
---

# `nwplotmatrix`

Plot a network as sociomatrix

## Syntax

```stata
nwplotmatrix
[netname] 
[,
sortby(varname)
group(varname, [connect_options])
label_options
patch_options
twoway_options]
```

| | |
|---|---|
| `tievalue` | show tie values as text inside patches |

## Description

This command plots a network as a sociomatrix. To plot a part of a network, make it first with [nwsubset](nwsubset). It gives a lot of flexibility to control all elements in a network plot. Furthermore, it is compatible with **schemes()** and accepts all `twoway_options`.

This loads the [Florentine data](netexample) and makes a simple matrix plot.

```stata
. nwwebuse florentine, nwclear
. nwplotmatrix flomarriage, lab
```
The look and feel of the axis labels can be changed with the `twoway_options` `ylabel()` and `xlabel()`:

```stata
. nwplotmatrix flomarriage, lab ylabel(,labsize(tiny)) xlabel(,labsize(tiny))
```
The following uses the values stored in variable **wealth** as labels.

```stata
. nwplotmatrix flomarriage, label(wealth)
```
The y-axis and the x-axis can be controlled independently from each other, for example:

```stata
. nwplotmatrix flomarriage, lab ylabel(,labsize(tiny)) xlabel(,labsize(vsmall))
```
It can be useful to sort the nodes of the network before plotting a sociomatrix. This example sorts the nodes according to the values in variable *wealth*.

```stata
. nwplotmatrix flomarriage, label(wealth) sortby(wealth)
```
The command accepts all normal `twoway_options`, e.g.

```stata
. nwplotmatrix flomarriage, scheme(s1mono) title("mynet")
```
One can also overwrite the colors used for the plot:

```stata
. nwplotmatrix flomarriage, scheme(s1mono) colorpalette(black) background(yellow) lcolor(red)
```
The command also allows to display the tie values inside the patches. The look and feel of these values is controlled with ** tievalueopt()**.

```stata
. nwplotmatrix flomarriage, tievalue
. nwplotmatrix flomarriage, tievalue tievalueopt(mlabsize(tiny) mlabcolor(yellow))
```
The option `group(varname)` sorts the nodes by `varname` first and then adds lines to the sociomatrix to separate groups from each other. The example generates the variable seat, which is one when a family had some seats in the council.

```stata
. nwplotmatrix flomarriage, group(seat)
```
If the group variable has names (a string variable, or a value label), the name of each group is written beside its block, at the top and at the left, unless node labels are shown (`lab` or `label()`); `nogrouplabels` leaves the names out. A numeric group variable without a value label gets no names. The lines between the groups are drawn medium thick.

All normal `options for lines` can be applied as well.

```stata
. nwplotmatrix flomarriage, group(seat, lcolor(green))
```

## Network types

**Directed:** the matrix shows asymmetry directly. **Valued:** the legend names the value classes of the cells ('no tie' and 'tie' on a binary network); `tievalue` prints the values. **Two-mode:** yes - the nodes of one mode are placed together (unless `sortby()` or `group()`) and a line separates the modes. **Signed:** negative values are not treated specially. See [nwnetworktypes](nwnetworktypes).

## Limits

One box (five points) is drawn for every pair of nodes, so memory and time grow with the square of the number of nodes: 1,000 nodes 5 seconds and 0.8 GB, 2,000 nodes 19 seconds and 2.6 GB. Networks of more than 2,500 nodes are refused; plot a part of the network or use [nwplot](nwplot).

## See also

- [nwplot](nwplot)

---

*nwcommands version 3.22.0, 13 November 2026* ([check your installed version](nwversion))
