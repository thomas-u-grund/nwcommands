---
title: "nwreplace"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Replace a network"
---

# `nwreplace`

Replace a network

## Syntax

```stata
nwreplace 
netname[subnet]
=netexp
[ifego]
[ifalter]
[if]
```

## Description

Replaces a whole network, a subnetwork or specific tie values with a network expression. This command is the network version of `replace`. A [network expression](netexp) is very similar to a normal `expression` in Stata, but it also accepts [netnames](netname).

One can also replace tie values in networks by 1) loading a network as Stata variables (see [nwload](nwload)), 2) changing the Stata variables (see `replace`) and 3) syncing Stata variables and network afterwards (see [nwsync](nwsync)). However, replacing the networks directly (as shown below) is the faster and preferred method.

One can also change the entire adjaceny matrix of a network with an existing Mata matrix using [nwreplacemat](nwreplacemat).

## Assign values

Only replace dyad (2,1) to a constant:

- **. nwset, mat((0,0,1\1,0,0\1,10)) name(mynet)**
- **. nwreplace mynet[2,1] = 55**

Set all dyads x_ij of an existing network *mynet* to a constant:

**. nwreplace mynet = 99**

## Network expressions

A network expresssion is similar to a normal expression in Stata with the addition that it accepts network names. It can be a simple constant, but also a very complicated expression that consists of operators, networks and variables.

The usual operators are allowed in network expressions. All calculations in a network expression are performed element-by-element.

For example, one can calculate the intersection of two networks.

- **nwwebuse florentine, nwclear**
- **nwgen bus_marr = flomarriage * flobusiness**

This generates a new network *bus_marr*, which takes the values 1 when two Florentine families have both marriage and business ties.

A more complicated network expression:

- **gen test = _n**
- **nwgen net = 2 * exp(flomarriage) / flobusiness * test**

Basically, one can do all sorts of calculations using network expressions. See more on network expressions [here](netexp).

## Network subsets

Set a subnetwork to a constant:

**. nwreplace mynet[(1::4),(1::4)] = 55**

Tie values can also be replaced with the values found in other networks for the corresponding positions. For example, this replaces the whole network *first* with the network *second*.

- **. nwclear**
- **. nwrandom 7, density(.2) name(first)**
- **. nwrandom 7, density(.3) name(second)**
- **. nwreplace first = second**

Again, one can limit such a nwreplace command by using network subsetting. Furthermore, one can use a network expression which performs element-by-element calculations:

- **. nwclear**
- **. nwrandom 6, density(1) name(first)**
- **. nwreplace first = first * 5**
- **. nwreplace first[(1::3),(1::3)] = 0**
- **. nwsummarize first, matonly**

```stata
     1   2   3   4   5   6
  +-------------------------+
1 |  .                      |
2 |  0   .                  |
3 |  0   0   .              |
4 |  5   5   5   .          |
5 |  5   5   5   5   .      |
6 |  5   5   5   5   5   .  |
  +-------------------------+
```

## Network types

**Directed:** a bracket write sets exactly the cell addressed, also on an undirected network (**nwreplace mynet[2,1] = 55** does not write cell (1,2); write both cells or use [nwsym](nwsym)); an undirected network whose matrix is then no longer symmetric becomes directed (a note says so). **Valued:**, **Signed:** any value can be assigned. **Two-mode:** same as for the bipartite graph read as a one-mode network. See [nwnetworktypes](nwnetworktypes).

## Limits

`nwreplace` evaluates an expression over the whole *n*-by-*n* network and holds three such matrices; above about 22,000 nodes (12 GB) it stops at once with r(484). Use [nwrecode](nwrecode) or [nwdichotomize](nwdichotomize) to change tie values, [nwfromedge](nwfromedge) or [nwset](nwset) to add or remove ties, [nwsubset](nwsubset) to work on a part of the network.

## Stored results

- **Scalars**
- **r(symmetric)** --- 1 if the network's updated adjacency matrix is symmetric, 0 otherwise
- **r(valued)** --- 1 if the network is valued, 0 otherwise

## See also

- [nwreplacemat](nwreplacemat), [nwsync](nwsync), [nwload](nwload)

---

*nwcommands version 3.22.0, 13 November 2026* ([check your installed version](nwversion))
