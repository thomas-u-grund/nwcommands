---
title: "nwsimmelian"
parent: "Core command reference"
grand_parent: "Packages and reference"
nav_exclude: true
search_exclude: false
description: "Simmelian ties"
---

# `nwsimmelian`

Simmelian ties

## Syntax

```stata
nwsimmelian 
[netname]
[,
name(newnetname)
nwreplace]
```

| | |
|---|---|
| `name(newnetname)` | Save Simmelian ties as new network; default *_simmelian* |
| `nwreplace` | Replace the network *name()* if it already exists |

## Description

Simmelian ties are concerned with more than just the strength of the relationship (see Krackhardt 1999). The original concept looks at the number of strong, reciprocated ties within a group: for a simmelian tie to exist, there must be three (a triad) or more of reciprocal strong ties in a group, viewed as even stronger than a regular strong tie. **This command implements the reciprocated-triad structure only - it does not apply any tie-strength/value threshold** (see **Network types** below); a weak reciprocated tie in a closed triad is flagged identically to a strong one.

For example, if Adam has a (reciprocated) tie to Betty, and both Adam and Betty share a (reciprocated) tie to Charles, this three-way tie would be a simmelian one.

The concept of a Simmelian tie is related to that of a clique; each pair of nodes (individuals) in a clique has a Simmelian tie between them. Thus a simmelian tie can be defined as a basic tie in a clique, or a co-clique relationship (between individuals who belong to a specific clique).

## Network types

**Directed:** only mutual ties count (the output says so). **Valued:** tie values are ignored (no strength threshold) and a note is printed. **Two-mode:** same as for the bipartite graph read as a one-mode network. **Signed:** not applicable. See [nwnetworktypes](nwnetworktypes).

## Limits

The mutual ties and the mutual neighbours they share are found from the tie lists. With 10 ties drawn per node, 20,000 nodes need about 1.2 GB.

The mutual ties that have a mutual neighbour in common are found in the compiled graph plugin (the native kernel of `nwcommands`) when the plugin of your platform has it, and in Mata otherwise; both give the same network. A network with self-loops takes the Mata route.

For all commands at network sizes of 1,000 to 100,000 nodes see the web page [How large a network can I analyze?](https://nwcommands.org/nwcommands/size-limits/)

## Examples

```stata
. nwwebuse florentine, nwclear
. nwsimmelian flomarriage
. nwplot flomarriage, edgecolor(_simmelian)
```

## References

Krackhardt, D. (1999). The ties that torture: Simmelian tie analysis in organizations. *Research in the Sociology of Organizations* (16), 183-210.

## See also

- [nwshared](nwshared)

---

*nwcommands version 3.38.0, 26 November 2026* ([check your installed version](nwversion))
