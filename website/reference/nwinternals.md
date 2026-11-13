---
title: "nwinternals"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
---

# `nwinternals`

## Contents

**SectionDescription**

- hline 46
- [**[NW-7.1]****Overview**](nwinternals)

- [**[NW-7.2]****Network resolution and identification**](nwinternals)

- [**[NW-7.3]****Network-expression parsing**](nwinternals)

- [**[NW-7.4]****Dialog-box generation**](nwinternals)

- [**[NW-7.5]****egen extension functions**](nwinternals)

- [**[NW-7.6]****Other small utilities**](nwinternals)

- [**[NW-7.7]****Shared error-code definitions**](nwinternals)

## Overview

Alongside the roughly 130 documented `nw*` commands, this package ships a number of leading-underscore files (e.g. `_nwsyntax.ado`) that are installed but not meant to be called by name directly. They exist purely to share logic between the real, documented commands - the same role Stata's own official commands use a leading underscore for throughout `ado/base/`.

This page exists so that a curious user finds an explanation somewhere, rather than these files turning up unexplained in an installed-file listing; it is not a tutorial for using them. If you are writing your own command against this package's own API (rather than just using the documented `nw*` commands), see [nwprogramming](nwprogramming) instead - several of the files below are exactly the shared helpers that page's own worked example uses.

## Network resolution and identification

`_nwsyntax` is the package's central dispatcher: almost every documented command's leading argument (an optional [netname](netname) or [netlist](netlist), falling back to the [current network](nwcurrent) when omitted) is resolved through it. `_nwname` holds the real implementation behind [nwname](nwname) (a network's own name and directed/valued/two-mode metadata). `_nwnodeid`/`_nwnodelab` look up a node's numeric id from its label and vice versa. `_nwtomata` returns a network's adjacency matrix as a Mata object or a plain copy - the real implementation behind [nwtomata](nwtomata). `_nwdatasync` keeps a network's optional Stata-variable representation (see [nwload](nwload)'s `xvars`) synchronized with the underlying Mata network object after a structural change. `_nwsetobs` sets the working dataset's observation count to match a network's node count.

## Network-expression parsing

`_nwevalnetexp`/`_nwexpnetexp` parse and evaluate the [netexp](netexp) mini-language (matrix-style expressions over networks, e.g. inside [nwgenerate](nwgenerate) / [nwreplace](nwreplace)). `_nwevalnetexp` is also documented on its own (see [netexp](netexp)) as the one file in this group a programmer may call directly, when writing a command that needs to accept a [netexp](netexp) argument itself.

## Dialog-box generation

`_nwdialog`, `_nwdialog_append`, `_nwdialog_clusters`, and `_nwdialog_lablist` hold the shared logic behind the roughly 120 `.dlg` dialog boxes reachable from Stata's "Network Analysis" menu (see [nwinstall](nwinstall)) - populating a dialog's network/cluster/label dropdowns with whatever is currently loaded, rather than each dialog file duplicating that logic.

## egen extension functions

`_gnwdegree` and `_growmedian2` follow Stata's own `egen` extension-function naming requirement (`egen` looks for a file named `_g`*function* automatically) - they are never called by name directly, only ever reached via `egen newvar = nwdegree(...)`-style syntax.

## Other small utilities

`_opts_oneof` validates that at most one of a set of mutually exclusive suboptions was specified, returning a clear error naming all of them if more than one was. `_extract_valuelabels` reads a variable's Stata value label into a usable form. `_nwedgelabs` is a small, currently-incomplete helper intended to return edge labels for [nwtabulate](nwtabulate). `_nwstrcat` *varlist* `:` *command* runs *command* with the string variables of *varlist* encoded under their own names (levels in alphabetical order) and puts the strings back afterwards, also after an error. It is meant for options where the values serve only as categories, such as `group()` of [nwbrokerage](nwbrokerage); options that use values as numbers refuse strings.

## Shared error-code definitions

`unw_defs` does not follow the leading-underscore convention above, but belongs on this page for the same reason: it is called by nearly every documented command to populate a shared table of this package's own error-code local macros (see [nwerrorcodes](nwerrorcodes) for the user-facing meaning of each code) and a handful of other commonly-needed locals, rather than each command redefining the same table itself.

---

*nwcommands version 3.24.0, 13 November 2026* ([check your installed version](nwversion))
