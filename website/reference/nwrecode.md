---
title: "nwrecode"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Recode network"
---

# `nwrecode`

Recode network

## Syntax

```stata
nwrecode [netlist] (rule) 
[(rule) ...]
[, generate(newnetlist) prefix(str) test]
where the most common forms for rule are
hline 16c TThline 13c TThline 27
c | rule           c | Example     c | Meaning                   c |
hline 16c +hline 13c +hline 27
c | # = #          c | 3 = 1       c | 3 recoded to 1            c |
c | # # = #        c | 2 . = 9     c | 2 and . recoded to 9      c |
c | #/# = #        c | 1/5 = 4     c | 1 through 5 recoded to 4  c |
c | nonm:issing = # c | nonmiss = 8 c | all other nonmissing to 8 c |
c | mis:sing = #    c | miss = 9    c | all other missings to 9   c | 
c | else  = #      c | else = 44   c | all other to 44           c |
hline 16c BThline 13c BThline 27
The keyword rules missing, nonmissing, and else must be the
last rules specified.  else may not be combined with missing or 
nonmissing.
```

## Description

`nwrecode` changes the dyad values of networks according to the specified rules. It works almost exactly as `recode`, but for networks. Dyad values that do not meet any of the conditions of the rules are left unchanged, unless an *otherwise* rule is specified.

`min` and `max` provide a convenient way to refer to the minimum and maximum for each dyad value in [netlist](netlist.md) and may be used in both the from-value and the to-value parts of the specification.

**Common recipe: dichotomizing at a single cutoff.** A frequent special case is turning a valued network binary at one threshold - values at or above the cutoff become 1, everything else becomes 0:

```stata
. nwrecode trade (100/max=1) (min/max=0)
```
- For exactly this case, [nwdichotomize](nwdichotomize.md) is a thin, more directly discoverable wrapper around
- the same rule shown above: `nwdichotomize trade, threshold(100)`. Reach for `nwrecode`
- directly whenever you need something [nwdichotomize](nwdichotomize.md) does not offer - multiple bands, an
- *otherwise* rule, or `missing`/`nonmissing` handling.

## Options

- dlgtab:Options

`generate`(*[newnetlist](newnetname.md)*) specifies the names of the network(s) that will contain the transformed dyads.  `into()` is a synonym for `generate()`.

If generate() is not specified, the input networks are overwritten; Overwriting networks is dangerous (you cannot undo changes, so we strongly recommend specifying nwgenerate().

`prefix(str)` specifies that the recoded networks be returned in new networks formed by prefixing the names of the original networks with *str*.

`test` specifies that Stata test whether rules are ever invoked or that rules overlap; for example, `(1/5=1) (3=2)`.

## Examples

**Setup**

- `. nwwebuse gang`
- `. nwwebuse glasgow`

- List the network adjacency matrix
- `. nwsummarize gang, mat`

- For *gang*, change 1 to 5, leave all other values unchanged, and store
- the results in `nx`
- `. nwrecode gang (1 = 5), generate(nx)`

- List the network adjacency matrix
- `. nwsummarize gang nx, mat`

- For *gang*, swap 1 and 2, and store the results in `nx1`
- `. nwrecode gang (1 = 2) (2 = 1), generate(nx1)`

- List the network adjacency matrix
- `. nwsummarize gang nx1, mat`

- For *gang*, collapse 1 and 2 into 1, change 3 through 4
- to 2, and store the results in `nx2`
- `. nwrecode gang (1 2 = 1) (3/4 = 2), generate(nx2)`

- List the network adjacency matrix
- `. nwsummarize gang nx2, mat`

- For *glasgow1*, *glasgow2*, and *glasgow3*, change dyad values 1 to 99 and store the
- transformed networks in *new_glasgow1*, *new_glasgow2*, and *new_glasgow3*.
- `. nwrecode glasgow1-glasgow3 (1=99) ,`

```stata
pre(new) test
```
- List the network adjacency matrices
- `. nwsummarize glasgow1-3 new_glasgow1-3, mat`

## Supported network types

Binary: yes - recoding a binary network's 0/1 values is a degenerate but valid case. Directed: yes. Weighted: yes, natively - this command's entire purpose is recoding tie values via a rule. Signed: yes, a recode rule can map negative values like any other. Two-mode: not checked.

## See also

- [nwreplace](nwreplace.md), `recode`, [nwdichotomize](nwdichotomize.md) (a thin wrapper around this command for the common single-cutoff case)
