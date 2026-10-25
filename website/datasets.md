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

Both data sets are two-mode networks: nodes of the first mode (people, `_nwmode` = 1) are tied to nodes of the second mode (events or companies, `_nwmode` = 2), and there are no ties inside a mode. Use `nw2degree`, `nw2clustering` and `nw2project` for them; `nw2project` turns each one into a one-mode network of the people or of the events or companies.

### davis: Southern women
- **What:** 18 women of a Southern US town ("Old City") and the 14 social events they attended in 1936, as reported in the local newspaper: 32 nodes and 89 ties, undirected, unvalued. Network `davis`, mode 1 `woman`, mode 2 `event`. Women are labeled by first name; events are labeled `E1` to `E14`. Attributes: `surname` and `title` (Miss or Mrs) for the women, `eventdate` (year-month-day, all 1936) for the events. The projection to the women has 139 ties (the number of shared events is the tie value, up to 7), the projection to the events 66 ties (up to 9).
- **Source:** Davis, A., Gardner, B. B. and Gardner, M. R. (1941), *Deep South: A Social Anthropological Study of Caste and Class*, University of Chicago Press. The attendance matrix is the classic one that is distributed with many network programs (for example the R package manynet and the UCINET and Pajek collections); the names are the pseudonyms of the book. The data have no licence of their own; the file contains only the facts of who attended which event.
- **Load:** `nwwebuse davis`
- **Used in:** no tutorial yet; examples for `nw2degree`, `nw2project` and `nwcommunity`.

### ftdirectors_se: company directors in Sweden
- **What:** 5,092 directors and the 455 Swedish listed companies on whose boards they sit: 5,547 nodes and 5,669 ties, undirected, unvalued. Network `ftdirectors_se`, mode 1 `director`, mode 2 `company`. Directors and companies carry only anonymous identifiers (`P00001`..., `C0001`...). Attributes of the directors: `gender` (1,025 women, 3,485 men, 582 unknown) and `age`; attributes of the companies: `sector`, `industry` and `employees` (number of employees). Missing values are empty (text) or missing (numbers). Most directors sit on one board (390 sit on two to seven), and the projection to the companies (759 ties) falls apart into many small groups of interlocked companies and a large number of companies with no shared director.
- **Source:** Evtushenko, A. and Gastner, M. T. (2019), *Data set discussed in "Beyond Fortune 500: Women in a Global Network of Directors"*, Zenodo, [doi:10.5281/zenodo.3553442](https://doi.org/10.5281/zenodo.3553442), licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). The original data come from the company profiles of the Financial Times web site, retrieved on 17 September 2016 (321,869 persons, 34,769 companies and 377,060 ties in 54 countries). See Evtushenko, A. and Gastner, M. T. (2020), "Beyond Fortune 500: Women in a Global Network of Directors", in Cherifi, H. et al. (eds.), *Complex Networks and Their Applications VIII*, vol. 1, Springer, 586-598, [arXiv:1910.07441](https://arxiv.org/abs/1910.07441).
- **Changes (derived data set):** this is a subset of the original data, adapted by Thomas U. Grund. Only the companies located in Sweden and all of their directors were kept. Of the original columns, the director's gender and age and the company's sector, industry and number of employees were kept; the other columns were dropped. The identifiers were renamed, the entry "NA" was turned into a missing value, age and the number of employees were made numeric, and the result was stored in the nwcommands network file format. No values were otherwise altered.
- **Load:** `nwwebuse ftdirectors_se`
- **Used in:** no tutorial yet; examples for `nw2degree`, `nw2project`, `nwcommunity` and for the homophily and assortativity commands. For plots use the projection to the companies; the director side is large.

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
- **Source:** OpenFlights airport and route databases, [openflights.org/data.php](https://openflights.org/data.php), Open Database License.
- **Load:** `nwwebuse usair`

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
