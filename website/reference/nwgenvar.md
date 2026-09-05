---
title: "nwgenvar"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Network extensions to generate"
---

# `nwgenvar`

Network extensions to generate

## Syntax

```stata
nwgenvar newvar = netfcn1(arguments) [, options]
nwgenvar newnetname = netfcn2(arguments) [, options]
nwgenvar newnetname = netexp [if] [, options]
		
where the options are also fcn dependent.
```

## Description

These are network extensions to `generate`. The command is very similar to `egen` and allows producing either variables or networks. There are basically three ways to use this commands: 1) produce Stata variables with some function ***netfcn1***, 2) produce networks with some function ***netfnc2***, 3) produce networks with an expression ***netexp***. A network expression is very similar to normal expressions in Stata.

## Examples

Generate a per-node variable with a network function:

```stata
. nwwebuse florentine, nwclear
. nwgenvar mydeg = degree(flomarriage)
. list mydeg in 1/5
```
Generate a new network with a network function:

```stata
. nwgenvar newnet = random(10), prob(.3)
. nwsummarize newnet
```

## Supported network types

Not applicable to `nwgenvar` itself - a dispatcher/shortcut layer over [nwgenerate](nwgenerate.md); the actual directed/valued/two-mode support depends entirely on whichever underlying *netfcn1*/*netfcn2* shortcut or network expression is invoked - see that function's own help topic.
