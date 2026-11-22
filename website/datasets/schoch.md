---
title: "Schoch networkdata"
parent: "Data sets"
permalink: /datasets/schoch/
description: "The 2,274 networks of David Schoch's R package networkdata, loadable with nwwebuse schoch: what they are, where they come from, how to cite them."
---

# The networkdata collection (Schoch)
{: .no_toc }

nwcommands ships none of these networks. `nwwebuse schoch <name>` (or `nwnetworkdata <name>`) downloads the original file from David Schoch's repository <https://github.com/schochastics/networkdata> when you ask for it, keeps it in a cache in your PLUS directory, reads it on your computer with Stata alone (no R is needed; the option `withr` of `nwnetworkdata` uses R with the package igraph instead, and the ego-centered object `gss_egor` falls back to R when R is installed) and builds the network.

**Licence and citation.** The R package is distributed under the MIT licence (Copyright (c) 2019 David Schoch), which covers the package itself. It documents no licence or permission for the individual data sets, which come from many original sources and may have their own terms. nwcommands ships none of them and downloads them from the source only on request; please check the original source of every data set you use and cite it, together with the collection:

> Schoch, D. (2022). *networkdata: Repository of Network Datasets*. <https://doi.org/10.5281/zenodo.7189928>

For the tennis networks `atp` and `wta` the package asks to give credit to Jeff Sackmann (<https://github.com/JeffSackmann>), from whose data they were constructed.

This page is our own overview: the descriptions are written by us, not copied from the package, and have not been checked against the original sources. The official documentation of every data set is in the package reference at <https://schochastics.github.io/networkdata/reference/> (one page per data set, for example [karate](https://schochastics.github.io/networkdata/reference/karate.html)). The package says that many of the data sets were assembled automatically and may contain errors.

```stata
. nwwebuse schoch list
. nwwebuse schoch describe karate
. nwwebuse schoch karate, nwclear
. nwwebuse schoch sampson, nwclear element(3)
```

A data set that is a *list of networks* (waves, seasons, groups) is loaded with all its networks, called `name_1`, `name_2`, ...; `element()` loads some of them. Sizes are nodes and ties as stored in R (parallel ties counted separately). "Type" gives the properties of the networks as listed in the catalogue; "some networks only" means that the property holds for some elements of a list.

## Summary

990 R objects: 917 single igraph networks, 72 lists of networks (together 1357 networks) and 1 ego-centered egor object (not a network). 2274 networks in total: 1962 undirected, 289 directed, 23 two-mode; 1823 with edge weights, 121 with multiple edges, 44 with loops, 7 with edge time stamps.

- [Animal social networks (Animal Social Network Repository)](#animal): 36 data sets
- [Covert networks](#covert): 46 data sets
- [Freeman's data sets (UCINET / Moreno collection)](#freeman): 60 data sets
- [KONECT networks](#konect): 22 data sets
- [Miscellaneous networks](#misc): 17 data sets
- [Movie networks (Harvard Dataverse)](#movies): 773 data sets
- [Shakespeare's plays](#shakespeare): 36 data sets

## Animal social networks (Animal Social Network Repository)
{: #animal }

Social networks of animals, taken by the package from the Animal Social Network Repository (<https://bansallab.github.io/asnr/>). Nodes are individual animals of one species; ties are observed interactions or associations such as proximity, shared group membership, grooming, food sharing or dominance. Most are valued; many data sets are lists of several networks (replicate groups or periods). The title names the species and the kind of interaction. The repository documents species, setting, observation method and the study reference of every data set: see the upstream page of each data set (<https://schochastics.github.io/networkdata/reference/animal_1.html> and so on) and cite the original study.

| Name | Title | Networks | Nodes | Ties | Type |
|---|---|---|---|---|---|
| <a id="animal_1"></a>[`animal_1`](https://schochastics.github.io/networkdata/reference/animal_1.html) | Fishstickleback Proximity (weighted) | 7 | 10 | 45 | undirected, valued |
| <a id="animal_10"></a>[`animal_10`](https://schochastics.github.io/networkdata/reference/animal_10.html) | Philetairus socius | 23 | 5-64 | 9-177 | undirected |
| <a id="animal_11"></a>[`animal_11`](https://schochastics.github.io/networkdata/reference/animal_11.html) | Wild birds | 6 | 126-149 | 1444-2837 | undirected, valued |
| <a id="animal_12"></a>[`animal_12`](https://schochastics.github.io/networkdata/reference/animal_12.html) | Ants Proximity (weighted) | 244 | 35-164 | 480-11139 | undirected, valued |
| <a id="animal_13"></a>[`animal_13`](https://schochastics.github.io/networkdata/reference/animal_13.html) | Ants Trophallaxis (weighted) | 16 | 24-37 | 23-68 | undirected, valued |
| <a id="animal_14"></a>[`animal_14`](https://schochastics.github.io/networkdata/reference/animal_14.html) | Beetle Proximity (weighted) | 12 | 27-30 | 117-210 | undirected, valued, loops (some networks only) |
| <a id="animal_15"></a>[`animal_15`](https://schochastics.github.io/networkdata/reference/animal_15.html) | Asianelephants Dominance (unweighted) | 1 | 73 | 60 | undirected, valued |
| <a id="animal_16"></a>[`animal_16`](https://schochastics.github.io/networkdata/reference/animal_16.html) | Baboon Association (weighted) | 58 | 4-26 | 0-41 | undirected, valued (some networks only) |
| <a id="animal_17"></a>[`animal_17`](https://schochastics.github.io/networkdata/reference/animal_17.html) | Bats Foodsharing (weighted) | 1 | 21 | 72 | undirected, valued |
| <a id="animal_18"></a>[`animal_18`](https://schochastics.github.io/networkdata/reference/animal_18.html) | Bats Roostuse (weighted) | 1 | 43 | 546 | undirected, valued |
| <a id="animal_19"></a>[`animal_19`](https://schochastics.github.io/networkdata/reference/animal_19.html) | Bison Dominance (weighted) | 1 | 26 | 222 | undirected, valued |
| <a id="animal_2"></a>[`animal_2`](https://schochastics.github.io/networkdata/reference/animal_2.html) | Guppy Proximity Frequency (weighted) | 9 | 6 | 15 | undirected, valued |
| <a id="animal_20"></a>[`animal_20`](https://schochastics.github.io/networkdata/reference/animal_20.html) | Cattle Dominance (weighted) | 1 | 28 | 205 | undirected, valued |
| <a id="animal_21"></a>[`animal_21`](https://schochastics.github.io/networkdata/reference/animal_21.html) | Dolphin Association (weighted) | 4 | 151-291 | 1032-3182 | undirected, valued |
| <a id="animal_22"></a>[`animal_22`](https://schochastics.github.io/networkdata/reference/animal_22.html) | Dolphin Proximity (unweighted) | 1 | 62 | 159 | undirected |
| <a id="animal_23"></a>[`animal_23`](https://schochastics.github.io/networkdata/reference/animal_23.html) | Elephantseal Dominance (weighted) | 4 | 18-50 | 15-58 | undirected, valued |
| <a id="animal_24"></a>[`animal_24`](https://schochastics.github.io/networkdata/reference/animal_24.html) | Hyenas Groupmembership (weighted) | 3 | 35-36 | 509-585 | undirected, valued |
| <a id="animal_25"></a>[`animal_25`](https://schochastics.github.io/networkdata/reference/animal_25.html) | Kangeroos Proximity (weighted) | 1 | 17 | 91 | undirected, valued |
| <a id="animal_26"></a>[`animal_26`](https://schochastics.github.io/networkdata/reference/animal_26.html) | Possum Burrowsharing (weighted) | 1 | 15 | 13 | undirected, valued |
| <a id="animal_27"></a>[`animal_27`](https://schochastics.github.io/networkdata/reference/animal_27.html) | Primates Association (weighted) | 19 | 5-25 | 10-181 | undirected, valued |
| <a id="animal_28"></a>[`animal_28`](https://schochastics.github.io/networkdata/reference/animal_28.html) | Raccoon Proximity (weighted) | 52 | 8-24 | 17-100 | undirected, valued |
| <a id="animal_29"></a>[`animal_29`](https://schochastics.github.io/networkdata/reference/animal_29.html) | Rhesusmacaque Association (weighted) | 2 | 28 | 228-378 | undirected, valued |
| <a id="animal_3"></a>[`animal_3`](https://schochastics.github.io/networkdata/reference/animal_3.html) | Hirundo rustica | 2 | 17 | 53-122 | undirected, valued |
| <a id="animal_30"></a>[`animal_30`](https://schochastics.github.io/networkdata/reference/animal_30.html) | Rhesusmacaque Dominance (weighted) | 1 | 62 | 1167 | undirected, valued |
| <a id="animal_31"></a>[`animal_31`](https://schochastics.github.io/networkdata/reference/animal_31.html) | Sheep Dominance (weighted) | 1 | 28 | 235 | undirected, valued |
| <a id="animal_32"></a>[`animal_32`](https://schochastics.github.io/networkdata/reference/animal_32.html) | Spidermonkeys Contact (weighted) | 1 | 17 | 72 | undirected, valued, loops |
| <a id="animal_33"></a>[`animal_33`](https://schochastics.github.io/networkdata/reference/animal_33.html) | Voles Social Projection Bipartite (weighted) | 254 | 4-183 | 0-515 | undirected, valued (some networks only) |
| <a id="animal_34"></a>[`animal_34`](https://schochastics.github.io/networkdata/reference/animal_34.html) | Zebra Groupmembership (weighted) | 1 | 27 | 111 | undirected |
| <a id="animal_35"></a>[`animal_35`](https://schochastics.github.io/networkdata/reference/animal_35.html) | Desert Tortoise Asynchronous Burrow Sharing (unweighted) | 53 | 12-1100 | 5-479 | undirected |
| <a id="animal_36"></a>[`animal_36`](https://schochastics.github.io/networkdata/reference/animal_36.html) | Lizard Proximity (weighted) | 1 | 60 | 318 | undirected, valued |
| <a id="animal_4"></a>[`animal_4`](https://schochastics.github.io/networkdata/reference/animal_4.html) | Branta leucopsis | 2 | 20-23 | 190-253 | undirected, valued |
| <a id="animal_5"></a>[`animal_5`](https://schochastics.github.io/networkdata/reference/animal_5.html) | White Leghorn | 1 | 32 | 496 | undirected |
| <a id="animal_6"></a>[`animal_6`](https://schochastics.github.io/networkdata/reference/animal_6.html) | Haemorhous mexicanus | 1 | 117 | 1027 | undirected, valued |
| <a id="animal_7"></a>[`animal_7`](https://schochastics.github.io/networkdata/reference/animal_7.html) | Zonotrichia Atricapilla | 2 | 31-40 | 211-305 | undirected, valued |
| <a id="animal_8"></a>[`animal_8`](https://schochastics.github.io/networkdata/reference/animal_8.html) | Zonotrichia atricapilla | 2 | 27-46 | 164-348 | undirected, valued, loops (some networks only) |
| <a id="animal_9"></a>[`animal_9`](https://schochastics.github.io/networkdata/reference/animal_9.html) | Acanthiza | 1 | 62 | 1151 | undirected, valued |

## Covert networks
{: #covert }

Networks of terrorist, insurgent and criminal groups and of other covert or illicit activity (fraud, trafficking, gangs, and similar). The package took most of them from a collection reconstructed at the University of Manchester (<https://sites.google.com/site/ucinetsoftware/datasets/covert-networks>), many of which are also available from <http://doitapps.jjay.cuny.edu/jjatt/data.php>. Nodes are usually persons, in the two-mode cases persons and events, places or organisations; ties are relations such as acquaintance, joint participation or communication. A list holds several networks of the same group (time periods, relation types or sources). Details and the original publications for each data set are on its upstream page (<https://schochastics.github.io/networkdata/reference/covert_1.html> and so on).

Selected original references (from the package documentation): Krebs (2002), *Connections* 24(3) (9/11 hijackers, `covert_2`); Morselli (2009), *Inside Criminal Networks*, Springer (`covert_10`, `covert_13`); Natarajan (2000), *Crime Prevention Studies* 11, and (2006) (drug dealing networks, `covert_13`, `covert_21`); Koschade (2006), *Studies in Conflict and Terrorism* 29(6) (`covert_26`); Acosta and Childs (2013), *Studies in Conflict and Terrorism* 36(1) (`covert_19`); Grund and Densley (2015), *Journal of Contemporary Criminal Justice* 31(3) (London gang, `covert_28`); Asal and Rethemeyer (2008), *Journal of Politics* 70(2) (`covert_9`).

| Name | Title | Networks | Nodes | Ties | Type |
|---|---|---|---|---|---|
| <a id="covert_1"></a>[`covert_1`](https://schochastics.github.io/networkdata/reference/covert_1.html) | 17 November Greece Bombing | 5 | 18-30 | 9-52 | two-mode (some networks only) |
| <a id="covert_10"></a>[`covert_10`](https://schochastics.github.io/networkdata/reference/covert_10.html) | Caviar | 12 | 15-110 | 18-205 | undirected, valued |
| <a id="covert_11"></a>[`covert_11`](https://schochastics.github.io/networkdata/reference/covert_11.html) | Christmas Eve Bombings Indonesia 2000 | 14 | 45 | 2-233 | undirected, valued (some networks only) |
| <a id="covert_12"></a>[`covert_12`](https://schochastics.github.io/networkdata/reference/covert_12.html) | CielNet | 1 | 25 | 35 | undirected, valued |
| <a id="covert_13"></a>[`covert_13`](https://schochastics.github.io/networkdata/reference/covert_13.html) | Cocaine Dealing Natarajan | 1 | 28 | 40 | undirected, valued |
| <a id="covert_14"></a>[`covert_14`](https://schochastics.github.io/networkdata/reference/covert_14.html) | Cocaine Smuggling | 1 | 28 | 40 | undirected, valued |
| <a id="covert_15"></a>[`covert_15`](https://schochastics.github.io/networkdata/reference/covert_15.html) | Czech Corruption | 1 | 16 | 50 | undirected, valued |
| <a id="covert_16"></a>[`covert_16`](https://schochastics.github.io/networkdata/reference/covert_16.html) | Domestic Terrorist Web Links | 1 | 32 | 50 | undirected, loops |
| <a id="covert_17"></a>[`covert_17`](https://schochastics.github.io/networkdata/reference/covert_17.html) | Drugnet | 1 | 293 | 284 | undirected |
| <a id="covert_18"></a>[`covert_18`](https://schochastics.github.io/networkdata/reference/covert_18.html) | FIFA | 2 | 340-450 | 3328-5022 | undirected, valued |
| <a id="covert_19"></a>[`covert_19`](https://schochastics.github.io/networkdata/reference/covert_19.html) | Global Suicide Attacks | 17 | 4-31 | 3-44 | undirected, valued, loops (some networks only) |
| <a id="covert_2"></a>[`covert_2`](https://schochastics.github.io/networkdata/reference/covert_2.html) | 9/11 Hijackers | 2 | 19-60 | 27-126 | undirected, loops (some networks only) |
| <a id="covert_20"></a>[`covert_20`](https://schochastics.github.io/networkdata/reference/covert_20.html) | Hamburg Cell 9/11 2001 | 23 | 34 | 4-122 | undirected, valued |
| <a id="covert_21"></a>[`covert_21`](https://schochastics.github.io/networkdata/reference/covert_21.html) | Heroin Dealing Natarajan | 1 | 38 | 87 | undirected |
| <a id="covert_22"></a>[`covert_22`](https://schochastics.github.io/networkdata/reference/covert_22.html) | Islamic State Allegiances | 1 | 67 | 47 | two-mode |
| <a id="covert_23"></a>[`covert_23`](https://schochastics.github.io/networkdata/reference/covert_23.html) | Islamic State Group | 3 | 56 | 6-15 | undirected |
| <a id="covert_24"></a>[`covert_24`](https://schochastics.github.io/networkdata/reference/covert_24.html) | Italian Gangs | 1 | 67 | 114 | undirected |
| <a id="covert_25"></a>[`covert_25`](https://schochastics.github.io/networkdata/reference/covert_25.html) | Jakarta Bombing 2009 / Noordin Top | 4 | 28 | 13-38 | undirected, valued |
| <a id="covert_26"></a>[`covert_26`](https://schochastics.github.io/networkdata/reference/covert_26.html) | Jemaah Islamiyah Koschade | 1 | 17 | 63 | undirected, valued |
| <a id="covert_27"></a>[`covert_27`](https://schochastics.github.io/networkdata/reference/covert_27.html) | Linux Terrorists | 2 | 260-645 | 571-3172 | undirected |
| <a id="covert_28"></a>[`covert_28`](https://schochastics.github.io/networkdata/reference/covert_28.html) | London Gang | 1 | 54 | 315 | undirected, valued |
| <a id="covert_29"></a>[`covert_29`](https://schochastics.github.io/networkdata/reference/covert_29.html) | Madoff Fraud | 1 | 61 | 61 | undirected, loops |
| <a id="covert_3"></a>[`covert_3`](https://schochastics.github.io/networkdata/reference/covert_3.html) | Al Qaeda 1993-2003 | 33 | 271 | 1-109 | undirected |
| <a id="covert_30"></a>[`covert_30`](https://schochastics.github.io/networkdata/reference/covert_30.html) | Madrid Train Bombing 2004 | 25 | 54 | 0-226 | undirected, valued (some networks only) |
| <a id="covert_31"></a>[`covert_31`](https://schochastics.github.io/networkdata/reference/covert_31.html) | Mali Terrorist Network | 1 | 36 | 67 | undirected |
| <a id="covert_32"></a>[`covert_32`](https://schochastics.github.io/networkdata/reference/covert_32.html) | Montreal Street Gangs | 1 | 35 | 78 | undirected |
| <a id="covert_33"></a>[`covert_33`](https://schochastics.github.io/networkdata/reference/covert_33.html) | Ndrangheta Mafia 2 | 1 | 203 | 455 | two-mode |
| <a id="covert_34"></a>[`covert_34`](https://schochastics.github.io/networkdata/reference/covert_34.html) | Noordin Top | 10 | 79 | 11-267 | undirected |
| <a id="covert_35"></a>[`covert_35`](https://schochastics.github.io/networkdata/reference/covert_35.html) | Paul Revere | 2 | 254-261 | 334-10221 | two-mode, valued (some networks only) |
| <a id="covert_36"></a>[`covert_36`](https://schochastics.github.io/networkdata/reference/covert_36.html) | Philippine Kidnappings | 1 | 351 | 402 | two-mode |
| <a id="covert_37"></a>[`covert_37`](https://schochastics.github.io/networkdata/reference/covert_37.html) | Philippines Bombing | 15 | 16 | 1-69 | undirected, valued |
| <a id="covert_38"></a>[`covert_38`](https://schochastics.github.io/networkdata/reference/covert_38.html) | Provisional Irish Republican Army | 5 | 83-526 | 92-1025 | undirected |
| <a id="covert_39"></a>[`covert_39`](https://schochastics.github.io/networkdata/reference/covert_39.html) | Rhodes Bombing | 1 | 22 | 66 | undirected |
| <a id="covert_4"></a>[`covert_4`](https://schochastics.github.io/networkdata/reference/covert_4.html) | Australian Embassy Bombing, Indonesia 2004 | 15 | 27 | 1-112 | undirected, valued |
| <a id="covert_40"></a>[`covert_40`](https://schochastics.github.io/networkdata/reference/covert_40.html) | Saxena Terror India | 4 | 5-25 | 6-64 | undirected, valued (some networks only) |
| <a id="covert_41"></a>[`covert_41`](https://schochastics.github.io/networkdata/reference/covert_41.html) | Siren | 1 | 44 | 103 | undirected |
| <a id="covert_42"></a>[`covert_42`](https://schochastics.github.io/networkdata/reference/covert_42.html) | Slumlords | 7 | 5-22 | 4-23 | two-mode, loops (some networks only) |
| <a id="covert_43"></a>[`covert_43`](https://schochastics.github.io/networkdata/reference/covert_43.html) | Southeast Asian Aggregated Attacks 2005 | 48 | 108 | 1-160 | undirected, valued (some networks only) |
| <a id="covert_44"></a>[`covert_44`](https://schochastics.github.io/networkdata/reference/covert_44.html) | Suffragettes | 12 | 13-1614 | 2-1996 | two-mode, valued, loops (some networks only) |
| <a id="covert_45"></a>[`covert_45`](https://schochastics.github.io/networkdata/reference/covert_45.html) | Swingers | 1 | 96 | 232 | two-mode |
| <a id="covert_46"></a>[`covert_46`](https://schochastics.github.io/networkdata/reference/covert_46.html) | Kenya Tanzania Gerdes | 1 | 43 | 65 | two-mode |
| <a id="covert_47"></a>[`covert_47`](https://schochastics.github.io/networkdata/reference/covert_47.html) | Togo | 1 | 33 | 47 | undirected |
| <a id="covert_6"></a>[`covert_6`](https://schochastics.github.io/networkdata/reference/covert_6.html) | Bali Bombing 2002/Jemaah Islamiyah | 11 | 27 | 4-156 | undirected, valued |
| <a id="covert_7"></a>[`covert_7`](https://schochastics.github.io/networkdata/reference/covert_7.html) | Bali Bombing 2005 | 21 | 27 | 0-90 | undirected, valued (some networks only) |
| <a id="covert_8"></a>[`covert_8`](https://schochastics.github.io/networkdata/reference/covert_8.html) | Baseball Steroid Use | 2 | 72-84 | 84-1017 | two-mode, valued (some networks only) |
| <a id="covert_9"></a>[`covert_9`](https://schochastics.github.io/networkdata/reference/covert_9.html) | Big Allied and Dangerous (BAAD) | 2 | 394-459 | 394-4939 | two-mode, loops (some networks only) |

## Shakespeare's plays
{: #shakespeare }

Networks of the characters of one of Shakespeare's plays. Nodes are characters; two characters are tied, with a count as the tie value, when they appear together in scenes of the play. The package built them from raw data at <https://github.com/mallaham/Shakespeare-Plays>. Pages: <https://schochastics.github.io/networkdata/reference/shakespeare_1.html> and so on.

| Name | Title | Networks | Nodes | Ties | Type |
|---|---|---|---|---|---|
| <a id="shakespeare_1"></a>[`shakespeare_1`](https://schochastics.github.io/networkdata/reference/shakespeare_1.html) | A Comedy of Errors | 1 | 20 | 130 | undirected, valued |
| <a id="shakespeare_10"></a>[`shakespeare_10`](https://schochastics.github.io/networkdata/reference/shakespeare_10.html) | Henry IV | 1 | 35 | 152 | undirected, valued |
| <a id="shakespeare_11"></a>[`shakespeare_11`](https://schochastics.github.io/networkdata/reference/shakespeare_11.html) | Henry V | 1 | 47 | 228 | undirected, valued |
| <a id="shakespeare_12"></a>[`shakespeare_12`](https://schochastics.github.io/networkdata/reference/shakespeare_12.html) | Henry VI Part 1 | 1 | 52 | 314 | undirected, valued |
| <a id="shakespeare_13"></a>[`shakespeare_13`](https://schochastics.github.io/networkdata/reference/shakespeare_13.html) | Henry VI Part 2 | 1 | 64 | 422 | undirected, valued |
| <a id="shakespeare_14"></a>[`shakespeare_14`](https://schochastics.github.io/networkdata/reference/shakespeare_14.html) | Henry VI Part 3 | 1 | 46 | 272 | undirected, valued |
| <a id="shakespeare_15"></a>[`shakespeare_15`](https://schochastics.github.io/networkdata/reference/shakespeare_15.html) | Henry VIII | 1 | 46 | 212 | undirected, valued |
| <a id="shakespeare_16"></a>[`shakespeare_16`](https://schochastics.github.io/networkdata/reference/shakespeare_16.html) | Julius Caesar | 1 | 50 | 290 | undirected, valued |
| <a id="shakespeare_17"></a>[`shakespeare_17`](https://schochastics.github.io/networkdata/reference/shakespeare_17.html) | King John | 1 | 29 | 161 | undirected, valued |
| <a id="shakespeare_18"></a>[`shakespeare_18`](https://schochastics.github.io/networkdata/reference/shakespeare_18.html) | King Lear | 1 | 26 | 161 | undirected, valued |
| <a id="shakespeare_19"></a>[`shakespeare_19`](https://schochastics.github.io/networkdata/reference/shakespeare_19.html) | Loves Labours Lost | 1 | 20 | 143 | undirected, valued |
| <a id="shakespeare_2"></a>[`shakespeare_2`](https://schochastics.github.io/networkdata/reference/shakespeare_2.html) | A Midsummer nights dream | 1 | 30 | 238 | undirected, valued |
| <a id="shakespeare_20"></a>[`shakespeare_20`](https://schochastics.github.io/networkdata/reference/shakespeare_20.html) | macbeth | 1 | 41 | 188 | undirected, valued |
| <a id="shakespeare_21"></a>[`shakespeare_21`](https://schochastics.github.io/networkdata/reference/shakespeare_21.html) | Measure for measure | 1 | 25 | 110 | undirected, valued |
| <a id="shakespeare_22"></a>[`shakespeare_22`](https://schochastics.github.io/networkdata/reference/shakespeare_22.html) | Merchant of Venice | 1 | 23 | 119 | undirected, valued |
| <a id="shakespeare_23"></a>[`shakespeare_23`](https://schochastics.github.io/networkdata/reference/shakespeare_23.html) | Merry Wives of Windsor | 1 | 24 | 182 | undirected, valued |
| <a id="shakespeare_24"></a>[`shakespeare_24`](https://schochastics.github.io/networkdata/reference/shakespeare_24.html) | Much Ado about nothing | 1 | 24 | 140 | undirected, valued |
| <a id="shakespeare_25"></a>[`shakespeare_25`](https://schochastics.github.io/networkdata/reference/shakespeare_25.html) | Othello | 1 | 27 | 172 | undirected, valued |
| <a id="shakespeare_26"></a>[`shakespeare_26`](https://schochastics.github.io/networkdata/reference/shakespeare_26.html) | Pericles | 1 | 46 | 185 | undirected, valued |
| <a id="shakespeare_27"></a>[`shakespeare_27`](https://schochastics.github.io/networkdata/reference/shakespeare_27.html) | Richard II | 1 | 35 | 170 | undirected, valued |
| <a id="shakespeare_28"></a>[`shakespeare_28`](https://schochastics.github.io/networkdata/reference/shakespeare_28.html) | Richard III | 1 | 68 | 477 | undirected, valued |
| <a id="shakespeare_29"></a>[`shakespeare_29`](https://schochastics.github.io/networkdata/reference/shakespeare_29.html) | Romeo and Juliet | 1 | 34 | 233 | undirected, valued |
| <a id="shakespeare_3"></a>[`shakespeare_3`](https://schochastics.github.io/networkdata/reference/shakespeare_3.html) | A Winters Tale | 1 | 35 | 174 | undirected, valued |
| <a id="shakespeare_30"></a>[`shakespeare_30`](https://schochastics.github.io/networkdata/reference/shakespeare_30.html) | Taming of the Shrew | 1 | 37 | 226 | undirected, valued |
| <a id="shakespeare_31"></a>[`shakespeare_31`](https://schochastics.github.io/networkdata/reference/shakespeare_31.html) | The Tempest | 1 | 20 | 121 | undirected, valued |
| <a id="shakespeare_32"></a>[`shakespeare_32`](https://schochastics.github.io/networkdata/reference/shakespeare_32.html) | Timon of Athens | 1 | 55 | 352 | undirected, valued |
| <a id="shakespeare_33"></a>[`shakespeare_33`](https://schochastics.github.io/networkdata/reference/shakespeare_33.html) | Titus Andronicus | 1 | 27 | 179 | undirected, valued |
| <a id="shakespeare_34"></a>[`shakespeare_34`](https://schochastics.github.io/networkdata/reference/shakespeare_34.html) | Troilus and Cressida | 1 | 28 | 160 | undirected, valued |
| <a id="shakespeare_35"></a>[`shakespeare_35`](https://schochastics.github.io/networkdata/reference/shakespeare_35.html) | Twelfth Night | 1 | 18 | 101 | undirected, valued |
| <a id="shakespeare_36"></a>[`shakespeare_36`](https://schochastics.github.io/networkdata/reference/shakespeare_36.html) | Two Gentlemen of Verona | 1 | 17 | 55 | undirected, valued |
| <a id="shakespeare_4"></a>[`shakespeare_4`](https://schochastics.github.io/networkdata/reference/shakespeare_4.html) | Alls well that ends well | 1 | 24 | 112 | undirected, valued |
| <a id="shakespeare_5"></a>[`shakespeare_5`](https://schochastics.github.io/networkdata/reference/shakespeare_5.html) | Antony and Cleopatra | 1 | 54 | 313 | undirected, valued |
| <a id="shakespeare_6"></a>[`shakespeare_6`](https://schochastics.github.io/networkdata/reference/shakespeare_6.html) | As you like it | 1 | 27 | 110 | undirected, valued |
| <a id="shakespeare_7"></a>[`shakespeare_7`](https://schochastics.github.io/networkdata/reference/shakespeare_7.html) | Coriolanus | 1 | 61 | 429 | undirected, valued |
| <a id="shakespeare_8"></a>[`shakespeare_8`](https://schochastics.github.io/networkdata/reference/shakespeare_8.html) | Cymbeline | 1 | 39 | 200 | undirected, valued |
| <a id="shakespeare_9"></a>[`shakespeare_9`](https://schochastics.github.io/networkdata/reference/shakespeare_9.html) | Hamlet | 1 | 34 | 207 | undirected, valued |

## Movie networks (Harvard Dataverse)
{: #movies }

Each of these 773 data sets is the social network of the characters of one film. The networks were built by the Moviegalaxies project from the film scripts with an automatic script parser: nodes are characters, and two characters are tied when they interact in the script (the upstream documentation describes the ties no further). The package notes that, despite manual checks, minor errors such as typing mistakes or wrongly parsed character names can remain, so check the character names before using a network. All 773 sources are the same: Kaminski, J., Schober, M., Albaladejo, R., Zastupailo, O. and Hidalgo, C. (2018), *Moviegalaxies - Social Networks in Movies*, Harvard Dataverse, V3, <https://doi.org/10.7910/DVN/T4HBA3>. Please cite it when you use any of them. The upstream page of a film is <https://schochastics.github.io/networkdata/reference/movie_1.html> (with the name of the data set). Every movie data set is a single undirected, valued network.

| Name | Film | Nodes | Ties | Type |
|---|---|---|---|---|
| <a id="movie_1"></a>`movie_1` | 10 Things I Hate About You | 21 | 68 | undirected, valued |
| <a id="movie_10"></a>`movie_10` | 2012 | 66 | 211 | undirected, valued |
| <a id="movie_100"></a>`movie_100` | Big | 16 | 41 | undirected, valued |
| <a id="movie_101"></a>`movie_101` | Bear in the Big Blue House | 28 | 82 | undirected, valued |
| <a id="movie_102"></a>`movie_102` | Big Fish | 37 | 81 | undirected, valued |
| <a id="movie_103"></a>`movie_103` | The Big Lebowski | 37 | 81 | undirected, valued |
| <a id="movie_104"></a>`movie_104` | The Big White | 29 | 64 | undirected, valued |
| <a id="movie_105"></a>`movie_105` | The Birds | 26 | 137 | undirected, valued |
| <a id="movie_106"></a>`movie_106` | Birthday Girl | 16 | 24 | undirected, valued |
| <a id="movie_107"></a>`movie_107` | The Black Dahlia | 61 | 144 | undirected, valued |
| <a id="movie_108"></a>`movie_108` | Black Rain | 27 | 69 | undirected, valued |
| <a id="movie_109"></a>`movie_109` | Black Snake Moan | 35 | 76 | undirected, valued |
| <a id="movie_11"></a>`movie_11` | 44 Inch Chest | 11 | 23 | undirected, valued |
| <a id="movie_110"></a>`movie_110` | Blade | 24 | 54 | undirected, valued |
| <a id="movie_111"></a>`movie_111` | Blade II | 33 | 126 | undirected, valued |
| <a id="movie_112"></a>`movie_112` | Blade Runner | 25 | 44 | undirected, valued |
| <a id="movie_113"></a>`movie_113` | Blade: Trinity | 42 | 115 | undirected, valued |
| <a id="movie_114"></a>`movie_114` | Blast from the Past | 46 | 119 | undirected, valued |
| <a id="movie_115"></a>`movie_115` | Blood Simple. | 12 | 21 | undirected, valued |
| <a id="movie_116"></a>`movie_116` | Blow | 54 | 140 | undirected, valued |
| <a id="movie_117"></a>`movie_117` | Blue Velvet | 30 | 64 | undirected, valued |
| <a id="movie_118"></a>`movie_118` | Bodies, Rest & Motion | 16 | 29 | undirected, valued |
| <a id="movie_119"></a>`movie_119` | Body Heat | 20 | 42 | undirected, valued |
| <a id="movie_12"></a>`movie_12` | 48 Hrs. | 42 | 124 | undirected, valued |
| <a id="movie_120"></a>`movie_120` | Body of Evidence | 26 | 68 | undirected, valued |
| <a id="movie_121"></a>`movie_121` | The Bodyguard | 40 | 120 | undirected, valued |
| <a id="movie_122"></a>`movie_122` | Bones | 27 | 74 | undirected, valued |
| <a id="movie_123"></a>`movie_123` | The Bonfire of the Vanities | 63 | 260 | undirected, valued |
| <a id="movie_124"></a>`movie_124` | Bonnie and Clyde | 16 | 39 | undirected, valued |
| <a id="movie_125"></a>`movie_125` | Boogie Nights | 55 | 175 | undirected, valued |
| <a id="movie_126"></a>`movie_126` | The Book of Eli | 27 | 69 | undirected, valued |
| <a id="movie_127"></a>`movie_127` | The Boondock Saints II: All Saints Day | 44 | 143 | undirected, valued |
| <a id="movie_128"></a>`movie_128` | The Boondock Saints | 36 | 95 | undirected, valued |
| <a id="movie_129"></a>`movie_129` | Bottle Rocket | 35 | 122 | undirected, valued |
| <a id="movie_13"></a>`movie_13` | (500) Days of Summer | 20 | 54 | undirected, valued |
| <a id="movie_130"></a>`movie_130` | Bound | 15 | 31 | undirected, valued |
| <a id="movie_131"></a>`movie_131` | The Bounty Hunter | 35 | 76 | undirected, valued |
| <a id="movie_132"></a>`movie_132` | The Bourne Identity | 36 | 101 | undirected, valued |
| <a id="movie_133"></a>`movie_133` | The Bourne Ultimatum | 46 | 102 | undirected, valued |
| <a id="movie_134"></a>`movie_134` | Braveheart | 67 | 310 | undirected, valued |
| <a id="movie_135"></a>`movie_135` | Brazil | 38 | 98 | undirected, valued |
| <a id="movie_136"></a>`movie_136` | Breakdown | 20 | 45 | undirected, valued |
| <a id="movie_137"></a>`movie_137` | The Breakfast Club | 9 | 22 | undirected, valued |
| <a id="movie_138"></a>`movie_138` | Brick | 22 | 45 | undirected, valued |
| <a id="movie_139"></a>`movie_139` | Bringing Out the Dead | 42 | 130 | undirected, valued |
| <a id="movie_14"></a>`movie_14` | 8MM | 22 | 38 | undirected, valued |
| <a id="movie_140"></a>`movie_140` | Broadcast News | 52 | 176 | undirected, valued |
| <a id="movie_141"></a>`movie_141` | Broken Arrow | 59 | 195 | undirected, valued |
| <a id="movie_142"></a>`movie_142` | Broken Embraces | 41 | 115 | undirected, valued |
| <a id="movie_143"></a>`movie_143` | Bruce Almighty | 50 | 140 | undirected, valued |
| <a id="movie_144"></a>`movie_144` | Buffy the Vampire Slayer | 41 | 203 | undirected, valued |
| <a id="movie_145"></a>`movie_145` | Bull Durham | 35 | 159 | undirected, valued |
| <a id="movie_146"></a>`movie_146` | Burlesque | 37 | 152 | undirected, valued |
| <a id="movie_147"></a>`movie_147` | Burn After Reading | 35 | 75 | undirected, valued |
| <a id="movie_148"></a>`movie_148` | The Butterfly Effect | 32 | 73 | undirected, valued |
| <a id="movie_149"></a>`movie_149` | The Cable Guy | 37 | 105 | undirected, valued |
| <a id="movie_15"></a>`movie_15` | A Few Good Men | 29 | 76 | undirected, valued |
| <a id="movie_150"></a>`movie_150` | Capote | 45 | 104 | undirected, valued |
| <a id="movie_151"></a>`movie_151` | Casino | 109 | 326 | undirected, valued |
| <a id="movie_152"></a>`movie_152` | Cast Away | 33 | 65 | undirected, valued |
| <a id="movie_153"></a>`movie_153` | Catch Me If You Can | 82 | 162 | undirected, valued |
| <a id="movie_154"></a>`movie_154` | The Cell | 24 | 59 | undirected, valued |
| <a id="movie_155"></a>`movie_155` | Cellular | 48 | 138 | undirected, valued |
| <a id="movie_156"></a>`movie_156` | Changeling | 59 | 145 | undirected, valued |
| <a id="movie_157"></a>`movie_157` | Spin City | 31 | 92 | undirected, valued |
| <a id="movie_158"></a>`movie_158` | Charade | 31 | 108 | undirected, valued |
| <a id="movie_159"></a>`movie_159` | Charlie's Angels: Full Throttle | 28 | 80 | undirected, valued |
| <a id="movie_16"></a>`movie_16` | Above the Law | 39 | 95 | undirected, valued |
| <a id="movie_160"></a>`movie_160` | Chasing Sleep | 17 | 40 | undirected, valued |
| <a id="movie_161"></a>`movie_161` | Cherry Falls | 51 | 112 | undirected, valued |
| <a id="movie_162"></a>`movie_162` | Chinatown | 50 | 125 | undirected, valued |
| <a id="movie_163"></a>`movie_163` | The Chronicles of Narnia: The Lion, the Witch and the Wardrobe | 29 | 146 | undirected, valued |
| <a id="movie_164"></a>`movie_164` | The Cider House Rules | 38 | 140 | undirected, valued |
| <a id="movie_165"></a>`movie_165` | The Cincinnati Kid | 36 | 198 | undirected, valued |
| <a id="movie_166"></a>`movie_166` | Cinema Paradiso | 40 | 100 | undirected, valued |
| <a id="movie_167"></a>`movie_167` | Citizen Kane | 56 | 148 | undirected, valued |
| <a id="movie_168"></a>`movie_168` | City of Joy | 44 | 143 | undirected, valued |
| <a id="movie_169"></a>`movie_169` | Clash of the Titans | 27 | 86 | undirected, valued |
| <a id="movie_17"></a>`movie_17` | Absolute Power | 27 | 46 | undirected, valued |
| <a id="movie_170"></a>`movie_170` | Clerks. | 38 | 117 | undirected, valued |
| <a id="movie_171"></a>`movie_171` | Cliffhanger | 23 | 78 | undirected, valued |
| <a id="movie_172"></a>`movie_172` | Cobb | 41 | 109 | undirected, valued |
| <a id="movie_173"></a>`movie_173` | Code of Silence | 41 | 105 | undirected, valued |
| <a id="movie_174"></a>`movie_174` | Cold Mountain | 45 | 112 | undirected, valued |
| <a id="movie_175"></a>`movie_175` | Collateral Damage | 42 | 97 | undirected, valued |
| <a id="movie_176"></a>`movie_176` | Confessions of a Dangerous Mind | 69 | 135 | undirected, valued |
| <a id="movie_177"></a>`movie_177` | Confidence | 25 | 81 | undirected, valued |
| <a id="movie_178"></a>`movie_178` | Constantine | 24 | 44 | undirected, valued |
| <a id="movie_179"></a>`movie_179` | The Cooler | 31 | 104 | undirected, valued |
| <a id="movie_18"></a>`movie_18` | The Abyss | 28 | 108 | undirected, valued |
| <a id="movie_180"></a>`movie_180` | Copycat | 33 | 72 | undirected, valued |
| <a id="movie_181"></a>`movie_181` | Coraline | 42 | 108 | undirected, valued |
| <a id="movie_182"></a>`movie_182` | Cradle 2 the Grave | 36 | 117 | undirected, valued |
| <a id="movie_183"></a>`movie_183` | Crank | 40 | 75 | undirected, valued |
| <a id="movie_184"></a>`movie_184` | Crash | 15 | 25 | undirected, valued |
| <a id="movie_185"></a>`movie_185` | Crime Spree | 43 | 152 | undirected, valued |
| <a id="movie_186"></a>`movie_186` | Crouching Tiger, Hidden Dragon | 32 | 92 | undirected, valued |
| <a id="movie_187"></a>`movie_187` | Croupier | 32 | 69 | undirected, valued |
| <a id="movie_188"></a>`movie_188` | The Crow: Salvation | 33 | 85 | undirected, valued |
| <a id="movie_189"></a>`movie_189` | The Crow | 30 | 68 | undirected, valued |
| <a id="movie_19"></a>`movie_19` | Ace Ventura: Pet Detective | 53 | 148 | undirected, valued |
| <a id="movie_190"></a>`movie_190` | The Crow: City of Angels | 24 | 60 | undirected, valued |
| <a id="movie_191"></a>`movie_191` | Cruel Intentions | 16 | 33 | undirected, valued |
| <a id="movie_192"></a>`movie_192` | The Crying Game | 15 | 39 | undirected, valued |
| <a id="movie_193"></a>`movie_193` | The Curious Case of Benjamin Button | 44 | 129 | undirected, valued |
| <a id="movie_194"></a>`movie_194` | The Damned United | 37 | 84 | undirected, valued |
| <a id="movie_195"></a>`movie_195` | Dances with Wolves | 29 | 73 | undirected, valued |
| <a id="movie_196"></a>`movie_196` | Dark Star | 8 | 16 | undirected, valued |
| <a id="movie_197"></a>`movie_197` | Darkman | 39 | 137 | undirected, valued |
| <a id="movie_198"></a>`movie_198` | Date Night | 42 | 141 | undirected, valued |
| <a id="movie_199"></a>`movie_199` | Day of the Dead | 35 | 86 | undirected, valued |
| <a id="movie_2"></a>`movie_2` | 12 | 33 | 61 | undirected, valued |
| <a id="movie_20"></a>`movie_20` | Adaptation. | 30 | 44 | undirected, valued |
| <a id="movie_200"></a>`movie_200` | The Day the Clown Cried | 39 | 151 | undirected, valued |
| <a id="movie_201"></a>`movie_201` | The Day the Earth Stood Still | 33 | 104 | undirected, valued |
| <a id="movie_202"></a>`movie_202` | Days of Heaven | 17 | 34 | undirected, valued |
| <a id="movie_203"></a>`movie_203` | Dead Poets Society | 42 | 275 | undirected, valued |
| <a id="movie_204"></a>`movie_204` | Death at a Funeral | 18 | 89 | undirected, valued |
| <a id="movie_205"></a>`movie_205` | Death to Smoochy | 49 | 118 | undirected, valued |
| <a id="movie_206"></a>`movie_206` | Deep Cover | 33 | 92 | undirected, valued |
| <a id="movie_207"></a>`movie_207` | Deep Rising | 19 | 71 | undirected, valued |
| <a id="movie_208"></a>`movie_208` | The Deer Hunter | 32 | 74 | undirected, valued |
| <a id="movie_209"></a>`movie_209` | Defiance | 58 | 248 | undirected, valued |
| <a id="movie_21"></a>`movie_21` | The Addams Family | 13 | 44 | undirected, valued |
| <a id="movie_210"></a>`movie_210` | The Departed | 51 | 117 | undirected, valued |
| <a id="movie_211"></a>`movie_211` | Detroit Rock City | 47 | 153 | undirected, valued |
| <a id="movie_212"></a>`movie_212` | Devil in a Blue Dress | 34 | 82 | undirected, valued |
| <a id="movie_213"></a>`movie_213` | The Devil's Advocate | 43 | 120 | undirected, valued |
| <a id="movie_214"></a>`movie_214` | Die Hard | 47 | 237 | undirected, valued |
| <a id="movie_215"></a>`movie_215` | The Distinguished Gentleman | 49 | 197 | undirected, valued |
| <a id="movie_216"></a>`movie_216` | Disturbia | 20 | 48 | undirected, valued |
| <a id="movie_217"></a>`movie_217` | Do the Right Thing | 34 | 171 | undirected, valued |
| <a id="movie_218"></a>`movie_218` | Dog Day Afternoon | 53 | 410 | undirected, valued |
| <a id="movie_219"></a>`movie_219` | Donnie Brasco | 50 | 160 | undirected, valued |
| <a id="movie_22"></a>`movie_22` | The Adventures of Buckaroo Banzai Across the 8th Dimension | 52 | 206 | undirected, valued |
| <a id="movie_220"></a>`movie_220` | The Doors | 95 | 567 | undirected, valued |
| <a id="movie_221"></a>`movie_221` | Double Indemnity | 20 | 44 | undirected, valued |
| <a id="movie_222"></a>`movie_222` | Drag Me to Hell | 30 | 77 | undirected, valued |
| <a id="movie_223"></a>`movie_223` | Dragonslayer | 15 | 52 | undirected, valued |
| <a id="movie_224"></a>`movie_224` | Drop Dead Gorgeous | 43 | 199 | undirected, valued |
| <a id="movie_225"></a>`movie_225` | A Dry White Season | 53 | 161 | undirected, valued |
| <a id="movie_226"></a>`movie_226` | Dumb & Dumber | 37 | 86 | undirected, valued |
| <a id="movie_227"></a>`movie_227` | Dune | 34 | 98 | undirected, valued |
| <a id="movie_228"></a>`movie_228` | Eagle Eye | 76 | 185 | undirected, valued |
| <a id="movie_229"></a>`movie_229` | Eastern Promises | 23 | 53 | undirected, valued |
| <a id="movie_23"></a>`movie_23` | Affliction | 24 | 57 | undirected, valued |
| <a id="movie_230"></a>`movie_230` | Edtv | 77 | 246 | undirected, valued |
| <a id="movie_231"></a>`movie_231` | Ed Wood | 60 | 246 | undirected, valued |
| <a id="movie_232"></a>`movie_232` | Eight Legged Freaks | 24 | 86 | undirected, valued |
| <a id="movie_233"></a>`movie_233` | Election | 36 | 91 | undirected, valued |
| <a id="movie_234"></a>`movie_234` | The Elephant Man | 39 | 90 | undirected, valued |
| <a id="movie_235"></a>`movie_235` | Elizabeth: The Golden Age | 43 | 136 | undirected, valued |
| <a id="movie_236"></a>`movie_236` | Enemy of the State | 60 | 152 | undirected, valued |
| <a id="movie_237"></a>`movie_237` | The English Patient | 34 | 72 | undirected, valued |
| <a id="movie_238"></a>`movie_238` | Entrapment | 10 | 19 | undirected, valued |
| <a id="movie_239"></a>`movie_239` | Erin Brockovich | 40 | 73 | undirected, valued |
| <a id="movie_24"></a>`movie_24` | After Life | 35 | 91 | undirected, valued |
| <a id="movie_240"></a>`movie_240` | Escape from L.A. | 35 | 91 | undirected, valued |
| <a id="movie_241"></a>`movie_241` | Escape from New York | 26 | 49 | undirected, valued |
| <a id="movie_242"></a>`movie_242` | Eternal Sunshine of the Spotless Mind | 32 | 69 | undirected, valued |
| <a id="movie_243"></a>`movie_243` | Even Cowgirls Get the Blues | 37 | 98 | undirected, valued |
| <a id="movie_244"></a>`movie_244` | Event Horizon | 19 | 56 | undirected, valued |
| <a id="movie_245"></a>`movie_245` | The Evil Dead | 5 | 10 | undirected, valued |
| <a id="movie_246"></a>`movie_246` | Evil Dead II | 13 | 30 | undirected, valued |
| <a id="movie_247"></a>`movie_247` | Excalibur | 30 | 97 | undirected, valued |
| <a id="movie_248"></a>`movie_248` | Extract | 28 | 75 | undirected, valued |
| <a id="movie_249"></a>`movie_249` | The Fabulous Baker Boys | 36 | 80 | undirected, valued |
| <a id="movie_25"></a>`movie_25` | Agnes of God | 21 | 102 | undirected, valued |
| <a id="movie_250"></a>`movie_250` | Face/Off | 38 | 106 | undirected, valued |
| <a id="movie_251"></a>`movie_251` | Fair Game | 68 | 214 | undirected, valued |
| <a id="movie_252"></a>`movie_252` | The Family Man | 32 | 64 | undirected, valued |
| <a id="movie_253"></a>`movie_253` | Fantastic Four | 37 | 114 | undirected, valued |
| <a id="movie_254"></a>`movie_254` | Fantastic Mr. Fox | 32 | 142 | undirected, valued |
| <a id="movie_255"></a>`movie_255` | Fargo | 32 | 64 | undirected, valued |
| <a id="movie_256"></a>`movie_256` | Fast Times at Ridgemont High | 57 | 151 | undirected, valued |
| <a id="movie_257"></a>`movie_257` | Fatal Instinct | 39 | 108 | undirected, valued |
| <a id="movie_258"></a>`movie_258` | Fear and Loathing in Las Vegas | 40 | 84 | undirected, valued |
| <a id="movie_259"></a>`movie_259` | Babette's Feast | 29 | 254 | undirected, valued |
| <a id="movie_26"></a>`movie_26` | Air Force One | 52 | 150 | undirected, valued |
| <a id="movie_260"></a>`movie_260` | Ferris Bueller's Day Off | 39 | 99 | undirected, valued |
| <a id="movie_261"></a>`movie_261` | The Fifth Element | 62 | 186 | undirected, valued |
| <a id="movie_262"></a>`movie_262` | Fight Club | 46 | 94 | undirected, valued |
| <a id="movie_263"></a>`movie_263` | Final Destination | 31 | 150 | undirected, valued |
| <a id="movie_264"></a>`movie_264` | Final Destination 2 | 38 | 171 | undirected, valued |
| <a id="movie_265"></a>`movie_265` | Five Easy Pieces | 21 | 61 | undirected, valued |
| <a id="movie_266"></a>`movie_266` | Fletch | 48 | 124 | undirected, valued |
| <a id="movie_267"></a>`movie_267` | The Flintstones | 35 | 105 | undirected, valued |
| <a id="movie_268"></a>`movie_268` | Forrest Gump | 94 | 271 | undirected, valued |
| <a id="movie_269"></a>`movie_269` | Four Feathers | 19 | 26 | undirected, valued |
| <a id="movie_27"></a>`movie_27` | Airplane! | 25 | 62 | undirected, valued |
| <a id="movie_270"></a>`movie_270` | Four Rooms | 28 | 70 | undirected, valued |
| <a id="movie_271"></a>`movie_271` | Fracture | 35 | 68 | undirected, valued |
| <a id="movie_272"></a>`movie_272` | French Kiss | 68 | 158 | undirected, valued |
| <a id="movie_273"></a>`movie_273` | Frankenstein | 56 | 160 | undirected, valued |
| <a id="movie_274"></a>`movie_274` | Freddy vs. Jason | 37 | 92 | undirected, valued |
| <a id="movie_275"></a>`movie_275` | The French Connection | 40 | 78 | undirected, valued |
| <a id="movie_276"></a>`movie_276` | Frequency | 39 | 90 | undirected, valued |
| <a id="movie_277"></a>`movie_277` | Friday the 13th | 14 | 36 | undirected, valued |
| <a id="movie_278"></a>`movie_278` | Friday the 13th Part VIII: Jason Takes Manhattan | 27 | 88 | undirected, valued |
| <a id="movie_279"></a>`movie_279` | From Dusk Till Dawn | 21 | 86 | undirected, valued |
| <a id="movie_28"></a>`movie_28` | Airplane II: The Sequel | 95 | 378 | undirected, valued |
| <a id="movie_280"></a>`movie_280` | Cashback | 9 | 21 | undirected, valued |
| <a id="movie_281"></a>`movie_281` | Frozen River | 22 | 32 | undirected, valued |
| <a id="movie_282"></a>`movie_282` | The Fugitive | 58 | 146 | undirected, valued |
| <a id="movie_283"></a>`movie_283` | Funny People | 43 | 104 | undirected, valued |
| <a id="movie_284"></a>`movie_284` | G.I. Jane | 41 | 141 | undirected, valued |
| <a id="movie_285"></a>`movie_285` | G.I. Joe: The Rise of Cobra | 29 | 84 | undirected, valued |
| <a id="movie_286"></a>`movie_286` | Game 6 | 33 | 73 | undirected, valued |
| <a id="movie_287"></a>`movie_287` | The Game | 49 | 116 | undirected, valued |
| <a id="movie_288"></a>`movie_288` | Gamer | 43 | 104 | undirected, valued |
| <a id="movie_289"></a>`movie_289` | Gandhi | 76 | 200 | undirected, valued |
| <a id="movie_29"></a>`movie_29` | Ali | 75 | 249 | undirected, valued |
| <a id="movie_290"></a>`movie_290` | Gang Related | 57 | 189 | undirected, valued |
| <a id="movie_291"></a>`movie_291` | Gangs of New York | 70 | 266 | undirected, valued |
| <a id="movie_292"></a>`movie_292` | Gattaca | 30 | 71 | undirected, valued |
| <a id="movie_293"></a>`movie_293` | Get Carter | 27 | 58 | undirected, valued |
| <a id="movie_294"></a>`movie_294` | The Getaway | 31 | 60 | undirected, valued |
| <a id="movie_295"></a>`movie_295` | Ghost | 37 | 118 | undirected, valued |
| <a id="movie_296"></a>`movie_296` | Ghost Rider | 74 | 251 | undirected, valued |
| <a id="movie_297"></a>`movie_297` | Ghost Ship | 15 | 46 | undirected, valued |
| <a id="movie_298"></a>`movie_298` | Ghost World | 53 | 144 | undirected, valued |
| <a id="movie_299"></a>`movie_299` | Ghostbusters | 14 | 41 | undirected, valued |
| <a id="movie_3"></a>`movie_3` | Twelve and Holding | 25 | 47 | undirected, valued |
| <a id="movie_30"></a>`movie_30` | Alien 3 | 25 | 77 | undirected, valued |
| <a id="movie_300"></a>`movie_300` | Ghostbusters II | 33 | 106 | undirected, valued |
| <a id="movie_301"></a>`movie_301` | Ginger Snaps | 27 | 82 | undirected, valued |
| <a id="movie_302"></a>`movie_302` | Gladiator | 29 | 82 | undirected, valued |
| <a id="movie_303"></a>`movie_303` | Go | 34 | 96 | undirected, valued |
| <a id="movie_304"></a>`movie_304` | The Godfather | 42 | 104 | undirected, valued |
| <a id="movie_305"></a>`movie_305` | The Godfather: Part II | 78 | 219 | undirected, valued |
| <a id="movie_306"></a>`movie_306` | Gods and Monsters | 26 | 70 | undirected, valued |
| <a id="movie_307"></a>`movie_307` | Godzilla | 49 | 151 | undirected, valued |
| <a id="movie_308"></a>`movie_308` | Gone in Sixty Seconds | 39 | 117 | undirected, valued |
| <a id="movie_309"></a>`movie_309` | Good Will Hunting | 31 | 65 | undirected, valued |
| <a id="movie_31"></a>`movie_31` | Alien Nation | 30 | 82 | undirected, valued |
| <a id="movie_310"></a>`movie_310` | Gothika | 22 | 59 | undirected, valued |
| <a id="movie_311"></a>`movie_311` | The Graduate | 34 | 97 | undirected, valued |
| <a id="movie_312"></a>`movie_312` | Gran Torino | 39 | 105 | undirected, valued |
| <a id="movie_313"></a>`movie_313` | Grand Theft Parsons | 28 | 59 | undirected, valued |
| <a id="movie_314"></a>`movie_314` | The Green Mile | 47 | 268 | undirected, valued |
| <a id="movie_315"></a>`movie_315` | Gremlins | 51 | 286 | undirected, valued |
| <a id="movie_316"></a>`movie_316` | Gremlins 2: The New Batch | 64 | 251 | undirected, valued |
| <a id="movie_317"></a>`movie_317` | The Grifters | 33 | 61 | undirected, valued |
| <a id="movie_318"></a>`movie_318` | Grosse Pointe Blank | 39 | 84 | undirected, valued |
| <a id="movie_319"></a>`movie_319` | Groundhog Day | 54 | 139 | undirected, valued |
| <a id="movie_32"></a>`movie_32` | AVP: Alien vs. Predator | 24 | 76 | undirected, valued |
| <a id="movie_320"></a>`movie_320` | The Grudge | 20 | 30 | undirected, valued |
| <a id="movie_321"></a>`movie_321` | Hackers | 51 | 190 | undirected, valued |
| <a id="movie_322"></a>`movie_322` | Halloween: The Curse of Michael Myers | 50 | 181 | undirected, valued |
| <a id="movie_323"></a>`movie_323` | Hancock | 44 | 87 | undirected, valued |
| <a id="movie_324"></a>`movie_324` | The Hangover | 37 | 158 | undirected, valued |
| <a id="movie_325"></a>`movie_325` | Hannah and Her Sisters | 42 | 134 | undirected, valued |
| <a id="movie_326"></a>`movie_326` | Hard to Kill | 30 | 54 | undirected, valued |
| <a id="movie_327"></a>`movie_327` | Harold & Kumar Go to White Castle | 41 | 138 | undirected, valued |
| <a id="movie_328"></a>`movie_328` | The Haunting | 15 | 35 | undirected, valued |
| <a id="movie_329"></a>`movie_329` | He's Just Not That Into You | 51 | 114 | undirected, valued |
| <a id="movie_33"></a>`movie_33` | Alien: Resurrection | 27 | 141 | undirected, valued |
| <a id="movie_330"></a>`movie_330` | Heat | 59 | 135 | undirected, valued |
| <a id="movie_331"></a>`movie_331` | Heathers | 44 | 231 | undirected, valued |
| <a id="movie_332"></a>`movie_332` | Heavenly Creatures | 13 | 25 | undirected, valued |
| <a id="movie_333"></a>`movie_333` | The Hebrew Hammer | 39 | 121 | undirected, valued |
| <a id="movie_334"></a>`movie_334` | Hellbound: Hellraiser II | 16 | 46 | undirected, valued |
| <a id="movie_335"></a>`movie_335` | Hellboy | 38 | 91 | undirected, valued |
| <a id="movie_336"></a>`movie_336` | Hellboy II: The Golden Army | 35 | 148 | undirected, valued |
| <a id="movie_337"></a>`movie_337` | Hellraiser | 16 | 42 | undirected, valued |
| <a id="movie_338"></a>`movie_338` | Hellraiser III: Hell on Earth | 42 | 112 | undirected, valued |
| <a id="movie_339"></a>`movie_339` | Hellraiser: Deader | 21 | 70 | undirected, valued |
| <a id="movie_34"></a>`movie_34` | Aliens | 24 | 106 | undirected, valued |
| <a id="movie_340"></a>`movie_340` | Hellraiser: Hellseeker | 35 | 84 | undirected, valued |
| <a id="movie_341"></a>`movie_341` | Henry Fool | 31 | 79 | undirected, valued |
| <a id="movie_342"></a>`movie_342` | High Fidelity | 28 | 67 | undirected, valued |
| <a id="movie_343"></a>`movie_343` | Highlander | 59 | 108 | undirected, valued |
| <a id="movie_344"></a>`movie_344` | Highlander: Endgame | 49 | 134 | undirected, valued |
| <a id="movie_345"></a>`movie_345` | His Girl Friday | 40 | 154 | undirected, valued |
| <a id="movie_346"></a>`movie_346` | The Hitchhiker's Guide to the Galaxy | 31 | 101 | undirected, valued |
| <a id="movie_347"></a>`movie_347` | Hollow Man | 13 | 35 | undirected, valued |
| <a id="movie_348"></a>`movie_348` | Honeydripper | 33 | 114 | undirected, valued |
| <a id="movie_349"></a>`movie_349` | The Horse Whisperer | 26 | 86 | undirected, valued |
| <a id="movie_35"></a>`movie_35` | All About Eve | 19 | 79 | undirected, valued |
| <a id="movie_350"></a>`movie_350` | The Kingdom | 50 | 148 | undirected, valued |
| <a id="movie_351"></a>`movie_351` | Hostage | 38 | 105 | undirected, valued |
| <a id="movie_352"></a>`movie_352` | Hot Tub Time Machine | 33 | 138 | undirected, valued |
| <a id="movie_353"></a>`movie_353` | Hotel Rwanda | 66 | 182 | undirected, valued |
| <a id="movie_354"></a>`movie_354` | House of 1000 Corpses | 33 | 121 | undirected, valued |
| <a id="movie_355"></a>`movie_355` | Hudson Hawk | 24 | 97 | undirected, valued |
| <a id="movie_356"></a>`movie_356` | The Hudsucker Proxy | 57 | 180 | undirected, valued |
| <a id="movie_357"></a>`movie_357` | Human Nature | 18 | 38 | undirected, valued |
| <a id="movie_358"></a>`movie_358` | I Am Sam | 47 | 140 | undirected, valued |
| <a id="movie_359"></a>`movie_359` | I Love You Phillip Morris | 51 | 94 | undirected, valued |
| <a id="movie_36"></a>`movie_36` | All About Steve | 44 | 110 | undirected, valued |
| <a id="movie_360"></a>`movie_360` | I Still Know What You Did Last Summer | 18 | 46 | undirected, valued |
| <a id="movie_361"></a>`movie_361` | I'll Do Anything | 47 | 189 | undirected, valued |
| <a id="movie_362"></a>`movie_362` | I, Robot | 29 | 72 | undirected, valued |
| <a id="movie_363"></a>`movie_363` | The Ice Storm | 29 | 65 | undirected, valued |
| <a id="movie_364"></a>`movie_364` | The Imaginarium of Doctor Parnassus | 39 | 183 | undirected, valued |
| <a id="movie_365"></a>`movie_365` | In the Loop | 33 | 130 | undirected, valued |
| <a id="movie_366"></a>`movie_366` | Independence Day | 66 | 209 | undirected, valued |
| <a id="movie_367"></a>`movie_367` | Indiana Jones and the Last Crusade | 24 | 65 | undirected, valued |
| <a id="movie_368"></a>`movie_368` | Indiana Jones and the Temple of Doom | 16 | 41 | undirected, valued |
| <a id="movie_369"></a>`movie_369` | Raiders of the Lost Ark | 32 | 134 | undirected, valued |
| <a id="movie_37"></a>`movie_37` | All the King's Men | 37 | 145 | undirected, valued |
| <a id="movie_370"></a>`movie_370` | The Insider | 45 | 109 | undirected, valued |
| <a id="movie_371"></a>`movie_371` | Insomnia | 32 | 91 | undirected, valued |
| <a id="movie_372"></a>`movie_372` | Interview with the Vampire: The Vampire Chronicles | 23 | 56 | undirected, valued |
| <a id="movie_373"></a>`movie_373` | Into the Wild | 27 | 38 | undirected, valued |
| <a id="movie_374"></a>`movie_374` | Intolerable Cruelty | 40 | 113 | undirected, valued |
| <a id="movie_375"></a>`movie_375` | Inventing the Abbotts | 17 | 39 | undirected, valued |
| <a id="movie_376"></a>`movie_376` | The Invention of Lying | 61 | 291 | undirected, valued |
| <a id="movie_377"></a>`movie_377` | The Island | 27 | 45 | undirected, valued |
| <a id="movie_378"></a>`movie_378` | It's a Wonderful Life | 70 | 339 | undirected, valued |
| <a id="movie_379"></a>`movie_379` | It's Complicated | 28 | 81 | undirected, valued |
| <a id="movie_38"></a>`movie_38` | Almost Famous | 53 | 206 | undirected, valued |
| <a id="movie_380"></a>`movie_380` | The Italian Job | 29 | 57 | undirected, valued |
| <a id="movie_381"></a>`movie_381` | The Jacket | 26 | 47 | undirected, valued |
| <a id="movie_382"></a>`movie_382` | Jackie Brown | 25 | 61 | undirected, valued |
| <a id="movie_383"></a>`movie_383` | Jacob's Ladder | 54 | 144 | undirected, valued |
| <a id="movie_384"></a>`movie_384` | Jason X | 26 | 150 | undirected, valued |
| <a id="movie_385"></a>`movie_385` | Jaws | 36 | 85 | undirected, valued |
| <a id="movie_386"></a>`movie_386` | Jaws 2 | 49 | 232 | undirected, valued |
| <a id="movie_387"></a>`movie_387` | Jay and Silent Bob Strike Back | 61 | 228 | undirected, valued |
| <a id="movie_388"></a>`movie_388` | Jennifer Eight | 25 | 61 | undirected, valued |
| <a id="movie_389"></a>`movie_389` | Jennifer's Body | 26 | 55 | undirected, valued |
| <a id="movie_39"></a>`movie_39` | Alone in the Dark | 27 | 71 | undirected, valued |
| <a id="movie_390"></a>`movie_390` | Jerry Maguire | 48 | 128 | undirected, valued |
| <a id="movie_391"></a>`movie_391` | JFK | 101 | 293 | undirected, valued |
| <a id="movie_392"></a>`movie_392` | Jimmy and Judy | 19 | 42 | undirected, valued |
| <a id="movie_393"></a>`movie_393` | John Q | 46 | 190 | undirected, valued |
| <a id="movie_394"></a>`movie_394` | Juno | 25 | 55 | undirected, valued |
| <a id="movie_395"></a>`movie_395` | Jurassic Park | 24 | 115 | undirected, valued |
| <a id="movie_396"></a>`movie_396` | Jurassic Park III | 20 | 57 | undirected, valued |
| <a id="movie_397"></a>`movie_397` | The Lost World: Jurassic Park | 27 | 93 | undirected, valued |
| <a id="movie_398"></a>`movie_398` | Kalifornia | 43 | 159 | undirected, valued |
| <a id="movie_399"></a>`movie_399` | Kate & Leopold | 24 | 54 | undirected, valued |
| <a id="movie_4"></a>`movie_4` | 127 Hours | 9 | 10 | undirected, valued |
| <a id="movie_40"></a>`movie_40` | Amadeus | 43 | 152 | undirected, valued |
| <a id="movie_400"></a>`movie_400` | Kids | 41 | 130 | undirected, valued |
| <a id="movie_401"></a>`movie_401` | Kill Bill: Vol. 1 | 38 | 78 | undirected, valued |
| <a id="movie_402"></a>`movie_402` | Killing Zoe | 21 | 64 | undirected, valued |
| <a id="movie_403"></a>`movie_403` | King Kong | 50 | 169 | undirected, valued |
| <a id="movie_404"></a>`movie_404` | The King of Comedy | 43 | 144 | undirected, valued |
| <a id="movie_405"></a>`movie_405` | The King's Speech | 26 | 80 | undirected, valued |
| <a id="movie_406"></a>`movie_406` | Indiana Jones and the Kingdom of the Crystal Skull | 44 | 182 | undirected, valued |
| <a id="movie_407"></a>`movie_407` | Klute | 37 | 71 | undirected, valued |
| <a id="movie_408"></a>`movie_408` | Kramer vs. Kramer | 57 | 266 | undirected, valued |
| <a id="movie_409"></a>`movie_409` | Kundun | 33 | 60 | undirected, valued |
| <a id="movie_41"></a>`movie_41` | Amelia | 26 | 54 | undirected, valued |
| <a id="movie_410"></a>`movie_410` | Kung Fu Panda | 21 | 70 | undirected, valued |
| <a id="movie_411"></a>`movie_411` | L.A. Confidential | 53 | 131 | undirected, valued |
| <a id="movie_412"></a>`movie_412` | The Ladykillers | 33 | 86 | undirected, valued |
| <a id="movie_413"></a>`movie_413` | Lake Placid | 22 | 65 | undirected, valued |
| <a id="movie_414"></a>`movie_414` | Land of the Dead | 51 | 221 | undirected, valued |
| <a id="movie_415"></a>`movie_415` | The Last Boy Scout | 44 | 100 | undirected, valued |
| <a id="movie_416"></a>`movie_416` | Last Chance Harvey | 41 | 96 | undirected, valued |
| <a id="movie_417"></a>`movie_417` | The Last Flight of Noah's Ark | 26 | 127 | undirected, valued |
| <a id="movie_418"></a>`movie_418` | The Last of the Mohicans | 29 | 134 | undirected, valued |
| <a id="movie_419"></a>`movie_419` | The Last Samurai | 20 | 54 | undirected, valued |
| <a id="movie_42"></a>`movie_42` | American Beauty | 22 | 46 | undirected, valued |
| <a id="movie_420"></a>`movie_420` | The Last Station | 15 | 47 | undirected, valued |
| <a id="movie_421"></a>`movie_421` | Law Abiding Citizen | 41 | 117 | undirected, valued |
| <a id="movie_422"></a>`movie_422` | Leaving Las Vegas | 34 | 57 | undirected, valued |
| <a id="movie_423"></a>`movie_423` | Legion | 23 | 86 | undirected, valued |
| <a id="movie_424"></a>`movie_424` | Leviathan | 12 | 44 | undirected, valued |
| <a id="movie_425"></a>`movie_425` | Liar Liar | 50 | 187 | undirected, valued |
| <a id="movie_426"></a>`movie_426` | Life | 56 | 212 | undirected, valued |
| <a id="movie_427"></a>`movie_427` | Life as a House | 29 | 99 | undirected, valued |
| <a id="movie_428"></a>`movie_428` | The Life of David Gale | 55 | 143 | undirected, valued |
| <a id="movie_429"></a>`movie_429` | Light Sleeper | 23 | 32 | undirected, valued |
| <a id="movie_43"></a>`movie_43` | American Gangster | 59 | 119 | undirected, valued |
| <a id="movie_430"></a>`movie_430` | The Limey | 22 | 48 | undirected, valued |
| <a id="movie_431"></a>`movie_431` | Little Athens | 47 | 124 | undirected, valued |
| <a id="movie_432"></a>`movie_432` | Little Nicky | 53 | 202 | undirected, valued |
| <a id="movie_433"></a>`movie_433` | Living in Oblivion | 21 | 91 | undirected, valued |
| <a id="movie_434"></a>`movie_434` | Lock, Stock and Two Smoking Barrels | 42 | 134 | undirected, valued |
| <a id="movie_435"></a>`movie_435` | Logan's Run | 21 | 69 | undirected, valued |
| <a id="movie_436"></a>`movie_436` | Lone Star | 52 | 142 | undirected, valued |
| <a id="movie_437"></a>`movie_437` | The Long Kiss Goodnight | 48 | 114 | undirected, valued |
| <a id="movie_438"></a>`movie_438` | Lord of Illusions | 28 | 64 | undirected, valued |
| <a id="movie_439"></a>`movie_439` | The Lord of the Rings: The Fellowship of the Ring | 23 | 102 | undirected, valued |
| <a id="movie_44"></a>`movie_44` | American History X | 39 | 114 | undirected, valued |
| <a id="movie_440"></a>`movie_440` | The Lord of the Rings: The Return of the King | 35 | 98 | undirected, valued |
| <a id="movie_441"></a>`movie_441` | Lord of War | 43 | 91 | undirected, valued |
| <a id="movie_442"></a>`movie_442` | The Losers | 33 | 108 | undirected, valued |
| <a id="movie_443"></a>`movie_443` | Lost Highway | 33 | 78 | undirected, valued |
| <a id="movie_444"></a>`movie_444` | Lost Horizon | 30 | 77 | undirected, valued |
| <a id="movie_445"></a>`movie_445` | Lost in Space | 27 | 96 | undirected, valued |
| <a id="movie_446"></a>`movie_446` | Lost in Translation | 27 | 48 | undirected, valued |
| <a id="movie_447"></a>`movie_447` | Love & Basketball | 39 | 126 | undirected, valued |
| <a id="movie_448"></a>`movie_448` | Magnolia | 82 | 239 | undirected, valued |
| <a id="movie_449"></a>`movie_449` | The Majestic | 47 | 159 | undirected, valued |
| <a id="movie_45"></a>`movie_45` | American Pie | 33 | 106 | undirected, valued |
| <a id="movie_450"></a>`movie_450` | Major League | 54 | 306 | undirected, valued |
| <a id="movie_451"></a>`movie_451` | Malcolm X | 76 | 174 | undirected, valued |
| <a id="movie_452"></a>`movie_452` | Malibu's Most Wanted | 34 | 166 | undirected, valued |
| <a id="movie_453"></a>`movie_453` | The Man in the Iron Mask | 38 | 107 | undirected, valued |
| <a id="movie_454"></a>`movie_454` | Man on Fire | 36 | 73 | undirected, valued |
| <a id="movie_455"></a>`movie_455` | Man on the Moon | 67 | 186 | undirected, valued |
| <a id="movie_456"></a>`movie_456` | Knight and Day | 29 | 79 | undirected, valued |
| <a id="movie_457"></a>`movie_457` | The Man Who Knew Too Much | 42 | 109 | undirected, valued |
| <a id="movie_458"></a>`movie_458` | The Man Who Wasn't There | 38 | 107 | undirected, valued |
| <a id="movie_459"></a>`movie_459` | The Manchurian Candidate | 40 | 131 | undirected, valued |
| <a id="movie_46"></a>`movie_46` | The American President | 49 | 163 | undirected, valued |
| <a id="movie_460"></a>`movie_460` | Manhunter | 47 | 100 | undirected, valued |
| <a id="movie_461"></a>`movie_461` | Margot at the Wedding | 16 | 57 | undirected, valued |
| <a id="movie_462"></a>`movie_462` | Desperado | 12 | 20 | undirected, valued |
| <a id="movie_463"></a>`movie_463` | Marley & Me | 30 | 67 | undirected, valued |
| <a id="movie_464"></a>`movie_464` | Marty | 26 | 59 | undirected, valued |
| <a id="movie_465"></a>`movie_465` | The Mask | 77 | 318 | undirected, valued |
| <a id="movie_466"></a>`movie_466` | The Matrix Reloaded | 27 | 81 | undirected, valued |
| <a id="movie_467"></a>`movie_467` | The Matrix | 31 | 88 | undirected, valued |
| <a id="movie_468"></a>`movie_468` | Max Payne | 62 | 331 | undirected, valued |
| <a id="movie_469"></a>`movie_469` | Meet Joe Black | 22 | 68 | undirected, valued |
| <a id="movie_47"></a>`movie_47` | American Psycho | 26 | 59 | undirected, valued |
| <a id="movie_470"></a>`movie_470` | Megamind | 35 | 96 | undirected, valued |
| <a id="movie_471"></a>`movie_471` | Memento | 14 | 19 | undirected, valued |
| <a id="movie_472"></a>`movie_472` | Men in Black | 32 | 75 | undirected, valued |
| <a id="movie_473"></a>`movie_473` | The Men Who Stare at Goats | 46 | 96 | undirected, valued |
| <a id="movie_474"></a>`movie_474` | Subway | 54 | 108 | undirected, valued |
| <a id="movie_475"></a>`movie_475` | Miami Vice | 28 | 82 | undirected, valued |
| <a id="movie_476"></a>`movie_476` | Midnight Cowboy | 28 | 47 | undirected, valued |
| <a id="movie_477"></a>`movie_477` | Mighty Morphin Power Rangers: The Movie | 36 | 200 | undirected, valued |
| <a id="movie_478"></a>`movie_478` | Milk | 41 | 133 | undirected, valued |
| <a id="movie_479"></a>`movie_479` | Mimic | 23 | 52 | undirected, valued |
| <a id="movie_48"></a>`movie_48` | American Shaolin | 32 | 73 | undirected, valued |
| <a id="movie_480"></a>`movie_480` | Mini's First Time | 42 | 114 | undirected, valued |
| <a id="movie_481"></a>`movie_481` | Minority Report | 51 | 149 | undirected, valued |
| <a id="movie_482"></a>`movie_482` | Mirrors | 26 | 45 | undirected, valued |
| <a id="movie_483"></a>`movie_483` | Mission: Impossible | 28 | 86 | undirected, valued |
| <a id="movie_484"></a>`movie_484` | Mission: Impossible II | 22 | 105 | undirected, valued |
| <a id="movie_485"></a>`movie_485` | Mission to Mars | 40 | 188 | undirected, valued |
| <a id="movie_486"></a>`movie_486` | Monkeybone | 52 | 146 | undirected, valued |
| <a id="movie_487"></a>`movie_487` | Moon | 12 | 27 | undirected, valued |
| <a id="movie_488"></a>`movie_488` | Moonstruck | 40 | 141 | undirected, valued |
| <a id="movie_489"></a>`movie_489` | Mr. Blandings Builds His Dream House | 37 | 157 | undirected, valued |
| <a id="movie_49"></a>`movie_49` | American Splendor | 35 | 82 | undirected, valued |
| <a id="movie_490"></a>`movie_490` | Mr. Brooks | 37 | 80 | undirected, valued |
| <a id="movie_491"></a>`movie_491` | Mr. Deeds Goes to Town | 61 | 331 | undirected, valued |
| <a id="movie_492"></a>`movie_492` | Her Majesty, Mrs. Brown | 23 | 44 | undirected, valued |
| <a id="movie_493"></a>`movie_493` | Mulholland Dr. | 49 | 163 | undirected, valued |
| <a id="movie_494"></a>`movie_494` | Mumford | 24 | 58 | undirected, valued |
| <a id="movie_495"></a>`movie_495` | The Mummy | 22 | 77 | undirected, valued |
| <a id="movie_496"></a>`movie_496` | Music of the Heart | 58 | 201 | undirected, valued |
| <a id="movie_497"></a>`movie_497` | My Best Friend's Wedding | 24 | 69 | undirected, valued |
| <a id="movie_498"></a>`movie_498` | My Girl | 33 | 108 | undirected, valued |
| <a id="movie_499"></a>`movie_499` | My Mother Dreams the Satan's Disciples in New York | 18 | 50 | undirected, valued |
| <a id="movie_5"></a>`movie_5` | 1492: Conquest of Paradise | 34 | 86 | undirected, valued |
| <a id="movie_50"></a>`movie_50` | An American Werewolf in London | 31 | 86 | undirected, valued |
| <a id="movie_500"></a>`movie_500` | Mystery Men | 53 | 299 | undirected, valued |
| <a id="movie_501"></a>`movie_501` | Nashville | 40 | 131 | undirected, valued |
| <a id="movie_502"></a>`movie_502` | Natural Born Killers | 50 | 147 | undirected, valued |
| <a id="movie_503"></a>`movie_503` | Newsies | 76 | 629 | undirected, valued |
| <a id="movie_504"></a>`movie_504` | Next | 41 | 150 | undirected, valued |
| <a id="movie_505"></a>`movie_505` | Next Friday | 21 | 83 | undirected, valued |
| <a id="movie_506"></a>`movie_506` | The Next Three Days | 43 | 87 | undirected, valued |
| <a id="movie_507"></a>`movie_507` | Nick of Time | 34 | 100 | undirected, valued |
| <a id="movie_508"></a>`movie_508` | A Nightmare on Elm Street | 31 | 73 | undirected, valued |
| <a id="movie_509"></a>`movie_509` | Freddy's Dead: The Final Nightmare | 36 | 104 | undirected, valued |
| <a id="movie_51"></a>`movie_51` | An Education | 18 | 46 | undirected, valued |
| <a id="movie_510"></a>`movie_510` | The Nines | 23 | 53 | undirected, valued |
| <a id="movie_511"></a>`movie_511` | Ninja Assassin | 23 | 38 | undirected, valued |
| <a id="movie_512"></a>`movie_512` | Ninotchka | 34 | 115 | undirected, valued |
| <a id="movie_513"></a>`movie_513` | Notting Hill | 34 | 103 | undirected, valued |
| <a id="movie_514"></a>`movie_514` | Nurse Betty | 52 | 173 | undirected, valued |
| <a id="movie_515"></a>`movie_515` | O Brother, Where Art Thou? | 44 | 170 | undirected, valued |
| <a id="movie_516"></a>`movie_516` | Observe and Report | 31 | 70 | undirected, valued |
| <a id="movie_517"></a>`movie_517` | Wicker Park | 27 | 99 | undirected, valued |
| <a id="movie_518"></a>`movie_518` | Ocean's Eleven | 50 | 145 | undirected, valued |
| <a id="movie_519"></a>`movie_519` | Ocean's Twelve | 42 | 147 | undirected, valued |
| <a id="movie_52"></a>`movie_52` | Analyze That | 47 | 130 | undirected, valued |
| <a id="movie_520"></a>`movie_520` | One Flew Over the Cuckoo's Nest | 32 | 178 | undirected, valued |
| <a id="movie_521"></a>`movie_521` | Ordinary People | 43 | 121 | undirected, valued |
| <a id="movie_522"></a>`movie_522` | Orphan | 48 | 199 | undirected, valued |
| <a id="movie_523"></a>`movie_523` | The Other Boleyn Girl | 35 | 109 | undirected, valued |
| <a id="movie_524"></a>`movie_524` | Out of Sight | 37 | 135 | undirected, valued |
| <a id="movie_525"></a>`movie_525` | The Pacifier | 46 | 191 | undirected, valued |
| <a id="movie_526"></a>`movie_526` | Panic Room | 11 | 25 | undirected, valued |
| <a id="movie_527"></a>`movie_527` | The Patriot | 51 | 182 | undirected, valued |
| <a id="movie_528"></a>`movie_528` | Pearl Harbor | 54 | 113 | undirected, valued |
| <a id="movie_529"></a>`movie_529` | Peeping Tom | 33 | 111 | undirected, valued |
| <a id="movie_53"></a>`movie_53` | Analyze This | 39 | 130 | undirected, valued |
| <a id="movie_530"></a>`movie_530` | A Perfect World | 52 | 140 | undirected, valued |
| <a id="movie_531"></a>`movie_531` | Pet Sematary | 20 | 43 | undirected, valued |
| <a id="movie_532"></a>`movie_532` | Pet Sematary II | 31 | 79 | undirected, valued |
| <a id="movie_533"></a>`movie_533` | Petulia | 42 | 137 | undirected, valued |
| <a id="movie_534"></a>`movie_534` | Philadelphia | 65 | 258 | undirected, valued |
| <a id="movie_535"></a>`movie_535` | Phone Booth | 17 | 40 | undirected, valued |
| <a id="movie_536"></a>`movie_536` | Pi | 15 | 26 | undirected, valued |
| <a id="movie_537"></a>`movie_537` | The Pianist | 39 | 103 | undirected, valued |
| <a id="movie_538"></a>`movie_538` | The Piano | 25 | 73 | undirected, valued |
| <a id="movie_539"></a>`movie_539` | Pineapple Express | 31 | 78 | undirected, valued |
| <a id="movie_54"></a>`movie_54` | Anastasia | 31 | 98 | undirected, valued |
| <a id="movie_540"></a>`movie_540` | Pirates of the Caribbean: The Curse of the Black Pearl | 27 | 93 | undirected, valued |
| <a id="movie_541"></a>`movie_541` | Pitch Black | 12 | 42 | undirected, valued |
| <a id="movie_542"></a>`movie_542` | Planet of the Apes | 19 | 56 | undirected, valued |
| <a id="movie_543"></a>`movie_543` | Platinum Blonde | 30 | 99 | undirected, valued |
| <a id="movie_544"></a>`movie_544` | Platoon | 39 | 197 | undirected, valued |
| <a id="movie_545"></a>`movie_545` | Pleasantville | 45 | 167 | undirected, valued |
| <a id="movie_546"></a>`movie_546` | Point Break | 31 | 79 | undirected, valued |
| <a id="movie_547"></a>`movie_547` | Il Postino: The Postman | 49 | 195 | undirected, valued |
| <a id="movie_548"></a>`movie_548` | The Power of One | 43 | 114 | undirected, valued |
| <a id="movie_549"></a>`movie_549` | Precious | 35 | 93 | undirected, valued |
| <a id="movie_55"></a>`movie_55` | Angel Eyes | 33 | 85 | undirected, valued |
| <a id="movie_550"></a>`movie_550` | Predator | 13 | 29 | undirected, valued |
| <a id="movie_551"></a>`movie_551` | Pretty Woman | 36 | 69 | undirected, valued |
| <a id="movie_552"></a>`movie_552` | The Princess Bride | 21 | 64 | undirected, valued |
| <a id="movie_553"></a>`movie_553` | The Private Life of Sherlock Holmes | 22 | 62 | undirected, valued |
| <a id="movie_554"></a>`movie_554` | The Jack Benny Program | 61 | 239 | undirected, valued |
| <a id="movie_555"></a>`movie_555` | The Prophecy | 50 | 178 | undirected, valued |
| <a id="movie_556"></a>`movie_556` | The Proposal | 31 | 90 | undirected, valued |
| <a id="movie_557"></a>`movie_557` | Psycho | 21 | 49 | undirected, valued |
| <a id="movie_558"></a>`movie_558` | Public Enemies | 99 | 317 | undirected, valued |
| <a id="movie_559"></a>`movie_559` | Pulp Fiction | 38 | 102 | undirected, valued |
| <a id="movie_56"></a>`movie_56` | Angels & Demons | 25 | 55 | undirected, valued |
| <a id="movie_560"></a>`movie_560` | Punch-Drunk Love | 34 | 92 | undirected, valued |
| <a id="movie_561"></a>`movie_561` | Purple Rain | 30 | 89 | undirected, valued |
| <a id="movie_562"></a>`movie_562` | Queen of the Damned | 38 | 98 | undirected, valued |
| <a id="movie_563"></a>`movie_563` | The Queen | 39 | 123 | undirected, valued |
| <a id="movie_564"></a>`movie_564` | Rachel Getting Married | 21 | 65 | undirected, valued |
| <a id="movie_565"></a>`movie_565` | Raging Bull | 35 | 89 | undirected, valued |
| <a id="movie_566"></a>`movie_566` | Raising Arizona | 29 | 59 | undirected, valued |
| <a id="movie_567"></a>`movie_567` | Rambling Rose | 19 | 43 | undirected, valued |
| <a id="movie_568"></a>`movie_568` | Rambo: First Blood Part II | 23 | 55 | undirected, valued |
| <a id="movie_569"></a>`movie_569` | The Reader | 29 | 55 | undirected, valued |
| <a id="movie_57"></a>`movie_57` | Annie Hall | 52 | 183 | undirected, valued |
| <a id="movie_570"></a>`movie_570` | Real Genius | 55 | 223 | undirected, valued |
| <a id="movie_571"></a>`movie_571` | Rear Window | 12 | 17 | undirected, valued |
| <a id="movie_572"></a>`movie_572` | Red Planet | 22 | 65 | undirected, valued |
| <a id="movie_573"></a>`movie_573` | The Relic | 34 | 97 | undirected, valued |
| <a id="movie_574"></a>`movie_574` | Remember Me | 27 | 81 | undirected, valued |
| <a id="movie_575"></a>`movie_575` | The Replacements | 53 | 233 | undirected, valued |
| <a id="movie_576"></a>`movie_576` | Reservoir Dogs | 21 | 82 | undirected, valued |
| <a id="movie_577"></a>`movie_577` | Resident Evil | 22 | 81 | undirected, valued |
| <a id="movie_578"></a>`movie_578` | Revolutionary Road | 18 | 34 | undirected, valued |
| <a id="movie_579"></a>`movie_579` | Ring | 29 | 69 | undirected, valued |
| <a id="movie_58"></a>`movie_58` | The Anniversary Party | 28 | 188 | undirected, valued |
| <a id="movie_580"></a>`movie_580` | RKO 281 | 41 | 126 | undirected, valued |
| <a id="movie_581"></a>`movie_581` | The Road | 13 | 23 | undirected, valued |
| <a id="movie_582"></a>`movie_582` | Robin Hood: Prince of Thieves | 39 | 174 | undirected, valued |
| <a id="movie_583"></a>`movie_583` | The Rock | 36 | 90 | undirected, valued |
| <a id="movie_584"></a>`movie_584` | RocknRolla | 40 | 144 | undirected, valued |
| <a id="movie_585"></a>`movie_585` | Rocky | 46 | 170 | undirected, valued |
| <a id="movie_586"></a>`movie_586` | The Rocky Horror Picture Show | 20 | 63 | undirected, valued |
| <a id="movie_587"></a>`movie_587` | Romeo Juliet | 41 | 120 | undirected, valued |
| <a id="movie_588"></a>`movie_588` | Ronin | 18 | 48 | undirected, valued |
| <a id="movie_589"></a>`movie_589` | Gunsmoke | 25 | 133 | undirected, valued |
| <a id="movie_59"></a>`movie_59` | Antitrust | 43 | 113 | undirected, valued |
| <a id="movie_590"></a>`movie_590` | The Ruins | 19 | 73 | undirected, valued |
| <a id="movie_591"></a>`movie_591` | Runaway Bride | 31 | 98 | undirected, valued |
| <a id="movie_592"></a>`movie_592` | Rush Hour | 39 | 108 | undirected, valued |
| <a id="movie_593"></a>`movie_593` | Rush Hour 2 | 24 | 51 | undirected, valued |
| <a id="movie_594"></a>`movie_594` | Donnie Darko | 28 | 80 | undirected, valued |
| <a id="movie_595"></a>`movie_595` | The Saint | 53 | 115 | undirected, valued |
| <a id="movie_596"></a>`movie_596` | The Salton Sea | 28 | 55 | undirected, valued |
| <a id="movie_597"></a>`movie_597` | The Sandlot | 39 | 230 | undirected, valued |
| <a id="movie_598"></a>`movie_598` | Save the Last Dance | 33 | 93 | undirected, valued |
| <a id="movie_599"></a>`movie_599` | Saving Private Ryan | 34 | 227 | undirected, valued |
| <a id="movie_6"></a>`movie_6` | 15 Minutes | 45 | 141 | undirected, valued |
| <a id="movie_60"></a>`movie_60` | Antz | 37 | 140 | undirected, valued |
| <a id="movie_600"></a>`movie_600` | Scarface | 49 | 157 | undirected, valued |
| <a id="movie_601"></a>`movie_601` | Schindler's List | 45 | 76 | undirected, valued |
| <a id="movie_602"></a>`movie_602` | Scream | 26 | 69 | undirected, valued |
| <a id="movie_603"></a>`movie_603` | Scream 2 | 43 | 186 | undirected, valued |
| <a id="movie_604"></a>`movie_604` | Scream 3 | 30 | 124 | undirected, valued |
| <a id="movie_605"></a>`movie_605` | Se7en | 49 | 100 | undirected, valued |
| <a id="movie_606"></a>`movie_606` | The Searchers | 40 | 152 | undirected, valued |
| <a id="movie_607"></a>`movie_607` | Semi-Pro | 56 | 275 | undirected, valued |
| <a id="movie_608"></a>`movie_608` | Sense and Sensibility | 25 | 128 | undirected, valued |
| <a id="movie_609"></a>`movie_609` | Serenity | 39 | 158 | undirected, valued |
| <a id="movie_61"></a>`movie_61` | The Apartment | 33 | 76 | undirected, valued |
| <a id="movie_610"></a>`movie_610` | Serial Mom | 48 | 167 | undirected, valued |
| <a id="movie_611"></a>`movie_611` | Sex and the City | 46 | 117 | undirected, valued |
| <a id="movie_612"></a>`movie_612` | Sex, Lies, and Videotape | 10 | 25 | undirected, valued |
| <a id="movie_613"></a>`movie_613` | Sexual Life | 28 | 56 | undirected, valued |
| <a id="movie_614"></a>`movie_614` | Shakespeare in Love | 47 | 219 | undirected, valued |
| <a id="movie_615"></a>`movie_615` | Shallow Grave | 16 | 27 | undirected, valued |
| <a id="movie_616"></a>`movie_616` | Shampoo | 44 | 209 | undirected, valued |
| <a id="movie_617"></a>`movie_617` | The Shawshank Redemption | 35 | 136 | undirected, valued |
| <a id="movie_618"></a>`movie_618` | She's Out of My League | 56 | 192 | undirected, valued |
| <a id="movie_619"></a>`movie_619` | Sherlock Holmes | 33 | 69 | undirected, valued |
| <a id="movie_62"></a>`movie_62` | Apocalypse Now | 40 | 211 | undirected, valued |
| <a id="movie_620"></a>`movie_620` | The Shining | 21 | 48 | undirected, valued |
| <a id="movie_621"></a>`movie_621` | The Shipping News | 29 | 63 | undirected, valued |
| <a id="movie_622"></a>`movie_622` | They Came from Within | 16 | 30 | undirected, valued |
| <a id="movie_623"></a>`movie_623` | Sideways | 41 | 119 | undirected, valued |
| <a id="movie_624"></a>`movie_624` | The Siege | 45 | 132 | undirected, valued |
| <a id="movie_625"></a>`movie_625` | Signs | 21 | 51 | undirected, valued |
| <a id="movie_626"></a>`movie_626` | The Silence of the Lambs | 35 | 78 | undirected, valued |
| <a id="movie_627"></a>`movie_627` | Silver Bullet | 29 | 54 | undirected, valued |
| <a id="movie_628"></a>`movie_628` | S1m0ne | 48 | 116 | undirected, valued |
| <a id="movie_629"></a>`movie_629` | Sister Act | 51 | 217 | undirected, valued |
| <a id="movie_63"></a>`movie_63` | Apt Pupil | 21 | 56 | undirected, valued |
| <a id="movie_630"></a>`movie_630` | The Sixth Sense | 24 | 41 | undirected, valued |
| <a id="movie_631"></a>`movie_631` | Sleepless in Seattle | 53 | 154 | undirected, valued |
| <a id="movie_632"></a>`movie_632` | Sleepy Hollow | 30 | 84 | undirected, valued |
| <a id="movie_633"></a>`movie_633` | Sling Blade | 31 | 83 | undirected, valued |
| <a id="movie_634"></a>`movie_634` | Slither | 31 | 88 | undirected, valued |
| <a id="movie_635"></a>`movie_635` | Slumdog Millionaire | 39 | 95 | undirected, valued |
| <a id="movie_636"></a>`movie_636` | Smokin' Aces | 49 | 180 | undirected, valued |
| <a id="movie_637"></a>`movie_637` | Snatch | 35 | 133 | undirected, valued |
| <a id="movie_638"></a>`movie_638` | Snow Falling on Cedars | 39 | 87 | undirected, valued |
| <a id="movie_639"></a>`movie_639` | So I Married an Axe Murderer | 53 | 154 | undirected, valued |
| <a id="movie_64"></a>`movie_64` | Army of Darkness | 23 | 68 | undirected, valued |
| <a id="movie_640"></a>`movie_640` | Solaris | 5 | 10 | undirected, valued |
| <a id="movie_641"></a>`movie_641` | Soldier | 26 | 82 | undirected, valued |
| <a id="movie_642"></a>`movie_642` | Someone to Watch Over Me | 25 | 60 | undirected, valued |
| <a id="movie_643"></a>`movie_643` | Something's Gotta Give | 28 | 128 | undirected, valued |
| <a id="movie_644"></a>`movie_644` | Spanglish | 24 | 71 | undirected, valued |
| <a id="movie_645"></a>`movie_645` | Spare Me | 27 | 94 | undirected, valued |
| <a id="movie_646"></a>`movie_646` | Meet the Spartans | 54 | 154 | undirected, valued |
| <a id="movie_647"></a>`movie_647` | Speed Racer | 76 | 274 | undirected, valued |
| <a id="movie_648"></a>`movie_648` | Sphere | 15 | 38 | undirected, valued |
| <a id="movie_649"></a>`movie_649` | Spider-Man | 37 | 113 | undirected, valued |
| <a id="movie_65"></a>`movie_65` | As Good as It Gets | 35 | 74 | undirected, valued |
| <a id="movie_650"></a>`movie_650` | Star Trek | 57 | 177 | undirected, valued |
| <a id="movie_651"></a>`movie_651` | Star Trek II: The Wrath of Khan | 25 | 107 | undirected, valued |
| <a id="movie_652"></a>`movie_652` | Star Trek: First Contact | 30 | 79 | undirected, valued |
| <a id="movie_653"></a>`movie_653` | Star Trek: Generations | 41 | 162 | undirected, valued |
| <a id="movie_654"></a>`movie_654` | Star Trek: Insurrection | 21 | 75 | undirected, valued |
| <a id="movie_655"></a>`movie_655` | Star Trek: The Motion Picture | 28 | 104 | undirected, valued |
| <a id="movie_656"></a>`movie_656` | Star Wars: Episode IV - A New Hope | 42 | 124 | undirected, valued |
| <a id="movie_657"></a>`movie_657` | Star Wars: Episode II - Attack of the Clones | 47 | 148 | undirected, valued |
| <a id="movie_658"></a>`movie_658` | Star Wars: Episode VI - Return of the Jedi | 32 | 84 | undirected, valued |
| <a id="movie_659"></a>`movie_659` | Star Wars: Episode V - The Empire Strikes Back | 37 | 82 | undirected, valued |
| <a id="movie_66"></a>`movie_66` | Assassins | 16 | 23 | undirected, valued |
| <a id="movie_660"></a>`movie_660` | Starman | 38 | 96 | undirected, valued |
| <a id="movie_661"></a>`movie_661` | Starship Troopers | 49 | 187 | undirected, valued |
| <a id="movie_662"></a>`movie_662` | State and Main | 42 | 208 | undirected, valued |
| <a id="movie_663"></a>`movie_663` | Station West | 30 | 101 | undirected, valued |
| <a id="movie_664"></a>`movie_664` | Stepmom | 21 | 40 | undirected, valued |
| <a id="movie_665"></a>`movie_665` | The Sting | 36 | 113 | undirected, valued |
| <a id="movie_666"></a>`movie_666` | Stir of Echoes | 32 | 116 | undirected, valued |
| <a id="movie_667"></a>`movie_667` | Storytelling | 21 | 43 | undirected, valued |
| <a id="movie_668"></a>`movie_668` | Strange Days | 38 | 103 | undirected, valued |
| <a id="movie_669"></a>`movie_669` | Strangers on a Train | 50 | 197 | undirected, valued |
| <a id="movie_67"></a>`movie_67` | The Assignment | 51 | 142 | undirected, valued |
| <a id="movie_670"></a>`movie_670` | Sugar | 45 | 129 | undirected, valued |
| <a id="movie_671"></a>`movie_671` | Sugar & Spice | 40 | 124 | undirected, valued |
| <a id="movie_672"></a>`movie_672` | Sunset Blvd. | 35 | 75 | undirected, valued |
| <a id="movie_673"></a>`movie_673` | Sunshine Cleaning | 30 | 59 | undirected, valued |
| <a id="movie_674"></a>`movie_674` | Superbad | 35 | 94 | undirected, valued |
| <a id="movie_675"></a>`movie_675` | The Surfer King | 30 | 60 | undirected, valued |
| <a id="movie_676"></a>`movie_676` | Suspect Zero | 27 | 50 | undirected, valued |
| <a id="movie_677"></a>`movie_677` | The Sweet Hereafter | 18 | 38 | undirected, valued |
| <a id="movie_678"></a>`movie_678` | Sweet Smell of Success | 37 | 111 | undirected, valued |
| <a id="movie_679"></a>`movie_679` | Swingers | 22 | 74 | undirected, valued |
| <a id="movie_68"></a>`movie_68` | At First Sight | 27 | 73 | undirected, valued |
| <a id="movie_680"></a>`movie_680` | Swordfish | 28 | 51 | undirected, valued |
| <a id="movie_681"></a>`movie_681` | Synecdoche, New York | 71 | 264 | undirected, valued |
| <a id="movie_682"></a>`movie_682` | Taking Lives | 29 | 55 | undirected, valued |
| <a id="movie_683"></a>`movie_683` | Taking Sides | 19 | 45 | undirected, valued |
| <a id="movie_684"></a>`movie_684` | The Talented Mr. Ripley | 22 | 42 | undirected, valued |
| <a id="movie_685"></a>`movie_685` | Taxi Driver | 22 | 57 | undirected, valued |
| <a id="movie_686"></a>`movie_686` | The Terminator | 32 | 52 | undirected, valued |
| <a id="movie_687"></a>`movie_687` | Terminator 2: Judgment Day | 26 | 57 | undirected, valued |
| <a id="movie_688"></a>`movie_688` | Terminator Salvation | 31 | 98 | undirected, valued |
| <a id="movie_689"></a>`movie_689` | Thelma & Louise | 20 | 43 | undirected, valued |
| <a id="movie_69"></a>`movie_69` | Austin Powers: International Man of Mystery | 40 | 103 | undirected, valued |
| <a id="movie_690"></a>`movie_690` | They | 2 | 1 | undirected, valued |
| <a id="movie_691"></a>`movie_691` | The Thing | 21 | 126 | undirected, valued |
| <a id="movie_692"></a>`movie_692` | Thirteen Days | 48 | 146 | undirected, valued |
| <a id="movie_693"></a>`movie_693` | This Boy's Life | 30 | 64 | undirected, valued |
| <a id="movie_694"></a>`movie_694` | Three Kings | 40 | 176 | undirected, valued |
| <a id="movie_695"></a>`movie_695` | Kings of the Turf | 9 | 16 | undirected, valued |
| <a id="movie_696"></a>`movie_696` | 3 Men and a Baby | 43 | 147 | undirected, valued |
| <a id="movie_697"></a>`movie_697` | The Three Musketeers | 32 | 120 | undirected, valued |
| <a id="movie_698"></a>`movie_698` | Thunderheart | 39 | 154 | undirected, valued |
| <a id="movie_699"></a>`movie_699` | Timber Falls | 9 | 24 | undirected, valued |
| <a id="movie_7"></a>`movie_7` | 17 Again | 36 | 128 | undirected, valued |
| <a id="movie_70"></a>`movie_70` | Austin Powers: The Spy Who Shagged Me | 41 | 117 | undirected, valued |
| <a id="movie_700"></a>`movie_700` | The Time Machine | 12 | 22 | undirected, valued |
| <a id="movie_701"></a>`movie_701` | Tin Cup | 33 | 123 | undirected, valued |
| <a id="movie_702"></a>`movie_702` | The Day After Tomorrow | 42 | 171 | undirected, valued |
| <a id="movie_703"></a>`movie_703` | Titanic | 70 | 299 | undirected, valued |
| <a id="movie_704"></a>`movie_704` | TMNT | 32 | 202 | undirected, valued |
| <a id="movie_705"></a>`movie_705` | To Sleep with Anger | 30 | 115 | undirected, valued |
| <a id="movie_706"></a>`movie_706` | Tombstone | 48 | 337 | undirected, valued |
| <a id="movie_707"></a>`movie_707` | Tomorrow Never Dies | 75 | 217 | undirected, valued |
| <a id="movie_708"></a>`movie_708` | Top Gun | 34 | 167 | undirected, valued |
| <a id="movie_709"></a>`movie_709` | Total Recall | 41 | 85 | undirected, valued |
| <a id="movie_71"></a>`movie_71` | Autumn in New York | 33 | 96 | undirected, valued |
| <a id="movie_710"></a>`movie_710` | The Tourist | 19 | 46 | undirected, valued |
| <a id="movie_711"></a>`movie_711` | Toy Story | 39 | 204 | undirected, valued |
| <a id="movie_712"></a>`movie_712` | Traffic | 68 | 131 | undirected, valued |
| <a id="movie_713"></a>`movie_713` | Trainspotting | 22 | 60 | undirected, valued |
| <a id="movie_714"></a>`movie_714` | The Transformers: The Movie | 63 | 591 | undirected, valued |
| <a id="movie_715"></a>`movie_715` | Tremors | 16 | 74 | undirected, valued |
| <a id="movie_716"></a>`movie_716` | TRON | 27 | 111 | undirected, valued |
| <a id="movie_717"></a>`movie_717` | Tropic Thunder | 44 | 219 | undirected, valued |
| <a id="movie_718"></a>`movie_718` | True Lies | 29 | 59 | undirected, valued |
| <a id="movie_719"></a>`movie_719` | True Romance | 43 | 237 | undirected, valued |
| <a id="movie_72"></a>`movie_72` | Avatar | 30 | 105 | undirected, valued |
| <a id="movie_720"></a>`movie_720` | The Truman Show | 44 | 87 | undirected, valued |
| <a id="movie_721"></a>`movie_721` | Twilight | 31 | 135 | undirected, valued |
| <a id="movie_722"></a>`movie_722` | New Moon | 36 | 130 | undirected, valued |
| <a id="movie_723"></a>`movie_723` | Twin Peaks | 56 | 144 | undirected, valued |
| <a id="movie_724"></a>`movie_724` | Dead Ringers | 45 | 99 | undirected, valued |
| <a id="movie_725"></a>`movie_725` | Two for the Money | 40 | 103 | undirected, valued |
| <a id="movie_726"></a>`movie_726` | U Turn | 20 | 52 | undirected, valued |
| <a id="movie_727"></a>`movie_727` | Unbreakable | 30 | 60 | undirected, valued |
| <a id="movie_728"></a>`movie_728` | Up | 22 | 49 | undirected, valued |
| <a id="movie_729"></a>`movie_729` | Up in the Air | 27 | 47 | undirected, valued |
| <a id="movie_73"></a>`movie_73` | The Avengers | 21 | 48 | undirected, valued |
| <a id="movie_730"></a>`movie_730` | The Usual Suspects | 35 | 130 | undirected, valued |
| <a id="movie_731"></a>`movie_731` | V for Vendetta | 44 | 100 | undirected, valued |
| <a id="movie_732"></a>`movie_732` | Valkyrie | 45 | 101 | undirected, valued |
| <a id="movie_733"></a>`movie_733` | Vanilla Sky | 29 | 69 | undirected, valued |
| <a id="movie_734"></a>`movie_734` | The Verdict | 42 | 114 | undirected, valued |
| <a id="movie_735"></a>`movie_735` | Very Bad Things | 30 | 118 | undirected, valued |
| <a id="movie_736"></a>`movie_736` | Virtuosity | 35 | 84 | undirected, valued |
| <a id="movie_737"></a>`movie_737` | Wag the Dog | 60 | 269 | undirected, valued |
| <a id="movie_738"></a>`movie_738` | A Walk to Remember | 20 | 42 | undirected, valued |
| <a id="movie_739"></a>`movie_739` | Walking Tall | 38 | 142 | undirected, valued |
| <a id="movie_74"></a>`movie_74` | Awakenings | 52 | 261 | undirected, valued |
| <a id="movie_740"></a>`movie_740` | Wall Street | 53 | 162 | undirected, valued |
| <a id="movie_741"></a>`movie_741` | WALL-E | 34 | 206 | undirected, valued |
| <a id="movie_742"></a>`movie_742` | Wanted | 25 | 54 | undirected, valued |
| <a id="movie_743"></a>`movie_743` | War of the Worlds | 31 | 114 | undirected, valued |
| <a id="movie_744"></a>`movie_744` | Warm Springs | 49 | 193 | undirected, valued |
| <a id="movie_745"></a>`movie_745` | Watchmen | 76 | 201 | undirected, valued |
| <a id="movie_746"></a>`movie_746` | We Own the Night | 57 | 204 | undirected, valued |
| <a id="movie_747"></a>`movie_747` | What About Bob? | 51 | 134 | undirected, valued |
| <a id="movie_748"></a>`movie_748` | What Lies Beneath | 18 | 32 | undirected, valued |
| <a id="movie_749"></a>`movie_749` | When a Stranger Calls | 41 | 117 | undirected, valued |
| <a id="movie_75"></a>`movie_75` | Babel | 71 | 154 | undirected, valued |
| <a id="movie_750"></a>`movie_750` | While She Was Out | 19 | 42 | undirected, valued |
| <a id="movie_751"></a>`movie_751` | White Christmas | 28 | 114 | undirected, valued |
| <a id="movie_752"></a>`movie_752` | White Jazz | 41 | 119 | undirected, valued |
| <a id="movie_753"></a>`movie_753` | White Squall | 43 | 279 | undirected, valued |
| <a id="movie_754"></a>`movie_754` | Whiteout | 24 | 62 | undirected, valued |
| <a id="movie_755"></a>`movie_755` | Who Framed Roger Rabbit | 43 | 138 | undirected, valued |
| <a id="movie_756"></a>`movie_756` | Wild at Heart | 41 | 84 | undirected, valued |
| <a id="movie_757"></a>`movie_757` | The Wild Bunch | 55 | 392 | undirected, valued |
| <a id="movie_758"></a>`movie_758` | Where the Wild Things Are | 28 | 88 | undirected, valued |
| <a id="movie_759"></a>`movie_759` | Wild Wild West | 28 | 77 | undirected, valued |
| <a id="movie_76"></a>`movie_76` | Bachelor Party | 62 | 284 | undirected, valued |
| <a id="movie_760"></a>`movie_760` | Willow | 39 | 123 | undirected, valued |
| <a id="movie_761"></a>`movie_761` | Witness | 48 | 231 | undirected, valued |
| <a id="movie_762"></a>`movie_762` | Wonder Boys | 29 | 86 | undirected, valued |
| <a id="movie_763"></a>`movie_763` | The Woodsman | 15 | 25 | undirected, valued |
| <a id="movie_764"></a>`movie_764` | The Wrestler | 43 | 81 | undirected, valued |
| <a id="movie_765"></a>`movie_765` | The X Files | 24 | 41 | undirected, valued |
| <a id="movie_766"></a>`movie_766` | X-Men | 25 | 91 | undirected, valued |
| <a id="movie_767"></a>`movie_767` | X-Men Origins: Wolverine | 38 | 67 | undirected, valued |
| <a id="movie_768"></a>`movie_768` | xXx | 27 | 60 | undirected, valued |
| <a id="movie_769"></a>`movie_769` | Yes Man | 50 | 132 | undirected, valued |
| <a id="movie_77"></a>`movie_77` | Backdraft | 40 | 174 | undirected, valued |
| <a id="movie_770"></a>`movie_770` | You Can Count on Me | 16 | 39 | undirected, valued |
| <a id="movie_771"></a>`movie_771` | You've Got Mail | 38 | 96 | undirected, valued |
| <a id="movie_772"></a>`movie_772` | Youth in Revolt | 42 | 129 | undirected, valued |
| <a id="movie_773"></a>`movie_773` | Zerophilia | 14 | 44 | undirected, valued |
| <a id="movie_78"></a>`movie_78` | Bad Boys | 38 | 95 | undirected, valued |
| <a id="movie_79"></a>`movie_79` | Bad Day at Black Rock | 15 | 50 | undirected, valued |
| <a id="movie_8"></a>`movie_8` | One Eight Seven | 33 | 68 | undirected, valued |
| <a id="movie_80"></a>`movie_80` | The Bad Lieutenant: Port of Call - New Orleans | 39 | 84 | undirected, valued |
| <a id="movie_81"></a>`movie_81` | Bad Santa | 27 | 64 | undirected, valued |
| <a id="movie_82"></a>`movie_82` | Badlands | 18 | 28 | undirected, valued |
| <a id="movie_83"></a>`movie_83` | Bamboozled | 56 | 198 | undirected, valued |
| <a id="movie_84"></a>`movie_84` | Barry Lyndon | 47 | 95 | undirected, valued |
| <a id="movie_85"></a>`movie_85` | Basic | 22 | 65 | undirected, valued |
| <a id="movie_86"></a>`movie_86` | Basic Instinct | 25 | 84 | undirected, valued |
| <a id="movie_87"></a>`movie_87` | Basquiat | 59 | 365 | undirected, valued |
| <a id="movie_88"></a>`movie_88` | Batman | 49 | 127 | undirected, valued |
| <a id="movie_89"></a>`movie_89` | Batman Returns | 51 | 124 | undirected, valued |
| <a id="movie_9"></a>`movie_9` | 2001: A Space Odyssey | 27 | 102 | undirected, valued |
| <a id="movie_90"></a>`movie_90` | The Battle of Algiers | 33 | 67 | undirected, valued |
| <a id="movie_91"></a>`movie_91` | The Battle of Shaker Heights | 32 | 80 | undirected, valued |
| <a id="movie_92"></a>`movie_92` | The Beach | 35 | 104 | undirected, valued |
| <a id="movie_93"></a>`movie_93` | Bean | 32 | 84 | undirected, valued |
| <a id="movie_94"></a>`movie_94` | Beavis and Butt-Head Do America | 56 | 150 | undirected, valued |
| <a id="movie_95"></a>`movie_95` | Being Human | 59 | 154 | undirected, valued |
| <a id="movie_96"></a>`movie_96` | Being John Malkovich | 34 | 83 | undirected, valued |
| <a id="movie_97"></a>`movie_97` | Being There | 48 | 114 | undirected, valued |
| <a id="movie_98"></a>`movie_98` | The Believer | 50 | 150 | undirected, valued |
| <a id="movie_99"></a>`movie_99` | Beloved | 31 | 65 | undirected, valued |

## Freeman's data sets (UCINET / Moreno collection)
{: #freeman }

Classic network data sets of the UCINET collection, as distributed by the University of California, Irvine (<http://moreno.ss.uci.edu/data.html>) and compiled by Linton Freeman and colleagues; the original studies are named for each data set.

### ants_1: Ant Colony (I)
{: #ants_1 }
- **What:** Dominance encounters among 16 worker ants of one colony that has a queen; a tie records one ant ritually dominating another, repeated encounters appear as parallel ties.
- **Structure:** `ants_1`: directed, multiple edges; 16 nodes, 200 ties. Vertex attributes: none; edge attributes: none.
- **Source:** Cole (1981), *Science* 212
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/ants_1.html>
- **Load:** `nwwebuse schoch ants_1`

### ants_2: Ant Colony (II)
{: #ants_2 }
- **What:** The same kind of dominance encounters among 13 worker ants of a colony without a queen.
- **Structure:** `ants_2`: directed, multiple edges; 13 nodes, 361 ties. Vertex attributes: none; edge attributes: none.
- **Source:** Cole (1981), *Science* 212
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/ants_2.html>
- **Load:** `nwwebuse schoch ants_2`

### bible: Nouns in the King's James Bible
{: #bible }
- **What:** Proper nouns (persons and places) of the King James Bible; two nouns are tied, with a count, when they occur in the same verse.
- **Structure:** `bible`: undirected, valued; 1773 nodes, 9131 ties. Vertex attributes: none; edge attributes: weight.
- **Source:** Harrison, BibleViz project, http://chrisharrison.net/projects/bibleviz/index.html
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/bible.html>
- **Load:** `nwwebuse schoch bible`

### bkfrab: Bernard/Killworth - Fraternity (interaction)
{: #bkfrab }
- **What:** Observed interactions among 58 residents of a fraternity house; the tie value counts how often two men were seen together.
- **Structure:** `bkfrab`: undirected, valued; 58 nodes, 967 ties. Vertex attributes: none; edge attributes: weight.
- **Source:** Bernard, Killworth and Sailer (1980), *Social Networks* 2; (1982), *Social Science Research* 11
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/bkfrab.html>
- **Load:** `nwwebuse schoch bkfrab`

### bkfrac: Bernard/Killworth - Fraternity (rankings)
{: #bkfrac }
- **What:** The same fraternity: each man's ranking of the others by how much he interacts with them, stored as directed valued ties.
- **Structure:** `bkfrac`: directed, valued; 58 nodes, 3306 ties. Vertex attributes: none; edge attributes: weight.
- **Source:** Bernard, Killworth and Sailer (1980), *Social Networks* 2
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/bkfrac.html>
- **Load:** `nwwebuse schoch bkfrac`

### bkoffb: Bernard/Killworth - Office (interaction)
{: #bkoffb }
- **What:** Observed interactions among 40 members of a small office; the tie value counts joint observations.
- **Structure:** `bkoffb`: undirected, valued; 40 nodes, 238 ties. Vertex attributes: none; edge attributes: weight.
- **Source:** Bernard, Killworth and Sailer (1980), *Social Networks* 2
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/bkoffb.html>
- **Load:** `nwwebuse schoch bkoffb`

### bkoffc: Bernard/Killworth - Office (rankings)
{: #bkoffc }
- **What:** The same office: each person's ranking of the others by interaction, stored as directed valued ties.
- **Structure:** `bkoffc`: directed, valued; 40 nodes, 1558 ties. Vertex attributes: none; edge attributes: weight.
- **Source:** Bernard, Killworth and Sailer (1980), *Social Networks* 2
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/bkoffc.html>
- **Load:** `nwwebuse schoch bkoffc`

### bktecb: Bernard/Killworth - Tech company (interaction)
{: #bktecb }
- **What:** Observed interactions among 34 members of a university technical group; the tie value counts joint observations.
- **Structure:** `bktecb`: undirected, valued; 34 nodes, 175 ties. Vertex attributes: none; edge attributes: weight.
- **Source:** Bernard, Killworth and Sailer (1980), *Social Networks* 2
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/bktecb.html>
- **Load:** `nwwebuse schoch bktecb`

### bktecc: Bernard/Killworth - Tech company (rankings)
{: #bktecc }
- **What:** The same group: each person's ranking of the others by interaction, stored as directed valued ties.
- **Structure:** `bktecc`: directed, valued; 34 nodes, 1122 ties. Vertex attributes: none; edge attributes: weight.
- **Source:** Bernard, Killworth and Sailer (1980), *Social Networks* 2
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/bktecc.html>
- **Load:** `nwwebuse schoch bktecc`

### bott: Preschool
{: #bott }
- **What:** Play interactions among 11 children of a nursery school in the 1920s; ties are directed from the child observed to the child involved and valued by how often.
- **Structure:** `bott`: directed, valued, multiple edges; 11 nodes, 256 ties. Vertex attributes: age, gender; edge attributes: weight, relation.
- **Source:** Bott (1928), *Genetic Psychology Monographs* 4
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/bott.html>
- **Load:** `nwwebuse schoch bott`

### ceos_clubs: Ceo's and Clubs
{: #ceos_clubs }
- **What:** Two-mode network linking 26 chief executives (and spouses) in one metropolitan area to the 15 clubs and boards in which they held membership.
- **Structure:** `ceos_clubs`: two-mode; 41 nodes, 98 ties (modes 26 and 15). Vertex attributes: type; edge attributes: none.
- **Source:** Galaskiewicz (1985), *Social Organization of an Urban Grants Economy*, Academic Press
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/ceos_clubs.html>
- **Load:** `nwwebuse schoch ceos_clubs`

### crime: St. Louis Crimes
{: #crime }
- **What:** Two-mode network of persons (victims, suspects, witnesses) and the crimes they were recorded in, from police records of one US city.
- **Structure:** `crime`: two-mode, valued; 1427 nodes, 1487 ties (modes 870 and 557). Vertex attributes: type, gender; edge attributes: weight.
- **Source:** UCINET collection
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/crime.html>
- **Load:** `nwwebuse schoch crime`

### dolphins_1: Dolphins (I)
{: #dolphins_1 }
- **What:** Association counts among 13 male dolphins seen swimming together in a lagoon; undirected, valued.
- **Structure:** `dolphins_1`: undirected, valued, loops; 13 nodes, 45 ties. Vertex attributes: none; edge attributes: weight.
- **Source:** Connor, Smolker and Richards (1992), in Harcourt and de Waal (eds.), *Coalitions and Alliances in Humans and Other Animals*
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/dolphins_1.html>
- **Load:** `nwwebuse schoch dolphins_1`

### dolphins_2: Dolphins (II)
{: #dolphins_2 }
- **What:** Frequent associations among the 62 bottlenose dolphins of one resident community; undirected, unvalued.
- **Structure:** `dolphins_2`: undirected; 62 nodes, 159 ties. Vertex attributes: none; edge attributes: none.
- **Source:** Lusseau et al. (2003), *Behavioral Ecology and Sociobiology* 54
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/dolphins_2.html>
- **Load:** `nwwebuse schoch dolphins_2`

### eies_messages: EIES (Messages)
{: #eies_messages }
- **What:** Message counts among 32 researchers who used an early computer-conference system; directed and valued.
- **Structure:** `eies_messages`: directed, valued, loops; 32 nodes, 460 ties. Vertex attributes: Citations, Discipline; edge attributes: weight.
- **Source:** Freeman and Freeman (1979), *Social Science Research Reports* 46, University of California, Irvine
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/eies_messages.html>
- **Load:** `nwwebuse schoch eies_messages`

### eies_relations: EIES (relations)
{: #eies_relations }
- **What:** Reported relationships among the same researchers, as directed ties with time stamps.
- **Structure:** `eies_relations`: directed, edge time stamps; 32 nodes, 768 ties. Vertex attributes: Citations, Discipline; edge attributes: rank_1, rank_2, time.
- **Source:** Freeman and Freeman (1979), *Social Science Research Reports* 46
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/eies_relations.html>
- **Load:** `nwwebuse schoch eies_relations`

### ffe_elite: French Financial Elite (elite)
{: #ffe_elite }
- **What:** Elite-membership judgements among 28 members of the French financial elite; directed.
- **Structure:** `ffe_elite`: directed; 28 nodes, 330 ties. Vertex attributes: birthdate, birthplace, cabinet, clubs, eliteprom, elitevote, ena, enayear, fathers_lev, finance_min, igyear, inspec_gen, masons, na, normal_sch, party, polytech, polyyear, prestige, religion, sciencepoly, socialreg, topboards, university, vertex_names, zipcode; edge attributes: edgevalue, na.
- **Source:** Kadushin (1995), *American Sociological Review* 60
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/ffe_elite.html>
- **Load:** `nwwebuse schoch ffe_elite`

### ffe_friends: French Financial Elite (friendships)
{: #ffe_friends }
- **What:** Friendship among the same 28 members of the French financial elite; undirected.
- **Structure:** `ffe_friends`: undirected; 28 nodes, 66 ties. Vertex attributes: birthdate, birthplace, cabinet, clubs, eliteprom, elitevote, ena, enayear, fathers_lev, finance_min, igyear, inspec_gen, masons, na, normal_sch, party, polytech, polyyear, prestige, religion, sciencepoly, socialreg, topboards, university, vertex_names, zipcode; edge attributes: none.
- **Source:** Kadushin (1995), *American Sociological Review* 60
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/ffe_friends.html>
- **Load:** `nwwebuse schoch ffe_friends`

### ffe_influence: French Financial Elite (influence)
{: #ffe_influence }
- **What:** Who was named as influential by each of the same 28 persons; directed.
- **Structure:** `ffe_influence`: directed; 28 nodes, 100 ties. Vertex attributes: birthdate, birthplace, cabinet, clubs, eliteprom, elitevote, ena, enayear, fathers_lev, finance_min, igyear, inspec_gen, masons, na, normal_sch, party, polytech, polyyear, prestige, religion, sciencepoly, socialreg, topboards, university, vertex_names, zipcode; edge attributes: edgevalue, na.
- **Source:** Kadushin (1995), *American Sociological Review* 60
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/ffe_influence.html>
- **Load:** `nwwebuse schoch ffe_influence`

### flo_business: Florentine Families (Business)
{: #flo_business }
- **What:** Business ties (loans, partnerships) among 16 prominent families of Renaissance Florence; undirected.
- **Structure:** `flo_business`: undirected; 16 nodes, 15 ties. Vertex attributes: wealth, priors, ties; edge attributes: none.
- **Source:** Breiger and Pattison (1986), *Social Networks* 8
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/flo_business.html>
- **Load:** `nwwebuse schoch flo_business`

### flo_marriage: Florentine Families (Marriage)
{: #flo_marriage }
- **What:** Marriage ties among the same 16 Florentine families; undirected.
- **Structure:** `flo_marriage`: undirected; 16 nodes, 20 ties. Vertex attributes: wealth, priors, ties; edge attributes: none.
- **Source:** Breiger and Pattison (1986), *Social Networks* 8
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/flo_marriage.html>
- **Load:** `nwwebuse schoch flo_marriage`

### fraternity: Newcomb Fraternity
{: #fraternity }
- **What:** Fifteen weekly waves of sociometric preference rankings among 17 men living in a university fraternity house; each ranking is a directed network.
- **Structure:** 15 networks `fraternity_1` ... `fraternity_15`: directed; 17 nodes, 272 ties each. Vertex attributes: none; edge attributes: rank.
- **Source:** Newcomb (1961), *The Acquaintance Process*, Holt, Rinehart and Winston
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/fraternity.html>
- **Load:** `nwwebuse schoch fraternity`

### giraffe: Giraffe Affiliation
{: #giraffe }
- **What:** Association among six captive female giraffes; directed, valued, with parallel ties.
- **Structure:** `giraffe`: directed, valued, multiple edges; 6 nodes, 90 ties. Vertex attributes: none; edge attributes: weight, relation.
- **Source:** Bradshaw et al. (2007), *Journal of Comparative Psychology* 121
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/giraffe.html>
- **Load:** `nwwebuse schoch giraffe`

### hall: Residence Hall Friendship
{: #hall }
- **What:** Friendship nominations among 217 residents of a university residence hall; directed and valued.
- **Structure:** `hall`: directed, valued; 217 nodes, 2672 ties. Vertex attributes: none; edge attributes: weight.
- **Source:** Freeman, Webster and Kirke (1998), *Social Networks* 20
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/hall.html>
- **Load:** `nwwebuse schoch hall`

### hens: Hens Pecking order
{: #hens }
- **What:** Pecking order in a flock of 32 hens: a tie from one hen to another means the first pecks the second.
- **Structure:** `hens`: directed; 32 nodes, 496 ties. Vertex attributes: none; edge attributes: none.
- **Source:** Guhl (1953), Kansas State College Technical Bulletin 73
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/hens.html>
- **Load:** `nwwebuse schoch hens`

### highschool_boys: Friendships among High School Boys
{: #highschool_boys }
- **What:** Friendship choices among 70 boys of one high school at two points in time; directed with time stamps.
- **Structure:** `highschool_boys`: directed, multiple edges, edge time stamps; 70 nodes, 506 ties. Vertex attributes: none; edge attributes: time.
- **Source:** Coleman (1964), *Introduction to Mathematical Sociology*, Free Press
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/highschool_boys.html>
- **Load:** `nwwebuse schoch highschool_boys`

### ht_advice: High-tech Managers (Advice)
{: #ht_advice }
- **What:** Who asks whom for advice among 21 managers of a high-technology company; directed.
- **Structure:** `ht_advice`: directed; 21 nodes, 190 ties. Vertex attributes: age, tenure, level, dept; edge attributes: none.
- **Source:** Krackhardt (1987), *Social Networks* 9
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/ht_advice.html>
- **Load:** `nwwebuse schoch ht_advice`

### ht_friends: High-tech Managers (Friendships)
{: #ht_friends }
- **What:** Who counts whom as a friend among the same 21 managers; directed.
- **Structure:** `ht_friends`: directed; 21 nodes, 102 ties. Vertex attributes: age, tenure, level, dept; edge attributes: none.
- **Source:** Krackhardt (1987), *Social Networks* 9
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/ht_friends.html>
- **Load:** `nwwebuse schoch ht_friends`

### ht_reports: High-tech Managers (Reports to)
{: #ht_reports }
- **What:** Who reports to whom among the same 21 managers (the formal hierarchy); directed.
- **Structure:** `ht_reports`: directed; 21 nodes, 20 ties. Vertex attributes: age, tenure, level, dept; edge attributes: none.
- **Source:** Krackhardt (1987), *Social Networks* 9
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/ht_reports.html>
- **Load:** `nwwebuse schoch ht_reports`

### insna: INSNA Teacher Student
{: #insna }
- **What:** Teacher-student links among 60 founding members of a social network analysis association; directed.
- **Structure:** `insna`: directed; 60 nodes, 94 ties. Vertex attributes: none; edge attributes: none.
- **Source:** Reitz and White (1989), in Freeman, White and Romney (eds.), *Research Methods in Social Network Analysis*
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/insna.html>
- **Load:** `nwwebuse schoch insna`

### jazz: Collaboration in Jazz
{: #jazz }
- **What:** Jazz bands (about 1912 to 1940) as nodes, tied when they share a musician.
- **Structure:** `jazz`: undirected; 198 nodes, 2742 ties. Vertex attributes: none; edge attributes: none.
- **Source:** Gleiser and Danon (2003), *Advances in Complex Systems* 6
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/jazz.html>
- **Load:** `nwwebuse schoch jazz`

### jpr: Joint Senate Press Releases
{: #jpr }
- **What:** US senators tied when they issued joint press releases.
- **Structure:** `jpr`: undirected; 92 nodes, 477 ties. Vertex attributes: none; edge attributes: none.
- **Source:** Grimmer, Harvard University
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/jpr.html>
- **Load:** `nwwebuse schoch jpr`

### kangaroo: Kangaroo
{: #kangaroo }
- **What:** Spatial proximity counts among 17 free-ranging grey kangaroos in a nature reserve; undirected, valued.
- **Structure:** `kangaroo`: undirected, valued, loops; 17 nodes, 105 ties. Vertex attributes: ss_rank, ps_rank, gender; edge attributes: weight.
- **Source:** Grant (1973), *Animal Behaviour* 21
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/kangaroo.html>
- **Load:** `nwwebuse schoch kangaroo`

### karate: Karate Club (binary)
{: #karate }
- **What:** Zachary's karate club of 34 members that split into two factions; a tie means the two members interacted outside the club (present or absent).
- **Structure:** `karate`: undirected; 34 nodes, 78 ties. Vertex attributes: none; edge attributes: none.
- **Source:** Zachary (1977), *Journal of Anthropological Research* 33
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/karate.html>
- **Load:** `nwwebuse schoch karate`

### karate_weight: Karate Club (weighted)
{: #karate_weight }
- **What:** The same karate club with ties valued by the number of settings in which two members interacted.
- **Structure:** `karate_weight`: undirected, multiple edges; 34 nodes, 231 ties. Vertex attributes: none; edge attributes: none.
- **Source:** Zachary (1977), *Journal of Anthropological Research* 33
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/karate_weight.html>
- **Load:** `nwwebuse schoch karate_weight`

### law_advice: Law Firm (Advice)
{: #law_advice }
- **What:** Advice seeking among the 71 lawyers of one corporate law firm; directed.
- **Structure:** `law_advice`: directed; 71 nodes, 892 ties. Vertex attributes: status, gender, office, seniority, age, practice, law_school; edge attributes: none.
- **Source:** Lazega (2001), *The Collegial Phenomenon*, Oxford University Press
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/law_advice.html>
- **Load:** `nwwebuse schoch law_advice`

### law_cowork: Law Firm (Co-work)
{: #law_cowork }
- **What:** Co-working relations among the same 71 lawyers; directed.
- **Structure:** `law_cowork`: directed; 71 nodes, 1104 ties. Vertex attributes: status, gender, office, seniority, age, practice, law_school; edge attributes: none.
- **Source:** Lazega (2001), *The Collegial Phenomenon*, Oxford University Press
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/law_cowork.html>
- **Load:** `nwwebuse schoch law_cowork`

### law_friends: Law Firm (Friendship)
{: #law_friends }
- **What:** Friendship among the same 71 lawyers; directed.
- **Structure:** `law_friends`: directed; 71 nodes, 575 ties. Vertex attributes: status, gender, office, seniority, age, practice, law_school; edge attributes: none.
- **Source:** Lazega (2001), *The Collegial Phenomenon*, Oxford University Press
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/law_friends.html>
- **Load:** `nwwebuse schoch law_friends`

### literary: Swedish Literary Criticism
{: #literary }
- **What:** Swedish literary critics' reviews around 1880: authors tied when they were mentioned together in the same review; undirected.
- **Structure:** `literary`: undirected; 15 nodes, 17 ties. Vertex attributes: none; edge attributes: none.
- **Source:** Rosengren (1968), *Sociological Aspects of the Literary System*, Natur och Kultur
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/literary.html>
- **Load:** `nwwebuse schoch literary`

### macaque: Macaque Dominance
{: #macaque }
- **What:** Dominance relations among 62 adult female Japanese macaques of one group; a directed tie means the first dominates the second.
- **Structure:** `macaque`: directed, valued; 62 nodes, 1187 ties. Vertex attributes: lineage; edge attributes: weight.
- **Source:** Takahata (1991), in Fedigan and Asquith (eds.), *The Monkeys of Arashiyama*
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/macaque.html>
- **Load:** `nwwebuse schoch macaque`

### mine: Kapferer - Mine
{: #mine }
- **What:** Interaction among 15 workers in a Zambian mine during a labour conflict; undirected.
- **Structure:** `mine`: undirected; 15 nodes, 25 ties. Vertex attributes: none; edge attributes: none.
- **Source:** Kapferer (1969), in Mitchell (ed.), *Social Networks in Urban Situations*
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/mine.html>
- **Load:** `nwwebuse schoch mine`

### miserables: Les Miserables co-appearances
{: #miserables }
- **What:** Characters of the novel Les Miserables tied, with a count, when they appear in the same chapter.
- **Structure:** `miserables`: undirected, valued; 77 nodes, 254 ties. Vertex attributes: none; edge attributes: weight.
- **Source:** Knuth (1993), *The Stanford GraphBase*
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/miserables.html>
- **Load:** `nwwebuse schoch miserables`

### netsci: Netscience Coauthorship
{: #netsci }
- **What:** Co-authorship among researchers on network science, collected in 2006; undirected, valued.
- **Structure:** `netsci`: undirected, valued; 1589 nodes, 2742 ties. Vertex attributes: none; edge attributes: weight.
- **Source:** Newman (2006), *Physical Review E* 74
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/netsci.html>
- **Load:** `nwwebuse schoch netsci`

### physicians: Innovations among Physicians
{: #physicians }
- **What:** Physicians of four Illinois towns tied by who named whom as a discussion partner or friend, from a study of the spread of a new drug; directed.
- **Structure:** `physicians`: directed; 246 nodes, 1099 ties. Vertex attributes: city, adoption_date, med_sch_yr, meetings, jours, free_time, discuss, clubs, friends, community, patients, proximity, specialty; edge attributes: relation.
- **Source:** Coleman (1964), *Introduction to Mathematical Sociology*, Free Press
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/physicians.html>
- **Load:** `nwwebuse schoch physicians`

### polblogs: Political Blogs
{: #polblogs }
- **What:** Political weblogs of the 2004 US election period tied by hyperlinks; directed.
- **Structure:** `polblogs`: directed, loops; 1490 nodes, 19025 ties. Vertex attributes: pol; edge attributes: none.
- **Source:** Adamic and Glance (2005), WWW-2005 Workshop on the Weblogging Ecosystem
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/polblogs.html>
- **Load:** `nwwebuse schoch polblogs`

### polbooks: Political Books
{: #polbooks }
- **What:** Books about US politics tied when they were frequently bought by the same customers; directed as stored.
- **Structure:** `polbooks`: directed; 105 nodes, 441 ties. Vertex attributes: none; edge attributes: none.
- **Source:** Krebs, unpublished, http://www.orgnet.com/
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/polbooks.html>
- **Load:** `nwwebuse schoch polbooks`

### pony: Pony
{: #pony }
- **What:** Threats among 17 ponies; the tie value counts how often one pony threatened another.
- **Structure:** `pony`: directed, multiple edges; 17 nodes, 761 ties. Vertex attributes: none; edge attributes: none.
- **Source:** Clutton-Brock, Greenwood and Powell (1976), *Zeitschrift fuer Tierpsychologie* 41
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/pony.html>
- **Load:** `nwwebuse schoch pony`

### protein: Protein-Protein Interactions (probably yeast)
{: #protein }
- **What:** Protein-protein interaction network (probably of yeast); undirected, with parallel ties and loops.
- **Structure:** `protein`: undirected, multiple edges, loops; 2114 nodes, 4480 ties. Vertex attributes: number, group, lethality; edge attributes: none.
- **Source:** Jeong et al. (2001), *Nature* 411
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/protein.html>
- **Load:** `nwwebuse schoch protein`

### rhesus: Rhesus Monkey Grooming
{: #rhesus }
- **What:** Grooming among 16 free-ranging rhesus monkeys (7 males, 9 females); directed and valued.
- **Structure:** `rhesus`: directed, valued; 16 nodes, 111 ties. Vertex attributes: gender; edge attributes: weight.
- **Source:** Sade (1972), *Folia Primatologica* 18
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/rhesus.html>
- **Load:** `nwwebuse schoch rhesus`

### sampson: Monastery
{: #sampson }
- **What:** Sampson's monastery: ten sociometric networks (liking and similar relations, at several times) among 18 novices of a monastery, recorded around a conflict in the community.
- **Structure:** 10 networks `sampson_1` ... `sampson_10`: directed; 18 nodes, 39-58 ties each. Vertex attributes: none; edge attributes: rank.
- **Source:** Sampson (1969), *Crisis in a Cloister*, PhD thesis, Cornell University
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/sampson.html>
- **Load:** `nwwebuse schoch sampson`

### sheep: Bighorn Sheep Dominance
{: #sheep }
- **What:** Dominance encounters among 28 female bighorn sheep; directed and valued by the number of times one dominated the other.
- **Structure:** `sheep`: directed, valued; 28 nodes, 250 ties. Vertex attributes: age; edge attributes: weight.
- **Source:** Hass (1991), *Journal of Zoology* 225
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/sheep.html>
- **Load:** `nwwebuse schoch sheep`

### sn_auth: Social Networks Coauthors
{: #sn_auth }
- **What:** Co-authorship among authors of the journal Social Networks; undirected, valued.
- **Structure:** `sn_auth`: undirected, valued; 475 nodes, 625 ties. Vertex attributes: none; edge attributes: weight.
- **Source:** McCarty, INSNA conference data set
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/sn_auth.html>
- **Load:** `nwwebuse schoch sn_auth`

### southern_women: Davis - Southern Women
{: #southern_women }
- **What:** Davis's Southern women: 18 women and the 14 social events they attended; two-mode.
- **Structure:** `southern_women`: two-mode; 32 nodes, 89 ties (modes 18 and 14). Vertex attributes: type; edge attributes: none.
- **Source:** Davis, Gardner and Gardner (1941), *Deep South*, University of Chicago Press
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/southern_women.html>
- **Load:** `nwwebuse schoch southern_women`

### surfersb: Windsurfers (Interactions)
{: #surfersb }
- **What:** Interactions among 43 windsurfers on one beach; undirected, valued.
- **Structure:** `surfersb`: undirected, valued, loops; 43 nodes, 378 ties. Vertex attributes: none; edge attributes: weight.
- **Source:** Freeman, Freeman and Michaelson (1988), *Journal of Social and Biological Structures* 11
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/surfersb.html>
- **Load:** `nwwebuse schoch surfersb`

### surfersc: Windsurfers (Closeness)
{: #surfersc }
- **What:** The same windsurfers: how close they were judged to be to each other; undirected, valued.
- **Structure:** `surfersc`: undirected, valued; 43 nodes, 897 ties. Vertex attributes: none; edge attributes: weight.
- **Source:** Freeman, Freeman and Michaelson (1988), *Journal of Social and Biological Structures* 11
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/surfersc.html>
- **Load:** `nwwebuse schoch surfersc`

### tailor_social: Kapferer - Tailor-Shop (social)
{: #tailor_social }
- **What:** Social contacts among 39 workers of a tailor shop in Zambia, observed over several months; undirected, with time stamps.
- **Structure:** `tailor_social`: undirected, edge time stamps; 39 nodes, 278 ties. Vertex attributes: none; edge attributes: time.
- **Source:** Kapferer (1972), *Strategy and Transaction in an African Factory*, Manchester University Press
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/tailor_social.html>
- **Load:** `nwwebuse schoch tailor_social`

### tailor_work: Kapferer - Tailor-Shop (work)
{: #tailor_work }
- **What:** Work-related contacts among the same 39 tailors; directed, with time stamps.
- **Structure:** `tailor_work`: directed, edge time stamps; 39 nodes, 211 ties. Vertex attributes: none; edge attributes: time.
- **Source:** Kapferer (1972), *Strategy and Transaction in an African Factory*, Manchester University Press
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/tailor_work.html>
- **Load:** `nwwebuse schoch tailor_work`

### taro: Taro Exchange
{: #taro }
- **What:** Gift exchange of taro among 22 households of a Papuan village; undirected.
- **Structure:** `taro`: undirected; 22 nodes, 39 ties. Vertex attributes: none; edge attributes: none.
- **Source:** Hage and Harary (1983), *Structural Models in Anthropology*, Cambridge University Press
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/taro.html>
- **Load:** `nwwebuse schoch taro`

### train: Madrid Train Bombing
{: #train }
- **What:** Contacts among the 70 persons linked to the 2004 Madrid train bombings, valued, with parallel ties.
- **Structure:** `train`: undirected, valued, multiple edges; 70 nodes, 486 ties. Vertex attributes: none; edge attributes: weight.
- **Source:** Hayes (2006), *American Scientist* 94
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/train.html>
- **Load:** `nwwebuse schoch train`

### wiring: Bank Wiring Room
{: #wiring }
- **What:** Interaction among 14 workers in the bank wiring room of a factory (Hawthorne study); undirected.
- **Structure:** `wiring`: undirected; 14 nodes, 32 ties. Vertex attributes: none; edge attributes: sign.
- **Source:** Roethlisberger and Dickson (1939), *Management and the Worker*
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/wiring.html>
- **Load:** `nwwebuse schoch wiring`


## KONECT networks
{: #konect }

Networks that the package took from the Koblenz Network Collection (KONECT, <http://konect.cc/>). Cite the collection as Kunegis, J. (2013), KONECT - The Koblenz Network Collection, *Proc. Int. Web Observatory Workshop*, 1343-1350, together with the original study of each data set.

### arenas_email: Arenas Email
{: #arenas_email }
- **What:** E-mail contacts among members of a Spanish university: a tie exists when at least one message was sent; undirected.
- **Structure:** `arenas_email`: undirected; 1133 nodes, 5451 ties. Vertex attributes: none; edge attributes: none.
- **Source:** Guimera et al. (2003), *Physical Review E* 68
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/arenas_email.html>
- **Load:** `nwwebuse schoch arenas_email`

### arenas_meta: Arenas Metabolic
{: #arenas_meta }
- **What:** Metabolic network of the roundworm C. elegans: nodes are metabolites, ties interactions between them (loops possible).
- **Structure:** `arenas_meta`: undirected, multiple edges, loops; 453 nodes, 4596 ties. Vertex attributes: none; edge attributes: none.
- **Source:** Duch and Arenas (2005), *Physical Review E* 72
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/arenas_meta.html>
- **Load:** `nwwebuse schoch arenas_meta`

### brunson_club_membership: Brunson Club Membership
{: #brunson_club_membership }
- **What:** Two-mode network of 25 executives and the 15 clubs and boards they belong to.
- **Structure:** `brunson_club_membership`: two-mode; 40 nodes, 95 ties (modes 25 and 15). Vertex attributes: type; edge attributes: none.
- **Source:** Faust (1997), *Social Networks* 19
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/brunson_club_membership.html>
- **Load:** `nwwebuse schoch brunson_club_membership`

### brunson_corporate_leadership: Brunson Corporate Leadership
{: #brunson_corporate_leadership }
- **What:** Two-mode network of 20 corporate directors and 24 companies they led (1962).
- **Structure:** `brunson_corporate_leadership`: two-mode; 44 nodes, 99 ties (modes 20 and 24). Vertex attributes: type; edge attributes: none.
- **Source:** Barnes and Burkett (2010), INSNA *Connections* 30
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/brunson_corporate_leadership.html>
- **Load:** `nwwebuse schoch brunson_corporate_leadership`

### brunson_revolution: Brunson Revolution
{: #brunson_revolution }
- **What:** Two-mode network of 136 persons of the American Revolution era and the 5 organisations they belonged to.
- **Structure:** `brunson_revolution`: two-mode; 141 nodes, 160 ties (modes 136 and 5). Vertex attributes: type; edge attributes: none.
- **Source:** original data via https://github.com/corybrunson/triadic
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/brunson_revolution.html>
- **Load:** `nwwebuse schoch brunson_revolution`

### brunson_south_africa: Brunson South Africa
{: #brunson_south_africa }
- **What:** Two-mode network of 6 persons and the 5 companies they jointly led in South African finance.
- **Structure:** `brunson_south_africa`: two-mode; 11 nodes, 13 ties (modes 6 and 5). Vertex attributes: type; edge attributes: none.
- **Source:** Hobson (1919), *The Evolution of Modern Capitalism*
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/brunson_south_africa.html>
- **Load:** `nwwebuse schoch brunson_south_africa`

### chicagoroad: Road Transportation Network Chicago
{: #chicagoroad }
- **What:** Road network of the Chicago region; nodes are junctions, ties road links.
- **Structure:** `chicagoroad`: undirected; 1467 nodes, 1298 ties. Vertex attributes: none; edge attributes: none.
- **Source:** Eash et al. (1983), *Transportation Research Record* 994
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/chicagoroad.html>
- **Load:** `nwwebuse schoch chicagoroad`

### dnc_corecipient: DNC Email (Corecipients)
{: #dnc_corecipient }
- **What:** People who received the same e-mail in the 2016 DNC e-mail leak; undirected, valued by the number of shared e-mails.
- **Structure:** `dnc_corecipient`: undirected, valued, multiple edges; 906 nodes, 12085 ties. Vertex attributes: none; edge attributes: weight.
- **Source:** Pickhardt, http://www.rene-pickhardt.de/
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/dnc_corecipient.html>
- **Load:** `nwwebuse schoch dnc_corecipient`

### dnc_temporalGraph: DNC Email (Temporal)
{: #dnc_temporalGraph }
- **What:** E-mails of the 2016 DNC leak as directed, time-stamped ties from sender to recipient.
- **Structure:** `dnc_temporalGraph`: directed, multiple edges, edge time stamps; 1891 nodes, 37421 ties. Vertex attributes: none; edge attributes: timestamp.
- **Source:** Pickhardt, http://www.rene-pickhardt.de/
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/dnc_temporalGraph.html>
- **Load:** `nwwebuse schoch dnc_temporalGraph`

### euroroad: Road network Europe
{: #euroroad }
- **What:** International E-road network; nodes are cities, ties E-roads.
- **Structure:** `euroroad`: undirected; 1174 nodes, 1417 ties. Vertex attributes: none; edge attributes: none.
- **Source:** Subelj and Bajec (2011), *European Physical Journal B* 81
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/euroroad.html>
- **Load:** `nwwebuse schoch euroroad`

### f2f_hypertext: Face-2-face contacts at Hypertext
{: #f2f_hypertext }
- **What:** Face-to-face contacts among attendees of the ACM Hypertext 2009 conference; time-stamped, with parallel ties.
- **Structure:** `f2f_hypertext`: undirected, multiple edges, edge time stamps; 113 nodes, 20818 ties. Vertex attributes: none; edge attributes: timestamp.
- **Source:** Isella et al. (2011), *J. Theoretical Biology* 271
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/f2f_hypertext.html>
- **Load:** `nwwebuse schoch f2f_hypertext`

### f2f_infectious: Face-2-face contacts at Infectious
{: #f2f_infectious }
- **What:** Face-to-face contacts among visitors of a Dublin science exhibition in 2009; time-stamped, with parallel ties.
- **Structure:** `f2f_infectious`: undirected, multiple edges, edge time stamps; 410 nodes, 17298 ties. Vertex attributes: none; edge attributes: timestamp.
- **Source:** Isella et al. (2011), *J. Theoretical Biology* 271
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/f2f_infectious.html>
- **Load:** `nwwebuse schoch f2f_infectious`

### maayan_faa: FAA Preferred Routes
{: #maayan_faa }
- **What:** Preferred air routes between US airports and service centres; directed.
- **Structure:** `maayan_faa`: directed; 1226 nodes, 2613 ties. Vertex attributes: none; edge attributes: none.
- **Source:** Federal Aviation Administration, Preferred Routes Database
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/maayan_faa.html>
- **Load:** `nwwebuse schoch maayan_faa`

### maayan_pdzbase: Maayan Pdzbase
{: #maayan_pdzbase }
- **What:** Protein-protein interactions from PDZBase.
- **Structure:** `maayan_pdzbase`: undirected, loops; 212 nodes, 244 ties. Vertex attributes: none; edge attributes: none.
- **Source:** Beuming et al. (2005), *Bioinformatics* 21
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/maayan_pdzbase.html>
- **Load:** `nwwebuse schoch maayan_pdzbase`

### petster: Petster Friendships
{: #petster }
- **What:** Friendship ties among users of a pet-owner social site, with pet attributes.
- **Structure:** `petster`: undirected; 1858 nodes, 12534 ties. Vertex attributes: pet_name, joined, pet_species, pet_coloring, pet_gender, pet_birthday, pet_age, hometown, pet_favorite_toy, pet_favorite_activity, pet_favorite_food; edge attributes: none.
- **Source:** KONECT, http://konect.cc/
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/petster.html>
- **Load:** `nwwebuse schoch petster`

### powergrid: Powergrid
{: #powergrid }
- **What:** Power grid of the western United States: generators, transformers and substations as nodes, lines as ties.
- **Structure:** `powergrid`: undirected; 4941 nodes, 6594 ties. Vertex attributes: none; edge attributes: none.
- **Source:** Watts and Strogatz (1998), *Nature* 393
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/powergrid.html>
- **Load:** `nwwebuse schoch powergrid`

### radoslaw_email: Radoslaw - Email Network
{: #radoslaw_email }
- **What:** Internal e-mail traffic among 167 employees of a manufacturing company; directed, valued.
- **Structure:** `radoslaw_email`: directed, valued, loops; 167 nodes, 5784 ties. Vertex attributes: none; edge attributes: weight.
- **Source:** Michalski, Palus and Kazienko (2011), *Lecture Notes in Business Information Processing* 87
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/radoslaw_email.html>
- **Load:** `nwwebuse schoch radoslaw_email`

### ucforum: UC forum (2-mode)
{: #ucforum }
- **What:** Two-mode network of students and the forums of an online community, valued by the number of posts.
- **Structure:** `ucforum`: two-mode, valued; 1421 nodes, 7089 ties (modes 899 and 522). Vertex attributes: type; edge attributes: weight.
- **Source:** Opsahl and Panzarasa (2011), *Social Networks* 34
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/ucforum.html>
- **Load:** `nwwebuse schoch ucforum`

### ucsocial: UC forum (messages sent)
{: #ucsocial }
- **What:** Messages sent among the students of an online community; directed and valued.
- **Structure:** `ucsocial`: directed, valued; 1899 nodes, 20296 ties. Vertex attributes: none; edge attributes: weight.
- **Source:** Opsahl and Panzarasa (2009), *Social Networks* 31
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/ucsocial.html>
- **Load:** `nwwebuse schoch ucsocial`

### unicodelang: Unicodelang
{: #unicodelang }
- **What:** Two-mode network of countries and the languages spoken there, valued by the share of speakers.
- **Structure:** `unicodelang`: two-mode, valued; 868 nodes, 38 ties (modes 254 and 614). Vertex attributes: type; edge attributes: weight.
- **Source:** Unicode CLDR territory-language data
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/unicodelang.html>
- **Load:** `nwwebuse schoch unicodelang`

### usa_borders: USA Bordering States
{: #usa_borders }
- **What:** The 48 contiguous US states and the District of Columbia, tied when they share a border.
- **Structure:** `usa_borders`: undirected; 49 nodes, 107 ties. Vertex attributes: none; edge attributes: none.
- **Source:** Knuth (2008), *The Art of Computer Programming* vol. 4
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/usa_borders.html>
- **Load:** `nwwebuse schoch usa_borders`

### usflights: US Flights 2010
{: #usflights }
- **What:** Flights between US airports in 2010; directed, valued by number of flights.
- **Structure:** `usflights`: directed, valued; 1574 nodes, 28236 ties. Vertex attributes: none; edge attributes: weight.
- **Source:** Opsahl (2011), *Why Anchorage is not (that) important*
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/usflights.html>
- **Load:** `nwwebuse schoch usflights`


## Miscellaneous networks
{: #misc }

Data sets from various sources that fit none of the groups above.

### adjnoun: Words in David Copperfield
{: #adjnoun }
- **What:** Adjectives and nouns of the novel David Copperfield, tied when they occur next to each other.
- **Structure:** `adjnoun`: undirected; 112 nodes, 425 ties. Vertex attributes: id, value; edge attributes: none.
- **Source:** Newman (2006), *Physical Review E* 74
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/adjnoun.html>
- **Load:** `nwwebuse schoch adjnoun`

### atp: ATP Tennis (1968-2021)
{: #atp }
- **What:** Professional men's tennis matches by year, 1968 to 2021 (54 networks); a tie runs from loser to winner and carries match attributes.
- **Structure:** 54 networks `atp_1` ... `atp_54`: directed, valued, multiple edges, loops (some networks only); 345-597 nodes, 1213-3892 ties each. Vertex attributes: age, hand, country; edge attributes: surface, weight.
- **Source:** Jeff Sackmann's tennis data, https://github.com/JeffSackmann (credit requested)
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/atp.html>
- **Load:** `nwwebuse schoch atp`

### cent_lit: Centrality literature network
{: #cent_lit }
- **What:** Citations among the literature on centrality, 1948 to 1979; directed.
- **Structure:** `cent_lit`: directed; 129 nodes, 613 ties. Vertex attributes: none; edge attributes: none.
- **Source:** Hummon, Doreian and Freeman (1990), *Knowledge* 11
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/cent_lit.html>
- **Load:** `nwwebuse schoch cent_lit`

### clique_graph: Illustrating cliques
{: #clique_graph }
- **What:** A small constructed graph that illustrates cliques and cores.
- **Structure:** `clique_graph`: undirected; 30 nodes, 47 ties. Vertex attributes: none; edge attributes: none.
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/clique_graph.html>
- **Load:** `nwwebuse schoch clique_graph`

### coleman: Coleman's High School Friendship Data
{: #coleman }
- **What:** Friendship choices among 73 boys of one high school at two points in time; directed.
- **Structure:** 2 networks `coleman_1` ... `coleman_2`: directed; 73 nodes, 243-263 ties each. Vertex attributes: none; edge attributes: none.
- **Source:** Coleman (1964), *Introduction to Mathematical Sociology*, Free Press
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/coleman.html>
- **Load:** `nwwebuse schoch coleman`

### core_graph: Illustrating core-periphery
{: #core_graph }
- **What:** A constructed graph that illustrates a core-periphery structure.
- **Structure:** `core_graph`: undirected; 100 nodes, 578 ties. Vertex attributes: none; edge attributes: none.
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/core_graph.html>
- **Load:** `nwwebuse schoch core_graph`

### cosponsor: Senat 2015 Bill cosponsorship
{: #cosponsor }
- **What:** Two-mode network of US senators and the bills they co-sponsored, 115th Congress.
- **Structure:** `cosponsor`: two-mode; 3984 nodes, 26392 ties (modes 110 and 3874). Vertex attributes: type, party; edge attributes: none.
- **Source:** GovTrack.us
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/cosponsor.html>
- **Load:** `nwwebuse schoch cosponsor`

### football_triad: Simplified football results
{: #football_triad }
- **What:** 112 networks of football league results, with a directed tie from the winning to the losing team.
- **Structure:** 112 networks `football_triad_1` ... `football_triad_112`: directed; 6-28 nodes, 20-273 ties each. Vertex attributes: none; edge attributes: none.
- **Source:** soccerverse.com
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/football_triad.html>
- **Load:** `nwwebuse schoch football_triad`

### glasgow129: Teenage Friends and Lifestyle Study data
{: #glasgow129 }
- **What:** Three waves of friendship networks and behaviour of 129 Scottish school pupils.
- **Structure:** 3 networks `glasgow129_1` ... `glasgow129_3`: directed, loops (some networks only); 129 nodes, 445-464 ties each. Vertex attributes: alcohol, tobacco, cannabis, age, money, romantic, familysmoking, sex_F; edge attributes: friendship_level.
- **Source:** Glasgow data page of the RSiena project, https://www.stats.ox.ac.uk/~snijders/siena/Glasgow_data.htm
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/glasgow129.html>
- **Load:** `nwwebuse schoch glasgow129`

### got: Game of Thrones Interactions
{: #got }
- **What:** Seven networks, one per season of the television series Game of Thrones: characters tied, with weights, when they interact.
- **Structure:** 7 networks `got_1` ... `got_7`: undirected, valued; 81-172 nodes, 398-667 ties each. Vertex attributes: none; edge attributes: weight.
- **Source:** Beveridge and Chemers (2018); https://github.com/mathbeveridge/gameofthrones/
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/got.html>
- **Load:** `nwwebuse schoch got`

### greys: Grey's Anatomy Hook-ups
{: #greys }
- **What:** Romantic and sexual relations among characters of the television series Grey's Anatomy.
- **Structure:** `greys`: undirected; 54 nodes, 57 ties. Vertex attributes: sex, race, birthyear, position, season, sign; edge attributes: none.
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/greys.html>
- **Load:** `nwwebuse schoch greys`

### gss_egor: General Social Survey 2004 Egocentric Network Data
{: #gss_egor }
- **What:** Not a network: egocentric survey data of 594 respondents of the 2004 General Social Survey, in three tables (egos, alters, alter-alter ties). Load: `nwnetworkdata tables gss_egor, table(ego) clear`
- **Source:** Smith et al., *General Social Surveys, 1972-2021*, NORC (2022)
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/gss_egor.html>

### knecht: Knecht's School Data
{: #knecht }
- **What:** Four waves of friendship among the 26 pupils of one Dutch school class.
- **Structure:** 4 networks `knecht_1` ... `knecht_4`: directed, loops (some networks only); 26 nodes, 91-133 ties each. Vertex attributes: deli, alcohol, gender, age, ethnic, religion; edge attributes: none.
- **Source:** Knecht (2006), PhD thesis, Utrecht University
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/knecht.html>
- **Load:** `nwwebuse schoch knecht`

### s50: 50-actor excerpt from the Teenage Friends and Lifestyle Study data
{: #s50 }
- **What:** A 50-pupil excerpt of the Glasgow study: three waves of friendship networks.
- **Structure:** 3 networks `s50_1` ... `s50_3`: undirected; 50 nodes, 74-81 ties each. Vertex attributes: smoke; edge attributes: none.
- **Source:** RSiena data page, https://www.stats.ox.ac.uk/~snijders/siena/siena_datasets.htm
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/s50.html>
- **Load:** `nwwebuse schoch s50`

### starwars: Star Wars Episode 1-7
{: #starwars }
- **What:** Seven networks, one per Star Wars film (episodes 1 to 7): characters tied, with weights, when they appear in the same scene.
- **Structure:** 7 networks `starwars_1` ... `starwars_7`: undirected, valued; 20-38 nodes, 55-135 ties each. Vertex attributes: height, mass, hair_color, skin_color, eye_color, birth_year, sex, homeworld, species; edge attributes: weight.
- **Source:** https://github.com/evelinag/StarWars-social-network
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/starwars.html>
- **Load:** `nwwebuse schoch starwars`

### us_flights: Flights within the US
{: #us_flights }
- **What:** Flights between US airports; undirected.
- **Structure:** `us_flights`: undirected; 276 nodes, 2682 ties. Vertex attributes: city, state, country, latitude, longitude; edge attributes: none.
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/us_flights.html>
- **Load:** `nwwebuse schoch us_flights`

### wta: WTA Tennis (1968-2021)
{: #wta }
- **What:** Professional women's tennis matches by year, 1968 to 2021 (54 networks); a tie runs from loser to winner and carries match attributes.
- **Structure:** 54 networks `wta_1` ... `wta_54`: directed, valued, multiple edges, loops (some networks only); 152-2513 nodes, 249-18901 ties each. Vertex attributes: age, hand, country; edge attributes: surface, weight.
- **Source:** Jeff Sackmann's tennis data, https://github.com/JeffSackmann (credit requested)
- **Upstream page:** <https://schochastics.github.io/networkdata/reference/wta.html>
- **Load:** `nwwebuse schoch wta`
