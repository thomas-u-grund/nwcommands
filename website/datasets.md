---
title: "Data sets"
nav_order: 11
description: "The example networks that ship with nwcommands: what they are, where they come from, how to load them and which tutorials use them."
permalink: /datasets/
---

# Data sets
{: .no_toc }

The core package ships with example networks, so every tutorial and help example can be run as written. Load any of them with `nwwebuse`, which reads the file from the project's GitHub repository:

```stata
. nwwebuse florentine, nwclear
. nwsummarize
```

`nwclear` removes networks already in memory first. `help netexample` in Stata lists the same data sets with their variable codings. The node and tie counts below were checked by loading each data set with the current core.

## Friendship and social networks over time

### glasgow: Teenage Friends and Lifestyle Study
- **What:** 50 girls from a school in the West of Scotland, friendship nominations (up to twelve best friends) at three waves, directed. Networks `glasgow1`, `glasgow2`, `glasgow3` (113, 116 and 122 ties). Attributes: smoking, alcohol use and sport at each wave.
- **Source:** an excerpt of the Teenage Friends and Lifestyle Study. Michell, L. and Amos, A. (1997), *Social Science & Medicine* 44, 1861-1869; Pearson, M. and Michell, L. (2000), *Drugs: Education, Prevention and Policy* 7, 21-37; Pearson, M. and West, P. (2003), *Connections* 25(2), 59-76.
- **Load:** `nwwebuse glasgow`
- **Used in:** [nwsaom tutorials 1](../nwsaom/tutorial-1-first-saom/), [4](../nwsaom/tutorial-4-selection-influence/), [5](../nwsaom/tutorial-5-testing-comparing/) and [6](../nwsaom/tutorial-6-beyond/).

### s50
- **What:** 50 actors, friendship at three waves, directed. Networks `s50_w1`, `s50_w2`, `s50_w3` (113, 116 and 122 ties, the same counts as `glasgow`). Attributes: alcohol and smoking at each wave. This is the 50-actor example that RSiena calls `s50`.
- **Source:** the 50-girl excerpt of the Teenage Friends and Lifestyle Study that is distributed as `s50` with RSiena; the networks are the same as in `glasgow` above (the tie counts agree at all three waves), which also has the sport variable. References as for `glasgow`.
- **Load:** `nwwebuse s50`
- **Used in:** [Tutorial 10 (longitudinal models: an overview)](../tutorials/10-intro-longitudinal-models/).

### klas12b: a Dutch school class
- **What:** 26 students (17 girls, 9 boys) in their first year of secondary school, friendship at four waves three months apart, directed. Networks `klas12b_wave1` to `klas12b_wave4`, plus `klas12b_primary` (same primary school). Attributes: delinquency (four waves), alcohol (waves 2-4), sex, age, ethnicity, religion, school advice.
- **Source:** collected by Andrea Knecht (supervised by Chris Baerveldt, University of Utrecht), 2003-2004. Knecht, A. (2008), *Friendship Selection and Friends' Influence*, PhD dissertation, University of Utrecht. Knecht, Snijders, Baerveldt, Steglich and Raub, "Friendship and delinquency: selection and influence processes in early adolescence", *Social Development*, [doi:10.1111/j.1467-9507.2009.00564.x](https://doi.org/10.1111/j.1467-9507.2009.00564.x).
- **Load:** `nwwebuse klas12b`
- **Used in:** listed in the [`netexample` reference](../reference/netexample); no tutorial yet.

### hpotter: peer support in the Harry Potter books
- **What:** support ties among 64 characters in each of the six books (`hpbook1` to `hpbook6`), directed. Attributes: school year, gender, house.
- **Source:** Bossaert, G. and Meidert, N. (2013), "We are only as strong as we are united, as weak as we are divided: a dynamic analysis of the peer support networks in the Harry Potter books", *Open Journal of Applied Sciences* 3(2), 174-185, [doi:10.4236/ojapps.2013.32024](https://doi.org/10.4236/ojapps.2013.32024).
- **Load:** `nwwebuse hpotter`
- **Used in:** listed in the [`netexample` reference](../reference/netexample); no tutorial yet.

### kapferer: a tailor shop in Zambia
- **What:** interaction among workers of a tailor shop at two time points around a labor dispute, undirected: `kapferer_t1` (39 nodes, 158 ties) and `kapferer_t2` (43 nodes, 190 ties). The two networks do not share a node set, so this is not a panel on the same actors. No attributes.
- **Source:** Kapferer, B. (1972), *Strategy and Transaction in an African Factory*, Manchester University Press.
- **Load:** `nwwebuse kapferer`
- **Used in:** [nwergm tutorial 3](../nwergm/tutorial-3-diagnostics/).

## One-time networks

### lazega: lawyers in a corporate law firm
- **What:** 71 lawyers, three directed networks: advice (`lazega_adv`, 892 ties), co-work (`lazega_cow`) and friendship (`lazega_fr`, 575 ties). Attributes: age, gender, office, practice, school, seniority, status, years with the firm.
- **Source:** Lazega, E. (2001), *The Collegial Phenomenon*, Oxford University Press; Lazega, E. and van Duijn, M. (1997), *Social Networks* 19, 375-397.
- **Load:** `nwwebuse lazega`
- **Used in:** [nwergm tutorials 2](../nwergm/tutorial-2-terms/), [3](../nwergm/tutorial-3-diagnostics/) and [5](../nwergm/tutorial-5-constraints-twomode-operators/).

### mesa: Faux Mesa High
- **What:** a simulated friendship network of 205 students, undirected, 203 ties, 57 isolates. Attributes: grade, race, sex.
- **Source:** simulated to match the size and composition of a school in the National Longitudinal Study of Adolescent Health; it is the `faux.mesa.high` example of R's ergm (Hunter, Handcock, Butts, Goodreau and Morris 2008, *Journal of Statistical Software* 24(3)). It is not real survey data.
- **Load:** `nwwebuse mesa`
- **Used in:** [nwergm tutorial 2](../nwergm/tutorial-2-terms/).

### florentine: Florentine families
- **What:** 16 Renaissance Florentine families, marriage ties (`flomarriage`, undirected, 20 ties) and business ties (`flobusiness`, undirected, 15 ties). Attributes: wealth and number of priorates.
- **Source:** Padgett, J. F. (1994), *Marriage and Elite Structure in Renaissance Florence, 1282-1500*, paper delivered to the Social Science History Association; Breiger, R. and Pattison, P. (1986), "Cumulated social roles", *Social Networks* 8, 215-256.
- **Load:** `nwwebuse florentine`
- **Used in:** the core tutorials [3](../tutorials/03-importing-exporting/), [6](../tutorials/06-manipulating-networks/) and [7](../tutorials/07-centrality/).

### sampson: Sampson's monastery
- **What:** 18 novice monks; ranked choices (1 to 3, valued, directed) at three times (`samplk1` to `samplk3`) and a liking ranking (`samplike`, 88 ties). Attributes: faction (Loyal, Turks, Outcasts) and "Cloisterville".
- **Source:** Sampson, S. F. (1969), *Crisis in a Cloister*, unpublished doctoral dissertation, Cornell University.
- **Load:** `nwwebuse sampson`
- **Used in:** listed in the [`netexample` reference](../reference/netexample); no tutorial yet.

### zachary: karate club
- **What:** 34 members of a university karate club, undirected: `zachary_bin` (binary) and `zachary_val` (valued, 78 ties, values up to 7). Attribute: the faction each member joined after the split.
- **Source:** Zachary, W. W. (1977), "An information flow model for conflict and fission in small groups", *Journal of Anthropological Research* 33, 452-473.
- **Load:** `nwwebuse zachary`
- **Used in:** listed in the [`netexample` reference](../reference/netexample); no tutorial yet.

### gang: a London street gang
- **What:** 54 members of a youth gang, undirected, 133 ties (the reference lists tie types from hanging out to co-offending). Attributes: age, birthplace, residence, arrests, convictions, prison, music.
- **Source:** collected by James Densley and Thomas Grund. Grund, T. and Densley, J. (2012), *European Journal of Criminology* 9(3), 388-406; Grund, T. and Densley, J. (2014), *Journal of Contemporary Criminal Justice*.
- **Load:** `nwwebuse gang`
- **Used in:** examples in the [command reference](../reference/nwplot).

### usstates: US state borders
- **What:** 50 US states, undirected, 107 ties (two states share a land border). Node labels are the two-letter abbreviations.
- **Source:** see `help netexample`.
- **Load:** `nwwebuse usstates`
- **Used in:** listed in the [`netexample` reference](../reference/netexample); no tutorial yet.

## Two-mode (affiliation) networks

Both data sets are two-mode networks: nodes of the first mode (people, `_nwmode` = 1) are tied to nodes of the second mode (events or companies, `_nwmode` = 2), and there are no ties inside a mode. Use `nwdegree`, `nwclustering`, `nwmotifs` and `nw2project` for them (the commands recognise a two-mode network); `nw2project` turns each one into a one-mode network of the people or of the events or companies.

### davis: Southern women
- **What:** 18 women of a Southern US town ("Old City") and the 14 social events they attended in 1936, as reported in the local newspaper: 32 nodes and 89 ties, undirected, unvalued. Network `davis`, mode 1 `woman`, mode 2 `event`. Women are labeled by first name; events are labeled `E1` to `E14`. Attributes: `surname` and `title` (Miss or Mrs) for the women, `eventdate` (year-month-day, all 1936) for the events. The projection to the women has 139 ties (the number of shared events is the tie value, up to 7), the projection to the events 66 ties (up to 9).
- **Source:** Davis, A., Gardner, B. B. and Gardner, M. R. (1941), *Deep South: A Social Anthropological Study of Caste and Class*, University of Chicago Press. The attendance matrix is the classic one that is distributed with many network programs; the names are the pseudonyms of the book.
- **Licence and redistribution:** Davis, A., Gardner, B. B. and Gardner, M. R. (1941), *Deep South: A Social Anthropological Study of Caste and Class*, University of Chicago Press. The attendance matrix, the pseudonymous names and the event dates are those of the 1941 publication as distributed in the CRAN package manynet and in other network software. The data have no licence statement of their own, so no licence is asserted here: they are facts (who attended which event), not covered by the GPL-3 of this package, and are redistributed with citation of the source.
- **Load:** `nwwebuse davis`
- **Used in:** [Tutorial 9 (two-mode networks)](../tutorials/11-two-mode-networks/); examples for `nwdegree`, `nw2project` and `nwcommunity`.

### ftdirectors_se: company directors in Sweden
- **What:** 5,092 directors and the 455 Swedish listed companies on whose boards they sit: 5,547 nodes and 5,669 ties, undirected, unvalued. Network `ftdirectors_se`, mode 1 `director`, mode 2 `company`. Directors and companies carry only anonymous identifiers (`P00001`..., `C0001`...). Attributes of the directors: `gender` (1,025 women, 3,485 men, 582 unknown) and `age`; attributes of the companies: `sector`, `industry` and `employees` (number of employees). Missing values are empty (text) or missing (numbers). Most directors sit on one board (390 sit on two to seven), and the projection to the companies (759 ties) falls apart into many small groups of interlocked companies and a large number of companies with no shared director.
- **Source:** Evtushenko, A. and Gastner, M. T. (2019), *Data set discussed in "Beyond Fortune 500: Women in a Global Network of Directors"*, Zenodo, [doi:10.5281/zenodo.3553442](https://doi.org/10.5281/zenodo.3553442), licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). The original data come from the company profiles of the Financial Times web site, retrieved on 17 September 2016 (321,869 persons, 34,769 companies and 377,060 ties in 54 countries). See Evtushenko, A. and Gastner, M. T. (2020), "Beyond Fortune 500: Women in a Global Network of Directors", in Cherifi, H. et al. (eds.), *Complex Networks and Their Applications VIII*, vol. 1, Springer, 586-598, [arXiv:1910.07441](https://arxiv.org/abs/1910.07441).
- **Changes (derived data set):** this is a subset of the original data, adapted by Thomas U. Grund. Only the companies located in Sweden and all of their directors were kept. Of the original columns, the director's gender and age and the company's sector, industry and number of employees were kept; the other columns were dropped. The identifiers were renamed, the entry "NA" was turned into a missing value, age and the number of employees were made numeric, and the result was stored in the nwcommands network file format. No values were otherwise altered.
- **Licence and redistribution:** Evtushenko, A. and Gastner, M. T. (2019), *Data set discussed in "Beyond Fortune 500: Women in a Global Network of Directors"*, Zenodo, https://doi.org/10.5281/zenodo.3553442, licensed under the Creative Commons Attribution 4.0 International licence (CC BY 4.0, https://creativecommons.org/licenses/by/4.0/); see also Evtushenko, A. and Gastner, M. T. (2020), "Beyond Fortune 500: Women in a Global Network of Directors", in Cherifi, H. et al. (eds.), *Complex Networks and Their Applications VIII*, Springer, 586-598. The original data were generated from the company profiles of the Financial Times web site (retrieved 17 September 2016). This file is a derived subset, adapted by Thomas U. Grund: only the companies located in Sweden and all of their directors were kept (5,092 directors, 455 companies, 5,669 ties); of the original columns only the director's gender and age and the company's sector, industry and number of employees were kept; identifiers were renamed, "NA" entries were turned into missing values, age and number of employees were made numeric, and the result was stored in the nwcommands network file format. This file stays under CC BY 4.0 (attribution required); it is not covered by the GPL-3 of the code.
- **Load:** `nwwebuse ftdirectors_se`
- **Used in:** [Tutorial 9 (two-mode networks)](../tutorials/11-two-mode-networks/); examples for `nwdegree`, `nw2project`, `nwcommunity` and for the homophily and assortativity commands. For plots use the projection to the companies; the director side is large.

## Signed networks

These networks are valued networks whose ties are +1 (positive: alliance, co-operation) or -1 (negative: enmity, opposition); no tie is 0. They are the examples for `nwbalance` (strong structural balance) and for the positive, negative and signed degree (`nwrecode` the positive and the negative part, then `nwdegree`). Load one of them with `nwclear` if other networks are in memory.

### senate114 and senate93: US Senate co-sponsorship
- **What:** signed networks of the US Senate, undirected. `senate114` (114th Congress, 2015-16): 100 senators, 1,435 positive and 2,261 negative ties (3,696 of 4,950 pairs); `senate93` (93rd Congress, 1973-74): 101 senators, 581 positive and 1,858 negative ties. Network `senate114` or `senate93`. Attributes: `state` and `party` (D, R, I; the 93rd Senate also has one senator with the party C, Conservative). Node names are the senators' surname and initial. A positive tie means that two senators co-sponsored significantly more bills together than expected by chance, a negative tie significantly fewer.
- **Balance:** of the 74,140 closed triads of `senate114`, 72,139 (97.3 percent) are balanced; of the 25,355 closed triads of `senate93` only 13,947 (55.0 percent). In the 114th Senate 95 percent of the ties between senators of the same party are positive and 97 percent of the ties between parties are negative. The two numbers describe two cross sections and are not a test of how balance changes.
- **Source:** Neal, Z. P. (2020), *A Sign of the Times: Dataset of US Congress signed network backbones from co-sponsorship data, 1973-2016*, figshare, https://doi.org/10.6084/m9.figshare.8096429, licensed under the Creative Commons Attribution 4.0 International licence (CC BY 4.0, https://creativecommons.org/licenses/by/4.0/); described in Neal, Z. P. (2020), "A sign of the times? Weak and strong polarization in the U.S. Congress, 1973-2016", *Social Networks* 60, 103-112, https://doi.org/10.1016/j.socnet.2018.07.007; the method is that of Neal, Z. P. (2014), "The backbone of bipartite projections: Inferring relationships from co-authorship, co-sponsorship, co-attendance and other co-behaviors", *Social Networks* 39, 84-97, https://doi.org/10.1016/j.socnet.2014.06.001.
- **Changes (derived data set):** These files are a derived subset, adapted by Thomas U. Grund: only the Senates of the 93rd (1973-74) and the 114th (2015-16) Congress were kept (the two sheets S93 and S114 of the workbook); of the original columns only the tie sign (+1, -1; no tie is 0) and, from the row labels "Name (ST-P)", the senator's name, state and party were kept; the result is stored in the nwcommands network file format. The files stay under CC BY 4.0; they are not covered by the GPL-3 of the code. Caveat: the signs are not observed likes and dislikes. They are inferred from bill co-sponsorship by a statistical model (the stochastic degree sequence model): +1 means two senators co-sponsored more bills together than expected by chance, -1 that they co-sponsored fewer.
- **Caveat:** the networks are dense (75 percent of all pairs in the 114th Senate carry a tie) and the signs come from a model, so a high share of balanced triads is partly built in; treat the data as an example of a signed network and not as a measurement of friendship.
- **Load:** `nwwebuse senate114` and `nwwebuse senate93`
- **Used in:** no tutorial yet; examples for `nwbalance` and the signed degree.

### gahuku: Gahuku-Gama tribes
- **What:** alliances (positive, *rova*) and enmities (negative, *hina*) among 16 tribes of the Eastern Central Highlands of New Guinea, undirected: 16 nodes, 29 positive and 29 negative ties (58 of 120 pairs). Network `gahuku`; the nodes are named by tribe (Alika, Asaro, Gahuk, Gama, Gavev, Geham, Kohik, Kotun, Masil, Nagad, Nagam, Notoh, Ove, Seuve, Uheto, Ukudz); no attributes.
- **Balance:** 68 closed triads, 59 balanced and 9 unbalanced in the strong sense; only 2 of them violate weak balance (7 of the 9 have three negative ties, which weak balance allows), so the network has three camps rather than two. Signed degree (positive minus negative) runs from -3 to 7.
- **Source and licence:** Read, K. E. (1954), "Cultures of the Central Highlands, New Guinea", *Southwestern Journal of Anthropology* 10(1), 1-43, https://doi.org/10.1086/soutjanth.10.1.3629074; the signed network of the 16 tribes was analysed by Hage, P. and Harary, F. (1983), *Structural Models in Anthropology*, Cambridge University Press. The data have no licence statement of their own, so no licence is asserted here: they are facts (which of the 16 tribes are allied and which are enemies), not covered by the GPL-3 of this package, and are redistributed with citation of the sources. The ties are taken from the version distributed with the R package signnet (data set tribes), which cites the UCINET data file gama.dat.
- **Load:** `nwwebuse gahuku`
- **Used in:** no tutorial yet; the small example for strong and weak balance.

## Event data

### socialevolution: phone calls in a dormitory
- **What:** 439 timestamped phone calls among students of a university dormitory over about six weeks; 54 of the 84 students appear in a call. This is plain data, not a ready network: declare it with `nwset`. A second file, `socialevolution_nodes`, has floor and class year for all 84 students.
- **Source:** MIT Media Lab "Social Evolution" study (Reality Commons), abbreviated version distributed with R's goldfish. Madan, A., Cebrian, M., Moturu, S., Farrahi, K. and Pentland, A. (2012), "Sensing the 'health state' of a community", *IEEE Pervasive Computing* 11(4), 36-45, [doi:10.1109/MPRV.2011.79](https://doi.org/10.1109/MPRV.2011.79).
- **Load:**
  ```stata
  . nwwebuse socialevolution, nwclear
  . nwset sender receiver, eventtime(t) name(calls)
  ```
- **Used in:** [nwdynam tutorial 1](../nwdynam/tutorial-1-first-dynam/) and [nwrem tutorial 1](../nwrem/tutorial-1-first-rem/) (both use the same 439 calls, read from a file in the tutorial folder).

## Networks that are not social

These show that the commands work on any network.

### macaque: cortical areas of the macaque
- **What:** 45 visuotactile areas of the macaque cortex, directed, 463 ties (a projection from one area to another).
- **Source:** Negyessy, L., Nepusz, T., Kocsis, L. and Bazso, F. (2006), *European Journal of Neuroscience* 23(7), 1919-1930.
- **Load:** `nwwebuse macaque`

### chesapeake: a food web
- **What:** 39 compartments of the Chesapeake Bay ecosystem, directed and valued (carbon flow), 176 ties. Attributes: compartment type and biomass.
- **Source:** Baird, D. and Ulanowicz, R. E. (1989), "The seasonal dynamics of the Chesapeake Bay ecosystem", *Ecological Monographs* 59, 329-364.
- **Load:** `nwwebuse chesapeake`

### usair: US airports
- **What:** the 50 busiest US airports, directed, direct routes between them. Attributes: name, city, latitude, longitude, degree in the full US network.
- **Source and licence:** OpenFlights airport and route databases, [openflights.org/data](https://openflights.org/data), made available under the [Open Database License (ODbL 1.0)](https://opendatacommons.org/licenses/odbl/1-0/). This is a derived database, adapted by Thomas U. Grund (see `usair_full` below for the changes); it is offered under the ODbL, not under the GPL-3 of the code.
- **Load:** `nwwebuse usair`

### usair_full: the full US airport network
- **What:** every US airport with at least one scheduled non-stop domestic route in OpenFlights' route database: 549 airports and 5,450 directed routes (density 0.018). Network `usair_full`, node names are the IATA codes (ATL, DEN, ...). Attributes: `iata`, `name`, `city`, `lat`, `lon` and the out-, in- and total degree (`_outdegree`, `_indegree`, `_degree`). The network falls into three connected components: 541 airports, an Alaska/Aleutian seaplane cluster of 4 and a San Juan Islands seaplane cluster of 4. A real example of a larger, messier network: Anchorage has by far the largest betweenness, and closeness needs `unconnected(max)`.
- **Source:** OpenFlights, *Airport Database* and *Route Database*, [openflights.org/data](https://openflights.org/data). The page states: "The OpenFlights Airport, Airline, Plane and Route Databases are made available under the Open Database License." and "Any rights in individual contents of the database are licensed under the Database Contents License." (ODbL 1.0, [opendatacommons.org/licenses/odbl/1-0](https://opendatacommons.org/licenses/odbl/1-0/); DbCL 1.0, [opendatacommons.org/licenses/dbcl/1.0](http://opendatacommons.org/licenses/dbcl/1.0/)). The airport data derive from OurAirports and DAFIF and the route data from Airline Route Mapper, which the page calls public domain. The route data are from about 2014: the third party that supplies them stopped updating them in June 2014, so the network is a snapshot and not today's flight schedule.
- **Changes (derived database):** adapted by Thomas U. Grund. Only airports in the United States with an IATA code were used. A tie runs from the origin to the destination airport if the route database lists at least one route between them; duplicates over airlines were merged and there are no self-loops. Airports without such a route were dropped. Of the original columns the IATA code, name, city, latitude and longitude were kept and the degrees were added. The result is stored in the nwcommands network file format.
- **Licence and redistribution:** this derived database is made available under the Open Database License 1.0 (ODbL), with attribution to OpenFlights (openflights.org); any database derived from it must again be offered under the ODbL and kept open. It is not covered by the GPL-3 of the code.
- **Load:** `nwwebuse usair_full`
- **Used in:** the book *Network Analysis with Stata* (performance appendix); examples for the centrality commands, `nwcomponents` and `nwcloseness, unconnected(max)`.

## Data sets used by RSiena and where to find them

The Siena project describes and distributes its example data at [stats.ox.ac.uk/~snijders/siena/siena_datasets.htm](https://www.stats.ox.ac.uk/~snijders/siena/siena_datasets.htm). The table says which of them you can load here; for the others, download the files from the Siena page and read them in with the [import commands](../tutorials/03-importing-exporting/).

| Siena data set | In nwcommands? |
|---|---|
| EIES | no |
| Kapferer tailor shop | yes: `nwwebuse kapferer` |
| van de Bunt students | no |
| Zeggelink students | no |
| van Duijn students | no |
| Knecht classroom | yes: `nwwebuse klas12b` |
| Teenage Friends and Lifestyle Study (the `s50` excerpt and Glasgow) | yes: `nwwebuse s50` and `nwwebuse glasgow` |
| Baerveldt | no |
| Harry Potter | yes: `nwwebuse hpotter` |
| Lazega lawyers | yes: `nwwebuse lazega` |

Please check the terms of use on the Siena page before you reuse these data.
