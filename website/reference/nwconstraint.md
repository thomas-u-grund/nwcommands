---
title: "nwconstraint"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Calculate Burt's constraint"
---

# `nwconstraint`

Calculate Burt's constraint

## Syntax

```stata
nwconstraint
[netname]
[,
nwset_options]
where nwset_options are any options accepted by nwset's mat() form (e.g.
name(), undirected, directed) - they are forwarded unchanged to the internal
nwset, mat() call that stores the result.
```

## Description

Calculates Burt's (1992) dyadic constraint for a [network](netname.md) and stores the result as a new [network](netname.md) (not a Stata variable) via `nwset, mat()` - the constraint matrix becomes the current network afterward. This is a different output shape than most other analysis commands in this package (which `generate()` a per-node Stata variable): `nwconstraint` returns the full dyadic *c_ij* matrix. [nwburt](nwburt.md) computes the standard per-node aggregate constraint (and Burt's related effective size/efficiency/hierarchy measures) directly as Stata variables - use it instead of this command if the dyadic matrix itself isn't what you need; see the "Aggregating to the node level" note below for why a plain row sum of this command's own output is **not** equivalent to [nwburt](nwburt.md)'s aggregate.

Constraint measures the extent to which a node *i*'s relationships are concentrated through a single contact or a tightly interconnected group of contacts, rather than spread across independent, unconnected contacts (the latter is Burt's "structural holes" - low constraint, high brokerage potential). Formally, for each pair *i,j*:

*p_ij = a_ij / sum_k(a_ik)*  (i's tie to j, as a proportion of all of i's outgoing ties)

*c_ij = (p_ij + sum_q(p_iq * p_qj))^2*  (direct investment in j, plus indirect investment via every other contact *q*)

The diagonal (self-constraint) is not meaningful and is not part of the returned network.

**Aggregating to the node level**: the quantity most commonly reported in the literature as "Burt's constraint" is node *i*'s aggregate constraint, *C_i = sum_j(c_ij)* for *j* in *i*'s direct contacts only - **not** summed over every *j*. This distinction matters because *c_ij* can be nonzero even when *i* and *j* are not directly tied at all (the *sum_q(p_iq*p_qj)* indirect term alone can make it positive), so naively summing an entire row of this command's output - *sum_j(c_ij)* over **all** *j* - silently over-counts and gives a different, larger number than the standard aggregate for any node with such indirect-only contributions. [nwburt](nwburt.md) computes the correctly-restricted aggregate directly (as *_constraint*); this command intentionally does not, since restricting the sum to *N(i)* requires already knowing which entries of the raw network matrix are direct ties, which is exactly the extra step [nwburt](nwburt.md) takes care of.

## Examples

```stata
. nwwebuse gang, nwclear
. nwconstraint gang, name(gangconstraint)
. nwtomata gangconstraint, mat(C)
. nwtomata gang, mat(A)
. mata: rowsum(C :* (A :!= 0 :& A :< .))
```

## Supported network types

Binary: yes. Directed: yes, but not symmetrized - *p_ij* is computed from the raw adjacency matrix exactly as given, so a directed network's constraint reflects outgoing ties only (a node with no outgoing ties at all has *p* entirely zero, and therefore zero constraint toward everyone, regardless of its incoming ties). This is a real, asymmetric treatment of directed data - not a symmetrized "Burt" constraint in the traditional (undirected) sense - and is the command's actual behavior, not silently assumed. Weighted: **W1**, native - tie weight is used directly as *p_ij*'s investment proportion (exactly Burt's own interpretation of tie strength), not as a distance. Signed: not supported - *p_ij* is a ratio to a sum of outgoing tie weights, which is only mathematically meaningful when all of a node's tie weights are non-negative; a negative tie included in the same network as positive ties will distort every *p_ij* for that node (values can fall outside [0,1], and *c_ij* can exceed 1) rather than being handled as a distinct signed relation. Two-mode: not checked.

## References

Ronald S. Burt (1992). *Structural Holes: The Social Structure of Competition*. Harvard University Press.

## See also

- [nwburt](nwburt.md), [nwdegree](nwdegree.md), [nwbetween](nwbetween.md), [nwcloseness](nwcloseness.md), [nwevcent](nwevcent.md), [nwclustering](nwclustering.md)

- last certified : 21 Aug 2026
