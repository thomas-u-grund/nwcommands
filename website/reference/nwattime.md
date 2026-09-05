---
title: "nwattime"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Static graph view of a temporal network at a given time"
---

# `nwattime`

Static graph view of a temporal network at a given time

## Syntax

```stata
nwattime
[netname]
,
at(#)
[name(newnetname)
xvars
replace]
```

| | |
|---|---|
| `at(#)` | The timepoint to slice at |
| `name(newnetname)` | Name of the new static network; default = *atview* |
| `xvars` | Generate Stata variables for the new network |
| `replace` | Replace an existing network of the same name |

## Description

`nwattime` takes a temporal network (declared via [nwset](nwset)'s **time()**, **interval()**, or **eventtime()** options) and produces an ordinary, static one-mode network containing only the ties active at the requested timepoint - the "temporal network -> select edges active at t -> static graph view -> ordinary nw algorithm" model: the resulting network is a completely normal network, usable with any existing **nw*** command exactly as if it had never been temporal at all. This is deliberate groundwork, not a full temporal-network modelling system - see [nwset](nwset)'s own temporal section for what is and is not supported yet.

The slicing rule depends on the source network's own temporal semantics:

- **snapshot**
- a tie is active at *t* when its own recorded time equals *t* exactly
- **interval**
- a tie is active at *t* when *start* <= *t* < *end* - the documented convention.
- A tie with a missing *end* (an ongoing tie with no recorded end date) is treated as open-ended
- and stays active for every *t* from its *start* onward. A missing *start* is not specially
- handled and excludes the tie
- **event**
- an exact-timestamp match: every event recorded at precisely *t* becomes a binary tie in
- the static view. This is the one place an event network is allowed to become a persistent graph in
- this package, and only because *t* was explicitly requested - no windowing or aggregation across a
- range of timestamps is done (not yet supported)

For example, a network declared with `nwset ego alter, time(wave)` can be sliced to the ties that existed in wave 2:

```stata
. clear
. input ego alter wave
```
- 1 2 1
- 2 3 1
- 1 3 2
- 2 3 2
- 3 4 3

```stata
. end
. nwset ego alter, time(wave) name(mynet)
. nwattime mynet, at(2) name(wave2)
```

## Supported network types

Binary: yes. Directed: preserved from the source network. Weighted: preserved from the source network's own tie values (the slice selects which ties are active, it does not change their values). Signed: not checked. Two-mode: not yet supported as a source (see [nwset](nwset)'s own note that **time()**/ **interval()**/**eventtime()** cannot currently be combined with **twomode**/**bipartite** - a composability item for a later pass).

## Stored results

**Scalars**

- **r(ties)** number of ties in the static view
- **r(at)** the timepoint sliced at

## See also

- [nwset](nwset), [nwsummarize](nwsummarize)

- last certified : 21 Aug 2026
