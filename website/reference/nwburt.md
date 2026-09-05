---
title: "nwburt"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Calculate Burt structural hole measures"
---

# `nwburt`

Calculate Burt structural hole measures

## Syntax

```stata
nwburt [netname] [, dyadredundancy dyadconstraint replace silent]
```

| | |
|---|---|
| `dyadredundancy` | Save dyadic redundancy as new network |
| `dyadconstraint` | Save dyadic constraint as new network |
| `replace` | Replace existing *_effsize*/*_efficiency*/*_constraint*/*_hierarchy* variables |
| `silent` | Suppress summary output |

## Description

This command calculates Burt's (1992) effective size, efficiency, constraint and hierarchy. All these measures are used to identify structural holes. They all build on the idea of redundancy. A network tie between ego and j is redundant, when ego is also connected to q and q is connected to j, i.e. that means ego can reach j via q instead of directly connecting to j. The level of redundancy of the tie between ego and j is based on the total number of ties ego has.

The dyadic redundancy measure calculates, for each actor in ego's neighborhood, how many of the other actors in the neighborhood are also tied to the other.  The larger the proportion of others in the neighborhood who are tied to a given "alter," the more "redundant" is ego's direct tie.

Dyadic constraint is a measure that indexes the extent to which the relationship between ego and each of the alters in ego's neighborhood "constrains" ego.  A full description is given in Burt's 1992 monograph, and the construction of the measure is somewhat complex.  At the core though, A is constrained by its relationship with B to the extent that A does not have many alternatives (has few other ties except that to B), and A's other alternatives are also tied to B.  If A has few alternatives to exchanging with B, and if those alternative exchange partners are also tied to B, then B is likely to constrain A's behavior.

- **ul:1. Effective size**

Conceptually the effective size is the number of people ego is connected to, minus the redundancy in the network, that is, it reduces to the non-redundant elements of the network. Another definition of effective size of the network is the number of alters that ego has, minus the average number of ties that each alter has to other alters (see Borgatti 1997). Suppose that A has ties to three other actors.  Suppose that none of these three has ties to any of the others.  The effective size of ego's network is three.  Alternatively, suppose that A has ties to three others, and that all of the others are tied to one another.  A's network size is three, but the ties are "redundant" because A can reach all three neighbors by reaching any one of them.  The average degree of the others in this case is 2 (each alter is tied to two other alters).  So, the effective size of the network is its actual size (3), reduced by its redundancy (2), to yield an effective size of 1. It is defined as:

EffSize_i = sum_over_j[ 1 - sum_over_q( p_iq * m_jq ) ]

Where, p_iq = y_iq / sum_over_j[ y_ij ] is the proportion of actor i's relations that are spent with q.

Furthermore, m_jq is the marginal strength of contact j's relation with contact q. Which is j's interaction with q divided by j's strongest interaction with anyone. For a binary network, the strongest link is always 1 and thus m_jq reduces to 0 or 1 (whether j is connected to q or not - that is, the adjacency matrix).

The sum of the product p_iq * m_jq measures the portion of i's relation with j that is redundant to i's relation with other primary contacts.

- **ul:2. Efficiency**

Efficiency norms the effective size of ego's network by its actual size.  That is, what proportion of ego's ties to its neighborhood are "non-redundant."  The effective size of ego's network may tell us something about ego's total impact; efficiency tells us how much impact ego is getting for each unit invested in using ties.  An actor can be effective without being efficient; and an actor can be efficient without being effective.

- **ul:3. Constraint**

Conceptually, constraint refers to how much room you have to negotiate or exploit potential structural holes in your network. Constraint is a summary measure that taps the extent to which ego's connections are to others who are connected to one another.  If ego's potential trading partners all have one another as potential trading partners, ego is highly constrained.  If ego's partners do not have other alternatives in the neighborhood, they cannot constrain ego's behavior.  The logic is pretty simple, but the measure itself is not.  It would be good to take a look at Burt's 1992 Structural Holes.  The idea of constraint is an important one because it points out that actors who have many ties to others may actually lose freedom of action rather than gain it -- depending on the relationships among the other actors.

"..opportunities are constrained to the extent that (a) another of your contacts q, in whom you have invested a large portion of your network time and energy, has (b) invested heavily in a relationship with contact j." (Burt 1992, p.54)

- **ul:4. Hierarchy**

Hierarchy is another quite complex measure that describes the nature of the constraint on ego.  If the total constraint on ego is concentrated in a single other actor, the hierarchy measure will have a higher value.  If the constraint results more equally from multiple actors in ego's neighborhood, hierarchy will be less.  The hierarchy measure, in itself, does not assess the degree of constraint.  But, among whatever constraint there is on ego, it measures the important property of dependency -- inequality in the distribution of constraints on ego across the alters in its neighborhood.

This command operates on the full adjacency matrix (via [nwtomata](nwtomata.md)) rather than the sparse network index, because the underlying formulas require genuine matrix products (two-step reach via every intermediary) rather than single-neighbor lookups - the same reason [nwsimilar](nwsimilar.md), [nwdissimilar](nwdissimilar.md), and [nwqap](nwqap.md) are also matrix-based. This is not expected to be practical on very large networks; see the sparse-backend documentation for detail on which nwcommands are, and are not yet, sparse-scalable.

## Examples

```stata
. nwwebuse florentine, nwclear
. nwburt flobusiness
```

## Supported network types

Binary: yes. Directed: yes, but not symmetrized - *p_ij* (the proportion of *i*'s outgoing investment in *j*) is computed from the raw adjacency matrix exactly as given, same convention as [nwconstraint](nwconstraint.md). Weighted: **W1**, native - tie weight is used directly as *p_ij*'s investment proportion, not as a distance. Signed: not supported, same reason as [nwconstraint](nwconstraint.md) - *p_ij* is a ratio to a sum of outgoing tie weights, only meaningful when all non-negative. Two-mode: not checked.

## Stored results

**Scalars**

- **r(nodes)** number of nodes

## References

Borgatti, S. (1997). Structural holes: Unpacking Burt's redundancy measures. *Connections* 20(1), 35-38.

Burt, R. S. (1992). *Structural Holes: The Social Structure of Competition*. Cambridge: Harvard University Press.

## See also

- [nwconstraint](nwconstraint.md), [nwbridges](nwbridges.md)

- last certified : 24 Aug 2026
