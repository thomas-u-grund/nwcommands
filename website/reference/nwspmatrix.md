---
title: "nwspmatrix"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Spatial weighting matrix from a network, for `spregress`"
---

# `nwspmatrix`

Spatial weighting matrix from a network, for `spregress`

## Syntax

```stata
nwspmatrix [netname] [, options]
```

| | |
|---|---|
| `name(spmatname)` | name of the weighting matrix; default `W` |
| `weights(binary\|valued)` | ties as 0/1 (default) or with their values |
| `dir:ection(out\|in\|symmetric\|mutual)` | how to read directed ties; default `out` |
| `norm:alize(row\|none\|spectral\|minmax)` | normalisation; default `row` |
| `idv:ar(varname)` | numeric variable that identifies the nodes in the data |
| `mat:rix(name)` | also store the matrix as an ordinary Stata matrix |
| `replace` | overwrite an existing weighting matrix |
| `silent` | do not show the summary |

## Description

`nwspmatrix` turns a network into a spatial weighting matrix of Stata's `spmatrix` system. The matrix can then be used in `spregress`, `spivregress` and the other commands of the `spatial` suite. With a network as the weighting matrix, `spregress, ml dvarlag()` fits the linear network autocorrelation (network effects) model

*y* = *rho* *W* *y* + *X* *b* + *e*

which is the model `lnam` of the R package sna fits when the disturbance is white noise. Row-normalised, *W**y* is the average of *y* over the neighbours of each node, so *rho* is the strength of influence of the neighbours' average.

Observation *i* of the data set in memory must hold node *i* of the network, as everywhere in nwcommands. Observations beyond the number of nodes should be missing on the variables of the model (they are then left out of the regression). The nodes are identified for Stata by an `spatial-unit ID`: the one the data set already has, the variable named in `idvar()`, or, if the data set is not `spset`, a new variable `_nwid` (the node number) that `nwspmatrix` creates and `spset`s.

## Options

`name(spmatname)` names the weighting matrix; the default is `W`. An existing matrix of that name is only overwritten with `replace`.

`weights(binary|valued)`: `binary` (default) uses 1 for every tie; `valued` uses the tie values. Values must not be negative. Self-loops are removed.

`direction()` applies to directed networks only (an undirected network is symmetric already). `out` (default): *W*sub:ij refers to the tie from *i* to *j*, so node *i* is influenced by the nodes it names. `in`: the transpose, so node *i* is influenced by the nodes that name it. `symmetric`: a tie in either direction counts (the larger of the two values with valued weights). `mutual`: only reciprocated ties count (the smaller of the two values).

`normalize()`: `row` (default) divides each row by its sum, so that rows sum to 1; `none` leaves the matrix as it is; `spectral` and `minmax` are done by Stata as described in `spmatrix normalize`. Note that Stata's own default is `spectral`, not `row`.

`idvar(varname)` sets the spatial-unit ID variable of the data to this numeric variable (it must identify the observations uniquely; see `spset`). Row *i* of the matrix is then labelled by the value of this variable in observation *i*.

`matrix(name)` also stores the matrix as a Stata matrix (for `matrix list`, or for exporting it). Stata limits the size of matrices (`matsize`); if the network is too large for it, the weighting matrix *spmatname* is still created and a message says so.

## Remarks

**Isolates.** A node without a tie (after the direction rule has been applied) gets a row of zeros: it is influenced by nobody, so *W**y* is 0 for it. Stata reports them as "islands". Row normalisation leaves such a row at zero rather than dividing by zero. The estimator still uses these nodes (their outcome enters the likelihood), which is the same as `lnam`.

**Which direction.** With `direction(out)` on a nomination network ("whom do you name as a friend?") a node is influenced by those it names. Use `in` if you want influence to run from the nominators to the nominated, and `symmetric` or `mutual` if you want to treat the network as undirected. The estimator accepts a non-symmetric matrix; with `ml` the autoregressive coefficient is restricted to the range allowed by the eigenvalues of the matrix.

**Comparison with R.** On the Glasgow example below, `spregress, ml` and `lnam` (sna 2.8; same row-normalised matrix) agree in the coefficients, the standard errors and the log likelihood to about 5 digits. Both maximise the same Gaussian likelihood of the autoregressive model. They differ in what is offered and in details: `lnam` can also fit a network-lagged disturbance and does not restrict the autoregressive coefficient to the range given by the eigenvalues of the weighting matrix, and its standard errors come from a numerical Hessian; `spregress` adds the generalized spatial two-stage least-squares estimator (`gs2sls`), lagged covariates (`ivarlag()`), an error lag and several weighting matrices. This agreement is shown for one example; other data, other weighting matrices or a very large autoregressive coefficient can show larger differences.

**Not covered.** `nwspmatrix` builds the weighting matrix from one network. Two-mode networks are refused (make a one-mode network first, see [nwproject](nwproject)). `spregress` fits continuous outcomes only; for a binary outcome that depends on the neighbours see the separate package nwalaam. `estat moran, errorlag()` works after `regress` with a matrix from `nwspmatrix`.

## Examples

- Friends among 50 pupils in Glasgow: does a pupil's alcohol consumption follow that of the friends?
- `. nwclear`
- `. nwwebuse glasgow, nwclear`
- `. nwspmatrix glasgow2, name(W)`
- `. spregress alcohol2 smoke2 sport2, ml dvarlag(W)`

- Treat the friendships as mutual only, without row normalisation, and compare
- `. nwspmatrix glasgow2, name(Wm) direction(mutual) normalize(none)`
- `. spregress alcohol2 smoke2 sport2, ml dvarlag(Wm)`

- Influence also through the covariates of the friends (spatially lagged covariates)
- `. spregress alcohol2 smoke2 sport2, ml dvarlag(W) ivarlag(W: smoke2)`

## Stored results

`nwspmatrix` stores the following in `r()`:

- **Scalars**
- **`r(nodes)`** --- number of nodes
- **`r(ties)`** --- number of nonzero cells of the matrix
- **`r(isolates)`** --- number of nodes with a row of zeros
- **Macros**
- **`r(name)`** --- name of the spatial weighting matrix
- **`r(network)`** --- network name
- **`r(weights)`, `r(direction)`, `r(normalize)`** --- options as used

## References

Butts, C. T. 2008. Social network analysis with sna. *Journal of Statistical Software* 24(6): 1-51.

Doreian, P. 1989. Network autocorrelation models: problems and prospects. In *Spatial Statistics: Past, Present, and Future*, ed. D. A. Griffith, 369-389. Ann Arbor: Institute of Mathematical Geography.

Leenders, R. T. A. J. 2002. Modeling social influence through network autocorrelation: constructing the weight matrix. *Social Networks* 24: 21-47.

## Also see

- psee
- [nwqap](nwqap), [nwcorrelate](nwcorrelate), [nwtomata](nwtomata), `spregress`, `spmatrix`

---

*nwcommands version 3.27.0, 18 November 2026* ([check your installed version](nwversion))
