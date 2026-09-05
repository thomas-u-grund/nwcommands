---
title: "nwplotmatrix"
parent: "Command reference"
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
[if]
[,
sortby(varname)
group(varname, [connect_options])
label_options
patch_options
twoway_options]
```

| | |
|---|---|
| `labelopt`(*`marker_label_options`*) | options for look of axis labels (e.g. size, color) |
| `tievalue` | show tie values as text inside patches |

## Description

This command plots a network as a sociomatrix. It supports subnetworks specified by the `if` condition. It gives a lot of flexibility to control all elements in a network plot. Furthermore, it is compatible with **schemes()** and accepts all `twoway_options`.

This loads the [Florentine data](netexample) and makes a simple matrix plot.

```stata
. nwwebuse florentine, nwclear
. nwplotmatrix flomarriage, lab
```
The look and feel of the axis labels ca be overwritten with `labelopt()`.

```stata
. nwplotmatrix flomarriage, lab labelopt(labsize(tiny))
```
The following uses the values stored in variable **wealth** as labels.

```stata
. nwplotmatrix flomarriage, label(wealth)
```
Notice that one can also use normal `twoway_options` to control the y-axis and the x-axis independently from each other. For example, the following command produces the same output as the previous command:

```stata
. nwplotmatrix flomarriage, ylabel(,labsize(tiny)) xlabel(,labsize(tiny))
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
All normal `options for lines` can be applied as well.

```stata
. nwplotmatrix flomarriage, group(seat, lcolor(green))
```

## Supported network types

Binary: yes. Directed: yes - the matrix display itself makes asymmetry visible directly (unlike [nwplot](nwplot)'s node-link layout, which needs `arrows` to show direction). Weighted: yes, tie values can drive cell shading/size. Signed: not checked. Two-mode: not checked.

## See also

- [nwplot](nwplot)

- last certified : 25 Aug 2026
