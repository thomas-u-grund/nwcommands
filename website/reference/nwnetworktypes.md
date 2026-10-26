---
title: "nwnetworktypes"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "How commands classify binary/directed/weighted/signed/two-mode networks"
---

# `nwnetworktypes`

How commands classify binary/directed/weighted/signed/two-mode networks

## Description

`nwcommands` networks can be binary or valued (weighted), undirected or directed, and one-mode or two-mode (bipartite) - see [nwintro](nwintro) for the underlying data model. No single command supports every combination equally: some are inherently structural and apply unchanged to any network (e.g. [nwdrop](nwdrop)); some have a well-defined weighted generalization but a separate binary-only default (e.g. [nwclustering](nwclustering)); some have a two-mode form of the same concept that they use automatically on a two-mode network (e.g. [nwdegree](nwdegree); the option `onemode` forces the one-mode computation); a few are simply not implemented for a combination yet.

Rather than guess, every `nw*` command's own help file has a **Supported network types** section (immediately after its **Description**) stating explicitly what it does with a directed, weighted, signed, or two-mode network - whether that is full native support, an explicit binary-only/one-mode-only restriction with a clear error, silent-but-documented dichotomization, or simply "not applicable" for a command with no network-type-dependent behavior at all. That per-command section is always the authoritative answer for a specific command; this page explains the vocabulary those sections use and points to the small set of commands that have been read closely enough to also carry a fuller, source-verified classification.

## Examples

[nwsummarize](nwsummarize) reports a loaded network's own classification along these same dimensions:

```stata
. nwwebuse florentine, nwclear
. nwsummarize flomarriage
```

## See also

- [nwintro](nwintro), [nwtopical](nwtopical), [introduction to two-mode networks](nw2set)

---

*nwcommands version 3.9.1, 26 October 2026* ([check your installed version](nwversion))
