---
title: "nwattime"
parent: "Command reference"
grand_parent: "nwcommands (core)"
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
- a tie is active at *t* when one of its recorded times equals *t* exactly (a pair
- listed at several times is active at each of them)
- **interval**
- a tie is active at *t* when *start* <= *t* < *end* - the documented convention.
- A tie with a missing *end* (an ongoing tie with no recorded end date) is treated as open-ended
- and stays active for every *t* from its *start* onward. A missing *start* is not specially
- handled and excludes that row. A pair with several rows is active in each of its periods
- **event**
- an exact-timestamp match: every event recorded at precisely *t* becomes a binary tie in
- the static view. This is the one place an event network is allowed to become a persistent graph in
- this package, and only because *t* was explicitly requested - no windowing or aggregation across a
- range of timestamps is done (not yet supported)

For example, a network declared with `nwset ego alter, time(wave)` can be sliced to the ties that existed in wave 2:

```stata
. clear
. input ego alter wave
1 2 1
2 3 1
1 3 2
2 3 2
3 4 3
. end
. nwset ego alter, time(wave) name(mynet)
. nwattime mynet, at(2) name(wave2)
```

## Network types

**Directed:** kept from the source network. **Valued:** the tie values of the source network are kept (the slice selects ties, it does not change their values). **Two-mode:** a temporal two-mode network ([nwset](nwset) with `twomode` and `time()`, `interval()` or `eventtime()`) gives a two-mode slice with the same modes and level labels. **Signed:** negative values are not treated specially. See [nwnetworktypes](nwnetworktypes).

## Limits

The ties at the time point are taken from the stored ties and the matrix of tie times; `nwset, time()`/`interval()`/`eventtime()` find the node of every label in a hash. 20,000 nodes with 200,000 ties and 3 waves: 0.3 seconds. The matrix of tie times itself is dense, 3.2 GB at 20,000 nodes.

For a temporal network of more than 2,000 nodes the times (or the starts and ends) of the ties are kept as a list of the ties that have one, not as *n*-by-*n* matrices (80 GB each at 100,000 nodes). `nwattime` of a network with 100,000 nodes and 1 million ties takes about 2 seconds.

## Stored results

- **Scalars**
- **r(ties)** --- number of rows in the tie list of the static view (an undirected tie is stored as two rows, so this is twice the number of ties in the printed *Ties* line)
- **r(at)** --- the timepoint sliced at

## See also

- [nwset](nwset), [nwsummarize](nwsummarize)

---

*nwcommands version 3.24.0, 13 November 2026* ([check your installed version](nwversion))
