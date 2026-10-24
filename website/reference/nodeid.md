---
title: "nodeid"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Node ids and node labels: how nodes are identified."
---

# `nodeid`

A node id is an integer from 1 to the size of the network that identifies a node. When a node is
deleted, the ids of the other nodes are renumbered so that they stay consecutive. A node label is a
unique word attached to a node; labels can be changed with [`nwname`](nwname). If node attributes are
stored as Stata variables, row *i* belongs to the node with id *i*.

To look up an id from a label or the other way around, see [`_nwnodeid`](_nwnodeid) and
[`_nwnodelab`](_nwnodelab); [`nwload`](nwload) creates the variables `_nodeid` and `_nodelab`.
