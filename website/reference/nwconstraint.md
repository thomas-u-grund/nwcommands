---
title: "nwconstraint"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Burt's constraint"
---

# `nwconstraint`

Burt's constraint

## Syntax

```stata
nwconstraint
[netname]
[,
name(newnetname)
replace
nwset_options]
name() names the new network and replace overwrites an existing network of that name. The
other nwset_options are any options accepted by nwset's mat() form (e.g.
undirected, directed); they are forwarded unchanged to the internal
nwset, mat() call that stores the result.
```

## Description

Calculates Burt's (1992) dyadic constraint for a [network](netname) and stores the result as a new [network](netname) (not a Stata variable) via `nwset, mat()` - the constraint matrix becomes the current network afterward. This is a different output shape than most other analysis commands in this package (which `generate()` a per-node Stata variable): `nwconstraint` returns the full dyadic *c_ij* matrix. [nwburt](nwburt) computes the standard per-node aggregate constraint (and Burt's related effective size/efficiency/hierarchy measures) directly as Stata variables - use it instead of this command if the dyadic matrix itself isn't what you need; see the "Aggregating to the node level" note below for why a plain row sum of this command's own output is **not** equivalent to [nwburt](nwburt)'s aggregate.

Constraint measures the extent to which a node *i*'s relationships are concentrated through a single contact or a tightly interconnected group of contacts, rather than spread across independent, unconnected contacts (the latter is Burt's "structural holes" - low constraint, high brokerage potential). Formally, for each pair *i,j*:

*p_ij = a_ij / sum_k(a_ik)*  (i's tie to j, as a proportion of all of i's outgoing ties)

*c_ij = (p_ij + sum_q(p_iq * p_qj))^2*  (direct investment in j, plus indirect investment via every other contact *q*)

The diagonal (self-constraint) is not meaningful and is not part of the returned network.

**Aggregating to the node level**: the quantity most commonly reported in the literature as "Burt's constraint" is node *i*'s aggregate constraint, *C_i = sum_j(c_ij)* for *j* in *i*'s direct contacts only - **not** summed over every *j*. This distinction matters because *c_ij* can be nonzero even when *i* and *j* are not directly tied at all (the *sum_q(p_iq*p_qj)* indirect term alone can make it positive), so naively summing an entire row of this command's output - *sum_j(c_ij)* over **all** *j* - silently over-counts and gives a different, larger number than the standard aggregate for any node with such indirect-only contributions. [nwburt](nwburt) computes the correctly-restricted aggregate directly (as *_constraint*); this command intentionally does not, since restricting the sum to *N(i)* requires already knowing which entries of the raw network matrix are direct ties, which is exactly the extra step [nwburt](nwburt) takes care of.

## Network types

**Directed:** not symmetrized - p_ij uses outgoing ties only, so a node without outgoing ties has zero constraint. **Valued:** tie values are used as Burt's investment proportions. **Two-mode:** same as for the bipartite graph read as a one-mode network. **Signed:** not supported - negative values distort p_ij (values outside [0,1]). See [nwnetworktypes](nwnetworktypes).

## Limits

The result is a dense *n*-by-*n* network. 20,000 nodes: 9 seconds in Stata/BE.

Above 2,000 nodes a network held as stored ties gets its constraint network from the list of its cells that are not zero (the direct ties and the two-step paths, about the sum of the squared degrees), without an *n*-by-*n* matrix; only `name()` and `replace` are accepted then. Measured in Stata/BE with 5 ties drawn per node (mean degree 10 when undirected) and 100,000 nodes: 0.7 seconds for a directed network and 2.2 seconds for an undirected one (11 million cells).

For all commands at network sizes of 1,000 to 100,000 nodes see the web page [How large a network can I analyze?](https://nwcommands.org/nwcommands/size-limits/)

The cells are computed in the compiled graph plugin (the native kernel of `nwcommands`) when the plugin of your platform has it, and in Mata otherwise; both give the same values (to the last digits). The kernel itself takes about one second at 100,000 nodes with mean degree 10; the rest of the time of a large network (1 second in Stata/BE for an undirected network) goes into storing the result as a network.

## Examples

```stata
. nwwebuse gang, nwclear
. nwconstraint gang, name(gangconstraint)
. nwtomata gangconstraint, mat(C)
. nwtomata gang, mat(A)
. mata: rowsum(C :* (A :!= 0 :& A :< .))
```

## References

Ronald S. Burt (1992). *Structural Holes: The Social Structure of Competition*. Harvard University Press.

## See also

- [nwburt](nwburt), [nwdegree](nwdegree), [nwbetween](nwbetween), [nwcloseness](nwcloseness), [nwevcent](nwevcent), [nwclustering](nwclustering)

---

*nwcommands version 3.22.0, 13 November 2026* ([check your installed version](nwversion))
