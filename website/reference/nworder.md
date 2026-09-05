---
title: "nworder"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Reorder networks in dataset"
---

# `nworder`

Reorder networks in dataset

## Syntax

```stata
nworder
netlist
[, 
options]
```

## Description

`nworder` relocates [netlist](netlist) to a position depending on which option you specify. If no option is specified, `nworder` relocates *netlist* to the **beginning** of the dataset in the order in which the variables are specified - matching plain Stata's own `order` command, which `nworder` is a thin wrapper around.

The command is useful when one wants to do bulk-operations with networks and when the network order matters (e.g. when making a movie out of _all networks, see [nwmovie](nwmovie)).

## Options

`last` shifts [netlist](netlist) to the end of the dataset.

`first` shifts [netlist](netlist) to the beginning of the dataset.  This is the default.

`before(netname)` shifts varlist before *netname*.

`after(netname)` shifts varlist after *netname*.

`alphabetic` alphabetizes [netlist](netlist) and moves it to the beginning of the dataset.  For example, here is a netlist in `alphabetic` order: `a x7 x70 x8 x80 z`.  If combined with another option, `alphabetic` just alphabetizes *varlist*, and the movement of *netlist* is controlled by the other option.

`sequential` alphabetizes [netlist](netlist), keeping netnames with the same ordered letters but with differing appended numbers in sequential order. *netlist* is moved to the beginning of the dataset.  For example, here is a netlist in `sequential` order: `a x7 x8 x70 x80 z`.

## Examples

**Setup**

- `. nwwebuse florentine`

- Describe the networks
- `. nwds`

- Move `flobusiness` to the beginning of the dataset
- `. nworder flobusiness`

- Describe the networks
- `. nwds`

- Make `flobusiness` the last network in the dataset
- `. nworder flobusiness, last`

- Describe the networks
- `. nwds`

- Alphabetize the networks
- `. nworder flomarriage flobusiness, alphabetic`

- Describe the networks
- `. nwds`

## Supported network types

Binary: yes. Directed: yes. Weighted: yes. Signed: yes. Two-mode: yes - reorders which networks occupy which position in the dataset only; does not read or depend on any network's own directed/valued/two-mode status or tie values.

## See also

- [nwds](nwds), `order`, [netlist](netlist)
