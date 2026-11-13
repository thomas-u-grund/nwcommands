---
title: "nwerrorcodes"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Return codes of nwcommands"
---

# `nwerrorcodes`

Return codes of nwcommands

## Description

The commands of `nwcommands` stop with two kinds of return codes: a small set of codes defined by this package for situations that recur across many commands and have no natural Stata code (network not found, network already exists, node not found, ...), and Stata's own codes, used for their standard meaning (invalid syntax, variable already defined, file not found, ...).

The two tables below list every code that the commands of the core package raise themselves, and in which situations. When Stata itself stops inside a command (for example a file that cannot be read, or too little memory), its own code is passed on unchanged; see `error` and **[P] error** for all of Stata's codes. The model packages (`nwsaom`, `nwergm`, `nwdynam`, `nwrem`) describe their messages in their own help files.

Use these codes when you catch errors in a do-file (`capture ...` followed by `if _rc == 482 ...`): a code keeps its meaning in every command.

Inside a program the package-specific codes are also available as local macros from `unw_defs.ado`, e.g. ````errNWsNotFound``'` instead of the bare number **482**.

## Package-specific codes

- **480** --- Network creation failed (`errNWsCreate`)
- **482** --- Network not found (`errNWsNotFound`)
- **483** --- Network already exists; specify **replace**, **nwreplace** or the command's own override option, or choose another name (`errNWsExists`)
- **484** --- Network too large to be held as a dense matrix (`errDenseTooLarge`)
- **485** --- A node (by name or id) does not exist in the network, or a node id is out of range (`errNodeNotFound`)
- **999** --- Loading would discard the networks in memory; specify **nwclear** or **nwappend** (`errNWsDataLoss`)
- **6056** --- Two networks that must have the same size do not (`errNWsSizeMismatch`)
- **6077** --- A [netexp](netexp) expression is empty or has unmatched parentheses (`errNetexpMalformed`)
- **6082** --- A matrix given by the user has the wrong shape (not square, wrong dimensions) (`errMatrixShape`)
- **6088** --- The command or option does not support two-mode networks (`errTwoModeUnsupported`)
- **6556** --- An option's value is not one of the values it allows (`errOptValue`)
- **6705** --- A file or data format that is not supported was requested or detected (`errFormatUnsupported`)

## Stata codes used by the commands

- **4** --- `nwinstall` building the Mata library: the data in memory would be cleared; save them and type `clear all` first
- **9** --- `nwinstall` building a native plugin: the compiler stopped
- **109** --- Type mismatch: a string variable where a numeric one is needed (for example `nwset, eventtime()`, `group()` of `nwbrokerage`)
- **110** --- A Stata variable already exists (for example a `generate()` target of a measure such as `nwdegree`, `nwbetween` or `nwplot`); specify `replace` or another name. **483** is the code for a *network* that already exists
- **111** --- Something named in an option was not found (a variable, a Mata matrix, a cluster)
- **125** --- A number is out of its allowed range (for example a probability outside 0 to 1, a number of nodes below 2)
- **184** --- Options that may not be combined (`nwtostata`)
- **198** --- Invalid syntax: a required option is missing, options are combined that exclude each other, or an option is given a value of the wrong kind
- **199** --- A function of `nwgenerate` that is not available
- **301** --- No estimates of a previous `nwqap` in memory
- **402**, **499** --- `nwdyadprob`: tie probabilities that are negative or all zero
- **416** --- Missing values where every observation needs a value (for example events without sender, receiver or time in `nwset, eventtime()`)
- **459** --- The data contradict what was declared (for example ties within a mode of a two-mode network, data rows not in node order, cluster levels that are not nested)
- **498** --- Other checks of the data or the results (for example inconsistent `maximum()` and `minimum()`, a model package that needs a newer core)
- **503** --- A Mata vector given by the user has the wrong length
- **601**, **602** --- A file was not found, or a file to be written already exists (specify `replace`)
- **621** --- `nwpreserve`: the networks are already preserved
- **900** --- The network has too many nodes to be held in one Stata variable per node
- **908** --- The network has more nodes than a Stata matrix can hold (`c(max_matdim)`)
- **2000**, **2001** --- No observations, or fewer observations than needed (for example fewer rows of data than the network has nodes)
- **3300** --- `nwdyadprob`: more ties requested than there are dyads with a positive probability
- **3499** --- The Mata library of nwcommands is missing or out of date; run `nwinstall`

## Examples

Catch a package-specific error code programmatically:

```stata
. nwclear
. capture nwname doesnotexist
. display _rc
. if _rc == 482 {
.     display "network not found"
. }
```

## See also

- [nwcommands](nwcommands), [nwtopical](nwtopical)

---

*nwcommands version 3.22.0, 13 November 2026* ([check your installed version](nwversion))
