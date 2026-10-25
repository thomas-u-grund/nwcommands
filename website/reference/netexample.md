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
macaque, chesapeake, usair, lazega, s50, sampson, mesa, zachary, kapferer, socialevolution, the two-mode data sets davis (Southern women) and ftdirectors_se (company directors in Sweden), and the signed networks senate114, senate93 (US Senate) and gahuku (Gahuku-Gama tribes). In
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

## The signed data sets

`senate114` (100 senators, 1,435 positive and 2,261 negative ties), `senate93` (101 senators, 581 positive and 1,858 negative ties) and `gahuku` (16 tribes, 29 positive and 29 negative ties) are valued networks with ties of +1 and -1; use them with `nwbalance` and for signed degrees. Sources, attributes and the changes made to the Senate subset are on the [data sets](../datasets/#signed-networks) page. Licence statements, as distributed with the package:

- `senate93`, `senate114` (US Senate): Neal, Z. P. (2020), *A Sign of the Times: Dataset of US Congress signed network backbones from co-sponsorship data, 1973-2016*, figshare, https://doi.org/10.6084/m9.figshare.8096429, licensed under the Creative Commons Attribution 4.0 International licence (CC BY 4.0, https://creativecommons.org/licenses/by/4.0/); described in Neal, Z. P. (2020), "A sign of the times? Weak and strong polarization in the U.S. Congress, 1973-2016", *Social Networks* 60, 103-112, https://doi.org/10.1016/j.socnet.2018.07.007; the method is that of Neal, Z. P. (2014), "The backbone of bipartite projections: Inferring relationships from co-authorship, co-sponsorship, co-attendance and other co-behaviors", *Social Networks* 39, 84-97, https://doi.org/10.1016/j.socnet.2014.06.001. These files are a derived subset, adapted by Thomas U. Grund: only the Senates of the 93rd (1973-74) and the 114th (2015-16) Congress were kept (the two sheets S93 and S114 of the workbook); of the original columns only the tie sign (+1, -1; no tie is 0) and, from the row labels "Name (ST-P)", the senator's name, state and party were kept; the result is stored in the nwcommands network file format (each tie is listed in both directions). The files stay under CC BY 4.0; they are not covered by the GPL-3 of the code. Caveat: the signs are not observed likes and dislikes. They are inferred from bill co-sponsorship by a statistical model (the stochastic degree sequence model): +1 means two senators co-sponsored more bills together than expected by chance, -1 that they co-sponsored fewer.
- `gahuku` (Gahuku-Gama tribes): Read, K. E. (1954), "Cultures of the Central Highlands, New Guinea", *Southwestern Journal of Anthropology* 10(1), 1-43, https://doi.org/10.1086/soutjanth.10.1.3629074; the signed network of the 16 tribes was analysed by Hage, P. and Harary, F. (1983), *Structural Models in Anthropology*, Cambridge University Press. The data have no licence statement of their own, so no licence is asserted here: they are facts (which of the 16 tribes are allied and which are enemies), not covered by the GPL-3 of this package, and are redistributed with citation of the sources. The ties are taken from the version distributed with the R package signnet (data set tribes), which cites the UCINET data file gama.dat.
