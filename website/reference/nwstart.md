---
title: "nwstart"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
---

# `nwstart`

## Contents

**SectionDescription**

- hline 46
- [**[NW-4.1]****A first session**](nwstart)
- [**[NW-4.2]****Three ideas to know**](nwstart)
- [**[NW-4.3]****Getting your own data in**](nwstart)
- [**[NW-4.4]****Tutorials**](nwstart)
- [**[NW-4.5]****Where to look next**](nwstart)

## A first session

Load the marriage and business ties between 16 Florentine families, look at what is in memory, and describe, plot and analyze the marriage network. Click a command to run it.

- `. nwwebuse florentine, nwclear`
- `. nwds`
- `. nwsummarize flomarriage`
- `. nwplot flomarriage, lab`
- `. nwdegree flomarriage, generate(deg)`
- `. nwbetween flomarriage, generate(btw)`
- `. list _nwnode deg btw in 1/5`

`nwwebuse` loads two networks, *flomarriage* and *flobusiness*. `nwdegree` and `nwbetween` store one value per node in ordinary Stata variables, which you can list, summarize or use in a regression.

## Three ideas to know

1. **Networks have names.** You refer to a network by its [netname](netname), just as you refer to a variable by its `varname`. Network lists can be abbreviated like variable lists: `nwsummarize flo*`.

2. **Networks are not variables.** nwcommands keeps networks next to the dataset. Stata's `clear` does not remove them; [nwclear](nwclear) does. Results for nodes (`generate()`) are ordinary variables, one observation per node.

3. **There is a current network.** A command without a network name uses the current network, normally the one loaded or created last; [nwcurrent](nwcurrent) shows and changes it.

More of these parallels with Stata are in [[NW-1.3]](nwintro) and [[NW-1.4]](nwintro).

## Getting your own data in

- **[nwfromedge](nwfromedge)** --- from an edge list (one row per tie) in the dataset
- **[nwset](nwset)** --- from an adjacency matrix stored as variables, or from an edge list
- **[nwimport](nwimport)** --- from a Pajek, UCINET, GML or edge list file
- **[nwuse](nwuse)** --- from a network file saved with [nwsave](nwsave)
- **[nwwebuse](nwwebuse)** --- the example data sets ([netexample](netexample))

Node attributes are ordinary variables in the same dataset, one observation per node. The tutorial [A reproducible workflow](https://nwcommands.org/tutorials/04-reproducible-workflow/) shows a complete do-file, from CSV files of ties and people to saved results.

## Tutorials

Nineteen worked tutorials, each with real Stata output, are at browse "https://nwcommands.org/tutorials/". They build on each other, but each one also stands alone.

- **Getting started**
- **1** --- [Installation and setup](https://nwcommands.org/tutorials/01-installation-setup/)
- **2** --- [Core concepts](https://nwcommands.org/tutorials/02-core-concepts/)
- **3** --- [Importing and exporting](https://nwcommands.org/tutorials/03-importing-exporting/)
- **4** --- [A reproducible workflow](https://nwcommands.org/tutorials/04-reproducible-workflow/)
- **Working with networks**
- **5** --- [Visualization](https://nwcommands.org/tutorials/05-visualization/)
- **6** --- [Generating networks](https://nwcommands.org/tutorials/06-generating-networks/)
- **7** --- [Manipulating networks](https://nwcommands.org/tutorials/07-manipulating-networks/)
- **Describing networks**
- **8** --- [Centrality](https://nwcommands.org/tutorials/08-centrality/)
- **9** --- [Paths and ego networks](https://nwcommands.org/tutorials/09-paths-ego-networks/)
- **10** --- [Cohesion and subgroups](https://nwcommands.org/tutorials/10-cohesion-subgroups/)
- **11** --- [Brokerage and structural holes](https://nwcommands.org/tutorials/11-brokerage/)
- **12** --- [Triads, dyads and motifs](https://nwcommands.org/tutorials/12-triads-motifs/)
- **13** --- [Positions and equivalence](https://nwcommands.org/tutorials/13-positions-equivalence/)
- **14** --- [Homophily, assortativity and mixing](https://nwcommands.org/tutorials/14-homophily-mixing/)
- **Other kinds of networks**
- **15** --- [Two-mode networks](https://nwcommands.org/tutorials/15-two-mode-networks/)
- **16** --- [Valued networks](https://nwcommands.org/tutorials/16-valued-networks/)
- **17** --- [Networks over time](https://nwcommands.org/tutorials/17-networks-over-time/)
- **Testing and models**
- **18** --- [Testing hypotheses about networks](https://nwcommands.org/tutorials/18-testing/)
- **19** --- [Longitudinal models: an overview](https://nwcommands.org/tutorials/19-intro-longitudinal-models/)

The statistical model packages have their own tutorials: [nwsaom](https://nwcommands.org/nwsaom/), [nwergm](https://nwcommands.org/nwergm/), [nwdynam](https://nwcommands.org/nwdynam/) and [nwrem](https://nwcommands.org/nwrem/).

## Where to look next

- **[nwtopical](nwtopical)** --- all commands, by topic
- **[nwalphabetical](nwalphabetical)** --- all commands, alphabetically
- **[nwintro](nwintro)** --- introduction, requirements, network size and speed
- **[nwnetworktypes](nwnetworktypes)** --- what each command does with directed, valued, signed and two-mode networks
- **[nwprogramming](nwprogramming)** --- writing your own network commands
- **[Getting help](https://nwcommands.org/help/)** --- questions, bug reports and the mailing list

Most commands also have a dialog box: after `nwinstall, all`, the **Network Analysis** menu appears under **User**.

---

*nwcommands version 3.25.0, 14 November 2026* ([check your installed version](nwversion))
