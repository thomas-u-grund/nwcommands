---
title: "nw_networktypes"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "How commands classify binary/directed/weighted/signed/two-mode networks"
---

# `nw_networktypes`

How commands classify binary/directed/weighted/signed/two-mode networks

## Description

`nwcommands` networks can be binary or valued (weighted), undirected or directed, and one-mode or two-mode (bipartite) - see [nw_intro](nw_intro.md) for the underlying data model. No single command supports every combination equally: some are inherently structural and apply unchanged to any network (e.g. [nwdrop](nwdrop.md)); some have a well-defined weighted generalization but a separate binary-only default (e.g. [nwclustering](nwclustering.md)); some are only meaningful for one-mode data and redirect automatically to a `nw2*` counterpart when given a two-mode network (e.g. [nwdegree](nwdegree.md) redirecting to [nw2degree](nw2degree.md)); a few are simply not implemented for a combination yet.

Rather than guess, every `nw*` command's own help file has a **Supported network types** section (immediately after its **Description**) stating explicitly what it does with a directed, weighted, signed, or two-mode network - whether that is full native support, an explicit binary-only/one-mode-only restriction with a clear error, silent-but-documented dichotomization, or simply "not applicable" for a command with no network-type-dependent behavior at all. That per-command section is always the authoritative answer for a specific command; this page explains the vocabulary those sections use and points to the small set of commands that have been read closely enough to also carry a fuller, source-verified classification.

## Examples

[nwsummarize](nwsummarize.md) reports a loaded network's own classification along these same dimensions:

```stata
. nwwebuse florentine, nwclear
. nwsummarize flomarriage
```

## See also

- [nw_intro](nw_intro.md), [nw_topical](nw_topical.md), [introduction to two-mode networks](nw2set.md)
