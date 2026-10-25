---
title: "netexample"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Example networks that can be loaded with nwwebuse."
---

# `netexample`

Example networks hosted in the nwcommands repository. Load one with [`nwwebuse`](nwwebuse), for example
`nwwebuse florentine`. The available data sets are: gang, glasgow, florentine, usstates, klas12b, hpotter,
macaque, chesapeake, usair, lazega, s50, sampson, mesa, zachary, kapferer, socialevolution, and the two-mode data sets davis (Southern women) and ftdirectors_se (company directors in Sweden). In
Stata, `help netexample` describes each data set and its sources.

The [Importing & Exporting](../tutorials/03-importing-exporting/) tutorial uses several of them. The
file format is described in [`nwsave`](nwsave).

## The two-mode data sets

`davis` (Southern women: 18 women, 14 events, 89 ties) and `ftdirectors_se` (company directors in Sweden: 5,092
directors, 455 companies, 5,669 ties) are two-mode networks. Sources, attributes and the changes made to the
subset are on the [data sets](../datasets/#two-mode-affiliation-networks) page, and
[Tutorial 9](../tutorials/11-two-mode-networks/) works through both. Licence statements, as distributed with the package:

- `davis` (Southern women): Davis, A., Gardner, B. B. and Gardner, M. R. (1941), *Deep South: A Social Anthropological Study of Caste and Class*, University of Chicago Press. The attendance matrix, the pseudonymous names and the event dates are those of the 1941 publication as distributed in the CRAN package manynet and in other network software. The data have no licence statement of their own, so no licence is asserted here: they are facts (who attended which event), not covered by the GPL-3 of this package, and are redistributed with citation of the source.
- `ftdirectors_se` (company directors in Sweden): Evtushenko, A. and Gastner, M. T. (2019), *Data set discussed in "Beyond Fortune 500: Women in a Global Network of Directors"*, Zenodo, https://doi.org/10.5281/zenodo.3553442, licensed under the Creative Commons Attribution 4.0 International licence (CC BY 4.0, https://creativecommons.org/licenses/by/4.0/); see also Evtushenko, A. and Gastner, M. T. (2020), "Beyond Fortune 500: Women in a Global Network of Directors", in Cherifi, H. et al. (eds.), *Complex Networks and Their Applications VIII*, Springer, 586-598. The original data were generated from the company profiles of the Financial Times web site (retrieved 17 September 2016). This file is a derived subset, adapted by Thomas U. Grund: only the companies located in Sweden and all of their directors were kept (5,092 directors, 455 companies, 5,669 ties); of the original columns only the director's gender and age and the company's sector, industry and number of employees were kept; identifiers were renamed, "NA" entries were turned into missing values, age and number of employees were made numeric, and the result was stored in the nwcommands network file format. This file stays under CC BY 4.0 (attribution required); it is not covered by the GPL-3 of the code.
