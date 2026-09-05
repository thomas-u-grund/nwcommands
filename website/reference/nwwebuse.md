---
title: "nwwebuse"
parent: "Command reference"
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
Report URL from which datasets will be obtained
nwwebuse query
Specify URL from which network dataset will be obtained
nwwebuse set [http://]url[/]
Reset URL to default
nwwebuse set
```

## Description

`nwwebuse` *filename* loads the specified network dataset, obtaining it over the web and [sets all networks](nwset) in this dataset. By default, datasets are obtained from *https://raw.githubusercontent.com/thomas-u-grund/nwcommands/master/data*.

Several [network datasets](netexample) are available from this source. If *filename* is specified without a suffix, `.dta` is assumed.

`nwwebuse` `query` reports the URL from which network datasets will be obtained.

`nwwebuse` `set` allows you to specify the URL to be used as the source for network datasets.

`nwwebuse` `set` without arguments resets the source to *https://raw.githubusercontent.com/thomas-u-grund/nwcommands/master/data*.

## Examples

- Report URL from which network datasets will be obtained
- `. nwwebuse query`

- Change URL from which datasets will be obtained
- `. nwwebuse set http://www.zzz.edu/users/~sue`

- Reset URL to the default
- `. nwwebuse set`

- Load the [Florentine network dataset](netexample) that is stored at
- https://raw.githubusercontent.com/thomas-u-grund/nwcommands/master/data
- `. nwwebuse florentine`

- Equivalent to above command
- `. nwwebuse https://raw.githubusercontent.com/thomas-u-grund/nwcommands/master/data/florentine`

## Supported network types

Binary: yes. Directed: yes. Weighted: yes. Signed: yes. Two-mode: yes - fetches and loads an example dataset exactly as published; the specific dataset fetched determines which of these properties the resulting network actually has, not this command itself.

## See also

- [nwuse](nwuse), [nwimport](nwimport), `webuse`

- last certified : 23 Aug 2026
