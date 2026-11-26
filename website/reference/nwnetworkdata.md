---
title: "nwnetworkdata"
parent: "Core command reference"
grand_parent: "Packages and reference"
nav_exclude: true
search_exclude: false
description: "Import the networks of the networkdata collection (R package by David Schoch) from GitHub"
---

# `nwnetworkdata`

Import the networks of the networkdata collection (R package by David Schoch) from GitHub

## Syntax

```stata
List the available data sets (one row per data set, or one row per network)
nwnetworkdata list [pattern] [, net:works dir:ected undir:ected two:mode one:mode
weight:ed mult:iple loops temp:oral k:ind(string) clear]
Show the properties of the networks of a data set
nwnetworkdata describe dataname
Load one network, or all networks of a data set, as nwcommands networks
nwnetworkdata [load] name [, nwclear clear replace name(newname)
el:ement(numlist) valuea:ttr(varname) bin:ary noattrs from(source) ref:resh withr]
Load the tie list or the node table, with all attributes, as an ordinary dataset
nwnetworkdata edges name [, clear el:ement(#) from(source) withr]
nwnetworkdata nodes name [, clear el:ement(#) from(source) withr]
Load one of the three tables of an ego-centered data set (class egor)
nwnetworkdata tables dataname , tab:le(ego|alter|aatie) [clear from(source) withr]
Source and cache
nwnetworkdata source [set url_or_folder | default]
nwnetworkdata cache [clear]
```

## Description

`nwnetworkdata` imports the networks of David Schoch's R package *networkdata* (https://github.com/schochastics/networkdata) into nwcommands: 990 R objects, which are 2,274 networks (917 single *igraph* objects and 72 lists holding 1,357 further networks, for example the waves of a longitudinal study, the seasons of a series or the groups of an animal study) plus one ego-centered (*egor*) object that is not a network. Every data set is documented (description, source, references) on [nwcommands.org/datasets/schoch](https://nwcommands.org/datasets/schoch/); `nwnetworkdata describe` *name* shows its size and attributes.

**This package contains no network data.** When you ask for a network, `nwnetworkdata` downloads the original file (*dataname*`.rda`) from the GitHub repository of the R package and keeps it in a cache folder of yours. The file is an R data file (compressed, in R's serialization format); `nwnetworkdata` reads it, on your computer, with Stata alone (**no R is needed**): it decompresses the file, decodes the R data, takes the *igraph* objects in it and writes csv tables into the cache; the network is built from these with [nwfromedge](nwfromedge). The result is the same as when R and its package igraph do the conversion. If the reader meets something it does not handle (which does not happen in the 990 objects of the collection except the *egor* object, see below) it says so and uses R, if you have it (`Rscript` is looked for in the usual places of a Windows installation and in the path, on macOS and Linux also in /usr/local/bin, /opt/homebrew/bin and /usr/bin; choose another with `global nwnd_rscript "path/to/Rscript"`); otherwise it stops with an error and never guesses. A damaged or truncated file is refused (error 610), as is a file that is larger than the limits of the reader. The option `withr` converts with R and the R package igraph (`install.packages("igraph")`) instead; the small R script that does it comes with this command (`nwnetworkdata_convert.R`) and only reads the downloaded file and writes the csv tables. The only file shipped in addition to code and help is a catalogue of the names, type and size of the networks, which `list`, `describe` and the name checks use. Only names that are in the catalogue are downloaded, and only from the repository of the R package.

*name* is either the name of a network or the name of a data set. A data set that is a list of networks (`sampson`, `atp`, `animal_12`, ...) loads all its networks, which are named *dataname*`_1`, *dataname*`_2`, ... in the order of the list; one of them can be loaded by that name (`nwnetworkdata sampson_3`) or by `element()`. Networks that are not part of a list have the name of the data set.

Directedness, two-mode status, loops and whether the ties are valued are taken from the original *igraph* object; nothing has to be specified. Node labels are the `name` vertex attribute of the *igraph* object (cleaned to valid names: letters, digits and underscores, at most 28 characters, unique), or `n1`, `n2`, ... if the object has no vertex names. The unchanged vertex names are kept in the variable `nd_name`. Every other vertex attribute becomes a variable of the current dataset, in the order of the nodes (attribute names are made valid Stata names: other characters become `_`). With a list of networks the dataset holds the attributes of the last network loaded; use `nwnetworkdata nodes` *name* to get the node table of any network.

## Options

`nwclear` specifies that it is okay to replace all network data in memory, even though the current network data have not been saved to disk. It removes all networks in memory first (as [nwwebuse](nwwebuse) does).

`clear` specifies that it is okay to replace the data in memory, but the networks in memory are kept.

`replace` replaces a network that exists already under the name that is loaded.

`name(`*newname*`)` names the network *newname*. For a data set with several networks, *newname* is the prefix: *newname*`_1`, *newname*`_2`, ...

`element(`*numlist*`)` loads only the listed elements of a list of networks.

`valueattr(`*varname*`)` takes the tie values from this numeric edge attribute (default: `weight`, if the network has one).

`binary` ignores edge weights and loads a binary network.

`noattrs` does not load the node attributes into the dataset (only the labels).

`from(`*source*`)` is where the original `.rda` files are fetched from: an address in the repository *https://raw.githubusercontent.com/schochastics/networkdata/* (other addresses are refused) or an existing local folder that contains the files (for example a clone of the repository). Default: the global `$nwnd_source` set by `nwnetworkdata source set`; if empty, *https://raw.githubusercontent.com/schochastics/networkdata/main/data*.

`refresh` downloads and converts the data set again, also if it is in the cache.

`withr` converts with R and the R package igraph instead of the reader without R (a data set that is in the cache and was converted before is converted again). It needs `Rscript`; error 601 if R or igraph is missing.

`list` options select networks: `directed`, `undirected`, `twomode` (also `onemode`), `weighted`, `multiple` (networks with multiple edges), `loops`, `temporal` (networks whose edges have a time stamp), `kind(igraph)` or `kind(list_of_igraph)`, and a text *pattern* that has to be part of the name. `networks` lists networks instead of data sets; `clear` leaves the list in memory as a dataset (variables `obj` and `net`).

## Cache and offline use

The cache is the folder `nwnd` in your PLUS directory (`sysdir`; change it with `global nwnd_cache "folder"`). It holds the downloaded `.rda` files (`rda`), their csv conversions (`conv`) and Stata versions of these (`typed`). A data set that is in the cache is not downloaded or converted again, so it can be used **without internet connection**. If a data set has to be downloaded and cannot be (no connection, GitHub not reachable), the command stops with error 677 and tells so; if R or igraph is needed (option `withr`, or the *egor* object) and missing, it stops with error 601 and shows the message of R. `nwnetworkdata cache` reports the folder and the number of data sets in it, `nwnetworkdata cache clear` deletes them. If the files of the repository change, use `refresh`. The catalogue was made from the repository as of November 2026 (version 0.2.4); a data set added later is not in `list`.

## Remarks

**What is not a plain network.** Multiple edges and edge attributes cannot be stored in an nwcommands network, which is a matrix: parallel edges are summed (weights) or counted (no weights), so that an unweighted multigraph becomes a valued network (121 networks; `describe` reports it). Edge attributes other than the tie value, and the individual parallel edges, stay available with `nwnetworkdata edges`. Edges with a time stamp (7 networks, for example `dnc_temporalGraph`) are loaded aggregated over time; they are not loaded as temporal networks, and the times are in `nwnetworkdata edges`. Ties with the value 0 are no ties. Two-mode networks (23) are loaded with `twomode` status, the first mode being the *igraph* vertices of type `FALSE`; they are limited to 20,000 nodes as all two-mode networks in nwcommands. The object `gss_egor` (class *egor*) holds ego-centered survey data, three tables, no network: it is not loaded by `nwnetworkdata gss_egor` (error 459) but with `nwnetworkdata tables gss_egor, table(ego)`, which is the one use that needs R. Node labels from accented letters lose the accent (a letter with an accent becomes the plain letter; the unchanged names are in `nd_name`); R's own conversion gives other labels on other systems.

**Licence, attribution, citation.** nwnetworkdata only imports; the data are not part of this package and not distributed with it. The R package networkdata is distributed under the MIT licence (Copyright (c) 2019 David Schoch), which covers the package itself. It documents no licence or permission for the individual data sets, which come from many original sources and may have their own terms (the page [nwcommands.org/datasets/schoch](https://nwcommands.org/datasets/schoch/) gives an overview and links to the documentation of the R package): please check the original sources, cite them, and cite the collection: David Schoch (2022), *networkdata: Repository of Network Datasets*, https://doi.org/10.5281/zenodo.7189928. The tennis networks (`atp`, `wta`) were compiled from data of Jeff Sackmann (https://github.com/JeffSackmann), whom the author asks users to credit.

## Examples

What is there?

```stata
. nwnetworkdata list
. nwnetworkdata list, twomode
. nwnetworkdata list sampson, networks
. nwnetworkdata describe karate
```
Load Zachary's karate club and a two-mode network

```stata
. nwnetworkdata karate, nwclear
. nwnetworkdata southern_women, nwclear
```
Load the ten Sampson monastery networks, or just the third

```stata
. nwnetworkdata sampson, nwclear
. nwnetworkdata sampson_3, nwclear
```
Tennis 1968, with the player attributes age, hand and country in the dataset

```stata
. nwnetworkdata atp, nwclear element(1)
```
The tie list of that network, with the surface of each match

```stata
. nwnetworkdata edges atp_1, clear
```
Use a local clone of the repository (no download)

```stata
. nwnetworkdata source set "C:/data/networkdata/data"
```
Convert with R instead of the reader without R

```stata
. nwnetworkdata karate, nwclear withr
```

Name of Rscript, if it is not found

```stata
. global nwnd_rscript "C:/Program Files/R/R-4.3.0/bin/Rscript.exe"
```

## Stored results

- `nwnetworkdata load` stores in `r()`:

- **`r(n_loaded)`** --- number of networks loaded
- **`r(net)`** --- name of the last network loaded (the current network)
- **`r(nets)`** --- names of all networks loaded
- **`r(obj)`** --- name of the data set

- `nwnetworkdata list` stores `r(n_objects)` and `r(n_networks)`.

## See also

- [nwwebuse](nwwebuse), [netexample](netexample), [nwfromedge](nwfromedge), [nwimport](nwimport), [nwset](nwset)

---

*nwcommands version 3.37.2, 26 November 2026* ([check your installed version](nwversion))
