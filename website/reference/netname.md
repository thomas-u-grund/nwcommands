---
title: "netname"
parent: "Command reference"
nav_exclude: true
search_exclude: false
---

# `netname`

## Description

A *netname* is one network name, such as

- `x`
- `mynet`
- `flobusiness`
- `flomarriage`
- `friendship`
- `friendship_wave2`
- `_advice`
- `_1994`

Network names may be 1 to 32 characters long and must start with `a`-`z`, `A`-`Z`, or `_`, and the remaining characters may be `a`-`z`, `A`-`Z`, `_`, or `0`-`9`.

When we use the term netname, we usually mean an existing netname -- a network that already exists in Stata, i.e. it has been setted by * [nwset](nwset.md)*, loaded or created by a network generator (see [[NW-1.2] Generators](nw_topical.md)). The alternative would be a *[newnetname](newnetname.md)*.

When referring to an existing netname, we can abbreviate. We can use a * [netlist](netlist.md)* notation, which is similar to the *`varlist`* notation, but it must identify one network:

- pin
- `flob*` might uniquely identify `flobusiness`

- pin
- `friend*2` might uniquely identify
- `friendship_wave2`.

In the netlist notation, `*` means that zero or more characters go here. Netnames are often specified inside options and then usually the netlist notation is allowed.

A list of all currently available networks is returned by * [nwset](nwset.md)*.

For most network commands a netname is optional. When no netname is explicitly specified the most current network is used. To find out which network is the current network and to change the current network use * [nwcurrent](nwcurrent.md)*. Furthermore, * [nwload](nwload.md)* also changes the current network.

## Examples

- `. nwuse florentine`
- `. nwset`
- `. nwdegree flobusiness`
- `. nwcomponents *marriage`
