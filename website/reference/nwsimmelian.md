---
title: "nwsimmelian"
parent: "Command reference"
grand_parent: "nwcommands (core)"
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

*nwcommands version 3.20.1, 12 November 2026* ([check your installed version](nwversion))
