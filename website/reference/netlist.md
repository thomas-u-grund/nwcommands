---
title: "netlist"
parent: "Command reference"
nav_exclude: true
search_exclude: false
---

# `netlist`

## Description

A *netlist* is a list of [network names](netname.md). It can also just hold the name of a single network. A *netlist* exclusively refers to existing networks.

Examples include

- `mynet` just one network
- `mynet1 mynet2 mynet3` three networks
- `mynet*` all networks starting with `mynet`
- `*net` all networks ending with `net`
- `my*t` all networks starting with `my` & ending
- with `t` with any number of other characters
- between
- `my~net` one network starting with `my` &
- ending with `net` with any number of other characters
- between
- `my?var` networks starting with `my` & ending
- with `net` with one other character between
- `mynet1-mynet6` `mynet1`, `mynet2`, ...,
- `net6` (probably)
- `this-that` networks `this` through `that`,
- inclusive
- `_all` all networks

The `*` character indicates to match one or more characters.  All networks matching the pattern are returned.

The `~` character also indicates to match one or more characters, but unlike `*`, only one network is allowed to match.  If more than one network matches, an error message is presented.

The `?` character matches one character.  All networks matching the pattern are returned.

The `-` character indicates that all networks in the dataset, starting with the network to the left of the `-` and ending with the network to the right of the `-` are to be returned.

Many commands understand the keyword `_all` to mean all networks. Some commands default to using all networks if none are specified.

The networks in the dataset can be reordered with [nworder](nworder.md).

## Examples

```stata
. nwuse glasgow
. nwset
```
- The next four commands are all equivalent.

```stata
. nwsummarize glasgow1 glasgow2 glasgow3
. nwsummarize glasgow1-glasgow3
. nwsummarize glasg*
. nwsummarize _all
```

## See also

- [netname](netname.md), [nwsummarize](nwsummarize.md), [nworder](nworder.md)
