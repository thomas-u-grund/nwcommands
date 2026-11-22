---
title: "nwwebuse"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Load network data over the web"
---

# `nwwebuse`

Load network data over the web

## Syntax

```stata
Load network data over the web
nwwebuse ["]filename["] [, nwclear]
Load a network from Schoch's collection networkdata (no R needed)
nwwebuse schoch name [, options]
nwwebuse name, schoch [options]
nwwebuse schoch [, list]
nwwebuse schoch list
nwwebuse schoch describe name
Report URL from which datasets will be obtained
nwwebuse query
Specify URL from which network dataset will be obtained
nwwebuse set [http://]url[/]
Reset URL to default
nwwebuse set
```

## Description

`nwwebuse` *filename* loads the specified network dataset, obtaining it over the web and [sets all networks](nwset) in this dataset. By default, datasets are obtained from *https://nwcommands.org/examples*, a copy of the `data` folder of the nwcommands repository on GitHub. If the website cannot be reached, `nwwebuse` loads the same file from GitHub (*https://raw.githubusercontent.com/thomas-u-grund/nwcommands/main/data*).

Several [network datasets](netexample) are available from this source. If *filename* is specified without a suffix, `.dta` is assumed.

`nwwebuse` `schoch` *name* loads one of the networks of the R package *networkdata* by David Schoch (*https://github.com/schochastics/networkdata*), for example `nwwebuse schoch karate`. The data are not part of nwcommands: `nwnetworkdata` downloads them from Schoch's repository the first time you ask for a data set and keeps them in a cache, and reads them with Stata alone (**no R is needed**; the option `withr` of `nwnetworkdata` converts with R and the package igraph instead). Every load prints which network was loaded and where the data come from. Cite the collection and the original source of each data set; see [nwnetworkdata](nwnetworkdata) and [nwcommands.org/datasets/schoch](https://nwcommands.org/datasets/schoch/). `nwwebuse schoch` alone gives an overview; `nwwebuse schoch list` lists all data sets and `nwwebuse schoch describe` *name* shows one. Options (for example `name()`, `element()`) are passed to `nwnetworkdata`.

`nwwebuse` `query` reports the URL from which network datasets will be obtained.

`nwwebuse` `set` allows you to specify the URL to be used as the source for network datasets.

`nwwebuse` `set` without arguments resets the source to *https://nwcommands.org/examples*.

## Option

`nwclear` specifies that it is okay to replace all network data in memory, even though the current network data have not been saved to disk.

## Network types

The command works the same for every network type (see [nwnetworktypes](nwnetworktypes)).

## Examples

- Report URL from which network datasets will be obtained
- `. nwwebuse query`

- Change URL from which datasets will be obtained
- `. nwwebuse set http://www.zzz.edu/users/~sue`

- Reset URL to the default
- `. nwwebuse set`

- Load the [Florentine network dataset](netexample) that is stored at
- https://nwcommands.org/examples
- `. nwwebuse florentine`

- Equivalent to above command
- `. nwwebuse https://nwcommands.org/examples/florentine`

## See also

- [nwuse](nwuse), [nwimport](nwimport), `webuse`

---

*nwcommands version 3.35.1, 22 November 2026* ([check your installed version](nwversion))
